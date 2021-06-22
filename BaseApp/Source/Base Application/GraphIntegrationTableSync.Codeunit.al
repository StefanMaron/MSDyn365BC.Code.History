codeunit 5451 "Graph Integration Table Sync"
{
    TableNo = "Integration Table Mapping";

    trigger OnRun()
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        GraphSubscriptionManagement: Codeunit "Graph Subscription Management";
        SynchronizeConnectionName: Text;
    begin
        GraphConnectionSetup.RegisterConnections;
        SynchronizeConnectionName := GraphConnectionSetup.GetSynchronizeConnectionName("Table ID");
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeConnectionName, true);

        if not TryAccessGraph(Rec) then begin
            SendTraceTag(
              '00001SP', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Error,
              StrSubstNo(NoGraphAccessTxt, GetLastErrorText), DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        if Direction in [Direction::ToIntegrationTable, Direction::Bidirectional] then
            PerformScheduledSynchToIntegrationTable(Rec);

        if Direction in [Direction::FromIntegrationTable, Direction::Bidirectional] then
            PerformScheduledSynchFromIntegrationTable(Rec);
    end;

    var
        SkippingSyncTxt: Label 'Ignoring sync for record of table %1.', Locked = true;
        NoGraphAccessTxt: Label 'Skipping synchronization due to an error accessing the Graph table. \\%1', Comment = '%1 - The error message.', Locked = true;

    local procedure PerformScheduledSynchToIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        IntegrationRecord: Record "Integration Record";
        ModifiedOnIntegrationRecord: Record "Integration Record";
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        LatestModifiedOn: DateTime;
        Found: Boolean;
        SkipSyncOnRecord: Boolean;
    begin
        SourceRecordRef.Open(IntegrationTableMapping."Table ID");

        IntegrationRecord.SetRange("Table ID", IntegrationTableMapping."Table ID");
        if IntegrationTableMapping."Synch. Modified On Filter" <> 0DT then
            IntegrationRecord.SetFilter("Modified On", '>%1', IntegrationTableMapping."Synch. Modified On Filter");

        // Peform synch.
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::MicrosoftGraph, IntegrationTableMapping, SourceRecordRef.Number);

        LatestModifiedOn := 0DT;
        if not IntegrationRecord.FindSet then begin
            IntegrationTableSynch.EndIntegrationSynchJob;
            exit;
        end;

        repeat
            Found := false;
            SkipSyncOnRecord := false;

            if SourceRecordRef.Get(IntegrationRecord."Record ID") then
                Found := true;

            if not Found then
                if GraphIntegrationRecord.IsRecordCoupled(IntegrationRecord."Record ID") then begin
                    SourceRecordRef.Get(IntegrationRecord."Record ID");
                    Found := true;
                end;

            OnBeforeSynchronizationStart(IntegrationTableMapping, SourceRecordRef, SkipSyncOnRecord);

            if Found and (not SkipSyncOnRecord) then
                if IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false) then begin
                    SaveChangeKeyFromDestinationRefToGraphIntegrationTable(IntegrationTableMapping, DestinationRecordRef);
                    ModifiedOnIntegrationRecord.FindByRecordId(SourceRecordRef.RecordId);
                    if ModifiedOnIntegrationRecord."Modified On" > LatestModifiedOn then
                        LatestModifiedOn := ModifiedOnIntegrationRecord."Modified On";
                end;
        until (IntegrationRecord.Next = 0);

        IntegrationTableSynch.EndIntegrationSynchJob;

        if (LatestModifiedOn <> 0DT) and (LatestModifiedOn > IntegrationTableMapping."Synch. Modified On Filter") then begin
            IntegrationTableMapping."Synch. Modified On Filter" := LatestModifiedOn;
            IntegrationTableMapping.Modify(true);
        end;
    end;

    local procedure PerformScheduledSynchFromIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SourceRecordRef: RecordRef;
        SourceRecordRef2: RecordRef;
        DestinationRecordRef: RecordRef;
        SourceFieldRef: FieldRef;
        ModifiedOn: DateTime;
        LatestModifiedOn: DateTime;
        SkipSyncOnRecord: Boolean;
    begin
        SourceRecordRef.Open(IntegrationTableMapping."Integration Table ID");
        if IntegrationTableMapping."Graph Delta Token" <> '' then begin
            SourceFieldRef := SourceRecordRef.Field(IntegrationTableMapping."Int. Tbl. Delta Token Fld. No.");
            SourceFieldRef.SetFilter('<>%1', IntegrationTableMapping."Graph Delta Token");
        end;

        // Peform synch.
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::MicrosoftGraph, IntegrationTableMapping, SourceRecordRef.Number);

        LatestModifiedOn := 0DT;
        if SourceRecordRef.FindSet then begin
            SaveDeltaTokenFromSourceRecRefToIntegrationTable(SourceRecordRef, IntegrationTableMapping);
            repeat
                SourceRecordRef2 := SourceRecordRef.Duplicate;
                SkipSyncOnRecord := false;
                OnBeforeSynchronizationStart(IntegrationTableMapping, SourceRecordRef2, SkipSyncOnRecord);
                if not SkipSyncOnRecord then
                    if IntegrationTableSynch.Synchronize(SourceRecordRef2, DestinationRecordRef, true, false) then begin
                        SaveChangeKeyFromDestinationRefToGraphIntegrationTable(IntegrationTableMapping, SourceRecordRef2);
                        ModifiedOn := IntegrationTableSynch.GetRowLastModifiedOn(IntegrationTableMapping, SourceRecordRef2);
                        if ModifiedOn > LatestModifiedOn then
                            LatestModifiedOn := ModifiedOn;
                    end;
            until (SourceRecordRef.Next = 0);
        end;

        IntegrationTableSynch.EndIntegrationSynchJob;

        if (LatestModifiedOn <> 0DT) and (LatestModifiedOn > IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr.") then begin
            IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := LatestModifiedOn;
            IntegrationTableMapping.Modify(true);
        end;
    end;

    procedure PerformRecordSynchToIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef): Boolean
    var
        ModifiedOnIntegrationRecord: Record "Integration Record";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        DestinationRecordRef: RecordRef;
        LatestModifiedOn: DateTime;
        SkipSyncOnRecord: Boolean;
    begin
        if GetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph) = '' then
            exit;

        // Peform synch.
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::MicrosoftGraph, IntegrationTableMapping, SourceRecordRef.Number);

        LatestModifiedOn := 0DT;

        OnBeforeSynchronizationStart(IntegrationTableMapping, SourceRecordRef, SkipSyncOnRecord);
        if not SkipSyncOnRecord then
            if IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, false) then begin
                SaveChangeKeyFromDestinationRefToGraphIntegrationTable(IntegrationTableMapping, DestinationRecordRef);
                ModifiedOnIntegrationRecord.FindByRecordId(SourceRecordRef.RecordId);
                if ModifiedOnIntegrationRecord."Modified On" > LatestModifiedOn then
                    LatestModifiedOn := ModifiedOnIntegrationRecord."Modified On";
            end;

        IntegrationTableSynch.EndIntegrationSynchJob;

        exit(SkipSyncOnRecord);
    end;

    procedure PerformRecordSynchFromIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef)
    var
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        DestinationRecordRef: RecordRef;
        ModifiedOn: DateTime;
        LatestModifiedOn: DateTime;
        SkipSyncOnRecord: Boolean;
    begin
        if GetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph) = '' then
            exit;

        // Peform synch.
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::MicrosoftGraph, IntegrationTableMapping, SourceRecordRef.Number);

        LatestModifiedOn := 0DT;
        OnBeforeSynchronizationStart(IntegrationTableMapping, SourceRecordRef, SkipSyncOnRecord);
        if not SkipSyncOnRecord then
            if IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, true, false) then begin
                SaveChangeKeyFromDestinationRefToGraphIntegrationTable(IntegrationTableMapping, SourceRecordRef);
                ModifiedOn := IntegrationTableSynch.GetRowLastModifiedOn(IntegrationTableMapping, SourceRecordRef);
                if ModifiedOn > LatestModifiedOn then
                    LatestModifiedOn := ModifiedOn;
            end;

        IntegrationTableSynch.EndIntegrationSynchJob;
    end;

    procedure PerformRecordDeleteFromIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping"; DestinationRecordRef: RecordRef)
    var
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SkipSyncOnRecord: Boolean;
    begin
        if GetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph) = '' then
            exit;

        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::MicrosoftGraph, IntegrationTableMapping, DestinationRecordRef.Number);
        OnBeforeSynchronizationStart(IntegrationTableMapping, DestinationRecordRef, SkipSyncOnRecord);
        IntegrationTableSynch.Delete(DestinationRecordRef);
        IntegrationTableSynch.EndIntegrationSynchJob;
    end;

    procedure PerformRecordDeleteToIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping"; DestinationRecordRef: RecordRef)
    var
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SkipSyncOnRecord: Boolean;
    begin
        if GetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph) = '' then
            exit;

        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::MicrosoftGraph, IntegrationTableMapping, DestinationRecordRef.Number);
        OnBeforeSynchronizationStart(IntegrationTableMapping, DestinationRecordRef, SkipSyncOnRecord);
        if IntegrationTableSynch.Delete(DestinationRecordRef) then
            ArchiveIntegrationRecords(DestinationRecordRef, IntegrationTableMapping);

        IntegrationTableSynch.EndIntegrationSynchJob;
    end;

    local procedure SaveDeltaTokenFromSourceRecRefToIntegrationTable(SourceRecRef: RecordRef; var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        DeltaTokenFieldRef: FieldRef;
    begin
        if IntegrationTableMapping."Int. Tbl. Delta Token Fld. No." > 0 then begin
            DeltaTokenFieldRef := SourceRecRef.Field(IntegrationTableMapping."Int. Tbl. Delta Token Fld. No.");
            IntegrationTableMapping."Graph Delta Token" := DeltaTokenFieldRef.Value;
            IntegrationTableMapping.Modify();
        end;
    end;

    local procedure SaveChangeKeyFromDestinationRefToGraphIntegrationTable(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecRef: RecordRef)
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        ChangeKeyFieldRef: FieldRef;
        GraphIdFieldRef: FieldRef;
    begin
        if SourceRecRef.Number = IntegrationTableMapping."Integration Table ID" then begin
            ChangeKeyFieldRef := SourceRecRef.Field(IntegrationTableMapping."Int. Tbl. ChangeKey Fld. No.");
            GraphIdFieldRef := SourceRecRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");

            GraphIntegrationRecord.SetRange("Graph ID", Format(GraphIdFieldRef.Value));
            GraphIntegrationRecord.SetRange("Table ID", IntegrationTableMapping."Table ID");
            if GraphIntegrationRecord.FindFirst then begin
                GraphIntegrationRecord.ChangeKey := ChangeKeyFieldRef.Value;
                GraphIntegrationRecord.Modify();
            end;
        end;
    end;

    procedure WasChangeKeyModifiedAfterLastRecordSynch(IntegrationTableMapping: Record "Integration Table Mapping"; var RecordRef: RecordRef): Boolean
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphRecordRef: RecordRef;
        ChangeKeyFieldRef: FieldRef;
        GraphIdFieldRef: FieldRef;
        DestinationGraphId: Text[250];
    begin
        // If a changekey field is not present, default it to changed so that the sync is not skipped
        if IntegrationTableMapping."Int. Tbl. ChangeKey Fld. No." = 0 then
            exit(true);

        if IntegrationTableMapping."Integration Table ID" = RecordRef.Number then begin
            ChangeKeyFieldRef := RecordRef.Field(IntegrationTableMapping."Int. Tbl. ChangeKey Fld. No.");
            GraphIdFieldRef := RecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");

            GraphIntegrationRecord.SetRange("Graph ID", Format(GraphIdFieldRef.Value));
            GraphIntegrationRecord.SetRange("Table ID", IntegrationTableMapping."Table ID");
            if not GraphIntegrationRecord.FindFirst then
                exit(true);
            if GraphIntegrationRecord.ChangeKey <> Format(ChangeKeyFieldRef.Value) then
                exit(true);
        end;

        if IntegrationTableMapping."Table ID" = RecordRef.Number then
            if GraphIntegrationRecord.FindIDFromRecordID(RecordRef.RecordId, DestinationGraphId) then begin
                GraphRecordRef.Open(IntegrationTableMapping."Integration Table ID");
                GraphIdFieldRef := GraphRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
                GraphIdFieldRef.SetRange(DestinationGraphId);
                if not GraphRecordRef.FindFirst then
                    exit(true);

                ChangeKeyFieldRef := GraphRecordRef.Field(IntegrationTableMapping."Int. Tbl. ChangeKey Fld. No.");
                GraphIntegrationRecord.SetRange("Graph ID", DestinationGraphId);
                GraphIntegrationRecord.SetRange("Table ID", IntegrationTableMapping."Table ID");
                if not GraphIntegrationRecord.FindFirst then
                    exit(true);
                if Format(ChangeKeyFieldRef.Value) <> GraphIntegrationRecord.ChangeKey then
                    exit(true);
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5451, 'OnBeforeSynchronizationStart', '', false, false)]
    local procedure IgnoreSyncBasedOnChangekey(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        GraphSubscriptionManagement: Codeunit "Graph Subscription Management";
    begin
        if IgnoreRecord or (IntegrationTableMapping."Int. Tbl. ChangeKey Fld. No." = 0) then
            exit;
        if WasChangeKeyModifiedAfterLastRecordSynch(IntegrationTableMapping, SourceRecordRef) then begin
            IgnoreRecord := SourceRecordRef.Number = IntegrationTableMapping."Table ID";
            if IgnoreRecord then
                SendTraceTag(
                  '00001BE', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Verbose,
                  StrSubstNo(SkippingSyncTxt, SourceRecordRef.Number), DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        IgnoreRecord := SourceRecordRef.Number = IntegrationTableMapping."Integration Table ID";
    end;

    local procedure ArchiveIntegrationRecords(RecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping")
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphIntegrationRecArchive: Record "Graph Integration Rec. Archive";
        GraphIdFieldRef: FieldRef;
    begin
        GraphIdFieldRef := RecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
        GraphIntegrationRecord.SetRange("Graph ID", Format(GraphIdFieldRef.Value));
        GraphIntegrationRecord.SetRange("Table ID", IntegrationTableMapping."Table ID");
        if GraphIntegrationRecord.FindFirst then begin
            GraphIntegrationRecArchive.TransferFields(GraphIntegrationRecord);
            if GraphIntegrationRecArchive.Insert() then
                GraphIntegrationRecord.Delete();
        end;
    end;

    [TryFunction]
    local procedure TryAccessGraph(IntegrationTableMapping: Record "Integration Table Mapping")
    var
        GraphRecordRef: RecordRef;
    begin
        // Attempt to call an operation on the graph. If it fails, then a sync shouldn't be attempted.
        GraphRecordRef.Open(IntegrationTableMapping."Integration Table ID");
        if GraphRecordRef.IsEmpty then;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSynchronizationStart(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
    end;
}

