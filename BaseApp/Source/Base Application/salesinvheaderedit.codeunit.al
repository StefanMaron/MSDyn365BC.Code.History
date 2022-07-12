codeunit 1409 "Sales Inv. Header - Edit"
{
    Permissions = TableData "Sales Invoice Header" = rm;
    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader := Rec;
        SalesInvoiceHeader.LockTable();
        SalesInvoiceHeader.Find();
        OnRunOnBeforeAssignValues(SalesInvoiceHeader, Rec);
        SalesInvoiceHeader."Payment Method Code" := "Payment Method Code";
        SalesInvoiceHeader."Payment Reference" := "Payment Reference";
        SalesInvoiceHeader."Company Bank Account Code" := "Company Bank Account Code";
        OnOnRunOnBeforeTestFieldNo(SalesInvoiceHeader, Rec);
        SalesInvoiceHeader.TestField("No.", "No.");
        SalesInvoiceHeader.Modify();
        Rec := SalesInvoiceHeader;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnRunOnBeforeTestFieldNo(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceHeaderRec: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeAssignValues(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceHeaderRec: Record "Sales Invoice Header")
    begin
    end;
}

