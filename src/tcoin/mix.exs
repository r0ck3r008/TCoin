defmodule Tcoin.MixProject do
  use Mix.Project

  def project do
    [
      app: :tcoin,
      version: "0.1.0",
      elixir: "~> 1.10.1",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:salty, "~> 0.1.3", hex: :libsalty}
    ]
  end
end
