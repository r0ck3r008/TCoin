defmodule GossipTest do
  use ExUnit.Case

  test "Torus Topology" do
    assert Gossip.start(1000, Torus)
  end

  test "Line topology" do
    assert Gossip.start(10, Line)
  end

  test "Full topology" do
    assert Gossip.start(1000, Full)
  end

end
