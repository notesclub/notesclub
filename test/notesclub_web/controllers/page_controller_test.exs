defmodule NotesclubWeb.PageControllerTest do
  use NotesclubWeb.ConnCase

  test "GET /terms", %{conn: conn} do
    conn = get(conn, "/terms")
    assert html_response(conn, 200) =~ "Terms and Conditions"
  end

  test "GET /privacy_policy", %{conn: conn} do
    conn = get(conn, "/privacy_policy")
    assert html_response(conn, 200) =~ "Privacy Policy"
  end
end
