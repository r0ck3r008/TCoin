defmodule Line.Test do
  use ExUnit.Case

  test "Line topology" do
    assert Gossip.start(1000, Line)
  end

end
