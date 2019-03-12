defmodule ASN.CDB.S1X2 do

  import ASN.CTT, only: :macros

  @trig [InitiatingMessage: 0, SuccessfulOutcome: 1, UnsuccessfulOutcome: 2]

  def elementary_procedures(db, s1x2_elem_procs) do
    typedef(typespec: objectset(set: set)) = db.(s1x2_elem_procs)
    set
    |> Enum.reduce([], fn
      {{_mod, _name}, id, attrs}, acc when is_integer(id) ->
        attrs = Map.new(attrs)
        %{procedureCode: proc, criticality: crit} = attrs
        valuedef(name: pname, value: ^id) = proc
        valuedef(value: pcrit) = crit
        attrs
        |> Map.take(Keyword.keys(@trig))
        |> Enum.reduce(acc, fn {mtrig, mtref}, acc ->
          extyperef(type: mtype) = mtref
          msg = %{trig: @trig[mtrig], proc: id, id_proc: pname, msg_type: mtype, criticality: pcrit}
          [msg | acc]
        end)
      :EXTENSIONMARK, acc ->
        acc
    end)
    |> Enum.reverse()
  end

  def message_ies(db, msg_type) do
    typedef(typespec: type(def: sequence(extaddgroup: :undefined, components: comps))) = db.(msg_type)
    {comps, []} = comps
    case comps do
      [comptype(name: :protocolIEs, typespec: ts1)] ->
        type(def: {:"SEQUENCE OF", type(def: sequence(tablecinf: ti1, components: c1))}) = ts1
        simpletabattrs(objectsetname: {_mod, iosa}) = ti1
        [_, _, _] = c1
      # IO.puts "#{msg_type} => #{inspect iosa}"
        ies_fields(db, iosa, msg_type)
      [comptype(name: :privateIEs, typespec: ts1)] ->
        type(def: {:"SEQUENCE OF", type(def: sequence(tablecinf: ti1, components: c1))}) = ts1
        simpletabattrs(objectsetname: {_mod, iosa}) = ti1
        [_, _, _] = c1
      # IO.puts "#{msg_type} => #{inspect iosa}"
        ies_fields(db, iosa, msg_type)
    end
  end

  defp ies_fields(db, iosa, msg_type) do
    # iosa: internal_object_set_argument_#
    typedef(typespec: objectset(set: set)) = db.(iosa)
    ies =
      Enum.reduce(set, [], fn
        {{:no_mod, :no_name}, _no, cols}, acc ->
          %{id: id1, criticality: cr1, Value: va1, presence: pr1} = Map.new(cols)
          valuedef(name: id, value: id_num) = id1
          valuedef(value: criticality) = cr1
          valuedef(value: presence) = pr1
          ie = %{id_num: id_num, id: id, criticality: criticality, presence: presence}
          ie =
            case va1 do
              extyperef(pos: pos, module: _module, type: type) ->
                ie |> Map.put(:type, type) |> Map.put(:pos, pos)
              typedef(typespec: type(def: type)) ->
                true = ASN.CDB.scalar?(type)
              # IO.puts "-- #{inspect type}"
                ie |> Map.put(:type, type)
            end
          [ie | acc]
        :EXTENSIONMARK, acc ->
          acc
      end)
    i2p = for %{pos: pos, id: id} <- ies, into: %{}, do: {id, pos}
    Enum.sort(ies, fn %{id: id1}, %{id: id2} ->
      ie_pos(msg_type, id1, i2p) <= ie_pos(msg_type, id2, i2p)
    end)
  end

  defp ie_pos(msg_type, id, i2p)
  defp ie_pos(:RerouteNASRequest, :"id-S1-Message", i2p) do
    (Map.fetch!(i2p, :"id-MME-UE-S1AP-ID") + Map.fetch!(i2p, :"id-MME-Group-ID")) / 2
  end
  defp ie_pos(_msg_type, id, i2p) do
    Map.fetch!(i2p, id)
  end

end
