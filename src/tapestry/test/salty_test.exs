defmodule SaltyTest do
  use ExUnit.Case

  test "Salty hashing test" do
    task=Task.async(fn-> IO.puts "hello" end)
    hash=Salty.Hash.Sha256.hash(inspect task.pid)
    assert IO.inspect hash
  end

end
