args = System.argv()
numNodes = String.to_integer(Enum.at(args, 0))
numRequests = String.to_integer(Enum.at(args, 1))
Tapestry.Init.main(numNodes, numRequests)
