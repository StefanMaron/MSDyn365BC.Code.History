codeunit 1405 "Purch. Inv. Header - Edit"
{
    Permissions = TableData "Purch. Inv. Header" = rm;
    TableNo = "Purch. Inv. Header";

    trigger OnRun()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader := Rec;
        PurchInvHeader.LockTable();
        PurchInvHeader.Find();
        PurchInvHeader."Payment Reference" := "Payment Reference";
        PurchInvHeader."Payment Method Code" := "Payment Method Code";
        PurchInvHeader."Creditor No." := "Creditor No.";
        PurchInvHeader."Ship-to Code" := "Ship-to Code";
        PurchInvHeader."Operation Description" := "Operation Description";
        PurchInvHeader."Operation Description 2" := "Operation Description 2";
        PurchInvHeader."Special Scheme Code" := "Special Scheme Code";
        PurchInvHeader."Invoice Type" := "Invoice Type";
        PurchInvHeader."ID Type" := "ID Type";
        PurchInvHeader."Succeeded Company Name" := "Succeeded Company Name";
        PurchInvHeader."Succeeded VAT Registration No." := "Succeeded VAT Registration No.";
        OnBeforePurchInvHeaderModify(PurchInvHeader, Rec);
        PurchInvHeader.TestField("No.", "No.");
        PurchInvHeader.Modify();
        Rec := PurchInvHeader;
        UpdateSIIDocUploadState(Rec);
    end;
    
    local procedure UpdateSIIDocUploadState(PurchInvHeader: Record "Purch. Inv. Header")
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIManagement: Codeunit "SII Management";
    begin
        if not SIIManagement.IsSIISetupEnabled then
            exit;

        if not SIIDocUploadState.GetSIIDocUploadStateByDocument(
             SIIDocUploadState."Document Source"::"Vendor Ledger",
             SIIDocUploadState."Document Type"::Invoice,
             PurchInvHeader."Posting Date",
             PurchInvHeader."No.")
        then
            exit;

        SIIDocUploadState."Purch. Invoice Type" := PurchInvHeader."Invoice Type" + 1;
        SIIDocUploadState."Purch. Special Scheme Code" := PurchInvHeader."Special Scheme Code" + 1;
        SIIDocUploadState.IDType := PurchInvHeader."ID Type";
        SIIDocUploadState."Succeeded Company Name" := PurchInvHeader."Succeeded Company Name";
        SIIDocUploadState."Succeeded VAT Registration No." := PurchInvHeader."Succeeded VAT Registration No.";
        SIIDocUploadState.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvHeaderModify(var PurchInvHeader: Record "Purch. Inv. Header"; PurchInvHeaderRec: Record "Purch. Inv. Header")
    begin
    end;
}

