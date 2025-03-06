defmodule Proto do

  #####################################

  def conv({:getf, meta, [f]}, data, type) when is_atom(f) do
#   IO.puts "gf #{inspect f}"
    {:getf, meta, [data, type, f]}
  end
  def conv({:with_msg, meta, [data, type, [do: block]]}, _data, _type) do
#   IO.puts "wm (#{Macro.to_string(data)}, #{inspect type})"
    {:with_msg, meta, [data, type, [do: conv(block, data, type)]]}
  end
  def conv(ast, _data, _type) do
    ast
  end

  #####################################

  defmacro with_msg(data, type, do: block) when is_atom(type) do
    quote do
      var!(with_msg, Proto) = true
      unquote(Macro.prewalk(block, &conv(&1, data, type)))
    end
  end
  defmacro getf(name) when is_atom(name) do
    quote do
      true = var!(with_msg, Proto)
      Proto.__getf(unquote(name))  #FIXME in production replace with: raise "getf/1 without with_msg/3"
    end
  end
  defmacro getf(data, type, name) when is_atom(type) and is_atom(name) do
    quote do
      Proto.__getf(unquote(data), unquote(type), unquote(name))
    end
  end
  def __getf(name) when is_atom(name) do
#   IO.puts "__getf ~~> #{inspect name}"
  end
  def __getf(_data, type, name) when is_atom(type) and is_atom(name) do
#   IO.puts "__getf(#{inspect data} | #{inspect type} |#{inspect name}"
  end
end

##############################################################################

defmodule TestProto do
  import Proto  #XXX import, as Proto.* produce different AST and don't work yet
  def test0 do
    data = %{x: 1, y: 2}
    Proto.getf(data, :Type, :field)
  end
  def test(result) do
    pduA = %{a: 1, b: 2}
    pduB = %{b: 2, c: 3}
    with_msg pduA, :msgA do
      getf(:a1)
      with_msg pduB, :msgB do
        getf(:b)
      end
      getf(:a2)
      result
    end
  end
end

################################################# prewalk/2 ##################
# gf :a1
# wm (pduB, :msgB)
# gf :b
# gf :a2
# iex(1)> TestProto.test 333
# __getf(%{a: 1, b: 2} | :msgA |:a1
# __getf(%{b: 2, c: 3} | :msgB |:b
# __getf(%{a: 1, b: 2} | :msgA |:a2
# 333
