defmodule NotesclubWeb.NotebookLive.ShowTest do
  use NotesclubWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Notesclub.NotebooksFixtures
  import Notesclub.AccountsFixtures
  import Notesclub.ReposFixtures

  test "GET notebook returns content and user", %{conn: conn} do
    user = user_fixture(%{name: "Hec", username: "hectorperez"})
    repo = repo_fixture(%{name: "myrepo", user_id: user.id})

    file = "hectorperez/myrepo/blob/main/a.livemd"

    notebook_fixture(%{
      content: "# Something\n\netc.",
      title: "Something",
      url: "https://github.com/#{file}",
      user_id: user.id,
      repo_id: repo.id
    })

    {:ok, view, _html} = live(conn, "/#{file}")

    assert render(view) =~ "Something"
    assert render(view) =~ "etc."
    assert render(view) =~ "Hec"
    assert render(view) =~ "@hectorperez"
  end
end
