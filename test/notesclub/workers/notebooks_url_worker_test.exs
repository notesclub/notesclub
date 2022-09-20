defmodule NotebooksUrlWorkerTest do
  use Notesclub.DataCase

  alias Notesclub.Workers.NotebooksUrlWorker
  alias Notesclub.ReposFixtures
  alias Notesclub.NotebooksFixtures
  alias Notesclub.Notebooks

  describe "RepoDefaultBranchWorker" do
    test "perform/1 downloads default_branch, name, full_name, fork" do
      repo = ReposFixtures.repo_fixture()
      # Three notebooks within the repo
      notebook1 = NotebooksFixtures.notebook_fixture(%{repo_id: repo.id, github_html_url: "https://github.com/user/repo/blob/7f1d1ab2e6c8a3/whatever1.livemd"})
      notebook2 = NotebooksFixtures.notebook_fixture(%{repo_id: repo.id, github_html_url: "https://github.com/user/repo/blob/6f1d1ab2e6c8a3/whatever2.livemd"})
      notebook3 = NotebooksFixtures.notebook_fixture(%{repo_id: repo.id, github_html_url: "https://github.com/user/repo/blob/5f1d1ab2e6c8a3/whatever3.livemd"})

      # One notebook from a different repo
      notebook4 = NotebooksFixtures.notebook_fixture(%{url: "https://whatever.com", github_html_url: "https://github.com/user/repo/blob/4f1d1ab2e6c8a3/whatever4.livemd"})

      # Update urls from repo:
      {:ok, _job} = perform_job(NotebooksUrlWorker, %{repo_id: repo.id})

      # It should have changed the first three notebooks
      assert Notebooks.get_notebook!(notebook1.id).url == "https://github.com/user/repo/blob/#{repo.default_branch}/whatever1.livemd"
      assert Notebooks.get_notebook!(notebook2.id).url == "https://github.com/user/repo/blob/#{repo.default_branch}/whatever2.livemd"
      assert Notebooks.get_notebook!(notebook3.id).url == "https://github.com/user/repo/blob/#{repo.default_branch}/whatever3.livemd"

      # And should have NOT changed the last notebook url
      assert Notebooks.get_notebook!(notebook4.id).url == "https://whatever.com"
    end
  end
end
