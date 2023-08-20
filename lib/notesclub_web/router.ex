defmodule NotesclubWeb.Router do
  use NotesclubWeb, :router

  import Redirect

  require Notesclub.Compile

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {NotesclubWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  Notesclub.Compile.only_if_loaded :oban_web do
    require Oban.Web.Router

    pipeline :oban_web_auth do
      plug(:auth)

      defp auth(conn, _opts) do
        username = System.fetch_env!("NOTESCLUB_OBAN_WEB_DASHBOARD_USERNAME")
        password = System.fetch_env!("NOTESCLUB_OBAN_WEB_DASHBOARD_PASSWORD")
        Plug.BasicAuth.basic_auth(conn, username: username, password: password)
      end
    end

    scope "/", NotesclubWeb do
      pipe_through([:browser, :oban_web_auth])

      Oban.Web.Router.oban_dashboard("/oban")
    end
  end

  redirect("/last_week", "/", :permanent)

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: NotesclubWeb.Telemetry)
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through(:browser)

      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  scope "/", NotesclubWeb do
    pipe_through(:browser)

    get("/status", StatusController, :status)

    live("/", NotebookLive.Index, :home)
    live("/search", NotebookLive.Index, :search)
    live("/random", NotebookLive.Index, :random)

    if Enum.any?([:dev, :test], fn env -> Mix.env() == env end) do
      get("/dummy/raise_error", DummyErrorController, :raise_error)
    end

    live("/hex/:package", NotebookLive.Index, :package)
    live("/:author", NotebookLive.Index, :author)
    live("/:author/:repo", NotebookLive.Index, :repo)
    live("/*file", NotebookLive.Show, :show)
  end
end
