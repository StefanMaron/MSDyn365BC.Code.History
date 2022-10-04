codeunit 6661 "Return Receipt - Printed"
{
    Permissions = TableData "Return Receipt Header" = rimd;
    TableNo = "Return Receipt Header";

    trigger OnRun()
    begin
        Find();
        "No. Printed" := "No. Printed" + 1;
        OnBeforeModify(Rec);
        Modify();
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var ReturnReceiptHeader: Record "Return Receipt Header")
    begin
    end;
}

