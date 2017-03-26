defmodule ASN.RRC do
  @asn1db __DIR__ <> "/../src/asn_rrc.asn1db"
  {:ok, tab} = :ets.file2tab(String.to_charlist(@asn1db))
  @db_map :ets.tab2list(tab) |> Map.new
  def db, do: @db_map
end
