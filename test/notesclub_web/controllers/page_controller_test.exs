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

  test "GET /livebookll returns all notebooks", %{conn: conn} do
    notebooks_in_home_count = PageController.notebooks_in_home_count()
    notebooks_count = notebooks_in_home_count + 3

    for i <- 1..notebooks_count do
      NotebooksFixtures.notebook_fixture(%{github_filename: "whatever#{i}.livemd"})
    end

    conn = get(conn, "/livebook")

    assert notebooks_count ==
      1..notebooks_count
      |> Enum.filter(fn i ->
        html_response(conn, 200) =~ "whatever#{i}.livemd"
      end)
      |> Enum.count
  end

  test "GET /livebook/:author filters notebooks", %{conn: conn} do
    NotebooksFixtures.notebook_fixture(%{github_filename: "whatever1.livemd", github_owner_login: "someone"})
    NotebooksFixtures.notebook_fixture(%{github_filename: "whatever2.livemd", github_owner_login: "someone"})
    NotebooksFixtures.notebook_fixture(%{github_filename: "whatever3.livemd", github_owner_login: "someone else"})
    NotebooksFixtures.notebook_fixture(%{github_filename: "whatever4.livemd", github_owner_login: "someone"})

    conn = get(conn, "/livebook/someone")

    assert html_response(conn, 200) =~ "whatever1.livemd"
    assert html_response(conn, 200) =~ "whatever2.livemd"
    refute html_response(conn, 200) =~ "whatever3.livemd"
    assert html_response(conn, 200) =~ "whatever4.livemd"
  end

  test "GET /livebook/:author/:repo filters notebooks", %{conn: conn} do
    NotebooksFixtures.notebook_fixture(%{github_filename: "whatever1.livemd", github_owner_login: "someone", github_repo_name: "one"})
    NotebooksFixtures.notebook_fixture(%{github_filename: "whatever2.livemd", github_owner_login: "someone", github_repo_name: "two"})
    NotebooksFixtures.notebook_fixture(%{github_filename: "whatever3.livemd", github_owner_login: "someone else", github_repo_name: "three"})
    NotebooksFixtures.notebook_fixture(%{github_filename: "whatever4.livemd", github_owner_login: "someone", github_repo_name: "one"})

    conn = get(conn, "/livebook/someone/one")

    assert html_response(conn, 200) =~ "whatever1.livemd"
    refute html_response(conn, 200) =~ "whatever2.livemd"
    refute html_response(conn, 200) =~ "whatever3.livemd"
    assert html_response(conn, 200) =~ "whatever4.livemd"
  end
end
