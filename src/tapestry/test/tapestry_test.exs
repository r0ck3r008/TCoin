defmodule TapestryTest do
  use ExUnit.Case

  test "basic run" do
    assert Tapestry.start(1000)
  end
end
