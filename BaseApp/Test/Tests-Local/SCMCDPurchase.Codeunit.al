codeunit 147102 "SCM CD Purchase"
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryCDTracking: Codeunit "Library - CD Tracking";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        DocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice","Posted Return Shipment","Posted Credit Memo";
        CDNoRequiredErr: Label 'You must assign a CD number for item %1.', Comment = '%1 - Item No.';
        CDLineFoundErr: Label '%1  is not found, filters: %2.';
        CDLineQtyErr: Label 'Incorrect quantity for CD Line No. = %1, filters: %2.';
        CDNoInfoDoesNotExistErr: Label 'The CD No. Information does not exist.';
        ItemTrackingSerialLotCDMsg: Label 'Item Tracking Serial No.  Lot No.  CD No.';
        IncorrConfirmDialogOpenedErr: Label 'Incorrect confirm dialog opened.';
        TemporaryCDMustBeNoErr: Label 'Temporary CD No. must be equal to ''No''  in CD No. Information';
        ItemTrackingDoesNotMatchErr: Label 'Item Tracking does not match for line 10000, Item %1, Qty. to Receive 4';
        DoYouWantToUndoMsg: Label 'Do you really want to undo the selected Receipt lines';
        QtyToInvoiceDoesNotMatchItemTrackingErr: Label 'The quantity to invoice does not match the quantity defined in item tracking.';

    [Normal]
    local procedure Initialize()
    begin
        if isInitialized then
            exit;

        LibraryCDTracking.UpdateERMCountryData;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder1CDPO()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CDHeader: array[2] of Record "CD No. Header";
        ReservationEntry: Record "Reservation Entry";
        CDLine: Record "CD No. Information";
        Qty: Decimal;
        CDNo: array[2, 2] of Code[30];
        i: Integer;
        j: Integer;
    begin
        // scenario for purchase order
        // 2 items with 2 different CD numbers are purchased

        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);

        for i := 1 to ArrayLen(Item) do begin
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);
            LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader[i]);
            for j := 1 to 2 do begin
                CDNo[i, j] := LibraryUtility.GenerateGUID;
                LibraryCDTracking.CreateItemCDInfo(CDHeader[i], CDLine, Item[i]."No.", CDNo[i, j]);
            end;
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader[1], Vendor."No.", Location.Code);
        Qty := 40;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1, 1], Qty);

        Qty := 50;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1, 2], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader[2], Vendor."No.", Location.Code);
        Qty := 70;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[2], Item[1]."No.", 20, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[2, 1], Qty);

        Qty := 30;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[2], Item[2]."No.", 15, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[2, 2], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', CDNo[1, 1], 40);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', CDNo[1, 2], 50);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', CDNo[2, 1], 70);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', CDNo[2, 2], 30);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder3CDSNLOT()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CDHeader: array[2] of Record "CD No. Header";
        CDLine: Record "CD No. Information";
        Qty: Decimal;
        CDNo: array[2, 2] of Code[30];
        LotNo: array[2] of Code[20];
        SerialNo: array[2, 5] of Code[20];
        i: Integer;
    begin
        // scenario for purchase order (1.3 Diff Types of Tracking: (CD-LOT-Serial No.))

        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, true, true, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader[1]);
        for i := 1 to ArrayLen(Item) do begin
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);
            CDNo[1, i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader[1], CDLine, Item[i]."No.", CDNo[1, i]);
            LotNo[i] := LibraryUtility.GenerateGUID;
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader[1], Vendor."No.", Location.Code);
        PurchaseHeader[1].Validate("Prices Including VAT", true);
        PurchaseHeader[1].Modify();
        Qty := 3;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        for i := 1 to 3 do begin
            SerialNo[1, i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, SerialNo[1, i], LotNo[1], CDNo[1, 1], 1);
        end;

        Qty := 5;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        for i := 1 to 5 do begin
            SerialNo[2, i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, SerialNo[2, i], LotNo[2], CDNo[1, 2], 1);
        end;

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);
        for i := 1 to 3 do
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[1, i], LotNo[1], CDNo[1, 1], 1);
        for i := 1 to 5 do
            LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[2, i], LotNo[2], CDNo[1, 2], 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder2CDAutoCr()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
        CDNo: array[3] of Code[30];
        i: Integer;
    begin
        // scenario for purchase order (1.2 PO > CD)
        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);

        for i := 1 to ArrayLen(Item) do begin
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);
            CDNo[i] := LibraryUtility.GenerateGUID;
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader[1], Vendor."No.", Location.Code);
        Qty := 4;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1], Qty);

        Qty := 5;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[2], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', CDNo[1], 4);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', CDNo[2], 5);

        CheckCDLineInfo(Item[1]."No.", CDNo[1], '', 4, 4, 0, Location.Code);
        CheckCDLineInfo(Item[2]."No.", CDNo[2], '', 5, 5, 0, Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder3CDLOT()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CDHeader: array[2] of Record "CD No. Header";
        CDLine: Record "CD No. Information";
        Qty: Decimal;
        CDNo: array[2, 2] of Code[30];
        LotNo: array[2, 2] of Code[20];
        i: Integer;
        j: Integer;
    begin
        // scenario for purchase order: 1.3 Different Types of Tracking: (CD+LOT No.)
        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader[1]);
        for i := 1 to ArrayLen(Item) do begin
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);
            CDNo[1, i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader[1], CDLine, Item[i]."No.", CDNo[1, i]);
            for j := 1 to ArrayLen(Item) do
                LotNo[i, j] := LibraryUtility.GenerateGUID;
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader[1], Vendor."No.", Location.Code);
        PurchaseHeader[1].Validate("Prices Including VAT", true);
        PurchaseHeader[1].Modify();
        Qty := 3;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', LotNo[1, 1], CDNo[1, 1], 1);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', LotNo[1, 2], CDNo[1, 1], 2);

        Qty := 5;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', LotNo[2, 1], CDNo[1, 2], 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', LotNo[2, 2], CDNo[1, 2], 3);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo[1, 1], CDNo[1, 1], 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo[1, 2], CDNo[1, 1], 2);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo[2, 1], CDNo[1, 2], 2);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo[2, 2], CDNo[1, 2], 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder4PartialPost()
    var
        Location: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
        PurchaseLine: Record "Purchase Line";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        Qty: Decimal;
        CDNo: Code[30];
        Qtytorec: Decimal;
    begin
        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);

        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo);

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify();
        Qty := 5;
        Qtytorec := 3;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item."No.", 15, Qty);
        PurchaseLine.Validate("Qty. to Receive", Qtytorec);
        PurchaseLine.Modify();

        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo, Qty);
        ReservationEntry.Validate("Qty. to Handle (Base)", 3);
        ReservationEntry.Validate("Qty. to Invoice (Base)", 3);
        ReservationEntry.Modify();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo, 3);

        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID);
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder5ComplexUOM()
    var
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CDHeader: Record "CD No. Header";
        ReservationEntry: Record "Reservation Entry";
        CDLine: Record "CD No. Information";
        CDNo: Code[30];
    begin
        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);

        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryCDTracking.CreateItemUnitOfMeasure(Item."No.", UnitOfMeasure.Code, 6);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo);

        CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code, PurchaseLine, Item."No.", UnitOfMeasure.Code, 4);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo, 24);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo, 24);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder7NoLocation()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        InvtSetup: Record "Inventory Setup";
        Qty: Decimal;
        CDNo: Code[30];
    begin
        // Purchase item with CD without Location

        Initialize;
        LibraryCDTracking.CreateForeignVendor(Vendor);
        InvtSetup.Get();
        InvtSetup."Check CD No. Format" := false;
        InvtSetup."Location Mandatory" := false;
        InvtSetup.Modify();

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryCDTracking.CreateItemUnitOfMeasure(Item."No.", UnitOfMeasure.Code, 6);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo);

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", '');
        PurchaseHeader.Validate("Prices Including VAT", true);

        Qty := 4;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item."No.", 20, Qty);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        PurchaseLine.Modify(true);

        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo, Qty * 6);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", '', '', '', CDNo, 24);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderCheckerrITL()
    var
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Trying to post purchase order without tracking information in ITL.

        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);

        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryCDTracking.CreateItemUnitOfMeasure(Item."No.", UnitOfMeasure.Code, 6);

        CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code, PurchaseLine, Item."No.", UnitOfMeasure.Code, 4);

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(StrSubstNo(CDNoRequiredErr, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderCheckerrITLQ()
    var
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        CDNo: Code[30];
    begin
        // Trying to post purchase order with wrong Qty in ITL.

        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryCDTracking.CreateItemUnitOfMeasure(Item."No.", UnitOfMeasure.Code, 6);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo);

        CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code, PurchaseLine, Item."No.", UnitOfMeasure.Code, 20);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo, 20);

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(QtyToInvoiceDoesNotMatchItemTrackingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder2CDmustEx()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
        PurchaseLine: Record "Purchase Line";
        CDNo: array[2] of Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        // scenario for purchase order (1.2 PO > CD)
        // Trying to set ITL without CD card and post purchase

        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);
        CDTrackingSetup.Validate("CD Info. Must Exist", true);
        CDTrackingSetup.Modify();

        for i := 1 to ArrayLen(Item) do begin
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);
            CDNo[i] := LibraryUtility.GenerateGUID;
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code);
        Qty := 4;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item[1]."No.", 20, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1], Qty);
        Qty := 5;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item[2]."No.", 15, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[2], Qty);

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(CDNoInfoDoesNotExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder3LOT()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
        PurchaseLine: Record "Purchase Line";
        LotNo: array[2, 2] of Code[20];
        Qty: Decimal;
        i: Integer;
        j: Integer;
    begin
        // scenario for purchase order: 1.3 Different Types of Tracking: (LOT tracking only)

        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, false);

        for i := 1 to ArrayLen(Item) do begin
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);
            for j := 1 to ArrayLen(Item) do
                LotNo[i, j] := LibraryUtility.GenerateGUID;
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader[1], Vendor."No.", Location.Code);
        PurchaseHeader[1].Validate("Prices Including VAT", true);
        PurchaseHeader[1].Modify();
        Qty := 3;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', LotNo[1, 1], '', 1);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', LotNo[1, 2], '', 2);
        Qty := 5;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', LotNo[2, 1], '', 2);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', LotNo[2, 2], '', 3);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo[1, 1], '', 1);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo[1, 2], '', 2);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo[2, 1], '', 2);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo[2, 2], '', 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderspecialCDset()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
        i: Integer;
    begin
        // Scenario for purchase order with special CD tracking:

        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, false);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);
        CDTrackingSetup.Validate("CD Info. Must Exist", true);
        CDTrackingSetup.Modify();

        for i := 1 to ArrayLen(Item) do
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader[1], Vendor."No.", Location.Code);
        Qty := 40;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        Qty := 50;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', '', 40);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', '', 50);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', '', 40);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', '', 50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchRetOrder()
    var
        UnitOfMeasure: Record "Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        Vendor: Record Vendor;
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        Location: Record Location;
        Item: Record Item;
        CopyPurchaseDocument: Report "Copy Purchase Document";
        CDNo: Code[30];
    begin
        // Test Purchase Return Order with CD tracking.

        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryCDTracking.CreateItemUnitOfMeasure(Item."No.", UnitOfMeasure.Code, 6);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo);

        CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code, PurchaseLine, Item."No.", UnitOfMeasure.Code, 4);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo, 24);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchRcptHeader.Reset();
        PurchRcptHeader.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchRcptHeader.FindFirst;

        LibraryCDTracking.CreatePurchReturnOrder(PurchaseHeader, Vendor."No.", Location.Code);

        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.InitializeRequest(DocType::"Posted Receipt", PurchRcptHeader."No.", true, true);
        CopyPurchaseDocument.Run;

        PurchaseHeader.Find;
        LibraryCDTracking.PostPurchaseDocument(PurchaseHeader, false, true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo, -24);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchRetOrderWrongCDTr()
    var
        UnitOfMeasure: Record "Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        Vendor: Record Vendor;
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        Location: Record Location;
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
        CopyPurchaseDocument: Report "Copy Purchase Document";
        CDHeader: Record "CD No. Header";
        CDLine: array[2] of Record "CD No. Information";
        CDNo: array[2] of Code[30];
        i: Integer;
    begin
        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);

        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryCDTracking.CreateItemUnitOfMeasure(Item."No.", UnitOfMeasure.Code, 6);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item."No.", CDNo[i]);
        end;

        CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code, PurchaseLine, Item."No.", UnitOfMeasure.Code, 4);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[2], 24);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptHeader.Reset();
        PurchRcptHeader.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchRcptHeader.FindFirst;
        LibraryCDTracking.CreatePurchReturnOrder(PurchaseHeader, Vendor."No.", Location.Code);

        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.InitializeRequest(DocType::"Posted Receipt", PurchRcptHeader."No.", true, true);
        CopyPurchaseDocument.Run;

        PurchaseHeader.Find;

        ReservationEntry.SetRange("CD No.", CDNo[2]);
        ReservationEntry.FindLast;
        ReservationEntry.Validate("CD No.", CDNo[1]);
        ReservationEntry.Modify();

        asserterror LibraryCDTracking.PostPurchaseDocument(PurchaseHeader, false, true, true);
        Assert.ExpectedError(ItemTrackingSerialLotCDMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrdCDautoCreateForm()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CDNo: array[2] of Code[30];
        Qty: Decimal;
        i: Integer;
    begin
        // Scenario for purchase order 2 PO > CD by "CD Auto-Create Inbound Info" = yes

        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        UpdateCDNoFormat;
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);

        for i := 1 to ArrayLen(Item) do begin
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);
            CDNo[i] := LibraryUtility.GenerateGUID;
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader[1], Vendor."No.", Location.Code);
        Qty := 4;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1], Qty);
        Qty := 5;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[2], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', CDNo[1], 4);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', CDNo[2], 5);

        CheckCDLineInfo(Item[1]."No.", CDNo[1], '', 4, 4, 0, Location.Code);
        CheckCDLineInfo(Item[2]."No.", CDNo[2], '', 5, 5, 0, Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrdCDautoCreateNoLoc()
    var
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CDNo: array[2] of Code[30];
        Qty: Decimal;
        i: Integer;
    begin
        // Scenario for purchase order PO > CD by "CD Auto-Create Inbound Info" = yes  without location

        Initialize;
        LibraryCDTracking.CreateForeignVendor(Vendor);
        UpdateInvtSetup(false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        ItemTrackingCode.Validate("CD Warehouse Tracking", true);
        ItemTrackingCode.Modify();

        for i := 1 to ArrayLen(Item) do begin
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);
            CDNo[i] := LibraryUtility.GenerateGUID;
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader[1], Vendor."No.", '');
        Qty := 4;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1], Qty);

        Qty := 5;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[2], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", '', '', '', CDNo[1], 4);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", '', '', '', CDNo[2], 5);

        CheckCDLineInfo(Item[1]."No.", CDNo[1], '', 4, 4, 0, '');
        CheckCDLineInfo(Item[2]."No.", CDNo[2], '', 5, 5, 0, '');
    end;

    [Test]
    [HandlerFunctions('HndlConfirm')]
    [Scope('OnPrem')]
    procedure TestPurchOrdCDreceipt()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        CDHeader: array[2] of Record "CD No. Header";
        CDLine: Record "CD No. Information";
        PurchaseInvLine: Record "Purchase Line";
        PurchaseInvHeader: Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
        ItemChargeAssgntSCode: Codeunit "Item Charge Assgnt. (Purch.)";
        PurchaseOrderNo: Code[20];
        CDNo: array[2, 2] of Code[30];
        ItemChargeNo: Code[20];
        i: Integer;
    begin
        // PO -> post as Receipt -> goto Posted Receipt and run function Undo
        // Receipt  -> goto  PO and post it again in Receipt option -> post Invoice ->
        // Apply Item Charges  as a separate invoice-> period activity Adjust Cost-Item Entries.

        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);

        for i := 1 to ArrayLen(Item) do begin
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);
            LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader[i]);
            CDNo[i, 1] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader[i], CDLine, Item[i]."No.", CDNo[i, 1]);
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader[1], Vendor."No.", Location.Code);
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[1], PurchaseHeader[1], Item[1]."No.", 20, 70);
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine[2], PurchaseHeader[1], Item[2]."No.", 30, 40);

        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', '', CDNo[1, 1], 70);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', '', CDNo[2, 1], 40);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', CDNo[1, 1], 70);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', CDNo[2, 1], 40);

        PurchRcptHeader.Reset();
        PurchRcptHeader.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchRcptHeader.FindFirst;
        PurchRcptLine.Reset();
        PurchRcptLine.SetFilter("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("No.", Item[1]."No.");
        PurchRcptLine.FindFirst;
        CODEUNIT.Run(CODEUNIT::"Undo Purchase Receipt Line", PurchRcptLine);
        PurchRcptLine.Reset();
        PurchRcptLine.SetFilter("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("No.", Item[2]."No.");
        PurchRcptLine.FindFirst;
        CODEUNIT.Run(CODEUNIT::"Undo Purchase Receipt Line", PurchRcptLine);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', CDNo[1, 1], -70);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', CDNo[2, 1], -40);

        PurchaseHeader[1].Reset();
        PurchaseHeader[1].SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader[1].FindFirst;

        PurchaseLine[1].Validate("Qty. to Receive", 53);
        PurchaseLine[1].Modify();
        PurchaseLine[2].Validate("Qty. to Receive", 0);
        PurchaseLine[2].Modify();

        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[1], '', '', CDNo[1, 1], 0);
        ReservationEntry.Validate("Qty. to Handle (Base)", 53);
        ReservationEntry.Modify();
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine[2], '', '', CDNo[2, 1], 0);
        ReservationEntry.Validate("Qty. to Handle (Base)", 0);
        ReservationEntry.Modify();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', CDNo[1, 1], 53);

        PurchaseHeader[1].Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID);
        PurchaseHeader[1].Modify();
        PurchaseOrderNo := PurchaseHeader[1]."No.";
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', CDNo[1, 1], 17);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', CDNo[2, 1], 40);

        PurchaseOrderNo := PurchaseHeader[1]."No.";

        ItemChargeNo := LibraryInventory.CreateItemChargeNo;
        CreatePurchInvoice(PurchaseInvHeader, Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseInvLine, PurchaseInvHeader, PurchaseInvLine.Type::"Charge (Item)", ItemChargeNo, 1);

        PurchaseInvLine.Validate("Direct Unit Cost", 20);
        PurchaseInvLine.Modify();

        PurchRcptLine.SetRange("Order No.", PurchaseOrderNo);
        PurchRcptLine.FindLast;
        repeat
            CreateItemChargeAssignPurchFromReceipt(
              PurchaseInvLine, ItemChargeNo, Item[1]."No.", PurchRcptLine);
        until PurchRcptLine.Next = 0;
        ItemChargeAssgntSCode.AssignItemCharges(PurchaseInvLine, 1, 1, ItemChargeAssgntSCode.AssignEquallyMenuText);
        LibraryPurchase.PostPurchaseDocument(PurchaseInvHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPOCheckerrITLRelease()
    var
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Trying to Release purchase order without tracking information in ITL.

        Initialize;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);
        CDTrackingSetup.Validate("CD Purchase Check on Release", true);
        CDTrackingSetup.Modify();

        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryCDTracking.CreateItemUnitOfMeasure(Item."No.", UnitOfMeasure.Code, 6);

        CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code, PurchaseLine, Item."No.", UnitOfMeasure.Code, 4);
        // Must be error because ITL are not filled
        asserterror LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        Assert.ExpectedError(StrSubstNo(ItemTrackingDoesNotMatchErr, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurOrdCDCheckFormAndSale()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        CDTrackingSetup: Record "CD Tracking Setup";
        Customer: Record Customer;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
        CDHeader: Record "CD No. Header";
        CDLine: array[2] of Record "CD No. Information";
        CDNo: array[2] of Code[30];
        i: Integer;
    begin
        // Scenario for purchase order, check CD No. format

        Initialize;
        UpdateCDNoFormat;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);
        CDTrackingSetup.Validate("Allow Temporary CD No.", true);
        CDTrackingSetup.Modify();

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(Item) do begin
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item[i]."No.", CDNo[i]);
            CDLine[i].Validate("Temporary CD No.", true);
            CDLine[i].Modify();
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code);
        Qty := 4;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item[1]."No.", 20, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1], Qty);

        Qty := 5;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item[2]."No.", 15, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[2], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibrarySales.CreateCustomer(Customer);
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        LibraryCDTracking.CreateSalesLineItem(SalesLine, SalesHeader, Item[1]."No.", 40, 2);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, '', '', CDNo[1], 2);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurOrdCDCheckFormY()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        CDTrackingSetup: Record "CD Tracking Setup";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
        CDHeader: Record "CD No. Header";
        CDLine: array[2] of Record "CD No. Information";
        CDNo: array[2] of Code[30];
        i: Integer;
    begin
        // scenario for purchase order, check CD No. format

        Initialize;
        UpdateCDNoFormat;
        CreateForeignVendorAndLocation(Vendor, Location, false);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);
        CDTrackingSetup.Validate("Allow Temporary CD No.", false);
        CDTrackingSetup.Modify();

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(Item) do begin
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item[i]."No.", CDNo[i]);
            CDLine[i].Validate("Temporary CD No.", true);
            CDLine[i].Modify();
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code);
        Qty := 4;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item[1]."No.", 20, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1], Qty);

        Qty := 5;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item[2]."No.", 15, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[2], Qty);

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(TemporaryCDMustBeNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurOrdCDCheckFormAndSales()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        CDTrackingSetup: Record "CD Tracking Setup";
        Customer: Record Customer;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
        CDHeader: Record "CD No. Header";
        CDLine: array[2] of Record "CD No. Information";
        CDNo: array[2] of Code[30];
        i: Integer;
    begin
        // Scenario for purchase order, check CD No. format

        Initialize;
        UpdateCDNoFormat;
        CreateForeignVendorAndLocation(Vendor, Location, true);

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);
        CDTrackingSetup.Validate("Allow Temporary CD No.", true);
        CDTrackingSetup.Validate("CD Sales Check on Release", true);
        CDTrackingSetup.Validate("CD Info. Must Exist", true);
        CDTrackingSetup.Modify();

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(Item) do begin
            LibraryCDTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode.Code);
            CDNo[i] := LibraryUtility.GenerateGUID;
            LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine[i], Item[i]."No.", CDNo[i]);
            CDLine[i].Validate("Temporary CD No.", true);
            CDLine[i].Modify();
        end;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code);
        Qty := 4;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item[1]."No.", 20, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1], Qty);

        Qty := 5;
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item[2]."No.", 15, Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[2], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibrarySales.CreateCustomer(Customer);
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        LibraryCDTracking.CreateSalesLineItem(SalesLine, SalesHeader, Item[1]."No.", 40, 2);
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, '', '', CDNo[1], 2);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure UpdateInvtSetup(CheckCDFormat: Boolean)
    var
        InvtSetup: Record "Inventory Setup";
        InvtSetupUpdated: Boolean;
    begin
        InvtSetup.Get();
        InvtSetupUpdated := false;
        if InvtSetup."Check CD No. Format" <> CheckCDFormat then begin
            InvtSetup.Validate("Check CD No. Format", CheckCDFormat);
            InvtSetupUpdated := true;
        end;
        if InvtSetupUpdated then
            InvtSetup.Modify();
    end;

    local procedure UpdateCDNoFormat()
    var
        SetCDNoFormat: Record "CD No. Format";
    begin
        if SetCDNoFormat.FindLast then begin
            SetCDNoFormat.Validate(Format, '####/##/####');
            SetCDNoFormat.Modify();
        end else begin
            SetCDNoFormat.Init();
            SetCDNoFormat.Validate(Format, '####/##/####');
            SetCDNoFormat.Insert();
        end;
    end;

    local procedure CreateForeignVendorAndLocation(var Vendor: Record Vendor; var Location: Record Location; CheckCDFormat: Boolean)
    begin
        LibraryCDTracking.CreateForeignVendor(Vendor);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        UpdateInvtSetup(CheckCDFormat);
    end;

    [Normal]
    local procedure CreatePurchOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[10]; Locationcode: Code[30]; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[10]; UnitOfMeasureCode: Code[10]; Qty: Decimal)
    begin
        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, VendorNo, Locationcode);
        PurchaseHeader.Validate("Prices Including VAT", true);

        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, ItemNo, 20, Qty);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CheckCDLineInfo(ItemNo: Code[20]; CDNo: Code[30]; CDHeaderNo: Code[30]; Inventory: Decimal; Purchase: Decimal; Sales: Decimal; Locationcode: Code[10]): Boolean
    var
        CDLine: Record "CD No. Information";
    begin
        CDLine.SetRange("No.", ItemNo);
        CDLine.SetRange("CD No.", CDNo);
        CDLine.SetRange("CD Header No.", CDHeaderNo);
        CDLine.SetRange("Location Filter", Locationcode);
        Assert.IsTrue(CDLine.FindLast, StrSubstNo(CDLineFoundErr, CDLine.TableCaption, CDLine.GetFilters));

        CDLine.CalcFields(Inventory, Purchases, Sales);

        Assert.AreEqual(Purchase, CDLine.Purchases, StrSubstNo(CDLineQtyErr, CDLine."No.", CDLine.GetFilters));
        Assert.AreEqual(Inventory, CDLine.Inventory, StrSubstNo(CDLineQtyErr, CDLine."No.", CDLine.GetFilters));
        Assert.AreEqual(Sales, CDLine.Sales, StrSubstNo(CDLineQtyErr, CDLine."No.", CDLine.GetFilters));
    end;

    local procedure CreatePurchInvoice(var PurchaseInvHeader: Record "Purchase Header"; VendorNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseInvHeader, PurchaseInvHeader."Document Type"::Invoice, VendorNo);
        PurchaseInvHeader.Validate("Vendor Invoice No.", PurchaseInvHeader."No.");
        PurchaseInvHeader.Validate("Location Code", LocationCode);
        PurchaseInvHeader.Modify();
    end;

    local procedure CreateItemChargeAssignPurchFromReceipt(PurchLine: Record "Purchase Line"; ItemChargeNo: Code[20]; ItemNo: Code[20]; PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        LineNo: Integer;
    begin
        with ItemChargeAssignmentPurch do begin
            SetRange("Document Type", PurchLine."Document Type");
            SetRange("Document No.", PurchLine."Document No.");
            SetRange("Document Line No.", PurchLine."Line No.");
            if FindLast then
                LineNo := "Line No."
            else
                LineNo := 0;

            Init;
            Validate("Document Type", PurchLine."Document Type");
            Validate("Document No.", PurchLine."Document No.");
            Validate("Document Line No.", PurchLine."Line No.");
            Validate("Line No.", LineNo);
            Validate("Item Charge No.", ItemChargeNo);
            Validate("Item No.", ItemNo);
            Validate("Applies-to Doc. Type", "Applies-to Doc. Type"::Receipt);
            Validate("Applies-to Doc. No.", PurchRcptLine."Document No.");
            Validate("Applies-to Doc. Line No.", PurchRcptLine."Line No.");
            Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
            Insert;
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HndlConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, DoYouWantToUndoMsg) = 0 then
            Error(IncorrConfirmDialogOpenedErr);

        Reply := true;
    end;
}

