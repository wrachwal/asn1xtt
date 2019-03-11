defmodule AsnCttTest do
  use ExUnit.Case

  alias ASN.CTT

  defp tuple_lists_lengths(tuple) do
    tuple
    |> Tuple.to_list()
    |> Enum.map(&length/1)
    |> List.to_tuple()
  end

  test "__typedef__ tuple lists lengths" do
    # 0 -> {:typedef, ... {:type, ...
    # 1 -> {:typedef, ... {:Object, ...
    # 2 -> {:typedef, ... {:ObjectSet, ...
    # 3 -> like 0, but not in :MODULE's :typeorval
    # 4 -> like 1, but not in :MODULE's :typeorval
    # 5 -> like 2, but not in :MODULE's :typeorval
    assert tuple_lists_lengths(RRC.db(:__typedef__)) == {2419, 0, 0, 3, 0, 0}
    assert tuple_lists_lengths(S1AP.db(:__typedef__)) == {564, 63, 263, 3, 0, 540}
    assert tuple_lists_lengths(X2AP.db(:__typedef__)) == {664, 46, 376, 3, 0, 746}
  end

  test "__classdef__ tuple lists lengths" do
    # 0 -> {:classdef, ...
    # 1 -> like 0, but not in :MODULE's :typeorval
    assert tuple_lists_lengths(RRC.db(:__classdef__)) == {0, 2}
    assert tuple_lists_lengths(S1AP.db(:__classdef__)) == {5, 2}
    assert tuple_lists_lengths(X2AP.db(:__classdef__)) == {5, 2}
  end

  test "CTT.asn_type_kind/1" do
    type_kind = CTT.asn_type_kind(&RRC.db/1)
    kind_used =
      type_kind
      |> Map.values
      |> Enum.reduce(%{}, fn k, m -> m |> Map.put_new(k, 0) |> update_in([k], &(&1 + 1)) end)
      |> Enum.sort
    assert kind_used == ["BIT STRING": 25,
                         BOOLEAN: 1,
                         CHOICE: 158,
                         ENUMERATED: 90,
                         Externaltypereference: 18, #XXX ???
                         INTEGER: 128,
                         "OCTET STRING": 5,
                         SEQUENCE: 1539,
                         "SEQUENCE OF": 455]
    exttyperefs =
      type_kind
      |> Enum.filter(fn {_, k} -> k == :Externaltypereference end)
      |> Keyword.keys
      |> Enum.sort
    assert exttyperefs == [:"BCCH-BCH-MessageType",
                           :"BCCH-BCH-MessageType-MBMS-r14",
                           :"BCCH-BCH-MessageType-MF",
                           :"BCCH-BCH-MessageType-NB",
                           :"BCCH-BCH-MessageType-TDD-NB-r15",
                           :"BandParametersDL-r13",
                           :"BandParametersUL-r13",
                           :"MobilityHistoryReport-r12",
                           :"RedirectedCarrierInfo-NB-r13",
                           :"SBCCH-SL-BCH-MessageType",
                           :"SBCCH-SL-BCH-MessageType-V2X-r14",
                           :"SystemInformation-BR-r13",
                           :"SystemInformation-MBMS-r14",
                           :"SystemInformationBlockType1-BR-r13",
                           :"SystemInformationBlockType16-NB-r13",
                           :"VarMobilityHistoryReport-r12",
                           :"VarShortMAC-Input-NB-r13",
                           :"VarShortResumeMAC-Input-NB-r13"]
  end

  test "ASN.CTT.asn_roots/1" do
    assert CTT.asn_roots(&RRC.db/1) == [
      :"BCCH-BCH-Message", :"BCCH-BCH-Message-MBMS", :"BCCH-BCH-Message-MF", :"BCCH-BCH-Message-NB", :"BCCH-BCH-Message-TDD-NB", :"BCCH-DL-SCH-Message",
      :"BCCH-DL-SCH-Message-BR", :"BCCH-DL-SCH-Message-MBMS", :"BCCH-DL-SCH-Message-MF", :"BCCH-DL-SCH-Message-NB",
      :"DL-CCCH-Message", :"DL-CCCH-Message-MF", :"DL-CCCH-Message-NB", :"DL-DCCH-Message", :"DL-DCCH-Message-MF",
      :"DL-DCCH-Message-NB", :HandoverCommand, :"HandoverCommand-MF",
      :HandoverPreparationInformation, :"HandoverPreparationInformation-MF", :"HandoverPreparationInformation-NB",
      :"HandoverPreparationInformation-v9j0-IEs", :"MCCH-Message", :"PCCH-Message", :"PCCH-Message-MF",
      :"PCCH-Message-NB", :"RRCConnectionReconfiguration-v8m0-IEs",
      :"RRCConnectionRelease-v9e0-IEs", :"SBCCH-SL-BCH-Message", :"SBCCH-SL-BCH-Message-V2X-r14", :"SC-MCCH-Message-NB",
      :"SC-MCCH-Message-r13", :"SCG-ConfigInfo-r12", :"SCGFailureInformation-v12d0-IEs",
      :"SL-Preconfiguration-r12", :"SL-V2X-Preconfiguration-r14",
      :"SystemInformationBlockType1-v8h0-IEs", :"SystemInformationBlockType2-v10m0-IEs",
      :"SystemInformationBlockType2-v8h0-IEs",
      :"SystemInformationBlockType3-v10j0-IEs",
      :"SystemInformationBlockType5-v8h0-IEs",
      :"SystemInformationBlockType6-v8h0-IEs", :"UE-Capability-NB-Ext-r14-IEs", :"UE-EUTRA-Capability",
      :"UE-EUTRA-Capability-v10j0-IEs", :"UE-EUTRA-Capability-v9a0-IEs",
      :"UEInformationResponse-v9e0-IEs", :UEPagingCoverageInformation,
      :"UEPagingCoverageInformation-NB", :UERadioAccessCapabilityInformation,
      :"UERadioAccessCapabilityInformation-NB", :UERadioPagingInformation,
      :"UERadioPagingInformation-NB", :"UL-CCCH-Message", :"UL-CCCH-Message-MF", :"UL-CCCH-Message-NB",
      :"UL-DCCH-Message", :"UL-DCCH-Message-MF", :"UL-DCCH-Message-NB", :"VarConnEstFailReport-r11",
      :"VarLogMeasConfig-r10", :"VarLogMeasConfig-r11", :"VarLogMeasConfig-r12", :"VarLogMeasConfig-r15",
      :"VarLogMeasReport-r10", :"VarLogMeasReport-r11", :VarMeasConfig, :"VarMeasConfig-MF", :"VarMeasIdleConfig-r15", :"VarMeasIdleReport-r15",
      :VarMeasReportList, :"VarMeasReportList-r12", :"VarMobilityHistoryReport-r12", :"VarPendingRnaUpdate-r15",
      :"VarRLF-Report-r10", :"VarRLF-Report-r11", :"VarShortINACTIVE-MAC-Input-r15", :"VarShortMAC-Input-NB-r13",
      :"VarShortResumeMAC-Input-NB-r13", :"VarWLAN-MobilityConfig",
      :"VarWLAN-Status-r13"
    ] #XXX length = 81
  end

  test "__typedef__ and __valuedef__ are in order as in .asn" do
    assert (RRC.db(:__typedef__) |> elem(0) |> Enum.take(8))  == [
        :"BCCH-BCH-Message",
        :"BCCH-BCH-MessageType",
        :"BCCH-BCH-Message-MBMS",
        :"BCCH-BCH-MessageType-MBMS-r14",
        :"BCCH-DL-SCH-Message",
        :"BCCH-DL-SCH-MessageType",
        :"BCCH-DL-SCH-Message-BR",
        :"BCCH-DL-SCH-MessageType-BR-r13",
      ]
    assert Enum.take(RRC.db(:__valuedef__), 4) == [
        :"maxAccessCat-1-r15",
        :"maxACDC-Cat-r13",
        :"maxAvailNarrowBands-r13",
        :"maxBandComb-r10"
      ]
  end

  test "search_field/3 - goal starting with root" do
    db = &RRC.db/1
    assert CTT.search_field(db, db.(:MasterInformationBlock), [:MasterInformationBlock, :"phich-Config"]) ==
      [{[],
        [{:"phich-Config", 2, :mandatory}]}]
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
         {:message, 1, :mandatory}]}]
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
         {:"plmn-IdentityList-r14", 1, :mandatory},
         :LIST,
         {:"cellAccessRelatedInfoList-r14", 3, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 5, :OPTIONAL},
         {:nonCriticalExtension, 4, :OPTIONAL},
         {:nonCriticalExtension, 3, :OPTIONAL},
         {:nonCriticalExtension, 3, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 9, :OPTIONAL},
         {:systemInformationBlockType1, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[],
        [{:"plmn-Identity", 1, :mandatory},
         :LIST,
         {:"plmn-IdentityList", 1, :mandatory},
         {:cellAccessRelatedInfo, 1, :mandatory},
         {:systemInformationBlockType1, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[],
        [{:"plmn-Identity", 1, :mandatory},
         :LIST,
         {:"plmn-IdentityList-r14", 1, :OPTIONAL},
         :LIST,
         {:"v2x-InterFreqInfoList-r15", 1, :OPTIONAL},
         {:"sib26-v1530", :ALT, :mandatory},
         :LIST,
         {:"sib-TypeAndInfo", 1, :mandatory},
         {:"systemInformation-r8", :ALT, :mandatory},
         {:criticalExtensions, 1, :mandatory},
         {:systemInformation, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[],
        [{:"plmn-Identity", 1, :mandatory},
         :LIST,
         {:"plmn-IdentityList-r14", 1, :OPTIONAL},
         :LIST,
         {:"v2x-InterFreqInfoList-r14", 6, :OPTIONAL},
         {:"sl-V2X-ConfigCommon-r14", 1, :OPTIONAL},
         {:"sib21-v1430", :ALT, :mandatory},
         :LIST,
         {:"sib-TypeAndInfo", 1, :mandatory},
         {:"systemInformation-r8", :ALT, :mandatory},
         {:criticalExtensions, 1, :mandatory},
         {:systemInformation, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]}]
  end

  test "search_field/3 - field given by type (ambiguous result), nested inside SEQUENCE OF" do
    db = &RRC.db/1
    assert CTT.search_field(db, db.(:"BCCH-DL-SCH-Message"), [:"PLMN-Identity"]) ==
      [{[],
        [{:"plmn-Identity-r15", :ALT, :mandatory},
         {:"plmn-Identity-5GC-r15", 1, :mandatory},
         :LIST,
         {:"plmn-IdentityList-r15", 1, :mandatory},
         :LIST,
         {:"cellAccessRelatedInfoList-5GC-r15", 3, :mandatory},
         {:"cellAccessRelatedInfo-5GC-r15", 7, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 4, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 5, :OPTIONAL},
         {:nonCriticalExtension, 4, :OPTIONAL},
         {:nonCriticalExtension, 3, :OPTIONAL},
         {:nonCriticalExtension, 3, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 9, :OPTIONAL},
         {:systemInformationBlockType1, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[],
        [{:"plmn-Identity", 1, :mandatory},
         :LIST,
         {:"plmn-IdentityList-r14", 1, :mandatory},
         :LIST,
         {:"cellAccessRelatedInfoList-r14", 3, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 5, :OPTIONAL},
         {:nonCriticalExtension, 4, :OPTIONAL},
         {:nonCriticalExtension, 3, :OPTIONAL},
         {:nonCriticalExtension, 3, :OPTIONAL},
         {:nonCriticalExtension, 2, :OPTIONAL},
         {:nonCriticalExtension, 9, :OPTIONAL},
         {:systemInformationBlockType1, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[],
        [{:"plmn-Identity", 1, :mandatory},
         :LIST,
         {:"plmn-IdentityList", 1, :mandatory},
         {:cellAccessRelatedInfo, 1, :mandatory},
         {:systemInformationBlockType1, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[],
        [{:"plmn-Identity", 1, :mandatory},
         :LIST,
         {:"plmn-IdentityList-r14", 1, :OPTIONAL},
         :LIST,
         {:"v2x-InterFreqInfoList-r15", 1, :OPTIONAL},
         {:"sib26-v1530", :ALT, :mandatory},
         :LIST,
         {:"sib-TypeAndInfo", 1, :mandatory},
         {:"systemInformation-r8", :ALT, :mandatory},
         {:criticalExtensions, 1, :mandatory},
         {:systemInformation, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[],
        [{:"plmn-Identity", 1, :mandatory},
         :LIST,
         {:"plmn-IdentityList-r14", 1, :OPTIONAL},
         :LIST,
         {:"v2x-InterFreqInfoList-r14", 6, :OPTIONAL},
         {:"sl-V2X-ConfigCommon-r14", 1, :OPTIONAL},
         {:"sib21-v1430", :ALT, :mandatory},
         :LIST,
         {:"sib-TypeAndInfo", 1, :mandatory},
         {:"systemInformation-r8", :ALT, :mandatory},
         {:criticalExtensions, 1, :mandatory},
         {:systemInformation, :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:message, 1, :mandatory}]},
       {[],
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
    assert IO.inspect CTT.search_field(db, db.(:"DL-DCCH-Message"), [:RRCConnectionReconfiguration, :bucketSizeDuration]) ==
      [{[],
        [{:bucketSizeDuration, 3, :mandatory},
         {:"ul-SpecificParameters", 1, :OPTIONAL},
         {:"logicalChannelConfig-r15", 3, :OPTIONAL},
         {:setup, :ALT, :mandatory},
         {:"rlc-BearerConfigDupl-r15", 6, :OPTIONAL},
         :LIST,
         {:"srb-ToAddModListSCG-r15", 5, :OPTIONAL},
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
         {:explicitValue, :ALT, :mandatory},
         {:logicalChannelConfig, 3, :OPTIONAL},
         :LIST,
         {:"srb-ToAddModListSCG-r15", 5, :OPTIONAL},
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
         {:"logicalChannelConfig-r15", 3, :OPTIONAL},
         {:setup, :ALT, :mandatory},
         {:"rlc-BearerConfigDupl-r15", 10, :OPTIONAL},
         :LIST,
         {:"drb-ToAddModListSCG-r15", 4, :OPTIONAL},
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
         {:"logicalChannelConfigSCG-r12", 6, :OPTIONAL},
         :LIST,
         {:"drb-ToAddModListSCG-r15", 4, :OPTIONAL},
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
         {:"logicalChannelConfig-r15", 3, :OPTIONAL},
         {:setup, :ALT, :mandatory},
         {:"rlc-BearerConfigDupl-r15", 10, :OPTIONAL},
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
         {:"logicalChannelConfig-r15", 3, :OPTIONAL},
         {:setup, :ALT, :mandatory},
         {:"rlc-BearerConfigDupl-r15", 18, :OPTIONAL},
         :LIST,
         {:"drb-ToAddModList-r15", 19, :OPTIONAL},
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
         {:logicalChannelConfig, 6, :OPTIONAL},
         :LIST,
         {:"drb-ToAddModList-r15", 19, :OPTIONAL},
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
         {:"logicalChannelConfig-r15", 3, :OPTIONAL},
         {:setup, :ALT, :mandatory},
         {:"rlc-BearerConfigDupl-r15", 6, :OPTIONAL},
         :LIST,
         {:"srb-ToAddModExtList-r15", 14, :OPTIONAL},
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
         {:"srb-ToAddModExtList-r15", 14, :OPTIONAL},
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
         {:"logicalChannelConfig-r15", 3, :OPTIONAL},
         {:setup, :ALT, :mandatory},
         {:"rlc-BearerConfigDupl-r15", 18, :OPTIONAL},
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
         {:"logicalChannelConfig-r15", 3, :OPTIONAL},
         {:setup, :ALT, :mandatory},
         {:"rlc-BearerConfigDupl-r15", 6, :OPTIONAL},
         :LIST,
         {:"srb-ToAddModList", 1, :OPTIONAL},
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
         {:message, 1, :mandatory}]}]
  end

  test "search_field/3 -- :bucketSizeDuration, 2 final results (goals)" do
    db = &RRC.db/1
    assert CTT.search_field(db, db.(:"DL-DCCH-Message"), [:"drb-ToAddModList", :bucketSizeDuration]) ==
      [{[],
        [{:bucketSizeDuration, 3, :mandatory},
         {:"ul-SpecificParameters", 1, :OPTIONAL},
         {:"logicalChannelConfig-r15", 3, :OPTIONAL},
         {:setup, :ALT, :mandatory},
         {:"rlc-BearerConfigDupl-r15", 18, :OPTIONAL},
         :LIST,
         {:"drb-ToAddModList", 2, :OPTIONAL},
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
         {:"logicalChannelConfig-r15", 3, :OPTIONAL},
         {:setup, :ALT, :mandatory},
         {:"rlc-BearerConfigDupl-r15", 18, :OPTIONAL},
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
         {:logicalChannelConfig, 6, :OPTIONAL},
         :LIST,
         {:"drb-ToAddModList", 2, :OPTIONAL},
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
         {:"logicalChannelConfig-r15", 3, :OPTIONAL},
         {:setup, :ALT, :mandatory},
         {:"rlc-BearerConfigDupl-r15", 18, :OPTIONAL},
         :LIST,
         {:"drb-ToAddModList", 2, :OPTIONAL},
         {:radioResourceConfigDedicated, 4, :OPTIONAL},
         {:"rrcConnectionReconfiguration-r8", :ALT, :mandatory},
         {:c1, :ALT, :mandatory},
         {:criticalExtensions, 2, :mandatory},
         {:rrcConnectionReconfiguration, :ALT, :mandatory},
         {:c1, :ALT, :mandatory}, {:message, 1, :mandatory}]},
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

  test "search_field/3 in s1ap..." do
    db = &S1AP.db/1
    assert CTT.search_field(db, db.(:"S1AP-PDU"), [:"S1AP-PDU", :"e-RAB-ID"]) ==
      [{[:"e-RAB-ID"], []}] #FIXME
  end

end
