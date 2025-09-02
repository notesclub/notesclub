defmodule Notesclub.Notebooks.Analyser.FakeAnalyser do
  @moduledoc """
  Fake notebook analyser implementation for testing.
  """

  alias Notesclub.Notebooks.Notebook

  @spec analyse_notebook(Notebook.t()) :: {:ok, integer(), list(String.t())} | {:error, term()}
  def analyse_notebook(%Notebook{content: nil}) do
    {:error, :no_content}
  end

  def analyse_notebook(%Notebook{content: ""}) do
    {:error, :no_content}
  end

  def analyse_notebook(_notebook) do
    {:ok, :rand.uniform(999) + 1, ["gen-server", "ai"]}
  end
end
