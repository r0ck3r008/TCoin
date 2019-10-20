defmodule Tapestry.Node.Helper do

  def hash_it(msg) do
    Salty.Hash.Sha256.hash(msg)
    |> elem(1)
    |> Base.encode16()
    |> String.slice(0, 16)
  end

  def remove_deadlocks(_num, _disp_pid, 0), do: :ok
  def remove_deadlocks(num, disp_pid, _dlta), do: remove_deadlocks(num, disp_pid, num-Tapestry.Dispenser.fetch_assigned(disp_pid))

  def publish(nbors, agnt_pid, {hash, msg}) do
    nbor=find_best_match(nbors, hash)
    if elem(nbor, 1)==self() do
      IO.puts "Publishing #{msg}:#{hash} at #{inspect self()}:#{elem(hd(nbors), 0)}"
      Agent.update(agnt_pid, &(&1++[{hash, msg}]))
    else
      send(elem(nbor, 1), {:publish, msg})
    end
  end

  def find_best_match([{self_hash, self_pid} | rest], hash) do
    #RE match here
  end

end
