defmodule Tapestry.Node do

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def update_route(of, num, disp_pid) do
    GenServer.cast(of, {:assign_hash, Salty.Random.uniform(10000000), disp_pid})

    #remove deadlocks
    Tapestry.Node.Helper.remove_deadlocks(num, disp_pid, num-Tapestry.Dispenser.fetch_assigned(disp_pid))
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, {}}
  end

  @impl true
  def handle_cast({:assign_hash, hash, disp_pid}, _state) do
    {:noreply,
      {Tapestry.Dispenser.assign_hash(disp_pid, self(), hash), disp_pid}
    }
  end

  @impl true
  def terminate(_, _) do
    IO.puts "Terminating Node"
  end

end
