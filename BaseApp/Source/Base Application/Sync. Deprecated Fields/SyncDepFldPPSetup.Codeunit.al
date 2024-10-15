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

    [EventSubscriber(ObjectType::Table, Database::"Purchases & Payables Setup", 'OnAfterValidateEvent', 'G/L Entry as Doc. Lines (Acc.)', false, false)]
    local procedure SyncOnAfterValidateGLEntryasDocLinesAccInPurchaseSetup(var Rec: Record "Purchases & Payables Setup"; var xRec: Record "Purchases & Payables Setup"; CurrFieldNo: Integer)
    var
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        // NAVCZ
        if IsFieldSynchronizationSkipped(SyncLoopingHelper, Rec.FieldNo("G/L Entry as Doc. Lines (Acc.)")) then
            exit;

        SkipFieldSynchronization(SyncLoopingHelper, Rec.FieldNo("Copy Line Descr. to G/L Entry"));
        Rec.Validate("Copy Line Descr. to G/L Entry", Rec."G/L Entry as Doc. Lines (Acc.)");
        RestoreFieldSynchronization(SyncLoopingHelper, Rec.FieldNo("Copy Line Descr. to G/L Entry"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchases & Payables Setup", 'OnAfterValidateEvent', 'Copy Line Descr. to G/L Entry', false, false)]
    local procedure SyncOnAfterValidateCopyLineDescrtoGLEntryInPurchaseSetup(var Rec: Record "Purchases & Payables Setup"; var xRec: Record "Purchases & Payables Setup"; CurrFieldNo: Integer)
    var
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        // NAVCZ
        if IsFieldSynchronizationSkipped(SyncLoopingHelper, Rec.FieldNo("Copy Line Descr. to G/L Entry")) then
            exit;

        SkipFieldSynchronization(SyncLoopingHelper, Rec.FieldNo("G/L Entry as Doc. Lines (Acc.)"));
        Rec.Validate("G/L Entry as Doc. Lines (Acc.)", Rec."Copy Line Descr. to G/L Entry");
        RestoreFieldSynchronization(SyncLoopingHelper, Rec.FieldNo("G/L Entry as Doc. Lines (Acc.)"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchases & Payables Setup", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertPurchaseSetup(RunTrigger: Boolean; var Rec: Record "Purchases & Payables Setup")
    var
        SyncDepFldUtilities: codeunit "Sync.Dep.Fld-Utilities";
    begin
        // NAVCZ
        SyncDepFldUtilities.SyncFields(Rec."G/L Entry as Doc. Lines (Acc.)", Rec."Copy Line Descr. to G/L Entry", false, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchases & Payables Setup", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyPurchaseSetup(RunTrigger: Boolean; var Rec: Record "Purchases & Payables Setup"; var xRec: Record "Purchases & Payables Setup")
    var
        PreviousPurchaseAndPayablesSetup: Record "Purchases & Payables Setup";
        SyncDepFldUtilities: codeunit "Sync.Dep.Fld-Utilities";
        PreviousRecordRef: RecordRef;
    begin
        // NAVCZ
        if SyncDepFldUtilities.GetPreviousRecord(Rec, PreviousRecordRef) then begin
            PreviousRecordRef.SetTable(PreviousPurchaseAndPayablesSetup);
            SyncDepFldUtilities.SyncFields(Rec."G/L Entry as Doc. Lines (Acc.)", Rec."Copy Line Descr. to G/L Entry", PreviousPurchaseAndPayablesSetup."G/L Entry as Doc. Lines (Acc.)", PreviousPurchaseAndPayablesSetup."Copy Line Descr. to G/L Entry");
        end else
            // Follow the same flow as OnBeforeInsert, the previous record does not exist
            SyncDepFldUtilities.SyncFields(Rec."G/L Entry as Doc. Lines (Acc.)", Rec."Copy Line Descr. to G/L Entry", false, false);
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