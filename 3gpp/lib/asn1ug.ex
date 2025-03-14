srcdir = Path.join(__DIR__, "../asn/asn1_ug/src")

defmodule Asn1UG do
  require ASN.CTT
  require Record

  # generate `db/1`
  ASN.CTT.burn_asn1db(Path.join(srcdir, "asn1_ug.asn1db"), :db)
  # summary
  |> Keyword.values()
  |> Enum.filter(&Record.is_record/1)
  |> Enum.map(&elem(&1, 0))
  |> Enum.reduce(%{}, fn rec, map -> map |> Map.put_new(rec, 0) |> update_in([rec], &(&1 + 1)) end)
  |> Enum.sort()
  |> Enum.each(fn {t, c} -> IO.puts("# Asn1UG/#{t} = #{c}") end)

  def encode(data, type) when is_atom(type) do
    :asn1_ug.encode(type, data)
  end

  def decode(pdu, type) when is_binary(pdu) and is_atom(type) do
    :asn1_ug.decode(type, pdu)
  end

  def decode!(pdu, type) when is_binary(pdu) and is_atom(type) do
    case decode(pdu, type) do
      {:ok, data} ->
        data
      {:error, reason} ->
        raise "#{inspect type} (#{Base.encode16(pdu)}) decode error: #{inspect reason}"
    end
  end
end
