args = System.argv()
numNodes = String.to_integer(Enum.at(args, 0))
topology = Enum.at(args, 1)
algorithm = Enum.at(args, 2)

start_time = System.monotonic_time(:millisecond)
Proj2.Application.start(:normal,{numNodes,topology, algorithm, start_time})
