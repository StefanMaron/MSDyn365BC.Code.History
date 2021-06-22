codeunit 5445 "Graph Delta Sync"
{

    trigger OnRun()
    var
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        GraphSyncRunner.RunDeltaSync
    end;
}

