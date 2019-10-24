defmodule Tapestry.Node.Helper do

  def hash_it(msg) do
    Salty.Hash.Sha256.hash(msg)
    |> elem(1)
    |> Base.encode16()
    |> String.slice(0, 8)
  end

  def remove_deadlocks(_num, _disp_pid, 0), do: :ok
  def remove_deadlocks(num, disp_pid, _dlta), do: remove_deadlocks(num, disp_pid, num-Tapestry.Dispenser.fetch_assigned(disp_pid))

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

  def route_to_obj(msg_hash, rqstr_pid, {nbors, agnt_pid}) do
    ret=Agent.get(agnt_pid, &Map.get(&1, msg_hash))
    if ret==nil do
      nbor=find_best_match(nbors, msg_hash)
      if elem(nbor, 1)==self() do
        IO.puts "[#{elem(nbor, 0)}] I seem to be root, object looks unpublished!"
      else
        IO.puts "[#{elem(Enum.at(nbors, 0), 0)}] Mapping not found!"
        send(elem(nbor, 1), {:route_o, msg_hash, rqstr_pid})
      end
    else
      IO.puts "[#{elem(Enum.at(nbors, 0), 0)}] Found mapping!"
      send(rqstr_pid, {:route_o_r, msg_hash, ret})
    end
  end

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

end
