defmodule Notesclub.Notebooks.Rater.FakeRater do
  @moduledoc """
  Fake notebook rater implementation for testing.
  """

  alias Notesclub.Notebooks.Notebook

  @spec rate_notebook_interest(Notebook.t()) :: {:ok, integer(), list(string())} | {:error, term()}
  def rate_notebook_interest(%Notebook{content: nil}) do
    {:error, :no_content}
  end

  def rate_notebook_interest(%Notebook{content: ""}) do
    {:error, :no_content}
  end

  def rate_notebook_interest(_notebook) do
    {:ok, :rand.uniform(999) + 1, ["gen-server", "ai"]}
  end
end
