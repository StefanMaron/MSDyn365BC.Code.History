codeunit 1407 "Return Receipt Header - Edit"
{
    Permissions = TableData "Return Receipt Header" = rm;
    TableNo = "Return Receipt Header";

    trigger OnRun()
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        ReturnReceiptHeader := Rec;
        ReturnReceiptHeader.LockTable();
        ReturnReceiptHeader.Find();
        ReturnReceiptHeader."Bill-to Country/Region Code" := "Bill-to Country/Region Code";
        ReturnReceiptHeader."Shipping Agent Code" := "Shipping Agent Code";
        ReturnReceiptHeader."Package Tracking No." := "Package Tracking No.";
        OnBeforeReturnReceiptHeaderModify(ReturnReceiptHeader, Rec);
        ReturnReceiptHeader.TestField("No.", "No.");
        ReturnReceiptHeader.Modify();
        Rec := ReturnReceiptHeader;

        OnRunOnAfterReturnReceiptHeaderEdit(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnReceiptHeaderModify(var ReturnReceiptHeader: Record "Return Receipt Header"; ReturnReceiptHeaderRec: Record "Return Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterReturnReceiptHeaderEdit(var ReturnReceiptHeader: Record "Return Receipt Header")
    begin
    end;
}

