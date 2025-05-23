defmodule Notesclub.MixProject do
  use Mix.Project

  def project do
    [
      app: :notesclub,
      version: "0.1.0",
      elixir: "~> 1.16.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:yecc] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Notesclub.Application, []},
      extra_applications: [:logger, :runtime_tools, :ssl]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    core_deps() ++ oban_pro_deps()
  end

  defp core_deps do
    [
      {:phoenix, "~> 1.7.21"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.7"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.0.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_view, "~> 2.0.3"},
      {:phoenix_live_reload, "~> 1.4.1", only: :dev},
      {:phoenix_live_view, "~> 1.0.11"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.7.1"},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:req, "~> 0.5"},
      {:mock, "~> 0.3.7"},
      {:appsignal, "~> 2.15.5"},
      {:appsignal_phoenix, "~> 2.7.0"},
      {:faker, "~> 0.17", only: :test},
      {:oban, "2.19.4"},
      {:oban_web, "~> 2.11.3"},
      {:timex, "~> 3.0"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:redirect, "~> 0.4.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:typed_ecto_schema, "~> 0.4.1", runtime: false},
      {:earmark, "~> 1.4"},
      {:makeup, "~> 1.0"},
      {:makeup_elixir, "0.15.2"},
      {:html_sanitize_ex, "~> 1.4"},
      {:html_entities, "~> 0.5"},
      {:ueberauth, "~> 0.10"},
      {:ueberauth_github, "~> 0.8"},
      {:tidewave, "~> 0.1", only: :dev}
    ]
  end

  defp oban_pro_deps do
    if System.get_env("NOTESCLUB_IS_OBAN_PRO_ENABLED") == "true" do
      [{:oban_pro, "~> 1.5.4", repo: "oban"}]
    else
      []
    end
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
