defmodule Line.Worker do

  use GenServer

  #public API
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [:debug])
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

  def converge(of) do
    [main_pid|_]=get_nbors(of)
    Line.converged(main_pid)
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:update_nbor_state, nbors}, _state) do
    {:noreply, {nbors, 0}}
  end

  @impl true
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
