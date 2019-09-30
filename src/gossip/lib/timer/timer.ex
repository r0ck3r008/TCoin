defmodule Timer do

  use GenServer

  #public API
  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def start_timer(of) do
    GenServer.cast(of, :init_time)
  end

  def end_timer(of) do
    GenServer.call(of, :stop_time)
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_cast(:init_time, _state) do
    {:noreply, :os.system_time(:milli_seconds)}
  end

  @impl true
  def handle_call(:stop_time, _from, state) do
    {:reply, :os.system_time(:milli_seconds)-state, state}
  end

end
