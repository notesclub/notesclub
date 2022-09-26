defmodule ContentSyncWorkerTest do
  use Notesclub.DataCase

  import Mock

  alias Notesclub.Workers.ContentSyncWorker
  alias Notesclub.AccountsFixtures
  alias Notesclub.ReposFixtures
  alias Notesclub.NotebooksFixtures
  alias Notesclub.Notebooks

  @github_repo_response %Req.Response{
    status: 200,
    body: """
    Classifying handwritten digits
    Mix.install([
      {:axon, github: \"elixir-nx/axon\"},
      ...
    """
  }

  describe "ContentSyncWorker" do
    test "perform/1 downloads url content and updates notebook" do
      with_mocks([
        {Notesclub.Workers.ContentSyncWorker, [:passthrough], [requests_enabled?: fn -> true end]},
        {Req, [:passthrough], [get!: fn _ -> @github_repo_response end]}
      ]) do
        user = AccountsFixtures.user_fixture(%{username: "elixir-nx"})
        repo = ReposFixtures.repo_fixture(%{name: "axon"})

        notebook =
          NotebooksFixtures.notebook_fixture(%{
            url: "https://github.com/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd",
            user: user.id,
            repo: repo.id
          })

        # Run worker:
        {:ok, _job} = perform_job(ContentSyncWorker, %{notebook_id: notebook.id})

        # It should have updated repo:
        notebook = Notebooks.get_notebook!(notebook.id)
        assert notebook.content == @github_repo_response.body
      end
    end

    test "raw_url/4 generates raw url from url" do
      url = "https://github.com/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd"

      raw_url =
        ContentSyncWorker.raw_url(%{
          url: url,
          username: "elixir-nx",
          repo_name: "axon"
        })

      assert raw_url ==
               "https://raw.githubusercontent.com/elixir-nx/axon/main/notebooks/vision/mnist.livemd"
    end
  end
end
