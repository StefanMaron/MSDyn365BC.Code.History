#pragma warning disable AL0432,AA0072
codeunit 31295 "Sync.Dep.Fld-PostGenJnlLn CZC"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Posted Gen. Journal Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertGenJnlLine(var Rec: Record "Posted Gen. Journal Line")
    begin
        SyncDeprecatedFields(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Posted Gen. Journal Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyGenJnlLine(var Rec: Record "Posted Gen. Journal Line")
    begin
        SyncDeprecatedFields(Rec);
    end;

    local procedure SyncDeprecatedFields(var Rec: Record "Posted Gen. Journal Line")
    var
        PreviousRecord: Record "Posted Gen. Journal Line";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
        PreviousRecordRef: RecordRef;
    begin
        if SyncDepFldUtilities.GetPreviousRecord(Rec, PreviousRecordRef) then
            PreviousRecordRef.SetTable(PreviousRecord);

        SyncDepFldUtilities.SyncFields(Rec.Compensation, Rec."Compensation CZC", PreviousRecord.Compensation, PreviousRecord."Compensation CZC");
    end;
}
