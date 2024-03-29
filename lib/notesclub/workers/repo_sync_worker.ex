defmodule Notesclub.Workers.RepoSyncWorker do
  @moduledoc """
    We fetch extra repo attributes not provided by Github Search API in fetch.ex
    Afterwards, we update the url of all notebooks of this repo
  """

  require Logger

  use Oban.Worker,
    queue: :github_rest,
    unique: [period: 300, states: [:available, :scheduled, :executing]]

  alias Notesclub.{Accounts.User, Notebooks, Repos, Repos.Repo}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"repo_id" => repo_id}}) do
    with %Repo{} = repo <- Repos.get_repo(repo_id, preload: [:user]),
         %Req.Response{status: 200} = response <- fetch_repo(repo, repo.user),
         attrs <- prepare_attrs(response),
         {:ok, repo} <- Repos.update_repo(repo, attrs),
         {:ok, _} <- Notebooks.enqueue_url_and_content_sync(repo) do
      :ok
    else
      nil -> {:ok, "repo doesn't exist. Skipping."}
      error -> {:error, error}
    end
  end

  defp fetch_repo(%Repo{name: repo_name}, %User{username: username}) do
    github_api_key = Application.get_env(:notesclub, :github_api_key)

    Req.get!("https://api.github.com/repos/#{username}/#{repo_name}",
      headers: [
        Accept: ["application/vnd.github+json"],
        Authorization: ["token #{github_api_key}"]
      ]
    )
  end

  defp prepare_attrs(%Req.Response{status: 200} = response) do
    body = response.body

    %{
      default_branch: body["default_branch"],
      fork: body["fork"],
      name: body["name"],
      full_name: body["full_name"]
    }
  end
end
