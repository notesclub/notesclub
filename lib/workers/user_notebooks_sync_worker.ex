defmodule Notesclub.Workers.UserNotebooksSyncWorker do
  use Oban.Worker,
    queue: :github_search,
    priority: 3

  alias Notesclub.GithubAPI
  alias Notesclub.Notebooks

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"username" => username, "page" => page, "per_page" => per_page}}) do
    options = [username: username, per_page: per_page, page: page, order: "desc"]

    {:ok, %GithubAPI{notebooks_data: notebooks_data, total_count: total_count}} =
      GithubAPI.get(options)

    Enum.map(notebooks_data, fn notebook_data ->
      {:ok, _} = Notebooks.save_notebook(notebook_data)
    end)

    if total_count > per_page * page do
      %{username: username, page: page + 1, per_page: per_page}
      |> Notesclub.Workers.UserNotebooksSyncWorker.new(priority: 2)
      |> Oban.insert()

      {:ok, "done and enqueued another page"}
    else
      {:ok, "done and NO more pages"}
    end
  end
end
