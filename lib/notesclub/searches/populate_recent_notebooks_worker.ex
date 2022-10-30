defmodule Notesclub.Workers.PopulateRecentNotebooksWorker do
  @moduledoc """
    Fetch and create or update recent notebooks from Github
  """

  use Oban.Worker, queue: :github_search

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    result = Notesclub.Searches.Populate.next()
    {:ok, result}
  end
end
