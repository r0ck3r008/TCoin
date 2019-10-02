defmodule Proj2.Rand2DPS do
  use GenServer

  # Public API
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def term(pid) do
    GenServer.cast(__MODULE__, {:term, pid})
    #IO.puts("Debug 1")
    #IO.puts("Random number : #{Decimal.div(:rand.uniform(10), 10)}")
  end

  def get_nbors(pid) do
    GenServer.call(__MODULE__, {:nbors, pid})
  end

  # Callbacks
  def init({num, startTime}) do
    Process.send_after(self(), :kickoff, 0)
    #IO.puts("In 2DPS")
    {:ok, {num, %{}, startTime}}
  end

  def handle_info(:kickoff, {num, nbor_map, startTime}) do

    node_pids = []

    #for i <- 0 .. (num-1) do
    #node_pids =  [GenServer.start_link(Proj2.Rand2D.Worker, :no_args) | node_pids]
    #end
    node_pids = Enum.reduce(1..num, [], fn x, acc ->
      {:ok, n_pid} = GenServer.start_link(Proj2.Rand2DPS.Worker, x)
      [n_pid | acc]
    end)

    #node_coordinates = Enum.map(node_pids, fn x -> %{x => [div(:rand.uniform(10), 10), div(:rand.uniform(10), 10)]} end)
    node_coordinates = Enum.reduce(node_pids, %{}, fn x, acc ->

      Map.put(acc, x, [:rand.uniform(15)/15, :rand.uniform(15)/15])
      end)

      nbor_map = Enum.reduce(node_pids, %{}, fn x, acc ->

        Map.put(acc, x, Proj2.Rand2DPS.nbor_list(x, node_coordinates, node_pids))
      end)

      start_node = Enum.random(node_pids)
      GenServer.cast(start_node, {:next, 0, 0})

    {:noreply, {num, nbor_map, startTime}}
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


    def handle_cast({:term, pid}, {num, nbor_map, startTime}) do

      #IO.puts("Debug 4")
      if(num <= 1) do

        endTime = System.monotonic_time(:millisecond)
        time = endTime - startTime
        IO.puts("Total time taken for convergence: #{time}")
        System.halt(0)
      end

      {:noreply, {num - 1, nbor_map, startTime}}
    end



  def handle_call({:nbors, pid}, _from, {num, nbor_map, startTime}) do

     nbors = Map.get(nbor_map, pid)
     {:reply, nbors, {num, nbor_map, startTime}}
   end


end
