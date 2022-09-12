defmodule Notesclub.Searches.PopulateTest do
  use Notesclub.DataCase

  alias Notesclub.Searches
  alias Notesclub.Searches.Search
  alias Notesclub.Searches.Populate
  alias Notesclub.Searches.Fetch
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook

  import Mock

  @valid_response %Req.Response{
    status: 200,
    body: %{
      "items" => [
        %{
          "name" => "structs.livemd",
          "github_owner_login" => Faker.Internet.user_name(),
          "github_repo_name" => Faker.Internet.user_name(),
          "html_url" =>
            "https://github.com/charlieroth/elixir-notebooks/blob/68716ab303da9b98e21be9c04a3c86770ab7c819/structs.livemd",
          "repository" => %{
            "name" => "elixir-notebooks",
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
          "github_owner_login" => Faker.Internet.user_name(),
          "github_repo_name" => Faker.Internet.user_name(),
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
        }
      ],
      "total_count" => 2446
    }
  }

  describe "next/0" do
    test "downloads and saves notebooks — until we reach daily_page_limit" do
      with_mocks([
        {Populate, [:passthrough], [default_per_page: fn -> 2 end]},
        {Populate, [:passthrough], [daily_page_limit: fn -> 2 end]},
        {Fetch, [:passthrough], [check_github_api_key: fn -> false end]},
        {Req, [:passthrough], [get!: fn _url, _options -> @valid_response end]}
      ]) do
        # Check that there are no searches or notebooks
        assert [] = Notebooks.list_notebooks()
        assert [] = Searches.list_searches()

        # Download the first page
        assert %{created: 2, updated: 0, downloaded: 2} == Populate.next()

        # Now we have one search and two notebooks
        [%Notebook{} = notebook2_in_db, %Notebook{} = notebook1_in_db] =
          Notebooks.list_notebooks(order: :desc)

        [%Search{} = search1] = Searches.list_searches()
        [notebook1_downloaded, notebook2_downloaded] = @valid_response.body["items"]
        assert_attributes(notebook1_in_db, notebook1_downloaded, search1)
        assert_attributes(notebook2_in_db, notebook2_downloaded, search1)

        # Download the 2nd page updates because @valid_response is the same
        assert %{created: 0, updated: 2, downloaded: 2} == Populate.next()

        # Now we have one more search and the same notebooks — with the new search_id
        [^search1, search2] = Searches.list_searches()
        [n2, n1] = Notebooks.list_notebooks(order: :desc)
        assert n2.id == notebook2_in_db.id
        assert n1.id == notebook1_in_db.id
        assert n1.search_id == search2.id
        assert n2.search_id == search2.id

        #  From now on, we download 0 notebooks as we reached daily_page_limit()
        assert %{downloaded: 0, created: 0, updated: 0} == Populate.next()
        assert %{downloaded: 0, created: 0, updated: 0} == Populate.next()
        assert %{downloaded: 0, created: 0, updated: 0} == Populate.next()
      end
    end

    def assert_attributes(notebook, expected, search) do
      assert notebook.github_html_url == expected["html_url"]
      assert notebook.github_repo_name == expected["repository"]["name"]
      assert notebook.github_owner_login == expected["repository"]["owner"]["login"]
      assert notebook.github_owner_avatar_url == expected["repository"]["owner"]["avatar_url"]
      assert notebook.search_id == search.id
    end
  end
end
