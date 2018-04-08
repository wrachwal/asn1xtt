srcdir = Path.join(__DIR__, "../asn/asn_s1ap/src")

defmodule S1AP do
  require ASN.CTT
  require Record

  ASN.CTT.burn_asn1db(Path.join(srcdir, "asn_s1ap.asn1db"), :db)
  |> Keyword.values()
  |> Enum.filter(&Record.is_record/1)
  |> Enum.map(&elem(&1, 0))
  |> Enum.reduce(%{}, fn rec, map -> map |> Map.put_new(rec, 0) |> update_in([rec], &(&1 + 1)) end)
  |> Enum.sort()
  |> Enum.each(fn {t, c} -> IO.puts("# S1AP/#{t} = #{c}") end)
end
