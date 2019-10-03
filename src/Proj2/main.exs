#!/usr/bin/elixir

args = System.argv()
numNodes = String.to_integer(Enum.at(args, 0))
topology = Enum.at(args, 1)
algorithm = Enum.at(args, 2)

String.to_atom(topology).start_link(numNodes, algorithm)
