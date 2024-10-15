#pragma warning disable AL0432
codeunit 31169 "Sync.Dep.Fld-JobJnlLine CZL"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed after removing feature from Base Application.';
    ObsoleteTag = '18.0';

    [EventSubscriber(ObjectType::Table, Database::"Job Journal Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertJobJnlLine(var Rec: Record "Job Journal Line")
    begin
        SyncDeprecatedFields(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Journal Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyJobJnlLine(var Rec: Record "Job Journal Line")
    begin
        SyncDeprecatedFields(Rec);
    end;

    local procedure SyncDeprecatedFields(var Rec: Record "Job Journal Line")
    var
        PreviousRecord: Record "Job Journal Line";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
        PreviousRecordRef: RecordRef;
        DepFieldTxt, NewFieldTxt : Text;
    begin
        if SyncDepFldUtilities.GetPreviousRecord(Rec, PreviousRecordRef) then
            PreviousRecordRef.SetTable(PreviousRecord);

        DepFieldTxt := Rec."Tariff No.";
        NewFieldTxt := Rec."Tariff No. CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Tariff No.", PreviousRecord."Tariff No. CZL");
        Rec."Tariff No." := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Tariff No."));
        Rec."Tariff No. CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Tariff No. CZL"));
        SyncDepFldUtilities.SyncFields(Rec."Net Weight", Rec."Net Weight CZL", PreviousRecord."Net Weight", PreviousRecord."Net Weight CZL");
        DepFieldTxt := Rec."Country/Region of Origin Code";
        NewFieldTxt := Rec."Country/Reg. of Orig. Code CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Country/Region of Origin Code", PreviousRecord."Country/Reg. of Orig. Code CZL");
        Rec."Country/Region of Origin Code" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Country/Region of Origin Code"));
        Rec."Country/Reg. of Orig. Code CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Country/Reg. of Orig. Code CZL"));
        DepFieldTxt := Rec."Statistic Indication";
        NewFieldTxt := Rec."Statistic Indication CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Statistic Indication", PreviousRecord."Statistic Indication CZL");
        Rec."Statistic Indication" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Statistic Indication"));
        Rec."Statistic Indication CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Statistic Indication CZL"));
        SyncDepFldUtilities.SyncFields(Rec."Intrastat Transaction", Rec."Intrastat Transaction CZL", PreviousRecord."Intrastat Transaction", PreviousRecord."Intrastat Transaction CZL");
        DepFieldTxt := Rec."Whse. Net Change Template";
        NewFieldTxt := Rec."Invt. Movement Template CZL";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Whse. Net Change Template", PreviousRecord."Invt. Movement Template CZL");
        Rec."Whse. Net Change Template" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Whse. Net Change Template"));
        Rec."Invt. Movement Template CZL" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Invt. Movement Template CZL"));
    end;
}
