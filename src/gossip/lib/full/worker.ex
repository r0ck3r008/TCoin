defmodule Full.Worker do

  use GenServer

  #public API
  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def update_nbor_state(to, agnt_pid) do
    GenServer.cast(to, {:update_nbors, Agent.get(agnt_pid, fn(state)->state end})
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:update_nbors, nbors}, _state) do
    {:no_reply, nbors}
  end

end
