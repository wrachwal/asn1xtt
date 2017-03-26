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
    type_kind = CTT.asn_type_kind(db)
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

  test "ASN.CTT.asn_roots/1" do
    assert is_map(db = RRC.db)
    assert CTT.asn_roots(db) == [
      :"BCCH-BCH-Message", :"BCCH-BCH-Message-NB", :"BCCH-DL-SCH-Message",
      :"BCCH-DL-SCH-Message-BR", :"BCCH-DL-SCH-Message-NB", :"CHARACTER STRING",
      :"DL-CCCH-Message", :"DL-CCCH-Message-NB", :"DL-DCCH-Message",
      :"DL-DCCH-Message-NB", :"EMBEDDED PDV", :EXTERNAL, :HandoverCommand,
      :HandoverPreparationInformation, :"HandoverPreparationInformation-NB",
      :"HandoverPreparationInformation-v9j0-IEs", :"MCCH-Message", :"PCCH-Message",
      :"PCCH-Message-NB", :"RRCConnectionReconfiguration-v8m0-IEs",
      :"RRCConnectionRelease-v9e0-IEs", :"SBCCH-SL-BCH-Message",
      :"SC-MCCH-Message-r13", :"SCG-ConfigInfo-r12", :"SL-Preconfiguration-r12",
      :"SL-V2X-Preconfiguration-r14", :"SystemInformationBlockType1-v8h0-IEs",
      :"SystemInformationBlockType2-v8h0-IEs",
      :"SystemInformationBlockType3-v10j0-IEs",
      :"SystemInformationBlockType5-v8h0-IEs",
      :"SystemInformationBlockType6-v8h0-IEs", :"UE-EUTRA-Capability",
      :"UE-EUTRA-Capability-v10j0-IEs", :"UE-EUTRA-Capability-v9a0-IEs",
      :"UEInformationResponse-v9e0-IEs", :UEPagingCoverageInformation,
      :"UEPagingCoverageInformation-NB", :UERadioAccessCapabilityInformation,
      :"UERadioAccessCapabilityInformation-NB", :UERadioPagingInformation,
      :"UERadioPagingInformation-NB", :"UL-CCCH-Message", :"UL-CCCH-Message-NB",
      :"UL-DCCH-Message", :"UL-DCCH-Message-NB", :"VarConnEstFailReport-r11",
      :"VarLogMeasConfig-r10", :"VarLogMeasConfig-r11", :"VarLogMeasConfig-r12",
      :"VarLogMeasReport-r10", :"VarLogMeasReport-r11", :VarMeasConfig,
      :VarMeasReportList, :"VarMeasReportList-r12", :"VarMobilityHistoryReport-r12",
      :"VarRLF-Report-r10", :"VarRLF-Report-r11", :"VarShortMAC-Input-NB-r13",
      :"VarShortResumeMAC-Input-NB-r13", :"VarWLAN-MobilityConfig",
      :"VarWLAN-Status-r13"
    ]
  end

end
