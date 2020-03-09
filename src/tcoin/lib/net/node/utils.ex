defmodule Tcoin.Net.Node.Utils do

  require Logger
  alias Tcoin.Net.Node.Route

  def hash_it(input) do
    input
    |> Salty.Hash.Sha256.hash
    |> elem(1)
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

  def inventory_chk(store_agnt, obj_hash) do
    state=Agent.get(store_agnt, fn(state)->state end)
    for {hash, payload}<-state, hash == obj_hash, do: {hash, payload}
    |> Enum.uniq()
  end

  def inventory_add(store_agnt, {obj_hash, payload}) do
    ret=inventory_chk(store_agnt, obj_hash)
    case ret do
      _->
        nil
      [nil]->
        Agent.update(store_agnt, &(&1 ++ [{obj_hash, payload}]))
    end
  end

  def inventory_remove(store_agnt, {obj_hash, payload}) do
    ret=inventory_chk(store_agnt, obj_hash)
    case ret do
      _->
        Agent.update(store_agnt, &(&1 -- [{obj_hash, payload}]))
        true
      [nil]->
        false
    end
  end

  def publish({_state_agnt, store_agnt, _hash}, {obj_hash, payload}, 5) do
    inventory_add(store_agnt, {obj_hash, payload})
  end
  def publish({state_agnt, store_agnt, hash}, {obj_hash, payload}, hops) do
    inventory_add(store_agnt, {obj_hash, payload})
    lvl=match_lvl(hash, obj_hash, 0)
    nbors=Agent.get(state_agnt, &Map.get(&1, String.to_atom("lvl#{lvl}")))
    case payload do
      {obj_hash, payload}->
        Route.send_to_lvl({obj_hash, payload}, nbors, hops)
      _->
        Route.send_to_lvl({obj_hash, {hash, self()}}, nbors, hops)
    end
  end

  def unpublish({state_agnt, store_agnt, _hash}, obj_hash) do
    ret=inventory_remove(store_agnt, obj_hash)
    case ret do
      true->
        Route.broadcast({:unpublish, obj_hash}, Agent.get(state_agnt, fn(state)->state end))
      false->
        nil
    end
  end

end
