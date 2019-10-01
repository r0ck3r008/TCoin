defmodule Honeycomb.Test do
  use ExUnit.Case

  test "Honeycomb topology" do
    assert Gossip.start(1000, Honeycomb)
  end

end
