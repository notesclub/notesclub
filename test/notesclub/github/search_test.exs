defmodule Notesclub.Github.SearchTest do
  use Notesclub.DataCase

  alias Notesclub.Github.Search
  alias Notesclub.Notebooks.Notebook

  import Mock

  @valid_reponse %Req.Response{
    status: 200,
    body: %{
      "items" => [
        %{
          "name" => "structs.livemd",
          "html_url" => "https://github.com/charlieroth/elixir-notebooks/blob/68716ab303da9b98e21be9c04a3c86770ab7c819/structs.livemd",
          "repository" => %{
            "name" => "elixir-notebooks",
            "private" => false,
            "fork" => false,
            "owner" => %{
              "avatar_url" => "https://avatars.githubusercontent.com/u/13981427?v=4",
              "login" => "charlieroth",
            },
          },
        },
        %{
          "name" => "collections.livemd",
          "html_url" => "https://github.com/charlieroth/elixir-notebooks/blob/48c66fbaac086bd98ea5891d8e47b20c49097d83/collections.livemd",
          "private" => false,
          "repository" => %{
            "name" => "elixir-notebooks",
            "private" => false,
            "fork" => false,
            "owner" => %{
              "login" => "charlieroth",
              "avatar_url" => "https://avatars.githubusercontent.com/u/13981427?v=4",
            },
          },
        }
      ],
      "total_count" => 2446
    }
  }

  describe "Github.Search" do
    test "get/3 returns notebooks" do
      with_mocks([
        { Req, [:passthrough], [get!: fn(_url, _headers) -> @valid_reponse end]}
      ]) do
        assert Search.get([per_page: 2, page: 1, order: :asc]) == [
          %Notebook{
            github_filename: "structs.livemd",
            github_html_url: "https://github.com/charlieroth/elixir-notebooks/blob/68716ab303da9b98e21be9c04a3c86770ab7c819/structs.livemd",
            github_owner_avatar_url: "https://avatars.githubusercontent.com/u/13981427?v=4",
            github_owner_login: "charlieroth",
            github_repo_name: "elixir-notebooks",
            id: nil,
            inserted_at: nil,
            updated_at: nil
          },
          %Notebook{
            github_filename: "collections.livemd",
            github_html_url: "https://github.com/charlieroth/elixir-notebooks/blob/48c66fbaac086bd98ea5891d8e47b20c49097d83/collections.livemd",
            github_owner_avatar_url: "https://avatars.githubusercontent.com/u/13981427?v=4",
            github_owner_login: "charlieroth",
            github_repo_name: "elixir-notebooks",
            id: nil,
            inserted_at: nil,
            updated_at: nil
          }
        ]
      end
    end
  end
end
