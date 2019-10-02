defmodule Gossip do
  def start(num, topo, algo) do
    topo.start_link(num, algo)
  end
end
