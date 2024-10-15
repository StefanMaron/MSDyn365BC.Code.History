codeunit 143010 "Library - CD Tracking"
{

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LedgerEntryFoundErr: Label '%1  is not found, filters: %2.';
        LedgerEntryQtyErr: Label 'Incorrect quantity for %1, filters: %2.';
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        AvailableQtyToTakeErr: Label 'Available Qty. to Take field is incorrect';
        XEUR: Label 'EUR';
        LibraryRandom: Codeunit "Library - Random";

    [Scope('OnPrem')]
    procedure CreateCDHeaderWithCountryRegion(var CDHeader: Record "CD No. Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.FindFirst;
        CreateCDHeader(CDHeader, CountryRegion.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateCDHeader(var CDHeader: Record "CD No. Header"; CountryCode: Code[10])
    begin
        with CDHeader do begin
            Init;
            "No." :=
              LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"CD No. Header");
            "Country/Region of Origin Code" := CountryCode;
            "Source Type" := "Source Type"::Vendor;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateCDInfo(CDHeader: Record "CD No. Header"; var CDNoInfo: Record "CD No. Information"; Type: Option; No: Code[20]; CDNo: Code[30])
    begin
        if CDNoInfo.Get(Type, No, '', CDNo) then begin
            CDNoInfo."CD Header No." := CDHeader."No.";
            CDNoInfo.Modify;
        end else begin
            CDNoInfo.Init;
            CDNoInfo.Validate(Type, Type);
            CDNoInfo."No." := No;
            CDNoInfo."CD No." := CDNo;
            CDNoInfo."CD Header No." := CDHeader."No.";
            CDNoInfo."Country/Region Code" := CDHeader."Country/Region of Origin Code";
            CDNoInfo.Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateFACDInfo(CDHeader: Record "CD No. Header"; var CDNoInfo: Record "CD No. Information"; FANo: Code[20]; CDNo: Code[30])
    begin
        CreateCDInfo(CDHeader, CDNoInfo, CDNoInfo.Type::"Fixed Asset", FANo, CDNo);
    end;

    [Scope('OnPrem')]
    procedure CreateItemCDInfo(CDHeader: Record "CD No. Header"; var CDNoInfo: Record "CD No. Information"; ItemNo: Code[20]; CDNo: Code[30])
    begin
        CreateCDInfo(CDHeader, CDNoInfo, CDNoInfo.Type::Item, ItemNo, CDNo);
    end;

    [Scope('OnPrem')]
    procedure CreateJnlLine(JnlTemplateName: Code[30]; JnlBatchName: Code[30]; JnlBatchSeries: Code[30]; var ItemJnlLine: Record "Item Journal Line"; EntryType: Option; PostingDate: Date; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10])
    var
        LineNo: Integer;
    begin
        with ItemJnlLine do begin
            SetRange("Journal Template Name", JnlTemplateName);
            SetRange("Journal Batch Name", JnlBatchName);
            if FindLast then;
            LineNo := "Line No." + 10000;

            Init;
            "Journal Template Name" := JnlTemplateName;
            "Journal Batch Name" := JnlBatchName;
            "Line No." := LineNo;
            Insert(true);
            Validate("Posting Date", PostingDate);
            "Document No." := NoSeriesMgt.GetNextNo(JnlBatchSeries, "Posting Date", true);
            Validate("Entry Type", EntryType);
            Validate("Item No.", ItemNo);
            Validate(Quantity, Qty);
            Validate("Location Code", LocationCode);
            Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; EntryType: Option; PostingDate: Date; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10])
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJournalTemplateType: Option Item,Transfer,"Phys. Inventory",Revaluation,Consumption,Output,Capacity,"Prod.Order";
    begin
        FindItemJnlTemplate(ItemJnlTemplate, ItemJournalTemplateType::Item);
        FindItemJnlBatch(ItemJnlBatch, ItemJournalTemplateType, ItemJnlTemplate.Name);
        CreateJnlLine(ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJnlBatch."No. Series",
          ItemJnlLine, EntryType, PostingDate, ItemNo, Qty, LocationCode);
    end;

    [Scope('OnPrem')]
    procedure CreateItemRecLine(var ItemJnlLine: Record "Item Journal Line"; EntryType: Option; PostingDate: Date; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10])
    var
        ItemJnlBatch: Record "Item Journal Batch";
        WhseJnlTemplate: Record "Warehouse Journal Template";
        WhseJnlTemplateType: Option Item,"Physical Inventory",Reclassification;
    begin
        WhseJnlTemplate.SetRange(Type, WhseJnlTemplateType::Reclassification);
        WhseJnlTemplate.FindFirst;
        FindItemJnlBatch(ItemJnlBatch, WhseJnlTemplateType, WhseJnlTemplate.Name);
        CreateJnlLine(WhseJnlTemplate.Name, ItemJnlBatch.Name, ItemJnlBatch."No. Series",
          ItemJnlLine, EntryType, PostingDate, ItemNo, Qty, LocationCode);
    end;

    [Scope('OnPrem')]
    procedure PostItemJnlLine(ItemJnlLine: Record "Item Journal Line")
    var
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    [Scope('OnPrem')]
    procedure FindItemJnlTemplate(var ItemJournalTemplate: Record "Item Journal Template"; ItemJournalTemplateType: Option)
    begin
        // Find Item Journal Template for the given Template Type.
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplateType);
        ItemJournalTemplate.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure FindItemJnlBatch(var ItemJnlBatch: Record "Item Journal Batch"; ItemJnlBatchTemplateType: Option; ItemJnlTemplateName: Code[10])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        // Find Name for Batch Name.
        ItemJnlBatch.SetRange("Template Type", ItemJnlBatchTemplateType);
        ItemJnlBatch.SetRange("Journal Template Name", ItemJnlTemplateName);

        // If Item Journal Batch not found then create it.
        if not ItemJnlBatch.FindFirst then
            CreateItemJnlBatch(ItemJnlBatch, ItemJnlTemplateName);

        if ItemJnlBatch."No. Series" = '' then begin
            LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
            LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
            ItemJnlBatch."No. Series" := NoSeries.Code;
        end;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateItemJnlBatch(var ItemJnlBatch: Record "Item Journal Batch"; ItemJnlTemplateName: Code[10])
    begin
        // Create Item Journal Batch with a random Name of String length less than 10.
        ItemJnlBatch.Init;
        ItemJnlBatch.Validate("Journal Template Name", ItemJnlTemplateName);
        ItemJnlBatch.Validate(
          Name, CopyStr(LibraryUtility.GenerateRandomCode(ItemJnlBatch.FieldNo(Name), DATABASE::"Item Journal Batch"), 1,
            MaxStrLen(ItemJnlBatch.Name)));
        ItemJnlBatch.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchLineTracking(var ReservationEntry: Record "Reservation Entry"; PurchaseLine: Record "Purchase Line"; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; Quantity: Decimal)
    begin
        LibraryItemTracking.CreatePurchOrderItemTracking(
          ReservationEntry,
          PurchaseLine,
          SerialNo,
          LotNo,
          Quantity);

        UpdateCDReservation(ReservationEntry, CDNo);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesLineTracking(var ReservationEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line"; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; Quantity: Decimal)
    begin
        LibraryItemTracking.CreateSalesOrderItemTracking(
          ReservationEntry,
          SalesLine,
          SerialNo,
          LotNo,
          Quantity);

        UpdateCDReservation(ReservationEntry, CDNo);
    end;

    [Scope('OnPrem')]
    procedure CreateItemJnlLineTracking(var ReservationEntry: Record "Reservation Entry"; ItemJnlLine: Record "Item Journal Line"; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; Quantity: Decimal)
    begin
        LibraryItemTracking.CreateItemJournalLineItemTracking(
          ReservationEntry,
          ItemJnlLine,
          SerialNo,
          LotNo,
          Quantity);

        UpdateCDReservation(ReservationEntry, CDNo);
    end;

    [Scope('OnPrem')]
    procedure CreateTransferLineTracking(var ReservationEntry: Record "Reservation Entry"; TransferLine: Record "Transfer Line"; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; Quantity: Decimal)
    begin
        LibraryItemTracking.CreateTransferOrderItemTracking(
          ReservationEntry,
          TransferLine,
          SerialNo,
          LotNo,
          Quantity);

        if ReservationEntry.FindSet then
            repeat
                UpdateCDReservation(ReservationEntry, CDNo);
            until ReservationEntry.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateItemDocumentLineTracking(var ReservationEntry: Record "Reservation Entry"; ItemDocumentLine: Record "Item Document Line"; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; Quantity: Decimal)
    begin
        LibraryItemTracking.CreateItemReceiptItemTracking(
          ReservationEntry,
          ItemDocumentLine,
          SerialNo,
          LotNo,
          Quantity);

        UpdateCDReservation(ReservationEntry, CDNo);
    end;

    [Scope('OnPrem')]
    procedure CreateReclassJnLineTracking(var ReservationEntry: Record "Reservation Entry"; ItemJnlLine: Record "Item Journal Line"; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; Qty: Decimal)
    begin
        LibraryItemTracking.CreateItemReclassJnLineItemTracking(
          ReservationEntry,
          ItemJnlLine,
          SerialNo,
          LotNo,
          Qty);
        UpdateCDReservation(ReservationEntry, CDNo);
    end;

    [Scope('OnPrem')]
    procedure CreateTrackingSpec(var TrackingSpec: Record "Tracking Specification"; var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; LocationCode: Code[10]; QtyBase: Decimal; Description: Text[50]; SourceType: Integer; SourceSubType: Integer; SourceID: Code[20]; SourceRefNo: Integer; CDNo: Code[30])
    var
        NextEntryNo: Integer;
    begin
        TrackingSpec.Reset;
        if TrackingSpec.FindLast then
            NextEntryNo := TrackingSpec."Entry No." + 1
        else
            NextEntryNo := 1;

        TrackingSpec.Init;
        TrackingSpec."Entry No." := NextEntryNo;
        TrackingSpec."Item No." := ItemNo;
        TrackingSpec."Location Code" := LocationCode;
        TrackingSpec."Quantity (Base)" := QtyBase;
        TrackingSpec."Qty. to Handle (Base)" := QtyBase;
        TrackingSpec."Qty. to Invoice (Base)" := QtyBase;
        TrackingSpec.Description := Description;
        TrackingSpec."Source Type" := SourceType;
        TrackingSpec."Source Subtype" := SourceSubType;
        TrackingSpec."Source ID" := SourceID;
        TrackingSpec."Source Ref. No." := SourceRefNo;
        TrackingSpec."CD No." := CDNo;
        TrackingSpec.Insert;

        UpdateCDReservation(ReservationEntry, CDNo);
    end;

    [Scope('OnPrem')]
    procedure CreateFAActHeader(var FADocHeader: Record "FA Document Header"; DocType: Option Writeoff,Release,Movement; PostingDate: Date)
    begin
        FADocHeader.Init;
        FADocHeader."Document Type" := DocType;
        FADocHeader.Insert(true);
        FADocHeader.Validate("Posting Date", PostingDate);
        FADocHeader.Modify;
    end;

    [Scope('OnPrem')]
    procedure CreateFAActLine(DocType: Option Writeoff,Release,Movement; FADocNo: Code[20]; FANo: Code[20])
    var
        FADocLine: Record "FA Document Line";
    begin
        FADocLine.Init;
        FADocLine."Document Type" := DocType;
        FADocLine."Document No." := FADocNo;
        FADocLine."Line No." := 10000;
        FADocLine.Validate("FA No.", FANo);
        FADocLine.Insert;
    end;

    [Scope('OnPrem')]
    procedure CreateFAWriteOffAct(var FADocHeader: Record "FA Document Header"; FANo: Code[20]; PostingDate: Date)
    var
        DocType: Option Writeoff,Release,Movement;
    begin
        CreateFAActHeader(FADocHeader, DocType::Writeoff, PostingDate);
        CreateFAActLine(DocType::Writeoff, FADocHeader."No.", FANo);
    end;

    [Scope('OnPrem')]
    procedure PostFAWriteOffAct(FADocHeader: Record "FA Document Header")
    var
        FADocPost: Codeunit "FA Document-Post";
    begin
        FADocPost.Run(FADocHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateFAReleaseAct(var FADocHeader: Record "FA Document Header"; FANo: Code[20]; PostingDate: Date)
    var
        DocType: Option Writeoff,Release,Movement;
    begin
        CreateFAActHeader(FADocHeader, DocType::Release, PostingDate);
        CreateFAActLine(DocType::Release, FADocHeader."No.", FANo);
    end;

    [Scope('OnPrem')]
    procedure PostFAReleaseAct(FADocHeader: Record "FA Document Header")
    var
        FADocPost: Codeunit "FA Document-Post";
    begin
        FADocPost.Run(FADocHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateItemWithItemTrackingCode(var Item: Record Item; ItemTrackingCode: Code[10]): Code[20]
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Modify(true);
        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateItemUnitOfMeasure(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo, UnitOfMeasureCode, QtyPerUnitOfMeasure);
    end;

    [Scope('OnPrem')]
    procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; SNSpecific: Boolean; LotSpecific: Boolean; CDSpecific: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecific, LotSpecific);
        ItemTrackingCode.Validate("CD Specific Tracking", CDSpecific);
        ItemTrackingCode.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCDTracking(var CDTrackingSetup: Record "CD Tracking Setup"; ItemTrackingCode: Code[10]; CDLocationCode: Code[10])
    begin
        CDTrackingSetup."Item Tracking Code" := ItemTrackingCode;
        CDTrackingSetup."Location Code" := CDLocationCode;
        CDTrackingSetup.Insert;
    end;

    [Scope('OnPrem')]
    procedure CreateForeignVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", XEUR);
        Vendor.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify;
    end;

    [Scope('OnPrem')]
    procedure CreatePurchCreditMemo(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify;
    end;

    [Scope('OnPrem')]
    procedure CreatePurchReturnOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify;
    end;

    [Scope('OnPrem')]
    procedure CreatePurchLineItem(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; UnitCost: Decimal; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify;
    end;

    [Scope('OnPrem')]
    procedure PostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; Receive: Boolean; Invoice: Boolean; Ship: Boolean)
    begin
        PurchaseHeader.Validate(Receive, Receive);
        PurchaseHeader.Validate(Invoice, Invoice);
        PurchaseHeader.Validate(Ship, Ship);
        CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchLineFA(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; FANo: Code[20]; UnitCost: Decimal; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FANo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify;
    end;

    [Scope('OnPrem')]
    procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify;
    end;

    [Scope('OnPrem')]
    procedure CreateSalesReturnOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify;
    end;

    [Scope('OnPrem')]
    procedure CreateSalesLineItem(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; UnitPrice: Decimal; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify;
    end;

    [Scope('OnPrem')]
    procedure CreateSalesLineFA(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; FANo: Code[20]; UnitPrice: Decimal; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FANo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify;
    end;

    [Scope('OnPrem')]
    procedure CreateItemDocument(var ItemDocumentHeader: Record "Item Document Header"; DocumentType: Option; LocationCode: Code[10])
    begin
        ItemDocumentHeader.Init;
        ItemDocumentHeader."Document Type" := DocumentType;
        ItemDocumentHeader.Insert(true);
        ItemDocumentHeader.Validate("Location Code", LocationCode);
        ItemDocumentHeader.Modify;
    end;

    [Scope('OnPrem')]
    procedure CreateItemDocumentLine(var ItemDocumentHeader: Record "Item Document Header"; var ItemDocumentLine: Record "Item Document Line"; ItemNo: Code[20]; UnitCost: Decimal; Quantity: Decimal)
    var
        RecRef: RecordRef;
    begin
        ItemDocumentLine.Init;
        ItemDocumentLine.Validate("Document Type", ItemDocumentHeader."Document Type");
        ItemDocumentLine.Validate("Document No.", ItemDocumentHeader."No.");
        RecRef.GetTable(ItemDocumentLine);
        ItemDocumentLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, ItemDocumentLine.FieldNo("Line No.")));
        ItemDocumentLine.Insert(true);
        ItemDocumentLine.Validate("Item No.", ItemNo);
        ItemDocumentLine.Validate("Unit Cost", UnitCost);
        ItemDocumentLine.Validate(Quantity, Quantity);
        ItemDocumentLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure PostItemDocument(ItemDocumentHeader: Record "Item Document Header")
    var
        ItemDocPostReceipt: Codeunit "Item Doc.-Post Receipt";
        ItemDocPostShipment: Codeunit "Item Doc.-Post Shipment";
    begin
        with ItemDocumentHeader do
            case "Document Type" of
                "Document Type"::Receipt:
                    ItemDocPostReceipt.Run(ItemDocumentHeader);
                "Document Type"::Shipment:
                    ItemDocPostShipment.Run(ItemDocumentHeader);
            end;
    end;

    [Scope('OnPrem')]
    procedure CreateSalesTrkgFromRes(SalesHeader: Record "Sales Header"; HideDialog: Boolean)
    var
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
    begin
        ItemTrackingDocMgt.CopyDocTrkgFromReservation(DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.", HideDialog);
    end;

    [Scope('OnPrem')]
    procedure CheckLastItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; LocationCode: Code[10]; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; Qty: Decimal): Boolean
    begin
        with ItemLedgerEntry do begin
            SetCurrentKey("Item No.", Open, "Variant Code", "Location Code", "Item Tracking", "Lot No.", "Serial No.", "CD No.");
            SetRange("Item No.", ItemNo);
            SetRange("Location Code", LocationCode);
            SetRange("Serial No.", SerialNo);
            SetRange("Lot No.", LotNo);
            SetRange("CD No.", CDNo);
            Assert.IsTrue(
              FindLast,
              StrSubstNo(
                LedgerEntryFoundErr,
                TableCaption,
                GetFilters));
            Assert.AreEqual(Qty, Quantity, StrSubstNo(LedgerEntryQtyErr, GetFilters));

            Reset;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckReservationEntry(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; ItemNo: Code[20]; LocationCode: Code[10]; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; Qty: Decimal; ResStatus: Option Reservation,Tracking,Surplus,Prospect): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // look for the reservation entry for specific source
        // within filters by
        //   - Serial No.
        //   - Lot No.
        //   - CD NO.
        // and check quantity
        ReservationEntry.SetCurrentKey("Item No.", "Source Type", "Source Subtype");
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source Subtype", SourceSubtype);
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.SetRange("Source Ref. No.", SourceRefNo);
        ReservationEntry.SetRange("Reservation Status", ResStatus);

        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Location Code", LocationCode);
        ReservationEntry.SetRange("Serial No.", SerialNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.SetRange("CD No.", CDNo);
        Assert.IsTrue(
          ReservationEntry.FindLast,
          StrSubstNo(
            LedgerEntryFoundErr,
            ReservationEntry.TableCaption,
            ReservationEntry.GetFilters));
        Assert.AreEqual(Qty, ReservationEntry.Quantity, StrSubstNo(LedgerEntryQtyErr, ReservationEntry.GetFilters));
    end;

    [Scope('OnPrem')]
    procedure CheckSalesReservationEntry(SalesLine: Record "Sales Line"; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; Qty: Decimal; ResStatus: Option Reservation,Tracking,Surplus,Prospect): Boolean
    begin
        // look for the reservation entry for sales line
        // within filters by
        //   - Serial No.
        //   - Lot No.
        //   - CD NO.
        // and check quantity
        CheckReservationEntry(
          DATABASE::"Sales Line",
          SalesLine."Document Type",
          SalesLine."Document No.",
          SalesLine."Line No.",
          SalesLine."No.",
          SalesLine."Location Code",
          SerialNo,
          LotNo,
          CDNo,
          Qty,
          ResStatus);
    end;

    [Scope('OnPrem')]
    procedure CheckPurchReservationEntry(PurchaseLine: Record "Purchase Line"; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; Qty: Decimal; ResStatus: Option Reservation,Tracking,Surplus,Prospect): Boolean
    begin
        // look for the reservation entry for purchase line
        // within filters by
        //   - Serial No.
        //   - Lot No.
        //   - CD NO.
        // and check quantity
        CheckReservationEntry(
          DATABASE::"Purchase Line",
          PurchaseLine."Document Type",
          PurchaseLine."Document No.",
          PurchaseLine."Line No.",
          PurchaseLine."No.",
          PurchaseLine."Location Code",
          SerialNo,
          LotNo,
          CDNo,
          Qty,
          ResStatus);
    end;

    [Scope('OnPrem')]
    procedure CheckItemDocReservationEntry(ItemDocumentLine: Record "Item Document Line"; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; Qty: Decimal; ResStatus: Option Reservation,Tracking,Surplus,Prospect): Boolean
    begin
        // look for the reservation entry for item document line
        // within filters by
        //   - Serial No.
        //   - Lot No.
        //   - CD NO.
        // and check quantity
        CheckReservationEntry(
          DATABASE::"Item Document Line",
          ItemDocumentLine."Document Type",
          ItemDocumentLine."Document No.",
          ItemDocumentLine."Line No.",
          ItemDocumentLine."Item No.",
          ItemDocumentLine."Location Code",
          SerialNo,
          LotNo,
          CDNo,
          Qty,
          ResStatus);
    end;

    local procedure UpdateCDReservation(var ReservationEntry: Record "Reservation Entry"; CDNo: Code[30])
    begin
        with ReservationEntry do begin
            "CD No." := CDNo;
            "Item Tracking" := ItemTrackingMgt.ItemTrackingOption("Lot No.", "Serial No.", "CD No.");
            Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure InitScenario1Item2CD(var Location: Record Location; var Item: Record Item; var CDNo: array[2] of Code[30])
    var
        CountryRegion: Record "Country/Region";
        ItemTrackingCode: Record "Item Tracking Code";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        i: Integer;
    begin
        // Function to simplify common scenario setup.
        // New location, item tracking with CD only,
        // new item, CD with 2 lines

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        CountryRegion.FindFirst;
        CreateCDHeader(CDHeader, CountryRegion.Code);
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[i]);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateVATPurchaseLedger(StartDate: Date; EndDate: Date; VendorFilter: Text[250]): Code[20]
    var
        VATLedger: Record "VAT Ledger";
        CreateVATPurchaseLedgerRep: Report "Create VAT Purchase Ledger";
    begin
        // TODO Method is copied from codeunit 82404 and should be replaced by original version
        // after the merge with VAT_Update functionality
        VATLedger.Init;
        VATLedger.Type := VATLedger.Type::Purchase;
        VATLedger.Insert(true);
        VATLedger.Validate("Start Date", StartDate);
        VATLedger.Validate("End Date", EndDate);
        VATLedger.Modify;

        VATLedger.SetRecFilter;
        CreateVATPurchaseLedgerRep.SetTableView(VATLedger);
        CreateVATPurchaseLedgerRep.UseRequestPage(false);
        CreateVATPurchaseLedgerRep.SetParameters(VendorFilter, '', '', 0, false, false, 0, 0, true, true, true, true);
        CreateVATPurchaseLedgerRep.Run;

        exit(VATLedger.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateVATSalesLedger(StartDate: Date; EndDate: Date; CustFilter: Text[250]): Code[20]
    var
        VATLedger: Record "VAT Ledger";
        CreateVATSalesLedgerRep: Report "Create VAT Sales Ledger";
    begin
        // TODO Method is copied from codeunit 82404 and should be replaced by original version
        // after the merge with VAT_Update functionality
        VATLedger.Init;
        VATLedger.Type := VATLedger.Type::Sales;
        VATLedger.Insert(true);
        VATLedger.Validate("Start Date", StartDate);
        VATLedger.Validate("End Date", EndDate);
        VATLedger.Modify;

        VATLedger.SetRecFilter;
        CreateVATSalesLedgerRep.SetTableView(VATLedger);
        CreateVATSalesLedgerRep.UseRequestPage(false);
        CreateVATSalesLedgerRep.SetParameters(CustFilter, '', '', 0, false, false, true, true, true, true, true);
        CreateVATSalesLedgerRep.Run;

        exit(VATLedger.Code);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateWMSLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Require Receive" := true;
        Location."Require Shipment" := true;
        Location."Require Put-away" := true;
        Location."Require Pick" := true;
        Location."Bin Mandatory" := true;
        Location."Directed Put-away and Pick" := false;
        Location.Modify;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateBin(Location: Record Location; BinNo: Integer): Code[30]
    var
        Bin: Record Bin;
    begin
        Bin.Init;
        Bin."Location Code" := Location.Code;
        Bin.Code := Location.Code + Format(BinNo);
        Bin.Insert;
        exit(Bin.Code);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure PostWareHouseActLine(Location: Record Location; BinCode: Code[30]; Qty: Decimal)
    var
        WarehouseActLine: Record "Warehouse Activity Line";
        WhseRegisterPutAwayYesNo: Codeunit "Whse.-Act.-Register (Yes/No)";
    begin
        WarehouseActLine.Reset;
        WarehouseActLine.SetCurrentKey("Location Code");
        WarehouseActLine.SetFilter("Location Code", Location.Code);
        WarehouseActLine.FindSet;
        repeat
            if WarehouseActLine."Bin Code" = '' then
                WarehouseActLine."Bin Code" := BinCode;
            WarehouseActLine.Validate("Qty. to Handle", Qty);
            WarehouseActLine.Modify;
        until WarehouseActLine.Next = 0;

        WhseRegisterPutAwayYesNo.Run(WarehouseActLine);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure RegisterPick(Location: Record Location; Qty: Decimal)
    var
        WarehouseActLine: Record "Warehouse Activity Line";
        WhseRegisterActivityYesNo: Codeunit "Whse.-Act.-Register (Yes/No)";
    begin
        WarehouseActLine.Reset;
        WarehouseActLine.SetCurrentKey("Location Code");
        WarehouseActLine.SetFilter("Location Code", Location.Code);
        WarehouseActLine.FindSet;
        repeat
            WarehouseActLine.Validate("Qty. to Handle", Qty);
            WarehouseActLine.Modify;
        until WarehouseActLine.Next = 0;

        WhseRegisterActivityYesNo.Run(WarehouseActLine);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure ValidateBinContentQty(Location: Record Location; BinCode: Code[30]; Qty: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.Reset;
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.FindFirst;
        Assert.AreEqual(Qty, BinContent.CalcQtyAvailToPick(0), AvailableQtyToTakeErr);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure WhseRcptSetBinCode(var WareHouseRcptLine: Record "Warehouse Receipt Line"; Item: Record Item; BinCode: Code[30])
    begin
        WareHouseRcptLine.Reset;
        WareHouseRcptLine.SetCurrentKey("Item No.");
        WareHouseRcptLine.SetFilter("Item No.", Item."No.");
        WareHouseRcptLine.FindFirst;
        WareHouseRcptLine.Validate("Bin Code", BinCode);
        WareHouseRcptLine.Modify;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure WhseShptSetBinCode(var WareHouseShptLine: Record "Warehouse Shipment Line"; Item: Record Item; BinCode: Code[30])
    begin
        WareHouseShptLine.Reset;
        WareHouseShptLine.SetCurrentKey("Item No.");
        WareHouseShptLine.SetFilter("Item No.", Item."No.");
        WareHouseShptLine.FindFirst;
        WareHouseShptLine.Validate("Bin Code", BinCode);
        WareHouseShptLine.Modify;
    end;

    [Scope('OnPrem')]
    procedure CreatePickFromWhseShpt(WarehouseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header")
    var
        CreatePickFromWhseShpt: Report "Whse.-Shipment - Create Pick";
    begin
        CreatePickFromWhseShpt.SetWhseShipmentLine(WarehouseShptLine, WhseShptHeader);
        CreatePickFromWhseShpt.SetHideValidationDialog(true);
        CreatePickFromWhseShpt.UseRequestPage(false);
        CreatePickFromWhseShpt.RunModal;
    end;

    [Scope('OnPrem')]
    procedure UpdateERMCountryData()
    begin
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateVATPostingSetup;
        LibraryERMCountryData.UpdateLocalData;
    end;

    [Scope('OnPrem')]
    procedure CreateFixedAsset(var FA: Record "Fixed Asset")
    var
        FASetup: Record "FA Setup";
        TaxRegisterSetup: Record "Tax Register Setup";
        FAPostingGroup: Record "FA Posting Group";
    begin
        FAPostingGroup.SetFilter("Acquisition Cost Account", '<>%1', '');
        FAPostingGroup.SetFilter("Acq. Cost Acc. on Disposal", '<>%1', '');
        FAPostingGroup.FindFirst;
        UpdateGLAccWithVATPostingSetup(FAPostingGroup."Acquisition Cost Account");
        UpdateGLAccWithVATPostingSetup(FAPostingGroup."Acq. Cost Acc. on Disposal");

        FASetup.Get;
        TaxRegisterSetup.Get;
        with FA do begin
            Init;
            Insert(true);
            InitFADeprBooks("No.");
            Modify(true);
        end;
        UpdateFADeprBook(FA."No.", FASetup."Default Depr. Book", FAPostingGroup.Code);
        UpdateFADeprBook(FA."No.", FASetup."Release Depr. Book", FAPostingGroup.Code);
        UpdateFADeprBook(FA."No.", TaxRegisterSetup."Tax Depreciation Book", FAPostingGroup.Code);
    end;

    local procedure UpdateFADeprBook(FANo: Code[20]; DeprBookCode: Code[10]; FAPostingGroupCode: Code[20])
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        if FADeprBook.Get(FANo, DeprBookCode) then begin
            FADeprBook.Validate("FA Posting Group", FAPostingGroupCode);
            FADeprBook.Validate("No. of Depreciation Years", 1 + LibraryRandom.RandInt(5));
            FADeprBook.Modify(true);
        end;
    end;

    local procedure UpdateGLAccWithVATPostingSetup(GLAccNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLAccount.Get(GLAccNo);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;
}

