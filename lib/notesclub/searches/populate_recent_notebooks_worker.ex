defmodule Notesclub.Workers.PopulateRecentNotebooksWorker do
  @moduledoc """
    Fetch and create or update recent notebooks from Github
  """

  use Oban.Worker, queue: :github_search, priority: 2

  alias Notesclub.Searches.Populate

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    result = Populate.next()
    {:ok, result}
  end
end
