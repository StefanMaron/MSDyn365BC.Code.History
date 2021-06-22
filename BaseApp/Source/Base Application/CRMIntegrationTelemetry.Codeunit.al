codeunit 5333 "CRM Integration Telemetry"
{

    trigger OnRun()
    begin
        SendIntegrationStatsTelemetry;
    end;

    var
        CRMConnectionCategoryTxt: Label 'AL CRM Connection', Locked = true;
        CRMIntegrationCategoryTxt: Label 'AL CRM Integration', Locked = true;
        EnabledConnectionTelemetryTxt: Label '{"Enabled": "Yes", "AuthenticationType": "%1", "CRMVersion": "%2", "ProxyVersion": "%3", "CRMSolutionInstalled": "%4", "SOIntegration": "%5", "AutoCreateSO": "%6", "AutoProcessSQ": "%7", "UsersMapRequired": "%8", "ItemAvailablityEnabled": "%9"}', Locked = true;
        DisabledConnectionTelemetryTxt: Label '{"Enabled": "No", "DisableReason": "%1","AuthenticationType": "%2", "ProxyVersion": "%3", "AutoCreateSO": "%4", "UsersMapRequired": "%5"}', Locked = true;
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        IntegrationTableStatsTxt: Label '{"TableID": "%1", "IntTableID": "%2", "Direction": "%3", "SyncCoupledOnly": "%4", "SyncJobsTotal": "%5", "TotalRecords": "%6", "CoupledRecords": "%7", "CoupledErrors": "%8"}', Locked = true;
        NoPermissionTxt: Label '{"READPERMISSION": "No"}', Locked = true;
        UserOpenedSetupPageTxt: Label 'User is attempting to set up the connection via %1 page.', Locked = true;
        UserDisabledConnectionTxt: Label 'User disabled the connection to %1.', Locked = true;

    local procedure GetEnabledConnectionTelemetryData(CRMConnectionSetup: Record "CRM Connection Setup"): Text
    begin
        with CRMConnectionSetup do
            exit(
              StrSubstNo(
                EnabledConnectionTelemetryTxt,
                Format("Authentication Type"), "CRM Version", "Proxy Version", "Is CRM Solution Installed",
                "Is S.Order Integration Enabled", "Auto Create Sales Orders", "Auto Process Sales Quotes",
                "Is User Mapping Required", CRMIntegrationManagement.IsItemAvailabilityWebServiceEnabled));
    end;

    local procedure GetDisabledConnectionTelemetryData(CRMConnectionSetup: Record "CRM Connection Setup"): Text
    begin
        with CRMConnectionSetup do
            exit(
              StrSubstNo(
                DisabledConnectionTelemetryTxt,
                "Disable Reason", Format("Authentication Type"), "Proxy Version", "Auto Create Sales Orders", "Is User Mapping Required"));
    end;

    local procedure GetIntegrationStatsTelemetryData() Data: Text
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        TableData: Text;
        Comma: Text;
    begin
        if not IntegrationTableMapping.ReadPermission then
            exit(NoPermissionTxt);

        Data := '[';
        with IntegrationTableMapping do
            if FindSet then
                repeat
                    TableData :=
                      StrSubstNo(
                        IntegrationTableStatsTxt,
                        "Table ID", "Integration Table ID", Format(Direction), "Synch. Only Coupled Records",
                        GetSyncJobsTotal(Name), GetTotalRecords("Table ID"),
                        GetCoupledRecords("Table ID"), GetCoupledErrors("Table ID"));
                    Data += Comma + TableData;
                    Comma := ','
                until Next = 0;
        Data += ']';
    end;

    local procedure GetSyncJobsTotal(Name: Code[20]): Integer
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        if not IntegrationSynchJob.ReadPermission then
            exit(-1);
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", Name);
        exit(IntegrationSynchJob.Count);
    end;

    local procedure GetTotalRecords(TableID: Integer) Result: Integer
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        if RecRef.ReadPermission then
            Result := RecRef.Count
        else
            Result := -1;
        RecRef.Close;
    end;

    local procedure GetCoupledRecords(TableID: Integer): Integer
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if not CRMIntegrationRecord.ReadPermission then
            exit(-1);
        CRMIntegrationRecord.SetRange("Table ID", TableID);
        exit(CRMIntegrationRecord.Count);
    end;

    local procedure GetCoupledErrors(TableID: Integer): Integer
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if not CRMIntegrationRecord.ReadPermission then
            exit(-1);
        CRMIntegrationRecord.SetRange("Table ID", TableID);
        CRMIntegrationRecord.SetRange(Skipped, true);
        exit(CRMIntegrationRecord.Count);
    end;

    local procedure SendConnectionTelemetry(CRMConnectionSetup: Record "CRM Connection Setup")
    begin
        with CRMConnectionSetup do
            if "Is Enabled" then
                SendTraceTag(
                  '000024X', CRMConnectionCategoryTxt, VERBOSITY::Normal,
                  GetEnabledConnectionTelemetryData(CRMConnectionSetup), DATACLASSIFICATION::SystemMetadata)
            else
                SendTraceTag(
                  '000024Y', CRMConnectionCategoryTxt, VERBOSITY::Normal,
                  GetDisabledConnectionTelemetryData(CRMConnectionSetup), DATACLASSIFICATION::SystemMetadata);
    end;

    local procedure SendIntegrationStatsTelemetry()
    begin
        SendTraceTag(
          '000024Z', CRMIntegrationCategoryTxt, VERBOSITY::Normal,
          GetIntegrationStatsTelemetryData, DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Table, 5330, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertConnectionSetup(var Rec: Record "CRM Connection Setup"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            SendConnectionTelemetry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 5330, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyConnectionSetup(var Rec: Record "CRM Connection Setup"; var xRec: Record "CRM Connection Setup"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            SendConnectionTelemetry(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5330, 'OnAfterCRMIntegrationEnabled', '', true, true)]
    local procedure ScheduleCRMIntTelemetryAfterIntegrationEnabled()
    var
        CodeUnitMetadata: Record "CodeUnit Metadata";
        TelemetryManagement: Codeunit "Telemetry Management";
    begin
        if CodeUnitMetadata.Get(CODEUNIT::"CRM Integration Telemetry") then
            TelemetryManagement.ScheduleCalEventsForTelemetryAsync(CodeUnitMetadata.RecordId, CODEUNIT::"Create Telemetry Cal. Events", 10);
    end;

    [Scope('OnPrem')]
    procedure LogTelemetryWhenConnectionDisabled()
    var
        CRMProductName: Codeunit "CRM Product Name";
    begin
        SendTraceTag(
          '00008A0', CRMConnectionCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(UserDisabledConnectionTxt, CRMProductName.SHORT), DATACLASSIFICATION::SystemMetadata)
    end;

    [EventSubscriber(ObjectType::Page, 5330, 'OnOpenPageEvent', '', false, false)]
    local procedure LogTelemetryOnAfterOpenCRMConnectionSetup(var Rec: Record "CRM Connection Setup")
    var
        CRMConnectionSetup: Page "CRM Connection Setup";
    begin
        SendTraceTag(
          '00008A1', CRMConnectionCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(UserOpenedSetupPageTxt, CRMConnectionSetup.Caption), DATACLASSIFICATION::SystemMetadata)
    end;

    [EventSubscriber(ObjectType::Page, 1817, 'OnOpenPageEvent', '', false, false)]
    local procedure LogTelemetryOnAfterOpenCRMConnectionSetupWizard(var Rec: Record "CRM Connection Setup")
    var
        CRMConnectionSetupWizard: Page "CRM Connection Setup Wizard";
    begin
        SendTraceTag(
          '00008A2', CRMConnectionCategoryTxt, VERBOSITY::Normal,
          StrSubstNo(UserOpenedSetupPageTxt, CRMConnectionSetupWizard.Caption), DATACLASSIFICATION::SystemMetadata)
    end;
}

