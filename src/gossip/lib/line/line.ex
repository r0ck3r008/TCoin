defmodule Line do

  def main(num) do
    #start agent
    {:ok, agnt_pid}=Agent.start_link(fn-> %{} end)

    #fork workers
    workers=for _x<-0..n-1, do: Line.Worker.start_link

    #update agent
    for x<-0..n-1, do: Agent.update(agnt_pid, &Map.put(
      &1,
      x,
      elem(Enum.at(workers, x), 1)
    ))

    #send state update req to each process
    for x<-0..n-1, do: Line.Worker.update_nbor_state(elem(Enum.at(workers, x), 1), num, agnt_pid, x) 
  end

end
