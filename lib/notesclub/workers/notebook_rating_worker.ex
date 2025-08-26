defmodule Notesclub.Workers.NotebookRatingWorker do
  @moduledoc """
  Worker to rate notebooks using AI-powered rating functionality
  """
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Rater
  alias Notesclub.Notebooks.Notebook

  use Oban.Worker,
    queue: :default,
    unique: [period: 300, states: [:available, :scheduled, :executing]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"notebook_id" => notebook_id}}) do
    case Notebooks.get_notebook(notebook_id) do
      nil ->
        {:cancel, "notebook does NOT exist"}

      %Notebook{ai_rating: ai_rating} when not is_nil(ai_rating) ->
        :ok

      %Notebook{content: nil} ->
        Notebooks.update_notebook(notebook, %{ai_rating: 0})
        {:cancel, "no content; skipping AI rating"}

      %Notebook{content: ""} ->
        Notebooks.update_notebook(notebook, %{ai_rating: 0})
        {:cancel, "empty content; skipping AI rating"}

      %Notebook{} = notebook ->
        case Rater.rate_notebook_interest(notebook) do
          {:ok, _rating} -> :ok
          {:error, :no_content} -> {:cancel, "empty content; skipping AI rating"}
          {:error, error} -> {:error, error}
        end
    end
  end
end
