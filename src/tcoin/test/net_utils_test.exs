defmodule Tcoin.Net.Node.Util.Test do

  use ExUnit.Case

  test "Test for different hashes fo same length" do
    hash1="abcef"
    hash2="abdef"
    assert Tcoin.Net.Node.Utils.match_lvl(hash1, hash2)==2
  end

  test "Test for same hashes" do
    hash1="abdef"
    hash2="abdef"
    assert Tcoin.Net.Node.Utils.match_lvl(hash1, hash2)==5
  end

  test "Test for different hashes different length" do
    hash1="ab"
    hash2="abdef"
    assert Tcoin.Net.Node.Utils.match_lvl(hash1, hash2)==2
  end

end
