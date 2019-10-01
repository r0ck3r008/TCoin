defmodule Full.Test do
  use ExUnit.Case

  test "Full topology" do
    assert Gossip.start(1000, Full)
  end

end
