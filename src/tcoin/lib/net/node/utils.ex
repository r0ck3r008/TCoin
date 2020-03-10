defmodule Tcoin.Net.Node.Utils do

  require Logger
  alias Tcoin.Net.Node.Route
  alias Tcoin.Net.Node.Public

  def hash_it(input) do
    input
    |> Salty.Hash.Sha256.hash
    |> elem(1)
    |> Base.encode16()
    |> String.slice(0, 8)
  end

  def match_lvl(hash1, hash2, p1, p2, count)
  when p1 == p2, do: match_lvl(
    hash1,
    hash2,
    String.slice(hash1, 0, count+2),
    String.slice(hash2, 0, count+2),
    count+1
    )
  def match_lvl(_hash1, _hash2, p1, p2, count)
  when p1 != p2, do: count
  def match_lvl(hash1, hash2) do
    match_lvl(
      hash1,
      hash2,
      String.slice(hash1, 0, 1),
      String.slice(hash2, 0, 1),
      0
    )
  end

  #TODO
  #Add a time stamp on the nbors so that stale nbors can be replaced
  def update_nbors({state_agnt, hash}, node) do
    node_hash=hash_it(inspect node)
    lvl=match_lvl(hash, node_hash)
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
      [nil]->
        Agent.update(store_agnt, &(&1 ++ [{obj_hash, payload}]))
          _->
        nil
    end
  end

  def inventory_remove(store_agnt, {obj_hash, payload}) do
    ret=inventory_chk(store_agnt, obj_hash)
    case ret do
      [nil]->
        false
          _->
        Agent.update(store_agnt, &(&1 -- [{obj_hash, payload}]))
        true
    end
  end

  def inventory_fetch(store_agnt, obj_hash) do
    state=Agent.get(store_agnt, fn(state)->state end)
    ret=for {hash, payload} <- state, hash==obj_hash, do: {hash, payload}
    |> Enum.uniq()
    ret -- [nil]
    |> Enum.at(0)
  end

  def publish({_state_agnt, store_agnt, _hash}, {obj_hash, payload}, 5) do
    inventory_add(store_agnt, {obj_hash, payload})
  end
  def publish({state_agnt, store_agnt, hash}, {obj_hash, payload}, hops) do
    inventory_add(store_agnt, {obj_hash, payload})
    lvl=match_lvl(hash, obj_hash)
    nbors=Agent.get(state_agnt, &Map.get(&1, String.to_atom("lvl#{lvl}")))
    case hops do
      0->
        Route.send_to_lvl({:publish, {obj_hash, {hash, self()}}, hops}, nbors)
      _->
        Route.send_to_lvl({:publish, {obj_hash, payload}, hops}, nbors)
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

  def route_to_obj({_state_agnt, store_agnt, _hash}, {obj_hash, requester, 5}) do
    ret=inventory_chk(store_agnt, obj_hash)
    case ret do
      [nil]->
        nil
      _->
        reach_out(requester, ret)
    end
  end
  def route_to_obj({state_agnt, store_agnt, hash}, {obj_hash, requester, hops}) do
    ret=inventory_chk(store_agnt, obj_hash)
    case ret do
      [nil]->
        pass_along({state_agnt, hash}, {obj_hash, requester, hops})
      _->
        reach_out(requester, ret)
    end
  end

  def pass_along({state_agnt, hash}, {obj_hash, requester, hops}) do
    lvl=match_lvl(hash, obj_hash)
    nbors=Agent.get(state_agnt, &Map.get(&1, String.to_atom("lvl#{lvl}")))
    Route.send_to_lvl({:route, {obj_hash, requester, hops}}, nbors)
  end

  def reach_out(requester, ret) do
    send(requester, {:found, Enum.at(ret, 0)})
  end

  def fetch({obj_hash, payload}) do
    ret=is_tuple(payload)
    case ret do
      true->
        Public.fetch_obj(elem(payload, 1), obj_hash)
      false->
        payload
    end
  end

end
