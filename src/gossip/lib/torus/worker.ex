defmodule Torus.Worker do

  use GenServer

  #public API
  def start_link(num, agnt_pid, disp_pid) do
    #find co_ordinates
    co_ords=fetch_co_ords(num, agnt_pid, disp_pid, nil)

    #fetch neighbors
    nbor_co_ords=calc_nbor_co_ords(
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
    nbor_dir=fetch_nbors(nbor_co_ords, agnt_pid, %{co_ords=>self()}, 0)

    GenServer.start_link(__MODULE__, nbor_dir)
  end

  def fetch_co_ords(num, agnt_pid, disp_pid, nil) do
    fetch_co_ords(num,
      agnt_pid,
      disp_pid,
      Torus.Dispenser.chk_co_cord(disp_pid,
        {:rand.unifrom(num), :rand.uniform(num), :rand.uniform(num)},
        agnt_pid, self()))
  end
  def fetch_co_ords(_num, _agnt_pid, _disp_pid, co_ords), do: co_ords

  def calc_nbor_co_ords(_num, _co_ords, _dlta_mat, nbor_co_ords, 6), do: nbor_co_ords
  def calc_nbor_co_ords(num, co_ords, dlta_mat, nbor_co_ords, count) do
    calc_nbor_co_ords(num, co_ords, dlta_mat,
      nbor_co_ords++[{
        calc_mirror(num, elem(co_ords, 0)+elem(Enum.at(dlta_mat, 0), count)),
        calc_mirror(num, elem(co_ords, 0)+elem(Enum.at(dlta_mat, 0), count)),
        calc_mirror(num, elem(co_ords, 0)+elem(Enum.at(dlta_mat, 0), count)),
      }], count+1)
  end

  def calc_mirror(num, n) when n<0, do: num-1
  def calc_mirror(num, n) when n>num-1, do: 0
  def calc_mirror(num, n), do: n

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
          Map.put(nbor_dir, Enum.at(nbor_co_ords, count), nbor_pid),
          count+1
        )
    end
  end

  #callbacks
  @impl true
  def init(nbor_dir) do
    {:ok, nbor_dir}
  end

end
