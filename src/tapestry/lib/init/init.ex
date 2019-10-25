defmodule Tapestry.Init do

  def main(n, _req, _failPercent) do
    #start dispenser
    {:ok, disp_pid}=Tapestry.Dispenser.start_link

    #start nodes
    nodes=for _x<-0..n-1, do: Tapestry.Node.start_link
    tasks=for {_, pid}<-nodes, do: Task.async(fn-> task_fn(pid, n, disp_pid, 0) end)
    :timer.sleep(1000)
    dolr_call(disp_pid, Enum.map(nodes, fn({:ok, pid})-> pid end))
    #makes main never exit
    for task<-tasks, do: Task.await(task, :infinity)
  end

  def task_fn(pid, n, disp_pid, 0) do
    Tapestry.Node.update_route(pid, n, disp_pid)
    task_fn(pid, n, disp_pid, 1)
  end
  def task_fn(pid, n, disp_pid, count) do
    :timer.sleep(1000)
    task_fn(pid, n, disp_pid, count)
  end

  def dolr_call(disp_pid, nodes) do
    nbors_done?(disp_pid, Tapestry.Dispenser.fetch_assigned(disp_pid))
    rqstr1=Enum.at(nodes, :rand.uniform(length(nodes))-1)
    rqstr2=Enum.at(nodes, :rand.uniform(length(nodes))-1)
    {:ok, acc_pid}=Agent.start_link(fn-> [] end)

    Tapestry.Dolr.route_to_node(rqstr2, rqstr1, acc_pid)

    :timer.sleep(1000)
    hops=Agent.get(acc_pid, fn(state)->state end)
    IO.puts "Reached in #{Enum.at(hops, 0)} hops!"
  end

  def nbors_done?(_disp_pid, 0), do: :ok
  def nbors_done?(disp_pid, _assigned), do: nbors_done?(disp_pid, Tapestry.Dispenser.fetch_assigned(disp_pid))

end
