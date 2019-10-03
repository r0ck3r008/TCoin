defmodule Torus.Test do
  use ExUnit.Case

  test "Torus topology with PushSum Algorithm" do
    assert Gossip.start(1000, Torus, PushSum)
  end

  test "Torus topology with Gossip Algorithm" do
    assert Gossip.start(1000, Torus, Gosp)
  end

end
