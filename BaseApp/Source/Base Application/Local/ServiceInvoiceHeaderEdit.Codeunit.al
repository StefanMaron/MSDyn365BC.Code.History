codeunit 12187 "Service Invoice Header - Edit"
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
        ServiceInvoiceHeader."Fattura Document Type" := "Fattura Document Type";
        OnRunOnBeforeServiceInvoiceHeaderModify(ServiceInvoiceHeader, Rec);
        ServiceInvoiceHeader.TestField("No.", "No.");
        ServiceInvoiceHeader.Modify();
        Rec := ServiceInvoiceHeader;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeServiceInvoiceHeaderModify(var ServiceInvoiceHeader: Record "Service Invoice Header"; FromServiceInvoiceHeader: Record "Service Invoice Header")
    begin
    end;
}

