codeunit 10765 "Sales Invoice Header - Edit"
{
    Permissions = TableData "Sales Invoice Header" = rm;
    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader := Rec;
        SalesInvoiceHeader.LockTable;
        SalesInvoiceHeader.Find;
        SalesInvoiceHeader."Special Scheme Code" := "Special Scheme Code";
        SalesInvoiceHeader."Invoice Type" := "Invoice Type";
        SalesInvoiceHeader."ID Type" := "ID Type";
        SalesInvoiceHeader."Succeeded Company Name" := "Succeeded Company Name";
        SalesInvoiceHeader."Succeeded VAT Registration No." := "Succeeded VAT Registration No.";
        SalesInvoiceHeader.TestField("No.", "No.");
        SalesInvoiceHeader.Modify;
        Rec := SalesInvoiceHeader;
    end;
}

