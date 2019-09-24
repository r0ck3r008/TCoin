defmodule Torus.Dispenser do

  use GenServer

  #public API
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_co_ord(num, agnt_pid, caller) do
    {:reply, co_ords, _}=GenServer.call({:fetch_co_ord, num})

    case Agent.get(agnt_pid, &Map.get(&1, co_ords)) do
      nil->
        Agent.update(agnt_pid, &Map.put(&1, co_ords, caller))
        co_ords
      _->
        nil
    end
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_call({:fetch_co_ords, num}, _from, _curr) do
    {
      :reply,
      {
        :rand.uniform(num), :rand.uniform(num), :rand.uniform(num)
      },
      []
    }

end
