defmodule Honeycomb_rand.Dispenser do

  use GenServer

  #public API
  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def chk_co_ord(to, co_ords, agnt_pid, caller) do
    {:reply, co_ords}=GenServer.call(to, {:chk_co_ord, agnt_pid, co_ords, caller})
    co_ords
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_call({:chk_co_ords, agnt_pid, co_ords, caller}, _from, _curr) do
    {
      :reply,
      (
        case Agent.get(agnt_pid, &Map.get(&1, co_ords)) do
          nil->
            Agent.update(agnt_pid, &Map.put(&1, co_ords, caller))
            {co_ords}
          _->
            nil
        end
      ),
      []
    }
  end

end
