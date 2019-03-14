defmodule AsnCdbTest do
  use ExUnit.Case

  alias ASN.CDB

  defp typedef_scalar?(db, type) do
    import ASN.CTT, only: :macros
    typedef(typespec: type(def: type)) = db.(type)
    CDB.scalar?(type)
  end

  defp explore_dev(db) do
    CDB.explore(db, :Rec1)
    CDB.explore(db, :Rec2)
    CDB.explore(db, :Rec3)
    CDB.explore(db, :Dim3)
  end

  defp explore_rrc_main_channels(db) do
    CDB.explore(db, :"BCCH-BCH-Message")
    CDB.explore(db, :"BCCH-DL-SCH-Message")
    CDB.explore(db, :"PCCH-Message")
    CDB.explore(db, :"UL-CCCH-Message")
    CDB.explore(db, :"DL-CCCH-Message")
    CDB.explore(db, :"UL-DCCH-Message")
    CDB.explore(db, :"DL-DCCH-Message")
  end

  defp explore_rrc_in_one_go(db) do
    CDB.explore(db, [
      :"BCCH-BCH-Message",
      :"BCCH-DL-SCH-Message",
      :"PCCH-Message",
      :"UL-CCCH-Message",
      :"DL-CCCH-Message",
      :"UL-DCCH-Message",
      :"DL-DCCH-Message"
    ])
  end

  defp explore_rrc_all_types(db) do
    %{__REF__: tref} = CDB.explore(db, db.(:__typedef__) |> elem(0))
    roots =
      tref
      |> Enum.filter(&(elem(&1, 1) == 1))
      |> Enum.map(&elem(&1, 0))
      |> Enum.reject(&typedef_scalar?(db, &1))
      |> Enum.sort()
    # |> IO.inspect(limit: :infinity, label: "ROOTS")
    assert length(roots) == 81
  end

  test "explore/2 -- Dev.db0", do: explore_dev(&Dev.db0/1)
  test "explore/2 -- Dev.db1", do: explore_dev(&Dev.db1/1)

  test "explore/2 -- RRC.db0 main channels", do: explore_rrc_main_channels(&RRC.db0/1)
  test "explore/2 -- RRC.db1 main channels", do: explore_rrc_main_channels(&RRC.db1/1)

  test "explore/2 -- RRC.db0 in one go", do: explore_rrc_in_one_go(&RRC.db0/1)
  test "explore/2 -- RRC.db1 in one go", do: explore_rrc_in_one_go(&RRC.db1/1)

  test "explore/2 -- RRC.db0 all types", do: explore_rrc_all_types(&RRC.db0/1)
  test "explore/2 -- RRC.db1 all types", do: explore_rrc_all_types(&RRC.db1/1)

# test "explore/2 -- S1AP" do
#   db = &S1AP.db0/1
#   CDB.explore(db, :"S1AP-PDU")
# end

end
