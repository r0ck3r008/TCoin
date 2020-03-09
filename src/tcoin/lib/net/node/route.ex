defmodule Tcoin.Net.Node.Route do

  require Logger

  def broadcast(new_node, nbors) do
    for {_, nbors} <- nbors do
      for {_, nbor_pid} <- nbors do
        if Process.alive?(nbor_pid) do
          send(nbor_pid, {:new_node, new_node})
        end
      end
    end
  end

end
