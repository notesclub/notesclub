defmodule Notesclub.Notebooks.Rater do
  @moduledoc """
  Context module for AI-powered notebook rating functionality.
  """

  alias Notesclub.Notebooks.Rater.AiRater
  alias Notesclub.Notebooks.Notebook

  @doc """
  Rates a notebook based on how interesting it would be to Elixir developers.
  Returns a rating from 0 (not interesting) to 1000 (max interest).

  The rating considers factors like:
  - Presence and quality of Elixir code cells
  - Length and depth of content
  - Use of Elixir packages/libraries
  - Educational value for Elixir developers
  - Code complexity and examples

  The AI also assigns relevant tags to categorize the content, such as:
  - "ai" for AI/ML content
  - "advent-of-code", "advent-of-code-2024" for Advent of Code solutions
  - "phoenix", "liveview" for web development
  - "otp", "genserver" for OTP patterns
  - "beginner", "intermediate", "advanced" for difficulty levels

  ## Examples

      iex> rate_notebook_interest(%Notebook{content: "# Simple Elixir Tutorial\\n```elixir\\nIO.puts(\\"Hello\\")\\n```"})
      {:ok, 450}

      iex> rate_notebook_interest(%Notebook{content: "# Python Tutorial\\n```python\\nprint('hello')\\n```"})
      {:ok, 50}

  """
  @spec rate_notebook_interest(Notebook.t()) :: {:ok, integer()} | {:error, term()}
  def rate_notebook_interest(%Notebook{} = notebook) do
    implementation().rate_notebook_interest(notebook)
  end

  defp implementation do
    Application.get_env(:notesclub, :notebook_rater_implementation, AiRater)
  end
end
