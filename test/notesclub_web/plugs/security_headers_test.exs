defmodule NotesclubWeb.Plugs.SecurityHeadersTest do
  use NotesclubWeb.ConnCase

  alias NotesclubWeb.Plugs.SecurityHeaders

  test "browser responses restrict scripts and attach a fresh nonce to trusted inline scripts", %{
    conn: conn
  } do
    conn = get(conn, "/terms")
    [policy] = get_resp_header(conn, "content-security-policy")
    nonce = conn.assigns.csp_nonce
    [script_policy] = Regex.run(~r/script-src[^;]+/, policy)

    assert byte_size(Base.decode64!(nonce)) == 24
    assert script_policy =~ "'nonce-#{nonce}'"
    refute script_policy =~ "'unsafe-inline'"
    refute script_policy =~ "'unsafe-eval'"
    assert policy =~ "object-src 'none'"
    assert policy =~ "base-uri 'self'"
    assert policy =~ "frame-ancestors 'self'"
    assert policy =~ "form-action 'self'"
    assert get_resp_header(conn, "x-content-type-options") == ["nosniff"]

    html = html_response(conn, 200)
    assert html =~ "sha384-A/+e8MGB5ruM9qUEz7ST0YKPo2TLEwdHhBIZL1Ii9jqCGKR2ZwLKc6ArNahGzYOV"
    assert html =~ ~s(crossorigin="anonymous")
    refute html =~ "cdn.jsdelivr.net"
    refute policy =~ "cdn.jsdelivr.net"

    other_conn = get(build_conn(), "/terms")
    refute other_conn.assigns.csp_nonce == nonce
  end

  test "error layouts without a nonce render without enabling inline scripts" do
    html =
      Phoenix.View.render_to_string(NotesclubWeb.LayoutView, "root.html",
        conn: put_private(build_conn(), :phoenix_endpoint, @endpoint),
        inner_content: "An error occurred",
        page_title: "Error"
      )

    assert html =~ "An error occurred"
    refute html =~ "customElements.define"
  end

  test "websocket connections are restricted to the serving origin" do
    for {url, websocket} <- [
          {"https://notes.club/", "wss://notes.club"},
          {"http://localhost:4000/", "ws://localhost:4000"}
        ] do
      conn =
        :get
        |> Plug.Test.conn(url)
        |> SecurityHeaders.call([])

      [policy] = get_resp_header(conn, "content-security-policy")
      assert policy =~ "connect-src 'self' #{websocket} https://plausible.io"
    end
  end

  test "LiveDashboard receives the nonce for its inline scripts", %{conn: conn} do
    conn = get(conn, "/dashboard/home")
    html = html_response(conn, 200)

    assert html =~ ~s(nonce="#{conn.assigns.csp_nonce}")
    assert conn.private.csp_nonce_assign_key.script == :csp_nonce
  end
end
