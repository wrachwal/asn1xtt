srcdir = Path.join(__DIR__, "../asn/asn_dev/src")

defmodule Dev.ASN do
  require ASN.CTT
  @external_resource hrl = Path.join(srcdir, "asn_dev.hrl")
  rec2kv = ASN.CTT.burn_record(hrl)
  def record do
    unquote(Keyword.keys(rec2kv))
  end
  Enum.each(rec2kv, fn {rec, kv} ->
    def rec2kv(unquote(rec)), do: unquote(kv)
    IO.puts "# Dev.ASN.\"#{rec}\" => #{inspect kv}"
  end)
  def rec2kv(rec) when is_atom(rec), do: nil
end

defmodule Dev do
  require ASN.CTT
  require Record

  @external_resource db0 = Path.join(srcdir, "asn_dev.asn1db.0")
  # generate `db0/1`
  ASN.CTT.burn_asn1db(db0, :db0)

  @external_resource db1 = Path.join(srcdir, "asn_dev.asn1db")
  # generate `db1/1`
  ASN.CTT.burn_asn1db(db1, :db1)
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
      {:ok, dev} ->
        dev
      {:error, reason} ->
        raise "#{inspect type} (#{Base.encode16(pdu)}) decode error: #{inspect reason}"
    end
  end

  def encode(rec) when Record.is_record(rec) do
    :asn_dev.encode(elem(rec, 0), rec)
  end

  def encode!(rec) when Record.is_record(rec) do
    case encode(rec) do
      {:ok, bin} ->
        bin
      {:error, reason} ->
        raise "encode error: #{inspect reason}"
    end
  end
end
