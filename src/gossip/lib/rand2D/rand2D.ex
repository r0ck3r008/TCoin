defmodule Proj2.Rand2D do
  use GenServer

  def start_link({num, startTime}) do
    GenServer.start_link(__MODULE__, {num, startTime})
  end

  def get_nbors(pid) do
    GenServer.call(__MODULE__, {:nbors, pid})
  end

  def done(pid) do
    GenServer.cast(__MODULE__, {:done, pid})
  end


  def init({num, startTime}) do
    node_pids = []

    for i <- 0 .. (num-1) do
      node_pids =  [Proj2.Rand2D.Worker.start_link | node_pids]
    end

    #node_coordinates = Enum.map(node_pids, fn x -> %{x => [div(:rand.uniform(10), 10), div(:rand.uniform(10), 10)]} end)
    node_coordinates = Enum.reduce(node_pids, %{}, fn x, acc ->

      Map.put(acc, x, [div(:rand.uniform(10), 10), div(:rand.uniform(10), 10)])
    end)

    nbor_map = Enum.reduce(node_pids, %{}, fn x, acc ->

      Map.put(acc, x, Proj2.Rand2D.nbor_list(x, node_coordinates, node_pids))
    end)


    {:ok, {nbor_map, num, startTime}}
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
        acc ++ []
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

  def handle_call({:nbors, pid}, _from, map) do
    neighbours = Map.get(map, pid)
    {:reply, neighbours, map}
  end

  def handle_cast({:done, pid}, {nbor_map, num, startTime}) do

    if(num <= 1) do
      end_time = System.monotonic_time(:millisecond)
      time_taken = end_time - startTime
      IO.puts("Time taken:")
      IO.inspect(time_taken)
      System.halt(0)
    end

    {:noreply, {nbor_map, num-1, startTime}}
  end
end
