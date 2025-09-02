defmodule Notesclub.Workers.UserNotebooksSyncWorkerTest do
  use Notesclub.DataCase

  import Mock
  import Notesclub.AccountsFixtures
  import Notesclub.NotebooksFixtures
  import Notesclub.ReposFixtures

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Workers.UserNotebooksSyncWorker

  @github_response %Req.Response{
    status: 200,
    body: %{
      "items" => [
        %{
          "name" => "structs.livemd",
          "html_url" =>
            "https://github.com/charlieroth/elixir-notebooks/blob/68716ab303da9b98e21be9c04a3c86770ab7c819/structs.livemd",
          "repository" => %{
            "name" => "elixir-notebooks",
            "full_name" => "charlieroth/elixir-notebooks",
            "private" => false,
            "fork" => false,
            "owner" => %{
              "avatar_url" => "https://avatars.githubusercontent.com/u/13981427?v=4",
              "login" => "charlieroth"
            }
          }
        },
        %{
          "name" => "collections.livemd",
          "html_url" =>
            "https://github.com/charlieroth/elixir-notebooks/blob/48c66fbaac086bd98ea5891d8e47b20c49097d83/collections.livemd",
          "private" => false,
          "repository" => %{
            "name" => "elixir-notebooks",
            "full_name" => "charlieroth/elixir-notebooks",
            "private" => false,
            "fork" => false,
            "owner" => %{
              "login" => "charlieroth",
              "avatar_url" => "https://avatars.githubusercontent.com/u/13981427?v=4"
            }
          }
        }
      ],
      "total_count" => 2446
    }
  }

  @github_invalid_response %Req.Response{
    status: 422,
    body: %{
      "errors" => [
        %{
          "code" => "invalid",
          "message" =>
            "The listed users and repositories cannot be searched either because the resources do not exist or you do not have permission to view them."
        }
      ]
    }
  }

  describe "perform/1" do
    test "saves notebooks and enqueues another page" do
      username = "elixir-nx"
      per_page = 2
      page = 1
      order = "desc"

      url =
        "https://api.github.com/search/code?q=user:#{username}+extension:livemd&per_page=#{per_page}&page=#{page}&sort=indexed&order=#{order}"

      with_mocks([
        {Req, [:passthrough], [get!: fn _url, _ -> @github_response end]}
      ]) do
        # Run job
        assert {:ok, _} =
                 perform_job(UserNotebooksSyncWorker, %{
                   username: username,
                   page: page,
                   per_page: per_page,
                   already_saved_ids: []
                 })

        assert called(Req.get!(url, :_))

        assert [
                 "collections.livemd",
                 "structs.livemd"
               ] = Notebooks.list_notebooks() |> Enum.map(& &1.github_filename) |> Enum.sort()

        n1 = Notebooks.get_by(github_filename: "structs.livemd")
        n2 = Notebooks.get_by(github_filename: "collections.livemd")

        # enqueue next page and url sync

        n2_id = n2.id
        n1_id = n1.id
        next_page = page + 1

        assert [
                 %Oban.Job{
                   worker: "Notesclub.Workers.UserNotebooksSyncWorker",
                   args: %{
                     "page" => ^next_page,
                     "per_page" => ^per_page,
                     "username" => ^username,
                     "already_saved_ids" => [^n1_id, ^n2_id]
                   }
                 },
                 %Oban.Job{
                   worker: "Notesclub.Workers.UrlContentSyncWorker",
                   args: %{"notebook_id" => ^n2_id}
                 },
                 %Oban.Job{
                   worker: "Notesclub.Workers.UrlContentSyncWorker",
                   args: %{"notebook_id" => ^n1_id}
                 }
               ] = all_enqueued()
      end
    end

    # The user could have changed their username or changed their permissions
    test "deletes all user notebooks because the user is invalid" do
      user1 = user_fixture(%{username: "one"})
      user2 = user_fixture(%{username: "two"})
      repo1 = repo_fixture(%{user_id: user1.id})
      repo2 = repo_fixture(%{user_id: user2.id})
      notebook_fixture(%{user: user1, repo: repo1, github_owner_login: user1.username})
      notebook_fixture(%{user: user1, repo: repo1, github_owner_login: user1.username})
      n3 = notebook_fixture(%{user: user2, repo: repo2, github_owner_login: user2.username})

      assert Notebooks.count() == 3

      with_mocks([
        {Req, [:passthrough], [get!: fn _url, _ -> @github_invalid_response end]}
      ]) do
        assert {:ok, _} =
                 perform_job(UserNotebooksSyncWorker, %{
                   username: user1.username,
                   page: 1,
                   per_page: 10,
                   already_saved_ids: []
                 })

        assert Notebooks.count() == 1

        # We did not delete the notebooks from other users
        assert Notebooks.get_notebook(n3.id).id == n3.id
      end
    end

    test "saves notebooks and does NOT enqueue because we reached GitHub's 2000" do
      username = "elixir-nx"
      per_page = 100
      page = 20
      order = "desc"

      url =
        "https://api.github.com/search/code?q=user:#{username}+extension:livemd&per_page=#{per_page}&page=#{page}&sort=indexed&order=#{order}"

      with_mocks([
        {Req, [:passthrough], [get!: fn _url, _ -> @github_response end]}
      ]) do
        # Run job
        assert {:ok, _} =
                 perform_job(UserNotebooksSyncWorker, %{
                   username: username,
                   page: page,
                   per_page: per_page,
                   already_saved_ids: []
                 })

        assert called(Req.get!(url, :_))

        assert [
                 %Notebook{github_filename: "structs.livemd"} = n1,
                 %Notebook{github_filename: "collections.livemd"} = n2
               ] = Notebooks.list_notebooks()

        refute_enqueued(
          worker: UserNotebooksSyncWorker,
          args: %{
            page: page + 1,
            per_page: per_page,
            username: username,
            already_saved_ids: [n1.id, n2.id]
          }
        )

        n2_id = n2.id
        n1_id = n1.id

        assert [
                 %Oban.Job{
                   worker: "Notesclub.Workers.UrlContentSyncWorker",
                   args: %{"notebook_id" => ^n2_id}
                 },
                 %Oban.Job{
                   worker: "Notesclub.Workers.UrlContentSyncWorker",
                   args: %{"notebook_id" => ^n1_id}
                 }
               ] = all_enqueued()
      end
    end
  end
end
