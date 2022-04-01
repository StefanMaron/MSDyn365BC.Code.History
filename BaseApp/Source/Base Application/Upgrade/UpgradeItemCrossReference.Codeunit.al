Codeunit 104021 "Upgrade Item Cross Reference"
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
#if not CLEAN19
        InventorySetup: Record "Inventory Setup";
#endif        
        ItemCrossReference: Record "Item Cross Reference";
        ItemReference: Record "Item Reference";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ApplicationAreaSetup: Record "Application Area Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
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

#if not CLEAN19
        InventorySetup.Get();
        InventorySetup."Use Item References" := true;
        InventorySetup.Modify();
#endif

        ItemCrossReference.FindSet();
        repeat
            Clear(ItemReference);
            ItemReference.TransferFields(ItemCrossReference, true, true);
            ItemReference.SystemId := ItemCrossReference.SystemId;
            ItemReference.Insert(false, true);
        until ItemCrossReference.Next() = 0;

        ItemLedgerEntry.SetLoadFields("Cross-Reference No.", "Item Reference No.");
        ItemLedgerEntry.SetFilter("Cross-Reference No.", '<>%1', '');
        if ItemLedgerEntry.FindSet() then
            repeat
                ItemLedgerEntry."Item Reference No." := ItemLedgerEntry."Cross-Reference No.";
                ItemLedgerEntry.Modify();
            until ItemLedgerEntry.Next() = 0;

        ItemJournalLine.SetLoadFields("Cross-Reference No.", "Item Reference No.");
        ItemJournalLine.SetFilter("Cross-Reference No.", '<>%1', '');
        if ItemJournalLine.FindSet() then
            repeat
                ItemJournalLine."Item Reference No." := ItemJournalLine."Cross-Reference No.";
                ItemJournalLine.Modify();
            until ItemJournalLine.Next() = 0;

        UpgradePurchaseLines();

        UpgradeSalesLines();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetItemCrossReferenceUpgradeTag());
    end;

    var
        EnvironmentInformation: Codeunit "Environment Information";
        NoOfRecordsInTableMsg: Label 'Table %1, number of records to upgrade: %2', Comment = '%1- table id, %2 - number of records';

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

    local procedure ConvertCrossRefTypeToItemRefType(CrossReferenceType: Option): Enum "Item Reference Type"
    var
        ItemCrossReference: Record "Item Cross Reference";
    begin
        case CrossReferenceType of
            ItemCrossReference."Cross-Reference Type"::" ":
                exit("Item Reference Type"::" ");
            ItemCrossReference."Cross-Reference Type"::Customer:
                exit("Item Reference Type"::Customer);
            ItemCrossReference."Cross-Reference Type"::Vendor:
                exit("Item Reference Type"::Vendor);
            ItemCrossReference."Cross-Reference Type"::"Bar Code":
                exit("Item Reference Type"::"Bar Code");
        end;
    end;

    local procedure LogTelemetryForManyRecords(TableNo: Integer; NoOfRecords: Integer): Boolean;
    begin
        Session.LogMessage(
            '0000G46', StrSubstNo(NoOfRecordsInTableMsg, TableNo, NoOfRecords),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'AL SaaS Upgrade');
        exit(NoOfRecords > GetSafeRecordCountForSaaSUpgrade());
    end;

    local procedure GetSafeRecordCountForSaaSUpgrade(): Integer
    begin
        exit(300000);
    end;

    local procedure UpgradeICInOutPurchLines()
    var
        ICInboxPurchaseLine: Record "IC Inbox Purchase Line";
        ICOutboxPurchaseLine: Record "IC Outbox Purchase Line";
        HandledICInboxPurchLine: Record "Handled IC Inbox Purch. Line";
        HandledICOutboxPurchLine: Record "Handled IC Outbox Purch. Line";
    begin
        ICInboxPurchaseLine.SetLoadFields("IC Partner Reference", "IC Item Reference No.");
        ICInboxPurchaseLine.SetFilter("IC Partner Reference", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            LogTelemetryForManyRecords(Database::"IC Inbox Purchase Line", ICInboxPurchaseLine.Count());
        if ICInboxPurchaseLine.FindSet() then
            repeat
                ICInboxPurchaseLine."IC Item Reference No." := ICInboxPurchaseLine."IC Partner Reference";
                ICInboxPurchaseLine.Modify();
            until ICInboxPurchaseLine.Next() = 0;

        ICOutboxPurchaseLine.SetLoadFields("IC Partner Reference", "IC Item Reference No.");
        ICOutboxPurchaseLine.SetFilter("IC Partner Reference", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            LogTelemetryForManyRecords(Database::"IC Outbox Purchase Line", ICOutboxPurchaseLine.Count());
        if ICOutboxPurchaseLine.FindSet() then
            repeat
                ICOutboxPurchaseLine."IC Item Reference No." := ICOutboxPurchaseLine."IC Partner Reference";
                ICOutboxPurchaseLine.Modify();
            until ICOutboxPurchaseLine.Next() = 0;

        HandledICInboxPurchLine.SetLoadFields("IC Partner Reference", "IC Item Reference No.");
        HandledICInboxPurchLine.SetFilter("IC Partner Reference", '<>%1', '');
        if not EnvironmentInformation.IsSaaS() or
            not LogTelemetryForManyRecords(Database::"Handled IC Inbox Purch. Line", HandledICInboxPurchLine.Count())
        then
            if HandledICInboxPurchLine.FindSet() then
                repeat
                    HandledICInboxPurchLine."IC Item Reference No." := HandledICInboxPurchLine."IC Partner Reference";
                    HandledICInboxPurchLine.Modify();
                until HandledICInboxPurchLine.Next() = 0;

        HandledICOutboxPurchLine.SetLoadFields("IC Partner Reference", "IC Item Reference No.");
        HandledICOutboxPurchLine.SetFilter("IC Partner Reference", '<>%1', '');
        if not EnvironmentInformation.IsSaaS() or
             not LogTelemetryForManyRecords(Database::"Handled IC Outbox Purch. Line", HandledICOutboxPurchLine.Count())
        then
            if HandledICOutboxPurchLine.FindSet() then
                repeat
                    HandledICOutboxPurchLine."IC Item Reference No." := HandledICOutboxPurchLine."IC Partner Reference";
                    HandledICOutboxPurchLine.Modify();
                until HandledICOutboxPurchLine.Next() = 0;
    end;

    local procedure UpgradeICInOutSalesLines()
    var
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
        HandledICInboxSalesLine: Record "Handled IC Inbox Sales Line";
        HandledICOutboxSalesLine: Record "Handled IC Outbox Sales Line";
    begin
        ICInboxSalesLine.SetLoadFields("IC Partner Reference", "IC Item Reference No.");
        ICInboxSalesLine.SetFilter("IC Partner Reference", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            LogTelemetryForManyRecords(Database::"IC Inbox Sales Line", ICInboxSalesLine.Count());
        if ICInboxSalesLine.FindSet() then
            repeat
                ICInboxSalesLine."IC Item Reference No." := ICInboxSalesLine."IC Partner Reference";
                ICInboxSalesLine.Modify();
            until ICInboxSalesLine.Next() = 0;

        ICOutboxSalesLine.SetLoadFields("IC Partner Reference", "IC Item Reference No.");
        ICOutboxSalesLine.SetFilter("IC Partner Reference", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            LogTelemetryForManyRecords(Database::"IC Outbox Sales Line", ICOutboxSalesLine.Count());
        if ICOutboxSalesLine.FindSet() then
            repeat
                ICOutboxSalesLine."IC Item Reference No." := ICOutboxSalesLine."IC Partner Reference";
                ICOutboxSalesLine.Modify();
            until ICOutboxSalesLine.Next() = 0;

        HandledICInboxSalesLine.SetLoadFields("IC Partner Reference", "IC Item Reference No.");
        HandledICInboxSalesLine.SetFilter("IC Partner Reference", '<>%1', '');
        if not EnvironmentInformation.IsSaaS() or
            not LogTelemetryForManyRecords(Database::"Handled IC Inbox Sales Line", HandledICInboxSalesLine.Count())
        then
            if HandledICInboxSalesLine.FindSet() then
                repeat
                    HandledICInboxSalesLine."IC Item Reference No." := HandledICInboxSalesLine."IC Partner Reference";
                    HandledICInboxSalesLine.Modify();
                until HandledICInboxSalesLine.Next() = 0;

        HandledICOutboxSalesLine.SetLoadFields("IC Partner Reference", "IC Item Reference No.");
        HandledICOutboxSalesLine.SetFilter("IC Partner Reference", '<>%1', '');
        if not EnvironmentInformation.IsSaaS() or
            not LogTelemetryForManyRecords(Database::"Handled IC Outbox Sales Line", HandledICOutboxSalesLine.Count())
        then
            if HandledICOutboxSalesLine.FindSet() then
                repeat
                    HandledICOutboxSalesLine."IC Item Reference No." := HandledICOutboxSalesLine."IC Partner Reference";
                    HandledICOutboxSalesLine.Modify();
                until HandledICOutboxSalesLine.Next() = 0;
    end;

    local procedure UpgradePurchaseLine()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetLoadFields(
            "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Unit of Measure (Cross Ref.)",
            "IC Partner Ref. Type", "IC Partner Reference", "IC Item Reference No.",
            "Item Reference No.", "Item Reference Type", "Item Reference Type No.", "Item Reference Unit of Measure");
        PurchaseLine.SetFilter("Cross-Reference No.", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            LogTelemetryForManyRecords(Database::"Purchase Line", PurchaseLine.Count());
        if PurchaseLine.FindSet() then
            repeat
                PurchaseLine."Item Reference No." := PurchaseLine."Cross-Reference No.";
                PurchaseLine."Item Reference Type" := ConvertCrossRefTypeToItemRefType(PurchaseLine."Cross-Reference Type");
                PurchaseLine."Item Reference Type No." := PurchaseLine."Cross-Reference Type No.";
                PurchaseLine."Item Reference Unit of Measure" := PurchaseLine."Unit of Measure (Cross Ref.)";
                PurchaseLine."Cross-Reference Type" := 0;
                PurchaseLine."Cross-Reference Type No." := '';
                PurchaseLine."Unit of Measure (Cross Ref.)" := '';
                if PurchaseLine."IC Partner Ref. Type" = PurchaseLine."IC Partner Ref. Type"::"Cross Reference" then
                    PurchaseLine."IC Item Reference No." := PurchaseLine."IC Partner Reference";
                PurchaseLine.Modify();
            until PurchaseLine.Next() = 0;
    end;

    local procedure UpgradePurchaseLineArchive()
    var
        PurchaseLineArchive: Record "Purchase Line Archive";
    begin
        PurchaseLineArchive.SetLoadFields(
            "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Unit of Measure (Cross Ref.)",
            "IC Partner Ref. Type", "IC Partner Reference", "IC Item Reference No.",
            "Item Reference No.", "Item Reference Type", "Item Reference Type No.", "Item Reference Unit of Measure");
        PurchaseLineArchive.SetFilter("Cross-Reference No.", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            if LogTelemetryForManyRecords(Database::"Purchase Line Archive", PurchaseLineArchive.Count()) then
                exit;
        if PurchaseLineArchive.FindSet() then
            repeat
                PurchaseLineArchive."Item Reference No." := PurchaseLineArchive."Cross-Reference No.";
                PurchaseLineArchive."Item Reference Type" := ConvertCrossRefTypeToItemRefType(PurchaseLineArchive."Cross-Reference Type");
                PurchaseLineArchive."Item Reference Type No." := PurchaseLineArchive."Cross-Reference Type No.";
                PurchaseLineArchive."Item Reference Unit of Measure" := PurchaseLineArchive."Unit of Measure (Cross Ref.)";
                PurchaseLineArchive."Cross-Reference Type" := 0;
                PurchaseLineArchive."Cross-Reference Type No." := '';
                PurchaseLineArchive."Unit of Measure (Cross Ref.)" := '';
                if PurchaseLineArchive."IC Partner Ref. Type" = PurchaseLineArchive."IC Partner Ref. Type"::"Cross Reference" then
                    PurchaseLineArchive."IC Item Reference No." := PurchaseLineArchive."IC Partner Reference";
                PurchaseLineArchive.Modify();
            until PurchaseLineArchive.Next() = 0;
    end;

    local procedure UpgradePurchCrMemoLine()
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetLoadFields(
            "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Unit of Measure (Cross Ref.)",
            "IC Partner Ref. Type", "IC Partner Reference", "IC Item Reference No.",
            "Item Reference No.", "Item Reference Type", "Item Reference Type No.", "Item Reference Unit of Measure");
        PurchCrMemoLine.SetFilter("Cross-Reference No.", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            if LogTelemetryForManyRecords(Database::"Purch. Cr. Memo Line", PurchCrMemoLine.Count()) then
                exit;
        if PurchCrMemoLine.FindSet() then
            repeat
                PurchCrMemoLine."Item Reference No." := PurchCrMemoLine."Cross-Reference No.";
                PurchCrMemoLine."Item Reference Type" := ConvertCrossRefTypeToItemRefType(PurchCrMemoLine."Cross-Reference Type");
                PurchCrMemoLine."Item Reference Type No." := PurchCrMemoLine."Cross-Reference Type No.";
                PurchCrMemoLine."Item Reference Unit of Measure" := PurchCrMemoLine."Unit of Measure (Cross Ref.)";
                PurchCrMemoLine."Cross-Reference Type" := 0;
                PurchCrMemoLine."Cross-Reference Type No." := '';
                PurchCrMemoLine."Unit of Measure (Cross Ref.)" := '';
                if PurchCrMemoLine."IC Partner Ref. Type" = PurchCrMemoLine."IC Partner Ref. Type"::"Cross Reference" then
                    PurchCrMemoLine."IC Item Reference No." := PurchCrMemoLine."IC Partner Reference";
                PurchCrMemoLine.Modify();
            until PurchCrMemoLine.Next() = 0;
    end;

    local procedure UpgradePurchInvLine()
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetLoadFields(
            "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Unit of Measure (Cross Ref.)",
            "IC Partner Ref. Type", "IC Partner Reference", "IC Cross-Reference No.",
            "Item Reference No.", "Item Reference Type", "Item Reference Type No.", "Item Reference Unit of Measure");
        PurchInvLine.SetFilter("Cross-Reference No.", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            if LogTelemetryForManyRecords(Database::"Purch. Inv. Line", PurchInvLine.Count()) then
                exit;
        if PurchInvLine.FindSet() then
            repeat
                PurchInvLine."Item Reference No." := PurchInvLine."Cross-Reference No.";
                PurchInvLine."Item Reference Type" := ConvertCrossRefTypeToItemRefType(PurchInvLine."Cross-Reference Type");
                PurchInvLine."Item Reference Type No." := PurchInvLine."Cross-Reference Type No.";
                PurchInvLine."Item Reference Unit of Measure" := PurchInvLine."Unit of Measure (Cross Ref.)";
                PurchInvLine."Cross-Reference Type" := 0;
                PurchInvLine."Cross-Reference Type No." := '';
                PurchInvLine."Unit of Measure (Cross Ref.)" := '';
                if PurchInvLine."IC Partner Ref. Type" = PurchInvLine."IC Partner Ref. Type"::"Cross Reference" then
                    PurchInvLine."IC Cross-Reference No." := PurchInvLine."IC Partner Reference";
                PurchInvLine.Modify();
            until PurchInvLine.Next() = 0;
    end;

    local procedure UpgradePurchRcptLine()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetLoadFields(
            "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Unit of Measure (Cross Ref.)",
            "IC Partner Ref. Type", "IC Partner Reference", "IC Item Reference No.",
            "Item Reference No.", "Item Reference Type", "Item Reference Type No.", "Item Reference Unit of Measure");
        PurchRcptLine.SetFilter("Cross-Reference No.", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            if LogTelemetryForManyRecords(Database::"Purch. Rcpt. Line", PurchRcptLine.Count()) then
                exit;
        if PurchRcptLine.FindSet() then
            repeat
                PurchRcptLine."Item Reference No." := PurchRcptLine."Cross-Reference No.";
                PurchRcptLine."Item Reference Type" := ConvertCrossRefTypeToItemRefType(PurchRcptLine."Cross-Reference Type");
                PurchRcptLine."Item Reference Type No." := PurchRcptLine."Cross-Reference Type No.";
                PurchRcptLine."Item Reference Unit of Measure" := PurchRcptLine."Unit of Measure (Cross Ref.)";
                PurchRcptLine."Cross-Reference Type" := 0;
                PurchRcptLine."Cross-Reference Type No." := '';
                PurchRcptLine."Unit of Measure (Cross Ref.)" := '';
                if PurchRcptLine."IC Partner Ref. Type" = PurchRcptLine."IC Partner Ref. Type"::"Cross Reference" then
                    PurchRcptLine."IC Item Reference No." := PurchRcptLine."IC Partner Reference";
                PurchRcptLine.Modify();
            until PurchRcptLine.Next() = 0;
    end;

    local procedure UpgradeReturnReceiptLine()
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ReturnReceiptLine.SetLoadFields(
            "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Unit of Measure (Cross Ref.)",
            "Item Reference No.", "Item Reference Type", "Item Reference Type No.", "Item Reference Unit of Measure");
        ReturnReceiptLine.SetFilter("Cross-Reference No.", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            if LogTelemetryForManyRecords(Database::"Return Receipt Line", ReturnReceiptLine.Count()) then
                exit;
        if ReturnReceiptLine.FindSet() then
            repeat
                ReturnReceiptLine."Item Reference No." := ReturnReceiptLine."Cross-Reference No.";
                ReturnReceiptLine."Item Reference Type" := ConvertCrossRefTypeToItemRefType(ReturnReceiptLine."Cross-Reference Type");
                ReturnReceiptLine."Item Reference Type No." := ReturnReceiptLine."Cross-Reference Type No.";
                ReturnReceiptLine."Item Reference Unit of Measure" := ReturnReceiptLine."Unit of Measure (Cross Ref.)";
                ReturnReceiptLine."Cross-Reference Type" := 0;
                ReturnReceiptLine."Cross-Reference Type No." := '';
                ReturnReceiptLine."Unit of Measure (Cross Ref.)" := '';
                ReturnReceiptLine.Modify();
            until ReturnReceiptLine.Next() = 0;
    end;

    local procedure UpgradeReturnShipmentLine()
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        ReturnShipmentLine.SetLoadFields(
            "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Unit of Measure (Cross Ref.)",
            "Item Reference No.", "Item Reference Type", "Item Reference Type No.", "Item Reference Unit of Measure");
        ReturnShipmentLine.SetFilter("Cross-Reference No.", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            if LogTelemetryForManyRecords(Database::"Return Shipment Line", ReturnShipmentLine.Count()) then
                exit;
        if ReturnShipmentLine.FindSet() then
            repeat
                ReturnShipmentLine."Item Reference No." := ReturnShipmentLine."Cross-Reference No.";
                ReturnShipmentLine."Item Reference Type" := ConvertCrossRefTypeToItemRefType(ReturnShipmentLine."Cross-Reference Type");
                ReturnShipmentLine."Item Reference Type No." := ReturnShipmentLine."Cross-Reference Type No.";
                ReturnShipmentLine."Item Reference Unit of Measure" := ReturnShipmentLine."Unit of Measure (Cross Ref.)";
                ReturnShipmentLine."Cross-Reference Type" := 0;
                ReturnShipmentLine."Cross-Reference Type No." := '';
                ReturnShipmentLine."Unit of Measure (Cross Ref.)" := '';
                ReturnShipmentLine.Modify();
            until ReturnShipmentLine.Next() = 0;
    end;

    local procedure UpgradeSalesLine()
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetLoadFields(
            "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Unit of Measure (Cross Ref.)",
            "IC Partner Ref. Type", "IC Partner Reference", "IC Item Reference No.",
            "Item Reference No.", "Item Reference Type", "Item Reference Type No.", "Item Reference Unit of Measure");
        SalesLine.SetFilter("Cross-Reference No.", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            LogTelemetryForManyRecords(Database::"Sales Line", SalesLine.Count());
        if SalesLine.FindSet() then
            repeat
                SalesLine."Item Reference No." := SalesLine."Cross-Reference No.";
                SalesLine."Item Reference Type" := ConvertCrossRefTypeToItemRefType(SalesLine."Cross-Reference Type");
                SalesLine."Item Reference Type No." := SalesLine."Cross-Reference Type No.";
                SalesLine."Item Reference Unit of Measure" := SalesLine."Unit of Measure (Cross Ref.)";
                SalesLine."Cross-Reference Type" := 0;
                SalesLine."Cross-Reference Type No." := '';
                SalesLine."Unit of Measure (Cross Ref.)" := '';
                if SalesLine."IC Partner Ref. Type" = SalesLine."IC Partner Ref. Type"::"Cross Reference" then
                    SalesLine."IC Item Reference No." := SalesLine."IC Partner Reference";
                SalesLine.Modify();
            until SalesLine.Next() = 0;
    end;

    local procedure UpgradeSalesLineArchive()
    var
        SalesLineArchive: Record "Sales Line Archive";
    begin
        SalesLineArchive.SetLoadFields(
            "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Unit of Measure (Cross Ref.)",
            "IC Partner Ref. Type", "IC Partner Reference", "IC Item Reference No.",
            "Item Reference No.", "Item Reference Type", "Item Reference Type No.", "Item Reference Unit of Measure");
        SalesLineArchive.SetFilter("Cross-Reference No.", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            if LogTelemetryForManyRecords(Database::"Sales Line Archive", SalesLineArchive.Count()) then
                exit;
        if SalesLineArchive.FindSet() then
            repeat
                SalesLineArchive."Item Reference No." := SalesLineArchive."Cross-Reference No.";
                SalesLineArchive."Item Reference Type" := ConvertCrossRefTypeToItemRefType(SalesLineArchive."Cross-Reference Type");
                SalesLineArchive."Item Reference Type No." := SalesLineArchive."Cross-Reference Type No.";
                SalesLineArchive."Item Reference Unit of Measure" := SalesLineArchive."Unit of Measure (Cross Ref.)";
                SalesLineArchive."Cross-Reference Type" := 0;
                SalesLineArchive."Cross-Reference Type No." := '';
                SalesLineArchive."Unit of Measure (Cross Ref.)" := '';
                if SalesLineArchive."IC Partner Ref. Type" = SalesLineArchive."IC Partner Ref. Type"::"Cross Reference" then
                    SalesLineArchive."IC Item Reference No." := SalesLineArchive."IC Partner Reference";
                SalesLineArchive.Modify();
            until SalesLineArchive.Next() = 0;
    end;

    local procedure UpgradeSalesShipmentLine()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetLoadFields(
            "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Unit of Measure (Cross Ref.)",
            "IC Partner Ref. Type", "IC Partner Reference", "IC Item Reference No.",
            "Item Reference No.", "Item Reference Type", "Item Reference Type No.", "Item Reference Unit of Measure");
        SalesShipmentLine.SetFilter("Cross-Reference No.", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            if LogTelemetryForManyRecords(Database::"Sales Shipment Line", SalesShipmentLine.Count()) then
                exit;
        if SalesShipmentLine.FindSet() then
            repeat
                SalesShipmentLine."Item Reference No." := SalesShipmentLine."Cross-Reference No.";
                SalesShipmentLine."Item Reference Type" := ConvertCrossRefTypeToItemRefType(SalesShipmentLine."Cross-Reference Type");
                SalesShipmentLine."Item Reference Type No." := SalesShipmentLine."Cross-Reference Type No.";
                SalesShipmentLine."Item Reference Unit of Measure" := SalesShipmentLine."Unit of Measure (Cross Ref.)";
                SalesShipmentLine."Cross-Reference Type" := 0;
                SalesShipmentLine."Cross-Reference Type No." := '';
                SalesShipmentLine."Unit of Measure (Cross Ref.)" := '';
                if SalesShipmentLine."IC Partner Ref. Type" = SalesShipmentLine."IC Partner Ref. Type"::"Cross Reference" then
                    SalesShipmentLine."IC Item Reference No." := SalesShipmentLine."IC Partner Reference";
                SalesShipmentLine.Modify();
            until SalesShipmentLine.Next() = 0;
    end;

    local procedure UpgradeSalesCrMemoLine()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetLoadFields(
            "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Unit of Measure (Cross Ref.)",
            "IC Partner Ref. Type", "IC Partner Reference", "IC Item Reference No.",
            "Item Reference No.", "Item Reference Type", "Item Reference Type No.", "Item Reference Unit of Measure");
        SalesCrMemoLine.SetFilter("Cross-Reference No.", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            if LogTelemetryForManyRecords(Database::"Sales Cr.Memo Line", SalesCrMemoLine.Count()) then
                exit;
        if SalesCrMemoLine.FindSet() then
            repeat
                SalesCrMemoLine."Item Reference No." := SalesCrMemoLine."Cross-Reference No.";
                SalesCrMemoLine."Item Reference Type" := ConvertCrossRefTypeToItemRefType(SalesCrMemoLine."Cross-Reference Type");
                SalesCrMemoLine."Item Reference Type No." := SalesCrMemoLine."Cross-Reference Type No.";
                SalesCrMemoLine."Item Reference Unit of Measure" := SalesCrMemoLine."Unit of Measure (Cross Ref.)";
                SalesCrMemoLine."Cross-Reference Type" := 0;
                SalesCrMemoLine."Cross-Reference Type No." := '';
                SalesCrMemoLine."Unit of Measure (Cross Ref.)" := '';
                if SalesCrMemoLine."IC Partner Ref. Type" = SalesCrMemoLine."IC Partner Ref. Type"::"Cross Reference" then
                    SalesCrMemoLine."IC Item Reference No." := SalesCrMemoLine."IC Partner Reference";
                SalesCrMemoLine.Modify();
            until SalesCrMemoLine.Next() = 0;
    end;

    local procedure UpgradeSalesInvoiceLine()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetLoadFields(
            "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Unit of Measure (Cross Ref.)",
            "IC Partner Ref. Type", "IC Partner Reference", "IC Item Reference No.",
            "Item Reference No.", "Item Reference Type", "Item Reference Type No.", "Item Reference Unit of Measure");
        SalesInvoiceLine.SetFilter("Cross-Reference No.", '<>%1', '');
        if EnvironmentInformation.IsSaaS() then
            if LogTelemetryForManyRecords(Database::"Sales Invoice Line", SalesInvoiceLine.Count()) then
                exit;
        if SalesInvoiceLine.FindSet() then
            repeat
                SalesInvoiceLine."Item Reference No." := SalesInvoiceLine."Cross-Reference No.";
                SalesInvoiceLine."Item Reference Type" := ConvertCrossRefTypeToItemRefType(SalesInvoiceLine."Cross-Reference Type");
                SalesInvoiceLine."Item Reference Type No." := SalesInvoiceLine."Cross-Reference Type No.";
                SalesInvoiceLine."Item Reference Unit of Measure" := SalesInvoiceLine."Unit of Measure (Cross Ref.)";
                SalesInvoiceLine."Cross-Reference Type" := 0;
                SalesInvoiceLine."Cross-Reference Type No." := '';
                SalesInvoiceLine."Unit of Measure (Cross Ref.)" := '';
                if SalesInvoiceLine."IC Partner Ref. Type" = SalesInvoiceLine."IC Partner Ref. Type"::"Cross Reference" then
                    SalesInvoiceLine."IC Item Reference No." := SalesInvoiceLine."IC Partner Reference";
                SalesInvoiceLine.Modify();
            until SalesInvoiceLine.Next() = 0;
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