defmodule Test.Asn1db do

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
    |> Enum.reject(&(Regex.match?(~r/^#/, &1) or &1 == "")) # comment or blank line
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
