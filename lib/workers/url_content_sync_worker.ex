defmodule Notesclub.Workers.UrlContentSyncWorker do
  @moduledoc """
  1. Regenerates url from github_html_url
  2. Fetches its content
  3. Updates notebooks.content and notebooks.url
  """
  use Oban.Worker,
    queue: :default,
    unique: [period: 300, states: [:available, :scheduled, :executing]]

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Repos.Repo
  alias Notesclub.Accounts.User

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"notebook_id" => notebook_id}}) do
    notebook = Notebooks.get_notebook(notebook_id, preload: [:user, :repo])

    url =
      Notebooks.url_from_github_html_url(notebook.github_html_url, notebook.repo.default_branch)

    url
    |> raw_url(notebook.user, notebook.repo)
    |> make_request(notebook)
    |> make_request_and_save_content(notebook, url)
  end

  # Notebook doesn't exists, skipping
  @spec raw_url(
          nil | binary,
          %User{},
          %Repo{}
        ) :: nil | binary
  def raw_url(nil, _, _), do: nil

  def raw_url(url, %User{} = user, %Repo{} = repo) do
    raw_url(%{
      url: url,
      username: user.username,
      repo_name: repo.name
    })
  end

  def raw_url(%{url: url, username: username, repo_name: repo_name}) do
    url
    |> String.replace(
      ~r/^https:\/\/github\.com\/#{username}\/#{repo_name}\/blob/,
      "https://raw.githubusercontent.com/#{username}/#{repo_name}"
    )
  end

  defp make_request(_url, nil), do: nil

  defp make_request(url, _notebook) do
    case __MODULE__.requests_enabled?() do
      true ->
        Req.get!(url)

      _ ->
        %Req.Response{
          status: 200,
          body: "whatever txt"
        }
    end
  end

  # Notebook doesn't exists, skipping
  defp make_request_and_save_content(_, nil, _), do: :ok

  defp make_request_and_save_content(
         %Req.Response{status: 200} = response,
         %Notebook{} = notebook,
         url
       ) do
    Notebooks.update_notebook(notebook, %{content: response.body, url: url})
  end

  # The file exists in github_html_url but not in the default branch
  #  Make another request to github_html_url instead of url
  # And save content
  defp make_request_and_save_content(%Req.Response{status: 404}, %Notebook{} = notebook, _url) do
    raw_github_html_url =
      raw_url(%{
        url: notebook.github_html_url,
        username: notebook.user.username,
        repo_name: notebook.repo.name
      })

    case make_request(raw_github_html_url, notebook) do
      %Req.Response{status: 200} = response ->
        Notebooks.update_notebook(notebook, %{content: response.body, url: nil})

      _ ->
        Notebooks.update_notebook(notebook, %{content: nil, url: nil})
    end
  end

  # Public function so it can be mocked
  def requests_enabled?() do
    case Application.get_env(:notesclub, :env) do
      :test -> false
      _ -> true
    end
  end
end
