codeunit 9312 "Sync.Dep.Fld-BankAccPostGroup"
{
    // This codeunit is used to synchronization between obsolete pending fields 
    // and their alternative fields in the Base Application or other extensions

    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed once the fields are marked as removed.';
    Access = Internal;
    ObsoleteTag = '16.0';

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account Posting Group", 'OnAfterValidateEvent', 'G/L Bank Account No.', false, false)]
    local procedure SyncOnAfterValidateGLBankAccNoInBankAccPostGrp(var Rec: Record "Bank Account Posting Group"; var xRec: Record "Bank Account Posting Group"; CurrFieldNo: Integer)
    var
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        // NAVCZ
        if IsFieldSynchronizationSkipped(SyncLoopingHelper, Rec.FieldNo("G/L Bank Account No.")) then
            exit;

        SkipFieldSynchronization(SyncLoopingHelper, Rec.FieldNo("G/L Account No."));
        Rec.Validate(Rec."G/L Account No.", Rec."G/L Bank Account No.");
        RestoreFieldSynchronization(SyncLoopingHelper, Rec.FieldNo("G/L Account No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account Posting Group", 'OnAfterValidateEvent', 'G/L Account No.', false, false)]
    local procedure SyncOnAfterValidateGLAccNoInBankAccPostGrp(var Rec: Record "Bank Account Posting Group"; var xRec: Record "Bank Account Posting Group"; CurrFieldNo: Integer)
    var
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        // NAVCZ
        if IsFieldSynchronizationSkipped(SyncLoopingHelper, Rec.FieldNo("G/L Account No.")) then
            exit;

        SkipFieldSynchronization(SyncLoopingHelper, Rec.FieldNo("G/L Bank Account No."));
        Rec.Validate("G/L Bank Account No.", Rec."G/L Account No.");
        RestoreFieldSynchronization(SyncLoopingHelper, Rec.FieldNo("G/L Bank Account No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account Posting Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertBankAccPostGrp(RunTrigger: Boolean; var Rec: Record "Bank Account Posting Group")
    var
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
        DepField: Text;
        NewField: Text;
    begin
        DepField := Rec."G/L Bank Account No.";
        NewField := Rec."G/L Account No.";
        SyncDepFldUtilities.SyncFields(DepField, NewField);
        Rec."G/L Bank Account No." := CopyStr(CopyStr(DepField, 1, MaxStrLen(Rec."G/L Bank Account No.")), 1, MaxStrlen(Rec."G/L Account No."));
        Rec."G/L Account No." := CopyStr(CopyStr(DepField, 1, MaxStrLen(Rec."G/L Account No.")), 1, MaxStrlen(Rec."G/L Bank Account No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account Posting Group", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyBankAccPostGrp(RunTrigger: Boolean; var Rec: Record "Bank Account Posting Group"; var xRec: Record "Bank Account Posting Group")
    var
        PreviousBankAccountPostingGroup: Record "Bank Account Posting Group";
        SyncDepFldUtilities: codeunit "Sync.Dep.Fld-Utilities";
        PreviousRecordRef: RecordRef;
        DepField: Text;
        NewField: Text;
    begin
        DepField := Rec."G/L Bank Account No.";
        NewField := Rec."G/L Account No.";
        if SyncDepFldUtilities.GetPreviousRecord(Rec, PreviousRecordRef) then begin
            PreviousRecordRef.SetTable(PreviousBankAccountPostingGroup);
            SyncDepFldUtilities.SyncFields(DepField, NewField, PreviousBankAccountPostingGroup."G/L Bank Account No.", PreviousBankAccountPostingGroup."G/L Account No.");
        end else
            // Follow the same flow as OnBeforeInsert, the previous record does not exist
            SyncDepFldUtilities.SyncFields(DepField, NewField);

        Rec."G/L Bank Account No." := CopyStr(CopyStr(DepField, 1, MaxStrLen(Rec."G/L Bank Account No.")), 1, MaxStrlen(Rec."G/L Account No."));
        Rec."G/L Account No." := CopyStr(CopyStr(DepField, 1, MaxStrLen(Rec."G/L Account No.")), 1, MaxStrlen(Rec."G/L Bank Account No."));
    end;

    local procedure SkipFieldSynchronization(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer)
    begin
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Bank Account Posting Group", FieldNo);
    end;

    local procedure RestoreFieldSynchronization(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer)
    begin
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Bank Account Posting Group", FieldNo);
    end;

    local procedure IsFieldSynchronizationSkipped(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; FieldNo: Integer): Boolean
    begin
        exit(SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Bank Account Posting Group", FieldNo));
    end;
}