defmodule Honeycomb_rand.Test do
  use ExUnit.Case

  test "Honeycomb Radom topology with PushSum algo" do
    assert Gossip.start(24, Honeycomb_rand, PushSum)
  end

  test "Honeycomb Radom topology with Gossip" do
    assert Gossip.start(24, Honeycomb_rand, Gosp)
  end

end
