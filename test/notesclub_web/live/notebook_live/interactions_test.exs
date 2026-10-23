defmodule NotesclubWeb.NotebookLive.InteractionsTest do
  use NotesclubWeb.ConnCase

  import Notesclub.AccountsFixtures
  import Notesclub.NotebooksFixtures
  import Phoenix.LiveViewTest

  alias Notesclub.Notebooks
  alias Notesclub.Stars
  alias Notesclub.Tags
  alias NotesclubWeb.NotebookLive.Index
  alias NotesclubWeb.RateLimiter

  test "sorting preserves each filter and cycles through supported orders", %{conn: conn} do
    user_fixture(%{username: "author"})
    {:ok, _} = Tags.create_tag(%{name: "tutorial"})

    for path <- ["/", "/author", "/author/repo", "/hex/req", "/tags/tutorial", "/search?q=guide"] do
      {:ok, view, _} = live(conn, path)
      separator = if String.contains?(path, "?"), do: "&", else: "?"
      render_click(view, "toggle-sort")
      assert_patch(view, path <> separator <> "sort=top")
      render_click(view, "toggle-sort")
      assert_patch(view, path <> separator <> "sort=random")
      render_click(view, "toggle-sort")
      assert_patch(view, path)

      for sort <- ["top", "random", "new", "invalid"] do
        render_click(view, "set-sort", %{"sort" => sort})

        expected =
          if sort in ["top", "random"], do: path <> separator <> "sort=" <> sort, else: path

        assert_patch(view, expected)
      end
    end
  end

  test "navigation events move between home, random, and top", %{conn: conn} do
    {:ok, view, _} = live(conn, "/")

    for {event, path} <- [{"random", "/random"}, {"top", "/top"}, {"home", "/"}] do
      render_click(view, event)
      assert_patch(view, path)
    end

    render_click(view, "random")
    render_click(view, "set-sort", %{"sort" => "new"})
    assert_patch(view, "/")
  end

  test "loading more notebooks appends the remaining results without skipping or duplicating them",
       %{conn: conn} do
    for i <- 1..(Index.per_page() + 1) do
      notebook_fixture(%{
        title: "Pagination notebook #{i}",
        github_filename: "pagination_#{i}.livemd"
      })
    end

    {:ok, view, html} = live(conn, "/")
    refute html =~ "pagination_1.livemd"
    html = render_click(view, "load-more")

    for i <- 1..(Index.per_page() + 1) do
      assert html =~ "pagination_#{i}.livemd"
    end

    assert render_click(view, "load-more") == html
  end

  test "unknown and empty tags have distinct empty messages", %{conn: conn} do
    {:ok, _, html} = live(conn, "/tags/unknown")
    assert html =~ "We don&#39;t have that tag yet!"
    {:ok, _} = Tags.create_tag(%{name: "tutorial"})
    {:ok, _, html} = live(conn, "/tags/tutorial")
    assert html =~ "No notebooks with that tag yet!"
  end

  test "users can expand and collapse the featured tag list", %{conn: conn} do
    {:ok, view, _} = live(conn, "/")
    refute has_element?(view, "a[href='/tags/robotics']")
    view |> element("[phx-click='show-all-tags']") |> render_click()
    assert has_element?(view, "a[href='/tags/robotics']")
    view |> element("[phx-click='dont-show-all-tags']") |> render_click()
    refute has_element?(view, "a[href='/tags/robotics']")
  end

  test "signed-in readers can add and remove stars and view their favourites", %{conn: conn} do
    user = user_fixture(%{username: "reader", name: nil, twitter_username: "reader"})

    notebook =
      notebook_fixture(%{
        user_id: user.id,
        title: "Favourite notebook",
        url: "https://github.com/reader/repo/blob/main/book.livemd"
      })

    conn = init_test_session(conn, %{user_id: user.id})
    {:ok, view, _} = live(conn, "/reader/repo/book")
    render_click(view, "toggle-star")
    assert Stars.starred?(notebook, user)
    assert Notebooks.get_star_count(notebook.id) == 1

    {:ok, _, html} = live(conn, "/reader/stars")
    assert html =~ "Favourite notebook"

    render_click(view, "toggle-star")
    refute Stars.starred?(notebook, user)
    assert Stars.star_count(notebook) == 0
  end

  test "anonymous readers are asked to sign in before starring", %{conn: conn} do
    user = user_fixture(%{name: nil, twitter_username: nil})

    notebook =
      notebook_fixture(%{
        user_id: user.id,
        url:
          "https://github.com/author/repo/blob/main/a/very/long/directory/path/for/a/notebook/book.livemd"
      })

    {:ok, view, html} = live(conn, "/author/repo/a/very/long/directory/path/for/a/notebook/book")
    assert html =~ notebook.github_filename
    assert render_click(view, "toggle-star") =~ "Log in to star this notebook"
    assert Stars.star_count(notebook) == 0
  end

  test "rate limits repeated LiveView events", %{conn: conn} do
    user = user_fixture()
    filename = "rate-limited.livemd"

    notebook =
      notebook_fixture(%{
        user_id: user.id,
        github_filename: filename,
        url: "https://github.com/#{user.username}/repo/blob/main/#{filename}"
      })

    conn = init_test_session(conn, %{user_id: user.id})
    {:ok, view, _} = live(conn, "/#{user.username}/repo/rate-limited")

    for _ <- 1..60 do
      assert RateLimiter.allow?({:live_event, {:user, user.id}, "toggle-star"}, 60, 60_000)
    end

    assert render_click(view, "toggle-star") =~ "Too many requests"
    refute Stars.starred?(notebook, user)
  end

  test "timestamped searches ignore older events", %{conn: conn} do
    {:ok, view, _} = live(conn, "/")
    render_keyup(view, "search", %{"value" => "latest", "timestamp" => 200})
    assert_patch(view, "/search?q=latest")
    render_keyup(view, "search", %{"value" => "stale", "timestamp" => 100})
    assert has_element?(view, "input[value='latest']")
  end
end
