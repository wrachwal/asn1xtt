defmodule AsnCdbS1X2Test do
  use ExUnit.Case

  test "S1AP elementary_procedures/2" do
    s1ap = &S1AP.db/1
    assert s1ap
      |> ASN.CDB.S1X2.elementary_procedures(:"S1AP-ELEMENTARY-PROCEDURES")
      |> Enum.map(&Map.fetch!(&1, :msg_type)) == [
      :HandoverRequired, :HandoverCommand, :HandoverPreparationFailure,
      :HandoverRequest, :HandoverRequestAcknowledge, :HandoverFailure,
      :HandoverNotify, :PathSwitchRequest, :PathSwitchRequestAcknowledge,
      :PathSwitchRequestFailure, :HandoverCancel, :HandoverCancelAcknowledge,
      :"E-RABSetupRequest", :"E-RABSetupResponse", :"E-RABModifyRequest",
      :"E-RABModifyResponse", :"E-RABReleaseCommand", :"E-RABReleaseResponse",
      :"E-RABReleaseIndication", :InitialContextSetupRequest,
      :InitialContextSetupResponse, :InitialContextSetupFailure, :Paging,
      :DownlinkNASTransport, :InitialUEMessage, :UplinkNASTransport, :Reset,
      :ResetAcknowledge, :ErrorIndication, :NASNonDeliveryIndication,
      :S1SetupRequest, :S1SetupResponse, :S1SetupFailure, :UEContextReleaseRequest,
      :DownlinkS1cdma2000tunnelling, :UplinkS1cdma2000tunnelling,
      :UEContextModificationRequest, :UEContextModificationResponse,
      :UEContextModificationFailure, :UECapabilityInfoIndication,
      :UEContextReleaseCommand, :UEContextReleaseComplete, :ENBStatusTransfer,
      :MMEStatusTransfer, :DeactivateTrace, :TraceStart, :TraceFailureIndication,
      :ENBConfigurationUpdate, :ENBConfigurationUpdateAcknowledge,
      :ENBConfigurationUpdateFailure, :MMEConfigurationUpdate,
      :MMEConfigurationUpdateAcknowledge, :MMEConfigurationUpdateFailure,
      :LocationReportingControl, :LocationReportingFailureIndication,
      :LocationReport, :OverloadStart, :OverloadStop, :WriteReplaceWarningRequest,
      :WriteReplaceWarningResponse, :ENBDirectInformationTransfer,
      :MMEDirectInformationTransfer, :PrivateMessage, :ENBConfigurationTransfer,
      :MMEConfigurationTransfer, :CellTrafficTrace, :KillRequest, :KillResponse,
      :DownlinkUEAssociatedLPPaTransport, :UplinkUEAssociatedLPPaTransport,
      :DownlinkNonUEAssociatedLPPaTransport, :UplinkNonUEAssociatedLPPaTransport,
      :UERadioCapabilityMatchRequest, :UERadioCapabilityMatchResponse,
      :PWSRestartIndication, :"E-RABModificationIndication",
      :"E-RABModificationConfirm", :PWSFailureIndication, :RerouteNASRequest,
      :UEContextModificationIndication, :UEContextModificationConfirm,
      :ConnectionEstablishmentIndication, :UEContextSuspendRequest,
      :UEContextSuspendResponse, :UEContextResumeRequest, :UEContextResumeResponse,
      :UEContextResumeFailure, :NASDeliveryIndication, :RetrieveUEInformation,
      :UEInformationTransfer, :ENBCPRelocationIndication, :MMECPRelocationIndication,
      :SecondaryRATDataUsageReport
    ]
  end

  test "X2AP elementary_procedures/2" do
    x2ap = &X2AP.db/1
    assert x2ap
      |> ASN.CDB.S1X2.elementary_procedures(:"X2AP-ELEMENTARY-PROCEDURES")
      |> Enum.map(&Map.fetch!(&1, :msg_type)) == [
      :HandoverRequest, :HandoverRequestAcknowledge, :HandoverPreparationFailure,
      :HandoverCancel, :LoadInformation, :ErrorIndication, :SNStatusTransfer,
      :UEContextRelease, :X2SetupRequest, :X2SetupResponse, :X2SetupFailure,
      :ResetRequest, :ResetResponse, :ENBConfigurationUpdate,
      :ENBConfigurationUpdateAcknowledge, :ENBConfigurationUpdateFailure,
      :ResourceStatusRequest, :ResourceStatusResponse, :ResourceStatusFailure,
      :ResourceStatusUpdate, :PrivateMessage, :MobilityChangeRequest,
      :MobilityChangeAcknowledge, :MobilityChangeFailure, :RLFIndication,
      :HandoverReport, :CellActivationRequest, :CellActivationResponse,
      :CellActivationFailure, :X2Release, :X2APMessageTransfer, :X2RemovalRequest,
      :X2RemovalResponse, :X2RemovalFailure, :SeNBAdditionRequest,
      :SeNBAdditionRequestAcknowledge, :SeNBAdditionRequestReject,
      :SeNBReconfigurationComplete, :SeNBModificationRequest,
      :SeNBModificationRequestAcknowledge, :SeNBModificationRequestReject,
      :SeNBModificationRequired, :SeNBModificationConfirm, :SeNBModificationRefuse,
      :SeNBReleaseRequest, :SeNBReleaseRequired, :SeNBReleaseConfirm,
      :SeNBCounterCheckRequest, :RetrieveUEContextRequest,
      :RetrieveUEContextResponse, :RetrieveUEContextFailure, :SgNBAdditionRequest,
      :SgNBAdditionRequestAcknowledge, :SgNBAdditionRequestReject,
      :SgNBReconfigurationComplete, :SgNBModificationRequest,
      :SgNBModificationRequestAcknowledge, :SgNBModificationRequestReject,
      :SgNBModificationRequired, :SgNBModificationConfirm, :SgNBModificationRefuse,
      :SgNBReleaseRequest, :SgNBReleaseRequestAcknowledge, :SgNBReleaseRequestReject,
      :SgNBReleaseRequired, :SgNBReleaseConfirm, :SgNBCounterCheckRequest,
      :SgNBChangeRequired, :SgNBChangeConfirm, :SgNBChangeRefuse, :RRCTransfer,
      :ENDCX2SetupRequest, :ENDCX2SetupResponse, :ENDCX2SetupFailure,
      :ENDCConfigurationUpdate, :ENDCConfigurationUpdateAcknowledge,
      :ENDCConfigurationUpdateFailure, :SecondaryRATDataUsageReport,
      :ENDCCellActivationRequest, :ENDCCellActivationResponse,
      :ENDCCellActivationFailure, :ENDCPartialResetRequired,
      :ENDCPartialResetConfirm, :EUTRANRCellResourceCoordinationRequest,
      :EUTRANRCellResourceCoordinationResponse, :SgNBActivityNotification,
      :ENDCX2RemovalRequest, :ENDCX2RemovalResponse, :ENDCX2RemovalFailure,
      :DataForwardingAddressIndication, :GNBStatusIndication
    ]
  end

  test "S1AP ies" do
    s1ap = &S1AP.db/1
    msg_types =
      s1ap
      |> ASN.CDB.S1X2.elementary_procedures(:"S1AP-ELEMENTARY-PROCEDURES")
      |> Enum.map(&Map.fetch!(&1, :msg_type))
    msg_ies =
      for type <- msg_types, into: %{} do
        {type, ASN.CDB.S1X2.message_ies(s1ap, type)}
      end
    assert [
      %{id: :"id-eNB-UE-S1AP-ID",  criticality: :reject, type: :"ENB-UE-S1AP-ID",  presence: :mandatory},
      %{id: :"id-MME-UE-S1AP-ID",  criticality: :ignore, type: :"MME-UE-S1AP-ID",  presence: :optional},
      %{id: :"id-S1-Message",      criticality: :reject, type: :"OCTET STRING",    presence: :mandatory},
      %{id: :"id-MME-Group-ID",    criticality: :reject, type: :"MME-Group-ID",    presence: :mandatory},
      %{id: :"id-Additional-GUTI", criticality: :ignore, type: :"Additional-GUTI", presence: :optional},
      %{id: :"id-UE-Usage-Type",   criticality: :ignore, type: :"UE-Usage-Type",   presence: :optional}
    ] = Map.fetch!(msg_ies, :RerouteNASRequest)
  end

  test "X2AP ies" do
    x2ap = &X2AP.db/1
    msg_types =
      x2ap
      |> ASN.CDB.S1X2.elementary_procedures(:"X2AP-ELEMENTARY-PROCEDURES")
      |> Enum.map(&Map.fetch!(&1, :msg_type))
    msg_ies =
      for type <- msg_types, into: %{} do
        {type, ASN.CDB.S1X2.message_ies(x2ap, type)}
      end
    assert [
      %{id: :"id-Cause", criticality: :ignore, type: :Cause, presence: :mandatory}
    ] = Map.fetch!(msg_ies, :ResetRequest)
  end

end
