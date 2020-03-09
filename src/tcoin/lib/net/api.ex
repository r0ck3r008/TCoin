defmodule Tcoin.Net.Api do

  require Logger
  alias Tcoin.Net.Node

  #returns the PID of the genserver
  def init_node do
    Node.start_link
  end

end
