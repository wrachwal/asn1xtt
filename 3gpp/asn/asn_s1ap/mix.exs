defmodule ASN.S1AP.Mixfile do
  use Mix.Project

  def project do
    [app: :asn_s1ap,
     version: "14.2.0",
     compilers: [:asn1] ++ Mix.compilers,
     asn1_paths: ["asn1"],
     asn1_options: [:per],  # Aligned PER
     deps: deps()]
  end

  defp deps do
    [{:asn1ex0, github: "wrachwal/asn1ex0"}]
  end
end
