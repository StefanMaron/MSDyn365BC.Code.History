#if not CLEAN23
codeunit 10602 "Sync.Dep.Fld - VAT Code"
{
    Access = Internal;
    ObsoleteReason = 'The codeunit is used to syncronize obsolete fields. Once they are removed this is no longer needed.';
    ObsoleteState = Pending;
    ObsoleteTag = '23.0';
    Permissions = tabledata "VAT Code" = rimd,
                  tabledata "VAT Reporting Code" = rimd;

    var
        ActionTypeOption: Option Insert,Modify,Delete;

    // Syncronize fields from VAT Code to VAT Reporting Code

    [EventSubscriber(ObjectType::Table, Database::"VAT Code", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertVATCode(var Rec: Record "VAT Code"; RunTrigger: Boolean)
    begin
        SyncFromDeprecatedTable(Rec, ActionTypeOption::Insert, RunTrigger);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Code", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyVATCode(var Rec: Record "VAT Code"; RunTrigger: Boolean)
    begin
        SyncFromDeprecatedTable(Rec, ActionTypeOption::Modify, RunTrigger);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Code", 'OnAfterDeleteEvent', '', false, false)]
    local procedure SyncOnAfterDeleteVATCode(var Rec: Record "VAT Code"; RunTrigger: Boolean)
    begin
        SyncFromDeprecatedTable(Rec, ActionTypeOption::Delete, RunTrigger);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Code", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameVATCode(var Rec: Record "VAT Code"; var xRec: Record "VAT Code")
    var
        VATReportingCode: Record "VAT Reporting Code";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Code") then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Reporting Code");

        GetVATReportingCodeLinkedToVATCode(VATReportingCode, xRec.Code);
        if not IsNullGuid(VATReportingCode.SystemId) then
            VATReportingCode.Rename(Rec.Code);

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Reporting Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Code", 'OnAfterRenameEvent', '', false, false)]
    local procedure SyncOnAfterRenameVATCode(var Rec: Record "VAT Code"; var xRec: Record "VAT Code")
    var
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Code") then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Code");

        Rec."Linked VAT Reporting Code" := Rec.Code;
        Rec.Modify();

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Code");
    end;

    // Syncronize fields from VAT Reporting Code to VAT Code

    [EventSubscriber(ObjectType::Table, Database::"VAT Reporting Code", 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncOnAfterInsertVATReportingCode(var Rec: Record "VAT Reporting Code"; RunTrigger: Boolean)
    begin
        SyncToDeprecatedTable(Rec, ActionTypeOption::Insert, RunTrigger);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Reporting Code", 'OnAfterModifyEvent', '', false, false)]
    local procedure SyncOnAfterModifyVATReportingCode(var Rec: Record "VAT Reporting Code"; RunTrigger: Boolean)
    begin
        SyncToDeprecatedTable(Rec, ActionTypeOption::Modify, RunTrigger);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Reporting Code", 'OnAfterDeleteEvent', '', false, false)]
    local procedure SyncOnAfterDeleteVATReportingCode(var Rec: Record "VAT Reporting Code"; RunTrigger: Boolean)
    begin
        SyncToDeprecatedTable(Rec, ActionTypeOption::Delete, RunTrigger);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Reporting Code", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameVATReportingCode(var Rec: Record "VAT Reporting Code"; var xRec: Record "VAT Reporting Code")
    var
        VATCode: Record "VAT Code";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        VATReportingCodeCode: Code[20];
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Reporting Code") then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Code");

        VATReportingCodeCode := Rec.Code;
        if StrLen(VATReportingCodeCode) > MaxStrLen(VATCode.Code) then
            VATReportingCodeCode := GetShortVATCode(VATReportingCodeCode);

        GetVATCodeLinkedToVATReportingCode(VATCode, xRec.Code);
        if not IsNullGuid(VATCode.SystemId) then begin
            VATCode."Linked VAT Reporting Code" := Rec.Code;
            VATCode.Modify();
            VATCode.Rename(VATReportingCodeCode);
        end;

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Code");
    end;

    // Syncronize fields VAT Code and VAT Number in VAT Posting Setup
    [EventSubscriber(ObjectType::Table, Database::"VAT Posting Setup", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyVATPostingSetup(var Rec: Record "VAT Posting Setup"; RunTrigger: Boolean)
    var
        PreviousRecord: Record "VAT Posting Setup";
        VATCode: Record "VAT Code";
        VATReportingCode: Record "VAT Reporting Code";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        PreviousRecordRef: RecordRef;
        DepFieldTxt, NewFieldTxt : Text;
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Code") then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Reporting Code") then
            exit;

        if SyncDepFldUtilities.GetPreviousRecord(Rec, PreviousRecordRef) then
            PreviousRecordRef.SetTable(PreviousRecord);

        // VAT Code <-> VAT Number
        DepFieldTxt := Rec."VAT Code";
        NewFieldTxt := Rec."VAT Number";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."VAT Code", PreviousRecord."VAT Number");
        GetVATCodeLinkedToVATReportingCode(VATCode, DepFieldTxt);
        GetVATReportingCodeLinkedToVATCode(VATReportingCode, NewFieldTxt);
        DepFieldTxt := VATCode.Code;
        NewFieldTxt := VATReportingCode.Code;
        Rec."VAT Code" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."VAT Code"));
        Rec."VAT Number" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."VAT Number"));

        // Sales VAT Reporting Code <-> Sale VAT Reporting Code
        DepFieldTxt := Rec."Sales VAT Reporting Code";
        NewFieldTxt := Rec."Sale VAT Reporting Code";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Sales VAT Reporting Code", PreviousRecord."Sale VAT Reporting Code");
        GetVATCodeLinkedToVATReportingCode(VATCode, DepFieldTxt);
        GetVATReportingCodeLinkedToVATCode(VATReportingCode, NewFieldTxt);
        DepFieldTxt := VATCode.Code;
        NewFieldTxt := VATReportingCode.Code;
        Rec."Sales VAT Reporting Code" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Sales VAT Reporting Code"));
        Rec."Sale VAT Reporting Code" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Sale VAT Reporting Code"));

        // Purchase VAT Reporting Code <-> Purch. VAT Reporting Code
        DepFieldTxt := Rec."Purchase VAT Reporting Code";
        NewFieldTxt := Rec."Purch. VAT Reporting Code";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Purchase VAT Reporting Code", PreviousRecord."Purch. VAT Reporting Code");
        GetVATCodeLinkedToVATReportingCode(VATCode, DepFieldTxt);
        GetVATReportingCodeLinkedToVATCode(VATReportingCode, NewFieldTxt);
        DepFieldTxt := VATCode.Code;
        NewFieldTxt := VATReportingCode.Code;
        Rec."Purchase VAT Reporting Code" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Purchase VAT Reporting Code"));
        Rec."Purch. VAT Reporting Code" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Purch. VAT Reporting Code"));
    end;

    // Syncronize fields VAT Code and VAT Number in G/L Account
    [EventSubscriber(ObjectType::Table, Database::"G/L Account", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyGLAccount(var Rec: Record "G/L Account"; RunTrigger: Boolean)
    var
        PreviousRecord: Record "G/L Account";
        VATCode: Record "VAT Code";
        VATReportingCode: Record "VAT Reporting Code";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        PreviousRecordRef: RecordRef;
        DepFieldTxt, NewFieldTxt : Text;
    begin
        if Rec.IsTemporary() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Code") then
            exit;
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Reporting Code") then
            exit;

        if SyncDepFldUtilities.GetPreviousRecord(Rec, PreviousRecordRef) then
            PreviousRecordRef.SetTable(PreviousRecord);
        DepFieldTxt := Rec."VAT Code";
        NewFieldTxt := Rec."VAT Number";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."VAT Code", PreviousRecord."VAT Number");
        GetVATCodeLinkedToVATReportingCode(VATCode, DepFieldTxt);
        GetVATReportingCodeLinkedToVATCode(VATReportingCode, NewFieldTxt);
        DepFieldTxt := VATCode.Code;
        NewFieldTxt := VATReportingCode.Code;
        Rec."VAT Code" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."VAT Code"));
        Rec."VAT Number" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."VAT Number"));
    end;

    local procedure SyncFromDeprecatedTable(var VATCode: Record "VAT Code"; ActionType: Option; RunTrigger: Boolean)
    var
        VATReportingCode: Record "VAT Reporting Code";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if VATCode.IsTemporary() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Code") then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Reporting Code");

        case ActionType of
            ActionTypeOption::Insert:
                begin
                    VATReportingCode.Init();
                    VATReportingCode.Code := VATCode.Code;
                    CopyFieldsFromObsoleteTable(VATCode, VATReportingCode);
                    VATReportingCode.Insert(RunTrigger);
                    VATCode."Linked VAT Reporting Code" := VATReportingCode.Code;
                    VATCode.Modify();
                end;
            ActionTypeOption::Modify:
                begin
                    GetVATReportingCodeLinkedToVATCode(VATReportingCode, VATCode.Code);
                    if not IsNullGuid(VATReportingCode.SystemId) then begin
                        CopyFieldsFromObsoleteTable(VATCode, VATReportingCode);
                        VATReportingCode.Modify(RunTrigger);
                    end;
                end;
            ActionTypeOption::Delete:
                begin
                    GetVATReportingCodeLinkedToVATCode(VATReportingCode, VATCode.Code);
                    if not IsNullGuid(VATReportingCode.SystemId) then
                        VATReportingCode.Delete(RunTrigger);
                end;
        end;

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Reporting Code");
    end;

    local procedure SyncToDeprecatedTable(var VATReportingCode: Record "VAT Reporting Code"; ActionType: Option; RunTrigger: Boolean)
    var
        VATCode: Record "VAT Code";
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
        VATReportingCodeCode: Code[20];
    begin
        if VATReportingCode.IsTemporary() then
            exit;

        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"VAT Reporting Code") then
            exit;
        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"VAT Code");

        case ActionType of
            ActionTypeOption::Insert:
                begin
                    VATReportingCodeCode := VATReportingCode.Code;
                    if StrLen(VATReportingCodeCode) > MaxStrLen(VATCode.Code) then
                        VATReportingCodeCode := GetShortVATCode(VATReportingCodeCode);

                    VATCode.Init();
                    VATCode.Code := CopyStr(VATReportingCodeCode, 1, MaxStrLen(VATCode.Code));
                    CopyFieldsToObsoleteTable(VATReportingCode, VATCode);
                    VATCode.Insert(RunTrigger);
                end;
            ActionTypeOption::Modify:
                begin
                    GetVATCodeLinkedToVATReportingCode(VATCode, VATReportingCode.Code);
                    if not IsNullGuid(VATCode.SystemId) then begin
                        CopyFieldsToObsoleteTable(VATReportingCode, VATCode);
                        VATCode.Modify(RunTrigger);
                    end;
                end;
            ActionTypeOption::Delete:
                begin
                    GetVATCodeLinkedToVATReportingCode(VATCode, VATReportingCode.Code);
                    if not IsNullGuid(VATCode.SystemId) then
                        VATCode.Delete(RunTrigger);
                end;
        end;

        SyncLoopingHelper.RestoreFieldSynchronization(Database::"VAT Code");
    end;

    local procedure CopyFieldsFromObsoleteTable(var VATCode: Record "VAT Code"; var VATReportingCode: Record "VAT Reporting Code")
    begin
        VATReportingCode."Gen. Posting Type" := VATCode."Gen. Posting Type";
        VATReportingCode."Test Gen. Posting Type" := VATCode."Test Gen. Posting Type";
        VATReportingCode.Description := VATCode.Description;
        VATReportingCode."Trade Settlement 2017 Box No." := VATCode."Trade Settlement 2017 Box No.";
        VATReportingCode."Reverse Charge Report Box No." := VATCode."Reverse Charge Report Box No.";
        VATReportingCode."VAT Specification Code" := VATCode."VAT Specification Code";
        VATReportingCode."VAT Note Code" := VATCode."VAT Note Code";
    end;

    local procedure CopyFieldsToObsoleteTable(var VATReportingCode: Record "VAT Reporting Code"; var VATCode: Record "VAT Code")
    begin
        VATCode."Linked VAT Reporting Code" := VATReportingCode.Code;
        VATCode."Gen. Posting Type" := VATReportingCode."Gen. Posting Type";
        VATCode."Test Gen. Posting Type" := VATReportingCode."Test Gen. Posting Type";
        VATCode.Description := CopyStr(VATReportingCode.Description, 1, MaxStrLen(VATCode.Description));
        VATCode."Trade Settlement 2017 Box No." := VATReportingCode."Trade Settlement 2017 Box No.";
        VATCode."Reverse Charge Report Box No." := VATReportingCode."Reverse Charge Report Box No.";
        VATCode."VAT Specification Code" := VATReportingCode."VAT Specification Code";
        VATCode."VAT Note Code" := VATReportingCode."VAT Note Code";
    end;

    procedure GetShortVATCode(VATReportingCode: Code[20]) VATCodeCode: Code[10]
    var
        VATCode: Record "VAT Code";
        VATCodeStart: Text;
        VATCodeEnd: Text;
    begin
        VATCodeEnd := '~001';
        VATCodeStart := CopyStr(VATReportingCode, 1, MaxStrLen(VATCodeCode) - StrLen(VATCodeEnd));
        VATCodeCode := VATCodeStart + VATCodeEnd;
        VATCode.SetLoadFields();
        while VATCode.Get(VATCodeCode) do
            VATCodeCode := IncStr(VATCodeCode);
    end;

    local procedure GetVATCodeLinkedToVATReportingCode(var VATCode: Record "VAT Code"; VATReportingCodeCode: Text)
    begin
        Clear(VATCode);

        if StrLen(VATReportingCodeCode) <= MaxStrLen(VATCode.Code) then
            if VATCode.Get(VATReportingCodeCode) then
                exit;

        if VATReportingCodeCode = '' then
            exit;

        VATCode.SetRange("Linked VAT Reporting Code", VATReportingCodeCode);
        if VATCode.FindFirst() then
            exit;
    end;

    local procedure GetVATReportingCodeLinkedToVATCode(var VATReportingCode: Record "VAT Reporting Code"; VATCodeCode: Text)
    var
        VATCode: Record "VAT Code";
    begin
        Clear(VATReportingCode);

        if VATReportingCode.Get(VATCodeCode) then
            exit;

        if VATCodeCode = '' then
            exit;

        if VATCode.Get(VATCodeCode) then
            if VATReportingCode.Get(VATCode."Linked VAT Reporting Code") then
                exit;
    end;
}
#endif