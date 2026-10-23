defmodule NotesclubWeb.SessionControllerTest do
  use NotesclubWeb.ConnCase

  alias NotesclubWeb.AuthController

  test "administrative OAuth setup requires HTTP basic authentication", %{conn: conn} do
    keys = ["NOTESCLUB_OBAN_WEB_DASHBOARD_USERNAME", "NOTESCLUB_OBAN_WEB_DASHBOARD_PASSWORD"]
    previous = Enum.map(keys, &{&1, System.get_env(&1)})
    Enum.each(keys, &System.put_env(&1, "test-credential"))

    on_exit(fn ->
      Enum.each(previous, fn
        {key, nil} -> System.delete_env(key)
        {key, value} -> System.put_env(key, value)
      end)
    end)

    assert conn |> get("/x/signin") |> response(401) =~ "Unauthorized"
    assert conn |> get("/oban/anything.png") |> response(401) =~ "Unauthorized"

    authenticated =
      conn
      |> put_req_header(
        "authorization",
        "Basic " <> Base.encode64("test-credential:test-credential")
      )
      |> get("/x/signin")

    assert redirected_to(authenticated) =~ "https://twitter.com/i/oauth2/authorize?"
    assert is_binary(get_session(authenticated, :x_oauth_state))
  end

  test "stores the return path and drops the session on signout", %{conn: conn} do
    conn = post(conn, "/_return_to", %{path: "/tags/tutorial"})
    assert response(conn, 204) == ""
    assert get_session(conn, :return_to) == "/tags/tutorial"
    conn = post(recycle(conn), "/auth/signout")
    assert redirected_to(conn) == "/"
    assert conn.private.plug_session_info == :drop
  end

  test "rejects unsafe return paths", %{conn: conn} do
    for path <- [
          "https://example.com",
          "//example.com",
          "/%2fexample.com",
          "/\\example.com",
          "/path\nheader",
          "/" <> String.duplicate("a", 2_048)
        ] do
      rejected = post(recycle(conn), "/_return_to", %{path: path})
      assert response(rejected, 422) == "invalid return path"
      assert get_session(rejected, :return_to) == nil
    end
  end

  test "rejects missing and non-string return paths", %{conn: conn} do
    for params <- [%{}, %{path: nil}, %{path: ["/"]}] do
      rejected = post(recycle(conn), "/_return_to", params)
      assert response(rejected, 422) == "invalid return path"
    end
  end

  test "does not allow logout via GET", %{conn: conn} do
    conn = conn |> init_test_session(%{user_id: 123}) |> get("/auth/signout")

    assert get_session(conn, :user_id) == 123
    refute conn.private.plug_session_info == :drop
  end

  test "rejects callbacks with missing or non-string OAuth state", %{conn: conn} do
    for params <- [%{}, %{"code" => "code", "state" => nil}] do
      result =
        conn
        |> bypass_through(NotesclubWeb.Router, [:browser])
        |> get("/x/callback")
        |> AuthController.botcallback(params)

      assert Phoenix.Flash.get(result.assigns.flash, :error) == "Failed to authenticate with X."
      assert redirected_to(result) == "/"
    end
  end

  test "relative notebook image requests are intercepted", %{conn: conn} do
    assert conn |> get("/author/repo/images/example.PNG") |> response(200) == "OK"
  end
end
