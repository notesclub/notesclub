defmodule NotesclubWeb.PageControllerTest do
  use NotesclubWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Notesclub"
  end
end
