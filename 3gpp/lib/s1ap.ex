srcdir = Path.join(__DIR__, "../asn/asn_s1ap/src")

defmodule S1AP do
  require ASN.CTT
  require Record

  @external_resource asn1db = Path.join(srcdir, "asn_s1ap.asn1db")
  # generate `db/1`
  ASN.CTT.burn_asn1db(asn1db, :db)
  # summary
  |> Keyword.values()
  |> Enum.filter(&Record.is_record/1)
  |> Enum.map(&elem(&1, 0))
  |> Enum.reduce(%{}, fn rec, map -> map |> Map.put_new(rec, 0) |> update_in([rec], &(&1 + 1)) end)
  |> Enum.sort()
  |> Enum.each(fn {t, c} -> IO.puts("# S1AP/#{t} = #{c}") end)

  def decode(pdu, type \\ :"S1AP-PDU") when is_binary(pdu) do
    :asn_s1ap.decode(type, pdu)
  end

  def decode!(pdu, type \\ :"S1AP-PDU") when is_binary(pdu) do
    case decode(pdu, type) do
      {:ok, rrc} ->
        rrc
      {:error, reason} ->
        raise "#{inspect type} (#{Base.encode16(pdu)}) decode error: #{inspect reason}"
    end
  end
end
