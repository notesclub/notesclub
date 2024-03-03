defmodule NotesclubWeb.StatusControllerTest do
  use NotesclubWeb.ConnCase
  import Notesclub.NotebooksFixtures

  test "GET /status returns OK when at least one notebook was inserted in the last 48 hours", %{
    conn: conn
  } do
    notebook = notebook_fixture(%{inserted_at: Timex.now() |> Timex.shift(hours: -47)})
    conn = get(conn, "/status")

    assert text_response(conn, 200) ==
             "OK: The most recent notebook was created on the #{notebook.inserted_at}"
  end

  test "GET /status returns ERROR when no notebook was inserted in the last 48 hours", %{
    conn: conn
  } do
    notebook = notebook_fixture(%{inserted_at: Timex.now() |> Timex.shift(hours: -49)})
    conn = get(conn, "/status")

    assert text_response(conn, 200) ==
             "ERROR: The most recent notebook was created on the #{notebook.inserted_at}"
  end
end
