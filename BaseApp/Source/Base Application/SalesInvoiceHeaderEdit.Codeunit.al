codeunit 10765 "Sales Invoice Header - Edit"
{
    Permissions = TableData "Sales Invoice Header" = rm;
    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader := Rec;
        SalesInvoiceHeader.LockTable();
        SalesInvoiceHeader.Find;
        SalesInvoiceHeader."Special Scheme Code" := "Special Scheme Code";
        SalesInvoiceHeader."Invoice Type" := "Invoice Type";
        SalesInvoiceHeader."ID Type" := "ID Type";
        SalesInvoiceHeader."Succeeded Company Name" := "Succeeded Company Name";
        SalesInvoiceHeader."Succeeded VAT Registration No." := "Succeeded VAT Registration No.";
        OnRunOnBeforeSalesInvoiceHeaderModify(SalesInvoiceHeader, Rec);
        SalesInvoiceHeader.TestField("No.", "No.");
        SalesInvoiceHeader.Modify();
        Rec := SalesInvoiceHeader;
        UpdateSIIDocUploadState(Rec);
    end;

    local procedure UpdateSIIDocUploadState(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIManagement: Codeunit "SII Management";
    begin
        if not SIIManagement.IsSIISetupEnabled then
            exit;

        if not SIIDocUploadState.GetSIIDocUploadStateByDocument(
             SIIDocUploadState."Document Source"::"Customer Ledger".AsInteger(),
             SIIDocUploadState."Document Type"::Invoice.AsInteger(),
             SalesInvoiceHeader."Posting Date",
             SalesInvoiceHeader."No.")
        then
            exit;

        SIIDocUploadState."Sales Invoice Type" := SalesInvoiceHeader."Invoice Type" + 1;
        SIIDocUploadState."Sales Special Scheme Code" := SalesInvoiceHeader."Special Scheme Code" + 1;
        SIIDocUploadState.IDType := SalesInvoiceHeader."ID Type";
        SIIDocUploadState."Succeeded Company Name" := SalesInvoiceHeader."Succeeded Company Name";
        SIIDocUploadState."Succeeded VAT Registration No." := SalesInvoiceHeader."Succeeded VAT Registration No.";
        SIIDocUploadState.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeSalesInvoiceHeaderModify(var SalesInvoiceHeader: Record "Sales Invoice Header"; FromSalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;
}

