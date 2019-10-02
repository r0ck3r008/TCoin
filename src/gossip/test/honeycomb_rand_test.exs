defmodule Honeycomb_rand.Test do
  use ExUnit.Case

  test "Honeycomb Radom topology" do
    assert Gossip.start(24, Honeycomb_rand)
  end

end
