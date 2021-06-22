codeunit 5454 "Graph Sync. Runner - OnDelete"
{
    TableNo = "Integration Record Archive";

    trigger OnRun()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphIntegrationTableSync: Codeunit "Graph Integration Table Sync";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
        GraphRecordRef: RecordRef;
        GraphIdFieldRef: FieldRef;
        SynchronizeConnectionName: Text;
        IntegrationMappingCode: Code[20];
    begin
        if IsTemporary then
            exit;

        if not GraphSyncRunner.IsGraphSyncEnabled then
            exit;

        if not GraphConnectionSetup.CanRunSync then
            exit;

        GraphConnectionSetup.RegisterConnections;
        SynchronizeConnectionName := GraphConnectionSetup.GetSynchronizeConnectionName("Table ID");
        IntegrationMappingCode := GraphDataSetup.GetMappingCodeForTable("Table ID");

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeConnectionName, true);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);

        GraphIntegrationRecord.SetRange("Integration ID", "Integration ID");
        GraphIntegrationRecord.SetRange("Table ID", IntegrationTableMapping."Table ID");
        if GraphIntegrationRecord.FindFirst then begin
            GraphRecordRef.Open(IntegrationTableMapping."Integration Table ID");
            GraphIdFieldRef := GraphRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
            GraphIdFieldRef.SetRange(GraphIntegrationRecord."Graph ID");
            if GraphRecordRef.FindFirst then
                GraphIntegrationTableSync.PerformRecordDeleteToIntegrationTable(IntegrationTableMapping, GraphRecordRef);
        end;
    end;
}

