defmodule Proj2.Rand2D.Worker do
use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def init(:no_args) do
    {:ok, 0}
  end

  def handle_cast(:next, count) do
    if(count == 0) do
      Proj2.Rand2D.done(self())
    end

    if(count <= 9) do
      nbor_pids = Proj2.Rand2D.get_nbors(self())
      GenServer.cast(Enum.random(nbor_pids), :next)
    end

    {:noreply, count + 1}
  end

end
