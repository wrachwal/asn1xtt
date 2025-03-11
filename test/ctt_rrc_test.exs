defmodule AsnCttRrcTest do
  use ExUnit.Case
  require ASN.CTT, as: CTT
  require Logger

  # --------------------------------------------------------------------------

  defp has_underscore?(atom) do
    Regex.match?(~r/_/, Atom.to_string(atom))
  end

  test "explicit & anonymous records" do
    assert [_ | _] = records = RRC.ASN.record()
    assert [_ | _] = asn1_records = Enum.reject(records, &has_underscore?/1)
    assert [_ | _] = anon_records = Enum.filter(records, &has_underscore?/1)
    assert length(asn1_records) == 1108
    assert length(anon_records) == 546
  end

  # rg -U "\{\n\}" 3gpp/asn/asn_rrc/src/asn_rrc.hrl | wc -l  #=> 368
  test "about 10% of records are empty! (SEQUENCE {})" do
    assert [_ | _] = records = RRC.ASN.record()
    assert [_ | _] = empty_records = Enum.filter(records, &(RRC.ASN.rec2kv(&1) == []))
    assert length(records) == 1654
    assert length(empty_records) == 184
  end

  test "explicit records found in database" do
    assert [_ | _] = asn1_records = Enum.reject(RRC.ASN.record(), &has_underscore?/1)
    Enum.each(asn1_records, fn asn1_rec ->
      assert CTT.typedef(name: ^asn1_rec, typespec: typespec) = RRC.db(asn1_rec)
      assert CTT.type(def: def) = typespec
      assert CTT.sequence() = def
    end)
  end

  # --------------------------------------------------------------------------
  #
  # Current RRC.db/1 is built from .asn1db being a by-product of :asn1ct.compile/2.
  #
  # RRC.db(:"SIB-MappingInfo") doesn't refer to RRC.db(:"SIB-Type"), but expands ENUMERATION inline :-(
  # ===
  # SIB-MappingInfo ::= SEQUENCE (SIZE (0..maxSIB-1)) OF SIB-Type
  #
  # SIB-Type ::=                        ENUMERATED {
  #                                         sibType3, sibType4, sibType5, sibType6,
  #                                         sibType7, sibType8, sibType9, sibType10,
  #                                         sibType11, sibType12-v920, sibType13-v920,
  #                                         sibType14-v1130, sibType15-v1130,
  #                                         sibType16-v1130, sibType17-v1250, sibType18-v1250,
  #                                         ..., sibType19-v1250, sibType20-v1310, sibType21-v14x0}
  # ===

  @asn_rrc :asn_rrc
  @rrc_set_asn1 Path.expand("../3gpp/asn/asn_rrc/asn1/asn_rrc.set.asn1", __DIR__)
  @rrc_modules_and_dirs Test.Asn1db.asn1_modules_and_dirs(@rrc_set_asn1)

  test ":asn1ct.parse_and_save/2 - single module" do
    outdir = String.to_charlist(__DIR__) # test/
    {modules, includes} = @rrc_modules_and_dirs
    includes = Enum.map(includes, &String.to_charlist/1)
    dirs = [outdir | includes]
    module = hd(modules)
    state = CTT.state(
      module: module,          # probably ignored
      erule: :uper,            # will  be stored in __version_and_erule__ record
      # sourcedir: outdir,
      options: [:uper, {:outdir, outdir} | for(i <- includes, do: {:i, i})] # cannot have :maps option(!)
    )

    assert :ok = :asn1_db.dbstart(dirs)
    assert :ok = :asn1ct.parse_and_save(module, state)

    asn1db = Path.join(outdir, Atom.to_string(module) <> ".asn1db")
    assert :ok = :asn1_db.dbsave(String.to_charlist(asn1db), module) # cast
    assert CTT.module() = :asn1_db.dbget(module, :MODULE)            # call
  end

  test "parse all modules (if needed) then merge into single database" do
    outdir = String.to_charlist(__DIR__) # test/
    {modules, includes} = @rrc_modules_and_dirs
    includes = Enum.map(includes, &String.to_charlist/1)
    dirs = [outdir | includes]
    assert :ok = :asn1_db.dbstart(dirs)
    db = :ets.new(@asn_rrc, [])
    erule = :uper
    # iterate: parse, save, load, and merge
    Enum.each(modules, fn module ->
      assert {:ok, asn1spec} = Test.Asn1db.path_find(dirs, module, [".asn1", ".asn"])
      spec_mtime = :filelib.last_modified(asn1spec)
      assert is_tuple(spec_mtime)
      {:ok, tab} =
        # quick load without parse/save?
        case :asn1_db.dbload(module, erule, false, spec_mtime) do
          :ok ->
            assert {:ok, asn1db} = Test.Asn1db.path_find(dirs, module, [".asn1db"])
            # load
            assert {:ok, _tab} = :ets.file2tab(String.to_charlist(asn1db))
          :error ->
            state = CTT.state(
                      module: module,
                      erule: erule,
                      options: [erule, {:outdir, outdir} | for(i <- includes, do: {:i, i})] # cannot have :maps option(!)
                    )
            # parse
            assert :ok = :asn1ct.parse_and_save(module, state)
            # save
            asn1db = Path.join(outdir, Atom.to_string(module) <> ".asn1db")
            assert :ok = :asn1_db.dbsave(String.to_charlist(asn1db), module) # cast
            assert CTT.module() = :asn1_db.dbget(module, :MODULE)            # call
            # load
            assert {:ok, _tab} = :ets.file2tab(String.to_charlist(asn1db))
        end
      # merge
      acc = %{
        table: db,
        module: @asn_rrc,
        errors: 0
      }
      assert %{errors: 0} = :ets.foldl(&merge_row_into_table/2, acc, tab)
    end)
    # save merged database
    asn1db = Path.join(outdir, Atom.to_string(@asn_rrc) <> ".asn1db")
    :ok = :ets.tab2file(db, String.to_charlist(asn1db), extended_info: [:object_count], sync: true)
    size = :ets.info(db, :size)
    assert size == 1903
    # Interesting facts:
    # database stored as the result of real compilation has the same number of objects (1903),
    # but size in kilobytes is larger (2562kB) vs (1704kB) what confirms the fact that much
    # data was expanded during check, the process proceeding code generation.
  end

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

  test ":asn1ct.dbload/4 - use to query if parse/save is needed" do
    outdir = String.to_charlist(__DIR__) # test/
    {modules, includes} = @rrc_modules_and_dirs
    includes = Enum.map(includes, &String.to_charlist/1)

    dirs = [outdir | includes]  # outdir is required for .asn1db to be found
    assert :ok = :asn1_db.dbstart(dirs)

    module = hd(modules)
    assert {:ok, asn1spec} = Test.Asn1db.path_find(dirs, module, [".asn1", ".asn"])
    assert File.exists?(asn1spec)
    spec_mtime = :filelib.last_modified(asn1spec)
    assert is_tuple(spec_mtime)

    case Test.Asn1db.path_find(dirs, module, [".asn1db"]) do
      {:ok, _asn1db} ->
        assert :ok = :asn1_db.dbload(module, :uper, false, spec_mtime)
      :error ->
        assert :error = :asn1_db.dbload(module, :uper, false, spec_mtime)
    end
  end

end
