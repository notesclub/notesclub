defmodule Notesclub.Workers.NotebookPackagesWorker do
  @moduledoc """
  Worker to extract and save packages from notebook.content
  """
  alias Notesclub.NotebooksPackages

  use Oban.Worker,
    queue: :github_rest,
    unique: [period: 60, states: [:available, :scheduled, :executing]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"notebook_id" => notebook_id}}) do
    NotebooksPackages.link_from_notebook!(notebook_id)
  end
end
