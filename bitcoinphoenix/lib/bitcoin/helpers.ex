defmodule Bitcoin.Helpers do
  def genereateKeys() do
    :crypto.generate_key(:ecdh, :secp256k1)
  end

  def calculate_hash(key_list) do
    :crypto.hash(:sha256, key_list) |> Base.encode16
  end
end


