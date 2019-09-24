defmodule Template do

  def main(num, topo) do
    make_topo(num, topo)
  end

  def make_topo(num, :mesh), do: Topologies.make_mesh(num)
  def make_topo(num, :line), do: Topologies.make_line(num)
  def make_topo(num, :"3d_t"), do: Topologies.make_3d_t(num)

end

defmodule Topologies do

  def make_mesh(num) do
    tasks = for _x<-1..num, do: Task.spawn_link(fn-> Work.sleeper() end)
    for task<-tasks, do: send(task, tasks)
  end

  def make_line(num) do
    tasks = for _x<-1..num, do: Task.spawn_link(fn -> Work.sleeper() end)
    Enum.each(tasks, fn(task) ->
      indx = Enum.find_index(tasks, fn t -> t == task end)
      case indx do
        0->
          send(task, [Enum.at(tasks, indx+1)])
        Enum.count(tasks)-1->
          send(task, [Enum.at(tasks, indx-1)])
        _->
          send(task, [Enum.at(tasks, indx-1), Enum.at(tasks, indx+1)])
      end
    end
      )
  end

end

defmodule Work do

  def sleeper() do
    :timer.sleep(10000)
  end

end
