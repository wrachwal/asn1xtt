defmodule AsnCttTest do
  use ExUnit.Case

  alias ASN.{CTT, RRC}

  test "RRC.db/0" do
    assert is_map(db = RRC.db)
    assert map_size(db) == 1704
  end

  test "CTT.asn_type_use/1" do
    assert is_map(db = RRC.db)
    assert is_map(cnt = CTT.asn_type_use(db))
    assert map_size(cnt) == 1569
    singles = cnt |> Enum.filter(fn {_, v} -> v == 1 end) |> Keyword.keys
    assert length(singles) == 238
  # IO.inspect singles |> Enum.sort(), limit: 1000
    assert :TimeAlignmentTimer in singles
  end

  test "CTT.asn_type_kind/1" do
    assert is_map(db = RRC.db)
    type_kind = CTT.asn_type_kind(RRC.db)
    kind_used =
      type_kind
      |> Map.values
      |> Enum.reduce(%{}, fn k, m -> m |> Map.put_new(k, 0) |> update_in([k], &(&1 + 1)) end)
      |> Enum.sort
    assert kind_used == ["BIT STRING": 14,
                         BOOLEAN: 1,
                         CHOICE: 90,
                         ENUMERATED: 65,
                         Externaltypereference: 13, #XXX ???
                         INTEGER: 94,
                         "OCTET STRING": 3,
                         SEQUENCE: 995,
                         "SEQUENCE OF": 294]
    exttyperefs =
      type_kind
      |> Enum.filter(fn {_, k} -> k == :Externaltypereference end)
      |> Keyword.keys
      |> Enum.sort
    assert exttyperefs == [:"BCCH-BCH-MessageType",
                           :"BCCH-BCH-MessageType-NB",
                           :"BandParametersDL-r13",
                           :"BandParametersUL-r13",
                           :"MobilityHistoryReport-r12",
                           :"RedirectedCarrierInfo-NB-r13",
                           :"SBCCH-SL-BCH-MessageType",
                           :"SystemInformation-BR-r13",
                           :"SystemInformationBlockType1-BR-r13",
                           :"SystemInformationBlockType16-NB-r13",
                           :"VarMobilityHistoryReport-r12",
                           :"VarShortMAC-Input-NB-r13",
                           :"VarShortResumeMAC-Input-NB-r13"]
  end

end
