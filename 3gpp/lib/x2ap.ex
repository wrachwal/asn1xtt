defmodule X2AP do
  require ASN.CTT

  @asn1db Path.join(__DIR__, "../asn/asn_x2ap/src/asn_x2ap.asn1db")

  ASN.CTT.burn_asn1db(@asn1db)

end
