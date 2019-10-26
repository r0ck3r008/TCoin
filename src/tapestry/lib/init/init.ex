defmodule Tapestry.Init do

  def main(n, _req, _failPercent) do
    #start dispenser
    {:ok, disp_pid}=Tapestry.Dispenser.start_link

    #start nodes
    nodes=for _x<-0..n-1, do: Tapestry.Node.start_link
    tasks=for {_, pid}<-nodes, do: Task.async(fn-> task_fn(pid, n, disp_pid, 0) end)
    :timer.sleep(1000)
    #    dolr_call(disp_pid, Enum.map(nodes, fn({:ok, pid})-> pid end), req)
    dolr_publish(disp_pid, Enum.map(nodes, fn({:ok, pid})-> pid end))
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

  def dolr_publish(disp_pid, nodes) do
    nbors_done?(disp_pid, Tapestry.Dispenser.fetch_assigned(disp_pid))
    rqstr_1=Enum.at(nodes, :rand.uniform(length(nodes))-1)
    rqstr_2=Enum.at(nodes, :rand.uniform(length(nodes))-1)
    {:ok, publisher}=Tapestry.Node.start_link
    publisher_hash=Tapestry.Node.Helper.hash_it(inspect publisher)
    Tapestry.Node.update_route(publisher, publisher_hash)
    Tapestry.Dolr.add_node(publisher, publisher_hash, rqstr_1)
    :timer.sleep(3000)
    Tapestry.Dolr.publish("HELLO", publisher)
    :timer.sleep(3000)
    IO.puts "Finding now"
    Tapestry.Dolr.route_to_obj("HELLO", rqstr_2)
    :timer.sleep(2000)
    IO.puts "Unpublishing now"
    Tapestry.Dolr.unpublish("HELLO", publisher)
    :timer.sleep(2000)
    IO.puts "Trying to find after unpublishing!"
    Tapestry.Dolr.route_to_obj("HELLO", rqstr_1)
  end

  def dolr_call(disp_pid, nodes, req) do
    nbors_done?(disp_pid, Tapestry.Dispenser.fetch_assigned(disp_pid))

    len=length(nodes)
    hops_l=Enum.uniq(for node<-nodes, do: do_node(node, nodes, len, req))--[[nil]]

    max_hops=Enum.max(Enum.max(hops_l))
    IO.puts "Reached in Maximum of #{max_hops} hops!"
    for node<-nodes, do: GenServer.stop(node, :normal)
    System.halt(0)
  end

  def do_node(node, nodes, len, req) do
    IO.puts "Doing #{inspect Enum.find(nodes, fn(x)-> x==node end)}"
    {:ok, acc_pid}=Agent.start_link(fn-> [] end)
    hops=iterate(node, nodes, acc_pid, len, req)
    GenServer.stop(acc_pid)
    hops
  end

  def iterate(node, nodes, acc_pid, len, req) do
    for _x<-0..req-1, do: make_req(node, Enum.at(nodes, :rand.uniform(len)), acc_pid)
  end

  def make_req(rqstr1, rqstr2, acc_pid) do
    Tapestry.Dolr.route_to_node(rqstr1, rqstr2, acc_pid)
    :timer.sleep(1000)
    #extract hops
    hops=Agent.get(acc_pid, fn(state)->state end)
    Enum.at(hops, length(hops)-1)
  end

  def nbors_done?(_disp_pid, 0), do: :ok
  def nbors_done?(disp_pid, _assigned), do: nbors_done?(disp_pid, Tapestry.Dispenser.fetch_assigned(disp_pid))

end
