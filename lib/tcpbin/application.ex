defmodule Tcpbin.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: Tcpbin.PubSub},
      {Registry, name: Registry, keys: :unique},
      # Start the Endpoint (http/https)
      TcpbinWeb.Endpoint
      # Start a worker by calling: Tcpbin.Worker.start_link(arg)
      # {Tcpbin.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tcpbin.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TcpbinWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
