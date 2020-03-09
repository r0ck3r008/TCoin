defmodule Tcoin.Net.Node.Public do

  require Logger

  def add_node(gateway_node, new_node) do
    GenServer.cast(gateway_node, {:add_node, new_node})
  end

end
