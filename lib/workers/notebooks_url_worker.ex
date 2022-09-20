defmodule Notesclub.Workers.NotebooksUrlWorker do
  @moduledoc """
  Regenerate all notebooks url within a repo
  """
  use Oban.Worker,
    queue: :default,
    unique: [period: 300, states: [:available, :scheduled, :executing]]


  alias Notesclub.Notebooks
  alias Notesclub.Repos

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"repo_id" => repo_id}}) do
    repo_id
    |> Repos.get_repo!()
    |> Notebooks.reset_notebooks_url()
  end
end
