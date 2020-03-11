defmodule Tcoin.Net.Node.Public do

  require Logger
  alias Tcoin.Net.Node.Utils

  def add_node(gateway_node, new_node) do
    GenServer.cast(gateway_node, {:add_node, new_node})
  end

  def publish(publisher, obj) do
    obj_hash=Utils.hash_it(inspect obj)
    Logger.debug("Publishing")
    GenServer.cast(publisher, {:publish, obj, obj_hash})
  end

  def unpublish(requester, obj_hash) do
    GenServer.cast(requester, {:unpublish, obj_hash})
  end

  def route_to_obj(requester, obj_hash) do
    GenServer.cast(requester, {:route, obj_hash})
  end

  def fetch_obj(requester, obj_hash) do
    GenServer.call(requester, {:fetch, obj_hash})
  end

end
