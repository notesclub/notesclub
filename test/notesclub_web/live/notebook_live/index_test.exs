defmodule NotesclubWeb.NotebookLive.IndexTest do
  use NotesclubWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Notesclub.NotebooksFixtures
  import Notesclub.AccountsFixtures

  test "GET /random loads notebooks", %{conn: conn} do
    count = 10

    for i <- 1..count do
      notebook_fixture(%{github_filename: "whatever#{i}.livemd"})
    end

    {:ok, _view, html} = live(conn, "/random")

    assert count ==
             1..count
             |> Enum.filter(fn i ->
               html =~ "whatever#{i}.livemd"
             end)
             |> Enum.count()
  end

  test "GET / includes the date", %{conn: conn} do
    notebook = notebook_fixture(%{})
    %NaiveDateTime{year: year, month: month, day: day} = notebook.inserted_at

    {:ok, _view, html} = live(conn, "/")
    html =~ "#{year}-#{month}-#{day}"
  end

  test "GET / returns notebooks", %{conn: conn} do
    for i <- 1..10 do
      notebook_fixture(%{github_filename: "whatever#{i}.livemd"})
    end

    {:ok, _view, html} = live(conn, "/")

    Enum.each(1..10, fn i ->
      assert html =~ "whatever#{i}.livemd"
    end)
  end

  test "GET / returns name and username", %{conn: conn} do
    user = user_fixture(%{name: "One person", username: "someone"})
    notebook_fixture(%{user_id: user.id, github_owner_login: "someone"})

    {:ok, view, _html} = live(conn, "/")

    assert render(view) =~ "One person"
    assert render(view) =~ "@someone"
  end

  test "GET / does NOT include close filter button", %{conn: conn} do
    notebook_fixture(%{github_filename: "myfile.livemd", content: "# One 🎄🤶\n ..."})

    {:ok, _view, html} = live(conn, "/")

    refute html =~ "Remove filter"
  end

  test "GET /search returns notebooks that match filename or content", %{conn: conn} do
    notebook_fixture(%{github_filename: "found.livemd"})

    notebook_fixture(%{
      github_filename: "any-name.livemd",
      content: "abc found xyz"
    })

    notebook_fixture(%{github_filename: "not_present.livemd"})

    {:ok, _view, html} = live(conn, "/search?q=found")

    assert html =~ "found.livemd"
    assert html =~ "any-name.livemd"
    refute html =~ "not_present.livemd"
  end

  test "GET /search empty search should change the path to /", %{conn: conn} do
    notebook_fixture(%{github_filename: "found.livemd"})

    {:ok, view, _html} = live(conn, "/")

    # When we search "ecto", the path is "/search?q=ecto"
    assert view
           |> form("#search", value: "ecto")
           |> render_submit()

    assert_patch(view, "/search?q=ecto")

    # When we search "", the path is "/"
    assert view
           |> form("#search", value: "")
           |> render_submit()

    assert_patch(view, "/")
  end

  test "GET /search without query returns all notebooks", %{conn: conn} do
    notebook_fixture(%{github_filename: "one.livemd"})
    notebook_fixture(%{github_filename: "two.livemd"})
    notebook_fixture(%{github_filename: "three.livemd"})

    {:ok, _view, html} = live(conn, "/search")

    assert html =~ "one.livemd"
    assert html =~ "two.livemd"
    assert html =~ "three.livemd"
  end

  test "GET /search returns notebooks with emojis", %{conn: conn} do
    notebook_fixture(%{github_filename: "one.livemd", content: "# One 🎄🤶\n ..."})
    notebook_fixture(%{github_filename: "two.livemd", content: ""})
    notebook_fixture(%{github_filename: "three.livemd"})

    {:ok, _view, html} = live(conn, "/search")

    assert html =~ "one.livemd"
    assert html =~ "two.livemd"
    assert html =~ "three.livemd"
  end

  test "GET /search does NOT include close filter button", %{conn: conn} do
    notebook_fixture(%{github_filename: "myfile.livemd", content: "# One 🎄🤶\n ..."})

    {:ok, _view, html} = live(conn, "/search?q=one")

    refute html =~ "Remove filter"
  end

  test "GET /:author filters notebooks", %{conn: conn} do
    user_fixture(%{username: "someone"})

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

    {:ok, _view, html} = live(conn, "/someone")

    assert html =~ "whatever1.livemd"
    refute html =~ "whatever3.livemd"
    assert html =~ "whatever2.livemd"
    assert html =~ "whatever4.livemd"
  end

  test "GET /:author includes close filter button", %{conn: conn} do
    user_fixture(%{username: "someone"})

    notebook_fixture(%{
      github_filename: "whatever1.livemd",
      github_owner_login: "someone"
    })

    {:ok, _view, html} = live(conn, "/someone")

    assert html =~ "Remove filter"
  end

  test "GET /:author/:repo includes close filter button", %{conn: conn} do
    notebook_fixture(%{
      github_filename: "whatever1.livemd",
      github_full_name: "someone/her_repo"
    })

    {:ok, _view, html} = live(conn, "/someone/her_repo")

    assert html =~ "Remove filter"
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

  test "GET / includes featured users", %{conn: conn} do
    notebook_fixture()

    {:ok, _view, html} = live(conn, "/")

    assert html =~ "Featured:"
    assert html =~ "@livebook-dev</a>"
    assert html =~ "@elixir-nx</a>"
    assert html =~ "@josevalim</a>"
    assert html =~ "@DockYard-Academy</a>"
    assert html =~ "@BrooklinJazz</a>"
  end

  test "/last_week redirects to /", %{conn: conn} do
    {:error, {:redirect, %{to: "/"}}} = live(conn, "/last_week")
  end
end
