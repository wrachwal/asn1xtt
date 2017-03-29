defmodule ASN.RRC do
  require Record
  @asn1db __DIR__ <> "/../src/asn_rrc.asn1db"

  {:ok, tab} = :ets.file2tab(String.to_charlist(@asn1db))
  @db_map :ets.tab2list(tab) |> Map.new

  def db do
    @db_map
  end

  Enum.each @db_map, fn {k, v} ->
    is_atom(k) or raise "not atom key #{inspect k} has value #{inspect v}"
    v = Macro.escape(v)
    def db(unquote(k)), do: unquote(v)
  end
  def db(:__type__), do: (for {k, v} <- @db_map, Record.is_record(v, :typedef), do: k) |> Enum.sort()
  def db(:__value__), do: (for {k, v} <- @db_map, Record.is_record(v, :valuedef), do: k) |> Enum.sort()
end
