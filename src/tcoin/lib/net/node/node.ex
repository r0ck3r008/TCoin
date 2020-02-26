defmodule Tcoin.Net.Node do

  use GenServer
  use Logger
  alias Tcoin.Net.Node.Helper
  alias Tcoin.Net.Dispenser
  alias Tcoin.Net.Dispenser.Hash_Helper

  def start_link do
    {:ok, agnt_pid}=Agent.start_link(fn-> %{} end)
    GenServer.start_link(__MODULE__, agnt_pid)
  end

  def update_route(of, num, disp_pid) do
    hash=Helper.hash_it(inspect of)
    GenServer.cast(of, {:assign_hash, hash, disp_pid})

    #remove deadlocks
    Helper.remove_deadlocks(num, disp_pid, num-Dispenser.fetch_assigned(disp_pid))

    nbor_t=Task.async(fn-> Hash_helper.get_nbors(disp_pid, hash) end)
    GenServer.cast(of,
      {
        :update_nbors,
        Task.await(nbor_t, :infinity)
      })
  end

  def update_route(of, node_hash) do
    GenServer.cast(of, {:assign_hash, node_hash})
    GenServer.cast(of, {:update_nbors, [[]]})
  end

  def fetch_object(srvr_pid, msg_hash) do
    GenServer.call(srvr_pid, {:fetch, msg_hash})
  end

  #callbacks
  @impl true
  def init(agnt_pid) do
    {:ok, agnt_pid}
  end

  ###########Casts##########
  @impl true
  def handle_cast({:assign_hash, hash, disp_pid}, agnt_pid) do
    {:noreply,
      {
        Dispenser.assign_hash(disp_pid, self(), hash),
        agnt_pid
      }
    }
  end

  @impl true
  def handle_cast({:assign_hash, hash}, agnt_pid) do
    {:noreply, {hash, agnt_pid}}
  end

  @impl true
  def handle_cast({:update_nbors, nbors}, {hash, agnt_pid}) do
    nbors=[[{hash, self()}]]++nbors
    {:noreply, {nbors, agnt_pid}}
  end

  @impl true
  def handle_cast({:store, msg_hash, msg}, {nbors, agnt_pid}) do
    #repurposing the agnt for storage
    Agent.update(agnt_pid, &Map.put(&1, msg_hash, [msg]))
    {:noreply, {nbors, agnt_pid}}
  end

  ###########Casts##########

  ###########Calls##########
  @impl true
  def handle_call({:fetch, msg_hash}, _from, {nbors, agnt_pid}) do
    {:reply,
      Agent.get(agnt_pid, &Map.get(&1, msg_hash)),
      {nbors, agnt_pid}
    }
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
  ###########Calls##########

  ###########publish related##########
  @impl true
  def handle_info({:publish, _msg_hash, _srvr_pid, 6}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:publish, msg_hash, srvr_pid, hops}, {nbors, agnt_pid}) do
    ret=Agent.get(agnt_pid, &Map.get(&1, msg_hash))
    if ret==nil or is_pid(Enum.at(ret, 0))==false do
      Helper.publish(nbors, agnt_pid, msg_hash, srvr_pid, hops+1)
    else
      #send to surrogate if a loop is detected
      Helper.lvl_send(Enum.at(nbors, 1),
        {:publish, msg_hash, srvr_pid, hops+1})
    end
    {:noreply, {nbors, agnt_pid}}
  end
  ###########publish related##########

  ###########route to object related##########
  @impl true
  def handle_info({:route_o, _msg_hash, _, 5}, state) do
    {:noreply, state}
  end
  @impl true
  def handle_info({:route_o, msg_hash, rqstr_pid, hops}, state) do
    Helper.route_to_obj(msg_hash, hops+1, rqstr_pid, state)
    {:noreply, state}
  end

  @impl true
  def handle_info({:route_o_r, msg_hash, ret, hops}, state) do
    obj=fetch_object(Enum.at(ret, 0), msg_hash)
    if obj != nil do
      Logger.debug("Found object #{msg_hash}: #{inspect obj} in #{hops} hops!")
    else
      Logger.debug("Found old mapping for the object that no longer exists!")
    end
    {:noreply, state}
  end
  ###########route to object related##########

  ###########Unpublish related##########
  @impl true
  def handle_info({:unpublish, _, 5}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:unpublish, msg_hash, hops}, state) do
    Helper.unpublish(msg_hash, hops+1, state)
    {:noreply, state}
  end
  ###########Unpublish related##########

  ##########new node Related#########
  @impl true
  def handle_info({:add_n, _node_hash, _node_pid, 5}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:add_n, node_hash, node_pid, hops}, {nbors, agnt_pid}) do
    new_nbors=Helper.add_node(node_hash, node_pid,
                                hops+1, {nbors, agnt_pid})
    new_nbors=if new_nbors==nil, do: nbors, else: new_nbors
    {:noreply, {new_nbors, agnt_pid}}
  end

  @impl true
  def handle_info({:welcome, sndr_hash, sndr_pid}, {nbors, agnt_pid}) do
    new_nbors=Helper.handle_welcome(sndr_hash, sndr_pid, nbors)
    new_nbors=if new_nbors==nil, do: nbors, else: new_nbors
    {:noreply, {new_nbors, agnt_pid}}
  end
  ##########new node related#########

  #########route to node related##########
  @impl true
  def handle_info({:route_n, _dest_hash, _src_pid, _acc_pid, 5}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:route_n, dest_hash, src_pid, acc_pid, hops}, {nbors, agnt_pid}) do
    lvl=Helper.next_hop(nbors, dest_hash)
    if elem(Enum.at(lvl, 0), 1)==self() do
      if self() != src_pid do
        if Process.alive?(src_pid)==true do
          send(src_pid, {:route_n_r, acc_pid, hops})
        end
      else
        Logger.warn("I tried reaching myself, took #{hops} hops!")
      end
    else
      Helper.lvl_send(lvl,
          {:route_n, dest_hash, src_pid, acc_pid, hops+1})
    end
    {:noreply, {nbors, agnt_pid}}
  end

  @impl true
  def handle_info({:route_n_r, acc_pid, hops}, state) do
    Agent.update(acc_pid, &(Enum.uniq(&1++[hops])))
    {:noreply, state}
  end
  ##########route to node related##########

end
