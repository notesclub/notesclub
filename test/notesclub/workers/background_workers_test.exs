defmodule Notesclub.Workers.BackgroundWorkersTest do
  use Notesclub.DataCase

  import Notesclub.AccountsFixtures
  import Notesclub.NotebooksFixtures

  alias Notesclub.Accounts
  alias Notesclub.Notebooks
  alias Notesclub.Workers.AllUserNotebooksSyncWorker
  alias Notesclub.Workers.AllUsersSyncWorker
  alias Notesclub.Workers.NotebookAnalysisWorker
  alias Notesclub.Workers.NotebookPackagesWorker
  alias Notesclub.Workers.RegenerateSitemapsWorker
  alias Notesclub.Workers.UserNotebooksSyncWorker
  alias Notesclub.Workers.UserSyncWorker

  test "bulk sync jobs enqueue every user's profile and notebooks" do
    users = [user_fixture(), user_fixture()]
    existing_jobs = length(all_enqueued(worker: UserSyncWorker))
    assert :ok = perform_job(AllUsersSyncWorker, %{})
    assert :ok = perform_job(AllUserNotebooksSyncWorker, %{})

    for user <- users do
      assert_enqueued(worker: UserSyncWorker, args: %{user_id: user.id})

      assert_enqueued(
        worker: UserNotebooksSyncWorker,
        args: %{
          username: user.username,
          github_owner_id: user.github_id,
          page: 1,
          per_page: 100,
          already_saved_ids: []
        }
      )
    end

    assert length(all_enqueued(worker: UserSyncWorker)) ==
             existing_jobs + length(Accounts.list_users())
  end

  test "analysis jobs cancel missing and empty notebooks and persist ratings and tags" do
    assert {:cancel, "notebook does NOT exist"} =
             perform_job(NotebookAnalysisWorker, %{notebook_id: -1})

    for {content, message} <- [{nil, "no content"}, {"", "empty content"}] do
      notebook = notebook_fixture(%{content: content})

      Repo.update_all(from(n in Notebooks.Notebook, where: n.id == ^notebook.id),
        set: [content: content]
      )

      assert {:cancel, reason} = perform_job(NotebookAnalysisWorker, %{notebook_id: notebook.id})
      assert reason == "#{message}; skipping AI analysis"
      assert Notebooks.get_notebook!(notebook.id).ai_rating == 0
    end

    notebook = notebook_fixture()
    assert :ok = perform_job(NotebookAnalysisWorker, %{notebook_id: notebook.id})
    analysed = Notebooks.get_notebook!(notebook.id, preload: :tags)
    assert analysed.ai_rating in 1..1000
    assert Enum.sort(Enum.map(analysed.tags, & &1.name)) == ["ai", "gen-server"]
  end

  test "package extraction jobs replace associations using the notebook content" do
    notebook =
      notebook_fixture(%{content: "Mix.install([{:req, \"~> 0.7\"}, {:jason, \"~> 1.4\"}])"})

    assert :ok = perform_job(NotebookPackagesWorker, %{notebook_id: notebook.id})
    packages = Notebooks.get_notebook!(notebook.id, preload: :packages).packages
    assert Enum.sort(Enum.map(packages, & &1.name)) == ["jason", "req"]
  end

  test "sitemap regeneration completes for a populated catalog" do
    notebook_fixture()
    assert :ok = perform_job(RegenerateSitemapsWorker, %{})
  end
end
