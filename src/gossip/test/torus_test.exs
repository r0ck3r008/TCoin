defmodule Torus.Test do
  use ExUnit.Case

  test "Torus topology" do
    assert Gossip.start(1000, Torus)
  end

end
