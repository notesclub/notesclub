defmodule Notesclub.Workers.UserSyncWorker do
  @moduledoc """
  Worker to fetch user info and include it during use creation
  """
  require Logger

  alias Notesclub.{Accounts, GithubAPI}

  use Oban.Worker,
    queue: :github_rest,
    unique: [period: 300, states: [:available, :scheduled, :executing]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do

    user = Accounts.get_user!(user_id)

    response = user
    |> Map.get(:username)
    |> GithubAPI.get_user_info()

    case response do
      {:ok, user_info} -> Accounts.update_user(user, user_info)
      {:error, error} -> {:error, error}
    end

  end
end
