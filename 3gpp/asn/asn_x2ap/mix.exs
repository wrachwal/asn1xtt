defmodule ASN.X2AP.Mixfile do
  use Mix.Project

  def project do
    [app: :asn_x2ap,
     version: "18.1.0",
     compilers: [:asn1] ++ Mix.compilers,
     asn1_paths: ["asn1"],
     asn1_options: [:per],  # Aligned PER
     deps: deps()]
  end

  defp deps do
    [{:asn1ex, git: "https://github.com/wrachwal/asn1ex.git"}]
  end
end
