defmodule AsnCttTest do
  use ExUnit.Case

  alias ASN.CTT

  test "CTT.asn_type_use/1" do
    assert is_map(cnt = CTT.asn_type_use(&RRC.db/1))
    assert map_size(cnt) == 1569
    singles = cnt |> Enum.filter(fn {_, v} -> v == 1 end) |> Keyword.keys
    assert length(singles) == 238
  # IO.inspect singles |> Enum.sort(), limit: 1000
    assert :TimeAlignmentTimer in singles
  end

  test "CTT.asn_type_kind/1" do
    type_kind = CTT.asn_type_kind(&RRC.db/1)
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
    assert CTT.asn_roots(&RRC.db/1) == [
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

  test "__typedef__ and __valuedef__ are in order as in .asn" do
    assert Enum.take(RRC.db(:__typedef__), 6) == [
        :"BCCH-BCH-Message",
        :"BCCH-BCH-MessageType",
        :"BCCH-DL-SCH-Message",
        :"BCCH-DL-SCH-MessageType",
        :"BCCH-DL-SCH-Message-BR",
        :"BCCH-DL-SCH-MessageType-BR-r13",
      ]
    assert Enum.take(RRC.db(:__valuedef__), 3) == [
        :"maxACDC-Cat-r13",
        :"maxAvailNarrowBands-r13",
        :"maxBandComb-r10"
      ]
  end

  test "search_field/3 - goal starting with root" do
    db = &RRC.db/1
    assert CTT.search_field(db, db.(:MasterInformationBlock), [:MasterInformationBlock, :"phich-Config"]) ==
      [{[],
        [{:"phich-Config", 2, :mandatory}]},
       {[:"phich-Config"],
        []}]
  end

  test "search_field/3 - goal without root" do
    db = &RRC.db/1
    assert CTT.search_field(db, db.(:MasterInformationBlock), [:"phich-Config"]) ==
      [{[],
        [{:"phich-Config", 2, :mandatory}]}]
  end

  test "search_field/3 - CHOICE field starting with root" do
    db = &RRC.db/1
    assert CTT.search_field(db, db.(:"BCCH-DL-SCH-Message"), [:"BCCH-DL-SCH-Message", :systemInformationBlockType1]) ==
      [{[],
        [{:systemInformationBlockType1, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[:systemInformationBlockType1],
        []}]
  end

  test "search_field/3 - CHOICE field without root" do
    db = &RRC.db/1
    assert CTT.search_field(db, db.(:"BCCH-DL-SCH-Message"), [:systemInformationBlockType1]) ==
      [{[],
        [{:systemInformationBlockType1, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]}]
  end

  test "search_field/3 - CHOICE field, given by type, without root" do
    db = &RRC.db/1
    assert CTT.search_field(db, db.(:"BCCH-DL-SCH-Message"), [:SystemInformationBlockType1]) ==
      [{[],
        [{:systemInformationBlockType1, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]}]
  end

  test "search_field/3 - field name, nested inside SEQUENCE OF" do
    db = &RRC.db/1
    assert CTT.search_field(db, db.(:"BCCH-DL-SCH-Message"), [:"plmn-Identity"]) ==
      [{[],
        [{:"plmn-Identity", 1, :mandatory},
         :LIST,
         {:"plmn-IdentityList", 1, :mandatory},
         {:cellAccessRelatedInfo, 1, :mandatory},
         {:systemInformationBlockType1, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]}]
  end

  test "search_field/3 - field given by type (ambiguous result), nested inside SEQUENCE OF" do
    db = &RRC.db/1
    assert CTT.search_field(db, db.(:"BCCH-DL-SCH-Message"), [:"PLMN-Identity"]) ==
      [{[], # final result #1
        [{:"plmn-Identity", 1, :mandatory},
         :LIST,
         {:"plmn-IdentityList", 1, :mandatory},
         {:cellAccessRelatedInfo, 1, :mandatory},
         {:systemInformationBlockType1, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[], # final result #2
        [{:"plmnIdentity-r12", :ALT, :mandatory},
         :LIST,
         {:"plmn-IdentityList-r12", 2, :OPTIONAL},
         :LIST,
         {:"discInterFreqList-r12", 2, :OPTIONAL},
         {:"sib19-v1250", :ALT, :mandatory},
         :LIST,
         {:"sib-TypeAndInfo", 1, :mandatory},
         {:"systemInformation-r8", :ALT, :mandatory},
         {:criticalExtensions, 1, :mandatory},
         {:systemInformation, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]}]
  end

  test "search_field/3 -- :bucketSizeDuration, 3 final results (goals)" do
    db = &RRC.db/1
    assert CTT.search_field(db, db.(:"DL-DCCH-Message"), [:RRCConnectionReconfiguration, :bucketSizeDuration]) ==
      [{[],
        [{:bucketSizeDuration, 3, :mandatory},
         {:"ul-SpecificParameters", 1, :OPTIONAL},
         {:"logicalChannelConfigSCG-r12", 6, :OPTIONAL},
         :LIST,
         {:"drb-ToAddModListSCG-r12", 1, :OPTIONAL},
         {:"radioResourceConfigDedicatedSCG-r12", 1, :OPTIONAL},
         {:"scg-ConfigPartSCG-r12", 2, :OPTIONAL},
         {:setup, :ALT, :mandatory},
         {:"scg-Configuration-r12", 2, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 3, :OPTIONAL},
         {:nonCriticalExtension, 3, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 6, :OPTIONAL},
         {:"rrcConnectionReconfiguration-r8", :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:criticalExtensions, 2, :mandatory},
         {:rrcConnectionReconfiguration, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[],
        [{:bucketSizeDuration, 3, :mandatory},
         {:"ul-SpecificParameters", 1, :OPTIONAL},
         {:logicalChannelConfig, 6, :OPTIONAL},
         :LIST,
         {:"drb-ToAddModList", 2, :OPTIONAL},
         {:radioResourceConfigDedicated, 4, :OPTIONAL},
         {:"rrcConnectionReconfiguration-r8", :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:criticalExtensions, 2, :mandatory},
         {:rrcConnectionReconfiguration, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[],
        [{:bucketSizeDuration, 3, :mandatory},
         {:"ul-SpecificParameters", 1, :OPTIONAL},
         {:explicitValue, :ALT, :mandatory},
         {:logicalChannelConfig, 3, :OPTIONAL},
         :LIST,
         {:"srb-ToAddModList", 1, :OPTIONAL},
         {:radioResourceConfigDedicated, 4, :OPTIONAL},
         {:"rrcConnectionReconfiguration-r8", :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:criticalExtensions, 2, :mandatory},
         {:rrcConnectionReconfiguration, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[:bucketSizeDuration],
         [{:rrcConnectionReconfiguration, :ALT, :mandatory},
          {:c1, :ALT, :mandatory},
          {:message, 1, :mandatory}]}]
  end

  test "search_field/3 -- :bucketSizeDuration, 2 final results (goals)" do
    db = &RRC.db/1
    assert CTT.search_field(db, db.(:"DL-DCCH-Message"), [:"drb-ToAddModList", :bucketSizeDuration]) ==
      [{[],
        [{:bucketSizeDuration, 3, :mandatory},
         {:"ul-SpecificParameters", 1, :OPTIONAL},
         {:logicalChannelConfig, 6, :OPTIONAL},
         :LIST,
         {:"drb-ToAddModList", 2, :OPTIONAL},
         {:"radioResourceConfigDedicated-r13", 1, :OPTIONAL},
         {:"rrcConnectionResume-r13", :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:criticalExtensions, 2, :mandatory},
         {:"rrcConnectionResume-r13", :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[:bucketSizeDuration],
         [{:"drb-ToAddModList", 2, :OPTIONAL},
          {:"radioResourceConfigDedicated-r13", 1, :OPTIONAL},
          {:"rrcConnectionResume-r13", :ALT, :mandatory},
          {:c1, :ALT, :mandatory},
          {:criticalExtensions, 2, :mandatory},
          {:"rrcConnectionResume-r13", :ALT, :mandatory},
          {:c1, :ALT, :mandatory},
          {:message, 1, :mandatory}]},
       {[],
        [{:bucketSizeDuration, 3, :mandatory},
         {:"ul-SpecificParameters", 1, :OPTIONAL},
         {:logicalChannelConfig, 6, :OPTIONAL},
         :LIST,
         {:"drb-ToAddModList", 2, :OPTIONAL},
         {:radioResourceConfigDedicated, 4, :OPTIONAL},
         {:"rrcConnectionReconfiguration-r8", :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:criticalExtensions, 2, :mandatory},
         {:rrcConnectionReconfiguration, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[:bucketSizeDuration],
        [{:"drb-ToAddModList", 2, :OPTIONAL},
         {:radioResourceConfigDedicated, 4, :OPTIONAL},
         {:"rrcConnectionReconfiguration-r8", :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:criticalExtensions, 2, :mandatory},
         {:rrcConnectionReconfiguration, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]}]
  end

  test "search_field/3 -- :bucketSizeDuration, 1 final result (goal)" do
    db = &RRC.db/1
    assert CTT.search_field(db, db.(:"DL-DCCH-Message"), [:RRCConnectionReconfiguration, :"drb-ToAddModList", :bucketSizeDuration]) ==
      [{[],
        [{:bucketSizeDuration, 3, :mandatory},
         {:"ul-SpecificParameters", 1, :OPTIONAL},
         {:logicalChannelConfig, 6, :OPTIONAL},
         :LIST,
         {:"drb-ToAddModList", 2, :OPTIONAL},
         {:radioResourceConfigDedicated, 4, :OPTIONAL},
         {:"rrcConnectionReconfiguration-r8", :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:criticalExtensions, 2, :mandatory},
         {:rrcConnectionReconfiguration, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[:bucketSizeDuration],
        [{:"drb-ToAddModList", 2, :OPTIONAL},
         {:radioResourceConfigDedicated, 4, :OPTIONAL},
         {:"rrcConnectionReconfiguration-r8", :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:criticalExtensions, 2, :mandatory},
         {:rrcConnectionReconfiguration, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[:"drb-ToAddModList", :bucketSizeDuration],
        [{:rrcConnectionReconfiguration, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]}]
  end

  test "search_field/3 in types that have defines like BCCH-BCH-MessageType ::= MasterInformationBlock" do
    db = &RRC.db/1
    assert CTT.search_field(db, db.(:"BCCH-BCH-Message"), [:"phich-Duration"]) ==
      [{[], # ----------------------- field  in record
        [{:"phich-Duration", 1, :mandatory},  # PHICH-Config
         {:"phich-Config", 2, :mandatory},    # MasterInformationBlock
         {:message, 1, :mandatory}]}]         # BCCH-BCH-Message
  end

end
