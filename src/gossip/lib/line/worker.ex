defmodule Line.Worker do

  use GenServer

  #public API
  def start_link(x) do
    GenServer.start_link(__MODULE__, x)
  end

  def update_nbor_state(pid, pos, num, agnt_pid, main_pid) do
    nbor_co_ords=get_nbor_co_ords(pos, num, {-1, +1}, [], 0)
    GenServer.cast(pid, {
      :update_nbor_state,
      Enum.filter([
        main_pid,
        Agent.get(agnt_pid, &Map.get(&1, Enum.at(nbor_co_ords, 0))),
        Agent.get(agnt_pid, &Map.get(&1, Enum.at(nbor_co_ords, 1)))
      ], fn(x)-> !is_nil(x) end)
    })
  end

  def get_nbor_co_ords(0, num, dlta_mat, [], 0), do: get_nbor_co_ords(0, num, dlta_mat, [], 1)
  def get_nbor_co_ords(pos, num, _dlta_mat, [], 0) when pos == num-1, do: get_nbor_co_ords(pos, num, {-1, -1}, [], 1)
  def get_nbor_co_ords(_pos, _num, _dlta_mat, nbors, 2), do: nbors
  def get_nbor_co_ords(pos, num, dlta_mat, nbors, count) do
    get_nbor_co_ords(
      pos,
      num,
      dlta_mat,
      nbors++[pos+elem(dlta_mat, count)],
      count+1
    )
  end

  def get_nbors(of) do
    GenServer.call(of, :get_nbors)
  end

  def get_round(of) do
    GenServer.call(of, :get_round)
  end

  def inc_round(of) do
    GenServer.cast(of, :inc_round)
  end

  def get_s_w(of) do
    GenServer.call(of, :get_s_w)
  end

  def reset_round(of) do
    GenServer.cast(of, :reset_round)
  end

  def half_s_w(of) do
    GenServer.cast(of, :half_s_w)
  end

  def converge(of) do
    [main_pid|_]=get_nbors(of)
    Line.converged(main_pid)
  end

  #callbacks
  @impl true
  def init(pos) do
    {:ok, {0, {pos, 1}}}
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
  def handle_cast({:update_nbor_state, nbors}, {n_round, ratio}) do
    {:noreply, {nbors, n_round, ratio}}
  end

  @impl true
  def handle_cast(:inc_round, {nbors, n_round, ratio}) do
    {:noreply, {nbors, n_round+1, ratio}}
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
  def handle_call(:get_s_w, _from, {nbors, n_round, ratio}) do
    {:reply, ratio, {nbors, n_round, ratio}}
  end

end
