defmodule Asn1ValueTest do
  use ExUnit.Case
  require Test.Asn1db
  require Asn1UG

  @outdir Path.expand("asn1db", __DIR__) |> String.to_charlist() # test/asn1db/

  setup_all do
    rrc = asn1db_fun(:asn_rrc, Path.expand("../3gpp/asn/asn_rrc/asn1/asn_rrc.set.asn1", __DIR__), :uper)
    s1ap = asn1db_fun(:asn_s1ap, Path.expand("../3gpp/asn/asn_s1ap/asn1/asn_s1ap.set.asn1", __DIR__), :per)
    x2ap = asn1db_fun(:asn_x2ap, Path.expand("../3gpp/asn/asn_x2ap/asn1/asn_x2ap.set.asn1", __DIR__), :per)
    asn1ug = asn1db_fun(:asn1_ug, Path.expand("../3gpp/asn/asn1_ug/asn/asn1_ug.set.asn1", __DIR__), :ber)
    start = System.monotonic_time(:millisecond)
    on_exit(fn ->
      elapsed = System.monotonic_time(:millisecond) - start
      false and IO.puts("\n* #{elapsed}ms spent in #{inspect __MODULE__}")
    end)
    {:ok, rrc: rrc, s1ap: s1ap, x2ap: x2ap, asn1ug: asn1ug}
  end

  defp asn1db_fun(module, asn1set, erule) do
    map = Test.Asn1db.asn1db_map(module, asn1set, @outdir, erule)
    # &Map.fetch!(map, &1)  ## produces too much verbose trace :(
    fn key ->
      case Map.fetch(map, key) do
        {:ok, val} ->
          val
        :error ->
          raise("asn1db(#{inspect module}) doesn't have #{inspect key} key!")
      end
    end
  end

  # --------------------------------------------------------------------------

  test "rrc is /1 fun", %{rrc: rrc} do
    assert Test.Asn1db.__asn1set__() = rrc.(:__asn1set__)
  end

  test "s1ap is /1 fun", %{s1ap: s1ap} do
    assert Test.Asn1db.__asn1set__() = s1ap.(:__asn1set__)
  end

  test "x2ap is /1 fun", %{x2ap: x2ap} do
    assert Test.Asn1db.__asn1set__() = x2ap.(:__asn1set__)
  end

  # --------------------------------------------------------------------------

  @mib_rrcspec """
  BCCH-BCH-Message ::= SEQUENCE {
      message  BCCH-BCH-MessageType
  }

  BCCH-BCH-MessageType ::= MasterInformationBlock

  MasterInformationBlock ::= SEQUENCE {
      dl-Bandwidth                 ENUMERATED {n6, n15, n25, n50, n75, n100},
      phich-Config                 PHICH-Config,
      systemFrameNumber            BIT STRING (SIZE (8)),
      schedulingInfoSIB1-BR-r13    INTEGER (0..31),
      systemInfoUnchanged-BR-r15   BOOLEAN,
      partEARFCN-r17           CHOICE {
          spare                        BIT STRING (SIZE (2)),
          earfcn-LSB                   BIT STRING (SIZE (2))
      },
      spare                        BIT STRING (SIZE (1))
  }
  """

  @mib_encoded Base.decode16!("6A0180")
  @mib_asn1val """
  value BCCH-BCH-Message ::=
  {
    message
    {
      dl-Bandwidth n50,
      phich-Config
      {
        phich-Duration normal,
        phich-Resource one
      },
      systemFrameNumber '10000000'B,
      schedulingInfoSIB1-BR-r13 12,
      systemInfoUnchanged-BR-r15 FALSE,
      partEARFCN-r17 spare : '00'B,
      spare '0'B
    }
  }
  """

  test "rrc:mib -- asn1value", %{rrc: db} do
    pdu_type = :"BCCH-BCH-Message"
    assert {:ok, mib} = RRC.decode(@mib_encoded, pdu_type)
    if false do
      IO.inspect(mib) && IO.puts(@mib_asn1val) && IO.puts(@mib_rrcspec)
      IO.inspect(db.(:"BCCH-BCH-Message"))
      IO.inspect(db.(:"BCCH-BCH-MessageType"))
      IO.inspect(db.(:"MasterInformationBlock"))
    end
    assert [_ | _] = asn1val = Test.Asn1Value.to_asn1value(mib, pdu_type, db)
    refute Enum.find(asn1val, &match?({:error, _}, &1))
    assert asn1val == ["value", :"BCCH-BCH-Message", "::=", :"{", :message, :"{", :"dl-Bandwidth",
                       :n50, :",", :"phich-Config", :"{", :"phich-Duration", :normal, :",",
                       :"phich-Resource", :one, :"}", :",", :systemFrameNumber, "'10000000'B", :",",
                       :"schedulingInfoSIB1-BR-r13", 12, :",", :"systemInfoUnchanged-BR-r15", "FALSE",
                       :",", :"partEARFCN-r17", :spare, :":", "'00'B", :",", :spare, "'0'B", :"}",
                       :"}"]
  end

  # --------------------------------------------------------------------------
  #
  # $ iex -S mix
  # iex(1)> cd "3gpp/asn/asn1_ug/src"
  # iex(2)> :asn1ct.value :asn1_ug, :SeqX
  # {:ok, {:SeqX, {:b, {:SeqX_a_b, 14763631}}}}
  # NOTE: this ASN.1 Value got from Asn1Studio
  #

  @erl_SeqX {:SeqX, {:b, {:SeqX_a_b, 14763631}}}
  @ber_SeqX Base.decode16!("300AA008A006800400E1466F")
  @a1v_SeqX """
  value1 SeqX ::= {
    a b : {
      c 14763631
    }
  }
  """

  # -record('SeqX_a_b',{c}).

  test "SeqX from asn1ug", %{asn1ug: db} do
    pdu_type = :SeqX
    assert {:ok, @ber_SeqX} = Asn1UG.encode(@erl_SeqX, pdu_type)
    assert {:ok, data} = Asn1UG.decode(@ber_SeqX, pdu_type)
    # IO.inspect(data)
    assert [_ | _] = asn1val = Test.Asn1Value.to_asn1value(data, pdu_type, db)
    false and IO.puts(@a1v_SeqX)
    assert asn1val == ["value", :SeqX, "::=", :"{", :a, :b, :":", :"{", :c, 14763631, :"}", :"}"]
  end

  # --------------------------------------------------------------------------
  #
  # The rest have been created under Asn1Studio.
  #

  @ber_SeqY Base.decode16!("301FA00A300380010B3003800116A111300380016F3004800200DE30048002014D")
  @a1v_SeqY """
  value1 SeqY ::= {
    a {
      {
        b 11
      },
      {
        b 22
      }
    },
    c {
      {
        d 111
      },
      {
        d 222
      },
      {
        d 333
      }
    }
  }
  """

  # -record('SeqY_a_SEQOF'{b}).
  # -record('SeqY_c_SETOF'{d}).

  test "SeqY from asn1ug", %{asn1ug: db} do
    pdu_type = :SeqY
    assert {:ok, data} = Asn1UG.decode(@ber_SeqY, pdu_type)
    # IO.inspect(data)
    assert {:ok, @ber_SeqY} = Asn1UG.encode(data, pdu_type)
    assert [_ | _] = asn1val = Test.Asn1Value.to_asn1value(data, pdu_type, db)
    false and IO.puts(@a1v_SeqY)
    assert asn1val == [
      "value", :SeqY, "::=", :"{",
        :a, :"{",
          :"{", :b, 11, :"}", :",",
          :"{", :b, 22, :"}",
        :"}", :",",
        :c, :"{",
          :"{", :d, 111, :"}", :",",
          :"{", :d, 222, :"}", :",",
          :"{", :d, 333, :"}",
        :"}",
      :"}"
    ]
  end

end
