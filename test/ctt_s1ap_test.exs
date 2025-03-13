defmodule AsnCttS1apTest do
  use ExUnit.Case
  require Test.Asn1db
  require ASN.CTT, as: CTT
  require Logger

  # --------------------------------------------------------------------------

  @asn_s1ap :asn_s1ap
  @s1ap_set_asn1 Path.expand("../3gpp/asn/asn_s1ap/asn1/asn_s1ap.set.asn1", __DIR__)
  @s1ap_modules_and_dirs Test.Asn1db.asn1_modules_and_dirs(@s1ap_set_asn1)

  test "merge all parsed modules of the protocol into single database" do
    outdir = String.to_charlist(__DIR__) # test/
    {modules, includes} = @s1ap_modules_and_dirs
    includes = Enum.map(includes, &String.to_charlist/1)
    options = for dir <- includes, do: {:i, dir}
    assert :ok = :asn1_db.dbstart(includes)
    db = :ets.new(@asn_s1ap, [])
    # iterate: parse, save, load, and merge
    Enum.each(modules, fn module ->
      state = CTT.state(
                module: module,
                erule: :per,
                options: [:per, {:outdir, outdir} | options] # cannot have :maps option(!)
              )
      # parse
      assert :ok = :asn1ct.parse_and_save(module, state)
      # save
      asn1db = Path.join(outdir, Atom.to_string(module) <> ".asn1db")
      assert :ok = :asn1_db.dbsave(String.to_charlist(asn1db), module) # cast
      assert CTT.module() = :asn1_db.dbget(module, :MODULE)            # call
      # load
      assert {:ok, tab} = :ets.file2tab(String.to_charlist(asn1db))
      # merge
      acc = %{
        table: db,
        module: @asn_s1ap,
        errors: 0
      }
      assert %{errors: 0} = :ets.foldl(&merge_row_into_table/2, acc, tab)
    end)
    # save merged database
    asn1db = Path.join(outdir, Atom.to_string(@asn_s1ap) <> ".asn1db")
    :ok = :ets.tab2file(db, String.to_charlist(asn1db), extended_info: [:object_count], sync: true)
    size = :ets.info(db, :size)
    assert size == 1522
    # database stored as the result of real compilation has much more objects
    assert :ets.foldl(&get_row_type/2, %{}, db) == %{
      typedef: 1047,
      valuedef: 452,
      ptypedef: 14,
      classdef: 7
    }
    assert [{:MODULE, CTT.module(typeorval: typeorval)}] = :ets.lookup(db, :MODULE)
    assert {
      types,                    # typedef
      values,                   # valuedef
      ptypes,                   # ptypedef
      classes,                  # classdef
      objects,                  # typedef
      objsets                   # typedef
    } = typeorval
    assert length(types) + length(objects) + length(objsets) == 1044
    # +('CHARACTER STRING', 'EMBEDDED PDV', 'EXTERNAL')  ## Find: typedef,false,undefined
    assert length(values) == 452
    assert length(ptypes) == 14
    assert length(classes) == 5
    # +(ABSTRACT-SYNTAX, TYPE-IDENTIFIER)  ##Find: classded,true,undefined
  end

  # ------------------------------------

  # duplicated keys found:
  # - :MODULE
  # - :"ABSTRACT-SYNTAX"
  # - :"TYPE-IDENTIFIER"
  defp merge_row_into_table(row, acc) when tuple_size(row) >= 1 do
    %{table: tab} = acc
    if :ets.insert_new(tab, row) do
      acc
    else
      case :ets.lookup(tab, elem(row, 0)) do
        [^row] ->
          acc
        [{:MODULE, CTT.module() = val}] ->
          merge_module(:MODULE, val, elem(row, 1), acc)
        [{key, CTT.classdef() = val}] when key in [:"ABSTRACT-SYNTAX", :"TYPE-IDENTIFIER"] ->
          subst_classdef(key, val, elem(row, 1), acc)
        [_prev] ->
          Logger.error(["* don't know howto merge: ", inspect(row)])
          Map.update!(acc, :errors, &(&1 + 1))
      end
    end
  end

  defp merge_module(key, old, CTT.module() = new, acc) do
    CTT.module(typeorval: tov1) = old
    CTT.module(typeorval: tov2) = new
    tuple_size(tov1) == tuple_size(tov2) or raise("tuple size")
    if clear_module(old) == clear_module(new) do
      %{table: tab, module: module} = acc
      tov =
        Enum.zip(Tuple.to_list(tov1), Tuple.to_list(tov2))
        |> Enum.map(fn {lst1, lst2} -> lst1 ++ lst2 end)
        |> List.to_tuple()
      new = CTT.module(clear_module(new), name: module, typeorval: tov)
      :ets.insert(tab, {key, new})
      acc
    else
      log_merge_error(key, old, new)
      Map.update!(acc, :errors, &(&1 + 1))
    end
  end

  defp clear_module(record) do
    CTT.module(record, pos: nil, name: nil, defid: nil, exports: nil, imports: nil, typeorval: nil)
  end

  defp subst_classdef(key, old, CTT.classdef() = new, acc) do
    %{table: tab, module: module} = acc
    if CTT.classdef(old, module: module) == CTT.classdef(new, module: module) do
      new = CTT.classdef(new, module: module)
      :ets.insert(tab, {key, new})
      acc
    else
      log_merge_error(key, old, new)
      Map.update!(acc, :errors, &(&1 + 1))
    end
  end

  defp log_merge_error(key, old, new) do
    Logger.error(["* cannot merge #{inspect key} old ", inspect(old), " with new ", inspect(new)])
  end

  # ------------------------------------

  defp get_row_type(row, acc) do
    {key, obj} = row
    cond do
      key in [:__version_and_erule__, :MODULE] ->
        acc
      key == elem(obj, 3) ->
        type = elem(obj, 0)
        Map.update(acc, type, 1, &(&1 + 1))
      # true ->
      #   acc
    end
  end

  # --------------------------------------------------------------------------

  test "insert_asn1db/4" do
    outdir = String.to_charlist(__DIR__) # test/
    tab = :ets.new(:asn_rrc, [])
    assert :ok = Test.Asn1db.insert_asn1db(tab, @s1ap_set_asn1, outdir, :uper)
    assert Test.Asn1db.__asn1set__(modules: modules) = :ets.lookup_element(tab, :__asn1set__, 2)
    assert [_ | _] = modules # |> IO.inspect()
  end

end
