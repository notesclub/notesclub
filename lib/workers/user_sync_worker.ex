defmodule Notesclub.Workers.UserSyncWorker do
  @moduledoc """
  Worker to fetch user info and include it during user creation
  """
  require Logger

  alias Notesclub.{Accounts, GithubAPI}

  use Oban.Worker,
    queue: :github_rest,
    unique: [period: 300, states: [:available, :scheduled, :executing]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do

    with user = %{username: username} <- Accounts.get_user!(user_id),
         {:ok, user_info} <- GithubAPI.get_user_info(username) do
        Accounts.update_user(user, user_info)
        :ok
    else
      {:error, error} -> {:error, error}

    end
  end
end
