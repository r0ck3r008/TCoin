defmodule Tapestry.Init do

  def main(n) do
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
    publisher=Enum.at(nodes, Salty.Random.uniform(length(nodes)))
    rqstr=Enum.at(nodes, Salty.Random.uniform(length(nodes)))

    IO.puts("Publishing!")
    Tapestry.Dolr.publish("HELLO", publisher)
    :timer.sleep(5000)
    Tapestry.Dolr.route_to_obj("HELLO", rqstr)
  end

  def nbors_done?(_disp_pid, 0), do: :ok
  def nbors_done?(disp_pid, _assigned), do: nbors_done?(disp_pid, Tapestry.Dispenser.fetch_assigned(disp_pid))

end
