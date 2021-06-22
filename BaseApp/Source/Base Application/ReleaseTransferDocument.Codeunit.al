codeunit 5708 "Release Transfer Document"
{
    TableNo = "Transfer Header";
    Permissions = TableData "Transfer Header" = rm;

    trigger OnRun()
    var
        TransLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        if Rec.Status = Rec.Status::Released then
            exit;

        OnBeforeReleaseTransferDoc(Rec);

        Rec.TestField("Transfer-from Code");
        Rec.TestField("Transfer-to Code");

        IsHandled := false;
        OnBeforeCheckTransferCode(Rec, IsHandled);
        if not IsHandled then
            if Rec."Transfer-from Code" = Rec."Transfer-to Code" then
                Error(Text001, Rec."No.", Rec.FieldCaption("Transfer-from Code"), Rec.FieldCaption("Transfer-to Code"));

        InvtSetup.Get();
        if not Rec."Direct Transfer" then
            Rec.TestField("In-Transit Code")
        else
            if InvtSetup."Direct Transfer Posting" = InvtSetup."Direct Transfer Posting"::"Receipt and Shipment" then begin
                Rec.VerifyNoOutboundWhseHandlingOnLocation(Rec."Transfer-from Code");
                Rec.VerifyNoInboundWhseHandlingOnLocation(Rec."Transfer-to Code");
            end;

        Rec.TestField(Status, Rec.Status::Open);

        CheckTransLines(TransLine, Rec);

        OnRunOnBeforeSetStatusReleased(Rec);
        Rec.Validate(Status, Rec.Status::Released);
        Rec.Modify();

        if not (
            Rec."Direct Transfer" and
            (InvtSetup."Direct Transfer Posting" = InvtSetup."Direct Transfer Posting"::"Direct Transfer"))
        then
            WhseTransferRelease.SetCallFromTransferOrder(true);

        WhseTransferRelease.Release(Rec);

        OnAfterReleaseTransferDoc(Rec);
    end;

    var
        InvtSetup: Record "Inventory Setup";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
        Text001: Label 'The transfer order %1 cannot be released because %2 and %3 are the same.';
        NothingToReleaseErr: Label 'There is nothing to release for transfer order %1.';

    procedure Reopen(var TransHeader: Record "Transfer Header")
    begin
        if TransHeader.Status = TransHeader.Status::Open then
            exit;

        OnBeforeReopenTransferDoc(TransHeader);
        WhseTransferRelease.Reopen(TransHeader);
        TransHeader.Validate(Status, TransHeader.Status::Open);
        TransHeader.Modify();

        OnAfterReopenTransferDoc(TransHeader);
    end;

    local procedure CheckTransLines(var TransLine: Record "Transfer Line"; TransHeader: Record "Transfer Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTransLines(TransLine, IsHandled, TransHeader);
        if IsHandled then
            exit;

        TransLine.SetRange("Document No.", TransHeader."No.");
        TransLine.SetFilter(Quantity, '<>0');
        if TransLine.IsEmpty() then
            Error(NothingToReleaseErr, TransHeader."No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransLines(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean; TransHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseTransferDoc(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenTransferDoc(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseTransferDoc(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenTransferDoc(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransferCode(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeSetStatusReleased(var TransferHeader: Record "Transfer Header")
    begin
    end;
}

