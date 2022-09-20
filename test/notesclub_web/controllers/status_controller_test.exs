defmodule NotesclubWeb.StatusControllerTest do
  use NotesclubWeb.ConnCase

  test "GET /status returns OK", %{conn: conn} do
    conn = get(conn, "/ok")

    assert text_response(conn, 200) == "OK"
  end
end
