codeunit 9311 "Sync.Dep.Fld-P&P Setup"
{
    // This codeunit is used to synchronization between obsolete pending fields 
    // and their alternative fields in the Base Application or other extensions

    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed once the fields are marked as removed.';
    ObsoleteTag = '16.0';
    Access = Internal;

    trigger OnRun()
    begin
    end;

    local procedure SkipFieldSynchronization(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer)
    begin
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Purchases & Payables Setup", FieldNo);
    end;

    local procedure RestoreFieldSynchronization(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer)
    begin
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Purchases & Payables Setup", FieldNo);
    end;

    local procedure IsFieldSynchronizationSkipped(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer): Boolean
    begin
        exit(SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Purchases & Payables Setup", FieldNo));
    end;
}