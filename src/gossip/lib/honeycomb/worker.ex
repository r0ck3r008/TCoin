defmodule Honeycomb.Worker do

  use GenServer

  #public API
  def start_link(num, disp_pid, agnt_pid, frbdn) do
    #fetch co_ords
    co_ords=fetch_co_ords(num, disp_pid, agnt_pid, frbdn, nil)

    #fetch nbors
    nbors=find_nbors(
      co_ords, 
      (if rem(elem(co_ords, 2))==0, do: 1, else: -1),
      frbdn,
      nil
    )
    nbors_dir=mk_nbor_dir(agnt_pid, nbors, %{co_ords=>self}, Enum.count(nbors))

    GenServer.start_link(__MODULE__, nbor_dir)
  end

  def fetch_co_ords(num, disp_pid, agnt_pid, frbdn, nil) do
    co_ords=gen_rand_co_ords(num, frbdn, nil)

    #dispenser check and recurse
    fetch_co_ords
    (
      num,
      disp_pid,
      agnt_pid,
      Honeycomb.Dispenser.chk_co_ords(disp_pid, co_ords, aagnt_pid, self())
    )
  end
  def fetch_co_ords(_num, _disp_pid, _agnt_pid, co_ords), do: co_ords

  def frbdn?(co_ords, frbdn) do
    if elem(co_ords, 0) in elem(frbdn, 0) and elem(co_ords, 1) in elem(frbdn, 1) do
      nil
    else
      co_ords
    end
  end

  def gen_rand_co_ords(num, frbdn, nil) do
    co_ords={
      #-1 adjusted a rand doesnt generate 0
      :rand.uniform(2*(num-1)+1)-1,
      :rand.uniform(4*(num-1)+4)-1
    }

    #primitive checks
    gen_rand_co_ords(num, frbdn, frbdn?(co_ords, frbdn))
  end
  def gen_rand_co_ords(_num, _frbdn, co_ords), do: co_ords

  def find_nbors(co_ords, flag, frbdn, nil) do
    find_nbors(
      co_ords,
      flag,
      [
        frbdn?({elem(co_ords, 0)+flag}, elem(co_ords, 1)}, frbdn),
        {elem(co_ords, 0), elem(co_ords, 1)+1},
        {elem(co_ords, 0), elem(co_ords, 1)-1}
      ]
    )
  end
  def find_nbors(_co_ords, _flag, frbdn, nbors), do: Enum.filter(nbors, fn(x)->!is_nil(x) end)

  def mk_nbor_dir(_agnt_pid, _nbors, nbor_dir, 0) do: nbor_dir
  def mk_nbor_dir(agnt_pid, nbors, nbor_dir, count) do
    nbor_pid=Agent.get(agnt_pid, &Map.get(&1, Enum.at(nbors, count-1)))
    case nbor_pid do
      nil->
        #the nbor is not updated yet
        mk_nbor_dir(
          agnt_pid, nbors, nbor_dir, count
        )
      _->
        #the nbor is now fetched
        mk_nbor_dir(
          agnt_pid,
          nbors,
          Map.put(nbor_dir, Enum.at(nbors, count-1), nbor_pid),
          count-1
        )
    end
  end

  #callbacks
  def init(nbor_dir) do
    {:ok, nbor_dir}
  end

end
