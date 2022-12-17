defmodule Notesclub.Workers.UserNotebooksSyncWorker do
  use Oban.Worker,
    queue: :github_search,
    priority: 3

  alias Notesclub.GithubAPI
  alias Notesclub.Notebooks

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "username" => username,
          "page" => page,
          "per_page" => per_page,
          "already_saved_ids" => already_saved_ids
        }
      }) do
    options = [username: username, per_page: per_page, page: page, order: "desc"]

    {:ok, %GithubAPI{notebooks_data: notebooks_data, total_count: total_count}} =
      GithubAPI.get(options)

    saved_ids =
      Enum.map(notebooks_data, fn notebook_data ->
        {:ok, notebook} = Notebooks.save_notebook(notebook_data)
        notebook.id
      end)

    already_saved_ids = already_saved_ids ++ saved_ids

    cond do
      per_page * (page + 1) > 2000 ->
        # We could actualy change to order :asc and get 2000 more — but not needed at the moment
        {:ok,
         "reached GitHub limit of 2000 — we can't download more for this user — we do NOT delete old notebooks"}

      total_count > per_page * page ->
        %{
          username: username,
          page: page + 1,
          per_page: per_page,
          already_saved_ids: already_saved_ids
        }
        |> Notesclub.Workers.UserNotebooksSyncWorker.new(priority: 2)
        |> Oban.insert()

        {:ok, "done and enqueued another page"}

      true ->
        {n, nil} =
          Notebooks.delete_notebooks(%{username: username, except_ids: already_saved_ids})

        {:ok, "done and NO more pages — #{n} old notebooks deleted"}
    end
  end
end
