defmodule Notesclub.Workers.UserNotebooksSyncWorkerTest do
  use Notesclub.DataCase

  import Mock

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Workers.UserNotebooksSyncWorker
  alias Notesclub.GithubAPI

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

  describe "perform/1" do
    test "saves notebooks and enqueues another page" do
      username = "elixir-nx"
      per_page = 2
      page = 1
      order = "desc"

      url =
        "https://api.github.com/search/code?q=user:#{username}+extension:livemd&per_page=#{per_page}&page=#{page}&sort=indexed&order=#{order}"

      with_mocks([
        {GithubAPI, [:passthrough], [check_github_api_key: fn -> false end]},
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

        assert_enqueued(
          worker: UserNotebooksSyncWorker,
          args: %{
            page: page + 1,
            per_page: per_page,
            username: username,
            already_saved_ids: [n1.id, n2.id]
          }
        )
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
        {GithubAPI, [:passthrough], [check_github_api_key: fn -> false end]},
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
      end
    end
  end
end
