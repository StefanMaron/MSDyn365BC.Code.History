#pragma warning disable AL0432,AA0072
codeunit 31233 "Sync.Dep.Fld-TransRcptHdr CZA"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Shipment Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertTransferShipmentHeader(var Rec: Record "Transfer Shipment Header")
    begin
        SyncDeprecatedFields(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Shipment Header", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyTransferShipmentHeader(var Rec: Record "Transfer Shipment Header")
    begin
        SyncDeprecatedFields(Rec);
    end;

    local procedure SyncDeprecatedFields(var Rec: Record "Transfer Shipment Header")
    var
        PreviousRecord: Record "Transfer Shipment Header";
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
