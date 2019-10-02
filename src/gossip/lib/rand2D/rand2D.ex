defmodule Rand2D do

  use GenServer

  def start_link(num) do
    #start agent
    {:ok, agnt_pid}=Agent.start_link(fn-> %{} end)

    #start timer
    {:ok, timer_pid}=Timer.start_link

    #start workers
    workers=for _x<-0..num-1, do: Rand2D.Worker.start_link
    workers=for {_, wrkr}<-workers, do: wrkr

    #update agent
    #Agent.update(agnt_pid, &(&1++workers))
    node_coordinates = Enum.reduce(workers, %{}, fn x, acc ->

    Map.put(acc, x, [:rand.uniform(15)/15, :rand.uniform(15)/15])
    end)

    nbor_map = Enum.reduce(workers, %{}, fn x, acc ->

    #Agent.update(agnt_pid, fn(state) -> Map.put(state, x, Rand2D.nbor_list(x, node_coordinates, workers)) end)
    Map.put(acc, x, Rand2D.nbor_list(x, node_coordinates, workers))
    end)

    Agent.update(agnt_pid, fn(state) -> nbor_map end)

    #start main
    {:ok, main_pid}=GenServer.start_link(__MODULE__, {num, timer_pid})

    #update workers
    for worker<-workers, do: Rand2D.Worker.update_nbors(worker, agnt_pid, main_pid)
    #start rumer
    start_rum(num, agnt_pid, timer_pid)
    {:ok, main_pid}
  end


  def nbor_list(id, coord, pid_list) do

    x_coord = List.first(Map.get(coord, id))
    y_coord = List.last(Map.get(coord, id))

    Enum.reduce(pid_list, [], fn x, acc ->

      x1 = List.first(Map.get(coord, x))
      y1 = List.last(Map.get(coord, x))
      dist = :math.sqrt((x1 - x_coord)*(x1 - x_coord) + (y1 - y_coord)*(y1 - y_coord))
      if dist != 0 and dist <= 0.1 do
        [x | acc]
      else
        acc ++ [id] -- [id]
      end

    end)

  end


  def start_rum(num, agnt_pid, timer_pid) do
    #start timer
    Timer.start_timer(timer_pid)

    #send first rumer
    node_pids = Agent.get(agnt_pid, fn(state)-> Map.keys(state) end)
    start_node = Enum.random(node_pids)
    mod_name=Rand2D.Worker
    Gosp.send_rum(mod_name, start_node)
  end

  def converged(self_pid) do
    {num, n_converged, timer_pid}=get_state(self_pid)
    dlta=num-n_converged
    if dlta==1 do
      Timer.end_timer(timer_pid)
      GenServer.stop(self_pid, :normal)
    else
      GenServer.cast(self_pid, :inc_converged)
    end
  end

  def get_state(self_pid) do
    GenServer.call(self_pid, :get_state)
  end

  #callbacks
  @impl true
  def init(attrs) do
    {:ok, {elem(attrs, 0), 0, elem(attrs, 1)}}
  end

  @impl true
  def handle_cast(:inc_converged, state) do
    {:noreply, {elem(state, 0), elem(state, 1)+1, elem(state, 2)}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

end
