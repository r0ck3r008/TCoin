defmodule Tapestry.Node.Helper do

  ##########Helper functions##########
  def hash_it(msg) do
    :crypto.hash(:sha, msg)
    |> Base.encode16()
    |> String.slice(0, 8)
  end

  def remove_deadlocks(_num, _disp_pid, 0), do: :ok
  def remove_deadlocks(num, disp_pid, _dlta), do: remove_deadlocks(num, disp_pid, num-Tapestry.Dispenser.fetch_assigned(disp_pid))
  ##########Helper functions##########

  ##########Publish related##########
  def publish(nbors, agnt_pid, msg_hash, srvr_pid, hops) do
    nbor=find_best_match(nbors, msg_hash)
    state=Agent.get(agnt_pid, &Map.get(&1, msg_hash))
    Agent.update(agnt_pid, &Map.put(
      &1,
      msg_hash,
      [srvr_pid]++state
    ))
    if elem(nbor, 1)==elem(hd(nbors), 1) do
      IO.puts "[#{elem(Enum.at(nbors, 0), 0)}] Published #{msg_hash}!"
    else
      IO.puts "[#{elem(Enum.at(nbors, 0), 0)}] Publishing #{msg_hash}!"
      send(elem(nbor, 1), {:publish, msg_hash, srvr_pid, hops})
    end
  end
  ###########Publish related##########

  ##########new_node related##########
  def add_node(node_hash, node_pid, hops, {nbors, agnt_pid}) do
    nbor=find_best_match(nbors, node_hash)
    #update nbor table of self
    new_nbors=update_nbor_table(node_hash, node_pid, nbors)
    #unpublish and then publish a revelent object
    update_obj_mapping(nbors, node_hash, agnt_pid)
    if elem(nbor, 1)==self() do
      IO.puts "[#{elem(hd(nbors), 0)}] Root node found for the newbie!"
    else
      IO.puts "[#{elem(hd(nbors), 0)}] Propagating newbie"
      #send to surrogate for every 100th hop to circumvent loops
      if rem(hops, 100)!=0 do
        send(elem(nbor,1 ), {:add_n, node_hash, node_pid, hops})
      else
        send(elem(Enum.at(nbors, 1), 1), {:add_n, node_hash, node_pid, hops})
      end
    end
    #send warm welcome if not self
    if node_pid != self() do
      send(node_pid, {:welcome, elem(hd(nbors), 0), self()})
    end
    new_nbors
  end

  def update_nbor_table(node_hash, node_pid, [self_map|rest]) do
    match_lvl=find_match_lvl(elem(self_map, 0), node_hash, 0)
    if elem(Enum.at(rest, match_lvl), 0)==nil do
      #update safely
      rest=List.delete_at(rest, match_lvl)
      [self_map]++List.insert_at(rest, match_lvl, {node_hash, node_pid})
    else
      nil
    end
  end

  def update_obj_mapping([_self_map|rest], node_hash, agnt_pid) do
    hash_to_find=Integer.to_string(elem(Integer.parse(node_hash, 16), 0)+1, 16)
    ret=Agent.get(agnt_pid, &Map.get(&1, hash_to_find))
    if ret != nil do
      #publish via surrogate
      send(elem(Enum.at(rest, 0), 1), {:publish, hash_to_find, hd(ret), 100})
    end
  end

  def handle_welcome(sndr_hash, sndr_pid, [{self_hash, self_pid}|rest]) do
    match_lvl=find_match_lvl(self_hash, sndr_hash, 0)
    if rest==[] do
      rest=for _x<-0..String.length(self_hash)-1, do: {nil, nil}
      rest=List.delete_at(rest, match_lvl)
      [{self_hash, self_pid}]++List.insert_at(rest, match_lvl, {sndr_hash, sndr_pid})
    else
      if elem(Enum.at(rest, match_lvl), 0)==nil do
        rest=List.delete_at(rest, match_lvl)
        [{self_hash, self_pid}]++List.insert_at(rest, match_lvl, {sndr_hash, sndr_pid})
      else
        nil
      end
    end
  end
  ##########new node related###########

  ##########route to an object related##########
  def route_to_obj(msg_hash, hops, rqstr_pid, {nbors, agnt_pid}) do
    ret=Agent.get(agnt_pid, &Map.get(&1, msg_hash))
    if ret==nil do
      nbor=find_best_match(nbors, msg_hash)
      if elem(nbor, 1)==self() do
        IO.puts "[#{elem(nbor, 0)}] I seem to be root, object looks unpublished!"
      else
        IO.puts "[#{elem(Enum.at(nbors, 0), 0)}] Mapping not found!"
        send(elem(nbor, 1), {:route_o, msg_hash, rqstr_pid, hops})
      end
    else
      IO.puts "[#{elem(Enum.at(nbors, 0), 0)}] Found mapping!"
      if Enum.at(ret, 0)==self() do
        #When the requestor is the one having mapping within
        #display found obj and dont send a msg as it will cause a deadlock
        IO.puts "[#{elem(hd(nbors), 0)}] Found mapping within myself! Object is: #{Enum.at(ret, 1)}"
      else
        send(rqstr_pid, {:route_o_r, msg_hash, ret, hops})
      end
    end
  end
  ##########route to an object related##########

  ##########unpublish related###########
  def unpublish(msg_hash, hops, {nbors, agnt_pid}) do
    #chk whatever you have
    ret=Agent.get(agnt_pid, &Map.get(&1, msg_hash))
    if ret != nil do
      #delete whatever you have and send to nbor
      IO.puts "[#{elem(hd(nbors), 0)}] Removing mapping #{msg_hash}!"
      Agent.update(agnt_pid, &Map.delete(&1, msg_hash))
      nbor=find_best_match(nbors, msg_hash)
      send(elem(nbor, 1), {:unpublish, msg_hash, hops})
    else
      #send to a surrogate
      send(elem(Enum.at(nbors, 1), 1), {:unpublish, msg_hash, hops})
    end
  end
  ##########unpublish related##########

  ##########route to node related##########
  def next_hop([{self_hash, self_pid} | rest], dest_hash) do
    if self_hash==dest_hash do
      {self_hash, self_pid}
    else
      nbor=Enum.at(rest, find_match_lvl(self_hash, dest_hash, 0))
      if is_nil(elem(nbor, 0)) do
        Enum.at(rest, 0)
      else
        nbor
      end
    end
  end

  ##########route to node related##########

  ##########general routing related##########
  def find_best_match([{self_hash, self_pid} | rest], msg_hash) do
    diff=elem(Integer.parse(msg_hash, 16),0)-elem(Integer.parse(self_hash, 16), 0)
    if diff==1 do
      {self_hash, self_pid}
    else
      nbor=Enum.at(rest, find_match_lvl(self_hash, msg_hash, 0))
      if is_nil(elem(nbor, 0)) do
        Enum.at(rest, 0)
      else
        nbor
      end
    end
  end

  def find_match_lvl(hash1, hash2, count) do
    if String.slice(hash1, 0, count)==String.slice(hash2, 0, count) do
      find_match_lvl(hash1, hash2, count+1)
    else
      count-1
    end
  end
  ##########general routing related##########

end
