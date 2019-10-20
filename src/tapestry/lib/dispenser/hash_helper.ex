defmodule Tapestry.Dispenser.Hash_helper do

  def get_nbors(disp_pid, hash) do
    map=GenServer.call(disp_pid, :get_map)

    hashes=for {key, _}<-map, do: key

    for x<-0..String.length(hash)-1, do: make_nbor_tbl(map, hashes, hash, x)
  end

  def make_nbor_tbl(map, hashes, hash, nbor_lvl) do
    sub_hash=String.slice(hash, 0, nbor_lvl)

    matches=Enum.filter(
      Enum.map(
        hashes,
        fn(x)-> if Regex.match?(~r/^#{sub_hash}/, x)==true, do: x end
      ),
      fn(x)-> !is_nil(x) end
    )
    match=Enum.at(matches, Salty.Random.uniform(length(matches)))
    {match, map[match]}
  end

end
