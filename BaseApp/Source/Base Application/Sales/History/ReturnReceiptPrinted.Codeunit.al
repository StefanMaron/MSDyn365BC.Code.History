namespace Microsoft.Sales.History;

codeunit 6661 "Return Receipt - Printed"
{
    Permissions = TableData "Return Receipt Header" = rimd;
    TableNo = "Return Receipt Header";

    trigger OnRun()
    begin
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        OnBeforeModify(Rec);
        Rec.Modify();
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var ReturnReceiptHeader: Record "Return Receipt Header")
    begin
    end;
}

