codeunit 147100 "SCM CD Base"
{
    // // [FEATURE] [CD Tracking]

    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryCDTracking: Codeunit "Library - CD Tracking";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        PostedItemDocumentShowTrackingErr: Label 'Can''t show Posted Item Tracking Page.';

    [Test]
    [Scope('OnPrem')]
    procedure TestPositiveAdjustment()
    var
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: array[2] of Code[30];
    begin
        // scenario for positive adjustment with item journal
        // one item journal line with 2 different CD numbers

        Initialize;
        LibraryCDTracking.InitScenario1Item2CD(Location, Item, CDNo);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryCDTracking.CreateItemUnitOfMeasure(Item."No.", UnitOfMeasure.Code, 20);

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate, Item."No.", 10, Location.Code);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[1], 6);
        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[2], 4);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], 6);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[2], 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Vendor: Record Vendor;
        CDNo: array[2, 2] of Code[30];
        Qty: array[2, 2] of Decimal;
        i: Integer;
        j: Integer;
    begin
        // scenario for purchase order
        // 2 items with 2 different CD numbers are purchased

        Initialize;
        PurchaseOrderScenario(Vendor, Location, Item, CDNo, Qty);
        for i := 1 to ArrayLen(Qty, 1) do
            for j := 1 to ArrayLen(Qty, 2) do
                LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[i]."No.", Location.Code, '', '', CDNo[i, j], Qty[i, j]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseCreditMemo()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        Qty: array[2, 2] of Decimal;
        CDNo: array[2, 2] of Code[30];
        i: Integer;
        j: Integer;
    begin
        // scenario for purchase credit memo
        // 2 items with 2 different CD numbers are purchased
        // after that, credit memo is created and posted

        Initialize;
        PurchaseOrderScenario(Vendor, Location, Item, CDNo, Qty);

        for i := 1 to ArrayLen(Qty, 1) do begin
            LibraryCDTracking.CreatePurchCreditMemo(PurchaseHeader[i], Vendor."No.", Location.Code);
            for j := 1 to ArrayLen(Qty, 2) do
                CreatePurchLineWithTracking(
                  PurchaseHeader[i], Item[i]."No.", CDNo[i, j], LibraryRandom.RandDec(100, 2), Qty[i, j]);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader[i], true, true);
            for j := 1 to ArrayLen(Qty, 2) do
                LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[i]."No.", Location.Code, '', '', CDNo[i, j], -Qty[i, j]);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrder()
    var
        Location: Record Location;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: array[2] of Code[30];
        TotalQty: Decimal;
        Qty: array[2] of Decimal;
        i: Integer;
    begin
        // scenario for sales order
        // 1. positive adjustment
        // 2. sales order

        Initialize;
        LibraryCDTracking.InitScenario1Item2CD(Location, Item, CDNo);
        InitQty(TotalQty, Qty);
        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate, Item."No.", TotalQty, Location.Code);
        for i := 1 to ArrayLen(Qty) do
            LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[i], Qty[i]);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibrarySales.CreateCustomer(Customer);
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        LibraryCDTracking.CreateSalesLineItem(SalesLine, SalesHeader, Item."No.", LibraryRandom.RandDec(100, 2), TotalQty);
        for i := 1 to ArrayLen(Qty) do
            LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, '', '', CDNo[i], Qty[i]);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        for i := 1 to ArrayLen(Qty) do
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[i], -Qty[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderReservation()
    var
        Location: Record Location;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: array[2] of Code[30];
        TotalQty: Decimal;
        Qty: array[2] of Decimal;
        i: Integer;
    begin
        // scenario for sales order reservation
        // 1. positive adjustment
        // 2. sales order
        // instead of direct setup of item tracking following schema is used:
        // a. Creating reservation for sales line
        // b. Transfer reservation to item tracking by using function
        // "Create Tracking From Reservation"

        Initialize;
        LibraryCDTracking.InitScenario1Item2CD(Location, Item, CDNo);
        InitQty(TotalQty, Qty);
        LibraryCDTracking.CreateItemJnlLine(
          ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate, Item."No.", TotalQty, Location.Code);
        for i := 1 to ArrayLen(Qty) do
            LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[i], Qty[i]);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibrarySales.CreateCustomer(Customer);
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        LibraryCDTracking.CreateSalesLineItem(
          SalesLine, SalesHeader, Item."No.", LibraryRandom.RandDec(100, 2), TotalQty);
        SalesLine.AutoReserve();
        LibraryCDTracking.CreateSalesTrkgFromRes(SalesHeader, true);

        for i := 1 to ArrayLen(Qty) do
            LibraryCDTracking.CheckSalesReservationEntry(
              SalesLine, '', '', CDNo[i], -Qty[i], ReservationEntry."Reservation Status"::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCopyDocument()
    var
        Location: Record Location;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        CopySalesDocument: Report "Copy Sales Document";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        DocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
        CDNo: array[2] of Code[30];
        TotalQty: Decimal;
        Qty: array[2] of Decimal;
        i: Integer;
    begin
        // scenario for copy sales document function
        // 1. positive adjustment
        // 2. sales order
        // 3. sales return order copied from posted sales invoice

        Initialize;
        LibraryCDTracking.InitScenario1Item2CD(Location, Item, CDNo);
        InitQty(TotalQty, Qty);
        LibraryCDTracking.CreateItemJnlLine(
          ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate, Item."No.", TotalQty, Location.Code);

        for i := 1 to ArrayLen(Qty) do
            LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[i], Qty[i]);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibrarySales.CreateCustomer(Customer);
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        LibraryCDTracking.CreateSalesLineItem(
          SalesLine, SalesHeader, Item."No.", LibraryRandom.RandDec(100, 2), TotalQty);
        for i := 1 to ArrayLen(Qty) do
            LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, '', '', CDNo[i], Qty[i]);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCDTracking.CreateSalesReturnOrder(SalesHeader, Customer."No.", Location.Code);
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.InitializeRequest(
          DocType::"Posted Invoice", FindLastPostedSalesInvoiceNo(Customer."No."), true, true);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.Run;

        FindFirstSalesLine(SalesLine, SalesHeader, Item."No.");
        for i := 1 to ArrayLen(Qty) do
            LibraryCDTracking.CheckSalesReservationEntry(
              SalesLine, '', '', CDNo[i], Qty[i], ReservationEntry."Reservation Status"::Surplus);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTransferOrder()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: array[2] of Code[30];
        TotalQty: Decimal;
        Qty: array[2] of Decimal;
        i: Integer;
    begin
        // scenario for transfer order
        // 1. positive adjustment
        // 2. transfer order

        Initialize;
        SetupTransferNosInInvSetup;
        InitQty(TotalQty, Qty);
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);

        for i := 1 to ArrayLen(Qty) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[i]);
        end;

        LibraryCDTracking.CreateItemJnlLine(
          ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate, Item."No.", TotalQty, LocationFrom.Code);
        for i := 1 to ArrayLen(Qty) do
            LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo[i], Qty[i]);
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(
          TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", TotalQty);
        for i := 1 to ArrayLen(Qty) do
            LibraryCDTracking.CreateTransferLineTracking(ReservationEntry, TransferLine, '', '', CDNo[i], Qty[i]);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        for i := 1 to ArrayLen(Qty) do
            LibraryCDTracking.CheckLastItemLedgerEntry(
              ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', CDNo[i], Qty[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemDocuments()
    var
        Location: Record Location;
        Item: Record Item;
        ItemDocumentHeader: Record "Item Document Header";
        CDNo: array[2] of Code[30];
        TotalQty: Decimal;
        Qty: array[2] of Decimal;
    begin
        Initialize;
        LibraryCDTracking.InitScenario1Item2CD(Location, Item, CDNo);
        InitQty(TotalQty, Qty);

        TestItemDocument(
          ItemDocumentHeader."Document Type"::Receipt, Location.Code, Item."No.", CDNo, TotalQty, Qty);
        TestItemDocument(
          ItemDocumentHeader."Document Type"::Shipment, Location.Code, Item."No.", CDNo, TotalQty, Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestForeignCurrencyCustLedgEntryApply()
    var
        GLSetup: Record "General Ledger Setup";
        CurrencyCode: Code[10];
        ItemNo: Code[20];
        LocationCode: Code[10];
        VendNo: Code[20];
        CustNo: Code[20];
        CDNo: Code[30];
        SalesInvDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize;
        GLSetup.Get();
        GLSetup.Validate("Cancel Curr. Prepmt. Adjmt.", false);
        GLSetup.Modify(true);

        CurrencyCode := CreateCurrencyAndExchangeRate;
        AddExchangeRate(CurrencyCode);

        VendNo := LibraryPurchase.CreateVendorNo;
        CustNo := LibrarySales.CreateCustomerNo;
        LocationCode := CreateLocation;
        ItemNo := CreateCDItem(LocationCode);
        CDNo := CreateCDNo(ItemNo, VendNo);

        CreatePostPurchInvoice(VendNo, LocationCode, CurrencyCode, ItemNo, CDNo);
        SalesInvDocNo := CreateReleaseSalesInvoice(CustNo, LocationCode, CurrencyCode, ItemNo, CDNo);
        PaymentDocNo := CreatePostCustPaymentGenJnlLine(CustNo, SalesInvDocNo, CurrencyCode);
        SalesInvDocNo := PostSalesDoc(SalesInvDocNo);
        ApplyPostCustPaymentToInvoice(PaymentDocNo, SalesInvDocNo);

        VerifyAppliedCustPaymentLedgEntry(PaymentDocNo);
        VerifyAppliedCustInvoiceLedgEntry(SalesInvDocNo);
    end;

    [Test]
    [HandlerFunctions('PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesShowOnPostedItemDocuments()
    var
        Location: Record Location;
        Item: Record Item;
        ItemDocumentHeader: Record "Item Document Header";
        ItemReceiptHeader: Record "Item Receipt Header";
        ItemReceiptLine: Record "Item Receipt Line";
        ItemShipmentHeader: Record "Item Shipment Header";
        ItemShipmentLine: Record "Item Shipment Line";
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        ReceiptNo: Code[20];
        ShipmentNo: Code[20];
        CDNo: array[2] of Code[30];
        TotalQty: Decimal;
        Qty: array[2] of Decimal;
    begin
        // [FEATURE] [Item Document]
        // [SCENARIO 379460] On pages Posted Item Receipt and Shipment Subform an action Item Tracking Lines shows tracking info
        Initialize;
        LibraryCDTracking.InitScenario1Item2CD(Location, Item, CDNo);
        InitQty(TotalQty, Qty);

        // [WHEN] Posted Item Receipt and Shipment with CD tracking on lines
        ReceiptNo := TestItemDocument(ItemDocumentHeader."Document Type"::Receipt, Location.Code, Item."No.", CDNo, TotalQty, Qty);
        ShipmentNo := TestItemDocument(ItemDocumentHeader."Document Type"::Shipment, Location.Code, Item."No.", CDNo, TotalQty, Qty);

        // [THEN] ItemTrackingDocMgt.ShowItemTrackingForInvoiceLine is true on receipt line
        ItemReceiptHeader.SetRange("Receipt No.", ReceiptNo);
        ItemReceiptHeader.FindFirst;
        ItemReceiptLine.SetRange("Document No.", ItemReceiptHeader."No.");
        ItemReceiptLine.FindFirst;

        Assert.IsTrue(ItemTrackingDocMgt.ShowItemTrackingForInvoiceLine(ItemReceiptLine.RowID1), PostedItemDocumentShowTrackingErr);

        // [THEN] ItemTrackingDocMgt.ShowItemTrackingForInvoiceLine is true on shipment line
        ItemShipmentHeader.SetRange("Shipment No.", ShipmentNo);
        ItemShipmentHeader.FindFirst;
        ItemShipmentLine.SetRange("Document No.", ItemShipmentHeader."No.");
        ItemShipmentLine.FindFirst;

        Assert.IsTrue(ItemTrackingDocMgt.ShowItemTrackingForInvoiceLine(ItemShipmentLine.RowID1), PostedItemDocumentShowTrackingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenAndCloseCDTrackingSetupLookupPage()
    var
        RecordCDTrackingSetup: Record "CD Tracking Setup";
        TestPageCDTrackingSetup: TestPage "CD Tracking Setup";
    begin
        // [FEATURE] [CD Tracking Setup] [UT]
        // [SCENARIO 229456] Lookup action for the table 12410 "CD Tracking Setup" should open page 14957 "CD Tracking Setup".
        TestPageCDTrackingSetup.Trap;
        PAGE.Run(0, RecordCDTrackingSetup);
        TestPageCDTrackingSetup.Close;
    end;

    local procedure Initialize()
    begin
        if isInitialized then
            exit;

        LibraryCDTracking.UpdateERMCountryData;

        isInitialized := true;
        Commit();
    end;

    local procedure SetupTransferNosInInvSetup()
    var
        InvSetup: Record "Inventory Setup";
    begin
        with InvSetup do begin
            Get;
            if "Transfer Order Nos." = '' then
                Validate("Transfer Order Nos.", CreateNoSeries);
            if "Posted Transfer Shpt. Nos." = '' then
                Validate("Posted Transfer Shpt. Nos.", CreateNoSeries);
            if "Posted Transfer Rcpt. Nos." = '' then
                Validate("Posted Transfer Rcpt. Nos.", CreateNoSeries);
            Modify(true);
        end;
    end;

    local procedure InitQty(var TotalQty: Decimal; var Qty: array[2] of Decimal)
    begin
        TotalQty := 3 + LibraryRandom.RandInt(10);
        Qty[1] := Round(TotalQty / 3, 1);
        Qty[2] := TotalQty - Qty[1];
    end;

    local procedure PurchaseOrderScenario(var Vendor: Record Vendor; var Location: Record Location; var Item: array[2] of Record Item; var CDNo: array[2, 2] of Code[30]; var Qty: array[2, 2] of Decimal)
    var
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: array[2] of Record "Purchase Header";
        CDHeader: array[2] of Record "CD No. Header";
        CDLine: Record "CD No. Information";
        i: Integer;
        j: Integer;
    begin
        // scenario for purchase order
        // 2 items with 2 different CD numbers are purchased

        LibraryCDTracking.CreateForeignVendor(Vendor);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);
        for i := 1 to ArrayLen(Item) do begin
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);
            Commit();
            LibraryCDTracking.CreatePurchOrder(PurchaseHeader[i], Vendor."No.", Location.Code);
            LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader[i]);
            for j := 1 to 2 do begin
                CDNo[i, j] := LibraryUtility.GenerateGUID;
                LibraryCDTracking.CreateItemCDInfo(CDHeader[i], CDLine, Item[i]."No.", CDNo[i, j]);
                Qty[i, j] := LibraryRandom.RandInt(100);
                CreatePurchLineWithTracking(
                  PurchaseHeader[i], Item[i]."No.", CDNo[i, j], LibraryRandom.RandDec(100, 2), Qty[i, j]);
            end;
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader[i], true, true);
        end;
    end;

    local procedure TestItemDocument(ItemDocType: Option; LocationCode: Code[10]; ItemNo: Code[20]; CDNo: array[2] of Code[30]; TotalQty: Decimal; Qty: array[2] of Decimal): Code[20]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        ReservationEntry: Record "Reservation Entry";
        i: Integer;
    begin
        // scenario for item documents
        // one item 2 different CD numbers

        LibraryCDTracking.CreateItemDocument(
          ItemDocumentHeader, ItemDocType, LocationCode);
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, ItemNo, LibraryRandom.RandDec(100, 2), TotalQty);
        for i := 1 to ArrayLen(Qty) do
            LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine, '', '', CDNo[i], Qty[i]);
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);
        for i := 1 to ArrayLen(Qty) do
            LibraryCDTracking.CheckLastItemLedgerEntry(
              ItemLedgerEntry, ItemNo, LocationCode, '', '', CDNo[i], GetitemDocSign(ItemDocType) * Qty[i]);
        exit(ItemDocumentHeader."No.");
    end;

    local procedure CreatePurchLineWithTracking(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; CDNo: Code[30]; UnitCost: Decimal; Qty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, ItemNo, UnitCost, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo, Qty);
    end;

    local procedure CreatePostPurchInvoice(VendNo: Code[20]; LocationCode: Code[10]; CurrencyCode: Code[10]; ItemNo: Code[20]; CDNo: Code[30])
    var
        Purchheader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(Purchheader, Purchheader."Document Type"::Invoice, VendNo);
        with Purchheader do begin
            Validate("Location Code", LocationCode);
            Validate("Vendor Invoice No.", "No.");
            Validate("Currency Code", CurrencyCode);
            Modify(true);
        end;
        CreatePurchLine(Purchheader, ItemNo, CDNo);
        LibraryPurchase.PostPurchaseDocument(Purchheader, true, true);
    end;

    local procedure CreatePurchLine(var PurchHeader: Record "Purchase Header"; ItemNo: Code[20]; CDNo: Code[30])
    var
        PurchLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Qty: Integer;
    begin
        Qty := LibraryRandom.RandInt(10);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo, Qty);
        with PurchLine do begin
            Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
            Modify(true);
        end;
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchLine, '', '', CDNo, Qty)
    end;

    local procedure CreateReleaseSalesInvoice(CustNo: Code[20]; LocationCode: Code[10]; CurrencyCode: Code[10]; ItemNo: Code[20]; CDNo: Code[30]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        with SalesHeader do begin
            Validate("Posting Date", CalcDate('<1M>', WorkDate));
            Validate("Location Code", LocationCode);
            Validate("Currency Code", CurrencyCode);
            Modify(true);
        end;
        CreateSalesLine(SalesHeader, ItemNo, CDNo);
        ReleaseSalesDoc.PerformManualRelease(SalesHeader);
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; CDNo: Code[30])
    var
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        Qty: Integer;
    begin
        Qty := 1;
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        with SalesLine do begin
            Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
            Modify(true);
        end;
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, '', '', CDNo, Qty);
    end;

    local procedure CreatePostCustPaymentGenJnlLine(CustNo: Code[20]; PrepmtDocNo: Code[20]; CurrencyCode: Code[10]) DocNo: Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        with GenJournalLine do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name",
              GenJournalBatch.Name, "Document Type"::Payment, "Account Type"::Customer, CustNo, 0);
            Validate(Prepayment, true);
            Validate("Prepayment Document No.", PrepmtDocNo);
            Validate("External Document No.", PrepmtDocNo);
            Validate("Bal. Account Type", "Bal. Account Type"::"Bank Account");
            Validate("Bal. Account No.", CreateBankAccount(CurrencyCode));
            Modify(true);
            DocNo := "Document No.";
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        with Currency do begin
            GeneralLedgerSetup.Get();
            LibraryERM.CreateCurrency(Currency);
            Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo);
            Validate("Realized Losses Acc.", LibraryERM.CreateGLAccountNo);
            Modify(true);

            LibraryERM.CreateExchangeRate(Code, WorkDate, 1, LibraryRandom.RandDec(100, 2));
            exit(Code);
        end;
    end;

    local procedure CreateBankAccount(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        exit(BankAccount."No.");
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        exit(Location.Code);
    end;

    local procedure CreateCDItem(LocationCode: Code[10]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, CreateItemTrackingCode);
        CreateCDTrackingSetup(Item."Item Tracking Code", LocationCode);
        with Item do begin
            Validate("Costing Method", "Costing Method"::FIFO);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        with ItemTrackingCode do begin
            Validate("Use Expiration Dates", true);
            Validate("Strict Expiration Posting", true);
            Modify(true);
            exit(Code);
        end;
    end;

    local procedure CreateCDTrackingSetup(ItemTrackingCode: Code[10]; LocationCode: Code[10])
    var
        CDTrackingSetup: Record "CD Tracking Setup";
    begin
        with CDTrackingSetup do begin
            Init;
            Validate("Item Tracking Code", ItemTrackingCode);
            Validate("Location Code", LocationCode);
            Validate("CD Info. Must Exist", true);
            Validate("CD Sales Check on Release", true);
            Validate("CD Purchase Check on Release", true);
            Insert(true);
        end;
    end;

    local procedure CreateCDNo(ItemNo: Code[20]; VendorNo: Code[20]): Code[30]
    var
        CDHeader: Record "CD No. Header";
        CDNoInfo: Record "CD No. Information";
    begin
        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        with CDHeader do begin
            Validate("Source No.", VendorNo);
            Validate("Declaration Date", WorkDate);
            Modify(true);
        end;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDNoInfo, ItemNo, LibraryUtility.GenerateGUID);
        exit(CDNoInfo."CD No.");
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        exit(NoSeries.Code);
    end;

    local procedure PostSalesDoc(SalesDocNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesDocNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure ApplyPostCustPaymentToInvoice(PaymentDocNo: Code[20]; InvoiceDocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.ApplyCustomerLedgerEntry(
          CustLedgerEntry."Document Type"::Payment, PaymentDocNo,
          CustLedgerEntry."Document Type"::Invoice, InvoiceDocNo);
    end;

    local procedure AddExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        with CurrencyExchangeRate do begin
            SetRange("Currency Code", CurrencyCode);
            FindFirst;
            Validate("Starting Date", CalcDate('<1M>', WorkDate));
            Validate("Relational Exch. Rate Amount", "Relational Exch. Rate Amount" + LibraryRandom.RandInt(100));
            Validate("Relational Adjmt Exch Rate Amt", "Relational Exch. Rate Amount");
            Insert(true);
        end;
    end;

    local procedure GetitemDocSign(ItemDocType: Option): Integer
    var
        ItemDocumentHeader: Record "Item Document Header";
    begin
        case ItemDocType of
            ItemDocumentHeader."Document Type"::Receipt:
                exit(1);
            ItemDocumentHeader."Document Type"::Shipment:
                exit(-1);
        end;
    end;

    local procedure FindLastPostedSalesInvoiceNo(CustNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        with SalesInvoiceHeader do begin
            SetCurrentKey("Sell-to Customer No.");
            SetRange("Sell-to Customer No.", CustNo);
            FindLast;
            exit("No.");
        end;
    end;

    local procedure FindFirstSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            SetRange(Type, Type::Item);
            SetRange("No.", ItemNo);
            FindFirst;
        end;
    end;

    local procedure VerifyAppliedCustPaymentLedgEntry(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        VerifyAppliedCustLedgEntry(DocumentNo, CustLedgerEntry."Document Type"::Payment);
    end;

    local procedure VerifyAppliedCustInvoiceLedgEntry(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        VerifyAppliedCustLedgEntry(DocumentNo, CustLedgerEntry."Document Type"::Invoice);
    end;

    local procedure VerifyAppliedCustLedgEntry(DocumentNo: Code[20]; DocType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, DocumentNo);
        Assert.AreEqual(0, CustLedgerEntry."Remaining Amount", '');
        Assert.AreEqual(false, CustLedgerEntry.Open, '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    begin
    end;
}

