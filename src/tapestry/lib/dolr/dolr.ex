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

  #NOTE
  #The basic algorithm of route to node is:
  #1. Routing to a node requires the destination as well as source pids to be provided
  #2. The messages send within contain the destination_hash, the src_pid and the number of hops
  #3. At any given intermidiatary node, next hop is calculated by matching in the respective nbor table
  #   and calculating the match level. Then the same route_n msg is sent to next node
  #   untill either the dest node receives it, or hops are exhausted
  def route_to_node(src_pid, dest_pid, acc_pid) do
    dest_hash=Tapestry.Node.Helper.hash_it(inspect dest_pid)
    send(src_pid, {:route_n, dest_hash, src_pid, acc_pid, 0})
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
  #   an object or a mapping of whose this new node can be root of, if yes, then republishes it but
  #   with a lesser number of hops
  def add_node(node_pid, node_hash, entry_point_pid) do
    #publishes that node's existance
    send(entry_point_pid, {:add_n, node_hash, node_pid, 0})
  end

end
