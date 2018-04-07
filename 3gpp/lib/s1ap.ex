defmodule S1AP do
  require ASN.CTT

  @asn1db Path.join(__DIR__, "../asn/asn_s1ap/src/asn_s1ap.asn1db")

  ASN.CTT.burn_asn1db(@asn1db, :db)

end
