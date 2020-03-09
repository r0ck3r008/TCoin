defmodule Tcoin.Net.Node.Public do

  require Logger
  alias Tcoin.Net.Node.Utils

  def add_node(gateway_node, new_node) do
    GenServer.cast(gateway_node, {:add_node, new_node})
  end

  def publish(publisher, obj) do
    obj_hash=Utils.hash_it(inspect obj)
    GenServer.cast(publisher, {:publish, obj, obj_hash})
  end

end
