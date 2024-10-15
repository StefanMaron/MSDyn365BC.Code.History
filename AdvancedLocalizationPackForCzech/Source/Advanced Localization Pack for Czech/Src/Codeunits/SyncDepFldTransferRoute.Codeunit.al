#if not CLEAN18
#pragma warning disable AL0432, AA0072
codeunit 31230 "Sync.Dep.Fld-TransferRoute CZA"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Route", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertTransferRoute(var Rec: Record "Transfer Route")
    begin
        SyncDeprecatedFields(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Route", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyTransferRoute(var Rec: Record "Transfer Route")
    begin
        SyncDeprecatedFields(Rec);
    end;

    local procedure SyncDeprecatedFields(var Rec: Record "Transfer Route")
    var
        PreviousRecord: Record "Transfer Route";
        SyncDepFldUtilities: Codeunit "Sync.Dep.Fld-Utilities";
        PreviousRecordRef: RecordRef;
        DepFieldTxt, NewFieldTxt : Text;
    begin
        if SyncDepFldUtilities.GetPreviousRecord(Rec, PreviousRecordRef) then
            PreviousRecordRef.SetTable(PreviousRecord);

        DepFieldTxt := Rec."Gen. Bus. Post. Group Ship";
        NewFieldTxt := Rec."Gen.Bus.Post.Group Ship CZA";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Gen. Bus. Post. Group Ship", PreviousRecord."Gen.Bus.Post.Group Ship CZA");
        Rec."Gen. Bus. Post. Group Ship" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Gen. Bus. Post. Group Ship"));
        Rec."Gen.Bus.Post.Group Ship CZA" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Gen.Bus.Post.Group Ship CZA"));

        DepFieldTxt := Rec."Gen. Bus. Post. Group Receive";
        NewFieldTxt := Rec."Gen.Bus.Post.Group Receive CZA";
        SyncDepFldUtilities.SyncFields(DepFieldTxt, NewFieldTxt, PreviousRecord."Gen. Bus. Post. Group Receive", PreviousRecord."Gen.Bus.Post.Group Receive CZA");
        Rec."Gen. Bus. Post. Group Receive" := CopyStr(DepFieldTxt, 1, MaxStrLen(Rec."Gen. Bus. Post. Group Receive"));
        Rec."Gen.Bus.Post.Group Receive CZA" := CopyStr(NewFieldTxt, 1, MaxStrLen(Rec."Gen.Bus.Post.Group Receive CZA"));
    end;
}
#endif