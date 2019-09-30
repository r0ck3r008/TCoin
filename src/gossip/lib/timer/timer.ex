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
    IO.puts("hello")
    IO.inspect "Time taken: #{GenServer.call(of, :stop_time)}"
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_cast(:init_time, _state) do
    {:noreply, System.monotonic_time(:millisecond)}
  end

  @impl true
  def handle_call(:stop_time, _from, state) do
    new_state=System.monotonic_time(:millisecond)-state
    {:reply, new_state, new_state}
  end

end
