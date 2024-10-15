codeunit 10769 "Service Cr. Memo Header - Edit"
{
    Permissions = TableData "Service Cr.Memo Header" = rm;
    TableNo = "Service Cr.Memo Header";

    trigger OnRun()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader := Rec;
        ServiceCrMemoHeader.LockTable();
        ServiceCrMemoHeader.Find();
        ServiceCrMemoHeader."Operation Description" := "Operation Description";
        ServiceCrMemoHeader."Operation Description 2" := "Operation Description 2";
        ServiceCrMemoHeader."Special Scheme Code" := "Special Scheme Code";
        ServiceCrMemoHeader."Cr. Memo Type" := "Cr. Memo Type";
        OnRunOnBeforeServiceCrMemoHeaderModify(ServiceCrMemoHeader, Rec);
        ServiceCrMemoHeader.TestField("No.", "No.");
        ServiceCrMemoHeader.Modify();
        Rec := ServiceCrMemoHeader;
        UpdateSIIDocUploadState(Rec);
    end;

    local procedure UpdateSIIDocUploadState(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
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
             ServiceCrMemoHeader."Posting Date",
             ServiceCrMemoHeader."No.")
        then
            exit;

        xSIIDocUploadState := SIIDocUploadState;
        SIIDocUploadState."Sales Cr. Memo Type" := ServiceCrMemoHeader."Cr. Memo Type" + 1;
        SIIDocUploadState."Sales Special Scheme Code" := ServiceCrMemoHeader."Special Scheme Code" + 1;
        SIISchemeCodeMgt.ValidateServiceSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState, SIIDocUploadState);
        SIIDocUploadState."Is Credit Memo Removal" := SIIDocUploadState.IsCreditMemoRemoval();
        SIIDocUploadState.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeServiceCrMemoHeaderModify(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; FromServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;
}

