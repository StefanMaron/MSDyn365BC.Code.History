// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Integration.Graph;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.IO;
using System.Environment;
using System.Environment.Configuration;
using System.Upgrade;

codeunit 104021 "Upgrade Item Cross Reference"
{
    Permissions = TableData "Item Ledger Entry" = rm,
                  TableData "Sales Shipment Line" = rm,
                  TableData "Sales Invoice Line" = rm,
                  TableData "Sales Cr.Memo Line" = rm,
                  TableData "Purch. Rcpt. Line" = rm,
                  TableData "Purch. Inv. Line" = rm,
                  TableData "Purch. Cr. Memo Line" = rm,
                  TableData "Return Receipt Line" = rm,
                  TableData "Return Shipment Line" = rm,
                  TableData "Handled IC Inbox Purch. Line" = rm,
                  TableData "Handled IC Outbox Purch. Line" = rm,
                  TableData "Handled IC Inbox Sales Line" = rm,
                  TableData "Handled IC Outbox Sales Line" = rm;
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
        DisableAggregateTableUpdate: Codeunit "Disable Aggregate Table Update";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        DisableAggregateTableUpdate.SetDisableAllRecords(true);
        BindSubscription(DisableAggregateTableUpdate);
        UpdateData();
        UpdateDateExchFieldMapping();
    end;

    procedure UpdateData();
    var
        ItemCrossReference: Record "Item Cross Reference";
        ItemReference: Record "Item Reference";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ApplicationAreaSetup: Record "Application Area Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        ItemLedgerEntryDataTransfer: DataTransfer;
        ItemJournalLineDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetItemCrossReferenceUpgradeTag()) then
            exit;

        if ApplicationAreaSetup.Get() then begin
            ApplicationAreaSetup."Item References" := true;
            ApplicationAreaSetup.Modify();
        end;

        // check if update already completed using feature management or
        // check if item cross reference had been used before
        if not ItemReference.IsEmpty() or ItemCrossReference.IsEmpty() then begin
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetItemCrossReferenceUpgradeTag());
            exit;
        end;

        ItemCrossReference.FindSet();
        repeat
            Clear(ItemReference);
            ItemReference.TransferFields(ItemCrossReference, true, true);
            ItemReference.SystemId := ItemCrossReference.SystemId;
            ItemReference.Insert(false, true);
        until ItemCrossReference.Next() = 0;

        ItemLedgerEntry.SetFilter("Item Reference No.", '<>%1', '');
        if ItemLedgerEntry.IsEmpty() then begin
            ItemLedgerEntryDataTransfer.SetTables(Database::"Item Ledger Entry", Database::"Item Ledger Entry");
            ItemLedgerEntryDataTransfer.AddSourceFilter(ItemLedgerEntry.FieldNo("Cross-Reference No."), '<>%1', '');
            ItemLedgerEntryDataTransfer.AddFieldValue(ItemLedgerEntry.FieldNo("Cross-Reference No."), ItemLedgerEntry.FieldNo("Item Reference No."));
            ItemLedgerEntryDataTransfer.UpdateAuditFields := false;
            ItemLedgerEntryDataTransfer.CopyFields();
        end;

        ItemJournalLine.SetFilter("Item Reference No.", '<>%1', '');
        if ItemJournalLine.IsEmpty() then begin
            ItemJournalLineDataTransfer.SetTables(Database::"Item Journal Line", Database::"Item Journal Line");
            ItemJournalLineDataTransfer.AddSourceFilter(ItemJournalLine.FieldNo("Cross-Reference No."), '<>%1', '');
            ItemJournalLineDataTransfer.AddFieldValue(ItemJournalLine.FieldNo("Cross-Reference No."), ItemJournalLine.FieldNo("Item Reference No."));
            ItemJournalLineDataTransfer.UpdateAuditFields := false;
            ItemJournalLineDataTransfer.CopyFields();
        end;

        UpgradePurchaseLines();

        UpgradeSalesLines();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetItemCrossReferenceUpgradeTag());
    end;

    local procedure UpgradePurchaseLines()
    begin
        UpgradePurchaseLine();
        UpgradePurchaseLineArchive();
        UpgradePurchRcptLine();
        UpgradePurchInvLine();
        UpgradePurchCrMemoLine();
        UpgradeReturnShipmentLine();
        UpgradeICInOutPurchLines();
    end;

    local procedure UpgradeSalesLines()
    begin
        UpgradeSalesLine();
        UpgradeSalesLineArchive();
        UpgradeSalesShipmentLine();
        UpgradeSalesInvoiceLine();
        UpgradeSalesCrMemoLine();
        UpgradeReturnReceiptLine();
        UpgradeICInOutSalesLines();
    end;

    local procedure UpgradeICInOutPurchLines()
    var
        ICInboxPurchaseLine: Record "IC Inbox Purchase Line";
        ICOutboxPurchaseLine: Record "IC Outbox Purchase Line";
        HandledICInboxPurchLine: Record "Handled IC Inbox Purch. Line";
        HandledICOutboxPurchLine: Record "Handled IC Outbox Purch. Line";
        ICInboxPurchaseLineDataTransfer: DataTransfer;
        ICOutboxPurchaseLineDataTransfer: DataTransfer;
        HandledICInboxPurchLineDataTransfer: DataTransfer;
        HandledICOutboxPurchLineDataTransfer: DataTransfer;
    begin
        ICInboxPurchaseLine.SetFilter("IC Item Reference No.", '<>%1', '');
        if ICInboxPurchaseLine.IsEmpty() then begin
            ICInboxPurchaseLineDataTransfer.SetTables(Database::"IC Inbox Purchase Line", Database::"IC Inbox Purchase Line");
            ICInboxPurchaseLineDataTransfer.AddFieldValue(ICInboxPurchaseLine.FieldNo("IC Partner Reference"), ICInboxPurchaseLine.FieldNo("IC Item Reference No."));
            ICInboxPurchaseLineDataTransfer.UpdateAuditFields := false;
            ICInboxPurchaseLineDataTransfer.CopyFields();
        end;

        ICOutboxPurchaseLine.SetFilter("IC Item Reference No.", '<>%1', '');
        if ICOutboxPurchaseLine.IsEmpty() then begin
            ICOutboxPurchaseLineDataTransfer.SetTables(Database::"IC Outbox Purchase Line", Database::"IC Outbox Purchase Line");
            ICOutboxPurchaseLineDataTransfer.AddFieldValue(ICOutboxPurchaseLine.FieldNo("IC Partner Reference"), ICOutboxPurchaseLine.FieldNo("IC Item Reference No."));
            ICOutboxPurchaseLineDataTransfer.UpdateAuditFields := false;
            ICOutboxPurchaseLineDataTransfer.CopyFields();
        end;

        HandledICInboxPurchLine.SetFilter("IC Item Reference No.", '<>%1', '');
        if HandledICInboxPurchLine.IsEmpty() then begin
            HandledICInboxPurchLineDataTransfer.SetTables(Database::"Handled IC Inbox Purch. Line", Database::"Handled IC Inbox Purch. Line");
            HandledICInboxPurchLineDataTransfer.AddFieldValue(HandledICInboxPurchLine.FieldNo("IC Partner Reference"), HandledICInboxPurchLine.FieldNo("IC Item Reference No."));
            HandledICInboxPurchLineDataTransfer.UpdateAuditFields := false;
            HandledICInboxPurchLineDataTransfer.CopyFields();
        end;

        HandledICOutboxPurchLine.SetFilter("IC Item Reference No.", '<>%1', '');
        if HandledICOutboxPurchLine.IsEmpty() then begin
            HandledICOutboxPurchLineDataTransfer.SetTables(Database::"Handled IC Outbox Purch. Line", Database::"Handled IC Outbox Purch. Line");
            HandledICOutboxPurchLineDataTransfer.AddFieldValue(HandledICOutboxPurchLine.FieldNo("IC Partner Reference"), HandledICOutboxPurchLine.FieldNo("IC Item Reference No."));
            HandledICOutboxPurchLineDataTransfer.UpdateAuditFields := false;
            HandledICOutboxPurchLineDataTransfer.CopyFields();
        end;
    end;

    local procedure UpgradeICInOutSalesLines()
    var
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
        HandledICInboxSalesLine: Record "Handled IC Inbox Sales Line";
        HandledICOutboxSalesLine: Record "Handled IC Outbox Sales Line";
        ICInboxSalesLineDataTransfer: DataTransfer;
        ICOutboxSalesLineDataTransfer: DataTransfer;
        HandledICInboxSalesLineDataTransfer: DataTransfer;
        HandledICOutboxSalesLineDataTransfer: DataTransfer;
    begin
        ICInboxSalesLine.SetFilter("IC Item Reference No.", '<>%1', '');
        if ICInboxSalesLine.IsEmpty() then begin
            ICInboxSalesLineDataTransfer.SetTables(Database::"IC Inbox Sales Line", Database::"IC Inbox Sales Line");
            ICInboxSalesLineDataTransfer.AddSourceFilter(ICInboxSalesLine.FieldNo("IC Partner Reference"), '<>%1', '');
            ICInboxSalesLineDataTransfer.AddFieldValue(ICInboxSalesLine.FieldNo("IC Partner Reference"), ICInboxSalesLine.FieldNo("IC Item Reference No."));
            ICInboxSalesLineDataTransfer.UpdateAuditFields := false;
            ICInboxSalesLineDataTransfer.CopyFields();
        end;

        ICOutboxSalesLine.SetFilter("IC Item Reference No.", '<>%1', '');
        if ICOutboxSalesLine.IsEmpty() then begin
            ICOutboxSalesLineDataTransfer.SetTables(Database::"IC Outbox Sales Line", Database::"IC Outbox Sales Line");
            ICOutboxSalesLineDataTransfer.AddSourceFilter(ICOutboxSalesLine.FieldNo("IC Partner Reference"), '<>%1', '');
            ICOutboxSalesLineDataTransfer.AddFieldValue(ICOutboxSalesLine.FieldNo("IC Partner Reference"), ICOutboxSalesLine.FieldNo("IC Item Reference No."));
            ICOutboxSalesLineDataTransfer.UpdateAuditFields := false;
            ICOutboxSalesLineDataTransfer.CopyFields();
        end;

        HandledICInboxSalesLine.SetFilter("IC Item Reference No.", '<>%1', '');
        if ICOutboxSalesLine.IsEmpty() then begin
            HandledICInboxSalesLineDataTransfer.SetTables(Database::"Handled IC Inbox Sales Line", Database::"Handled IC Inbox Sales Line");
            HandledICInboxSalesLineDataTransfer.AddSourceFilter(HandledICInboxSalesLine.FieldNo("IC Partner Reference"), '<>%1', '');
            HandledICInboxSalesLineDataTransfer.AddFieldValue(HandledICInboxSalesLine.FieldNo("IC Partner Reference"), HandledICInboxSalesLine.FieldNo("IC Item Reference No."));
            HandledICInboxSalesLineDataTransfer.UpdateAuditFields := false;
            HandledICInboxSalesLineDataTransfer.CopyFields();
        end;

        HandledICOutboxSalesLine.SetFilter("IC Item Reference No.", '<>%1', '');
        if HandledICOutboxSalesLine.IsEmpty() then begin
            HandledICOutboxSalesLineDataTransfer.SetTables(Database::"Handled IC Outbox Sales Line", Database::"Handled IC Outbox Sales Line");
            HandledICOutboxSalesLineDataTransfer.AddSourceFilter(HandledICOutboxSalesLine.FieldNo("IC Partner Reference"), '<>%1', '');
            HandledICOutboxSalesLineDataTransfer.AddFieldValue(HandledICOutboxSalesLine.FieldNo("IC Partner Reference"), HandledICOutboxSalesLine.FieldNo("IC Item Reference No."));
            HandledICOutboxSalesLineDataTransfer.UpdateAuditFields := false;
            HandledICOutboxSalesLineDataTransfer.CopyFields();
        end;
    end;

    local procedure UpgradePurchaseLine()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLineDataTransfer: DataTransfer;
    begin
        PurchaseLine.SetFilter("Item Reference No.", '<>%1', '');
        if not PurchaseLine.IsEmpty() then
            exit;

        // Move obsoleted fields
        PurchaseLineDataTransfer.SetTables(Database::"Purchase Line", Database::"Purchase Line");
        PurchaseLineDataTransfer.AddSourceFilter(PurchaseLine.FieldNo("Cross-Reference No."), '<>%1', '');
        PurchaseLineDataTransfer.AddFieldValue(PurchaseLine.FieldNo("Cross-Reference No."), PurchaseLine.FieldNo("Item Reference No."));
        PurchaseLineDataTransfer.AddFieldValue(PurchaseLine.FieldNo("Cross-Reference Type"), PurchaseLine.FieldNo("Item Reference Type"));
        PurchaseLineDataTransfer.AddFieldValue(PurchaseLine.FieldNo("Cross-Reference Type No."), PurchaseLine.FieldNo("Item Reference Type No."));
        PurchaseLineDataTransfer.AddFieldValue(PurchaseLine.FieldNo("Unit of Measure (Cross Ref.)"), PurchaseLine.FieldNo("Item Reference Unit of Measure"));
        PurchaseLineDataTransfer.UpdateAuditFields := false;
        PurchaseLineDataTransfer.CopyFields();

        // Move IC Partner Reference
        Clear(PurchaseLineDataTransfer);
        PurchaseLineDataTransfer.SetTables(Database::"Purchase Line", Database::"Purchase Line");
        PurchaseLineDataTransfer.AddSourceFilter(PurchaseLine.FieldNo("Cross-Reference No."), '<>%1', '');
        PurchaseLineDataTransfer.AddSourceFilter(PurchaseLine.FieldNo("IC Partner Ref. Type"), '=%1', PurchaseLine."IC Partner Ref. Type"::"Cross Reference");
        PurchaseLineDataTransfer.AddFieldValue(PurchaseLine.FieldNo("IC Partner Reference"), PurchaseLine.FieldNo("IC Item Reference No."));
        PurchaseLineDataTransfer.UpdateAuditFields := false;
        PurchaseLineDataTransfer.CopyFields();
    end;

    local procedure UpgradePurchaseLineArchive()
    var
        PurchaseLineArchive: Record "Purchase Line Archive";
        PurchaseLineArchiveDataTransfer: DataTransfer;
    begin
        PurchaseLineArchive.SetFilter("Item Reference No.", '<>%1', '');
        if not PurchaseLineArchive.IsEmpty() then
            exit;

        // Move obsoleted fields
        PurchaseLineArchiveDataTransfer.SetTables(Database::"Purchase Line Archive", Database::"Purchase Line Archive");
        PurchaseLineArchiveDataTransfer.AddSourceFilter(PurchaseLineArchive.FieldNo("Cross-Reference No."), '<>%1', '');
        PurchaseLineArchiveDataTransfer.AddFieldValue(PurchaseLineArchive.FieldNo("Cross-Reference No."), PurchaseLineArchive.FieldNo("Item Reference No."));
        PurchaseLineArchiveDataTransfer.AddFieldValue(PurchaseLineArchive.FieldNo("Cross-Reference Type"), PurchaseLineArchive.FieldNo("Item Reference Type"));
        PurchaseLineArchiveDataTransfer.AddFieldValue(PurchaseLineArchive.FieldNo("Cross-Reference Type No."), PurchaseLineArchive.FieldNo("Item Reference Type No."));
        PurchaseLineArchiveDataTransfer.AddFieldValue(PurchaseLineArchive.FieldNo("Unit of Measure (Cross Ref.)"), PurchaseLineArchive.FieldNo("Item Reference Unit of Measure"));
        PurchaseLineArchiveDataTransfer.UpdateAuditFields := false;
        PurchaseLineArchiveDataTransfer.CopyFields();

        // Move IC Partner Reference
        Clear(PurchaseLineArchiveDataTransfer);
        PurchaseLineArchiveDataTransfer.SetTables(Database::"Purchase Line Archive", Database::"Purchase Line Archive");
        PurchaseLineArchiveDataTransfer.AddSourceFilter(PurchaseLineArchive.FieldNo("Cross-Reference No."), '<>%1', '');
        PurchaseLineArchiveDataTransfer.AddSourceFilter(PurchaseLineArchive.FieldNo("IC Partner Ref. Type"), '=%1', PurchaseLineArchive."IC Partner Ref. Type"::"Cross Reference");
        PurchaseLineArchiveDataTransfer.AddFieldValue(PurchaseLineArchive.FieldNo("IC Partner Reference"), PurchaseLineArchive.FieldNo("IC Item Reference No."));
        PurchaseLineArchiveDataTransfer.UpdateAuditFields := false;
        PurchaseLineArchiveDataTransfer.CopyFields();
    end;

    local procedure UpgradePurchCrMemoLine()
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchCrMemoLineDataTransfer: DataTransfer;
    begin
        PurchCrMemoLine.SetFilter("Item Reference No.", '<>%1', '');
        if not PurchCrMemoLine.IsEmpty() then
            exit;

        // Move obsoleted fields
        PurchCrMemoLineDataTransfer.SetTables(Database::"Purch. Cr. Memo Line", Database::"Purch. Cr. Memo Line");
        PurchCrMemoLineDataTransfer.AddSourceFilter(PurchCrMemoLine.FieldNo("Cross-Reference No."), '<>%1', '');
        PurchCrMemoLineDataTransfer.AddFieldValue(PurchCrMemoLine.FieldNo("Cross-Reference No."), PurchCrMemoLine.FieldNo("Item Reference No."));
        PurchCrMemoLineDataTransfer.AddFieldValue(PurchCrMemoLine.FieldNo("Cross-Reference Type"), PurchCrMemoLine.FieldNo("Item Reference Type"));
        PurchCrMemoLineDataTransfer.AddFieldValue(PurchCrMemoLine.FieldNo("Cross-Reference Type No."), PurchCrMemoLine.FieldNo("Item Reference Type No."));
        PurchCrMemoLineDataTransfer.AddFieldValue(PurchCrMemoLine.FieldNo("Unit of Measure (Cross Ref.)"), PurchCrMemoLine.FieldNo("Item Reference Unit of Measure"));
        PurchCrMemoLineDataTransfer.UpdateAuditFields := false;
        PurchCrMemoLineDataTransfer.CopyFields();

        // Move IC Partner Reference
        Clear(PurchCrMemoLineDataTransfer);
        PurchCrMemoLineDataTransfer.SetTables(Database::"Purch. Cr. Memo Line", Database::"Purch. Cr. Memo Line");
        PurchCrMemoLineDataTransfer.AddSourceFilter(PurchCrMemoLine.FieldNo("Cross-Reference No."), '<>%1', '');
        PurchCrMemoLineDataTransfer.AddSourceFilter(PurchCrMemoLine.FieldNo("IC Partner Ref. Type"), '=%1', PurchCrMemoLine."IC Partner Ref. Type"::"Cross Reference");
        PurchCrMemoLineDataTransfer.AddFieldValue(PurchCrMemoLine.FieldNo("IC Partner Reference"), PurchCrMemoLine.FieldNo("IC Item Reference No."));
        PurchCrMemoLineDataTransfer.UpdateAuditFields := false;
        PurchCrMemoLineDataTransfer.CopyFields();
    end;

    local procedure UpgradePurchInvLine()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchInvLineDataTransfer: DataTransfer;
    begin
        PurchInvLine.SetFilter("Item Reference No.", '<>%1', '');
        if not PurchInvLine.IsEmpty() then
            exit;

        // Move obsoleted fields
        PurchInvLineDataTransfer.SetTables(Database::"Purch. Inv. Line", Database::"Purch. Inv. Line");
        PurchInvLineDataTransfer.AddSourceFilter(PurchInvLine.FieldNo("Cross-Reference No."), '<>%1', '');
        PurchInvLineDataTransfer.AddFieldValue(PurchInvLine.FieldNo("Cross-Reference No."), PurchInvLine.FieldNo("Item Reference No."));
        PurchInvLineDataTransfer.AddFieldValue(PurchInvLine.FieldNo("Cross-Reference Type"), PurchInvLine.FieldNo("Item Reference Type"));
        PurchInvLineDataTransfer.AddFieldValue(PurchInvLine.FieldNo("Cross-Reference Type No."), PurchInvLine.FieldNo("Item Reference Type No."));
        PurchInvLineDataTransfer.AddFieldValue(PurchInvLine.FieldNo("Unit of Measure (Cross Ref.)"), PurchInvLine.FieldNo("Item Reference Unit of Measure"));
        PurchInvLineDataTransfer.UpdateAuditFields := false;
        PurchInvLineDataTransfer.CopyFields();

        // Move IC Partner Reference
        Clear(PurchInvLineDataTransfer);
        PurchInvLineDataTransfer.SetTables(Database::"Purch. Inv. Line", Database::"Purch. Inv. Line");
        PurchInvLineDataTransfer.AddSourceFilter(PurchInvLine.FieldNo("Cross-Reference No."), '<>%1', '');
        PurchInvLineDataTransfer.AddSourceFilter(PurchInvLine.FieldNo("IC Partner Ref. Type"), '=%1', PurchInvLine."IC Partner Ref. Type"::"Cross Reference");
        PurchInvLineDataTransfer.AddFieldValue(PurchInvLine.FieldNo("IC Partner Reference"), PurchInvLine.FieldNo("IC Cross-Reference No."));
        PurchInvLineDataTransfer.UpdateAuditFields := false;
        PurchInvLineDataTransfer.CopyFields();
    end;

    local procedure UpgradePurchRcptLine()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchRcptLineDataTransfer: DataTransfer;
    begin
        PurchRcptLine.SetFilter("Item Reference No.", '<>%1', '');
        if not PurchRcptLine.IsEmpty() then
            exit;

        PurchRcptLineDataTransfer.SetTables(Database::"Purch. Rcpt. Line", Database::"Purch. Rcpt. Line");
        PurchRcptLineDataTransfer.AddSourceFilter(PurchRcptLine.FieldNo("Cross-Reference No."), '<>%1', '');
        PurchRcptLineDataTransfer.AddFieldValue(PurchRcptLine.FieldNo("Cross-Reference No."), PurchRcptLine.FieldNo("Item Reference No."));
        PurchRcptLineDataTransfer.AddFieldValue(PurchRcptLine.FieldNo("Cross-Reference Type"), PurchRcptLine.FieldNo("Item Reference Type"));
        PurchRcptLineDataTransfer.AddFieldValue(PurchRcptLine.FieldNo("Cross-Reference Type No."), PurchRcptLine.FieldNo("Item Reference Type No."));
        PurchRcptLineDataTransfer.AddFieldValue(PurchRcptLine.FieldNo("Unit of Measure (Cross Ref.)"), PurchRcptLine.FieldNo("Item Reference Unit of Measure"));
        PurchRcptLineDataTransfer.UpdateAuditFields := false;
        PurchRcptLineDataTransfer.CopyFields();

        // Move IC Partner Reference
        Clear(PurchRcptLineDataTransfer);
        PurchRcptLineDataTransfer.SetTables(Database::"Purch. Rcpt. Line", Database::"Purch. Rcpt. Line");
        PurchRcptLineDataTransfer.AddSourceFilter(PurchRcptLine.FieldNo("Cross-Reference No."), '<>%1', '');
        PurchRcptLineDataTransfer.AddSourceFilter(PurchRcptLine.FieldNo("IC Partner Ref. Type"), '=%1', PurchRcptLine."IC Partner Ref. Type"::"Cross Reference");
        PurchRcptLineDataTransfer.AddFieldValue(PurchRcptLine.FieldNo("IC Partner Reference"), PurchRcptLine.FieldNo("IC Item Reference No."));
        PurchRcptLineDataTransfer.UpdateAuditFields := false;
        PurchRcptLineDataTransfer.CopyFields();
    end;

    local procedure UpgradeReturnReceiptLine()
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        ReturnReceiptLineDataTransfer: DataTransfer;
    begin
        ReturnReceiptLine.SetFilter("Item Reference No.", '<>%1', '');
        if not ReturnReceiptLine.IsEmpty() then
            exit;

        ReturnReceiptLineDataTransfer.SetTables(Database::"Return Receipt Line", Database::"Return Receipt Line");
        ReturnReceiptLineDataTransfer.AddSourceFilter(ReturnReceiptLine.FieldNo("Cross-Reference No."), '<>%1', '');
        ReturnReceiptLineDataTransfer.AddFieldValue(ReturnReceiptLine.FieldNo("Cross-Reference No."), ReturnReceiptLine.FieldNo("Item Reference No."));
        ReturnReceiptLineDataTransfer.AddFieldValue(ReturnReceiptLine.FieldNo("Cross-Reference Type"), ReturnReceiptLine.FieldNo("Item Reference Type"));
        ReturnReceiptLineDataTransfer.AddFieldValue(ReturnReceiptLine.FieldNo("Cross-Reference Type No."), ReturnReceiptLine.FieldNo("Item Reference Type No."));
        ReturnReceiptLineDataTransfer.AddFieldValue(ReturnReceiptLine.FieldNo("Unit of Measure (Cross Ref.)"), ReturnReceiptLine.FieldNo("Item Reference Unit of Measure"));
        ReturnReceiptLineDataTransfer.UpdateAuditFields := false;
        ReturnReceiptLineDataTransfer.CopyFields();
    end;

    local procedure UpgradeReturnShipmentLine()
    var
        ReturnShipmentLine: Record "Return Shipment Line";
        ReturnShipmentLineDataTransfer: DataTransfer;
    begin
        ReturnShipmentLine.SetFilter("Item Reference No.", '<>%1', '');
        if not ReturnShipmentLine.IsEmpty() then
            exit;

        ReturnShipmentLineDataTransfer.SetTables(Database::"Return Shipment Line", Database::"Return Shipment Line");
        ReturnShipmentLineDataTransfer.AddSourceFilter(ReturnShipmentLine.FieldNo("Cross-Reference No."), '<>%1', '');
        ReturnShipmentLineDataTransfer.AddFieldValue(ReturnShipmentLine.FieldNo("Cross-Reference No."), ReturnShipmentLine.FieldNo("Item Reference No."));
        ReturnShipmentLineDataTransfer.AddFieldValue(ReturnShipmentLine.FieldNo("Cross-Reference Type"), ReturnShipmentLine.FieldNo("Item Reference Type"));
        ReturnShipmentLineDataTransfer.AddFieldValue(ReturnShipmentLine.FieldNo("Cross-Reference Type No."), ReturnShipmentLine.FieldNo("Item Reference Type No."));
        ReturnShipmentLineDataTransfer.AddFieldValue(ReturnShipmentLine.FieldNo("Unit of Measure (Cross Ref.)"), ReturnShipmentLine.FieldNo("Item Reference Unit of Measure"));
        ReturnShipmentLineDataTransfer.UpdateAuditFields := false;
        ReturnShipmentLineDataTransfer.CopyFields();
    end;

    local procedure UpgradeSalesLine()
    var
        SalesLine: Record "Sales Line";
        SalesLineDataTransfer: DataTransfer;
    begin
        SalesLine.SetFilter("Item Reference No.", '<>%1', '');
        if not SalesLine.IsEmpty() then
            exit;

        SalesLineDataTransfer.SetTables(Database::"Sales Line", Database::"Sales Line");
        SalesLineDataTransfer.AddSourceFilter(SalesLine.FieldNo("Cross-Reference No."), '<>%1', '');
        SalesLineDataTransfer.AddFieldValue(SalesLine.FieldNo("Cross-Reference No."), SalesLine.FieldNo("Item Reference No."));
        SalesLineDataTransfer.AddFieldValue(SalesLine.FieldNo("Cross-Reference Type"), SalesLine.FieldNo("Item Reference Type"));
        SalesLineDataTransfer.AddFieldValue(SalesLine.FieldNo("Cross-Reference Type No."), SalesLine.FieldNo("Item Reference Type No."));
        SalesLineDataTransfer.AddFieldValue(SalesLine.FieldNo("Unit of Measure (Cross Ref.)"), SalesLine.FieldNo("Item Reference Unit of Measure"));
        SalesLineDataTransfer.UpdateAuditFields := false;
        SalesLineDataTransfer.CopyFields();

        // Move IC Partner Reference
        Clear(SalesLineDataTransfer);
        SalesLineDataTransfer.SetTables(Database::"Sales Line", Database::"Sales Line");
        SalesLineDataTransfer.AddSourceFilter(SalesLine.FieldNo("Cross-Reference No."), '<>%1', '');
        SalesLineDataTransfer.AddSourceFilter(SalesLine.FieldNo("IC Partner Ref. Type"), '=%1', SalesLine."IC Partner Ref. Type"::"Cross Reference");
        SalesLineDataTransfer.AddFieldValue(SalesLine.FieldNo("IC Partner Reference"), SalesLine.FieldNo("IC Item Reference No."));
        SalesLineDataTransfer.UpdateAuditFields := false;
        SalesLineDataTransfer.CopyFields();
    end;

    local procedure UpgradeSalesLineArchive()
    var
        SalesLineArchive: Record "Sales Line Archive";
        SalesLineArchiveDataTransfer: DataTransfer;
    begin
        SalesLineArchive.SetFilter("Item Reference No.", '<>%1', '');
        if not SalesLineArchive.IsEmpty() then
            exit;

        SalesLineArchiveDataTransfer.SetTables(Database::"Sales Line Archive", Database::"Sales Line Archive");
        SalesLineArchiveDataTransfer.AddSourceFilter(SalesLineArchive.FieldNo("Cross-Reference No."), '<>%1', '');
        SalesLineArchiveDataTransfer.AddFieldValue(SalesLineArchive.FieldNo("Cross-Reference No."), SalesLineArchive.FieldNo("Item Reference No."));
        SalesLineArchiveDataTransfer.AddFieldValue(SalesLineArchive.FieldNo("Cross-Reference Type"), SalesLineArchive.FieldNo("Item Reference Type"));
        SalesLineArchiveDataTransfer.AddFieldValue(SalesLineArchive.FieldNo("Cross-Reference Type No."), SalesLineArchive.FieldNo("Item Reference Type No."));
        SalesLineArchiveDataTransfer.AddFieldValue(SalesLineArchive.FieldNo("Unit of Measure (Cross Ref.)"), SalesLineArchive.FieldNo("Item Reference Unit of Measure"));
        SalesLineArchiveDataTransfer.UpdateAuditFields := false;
        SalesLineArchiveDataTransfer.CopyFields();

        // Move IC Partner Reference
        Clear(SalesLineArchiveDataTransfer);
        SalesLineArchiveDataTransfer.SetTables(Database::"Sales Line Archive", Database::"Sales Line Archive");
        SalesLineArchiveDataTransfer.AddSourceFilter(SalesLineArchive.FieldNo("Cross-Reference No."), '<>%1', '');
        SalesLineArchiveDataTransfer.AddSourceFilter(SalesLineArchive.FieldNo("IC Partner Ref. Type"), '=%1', SalesLineArchive."IC Partner Ref. Type"::"Cross Reference");
        SalesLineArchiveDataTransfer.AddFieldValue(SalesLineArchive.FieldNo("IC Partner Reference"), SalesLineArchive.FieldNo("IC Item Reference No."));
        SalesLineArchiveDataTransfer.UpdateAuditFields := false;
        SalesLineArchiveDataTransfer.CopyFields();
    end;

    local procedure UpgradeSalesShipmentLine()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesShipmentLineDataTransfer: DataTransfer;
    begin
        SalesShipmentLine.SetFilter("Item Reference No.", '<>%1', '');
        if not SalesShipmentLine.IsEmpty() then
            exit;

        SalesShipmentLineDataTransfer.SetTables(Database::"Sales Shipment Line", Database::"Sales Shipment Line");
        SalesShipmentLineDataTransfer.AddSourceFilter(SalesShipmentLine.FieldNo("Cross-Reference No."), '<>%1', '');
        SalesShipmentLineDataTransfer.AddFieldValue(SalesShipmentLine.FieldNo("Cross-Reference No."), SalesShipmentLine.FieldNo("Item Reference No."));
        SalesShipmentLineDataTransfer.AddFieldValue(SalesShipmentLine.FieldNo("Cross-Reference Type"), SalesShipmentLine.FieldNo("Item Reference Type"));
        SalesShipmentLineDataTransfer.AddFieldValue(SalesShipmentLine.FieldNo("Cross-Reference Type No."), SalesShipmentLine.FieldNo("Item Reference Type No."));
        SalesShipmentLineDataTransfer.AddFieldValue(SalesShipmentLine.FieldNo("Unit of Measure (Cross Ref.)"), SalesShipmentLine.FieldNo("Item Reference Unit of Measure"));
        SalesShipmentLineDataTransfer.UpdateAuditFields := false;
        SalesShipmentLineDataTransfer.CopyFields();

        // Move IC Partner Reference
        Clear(SalesShipmentLineDataTransfer);
        SalesShipmentLineDataTransfer.SetTables(Database::"Sales Shipment Line", Database::"Sales Shipment Line");
        SalesShipmentLineDataTransfer.AddSourceFilter(SalesShipmentLine.FieldNo("Cross-Reference No."), '<>%1', '');
        SalesShipmentLineDataTransfer.AddSourceFilter(SalesShipmentLine.FieldNo("IC Partner Ref. Type"), '=%1', SalesShipmentLine."IC Partner Ref. Type"::"Cross Reference");
        SalesShipmentLineDataTransfer.AddFieldValue(SalesShipmentLine.FieldNo("IC Partner Reference"), SalesShipmentLine.FieldNo("IC Item Reference No."));
        SalesShipmentLineDataTransfer.UpdateAuditFields := false;
        SalesShipmentLineDataTransfer.CopyFields();
    end;

    local procedure UpgradeSalesCrMemoLine()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesCrMemoLineDataTransfer: DataTransfer;
    begin
        SalesCrMemoLine.SetFilter("Item Reference No.", '<>%1', '');
        if not SalesCrMemoLine.IsEmpty() then
            exit;

        SalesCrMemoLineDataTransfer.SetTables(Database::"Sales Cr.Memo Line", Database::"Sales Cr.Memo Line");
        SalesCrMemoLineDataTransfer.AddSourceFilter(SalesCrMemoLine.FieldNo("Cross-Reference No."), '<>%1', '');
        SalesCrMemoLineDataTransfer.AddFieldValue(SalesCrMemoLine.FieldNo("Cross-Reference No."), SalesCrMemoLine.FieldNo("Item Reference No."));
        SalesCrMemoLineDataTransfer.AddFieldValue(SalesCrMemoLine.FieldNo("Cross-Reference Type"), SalesCrMemoLine.FieldNo("Item Reference Type"));
        SalesCrMemoLineDataTransfer.AddFieldValue(SalesCrMemoLine.FieldNo("Cross-Reference Type No."), SalesCrMemoLine.FieldNo("Item Reference Type No."));
        SalesCrMemoLineDataTransfer.AddFieldValue(SalesCrMemoLine.FieldNo("Unit of Measure (Cross Ref.)"), SalesCrMemoLine.FieldNo("Item Reference Unit of Measure"));
        SalesCrMemoLineDataTransfer.UpdateAuditFields := false;
        SalesCrMemoLineDataTransfer.CopyFields();

        // Move IC Partner Reference
        Clear(SalesCrMemoLineDataTransfer);
        SalesCrMemoLineDataTransfer.SetTables(Database::"Sales Cr.Memo Line", Database::"Sales Cr.Memo Line");
        SalesCrMemoLineDataTransfer.AddSourceFilter(SalesCrMemoLine.FieldNo("Cross-Reference No."), '<>%1', '');
        SalesCrMemoLineDataTransfer.AddSourceFilter(SalesCrMemoLine.FieldNo("IC Partner Ref. Type"), '=%1', SalesCrMemoLine."IC Partner Ref. Type"::"Cross Reference");
        SalesCrMemoLineDataTransfer.AddFieldValue(SalesCrMemoLine.FieldNo("IC Partner Reference"), SalesCrMemoLine.FieldNo("IC Item Reference No."));
        SalesCrMemoLineDataTransfer.UpdateAuditFields := false;
        SalesCrMemoLineDataTransfer.CopyFields();
    end;

    local procedure UpgradeSalesInvoiceLine()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceLineDataTransfer: DataTransfer;
    begin
        SalesInvoiceLine.SetFilter("Item Reference No.", '<>%1', '');
        if not SalesInvoiceLine.IsEmpty() then
            exit;

        SalesInvoiceLineDataTransfer.SetTables(Database::"Sales Invoice Line", Database::"Sales Invoice Line");
        SalesInvoiceLineDataTransfer.AddSourceFilter(SalesInvoiceLine.FieldNo("Cross-Reference No."), '<>%1', '');
        SalesInvoiceLineDataTransfer.AddFieldValue(SalesInvoiceLine.FieldNo("Cross-Reference No."), SalesInvoiceLine.FieldNo("Item Reference No."));
        SalesInvoiceLineDataTransfer.AddFieldValue(SalesInvoiceLine.FieldNo("Cross-Reference Type"), SalesInvoiceLine.FieldNo("Item Reference Type"));
        SalesInvoiceLineDataTransfer.AddFieldValue(SalesInvoiceLine.FieldNo("Cross-Reference Type No."), SalesInvoiceLine.FieldNo("Item Reference Type No."));
        SalesInvoiceLineDataTransfer.AddFieldValue(SalesInvoiceLine.FieldNo("Unit of Measure (Cross Ref.)"), SalesInvoiceLine.FieldNo("Item Reference Unit of Measure"));
        SalesInvoiceLineDataTransfer.UpdateAuditFields := false;
        SalesInvoiceLineDataTransfer.CopyFields();

        // Move IC Partner Reference
        Clear(SalesInvoiceLineDataTransfer);
        SalesInvoiceLineDataTransfer.SetTables(Database::"Sales Invoice Line", Database::"Sales Invoice Line");
        SalesInvoiceLineDataTransfer.AddSourceFilter(SalesInvoiceLine.FieldNo("Cross-Reference No."), '<>%1', '');
        SalesInvoiceLineDataTransfer.AddSourceFilter(SalesInvoiceLine.FieldNo("IC Partner Ref. Type"), '=%1', SalesInvoiceLine."IC Partner Ref. Type"::"Cross Reference");
        SalesInvoiceLineDataTransfer.AddFieldValue(SalesInvoiceLine.FieldNo("IC Partner Reference"), SalesInvoiceLine.FieldNo("IC Item Reference No."));
        SalesInvoiceLineDataTransfer.UpdateAuditFields := false;
        SalesInvoiceLineDataTransfer.CopyFields();
    end;

    local procedure UpdateDateExchFieldMapping()
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetItemCrossReferenceInPEPPOLUpgradeTag()) then
            exit;

        DataExchFieldMapping.SetFilter("Data Exch. Def Code", 'PEPPOLINVOICE|PEPPOLCREDITMEMO');
        DataExchFieldMapping.SetRange("Target Table ID", Database::"Purchase Line");
        DataExchFieldMapping.SetRange("Target Field ID", 5705); // this is the old cross-reference no. field id
        if not DataExchFieldMapping.IsEmpty() then
            DataExchFieldMapping.ModifyAll("Target Field ID", 5725); // this is new Item Reference No. field id

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetItemCrossReferenceInPEPPOLUpgradeTag());
    end;
}