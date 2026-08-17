defmodule Notesclub.Workers.UserNotebooksSyncWorker do
  @moduledoc """
  Downloads and creates or updates notebooks by the given username

  Notebooks that are no longer on GitHub get deleted. As that is a destructive
  and unrecoverable operation, we only delete when we are confident that the
  response reflects reality — see `delete_old_notebooks_if_safe/1` and
  `confirm_account_is_gone_and_delete/3`.
  """

  use Oban.Worker,
    queue: :github_search,
    priority: 3

  alias Notesclub.Accounts
  alias Notesclub.Accounts.User
  alias Notesclub.GithubAPI
  alias Notesclub.Notebooks
  alias Notesclub.Workers.UrlContentSyncWorker
  alias Notesclub.Workers.UserNotebooksSyncWorker

  # GitHub returns these messages when it can NOT search a user, which happens
  # both when the account no longer exists and when we can't see it — an
  # expired or downgraded token, a lapsed SSO authorization, etc.
  @account_not_searchable_messages [
    "The listed users and repositories cannot be searched either because the resources do not exist or you do not have permission to view them.",
    "The listed users, orgs, or repositories cannot be searched either because the resources do not exist or you do not have permission to view them."
  ]

  @impl Oban.Worker
  def perform(%Oban.Job{
        args:
          %{
            "username" => username,
            "page" => page,
            "per_page" => per_page,
            "already_saved_ids" => already_saved_ids
          } = args
      }) do
    options = [username: username, per_page: per_page, page: page, order: "desc"]
    github_owner_id = github_owner_id(args, username)

    case GithubAPI.get(options) do
      {:ok,
       %GithubAPI{
         notebooks_data: notebooks_data,
         total_count: total_count,
         incomplete_results: incomplete_results
       }} ->
        save_notebooks(%{
          notebooks_data: notebooks_data,
          total_count: total_count,
          incomplete_results: incomplete_results,
          username: username,
          github_owner_id: github_owner_id,
          already_saved_ids: already_saved_ids,
          page: page,
          per_page: per_page
        })

      {:error,
       %Notesclub.GithubAPI{
         response: %Req.Response{
           body: %{"errors" => [%{"code" => "invalid", "message" => message}]}
         }
       } = error} ->
        may_delete_notebooks(username, github_owner_id, message, error)

      error ->
        {:error, "Retrying. Unknown error: #{inspect(error)}"}
    end
  end

  #  The account's id is immutable; its username is not. We take the id from the
  #  job args and fall back to the user record when the job predates this arg.
  defp github_owner_id(%{"github_owner_id" => github_owner_id}, _username)
       when is_integer(github_owner_id),
       do: github_owner_id

  defp github_owner_id(_args, username) do
    case Accounts.get_by_username(username) do
      %User{github_id: github_id} -> github_id
      _ -> nil
    end
  end

  defp save_notebooks(attrs) do
    saved_ids = save_notebooks_and_enqueue_content_sync(attrs.notebooks_data)

    enqueue_next_and_delete_old_if_required(%{
      per_page: attrs.per_page,
      page: attrs.page,
      total_count: attrs.total_count,
      incomplete_results: attrs.incomplete_results,
      already_saved_ids: attrs.already_saved_ids ++ saved_ids,
      username: attrs.username,
      github_owner_id: attrs.github_owner_id
    })
  end

  #  The user could have changed the username or changed the permissions
  #  We match the message to make sure we don't delete notebooks that we shouldn't
  defp may_delete_notebooks(username, github_owner_id, message, error) do
    if message in @account_not_searchable_messages do
      confirm_account_is_gone_and_delete(username, github_owner_id, error)
    else
      {:error, "Retrying. Invalid code but unknown message: #{inspect(error)}"}
    end
  end

  #  The error above also shows up when *we* lost access to GitHub, which would
  #  affect every user at once. So we ask GitHub about the account before
  #  deleting anything and only delete when it's really gone (404).
  defp confirm_account_is_gone_and_delete(username, nil, _error) do
    {:ok, "We do NOT know the github_owner_id of #{username} — we do NOT delete any notebook"}
  end

  defp confirm_account_is_gone_and_delete(username, github_owner_id, error) do
    case GithubAPI.get_user_info(github_owner_id) do
      {:error, :not_found} ->
        delete_notebooks(username, github_owner_id)

      {:ok, _user_info} ->
        {:error,
         "Retrying. We can NOT search #{username} but the account #{github_owner_id} still exists: #{inspect(error)}"}

      _ ->
        {:error,
         "Retrying. We could NOT confirm whether the account #{github_owner_id} exists: #{inspect(error)}"}
    end
  end

  def delete_notebooks(username, github_owner_id) do
    {:ok, {n, _}} =
      Notebooks.delete_notebooks(%{github_owner_id: github_owner_id, except_ids: []})

    {:ok,
     "User #{username} (#{github_owner_id}) does NOT exist on GitHub anymore. #{n} notebooks deleted"}
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

  def enqueue_next_and_delete_old_if_required(
        %{
          per_page: per_page,
          page: page,
          total_count: total_count,
          already_saved_ids: already_saved_ids,
          username: username
        } = attrs
      ) do
    cond do
      per_page * (page + 1) > 2000 ->
        # We could actualy change to order :asc and get 2000 more — but not needed at the moment
        {:ok,
         "reached GitHub limit of 2000 — we can't download more for this user — we do NOT delete old notebooks"}

      total_count > per_page * page ->
        %{
          username: username,
          github_owner_id: attrs[:github_owner_id],
          page: page + 1,
          per_page: per_page,
          already_saved_ids: already_saved_ids
        }
        |> UserNotebooksSyncWorker.new(priority: 2)
        |> Oban.insert()

        {:ok, "done and enqueued another page"}

      true ->
        delete_old_notebooks_if_safe(attrs)
    end
  end

  #  GitHub's Search API regularly answers with zero or partial results while
  #  its index is degraded, and this worker runs for every user every night. So
  #  we only delete when the response looks complete AND we saved at least one
  #  notebook — otherwise a bad minute at GitHub would empty the whole database.
  defp delete_old_notebooks_if_safe(%{total_count: total_count})
       when not is_integer(total_count) or total_count <= 0 do
    {:ok, "GitHub returned NO result — we do NOT delete old notebooks"}
  end

  defp delete_old_notebooks_if_safe(%{incomplete_results: true}) do
    {:ok, "GitHub returned incomplete results — we do NOT delete old notebooks"}
  end

  defp delete_old_notebooks_if_safe(%{already_saved_ids: []}) do
    {:ok, "We saved NO notebook in this sync — we do NOT delete old notebooks"}
  end

  defp delete_old_notebooks_if_safe(%{already_saved_ids: already_saved_ids} = attrs) do
    case attrs[:github_owner_id] do
      nil ->
        {:ok,
         "We do NOT know the github_owner_id of #{attrs[:username]} — we do NOT delete old notebooks"}

      github_owner_id ->
        {:ok, {n, _}} =
          Notebooks.delete_notebooks(%{
            github_owner_id: github_owner_id,
            except_ids: already_saved_ids
          })

        {:ok, "done and NO more pages — #{n} old notebooks deleted"}
    end
  end
end
