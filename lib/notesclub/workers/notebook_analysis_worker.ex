defmodule Notesclub.Workers.NotebookAnalysisWorker do
  @moduledoc """
  Worker to analyse notebooks using AI-powered analysis functionality
  """
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Analyser
  alias Notesclub.Notebooks.Notebook

  use Oban.Worker,
    queue: :default,
    unique: [period: 300, states: [:available, :scheduled, :executing]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"notebook_id" => notebook_id}}) do
    case Notebooks.get_notebook(notebook_id) do
      nil ->
        {:cancel, "notebook does NOT exist"}

      %Notebook{content: nil} = notebook ->
        {:ok, _} = Notebooks.update_notebook(notebook, %{ai_rating: 0})
        {:cancel, "no content; skipping AI analysis"}

      %Notebook{content: ""} = notebook ->
        {:ok, _} = Notebooks.update_notebook(notebook, %{ai_rating: 0})
        {:cancel, "empty content; skipping AI analysis"}

      %Notebook{} = notebook ->
        case Analyser.analyse_notebook(notebook) do
          {:ok, _rating, _tags} -> :ok
          {:error, :no_content} -> {:cancel, "empty content; skipping AI rating"}
          {:error, error} -> {:error, error}
        end
    end
  end
end
