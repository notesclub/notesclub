defmodule UrlContentSyncWorkerTest do
  use Notesclub.DataCase

  import Mock

  alias Notesclub.AccountsFixtures
  alias Notesclub.Notebooks
  alias Notesclub.NotebooksFixtures
  alias Notesclub.ReposFixtures
  alias Notesclub.Workers.UrlContentSyncWorker

  @valid_response %Req.Response{
    status: 200,
    body: """
    # Classifying handwritten digits

    Mix.install([
      {:axon, github: \"elixir-nx/axon\"},
      ...
    """
  }

  @not_found_404_response %Req.Response{
    status: 404,
    body: ""
  }

  setup do
    user = AccountsFixtures.user_fixture(%{username: "elixir-nx"})
    repo = ReposFixtures.repo_fixture(%{name: "axon", default_branch: "main", user_id: user.id})

    notebook =
      NotebooksFixtures.notebook_fixture(%{
        github_html_url:
          "https://github.com/elixir-nx/axon/blob/432e3ed23232424/notebooks/vision/mnist.livemd",
        user_id: user.id,
        repo_id: repo.id,
        content: "My Elixir notebook",
        url: "https://github.com/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd"
      })

    %{notebook: notebook, user: user, repo: repo}
  end

  describe "UrlContentSyncWorker" do
    test "perform/1 downloads url content and updates notebook", %{notebook: notebook} do
      with_mocks([
        {Req, [:passthrough],
         [
           get:
             fn "https://raw.githubusercontent.com/elixir-nx/axon/main/notebooks/vision/mnist.livemd" ->
               {:ok, @valid_response}
             end
         ]}
      ]) do
        # Run job
        {:ok, :synced} = perform_job(UrlContentSyncWorker, %{notebook_id: notebook.id})

        # It should have updated content and url
        notebook = Notebooks.get_notebook!(notebook.id)
        assert notebook.content == @valid_response.body
        assert notebook.title == "Classifying handwritten digits"

        assert notebook.url ==
                 "https://github.com/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd"
      end
    end

    test "perform/1 cancels when user is nil", %{notebook: notebook} do
      {:ok, notebook} = Notebooks.update_notebook(notebook, %{user_id: nil})

      # Run job
      assert perform_job(UrlContentSyncWorker, %{notebook_id: notebook.id}) ==
               {:cancel, "user is nil"}

      # content and url should have NOT changed:
      notebook = Notebooks.get_notebook!(notebook.id)
      assert notebook.content == "My Elixir notebook"

      assert notebook.url ==
               "https://github.com/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd"
    end

    test "perform/1 cancels when repo is nil", %{notebook: notebook} do
      {:ok, notebook} = Notebooks.update_notebook(notebook, %{repo_id: nil})

      assert perform_job(UrlContentSyncWorker, %{notebook_id: notebook.id}) ==
               {:cancel, "repo is nil"}

      # content and url should have NOT changed:
      notebook = Notebooks.get_notebook!(notebook.id)
      assert notebook.content == "My Elixir notebook"

      assert notebook.url ==
               "https://github.com/elixir-nx/axon/blob/main/notebooks/vision/mnist.livemd"
    end

    test "performs/1 enqueues RepoSyncWorker when repo default branch is nil" do
      repo = ReposFixtures.repo_fixture(%{default_branch: nil})

      notebook =
        NotebooksFixtures.notebook_fixture(%{
          user_id: repo.user_id,
          repo_id: repo.id
        })

      {:cancel, "No default branch. Enqueueing RepoSyncWorker."} =
        perform_job(UrlContentSyncWorker, %{notebook_id: notebook.id})

      assert_enqueued(worker: Notesclub.Workers.RepoSyncWorker, args: %{repo_id: repo.id})
    end

    test "perform/1 when request to default_branch_url returns 404, request github_html_url and set url=nil",
         %{notebook: notebook} do
      with_mocks([
        {Req, [:passthrough],
         [
           get: fn url ->
             case url do
               "https://raw.githubusercontent.com/elixir-nx/axon/main/notebooks/vision/mnist.livemd" ->
                 {:ok, @not_found_404_response}

               "https://raw.githubusercontent.com/elixir-nx/axon/432e3ed23232424/notebooks/vision/mnist.livemd" ->
                 {:ok, @valid_response}
             end
           end
         ]}
      ]) do
        {:ok, notebook} = Notebooks.update_notebook(notebook, %{url: nil})

        # Run job
        {:ok, :synced} = perform_job(UrlContentSyncWorker, %{notebook_id: notebook.id})

        # It should have updated content
        notebook = Notebooks.get_notebook!(notebook.id)
        assert notebook.content == @valid_response.body

        # But url should be nil
        assert notebook.url == nil
      end
    end
  end
end
