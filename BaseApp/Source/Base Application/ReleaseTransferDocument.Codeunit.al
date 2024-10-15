codeunit 5708 "Release Transfer Document"
{
    TableNo = "Transfer Header";

    trigger OnRun()
    var
        TransLine: Record "Transfer Line";
        GLSetup: Record "General Ledger Setup";
        UserSetupAdvMgt: Codeunit "User Setup Adv. Management";
        IsHandled: Boolean;
    begin
        if Status = Status::Released then
            exit;

        OnBeforeReleaseTransferDoc(Rec);
        TestField("Transfer-from Code");
        TestField("Transfer-to Code");
        IsHandled := false;
        OnBeforeCheckTransferCode(Rec, IsHandled);
        if not IsHandled then
            if "Transfer-from Code" = "Transfer-to Code" then
                Error(Text001, "No.", FieldCaption("Transfer-from Code"), FieldCaption("Transfer-to Code"));
        if not "Direct Transfer" then
            TestField("In-Transit Code")
        else begin
            VerifyNoOutboundWhseHandlingOnLocation("Transfer-from Code");
            VerifyNoInboundWhseHandlingOnLocation("Transfer-to Code");
        end;

        TestField(Status, Status::Open);

        CheckTransLines(TransLine, Rec);

        // NAVCZ
        GLSetup.Get();
        if GLSetup."User Checks Allowed" then
            repeat
                case true of
                    TransLine.Quantity > 0:
                        begin
                            UserSetupAdvMgt.SetItem(TransLine."Item No.");
                            if not UserSetupAdvMgt.CheckReleasLocQuantityDecrease(TransLine."Transfer-from Code") then
                                TransLine.FieldError("Transfer-from Code");
                            if not UserSetupAdvMgt.CheckReleasLocQuantityIncrease(TransLine."Transfer-to Code") then
                                TransLine.FieldError("Transfer-to Code");
                        end;
                    TransLine.Quantity < 0:
                        begin
                            UserSetupAdvMgt.SetItem(TransLine."Item No.");
                            if not UserSetupAdvMgt.CheckReleasLocQuantityIncrease(TransLine."Transfer-from Code") then
                                TransLine.FieldError("Transfer-from Code");
                            if not UserSetupAdvMgt.CheckReleasLocQuantityDecrease(TransLine."Transfer-to Code") then
                                TransLine.FieldError("Transfer-to Code");
                        end;
                end;
            until TransLine.Next = 0;
        // NAVCZ

        Validate(Status, Status::Released);
        Modify;

        WhseTransferRelease.SetCallFromTransferOrder(true);
        WhseTransferRelease.Release(Rec);

        OnAfterReleaseTransferDoc(Rec);
    end;

    var
        Text001: Label 'The transfer order %1 cannot be released because %2 and %3 are the same.';
        Text002: Label 'There is nothing to release for transfer order %1.';
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";

    procedure Reopen(var TransHeader: Record "Transfer Header")
    begin
        with TransHeader do begin
            if Status = Status::Open then
                exit;

            OnBeforeReopenTransferDoc(TransHeader);
            WhseTransferRelease.Reopen(TransHeader);
            Validate(Status, Status::Open);
            Modify;
        end;

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
        if TransLine.IsEmpty then
            Error(Text002, TransHeader."No.");
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
}

