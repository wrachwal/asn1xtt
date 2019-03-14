defmodule ASN.CDB do
  import ASN.CTT, only: :macros

  @scalar1 ASN.CTT.scalar1()
  @scalar2 ASN.CTT.scalar2()

  def scalar?(scalar) when scalar in @scalar1, do: true
  def scalar?({scalar, _}) when scalar in @scalar2, do: true
  def scalar?(_other), do: false

  def explore(db, type) when is_atom(type) do
    %{}
    |> explore(db, type)
    |> explore_undef(db)
  end
  def explore(db, types) when is_list(types) do
    types
    |> Enum.reduce(%{}, &explore(&2, db, &1))
    |> Map.put_new(:__REF__, %{})
    |> explore_undef(db)
  end

  def explore_undef(%{__REF__: tref} = map, db) do
    case tref |> Enum.reject(&(scalar?(elem(&1, 0)) or elem(&1, 1) > 0)) |> Enum.map(&elem(&1, 0)) do
      [] ->
        map
      undefs ->
        undefs
        |> Enum.reduce(map, &explore(&2, db, &1))
        |> explore_undef(db)
    end
  end

  def explore(map, db, type) do
    map
    |> Map.put_new(:__REF__, %{})
    |> exp(db.(type), [])
  end

  defp tref(%{__REF__: tref} = map, type) do
    tref = Map.update(tref, type, -1, fn
      cnt when cnt < 0 -> cnt - 1
      cnt -> cnt + 1
    end)
    Map.put(map, :__REF__, tref)
  end

  defp tdef(%{__REF__: tref} = map, type) do
    tref = Map.update(tref, type, 1, fn
      cnt when cnt < 0 -> -cnt + 1
      cnt -> cnt + 1
    end)
    Map.put(map, :__REF__, tref)
  end

  defp exp(map, typedef(name: name, typespec: type(def: type)), []) do
    case map do
      %{__REF__: %{^name => cnt}} when cnt > 0 ->
        map
      %{} ->
        map
        |> tdef(name)
        |> exp(type, [name])
    end
  end

  defp exp(map, sequence(components: comps, extaddgroup: :undefined), ts) do
    exp_comps(map, :SEQUENCE, comps, ts)
  end
  defp exp(map, sequence(components: comps, extaddgroup: exts), ts) do
    map
    |> exp_comps(:SEQUENCE, comps, ts)
    |> exp_comps(:SEQUENCE, exts, ts)
  end

  defp exp(map, {:CHOICE, comps}, ts) do
    exp_comps(map, :CHOICE, comps, ts)
  end

  defp exp(map, {:"SEQUENCE OF", type(def: type)}, ts) do
    map |> exp(type, ["SEQOF" | ts])
  end

  defp exp(map, {:"SET OF", type(def: type)}, ts) do
    map |> exp(type, ["SETOF" | ts])
  end

  defp exp(map, extyperef(type: type), _ts) do
    map |> tref(type)
  end

  defp exp(map, {:ENUMERATED, _kv}, _ts) do
    map
  end

  defp exp(map, scalar, _ts) when scalar in @scalar1, do: map
  defp exp(map, {scalar, _}, _ts) when scalar in @scalar2, do: map

  defp exp_comps(map, cont, {comps, exts}, ts) do
    map
    |> comps_list(cont, comps, ts)
    |> comps_list(cont, exts, ts)
  end
  defp exp_comps(map, cont, comps, ts) do
    comps_list(map, cont, comps, ts)
  end

  defp comps_list(map, cont, [h | t], ts) do
    map
    |> comp(cont, h, ts)
    |> comps_list(cont, t, ts)
  end
  defp comps_list(map, _cont, [], _ts) do
    map
  end

  defp comp(map, :SEQUENCE, comptype(name: en, typespec: type(def: type), prop: _prop, textual_order: ei), ts) do
    fts = [Atom.to_string(en) | ts]
    IO.puts "SEQUENCE #{inspect Enum.reverse(ts)} => #{inspect en} | #{ei} | #{inspect field_type(type, fts)}"
    map |> exp(type, fts)
  end
  defp comp(map, :CHOICE, comptype(name: en, typespec: type(def: type), prop: _prop, textual_order: :undefined), ts) do
    fts = [Atom.to_string(en) | ts]
    IO.puts "CHOICE #{inspect Enum.reverse(ts)} => #{inspect en} | #{inspect field_type(type, fts)}"
    map |> exp(type, fts)
  end
  defp comp(map, _cont, extaddgroup(), _ts), do: map
  defp comp(map, _cont, :ExtensionAdditionGroupEnd, _ts), do: map
  #XXX DB0
  defp comp(map, _cont, extmark(), _ts), do: map

  defp field_type(extyperef(type: type), _ts), do: type
  defp field_type(sequence(), ts), do: ts_atom(ts)
  defp field_type({:CHOICE, _}, _ts), do: nil
  defp field_type({:"SEQUENCE OF", _}, _ts), do: nil
  defp field_type({:"SET OF", _}, _ts), do: nil
  defp field_type(scalar, _ts) when scalar in @scalar1, do: scalar
  defp field_type({scalar, _} = type, _ts) when scalar in @scalar2, do: type

  defp ts_atom(ts) do
    ts |> Enum.reverse() |> Enum.join("_") |> String.to_existing_atom()
  end

end
