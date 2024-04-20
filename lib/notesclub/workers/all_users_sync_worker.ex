defmodule Notesclub.Workers.AllUsersSyncWorker do
  @moduledoc """
    Sync all users
  """

  use Oban.Worker

  alias Notesclub.Accounts
  alias Notesclub.Workers.UserSyncWorker

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Accounts.list_users()
    |> Enum.map(&UserSyncWorker.new(%{user_id: &1.id}))
    |> Oban.insert_all()

    :ok
  end
end
