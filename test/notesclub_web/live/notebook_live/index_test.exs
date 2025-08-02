defmodule NotesclubWeb.NotebookLive.IndexTest do
  use NotesclubWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Notesclub.NotebooksFixtures
  import Notesclub.AccountsFixtures

  test "GET /random loads notebooks", %{conn: conn} do
    count = 10

    for i <- 1..count do
      notebook_fixture(github_filename: "whatever#{i}.livemd")
    end

    {:ok, _view, html} = live(conn, "/random")

    assert count ==
             1..count
             |> Enum.filter(fn i ->
               html =~ "whatever#{i}.livemd"
             end)
             |> Enum.count()
  end

  test "GET /top returns notebooks", %{conn: conn} do
    notebook_fixture(github_filename: "whatever5.livemd", likes_count: 5)
    notebook_fixture(github_filename: "whatever15.livemd", likes_count: 15)
    notebook_fixture(github_filename: "whatever0.livemd", likes_count: 0)

    {:ok, _view, html} = live(conn, "/top")

    assert html =~ "whatever15.livemd"
    assert html =~ "whatever5.livemd"
    assert html =~ "whatever0.livemd"
  end

  test "GET / includes the date", %{conn: conn} do
    notebook = notebook_fixture()
    %NaiveDateTime{year: year, month: month, day: day} = notebook.inserted_at

    {:ok, _view, html} = live(conn, "/")
    html =~ "#{year}-#{month}-#{day}"
  end

  test "GET / returns notebooks", %{conn: conn} do
    for i <- 1..10 do
      notebook_fixture(github_filename: "whatever#{i}.livemd")
    end

    {:ok, _view, html} = live(conn, "/")

    Enum.each(1..10, fn i ->
      assert html =~ "whatever#{i}.livemd"
    end)
  end

  test "GET / returns number of notebooks" do
    count = 3

    for i <- 1..count do
      notebook_fixture(github_filename: "whatever#{i}.livemd")
    end

    assert "#{count} notebooks and counting"
  end

  test "GET / returns name and username", %{conn: conn} do
    user = user_fixture(name: "One person", username: "someone")
    notebook_fixture(user_id: user.id, github_owner_login: "someone")

    {:ok, view, _html} = live(conn, "/")

    assert render(view) =~ "One person"
    assert render(view) =~ "@someone"
  end

  test "GET / does NOT include close filter button", %{conn: conn} do
    notebook_fixture(github_filename: "myfile.livemd", content: "# One 🎄🤶\n ...")

    {:ok, _view, html} = live(conn, "/")

    refute html =~ "Remove filter"
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

  test "GET /search returns notebooks that match filename or content (exact search)", %{
    conn: conn
  } do
    notebook_fixture(github_filename: "found.livemd")

    notebook_fixture(
      github_filename: "any-name.livemd",
      content: "abc found xyz"
    )

    notebook_fixture(github_filename: "not_present.livemd")

    {:ok, _view, html} = live(conn, "/search?q=\"found\"")

    assert html =~ "found.livemd"
    assert html =~ "any-name.livemd"
    # Content fragment is only shown when filename doesn't contain search term
    assert html =~ "abc found xyz"

    refute html =~ "not_present.livemd"
  end

  test "GET /search returns notebooks with content that match title (exact search)", %{conn: conn} do
    notebook_fixture(
      github_filename: "livebook.livemd",
      title: "Found",
      content: "abc found xyz"
    )

    {:ok, _view, html} = live(conn, "/search?q=\"found\"")

    assert html =~ "livebook.livemd"
    # Content fragment is shown because filename doesn't contain search term
    assert html =~ "abc found xyz"
  end

  test "GET /search full-text search returns relevant notebooks", %{conn: conn} do
    notebook_fixture(
      github_filename: "machine_learning.livemd",
      title: "Introduction to Machine Learning",
      content: "This notebook covers neural networks and deep learning concepts."
    )

    notebook_fixture(
      github_filename: "data_analysis.livemd",
      title: "Data Analysis with Elixir",
      content: "Introduction to whatever and learning."
    )

    notebook_fixture(
      github_filename: "unrelated.livemd",
      title: "Web Development",
      content: "Building web applications with Phoenix framework."
    )

    {:ok, _view, html} = live(conn, "/search?q=introduction+learning")

    assert html =~ "machine_learning.livemd"
    assert html =~ "Introduction to Machine Learning"
    refute html =~ "unrelated.livemd"
  end

  test "GET /search full-text search with single word", %{conn: conn} do
    notebook_fixture(
      github_filename: "neural_networks.livemd",
      title: "Neural Networks Tutorial",
      content: "Deep learning with neural networks and backpropagation."
    )

    notebook_fixture(
      github_filename: "web_app.livemd",
      title: "Web Application",
      content: "Building web applications with Phoenix."
    )

    {:ok, _view, html} = live(conn, "/search?q=neural")

    assert html =~ "neural_networks.livemd"
    assert html =~ "Neural Networks Tutorial"
    refute html =~ "web_app.livemd"
  end

  test "GET /search full-text search matches content", %{conn: conn} do
    notebook_fixture(
      github_filename: "tutorial.livemd",
      title: "Elixir Tutorial",
      content: "This notebook teaches you about pattern matching and recursion in Elixir."
    )

    notebook_fixture(
      github_filename: "other.livemd",
      title: "Other Topic",
      content: "This notebook is about something else entirely."
    )

    {:ok, _view, html} = live(conn, "/search?q=pattern matching")

    assert html =~ "tutorial.livemd"
    assert html =~ "Elixir Tutorial"
    refute html =~ "other.livemd"
  end

  test "GET /search empty search should change the path to /", %{conn: conn} do
    notebook_fixture(github_filename: "found.livemd")

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
    notebook_fixture(github_filename: "one.livemd")
    notebook_fixture(github_filename: "two.livemd")
    notebook_fixture(github_filename: "three.livemd")

    {:ok, _view, html} = live(conn, "/search")

    assert html =~ "one.livemd"
    assert html =~ "two.livemd"
    assert html =~ "three.livemd"
  end

  test "GET /search returns notebooks with emojis", %{conn: conn} do
    notebook_fixture(github_filename: "one.livemd", content: "# One 🎄🤶\n ...")
    notebook_fixture(github_filename: "two.livemd", content: "no emojis")
    notebook_fixture(github_filename: "three.livemd", content: "whatever")

    {:ok, _view, html} = live(conn, "/search")

    assert html =~ "one.livemd"
    assert html =~ "two.livemd"
    assert html =~ "three.livemd"
  end

  test "GET /search excludes notebooks without content", %{conn: conn} do
    notebook_fixture(github_filename: "one.livemd", content: "One")
    notebook_fixture(github_filename: "no-content.livemd", content: nil)
    notebook_fixture(github_filename: "two.livemd", content: "whatever")

    {:ok, _view, html} = live(conn, "/search")

    assert html =~ "one.livemd"
    assert html =~ "two.livemd"

    # Excludes notebooks with content: nil
    refute html =~ "no-content.livemd"
  end

  test "GET /search does NOT include close filter button", %{conn: conn} do
    notebook_fixture(github_filename: "myfile.livemd", content: "# One 🎄🤶\n ...")

    {:ok, _view, html} = live(conn, "/search?q=one")

    refute html =~ "Remove filter"
  end

  test "GET /:author filters notebooks", %{conn: conn} do
    user_fixture(username: "someone")

    notebook_fixture(
      github_filename: "whatever1.livemd",
      github_owner_login: "someone"
    )

    notebook_fixture(
      github_filename: "whatever2.livemd",
      github_owner_login: "someone"
    )

    notebook_fixture(
      github_filename: "whatever3.livemd",
      github_owner_login: "someone else"
    )

    notebook_fixture(
      github_filename: "whatever4.livemd",
      github_owner_login: "someone"
    )

    {:ok, _view, html} = live(conn, "/someone")

    assert html =~ "whatever1.livemd"
    refute html =~ "whatever3.livemd"
    assert html =~ "whatever2.livemd"
    assert html =~ "whatever4.livemd"
  end

  test "GET /:author includes close filter button", %{conn: conn} do
    user_fixture(username: "someone")

    notebook_fixture(
      github_filename: "whatever1.livemd",
      github_owner_login: "someone"
    )

    {:ok, _view, html} = live(conn, "/someone")

    assert html =~ "Remove filter"
  end

  test "GET /:author/:repo includes close filter button", %{conn: conn} do
    notebook_fixture(
      github_filename: "whatever1.livemd",
      github_full_name: "someone/her_repo"
    )

    {:ok, _view, html} = live(conn, "/someone/her_repo")

    assert html =~ "Remove filter"
  end

  test "GET /:author/:repo filters notebooks", %{conn: conn} do
    notebook_fixture(
      github_filename: "whatever1.livemd",
      github_owner_login: "someone",
      github_repo_name: "one"
    )

    notebook_fixture(
      github_filename: "whatever2.livemd",
      github_owner_login: "someone",
      github_repo_name: "two"
    )

    notebook_fixture(
      github_filename: "whatever3.livemd",
      github_owner_login: "someone else",
      github_repo_name: "three"
    )

    notebook_fixture(
      github_filename: "whatever4.livemd",
      github_owner_login: "someone",
      github_repo_name: "one"
    )

    {:ok, _view, html} = live(conn, "/someone/one")

    assert html =~ "whatever1.livemd"
    refute html =~ "whatever2.livemd"
    refute html =~ "whatever3.livemd"
    assert html =~ "whatever4.livemd"
  end

  test "/last_week redirects to /", %{conn: conn} do
    {:error, {:redirect, %{to: "/"}}} = live(conn, "/last_week")
  end
end
