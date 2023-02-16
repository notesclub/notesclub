defmodule Notesclub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Attach the LiveView Telemetry handlers
    Appsignal.Phoenix.LiveView.attach()

    children = [
      # Start the Ecto repository
      Notesclub.Repo,
      # Start the Telemetry supervisor
      NotesclubWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Notesclub.PubSub},
      # Start the Endpoint (http/https)
      NotesclubWeb.Endpoint,
      # Cron scheduler
      Notesclub.Scheduler,
      # Oban
      {Oban, Application.fetch_env!(:notesclub, Oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Notesclub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NotesclubWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
