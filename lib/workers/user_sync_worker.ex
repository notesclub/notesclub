defmodule Notesclub.Workers.UserSyncWorker do
  @moduledoc """
  Worker to fetch user info and include it during use creation
  """
  require Logger

  alias Notesclub.Accounts

  use Oban.Worker,
    queue: :github_rest,
    unique: [period: 300, states: [:available, :scheduled, :executing]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do

    user = Accounts.get_user!(user_id)
    IO.inspect(user)

    :ok
  end
end
