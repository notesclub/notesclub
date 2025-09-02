defmodule Notesclub.Notebooks.Rater do
  @moduledoc """
  Context module for AI-powered notebook rating functionality.
  """

  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Notebooks.Rater.AiRater

  @doc """
  Rates a notebook based on how interesting it would be to Elixir developers via an AI-powered rating.
  Returns a rating from 0 (not interesting) to 1000 (max interest).

  ## Examples

      iex> rate_notebook_interest(%Notebook{content: "# Simple Elixir Tutorial\\n```elixir\\nIO.puts(\\"Hello\\")\\n```"})
      {:ok, 450}

      iex> rate_notebook_interest(%Notebook{content: "# Python Tutorial\\n```python\\nprint('hello')\\n```"})
      {:ok, 50}

  """
  @spec rate_notebook_interest(Notebook.t()) :: {:ok, integer()} | {:error, term()}
  def rate_notebook_interest(%Notebook{} = notebook) do
    with {:ok, rating, tags} <- implementation().rate_notebook_interest(notebook),
         {:ok, _notebook} <- Notesclub.Notebooks.update_notebook(notebook, %{ai_rating: rating}) do
          IO.inspect(tags, label: "-------------- tags --------------")
      {:ok, rating, tags}
    end
  end

  defp implementation do
    Application.get_env(:notesclub, :notebook_rater_implementation, AiRater)
  end
end
