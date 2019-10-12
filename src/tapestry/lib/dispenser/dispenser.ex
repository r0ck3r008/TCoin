defmodule Tapestry.Dispenser do

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def assign_hash(to, caller, hash) do
    GenServer.cast(to, {:assign_hash, caller, hash})
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
  def handle_cast({:assign_hash, caller, hash}, {map, assigned}) do
    {:noreply, {Map.put(map, caller, hash), assigned+1}}
  end

  @impl true
  def handle_call(:fetch_assigned, _from, {map, assigned}) do
    {:reply, assigned, {map, assigned}}
  end

  @impl true
  def terminate(_, _) do
    IO.puts "Terminating Dispenser"
  end

end
