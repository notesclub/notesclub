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
             |> Enum.count()
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
             |> Enum.count()
  end

  test "GET /all with search returns notebooks that match filename", %{conn: conn} do
    NotebooksFixtures.notebook_fixture(%{github_filename: "found.livemd"})

    NotebooksFixtures.notebook_fixture(%{
      github_filename: "any-name.livemd",
      content: "abc found xyz"
    })

    NotebooksFixtures.notebook_fixture(%{github_filename: "not_present.livemd"})

    conn = get(conn, "/all", search: "found")

    assert html_response(conn, 200) =~ "found.livemd"
    refute html_response(conn, 200) =~ "any-name.livemd"
    refute html_response(conn, 200) =~ "not_present.livemd"
  end

  test "GET /all with content:search returns notebooks that match filename or content", %{conn: conn} do
    NotebooksFixtures.notebook_fixture(%{github_filename: "found.livemd"})

    NotebooksFixtures.notebook_fixture(%{
      github_filename: "any-name.livemd",
      content: "abc found xyz"
    })

    NotebooksFixtures.notebook_fixture(%{github_filename: "not_present.livemd"})

    conn = get(conn, "/all", search: "content:found")

    assert html_response(conn, 200) =~ "found.livemd"
    assert html_response(conn, 200) =~ "any-name.livemd"
    refute html_response(conn, 200) =~ "not_present.livemd"
  end

  test "GET /:author filters notebooks", %{conn: conn} do
    NotebooksFixtures.notebook_fixture(%{
      github_filename: "whatever1.livemd",
      github_owner_login: "someone"
    })

    NotebooksFixtures.notebook_fixture(%{
      github_filename: "whatever2.livemd",
      github_owner_login: "someone"
    })

    NotebooksFixtures.notebook_fixture(%{
      github_filename: "whatever3.livemd",
      github_owner_login: "someone else"
    })

    NotebooksFixtures.notebook_fixture(%{
      github_filename: "whatever4.livemd",
      github_owner_login: "someone"
    })

    conn = get(conn, "/someone")

    assert html_response(conn, 200) =~ "whatever1.livemd"
    assert html_response(conn, 200) =~ "whatever2.livemd"
    refute html_response(conn, 200) =~ "whatever3.livemd"
    assert html_response(conn, 200) =~ "whatever4.livemd"
  end

  test "GET /:author/:repo filters notebooks", %{conn: conn} do
    NotebooksFixtures.notebook_fixture(%{
      github_filename: "whatever1.livemd",
      github_owner_login: "someone",
      github_repo_name: "one"
    })

    NotebooksFixtures.notebook_fixture(%{
      github_filename: "whatever2.livemd",
      github_owner_login: "someone",
      github_repo_name: "two"
    })

    NotebooksFixtures.notebook_fixture(%{
      github_filename: "whatever3.livemd",
      github_owner_login: "someone else",
      github_repo_name: "three"
    })

    NotebooksFixtures.notebook_fixture(%{
      github_filename: "whatever4.livemd",
      github_owner_login: "someone",
      github_repo_name: "one"
    })

    conn = get(conn, "/someone/one")

    assert html_response(conn, 200) =~ "whatever1.livemd"
    refute html_response(conn, 200) =~ "whatever2.livemd"
    refute html_response(conn, 200) =~ "whatever3.livemd"
    assert html_response(conn, 200) =~ "whatever4.livemd"
  end

  test "GET /last_week returns last week's notebooks", %{conn: conn} do
    # today
    NotebooksFixtures.notebook_fixture(%{github_filename: "whatever0.livemd"})

    for day <- 1..10 do
      n = NotebooksFixtures.notebook_fixture(%{github_filename: "whatever#{day}.livemd"})
      {:ok, _} = Notebooks.update_notebook(n, %{inserted_at: DateTools.days_ago(day)})
    end

    conn = get(conn, "/last_week")

    for day <- 0..6 do
      assert html_response(conn, 200) =~ "whatever#{day}.livemd"
    end

    refute html_response(conn, 200) =~ "whatever8.livemd"
    refute html_response(conn, 200) =~ "whatever9.livemd"
    refute html_response(conn, 200) =~ "whatever10.livemd"
  end

  test "GET /last_month returns last month's notebooks", %{conn: conn} do
    # today
    NotebooksFixtures.notebook_fixture(%{github_filename: "whatever0.livemd"})

    for day <- 1..32 do
      n = NotebooksFixtures.notebook_fixture(%{github_filename: "whatever#{day}.livemd"})
      {:ok, _} = Notebooks.update_notebook(n, %{inserted_at: DateTools.days_ago(day)})
    end

    conn = get(conn, "/last_month")

    for day <- 0..29 do
      assert html_response(conn, 200) =~ "whatever#{day}.livemd"
    end

    refute html_response(conn, 200) =~ "whatever30.livemd"
    refute html_response(conn, 200) =~ "whatever31.livemd"
  end
end
