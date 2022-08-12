defmodule Quizzaz.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias :mnesia, as: Mnesia

  @impl true
  def start(_type, _args) do
    start_mnesia()

    children = [
      # Start the Ecto repository
      Quizzaz.Repo,
      # Start the Telemetry supervisor
      QuizzazWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Quizzaz.PubSub},
      # Start the Endpoint (http/https)
      QuizzazWeb.Endpoint,
      # registry for GameSessions
      {Horde.Registry, keys: :unique, name: GameSessionRegistry},
      # dynamic supervisor for game sessions
      {Horde.DynamicSupervisor, strategy: :one_for_one, name: GameSessionSupervisor},
      # Registry of running game sessions
      #{Quizzaz.GameSessions.RunningSessionsServer, MapSet.new()},
      # Player Monitor
      #{Quizzaz.GameSessions.PlayerMonitor, %{}}
      # Start a worker by calling: Quizzaz.Worker.start_link(arg)
      # {Quizzaz.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Quizzaz.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_mnesia() do
    Mnesia.stop()
    Mnesia.create_schema([node()])
    Mnesia.start()
    Mnesia.create_table(GameSessions, attributes: [:id, :name])
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    QuizzazWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
