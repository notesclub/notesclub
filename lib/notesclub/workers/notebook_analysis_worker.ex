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
    notebook_id
    |> Notebooks.get_notebook()
    |> analyse()
  end

  defp analyse(nil), do: {:cancel, "notebook does NOT exist"}

  defp analyse(%Notebook{content: nil} = notebook) do
    {:ok, _} = Notebooks.update_notebook(notebook, %{ai_rating: 0})
    {:cancel, "no content; skipping AI analysis"}
  end

  defp analyse(%Notebook{content: ""} = notebook) do
    {:ok, _} = Notebooks.update_notebook(notebook, %{ai_rating: 0})
    {:cancel, "empty content; skipping AI analysis"}
  end

  defp analyse(%Notebook{} = notebook) do
    notebook
    |> Analyser.analyse_notebook()
    |> handle_analysis_result()
  end

  defp handle_analysis_result({:ok, _rating, _tags}), do: :ok

  defp handle_analysis_result({:error, :no_content}) do
    {:cancel, "empty content; skipping AI rating"}
  end

  defp handle_analysis_result({:error, error})
       when error in [:nil_content, :empty_content, :invalid_response] do
    {:cancel, "invalid AI analysis response: #{error}"}
  end

  defp handle_analysis_result({:error, {:json_parse_error, _reason}}) do
    {:cancel, "invalid JSON in AI analysis response"}
  end

  defp handle_analysis_result({:error, error}), do: {:error, error}
end
