defmodule Bitcoinphoenix.Repo do
  use Ecto.Repo,
    otp_app: :bitcoinphoenix,
    adapter: Ecto.Adapters.Postgres
end
