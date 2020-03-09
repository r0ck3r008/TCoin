defmodule Tcoin.Net.Node do

  use GenServer
  require Logger
  alias Tcoin.Net.Node.Utils
  alias Tcoin.Net.Node.Route

  def start_link do
    {:ok, state_agnt}=Agent.start_link(fn-> %{} end)
    {:ok, store_agnt}=Agent.start_link(fn-> [] end)
    {:ok, self_pid}=GenServer.start_link(__MODULE__, {state_agnt, store_agnt})
    GenServer.cast(self_pid, :update_hash)
    {:ok, self_pid}
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast(:update_hash, {state_agnt, store_agnt}) do
    hash=Utils.hash_it(inspect self())
    Agent.update(
      state_agnt,
      &Map.put(&1, String.to_atom("lvl#{String.length(hash)}"), [{hash, self()}])
    )
    {:noreply, {state_agnt, store_agnt, hash}}
  end

  @impl true
  def handle_cast({:add_node, new_node}, {state_agnt, store_agnt, hash}) do
    nbors=Agent.get(state_agnt, fn(state)->state end)
    Route.broadcast(new_node, nbors)
    {:noreply, {state_agnt, store_agnt, hash}}
  end

  @impl true
  def handle_info({:new_node, new_node}, {state_agnt, store_agnt, hash}) do
    Utils.update_nbors({state_agnt, hash}, new_node)
    send(new_node, {:welcome, self()})
    {:noreply, {state_agnt, store_agnt, hash}}
  end

  @impl true
  def handle_info({:welcome, greeter}, {state_agnt, store_agnt, hash}) do
    Utils.update_nbors({state_agnt, hash}, greeter)
    {:noreply, {state_agnt, store_agnt, hash}}
  end

  @impl true
  def handle_cast({:publish, obj, obj_hash}, {state_agnt, store_agnt, hash}) do
    Utils.publish({state_agnt, store_agnt, hash}, {obj_hash, obj}, 0)
    {:noreply, {state_agnt, store_agnt, hash}}
  end

  @impl true
  def handle_info({:publish, {obj_hash, payload}, 5}, state) do
    Utils.publish(state, {obj_hash, payload}, 5)
    {:noreply, state}
  end

  @impl true
  def handle_info({:publish, pointer, hops}, state) do
    Utils.publish(state, pointer, hops+1)
    {:noreply, state}
  end

end
