defmodule ASN.RRC.Mixfile do
  use Mix.Project

  def project do
    [app: :asn_rrc,
     version: "14.2.1",
     compilers: [:asn1] ++ Mix.compilers,
     asn1_paths: ["asn1"],
     asn1_options: [:uper,        # Unaligned PER
                    :undec_rest], # to decode MIB/SIB(s) with 0 padding
     deps: deps()]
  end

  defp deps do
    [{:asn1ex, git: "https://github.com/wrachwal/asn1ex.git"}]
  end
end
