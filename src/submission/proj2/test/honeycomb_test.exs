defmodule Honeycomb.Test do
  use ExUnit.Case

  test "Honeycomb topology with PushSum algo" do
    assert Proj2.start(24, Honeycomb, PushSum)
  end

  test "Honeycomb topology with Gossip Algo" do
    assert Proj2.start(24, Honeycomb, Gosp)
  end

end
