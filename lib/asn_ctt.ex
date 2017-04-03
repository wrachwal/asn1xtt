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

  def search_field(db, node, goal, path, acc)

  def search_field(_db, _node, [], _pl, acc), do: acc
  def search_field(db, typedef(name: gh, typespec: spec), [gh | gt], pl, acc),
    do: search_field(db, spec, gt, pl, [{gt, pl} | acc])
  def search_field(db, typedef(name: _, typespec: spec), gl, pl, acc),
    do: search_field(db, spec, gl, pl, acc)
  def search_field(db, type(def: def), gl, pl, acc),
    do: search_field(db, def, gl, pl, acc)
  def search_field(db, sequence(components: comps, extaddgroup: :undefined), gl, pl, acc),
    do: search_components(db, comps, gl, pl, acc)
  def search_field(db, sequence(components: comps, extaddgroup: exts), gl, pl, acc),
    do: search_components(db, exts, gl, pl, search_components(db, comps, gl, pl, acc))
  def search_field(_db, :INTEGER, _gl, _pl, acc), do: acc
  def search_field(_db, {:ENUMERATED, _}, _gl, _pl, acc), do: acc
  def search_field(_db, {:"BIT STRING", _}, _gl, _pl, acc), do: acc
  def search_field(db, extyperef(type: type), gl, pl, acc) when is_atom(type),
    do: search_field(db, db.(type), gl, pl, acc)
  def search_field(db, {:CHOICE, comps}, gl, pl, acc),
    do: search_components(db, comps, gl, pl, acc)
  def search_field(db, {:"SEQUENCE OF", type() = type}, gl, pl, acc),
    do: search_field(db, type, gl, [@list | pl], acc)
  def search_field(_db, :BOOLEAN, _gl, _pl, acc), do: acc
  def search_field(_db, :NULL, _gl, _pl, acc), do: acc
  def search_field(_db, :"OCTET STRING", _gl, _pl, acc), do: acc

  defp search_components(db, {comps, exts}, gl, pl, acc),
    do: search_comps_list(db, exts, gl, pl, search_comps_list(db, comps, gl, pl, acc))
  defp search_components(db, comps, gl, pl, acc) when is_list(comps),
    do: search_comps_list(db, comps, gl, pl, acc)

  defp search_comps_list(db, [comp | comps], gl, pl, acc),
    do: search_comps_list(db, comps, gl, pl, search_comp(db, comp, gl, pl, acc))
  defp search_comps_list(_db, [], _gl, _pl, acc), do: acc

  defp search_comp(db, comptype(name: gh, typespec: spec, textual_order: ei), [gh | gt], pl, acc) do
    pl_new = [{gh, textual_order(ei)} | pl]
    search_field(db, spec, gt, pl_new, [{gt, pl_new} | acc])
  end
  defp search_comp(db, comptype(name: en, typespec: spec, textual_order: ei), gl, pl, acc),
    do: search_field(db, spec, gl, [{en, textual_order(ei)} | pl], acc)
  defp search_comp(_db, extaddgroup(), _gl, _pl, acc), do: acc
  defp search_comp(_db, :ExtensionAdditionGroupEnd, _gl, _pl, acc), do: acc

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
