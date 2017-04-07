defmodule Proto do

  #####################################

  def show(mode, {:getf, _meta, [fld]} = node, acc) do
    IO.puts "-- #{mode} | gf #{inspect fld}"
    {node, acc}
  end
  def show(mode, {:with_msg, _meta, [d, t, _]} = node, acc) do
    IO.puts "-- #{mode} | wm (#{Macro.to_string(d)}, #{inspect t})"
    {node, acc}
  end
  def show(_mode, node, acc), do: {node, acc}

  #####################################

  def conv(mode, {:getf, meta, [f]}, [{d, t} | _] = acc) do
    IO.puts "-- #{mode} | gf #{inspect f}"
    {{:getf, meta, [d, t, f]}, acc}
  end
  def conv(:pre, {:with_msg, _meta, [d, t, _]} = ast, acc) do
    IO.puts "-- pre | wm (#{Macro.to_string(d)}, #{inspect t})"
    {ast, [{d, t} | acc]}
  end
  def conv(:post, {:with_msg, _meta, [d, t, _]} = ast, acc) do
    IO.puts "-- post | wm (#{Macro.to_string(d)}, #{inspect t})"
    {ast, tl(acc)}
  end
  def conv(_mode, ast, acc) do
    {ast, acc}
  end

  #####################################

  defmacro with_msg(data, type, do: block) when is_atom(type) do
    ast =
      quote do
        var!(with_msg, Proto) = true
        unquote(block)
      end
    IO.puts "============== #{inspect type}"

  # {ast, _acc} = Macro.traverse(ast, {data, type}, &show(" PRE", &1, &2), &show("POST", &1, &2))
    {ast, _acc} = Macro.traverse(ast, [{data, type}], &conv(:pre, &1, &2), &conv(:post, &1, &2))
    ast
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
    IO.puts "__getf ~~> #{inspect name}"
  end
  def __getf(data, type, name) when is_atom(type) and is_atom(name) do
    IO.puts "__getf(#{inspect data} | #{inspect type} |#{inspect name}"
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

################################################# traverse (show) ############
# ============== :msgA
# --  PRE | gf :a1
# -- POST | gf :a1
# --  PRE | wm (pduB, :msgB)
# --  PRE | gf :b
# -- POST | gf :b
# -- POST | wm (pduB, :msgB)
# --  PRE | gf :a2
# -- POST | gf :a2
# ============== :msgB
# --  PRE | gf :b
# -- POST | gf :b
# iex(100)> TestProto.test 333
# __getf ~~> :a1
# __getf ~~> :b
# __getf ~~> :a2
# 333

################################################# traverse (conv) ############
# ============== :msgA
# -- pre | gf :a1
# -- pre | wm (pduB, :msgB)
# -- pre | gf :b
# -- post | wm (pduB, :msgB)
# -- pre | gf :a2
# ============== :msgB
# iex(28)> TestProto.test 333
# __getf(%{a: 1, b: 2} | :msgA |:a1
# __getf(%{b: 2, c: 3} | :msgB |:b
# __getf(%{a: 1, b: 2} | :msgA |:a2
# 333
