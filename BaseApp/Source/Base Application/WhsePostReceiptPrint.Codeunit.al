codeunit 5762 "Whse.-Post Receipt + Print"
{
    TableNo = "Warehouse Receipt Line";

    trigger OnRun()
    begin
        WhseReceiptLine.Copy(Rec);
        Code;
        Rec := WhseReceiptLine;
    end;

    var
        Text001: Label 'Number of put-away activities printed: %1.';
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        PrintedDocuments: Integer;

    local procedure "Code"()
    var
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(WhseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        WhsePostReceipt.Run(WhseReceiptLine);
        WhsePostReceipt.GetResultMessage();

        PrintedDocuments := 0;
        if WhsePostReceipt.GetFirstPutAwayDocument(WhseActivHeader) then begin
            repeat
                WhseActivHeader.SetRecFilter();
                OnBeforePrintReport(WhseActivHeader);
                REPORT.Run(REPORT::"Put-away List", false, false, WhseActivHeader);
                OnAfterPrintReport(WhseActivHeader);
                PrintedDocuments := PrintedDocuments + 1;
            until not WhsePostReceipt.GetNextPutAwayDocument(WhseActivHeader);
            Message(Text001, PrintedDocuments);
        end;
        Clear(WhsePostReceipt);

        OnAfterCode(WhseReceiptLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintReport(var WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WhseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintReport(var WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;
}