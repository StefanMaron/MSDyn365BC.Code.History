﻿namespace Microsoft.Purchases.Document;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Setup;
using System.Automation;

codeunit 415 "Release Purchase Document"
{
    TableNo = "Purchase Header";
    Permissions = TableData "Purchase Header" = rm,
                  TableData "Purchase Line" = r;

    trigger OnRun()
    begin
        PurchaseHeader.Copy(Rec);
        PurchaseHeader.SetHideValidationDialog(Rec.GetHideValidationDialog());
        Code();
        Rec := PurchaseHeader;
    end;

    var
        Text001: Label 'There is nothing to release for the document of type %1 with the number %2.';
        PurchSetup: Record "Purchases & Payables Setup";
        InvtSetup: Record "Inventory Setup";
        PurchaseHeader: Record "Purchase Header";
        WhsePurchRelease: Codeunit "Whse.-Purch. Release";
        Text002: Label 'This document can only be released when the approval process is complete.';
        Text003: Label 'The approval process must be cancelled or completed to reopen this document.';
        Text005: Label 'There are unpaid prepayment invoices that are related to the document of type %1 with the number %2.';
        UnpostedPrepaymentAmountsErr: Label 'There are unposted prepayment amounts on the document of type %1 with the number %2.', Comment = '%1 - Document Type; %2 - Document No.';
        PreviewMode: Boolean;
        SkipCheckReleaseRestrictions: Boolean;
        SkipWhseRequestOperations: Boolean;

    local procedure "Code"() LinesWereModified: Boolean
    var
        PurchLine: Record "Purchase Line";
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        NotOnlyDropShipment: Boolean;
        PostingDate: Date;
        PrintPostedDocuments: Boolean;
        IsHandled: Boolean;
    begin
        with PurchaseHeader do begin
            if Status = Status::Released then
                exit;

            IsHandled := false;
            OnBeforeReleasePurchaseDoc(PurchaseHeader, PreviewMode, SkipCheckReleaseRestrictions, IsHandled, SkipWhseRequestOperations);
            if IsHandled then
                exit;

            if not (PreviewMode or SkipCheckReleaseRestrictions) then
                CheckPurchaseReleaseRestrictions();

            TestField("Buy-from Vendor No.");

            IsHandled := false;
            OnCodeOnAfterCheckPurchaseReleaseRestrictions(PurchaseHeader, IsHandled);
            if IsHandled then
                exit;

            CheckPurchLines(PurchLine);

            OnCodeOnAfterCheck(PurchaseHeader, PurchLine, LinesWereModified);

            PurchLine.SetRange("Drop Shipment", false);
            NotOnlyDropShipment := PurchLine.Find('-');

            OnCodeOnCheckTracking(PurchaseHeader, PurchLine);

            PurchLine.Reset();

            IsHandled := false;
            OnBeforeCalcInvDiscount(PurchaseHeader, PreviewMode, LinesWereModified, IsHandled);
            PurchSetup.Get();
            if not IsHandled then
                if PurchSetup."Calc. Inv. Discount" then begin
                    PostingDate := "Posting Date";
                    PrintPostedDocuments := "Print Posted Documents";
                    CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchLine);
                    LinesWereModified := true;
                    Get("Document Type", "No.");
                    "Print Posted Documents" := PrintPostedDocuments;
                    if PostingDate <> "Posting Date" then
                        Validate("Posting Date", PostingDate);
                end;

            IsHandled := false;
            OnBeforeModifyPurchDoc(PurchaseHeader, PreviewMode, IsHandled);
            if IsHandled then
                exit;

            if PrepaymentMgt.TestPurchasePrepayment(PurchaseHeader) and ("Document Type" = "Document Type"::Order) then begin
                Status := Status::"Pending Prepayment";
                Modify(true);
                OnAfterReleasePurchaseDoc(PurchaseHeader, PreviewMode, LinesWereModified, SkipWhseRequestOperations);
                exit;
            end;
            Status := Status::Released;

            OnCodeOnBeforeCalcAndUpdateVATOnLines(PurchaseHeader);
            LinesWereModified := LinesWereModified or CalcAndUpdateVATOnLines(PurchaseHeader, PurchLine);

            OnCodeOnBeforeModifyHeader(PurchaseHeader, PurchLine, PreviewMode, LinesWereModified);

            Modify(true);

            if NotOnlyDropShipment then
                if "Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"] then
                    if not SkipWhseRequestOperations then
                        WhsePurchRelease.Release(PurchaseHeader);

            OnAfterReleasePurchaseDoc(PurchaseHeader, PreviewMode, LinesWereModified, SkipWhseRequestOperations);
        end;
    end;

    local procedure CheckPurchLines(var PurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchLines(PurchaseHeader, PurchLine, IsHandled);
        if IsHandled then
            exit;

        PurchLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchLine.SetFilter(Type, '>0');
        PurchLine.SetFilter(Quantity, '<>0');
        IsHandled := false;
        OnCodeOnAfterPurchLineSetFilters(PurchaseHeader, PurchLine, IsHandled);
        if not IsHandled then
            if not PurchLine.Find('-') then
                Error(Text001, PurchaseHeader."Document Type", PurchaseHeader."No.");

        CheckMandatoryFields(PurchLine);
    end;

    local procedure CheckMandatoryFields(var PurchaseLine: Record "Purchase Line")
    var
        Item: Record "Item";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMandatoryFields(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        InvtSetup.Get();
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        if PurchaseLine.FindSet() then
            repeat
                if InvtSetup."Location Mandatory" then
                    if PurchaseLine.IsInventoriableItem() then begin
                        IsHandled := false;
                        OnCodeOnCheckPurchLineLocationCode(PurchaseLine, IsHandled);
                        if not IsHandled then
                            PurchaseLine.TestField("Location Code");
                    end;
                if Item.Get(PurchaseLine."No.") then
                    if Item.IsVariantMandatory() then
                        PurchaseLine.TestField("Variant Code");
            until PurchaseLine.Next() = 0;
        PurchaseLine.SetFilter(Type, '>0');
    end;

    procedure Reopen(var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReopenPurchaseDoc(PurchHeader, PreviewMode, IsHandled, SkipWhseRequestOperations);
        if IsHandled then
            exit;

        with PurchHeader do begin
            if Status = Status::Open then
                exit;
            if "Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"] then
                if not SkipWhseRequestOperations then
                    WhsePurchRelease.Reopen(PurchHeader);
            Status := Status::Open;
            OnReopenOnBeforePurchaseHeaderModify(PurchHeader);
            Modify(true);
        end;

        OnAfterReopenPurchaseDoc(PurchHeader, PreviewMode, SkipWhseRequestOperations);
    end;

    procedure PerformManualRelease(var PurchHeader: Record "Purchase Header")
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        OnPerformManualReleaseOnBeforeTestPurchasePrepayment(PurchHeader, PreviewMode);
        if PrepaymentMgt.TestPurchasePrepayment(PurchHeader) then
            Error(UnpostedPrepaymentAmountsErr, PurchHeader."Document Type", PurchHeader."No.");

        OnBeforeManualReleasePurchaseDoc(PurchHeader, PreviewMode);
        PerformManualCheckAndRelease(PurchHeader);
        OnAfterManualReleasePurchaseDoc(PurchHeader, PreviewMode);
    end;

    procedure PerformManualCheckAndRelease(var PurchHeader: Record "Purchase Header")
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePerformManualCheckAndRelease(PurchHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        with PurchHeader do
            if ("Document Type" = "Document Type"::Order) and PrepaymentMgt.TestPurchasePayment(PurchHeader) then begin
                if TestStatusIsNotPendingPrepayment() then begin
                    Status := Status::"Pending Prepayment";
                    Modify();
                    Commit();
                end;
                Error(Text005, "Document Type", "No.");
            end;

        CheckPurchaseHeaderPendingApproval(PurchHeader);

        IsHandled := false;
        OnBeforePerformManualRelease(PurchHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        CODEUNIT.Run(CODEUNIT::"Release Purchase Document", PurchHeader);

        OnAfterPerformManualCheckAndRelease(PurchHeader);
    end;

    local procedure CheckPurchaseHeaderPendingApproval(var PurchHeader: Record "Purchase Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchaseHeaderPendingApproval(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if ApprovalsMgmt.IsPurchaseHeaderPendingApproval(PurchHeader) then
            Error(Text002);
    end;

    procedure PerformManualReopen(var PurchHeader: Record "Purchase Header")
    begin
        if PurchHeader.Status = PurchHeader.Status::"Pending Approval" then
            Error(Text003);

        OnBeforeManualReopenPurchaseDoc(PurchHeader, PreviewMode);
        Reopen(PurchHeader);
        OnAfterManualReopenPurchaseDoc(PurchHeader, PreviewMode);
    end;

    procedure ReleasePurchaseHeader(var PurchHdr: Record "Purchase Header"; Preview: Boolean) LinesWereModified: Boolean
    begin
        PreviewMode := Preview;
        PurchaseHeader.Copy(PurchHdr);
        LinesWereModified := Code();
        PurchHdr := PurchaseHeader;
    end;

    procedure CalcAndUpdateVATOnLines(var PurchaseHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line") LinesWereModified: Boolean
    var
        TempVATAmountLine0: Record "VAT Amount Line" temporary;
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
    begin
        PurchLine.SetPurchHeader(PurchaseHeader);
        PurchLine.CalcVATAmountLines(0, PurchaseHeader, PurchLine, TempVATAmountLine0);
        PurchLine.CalcVATAmountLines(1, PurchaseHeader, PurchLine, TempVATAmountLine1);
        LinesWereModified :=
          PurchLine.UpdateVATOnLines(0, PurchaseHeader, PurchLine, TempVATAmountLine0) or
          PurchLine.UpdateVATOnLines(1, PurchaseHeader, PurchLine, TempVATAmountLine1);
    end;

    procedure SetSkipCheckReleaseRestrictions()
    begin
        SkipCheckReleaseRestrictions := true;
    end;

    internal procedure SetSkipWhseRequestOperations(NewSkipWhseRequestOperations: Boolean)
    begin
        SkipWhseRequestOperations := NewSkipWhseRequestOperations;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvDiscount(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var LinesWereModified: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchaseHeaderPendingApproval(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeManualReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualCheckAndRelease(var PurchHeader: Record "Purchase Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var SkipCheckReleaseRestrictions: Boolean; var IsHandled: Boolean; SkipWhseRequestOperations: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var LinesWereModified: Boolean; SkipWhseRequestOperations: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManualReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeManualReopenPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var IsHandled: Boolean; SkipWhseRequestOperations: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPurchDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualRelease(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchLines(var PurchaseHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; SkipWhseRequestOperations: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManualReopenPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCheck(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var LinesWereModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterPurchLineSetFilters(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeModifyHeader(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnCheckTracking(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPerformManualReleaseOnBeforeTestPurchasePrepayment(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCheckPurchaseReleaseRestrictions(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCalcAndUpdateVATOnLines(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnCheckPurchLineLocationCode(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMandatoryFields(PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReopenOnBeforePurchaseHeaderModify(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPerformManualCheckAndRelease(var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

