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
        SalesInvoiceHeader."Payment Method Code" := "Payment Method Code";
        SalesInvoiceHeader."Payment Reference" := "Payment Reference";
        SalesInvoiceHeader.TestField("No.", "No.");
        SalesInvoiceHeader.Modify();
        Rec := SalesInvoiceHeader;
    end;
}

