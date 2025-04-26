# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :notesclub,
  ecto_repos: [Notesclub.Repo]

# Configures the endpoint
config :notesclub, NotesclubWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: NotesclubWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Notesclub.PubSub,
  live_view: [signing_salt: "IhLlFkQ5"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :notesclub, Notesclub.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tailwind,
  version: "3.1.8",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
    cd: Path.expand("../assets", __DIR__)
  ]

if System.get_env("NOTESCLUB_IS_OBAN_WEB_PRO_ENABLED") == "true" do
  config :notesclub, Oban,
    engine: Oban.Pro.Engines.Smart,
    repo: Notesclub.Repo,
    plugins: [
      {Oban.Plugins.Cron,
       crontab: [
         {"0 2 * * *", Notesclub.Workers.AllUserNotebooksSyncWorker, queue: :default},
         {"0 0 * * *", Notesclub.Workers.AllUsersSyncWorker, queue: :default},
         {"0 7 * * *", Notesclub.Workers.RecentNotebooksWorker, args: %{"page" => 1}},
         {"0 */8 * * *", Notesclub.Workers.XScheduledPostWorker, queue: :default}
       ]},
      {Oban.Pro.Plugins.DynamicPruner,
       state_overrides: [
         completed: {:max_age, {5, :minutes}},
         cancelled: {:max_age, {1, :month}},
         discarded: {:max_age, {1, :month}}
       ]},
      Oban.Pro.Plugins.DynamicLifeline
    ],
    queues: [
      default: 10,
      # Github REST API allows us to make 5000 req/h = 83 req/min
      github_rest: [global_limit: 10, rate_limit: [allowed: 80, period: {1, :minute}]],
      # Github Search API allows us to make 10 req/min = 1 req every 6 seconds
      github_search: [global_limit: 1, rate_limit: [allowed: 1, period: {10, :second}]]
    ]
else
  config :notesclub, Oban,
    repo: Notesclub.Repo,
    plugins: [Oban.Plugins.Pruner],
    queues: [
      default: 10
    ]
end

if config_env() == :prod do
  config :appsignal, :config,
    revision: System.get_env("APP_REVISION"),
    ignore_errors: [
      "Ecto.NoResultsError"
    ]
end

config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, [default_scope: "user:email"]}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
