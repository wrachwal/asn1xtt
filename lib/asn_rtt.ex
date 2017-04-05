defmodule ASN.RTT do

  @doc """
  Convert standard record-based ASN.1 data to more digestible map-based form.
  """
  def to_map(tuple_data, rec2kv) when is_function(rec2kv, 1) do
    conv_to(tuple_data, rec2kv)
  end

  defp conv_to({e0, e1}, rec2kv) when is_atom(e0) do
    case rec2kv.(e0) do
      nil -> %{e0 => conv_to(e1, rec2kv)} # CHOICE
      kv -> zip_seq(kv, [e1], rec2kv, [{:__record__, e0}]) |> Map.new
    end
  end
  defp conv_to(tuple, rec2kv) when is_atom(elem(tuple, 0)) do
    e0 = elem(tuple, 0)
    kv = rec2kv.(e0) || raise "#{inspect e0} is not ASN.1 record type"
    vs = tuple |> Tuple.to_list |> tl
    zip_seq(kv, vs, rec2kv, [{:__record__, e0}]) |> Map.new
  end
  defp conv_to(list, rec2kv) when is_list(list) do
    Enum.map(list, &conv_to(&1, rec2kv))
  end
  defp conv_to(val, _rec2kv) do
    val
  end

  defp zip_seq([{key, _def} | kv], [val | vs], rec2kv, acc) do
    case val do
      :asn1_NOVALUE -> zip_seq(kv, vs, rec2kv, acc) #XXX or alternatively {key, nil}
      val -> zip_seq(kv, vs, rec2kv, [{key, conv_to(val, rec2kv)} | acc])
    end
  end
  defp zip_seq([], [], _rec2kv, acc) do
    acc
  end
  defp zip_seq([], vs, _rec2kv, _acc) do
    raise "tuple too long, left #{inspect vs}"
  end
  defp zip_seq(_kv, [], _rec2kv, _acc) do
    raise "tuple too short, missing"
  end

  @doc """
  Convert expanded map-based ASN.1 data back to the standard record-based form.
  """
  def from_map(expanded_map, rec2kv) when is_function(rec2kv, 1) do
    conv_from(expanded_map, rec2kv)
  end

  defp conv_from(%{__record__: type} = map, rec2kv) do
    kd = rec2kv.(type) || raise "#{inspect type} is not ASN.1 record type"
    kv = Map.to_list(map) |> Keyword.delete_first(:__record__)
    {rem, kv} =
      Enum.reduce(kd, {kv, []}, fn {k, d}, {kv, acc} ->
        case Keyword.fetch(kv, k) do
          {:ok, v} ->
            kv = kv |> Keyword.pop_first(k) |> elem(1)
            {kv, [{k, conv_from(v, rec2kv)} | acc]}
          :error ->
            case d do
              :asn1_NOVALUE -> {kv, [{k, :asn1_NOVALUE} | acc]}
              :undefined -> raise "Missing #{inspect k} field in #{inspect type}"
              _d -> {kv, [{k, d} | acc]}
            end
        end
      end)
    rem == [] or raise "Unknown #{inspect Keyword.keys(rem)} fields in #{inspect type}"
    [type | kv |> Keyword.values |> Enum.reverse] |> List.to_tuple
  end
  defp conv_from(choice, rec2kv) when is_map(choice) do
    map_size(choice) == 1 or raise "dubious choice #{inspect Map.keys(choice)}"
    {a, v} = choice |> Map.to_list |> hd
    {a, conv_from(v, rec2kv)}
  end
  defp conv_from(list, rec2kv) when is_list(list) do
    Enum.map(list, &conv_from(&1, rec2kv))
  end
  defp conv_from(val, _rec2kv) do
    val
  end

end
