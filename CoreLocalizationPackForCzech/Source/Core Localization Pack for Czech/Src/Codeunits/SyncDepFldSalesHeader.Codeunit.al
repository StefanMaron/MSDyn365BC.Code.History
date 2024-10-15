#pragma warning disable AL0432
codeunit 31158 "Sync.Dep.Fld-SalesHeader CZL"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed after removing feature from Base Application.';
    ObsoleteTag = '18.0';

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertSalesHeader(var Rec: Record "Sales Header")
    begin
        SyncDeprecatedFields(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifySalesHeader(var Rec: Record "Sales Header")
    begin
        SyncDeprecatedFields(Rec);
    end;

    local procedure SyncDeprecatedFields(var Rec: Record "Sales Header")
    var
        PreviousRecord: Record "Sales Header";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
        PreviousRecordRef: RecordRef;
        DepFieldTxt, NewFieldTxt : Text;
        DepFieldInt, NewFieldInt : Integer;
    begin
        if SyncDepFldUtilities.GetPreviousRecord(Rec, PreviousRecordRef) then
            PreviousRecordRef.SetTable(PreviousRecord);

        DepFieldTxt := Rec."Specific Symbol";
        NewFieldTxt := Rec."Specific Symbol CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Specific Symbol", PreviousRecord."Specific Symbol CZL");
        Rec."Specific Symbol" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Specific Symbol"));
        Rec."Specific Symbol CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Specific Symbol CZL"));
        DepFieldTxt := Rec."Variable Symbol";
        NewFieldTxt := Rec."Variable Symbol CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Variable Symbol", PreviousRecord."Variable Symbol CZL");
        Rec."Variable Symbol" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Variable Symbol"));
        Rec."Variable Symbol CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Variable Symbol CZL"));
        DepFieldTxt := Rec."Constant Symbol";
        NewFieldTxt := Rec."Constant Symbol CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Constant Symbol", PreviousRecord."Constant Symbol CZL");
        Rec."Constant Symbol" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Constant Symbol"));
        Rec."Constant Symbol CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Constant Symbol CZL"));
        DepFieldTxt := Rec."Bank Account Code";
        NewFieldTxt := Rec."Bank Account Code CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Bank Account Code", PreviousRecord."Bank Account Code CZL");
        Rec."Bank Account Code" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Bank Account Code"));
        Rec."Bank Account Code CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Bank Account Code CZL"));
        DepFieldTxt := Rec."Bank Account No.";
        NewFieldTxt := Rec."Bank Account No. CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Bank Account No.", PreviousRecord."Bank Account No. CZL");
        Rec."Bank Account No." := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Bank Account No."));
        Rec."Bank Account No. CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Bank Account No. CZL"));
        DepFieldTxt := Rec."Bank Branch No.";
        NewFieldTxt := Rec."Bank Branch No. CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Bank Branch No.", PreviousRecord."Bank Branch No. CZL");
        Rec."Bank Branch No." := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Bank Branch No."));
        Rec."Bank Branch No. CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Bank Branch No. CZL"));
        DepFieldTxt := Rec."Bank Name";
        NewFieldTxt := Rec."Bank Name CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Bank Name", PreviousRecord."Bank Name CZL");
        Rec."Bank Name" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Bank Name"));
        Rec."Bank Name CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Bank Name CZL"));
        DepFieldTxt := Rec."Transit No.";
        NewFieldTxt := Rec."Transit No. CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Transit No.", PreviousRecord."Transit No. CZL");
        Rec."Transit No." := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Transit No."));
        Rec."Transit No. CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Transit No. CZL"));
        DepFieldTxt := Rec.IBAN;
        NewFieldTxt := Rec."IBAN CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord.IBAN, PreviousRecord."IBAN CZL");
        Rec.IBAN := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec.IBAN));
        Rec."IBAN CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."IBAN CZL"));
        DepFieldTxt := Rec."SWIFT Code";
        NewFieldTxt := Rec."SWIFT Code CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."SWIFT Code", PreviousRecord."SWIFT Code CZL");
        Rec."SWIFT Code" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."SWIFT Code"));
        Rec."SWIFT Code CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."SWIFT Code CZL"));
        SyncDepFldUtilities.SyncFields(Rec."VAT Date", Rec."VAT Date CZL", PreviousRecord."VAT Date", PreviousRecord."VAT Date CZL");
        DepFieldTxt := Rec."Registration No.";
        NewFieldTxt := Rec."Registration No. CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Registration No.", PreviousRecord."Registration No. CZL");
        Rec."Registration No." := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Registration No."));
        Rec."Registration No. CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Registration No. CZL"));
        DepFieldTxt := Rec."Tax Registration No.";
        NewFieldTxt := Rec."Tax Registration No. CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Tax Registration No.", PreviousRecord."Tax Registration No. CZL");
        Rec."Tax Registration No." := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Tax Registration No."));
        Rec."Tax Registration No. CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Tax Registration No. CZL"));
        DepFieldInt := Rec."Credit Memo Type";
        NewFieldInt := Rec."Credit Memo Type CZL".AsInteger();
        SyncDepFldUtilities.SyncFields(DepFieldInt, NewFieldInt, PreviousRecord."Credit Memo Type", PreviousRecord."Credit Memo Type CZL".AsInteger());
        Rec."Credit Memo Type" := DepFieldInt;
        Rec."Credit Memo Type CZL" := "Credit Memo Type CZL".FromInteger(NewFieldInt);
        SyncDepFldUtilities.SyncFields(Rec."Physical Transfer", Rec."Physical Transfer CZL", PreviousRecord."Physical Transfer", PreviousRecord."Physical Transfer CZL");
        SyncDepFldUtilities.SyncFields(Rec."Intrastat Exclude", Rec."Intrastat Exclude CZL", PreviousRecord."Intrastat Exclude", PreviousRecord."Intrastat Exclude CZL");
        SyncDepFldUtilities.SyncFields(Rec."EU 3-Party Intermediate Role", Rec."EU 3-Party Intermed. Role CZL", PreviousRecord."EU 3-Party Intermediate Role", PreviousRecord."EU 3-Party Intermed. Role CZL");
        SyncDepFldUtilities.SyncFields(Rec."Original Document VAT Date", Rec."Original Doc. VAT Date CZL", PreviousRecord."Original Document VAT Date", PreviousRecord."Original Doc. VAT Date CZL");
        SyncDepFldUtilities.SyncFields(Rec."VAT Currency Factor", Rec."VAT Currency Factor CZL", PreviousRecord."VAT Currency Factor", PreviousRecord."VAT Currency Factor CZL");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Bank Account Code', false, false)]
    local procedure SyncOnAfterValidateBankAccountCode(var Rec: Record "Sales Header")
    var
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Sales Header", Rec.FieldNo("Bank Account Code")) then
            exit;

        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Sales Header", Rec.FieldNo("Bank Account Code CZL"));
        Rec.Validate("Bank Account Code CZL", Rec."Bank Account Code");
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Sales Header", Rec.FieldNo("Bank Account Code CZL"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Bank Account Code CZL', false, false)]
    local procedure SyncOnAfterValidateBankAccountCodeCZL(var Rec: Record "Sales Header")
    var
        SyncLoopingHelper: Codeunit "Sync. Looping Helper";
    begin
        if SyncLoopingHelper.IsFieldSynchronizationSkipped(Database::"Sales Header", Rec.FieldNo("Bank Account Code CZL")) then
            exit;

        SyncLoopingHelper.SkipFieldSynchronization(SyncLoopingHelper, Database::"Sales Header", Rec.FieldNo("Bank Account Code"));
        Rec.Validate("Bank Account Code", Rec."Bank Account Code CZL");
        SyncLoopingHelper.RestoreFieldSynchronization(Database::"Sales Header", Rec.FieldNo("Bank Account Code"));
    end;
}
