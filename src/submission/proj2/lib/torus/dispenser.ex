defmodule Torus.Dispenser do

  use GenServer

  #public API
  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def chk_co_cord(to, co_ords, agnt_pid, caller) do
    GenServer.call(to, {:chk_co_ords, agnt_pid, co_ords, caller})
  end

  #here we avoid deadlocks
  def inc_done_count(self_pid) do
    GenServer.cast(self_pid, :inc_done_count)
  end

  def get_done_count(self_pid) do
    GenServer.call(self_pid, :get_done_count)
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, 0}
  end

  @impl true
  def handle_cast(:inc_done_count, state) do
    {:noreply, state+1}
  end

  @impl true
  def handle_call({:chk_co_ords, agnt_pid, co_ords, caller}, _from, state) do
    {
      :reply,
      (
        case Agent.get(agnt_pid, &Map.get(&1, co_ords)) do
          nil->
            inc_done_count(self())
            Agent.update(agnt_pid, &Map.put(&1, co_ords, caller))
            co_ords
          _->
            nil
        end
      ),
      state
    }
  end

  @impl true
  def handle_call(:get_done_count, _from, state) do
    {:reply, state, state}
  end
end
