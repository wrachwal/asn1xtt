defmodule ASN.CTT do
  require Record
  @asn1_hrl "asn1/src/asn1_records.hrl"

  @venc :__version_and_erule__

  asn1_records = Record.extract_all(from_lib: @asn1_hrl)

  for {rec, tag} <- %{module: nil,
                      typedef: nil,
                      classdef: nil,
                      valuedef: nil,
                      ptypedef: nil,
                      type: nil,
                      SEQUENCE: :sequence,
                      Object: :object,
                      ObjectSet: :objectset,
                      Externaltypereference: :extyperef,
                      ComponentType: :comptype,
                      ExtensionAdditionGroup: :extaddgroup,
                    } do
    Record.defrecord tag || rec, rec, asn1_records[rec]
  end

  # --------------------------------------------------------------------------

  defmacro burn_asn1db(asn1db, fun \\ :asn1db) do
    quote bind_quoted: [asn1db: asn1db, fun: fun] do
      require Record
      kv_list = ASN.CTT.__asn1db_kv(asn1db)
      Enum.each kv_list, fn {k, v} ->
        is_atom(k) or raise "not atom key #{inspect k} has value #{inspect v}"
        v = Macro.escape(v)
        def unquote(fun)(unquote(k)), do: unquote(v)
      end
      kv_list
    end
  end

  @doc false
  def __asn1db_kv(asn1db) do
    {:ok, tab} = :ets.file2tab(String.to_charlist(asn1db))
    tab_kv = :ets.tab2list(tab)
    tab_map = Map.new(tab_kv)
    kind_map = Enum.reduce(tab_kv, %{}, &asn1db_reduce_kv/2)
    {typeord, valueord, ptypeord, classord, objord, objsetord} =
      module(Map.fetch!(tab_map, :MODULE), :typeorval)
      |> Tuple.to_list()
      |> Enum.map(fn list -> list |> Enum.reverse |> Enum.with_index |> Map.new end)
      |> List.to_tuple()
    kind_kv = Enum.map(kind_map, fn {kind, keys} ->
      keys =
        case kind do
          :__typedef__ ->
            keys
            |> Enum.map(&{typedef_slot(Map.fetch!(tab_map, &1), typeord, objord, objsetord), &1})
            |> Enum.sort()
            |> Enum.reverse()
            |> Enum.reduce(Tuple.duplicate([], 6), fn {{slot, _ord}, type}, acc ->
              update_in(acc, [Access.elem(slot)], &[type | &1])
            end)
          :__classdef__ ->
            keys
            |> Enum.map(&{classdef_slot(Map.fetch!(tab_map, &1), classord), &1})
            |> Enum.sort()
            |> Enum.reverse()
            |> Enum.reduce(Tuple.duplicate([], 2), fn {{slot, _ord}, class}, acc ->
              update_in(acc, [Access.elem(slot)], &[class | &1])
            end)
          :__valuedef__ -> Enum.sort(keys, &(Map.fetch!(valueord, &1) <= Map.fetch!(valueord, &2)))
          :__ptypedef__ -> Enum.sort(keys, &(Map.fetch!(ptypeord, &1) <= Map.fetch!(ptypeord, &2)))
          :__UNKNOWN__ -> Enum.sort(keys)
        end
      {kind, keys}
    end)
    kindord = [__typedef__: 0, __valuedef__: 1, __ptypedef__: 2, __classdef__: 3, __UNKNOWN__: 4]
    kind_kv = Enum.sort(kind_kv, fn {k1, _v1}, {k2, _v2} -> kindord[k1] <= kindord[k2] end)
    [{:__asn1db__, [:MODULE, @venc | Keyword.keys(kind_kv)]} | kind_kv] ++ tab_kv
  end

  defp asn1db_reduce_kv({k, typedef()}, map), do: asn1db_put_kind(map, :__typedef__, k)
  defp asn1db_reduce_kv({k, classdef()}, map), do: asn1db_put_kind(map, :__classdef__, k)
  defp asn1db_reduce_kv({k, valuedef()}, map), do: asn1db_put_kind(map, :__valuedef__, k)
  defp asn1db_reduce_kv({k, ptypedef()}, map), do: asn1db_put_kind(map, :__ptypedef__, k)
  defp asn1db_reduce_kv({k, _}, map) when k in [:MODULE, @venc], do: map
  defp asn1db_reduce_kv({k, _}, map), do: asn1db_put_kind(map, :__UNKNOWN__, k)

  defp asn1db_put_kind(map, kind, k) do
    map
    |> Map.put_new(kind, [])
    |> update_in([kind], &([k | &1]))
  end

  defp typedef_slot(typedef(name: name, typespec: spec), typeord, objord, objsetord) do
    cond do
      match?(type(), spec) -> (ord = typeord[name]) && {0, ord} || {3, name}
      match?(object(), spec) -> (ord = objord[name]) && {1, ord} || {4, name}
      match?(objectset(), spec) -> (ord = objsetord[name]) && {2, ord} || {5, name}
    end
  end

  defp classdef_slot(classdef(name: name), classord) do
    (ord = classord[name]) && {0, ord} || {1, name}
  end

  # --------------------------------------------------------------------------

  defmacro burn_record(asn1hrl) do
    quote bind_quoted: [asn1hrl: asn1hrl] do
      require Record
      rec2kv = Record.extract_all(from: asn1hrl)
      Enum.each(rec2kv, fn {rec, kv} ->
        Record.defrecord rec, kv
      end)
      rec2kv
    end
  end

  # --------------------------------------------------------------------------

  def asn_type_use(db) when is_function(db, 1) do
    db.(:__typedef__)
    |> elem(0) # {:typedef, ... {:type, ...
    |> Enum.map(&{&1, db.(&1)})
    |> Enum.reduce(%{}, fn
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

  def asn_type_kind(db) when is_function(db, 1) do
    db.(:__typedef__)
    |> elem(0)
    |> Enum.map(&{&1, asn_type_kind(db, &1)})
    |> Map.new
  end

  def asn_type_kind(db, type) do
    typedef(name: ^type, typespec: spec) = db.(type)
    type(def: tdef) = spec
    case tdef do
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

  def asn_roots(db) when is_function(db, 1) do
    for {type, 1} <- asn_type_use(db), kind_mapping(asn_type_kind(db, type)) not in [:scalar] do
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
    |> Enum.reverse()
    |> eliminate_partial_results([])
  end

  defp eliminate_partial_results([], acc), do: acc
  defp eliminate_partial_results([r], acc), do: [r | acc]
  defp eliminate_partial_results([{[_ | g2], p1} = r1, {g2, p2} = r2 | t], acc) do
    if List.starts_with?(Enum.reverse(p2), Enum.reverse(p1)) do
      eliminate_partial_results([r2 | t], acc)
    else
      eliminate_partial_results([r2 | t], [r1 | acc])
    end
  end
  defp eliminate_partial_results([r1, r2 | t], acc) do
    eliminate_partial_results([r2 | t], [r1 | acc])
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

end
