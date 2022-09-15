defmodule Notesclub.Searches.RemoveTest do
  use Notesclub.DataCase

  alias Notesclub.Repo
  alias Notesclub.Searches.Remove
  alias Notesclub.Searches.Search
  alias Notesclub.Notebooks.Notebook

  import Notesclub.SearchesFixtures
  import Notesclub.NotebooksFixtures


  describe "delete/0" do
    test "function returns expected response" do
      _search = search_fixture()
      assert {0, nil} = Remove.eliminate()
    end

    test "should only delete older records specfied in module" do
      search_1 = search_fixture()
      _search_2 = search_fixture()

      update_inserted_at(search_1, get_expiry_date(1))

      assert {1, nil} = Remove.eliminate()
      assert nil == Repo.get(Search, search_1.id)
    end

    test "shouldn't delete on last day" do
      search_1 = search_fixture()
      _search_2 = search_fixture()

      update_inserted_at(search_1, get_expiry_date(0))

      assert {0, nil} = Remove.eliminate()
    end

    test "linked notebooks should be nulified" do
      search_1 = search_fixture()
      notebook = notebook_fixture(%{search_id: search_1.id})

      assert notebook.search_id == search_1.id

      update_inserted_at(search_1, get_expiry_date(2))

      {1, nil} = Remove.eliminate()
      updated_notebook = Repo.get(Notebook, notebook.id)

      assert updated_notebook.id == notebook.id
      assert updated_notebook.search_id == nil
    end
  end

  defp update_inserted_at(search, date) do
    Search
    |> Repo.get(search.id)
    |> Search.changeset(%{inserted_at: date})
    |> Repo.update()
  end

  defp get_expiry_date(time_margin) do
    Timex.now()
    |> Timex.shift(days: -(Remove.number_of_days_to_keep_search_results() + time_margin))
  end
end
