defmodule ASN.Dev.Mixfile do
  use Mix.Project

  def project do
    [app: :asn_dev,
     version: "0.0.1",
     compilers: [:asn1] ++ Mix.compilers,
     asn1_paths: ["asn1"],
     asn1_options: [:ber],
     deps: deps()]
  end

  defp deps do
    [{:asn1ex0, github: "wrachwal/asn1ex0"}]
  end
end
