defmodule Tapestry.Dispenser.Hash_helper do

  def get_nbors(disp_pid, hash) do
    map=GenServer.call(disp_pid, :get_map)
    hashes=for {key, _}<-map, do: key
    make_nbor_tbl(map, hashes, hash, %{}, 0)
  end

  def make_nbor_tbl(_map, _hashes, hash, nbot_tbl, nbor_lvl) when nbor_lvl=length(hash)-1, do: nbor_tbl
  def make_nbor_tbl(map, hashes, hash, nbor_tbl, nbor_lvl) do
    sub_hash=String.slice(hash, 0, nbor_lvl)

    make_nbor_tbl(
      map,
      hashes,
      hash,
      search_nbor(sub_hash, map, hashes, nbor_tbl),
      nbor_lvl+1
    )
  end

  def search_for_nbor(sub_hash, map, nbor_tbl) do
    matches=for hash<-hashes do
      if Regex.match?(~r/^#{sub_hash}/, hash) do
        hash
      else
        nil
      end
    end
    Enum.filter(matches, fn(x)-> !is_nil(x) end)
    #TODO
    #now we have matches for the particular sub_hash, update the nbor_tbl
    #which is a map and return the same
  end

end
