#pragma warning disable AS0049
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Foundation.UOM;
using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Document;
using System.AI;

codeunit 6125 "Prepare Purchase E-Doc. Draft" implements IProcessStructuredData
{
    Access = Internal;

    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type"
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        UnitOfMeasure: Record "Unit of Measure";
        Vendor: Record Vendor;
        PurchaseOrder: Record "Purchase Header";
        EDocVendorAssignmentHistory: Record "E-Doc. Vendor Assign. History";
        EDocPurchaseLineHistory: Record "E-Doc. Purchase Line History";
        LineToAccountLLMMatching: Codeunit "Line To Account LLM Matching";
        EDocPurchaseHistMapping: Codeunit "E-Doc. Purchase Hist. Mapping";
        CopilotCapability: Codeunit "Copilot Capability";
        IUnitOfMeasureProvider: Interface IUnitOfMeasureProvider;
        IPurchaseLineProvider: Interface IPurchaseLineProvider;
        IPurchaseOrderProvider: Interface IPurchaseOrderProvider;
    begin
        IUnitOfMeasureProvider := EDocImportParameters."Processing Customizations";
        IPurchaseLineProvider := EDocImportParameters."Processing Customizations";
        IPurchaseOrderProvider := EDocImportParameters."Processing Customizations";

        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        EDocumentPurchaseHeader.TestField("E-Document Entry No.");
        Vendor := GetVendor(EDocument, EDocImportParameters."Processing Customizations");
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";

        PurchaseOrder := IPurchaseOrderProvider.GetPurchaseOrder(EDocumentPurchaseHeader);
        if PurchaseOrder."No." <> '' then begin
            PurchaseOrder.TestField("Document Type", "Purchase Document Type"::Order);
            EDocumentPurchaseHeader."[BC] Purchase Order No." := PurchaseOrder."No.";
            EDocumentPurchaseHeader.Modify();
            exit("E-Document Type"::"Purchase Order");
        end;
        if EDocPurchaseHistMapping.FindRelatedPurchaseHeaderInHistory(EDocument, EDocVendorAssignmentHistory) then
            EDocPurchaseHistMapping.UpdateMissingHeaderValuesFromHistory(EDocVendorAssignmentHistory, EDocumentPurchaseHeader);
        EDocumentPurchaseHeader.Modify();

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if EDocumentPurchaseLine.FindSet() then
            repeat
                // Look up based on text-to-account mapping
                UnitOfMeasure := IUnitOfMeasureProvider.GetUnitOfMeasure(EDocument, EDocumentPurchaseLine."Line No.", EDocumentPurchaseLine."Unit of Measure");
                EDocumentPurchaseLine."[BC] Unit of Measure" := UnitOfMeasure.Code;
                // Resolve the purchase line type and No., as well as related fields
                IPurchaseLineProvider.GetPurchaseLine(EDocumentPurchaseLine);

                if EDocPurchaseHistMapping.FindRelatedPurchaseLineInHistory(EDocumentPurchaseHeader."[BC] Vendor No.", EDocumentPurchaseLine, EDocPurchaseLineHistory) then
                    EDocPurchaseHistMapping.UpdateMissingLineValuesFromHistory(EDocPurchaseLineHistory, EDocumentPurchaseLine);
                EDocumentPurchaseLine.Modify();
                // Mark the lines that are not matched yet
                if EDocumentPurchaseLine."[BC] Purchase Type No." = '' then
                    EDocumentPurchaseLine.Mark(true);
            until EDocumentPurchaseLine.Next() = 0;
        EDocumentPurchaseLine.MarkedOnly(true);

        // Ask Copilot to try to match the marked ones (those that are not matched yet)
        if CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"E-Document Matching Assistance") then
            if CopilotCapability.IsCapabilityActive(Enum::"Copilot Capability"::"E-Document Matching Assistance") then
                LineToAccountLLMMatching.GetPurchaseLineAccountsWithCopilot(EDocumentPurchaseLine);

        exit("E-Document Type"::"Purchase Invoice");
    end;

    procedure OpenDraftPage(var EDocument: Record "E-Document")
    var
        EDocumentPurchaseDraft: Page "E-Document Purchase Draft";
    begin
        EDocumentPurchaseDraft.SetRecord(EDocument);
        EDocumentPurchaseDraft.Run();
    end;

    procedure CleanUpDraft(EDocument: Record "E-Document")
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        EDocumentPurchaseHeader.SetRange("E-Document Entry No.", EDocument."Entry No");
        if not EDocumentPurchaseHeader.IsEmpty() then
            EDocumentPurchaseHeader.DeleteAll(true);

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if not EDocumentPurchaseLine.IsEmpty() then
            EDocumentPurchaseLine.DeleteAll(true);
    end;

    procedure GetVendor(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations") Vendor: Record Vendor
    var
        IVendorProvider: Interface IVendorProvider;
    begin
        IVendorProvider := Customizations;
        Vendor := IVendorProvider.GetVendor(EDocument);
    end;
}
#pragma warning restore AS0049