codeunit 5452 "Graph Sync. Runner"
{

    trigger OnRun()
    begin
        RunFullSync;
    end;

    var
        GraphDataSetup: Codeunit "Graph Data Setup";
        ALGraphSyncSynchronouslyCategoryTxt: Label 'AL Graph Sync Synchronously', Locked = true;

    procedure IsGraphSyncEnabled(): Boolean
    var
        MarketingSetup: Record "Marketing Setup";
        AuxSyncEnabled: Boolean;
    begin
        if CurrentExecutionMode = EXECUTIONMODE::Debug then
            exit(false);

        if not MarketingSetup.Get then
            exit(false);

        if MarketingSetup."Sync with Microsoft Graph" then
            exit(true);

        OnCheckAuxiliarySyncEnabled(AuxSyncEnabled);
        exit(AuxSyncEnabled);
    end;

    procedure RunDeltaSync()
    begin
        OnRunGraphDeltaSync;
    end;

    procedure RunDeltaSyncForEntity(TableID: Integer)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationMappingCode: Code[20];
    begin
        IntegrationMappingCode := GraphDataSetup.GetMappingCodeForTable(TableID);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        if not IntegrationTableMapping.IsFullSyncAllowed then
            exit;

        IntegrationTableMapping.SetFullSyncStartAndCommit();
        RunIntegrationTableSynch(IntegrationTableMapping);

        IntegrationTableMapping.Get(IntegrationTableMapping.Name);
        IntegrationTableMapping.SetFullSyncEndAndCommit();

        OnAfterRunDeltaSyncForEntity(TableID);
    end;

    procedure RunFullSync()
    begin
        OnRunGraphFullSync;
    end;

    procedure RunFullSyncForEntity(TableID: Integer)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationMappingCode: Code[20];
    begin
        IntegrationMappingCode := GraphDataSetup.GetMappingCodeForTable(TableID);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        if not IntegrationTableMapping.IsFullSyncAllowed then
            exit;
        IntegrationTableMapping.SetFullSyncStartAndCommit();

        IntegrationTableMapping."Graph Delta Token" := '';
        IntegrationTableMapping.Modify(true);

        CreateIntegrationRecordsForUncoupledRecords(IntegrationTableMapping."Table ID");
        RunIntegrationTableSynch(IntegrationTableMapping);

        IntegrationTableMapping.Get(IntegrationTableMapping.Name);
        IntegrationTableMapping.SetFullSyncEndAndCommit();

        OnAfterRunFullSyncForEntity(TableID);
    end;

    procedure RunIntegrationTableSynch(IntegrationTableMapping: Record "Integration Table Mapping")
    var
        IntegrationManagement: Codeunit "Integration Management";
        InsertEnabled: Boolean;
        ModifyEnabled: Boolean;
        DeleteEnabled: Boolean;
        RenameEnabled: Boolean;
    begin
        IntegrationManagement.GetDatabaseTableTriggerSetup(
          IntegrationTableMapping."Table ID", InsertEnabled, ModifyEnabled, DeleteEnabled, RenameEnabled);
        CODEUNIT.Run(IntegrationTableMapping."Synch. Codeunit ID", IntegrationTableMapping);
    end;

    local procedure CreateIntegrationRecordsForUncoupledRecords(TableId: Integer)
    var
        IntegrationRecord: Record "Integration Record";
        IntegrationManagement: Codeunit "Integration Management";
        NavRecordRef: RecordRef;
    begin
        NavRecordRef.Open(TableId);

        if NavRecordRef.FindSet then
            repeat
                Clear(IntegrationRecord);
                IntegrationRecord.SetRange("Record ID", NavRecordRef.RecordId);
                if IntegrationRecord.IsEmpty then begin
                    Clear(IntegrationRecord);
                    IntegrationRecord."Integration ID" := NavRecordRef.Field(NavRecordRef.SystemIdNo()).Value();
                    IntegrationRecord."Record ID" := NavRecordRef.RecordId;
                    IntegrationRecord."Table ID" := NavRecordRef.Number;
                    IntegrationRecord.Insert(true);
                end;
            until NavRecordRef.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAuxiliarySyncEnabled(var AuxSyncEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunGraphDeltaSync()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunGraphFullSync()
    begin
    end;

    procedure SyncFromGraphSynchronously(CodeunitId: Integer; TimeoutInSeconds: Integer)
    var
        SessionId: Integer;
        StartDateTime: DateTime;
        TimePassed: Duration;
        TimeoutReached: Boolean;
    begin
        // Start session will use CPU time of main thread while main thread is SLEEPing
        // Taskscheduler cannot be used since it requires a COMMIT to start
        SessionId := 0;

        if not StartSession(SessionId, CodeunitId, CompanyName) then begin
            OnSyncSynchronouslyCannotStartSession('Codeunit: ' + Format(CodeunitId));
            exit;
        end;

        StartDateTime := CurrentDateTime;

        repeat
            Sleep(300);
            if not IsSessionActive(SessionId) then
                exit;

            TimePassed := CurrentDateTime - StartDateTime;
            TimeoutReached := TimePassed > TimeoutInSeconds * 1000;
        until TimeoutReached;

        OnSyncSynchronouslyTimeout('Codeunit: ' + Format(CodeunitId));
    end;

    procedure GetDefaultSyncSynchronouslyTimeoutInSeconds(): Integer
    begin
        // User is waiting for the sync to complete
        // This value should not be too great
        exit(30);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSyncSynchronouslyCannotStartSession(AdditionalDetails: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSyncSynchronouslyTimeout(AdditionalDetails: Text)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 5452, 'OnSyncSynchronouslyCannotStartSession', '', false, false)]
    local procedure HandleOnSyncSynchronouslyCannotStartSession(AdditionalDetails: Text)
    begin
        SendTraceTag(
          '00001KX', ALGraphSyncSynchronouslyCategoryTxt, VERBOSITY::Error,
          'Could not start the session. ' + AdditionalDetails, DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5452, 'OnSyncSynchronouslyTimeout', '', false, false)]
    local procedure HandleOnSyncSynchronouslySessionTimeout(AdditionalDetails: Text)
    begin
        SendTraceTag(
          '00001KY', ALGraphSyncSynchronouslyCategoryTxt, VERBOSITY::Error,
          'Timeout on the Forced Graph Sync. ' + AdditionalDetails, DATACLASSIFICATION::SystemMetadata);
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterRunDeltaSyncForEntity(TableId: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterRunFullSyncForEntity(TableId: Integer)
    begin
    end;
}

