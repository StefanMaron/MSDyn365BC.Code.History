codeunit 10767 "Purch. Cr. Memo Hdr. - Edit"
{
    Permissions = TableData "Purch. Cr. Memo Hdr." = rm;
    TableNo = "Purch. Cr. Memo Hdr.";

    trigger OnRun()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr := Rec;
        PurchCrMemoHdr.LockTable();
        PurchCrMemoHdr.Find();
        PurchCrMemoHdr."Operation Description" := "Operation Description";
        PurchCrMemoHdr."Operation Description 2" := "Operation Description 2";
        PurchCrMemoHdr."Special Scheme Code" := "Special Scheme Code";
        PurchCrMemoHdr."Cr. Memo Type" := "Cr. Memo Type";
        PurchCrMemoHdr."Correction Type" := "Correction Type";
        PurchCrMemoHdr."Corrected Invoice No." := "Corrected Invoice No.";
        OnRunOnBeforeTestFieldNo(PurchCrMemoHdr, Rec);
        PurchCrMemoHdr.TestField("No.", "No.");
        PurchCrMemoHdr.Modify();
        Rec := PurchCrMemoHdr;
        UpdateSIIDocUploadState(Rec);
    end;

    local procedure UpdateSIIDocUploadState(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        xSIIDocUploadState: Record "SII Doc. Upload State";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIManagement: Codeunit "SII Management";
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        if not SIIManagement.IsSIISetupEnabled then
            exit;

        if not SIIDocUploadState.GetSIIDocUploadStateByDocument(
             SIIDocUploadState."Document Source"::"Vendor Ledger".AsInteger(),
             SIIDocUploadState."Document Type"::"Credit Memo".AsInteger(),
             PurchCrMemoHdr."Posting Date",
             PurchCrMemoHdr."No.")
        then
            exit;

        xSIIDocUploadState := SIIDocUploadState;
        SIIDocUploadState.AssignPurchCreditMemoType(PurchCrMemoHdr."Cr. Memo Type");
        SIIDocUploadState.AssignPurchSchemeCode(PurchCrMemoHdr."Special Scheme Code");
        SIISchemeCodeMgt.ValidatePurchSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState, SIIDocUploadState);
        SIIDocUploadState.IDType := PurchCrMemoHdr."ID Type";
        SIIDocUploadState."Succeeded Company Name" := PurchCrMemoHdr."Succeeded Company Name";
        SIIDocUploadState."Succeeded VAT Registration No." := PurchCrMemoHdr."Succeeded VAT Registration No.";
        SIIDocUploadState.GetCorrectionInfo(
          SIIDocUploadState."Corrected Doc. No.", SIIDocUploadState."Corr. Posting Date", SIIDocUploadState."Posting Date");
        SIIDocUploadState."Is Credit Memo Removal" := SIIDocUploadState.IsCreditMemoRemoval();
        SIIDocUploadState.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeTestFieldNo(var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchCrMemoHeaderRec: Record "Purch. Cr. Memo Hdr.")
    begin
    end;
}

