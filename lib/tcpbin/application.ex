defmodule Tcpbin.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TcpbinWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:tcpbin, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Tcpbin.PubSub},
      {Registry, name: Registry, keys: :unique},
      # Start a worker by calling: Tcpbin.Worker.start_link(arg)
      # {Tcpbin.Worker, arg},
      # Start to serve requests, typically the last entry
      TcpbinWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tcpbin.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TcpbinWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
