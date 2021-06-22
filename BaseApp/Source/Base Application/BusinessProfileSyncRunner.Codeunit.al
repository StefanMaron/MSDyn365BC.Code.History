codeunit 5440 "Business Profile Sync. Runner"
{

    trigger OnRun()
    var
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::"Company Information");
    end;
}

