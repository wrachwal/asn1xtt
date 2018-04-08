defmodule RRC do
  require ASN.CTT
  require Record

  @asn1db Path.join(__DIR__, "../asn/asn_rrc/src/asn_rrc.asn1db")

  ASN.CTT.burn_asn1db(@asn1db, :db)
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
