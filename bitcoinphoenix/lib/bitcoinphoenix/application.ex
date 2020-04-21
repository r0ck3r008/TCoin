defmodule Bitcoinphoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Bitcoinphoenix.Repo,
      # Start the endpoint when the application starts
      BitcoinphoenixWeb.Endpoint
      # Starts a worker by calling: Bitcoinphoenix.Worker.start_link(arg)
      # {Bitcoinphoenix.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bitcoinphoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BitcoinphoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
