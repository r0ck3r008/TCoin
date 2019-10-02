defmodule Full do

  use GenServer

  def start_link(num) do
    #start agent
    {:ok, agnt_pid}=Agent.start_link(fn-> [] end)

    #start timer
    {:ok, timer_pid}=Timer.start_link

    #start workers
    workers=for _x<-0..num-1, do: Full.Worker.start_link
    workers=for {_, wrkr}<-workers, do: wrkr

    #update agent
    Agent.update(agnt_pid, &(&1++workers))

    #start main
    {:ok, main_pid}=GenServer.start_link(__MODULE__, {num, timer_pid})

    #update workers
    for worker<-workers, do: Full.Worker.update_nbors(worker, agnt_pid, main_pid)
    #start rumer
    start_rum(num, agnt_pid, timer_pid)
    {:ok, main_pid}
  end

  def start_rum(num, agnt_pid, timer_pid) do
    #start timer
    Timer.start_timer(timer_pid)

    #send first rumer
    mod_name=Full.Worker
    Gosp.send_rum(
      mod_name,
      Agent.get(
        agnt_pid, &Enum.at(&1, Salty.Random.uniform(num))
      )
    )
  end

  def converged(self_pid) do
    {num, n_converged, timer_pid}=get_state(self_pid)
    dlta=num-n_converged
    if dlta==1 do
      IO.puts "All Done!"
      Timer.end_timer(timer_pid)
      System.halt(0)
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
    Process.flag(:trap_exit, true)
    {:ok, {elem(attrs, 0), 0, elem(attrs, 1)}}
  end

  @impl true
  def terminate(_, _) do
    IO.puts "Terminating as unconverged"
  end

  @impl true
  def handle_cast(:inc_converged, {num, n_converged, timer_pid}) do
    IO.puts "#{((n_converged+1)/num)*100}% converged!"
    {:noreply, {num, n_converged+1, timer_pid}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

end
