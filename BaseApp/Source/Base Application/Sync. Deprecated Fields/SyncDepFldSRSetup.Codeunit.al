codeunit 9310 "Sync.Dep.Fld-S&R Setup"
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

    [EventSubscriber(ObjectType::Table, Database::"Sales & Receivables Setup", 'OnAfterValidateEvent', 'G/L Entry as Doc. Lines (Acc.)', false, false)]
    local procedure SyncOnAfterValidateGLEntryasDocLinesAccInSalesSetup(var Rec: Record "Sales & Receivables Setup"; var xRec: Record "Sales & Receivables Setup"; CurrFieldNo: Integer)
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

    [EventSubscriber(ObjectType::Table, Database::"Sales & Receivables Setup", 'OnAfterValidateEvent', 'Copy Line Descr. to G/L Entry', false, false)]
    local procedure SyncOnAfterValidateCopyLineDescrtoGLEntryInSalesSetup(var Rec: Record "Sales & Receivables Setup"; var xRec: Record "Sales & Receivables Setup"; CurrFieldNo: Integer)
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

    [EventSubscriber(ObjectType::Table, Database::"Sales & Receivables Setup", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertSalesSetup(RunTrigger: Boolean; var Rec: Record "Sales & Receivables Setup")
    var
        SyncDepFldUtilities: codeunit "Sync.Dep.Fld-Utilities";
    begin
        // NAVCZ
        SyncDepFldUtilities.SyncFields(Rec."G/L Entry as Doc. Lines (Acc.)", Rec."Copy Line Descr. to G/L Entry", false, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales & Receivables Setup", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifySalesSetup(RunTrigger: Boolean; var Rec: Record "Sales & Receivables Setup"; var xRec: Record "Sales & Receivables Setup")
    var
        PreviousSalesReceivablesSetup: Record "Sales & Receivables Setup";
        SyncDepFldUtilities: codeunit "Sync.Dep.Fld-Utilities";
        PreviousRecordRef: RecordRef;
    begin
        // NAVCZ
        if SyncDepFldUtilities.GetPreviousRecord(Rec, PreviousRecordRef) then begin
            PreviousRecordRef.SetTable(PreviousSalesReceivablesSetup);
            SyncDepFldUtilities.SyncFields(Rec."G/L Entry as Doc. Lines (Acc.)", Rec."Copy Line Descr. to G/L Entry", PreviousSalesReceivablesSetup."G/L Entry as Doc. Lines (Acc.)", PreviousSalesReceivablesSetup."Copy Line Descr. to G/L Entry");
        end else
            // Follow the same flow as OnBeforeInsert, the previous record does not exist
            SyncDepFldUtilities.SyncFields(Rec."G/L Entry as Doc. Lines (Acc.)", Rec."Copy Line Descr. to G/L Entry", false, false);
    end;

    local procedure SkipFieldSynchronization(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer)
    begin
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Sales & Receivables Setup", FieldNo);
    end;

    local procedure RestoreFieldSynchronization(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer)
    begin
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Sales & Receivables Setup", FieldNo);
    end;

    local procedure IsFieldSynchronizationSkipped(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer): Boolean
    begin
        exit(SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Sales & Receivables Setup", FieldNo));
    end;
}