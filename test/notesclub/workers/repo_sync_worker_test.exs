defmodule RepoSyncWorkerTest do
  use Notesclub.DataCase

  import Mock

  alias Notesclub.{NotebooksFixtures, Repos, ReposFixtures}
  alias Notesclub.Workers.{RepoSyncWorker, UrlContentSyncWorker}

  @github_repo_response %Req.Response{
    status: 200,
    body: %{
      "default_branch" => "mybranch",
      "fork" => true,
      "name" => "repo1",
      "full_name" => "user1/repo1"
    }
  }

  @github_content_response %Req.Response{status: 200, body: "whatever content"}

  describe "RepoSyncWorker" do
    test "perform/1 downloads default_branch, name, full_name, fork" do
      with_mocks([
        {Req, [:passthrough], [get!: fn _url, _options -> @github_repo_response end]}
      ]) do
        repo = ReposFixtures.repo_fixture()

        # Run worker:
        :ok = perform_job(RepoSyncWorker, %{repo_id: repo.id})

        # It should have updated repo:
        repo = Repos.get_repo!(repo.id)
        assert repo.default_branch == "mybranch"
        assert repo.name == "repo1"
        assert repo.full_name == "user1/repo1"
        assert repo.fork == true
      end
    end

    test "perform/1 downloads data using user.username/repo.name instead of repo.full_name" do
      with_mocks([
        {Req, [:passthrough], [get!: fn _url, _options -> @github_repo_response end]}
      ]) do
        repo = ReposFixtures.repo_fixture(%{full_name: "wrong"})

        # Run worker:
        :ok = perform_job(RepoSyncWorker, %{repo_id: repo.id})

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
        # Req from RepoSyncWorker
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
        :ok = perform_job(RepoSyncWorker, %{repo_id: repo.id})

        # It should have changed the first three notebooks
        assert_enqueued(worker: UrlContentSyncWorker, args: %{notebook_id: notebook1.id})
        assert_enqueued(worker: UrlContentSyncWorker, args: %{notebook_id: notebook2.id})
        assert_enqueued(worker: UrlContentSyncWorker, args: %{notebook_id: notebook3.id})

        # And should have NOT changed the last notebook url
        refute_enqueued(worker: UrlContentSyncWorker, args: %{notebook_id: notebook4.id})
      end
    end
  end
end
