defmodule Tapestry.Node do

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def update_route(of, num, disp_pid) do
    hash=String.slice(Base.encode16(elem(Salty.Hash.Sha256.hash(inspect of), 1)), 0, 16)
    GenServer.cast(of, {:assign_hash, hash, disp_pid})

    #remove deadlocks
    Tapestry.Node.Helper.remove_deadlocks(num, disp_pid, num-Tapestry.Dispenser.fetch_assigned(disp_pid))

    nbors=Tapestry.Dispenser.Hash_helper.get_nbors(disp_pid, hash)
    GenServer.cast(of, {:update_nbors, nbors})
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, {}}
  end

  @impl true
  def handle_cast({:assign_hash, hash, disp_pid}, _state) do
    {:noreply,
      Tapestry.Dispenser.assign_hash(disp_pid, self(), hash)
    }
  end

  @impl true
  def handle_cast({:update_nbors, nbors}, hash) do
    #remove self
    nbors=Enum.uniq([{hash, self()}]++nbors)
    IO.inspect nbors
    {:noreply, {nbors, hash}}
  end

  @impl true
  def terminate(_, _) do
    IO.puts "Terminating Node"
  end

end
