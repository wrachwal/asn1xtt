defmodule RRC do
  require ASN.CTT

  @asn1db Path.join(__DIR__, "../asn/asn_rrc/src/asn_rrc.asn1db")

  ASN.CTT.burn_asn1db(@asn1db)

end
