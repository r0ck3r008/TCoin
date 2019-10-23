defmodule Tapestry.Node do

  use GenServer

  def start_link do
    {:ok, agnt_pid}=Agent.start_link(fn-> %{} end)
    GenServer.start_link(__MODULE__, agnt_pid)
  end

  def update_route(of, num, disp_pid) do
    hash=Tapestry.Node.Helper.hash_it(inspect of)
    GenServer.cast(of, {:assign_hash, hash, disp_pid})

    #remove deadlocks
    Tapestry.Node.Helper.remove_deadlocks(num, disp_pid, num-Tapestry.Dispenser.fetch_assigned(disp_pid))

    nbor_t=Task.async(fn-> Tapestry.Dispenser.Hash_helper.get_nbors(disp_pid, hash) end)
    GenServer.cast(of,
      {
        :update_nbors,
        Task.await(nbor_t, :infinity)
      })
  end

  #callbacks
  @impl true
  def init(agnt_pid) do
    {:ok, agnt_pid}
  end

  @impl true
  def handle_cast({:assign_hash, hash, disp_pid}, agnt_pid) do
    {:noreply,
      {
        Tapestry.Dispenser.assign_hash(disp_pid, self(), hash),
        agnt_pid
      }
    }
  end

  @impl true
  def handle_cast({:update_nbors, nbors}, {hash, agnt_pid}) do
    #remove self
    nbors=[{hash, self()}]++nbors
    IO.inspect nbors
    {:noreply, {nbors, agnt_pid}}
  end


  @impl true
  def handle_info({:publish, msg_hash, srvr_pid, 1000}, state) do
    IO.puts "#{msg_hash} unpublished"
    {:noreply, state}
  end

  @impl true
  def handle_info({:publish, msg_hash, srvr_pid, hops}, {nbors, agnt_pid}) do
    if Agent.get(agnt_pid, &Map.get(&1, msg_hash))==nil do
      Tapestry.Node.Helper.publish(nbors, agnt_pid, msg_hash, srvr_pid, hops+1)
    else
      #send to surrogate if a loop is detected
      IO.puts "sending to surrogate"
      send(elem(Enum.at(tl(nbors), 0), 1), {:publish, msg_hash, srvr_pid, hops+1})
    end
    {:noreply, {nbors, agnt_pid}}
  end

  @impl true
  def terminate(_, {nbors, _}) do
    IO.puts "Terminating Node #{elem(hd(nbors), 0)}"
  end

end
