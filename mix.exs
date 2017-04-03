defmodule Asn1xtt.Mixfile do
  use Mix.Project

  def project do
    [
      app: :asn1xtt,
      version: "0.1.0",
      elixir: "~> 1.5-dev",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:asn_rrc,  path: "asn/asn_rrc", only: [:dev, :test]}
    ]
  end
end
