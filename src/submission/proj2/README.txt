Team Members:
Naman Arora - UFID: 3979-0439
Drona Banerjee - UFID: 4662-7749

Instructions to RUN:

Run following commands from the proj2/ directory which has mix.exs
	mix test test/{topology}_test.exs
	{This shows failed tests but isnt failing actually as exit(:normal) is used}

where values of topology can be - rand2D, line, full, torus, honeycomb or honeycomb_rand


Things that are working:
1. Complete convergence is being achieved for Gossip algorithm for all topologies except rand2D. For rand2D, complete convergence is not always
being achieved owing to the randomness.
2. All topologies have been implemented for both algorithms

Largest Network Used:
1. Gossip Protocol:
a) Full Network: 5000 nodes
b) rand2D Topology: 10000 nodes
c) Honeycomb: 100000 nodes
d) Line: 100000 nodes
e) Random Honeycomb: 100000 nodes
f) 3D Torus: 100000 nodes

2. Push-Sum:
a) Full Network: 5000 nodes
b) rand2D Topology: 10000 nodes
c) Honeycomb: 100000 nodes
d) Line: 100000 nodes
e) Random Honeycomb: 100000 nodes
f) 3D Torus: 100000 nodes
