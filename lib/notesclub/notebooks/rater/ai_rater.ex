defmodule Notesclub.Notebooks.Rater.AiRater do
  @moduledoc """
  OpenRouter API client for AI-powered notebook analysis.
  """

  require Logger
  alias Notesclub.Notebooks.Notebook

  @openrouter_base_url "https://openrouter.ai/api/v1"
  @model "openai/gpt-4o-mini"
  @max_content_chars 150_000

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
    truncated_content = truncate_content(content, @max_content_chars)

    # Prepare a comprehensive view of the notebook for analysis
    analysis_content = """
    NOTEBOOK ANALYSIS REQUEST

    Title: #{title || "Untitled"}
    Filename: #{filename || "unknown.livemd"}

    Content:
    #{truncated_content}
    """

    {:ok, analysis_content}
  end

  defp truncate_content(content, max_length) when byte_size(content) <= max_length do
    content
  end

  defp truncate_content(content, max_length) do
    content
    |> String.slice(0, max_length)
    |> Kernel.<>("...")
  end

  defp make_rating_request(content) do
    api_key = get_api_key()

    if api_key == nil, do: raise("no api key")

    case Req.post(
           "#{@openrouter_base_url}/chat/completions",
           json: build_request_body(content),
           headers: [
             {"Authorization", "Bearer #{api_key}"},
             {"Content-Type", "application/json"},
             {"HTTP-Referer", "https://notesclub.app"},
             {"X-Title", "NotesClub Notebook Rating"}
           ]
         ) do
      {:ok, %{status: 200, body: body}} ->
        Logger.info("Fallback request response: #{inspect(body)}")
        parse_response(body)

      {:ok, %{status: status, body: body}} ->
        Logger.error("OpenRouter fallback API error: #{status} - #{inspect(body)}")
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        Logger.error("OpenRouter fallback request failed: #{inspect(reason)}")
        {:error, {:request_failed, reason}}
    end
  end

  defp build_request_body(content) do
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
      max_tokens: 200,
      response_format: %{
        type: "json_schema",
        json_schema: %{
          name: "notebook_rating",
          strict: true,
          schema: %{
            type: "object",
            properties: %{
              rating: %{
                type: "integer",
                minimum: 0,
                maximum: 1000,
                description: "Interest rating from 0-1000 for Elixir developers"
              }
            },
            required: ["rating"],
            additionalProperties: false
          }
        }
      }
    }
  end

  defp parse_response(%{"choices" => [%{"message" => %{"content" => nil}} | _]}) do
    {:error, :nil_content}
  end

  defp parse_response(%{"choices" => [%{"message" => %{"content" => ""}} | _]}) do
    {:error, :empty_content}
  end

  defp parse_response(%{"choices" => [%{"message" => %{"content" => content}} | _]})
       when is_binary(content) do
    case Jason.decode(content) do
      {:ok, %{"rating" => rating} = _response}
      when is_integer(rating) and rating >= 0 and rating <= 1000 ->
        Logger.debug("Notebook rated: #{rating}/1000")
        {:ok, rating}

      {:ok, invalid_response} ->
        Logger.error("Invalid rating response structure: #{inspect(invalid_response)}")
        {:error, :invalid_response}

      {:error, reason} ->
        Logger.error("Failed to parse rating JSON: #{inspect(reason)}")
        Logger.error("Raw content was: #{inspect(content)}")
        {:error, {:json_parse_error, reason}}
    end
  end

  defp get_api_key do
    Application.get_env(:notesclub, :openrouter_api_key)
  end
end
