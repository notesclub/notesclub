defmodule NotesclubWeb.Plugs.SecurityHeaders do
  @moduledoc """
  Adds a per-response Content Security Policy and a nonce for trusted inline scripts.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    nonce = Base.encode64(:crypto.strong_rand_bytes(24))
    websocket_scheme = if conn.scheme == :https, do: "wss", else: "ws"

    websocket_origin =
      URI.to_string(%URI{scheme: websocket_scheme, host: conn.host, port: conn.port})

    policy =
      Enum.join(
        [
          "default-src 'self'",
          "script-src 'self' 'nonce-#{nonce}' https://plausible.io/js/plausible.js",
          # Mermaid and the dashboards generate inline styles; scripts remain restricted.
          "style-src 'self' 'unsafe-inline'",
          "img-src 'self' data: https://avatars.githubusercontent.com " <>
            "https://github.com https://private-user-images.githubusercontent.com " <>
            "https://raw.githubusercontent.com https://user-images.githubusercontent.com",
          "font-src 'self' data:",
          "connect-src 'self' #{websocket_origin} https://plausible.io",
          "object-src 'none'",
          "base-uri 'self'",
          "form-action 'self'",
          "frame-ancestors 'self'"
        ],
        "; "
      )

    conn
    |> assign(:csp_nonce, nonce)
    |> put_resp_header("content-security-policy", policy)
  end
end
