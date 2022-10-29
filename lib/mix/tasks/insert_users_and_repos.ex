defmodule Mix.Tasks.InsertUsersAndRepos do
  @moduledoc """
    Insert users and repos from notebooks.
    One time task used just after the creation of the users and repos table.
  """

  use Mix.Task

  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto,
    # If using Ecto 3.0 or higher
    :ecto_sql
  ]

  @repos Application.get_env(:notesclub, :ecto_repos, [])

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Accounts
  alias Notesclub.Repos

  @shortdoc "Insert users and repos from notebooks and set user_id and repo_id"
  def run(_) do
    start_services()

    Notebooks.list_notebooks()
    |> Enum.map(fn notebook ->
      notebook
      |> find_or_create_user()
      |> find_or_create_repo()
      |> set_notebook_user_id_and_repo_id()
    end)

    stop_services()
  end

  defp find_or_create_user(%Notebook{} = notebook) do
    case Accounts.get_by_username(notebook.github_owner_login) do
      nil ->
        {:ok, user} =
          Accounts.create_user(%{
            username: notebook.github_owner_login,
            avatar_url: notebook.github_owner_avatar_url
          })

        %{notebook: notebook, user: user}

      user ->
        %{notebook: notebook, user: user}
    end
  end

  defp find_or_create_repo(%{notebook: notebook, user: user}) do
    case Repos.get_by(%{name: notebook.github_repo_name, user_id: user.id}) do
      nil ->
        {:ok, repo} = Repos.create_repo(%{name: notebook.github_repo_name, user_id: user.id})
        %{notebook: notebook, user: user, repo: repo}

      repo ->
        %{notebook: notebook, user: user, repo: repo}
    end
  end

  defp set_notebook_user_id_and_repo_id(%{notebook: notebook, user: user, repo: repo}) do
    {:ok, _} = Notebooks.update_notebook(notebook, %{user_id: user.id, repo_id: repo.id})
  end

  defp start_services do
    IO.puts("Starting dependencies..")
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for app
    IO.puts("Starting repos..")

    # pool_size can be 1 for ecto < 3.0
    Enum.each(@repos, & &1.start_link(pool_size: 2))
  end

  defp stop_services do
    IO.puts("Success!")
    :init.stop()
  end
end
