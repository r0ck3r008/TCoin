defmodule Line.Worker do

  use GenServer

  #public API
  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def update_nbor_state(pid, num, agnt_pid, pos) do
    nbor_co_ords=get_nbor_co_ords(pos, num, {-1, +1}, [], 0)
    GenServer.cast(pid, {
      :update_nbor_state,
      [
        Agent.get(agnt_pid, &Map.get(&1, Enum.at(nbor_co_ords, 0))),
        Agent.get(agnt_pid, &Map.get(&1, Enum.at(nbor_co_ords, 1)))
      ]
    })
  end

  def get_nbor_co_ords(0, nbors, dlta_mat, 0), do: get_nbor_co_ords(0, nbors, dlta_mat, 1)
  def get_nbor_co_ords(pos, num, nbors, _dlta_mat, count) when pos==num-1, do: get_nbor_co_ords(pos, num, nbors, {-1, -1}, count+1)
  def get_nbor_co_ords(_pos, nbors, _dlta_mat, 2), do: nbors
  def get_nbor_co_ords(pos, nbors, dlta_mat, count) do
    get_nbor_co_ords(
      pos,
      nbors++[pos+elem(dlta_mat, count)],
      dlta_mat,
      count+1
    )
  end

  #callbacks
  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:update_nbor_state, nbors}, _state) do
    {:no_reply, nbors}
  end

end
