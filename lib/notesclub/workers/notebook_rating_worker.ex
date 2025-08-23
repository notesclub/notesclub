defmodule Notesclub.Workers.NotebookRatingWorker do
  @moduledoc """
  Worker to rate notebooks using AI-powered rating functionality
  """
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Rater

  use Oban.Worker,
    queue: :default,
    unique: [period: 300, states: [:available, :scheduled, :executing]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"notebook_id" => notebook_id}}) do
    with notebook <- Notebooks.get_notebook!(notebook_id),
         {:ok, _rating} <- Rater.rate_notebook_interest(notebook) do
      :ok
    else
      {:error, error} -> {:error, error}
    end
  end
end
