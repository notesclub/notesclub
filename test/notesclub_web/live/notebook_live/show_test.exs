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

    notebook_fixture(%{
      content: "# Something\n\netc.",
      title: "Something",
      url: "https://github.com/#{path}",
      user_id: user.id,
      repo_id: repo.id
    })

    %{path: path}
  end

  test "GET notebook returns content and user", %{path: path, conn: conn} do
    {:ok, view, _html} = live(conn, "/#{path}")

    assert render(view) =~ "Something"
    assert render(view) =~ "etc."
    assert render(view) =~ "Hec"
    assert render(view) =~ "@hectorperez"
  end

  test "GET notebook has More notebooks link", %{path: path, conn: conn} do
    {:ok, view, _html} = live(conn, "/#{path}")

    assert has_element?(view, "a[href=\"/\"]", "More notebooks")
  end
end
