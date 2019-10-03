defmodule Proj2.Rand2DPS.Worker do
  use GenServer

  def start_link(i) do
    GenServer.start_link(__MODULE__, i)
  end

  def init(i) do
    w = 1
    sum_est = i/w
    {:ok, {i, w, sum_est, 0, 0}}
  end

  def handle_cast({:next, s_rec, w_rec}, {s, w, sum_est, counter, flag}) do
    w_new = w + w_rec
    s_new = s + s_rec
    curr_sum_est = s_new / w_new
    #w_send = (w + w_rec)/2
    #s_send = (s + s_rec)/2
    #curr_sum_est = s_send / w_send
    change = abs(curr_sum_est - sum_est)
    threshold = :math.pow(10, -10)

    flag =
    if(counter == 2 && change < threshold) do
      #Proj2.Rand2DPS.term(self())
      1
    end

    counter =
    if(counter == 2 && change < threshold) do
      Proj2.Rand2DPS.term(self())
      counter + 1
    else
      if (counter < 3 && flag ==0) do
        nbor_pids = Proj2.Rand2DPS.get_nbors(self())
        next_pid = Enum.random(nbor_pids)
        w_send = w_new/2
        s_send = s_new/2
        GenServer.cast(next_pid, {:next, s_send, w_send})
        w_new = w_send
        s_new = s_send
        #curr_sum_est = s_new/w_new
      end

      if(change > threshold && flag ==0) do
        0
      else
        counter + 1
      end
    end

    curr_sum_est = s_new/w_new

    {:noreply, {s_new, w_new, curr_sum_est, counter, flag}}
  end
end
