defmodule Notesclub.Notebooks.Analyser do
  @moduledoc """
  Context module for AI-powered notebook analysis functionality.
  """

  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Notebooks.Analyser.AiAnalyser

  @doc """
  Analyses a notebook based on how interesting it would be to Elixir developers via AI-powered analysis.
  Returns a rating from 0 (not interesting) to 1000 (max interest) and a list of relevant tags.

  ## Examples

      iex> analyse_notebook(%Notebook{content: "# Simple Elixir Tutorial\\n```elixir\\nIO.puts(\\"Hello\\")\\n```"})
      {:ok, 450, ["tutorial", "beginner"]}

      iex> analyse_notebook(%Notebook{content: "# Python Tutorial\\n```python\\nprint('hello')\\n```"})
      {:ok, 50, ["python"]}

  """
  @spec analyse_notebook(Notebook.t()) :: {:ok, integer(), list(String.t())} | {:error, term()}
  def analyse_notebook(%Notebook{} = notebook) do
    with {:ok, rating, tags} <- implementation().analyse_notebook(notebook),
         {:ok, _notebook} <- Notesclub.Notebooks.update_notebook(notebook, %{ai_rating: rating}) do
          IO.inspect(tags, label: "-------------- tags --------------")
      {:ok, rating, tags}
    end
  end

  defp implementation do
    Application.get_env(:notesclub, :notebook_analyser_implementation, AiAnalyser)
  end
end
