defmodule Tcoin.Net.Node.Utils do

  require Logger

  def hash_it(input) do
    :crypto.hash(:sha, input)
    |> Base.encode16()
    |> String.slice(0, 8)
  end

  def match_lvl(hash1, hash2, count)
              when hash1 == hash2, do: match_lvl(
                                                  String.slice(hash1, 0, count+2),
                                                  String.slice(hash2, 0, count+2),
                                                  count+1
                                                  )
  def match_lvl(hash1, hash2, count)
              when hash1 != hash2, do: count
  def match_lvl(hash1, hash2, 0) do
    match_lvl(
      String.slice(hash1, 0, 1),
      String.slice(hash2, 0, 1),
      0
    )
  end

  #TODO
  #Add a time stamp on the nbors so that stale nbors can be replaced
  def update_nbors({state_agnt, hash}, node) do
    node_hash=hash_it(inspect node)
    lvl=match_lvl(hash, node_hash, 0)
    nbors=Agent.get(state_agnt, &Map.get(&1, String.to_atom("lvl#{lvl}")))
    len=length(nbors)
    case len do
      0->
        Agent.update(
          state_agnt,
          &Map.put(&1, String.to_atom("lvl#{lvl}"), [{node_hash, node}])
        )
      x when x in 0..length(node_hash)-1->
        Agent.update(
          state_agnt,
          &Map.update(&1, String.to_atom("lvl#{lvl}"), nbors, fn(nbors)-> nbors++[{node_hash, node}] end)
        )
      _->
        nil
    end
  end

end
