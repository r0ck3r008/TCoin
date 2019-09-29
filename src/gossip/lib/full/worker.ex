defmodule Full.Worker do

  use GenServer

  #public API
  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def update_nbor_state(to, agnt_pid, main_pid) do
    nbor_pids=for {_, val}<-Agent.get(agnt_pid, fn(state)->state end), do: val
    GenServer.cast(to, {:update_nbors, nbor_pids++main_pid})
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:update_nbors, nbors}, _state) do
    {:noreply, nbors}
  end

end
