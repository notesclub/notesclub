defmodule Notesclub.Notebooks.UrlsTest do
  use Notesclub.DataCase

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Urls
  alias Notesclub.NotebooksFixtures
  alias Notesclub.AccountsFixtures
  alias Notesclub.ReposFixtures
  alias Notesclub.Repos

  setup do
    user = AccountsFixtures.user_fixture(%{username: "elixir-nx"})
    repo = ReposFixtures.repo_fixture(%{name: "axon", default_branch: "main"})

    notebook =
      NotebooksFixtures.notebook_fixture(%{
        github_html_url:
          "https://github.com/elixir-nx/axon/blob/7f1d1ab2e6c8a35edf3f58eae9182c4a149cd8d5/notebooks/vision/mnist.livemd",
        repo_id: repo.id,
        user_id: user.id
      })

    notebook = Notebooks.get_notebook!(notebook.id, preload: [:user, :repo])

    %{notebook: notebook}
  end

  describe "Notebooks.Urls" do
    test "get_urls/1 generates urls", %{notebook: notebook} do
      {:ok, urls} = Urls.get_urls(notebook)

      assert urls.commit_url ==
               "https://github.com/elixir-nx/axon/blob/7f1d1ab2e6c8a35edf3f58eae9182c4a149cd8d5/notebooks/vision/mnist.livemd"

      assert urls.default_branch_url ==
               "https://github.com/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd"

      assert urls.raw_commit_url ==
               "https://raw.githubusercontent.com/elixir-nx/axon/7f1d1ab2e6c8a35edf3f58eae9182c4a149cd8d5/notebooks/vision/mnist.livemd"

      assert urls.raw_default_branch_url ==
               "https://raw.githubusercontent.com/elixir-nx/axon/main/notebooks/vision/mnist.livemd"
    end
  end

  test "get_urls/1 complains when NO notebook" do
    assert Urls.get_urls(nil) == {:error, "notebook can't be nil"}
  end

  test "get_urls/1 complains when NO notebook.user", %{notebook: notebook} do
    notebook = Map.put(notebook, :user, nil)
    assert Urls.get_urls(notebook) == {:error, "notebook must include user and repo preloaded."}
  end

  test "get_urls/1 complains when NO notebook.repo.default_branch", %{notebook: notebook} do
    # Complains when repo is nil
    notebook2 = Map.put(notebook, :repo, nil)
    assert Urls.get_urls(notebook2) == {:error, "notebook must include user and repo preloaded."}

    # Complains when repo.default_branch is nil
    {:ok, _repo} = Repos.update_repo(notebook.repo, %{default_branch: nil})
    notebook3 = Notebooks.get_notebook!(notebook.id, preload: [:user, :repo])
    assert Urls.get_urls(notebook3) == {:error, "repo.default_branch can't be nil"}
  end
end
