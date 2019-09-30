defmodule GossipTest do
  use ExUnit.Case

  test "Full topology" do
    assert Gossip.start(100000, Full)
  end
end
