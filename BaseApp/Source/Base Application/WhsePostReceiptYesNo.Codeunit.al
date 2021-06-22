codeunit 5761 "Whse.-Post Receipt (Yes/No)"
{
    TableNo = "Warehouse Receipt Line";

    trigger OnRun()
    begin
        WhseReceiptLine.Copy(Rec);
        Code;
        Rec := WhseReceiptLine;
    end;

    var
        Text000: Label 'Do you want to post the receipt?';
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";

    local procedure "Code"()
    var
        HideDialog: Boolean;
        IsPosted: Boolean;
    begin
        HideDialog := false;
        IsPosted := false;
        OnBeforeConfirmWhseReceiptPost(WhseReceiptLine, HideDialog, IsPosted);
        if IsPosted then
            exit;

        with WhseReceiptLine do begin
            if Find then
                if not HideDialog then
                    if not Confirm(Text000, false) then
                        exit;

            OnAfterConfirmPost(WhseReceiptLine);

            WhsePostReceipt.Run(WhseReceiptLine);
            WhsePostReceipt.GetResultMessage;
            Clear(WhsePostReceipt);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmWhseReceiptPost(var WhseReceiptLine: Record "Warehouse Receipt Line"; var HideDialog: Boolean; var IsPosted: Boolean)
    begin
    end;
}

