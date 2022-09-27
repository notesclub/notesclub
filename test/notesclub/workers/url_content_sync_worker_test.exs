defmodule UrlContentSyncWorkerTest do
  use Notesclub.DataCase

  import Mock

  alias Notesclub.Workers.UrlContentSyncWorker
  alias Notesclub.AccountsFixtures
  alias Notesclub.ReposFixtures
  alias Notesclub.NotebooksFixtures
  alias Notesclub.Notebooks

  @valid_response %Req.Response{
    status: 200,
    body: """
    Classifying handwritten digits
    Mix.install([
      {:axon, github: \"elixir-nx/axon\"},
      ...
    """
  }

  @not_found_404_response %Req.Response{
    status: 404,
    body: ""
  }

  describe "UrlContentSyncWorker" do
    test "perform/1 downloads url content and updates notebook" do
      with_mocks([
        {Notesclub.Workers.UrlContentSyncWorker, [:passthrough],
         [requests_enabled?: fn -> true end]},
        {Req, [:passthrough],
         [
           get!:
             fn "https://raw.githubusercontent.com/elixir-nx/axon/main/notebooks/vision/mnist.livemd" ->
               @valid_response
             end
         ]}
      ]) do
        notebook =
          NotebooksFixtures.notebook_fixture(%{
            github_html_url:
              "https://github.com/elixir-nx/axon/blob/432e3ed23232424/notebooks/vision/mnist.livemd",
            user_id: AccountsFixtures.user_fixture(%{username: "elixir-nx"}).id,
            repo_id: ReposFixtures.repo_fixture(%{name: "axon", default_branch: "main"}).id
          })

        # Run worker:
        {:ok, _job} = perform_job(UrlContentSyncWorker, %{notebook_id: notebook.id})

        # It should have updated repo:
        notebook = Notebooks.get_notebook!(notebook.id)
        assert notebook.content == @valid_response.body

        assert notebook.url ==
                 "https://github.com/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd"
      end
    end

    test "perform/1 when url returns 404, fetch github_html_url and set url=nil" do
      with_mocks([
        {Notesclub.Workers.UrlContentSyncWorker, [:passthrough],
         [requests_enabled?: fn -> true end]},
        {Req, [:passthrough],
         [
           get!: fn url ->
             case url do
               "https://raw.githubusercontent.com/elixir-nx/axon/main/notebooks/vision/mnist.livemd" ->
                 @not_found_404_response

               "https://raw.githubusercontent.com/elixir-nx/axon/432e3ed23232424/notebooks/vision/mnist.livemd" ->
                 @valid_response
             end
           end
         ]}
      ]) do
        notebook =
          NotebooksFixtures.notebook_fixture(%{
            github_html_url:
              "https://github.com/elixir-nx/axon/blob/432e3ed23232424/notebooks/vision/mnist.livemd",
            user_id: AccountsFixtures.user_fixture(%{username: "elixir-nx"}).id,
            repo_id: ReposFixtures.repo_fixture(%{name: "axon", default_branch: "main"}).id
          })

        # Run worker:
        {:ok, _job} = perform_job(UrlContentSyncWorker, %{notebook_id: notebook.id})

        # It should have updated repo:
        notebook = Notebooks.get_notebook!(notebook.id)
        assert notebook.content == @valid_response.body
        assert notebook.url == nil
      end
    end

    test "raw_url/4 generates raw url from url" do
      url = "https://github.com/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd"

      raw_url =
        UrlContentSyncWorker.raw_url(%{
          url: url,
          username: "elixir-nx",
          repo_name: "axon"
        })

      assert raw_url ==
               "https://raw.githubusercontent.com/elixir-nx/axon/main/notebooks/vision/mnist.livemd"
    end
  end
end
