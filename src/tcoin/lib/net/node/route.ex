defmodule Tcoin.Net.Node.Route do

  require Logger

  #NOTE
  #Pointer is a tuple with obj_hash as first element and address of publisher as second
  def send_to_lvl(pointer, nbors, hops) do
    for {_, pid}<-nbors do
      send(pid, {:publish, pointer, hops})
    end
  end

  def broadcast(msg, nbors) do
    for {_, nbors} <- nbors do
      for {_, nbor_pid} <- nbors do
        if Process.alive?(nbor_pid) do
          send(nbor_pid, msg)
        end
      end
    end
  end

end
