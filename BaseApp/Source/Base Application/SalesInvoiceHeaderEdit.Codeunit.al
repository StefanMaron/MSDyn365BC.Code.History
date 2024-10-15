codeunit 12186 "Sales Invoice Header - Edit"
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
        SalesInvoiceHeader."Fattura Document Type" := "Fattura Document Type";
        OnRunOnBeforeSalesInvoiceHeaderModify(SalesInvoiceHeader, Rec);
        SalesInvoiceHeader.TestField("No.", "No.");
        SalesInvoiceHeader.Modify();
        Rec := SalesInvoiceHeader;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeSalesInvoiceHeaderModify(var SalesInvoiceHeader: Record "Sales Invoice Header"; FromSalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;
}

