args = System.argv()
numNodes = String.to_integer(Enum.at(args, 0))
numRequests = String.to_integer(Enum.at(args, 1))
num_of_args = length(args)
failure_percent=  if num_of_args == 3, do: String.to_integer(Enum.at(args, 2)), else: 0

Tapestry.Init.main(numNodes, numRequests, failure_percent)
