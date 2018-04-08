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

  # generate `db/1`
  ASN.CTT.burn_asn1db(Path.join(srcdir, "asn_rrc.asn1db"), :db)
  # summary
  |> Keyword.values()
  |> Enum.filter(&Record.is_record/1)
  |> Enum.map(&elem(&1, 0))
  |> Enum.reduce(%{}, fn rec, map -> map |> Map.put_new(rec, 0) |> update_in([rec], &(&1 + 1)) end)
  |> Enum.sort()
  |> Enum.each(fn {t, c} -> IO.puts("# RRC/#{t} = #{c}") end)

# XXX we can tail clauses to change behavior of burned definition in case of unknown input
# def db(name) when is_atom(name), do: nil

  @pad0channels [
    :"BCCH-BCH-Message",
    :"BCCH-DL-SCH-Message",
    :"BCCH-DL-SCH-Message-BR",
    :"PCCH-Message",
    :"BCCH-BCH-Message-NB",
    :"BCCH-DL-SCH-Message-NB",
    :"PCCH-Message-NB"
  ]

  def decode(pdu, type) when is_binary(pdu) do
    case :asn_rrc.decode(type, pdu) do
      {:ok, rrc, rest} when bit_size(rest) < 8 ->
        {:ok, rrc}
      {:ok, rrc, rest} -> # rrc is compiled with :undec_rest asn1_options, see asn_rrc's mix.exs
        pad_len = bit_size(rest)
        if rest == <<0::size(pad_len)>> and type in @pad0channels do
          {:ok, rrc}
        else
          {:error, {:undec_rest, type, pdu, rest}}
        end
      {:error, _} = error ->
        error
    end
  end

  def decode!(pdu, type) when is_binary(pdu) do
    case decode(pdu, type) do
      {:ok, rrc} ->
        rrc
      {:error, {:undec_rest, _, _, rest}} ->
        raise "#{inspect type} (#{Base.encode16(pdu)}) decoded with rest #{inspect rest}"
      {:error, reason} ->
        raise "#{inspect type} (#{Base.encode16(pdu)}) decode error: #{inspect reason}"
    end
  end
end
