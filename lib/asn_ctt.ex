defmodule ASN.CTT do
  require Record
  @asn1_hrl "asn1/src/asn1_records.hrl"

  @venc :__version_and_erule__

  Record.defrecord :typedef, Record.extract(:typedef, from_lib: @asn1_hrl)
  Record.defrecord :valuedef, Record.extract(:valuedef, from_lib: @asn1_hrl)
  Record.defrecord :classdef, Record.extract(:classdef, from_lib: @asn1_hrl)
  Record.defrecord :module, Record.extract(:module, from_lib: @asn1_hrl)
  Record.defrecord :type, Record.extract(:type, from_lib: @asn1_hrl)
  Record.defrecord :sequence, :SEQUENCE, Record.extract(:SEQUENCE, from_lib: @asn1_hrl)
  Record.defrecord :extyperef, :Externaltypereference, Record.extract(:Externaltypereference, from_lib: @asn1_hrl)
  Record.defrecord :comptype, :ComponentType, Record.extract(:ComponentType, from_lib: @asn1_hrl)
  Record.defrecord :extaddgroup, :ExtensionAdditionGroup, Record.extract(:ExtensionAdditionGroup, from_lib: @asn1_hrl)

  def asn_type_use(db) do
    Enum.reduce(db, %{}, fn
      {type, typedef(name: type) = tdef}, tref -> tref_typedef(tdef, tref)
      {_, rec}, tref when elem(rec, 0) in [:valuedef, :classdef, :module] -> tref
      {@venc, _}, tref -> tref
    end)
  end

  defp tref_typedef(typedef(name: name, typespec: spec), tref) do
    tref_typespec(spec, inckey(tref, name))
  end

  defp tref_typespec(type(def: def), tref) do
    tref_def(def, tref)
  end

  defp tref_def(sequence(components: comps, extaddgroup: :undefined), tref) do
    tref_components(tref, comps)
  end
  defp tref_def(sequence(components: comps, extaddgroup: exts), tref) do
    tref |> tref_components(comps) |> tref_components(exts)
  end
  defp tref_def({:"SEQUENCE OF", type() = type}, tref) do
    tref_typespec(type, tref)
  end
  defp tref_def(:INTEGER, tref) do
    tref
  end
  defp tref_def({:CHOICE, comps}, tref) when is_list(comps) do
    tref_components(tref, comps)
  end
  defp tref_def({:CHOICE, {comps, exts}}, tref) do
    tref |> tref_components(comps) |> tref_components(exts)
  end
  defp tref_def(extyperef(type: type), tref) do
    inckey(tref, type)
  end
  defp tref_def({:ENUMERATED, _}, tref) do
    tref
  end
  defp tref_def({:"BIT STRING", _}, tref) do
    tref
  end
  defp tref_def(:"OCTET STRING", tref) do
    tref
  end
  defp tref_def(:BOOLEAN, tref) do
    tref
  end
  defp tref_def(:NULL, tref) do
    tref
  end
  defp tref_def(:"OBJECT IDENTIFIER", tref) do
    tref
  end
  defp tref_def(:"ObjectDescriptor", tref) do
    tref
  end
  defp tref_def(:ANY, tref) do
    tref
  end

  defp tref_components(tref, {comps, exts}) when is_list(comps) and is_list(exts) do
    tref |> tref_comp_list(comps) |> tref_comp_list(exts)
  end
  defp tref_components(tref, comps) when is_list(comps) do
    tref_comp_list(tref, comps)
  end

  defp tref_comp_list(tref, [comp | comps]) do
    tref_comp_list(tref_comp(tref, comp), comps)
  end
  defp tref_comp_list(tref, []) do
    tref
  end

  defp tref_comp(tref, comptype(typespec: spec)) do
    tref_typespec(spec, tref)
  end
  defp tref_comp(tref, extaddgroup()) do
    tref
  end
  defp tref_comp(tref, :ExtensionAdditionGroupEnd) do
    tref
  end

  defp inckey(map, key) do
    map |> Map.put_new(key, 0) |> update_in([key], &(&1 + 1))
  end

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
