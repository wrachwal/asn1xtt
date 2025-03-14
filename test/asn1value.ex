defmodule Test.Asn1Value do
  require ASN.CTT, as: DB

  @spec to_asn1value(term(), atom(), (any() -> any())) :: [term()] #TODO
  def to_asn1value(data, type, db) when is_atom(type) and is_function(db, 1) do
    typedef = DB.typedef() = db.(type)
    ["value", type, "::=", a1v_typedef(data, typedef, db)]
    |> List.flatten()
  # |> IO.inspect()
  end

  # ------------------------------------

  defp a1v_typedef(data, DB.typedef(name: _name, typespec: typespec), db) do # when elem(data, 0) == name do
    DB.type() = typespec
    a1v_type(data, typespec, db)
  end

  # ------------------------------------

  defp a1v_type(data, DB.type(def: DB.extyperef(type: type)), db) do
    a1v_typedef(data, db.(type), db)
  end
  defp a1v_type(data, DB.type(def: DB.sequence() = seq), db) do
    [:"{", a1v_sequence(data, seq, db), :"}"]
  end
  defp a1v_type(data, DB.type(def: {:CHOICE, comps}), db) do
    case data do
      {sel, val} when is_atom(sel) ->
        a1v_choice_sel(val, sel, comps, db)
      bad_choice ->
        {:error, {:bad_choice, bad_choice}}
    end
  end
  defp a1v_type(data, DB.type(def: {:"SEQUENCE OF", DB.type() = eltype}, constraint: constraint), db) do
    [:"{", a1v_seqsetof(data, :SEQOF, constraint, eltype, db), :"}"]
  end
  defp a1v_type(data, DB.type(def: {:"SET OF", DB.type() = eltype}, constraint: constraint), db) do
    [:"{", a1v_seqsetof(data, :SETOF, constraint, eltype, db), :"}"]
  end
  defp a1v_type(data, DB.type(def: {:ENUMERATED, enums}), _db) do
    if enums_member?(enums, data) do
      data
    else
      {:error, data}
    end
  end
  defp a1v_type(data, DB.type(def: {:"BIT STRING", _}), _db) do
    if is_bitstring(data) do
      a1v_bitvalue(data)
    else
      {:error, data}
    end
  end
  defp a1v_type(data, DB.type(def: :INTEGER), _db) do
    if is_integer(data) do
      data
    else
      {:error, data}
    end
  end
  defp a1v_type(data, DB.type(def: :BOOLEAN), _db) do
    if is_boolean(data) do
      data and "TRUE" || "FALSE"
    else
      {:error, data}
    end
  end

  defp enums_member?([{_, _} | _] = enums, item), do: List.keymember?(enums, item, 0) # .asn1db
  defp enums_member?(enums, item) when is_list(enums), do: item in enums              # AST form

  # ------------------------------------

  defp a1v_sequence(data, DB.sequence(components: comps), db) when is_list(comps) do
    tuple_size(data) == 1 + length(comps) or raise("XXX")
    a1v_list_comps(data, comps, db, 1, [])
    |> Enum.intersperse(:",")
  end

  defp a1v_list_comps(data, [DB.comptype() = comptype | rest], db, idx, acc) do
    case a1v_comp_value(elem(data, idx), comptype, db) do
      [] ->       a1v_list_comps(data, rest, db, idx + 1, acc)
      cv -> [cv | a1v_list_comps(data, rest, db, idx + 1, acc)]
    end
  end
  defp a1v_list_comps(_data, [], _db, _idx, acc) do
    acc
  end

  defp a1v_comp_value(:asn1_NOVALUE, DB.comptype(prop: :OPTIONAL), _db), do: []
  defp a1v_comp_value(data, DB.comptype(name: name, typespec: typespec), db) do
    DB.type() = typespec
    [name, a1v_type(data, typespec, db)]
  end

  # ------------------------------------

  defp a1v_choice_sel(data, sel, comps, db) when is_list(comps) do
    if comp = Enum.find(comps, &match?(DB.comptype(name: ^sel), &1)) do
      DB.comptype(typespec: typespec) = comp
      DB.type() = typespec
      [sel, :":", a1v_type(data, typespec, db)]
    else
      {:error, {:unknown_choice, sel}}
    end
  end

  # ------------------------------------

  defp a1v_seqsetof(data, seqset, _constraint, eltype, db) do
    if is_list(data) do
      #FIXME go to concrete type skipping external references?
      {_count, result} = a1v_seqsetof_reduce(data, eltype, db, 0, [])
      # check count against constraint
      result
    else
      {:error, {seqset, data}}
    end
  end

  defp a1v_seqsetof_reduce([item | rest], eltype, db, idx, acc) do
    value =
      case a1v_type(item, eltype, db) do
        {:error, reason} ->
          {:error, {idx, reason}}
        value ->
          value
      end
    a1v_seqsetof_reduce(rest, eltype, db, idx + 1, [value | acc])
  end
  defp a1v_seqsetof_reduce([], _eltype, _db, idx, acc) do
    {idx, acc |> :lists.reverse() |> Enum.intersperse(:",")}
  end

  # ------------------------------------

  defp a1v_bitvalue(bitstream) do
    for(<<x::1 <- bitstream>>, into: "'", do: <<?0 + x>>) <> "'B"
  end

end
