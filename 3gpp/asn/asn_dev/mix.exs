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
    [{:asn1ex, git: "https://github.com/vicentfg/asn1ex.git"}]
  end
end
