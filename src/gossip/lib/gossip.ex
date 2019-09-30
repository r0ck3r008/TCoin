defmodule Gossip do
  def start(num, topo) do
    topo.start_link(num)
  end
end
