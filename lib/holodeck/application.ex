defmodule Holodeck.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    HolodeckWeb.LogBroadcaster.attach()

    children = [
      HolodeckWeb.Telemetry,
      Holodeck.Repo,
      {DNSCluster, query: Application.get_env(:holodeck, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Holodeck.PubSub},
      # Start a worker by calling: Holodeck.Worker.start_link(arg)
      # {Holodeck.Worker, arg},
      # Start to serve requests, typically the last entry
      HolodeckWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Holodeck.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HolodeckWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
