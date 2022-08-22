defmodule Notesclub.Searches.PopulateTest do
  use Notesclub.DataCase

  alias Notesclub.Searches.Populate
  alias Notesclub.Searches
  alias Notesclub.Searches.Search
  alias Notesclub.Searches.Fetch.Options
  alias Notesclub.Notebooks
  alias Notesclub.Notebooks.Notebook

  import Mock

  @valid_response %Req.Response{
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

  describe "populate" do
    test "populate/1 downloads and saves notebooks" do
      with_mocks([
        { Req, [:passthrough], [get!: fn(_url, _options) -> @valid_response end]}
      ]) do
        options = %Options{per_page: 2, page: 1, order: "asc"}

        # Check that there are no searches or notebooks
        assert [] = Notebooks.list_notebooks()
        assert [] = Searches.list_searches()

        # Download two records and create them:
        assert Populate.populate(options) == %{created: 2, updated: 0, downloaded: 2}

        # Now we have one search and two notebooks
        [%Notebook{} = notebook1, %Notebook{} = notebook2] = Notebooks.list_notebooks()
        [%Search{} = search] = Searches.list_searches()
        [expected1, expected2] = @valid_response.body["items"]
        assert_attributes(notebook1, expected1, search)
        assert_attributes(notebook2, expected2, search)

        # Downloading the same records updates them — and creates one more search
        assert Populate.populate(options) == %{created: 0, updated: 2, downloaded: 2}
        [_, search2] = Searches.list_searches()
        [notebook1_after_update, notebook2_after_update] = Notebooks.list_notebooks()
        assert_attributes(notebook1_after_update, expected1, search2)
        assert_attributes(notebook2_after_update, expected2, search2)
      end
    end

    def test "next/0" do
      with_mocks([
        { Populate, [:passthrough], [populate: fn -> %{downloaded: 5} end]}
      ]) do

        assert [] = Notebooks.list_notebooks()

        # The first daily_page_limit() pages call populate()
        for _ <- 1..Populate.daily_page_limit() do
          assert %{downloaded: 5} == Populate.next()
        end

        # From then on, we don't download anymore:
        assert %{downloaded: 0} == Populate.next()
        assert %{downloaded: 0} == Populate.next()
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
