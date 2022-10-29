defmodule Notesclub.SearchesTest do
  use Notesclub.DataCase

  alias Notesclub.Searches

  describe "searches" do
    alias Notesclub.Searches.Search

    import Notesclub.SearchesFixtures
    import Notesclub.AccountsFixtures

    @invalid_attrs %{
      order: nil,
      page: nil,
      per_page: nil,
      response_notebooks_count: nil,
      response_status: nil,
      url: nil
    }

    test "list_searches/0 returns all searches" do
      search = search_fixture()
      assert Searches.list_searches() == [search]
    end

    test "get_search!/1 returns the search with given id" do
      search = search_fixture()
      assert Searches.get_search!(search.id) == search
    end

    test "create_search/1 with valid data creates a search" do
      valid_attrs = %{
        order: "some order",
        page: 42,
        per_page: 42,
        response_notebooks_count: 42,
        response_status: 42,
        url: "some url"
      }

      assert {:ok, %Search{} = search} = Searches.create_search(valid_attrs)
      assert search.order == "some order"
      assert search.page == 42
      assert search.per_page == 42
      assert search.response_notebooks_count == 42
      assert search.response_status == 42
      assert search.url == "some url"
    end

    test "create_search/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Searches.create_search(@invalid_attrs)
    end

    test "update_search/2 with valid data updates the search" do
      search = search_fixture()

      update_attrs = %{
        order: "some updated order",
        page: 43,
        per_page: 43,
        response_notebooks_count: 43,
        response_status: 43,
        url: "some updated url"
      }

      assert {:ok, %Search{} = search} = Searches.update_search(search, update_attrs)
      assert search.order == "some updated order"
      assert search.page == 43
      assert search.per_page == 43
      assert search.response_notebooks_count == 43
      assert search.response_status == 43
      assert search.url == "some updated url"
    end

    test "update_search/2 with invalid data returns error changeset" do
      search = search_fixture()
      assert {:error, %Ecto.Changeset{}} = Searches.update_search(search, @invalid_attrs)
      assert search == Searches.get_search!(search.id)
    end

    test "delete_search/1 deletes the search" do
      search = search_fixture()
      assert {:ok, %Search{}} = Searches.delete_search(search)
      assert_raise Ecto.NoResultsError, fn -> Searches.get_search!(search.id) end
    end

    test "change_search/1 returns a search changeset" do
      search = search_fixture()
      assert %Ecto.Changeset{} = Searches.change_search(search)
    end

    test "notebooks_by_user/1 inserts new notebooks" do
      # don't pass a user
      # api endpoint fails
      user = user_fixture()
      {:ok, _notebooks} = Searches.notebooks_by_user(user)
    end
  end
end
