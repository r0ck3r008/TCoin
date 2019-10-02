defmodule Gosp do

  #called inside the sender's public API
  def send_rum(wrkr_mod, from) do
    [_|nbors]=wrkr_mod.get_nbors(from)

    #broadcast select rand neighbour
    rand_num=Salty.Random.uniform(length(nbors))
    nbor=Enum.at(nbors, rand_num)
    recv_rum(wrkr_mod, nbor)
  end

  #called inside the receiver's public API
  def recv_rum(wrkr_mod, to) do
    n_rounds=wrkr_mod.get_round(to)
    case n_rounds do
      9->
        wrkr_mod.converge(to)
      10->
        :ok
      _->
        wrkr_mod.inc_round(to)
        #send back out again
        send_rum(wrkr_mod, to)
    end
  end

end
