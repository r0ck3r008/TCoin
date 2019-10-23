defmodule Tapestry.Node.Helper do

  def hash_it(msg) do
    Salty.Hash.Sha256.hash(msg)
    |> elem(1)
    |> Base.encode16()
    |> String.slice(0, 4)
  end

  def remove_deadlocks(_num, _disp_pid, 0), do: :ok
  def remove_deadlocks(num, disp_pid, _dlta), do: remove_deadlocks(num, disp_pid, num-Tapestry.Dispenser.fetch_assigned(disp_pid))

  def publish(nbors, agnt_pid, {msg_hash, srvr_pid}) do
    nbor=find_best_match(nbors, msg_hash)
    Agent.update(agnt_pid, &(&1++[{msg_hash, srvr_pid}]))
    if elem(nbor, 1)==self() do
      IO.puts "Publishing #{msg_hash} at #{inspect self()}:#{elem(hd(nbors), 0)}"
    else
      send(elem(nbor, 1), {:publish, msg_hash, srvr_pid})
    end
  end

  def find_best_match([{self_hash, self_pid} | rest], msg_hash) do
    diff=elem(Integer.parse(msg_hash, 16),0)-elem(Integer.parse(self_hash, 16), 0)
    if diff==1 do
      {self_hash, self_pid}
    else
      #TODO
      #If this level returns a nil, send to surrogate
      if is_nil(Enum.at(rest, find_match_lvl(self_hash, msg_hash, 1))) do
        0
      else
        Enum.at(rest, find_match_lvl(self_hash, msg_hash, 1))
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
