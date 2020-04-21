defmodule BitcoinphoenixWeb.BitcoinphoenixController do
  use BitcoinphoenixWeb, :controller
  #use Drab.Controller, commanders: [BitcoinSimulatorWeb.NavbarCommander]

  #alias BitcoinSimulator.Simulation.Monitor
  alias Bitcoin.Main
  def index(conn, _params) do
    #Process.register Observer.newObserver(), :observer
    {client_list, miner_list} = Bitcoin.Main.setup_nodes()
    b=Enum.random(client_list)
    try do
      Process.register(b, :nakk)
    rescue
      _ -> Process.unregister(:nakk)
      Process.register(b, :nakk)
    end
    Bitcoin.Main.startSimulation(client_list, miner_list, 5)
    conn
    |> assign(:peer_count, 100)
    # |> assign(:trader_count, GenServer.call(Monitor, {:stat, :trader_count}))
    # |> assign(:miner_count, GenServer.call(Monitor, {:stat, :miner_count}))
    # |> assign(:trading_interval, GenServer.call(Monitor, {:stat, :trading_interval}))
    # |> assign(:blockchain_height, GenServer.call(Monitor, {:stat, :blockchain_height}))
    # |> assign(:difficulty, GenServer.call(Monitor, {:stat, :difficulty}))
    # |> assign(:net_worth, GenServer.call(Monitor, {:stat, :net_worth}))
    |> render("index.html")
    #render(conn, "index.html")
  end
  def fetch_data() do
    GenServer.call(:nakk, {:get_chain_data},1000000)
  end
end

