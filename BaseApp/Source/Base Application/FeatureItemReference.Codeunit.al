/// <summary>
/// Replaces "Item Cross Reference" data with "Item Reference" on enabling the Item Reference feature
/// </summary>
Codeunit 5721 "Feature - Item Reference" implements "Feature Data Update"
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

    procedure IsDataUpdateRequired(): Boolean;
    begin
        CountRecords();
        exit(not TempDocumentEntry.IsEmpty);
    end;

    procedure ReviewData();
    var
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        Commit();
        Clear(DataUpgradeOverview);
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status");
    var
        StartDateTime: DateTime;
    begin
#if not CLEAN16
        if ItemCrossReference.IsEmpty() then
            exit;

        if not ItemReference.IsEmpty() then
            exit;

        StartDateTime := CurrentDateTime;
        ItemCrossReference.FindSet();
        repeat
            ItemReference.Init();
            ItemReference.TransferFields(ItemCrossReference, true);
            ItemReference.SystemId := ItemCrossReference.SystemId;
            if ItemReference.Insert(false, true) then;
        until ItemCrossReference.Next() = 0;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ItemReference.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        ItemLedgerEntry.SetFilter("Cross-Reference No.", '<>%1', '');
        if ItemLedgerEntry.FindSet() then
            repeat
                ItemLedgerEntry."Item Reference No." := ItemLedgerEntry."Cross-Reference No.";
                ItemLedgerEntry.Modify();
            until ItemLedgerEntry.Next() = 0;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ItemLedgerEntry.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        ItemJournalLine.SetFilter("Cross-Reference No.", '<>%1', '');
        if ItemJournalLine.FindSet() then
            repeat
                ItemJournalLine."Item Reference No." := ItemJournalLine."Cross-Reference No.";
                ItemJournalLine.Modify();
            until ItemJournalLine.Next() = 0;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ItemJournalLine.TableCaption(), StartDateTime);

        UpgradePurchaseLines(FeatureDataUpdateStatus);

        UpgradeSalesLines(FeatureDataUpdateStatus);
#endif
    end;

    procedure GetTaskDescription() TaskDescription: Text;
    begin
        TaskDescription := StrSubstNo(DescrTok, Description1Txt, Description2Txt);
    end;

    var
#if not CLEAN16
        ItemCrossReference: Record "Item Cross Reference";
#endif
        ItemReference: Record "Item Reference";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ICInboxPurchaseLine: Record "IC Inbox Purchase Line";
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        ICOutboxPurchaseLine: Record "IC Outbox Purchase Line";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
        HandledICInboxPurchLine: Record "Handled IC Inbox Purch. Line";
        HandledICInboxSalesLine: Record "Handled IC Inbox Sales Line";
        HandledICOutboxPurchLine: Record "Handled IC Outbox Purch. Line";
        HandledICOutboxSalesLine: Record "Handled IC Outbox Sales Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineArchive: Record "Purchase Line Archive";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        SalesLine: Record "Sales Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLineArchive: Record "Sales Line Archive";
        SalesShipmentLine: Record "Sales Shipment Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        TempDocumentEntry: Record "Document Entry" temporary;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        LastEntryNo: Integer;
        Description1Txt: Label 'If you use item cross references, data from Cross-Reference No. field will be copied to a new Item Reference No. field.';
        Description2Txt: Label 'If you use intercompany, data from the IC Partner Reference field for item cross references will be moved to new IC Item Reference No. field.';
        DescrTok: Label '%1 %2', Locked = true;

    local procedure CountRecords()
    begin
#if not CLEAN16
        TempDocumentEntry.DeleteAll();
        InsertDocumentEntry(Database::"Item Cross Reference", ItemCrossReference.TableCaption, ItemCrossReference.CountApprox);
        ItemLedgerEntry.SetFilter("Cross-Reference No.", '<>%1', '');
        InsertDocumentEntry(Database::"Item Ledger Entry", ItemLedgerEntry.TableCaption, ItemLedgerEntry.CountApprox);
        ItemJournalLine.SetFilter("Cross-Reference No.", '<>%1', '');
        InsertDocumentEntry(Database::"Item Journal Line", ItemJournalLine.TableCaption, ItemJournalLine.CountApprox);

        PurchaseLine.SetFilter("Cross-Reference No.", '<>%1', '');
        InsertDocumentEntry(Database::"Purchase Line", PurchaseLine.TableCaption, PurchaseLine.CountApprox);
        PurchaseLineArchive.SetFilter("Cross-Reference No.", '<>%1', '');
        InsertDocumentEntry(Database::"Purchase Line Archive", PurchaseLineArchive.TableCaption, PurchaseLineArchive.CountApprox);
        PurchRcptLine.SetFilter("Cross-Reference No.", '<>%1', '');
        InsertDocumentEntry(Database::"Purch. Rcpt. Line", PurchRcptLine.TableCaption, PurchRcptLine.CountApprox);
        PurchInvLine.SetFilter("Cross-Reference No.", '<>%1', '');
        InsertDocumentEntry(Database::"Purch. Inv. Line", PurchInvLine.TableCaption, PurchInvLine.CountApprox);
        PurchCrMemoLine.SetFilter("Cross-Reference No.", '<>%1', '');
        InsertDocumentEntry(Database::"Purch. Cr. Memo Line", PurchCrMemoLine.TableCaption, PurchCrMemoLine.CountApprox);
        ReturnShipmentLine.SetFilter("Cross-Reference No.", '<>%1', '');
        InsertDocumentEntry(Database::"Return Shipment Line", ReturnShipmentLine.TableCaption, ReturnShipmentLine.CountApprox);

        ICInboxPurchaseLine.SetRange("IC Partner Ref. Type", "IC Partner Reference Type"::"Cross Reference");
        ICInboxPurchaseLine.SetFilter("IC Partner Reference", '<>%1', '');
        InsertDocumentEntry(Database::"IC Inbox Purchase Line", ICInboxPurchaseLine.TableCaption, ICInboxPurchaseLine.CountApprox);
        ICOutboxPurchaseLine.SetRange("IC Partner Ref. Type", "IC Partner Reference Type"::"Cross Reference");
        ICOutboxPurchaseLine.SetFilter("IC Partner Reference", '<>%1', '');
        InsertDocumentEntry(Database::"IC Outbox Purchase Line", ICOutboxPurchaseLine.TableCaption, ICOutboxPurchaseLine.CountApprox);

        HandledICInboxPurchLine.SetRange("IC Partner Ref. Type", "IC Partner Reference Type"::"Cross Reference");
        HandledICInboxPurchLine.SetFilter("IC Partner Reference", '<>%1', '');
        InsertDocumentEntry(Database::"Handled IC Inbox Purch. Line", HandledICInboxPurchLine.TableCaption, HandledICInboxPurchLine.CountApprox);
        HandledICOutboxPurchLine.SetRange("IC Partner Ref. Type", "IC Partner Reference Type"::"Cross Reference");
        HandledICOutboxPurchLine.SetFilter("IC Partner Reference", '<>%1', '');
        InsertDocumentEntry(Database::"Handled IC Outbox Purch. Line", HandledICOutboxPurchLine.TableCaption, handledICOutboxPurchLine.CountApprox);

        SalesLine.SetFilter("Cross-Reference No.", '<>%1', '');
        InsertDocumentEntry(Database::"Sales Line", SalesLine.TableCaption, SalesLine.CountApprox);
        SalesLineArchive.SetFilter("Cross-Reference No.", '<>%1', '');
        InsertDocumentEntry(Database::"Sales Line Archive", SalesLineArchive.TableCaption, SalesLineArchive.CountApprox);
        SalesShipmentLine.SetFilter("Cross-Reference No.", '<>%1', '');
        InsertDocumentEntry(Database::"Sales Shipment Line", SalesShipmentLine.TableCaption, SalesShipmentLine.CountApprox);
        SalesInvoiceLine.SetFilter("Cross-Reference No.", '<>%1', '');
        InsertDocumentEntry(Database::"Sales Invoice Line", SalesInvoiceLine.TableCaption, SalesInvoiceLine.CountApprox);
        SalesCrMemoLine.SetFilter("Cross-Reference No.", '<>%1', '');
        InsertDocumentEntry(Database::"Sales Cr.Memo Line", SalesCrMemoLine.TableCaption, SalesCrMemoLine.CountApprox);
        ReturnReceiptLine.SetFilter("Cross-Reference No.", '<>%1', '');
        InsertDocumentEntry(Database::"Return Receipt Line", ReturnReceiptLine.TableCaption, ReturnReceiptLine.CountApprox);

        ICInboxSalesLine.SetRange("IC Partner Ref. Type", "IC Partner Reference Type"::"Cross Reference");
        ICInboxSalesLine.SetFilter("IC Partner Reference", '<>%1', '');
        InsertDocumentEntry(Database::"IC Inbox Sales Line", ICInboxSalesLine.TableCaption, ICInboxSalesLine.CountApprox);
        ICOutboxSalesLine.SetRange("IC Partner Ref. Type", "IC Partner Reference Type"::"Cross Reference");
        ICOutboxSalesLine.SetFilter("IC Partner Reference", '<>%1', '');
        InsertDocumentEntry(Database::"IC Outbox Sales Line", ICOutboxSalesLine.TableCaption, ICOutboxSalesLine.CountApprox);

        HandledICInboxSalesLine.SetRange("IC Partner Ref. Type", "IC Partner Reference Type"::"Cross Reference");
        HandledICInboxSalesLine.SetFilter("IC Partner Reference", '<>%1', '');
        InsertDocumentEntry(Database::"Handled IC Inbox Sales Line", HandledICInboxSalesLine.TableCaption, HandledICInboxSalesLine.CountApprox);
        HandledICOutboxSalesLine.SetRange("IC Partner Ref. Type", "IC Partner Reference Type"::"Cross Reference");
        HandledICOutboxSalesLine.SetFilter("IC Partner Reference", '<>%1', '');
        InsertDocumentEntry(Database::"Handled IC Outbox Sales Line", HandledICOutboxSalesLine.TableCaption, handledICOutboxSalesLine.CountApprox);
#endif

        OnAfterCountRecords(TempDocumentEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCountRecords(var TempDocumentEntry: Record "Document Entry" temporary)
    begin
    end;

    local procedure InsertDocumentEntry(TableID: Integer; TableName: Text; RecordCount: Integer)
    begin
        if RecordCount = 0 then
            exit;

        LastEntryNo += 1;
        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." := LastEntryNo;
        TempDocumentEntry."Table ID" := TableID;
        TempDocumentEntry."Table Name" := CopyStr(TableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecordCount;
        TempDocumentEntry.Insert();
    end;

#if not CLEAN16
    local procedure UpgradePurchaseLines(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
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
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, PurchaseLine.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
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
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, PurchaseLineArchive.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
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
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, PurchRcptLine.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
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
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, PurchInvLine.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
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
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, PurchCrMemoLine.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
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
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ReturnShipmentLine.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        if ICInboxPurchaseLine.FindSet() then
            repeat
                ICInboxPurchaseLine."IC Item Reference No." := ICInboxPurchaseLine."IC Partner Reference";
                ICInboxPurchaseLine.Modify();
            until ICInboxPurchaseLine.Next() = 0;

        if ICOutboxPurchaseLine.FindSet() then
            repeat
                ICOutboxPurchaseLine."IC Item Reference No." := ICOutboxPurchaseLine."IC Partner Reference";
                ICOutboxPurchaseLine.Modify();
            until ICOutboxPurchaseLine.Next() = 0;

        if HandledICInboxPurchLine.FindSet() then
            repeat
                HandledICInboxPurchLine."IC Item Reference No." := HandledICInboxPurchLine."IC Partner Reference";
                HandledICInboxPurchLine.Modify();
            until HandledICInboxPurchLine.Next() = 0;

        if HandledICOutboxPurchLine.FindSet() then
            repeat
                HandledICOutboxPurchLine."IC Item Reference No." := HandledICOutboxPurchLine."IC Partner Reference";
                HandledICOutboxPurchLine.Modify();
            until HandledICOutboxPurchLine.Next() = 0;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ICInboxPurchaseLine.FieldCaption("IC Partner Reference"), StartDateTime);
    end;
#endif

#if not CLEAN16
    local procedure UpgradeSalesLines(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
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
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, SalesLine.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
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
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, SalesLineArchive.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
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
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, SalesShipmentLine.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
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
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, SalesInvoiceLine.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
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
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, SalesCrMemoLine.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
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
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ReturnReceiptLine.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        if ICInboxSalesLine.FindSet() then
            repeat
                ICInboxSalesLine."IC Item Reference No." := ICInboxSalesLine."IC Partner Reference";
                ICInboxSalesLine.Modify();
            until ICInboxSalesLine.Next() = 0;

        if ICOutboxSalesLine.FindSet() then
            repeat
                ICOutboxSalesLine."IC Item Reference No." := ICOutboxSalesLine."IC Partner Reference";
                ICOutboxSalesLine.Modify();
            until ICOutboxSalesLine.Next() = 0;

        if HandledICInboxSalesLine.FindSet() then
            repeat
                HandledICInboxSalesLine."IC Item Reference No." := HandledICInboxSalesLine."IC Partner Reference";
                HandledICInboxSalesLine.Modify();
            until HandledICInboxSalesLine.Next() = 0;

        if HandledICOutboxSalesLine.FindSet() then
            repeat
                HandledICOutboxSalesLine."IC Item Reference No." := HandledICOutboxSalesLine."IC Partner Reference";
                HandledICOutboxSalesLine.Modify();
            until HandledICOutboxSalesLine.Next() = 0;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ICInboxSalesLine.FieldCaption("IC Partner Reference"), StartDateTime);
    end;
#endif

#if not CLEAN16
    local procedure ConvertCrossRefTypeToItemRefType(CrossReferenceType: Option): Enum "Item Reference Type"
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
#endif
}