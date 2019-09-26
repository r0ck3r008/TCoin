defmodule Honeycomb.Worker do

  use GenServer

  #public API
  def start_link(num, disp_pid, agnt_pid, frbdn) do
    #fetch co_ords
    co_ords=fetch_co_ords(num, disp_pid, agnt_pid, frbdn, nil)

    #fecth nbors

    GenServer.start_link(__MODULE__, :ok)
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

  def gen_rand_co_ords(num, frbdn, nil) do
    co_ords={
      #-1 adjusted a rand doesnt generate 0
      :rand.uniform(2*(num-1)+1)-1,
      :rand.uniform(4*(num-1)+4)-1
    }

    #primitive checks
    if elem(co_ords, 0) in elem(frbdn, 0) and elem(co_ords, 1) in elem(frbdn, 1) do
      gen_rand_co_ords(num, frbdn, nil)
    else
      gen_rand_co_ords(num, frbdn, co_ords)
    end
  end
  def gen_rand_co_ords(_num, co_ords), do: co_ords

  #callbacks
  def init(:ok) do
    {:ok, []}
  end

end
