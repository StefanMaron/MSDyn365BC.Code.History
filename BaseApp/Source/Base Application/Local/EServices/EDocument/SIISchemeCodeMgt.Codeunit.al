﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Posting;
using System.Utilities;

codeunit 10758 "SII Scheme Code Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        ConfirmChangeQst: Label 'Do you want to change %1?', Comment = '%1 = a Field Caption like Currency Code';

    procedure GetMaxNumberOfRegimeCodes(): Integer
    var
    begin
        exit(3);
    end;

    procedure SalesDocHasRegimeCodes(RecVar: Variant): Boolean
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        if not GetSIISalesDocRecFromRec(SIISalesDocumentSchemeCode, RecVar) then
            exit(false);
        exit(not SIISalesDocumentSchemeCode.IsEmpty());
    end;

    procedure SalesDrillDownRegimeCodes(RecVar: Variant)
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        if GetSIISalesDocRecFromRec(SIISalesDocumentSchemeCode, RecVar) then
            PAGE.RunModal(0, SIISalesDocumentSchemeCode);
    end;

    local procedure GetSIISalesDocRecFromRec(var SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code"; RecVar: Variant): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        case RecRef.Number of
            DATABASE::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Sales);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SalesHeader."Document Type");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", SalesHeader."No.");
                    exit(true);
                end;
            DATABASE::"Sales Invoice Header":
                begin
                    RecRef.SetTable(SalesInvoiceHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Sales);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", SalesInvoiceHeader."No.");
                    exit(true);
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    RecRef.SetTable(SalesCrMemoHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Sales);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", SalesCrMemoHeader."No.");
                    exit(true);
                end;
            DATABASE::"Service Header":
                begin
                    RecRef.SetTable(ServiceHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Service);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", ServiceHeader."Document Type");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", ServiceHeader."No.");
                    exit(true);
                end;
            DATABASE::"Service Invoice Header":
                begin
                    RecRef.SetTable(ServiceInvoiceHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Service);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", ServiceInvoiceHeader."No.");
                    exit(true);
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    RecRef.SetTable(ServiceCrMemoHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Service);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", ServiceCrMemoHeader."No.");
                    exit(true);
                end;
        end;
    end;

    local procedure MoveSalesRegimeCodesToPostedDoc(DocType: Enum "Service Document Type"; DocNo: Code[20]; EntryType: Option; PostedDocType: Option; PostedDocNo: Code[20])
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        NewSIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        SIISalesDocumentSchemeCode.SetRange("Entry Type", EntryType);
        SIISalesDocumentSchemeCode.SetRange("Document Type", DocType);
        SIISalesDocumentSchemeCode.SetRange("Document No.", DocNo);
        if not SIISalesDocumentSchemeCode.FindSet() then
            exit;

        repeat
            NewSIISalesDocumentSchemeCode := SIISalesDocumentSchemeCode;
            NewSIISalesDocumentSchemeCode."Document Type" := PostedDocType;
            NewSIISalesDocumentSchemeCode."Document No." := PostedDocNo;
            NewSIISalesDocumentSchemeCode.Insert();
        until SIISalesDocumentSchemeCode.Next() = 0;
        SIISalesDocumentSchemeCode.DeleteAll(true);
    end;

    procedure PurchDocHasRegimeCodes(RecVar: Variant): Boolean
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        if not GetSIIPurchDocRecFromRec(SIIPurchDocSchemeCode, RecVar) then
            exit(false);
        exit(not SIIPurchDocSchemeCode.IsEmpty());
    end;

    procedure PurchDrillDownRegimeCodes(RecVar: Variant)
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        if GetSIIPurchDocRecFromRec(SIIPurchDocSchemeCode, RecVar) then
            PAGE.RunModal(0, SIIPurchDocSchemeCode);
    end;

    procedure ValidateSalesSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState: Record "SII Doc. Upload State"; SIIDocUploadState: Record "SII Doc. Upload State")
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        ValidateSalesAndServSpecialRegimeCodeInSIIDocUploadState(
          xSIIDocUploadState, SIIDocUploadState, SIISalesDocumentSchemeCode."Entry Type"::Sales);
    end;

    procedure ValidateServiceSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState: Record "SII Doc. Upload State"; SIIDocUploadState: Record "SII Doc. Upload State")
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        ValidateSalesAndServSpecialRegimeCodeInSIIDocUploadState(
          xSIIDocUploadState, SIIDocUploadState, SIISalesDocumentSchemeCode."Entry Type"::Service);
    end;

    local procedure ValidateSalesAndServSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState: Record "SII Doc. Upload State"; SIIDocUploadState: Record "SII Doc. Upload State"; EntryType: Option)
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        DocType: Option;
    begin
        if xSIIDocUploadState."Sales Special Scheme Code" = SIIDocUploadState."Sales Special Scheme Code" then
            exit;

        DocType := GetSpecialRegimeDocTypeFromSIIDocUploadState(SIIDocUploadState);
        if xSIIDocUploadState."Sales Special Scheme Code" <> 0 then
            if SIISalesDocumentSchemeCode.Get(EntryType, DocType, SIIDocUploadState."Document No.",
                 xSIIDocUploadState."Sales Special Scheme Code")
            then
                SIISalesDocumentSchemeCode.Delete(true);

        if SIIDocUploadState."Sales Special Scheme Code" = 0 then
            exit;

        SIISalesDocumentSchemeCode.Init();
        SIISalesDocumentSchemeCode.Validate("Entry Type", EntryType);
        SIISalesDocumentSchemeCode.Validate("Document Type", DocType);
        SIISalesDocumentSchemeCode.Validate(
          "Document No.", CopyStr(SIIDocUploadState."Document No.", 1, MaxStrLen(SIISalesDocumentSchemeCode."Document No.")));
        SIISalesDocumentSchemeCode.Validate("Special Scheme Code", SIIDocUploadState."Sales Special Scheme Code");
        SIISalesDocumentSchemeCode.Insert(true);
    end;

    procedure ValidatePurchSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState: Record "SII Doc. Upload State"; SIIDocUploadState: Record "SII Doc. Upload State")
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        DocType: Option;
    begin
        if xSIIDocUploadState."Purch. Special Scheme Code" = SIIDocUploadState."Purch. Special Scheme Code" then
            exit;

        DocType := GetSpecialRegimeDocTypeFromSIIDocUploadState(SIIDocUploadState);
        if xSIIDocUploadState."Purch. Special Scheme Code" <> 0 then
            if SIIPurchDocSchemeCode.Get(DocType, SIIDocUploadState."Document No.", xSIIDocUploadState."Purch. Special Scheme Code") then
                SIIPurchDocSchemeCode.Delete(true);

        if SIIDocUploadState."Purch. Special Scheme Code" = 0 then
            exit;

        SIIPurchDocSchemeCode.Init();
        SIIPurchDocSchemeCode.Validate("Document Type", DocType);
        SIIPurchDocSchemeCode.Validate(
          "Document No.", CopyStr(SIIDocUploadState."Document No.", 1, MaxStrLen(SIIPurchDocSchemeCode."Document No.")));
        SIIPurchDocSchemeCode.Validate("Special Scheme Code", SIIDocUploadState."Purch. Special Scheme Code");
        SIIPurchDocSchemeCode.Insert(true);
    end;

    procedure UpdatePurchaseSpecialSchemeCodeInPurchaseHeader(PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        If PurchaseHeader."Special Scheme Code" = xPurchaseHeader."Special Scheme Code" then
            exit;
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if not PurchaseLine.FindSet(true) then
            exit;
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmChangeQst, PurchaseHeader.FieldCaption("Special Scheme Code")), true) then
            exit;
        repeat
            PurchaseLine.Validate("Special Scheme Code", PurchaseHeader."Special Scheme Code");
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    procedure UpdateSalesSpecialSchemeCodeInSalesHeader(SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        If SalesHeader."Special Scheme Code" = xSalesHeader."Special Scheme Code" then
            exit;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if not SalesLine.FindSet(true) then
            exit;
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmChangeQst, SalesHeader.FieldCaption("Special Scheme Code")), true) then
            exit;
        repeat
            SalesLine.Validate("Special Scheme Code", SalesHeader."Special Scheme Code");
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    procedure UpdateServiceSpecialSchemeCodeInSalesHeader(ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        If ServiceHeader."Special Scheme Code" = xServiceHeader."Special Scheme Code" then
            exit;
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        if not ServiceLine.FindSet(true) then
            exit;
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmChangeQst, ServiceHeader.FieldCaption("Special Scheme Code")), true) then
            exit;
        repeat
            ServiceLine.Validate("Special Scheme Code", ServiceHeader."Special Scheme Code");
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    procedure UpdateSalesSpecialSchemeCodeInSalesLine(var SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        SalesLine."Special Scheme Code" := SalesLine."Special Scheme Code"::"01 General";
        if not VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then
            exit;
        if VATPostingSetup."Sales Special Scheme Code" = VATPostingSetup."Sales Special Scheme Code"::" " then
            exit;
        SalesLine."Special Scheme Code" := VATPostingSetup."Sales Special Scheme Code" - 1;
    end;

    procedure UpdatePurchSpecialSchemeCodeInPurchLine(var PurchaseLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        PurchaseLine."Special Scheme Code" := PurchaseLine."Special Scheme Code"::"01 General";
        if not VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group") then
            exit;
        if VATPostingSetup."Purch. Special Scheme Code" = VATPostingSetup."Purch. Special Scheme Code"::" " then
            exit;
        PurchaseLine."Special Scheme Code" := VATPostingSetup."Purch. Special Scheme Code" - 1;
    end;

    procedure UpdatePurchSpecialSchemeCodeInServiceine(var ServiceLine: Record "Service Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        ServiceLine."Special Scheme Code" := ServiceLine."Special Scheme Code"::"01 General";
        if not VATPostingSetup.Get(ServiceLine."VAT Bus. Posting Group", ServiceLine."VAT Prod. Posting Group") then
            exit;
        if VATPostingSetup."Sales Special Scheme Code" = VATPostingSetup."Sales Special Scheme Code"::" " then
            exit;
        ServiceLine."Special Scheme Code" := VATPostingSetup."Sales Special Scheme Code" - 1;
    end;

    local procedure GetSpecialRegimeDocTypeFromSIIDocUploadState(SIIDocUploadState: Record "SII Doc. Upload State"): Integer
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        case SIIDocUploadState."Document Type" of
            SIIDocUploadState."Document Type"::Invoice:
                exit(SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice");
            SIIDocUploadState."Document Type"::"Credit Memo":
                exit(SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo");
        end;
    end;

    local procedure GetSIIPurchDocRecFromRec(var SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code"; RecVar: Variant): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        case RecRef.Number of
            DATABASE::"Purchase Header":
                begin
                    RecRef.SetTable(PurchaseHeader);
                    SIIPurchDocSchemeCode.SetRange("Document Type", PurchaseHeader."Document Type");
                    SIIPurchDocSchemeCode.SetRange("Document No.", PurchaseHeader."No.");
                    exit(true);
                end;
            DATABASE::"Purch. Inv. Header":
                begin
                    RecRef.SetTable(PurchInvHeader);
                    SIIPurchDocSchemeCode.SetRange("Document Type", SIIPurchDocSchemeCode."Document Type"::"Posted Invoice");
                    SIIPurchDocSchemeCode.SetRange("Document No.", PurchInvHeader."No.");
                    exit(true);
                end;
            DATABASE::"Purch. Cr. Memo Hdr.":
                begin
                    RecRef.SetTable(PurchCrMemoHdr);
                    SIIPurchDocSchemeCode.SetRange("Document Type", SIIPurchDocSchemeCode."Document Type"::"Posted Credit Memo");
                    SIIPurchDocSchemeCode.SetRange("Document No.", PurchCrMemoHdr."No.");
                    exit(true);
                end;
        end;
    end;

    local procedure MovePurchRegimeCodesToPostedDoc(PurchaseHeader: Record "Purchase Header"; PostedDocType: Option; PostedDocNo: Code[20])
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        NewSIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        SIIPurchDocSchemeCode.SetRange("Document Type", PurchaseHeader."Document Type");
        SIIPurchDocSchemeCode.SetRange("Document No.", PurchaseHeader."No.");
        if not SIIPurchDocSchemeCode.FindSet() then
            exit;

        repeat
            NewSIIPurchDocSchemeCode := SIIPurchDocSchemeCode;
            NewSIIPurchDocSchemeCode."Document Type" := PostedDocType;
            NewSIIPurchDocSchemeCode."Document No." := PostedDocNo;
            NewSIIPurchDocSchemeCode.Insert();
        until SIIPurchDocSchemeCode.Next() = 0;
        SIIPurchDocSchemeCode.DeleteAll(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var HideProgressWindow: Boolean)
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        Found: Boolean;
        SpecialSchemeCodeToInsert: Boolean;
    begin
        SIISalesDocumentSchemeCode."Entry Type" := SIISalesDocumentSchemeCode."Entry Type"::Sales;
        SIISalesDocumentSchemeCode."Document Type" := SalesHeader."Document Type";
        SIISalesDocumentSchemeCode."Document No." := SalesHeader."No.";

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if not SalesLine.FindSet() then
            exit;

        repeat
            SpecialSchemeCodeToInsert := false;
            If SalesLine."Special Scheme Code" <> SalesLine."Special Scheme Code"::"01 General" then begin
                SIISalesDocumentSchemeCode."Special Scheme Code" := SalesLine."Special Scheme Code" + 1;
                SpecialSchemeCodeToInsert := true;
            end;
            if (VATPostingSetup."VAT Bus. Posting Group" <> SalesLine."VAT Bus. Posting Group") or
                (VATPostingSetup."VAT Prod. Posting Group" <> SalesLine."VAT Prod. Posting Group")
            then begin
                if not VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then
                    VATPostingSetup.Init();
                if (VATPostingSetup."VAT Clause Code" <> '') and
                    (SalesHeader."Special Scheme Code" <= SalesHeader."Special Scheme Code"::"01 General")
                then
                    if VATPostingSetup."VAT Clause Code" <> VATClause.Code then begin
                        VATClause.Get(VATPostingSetup."VAT Clause Code");
                        Found :=
                        VATClause."SII Exemption Code" in [VATClause."SII Exemption Code"::"E2 Exempt on account of Article 21",
                                                            VATClause."SII Exemption Code"::"E3 Exempt on account of Article 22"]
                    end;
                if (VATPostingSetup."Sales Special Scheme Code" <> 0) and (not SpecialSchemeCodeToInsert) then begin
                    SIISalesDocumentSchemeCode."Special Scheme Code" := VATPostingSetup."Sales Special Scheme Code";
                    SpecialSchemeCodeToInsert := true;
                end;
            end;
            if SpecialSchemeCodeToInsert then begin
                if not SIISalesDocumentSchemeCode.Find() then
                    SIISalesDocumentSchemeCode.Insert();
                SalesHeader."Special Scheme Code" := SIISalesDocumentSchemeCode."Special Scheme Code" - 1;
            end;
        until (SalesLine.Next() = 0) or Found;
        if Found then begin
            SalesHeader."Special Scheme Code" := SalesHeader."Special Scheme Code"::"02 Export";
            if SalesDocHasRegimeCodes(SalesHeader) then begin
                SIISalesDocumentSchemeCode."Special Scheme Code" := SIISalesDocumentSchemeCode."Special Scheme Code"::"02 Export";
                if not SIISalesDocumentSchemeCode.Find() then
                    SIISalesDocumentSchemeCode.Insert();
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnBeforePostWithLines', '', false, false)]
    local procedure OnBeforePostWithLines(var PassedServHeader: Record "Service Header"; var PassedServLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    var
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        Found: Boolean;
        SpecialSchemeCodeToInsert: Boolean;
    begin
        SIISalesDocumentSchemeCode."Entry Type" := SIISalesDocumentSchemeCode."Entry Type"::Service;
        SIISalesDocumentSchemeCode."Document Type" := PassedServHeader."Document Type";
        SIISalesDocumentSchemeCode."Document No." := PassedServHeader."No.";

        ServiceLine.SetRange("Document Type", PassedServHeader."Document Type");
        ServiceLine.SetRange("Document No.", PassedServHeader."No.");
        if not ServiceLine.FindSet() then
            exit;

        repeat
            SpecialSchemeCodeToInsert := false;
            If ServiceLine."Special Scheme Code" <> ServiceLine."Special Scheme Code"::"01 General" then begin
                SIISalesDocumentSchemeCode."Special Scheme Code" := ServiceLine."Special Scheme Code" + 1;
                SpecialSchemeCodeToInsert := true;
            end;
            if (VATPostingSetup."VAT Bus. Posting Group" <> ServiceLine."VAT Bus. Posting Group") or
                (VATPostingSetup."VAT Prod. Posting Group" <> ServiceLine."VAT Prod. Posting Group")
            then begin
                if not VATPostingSetup.Get(ServiceLine."VAT Bus. Posting Group", ServiceLine."VAT Prod. Posting Group") then
                    VATPostingSetup.Init();
                if (VATPostingSetup."VAT Clause Code" <> '') and
                    (PassedServHeader."Special Scheme Code" <= PassedServHeader."Special Scheme Code"::"01 General")
                then
                    if VATPostingSetup."VAT Clause Code" <> VATClause.Code then begin
                        VATClause.Get(VATPostingSetup."VAT Clause Code");
                        Found :=
                          VATClause."SII Exemption Code" in [VATClause."SII Exemption Code"::"E2 Exempt on account of Article 21",
                                                              VATClause."SII Exemption Code"::"E3 Exempt on account of Article 22"]
                    end;
                if (VATPostingSetup."Sales Special Scheme Code" <> 0) and (not SpecialSchemeCodeToInsert) then begin
                    SIISalesDocumentSchemeCode."Special Scheme Code" := VATPostingSetup."Sales Special Scheme Code";
                    SpecialSchemeCodeToInsert := true;
                end;
            end;
            if SpecialSchemeCodeToInsert then begin
                if not SIISalesDocumentSchemeCode.Find() then
                    SIISalesDocumentSchemeCode.Insert();
                PassedServHeader."Special Scheme Code" := SIISalesDocumentSchemeCode."Special Scheme Code" - 1;
            end;
        until (ServiceLine.Next() = 0) or Found;
        if Found then begin
            PassedServHeader."Special Scheme Code" := PassedServHeader."Special Scheme Code"::"02 Export";
            if SalesDocHasRegimeCodes(PassedServHeader) then begin
                SIISalesDocumentSchemeCode."Special Scheme Code" := SIISalesDocumentSchemeCode."Special Scheme Code"::"02 Export";
                if not SIISalesDocumentSchemeCode.Find() then
                    SIISalesDocumentSchemeCode.Insert();
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure OnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var HideProgressWindow: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        SpecialSchemeCodeToInsert: Boolean;
    begin
        SIIPurchDocSchemeCode."Document Type" := PurchaseHeader."Document Type";
        SIIPurchDocSchemeCode."Document No." := PurchaseHeader."No.";

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if not PurchaseLine.FindSet() then
            exit;

        repeat
            SpecialSchemeCodeToInsert := false;
            If PurchaseLine."Special Scheme Code" <> PurchaseLine."Special Scheme Code"::"01 General" then begin
                SIIPurchDocSchemeCode."Special Scheme Code" := PurchaseLine."Special Scheme Code" + 1;
                SpecialSchemeCodeToInsert := true;
            end;
            if (VATPostingSetup."VAT Bus. Posting Group" <> PurchaseLine."VAT Bus. Posting Group") or
                (VATPostingSetup."VAT Prod. Posting Group" <> PurchaseLine."VAT Prod. Posting Group")
            then begin
                if not VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group") then
                    VATPostingSetup.Init();
                if VATPostingSetup."Purch. Special Scheme Code" <> 0 then begin
                    PurchaseHeader."Special Scheme Code" := VATPostingSetup."Purch. Special Scheme Code" - 1;
                    SIIPurchDocSchemeCode."Special Scheme Code" := VATPostingSetup."Purch. Special Scheme Code";
                    SpecialSchemeCodeToInsert := true;
                end;
            end;
            if SpecialSchemeCodeToInsert then begin
                if not SIIPurchDocSchemeCode.Find() then
                    SIIPurchDocSchemeCode.Insert();
                PurchaseHeader."Special Scheme Code" := SIIPurchDocSchemeCode."Special Scheme Code" - 1;
            end;
        until PurchaseLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesInvHeaderInsert', '', false, false)]
    local procedure OnAfterSalesInvHeaderInsert(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        MoveSalesRegimeCodesToPostedDoc(
          SalesHeader."Document Type", SalesHeader."No.", SIISalesDocumentSchemeCode."Entry Type"::Sales,
          SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice", SalesInvHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesCrMemoHeaderInsert', '', false, false)]
    local procedure OnAfterSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        MoveSalesRegimeCodesToPostedDoc(
          SalesHeader."Document Type", SalesHeader."No.", SIISalesDocumentSchemeCode."Entry Type"::Sales,
          SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo", SalesCrMemoHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnAfterServInvHeaderInsert', '', false, false)]
    local procedure OnAfterServInvHeaderInsert(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header")
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        MoveSalesRegimeCodesToPostedDoc(
          ServiceHeader."Document Type", ServiceHeader."No.", SIISalesDocumentSchemeCode."Entry Type"::Service,
          SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice", ServiceInvoiceHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnAfterServCrMemoHeaderInsert', '', false, false)]
    local procedure OnAfterServCrMemoHeaderInsert(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ServiceHeader: Record "Service Header")
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        MoveSalesRegimeCodesToPostedDoc(
          ServiceHeader."Document Type", ServiceHeader."No.", SIISalesDocumentSchemeCode."Entry Type"::Service,
          SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo", ServiceCrMemoHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchInvHeaderInsert', '', false, false)]
    local procedure OnAfterPurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header")
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        MovePurchRegimeCodesToPostedDoc(PurchHeader, SIIPurchDocSchemeCode."Document Type"::"Posted Invoice", PurchInvHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchCrMemoHeaderInsert', '', false, false)]
    local procedure OnAfterPurchCrMemoHeaderInsert(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        MovePurchRegimeCodesToPostedDoc(PurchHeader, SIIPurchDocSchemeCode."Document Type"::"Posted Credit Memo", PurchCrMemoHdr."No.");
    end;
}

