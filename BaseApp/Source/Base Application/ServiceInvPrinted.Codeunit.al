codeunit 5902 "Service Inv.-Printed"
{
    Permissions = TableData "Service Invoice Header" = rimd;
    TableNo = "Service Invoice Header";

    trigger OnRun()
    begin
        Find;
        "No. Printed" := "No. Printed" + 1;
        OnBeforeModify(Rec);
        Modify;
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
    end;
}

