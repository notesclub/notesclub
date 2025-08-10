defmodule Notesclub.Bluesky.Api do
  @moduledoc """
  Client for interacting with the Bluesky API.
  """

  require Logger

  @bluesky_base_url "https://bsky.social"

  def post(message) do
    with {:ok, access_token} <- authenticate(),
         {:ok, handle} <- get_handle(),
         {:ok, _response} <- create_post(access_token, handle, message) do
      {:ok, "Post created successfully"}
    else
      {:error, reason} ->
        Logger.error("Failed to post to Bluesky: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp authenticate do
    handle = Application.get_env(:notesclub, :bluesky_handle)
    password = Application.get_env(:notesclub, :bluesky_password)

    if handle && password do
      auth_url = "#{@bluesky_base_url}/xrpc/com.atproto.server.createSession"

      auth_data = %{
        "identifier" => handle,
        "password" => password
      }

      case Req.post(auth_url, json: auth_data) do
        {:ok, %Req.Response{status: 200, body: %{"accessJwt" => access_token}}} ->
          {:ok, access_token}

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, "Authentication failed with status #{status}: #{inspect(body)}"}

        {:error, reason} ->
          {:error, "HTTP request failed: #{inspect(reason)}"}
      end
    else
      {:error, "Bluesky credentials not configured"}
    end
  end

  defp get_handle do
    handle = Application.get_env(:notesclub, :bluesky_handle)

    if handle do
      {:ok, handle}
    else
      {:error, "Bluesky handle not configured"}
    end
  end

  defp create_post(access_token, handle, text) do
    post_url = "#{@bluesky_base_url}/xrpc/com.atproto.repo.createRecord"

    facets = extract_link_facets(text)

    record = %{
      "$type" => "app.bsky.feed.post",
      "text" => text,
      "createdAt" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    # Add facets only if there are links to make clickable
    record = if facets != [], do: Map.put(record, "facets", facets), else: record

    post_data = %{
      "repo" => handle,
      "collection" => "app.bsky.feed.post",
      "record" => record
    }

    headers = [
      {"Authorization", "Bearer #{access_token}"}
    ]

    case Req.post(post_url, json: post_data, headers: headers) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, "Post creation failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  defp extract_link_facets(text) do
    # Extract URL facets and hashtag facets, then combine them
    url_facets = extract_url_facets(text)
    hashtag_facets = extract_hashtag_facets(text)

    # Combine and sort by byte position
    (url_facets ++ hashtag_facets)
    |> Enum.sort_by(fn facet -> facet["index"]["byteStart"] end)
  end

  defp extract_url_facets(text) do
    # More precise regex to match URLs with proper boundaries
    # This matches http/https URLs but stops at whitespace or common delimiters
    url_regex = ~r/https?:\/\/[^\s\]]+/

    Regex.scan(url_regex, text, return: :index)
    |> Enum.map(fn [{start_char_index, length}] ->
      # Extract the raw URL
      raw_url = String.slice(text, start_char_index, length)

      # Clean the URL by removing common trailing punctuation that shouldn't be part of URLs
      cleaned_url = Regex.replace(~r/[.,!?;:]+$/, raw_url, "")

      # Convert character indices to byte indices
      # Calculate the byte position of the cleaned URL within the original text
      byte_start = text |> String.slice(0, start_char_index) |> byte_size()
      byte_end = byte_start + byte_size(cleaned_url)

      # Validate that this is a proper URI before including it
      case URI.parse(cleaned_url) do
        %URI{scheme: scheme, host: host}
        when scheme in ["http", "https"] and
               not is_nil(host) and
               host != "" and
               host != "." ->
          %{
            "index" => %{
              "byteStart" => byte_start,
              "byteEnd" => byte_end
            },
            "features" => [
              %{
                "$type" => "app.bsky.richtext.facet#link",
                "uri" => cleaned_url
              }
            ]
          }

        _ ->
          # Skip invalid URIs
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp extract_hashtag_facets(text) do
    # Regular expression to match hashtags (#word)
    hashtag_regex = ~r/#[a-zA-Z0-9_]+/

    Regex.scan(hashtag_regex, text, return: :index)
    |> Enum.map(fn [{start_char_index, length}] ->
      # Convert character indices to byte indices
      byte_start = text |> String.slice(0, start_char_index) |> byte_size()
      byte_end = text |> String.slice(0, start_char_index + length) |> byte_size()

      # Extract the hashtag (including the #)
      hashtag = String.slice(text, start_char_index, length)
      # Remove the # to get just the tag name
      tag_name = String.slice(hashtag, 1..-1//1)

      %{
        "index" => %{
          "byteStart" => byte_start,
          "byteEnd" => byte_end
        },
        "features" => [
          %{
            "$type" => "app.bsky.richtext.facet#tag",
            "tag" => tag_name
          }
        ]
      }
    end)
  end
end
