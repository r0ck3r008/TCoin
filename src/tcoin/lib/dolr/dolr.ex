defmodule Tapestry.Dolr do

  #NOTE
  #The basic algorithm for publish is:
  #1. Input what to publish and the piblisher's pid
  #2. Hash the object and send a publish message with object hash, srvr_pid and hop count
  #3. The message traverses the network using tapestry routing and tries to find its root node
  #4. The intermidiatory nodes when receive this message, add this mapping and pass along to nbor
  #   if already added pass to surrogate
  def publish(msg, srvr_pid) do
    msg_hash=Tapestry.Node.Helper.hash_it(msg)
    GenServer.cast(srvr_pid, {:store, msg_hash, msg})
    send(srvr_pid, {:publish, msg_hash, srvr_pid, 0})
  end

  #NOTE
  #The basic algorithm for ubpublish is:
  #1. Input what to unpublish and the publisher's pid
  #2. Send the unpublish message including initial hop count, message hash to it self for tapestry routing
  #3. For each intermidiatary node, check if it has mapping, if yes then delete else pass its surrogate
  #   else pass to its next nbor
  def unpublish(msg, srvr_pid) do
    msg_hash=Tapestry.Node.Helper.hash_it(msg)
    send(srvr_pid, {:unpublish, msg_hash, 0})
  end

  #NOTE:
  #The basic algorithm for route to obj is:
  #1. Inpute the message that need to be looked for and the requestor that need it
  #2. Send a message to itself requesting the message hash and its own pid along with inital hop count
  #3. The tapestry algorithm routes it in its own way until it either finds a mapping published when that
  #   object was published or the root node
  #4. The root node or the intermidiatary node with object's published mapping sends its server's pid to requestor
  #   and the requestor can now fetch
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
