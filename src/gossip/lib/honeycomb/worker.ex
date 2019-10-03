defmodule Honeycomb.Worker do

  use GenServer

  #public API
  def start_link(x) do
    GenServer.start_link(__MODULE__, x)
  end

  def update_nbors(self_pid, t, disp_pid, agnt_pid, main_pid, frbdn) do
    #fetch co_ords
    co_ords=fetch_co_ords(t, self_pid, disp_pid, agnt_pid, frbdn, nil)

    #fetch nbors
    nbors=find_nbors(
      co_ords,
      (if rem(elem(co_ords, 0)+elem(co_ords, 1), 2)==0, do: 1, else: -1),
      frbdn,
      t,
      nil
    )

    #remove deadlocks
    num=6*(ceil(:math.pow(t+1, 2)))
    remove_deadlocks(disp_pid, num, num-Honeycomb.Dispenser.get_done_num(disp_pid))

    nbor_dir=mk_nbor_dir(agnt_pid, nbors, [main_pid], Enum.count(nbors))

    GenServer.cast(self_pid, {:update_state, nbor_dir})
  end

  def fetch_co_ords(num, self_pid, disp_pid, agnt_pid, frbdn, nil) do
    co_ords=gen_rand_co_ords(num, frbdn, nil)

    #dispenser check and recurse
    fetch_co_ords(
      num,
      self_pid,
      disp_pid,
      agnt_pid,
      frbdn,
      Honeycomb.Dispenser.chk_co_ord(disp_pid, co_ords, agnt_pid, self_pid)
    )
  end
  def fetch_co_ords(_num, _self_pid, _disp_pid, _agnt_pid, _frbdn, co_ords), do: co_ords

  def frbdn?(co_ords, frbdn, t) do
    x=elem(co_ords, 0)
    y=elem(co_ords, 1)
    max_x= 2*t+1
    max_y= 4*t+2
    if (x in elem(frbdn, 0) and y in elem(frbdn, 1)) or (x<0 or x>max_x) or (y<0 or y>max_y) do
      nil
    else
      co_ords
    end
  end

  def gen_rand_co_ords(num, frbdn, nil) do
    co_ords={
      Salty.Random.uniform(2*(num)+2),
      Salty.Random.uniform(4*(num)+3)
    }

    #primitive checks
    gen_rand_co_ords(num, frbdn, frbdn?(co_ords, frbdn, num))
  end
  def gen_rand_co_ords(_num, _frbdn, co_ords), do: co_ords

  def find_nbors(co_ords, flag, frbdn, t, nil) do
    find_nbors(
      co_ords,
      flag,
      frbdn,
      t,
      [
        frbdn?({elem(co_ords, 0)+flag, elem(co_ords, 1)}, frbdn, t),
        frbdn?({elem(co_ords, 0), elem(co_ords, 1)+1}, frbdn, t),
        frbdn?({elem(co_ords, 0), elem(co_ords, 1)-1}, frbdn, t)
      ]
    )
  end
  def find_nbors(_co_ords, _flag, _frbdn, _t, nbors), do: Enum.filter(nbors, fn(x)->!is_nil(x) end)

  def remove_deadlocks(_disp_pid, _num, 0), do: :ok
  def remove_deadlocks(disp_pid, num, _dlta) do
    remove_deadlocks(disp_pid, num, num-Honeycomb.Dispenser.get_done_num(disp_pid))
  end

  def mk_nbor_dir(_agnt_pid, _nbors, nbor_dir, 0), do: Enum.filter(nbor_dir, fn(x)-> !is_nil(x) end)
  def mk_nbor_dir(agnt_pid, nbors, nbor_dir, count) do
    nbor_pid=Agent.get(agnt_pid, &Map.get(&1, Enum.at(nbors, count-1)))
        mk_nbor_dir(
          agnt_pid,
          nbors,
          nbor_dir++[nbor_pid],
          count-1
        )
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

  def reset_round(of) do
    GenServer.cast(of, :half_s_w)
  end

  def get_s_w(of) do
    GenServer.call(of, :get_s_w)
  end

  def half_s_w(of) do
    GenServer.cast(of, :half_s_w)
  end

  def converge(of) do
    [main_pid| _]=get_nbors(of)
    Honeycomb.converged(main_pid)
  end

  #callbacks
  @impl true
  def init(pos) do
    {:ok, {0, {pos, 1}}}
  end

  @impl true
  def handle_cast({:update_state, nbors}, {n_round, ratio}) do
    {:noreply, {nbors, n_round, ratio}}
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
