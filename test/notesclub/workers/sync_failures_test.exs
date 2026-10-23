defmodule Notesclub.Workers.SyncFailuresTest do
  use Notesclub.DataCase

  import Notesclub.HTTPStub
  import Notesclub.NotebooksFixtures
  import Notesclub.ReposFixtures
  import Plug.Conn

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Analyser.AiAnalyser
  alias Notesclub.Workers.NotebookAnalysisWorker
  alias Notesclub.Workers.RepoSyncWorker
  alias Notesclub.Workers.UrlContentSyncWorker

  @moduletag :capture_log
  setup :setup_http

  setup do
    repo = repo_fixture(%{default_branch: "main"})

    notebook =
      notebook_fixture(%{
        repo_id: repo.id,
        user_id: repo.user_id,
        github_html_url: "https://github.com/author/repo/blob/commit/book.livemd",
        content: "Original content",
        url: "https://github.com/author/repo/blob/main/book.livemd"
      })

    %{notebook: notebook, repo: repo}
  end

  test "removed notebooks and repos cancel or skip without requesting GitHub" do
    assert {:cancel, "notebook does NOT exist"} =
             perform_job(UrlContentSyncWorker, %{notebook_id: -1})

    assert {:ok, "repo doesn't exist. Skipping."} = perform_job(RepoSyncWorker, %{repo_id: -1})
  end

  test "missing default and commit URLs cancel without overwriting stored content", %{
    notebook: notebook
  } do
    Req.Test.stub(__MODULE__, &send_resp(&1, 404, "Not found"))
    assert {:cancel, message} = perform_job(UrlContentSyncWorker, %{notebook_id: notebook.id})
    assert message =~ "deleted or moved on Github"
    assert Notebooks.get_notebook!(notebook.id).content == "Original content"
  end

  test "temporary default-branch and commit failures remain retryable", %{notebook: notebook} do
    Req.Test.stub(__MODULE__, &Req.Test.transport_error(&1, :timeout))

    assert_raise RuntimeError, "request to notebook default branch url failed", fn ->
      perform_job(UrlContentSyncWorker, %{notebook_id: notebook.id})
    end

    Req.Test.stub(__MODULE__, fn conn ->
      if conn.request_path =~ "/main/",
        do: send_resp(conn, 404, "Not found"),
        else: Req.Test.transport_error(conn, :timeout)
    end)

    assert_raise RuntimeError, "request to notebook commit url failed", fn ->
      perform_job(UrlContentSyncWorker, %{notebook_id: notebook.id})
    end

    assert Notebooks.get_notebook!(notebook.id).content == "Original content"
  end

  test "repository errors are returned for job retries", %{repo: repo} do
    Req.Test.stub(__MODULE__, &Req.Test.json(put_status(&1, 403), %{message: "rate limited"}))
    assert {:error, %{status: 403}} = perform_job(RepoSyncWorker, %{repo_id: repo.id})
  end

  @tag app_env: [notebook_analyser_implementation: AiAnalyser, openrouter_api_key: "test-key"]
  test "analysis API failures do not overwrite existing ratings", %{notebook: notebook} do
    Req.Test.stub(__MODULE__, &Req.Test.json(put_status(&1, 503), %{error: "unavailable"}))

    assert {:error, {:api_error, 503, _}} =
             perform_job(NotebookAnalysisWorker, %{notebook_id: notebook.id})

    assert Notebooks.get_notebook!(notebook.id).ai_rating == nil
  end

  @tag app_env: [notebook_analyser_implementation: AiAnalyser, openrouter_api_key: "test-key"]
  test "invalid analysis output is cancelled without overwriting ratings", %{notebook: notebook} do
    Req.Test.stub(__MODULE__, fn conn ->
      Req.Test.json(
        conn,
        %{"choices" => [%{"message" => %{"content" => ~s({"rating":999,"tags":["bogus"]})}}]}
      )
    end)

    assert {:cancel, "invalid AI analysis response: invalid_response"} =
             perform_job(NotebookAnalysisWorker, %{notebook_id: notebook.id})

    assert Notebooks.get_notebook!(notebook.id).ai_rating == nil
  end
end
