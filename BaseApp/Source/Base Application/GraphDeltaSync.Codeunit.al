codeunit 5445 "Graph Delta Sync"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This functionality will be removed. The API that it was integrating to was discontinued.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    var
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        GraphSyncRunner.RunDeltaSync
    end;
}

