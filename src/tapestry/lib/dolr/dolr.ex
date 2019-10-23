defmodule Tapestry.Dolr do

  def publish(srvr_pid, msg) do
    msg_hash=Tapestry.Node.Helper.hash_it(msg)
    send(srvr_pid, {:publish, msg_hash, srvr_pid, 0})
  end

end
