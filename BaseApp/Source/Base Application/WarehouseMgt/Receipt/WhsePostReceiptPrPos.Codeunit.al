codeunit 5766 "Whse.-Post Receipt + Pr. Pos."
{
    TableNo = "Warehouse Receipt Line";

    trigger OnRun()
    begin
        WhseReceiptLine.Copy(Rec);
        Code();
    end;

    var
        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        Text001: Label 'Number of posted whse. receipts printed: 1.';

    local procedure "Code"()
    var
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(WhseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        with WhseReceiptLine do begin
            WhsePostReceipt.Run(WhseReceiptLine);
            WhsePostReceipt.GetResultMessage();

            PostedWhseRcptHeader.SetRange("Whse. Receipt No.", "No.");
            PostedWhseRcptHeader.SetRange("Location Code", "Location Code");
            PostedWhseRcptHeader.FindLast();

            Commit();
            WarehouseDocumentPrint.PrintPostedRcptHeader(PostedWhseRcptHeader);
            Message(Text001);

            Clear(WhsePostReceipt);
        end;

        OnAfterCode(WhseReceiptLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;
}

