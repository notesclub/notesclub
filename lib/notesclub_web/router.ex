defmodule NotesclubWeb.Router do
  use NotesclubWeb, :router

  import Oban.Web.Router
  import Redirect
  import NotesclubWeb.UserAuth

  alias NotesclubWeb.Plugs.AssetInterceptor

  require Notesclub.Compile

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {NotesclubWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)

    plug AssetInterceptor
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :admin_auth do
    plug(:auth)

    defp auth(conn, _opts) do
      username = System.fetch_env!("NOTESCLUB_OBAN_WEB_DASHBOARD_USERNAME")
      password = System.fetch_env!("NOTESCLUB_OBAN_WEB_DASHBOARD_PASSWORD")
      Plug.BasicAuth.basic_auth(conn, username: username, password: password)
    end
  end

  scope "/", NotesclubWeb do
    pipe_through([:browser, :admin_auth])

    oban_dashboard("/oban")

    get("/x/signin", AuthController, :botsignin)
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

  scope "/auth", NotesclubWeb do
    pipe_through([:browser])

    get("/signout", AuthController, :signout)
    get("/:provider", AuthController, :request)
    get("/:provider/callback", AuthController, :callback)
  end

  scope "/", NotesclubWeb do
    pipe_through(:browser)

    get("/x/callback", AuthController, :botcallback)

    get("/status", StatusController, :status)
    get("/packages_sitemap.xml", SitemapController, :packages_sitemap)
    get("/clapped_notebooks_sitemap.xml", SitemapController, :clapped_notebooks_sitemap)
    get("/terms", PageController, :terms)
    get("/privacy_policy", PageController, :privacy_policy)
    post("/_return_to", ReturnToController, :create)

    if Enum.any?([:dev, :test], fn env -> Mix.env() == env end) do
      get("/dummy/raise_error", DummyErrorController, :raise_error)
    end

    live_session(:current_user, on_mount: [{NotesclubWeb.UserAuth, :mount_current_user}]) do
      live("/", NotebookLive.Index, :home)
      live("/search", NotebookLive.Index, :search)
      live("/random", NotebookLive.Index, :random)
      live("/top", NotebookLive.Index, :top)
      live("/hex/:package", NotebookLive.Index, :package)
      live("/:author", NotebookLive.Index, :author)
      live("/:username/stars", NotebookLive.Index, :stars)
      live("/:author/:repo", NotebookLive.Index, :repo)

      # Catch-all route for showing notebooks
      # Asset requests are intercepted by the AssetInterceptor plug earlier
      live("/*file", NotebookLive.Show, :show)
    end
  end
end
