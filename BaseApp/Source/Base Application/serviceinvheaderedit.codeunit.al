codeunit 1412 "Service Inv. Header - Edit"
{
    Permissions = TableData "Service Invoice Header" = rm;
    TableNo = "Service Invoice Header";

    trigger OnRun()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader := Rec;
        ServiceInvoiceHeader.LockTable();
        ServiceInvoiceHeader.Find();
        ServiceInvoiceHeader."Payment Method Code" := "Payment Method Code";
        ServiceInvoiceHeader."Payment Reference" := "Payment Reference";
        ServiceInvoiceHeader.TestField("No.", "No.");
        ServiceInvoiceHeader.Modify();
        Rec := ServiceInvoiceHeader;
    end;
}

