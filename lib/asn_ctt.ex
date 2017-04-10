defmodule ASN.CTT do
  require Record
  @asn1_hrl "asn1/src/asn1_records.hrl"

  @venc :__version_and_erule__

  asn1_records = Record.extract_all(from_lib: @asn1_hrl)

  for {rec, tag} <- %{typedef: nil,
                      valuedef: nil,
                      classdef: nil,
                      module: nil,
                      type: nil,
                      SEQUENCE: :sequence,
                      Externaltypereference: :extyperef,
                      ComponentType: :comptype,
                      ExtensionAdditionGroup: :extaddgroup,
                    } do
    Record.defrecord tag || rec, rec, asn1_records[rec]
  end

  # --------------------------------------------------------------------------

  defmacro burn_asn1db(asn1db) do
    quote bind_quoted: [asn1db: asn1db] do
      require Record
      kv_list = ASN.CTT.__asn1db_kv(asn1db)
      Enum.each kv_list, fn {k, v} ->
        is_atom(k) or raise "not atom key #{inspect k} has value #{inspect v}"
        v = Macro.escape(v)
        def db(unquote(k)), do: unquote(v)
      end
    end
  end

  @doc false
  def __asn1db_kv(asn1db) do
    {:ok, tab} = :ets.file2tab(String.to_charlist(asn1db))
    tab_kv = :ets.tab2list(tab)
    kind_map = Enum.reduce(tab_kv, %{}, &asn1db_reduce_kv/2)
    tab_kv = [{:__asn1db__, kind_map |> Map.keys() |> Enum.sort()} | tab_kv]
    for {kind, keys} <- kind_map, into: tab_kv do
      {kind, Enum.reverse(keys)}
    end
  end

  defp asn1db_reduce_kv({k, typedef()}, map), do: asn1db_put_kind(map, :__typedef__, k)
  defp asn1db_reduce_kv({k, valuedef()}, map), do: asn1db_put_kind(map, :__valuedef__, k)
  defp asn1db_reduce_kv({k, _}, map), do: asn1db_put_kind(map, k, k)

  defp asn1db_put_kind(map, kind, k) do
    map
    |> Map.put_new(kind, [])
    |> update_in([kind], &([k | &1]))
  end

  # --------------------------------------------------------------------------

  def asn_type_use(db) do
    Enum.reduce(db, %{}, fn
      {type, typedef(name: type) = tdef}, tref -> tref_typedef(tref, tdef)
      {_, rec}, tref when elem(rec, 0) in [:valuedef, :classdef, :module] -> tref
      {@venc, _}, tref -> tref
    end)
  end

  defp tref_typedef(tref, typedef(name: name, typespec: spec)) do
    tref |> inckey(name) |> tref_typespec(spec)
  end

  defp tref_typespec(tref, type(def: def)) do
    tref_def(tref, def)
  end

  defp tref_def(tref, :INTEGER), do: tref
  defp tref_def(tref, :"OCTET STRING"), do: tref
  defp tref_def(tref, :BOOLEAN), do: tref
  defp tref_def(tref, :NULL), do: tref
  defp tref_def(tref, :"OBJECT IDENTIFIER"), do: tref
  defp tref_def(tref, :"ObjectDescriptor"), do: tref
  defp tref_def(tref, :ANY), do: tref
  defp tref_def(tref, {:ENUMERATED, _}), do: tref
  defp tref_def(tref, {:"BIT STRING", _}), do: tref
  defp tref_def(tref, sequence(components: comps, extaddgroup: :undefined)) do
    tref_components(tref, comps)
  end
  defp tref_def(tref, sequence(components: comps, extaddgroup: exts)) do
    tref |> tref_components(comps) |> tref_components(exts)
  end
  defp tref_def(tref, {:"SEQUENCE OF", type() = type}) do
    tref_typespec(tref, type)
  end
  defp tref_def(tref, {:CHOICE, comps}) when is_list(comps) do
    tref_components(tref, comps)
  end
  defp tref_def(tref, {:CHOICE, {comps, exts}}) do
    tref |> tref_components(comps) |> tref_components(exts)
  end
  defp tref_def(tref, extyperef(type: type)) do
    inckey(tref, type)
  end

  defp tref_components(tref, {comps, exts}) when is_list(comps) and is_list(exts) do
    tref |> tref_comp_list(comps) |> tref_comp_list(exts)
  end
  defp tref_components(tref, comps) when is_list(comps) do
    tref |> tref_comp_list(comps)
  end

  defp tref_comp_list(tref, [comp | comps]) do
    tref_comp_list(tref_comp(tref, comp), comps)
  end
  defp tref_comp_list(tref, []) do
    tref
  end

  defp tref_comp(tref, extaddgroup()), do: tref
  defp tref_comp(tref, :ExtensionAdditionGroupEnd), do: tref
  defp tref_comp(tref, comptype(typespec: spec)) do
    tref_typespec(tref, spec)
  end

  defp inckey(map, key) do
    map |> Map.put_new(key, 0) |> update_in([key], &(&1 + 1))
  end

  # --------------------------------------------------------------------------

  def asn_type_kind(db) do
    for {type, typedef()} <- db, into: %{} do
      {type, asn_type_kind(db, type)}
    end
  end

  def asn_type_kind(db, type) do
    typedef(name: ^type, typespec: spec) = db[type]
    type(def: def) = spec
    case def do
      rec when tuple_size(rec) > 1 -> elem(rec, 0)
      basic when is_atom(basic) -> basic
    end
  end

  # --------------------------------------------------------------------------

  def kind_mapping(:"BIT STRING"), do: :scalar
  def kind_mapping(:BOOLEAN), do: :scalar
  def kind_mapping(:CHOICE), do: :record
  def kind_mapping(:ENUMERATED), do: :scalar
  def kind_mapping(:Externaltypereference), do: :typedef
  def kind_mapping(:INTEGER), do: :scalar
  def kind_mapping(:"OCTET STRING"), do: :scalar
  def kind_mapping(:SEQUENCE), do: :record
  def kind_mapping(:"SEQUENCE OF"), do: :list

  def asn_roots(db) do
    for {type, 1} <- asn_type_use(db), not kind_mapping(asn_type_kind(db, type)) in [:scalar] do
      type
    end |> Enum.sort()
  end

  # --------------------------------------------------------------------------

  @list :LIST
  @alt  :ALT

  @scalar1 [:INTEGER, :BOOLEAN, :"OCTET STRING", :NULL]
  @scalar2 [:ENUMERATED, :"BIT STRING"]

  def search_field(db, node, goal) do
    search_field(db, node, goal, [], [])
  end

  defp search_field(_db, _node, [], _pl, acc), do: acc
  defp search_field(db, typedef(name: gh, typespec: spec), [gh | gt], pl, acc),
    do: search_field(db, spec, gt, pl, [{gt, pl} | acc])
  defp search_field(db, typedef(name: _, typespec: spec), gl, pl, acc),
    do: search_field(db, spec, gl, pl, acc)
  defp search_field(db, type(def: def), gl, pl, acc),
    do: search_field(db, def, gl, pl, acc)
  defp search_field(db, extyperef(type: type), gl, pl, acc) when is_atom(type),
    do: search_field(db, db.(type), gl, pl, acc)
  defp search_field(db, sequence(components: comps, extaddgroup: :undefined), gl, pl, acc),
    do: search_components(db, comps, gl, pl, acc)
  defp search_field(db, sequence(components: comps, extaddgroup: exts), gl, pl, acc),
    do: search_components(db, exts, gl, pl, search_components(db, comps, gl, pl, acc))
  defp search_field(db, {:CHOICE, comps}, gl, pl, acc),
    do: search_components(db, comps, gl, pl, acc)
  defp search_field(db, {:"SEQUENCE OF", type() = type}, gl, pl, acc),
    do: search_field(db, type, gl, [@list | pl], acc)
  defp search_field(_db, {scalar, _}, _gl, _pl, acc) when scalar in @scalar2, do: acc
  defp search_field(_db, scalar, _gl, _pl, acc) when scalar in @scalar1, do: acc

  defp search_components(db, {comps, exts}, gl, pl, acc),
    do: search_comps_list(db, exts, gl, pl, search_comps_list(db, comps, gl, pl, acc))
  defp search_components(db, comps, gl, pl, acc) when is_list(comps),
    do: search_comps_list(db, comps, gl, pl, acc)

  defp search_comps_list(db, [comp | comps], gl, pl, acc),
    do: search_comps_list(db, comps, gl, pl, search_comp(db, comp, gl, pl, acc))
  defp search_comps_list(_db, [], _gl, _pl, acc), do: acc

  defp search_comp(db, comptype(name: gh, typespec: spec, prop: prop, textual_order: ei), [gh | gt], pl, acc) do
    pl_new = [{gh, textual_order(ei), prop(prop)} | pl]
    search_field(db, spec, gt, pl_new, [{gt, pl_new} | acc])
  end
  defp search_comp(db, comptype(name: en, typespec: spec, prop: prop, textual_order: ei), gl, pl, acc),
    do: search_field(db, spec, gl, [{en, textual_order(ei), prop(prop)} | pl], acc)
  defp search_comp(_db, extaddgroup(), _gl, _pl, acc), do: acc
  defp search_comp(_db, :ExtensionAdditionGroupEnd, _gl, _pl, acc), do: acc

  defp prop(:mandatory), do: :mandatory
  defp prop(:OPTIONAL), do: :OPTIONAL
  defp prop({:DEFAULT, _} = default), do: default

  defp textual_order(pos) when is_integer(pos), do: pos
  defp textual_order(:undefined), do: @alt

  # --------------------------------------------------------------------------

  def dump_to_file(db, file) do
    db = Enum.sort(db)
    File.open!(file, [:write, :exclusive], fn device ->
      for {type, typedef(name: type) = obj} <- db do
        IO.puts device, "===="
        IO.inspect device, obj, limit: 100_000
      end
      :ok
    end)
    {:ok, file, length(db)}
  end

end
