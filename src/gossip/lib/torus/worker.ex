defmodule Torus.Worker do

  use GenServer

  #public API
  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def update_state(self_pid, num, agnt_pid, disp_pid, main_pid) do
    #find co_ordinates
    co_ords=fetch_co_ords(num, self_pid, agnt_pid, disp_pid, nil)

    #fetch neighbors
    nbor_co_ords=calc_nbor_co_ords(
      num,
      co_ords,
      [
        {-1, 0, 0},
        {+1, 0, 0},
        {0, -1, 0},
        {0, +1, 0},
        {0, 0, -1},
        {0, 0, +1}
      ],
      [],
      0
    )
    n3=ceil(:math.pow(num, 3))
    remove_deadlocks(disp_pid, n3, n3-Torus.Dispenser.get_done_count(disp_pid))
    nbor_dir=fetch_nbors(nbor_co_ords, agnt_pid, [main_pid], 0)
    GenServer.cast(self_pid, {:update_state, nbor_dir})
  end

  def fetch_co_ords(num, self_pid, agnt_pid, disp_pid, nil) do
    fetch_co_ords(num,
      self_pid,
      agnt_pid,
      disp_pid,
      Torus.Dispenser.chk_co_cord(disp_pid,
        {Salty.Random.uniform(num), Salty.Random.uniform(num), Salty.Random.uniform(num)},
        agnt_pid, self_pid))
  end
  def fetch_co_ords(_num, _self_pid,  _agnt_pid, _disp_pid, co_ords), do: co_ords

  def calc_nbor_co_ords(_num, _co_ords, _dlta_mat, nbor_co_ords, 6), do: nbor_co_ords
  def calc_nbor_co_ords(num, co_ords, dlta_mat, nbor_co_ords, count) do
    new_nbor_co_ords=nbor_co_ords++[{
        calc_mirror(num, elem(co_ords, 0)+elem(Enum.at(dlta_mat, count), 0)),
        calc_mirror(num, elem(co_ords, 1)+elem(Enum.at(dlta_mat, count), 1)),
        calc_mirror(num, elem(co_ords, 2)+elem(Enum.at(dlta_mat, count), 2)),
      }]
    calc_nbor_co_ords(num, co_ords, dlta_mat, new_nbor_co_ords, count+1)
  end

  def calc_mirror(num, n) when n<0, do: num-1
  def calc_mirror(num, n) when n>num-1, do: 0
  def calc_mirror(_num, n), do: n

  def remove_deadlocks(_disp_pid, _num, 0), do: :ok
  def remove_deadlocks(disp_pid, num, _dlta) do
    remove_deadlocks(disp_pid, num, num-Torus.Dispenser.get_done_count(disp_pid))
  end

  def fetch_nbors(_nbor_co_ords, _agnt_pid, nbor_dir, 6), do: nbor_dir
  def fetch_nbors(nbor_co_ords,
    agnt_pid, nbor_dir, count) do

      nbor_pid=Agent.get(agnt_pid,
        &Map.get(&1, Enum.at(nbor_co_ords, count)))
    case nbor_pid do
      nil->
        fetch_nbors(nbor_co_ords, agnt_pid, nbor_dir, count)
      _->
        fetch_nbors(nbor_co_ords, agnt_pid,
          nbor_dir++[nbor_pid],
          count+1
        )
    end
  end

  def inc_round(of) do
    GenServer.cast(of, :inc_round)
  end

  def get_round(of) do
    GenServer.call(of, :get_round)
  end

  def get_nbors(of) do
    GenServer.call(of, :get_nbors)
  end

  def converge(of) do
    [main_pid|_]=get_nbors(of)
    Torus.converged(main_pid)
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:update_state, state}, _) do
    {:noreply, {state, 0}}
  end

  @impl true
  def handle_cast(:inc_round, state) do
    {:noreply, {elem(state, 0), elem(state , 1)+1}}
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
