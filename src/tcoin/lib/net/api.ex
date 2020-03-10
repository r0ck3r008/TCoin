defmodule Tcoin.Net.Api do

  require Logger
  alias Tcoin.Net.Node
  alias Tcoin.Net.Node.Public

  #returns the PID of the genserver
  def init_node do
    Node.start_link
  end

  #receives the pid of new node and the node that is adding it
  def add_node(gateway_node, new_node) do
    Public.add_node(gateway_node, new_node)
  end

  #publish receives the publisher's pid as well as the object
  def publish(publisher, obj) do
    Public.publish(publisher, obj)
  end

  #unpublish receives the unpublish requesting node's pid as well as object
  def unpublish(requester, obj_hash) do
    Public.unpublish(requester, obj_hash)
  end

  def route_to_obj(requester, obj_hash) do
    Public.route_to_obj(requester, obj_hash)
    Public.fetch_obj(requester, obj_hash)
  end

end
