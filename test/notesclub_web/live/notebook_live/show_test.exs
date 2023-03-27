defmodule NotesclubWeb.NotebookLive.ShowTest do
  use NotesclubWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Notesclub.NotebooksFixtures
  import Notesclub.AccountsFixtures
  import Notesclub.ReposFixtures

  setup do
    user = user_fixture(%{name: "Hec", username: "hectorperez"})
    repo = repo_fixture(%{name: "myrepo", user_id: user.id})

    path = "hectorperez/myrepo/blob/main/a.livemd"

    notebook =
      notebook_fixture(%{
        content: "# Something\n\netc.",
        title: "Something",
        url: "https://github.com/#{path}",
        user_id: user.id,
        repo_id: repo.id
      })

    %{user: user, repo: repo, path: path, notebook: notebook}
  end

  test "GET notebook returns content and user", %{path: path, conn: conn} do
    {:ok, view, _html} = live(conn, "/#{path}")

    assert render(view) =~ "Something"
    assert render(view) =~ "etc."
    assert has_element?(view, "a[href=\"/hectorperez\"]", "Hec")
    assert has_element?(view, "a[href=\"/hectorperez\"]", "@hectorperez")
    assert has_element?(view, "a[href=\"/hectorperez/myrepo\"]", "myrepo")
  end

  test "GET notebook has More notebooks link", %{path: path, conn: conn} do
    {:ok, view, _html} = live(conn, "/#{path}")

    assert has_element?(view, "a[href=\"/\"]", "More notebooks")
  end

  test "GET notebook escapes js to prevent XSS", %{conn: conn, user: user, repo: repo} do
    content = "<script>alert('hi')</script>"
    path = "hectorperez/myrepo/blob/main/b.livemd"

    notebook_fixture(%{
      content: content,
      title: "",
      url: "https://github.com/#{path}",
      user_id: user.id,
      repo_id: repo.id
    })

    {:ok, view, _html} = live(conn, "/#{path}")
    refute render(view) =~ ~r/<script>[\s\n]*alert\('hi'\)<\/script>/
    refute render(view) =~ ~r/<script>/
  end
end
