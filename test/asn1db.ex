defmodule Test.Asn1db do
  require Record
  require ASN.CTT, as: CTT

  @asn1set :__asn1set__

  Record.defrecord @asn1set, [
    modules: []
  ]
  @type __asn1set__ :: record(unquote(@asn1set),
    modules: [{asn1_module(), typeorval_count()}]
  )

  @type erule :: :ber | :per | :uper | :jer

  @typep asn1_module :: atom()
  @typep typeorval_count :: {types :: non_neg_integer(),
                             values :: non_neg_integer(),
                             ptypes :: non_neg_integer(),
                             classes :: non_neg_integer(),
                             objects :: non_neg_integer(),
                             objsets :: non_neg_integer()}

  # --------------------------------------------------------------------------

  @spec insert_asn1db(:ets.tid(), Path.t(), Path.t(), erule()) :: :ok
  def insert_asn1db(tid, multi_or_single_asn1, outdir, erule) when is_atom(erule) do
    outdir = outdir |> IO.chardata_to_string() |> String.to_charlist()
    {modules, includes} = asn1_modules_and_dirs(multi_or_single_asn1)
    includes = Enum.map(includes, &String.to_charlist/1)
    options = [erule, {:outdir, outdir} | for(i <- includes, do: {:i, i})] # cannot have :maps(!)
    dirs = [outdir | includes]
    :ets.insert_new(tid, {@asn1set, __asn1set__()})
    :ok = :asn1_db.dbstart(dirs)
    try do
      Enum.each(modules, fn module ->
        {:ok, asn1spec} = Test.Asn1db.path_find(dirs, module, [".asn1", ".asn"])
        spec_mtime = :filelib.last_modified(asn1spec)
        true = is_tuple(spec_mtime)
        asn1db =
          case :asn1_db.dbload(module, erule, false, spec_mtime) do
            :ok ->
              {:ok, asn1db} = Test.Asn1db.path_find(dirs, module, [".asn1db"])
              asn1db
            :error ->
              state = CTT.state(module: module, erule: erule, options: options)
              # parse
              :ok = :asn1ct.parse_and_save(module, state)
              # save
              asn1db = Path.join(outdir, Atom.to_string(module) <> ".asn1db")
              :ok = :asn1_db.dbsave(String.to_charlist(asn1db), module) # cast
              CTT.module() = :asn1_db.dbget(module, :MODULE)            # call
              asn1db
          end
        # load
        {:ok, tab} = :ets.file2tab(String.to_charlist(asn1db))
        try do
          # merge
          acc = %{
            table: tid,
            module: :ets.info(tid, :name),
            errors: []
          }
          %{errors: []} = :ets.foldl(&merge_row_into_table/2, acc, tab)
        after
          :ets.delete(tab)
        end
      end)
    after
      :asn1_db.dbstop()
    end
  end

  defp merge_row_into_table(row, acc) when tuple_size(row) >= 1 do
    %{table: tab} = acc
    if :ets.insert_new(tab, row) do
      case elem(row, 0) do
        :MODULE ->
          update_asn1set(tab, elem(row, 1))
          acc
        _ ->
          acc
      end
    else
      case :ets.lookup(tab, elem(row, 0)) do
        [^row] ->
          acc
        [{:MODULE, CTT.module() = old}] ->
          merge_module(old, elem(row, 1), acc)
          acc
        [{key, CTT.classdef() = old}] when key in [:"ABSTRACT-SYNTAX", :"TYPE-IDENTIFIER"] ->
          subst_classdef(key, old, elem(row, 1), acc)
        [_prev] ->
          Map.update!(acc, :errors, &[{:merge, row} | &1])
      end
    end
  end

  defp merge_module(old, CTT.module() = new, acc) do
    CTT.module(typeorval: tov1) = old
    CTT.module(typeorval: tov2) = new
    tuple_size(tov1) == tuple_size(tov2) or raise("tuple size")
    if clear_module(old) == clear_module(new) do
      %{table: tab, module: module} = acc
      update_asn1set(tab, new)
      tov =
        Enum.zip(Tuple.to_list(tov1), Tuple.to_list(tov2))
        |> Enum.map(fn {lst1, lst2} -> lst1 ++ lst2 end)
        |> List.to_tuple()
      new = CTT.module(clear_module(new), name: module, typeorval: tov)
      :ets.insert(tab, {:MODULE, new})
      acc
    else
      Map.update!(acc, :errors, &[{:merge, {:MODULE, new}} | &1])
    end
  end

  defp clear_module(record) do
    CTT.module(record, pos: nil, name: nil, defid: nil, exports: nil, imports: nil, typeorval: nil)
  end

  defp update_asn1set(tab, CTT.module(name: name2, typeorval: tov2)) do
    asn1db1 = __asn1set__(modules: modules1) = :ets.lookup_element(tab, @asn1set, 2)
    tov2count =
      tov2
      |> Tuple.to_list()
      |> Enum.map(&length/1)
      |> List.to_tuple()
    modules = modules1 ++ [{name2, tov2count}]
    :ets.update_element(tab, @asn1set, {2, __asn1set__(asn1db1, modules: modules)})
  end

  defp subst_classdef(key, old, CTT.classdef() = new, acc) do
    %{table: tab, module: module} = acc
    if CTT.classdef(old, module: module) == CTT.classdef(new, module: module) do
      new = CTT.classdef(new, module: module)
      :ets.insert(tab, {key, new})
      acc
    else
      Map.update!(acc, :errors, &[{:merge, {key, new}} | &1])
    end
  end

  # --------------------------------------------------------------------------

  @spec asn1_modules_and_dirs(Path.t()) :: {[asn1_module :: atom()], [inc_dir :: binary()]}
  def asn1_modules_and_dirs(multi_or_single_asn1) do
    multi_or_single_asn1 = IO.chardata_to_string(multi_or_single_asn1)
    modules_with_dirs =
      if String.ends_with?(multi_or_single_asn1, [".set.asn1", ".set.asn"]) do
        multi_asn1_modules(multi_or_single_asn1)
      else
        [single_asn1_module(multi_or_single_asn1)]
      end
    Enum.map_reduce(modules_with_dirs, [], fn {asn1_module, inc_dir}, acc ->
      acc = if inc_dir in acc do acc else acc ++ [inc_dir] end
      {asn1_module, acc}
    end)
  end

  @spec multi_asn1_modules(Path.t()) :: [{asn1_module :: atom(), inc_dir :: binary()}]
  def multi_asn1_modules(set_asn1) do
    set_asn1_dir = Path.dirname(set_asn1)
    File.read!(set_asn1)
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(Regex.match?(~r/^(--|#)/, &1) or &1 == "")) # comment or blank line
    |> Enum.map(&single_asn1_module(&1, set_asn1_dir))
  end

  @spec single_asn1_module(Path.t()) :: {asn1_module :: atom(), inc_dir :: binary()}
  def single_asn1_module(asn1_spec, relative_to \\ ".") do
    inc_dir = Path.expand(Path.dirname(asn1_spec), relative_to)
    module =
      asn1_spec
      |> Path.basename(".asn1")
      |> Path.basename(".asn")
      |> String.to_atom()
    asn1_spec = Path.join(inc_dir, Path.basename(asn1_spec))
    File.regular?(asn1_spec) or raise("no such file: #{inspect asn1_spec}")
    {module, inc_dir}
  end

  # --------------------------------------------------------------------------

  @spec path_find([Path.t()], atom(), [binary()]) :: {:ok, binary()} | :error
  def path_find(dirs, asn1_module, extensions) do
    asn1_module = Atom.to_string(asn1_module)
    Enum.find_value(dirs, fn dir ->
      Enum.find_value(extensions, fn ext ->
        path = Path.join(dir, asn1_module <> ext)
        File.regular?(path) and {:ok, path}
      end)
    end) || :error
  end

end
