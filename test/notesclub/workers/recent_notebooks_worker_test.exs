defmodule Notesclub.Workers.RecentNotebooksWorkerTest do
  use Notesclub.DataCase

  alias Notesclub.GithubAPI
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Workers.RecentNotebooksWorker

  import Mock

  # Invalid response as it only returns one item and per_page=5
  @invalid_response %Req.Response{
    status: 200,
    body: %{
      "items" => [
        %{
          "name" => "structs.livemd",
          "github_owner_login" => "charlieroth",
          "github_repo_name" => "elixir-notebooks",
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
        }
      ]
    }
  }

  @valid_response %Req.Response{
    status: 200,
    body: %{
      "items" => [
        %{
          "name" => "structs.livemd",
          "github_owner_login" => "charlieroth",
          "github_repo_name" => "elixir-notebooks",
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
          "name" => "collections1.livemd",
          "full_name" => "charlieroth/elixir-notebooks",
          "github_owner_login" => "charlieroth",
          "github_repo_name" => "elixir-notebooks",
          "html_url" =>
            "https://github.com/charlieroth/elixir-notebooks/blob/48c66fbaac086bd98ea5891d8e47b20c49097d83/collections.livemd",
          "private" => false,
          "repository" => %{
            "name" => "elixir-notebooks",
            "private" => false,
            "fork" => false,
            "owner" => %{
              "login" => "charlieroth",
              "avatar_url" => "https://avatars.githubusercontent.com/u/13981427?v=4"
            }
          }
        },
        %{
          "name" => "collections2.livemd",
          "full_name" => "charlieroth/elixir-notebooks",
          "github_owner_login" => "charlieroth",
          "github_repo_name" => "elixir-notebooks",
          "html_url" =>
            "https://github.com/charlieroth/elixir-notebooks/blob/48c66fbaac086bd98ea5891d8e47b20c49097d83/collections2.livemd",
          "private" => false,
          "repository" => %{
            "name" => "elixir-notebooks",
            "private" => false,
            "fork" => false,
            "owner" => %{
              "login" => "charlieroth",
              "avatar_url" => "https://avatars.githubusercontent.com/u/13981427?v=4"
            }
          }
        },
        %{
          "name" => "collections3.livemd",
          "full_name" => "charlieroth/elixir-notebooks",
          "github_owner_login" => "charlieroth",
          "github_repo_name" => "elixir-notebooks",
          "html_url" =>
            "https://github.com/charlieroth/elixir-notebooks/blob/48c66fbaac086bd98ea5891d8e47b20c49097d83/collections3.livemd",
          "private" => false,
          "repository" => %{
            "name" => "elixir-notebooks",
            "private" => false,
            "fork" => false,
            "owner" => %{
              "login" => "charlieroth",
              "avatar_url" => "https://avatars.githubusercontent.com/u/13981427?v=4"
            }
          }
        },
        %{
          "name" => "collections4.livemd",
          "full_name" => "charlieroth/elixir-notebooks",
          "github_owner_login" => "charlieroth",
          "github_repo_name" => "elixir-notebooks",
          "html_url" =>
            "https://github.com/charlieroth/elixir-notebooks/blob/48c66fbaac086bd98ea5891d8e47b20c49097d83/collections4.livemd",
          "private" => false,
          "repository" => %{
            "name" => "elixir-notebooks",
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

  test "downloads notebooks and enqueue next page" do
    with_mocks([
      {Req, [:passthrough], [get!: fn _url, _options -> @valid_response end]},
      {GithubAPI, [:passthrough], [check_github_api_key: fn -> false end]}
    ]) do
      assert {:ok, _} = perform_job(RecentNotebooksWorker, %{page: 1})

      url =
        "https://api.github.com/search/code?q=extension:livemd&per_page=5&page=1&sort=indexed&order=desc"

      assert called(Req.get!(url, :_))

      assert [
               %Notebook{github_filename: "structs.livemd"},
               %Notebook{github_filename: "collections1.livemd"},
               %Notebook{github_filename: "collections2.livemd"},
               %Notebook{github_filename: "collections3.livemd"},
               %Notebook{github_filename: "collections4.livemd"}
             ] = Notebooks.list_notebooks()

      assert_enqueued(worker: Notesclub.Workers.RecentNotebooksWorker, args: %{page: 2})
    end
  end

  test "retry if we get less elements than we asked" do
    with_mocks([
      {Req, [:passthrough], [get!: fn _url, _options -> @invalid_response end]},
      {GithubAPI, [:passthrough], [check_github_api_key: fn -> false end]}
    ]) do
      assert {:error, "Retry. \"Returned data did NOT match per_page.\""} =
               perform_job(RecentNotebooksWorker, %{page: 1})

      # It didn't create any notebooks:
      assert [] = Notebooks.list_notebooks()

      # It didn't enqueue the next page
      refute_enqueued(worker: Notesclub.Workers.RecentNotebooksWorker, args: %{page: 2})
    end
  end
end
defmodule Notesclub.Workers.RecentNotebooksWorkerTest do
  use Notesclub.DataCase

  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook
  alias Notesclub.Workers.RecentNotebooksWorker

  import Mock

  # Invalid response as it only returns one item and per_page=5
  @invalid_response %Req.Response{
    status: 200,
    body: %{
      "items" => [
        %{
          "name" => "structs.livemd",
          "github_owner_login" => "charlieroth",
          "github_repo_name" => "elixir-notebooks",
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
        }
      ]
    }
  }

  @valid_response %Req.Response{
    status: 200,
    body: %{
      "items" => [
        %{
          "name" => "structs.livemd",
          "github_owner_login" => "charlieroth",
          "github_repo_name" => "elixir-notebooks",
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
          "name" => "collections1.livemd",
          "full_name" => "charlieroth/elixir-notebooks",
          "github_owner_login" => "charlieroth",
          "github_repo_name" => "elixir-notebooks",
          "html_url" =>
            "https://github.com/charlieroth/elixir-notebooks/blob/48c66fbaac086bd98ea5891d8e47b20c49097d83/collections.livemd",
          "private" => false,
          "repository" => %{
            "name" => "elixir-notebooks",
            "private" => false,
            "fork" => false,
            "owner" => %{
              "login" => "charlieroth",
              "avatar_url" => "https://avatars.githubusercontent.com/u/13981427?v=4"
            }
          }
        },
        %{
          "name" => "collections2.livemd",
          "full_name" => "charlieroth/elixir-notebooks",
          "github_owner_login" => "charlieroth",
          "github_repo_name" => "elixir-notebooks",
          "html_url" =>
            "https://github.com/charlieroth/elixir-notebooks/blob/48c66fbaac086bd98ea5891d8e47b20c49097d83/collections2.livemd",
          "private" => false,
          "repository" => %{
            "name" => "elixir-notebooks",
            "private" => false,
            "fork" => false,
            "owner" => %{
              "login" => "charlieroth",
              "avatar_url" => "https://avatars.githubusercontent.com/u/13981427?v=4"
            }
          }
        },
        %{
          "name" => "collections3.livemd",
          "full_name" => "charlieroth/elixir-notebooks",
          "github_owner_login" => "charlieroth",
          "github_repo_name" => "elixir-notebooks",
          "html_url" =>
            "https://github.com/charlieroth/elixir-notebooks/blob/48c66fbaac086bd98ea5891d8e47b20c49097d83/collections3.livemd",
          "private" => false,
          "repository" => %{
            "name" => "elixir-notebooks",
            "private" => false,
            "fork" => false,
            "owner" => %{
              "login" => "charlieroth",
              "avatar_url" => "https://avatars.githubusercontent.com/u/13981427?v=4"
            }
          }
        },
        %{
          "name" => "collections4.livemd",
          "full_name" => "charlieroth/elixir-notebooks",
          "github_owner_login" => "charlieroth",
          "github_repo_name" => "elixir-notebooks",
          "html_url" =>
            "https://github.com/charlieroth/elixir-notebooks/blob/48c66fbaac086bd98ea5891d8e47b20c49097d83/collections4.livemd",
          "private" => false,
          "repository" => %{
            "name" => "elixir-notebooks",
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

  test "downloads notebooks and enqueue next page" do
    with_mocks([
      {Req, [:passthrough], [get!: fn _url, _options -> @valid_response end]}
    ]) do
      assert {:ok, _} = perform_job(RecentNotebooksWorker, %{page: 1})

      url =
        "https://api.github.com/search/code?q=extension:livemd&per_page=5&page=1&sort=indexed&order=desc"

      assert called(Req.get!(url, :_))

      assert [
               %Notebook{github_filename: "structs.livemd"},
               %Notebook{github_filename: "collections1.livemd"},
               %Notebook{github_filename: "collections2.livemd"},
               %Notebook{github_filename: "collections3.livemd"},
               %Notebook{github_filename: "collections4.livemd"}
             ] = Notebooks.list_notebooks(order: :asc)

      assert_enqueued(worker: Notesclub.Workers.RecentNotebooksWorker, args: %{page: 2})
    end
  end

  test "retry when GitHub's returned data != per_page" do
    with_mocks([
      {Req, [:passthrough], [get!: fn _url, _options -> @invalid_response end]}
    ]) do
      assert {:error, "Retry. Returned data did NOT match per_page."} =
               perform_job(RecentNotebooksWorker, %{page: 1})

      # It didn't create any notebooks:
      assert [] = Notebooks.list_notebooks()

      # It didn't enqueue the next page
      refute_enqueued(worker: Notesclub.Workers.RecentNotebooksWorker, args: %{page: 2})
    end
  end
end
