defmodule Tapestry.Init do

  def main(n) do
    #start dispenser
    {:ok, disp_pid}=Tapestry.Dispenser.start_link

    #start nodes
    nodes=for _x<-0..n-1, do: Tapestry.Node.start_link
    tasks=for {_, pid}<-nodes, do: Task.async(fn-> Tapestry.Node.update_route(pid, n, disp_pid) end)
    #makes main never exit
    for task<-tasks, do: Task.await(task, :infinity)
  end

end
