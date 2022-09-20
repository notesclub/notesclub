defmodule RepoSyncWorkerTest do
  use Notesclub.DataCase

  import Mock

  alias Notesclub.Workers.RepoSyncWorker
  alias Notesclub.ReposFixtures
  alias Notesclub.Repos

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
        assert [] = all_enqueued()

        repo = ReposFixtures.repo_fixture()

        Oban.Testing.with_testing_mode(:manual, fn ->
          # Run worker:
          {:ok, _job} = perform_job(RepoSyncWorker, %{repo_id: repo.id})

          # It should have enqueued an Url Worker:
          assert_enqueued(worker: Notesclub.Workers.NotebooksUrlWorker, args: %{repo_id: repo.id})

          # It should have updated repo:
          repo = Repos.get_repo!(repo.id)
          assert repo.default_branch == "mybranch"
          assert repo.name == "repo1"
          assert repo.full_name == "user1/repo1"
          assert repo.fork == true
        end)
      end
    end
  end
end
