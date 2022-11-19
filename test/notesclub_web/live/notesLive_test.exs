defmodule NotesclubWeb.NotesLiveTest do
  use NotesclubWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Notesclub.NotebooksFixtures

  alias Notesclub.Notebooks
  alias NotesclubWeb.NotesLive

  test "GET /random only returns first n notebooks", %{conn: conn} do
    random_notebooks_count = NotesLive.random_notebooks_count()
    notebooks_count = random_notebooks_count + 3

    for i <- 1..notebooks_count do
      notebook_fixture(%{github_filename: "whatever#{i}.livemd"})
    end

    {:ok, _view, html} = live(conn, "/random")

    assert random_notebooks_count ==
             1..notebooks_count
             |> Enum.filter(fn i ->
               html =~ "whatever#{i}.livemd"
             end)
             |> Enum.count()
  end

  test "GET /all includes the date", %{conn: conn} do
    notebook = notebook_fixture(%{})
    %NaiveDateTime{year: year, month: month, day: day} = notebook.inserted_at

    {:ok, _view, html} = live(conn, "/all")
    html =~ "#{year}-#{month}-#{day}"
  end

  test "GET /all returns all notebooks", %{conn: conn} do
    random_notebooks_count = NotesLive.random_notebooks_count()
    notebooks_count = random_notebooks_count + 3

    for i <- 1..notebooks_count do
      notebook_fixture(%{github_filename: "whatever#{i}.livemd"})
    end

    {:ok, _view, html} = live(conn, "/all")

    assert notebooks_count ==
             1..notebooks_count
             |> Enum.filter(fn i ->
               html =~ "whatever#{i}.livemd"
             end)
             |> Enum.count()
  end

  test "GET /all with search returns notebooks that match filename", %{conn: conn} do
    notebook_fixture(%{github_filename: "found.livemd"})

    notebook_fixture(%{
      github_filename: "any-name.livemd",
      content: "abc found xyz"
    })

    notebook_fixture(%{github_filename: "not_present.livemd"})

    {:ok, _view, html} = live(conn, "/all?search=found")

    assert html =~ "found.livemd"
    refute html =~ "any-name.livemd"
    refute html =~ "not_present.livemd"
  end

  test "GET /all with content:search returns notebooks that match filename or content", %{
    conn: conn
  } do
    notebook_fixture(%{github_filename: "found.livemd"})

    notebook_fixture(%{
      github_filename: "any-name.livemd",
      content: "abc found xyz"
    })

    notebook_fixture(%{github_filename: "not_present.livemd"})

    {:ok, _view, html} = live(conn, "/all?search=content:found")

    assert html =~ "found.livemd"
    assert html =~ "any-name.livemd"
    refute html =~ "not_present.livemd"
  end

  test "GET /:author filters notebooks", %{conn: conn} do
    notebook_fixture(%{
      github_filename: "whatever1.livemd",
      github_owner_login: "someone"
    })

    notebook_fixture(%{
      github_filename: "whatever2.livemd",
      github_owner_login: "someone"
    })

    notebook_fixture(%{
      github_filename: "whatever3.livemd",
      github_owner_login: "someone else"
    })

    notebook_fixture(%{
      github_filename: "whatever4.livemd",
      github_owner_login: "someone"
    })

    conn = get(conn, "/someone")
    {:ok, _view, html} = live(conn, "/someone")

    assert html =~ "whatever1.livemd"
    refute html =~ "whatever3.livemd"
    assert html =~ "whatever2.livemd"
    assert html =~ "whatever4.livemd"
  end

  test "GET /:author/:repo filters notebooks", %{conn: conn} do
    notebook_fixture(%{
      github_filename: "whatever1.livemd",
      github_owner_login: "someone",
      github_repo_name: "one"
    })

    notebook_fixture(%{
      github_filename: "whatever2.livemd",
      github_owner_login: "someone",
      github_repo_name: "two"
    })

    notebook_fixture(%{
      github_filename: "whatever3.livemd",
      github_owner_login: "someone else",
      github_repo_name: "three"
    })

    notebook_fixture(%{
      github_filename: "whatever4.livemd",
      github_owner_login: "someone",
      github_repo_name: "one"
    })

    {:ok, _view, html} = live(conn, "/someone/one")

    assert html =~ "whatever1.livemd"
    refute html =~ "whatever2.livemd"
    refute html =~ "whatever3.livemd"
    assert html =~ "whatever4.livemd"
  end

  test "GET / returns last week's notebooks", %{conn: conn} do
    # today
    notebook_fixture(%{github_filename: "whatever0.livemd"})

    for day <- 1..10 do
      n = notebook_fixture(%{github_filename: "whatever#{day}.livemd"})
      {:ok, _} = Notebooks.update_notebook(n, %{inserted_at: DateTools.days_ago(day)})
    end

    {:ok, _view, html} = live(conn, "/")

    for day <- 0..6 do
      assert html =~ "whatever#{day}.livemd"
    end

    refute html =~ "whatever8.livemd"
    refute html =~ "whatever9.livemd"
    refute html =~ "whatever10.livemd"
  end
end
