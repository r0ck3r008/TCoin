defmodule PushSum do

  #called inside the sender's public API
  def send_rum(wrkr_mod, from) do
    [_|nbors]=wrkr_mod.get_nbors(from)
    {s_i, w_i}=wrkr_mod.get_s_w(from)
    wrkr_mod.half_s_w(from)

    #broadcast select rand neighbour
    rand_num=Salty.Random.uniform(length(nbors))
    nbor=Enum.at(nbors, rand_num)
    recv_rum(wrkr_mod, nbor, {s_i/2, w_i/2})
  end

  #called inside the receiver's public API
  def recv_rum(wrkr_mod, to, {s, w}) do
    n_round=wrkr_mod.get_round(to)
    {s_i, w_i}=wrkr_mod.get_s_w(to)

    if floor(((s_i+s)/(w_i+w))-(s_i/w_i))==0 do
      case n_round do
        2->
          wrkr_mod.inc_round(to)
          wrkr_mod.converge(to)
          send_rum(wrkr_mod, to)
        3->
          :ok
        _->
          wrkr_mod.inc_round(to)
          send_rum(wrkr_mod, to)
      end

    else
      #just send along
      wrkr_mod.reset_round(to)
      send_rum(wrkr_mod, to)
    end
  end

end
