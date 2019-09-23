defmodule Torus do

  def main(n3) do
    #find cube root
    n=ceil(:math.pow(n3, :math.pow(3, -1)))
    chk_cube_rt(n3, n)

    #start agent
    {:ok, agnt_pid}=Agent.start_link(fn -> %{} end)

    #Start dispenser
    Dispenser.start_link(n)

    #fork workers
    for _x <- 1..n, do: Worker.start_link(agnt_pid)
  end

  def chk_cube_rt(n3, n) when rem(n3, n)==0, do: :ok
  def chk_cube_rt(n3, n) when rem(n3, n)==1, do: exit(:err)

end

defmodule Dispenser do

  use GenServer

  #extern API
  def start_link(num) do
    GenServer.start_link(__MODULE__, num, name: __MODULE__)
  end

  def find_co_ords(_num, agnt_pid, caller) do
    {:reply, _num, co_ords}=GenServer.call(__MODULE__, :find_co_ords)

    #check if it exists in db, if not append
    case Agent.get(agnt_pid, &Map.get(&1, co_ords)) do
      nil->
        Agent.update(agnt_pid, &Map.put(&1, co_ords, caller))
        co_ords
      _->
        nil
    end
  end

  #Callbacks
  @impl true
  def init(num) do
    {:ok, num}
  end

  @impl true
  def handle_call(:find_co_ords, _from, num) do
    {:reply, num, {:rand.uniform(num), :rand.uniform(num), :rand.uniform(num)}}
  end

end

defmodule Worker do

  use GenServer

  #extern API
  def start_link(num, agnt_pid) do
    #fetch co_ordinates
    fetch_co_ords(num, agnt_pid, nil)

    #initiate the genserver
    GenServer.start_link(__MODULE__, num, name: __MODULE__)
  end

  def fetch_co_ords(num, agnt_pid, nil) do
    fetch_co_ords(num, agnt_pid, Dispenser.find_co_ords(num, agnt_pid, self()))
  end
  def fetch_co_ords(_num, _agnt_pid, co_ords), do: co_ords

  #callbacks
  @impl true
  def init(num) do
    {:ok, num}
  end
  #further pushsum/gossip code


end
