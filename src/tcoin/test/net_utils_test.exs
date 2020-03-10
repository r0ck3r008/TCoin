defmodule Tcoin.Net.Node.Util.Test do

  use ExUnit.Case

  test "Test for hashes" do
    hash1="abcde"
    hash2="abdef"
    assert Tcoin.Net.Node.Utils.match_lvl(hash1, hash2)==2
  end

end
