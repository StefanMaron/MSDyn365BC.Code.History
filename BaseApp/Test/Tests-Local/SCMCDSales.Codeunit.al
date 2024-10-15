codeunit 147101 "SCM CD Sales"
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        CDNumberNotDefinedErr: Label 'You must assign a CD number for';
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryCDTracking: Codeunit "Library - CD Tracking";
        LibraryReservation: Codeunit "Create Reserv. Entry";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        EntryType: Option " ",Sales,Purchase,Receipt;
        ItemEntryType: Option " ",Receipt,Shipment;
        DocType: Option " ","Order","Credit Memo";
        CDType: Option "1 CD","Empty CD","2 CDs","3 CDs";
        ItemDocType: Option Receipt,Shipment,"Posted Receipt","Posted Shipment";
        isInitialized: Boolean;
        IncorrectConfirmDialogErr: Label 'Incorrect confirm dialog opened: ';
        FunctionCreateSpecMsg: Label 'This function create tracking specification from';
        DoYouWantYoUpdMsg: Label 'Do you want to update';
        DoYouWantToUndoMsg: Label 'Do you really want to undo';
        TestSerialTxt: Label 'TestSerialNo0';

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        LibraryCDTracking.UpdateERMCountryData;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res1ItemCD_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        Qty: Decimal;
    begin
        Initialize;
        InitScenario(Vendor, Customer, Item, Location, false, false, true);
        Qty := LibraryRandom.RandInt(100);
        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.", Qty, 20);
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, false, Qty, SerialNo, '', CDNo);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate, Location.Code, Item."No.", Qty);
        CreateSalesLineTracking(CDType::"1 CD", SalesLine, ReservationEntry, false, Qty, SerialNo, '', CDNo);
        CreatePOSOReservation(CDType::"1 CD", SalesHeader, PurchaseHeader, Location.Code, Item."No.", Qty, '', CDNo);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine, '', '', CDNo[1], Qty, ReservationEntry."Reservation Status"::Reservation);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Location.Code, '', CDNo[1], Qty);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, '', CDNo[1], -Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure Res1ItemCD_POIR()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        Qty: array[3] of Decimal;
        QtyToReserve: Decimal;
        i: Integer;
    begin
        Initialize;
        InitScenario(Vendor, Customer, Item, Location, false, false, true);

        for i := 1 to ArrayLen(Qty) do begin
            Qty[i] := LibraryRandom.RandInt(10);
            if (Qty[i] < QtyToReserve) or (QtyToReserve = 0) then
                QtyToReserve := Qty[i]
        end;

        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.",
          Qty[EntryType::Purchase], LibraryRandom.RandDec(100, 2));
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, false, Qty[EntryType::Purchase], SerialNo, '', CDNo);

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty[EntryType::Receipt]);
        CreateIRLineTracking(CDType::"1 CD", ItemDocumentLine, ReservationEntry, false, Qty[EntryType::Receipt], SerialNo, '', CDNo);

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate, Location.Code, Item."No.", Qty[EntryType::Sales]);
        CreateSalesLineTracking(CDType::"1 CD", SalesLine, ReservationEntry, false, Qty[EntryType::Sales], SerialNo, '', CDNo);

        CreatePOSOReservation(
          CDType::"1 CD", SalesHeader, PurchaseHeader, Location.Code, Item."No.", QtyToReserve, '', CDNo);
        CreateIRSOReservation(
          SalesHeader, ItemDocumentHeader, Location.Code, Item."No.", QtyToReserve, '', CDNo);

        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine, SerialNo[1], '', CDNo[1], QtyToReserve,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckItemDocReservationEntry(ItemDocumentLine, SerialNo[1], '', CDNo[1], QtyToReserve,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        SalesLine.Find;
        LibraryVariableStorage.Enqueue(CDNo[1]);
        LibraryVariableStorage.Enqueue(SalesLine."Quantity (Base)");
        LibraryVariableStorage.Enqueue(SalesLine."Qty. to Ship (Base)");
        LibraryVariableStorage.Enqueue(SalesLine."Qty. to Invoice (Base)");
        SalesLine.OpenItemTrackingLines();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Location.Code, '', CDNo[1], Qty[EntryType::Purchase]);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, '', CDNo[1], -Qty[EntryType::Sales]);
        CheckILEs(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, '', CDNo[1], Qty[EntryType::Receipt]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res1ItemCDLot_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        LotNo: Code[20];
        Qty: Decimal;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, false, true, true);
        Qty := LibraryRandom.RandInt(100);
        LotNo := LibraryUtility.GenerateGUID;
        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.", Qty, 20);
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, false, Qty, SerialNo, LotNo, CDNo);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate, Location.Code, Item."No.", Qty);
        CreateSalesLineTracking(CDType::"1 CD", SalesLine, ReservationEntry, false, Qty, SerialNo, LotNo, CDNo);
        CreatePOSOReservation(CDType::"1 CD", SalesHeader, PurchaseHeader, Location.Code, Item."No.", 4, LotNo, CDNo);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine, SerialNo[1], LotNo, CDNo[1], 4,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Location.Code, LotNo, CDNo[1], Qty);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, LotNo, CDNo[1], -Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res1ItemCDLot_POIR()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        LotNo: Code[20];
        Qty: array[3] of Decimal;
        QtyToReserve: Decimal;
        i: Integer;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, false, true, true);

        for i := 1 to ArrayLen(Qty) do begin
            Qty[i] := LibraryRandom.RandInt(100);
            if (Qty[i] < QtyToReserve) or (QtyToReserve = 0) then
                QtyToReserve := Qty[i];
        end;

        LotNo := LibraryUtility.GenerateGUID;

        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.", Qty[EntryType::Purchase], 20);
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, false, Qty[EntryType::Purchase], SerialNo, LotNo, CDNo);

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty[EntryType::Receipt]);
        CreateIRLineTracking(CDType::"1 CD", ItemDocumentLine, ReservationEntry, false, Qty[EntryType::Receipt], SerialNo, LotNo, CDNo);

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate, Location.Code, Item."No.", Qty[EntryType::Sales]);
        CreateSalesLineTracking(CDType::"1 CD", SalesLine, ReservationEntry, false, Qty[EntryType::Sales], SerialNo, LotNo, CDNo);

        CreatePOSOReservation(
          CDType::"1 CD", SalesHeader, PurchaseHeader, Location.Code, Item."No.", QtyToReserve, LotNo, CDNo);
        CreateIRSOReservation(
          SalesHeader, ItemDocumentHeader, Location.Code, Item."No.", QtyToReserve, LotNo, CDNo);

        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine, SerialNo[1], LotNo, CDNo[1], QtyToReserve,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckItemDocReservationEntry(ItemDocumentLine, SerialNo[1], LotNo, CDNo[1], QtyToReserve,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEs(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Location.Code, LotNo, CDNo[1], Qty[EntryType::Purchase]);
        CheckILEs(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, LotNo, CDNo[1], -Qty[EntryType::Sales]);
        CheckILEs(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, LotNo, CDNo[1], Qty[EntryType::Receipt]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res1ItemCDLotSerial_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        LotNo: Code[20];
        Qty: array[2] of Decimal;
        i: Integer;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, true, true, true);

        for i := 1 to ArrayLen(Qty) do
            Qty[i] := LibraryRandom.RandInt(10);
        LotNo := LibraryUtility.GenerateGUID;

        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.", Qty[EntryType::Purchase], 20);
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, true, Qty[EntryType::Purchase], SerialNo, LotNo, CDNo);

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate, Location.Code, Item."No.", Qty[EntryType::Sales]);
        CreateSalesLineTracking(CDType::"1 CD", SalesLine, ReservationEntry, true, Qty[EntryType::Sales], SerialNo, LotNo, CDNo);

        SalesLine.AutoReserve();

        for i := 1 to Qty[EntryType::Sales] do
            LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine, SerialNo[i], LotNo, CDNo[1], 1,
              ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEsWithSerial(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.",
          Location.Code, SerialNo, LotNo, CDNo[1], -Qty[EntryType::Sales]);
        CheckILEsWithSerial(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.",
          Location.Code, SerialNo, LotNo, CDNo[1], Qty[EntryType::Purchase]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res1ItemCDLotSerial_POIR()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDNo: array[3] of Code[30];
        SerialNo: array[20] of Code[20];
        LotNo: Code[20];
        Qty: array[3] of Decimal;
        i: Integer;
    begin
        Initialize;
        InitScenario(Vendor, Customer, Item, Location, true, true, true);

        Qty[EntryType::Sales] := 8;
        Qty[EntryType::Purchase] := 4;
        Qty[EntryType::Receipt] := 6;
        LotNo := LibraryUtility.GenerateGUID;

        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.", Qty[EntryType::Purchase], 20);
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, true, Qty[EntryType::Purchase], SerialNo, LotNo, CDNo);

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty[EntryType::Receipt]);
        for i := 1 to Qty[EntryType::Receipt] do begin
            SerialNo[i + 4] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine, SerialNo[i + 4], LotNo, CDNo[1], 1);
        end;

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate, Location.Code, Item."No.", Qty[EntryType::Sales]);
        CreateSalesLineTracking(CDType::"1 CD", SalesLine, ReservationEntry, true, Qty[EntryType::Sales], SerialNo, LotNo, CDNo);

        SalesLine.AutoReserve();

        for i := 1 to Qty[EntryType::Purchase] do
            LibraryCDTracking.CheckPurchReservationEntry(
              PurchaseLine, SerialNo[i], LotNo, CDNo[1], 1, ReservationEntry."Reservation Status"::Reservation);
        for i := 1 to Qty[EntryType::Purchase] do
            LibraryCDTracking.CheckItemDocReservationEntry(
              ItemDocumentLine, SerialNo[i + 4], LotNo, CDNo[1], 1, ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        for i := 1 to Qty[EntryType::Sales] do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[i], LotNo, CDNo[1], -1);
        end;

        for i := 1 to Qty[EntryType::Purchase] do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[i], LotNo, CDNo[1], 1);
        end;

        for i := 1 to Qty[EntryType::Receipt] do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[i + 4], LotNo, CDNo[1], 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res1Item2CD_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        Qty: array[2] of Decimal;
        i: Integer;
    begin
        Initialize;
        InitScenario(Vendor, Customer, Item, Location, false, false, true);

        Qty[EntryType::Sales] := 2 * LibraryRandom.RandInt(5);
        Qty[EntryType::Purchase] := Qty[EntryType::Sales];

        CreateCD(CDType::"2 CDs", CDHeader, CDLine, Item, CDNo);

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.",
          Qty[EntryType::Purchase], LibraryRandom.RandDec(100, 2));
        CreatePurchLineTracking(CDType::"2 CDs", PurchaseLine, ReservationEntry, false, Qty[EntryType::Purchase], SerialNo, '', CDNo);

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate, Location.Code, Item."No.", Qty[EntryType::Sales]);
        CreateSalesLineTracking(CDType::"2 CDs", SalesLine, ReservationEntry, false, Qty[EntryType::Sales], SerialNo, '', CDNo);

        SalesLine.AutoReserve();
        for i := 1 to ArrayLen(Qty) do
            LibraryCDTracking.CheckPurchReservationEntry(
              PurchaseLine, '', '', CDNo[i], Qty[i] / 2, ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        for i := 1 to ArrayLen(Qty) do begin
            CheckILEs(
              ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Location.Code, '', CDNo[i], Qty[EntryType::Purchase] / 2);
            CheckILEs(
              ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, '', CDNo[i], -Qty[EntryType::Sales] / 2);
        end;
    end;

    [Test]
    [HandlerFunctions('HndlConfirmTracking')]
    [Scope('OnPrem')]
    procedure Res1Item2CD_POIR()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        CDNo: array[3] of Code[30];
        Qty: array[3] of Decimal;
        i: Integer;
    begin
        Initialize;
        InitScenario(Vendor, Customer, Item, Location, false, false, true);

        for i := EntryType::Purchase to EntryType::Receipt do
            Qty[i] := LibraryRandom.RandInt(100);
        Qty[EntryType::Sales] := Qty[EntryType::Purchase] + Qty[EntryType::Receipt];

        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[i]);
        end;

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.",
          Qty[EntryType::Purchase], LibraryRandom.RandDec(100, 2));
        for i := 1 to 2 do
            LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[i], Qty[EntryType::Purchase] / 2);

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty[EntryType::Receipt]);
        for i := 1 to 2 do
            LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine, '', '', CDNo[i], Qty[EntryType::Receipt] / 2);

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate, Location.Code, Item."No.", Qty[EntryType::Sales]);
        SalesLine.AutoReserve();
        LibraryCDTracking.CreateSalesTrkgFromRes(SalesHeader, false);

        for i := 1 to 2 do begin
            LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine, '', '', CDNo[i], Qty[EntryType::Purchase] / 2,
              ReservationEntry."Reservation Status"::Reservation);
            LibraryCDTracking.CheckItemDocReservationEntry(ItemDocumentLine, '', '', CDNo[i], Qty[EntryType::Receipt] / 2,
              ReservationEntry."Reservation Status"::Reservation);
        end;

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        for i := 1 to 2 do begin
            CheckILEs(
              ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Location.Code, '', CDNo[i], Qty[EntryType::Purchase] / 2);
            CheckILEs(
              ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, '', CDNo[i], Qty[EntryType::Receipt] / 2);
            CheckILEs(
              ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, '', CDNo[1], -Qty[EntryType::Sales] / 2);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res1ItemLot_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[20];
        Qty: array[2] of Decimal;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, false, true, true);

        Qty[EntryType::Purchase] := LibraryRandom.RandInt(10);
        Qty[EntryType::Sales] := Qty[EntryType::Purchase];
        LotNo := LibraryUtility.GenerateGUID;

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.", Qty[EntryType::Purchase], 20);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', LotNo, '', Qty[EntryType::Purchase]);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate, Location.Code, Item."No.", Qty[EntryType::Sales]);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, '', LotNo, '', Qty[EntryType::Sales]);
        SalesLine.AutoReserve();

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(CDNumberNotDefinedErr);

        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(CDNumberNotDefinedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res2ItemCD_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[3] of Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDNo: array[3] of Code[30];
        PostingDate: Date;
        TotalQty: array[2, 2] of Decimal;
        PurchQty: array[2, 2] of Decimal;
        SalesQty: array[2, 2] of Decimal;
        i: Integer;
        j: Integer;
    begin
        Initialize;
        InitComplexScenario(Vendor, Customer, Item, Location, false, false, true);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo[1] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item[1]."No.", CDNo[1]);
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item[2]."No.", CDNo[1]);
        CDNo[2] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[2], Item[1]."No.", CDNo[2]);
        CDNo[3] := LibraryUtility.GenerateGUID;

        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[3], Item[2]."No.", CDNo[3]);
        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code);
        PurchaseHeader.Validate("Posting Date", WorkDate);
        PurchaseHeader.Modify();
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[1], PurchaseHeader, Item[1]."No.", 20, 4);
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[2], PurchaseHeader, Item[2]."No.", 30, 5);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', '', CDNo[1], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', '', CDNo[2], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', '', CDNo[1], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', '', CDNo[3], 3);

        PostingDate := CalcDate('<+5D>', WorkDate);
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibraryCDTracking.CreateSalesLineItem(SalesLine[1], SalesHeader, Item[1]."No.", 30, 3);
        SalesLine[1].Validate("Planned Delivery Date", PostingDate);
        SalesLine[1].Modify();
        LibraryCDTracking.CreateSalesLineItem(SalesLine[2], SalesHeader, Item[2]."No.", 40, 3);
        SalesLine[2].Validate("Planned Delivery Date", PostingDate);
        SalesLine[2].Modify();

        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[1], '', '', CDNo[1], 2);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[1], '', '', CDNo[2], 1);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[2], '', '', CDNo[1], 2);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[2], '', '', CDNo[3], 1);

        SalesLine[1].AutoReserve();
        SalesLine[2].AutoReserve();

        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[1], '', '', CDNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[1], '', '', CDNo[2], 1,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[2], '', '', CDNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[2], '', '', CDNo[3], 1,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[1]."No.", Location.Code, '', CDNo[1], 2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[1]."No.", Location.Code, '', CDNo[2], 2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[2]."No.", Location.Code, '', CDNo[1], 2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[2]."No.", Location.Code, '', CDNo[3], 3);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[1]."No.", Location.Code, '', CDNo[1], -2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[1]."No.", Location.Code, '', CDNo[2], -1);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[2]."No.", Location.Code, '', CDNo[1], -2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[2]."No.", Location.Code, '', CDNo[3], -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res2ItemCDLot_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[3] of Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDNo: array[3] of Code[30];
        LotNo: Code[20];
        PostingDate: Date;
    begin
        Initialize;

        InitComplexScenario(Vendor, Customer, Item, Location, true, false, true);
        LotNo := LibraryUtility.GenerateGUID;

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);

        CDNo[1] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item[1]."No.", CDNo[1]);
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item[2]."No.", CDNo[1]);
        CDNo[2] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[2], Item[1]."No.", CDNo[2]);
        CDNo[3] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[3], Item[2]."No.", CDNo[3]);

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code);
        PurchaseHeader.Validate("Posting Date", WorkDate);
        PurchaseHeader.Modify();
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[1], PurchaseHeader, Item[1]."No.", 20, 4);
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[2], PurchaseHeader, Item[2]."No.", 30, 5);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', LotNo, CDNo[1], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', LotNo, CDNo[2], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', LotNo, CDNo[1], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', LotNo, CDNo[3], 3);

        PostingDate := CalcDate('<+5D>', WorkDate);
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibraryCDTracking.CreateSalesLineItem(SalesLine[1], SalesHeader, Item[1]."No.", 30, 3);
        SalesLine[1].Validate("Planned Delivery Date", PostingDate);
        SalesLine[1].Modify();
        LibraryCDTracking.CreateSalesLineItem(SalesLine[2], SalesHeader, Item[2]."No.", 40, 3);
        SalesLine[2].Validate("Planned Delivery Date", PostingDate);
        SalesLine[2].Modify();

        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[1], '', LotNo, CDNo[1], 2);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[1], '', LotNo, CDNo[2], 1);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[2], '', LotNo, CDNo[1], 2);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[2], '', LotNo, CDNo[3], 1);

        SalesLine[1].AutoReserve();
        SalesLine[2].AutoReserve();

        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[1], '', LotNo, CDNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[1], '', LotNo, CDNo[2], 1,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[2], '', LotNo, CDNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[2], '', LotNo, CDNo[3], 1,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[1]."No.", Location.Code, LotNo, CDNo[1], 2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[1]."No.", Location.Code, LotNo, CDNo[2], 2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[2]."No.", Location.Code, LotNo, CDNo[1], 2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[2]."No.", Location.Code, LotNo, CDNo[3], 3);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[1]."No.", Location.Code, LotNo, CDNo[1], -2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[1]."No.", Location.Code, LotNo, CDNo[2], -1);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[2]."No.", Location.Code, LotNo, CDNo[1], -2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[2]."No.", Location.Code, LotNo, CDNo[3], -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res2ItemCDLotSerial_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[3] of Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        LotNo: Code[20];
        PostingDate: Date;
        j: Integer;
    begin
        Initialize;

        InitComplexScenario(Vendor, Customer, Item, Location, true, true, true);

        LotNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo[1] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item[1]."No.", CDNo[1]);
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item[2]."No.", CDNo[1]);
        CDNo[2] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[2], Item[1]."No.", CDNo[2]);
        CDNo[3] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[3], Item[2]."No.", CDNo[3]);

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code);
        PurchaseHeader.Validate("Posting Date", WorkDate);
        PurchaseHeader.Modify();
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[1], PurchaseHeader, Item[1]."No.", 20, 4);
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[2], PurchaseHeader, Item[2]."No.", 30, 5);

        for j := 1 to 2 do begin
            SerialNo[j] := LibraryUtility.GenerateGUID + Format(j);
            LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], SerialNo[j],
              LotNo, CDNo[1], 1);
        end;
        for j := 1 to 2 do begin
            SerialNo[j + 2] := LibraryUtility.GenerateGUID + Format(j + 2);
            LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], SerialNo[j + 2],
              LotNo, CDNo[2], 1);
        end;
        for j := 1 to 2 do begin
            SerialNo[j + 4] := LibraryUtility.GenerateGUID + Format(j + 4);
            LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], SerialNo[j + 4],
              LotNo, CDNo[1], 1);
        end;
        for j := 1 to 3 do begin
            SerialNo[j + 6] := LibraryUtility.GenerateGUID + Format(j + 6);
            LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], SerialNo[j + 6],
              LotNo, CDNo[3], 1);
        end;

        PostingDate := CalcDate('<+5D>', WorkDate);
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibraryCDTracking.CreateSalesLineItem(SalesLine[1], SalesHeader, Item[1]."No.", 30, 3);
        SalesLine[1].Validate("Planned Delivery Date", PostingDate);
        SalesLine[1].Modify();
        LibraryCDTracking.CreateSalesLineItem(SalesLine[2], SalesHeader, Item[2]."No.", 40, 3);
        SalesLine[2].Validate("Planned Delivery Date", PostingDate);
        SalesLine[2].Modify();

        for j := 1 to 2 do
            LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[1], SerialNo[j],
              LotNo, CDNo[1], 1);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[1], SerialNo[3],
          LotNo, CDNo[2], 1);
        for j := 1 to 2 do
            LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[2], SerialNo[j + 4],
              LotNo, CDNo[1], 1);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[2], SerialNo[7],
          LotNo, CDNo[3], 1);

        SalesLine[1].AutoReserve();
        SalesLine[2].AutoReserve();

        for j := 1 to 2 do
            LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[1], SerialNo[j], LotNo, CDNo[1], 1,
              ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[1], SerialNo[3], LotNo, CDNo[2], 1,
          ReservationEntry."Reservation Status"::Reservation);
        for j := 1 to 2 do
            LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[2], SerialNo[j + 4], LotNo, CDNo[1], 1,
              ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[2], SerialNo[7], LotNo, CDNo[3], 1,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[j], LotNo, CDNo[1], -1);
        end;
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[3], LotNo, CDNo[2], -1);

        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[j + 4], LotNo, CDNo[1], -1);
        end;
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[7], LotNo, CDNo[3], -1);

        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[j], LotNo, CDNo[1], 1);
        end;
        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[j + 2], LotNo, CDNo[2], 1);
        end;
        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[j + 4], LotNo, CDNo[1], 1);
        end;
        for j := 1 to 3 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[j + 6], LotNo, CDNo[3], 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res2ItemCD_2PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[3] of Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDNo: array[3] of Code[30];
        PostingDate: Date;
    begin
        Initialize;

        InitComplexScenario(Vendor, Customer, Item, Location, false, false, true);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo[1] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item[1]."No.", CDNo[1]);
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item[2]."No.", CDNo[1]);
        CDNo[2] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[2], Item[1]."No.", CDNo[2]);
        CDNo[3] := LibraryUtility.GenerateGUID;

        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[3], Item[2]."No.", CDNo[3]);
        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code);
        PurchaseHeader.Validate("Posting Date", WorkDate);
        PurchaseHeader.Modify();
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[1], PurchaseHeader, Item[1]."No.", 20, 4);
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[2], PurchaseHeader, Item[2]."No.", 30, 5);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', '', CDNo[1], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', '', CDNo[2], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', '', CDNo[1], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', '', CDNo[3], 3);

        PostingDate := CalcDate('<+5D>', WorkDate);
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibraryCDTracking.CreateSalesLineItem(SalesLine[1], SalesHeader, Item[1]."No.", 30, 3);
        SalesLine[1].Validate("Planned Delivery Date", PostingDate);
        SalesLine[1].Modify();
        LibraryCDTracking.CreateSalesLineItem(SalesLine[2], SalesHeader, Item[2]."No.", 40, 3);
        SalesLine[2].Validate("Planned Delivery Date", PostingDate);
        SalesLine[2].Modify();

        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[1], '', '', CDNo[1], 2);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[1], '', '', CDNo[2], 1);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[2], '', '', CDNo[1], 2);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[2], '', '', CDNo[3], 1);

        SalesLine[1].AutoReserve();
        SalesLine[2].AutoReserve();

        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[1], '', '', CDNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[1], '', '', CDNo[2], 1,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[2], '', '', CDNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[2], '', '', CDNo[3], 1,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', CDNo[1], -2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', CDNo[2], -1);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', CDNo[1], -2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', CDNo[3], -1);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', CDNo[1], 2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', CDNo[2], 2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', CDNo[1], 2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', CDNo[3], 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res2ItemCDLot_2PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[3] of Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDNo: array[3] of Code[30];
        LotNo: Code[20];
        PostingDate: Date;
    begin
        Initialize;

        InitComplexScenario(
          Vendor, Customer, Item, Location, true, false, true);

        LotNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo[1] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item[1]."No.", CDNo[1]);
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item[2]."No.", CDNo[1]);
        CDNo[2] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[2], Item[1]."No.", CDNo[2]);
        CDNo[3] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[3], Item[2]."No.", CDNo[3]);

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader[1], Vendor."No.", Location.Code);
        PurchaseHeader[1].Validate("Posting Date", WorkDate);
        PurchaseHeader[1].Modify();
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[1], PurchaseHeader[1], Item[1]."No.", 20, 4);

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader[2], Vendor."No.", Location.Code);
        PurchaseHeader[2].Validate("Posting Date", WorkDate);
        PurchaseHeader[2].Modify();
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[2], PurchaseHeader[2], Item[2]."No.", 30, 5);

        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', LotNo, CDNo[1], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', LotNo, CDNo[2], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', LotNo, CDNo[1], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', LotNo, CDNo[3], 3);

        PostingDate := CalcDate('<+5D>', WorkDate);
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibraryCDTracking.CreateSalesLineItem(SalesLine[1], SalesHeader, Item[1]."No.", 30, 3);
        SalesLine[1].Validate("Planned Delivery Date", PostingDate);
        SalesLine[1].Modify();
        LibraryCDTracking.CreateSalesLineItem(SalesLine[2], SalesHeader, Item[2]."No.", 40, 3);
        SalesLine[2].Validate("Planned Delivery Date", PostingDate);
        SalesLine[2].Modify();

        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[1], '', LotNo, CDNo[1], 2);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[1], '', LotNo, CDNo[2], 1);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[2], '', LotNo, CDNo[1], 2);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[2], '', LotNo, CDNo[3], 1);

        SalesLine[1].AutoReserve();
        SalesLine[2].AutoReserve();

        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[1], '', LotNo, CDNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[1], '', LotNo, CDNo[2], 1,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[2], '', LotNo, CDNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[2], '', LotNo, CDNo[3], 1,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo, CDNo[1], -2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo, CDNo[2], -1);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo, CDNo[1], -2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo, CDNo[3], -1);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo, CDNo[1], 2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo, CDNo[2], 2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo, CDNo[1], 2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo, CDNo[3], 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res2ItemCDLotSerial_2PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[3] of Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        LotNo: Code[20];
        PostingDate: Date;
        j: Integer;
    begin

        Initialize;

        InitComplexScenario(Vendor, Customer, Item, Location, true, true, true);
        LotNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo[1] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item[1]."No.", CDNo[1]);
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item[2]."No.", CDNo[1]);
        CDNo[2] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[2], Item[1]."No.", CDNo[2]);
        CDNo[3] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[3], Item[2]."No.", CDNo[3]);

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader[1], Vendor."No.", Location.Code);
        PurchaseHeader[1].Validate("Posting Date", WorkDate);
        PurchaseHeader[1].Modify();
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[1], PurchaseHeader[1], Item[1]."No.", 20, 4);

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader[2], Vendor."No.", Location.Code);
        PurchaseHeader[2].Validate("Posting Date", WorkDate);
        PurchaseHeader[2].Modify();
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[2], PurchaseHeader[2], Item[2]."No.", 30, 5);

        for j := 1 to 2 do begin
            SerialNo[j] := LibraryUtility.GenerateGUID + Format(j);
            LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], SerialNo[j],
              LotNo, CDNo[1], 1);
        end;
        for j := 1 to 2 do begin
            SerialNo[j + 2] := LibraryUtility.GenerateGUID + Format(j + 2);
            LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], SerialNo[j + 2],
              LotNo, CDNo[2], 1);
        end;
        for j := 1 to 2 do begin
            SerialNo[j + 4] := LibraryUtility.GenerateGUID + Format(j + 4);
            LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], SerialNo[j + 4],
              LotNo, CDNo[1], 1);
        end;
        for j := 1 to 3 do begin
            SerialNo[j + 6] := LibraryUtility.GenerateGUID + Format(j + 6);
            LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], SerialNo[j + 6],
              LotNo, CDNo[3], 1);
        end;

        PostingDate := CalcDate('<+5D>', WorkDate);
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibraryCDTracking.CreateSalesLineItem(SalesLine[1], SalesHeader, Item[1]."No.", 30, 3);
        SalesLine[1].Validate("Planned Delivery Date", PostingDate);
        SalesLine[1].Modify();
        LibraryCDTracking.CreateSalesLineItem(SalesLine[2], SalesHeader, Item[2]."No.", 40, 3);
        SalesLine[2].Validate("Planned Delivery Date", PostingDate);
        SalesLine[2].Modify();

        for j := 1 to 2 do begin
            LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[1], SerialNo[j],
              LotNo, CDNo[1], 1);
        end;
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[1], SerialNo[3],
          LotNo, CDNo[2], 1);
        for j := 1 to 2 do begin
            LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[2], SerialNo[j + 4],
              LotNo, CDNo[1], 1);
        end;
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[2], SerialNo[7],
          LotNo, CDNo[3], 1);

        SalesLine[1].AutoReserve();
        SalesLine[2].AutoReserve();

        for j := 1 to 2 do begin
            LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[1], SerialNo[j], LotNo, CDNo[1], 1,
              ReservationEntry."Reservation Status"::Reservation);
        end;
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[1], SerialNo[3], LotNo, CDNo[2], 1,
          ReservationEntry."Reservation Status"::Reservation);
        for j := 1 to 2 do begin
            LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[2], SerialNo[j + 4], LotNo, CDNo[1], 1,
              ReservationEntry."Reservation Status"::Reservation);
        end;
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[2], SerialNo[7], LotNo, CDNo[3], 1,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[j], LotNo, CDNo[1], -1);
        end;
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[3], LotNo, CDNo[2], -1);

        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[j + 4], LotNo, CDNo[1], -1);
        end;
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[7], LotNo, CDNo[3], -1);

        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[j], LotNo, CDNo[1], 1);
        end;
        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[j + 2], LotNo, CDNo[2], 1);
        end;
        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[j + 4], LotNo, CDNo[1], 1);
        end;
        for j := 1 to 3 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[j + 6], LotNo, CDNo[3], 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "1ItemCD_POCM"()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        SerialNo: array[10] of Code[20];
        CDNo: array[3] of Code[30];
        Qty: array[2] of Decimal;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, false, false, true);
        Qty[DocType::Order] := 3 * LibraryRandom.RandInt(10);
        Qty[DocType::"Credit Memo"] := Round(LibraryRandom.RandInt(10) / 3, 1);

        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.",
          Qty[DocType::Order], LibraryRandom.RandDec(100, 2));
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, false, Qty[DocType::Order], SerialNo, '', CDNo);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryCDTracking.CreatePurchCreditMemo(PurchaseHeader, Vendor."No.", Location.Code);
        LibraryCDTracking.CreatePurchLineItem(
          PurchaseLine, PurchaseHeader, Item."No.", LibraryRandom.RandDec(100, 2), Qty[DocType::"Credit Memo"]);
        CreateCreditMemoTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, false, Qty[DocType::"Credit Memo"], SerialNo, '', CDNo);

        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader, false, true, true);

        FindLastReturnShipment(ReturnShipmentHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", ReturnShipmentHeader."No.");
        LibraryCDTracking.CheckLastItemLedgerEntry(
          ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], -Qty[DocType::"Credit Memo"]);

        FindLastPurchReceipt(PurchRcptHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", PurchRcptHeader."No.");
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], Qty[DocType::Order]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "1ItemCDLot_POCM"()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        SerialNo: array[10] of Code[20];
        LotNo: Code[20];
        CDNo: array[3] of Code[30];
        Qty: array[2] of Decimal;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, false, true, true);

        Qty[DocType::Order] := 4;
        Qty[DocType::"Credit Memo"] := 2;
        LotNo := LibraryUtility.GenerateGUID;

        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.",
          Qty[DocType::Order], LibraryRandom.RandDec(100, 2));
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, false, Qty[DocType::Order], SerialNo, LotNo, CDNo);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryCDTracking.CreatePurchCreditMemo(PurchaseHeader, Vendor."No.", Location.Code);
        LibraryCDTracking.CreatePurchLineItem(
          PurchaseLine, PurchaseHeader, Item."No.", LibraryRandom.RandDec(100, 2), Qty[DocType::"Credit Memo"]);
        CreateCreditMemoTracking(
          CDType::"1 CD", PurchaseLine, ReservationEntry, false, Qty[DocType::"Credit Memo"], SerialNo, LotNo, CDNo);

        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader, false, true, true);

        FindLastReturnShipment(ReturnShipmentHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", ReturnShipmentHeader."No.");
        LibraryCDTracking.CheckLastItemLedgerEntry(
          ItemLedgerEntry, Item."No.", Location.Code, SerialNo[1], LotNo, CDNo[1], -Qty[DocType::"Credit Memo"]);

        FindLastPurchReceipt(PurchRcptHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", PurchRcptHeader."No.");
        LibraryCDTracking.CheckLastItemLedgerEntry(
          ItemLedgerEntry, Item."No.", Location.Code, SerialNo[1], LotNo, CDNo[1], Qty[DocType::Order]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "1ItemCDLotSerial_POCM"()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        SerialNo: array[10] of Code[20];
        LotNo: Code[20];
        CDNo: array[3] of Code[30];
        Qty: array[2] of Decimal;
        j: Integer;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, true, true, true);
        Qty[DocType::Order] := 3 * LibraryRandom.RandInt(10);
        Qty[DocType::"Credit Memo"] := Round(LibraryRandom.RandInt(10) / 3, 1);

        LotNo := LibraryUtility.GenerateGUID;

        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.",
          Qty[DocType::Order], LibraryRandom.RandDec(100, 2));
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, true, Qty[DocType::Order], SerialNo, LotNo, CDNo);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryCDTracking.CreatePurchCreditMemo(PurchaseHeader, Vendor."No.", Location.Code);
        LibraryCDTracking.CreatePurchLineItem(
          PurchaseLine, PurchaseHeader, Item."No.", LibraryRandom.RandDec(100, 2), Qty[DocType::"Credit Memo"]);
        CreateCreditMemoTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, true, Qty[DocType::"Credit Memo"], SerialNo, LotNo, CDNo);

        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader, false, true, true);

        FindLastReturnShipment(ReturnShipmentHeader, Vendor."No.");
        for j := 1 to Qty[DocType::"Credit Memo"] do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            ItemLedgerEntry.SetRange("Document No.", ReturnShipmentHeader."No.");
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], LotNo, CDNo[1], -1);
        end;

        FindLastPurchReceipt(PurchRcptHeader, Vendor."No.");
        for j := 1 to Qty[DocType::Order] do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            ItemLedgerEntry.SetRange("Document No.", PurchRcptHeader."No.");
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], LotNo, CDNo[1], 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "1ItemCD_POCMCopy"()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        PurchInvHeader: Record "Purch. Inv. Header";
        CopyPurchaseDocument: Report "Copy Purchase Document";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        DocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice","Posted Return Shipment","Posted Credit Memo";
        SerialNo: array[10] of Code[20];
        CDNo: array[3] of Code[30];
        Qty: Decimal;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, false, false, true);

        Qty := 4;
        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.", Qty, LibraryRandom.RandDec(100, 2));
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, false, Qty, SerialNo, '', CDNo);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Copying
        PurchInvHeader.SetCurrentKey("Buy-from Vendor No.");
        PurchInvHeader.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchInvHeader.FindFirst;

        LibraryCDTracking.CreatePurchCreditMemo(PurchaseHeader, Vendor."No.", Location.Code);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.InitializeRequest(DocType::"Posted Invoice", PurchInvHeader."No.", true, false);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run;

        PurchaseHeader.Find;
        PurchaseHeader.Validate(Correction, true);
        PurchaseHeader.Modify();

        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindFirst;
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, false, Qty, SerialNo, '', CDNo);
        ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify();

        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader, false, true, true);

        FindLastReturnShipment(ReturnShipmentHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", ReturnShipmentHeader."No.");
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], -Qty);

        FindLastPurchReceipt(PurchRcptHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", PurchRcptHeader."No.");
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "1ItemCDLot_POCMCopy"()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        PurchInvHeader: Record "Purch. Inv. Header";
        CopyPurchaseDocument: Report "Copy Purchase Document";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        DocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice","Posted Return Shipment","Posted Credit Memo";
        SerialNo: array[10] of Code[20];
        LotNo: Code[20];
        CDNo: array[3] of Code[30];
        Qty: Decimal;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, false, true, true);

        Qty := 4;
        LotNo := LibraryUtility.GenerateGUID;
        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.", Qty, LibraryRandom.RandDec(100, 2));
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, false, Qty, SerialNo, LotNo, CDNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.SetCurrentKey("Buy-from Vendor No.");
        PurchInvHeader.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchInvHeader.FindFirst;

        LibraryCDTracking.CreatePurchCreditMemo(PurchaseHeader, Vendor."No.", Location.Code);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.InitializeRequest(DocType::"Posted Invoice", PurchInvHeader."No.", true, false);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run;

        PurchaseHeader.Find;
        PurchaseHeader.Validate(Correction, true);
        PurchaseHeader.Modify();
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindFirst;
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, false, Qty, SerialNo, LotNo, CDNo);
        ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify();

        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader, false, true, true);

        FindLastReturnShipment(ReturnShipmentHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", ReturnShipmentHeader."No.");
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', LotNo, CDNo[1], -Qty);

        FindLastPurchReceipt(PurchRcptHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", PurchRcptHeader."No.");
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', LotNo, CDNo[1], Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "1ItemCDLotSerial_POCMCopy"()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        PurchInvHeader: Record "Purch. Inv. Header";
        CopyPurchaseDocument: Report "Copy Purchase Document";
        SerialNo: array[10] of Code[20];
        LotNo: Code[20];
        CDNo: array[3] of Code[30];
        QtyPO: Decimal;
        QtyCM: Decimal;
        DocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice","Posted Return Shipment","Posted Credit Memo";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        j: Integer;
    begin
        Initialize;
        InitScenario(Vendor, Customer, Item, Location, true, true, true);

        QtyPO := 4;
        LotNo := LibraryUtility.GenerateGUID;

        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate, Location.Code, Item."No.", QtyPO, 20);
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, true, QtyPO, SerialNo, LotNo, CDNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.SetCurrentKey("Buy-from Vendor No.");
        PurchInvHeader.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchInvHeader.FindFirst;

        LibraryCDTracking.CreatePurchCreditMemo(PurchaseHeader, Vendor."No.", Location.Code);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.InitializeRequest(DocType::"Posted Invoice", PurchInvHeader."No.", true, false);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run;

        PurchaseHeader.Find;
        PurchaseHeader.Validate(Correction, true);
        PurchaseHeader.Modify();
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindFirst;
        CreatePurchLineTracking(CDType::"1 CD", PurchaseLine, ReservationEntry, true, QtyPO, SerialNo, LotNo, CDNo);
        ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify();

        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader, false, true, true);

        FindLastReturnShipment(ReturnShipmentHeader, Vendor."No.");
        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            ItemLedgerEntry.SetRange("Document No.", ReturnShipmentHeader."No.");
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], LotNo, CDNo[1], -1);
        end;

        FindLastPurchReceipt(PurchRcptHeader, Vendor."No.");
        for j := 1 to 4 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            ItemLedgerEntry.SetRange("Document No.", PurchRcptHeader."No.");
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], LotNo, CDNo[1], 1);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,HndlConfirmTracking')]
    [Scope('OnPrem')]
    procedure Res1ItemCD_PartShip()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[3] of Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        PostingDate: Date;
        i: Integer;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, false, false, true);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo[1] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item."No.", CDNo[1]);
        CDNo[2] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[2], Item."No.", CDNo[2]);
        CDNo[3] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[3], Item."No.", CDNo[3]);

        CreatePurchaseOrder(PurchaseHeader[1], PurchaseLine[1], Vendor."No.", WorkDate, Location.Code, Item."No.", 6, 20);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', '', CDNo[1], 3);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', '', CDNo[2], 3);

        CreatePurchaseOrder(PurchaseHeader[2], PurchaseLine[2], Vendor."No.", WorkDate, Location.Code, Item."No.", 4, 20);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', '', CDNo[3], 4);

        PostingDate := CalcDate('<+5D>', WorkDate);
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibraryCDTracking.CreateSalesLineItem(SalesLine, SalesHeader, Item."No.", 30, 10);
        SalesLine.Validate("Planned Delivery Date", PostingDate);
        SalesLine.Validate("Qty. to Ship", 7);
        SalesLine.Modify();
        SalesLine.AutoReserve();

        LibraryCDTracking.CreateSalesTrkgFromRes(SalesHeader, false);

        LibraryVariableStorage.Enqueue(CDNo[1]);
        LibraryVariableStorage.Enqueue(3);
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(0);
        SalesLine.Find;
        SalesLine.OpenItemTrackingLines();

        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[1], '', '', CDNo[1], 3,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[1], '', '', CDNo[2], 3,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryCDTracking.CheckPurchReservationEntry(PurchaseLine[2], '', '', CDNo[3], 4,
          ReservationEntry."Reservation Status"::Reservation);

        for i := 1 to ArrayLen(PurchaseHeader) do
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader[i], true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[3], -4);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[2], -3);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], 3);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[2], 3);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[3], 4);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "2ItemSO_UndoShip"()
    var
        ItemChargeAssgntSales: array[2] of Record "Item Charge Assignment (Sales)";
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[3] of Record "CD No. Information";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemChargeAssgntSCode: Codeunit "Item Charge Assgnt. (Sales)";
        CDNo: array[3] of Code[30];
        SalesOrderNo: Code[20];
        ItemChargeNo: Code[20];
        PostingDate: Date;
    begin
        if true then // avoid precal issue
            exit; // Known issue
        Initialize;

        InitComplexScenario(Vendor, Customer, Item, Location, false, false, true);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo[1] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item[1]."No.", CDNo[1]);
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[1], Item[2]."No.", CDNo[1]);
        CDNo[2] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[2], Item[1]."No.", CDNo[2]);
        CDNo[3] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[3], Item[2]."No.", CDNo[3]);

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code);
        PurchaseHeader.Validate("Posting Date", WorkDate);
        PurchaseHeader.Modify();
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[1], PurchaseHeader, Item[1]."No.", 20, 4);
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[2], PurchaseHeader, Item[2]."No.", 30, 5);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', '', CDNo[1], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', '', CDNo[2], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', '', CDNo[1], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', '', CDNo[3], 3);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PostingDate := CalcDate('<+5D>', WorkDate);
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibraryCDTracking.CreateSalesLineItem(SalesLine[1], SalesHeader, Item[1]."No.", 30, 3);
        SalesLine[1].Validate("Planned Delivery Date", PostingDate);
        SalesLine[1].Modify();
        LibraryCDTracking.CreateSalesLineItem(SalesLine[2], SalesHeader, Item[2]."No.", 40, 3);
        SalesLine[2].Validate("Planned Delivery Date", PostingDate);
        SalesLine[2].Modify();

        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[1], '', '', CDNo[1], 2);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[1], '', '', CDNo[2], 1);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[2], '', '', CDNo[1], 2);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine[2], '', '', CDNo[3], 1);

        SalesOrderNo := SalesHeader."No.";

        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', CDNo[1], -2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', CDNo[2], -1);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', CDNo[1], -2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', CDNo[3], -1);

        SalesShipmentHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesShipmentHeader.SetRange("Order No.", SalesOrderNo);
        SalesShipmentHeader.FindFirst;
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.SetRange("No.", Item[1]."No.");
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.FindFirst;
        SalesShipmentLine.SetRecFilter;
        CODEUNIT.Run(CODEUNIT::"Undo Sales Shipment Line", SalesShipmentLine);
        SalesShipmentLine.Reset();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.SetRange("No.", Item[2]."No.");
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.FindFirst;
        SalesShipmentLine.SetRecFilter;
        CODEUNIT.Run(CODEUNIT::"Undo Sales Shipment Line", SalesShipmentLine);

        SalesHeader.SetRange("No.", SalesOrderNo);
        SalesHeader.FindFirst;
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        SalesHeader.Reset();
        SalesShipmentLine.Reset();
        SalesShipmentHeader.Reset();

        ItemChargeNo := LibraryInventory.CreateItemChargeNo;
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::"Charge (Item)", ItemChargeNo, 1);
        SalesLine[1].Validate("Unit Price", 100);
        SalesLine[1].Modify();

        SalesShipmentHeader.SetRange("Order No.", SalesOrderNo);
        SalesShipmentHeader.FindFirst;

        ItemChargeAssgntSales[1].Init();
        ItemChargeAssgntSales[1].Validate("Document Type", ItemChargeAssgntSales[1]."Document Type"::Order);
        ItemChargeAssgntSales[1].Validate("Document No.", SalesOrderNo);
        ItemChargeAssgntSales[1].Validate("Document Line No.", 10000);
        ItemChargeAssgntSales[1].Validate("Line No.", 10000);
        ItemChargeAssgntSales[1].Insert(true);
        ItemChargeAssgntSales[1].Validate("Item Charge No.", ItemChargeNo);
        ItemChargeAssgntSales[1].Validate("Item No.", Item[1]."No.");
        ItemChargeAssgntSales[1].Validate("Applies-to Doc. Type", ItemChargeAssgntSales[1]."Applies-to Doc. Type"::Shipment);
        ItemChargeAssgntSales[1].Validate("Applies-to Doc. No.", SalesShipmentHeader."No.");
        ItemChargeAssgntSales[1].Validate("Applies-to Doc. Line No.", 10000);
        ItemChargeAssgntSales[1].Validate("Unit Cost", 100);
        ItemChargeAssgntSales[1].Modify();

        ItemChargeAssgntSales[2].Init();
        ItemChargeAssgntSales[2].Validate("Document Type", ItemChargeAssgntSales[1]."Document Type"::Order);
        ItemChargeAssgntSales[2].Validate("Document No.", SalesOrderNo);
        ItemChargeAssgntSales[2].Validate("Document Line No.", 10000);
        ItemChargeAssgntSales[2].Validate("Line No.", 20000);
        ItemChargeAssgntSales[2].Insert(true);
        ItemChargeAssgntSales[2].Validate("Item Charge No.", ItemChargeNo);
        ItemChargeAssgntSales[2].Validate("Item No.", Item[2]."No.");
        ItemChargeAssgntSales[2].Validate("Applies-to Doc. Type",
          ItemChargeAssgntSales[2]."Applies-to Doc. Type"::Shipment);
        ItemChargeAssgntSales[2].Validate("Applies-to Doc. No.", SalesShipmentHeader."No.");
        ItemChargeAssgntSales[2].Validate("Applies-to Doc. Line No.", 20000);
        ItemChargeAssgntSales[2].Validate("Unit Cost", 100);
        ItemChargeAssgntSales[2].Modify();

        ItemChargeAssgntSCode.AssignItemCharges(SalesLine[1], 1, 1, ItemChargeAssgntSCode.AssignEquallyMenuText);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "1ItemCD_IRRedStorno"()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemReceiptHeader: Record "Item Receipt Header";
        CopyItemDocumentMgt: Codeunit "Copy Item Document Mgt.";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        ItemReceiptNo: Code[20];
        Qty: Decimal;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, false, false, true);
        WarehouseSetup;
        Qty := 6;
        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        ItemReceiptNo := ItemDocumentHeader."No.";
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty);
        CreateIRLineTracking(CDType::"1 CD", ItemDocumentLine, ReservationEntry, false, Qty, SerialNo, '', CDNo);
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], Qty);

        ItemReceiptHeader.SetRange("Receipt No.", ItemReceiptNo);
        ItemReceiptHeader.FindFirst;

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        CopyItemDocumentMgt.CopyItemDoc(ItemDocType::"Posted Receipt", ItemReceiptHeader."No.",
          ItemDocumentHeader);
        ItemDocumentHeader.Validate(Correction, true);
        ItemDocumentHeader.Modify();
        CreateIRLineTracking(CDType::"1 CD", ItemDocumentLine, ReservationEntry, false, Qty, SerialNo, '', CDNo);
        ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify();
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], -Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "1ItemCDLot_IRRedStorno"()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemReceiptHeader: Record "Item Receipt Header";
        CopyItemDocumentMgt: Codeunit "Copy Item Document Mgt.";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        LotNo: Code[20];
        ItemReceiptNo: Code[20];
        Qty: Decimal;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, false, true, true);
        WarehouseSetup;
        Qty := 6;
        LotNo := LibraryUtility.GenerateGUID;
        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        ItemReceiptNo := ItemDocumentHeader."No.";
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty);
        CreateIRLineTracking(CDType::"1 CD", ItemDocumentLine, ReservationEntry, false, Qty, SerialNo, LotNo, CDNo);
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', LotNo, CDNo[1], Qty);

        ItemReceiptHeader.SetRange("Receipt No.", ItemReceiptNo);
        ItemReceiptHeader.FindFirst;

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        CopyItemDocumentMgt.CopyItemDoc(ItemDocType::"Posted Receipt", ItemReceiptHeader."No.",
          ItemDocumentHeader);
        ItemDocumentHeader.Validate(Correction, true);
        ItemDocumentHeader.Modify();
        CreateIRLineTracking(CDType::"1 CD", ItemDocumentLine, ReservationEntry, false, Qty, SerialNo, LotNo, CDNo);
        ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify();
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', LotNo, CDNo[1], -Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "1ItemCDLotSerial_IRRedStorno"()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemReceiptHeader: Record "Item Receipt Header";
        CopyItemDocumentMgt: Codeunit "Copy Item Document Mgt.";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        LotNo: Code[20];
        ItemReceiptNo: Code[20];
        Qty: Decimal;
        j: Integer;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, true, true, true);
        WarehouseSetup;
        Qty := 6;
        LotNo := LibraryUtility.GenerateGUID;
        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        ItemReceiptNo := ItemDocumentHeader."No.";
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty);
        CreateIRLineTracking(CDType::"1 CD", ItemDocumentLine, ReservationEntry, true, Qty, SerialNo, LotNo, CDNo);
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        for j := 1 to Qty do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], LotNo, CDNo[1], 1);
        end;

        ItemReceiptHeader.SetRange("Receipt No.", ItemReceiptNo);
        ItemReceiptHeader.FindFirst;

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        CopyItemDocumentMgt.CopyItemDoc(ItemDocType::"Posted Receipt", ItemReceiptHeader."No.",
          ItemDocumentHeader);
        ItemDocumentHeader.Validate(Correction, true);
        ItemDocumentHeader.Modify();
        CreateIRLineTracking(CDType::"1 CD", ItemDocumentLine, ReservationEntry, true, Qty, SerialNo, LotNo, CDNo);
        ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify();
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        for j := 1 to Qty do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], LotNo, CDNo[1], -1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "1ItemCD_ISRedStorno"()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemShipmentHeader: Record "Item Shipment Header";
        CopyItemDocumentMgt: Codeunit "Copy Item Document Mgt.";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        ItemShipmentNo: Code[20];
        Qty: array[2] of Decimal;
        i: Integer;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, false, false, true);
        WarehouseSetup;
        Qty[ItemEntryType::Receipt] := 10 * LibraryRandom.RandInt(10);
        Qty[ItemEntryType::Shipment] := Round(Qty[ItemEntryType::Receipt] / 3, 1);
        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty[ItemEntryType::Receipt]);
        CreateIRLineTracking(CDType::"1 CD", ItemDocumentLine, ReservationEntry, false, Qty[ItemEntryType::Receipt], SerialNo, '', CDNo);
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], Qty[ItemEntryType::Receipt]);

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Shipment, Location.Code);
        ItemShipmentNo := ItemDocumentHeader."No.";
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty[ItemEntryType::Shipment]);
        LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine, '', '', CDNo[1], Qty[ItemEntryType::Shipment]);
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], -Qty[ItemEntryType::Shipment]);

        ItemShipmentHeader.SetRange("Shipment No.", ItemShipmentNo);
        ItemShipmentHeader.FindFirst;

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Shipment, Location.Code);
        CopyItemDocumentMgt.CopyItemDoc(ItemDocType::"Posted Shipment", ItemShipmentHeader."No.",
          ItemDocumentHeader);

        ItemDocumentHeader.Validate(Correction, true);
        ItemDocumentHeader.Modify();

        LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine, '', '', CDNo[1], Qty[ItemEntryType::Shipment]);
        ReservationEntry.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify();
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], Qty[ItemEntryType::Shipment]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "1ItemCDLot_ISRedStorno"()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        CDLine: Record "CD No. Information";
        CDHeader: Record "CD No. Header";
        ItemShipmentHeader: Record "Item Shipment Header";
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CopyItemDocumentMgt: Codeunit "Copy Item Document Mgt.";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        LotNo: Code[20];
        ItemNo: array[1] of Code[20];
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        ItemShipmentNo: Code[20];
        Qty: array[2] of Decimal;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, false, true, true);
        WarehouseSetup;
        Qty[ItemEntryType::Receipt] := 10 * LibraryRandom.RandInt(10);
        Qty[ItemEntryType::Shipment] := Round(Qty[ItemEntryType::Receipt] / 3, 1);
        LotNo := LibraryUtility.GenerateGUID;
        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty[ItemEntryType::Receipt]);
        CreateIRLineTracking(
          CDType::"1 CD", ItemDocumentLine, ReservationEntry, false, Qty[ItemEntryType::Receipt], SerialNo, LotNo, CDNo);

        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);
        LibraryCDTracking.CheckLastItemLedgerEntry(
          ItemLedgerEntry, Item."No.", Location.Code, '', LotNo, CDNo[1], Qty[ItemEntryType::Receipt]);

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Shipment, Location.Code);
        ItemShipmentNo := ItemDocumentHeader."No.";
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty[ItemEntryType::Shipment]);
        LibraryCDTracking.CreateItemDocumentLineTracking(
          ReservationEntry, ItemDocumentLine, '', LotNo, CDNo[1], Qty[ItemEntryType::Shipment]);

        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        LibraryCDTracking.CheckLastItemLedgerEntry(
          ItemLedgerEntry, Item."No.", Location.Code, '', LotNo, CDNo[1], -Qty[ItemEntryType::Shipment]);

        ItemShipmentHeader.SetRange("Shipment No.", ItemShipmentNo);
        ItemShipmentHeader.FindFirst;

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Shipment, Location.Code);
        CopyItemDocumentMgt.CopyItemDoc(
          ItemDocType::"Posted Shipment", ItemShipmentHeader."No.", ItemDocumentHeader);

        ItemDocumentHeader.Validate(Correction, true);
        ItemDocumentHeader.Modify();

        LibraryCDTracking.CreateItemDocumentLineTracking(
          ReservationEntry, ItemDocumentLine, '', LotNo, CDNo[1], Qty[ItemEntryType::Shipment]);
        ReservationEntry.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify();
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        LibraryCDTracking.CheckLastItemLedgerEntry(
          ItemLedgerEntry, Item."No.", Location.Code, '', LotNo, CDNo[1], Qty[ItemEntryType::Shipment]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "1ItemCDLotSerial_ISRedStorno"()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        ItemShipmentHeader: Record "Item Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CopyItemDocumentMgt: Codeunit "Copy Item Document Mgt.";
        CDNo: array[3] of Code[30];
        SerialNo: array[10] of Code[20];
        LotNo: Code[20];
        ItemNo: array[1] of Code[20];
        Qty: array[2] of Decimal;
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        ItemShipmentNo: Code[20];
        j: Integer;
    begin
        Initialize;

        InitScenario(Vendor, Customer, Item, Location, true, true, true);
        WarehouseSetup;
        Qty[ItemEntryType::Receipt] := 10 * LibraryRandom.RandInt(10);
        Qty[ItemEntryType::Shipment] := Round(Qty[ItemEntryType::Receipt] / 3, 1);
        LotNo := LibraryUtility.GenerateGUID;
        CreateCD(CDType::"1 CD", CDHeader, CDLine, Item, CDNo);

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty[ItemEntryType::Receipt]);
        CreateIRLineTracking(CDType::"1 CD", ItemDocumentLine, ReservationEntry, true, Qty[ItemEntryType::Receipt], SerialNo, LotNo, CDNo);
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        for j := 1 to Qty[ItemEntryType::Receipt] do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], LotNo, CDNo[1], 1);
        end;

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Shipment, Location.Code);
        ItemShipmentNo := ItemDocumentHeader."No.";
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty[ItemEntryType::Shipment]);

        for j := 1 to Qty[ItemEntryType::Shipment] do begin
            LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine, SerialNo[j], LotNo, CDNo[1], 1);
        end;
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        for j := 1 to Qty[ItemEntryType::Shipment] do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], LotNo, CDNo[1], -1);
        end;

        ItemShipmentHeader.SetRange("Shipment No.", ItemShipmentNo);
        ItemShipmentHeader.FindFirst;

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Shipment, Location.Code);
        CopyItemDocumentMgt.CopyItemDoc(ItemDocType::"Posted Shipment", ItemShipmentHeader."No.",
          ItemDocumentHeader);

        ItemDocumentHeader.Validate(Correction, true);
        ItemDocumentHeader.Modify();

        for j := 1 to Qty[ItemEntryType::Shipment] do begin
            LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine, SerialNo[j], LotNo, CDNo[1], 1);
        end;

        ReservationEntry.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify();
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        for j := 1 to Qty[ItemEntryType::Shipment] do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], LotNo, CDNo[1], 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "1FAWriteOffLot_2ItemsIR"()
    var
        CDTrackingSetup: Record "CD Tracking Setup";
        Vendor: Record Vendor;
        Location: Record Location;
        Customer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        PurchaseHeader: Record "Purchase Header";
        FA: Record "Fixed Asset";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Item: array[2] of Record Item;
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: array[2] of Record "Item Document Line";
        FADocHeader: Record "FA Document Header";
        FADocLine: Record "FA Document Line";
        CopySalesDocument: Report "Copy Sales Document";
        LibrarySales: Codeunit "Library - Sales";
        CopyFixedAsset: Report "Copy Fixed Asset";
        VATLedgerCode: Code[20];
        CDNo: array[2] of Code[30];
        SaleDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
        WriteoffDate: Date;
        ReleaseDate: Date;
        QtyFA: Integer;
        QtyIR: Decimal;
        DocType: Option Writeoff,Release,Movement;
        StartDate: Date;
        EndDate: Date;
        ItemReceiptNo: Code[20];
        LotNo: Code[20];
        i: Integer;
    begin
        Initialize;
        LibraryCDTracking.CreateForeignVendor(Vendor);
        LotNo := LibraryUtility.GenerateGUID;
        LibrarySales.CreateCustomer(Customer);
        LibraryCDTracking.CreateFixedAsset(FA);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, false);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);
        for i := 1 to 2 do
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo[1] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateFACDInfo(CDHeader, CDLine, FA."No.", CDNo[1]);
        FA.Validate("CD No.", CDNo[1]);
        FA.Modify();

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code);
        QtyFA := 1;
        LibraryCDTracking.CreatePurchLineFA(
          PurchaseLine, PurchaseHeader, FA."No.", LibraryRandom.RandDec(100, 2), QtyFA);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryCDTracking.CreateFAReleaseAct(FADocHeader, FA."No.", CalcDate('<+1D>', WorkDate));
        LibraryCDTracking.PostFAReleaseAct(FADocHeader);

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryCDTracking.CreateItemDocumentLine(ItemDocumentHeader, ItemDocumentLine[1], Item[1]."No.", 20, 1);
        LibraryCDTracking.CreateItemDocumentLine(ItemDocumentHeader, ItemDocumentLine[2], Item[2]."No.", 30, 1);
        LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine[1], '', LotNo, '', 1);
        LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine[2], '', LotNo, '', 1);
        ItemReceiptNo := ItemDocumentHeader."No.";

        LibraryCDTracking.CreateFAWriteOffAct(FADocHeader, FA."No.", CalcDate('<+2D>', WorkDate));
        FADocLine.SetRange("Document No.", FADocHeader."No.");
        FADocLine.SetRange("Document Type", FADocHeader."Document Type");
        FADocLine.FindFirst;
        FADocLine.Validate("Item Receipt No.", ItemReceiptNo);
        LibraryCDTracking.PostFAWriteOffAct(FADocHeader);

        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item[1]."No.", Location.Code, LotNo, '', 1);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item[2]."No.", Location.Code, LotNo, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "1FAWriteOffCD_2ItemsIR"()
    var
        CDTrackingSetup: Record "CD Tracking Setup";
        Vendor: Record Vendor;
        Location: Record Location;
        Customer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        PurchaseHeader: Record "Purchase Header";
        FA: Record "Fixed Asset";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Item: array[2] of Record Item;
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: array[2] of Record "Item Document Line";
        FADocHeader: Record "FA Document Header";
        FADocLine: Record "FA Document Line";
        CopySalesDocument: Report "Copy Sales Document";
        CopyFixedAsset: Report "Copy Fixed Asset";
        LibrarySales: Codeunit "Library - Sales";
        VATLedgerCode: Code[20];
        CDNo: array[2] of Code[30];
        SaleDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
        WriteoffDate: Date;
        ReleaseDate: Date;
        QtyFA: Integer;
        QtyIR: Decimal;
        DocType: Option Writeoff,Release,Movement;
        StartDate: Date;
        EndDate: Date;
        ItemReceiptNo: Code[20];
        LotNo: Code[20];
        i: Integer;
    begin
        Initialize;
        LibraryCDTracking.CreateForeignVendor(Vendor);
        LibrarySales.CreateCustomer(Customer);
        LibraryCDTracking.CreateFixedAsset(FA);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);
        for i := 1 to ArrayLen(Item) do
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo[1] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateFACDInfo(CDHeader, CDLine, FA."No.", CDNo[1]);
        FA.Validate("CD No.", CDNo[1]);
        FA.Modify();
        for i := 1 to ArrayLen(Item) do
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item[i]."No.", CDNo[1]);

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code);
        QtyFA := 1;
        LibraryCDTracking.CreatePurchLineFA(
          PurchaseLine, PurchaseHeader, FA."No.", LibraryRandom.RandDec(100, 2), QtyFA);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryCDTracking.CreateFAReleaseAct(FADocHeader, FA."No.", CalcDate('<+1D>', WorkDate));
        LibraryCDTracking.PostFAReleaseAct(FADocHeader);

        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryCDTracking.CreateItemDocumentLine(ItemDocumentHeader, ItemDocumentLine[1], Item[1]."No.", 20, 1);
        LibraryCDTracking.CreateItemDocumentLine(ItemDocumentHeader, ItemDocumentLine[2], Item[2]."No.", 30, 1);
        LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine[1], '', '', CDNo[1], 1);
        LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine[2], '', '', CDNo[1], 1);
        ItemReceiptNo := ItemDocumentHeader."No.";

        LibraryCDTracking.CreateFAWriteOffAct(FADocHeader, FA."No.", CalcDate('<+2D>', WorkDate));
        FADocLine.SetRange("Document No.", FADocHeader."No.");
        FADocLine.SetRange("Document Type", FADocHeader."Document Type");
        FADocLine.FindFirst;
        FADocLine.Validate("Item Receipt No.", ItemReceiptNo);
        LibraryCDTracking.PostFAWriteOffAct(FADocHeader);
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        for i := 1 to ArrayLen(Item) do
            CheckILEs(
              ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item[i]."No.", Location.Code, '', CDNo[1], 1);
    end;

    [Test]
    [HandlerFunctions('HndlConfirmExRateAndTracking')]
    [Scope('OnPrem')]
    procedure Res1ItemFIFO4CD_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: array[4] of Record "Purchase Header";
        PurchaseLine: array[4] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[4] of Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        CDNo: array[4] of Code[30];
        SerialNo: array[10] of Code[20];
        QtyPO: Decimal;
        QtySO: Decimal;
        i: Integer;
    begin
        Initialize;
        InitScenario(Vendor, Customer, Item, Location, false, false, true);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Modify();

        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item."No.", CDNo[i]);
        end;

        CreatePurchaseOrder(PurchaseHeader[1], PurchaseLine[1], Vendor."No.", WorkDate, Location.Code, Item."No.", 5, 100);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', '', CDNo[1], 5);
        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader[1], true, true, false);
        CreatePurchaseOrder(PurchaseHeader[2], PurchaseLine[2], Vendor."No.", CalcDate('<+1D>', WorkDate), Location.Code, Item."No.", 1, 120);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', '', CDNo[2], 1);
        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader[2], true, true, false);
        CreatePurchaseOrder(PurchaseHeader[3], PurchaseLine[3], Vendor."No.", CalcDate('<+2D>', WorkDate), Location.Code, Item."No.", 3, 101);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[3], '', '', CDNo[3], 3);
        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader[3], true, true, false);
        CreatePurchaseOrder(PurchaseHeader[4], PurchaseLine[4], Vendor."No.", CalcDate('<+3D>', WorkDate), Location.Code, Item."No.", 2, 131);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[4], '', '', CDNo[4], 2);
        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader[4], true, true, false);

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate, Location.Code, Item."No.", 7);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;

        SalesLine.ReserveFromInventory(SalesLine);
        LibraryCDTracking.CreateSalesTrkgFromRes(SalesHeader, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, '', CDNo[1], -5);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, '', CDNo[2], -1);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, '', CDNo[3], -1);
    end;

    [Test]
    [HandlerFunctions('HndlConfirmExRateAndTracking')]
    [Scope('OnPrem')]
    procedure Res1ItemAverage4CD_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: array[4] of Record "Purchase Header";
        PurchaseLine: array[4] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[4] of Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        CDNo: array[4] of Code[30];
        SerialNo: array[10] of Code[20];
        QtyPO: Decimal;
        QtySO: Decimal;
        i: Integer;
    begin
        Initialize;
        InitScenario(Vendor, Customer, Item, Location, false, false, true);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify();

        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item."No.", CDNo[i]);
        end;

        CreatePurchaseOrder(PurchaseHeader[1], PurchaseLine[1], Vendor."No.", WorkDate, Location.Code, Item."No.", 5, 100);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', '', CDNo[1], 5);
        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader[1], true, true, false);
        CreatePurchaseOrder(PurchaseHeader[2], PurchaseLine[2], Vendor."No.", CalcDate('<+1D>', WorkDate), Location.Code, Item."No.", 1, 120);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', '', CDNo[2], 1);
        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader[2], true, true, false);
        CreatePurchaseOrder(PurchaseHeader[3], PurchaseLine[3], Vendor."No.", CalcDate('<+2D>', WorkDate), Location.Code, Item."No.", 3, 101);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[3], '', '', CDNo[3], 3);
        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader[3], true, true, false);
        CreatePurchaseOrder(PurchaseHeader[4], PurchaseLine[4], Vendor."No.", CalcDate('<+3D>', WorkDate), Location.Code, Item."No.", 2, 131);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[4], '', '', CDNo[4], 2);
        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader[4], true, true, false);

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate, Location.Code, Item."No.", 7);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;

        SalesLine.ReserveFromInventory(SalesLine);
        LibraryCDTracking.CreateSalesTrkgFromRes(SalesHeader, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, '', CDNo[1], -5);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, '', CDNo[2], -1);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, '', CDNo[3], -1);
    end;

    [Test]
    [HandlerFunctions('HndlConfirmExRateAndTracking')]
    [Scope('OnPrem')]
    procedure Res1ItemSpecific4CD_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: array[4] of Record "Purchase Header";
        PurchaseLine: array[4] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: array[4] of Record "CD No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        CDNo: array[4] of Code[30];
        SerialNo: array[11] of Code[20];
        QtyPO: Decimal;
        QtySO: Decimal;
        j: Integer;
    begin
        Initialize;
        InitScenario(Vendor, Customer, Item, Location, true, false, true);
        Item.Validate("Costing Method", Item."Costing Method"::Specific);
        Item.Modify();

        for j := 1 to ArrayLen(CDNo) do begin
            CDNo[j] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[j], Item."No.", CDNo[j]);
        end;

        CreatePurchaseOrder(PurchaseHeader[1], PurchaseLine[1], Vendor."No.", WorkDate, Location.Code, Item."No.", 5, 100);
        CreatePurchaseOrder(PurchaseHeader[2], PurchaseLine[2], Vendor."No.", CalcDate('<+1D>', WorkDate), Location.Code, Item."No.", 1, 120);
        CreatePurchaseOrder(PurchaseHeader[3], PurchaseLine[3], Vendor."No.", CalcDate('<+2D>', WorkDate), Location.Code, Item."No.", 3, 101);
        CreatePurchaseOrder(PurchaseHeader[4], PurchaseLine[4], Vendor."No.", CalcDate('<+3D>', WorkDate), Location.Code, Item."No.", 2, 131);

        for j := 1 to 11 do begin
            SerialNo[j] := LibraryUtility.GenerateGUID + Format(j);
            case j of
                1 .. 5:
                    LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], SerialNo[j], '', CDNo[1], 1);
                6:
                    LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], SerialNo[j], '', CDNo[2], 1);
                7 .. 9:
                    LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[3], SerialNo[j], '', CDNo[3], 1);
                10 .. 11:
                    LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[4], SerialNo[j], '', CDNo[4], 1);
            end;
        end;

        for j := 1 to 4 do
            LibraryCDTracking.PostPurchaseDocument(PurchaseHeader[j], true, true, false);

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate, Location.Code, Item."No.", 7);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;

        SalesLine.ReserveFromInventory(SalesLine);
        LibraryCDTracking.CreateSalesTrkgFromRes(SalesHeader, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        for j := 1 to 7 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            case j of
                1 .. 5:
                    LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], '', CDNo[1], -1);
                6:
                    LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], '', CDNo[2], -1);
                7:
                    LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], '', CDNo[3], -1);
            end;
        end;
    end;

    local procedure InitScenario(var Vendor: Record Vendor; var Customer: Record Customer; var Item: Record Item; var Location: Record Location; NewSerialTracking: Boolean; NewLotTracking: Boolean; NewCDTracking: Boolean)
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryCDTracking.CreateForeignVendor(Vendor);
        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, NewSerialTracking, NewLotTracking, NewCDTracking);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryCDTracking.CreateItemUnitOfMeasure(Item."No.", UnitOfMeasure.Code, 20);
    end;

    local procedure InitComplexScenario(var Vendor: Record Vendor; var Customer: Record Customer; var Item: array[2] of Record Item; var Location: Record Location; NewLotTracking: Boolean; NewSerialTracking: Boolean; NewCDTracking: Boolean)
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryCDTracking.CreateForeignVendor(Vendor);
        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, NewSerialTracking, NewLotTracking, NewCDTracking);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item[1], ItemTrackingCode.Code);
        LibraryCDTracking.CreateItemUnitOfMeasure(Item[1]."No.", UnitOfMeasure.Code, 20);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item[2], ItemTrackingCode.Code);
        LibraryCDTracking.CreateItemUnitOfMeasure(Item[2]."No.", UnitOfMeasure.Code, 20);
    end;

    local procedure UpdateSerialNos(var SerialNo: array[10] of Code[20]; i: Integer)
    begin
        if i = 1 then
            SerialNo[i] := TestSerialTxt
        else
            SerialNo[i] := IncStr(SerialNo[i - 1]);
    end;

    local procedure WarehouseSetup()
    var
        InvSetup: Record "Inventory Setup";
    begin
        InvSetup.Get();
        if not InvSetup."Enable Red Storno" then
            InvSetup."Enable Red Storno" := true;
        InvSetup.Modify();
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; PostingDate: Date; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal)
    begin
        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, VendorNo, LocationCode);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify();
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, ItemNo, UnitCost, Qty);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; PostingDate: Date; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        NewDate: Date;
    begin
        LibraryCDTracking.CreateSalesOrder(SalesHeader, CustomerNo, LocationCode);
        NewDate := CalcDate('<+5D>', PostingDate);
        SalesHeader.Validate("Posting Date", NewDate);
        SalesHeader.Validate("Order Date", NewDate);
        SalesHeader.Modify();
        LibraryCDTracking.CreateSalesLineItem(SalesLine, SalesHeader, ItemNo, 30, Qty);
        SalesLine.Validate("Planned Delivery Date", NewDate);
        SalesLine.Modify();
    end;

    local procedure CreateCD(Type: Option "1 CD","Empty CD","2 CDs","3 CDs"; var CDHeader: Record "CD No. Header"; var CDLine: Record "CD No. Information"; Item: Record Item; var CDNo: array[3] of Code[30])
    begin
        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        case Type of
            Type::"1 CD":
                begin
                    CDNo[1] := LibraryUtility.GenerateGUID;
                    LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[1]);
                end;
            Type::"Empty CD":
                begin
                    CDNo[1] := '';
                    LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[1]);
                end;
            Type::"2 CDs":
                begin
                    CDNo[1] := LibraryUtility.GenerateGUID;
                    LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[1]);
                    CDNo[2] := LibraryUtility.GenerateGUID;
                    LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[2]);
                end;
        end;
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

    local procedure CreatePurchLineTracking(Type: Option "1 CD","Empty CD","2 CDs","3 CDs"; var PurchaseLine: Record "Purchase Line"; var ReservationEntry: Record "Reservation Entry"; NewSerialTracking: Boolean; Qty: Decimal; var SerialNo: array[10] of Code[20]; LotNo: Code[20]; CDNo: array[3] of Code[30])
    var
        j: Integer;
    begin
        case Type of
            Type::"1 CD",
            Type::"Empty CD":
                begin
                    if not NewSerialTracking then
                        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', LotNo, CDNo[1], Qty)
                    else
                        for j := 1 to Qty do begin
                            UpdateSerialNos(SerialNo, j);
                            LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, SerialNo[j], LotNo, CDNo[1], 1);
                        end;
                end;
            Type::"2 CDs":
                begin
                    if not NewSerialTracking then begin
                        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', LotNo, CDNo[1],
                          Round(Qty / 2, 1));
                        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', LotNo, CDNo[2], Qty - Round(Qty / 2, 1));
                    end
                    else
                        for j := 1 to Qty do begin
                            UpdateSerialNos(SerialNo, j);
                            case j of
                                1 .. Round(Qty / 2, 1):
                                    LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, SerialNo[j], LotNo, CDNo[1], 1);
                                (Round(Qty / 2, 1) + 1) .. Qty:
                                    LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, SerialNo[j], LotNo, CDNo[2], 1);
                            end;
                        end;
                end;
        end;
    end;

    local procedure CreateIRLineTracking(Type: Option "1 CD","Empty CD","2 CDs","3 CDs"; var ItemDocumentLine: Record "Item Document Line"; var ReservationEntry: Record "Reservation Entry"; NewSerialTracking: Boolean; Qty: Decimal; var SerialNo: array[10] of Code[20]; LotNo: Code[20]; CDNo: array[3] of Code[30])
    var
        j: Integer;
    begin
        case Type of
            Type::"1 CD",
            Type::"Empty CD":
                begin
                    if not NewSerialTracking then
                        LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine, '', LotNo, CDNo[1], Qty)
                    else
                        for j := 1 to Qty do begin
                            UpdateSerialNos(SerialNo, j);
                            LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine, SerialNo[j], LotNo, CDNo[1], 1);
                        end;
                end;
            Type::"2 CDs":
                begin
                    if not NewSerialTracking then begin
                        LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine, '', LotNo, CDNo[1], Round(Qty / 2, 1));
                        LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine, '', LotNo, CDNo[2],
                          Qty - Round(Qty / 2, 1));
                    end else
                        for j := 1 to Qty do begin
                            UpdateSerialNos(SerialNo, j);
                            case j of
                                1 .. Round(Qty / 2, 1):
                                    LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine, SerialNo[j], LotNo, CDNo[1], 1);
                                (Round(Qty / 2, 1) + 1) .. Qty:
                                    LibraryCDTracking.CreateItemDocumentLineTracking(ReservationEntry, ItemDocumentLine, SerialNo[j], LotNo, CDNo[2], 1);
                            end;
                        end;
                end;
        end;
    end;

    local procedure CreateSalesLineTracking(Type: Option "1 CD","Empty CD","2 CDs","3 CDs"; var SalesLine: Record "Sales Line"; var ReservationEntry: Record "Reservation Entry"; NewSerialTracking: Boolean; Qty: Decimal; var SerialNo: array[10] of Code[20]; LotNo: Code[20]; CDNo: array[3] of Code[30])
    var
        j: Integer;
    begin
        case Type of
            Type::"1 CD",
            Type::"Empty CD":
                begin
                    if not NewSerialTracking then
                        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, '', LotNo, CDNo[1], Qty)
                    else
                        for j := 1 to Qty do
                            LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, SerialNo[j], LotNo, CDNo[1], 1);
                end;
            Type::"2 CDs":
                begin
                    if not NewSerialTracking then begin
                        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, '', LotNo, CDNo[1], Round(Qty / 2, 1));
                        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, '', LotNo, CDNo[2], Qty - Round(Qty / 2, 1));
                    end else
                        for j := 1 to Qty do
                            case j of
                                1 .. Round(Qty / 2, 1):
                                    LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, SerialNo[j], LotNo, CDNo[1], 1);
                                Round(Qty / 2, 1) + 1 .. Qty:
                                    LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, SerialNo[j], LotNo, CDNo[2], 1);
                            end;
                end;
        end;
    end;

    local procedure CreateCreditMemoTracking(Type: Option "1 CD","Empty CD","2 CDs","3 CDs"; var PurchaseLine: Record "Purchase Line"; var ReservationEntry: Record "Reservation Entry"; NewSerialTracking: Boolean; Qty: Decimal; var SerialNo: array[10] of Code[20]; LotNo: Code[20]; CDNo: array[3] of Code[30])
    var
        j: Integer;
    begin
        case Type of
            Type::"1 CD",
            Type::"Empty CD":
                begin
                    if not NewSerialTracking then
                        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', LotNo, CDNo[1], Qty)
                    else
                        for j := 1 to Qty do
                            LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, SerialNo[j], LotNo, CDNo[1], 1);
                end;
            Type::"2 CDs":
                begin
                    if not NewSerialTracking then begin
                        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, SerialNo[j], LotNo, CDNo[1], Round(Qty / 2, 1));
                        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, SerialNo[j], LotNo, CDNo[2],
                          Qty - Round(Qty / 2, 1));
                    end else
                        for j := 1 to Qty do
                            case j of
                                1 .. Round(Qty / 2, 1):
                                    LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, SerialNo[j], LotNo, CDNo[1], 1);
                                Round(Qty / 2, 1) + 1 .. Qty:
                                    LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, SerialNo[j], LotNo, CDNo[2], 1);
                            end;
                end;
        end;
    end;

    local procedure CreatePOSOReservation(Type: Option "1 CD","Empty CD","2 CDs","3 CDs"; SalesHeader: Record "Sales Header"; PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; QtyRPO: Decimal; LotNo: Code[20]; CDNo: array[3] of Code[30])
    begin
        case Type of
            Type::"1 CD",
            Type::"Empty CD":
                begin
                    LibraryReservation.CreateReservEntryFrom(37, 1, SalesHeader."No.", '', 0, 10000, 1, '', LotNo, CDNo[1]);
                    LibraryReservation.CreateEntry(ItemNo, '', LocationCode, '', CalcDate('<+1D>', WorkDate), CalcDate('<+5D>', WorkDate), 0, "Reservation Status"::Reservation);
                    LibraryReservation.CreateReservEntryFor(39, 1, PurchaseHeader."No.", '', 0, 10000, 1, QtyRPO, QtyRPO, '', LotNo, CDNo[1]);
                    LibraryReservation.CreateEntry(ItemNo, '', LocationCode, '', CalcDate('<+1D>', WorkDate), CalcDate('<+5D>', WorkDate), 0, "Reservation Status"::Reservation);
                end;
            Type::"2 CDs":
                begin
                    LibraryReservation.CreateReservEntryFrom(37, 1, SalesHeader."No.", '', 0, 10000, 1, '', LotNo, CDNo[1]);
                    LibraryReservation.CreateEntry(ItemNo, '', LocationCode, '', CalcDate('<+1D>', WorkDate), CalcDate('<+5D>', WorkDate), 0, "Reservation Status"::Reservation);
                    LibraryReservation.CreateReservEntryFor(
                      39, 1, PurchaseHeader."No.", '', 0, 10000, 1, Round(QtyRPO / 2, 1), Round(QtyRPO / 2, 1), '', LotNo, CDNo[1]);
                    LibraryReservation.CreateEntry(ItemNo, '', LocationCode, '', CalcDate('<+1D>', WorkDate), CalcDate('<+5D>', WorkDate), 0, "Reservation Status"::Reservation);
                    LibraryReservation.CreateReservEntryFrom(37, 1, SalesHeader."No.", '', 0, 10000, 1, '', LotNo, CDNo[1]);
                    LibraryReservation.CreateEntry(ItemNo, '', LocationCode, '', CalcDate('<+1D>', WorkDate), CalcDate('<+5D>', WorkDate), 0, "Reservation Status"::Reservation);
                    LibraryReservation.CreateReservEntryFor(39, 1, PurchaseHeader."No.", '', 0, 10000, 1, QtyRPO - Round(QtyRPO / 2, 1),
                      QtyRPO - Round(QtyRPO / 2, 1), '', LotNo, CDNo[2]);
                    LibraryReservation.CreateEntry(ItemNo, '', LocationCode, '', CalcDate('<+1D>', WorkDate), CalcDate('<+5D>', WorkDate), 0, "Reservation Status"::Reservation);
                end;
        end;
    end;

    local procedure CreateIRSOReservation(SalesHeader: Record "Sales Header"; ItemDocumentHeader: Record "Item Document Header"; LocationCode: Code[10]; ItemNo: Code[20]; QtyRIR: Integer; LotNo: Code[20]; CDNo: array[3] of Code[30])
    begin
        LibraryReservation.CreateReservEntryFrom(37, 1, SalesHeader."No.", '', 0, 10000, 1, '', LotNo, CDNo[1]);
        LibraryReservation.CreateEntry(ItemNo, '', LocationCode, '', CalcDate('<+1D>', WorkDate), CalcDate('<+5D>', WorkDate), 0, "Reservation Status"::Reservation);
        LibraryReservation.CreateReservEntryFor(12453, 0, ItemDocumentHeader."No.", '', 0, 10000,
          1, QtyRIR, QtyRIR, '', LotNo, CDNo[1]);
        LibraryReservation.CreateEntry(ItemNo, '', LocationCode, '', CalcDate('<+1D>', WorkDate), CalcDate('<+5D>', WorkDate), 0, "Reservation Status"::Reservation);
    end;

    local procedure CheckILEs(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LocationCode: Code[10]; LotNo: Code[20]; CDNo: Code[30]; Qty: Decimal)
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, ItemNo, LocationCode, '', LotNo, CDNo, Qty);
    end;

    local procedure CheckILEsWithSerial(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LocationCode: Code[10]; SerialNo: array[10] of Code[20]; LotNo: Code[20]; CDNo: Code[30]; Qty: Decimal)
    var
        j: Integer;
        sign: Integer;
    begin
        if Qty > 0 then
            sign := 1
        else
            sign := -1;

        for j := 1 to Abs(Qty) do begin
            ItemLedgerEntry.SetRange("Entry Type", EntryType);
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, ItemNo, LocationCode, SerialNo[j], LotNo, CDNo, sign * 1);
        end;
    end;

    local procedure FindLastReturnShipment(var ReturnShipmentHeader: Record "Return Shipment Header"; VendNo: Code[20])
    begin
        ReturnShipmentHeader.SetRange("Buy-from Vendor No.", VendNo);
        ReturnShipmentHeader.FindLast;
    end;

    local procedure FindLastPurchReceipt(var PurchRcptHeader: Record "Purch. Rcpt. Header"; VendNo: Code[20])
    begin
        PurchRcptHeader.SetRange("Buy-from Vendor No.", VendNo);
        PurchRcptHeader.FindLast;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.FILTER.SetFilter("CD No.", LibraryVariableStorage.DequeueText);
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal);
        ItemTrackingLines."Qty. to Handle (Base)".SetValue(LibraryVariableStorage.DequeueDecimal);
        ItemTrackingLines."Qty. to Invoice (Base)".SetValue(LibraryVariableStorage.DequeueDecimal);
        ItemTrackingLines.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HndlConfirmUndo(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, DoYouWantToUndoMsg) = 0 then
            Error(IncorrectConfirmDialogErr + Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HndlConfirmTracking(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, FunctionCreateSpecMsg) = 0 then
            Error(IncorrectConfirmDialogErr + Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HndlConfirmExRateAndTracking(Question: Text[1024]; var Reply: Boolean)
    begin
        if (StrPos(Question, DoYouWantYoUpdMsg) = 0) and (StrPos(Question, FunctionCreateSpecMsg) = 0)
        then
            Error(IncorrectConfirmDialogErr + Question);
        Reply := true;
    end;
}

