defmodule Tcoin.Net.Dispenser.Hash_helper do

  def get_nbors(disp_pid, hash) do
    map=GenServer.call(disp_pid, :get_map)

    hashes=for {key, _}<-map, do: key

    matches=for x<-0..String.length(hash)-1, do: make_nbor_tbl(hashes, hash, x)
    nbors=Enum.map(
      matches,
      fn(x)-> Enum.map(
        x,
        fn(y)-> {y, map[y]} end
      ) end
    )
    GenServer.cast(disp_pid, :dec_assigned)
    nbors
    end
  def make_nbor_tbl(hashes, hash, nbor_lvl) do
    sub_hash=String.slice(hash, 0, nbor_lvl)

    matches=Enum.uniq(
      Enum.map(
        hashes,
        fn(x)-> if Regex.match?(~r/^#{sub_hash}/, x)==true, do: x end
      )
    )
    #remove nil if matches has at least 1 match
    matches=if matches != [nil], do: matches--[nil], else: [nil]
    #the new 8 backup list match
    len=length(matches)
    if len != 8 do
      if len<8 do
        matches++(for _x<-length(matches)..7, do: nil)
      else
        for x<-0..7, do: Enum.at(matches, x)
      end
    else
      matches
    end
  end

end
