codeunit 10768 "Service Invoice Header - Edit"
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
        ServiceInvoiceHeader."Country/Region Code" := "Country/Region Code";
        ServiceInvoiceHeader."Bill-to Country/Region Code" := "Bill-to Country/Region Code";
        ServiceInvoiceHeader."Ship-to Country/Region Code" := "Ship-to Country/Region Code";

        ServiceInvoiceHeader."Operation Description" := "Operation Description";
        ServiceInvoiceHeader."Operation Description 2" := "Operation Description 2";
        ServiceInvoiceHeader."Special Scheme Code" := "Special Scheme Code";
        ServiceInvoiceHeader."Invoice Type" := "Invoice Type";
        ServiceInvoiceHeader."ID Type" := "ID Type";
        ServiceInvoiceHeader."Succeeded Company Name" := "Succeeded Company Name";
        ServiceInvoiceHeader."Succeeded VAT Registration No." := "Succeeded VAT Registration No.";
        OnRunOnBeforeServiceInvoiceHeaderModify(ServiceInvoiceHeader, Rec);
        ServiceInvoiceHeader.TestField("No.", "No.");
        ServiceInvoiceHeader.Modify();
        Rec := ServiceInvoiceHeader;
        UpdateSIIDocUploadState(Rec);
    end;

    local procedure UpdateSIIDocUploadState(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIManagement: Codeunit "SII Management";
    begin
        if not SIIManagement.IsSIISetupEnabled() then
            exit;

        if not SIIDocUploadState.GetSIIDocUploadStateByDocument(
             SIIDocUploadState."Document Source"::"Customer Ledger".AsInteger(),
             SIIDocUploadState."Document Type"::Invoice.AsInteger(),
             ServiceInvoiceHeader."Posting Date",
             ServiceInvoiceHeader."No.")
        then
            exit;

        SIIDocUploadState.AssignSalesInvoiceType(ServiceInvoiceHeader."Invoice Type");
        SIIDocUploadState.AssignSalesSchemeCode(ServiceInvoiceHeader."Special Scheme Code");
        SIIDocUploadState.IDType := ServiceInvoiceHeader."ID Type";
        SIIDocUploadState."Succeeded Company Name" := ServiceInvoiceHeader."Succeeded Company Name";
        SIIDocUploadState."Succeeded VAT Registration No." := ServiceInvoiceHeader."Succeeded VAT Registration No.";
        SIIDocUploadState.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeServiceInvoiceHeaderModify(var ServiceInvoiceHeader: Record "Service Invoice Header"; FromServiceInvoiceHeader: Record "Service Invoice Header")
    begin
    end;
}

