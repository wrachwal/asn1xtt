defmodule AsnCdbTest do
  use ExUnit.Case

  alias ASN.CDB

  defp typedef_scalar?(db, type) do
    import ASN.CTT, only: :macros
    typedef(typespec: type(def: type)) = db.(type)
    CDB.scalar?(type)
  end

  test "explore/2 -- Dev" do
    db = &Dev.db0/1
    CDB.explore(db, :Rec1)
    CDB.explore(db, :Rec2)
    CDB.explore(db, :Rec3)
    CDB.explore(db, :Dim3)
  end

  test "explore/2 -- main RRC channels" do
    db = &RRC.db0/1
    CDB.explore(db, :"BCCH-BCH-Message")
    CDB.explore(db, :"BCCH-DL-SCH-Message")
    CDB.explore(db, :"PCCH-Message")
    CDB.explore(db, :"UL-CCCH-Message")
    CDB.explore(db, :"DL-CCCH-Message")
    CDB.explore(db, :"UL-DCCH-Message")
    CDB.explore(db, :"DL-DCCH-Message")
  end

  test "explore/2 -- main RRC channels in one go" do
    db = &RRC.db0/1
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

  test "explore/2 -- *all* RRC types in one go" do
    db = &RRC.db0/1
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

# test "explore/2 -- S1AP" do
#   db = &S1AP.db0/1
#   CDB.explore(db, :"S1AP-PDU")
# end

end
