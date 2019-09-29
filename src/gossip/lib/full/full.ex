defmodule Full do

  use GenServer

  #public API
  def start_link(num) do
    #start agent
    {:ok, agnt_pid}=Agent.start_link(fn->[] end)

    #spawn workers
    workers=for _x<-0..num-1, do: Full.Worker.start_link

    #update agent
    Agent.update(agnt_pid, &(&1++workers))

    #send msgs to all workers that neighbours are ready to be fetched
    for worker<-workers, do: Full.Worker.update_nbor_state(elem(worker, 1), agnt_pid, [self()])
    GenServer.start_link(__MODULE__, num)
  end

  #callbacks
  @impl true
  def init(num) do
    {:ok, num}
  end

end
