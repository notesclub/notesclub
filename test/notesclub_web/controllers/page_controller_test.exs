defmodule NotesclubWeb.PageControllerTest do
  use NotesclubWeb.ConnCase

  alias NotesclubWeb.PageController
  alias Notesclub.Notebooks
  alias Notesclub.NotebooksFixtures

  test "GET / only returns first n notebooks", %{conn: conn} do
    notebooks_in_home_count = PageController.notebooks_in_home_count()
    notebooks_count = notebooks_in_home_count + 3

    for i <- 1..notebooks_count do
      NotebooksFixtures.notebook_fixture(%{github_filename: "whatever#{i}.livemd"})
    end

    conn = get(conn, "/")

    assert notebooks_in_home_count ==
      1..notebooks_count
      |> Enum.filter(fn i ->
        html_response(conn, 200) =~ "whatever#{i}.livemd"
      end)
      |> Enum.count
  end

  test "GET /all returns all notebooks", %{conn: conn} do
    notebooks_in_home_count = PageController.notebooks_in_home_count()
    notebooks_count = notebooks_in_home_count + 3

    for i <- 1..notebooks_count do
      NotebooksFixtures.notebook_fixture(%{github_filename: "whatever#{i}.livemd"})
    end

    conn = get(conn, "/all")

    assert notebooks_count ==
      1..notebooks_count
      |> Enum.filter(fn i ->
        html_response(conn, 200) =~ "whatever#{i}.livemd"
      end)
      |> Enum.count
  end
end
