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
        OnRunOnBeforeAssignNewValues(ServiceInvoiceHeader, Rec);
        ServiceInvoiceHeader."Payment Method Code" := "Payment Method Code";
        ServiceInvoiceHeader."Payment Reference" := "Payment Reference";
        ServiceInvoiceHeader."Company Bank Account Code" := "Company Bank Account Code";
        OnOnRunOnBeforeTestFieldNo(ServiceInvoiceHeader, Rec);
        ServiceInvoiceHeader.TestField("No.", "No.");
        ServiceInvoiceHeader.Modify();
        Rec := ServiceInvoiceHeader;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeAssignNewValues(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceInvoiceHeaderRec: Record "Service Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnRunOnBeforeTestFieldNo(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceInvoiceHeaderRec: Record "Service Invoice Header")
    begin
    end;
}

