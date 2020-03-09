defmodule Tcoin.Net.Node do

  use GenServer
  require Logger
  alias Tcoin.Net.Node.Utils
  alias Tcoin.Net.Node.Route

  def start_link do
    {:ok, state_agnt}=Agent.start_link(fn-> %{} end)
    {:ok, self_pid}=GenServer.start_link(__MODULE__, state_agnt)
    GenServer.cast(self_pid, :update_hash)
    {:ok, self_pid}
  end

  @impl true
  def init(state_agnt) do
    {:ok, {state_agnt}}
  end

  @impl true
  def handle_cast(:update_hash, {state_agnt}) do
    hash=Utils.hash_it(inspect self())
    Agent.update(
      state_agnt,
      &Map.put(&1, String.to_atom("lvl#{String.length(hash)}"), [{hash, self()}])
    )
    {:noreply, {state_agnt, hash}}
  end

  @impl true
  def handle_cast({:add_node, new_node}, {state_agnt, hash}) do
    nbors=Agent.get(state_agnt, fn(state)->state end)
    Route.broadcast(new_node, nbors)
    {:noreply, {state_agnt, hash}}
  end

  @impl true
  def handle_info({:new_node, new_node}, state) do
    Utils.update_nbors(state, new_node)
    send(new_node, {:welcome, self()})
    {:noreply, state}
  end

  @impl true
  def handle_info({:welcome, greeter}, state) do
    Utils.update_nbors(state, greeter)
    {:noreply, state}
  end

end
