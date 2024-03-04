defmodule Asn1xtt.Mixfile do
  use Mix.Project

  def project do
    [
      app: :asn1xtt,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  defp elixirc_paths(env) when env in [:dev, :test] do
    ["3gpp/lib", "lib"]
  end
  defp elixirc_paths(_env) do
    ["lib"]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, {:asn1, :optional}]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:asn_rrc,  path: "3gpp/asn/asn_rrc", only: [:dev, :test]},
     {:asn_s1ap,  path: "3gpp/asn/asn_s1ap", only: [:dev, :test]},
     {:asn_x2ap,  path: "3gpp/asn/asn_x2ap", only: [:dev, :test]}]
  end
end
