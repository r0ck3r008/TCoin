defmodule Tapestry.Dolr do

  def publish(msg, srvr_pid) do
    msg_hash=Tapestry.Node.Helper.hash_it(msg)
    GenServer.cast(srvr_pid, {:store, msg_hash, msg})
    send(srvr_pid, {:publish, msg_hash, srvr_pid, 0})
  end

  def route_to_obj(msg, rqstr_pid) do
    msg_hash=Tapestry.Node.Helper.hash_it(msg)
    send(rqstr_pid, {:route_o, msg_hash, rqstr_pid, 0})
  end

  def unpublish(msg, srvr_pid) do
    msg_hash=Tapestry.Node.Helper.hash_it(msg)
    send(srvr_pid, {:unpublish, msg_hash, 0})
  end

  #NOTE
  #The basic algo for new node is:
  #1. Using the underlying find_best match, continually find new nodes that are revelant to the new node
  #   and update those nodes {nil, nil} nbor entry if new node fits in
  #2. Whenevr a node receives notification that a new node has joined network, it sends it a welcome message
  #   the new node can decide to add the welcome message's sender in its own nbor table nor not
  #3. While the new node notification is received by any node, it checks weather it has previously published
  #   an object or a mapping of whose this new node can be root of, if yes, it unpublishes it, then republishes it
  #   with a lesser number of hops
  def add_node(node_pid, node_hash, entry_point_pid) do
    #publishes that node's existance
    send(entry_point_pid, {:add_n, node_hash, node_pid, 0})
  end

end
