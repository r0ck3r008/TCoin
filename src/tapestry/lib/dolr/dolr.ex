defmodule Tapestry.Dolr do

  def publish(msg, srvr_pid) do
    msg_hash=Tapestry.Node.Helper.hash_it(msg)
    send(srvr_pid, {:store, msg_hash, msg})
    send(srvr_pid, {:publish, msg_hash, srvr_pid, 0})
  end

  def route_to_obj(msg, rqstr_pid) do
    msg_hash=Tapestry.Node.Helper.hash_it(msg)
    send(rqstr_pid, {:route_o, msg_hash, rqstr_pid, 0})
  end

end
