defmodule Notesclub.BlueskyApi do
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

    post_data = %{
      "repo" => handle,
      "collection" => "app.bsky.feed.post",
      "record" => %{
        "$type" => "app.bsky.feed.post",
        "text" => text,
        "createdAt" => DateTime.utc_now() |> DateTime.to_iso8601()
      }
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
end
