namespace Microsoft.Purchases.History;

using Microsoft.Purchases.Payables;
using Microsoft.EServices.EDocument;

codeunit 1405 "Purch. Inv. Header - Edit"
{
    Permissions = TableData "Purch. Inv. Header" = rm;
    TableNo = "Purch. Inv. Header";

    trigger OnRun()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Copy(Rec);
        PurchInvHeader.ReadIsolation(IsolationLevel::UpdLock);
        PurchInvHeader.Find();
        PurchInvHeader."Payment Reference" := Rec."Payment Reference";
        PurchInvHeader."Payment Method Code" := Rec."Payment Method Code";
        PurchInvHeader."Creditor No." := Rec."Creditor No.";
        PurchInvHeader."Ship-to Code" := Rec."Ship-to Code";
        PurchInvHeader."Operation Description" := Rec."Operation Description";
        PurchInvHeader."Operation Description 2" := Rec."Operation Description 2";
        PurchInvHeader."Special Scheme Code" := Rec."Special Scheme Code";
        PurchInvHeader."Invoice Type" := Rec."Invoice Type";
        PurchInvHeader."ID Type" := Rec."ID Type";
        PurchInvHeader."Succeeded Company Name" := Rec."Succeeded Company Name";
        PurchInvHeader."Succeeded VAT Registration No." := Rec."Succeeded VAT Registration No.";
        PurchInvHeader."Posting Description" := Rec."Posting Description";
        OnBeforePurchInvHeaderModify(PurchInvHeader, Rec);
        PurchInvHeader.TestField("No.", Rec."No.");
        PurchInvHeader.Modify();
        Rec.Copy(PurchInvHeader);
        UpdateSIIDocUploadState(Rec);
        UpdateVendorLedgerEntry(Rec);

        OnRunOnAfterPurchInvHeaderEdit(Rec);
    end;

    local procedure UpdateSIIDocUploadState(PurchInvHeader: Record "Purch. Inv. Header")
    var
        xSIIDocUploadState: Record "SII Doc. Upload State";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIManagement: Codeunit "SII Management";
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        if not SIIManagement.IsSIISetupEnabled() then
            exit;

        if not SIIDocUploadState.GetSIIDocUploadStateByDocument(
             SIIDocUploadState."Document Source"::"Vendor Ledger".AsInteger(),
             SIIDocUploadState."Document Type"::Invoice.AsInteger(),
             PurchInvHeader."Posting Date",
             PurchInvHeader."No.")
        then
            exit;

        xSIIDocUploadState := SIIDocUploadState;
        SIIDocUploadState.AssignPurchInvoiceType(PurchInvHeader."Invoice Type");
        SIIDocUploadState.AssignPurchSchemeCode(PurchInvHeader."Special Scheme Code");
        SIISchemeCodeMgt.ValidatePurchSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState, SIIDocUploadState);
        SIIDocUploadState.IDType := PurchInvHeader."ID Type";
        SIIDocUploadState."Succeeded Company Name" := PurchInvHeader."Succeeded Company Name";
        SIIDocUploadState."Succeeded VAT Registration No." := PurchInvHeader."Succeeded VAT Registration No.";
        SIIDocUploadState.Modify();
    end;

    local procedure UpdateVendorLedgerEntry(PurchInvHeader: Record "Purch. Inv. Header")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if not GetVendorLedgerEntry(VendorLedgerEntry, PurchInvHeader) then
            exit;
        VendorLedgerEntry."Payment Method Code" := PurchInvHeader."Payment Method Code";
        VendorLedgerEntry."Payment Reference" := PurchInvHeader."Payment Reference";
        VendorLedgerEntry."Creditor No." := PurchInvHeader."Creditor No.";
        VendorLedgerEntry.Description := PurchInvHeader."Posting Description";
        OnBeforeUpdateVendorLedgerEntryAfterSetValues(VendorLedgerEntry, PurchInvHeader);
        Codeunit.Run(Codeunit::"Vend. Entry-Edit", VendorLedgerEntry);
    end;

    local procedure GetVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PurchInvHeader: Record "Purch. Inv. Header"): Boolean
    begin
        if PurchInvHeader."Vendor Ledger Entry No." = 0 then
            exit(false);
        VendorLedgerEntry.ReadIsolation(IsolationLevel::UpdLock);
        exit(VendorLedgerEntry.Get(PurchInvHeader."Vendor Ledger Entry No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvHeaderModify(var PurchInvHeader: Record "Purch. Inv. Header"; PurchInvHeaderRec: Record "Purch. Inv. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVendorLedgerEntryAfterSetValues(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterPurchInvHeaderEdit(var PurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;
}

