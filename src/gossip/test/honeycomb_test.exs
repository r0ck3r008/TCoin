defmodule Honeycomb.Test do
  use ExUnit.Case

  test "Honeycomb topology" do
    assert Gossip.start(24, Honeycomb)
  end

end
