defmodule RRC do
  require ASN.CTT

  @asn1db Path.join(__DIR__, "../asn/asn_rrc/src/asn_rrc.asn1db")

  #
  # db/0
  #
  {:ok, tab} = :ets.file2tab(String.to_charlist(@asn1db))
  @db_map :ets.tab2list(tab) |> Map.new

  def db do
    @db_map
  end

  #
  # db/1
  #
  ASN.CTT.burn_asn1db(@asn1db)

end
