defmodule Tcoin.Net.Dispenser do

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def assign_hash(to, caller, hash) do
    GenServer.call(to, {:assign_hash, caller, hash})
  end

  def fetch_assigned(to) do
    GenServer.call(to, :fetch_assigned)
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, {%{}, 0}}
  end

  @impl true
  def handle_call({:assign_hash, caller, hash}, _from, {map, assigned}) do
    {:reply, hash, {Map.put(map, hash, caller), assigned+1}}
  end

  @impl true
  def handle_call(:fetch_assigned, _from, {map, assigned}) do
    {:reply, assigned, {map, assigned}}
  end

  @impl true
  def handle_call(:get_map, _from, {map, assigned}) do
    {:reply, map, {map, assigned}}
  end

  @impl true
  def handle_cast(:dec_assigned, {map, assigned}) do
    {:noreply, {map, assigned-1}}
  end

  @impl true
  def terminate(_, _) do
    IO.puts "Terminating Dispenser"
  end

end
