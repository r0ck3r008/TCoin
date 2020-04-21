defmodule Bitcoin.Client do
    use GenServer
    alias Bitcoin.Miner
    alias Bitcoin.Helpers

    def create_wallet() do
        {:ok,pid}=GenServer.start_link(__MODULE__, :ok,[])
        pid
    end
    def init(:ok) do
        {public_key, private_key} = :crypto.generate_key(:ecdh, :secp256k1)
        {:ok, {public_key, private_key, "", "", 0, "",[], []}}
    end

    def create_transaction(pid, receiver, coins, incentive) do
        timestamp = Integer.to_string(:os.system_time(:millisecond))
        GenServer.cast(pid, {:updatePIDState, receiver, coins, timestamp})
        transaction_hash = sign_transaction(pid)
        {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain} = get_transaction_details(pid)
        %{:sender => state_public_key, :receiver => state_receiver, :transaction_hash => transaction_hash,
            :coins => state_coins, :signature => state_signature, :incentive => incentive}
    end


    def handle_cast({:updatePIDState, receiver, coins, timestamp}, state) do
        {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain} = state
        state_receiver = receiver
        state_coins = coins
        state_timestamp = timestamp
        state = {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain}
        {:noreply, state}
    end

    def handle_cast({:update_blockchain, mined_blockchain}, state) do
        {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain} = state
        is_valid = Miner.is_blockchain_valid(mined_blockchain)
        blockchain =
        if is_valid do
            mined_blockchain
        else
            blockchain
        end
        state = {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain}
        {:noreply, state}
    end
    def calculate_hash(keys) do
        hash = Helpers.calculate_hash(keys)
        hash
    end

    def sign_transaction(pid) do
        # private_key = GenServer.call(pid, {:get_private_key})
        {public_key, private_key, receiver, signature, coins, timestamp, peers, blockchain} = get_transaction_details(pid)
        transaction_hash = calculate_hash([public_key, receiver, coins, timestamp])
        signature=
            :crypto.sign(
                :ecdsa,
                :sha256,
                transaction_hash,
                [private_key, :secp256k1]
            )
        GenServer.cast(pid, {:set_signature, signature})
        transaction_hash
    end

    # def handle_call({:get_private_key}, _from, state) do
    #     {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp} = state
    #     {:reply, state_private_key, state}
    # end
    def handle_cast({:store_peers, peers_list}, state) do
        {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain} = state
        peers = peers_list
        state = {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain}
        {:noreply, state}
    end

    def handle_call({:get_peers}, _from, state) do
        {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain} = state
        {:reply, peers, state}
    end

    # def handle_call({:get_return_data}, _from, state) do
    #     {:reply, %{"a" => 20}, state}
    # end
    def handle_call({:get_public_key}, _from, state) do
        {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain} = state
        {:reply, state_public_key, state}
    end

    def handle_call({:get}, _from, state) do
        {:reply, 20, state}
    end

    def handle_call({:get_chain_data}, _from, state) do
        {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain} = state
        returning_data=%{}
        #Get the number of transactions
        number_of_transactions=Enum.reduce(blockchain, 0 ,fn t,accc ->
             accc+ length(t.transactions)
        end)
        number_of_coins_transacted = Enum.reduce(blockchain, 0 ,fn t,accc ->
            accc+ Enum.reduce(t.transactions, 0,fn x,acc ->
              acc + x.coins + x.incentive
            end)
        end)
        number_of_coins_mined = Enum.reduce(blockchain, 0 ,fn t,accc ->
            accc+ Enum.reduce(t.transactions, 0,fn x,acc ->
            cond do
              x.sender == "" -> acc + x.coins + x.incentive
              true -> acc
            end
            end)
          end)
        number_of_coins = number_of_coins_transacted - number_of_coins_mined
        
        number_of_blocks = length(blockchain)
        returning_data=Map.put(returning_data,:number_of_transactions,number_of_transactions)
        returning_data = Map.put(returning_data, :number_of_blocks, number_of_blocks)
        returning_data = Map.put(returning_data, :clients, 80)
        returning_data = Map.put(returning_data, :miners, 20)
        returning_data = Map.put(returning_data, :number_of_coins_transacted, number_of_coins)
        returning_data = Map.put(returning_data, :number_of_coins_mined, number_of_coins_mined)
        {:reply, returning_data, state}
    end

    def handle_cast({:set_signature, signature}, state) do
        {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain} = state
        state_signature = signature
        state = {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain}
        {:noreply, state}
    end

    def get_transaction_details(pid) do
        GenServer.call(pid, {:get_transaction_details}, 100000)
    end

    def handle_call({:get_transaction_details}, _from, state) do
        {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain} = state
        {:reply, {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain}, state}
    end

    def handle_call({:get_blockchain}, _from, state) do
        {state_public_key, state_private_key, state_receiver, state_signature, state_coins, state_timestamp, peers, blockchain} = state
        {:reply, blockchain, state}
    end
end

