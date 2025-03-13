defmodule ASN1.UG.Mixfile do
  use Mix.Project

  def project do
    [app: :asn1_ug,  ## https://www.erlang.org/doc/apps/asn1/asn1_getting_started.html
     version: "0.0.1",
     compilers: [:asn1] ++ Mix.compilers,
     asn1_paths: ["asn"],
     asn1_options: [:ber],
     deps: deps()]
  end

  defp deps do
    [{:asn1ex, git: "https://github.com/wrachwal/asn1ex.git"}]
  end
end
