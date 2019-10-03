defmodule Honeycomb.Dispenser do

  use GenServer

  #public API
  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def chk_co_ord(to, co_ords, agnt_pid, caller) do
    GenServer.call(to, {:chk_co_ords, agnt_pid, co_ords, caller})
  end

  def inc_done_num(of) do
    GenServer.cast(of, :inc_done_num)
  end

  def get_done_num(of) do
    GenServer.call(of, :get_done_num)
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, 0}
  end

  @impl true
  def handle_cast(:inc_done_num, state) do
    {:noreply, state+1}
  end

  @impl true
  def handle_call({:chk_co_ords, agnt_pid, co_ords, caller}, _from, state) do
    {
      :reply,
      (
        case Agent.get(agnt_pid, &Map.get(&1, co_ords)) do
          nil->
            inc_done_num(self())
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
  def handle_call(:get_done_num, _from, state) do
    {:reply, state, state}
  end
end
