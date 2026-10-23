defmodule NotesclubWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :notesclub

  # Production is HTTPS-only; development and test still need HTTP cookies.
  @session_options [
    store: :cookie,
    key: "_notesclub_key",
    signing_salt: "WuUjyTB7",
    encryption_salt: "K4HjZdpu",
    http_only: true,
    secure: Mix.env() == :prod,
    same_site: "Lax"
  ]

  def session_options, do: @session_options

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [check_origin: :conn, connect_info: [:peer_data, session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :notesclub,
    gzip: false,
    only: NotesclubWeb.static_paths()

  if Code.ensure_loaded?(Tidewave) do
    plug Tidewave
  end

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket,
      websocket: [check_origin: :conn]

    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :notesclub
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug NotesclubWeb.Router
end
