defmodule Notesclub.Workers.UserNotebooksSyncWorker do
  @moduledoc """
  Downloads and creates or updates notebooks by the given username
  """

  use Oban.Worker,
    queue: :github_search,
    priority: 3

  alias Notesclub.GithubAPI
  alias Notesclub.Notebooks
  alias Notesclub.Workers.UrlContentSyncWorker
  alias Notesclub.Workers.UserNotebooksSyncWorker

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

    case GithubAPI.get(options) do
      {:ok, %GithubAPI{notebooks_data: notebooks_data, total_count: total_count}} ->
        save_notebooks(notebooks_data, total_count, username, already_saved_ids, page, per_page)

      {:error,
       %Notesclub.GithubAPI{
         response: %Req.Response{
           body: %{"errors" => [%{"code" => "invalid", "message" => message}]}
         }
       } = error} ->
        may_delete_notebooks(username, message, error)

      error ->
        {:error, "Retrying. Unknown error: #{inspect(error)}"}
    end
  end

  defp save_notebooks(notebooks_data, total_count, username, already_saved_ids, page, per_page) do
    saved_ids = save_notebooks_and_enqueue_content_sync(notebooks_data)
    already_saved_ids = already_saved_ids ++ saved_ids

    enqueue_next_and_delete_old_if_required(%{
      per_page: per_page,
      page: page,
      total_count: total_count,
      already_saved_ids: already_saved_ids,
      username: username
    })
  end

  # The user could have changed the username or changed the permissions
  #  We match the message to make sure we don't delete notebooks that we shouldn't
  defp may_delete_notebooks(username, message, error) do
    case message do
      "The listed users and repositories cannot be searched either because the resources do not exist or you do not have permission to view them." ->
        delete_notebooks(username)

      "The listed users, orgs, or repositories cannot be searched either because the resources do not exist or you do not have permission to view them." ->
        delete_notebooks(username)

      _ ->
        {:error, "Retrying. Invalid code but unknown message: #{inspect(error)}"}
    end
  end

  def delete_notebooks(username) do
    {:ok, {n, _}} = Notebooks.delete_notebooks(%{username: username, except_ids: []})
    {:ok, "User does NOT exist or we do not have permissions. #{n} notebooks deleted"}
  end

  defp save_notebooks_and_enqueue_content_sync(notebooks_data) do
    notebooks_data
    |> Enum.map(fn notebook_data ->
      case Notebooks.save_notebook(notebook_data) do
        {:ok, notebook} ->
          %{notebook_id: notebook.id}
          |> UrlContentSyncWorker.new()
          |> Oban.insert()

          notebook.id

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  def enqueue_next_and_delete_old_if_required(%{
        per_page: per_page,
        page: page,
        total_count: total_count,
        already_saved_ids: already_saved_ids,
        username: username
      }) do
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
        |> UserNotebooksSyncWorker.new(priority: 2)
        |> Oban.insert()

        {:ok, "done and enqueued another page"}

      true ->
        {:ok, {n, _}} =
          Notebooks.delete_notebooks(%{username: username, except_ids: already_saved_ids})

        {:ok, "done and NO more pages — #{n} old notebooks deleted"}
    end
  end
end
