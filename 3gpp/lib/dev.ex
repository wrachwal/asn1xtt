srcdir = Path.join(__DIR__, "../asn/asn_dev/src")

defmodule Dev do
  require ASN.CTT
  require Record

  # generate `db/1`
  ASN.CTT.burn_asn1db(Path.join(srcdir, "asn_dev.asn1db"), :db)
  # summary
  |> Keyword.values()
  |> Enum.filter(&Record.is_record/1)
  |> Enum.map(&elem(&1, 0))
  |> Enum.reduce(%{}, fn rec, map -> map |> Map.put_new(rec, 0) |> update_in([rec], &(&1 + 1)) end)
  |> Enum.sort()
  |> Enum.each(fn {t, c} -> IO.puts("# Dev/#{t} = #{c}") end)

  def decode(pdu, type) when is_binary(pdu) do
    :asn_dev.decode(type, pdu)
  end

  def decode!(pdu, type) when is_binary(pdu) do
    case decode(pdu, type) do
      {:ok, rrc} ->
        rrc
      {:error, reason} ->
        raise "#{inspect type} (#{Base.encode16(pdu)}) decode error: #{inspect reason}"
    end
  end
end
