codeunit 1408 "Sales Credit Memo Hdr. - Edit"
{
    Permissions = TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Sales Cr.Memo Header";

    trigger OnRun()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader := Rec;
        SalesCrMemoHeader.LockTable();
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader."Shipping Agent Code" := "Shipping Agent Code";
        SalesCrMemoHeader."Shipping Agent Service Code" := "Shipping Agent Service Code";
        SalesCrMemoHeader."Package Tracking No." := "Package Tracking No.";
        SalesCrMemoHeader."Operation Description" := "Operation Description";
        SalesCrMemoHeader."Operation Description 2" := "Operation Description 2";
        SalesCrMemoHeader."Special Scheme Code" := "Special Scheme Code";
        SalesCrMemoHeader."Cr. Memo Type" := "Cr. Memo Type";
        SalesCrMemoHeader."Correction Type" := "Correction Type";
        SalesCrMemoHeader."Corrected Invoice No." := "Corrected Invoice No.";
        SalesCrMemoHeader."Issued By Third Party" := "Issued By Third Party";
        SalesCrMemoHeader.SetSIIFirstSummaryDocNo(GetSIIFirstSummaryDocNo());
        SalesCrMemoHeader.SetSIILastSummaryDocNo(GetSIILastSummaryDocNo());
        OnBeforeSalesCrMemoHeaderModify(SalesCrMemoHeader, Rec);        
        SalesCrMemoHeader.TestField("No.", "No.");
        SalesCrMemoHeader.Modify();
        Rec := SalesCrMemoHeader;
        UpdateSIIDocUploadState(Rec);
    end;

    local procedure UpdateSIIDocUploadState(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        xSIIDocUploadState: Record "SII Doc. Upload State";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIManagement: Codeunit "SII Management";
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        if not SIIManagement.IsSIISetupEnabled() then
            exit;

        if not SIIDocUploadState.GetSIIDocUploadStateByDocument(
             SIIDocUploadState."Document Source"::"Customer Ledger".AsInteger(),
             SIIDocUploadState."Document Type"::"Credit Memo".AsInteger(),
             SalesCrMemoHeader."Posting Date",
             SalesCrMemoHeader."No.")
        then
            exit;

        xSIIDocUploadState := SIIDocUploadState;
        SIIDocUploadState."Sales Cr. Memo Type" := SalesCrMemoHeader."Cr. Memo Type" + 1;
        SIIDocUploadState."Sales Special Scheme Code" := SalesCrMemoHeader."Special Scheme Code" + 1;
        SIISchemeCodeMgt.ValidateSalesSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState, SIIDocUploadState);
        SIIDocUploadState.IDType := SalesCrMemoHeader."ID Type";
        SIIDocUploadState."Succeeded Company Name" := SalesCrMemoHeader."Succeeded Company Name";
        SIIDocUploadState."Succeeded VAT Registration No." := SalesCrMemoHeader."Succeeded VAT Registration No.";
        SIIDocUploadState."Issued By Third Party" := SIIDocUploadState."Issued By Third Party";
        SIIDocUploadState."First Summary Doc. No." := CopyStr(SalesCrMemoHeader.GetSIIFirstSummaryDocNo(), 1, 35);
        SIIDocUploadState."Last Summary Doc. No." := CopyStr(SalesCrMemoHeader.GetSIILastSummaryDocNo(), 1, 35);
        SIIDocUploadState.Modify();
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeSalesCrMemoHeaderModify(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;
}
