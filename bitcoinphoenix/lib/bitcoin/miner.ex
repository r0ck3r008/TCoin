#Miner
defmodule Bitcoin.Miner do
  use GenServer
  alias Bitcoin.Helpers
  def createMiner() do
    {:ok,pid} = GenServer.start_link(__MODULE__,:ok)
    pid
  end

  @doc """
  Init function.
  Miner will have blockchain, publickey, privatekey, pendingTransactions(which will be empty when created)
  publickey and privatekey are generated from helper method
  """
  def init(:ok) do
    {publicKey,privateKey}=Helpers.genereateKeys()
    {:ok, {[],publicKey,privateKey,[],[]}}
  end

  def addTransaction(p,transaction) do
    GenServer.cast(p,{:addTransaction,transaction})
  end
  @doc """
  Adds a transaction to pending transactions array
  """
  def handle_cast({:addTransaction,transaction},state) do
    {blockchain, publickey, privatekey, pendingTransactions, peers}=state
    l=pendingTransactions
    l=l++[transaction]
    pendingTransactions=l
    #pendngTransactions=pendingTransactions++[transaction]
    state={blockchain, publickey, privatekey, pendingTransactions, peers}
    {:noreply,state}
  end

  def getPendingTransactions(p) do
    GenServer.call(p,{:getPendingTransactions})
  end

  def handle_call({:getPendingTransactions},_from,state) do
    {_, _, _, pendingTransactions,peers}=state
    {:reply,pendingTransactions,state}
  end

  def mine(p) do
    GenServer.cast(p,{:mine})
  end
  @doc """
  Mine function
  """
  def handle_cast({:mine},state) do
    {blockchain, publickey, privatekey, pendingTransactions, peers}=state

    validPendingTransactions=Enum.filter(pendingTransactions,fn x -> isValidTransaction(x,blockchain) == true end)
    blockchain=
    if validPendingTransactions == [] do
      blockchain
    else
      #Adding all the incentives sent by transactions clients to miner's rewards
      rewardCoins=Enum.map(validPendingTransactions, fn x -> Map.get(x,:incentive) end) |> Enum.reduce(fn g,sum -> sum+g end)
      #Adding the default reward
      rewardCoins=rewardCoins+20

      #Miner adds only valid transactions to the block
      th=Helpers.calculate_hash(["",publickey,rewardCoins,0])
      rewardTransaction=%{
        :sender => "",
        :receiver => publickey,
        :transaction_hash => th,
        :signature => :crypto.sign(:ecdsa,:sha256,th,[privatekey, :secp256k1]),
        :coins => rewardCoins,
        :incentive => 0
      }
      validPendingTransactions=validPendingTransactions++[rewardTransaction]

      # #validPendingTransactions=[rewardTransaction]
      # validPendingTransactions=Enum.filter(pendingTransactions,fn x -> isValidTransaction(x,blockchain) == true end)
      # validPendingTransactions=validPendingTransactions++[rewardTransaction]
      # #Adding all the incentives sent by transactions clients to miner's rewards
      # rewardCoins=Enum.map(pendingTransactions, fn x -> Map.get(x,:incentive) end) |> Enum.reduce(fn g,sum -> sum+g end)


      #mined block starts here
      minedBlock=%{}

      #Get the previous block from the blockchain
      previousHash=
      if blockchain == [] do
        :crypto.hash(:sha256,'initialHash') |> Base.encode16
      else
        previousBlock=Enum.at(blockchain, -1)
        previousBlock[:currentHash]
      end

      #Update the previous hash
      minedBlock=Map.put(minedBlock,:previousHash,previousHash)


      #update all the transactions
      minedBlock=Map.put(minedBlock,:transactions,validPendingTransactions)

      #Call the miner and get the correct hash and nonce
      #toEncrypt=validPendingTransactions++[previousHash]
      toEncrypt=Enum.map(validPendingTransactions,fn x ->
        Enum.map(x,fn {_,v} -> v end)
      end)
      toEncrypt=toEncrypt++[previousHash]
      {currentHash,nonce}=miner(toEncrypt,"0")

      #Update the mined block with current hash and nonce
      minedBlock=Map.put(minedBlock,:currentHash,currentHash)
      minedBlock=Map.put(minedBlock,:nonce,nonce)
      minedBlock=Map.put(minedBlock,:timestamp,:os.system_time(:millisecond))

      #Add the mined block to the blockchain
      blockchain=blockchain++[minedBlock]
      blockchain
    end

    Enum.each(peers, fn x ->
      GenServer.cast(x, {:update_blockchain, blockchain})
    end)
    #update the states
    state={blockchain, publickey, privatekey, [], peers}
    {:noreply,state}
  end

  def miner(data, nonce) do
    nonce_int = String.to_integer(nonce)
    temp = :crypto.hash(:sha256, [nonce, data]) |> Base.encode16
    if(String.slice(temp,0,3) === String.duplicate("0",3)) do
        {temp,nonce}
    else
        miner(data, Integer.to_string(nonce_int+1))
    end
  end

  def isValidTransaction(transaction,blockchain) do
    hashVerify=:crypto.verify(
      :ecdsa,
      :sha256,
      transaction[:transaction_hash],
      transaction[:signature],
      [transaction[:sender], :secp256k1]
    )
    #Assume every client has initial balance of 10 coins
    initialBalance=10

    balanceVerify=
    if blockchain == [] do
      true
      #initialBalance=10
      #IO.puts 'HIEEEE'
      initialBalance >= transaction[:coins] + transaction[:incentive]

    else
      #Fetch the number of coins sender has sent
      #sentCoins=Enum.filter(blockchain,fn x -> Map.get(x,:sender)== transaction[:sender] end) |> Enum.map( fn x -> Map.get(x,:c) end) |> Enum.reduce(fn x,sum -> x+sum end)
      sentCoins=
      try do
        Enum.reduce(blockchain, 0 ,fn t,accc ->
          accc+ Enum.reduce(t.transactions, 0,fn x,acc ->
          cond do
            x.sender  == transaction[:sender] -> acc + x.coins + x.incentive
            true -> acc
          end
          end)
        end)
        #IO.inspect Enum.at(ll,0)
        #IO.inspect "_____________"
        #IO.inspect ll
        #firstList=Enum.map(blockchain, fn x -> Enum.filter(x, fn {k,v} -> k == :transactions end) end)
        #Enum.map(blockchain,fn x -> x.transactions end) |>
        #Enum.filter(blockchain,fn x -> Map.get(x,:sender)== transaction[:sender] end) |> Enum.map( fn x -> Map.get(x,:c) end) |> Enum.reduce(fn x,sum -> x+sum end)
      rescue
        _ in Enum.EmptyError -> 0
      end

      #Fetch the number of coins sender has received
      receivedCoins=
      try do
        Enum.reduce(blockchain, 0 ,fn t,accc ->
          accc+ Enum.reduce(t.transactions, 0,fn x,acc ->
          cond do
            x.receiver  == transaction[:sender] -> acc + x.coins
            true -> acc
          end
          end)
        end)
      rescue
        _ in Enum.EmptyError -> 0
      end
      #Add the initial amount of coins
      receivedCoins=receivedCoins+initialBalance

      #IO.inspect blockchain
      #IO.inspect receivedCoins
      #IO.inspect sentCoins


      # True if receivedCoins is more than sent, false otherwise
      receivedCoins >= sentCoins + transaction[:coins] + transaction[:incentive]

    end
    #IO.inspect balanceVerify
    balanceVerify && hashVerify
  end

  def is_blockchain_valid(chain) do
    # chain = GenServer.call(pid, {:get_blockchain})
    Enum.reduce(Enum.slice(chain, 1, length(chain)), true, fn x, acc ->

      previous = Enum.at(chain, Enum.find_index(chain, fn k -> x == k end) - 1)
      cond do
        # end!hasValidTransactions(x) -> acc and false

        getNewHash(x) != x.currentHash -> acc and false
        x.previousHash != previous.currentHash -> acc and false
        true -> acc and true
      end
    end)
  end

  def getNewHash(block) do
    toEncrypt=Enum.map(block.transactions,fn x ->
        Enum.map(x,fn {_,v} -> v end)
      end)
      toEncrypt=toEncrypt++[block.previousHash]
      {currentHash,nonce}=miner(toEncrypt,"0")
      currentHash
  end

  def handle_call({:get_blockchain}, _from, state) do
    {blockchain, publickey, privatekey, pendingTransactions,peers}=state
    {:reply, blockchain, state}
  end

  def handle_cast({:store_peers, peers_list}, state) do
    {blockchain, publickey, privatekey, pendingTransactions, peers}=state
    peers = peers_list
    state = {blockchain, publickey, privatekey, pendingTransactions, peers}
    {:noreply, state}
  end

  def handle_call({:get_peers}, _from, state) do
    {blockchain, publickey, privatekey, pendingTransactions, peers} = state
    {:reply, peers, state}
  end

  def handle_cast({:update_blockchain, mined_blockchain}, state) do
    {blockchain, publickey, privatekey, pendingTransactions, peers} = state
    is_valid = is_blockchain_valid(mined_blockchain)
    blockchain =
    if is_valid do
        mined_blockchain
    else
        blockchain
    end
    state = {blockchain, publickey, privatekey, pendingTransactions, peers}
    {:noreply, state}
  end

end
