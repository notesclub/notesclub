defmodule Notesclub.Workers.UserNotebooksSyncWorkerTest do
  use Notesclub.DataCase

  import Mock
  import Notesclub.AccountsFixtures
  import Notesclub.NotebooksFixtures
  import Notesclub.ReposFixtures

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Workers.UserNotebooksSyncWorker

  @github_owner_id 13_981_427

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
              "login" => "charlieroth",
              "id" => @github_owner_id
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
              "avatar_url" => "https://avatars.githubusercontent.com/u/13981427?v=4",
              "id" => @github_owner_id
            }
          }
        }
      ],
      "total_count" => 2446
    }
  }

  # Same notebooks, but GitHub says there are no more pages
  @last_page_github_response %Req.Response{
    @github_response
    | body: %{@github_response.body | "total_count" => 2}
  }

  @empty_github_response %Req.Response{
    status: 200,
    body: %{"items" => [], "total_count" => 0, "incomplete_results" => false}
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

  @github_user_not_found_response %Req.Response{
    status: 404,
    body: %{"message" => "Not Found"}
  }

  @github_user_response %Req.Response{
    status: 200,
    body: %{"id" => 1, "login" => "one", "name" => "One", "twitter_username" => nil}
  }

  # The search and the user endpoints answer differently within the same test
  defp mock_req(search_response, user_response) do
    {Req, [:passthrough],
     [
       get!: fn url, _options ->
         if String.contains?(url, "api.github.com/user"),
           do: user_response,
           else: search_response
       end
     ]}
  end

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

        # we store the owner's immutable id so we can delete safely later
        assert n1.github_owner_id == @github_owner_id

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

    test "deletes the notebooks that are no longer on GitHub" do
      user = user_fixture(%{username: "charlieroth", github_id: @github_owner_id})
      repo = repo_fixture(%{user_id: user.id})

      old =
        notebook_fixture(%{
          user: user,
          repo: repo,
          github_owner_login: user.username,
          github_owner_id: @github_owner_id
        })

      with_mocks([
        {Req, [:passthrough], [get!: fn _url, _ -> @last_page_github_response end]}
      ]) do
        assert {:ok, "done and NO more pages — 1 old notebooks deleted"} =
                 perform_job(UserNotebooksSyncWorker, %{
                   username: user.username,
                   github_owner_id: @github_owner_id,
                   page: 1,
                   per_page: 100,
                   already_saved_ids: []
                 })

        refute Notebooks.get_notebook(old.id)
        assert Notebooks.count() == 2
      end
    end

    test "does NOT delete notebooks when GitHub returns no result" do
      user = user_fixture(%{username: "charlieroth", github_id: @github_owner_id})
      repo = repo_fixture(%{user_id: user.id})

      notebook_fixture(%{
        user: user,
        repo: repo,
        github_owner_login: user.username,
        github_owner_id: @github_owner_id
      })

      with_mocks([
        {Req, [:passthrough], [get!: fn _url, _ -> @empty_github_response end]}
      ]) do
        assert {:ok, "GitHub returned NO result — we do NOT delete old notebooks"} =
                 perform_job(UserNotebooksSyncWorker, %{
                   username: user.username,
                   github_owner_id: @github_owner_id,
                   page: 1,
                   per_page: 100,
                   already_saved_ids: []
                 })

        assert Notebooks.count() == 1
      end
    end

    test "does NOT delete notebooks when GitHub returns incomplete results" do
      user = user_fixture(%{username: "charlieroth", github_id: @github_owner_id})
      repo = repo_fixture(%{user_id: user.id})

      notebook_fixture(%{
        user: user,
        repo: repo,
        github_owner_login: user.username,
        github_owner_id: @github_owner_id
      })

      incomplete_response = %Req.Response{
        @last_page_github_response
        | body: Map.put(@last_page_github_response.body, "incomplete_results", true)
      }

      with_mocks([
        {Req, [:passthrough], [get!: fn _url, _ -> incomplete_response end]}
      ]) do
        assert {:ok, "GitHub returned incomplete results — we do NOT delete old notebooks"} =
                 perform_job(UserNotebooksSyncWorker, %{
                   username: user.username,
                   github_owner_id: @github_owner_id,
                   page: 1,
                   per_page: 100,
                   already_saved_ids: []
                 })

        assert Notebooks.count() == 3
      end
    end

    test "does NOT delete notebooks when every item is discarded as private" do
      user = user_fixture(%{username: "charlieroth", github_id: @github_owner_id})
      repo = repo_fixture(%{user_id: user.id})

      notebook_fixture(%{
        user: user,
        repo: repo,
        github_owner_login: user.username,
        github_owner_id: @github_owner_id
      })

      # e.g. GitHub stops returning `private`
      items =
        Enum.map(@last_page_github_response.body["items"], fn item ->
          update_in(item, ["repository"], &Map.delete(&1, "private"))
        end)

      response = %Req.Response{
        @last_page_github_response
        | body: %{@last_page_github_response.body | "items" => items}
      }

      with_mocks([
        {Req, [:passthrough], [get!: fn _url, _ -> response end]}
      ]) do
        assert {:error, _} =
                 perform_job(UserNotebooksSyncWorker, %{
                   username: user.username,
                   github_owner_id: @github_owner_id,
                   page: 1,
                   per_page: 100,
                   already_saved_ids: []
                 })

        assert Notebooks.count() == 1
      end
    end

    # The user could have changed their username or changed their permissions
    test "deletes all user notebooks because the account no longer exists" do
      user1 = user_fixture(%{username: "one", github_id: 1})
      user2 = user_fixture(%{username: "two", github_id: 2})
      repo1 = repo_fixture(%{user_id: user1.id})
      repo2 = repo_fixture(%{user_id: user2.id})

      notebook_fixture(%{
        user: user1,
        repo: repo1,
        github_owner_login: user1.username,
        github_owner_id: user1.github_id
      })

      notebook_fixture(%{
        user: user1,
        repo: repo1,
        github_owner_login: user1.username,
        github_owner_id: user1.github_id
      })

      n3 =
        notebook_fixture(%{
          user: user2,
          repo: repo2,
          github_owner_login: user2.username,
          github_owner_id: user2.github_id
        })

      assert Notebooks.count() == 3

      with_mocks([mock_req(@github_invalid_response, @github_user_not_found_response)]) do
        assert {:ok, _} =
                 perform_job(UserNotebooksSyncWorker, %{
                   username: user1.username,
                   github_owner_id: user1.github_id,
                   page: 1,
                   per_page: 10,
                   already_saved_ids: []
                 })

        assert Notebooks.count() == 1

        # We did not delete the notebooks from other users
        assert Notebooks.get_notebook(n3.id).id == n3.id
      end
    end

    # A revoked token —or an org we lost access to— returns the same error for
    # every user, so we confirm with GitHub before deleting anything
    test "does NOT delete notebooks when the account still exists" do
      user = user_fixture(%{username: "one", github_id: 1})
      repo = repo_fixture(%{user_id: user.id})

      notebook_fixture(%{
        user: user,
        repo: repo,
        github_owner_login: user.username,
        github_owner_id: user.github_id
      })

      with_mocks([mock_req(@github_invalid_response, @github_user_response)]) do
        assert {:error, message} =
                 perform_job(UserNotebooksSyncWorker, %{
                   username: user.username,
                   github_owner_id: user.github_id,
                   page: 1,
                   per_page: 10,
                   already_saved_ids: []
                 })

        assert message =~ "still exists"
        assert Notebooks.count() == 1
      end
    end

    test "does NOT delete notebooks when we don't know the account id" do
      user = user_fixture(%{username: "one", github_id: nil})
      repo = repo_fixture(%{user_id: user.id})

      notebook_fixture(%{
        user: user,
        repo: repo,
        github_owner_login: user.username,
        github_owner_id: nil
      })

      with_mocks([mock_req(@github_invalid_response, @github_user_not_found_response)]) do
        assert {:ok, message} =
                 perform_job(UserNotebooksSyncWorker, %{
                   username: user.username,
                   page: 1,
                   per_page: 10,
                   already_saved_ids: []
                 })

        assert message =~ "do NOT delete"
        assert Notebooks.count() == 1
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
