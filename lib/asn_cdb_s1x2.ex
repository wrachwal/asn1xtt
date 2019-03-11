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
end
