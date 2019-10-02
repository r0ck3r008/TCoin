defmodule Full.Worker do

  use GenServer

  def start_link(x) do
    GenServer.start_link(__MODULE__, x)
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

  def get_s_w(of) do
    GenServer.call(of, :get_s_w)
  end

  def half_s_w(of) do
    GenServer.cast(of, :half_s_w)
  end

  def reset_round(of) do
    GenServer.cast(of, :reset_round)
  end

  def converge(of) do
    inc_round(of)
    [main_pid|_]=get_nbors(of)
    Full.converged(main_pid)
  end

  #callbacks
  @impl true
  def init(pos) do
    {:ok, {0, {pos, 1}}}
  end

  @impl true
  def handle_cast({:update_state, new_state}, {n_round, ratio}) do
    {:noreply, {new_state, n_round, ratio}}
  end

  @impl true
  def handle_cast(:inc_round, {nbors, n_round, ratio}) do
    {:noreply, {nbors, n_round+1, ratio}}
  end

  @impl true
  def handle_cast(:reset_round, {nbors, _n_round, ratio}) do
    {:noreply, {nbors, 0, ratio}}
  end

  @impl true
  def handle_cast(:half_s_w, {nbors, n_round, {s, w}}) do
    {:noreply, {nbors, n_round, {s/2, w/2}}}
  end

  @impl true
  def handle_call(:get_nbors, _from, state) do
    {:reply, elem(state, 0), state}
  end

  @impl true
  def handle_call(:get_round, _from, state) do
    {:reply, elem(state, 1), state}
  end

  @impl true
  def handle_call(:get_s_w, _from, {nbors, n_round, s_w}) do
    {:reply, s_w, {nbors, n_round, s_w}}
  end

end
