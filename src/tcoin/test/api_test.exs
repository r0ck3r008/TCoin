defmodule Tcoin.Net.Api.Test do

  use ExUnit.Case
  alias Tcoin.Net.Node
  alias Tcoin.Net.Api

  setup do
    n=Salty.Random.uniform(1000)
    {:ok, node1}=Node.start_link
    nodes=for _x <- 0..n-1, do: Node.start_link
    nodes=nodes
          |> Enum.map(fn(t)-> elem(t, 1) end)
    for pid <- nodes, do: Api.add_node(node1, pid)
    {:ok, [node1: node1, nodes: nodes]}
  end

  test("Publish Objects", state) do
    assert Api.publish(Enum.at(state[:nodes], 0), "hello")
  end

  """
  test "Unpublish Objects" do

  end

  test "Route to an object" do

  end
"""
end
