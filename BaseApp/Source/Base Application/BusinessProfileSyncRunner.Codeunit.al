#if not CLEAN18
codeunit 5440 "Business Profile Sync. Runner"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This functionality will be removed. The API that it was integrating to was discontinued.';
    ObsoleteTag = '18.0';

    trigger OnRun()
    var
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::"Company Information");
    end;
}
#endif
