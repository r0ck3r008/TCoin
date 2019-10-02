defmodule Full.Test do
  use ExUnit.Case

  test "Full topology with PushSum Algorithm" do
    assert Gossip.start(1000, Full, PushSum)
  end

  test "Full topology With Gossip Algorithm" do
    assert Gossip.start(1000, Full, Gosp)
  end

end
