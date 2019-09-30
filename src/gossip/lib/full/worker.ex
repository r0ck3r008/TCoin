defmodule Full.Worker do

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def update_nbors(self_pid, agnt_pid, main_pid) do
    #get neighbours
    nbors=Agent.get(agnt_pid, fn(state)->state end)

    #update state
    GenServer.cast(self_pid, {:update_state, [main_pid]++nbors})
  end

  def get_nbors(of) do
    GenServer.call(of, :get_nbors)
  end

  def inc_round(of) do
    GenServer.cast(of, :inc_round)
  end

  def get_round(of) do
    GenServer.call(of, :get_round)
  end

  def converge(of) do
    [main_pid|_]=get_nbors(of)
    Full.converged(main_pid)
    GenServer.stop(of, :normal)
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:update_state, new_state}, _state) do
    {:noreply, {new_state, 0}}
  end

  def handle_cast(:inc_round, state) do
    {:noreply, {elem(state, 0), elem(state, 1)+1}}
  end

  @impl true
  def handle_call(:get_nbors, _from, state) do
    {:reply, elem(state, 0), state}
  end

  @impl true
  def handle_call(:get_round, _from, state) do
    {:reply, elem(state, 1), state}
  end

end
