codeunit 5453 "Graph Sync. Runner - OnModify"
{
    TableNo = "Integration Record";

    trigger OnRun()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphIntegrationTableSync: Codeunit "Graph Integration Table Sync";
        SourceRecordRef: RecordRef;
        IntegrationMappingCode: Code[20];
        InboundConnectionName: Text;
        SynchronizeConnectionName: Text;
        DestinationGraphId: Text[250];
        SyncOnRecordSkipped: Boolean;
    begin
        if IsTemporary then
            exit;

        if not GraphSyncRunner.IsGraphSyncEnabled then
            exit;

        if not GraphConnectionSetup.CanRunSync then
            exit;

        GraphConnectionSetup.RegisterConnections;
        IntegrationMappingCode := GraphDataSetup.GetMappingCodeForTable("Table ID");
        SynchronizeConnectionName := GraphConnectionSetup.GetSynchronizeConnectionName("Table ID");
        InboundConnectionName := GraphConnectionSetup.GetInboundConnectionName("Table ID");

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeConnectionName, true);

        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        SourceRecordRef.Get("Record ID");

        SyncOnRecordSkipped := GraphIntegrationTableSync.PerformRecordSynchToIntegrationTable(IntegrationTableMapping, SourceRecordRef);

        // SyncOnRecordSkipped = TRUE when conflict is detected. In this case we force sync graph to nav
        if SyncOnRecordSkipped and GraphIntegrationRecord.FindIDFromRecordID(SourceRecordRef.RecordId, DestinationGraphId) then begin
            SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, InboundConnectionName, true);
            GraphDataSetup.GetGraphRecord(SourceRecordRef, DestinationGraphId, "Table ID");
            GraphIntegrationTableSync.PerformRecordSynchFromIntegrationTable(IntegrationTableMapping, SourceRecordRef);
        end;
    end;
}

