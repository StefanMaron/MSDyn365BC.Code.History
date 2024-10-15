codeunit 5761 "Whse.-Post Receipt (Yes/No)"
{
    TableNo = "Warehouse Receipt Line";

    trigger OnRun()
    begin
        WhseReceiptLine.Copy(Rec);
        Code();
        Rec := WhseReceiptLine;
    end;

    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";

        Text000: Label 'Do you want to post the receipt?';

    local procedure "Code"()
    var
        HideDialog: Boolean;
        IsPosted: Boolean;
        IsHandled: Boolean;
    begin
        HideDialog := false;
        IsPosted := false;
        OnBeforeConfirmWhseReceiptPost(WhseReceiptLine, HideDialog, IsPosted);
        if IsPosted then
            exit;

        with WhseReceiptLine do begin
            if Find() then
                if not HideDialog then
                    if not Confirm(Text000, false) then
                        exit;

            IsHandled := false;
            OnAfterConfirmPost(WhseReceiptLine, IsHandled);
            if not IsHandled then begin
                WhsePostReceipt.Run(WhseReceiptLine);
                OnAfterWhsePostReceiptRun(WhseReceiptLine, WhsePostReceipt);
                WhsePostReceipt.GetResultMessage();
                Clear(WhsePostReceipt);
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(WhseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhsePostReceiptRun(var WhseReceiptLine: Record "Warehouse Receipt Line"; WhsePostReceipt: Codeunit "Whse.-Post Receipt")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmWhseReceiptPost(var WhseReceiptLine: Record "Warehouse Receipt Line"; var HideDialog: Boolean; var IsPosted: Boolean)
    begin
    end;
}

