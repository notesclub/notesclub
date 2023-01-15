defmodule Notesclub.Workers.RepoSyncWorker do
  @moduledoc """
    We fetch extra repo attributes not provided by Github Search API in fetch.ex
    Afterwards, we update the url of all notebooks of this repo
  """

  require Logger

  use Oban.Worker,
    queue: :github_rest,
    unique: [period: 300, states: [:available, :scheduled, :executing]]

  alias Notesclub.Notebooks
  alias Notesclub.Repos

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"repo_id" => repo_id}}) do
    case Repos.get_repo(repo_id, preload: :user) do
      nil ->
        {:ok, "repo doesn't exist anymore. Skipping"}

      repo ->
        "#{repo.user.username}/#{repo.name}"
        |> fetch_repo()
        |> prepare_attrs()
        |> update_repo(repo)
    end
  end

  defp fetch_repo(full_name) do
    github_api_key = Application.get_env(:notesclub, :github_api_key)

    Req.get!("https://api.github.com/repos/" <> full_name,
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

  defp prepare_attrs(%Req.Response{status: status} = response) do
    {:error, "response status: #{status}, msg: #{response.body["message"]}"}
  end

  defp update_repo({:error, error}), do: {:error, error}
  defp update_repo(%{default_branch: nil}, _), do: {:error, "default_branch is empty"}
  defp update_repo(%{default_branch: ""}, _), do: {:error, "default_branch is empty"}
  defp update_repo(%{fork: nil}, _), do: {:error, "fork is nil"}
  defp update_repo(%{fork: ""}, _), do: {:error, "fork is empty"}
  defp update_repo(%{name: nil}, _), do: {:error, "name is nil"}
  defp update_repo(%{name: ""}, _), do: {:error, "name is empty"}
  defp update_repo(%{full_name: nil}, _), do: {:error, "full_name is nil"}
  defp update_repo(%{full_name: ""}, _), do: {:error, "full_name is empty"}

  defp update_repo(attrs, repo) do
    case Repos.update_repo(repo, attrs) do
      {:ok, repo} ->
        Notebooks.enqueue_url_and_content_sync(repo)

      {:error, error} ->
        {:error, error}
    end
  end
end
