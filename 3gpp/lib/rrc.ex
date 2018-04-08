srcdir = Path.join(__DIR__, "../asn/asn_rrc/src")

defmodule RRC.ASN do
  require ASN.CTT
  rec2kv = ASN.CTT.burn_record(Path.join(srcdir, "asn_rrc.hrl"))
  def record do
    unquote(Keyword.keys(rec2kv))
  end
  Enum.each(rec2kv, fn {rec, kv} ->
    def rec2kv(unquote(rec)), do: unquote(kv)
  end)
  def rec2kv(rec) when is_atom(rec), do: nil
end

defmodule RRC do
  require ASN.CTT
  require Record

  ASN.CTT.burn_asn1db(Path.join(srcdir, "asn_rrc.asn1db"), :db)
  |> Keyword.values()
  |> Enum.filter(&Record.is_record/1)
  |> Enum.map(&elem(&1, 0))
  |> Enum.reduce(%{}, fn rec_t, acc ->
    acc |> Map.put_new(rec_t, 0) |> update_in([rec_t], &(&1 + 1))
  end)
  |> Enum.sort()
  |> Enum.each(fn {t, c} -> IO.puts("# RRC/#{t} = #{c}") end)

# XXX we can tail clauses to change behavior of burned definition in case of unknown input
# def db(name) when is_atom(name), do: nil

end
