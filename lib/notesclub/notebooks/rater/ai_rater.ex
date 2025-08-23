defmodule Notesclub.Notebooks.Rater.API do
  @moduledoc """
  OpenRouter API client for AI-powered notebook analysis.
  """

  require Logger
  alias Notesclub.Notebooks.Notebook

  @openrouter_base_url "https://openrouter.ai/api/v1"
  # Using a more reliable model that supports structured outputs
  @model "openai/gpt-4o-mini"

  @doc """
  Rates a notebook's interest level for Elixir developers using OpenRouter's structured outputs.
  """
  @spec rate_notebook_interest(Notebook.t()) :: {:ok, integer()} | {:error, term()}
  def rate_notebook_interest(%Notebook{} = notebook) do
    case prepare_content(notebook) do
      {:ok, content} ->
        make_rating_request(content)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp prepare_content(%Notebook{content: nil}), do: {:ok, 0}
  defp prepare_content(%Notebook{content: ""}), do: {:ok, 0}

  defp prepare_content(%Notebook{content: content, title: title, github_filename: filename}) do
    # Prepare a comprehensive view of the notebook for analysis
    analysis_content = """
    NOTEBOOK ANALYSIS REQUEST

    Title: #{title || "Untitled"}
    Filename: #{filename || "unknown.livemd"}

    Content:
    #{content}
    """

    {:ok, analysis_content}
  end

  defp make_rating_request(content) do
    api_key = get_api_key()

    if api_key do
      # Use fallback format by default since structured outputs may not be supported
      Logger.info("Using fallback request format for better compatibility")
      try_fallback_request(content, api_key)
    else
      {:error, :no_api_key}
    end
  end

  defp try_fallback_request(content, api_key) do
    request_body = build_fallback_request_body(content)

    case Req.post(
           "#{@openrouter_base_url}/chat/completions",
           json: request_body,
           headers: [
             {"Authorization", "Bearer #{api_key}"},
             {"Content-Type", "application/json"},
             {"HTTP-Referer", "https://notesclub.app"},
             {"X-Title", "NotesClub Notebook Rating"}
           ]
         ) do
      {:ok, %{status: 200, body: body}} ->
        Logger.info("Fallback request response: #{inspect(body)}")
        parse_fallback_response(body)

      {:ok, %{status: status, body: body}} ->
        Logger.error("OpenRouter fallback API error: #{status} - #{inspect(body)}")
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        Logger.error("OpenRouter fallback request failed: #{inspect(reason)}")
        {:error, {:request_failed, reason}}
    end
  end

  defp build_fallback_request_body(content) do
    %{
      model: @model,
      messages: [
        %{
          role: "system",
          content: """
          You are an expert Elixir developer and educator tasked with rating Livebook notebooks based on their interest level to Elixir developers.

          Rate the notebook on a scale from 0 to 1000 where:
          - 0-100: Not interesting (no Elixir content, very basic, or irrelevant)
          - 101-300: Slightly interesting (minimal Elixir content, basic examples)
          - 301-500: Moderately interesting (some Elixir code, educational value)
          - 501-700: Quite interesting (good Elixir examples, practical use cases)
          - 701-900: Very interesting (advanced concepts, comprehensive examples, real-world applications)
          - 901-1000: Extremely interesting (cutting-edge techniques, exceptional educational value, expert-level content)

          Please respond with ONLY a JSON object containing a "rating" number (0-1000).
          Example: {"rating": 650}
          """
        },
        %{
          role: "user",
          content: content
        }
      ],
      temperature: 0.1,
      max_tokens: 200
    }
  end

  defp parse_fallback_response(%{"choices" => [%{"message" => %{"content" => content}} | _]}) do
    Logger.info("Fallback content: #{inspect(content)}")

    case content do
      nil ->
        Logger.error("Received nil content from fallback API")
        {:error, :nil_content}

      "" ->
        Logger.error("Received empty content from fallback API")
        {:error, :empty_content}

      content when is_binary(content) ->
        # Try to extract JSON from the response
        content = String.trim(content)

        # Remove markdown code blocks if present
        cleaned_content =
          content
          |> String.replace(~r/```json\n?/, "")
          |> String.replace(~r/```\n?/, "")
          |> String.trim()

        case Jason.decode(cleaned_content) do
          {:ok, %{"rating" => rating} = _response}
          when is_integer(rating) and rating >= 0 and rating <= 1000 ->
            Logger.info("Fallback notebook rated: #{rating}/1000")
            {:ok, rating}

          {:ok, invalid_response} ->
            Logger.error(
              "Invalid fallback rating response structure: #{inspect(invalid_response)}"
            )

            {:error, :invalid_response}

          {:error, reason} ->
            Logger.error("Failed to parse fallback rating JSON: #{inspect(reason)}")
            Logger.error("Raw content was: #{inspect(cleaned_content)}")
            {:error, {:json_parse_error, reason}}
        end

      other ->
        Logger.error("Received non-string content from fallback: #{inspect(other)}")
        {:error, :invalid_content_type}
    end
  end

  defp parse_fallback_response(response) do
    Logger.error("Unexpected fallback response format: #{inspect(response)}")
    {:error, :unexpected_response_format}
  end

  defp get_api_key do
    Application.get_env(:notesclub, :openrouter_api_key)
  end
end
