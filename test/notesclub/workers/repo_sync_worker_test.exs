defmodule RepoSyncWorkerTest do
  use Notesclub.DataCase

  import Mock

  alias Notesclub.Workers.RepoSyncWorker
  alias Notesclub.ReposFixtures
  alias Notesclub.NotebooksFixtures
  alias Notesclub.Repos
  alias Notesclub.Notebooks

  @github_repo_response %Req.Response{
    status: 200,
    body: %{
      "default_branch" => "mybranch",
      "fork" => true,
      "name" => "repo1",
      "full_name" => "user1/repo1"
    }
  }

  describe "RepoSyncWorker" do
    test "perform/1 downloads default_branch, name, full_name, fork" do
      with_mocks([
        {Req, [:passthrough], [get!: fn _url, _options -> @github_repo_response end]}
      ]) do
        repo = ReposFixtures.repo_fixture()

        # Run worker:
        {:ok, _job} = perform_job(RepoSyncWorker, %{repo_id: repo.id})

        # It should have updated repo:
        repo = Repos.get_repo!(repo.id)
        assert repo.default_branch == "mybranch"
        assert repo.name == "repo1"
        assert repo.full_name == "user1/repo1"
        assert repo.fork == true
      end
    end

    test "perform/1 enqueue_url_and_content_sync" do
      with_mocks([
        {Req, [:passthrough], [get!: fn _url, _options -> @github_repo_response end]}
      ]) do
        repo = ReposFixtures.repo_fixture(%{default_branch: "mybranch"})
        # Three notebooks within the repo
        notebook1 =
          NotebooksFixtures.notebook_fixture(%{
            repo_id: repo.id,
            github_html_url: "https://github.com/user/repo/blob/7f1d1ab2e6c8a3/whatever1.livemd"
          })

        notebook2 =
          NotebooksFixtures.notebook_fixture(%{
            repo_id: repo.id,
            github_html_url: "https://github.com/user/repo/blob/6f1d1ab2e6c8a3/whatever2.livemd"
          })

        notebook3 =
          NotebooksFixtures.notebook_fixture(%{
            repo_id: repo.id,
            github_html_url: "https://github.com/user/repo/blob/5f1d1ab2e6c8a3/whatever3.livemd"
          })

        # One notebook from a different repo
        notebook4 =
          NotebooksFixtures.notebook_fixture(%{
            url: "https://whatever.com",
            github_html_url: "https://github.com/user/repo/blob/4f1d1ab2e6c8a3/whatever4.livemd"
          })

        # Sync & update urls from repo:
        {:ok, _job} = perform_job(RepoSyncWorker, %{repo_id: repo.id})

        # It should have changed the first three notebooks
        assert Notebooks.get_notebook!(notebook1.id).url ==
                 "https://github.com/user/repo/blob/#{repo.default_branch}/whatever1.livemd"

        assert Notebooks.get_notebook!(notebook2.id).url ==
                 "https://github.com/user/repo/blob/#{repo.default_branch}/whatever2.livemd"

        assert Notebooks.get_notebook!(notebook3.id).url ==
                 "https://github.com/user/repo/blob/#{repo.default_branch}/whatever3.livemd"

        # And should have NOT changed the last notebook url
        assert Notebooks.get_notebook!(notebook4.id).url == "https://whatever.com"
      end
    end
  end
end
