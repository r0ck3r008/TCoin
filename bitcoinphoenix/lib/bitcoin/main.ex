defmodule Bitcoin.Main do
  alias Bitcoin.Client
  alias Bitcoin.Miner

  def startSimulation(client_list, miner_list, timeInterval) do
    Task.async(fn -> simulate(client_list, miner_list, timeInterval) end)
  end

  def setup_nodes() do
    client_list = Enum.map(1..80, fn x -> Client.create_wallet() end)
    miner_list = Enum.map(1..20, fn x -> Miner.createMiner() end)

    Enum.each(client_list, fn x ->
      peer_list = List.delete(client_list, x)
      peer_list = peer_list ++ miner_list
      GenServer.cast(x,{:store_peers, peer_list})
    end)

    Enum.each(miner_list, fn x ->
      peer_list = List.delete(miner_list, x)
      peer_list = peer_list ++ client_list
      GenServer.cast(x,{:store_peers, peer_list})
    end)
    #Process.register(Enum.random(client_list),:amman)
    {client_list, miner_list}
  end

  def simulate(client_list, miner_list, timeInterval) do
    # client_list = Enum.map(1..20, fn x -> Client.create_wallet() end)
    # miner_list = Enum.map(1..20, fn -> Miner.createMiner() end)

    miner = Enum.random(miner_list)

    # Enum.each(client_list, fn x -> )


    # peers = GenServer.call(miner,{:get_peers})
    # IO.inspect peers
    random_number = :rand.uniform(5)

    Enum.each(0..random_number, fn x -> create_add_transactions(miner, client_list) end)

    Miner.mine(miner)

    # Miner.addTransaction(miner,transaction2)

    #random_client = Enum.random(client_list)
    #c = GenServer.call(random_client,{:get_blockchain}, 100000)


    # Miner.addTransaction(miner,transaction)

    # IO.inspect sender_client
    # IO.inspect receiver_client
    # IO.inspect miner
    # c=Miner.mine(miner)
    #IO.inspect c
    :timer.sleep(1000)
    simulate(client_list, miner_list, timeInterval)
  end

  def create_add_transactions(miner, client_list) do
    sender_client = Enum.random(client_list)
    receiver_client = Enum.random(client_list)
    receiver_key = GenServer.call(receiver_client,{:get_public_key}, 100000)
    random_coins = :rand.uniform(10)
    transaction = Client.create_transaction(sender_client, receiver_key, random_coins, 0)
    Miner.addTransaction(miner,transaction)
  end
end

