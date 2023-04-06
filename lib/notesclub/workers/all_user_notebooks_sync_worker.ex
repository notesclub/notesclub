defmodule Notesclub.Workers.AllUserNotebooksSyncWorker do
  @moduledoc """
    Sync all user notebooks
  """

  use Oban.Worker

  alias Notesclub.Accounts
  alias Notesclub.Workers.UserNotebooksSyncWorker

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Accounts.list_users()
    |> Enum.each(fn user ->
      %{username: user.username, page: 1, per_page: 100, already_saved_ids: []}
      |> UserNotebooksSyncWorker.new()
      |> Oban.insert()
    end)

    :ok
  end
end
