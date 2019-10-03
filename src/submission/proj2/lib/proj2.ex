defmodule Proj2 do
  def start(num, topo, algo) do
    topo.start_link(num, algo)
  end
end

