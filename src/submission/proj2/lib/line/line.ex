defmodule Line do

  use GenServer

  #public API
  def start_link(num, algo) do
    #start agent
    {:ok, agnt_pid}=Agent.start_link(fn-> %{} end)

    #start timer
    {:ok, timer_pid}=Timer.start_link

    #start genserver
    {:ok, main_pid}=GenServer.start_link(__MODULE__, {num, timer_pid})

    #fork workers
    workers=for x<-0..num-1, do: Line.Worker.start_link(x)
    workers=for {_, wrkr}<-workers, do: wrkr

    #update agent
    for x<-0..num-1, do: Agent.update(agnt_pid, &Map.put(
      &1,
      x,
      Enum.at(workers, x)
    ))

    #send state update req to each process
    for x<-0..num-1, do: Line.Worker.update_nbor_state(Enum.at(workers, x),x, num, agnt_pid, main_pid)

    #start rumor
    start_rumor(num, algo, agnt_pid, timer_pid)
  end

  def start_rumor(num, algo, agnt_pid, timer_pid) do
    #start timer
    Timer.start_timer(timer_pid)

    #send first rum
    wrkr_mod=Line.Worker
    algo.send_rum(
      wrkr_mod,
      Agent.get(agnt_pid, &Map.get(&1, Salty.Random.uniform(num)))
    )
  end

  def get_state(self_pid) do
    GenServer.call(self_pid, :get_state)
  end

  def converged(self_pid) do
    {num, n_converged, timer_pid}=get_state(self_pid)
    delta=num-n_converged

    if delta==1 do
      IO.puts "All Done!"
      Timer.end_timer(timer_pid)
      exit(:shutdown)
    else
      GenServer.cast(self_pid, :inc_converged)
    end
  end

  #callbacks
  @impl true
  def init(attrs) do
    Process.flag(:trap_exit, true)
    {:ok, {elem(attrs, 0), 0, elem(attrs, 1)}}
  end

  @impl true
  def terminate(_, _) do
    IO.puts "Terminating as not converged!"
    exit(:shutdown)
  end

  @impl true
  def handle_cast(:inc_converged, {num, n_converged, timer_pid}) do
    IO.puts "#{((n_converged+1)/num)*100}% done!"
    {:noreply, {num, n_converged+1, timer_pid}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

end
