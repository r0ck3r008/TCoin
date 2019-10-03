defmodule Honeycomb.Test do
  use ExUnit.Case

  test "Honeycomb topology with PushSum algo" do
    assert Gossip.start(24, Honeycomb, PushSum)
  end

  test "Honeycomb topology with Gossip Algo" do
    assert Gossip.start(24, Honeycomb, Gosp)
  end

end
