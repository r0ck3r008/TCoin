defmodule Line.Test do
  use ExUnit.Case

  test "Line topology with PushSum Algorithm" do
    assert Gossip.start(10000, Line, PushSum)
  end

  test "Line topology with Gossip Algorithm" do
    assert Gossip.start(10000, Line, Gosp)
  end

end
