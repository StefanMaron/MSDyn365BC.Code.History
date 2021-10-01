codeunit 137140 "SCM Inventory Documents"
{
    // // [FEATURE] [SCM] [Inventory Documents]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        ItemTrackingAction: Option AssignSerialNo,SelectEntries;
        RoundingTo0Err: Label 'Rounding of the field';
        RoundingErr: Label 'is of lesser precision than expected';

    [Test]
    [Scope('OnPrem')]
    procedure ItemReceiptWithDimension()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);

        // Execute
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        InvtDocumentHeader.Validate("Salesperson/Purchaser Code", SalespersonPurchaser.Code);
        InvtDocumentHeader.Modify(true);

        // Verify
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, InvtDocumentHeader."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReceiptWithDimensionLines()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DimensionValueItem: Record "Dimension Value";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValueItem);

        // Execute
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code);

        // Verify
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, InvtDocumentLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemShipmentWithDimension()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);

        // Execute
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, Location.Code);
        InvtDocumentHeader.Validate("Salesperson/Purchaser Code", SalespersonPurchaser.Code);
        InvtDocumentHeader.Modify(true);

        // Verify
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, InvtDocumentHeader."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemShipmentWithDimensionLines()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValue);

        // Execute
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Shipment, Location.Code, SalespersonPurchaser.Code);

        // Verify
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, InvtDocumentLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedItemReceiptWithDimension()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DimensionValueItem: Record "Dimension Value";
        ItemReceiptHeader: Record "Invt. Receipt Header";
        ItemReceiptLine: Record "Invt. Receipt Line";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValueItem);

        // Execute
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // Verify
        ItemReceiptHeader.SetRange("Location Code", Location.Code);
        ItemReceiptHeader.FindFirst();
        Assert.AreEqual(SalespersonPurchaser.Code, ItemReceiptHeader."Purchaser Code", 'Purchaser code should be same');
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, ItemReceiptHeader."Dimension Set ID");
        ItemReceiptLine.SetRange("Document No.", ItemReceiptHeader."No.");
        ItemReceiptLine.FindFirst();
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, ItemReceiptLine."Dimension Set ID");
        VerifyDimensionCode(DimensionValueItem."Dimension Code", DimensionValueItem.Code, ItemReceiptLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedItemShipmentWithDimension()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DimensionValueItem: Record "Dimension Value";
        InvtShipmentHeader: Record "Invt. Shipment Header";
        InvtShipmentLine: Record "Invt. Shipment Line";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValueItem);

        // Execute
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Shipment, Location.Code, SalespersonPurchaser.Code);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // Verify
        InvtShipmentHeader.SetRange("Location Code", Location.Code);
        InvtShipmentHeader.FindFirst();
        Assert.AreEqual(SalespersonPurchaser.Code, InvtShipmentHeader."Salesperson Code", 'Salesperson code should be same');
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, InvtShipmentHeader."Dimension Set ID");
        InvtShipmentLine.SetRange("Document No.", InvtShipmentHeader."No.");
        InvtShipmentLine.FindFirst();
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, InvtShipmentLine."Dimension Set ID");
        VerifyDimensionCode(DimensionValueItem."Dimension Code", DimensionValueItem.Code, InvtShipmentLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDirectTransferRequireReceive()
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        Bin: Record Bin;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseEntry: Record "Warehouse Entry";
        Qty: Integer;
    begin
        // [FEATURE] [Location] [Warehouse] [Direct Transfer]
        // [SCENARIO 253751] Direct transfer to location with inbound warehouse handling should be posted without warehouse receipt

        Initialize();

        // [GIVEN] Two locations: "A" without warehouse setup, and "B" with "Require Receipt" enabled
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWMS(ToLocation, true, false, false, true, false);
        LibraryWarehouse.CreateBin(Bin, ToLocation.Code, '', '', '');

        // [GIVEN] Item "I" with stock of 100 pcs on location "A"
        Qty := CreateAndPostItemJournalLine(Item."No.", FromLocation.Code, '');

        // [GIVEN] Create a direct transfer order from location "A" to location "B"
        CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
        TransferLine.Validate("Transfer-To Bin Code", Bin.Code);
        TransferLine.Modify(true);

        // [WHEN] Post the transfer using "Direct Transfer Posting" = "Direct Transfer"
        SetDirectTransferPosting(1);
        LibraryInventory.PostDirectTransferOrder(TransferHeader);
        SetDirectTransferPosting(0);

        // [THEN] Item ledger shows 100 pcs of item "I" moved to location "B"
        VerifyItemInventory(Item, ToLocation.Code, Qty);

        // [THEN] Positive adjustment for 100 pcs of item "I" is posted on location "B"
        VerifyWarehouseEntry(ToLocation.Code, Item."No.", WarehouseEntry."Entry Type"::"Positive Adjmt.", Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDirectTransferRequireShipment()
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        Bin: Record Bin;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseEntry: Record "Warehouse Entry";
        Qty: Integer;
    begin
        // [FEATURE] [Location] [Warehouse] [Direct Transfer]
        // [SCENARIO 253751] Direct transfer from location with outbound warehouse handling should be posted without warehouse shipment

        Initialize;

        // [GIVEN] Two locations: "A" with "Require Shipment" enabled, and "B" without warehouse setup
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(FromLocation, true, false, false, false, true);
        LibraryWarehouse.CreateBin(Bin, FromLocation.Code, '', '', '');
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);

        // [GIVEN] Item "I" with stock of 100 pcs on location "A"
        Qty := CreateAndPostItemJournalLine(Item."No.", FromLocation.Code, Bin.Code);

        // [GIVEN] Create a direct transfer order from location "A" to location "B"
        CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
        TransferLine.Validate("Transfer-from Bin Code", Bin.Code);
        TransferLine.Modify(true);

        // [WHEN] Post the transfer using "Direct Transfer Posting" = "Direct Transfer"
        SetDirectTransferPosting(1);
        LibraryInventory.PostDirectTransferOrder(TransferHeader);
        SetDirectTransferPosting(0);

        // [THEN] Item ledger shows 100 pcs of item "I" moved to location "B"
        VerifyItemInventory(Item, ToLocation.Code, Qty);

        // [THEN] Negative adjustment for -100 pcs of item "I" is posted on location "B"
        VerifyWarehouseEntry(FromLocation.Code, Item."No.", WarehouseEntry."Entry Type"::"Negative Adjmt.", -Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemReceiptWithMultipleSerialNos()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [Item Receipt] [Item Tracking] [Warehouse]
        // [SCENARIO 307763] Posting item receipt with multiple serial nos. generates a separate warehouse entry for each serial no.
        Initialize();

        // [GIVEN] Location with a bin.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID, '', '');

        // [GIVEN] Serial no.-tracked item. "SN Warehouse Tracking" is enabled.
        CreateSNTrackedItem(Item);

        // [GIVEN] Create item receipt, assign 5 serial nos. to the line.
        CreateInvtDocumentWithItemTracking(
          InvtDocumentHeader, InvtDocumentLine, InvtDocumentHeader."Document Type"::Receipt,
          Item."No.", Location.Code, Bin.Code, LibraryRandom.RandIntInRange(5, 10), ItemTrackingAction::AssignSerialNo);

        // [WHEN] Post the item receipt.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [THEN] 5 warehouse entries are created.
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::"Positive Adjmt.");
        Assert.RecordCount(WarehouseEntry, InvtDocumentLine.Quantity);

        // [THEN] Total quantity posted in the warehouse ledger = 5.
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(InvtDocumentLine.Quantity, WarehouseEntry.Quantity, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler,ItemTrackingSummaryModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemShipmentWithMultipleSerialNos()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ReceiptInvtDocumentHeader: Record "Invt. Document Header";
        ReceiptInvtDocumentLine: Record "Invt. Document Line";
        ShipmentInvtDocumentHeader: Record "Invt. Document Header";
        ShipmentInvtDocumentLine: Record "Invt. Document Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [Item Shipment] [Item Tracking] [Warehouse]
        // [SCENARIO 307763] Posting item shipment with multiple serial nos. generates a separate warehouse entry for each serial no.
        Initialize();

        // [GIVEN] Location with a bin.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID, '', '');

        // [GIVEN] Serial no.-tracked item. "SN Warehouse Tracking" is enabled.
        CreateSNTrackedItem(Item);

        // [GIVEN] Create item receipt, assign 5 serial nos. to the line and post it.
        CreateInvtDocumentWithItemTracking(
          ReceiptInvtDocumentHeader, ReceiptInvtDocumentLine, ReceiptInvtDocumentHeader."Document Type"::Receipt,
          Item."No.", Location.Code, Bin.Code, LibraryRandom.RandIntInRange(5, 10), ItemTrackingAction::AssignSerialNo);
        LibraryInventory.PostInvtDocument(ReceiptInvtDocumentHeader);

        // [GIVEN] Create item shipment, select received 5 serial nos.
        CreateInvtDocumentWithItemTracking(
          ShipmentInvtDocumentHeader, ShipmentInvtDocumentLine, ShipmentInvtDocumentHeader."Document Type"::Shipment,
          Item."No.", Location.Code, Bin.Code, ReceiptInvtDocumentLine.Quantity, ItemTrackingAction::SelectEntries);

        // [WHEN] Post the item shipment.
        LibraryInventory.PostInvtDocument(ShipmentInvtDocumentHeader);

        // [THEN] 5 warehouse entries are created.
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::"Negative Adjmt.");
        Assert.RecordCount(WarehouseEntry, ShipmentInvtDocumentLine.Quantity);

        // [THEN] Total quantity posted in the warehouse ledger by warehouse shipment = -5.
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(-ShipmentInvtDocumentLine.Quantity, WarehouseEntry.Quantity, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReceiptWithNegativeQuantity()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValue);

        // Execute
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code);

        // Verify
        asserterror InvtDocumentLine.Validate(Quantity, -1);
        Assert.ExpectedError('cannot be negative');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemShipmentWithNegativeQuantity()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
    begin
        // Setup
        Initialize();
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValue);

        // Execute
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Shipment, Location.Code, SalespersonPurchaser.Code);

        // Verify
        asserterror InvtDocumentLine.Validate(Quantity, -1);
        Assert.ExpectedError('cannot be negative');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyIsRoundedTo0OnInvtDocumentLine()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize;
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code, 0);
        InvtDocumentLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        InvtDocumentLine.Modify();

        asserterror InvtDocumentLine.Validate(Quantity, 0.01);
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQtyIsRoundedTo0OnInvtDocumentLine()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize;
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code, 0);
        InvtDocumentLine.Validate("Unit of Measure Code", BaseUOM.Code);
        InvtDocumentLine.Modify();
        asserterror InvtDocumentLine.Validate(Quantity, 0.01);
        Assert.ExpectedError(RoundingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionSpecifiedOnInvtDocumentLine()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize;
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateInvtDocumentWithLine(
            InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code, 0);
        InvtDocumentLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        InvtDocumentLine.Validate(Quantity, 5.67);
        Assert.AreEqual(17.0, InvtDocumentLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionUnspecifiedOnInvtDocumentLine()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize;
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        NonBaseQtyPerUOM := 3;
        BaseQtyPerUOM := 1;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateInvtDocumentWithLine(
            InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code, 0);
        InvtDocumentLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        InvtDocumentLine.Validate(Quantity, 5.6666666);
        Assert.AreEqual(17.00001, InvtDocumentLine."Quantity (Base)", 'Base qty. is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionOnInvtDocumentLine()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize;
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        NonBaseQtyPerUOM := 6;
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateInvtDocumentWithLine(
            InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code, 0);
        InvtDocumentLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        InvtDocumentLine.Validate(Quantity, 5 / 6);
        Assert.AreEqual(5, InvtDocumentLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReceiptWithNonInventoryItemError()
    var
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
    begin
        // [FEATURE 378558] [Item Receipt] 
        // Create item document line with non-inventory item produce error
        Initialize();

        // [GIVEN] Create item receipt
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, "Invt. Doc. Document Type"::Receipt, Location.Code);

        LibraryInventory.CreateItem(Item);
        Item.Type := Item.Type::"Non-Inventory";
        Item.Modify();

        // [THEN] Create line
        asserterror LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldTransferRoundingPrecisionToInvtShipmentLine()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        Location: Record Location;
        InvtShipmentHeader: Record "Invt. Shipment Header";
        InvtShipmentLine: Record "Invt. Shipment Line";
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateInvtDocumentWithLine(
            InvtDocumentHeader, InvtDocumentLine, Item,
            InvtDocumentHeader."Document Type"::Shipment, Location.Code, '', 1
        );
        InvtDocumentLine.Validate("Unit of Measure Code", BaseUOM.Code);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        InvtShipmentHeader.SetRange("Location Code", Location.Code);
        InvtShipmentHeader.FindFirst();
        InvtShipmentLine.SetRange("Document No.", InvtShipmentHeader."No.");
        InvtShipmentLine.FindFirst();

        Assert.AreEqual(
            InvtDocumentLine."Qty. Rounding Precision", InvtShipmentLine."Qty. Rounding Precision",
            'Expected Qty. Rounding Precision to be transferred.'
        );
        Assert.AreEqual(
            InvtDocumentLine."Qty. Rounding Precision (Base)", InvtShipmentLine."Qty. Rounding Precision (Base)",
            'Expected Qty. Rounding Precision (Base) to be transferred.'
        );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldTransferRoundingPrecisionToInvtReceiptLine()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        Location: Record Location;
        InvtReceiptHeader: Record "Invt. Receipt Header";
        InvtReceiptLine: Record "Invt. Receipt Line";
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        Initialize();
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateInvtDocumentWithLine(
            InvtDocumentHeader, InvtDocumentLine, Item,
            InvtDocumentHeader."Document Type"::Receipt, Location.Code, '', 1
        );
        InvtDocumentLine.Validate("Unit of Measure Code", BaseUOM.Code);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        InvtReceiptHeader.SetRange("Location Code", Location.Code);
        InvtReceiptHeader.FindFirst();
        InvtReceiptLine.SetRange("Document No.", InvtReceiptHeader."No.");
        InvtReceiptLine.FindFirst();

        Assert.AreEqual(
            InvtDocumentLine."Qty. Rounding Precision", InvtReceiptLine."Qty. Rounding Precision",
            'Expected Qty. Rounding Precision to be transferred.'
        );
        Assert.AreEqual(
            InvtDocumentLine."Qty. Rounding Precision (Base)", InvtReceiptLine."Qty. Rounding Precision (Base)",
            'Expected Qty. Rounding Precision (Base) to be transferred.'
        );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationWithRequireReceiptAllowed()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        LocationReceipt: Record Location;
        LocationPutAwayAndPick: Record Location;
        InvtReceiptHeader: Record "Invt. Receipt Header";
    begin
        // [SCENARIO] It is possible to use a location with require receipt for inventory receipt document but 
        // not for directed put-away and pick.
        Initialize();

        // [GIVEN] An item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A location with require receipt and one with put-away and pick.
        LibraryWarehouse.CreateLocationWMS(LocationReceipt, false, false, false, true, false);
        LibraryWarehouse.CreateFullWMSLocation(LocationPutAwayAndPick, 1);

        // [WHEN] Creating an inventory receipt document for location with require receipt.
        LibraryInventory.CreateInvtDocument(
            InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, LocationReceipt.Code);

        // [THEN] No error is thrown.

        // [WHEN] Setting location with require put-away and pick.
        asserterror InvtDocumentHeader.Validate("Location Code", LocationPutAwayAndPick.Code);

        // [THEN] An error is thrown.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationWithRequireShipmentAllowed()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Item: Record Item;
        LocationShipment: Record Location;
        LocationPutAwayAndPick: Record Location;
        InvtReceiptHeader: Record "Invt. Receipt Header";
    begin
        // [SCENARIO] It is possible to use a location with require receipt for inventory shipment document but 
        // not for directed put-away and pick.
        Initialize();

        // [GIVEN] An item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A location with require shipment and one with put-away and pick.
        LibraryWarehouse.CreateLocationWMS(LocationShipment, false, false, false, false, true);
        LibraryWarehouse.CreateFullWMSLocation(LocationPutAwayAndPick, 1);

        // [WHEN] Creating an inventory shipment document for location with require shipment.
        LibraryInventory.CreateInvtDocument(
            InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, LocationShipment.Code);

        // [THEN] No error is thrown.

        // [WHEN] Setting location with require put-away and pick.
        asserterror InvtDocumentHeader.Validate("Location Code", LocationPutAwayAndPick.Code);

        // [THEN] An error is thrown.
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();

        SetupInvtDocumentsNoSeries();
        SetupPostedDirectTransfersNoSeries();

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]): Integer
    var
        ItemJournalLine: Record "Item Journal Line";
        Qty: Integer;
    begin
        Qty := LibraryRandom.RandInt(100);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        exit(Qty);
    end;

    local procedure CreateDirectTransferHeader(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    begin
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
    end;

    local procedure CreateSNTrackedItem(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode, ItemTrackingCode.Code);
    end;

    local procedure CreateInvtDocumentWithLine(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; Item: Record Item; DocumentType: Enum "Invt. Doc. Document Type"; LocationCode: Code[10]; SalespersonPurchaserCode: Code[20])
    begin
        CreateInvtDocumentWithLine(InvtDocumentHeader, InvtDocumentLine, Item, DocumentType, LocationCode, SalespersonPurchaserCode, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateInvtDocumentWithLine(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; Item: Record Item; DocumentType: Enum "Invt. Doc. Document Type"; LocationCode: Code[10]; SalespersonPurchaserCode: Code[20]; Qty: Decimal)
    begin
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, DocumentType, LocationCode);
        InvtDocumentHeader.Validate("Salesperson/Purchaser Code", SalespersonPurchaserCode);
        InvtDocumentHeader.Modify(true);
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, Item."No.", Item."Unit Cost", Qty);
    end;

    local procedure CreateInvtDocumentWithItemTracking(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; ItemDocumentType: Enum "Invt. Doc. Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal; ItemTrkgAction: Option)
    begin
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, ItemDocumentType, LocationCode);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, ItemNo, 0, Qty);
        InvtDocumentLine.Validate("Bin Code", BinCode);
        InvtDocumentLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrkgAction);
        InvtDocumentLine.OpenItemTrackingLines();
    end;

    local procedure CreateItemWithDimension(var Item: Record Item; var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        Clear(DimensionValue);
        LibraryInventory.CreateItem(Item);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Item, Item."No.", Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, ItemNo, Quantity);

        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateSalespersonPurchaseWithDimension(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", SalespersonPurchaser.Code, Dimension.Code, DimensionValue.Code);
    end;

    local procedure SetupPostedDirectTransfersNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Posted Direct Trans. Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        InventorySetup.Validate("Direct Transfer Posting", InventorySetup."Direct Transfer Posting"::"Direct Transfer");
        InventorySetup.Modify(true);
    end;

    local procedure SetupInvtDocumentsNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if InventorySetup."Invt. Receipt Nos." = '' then
            InventorySetup.Validate("Invt. Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        if InventorySetup."Posted Invt. Receipt Nos." = '' then
            InventorySetup.Validate("Posted Invt. Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        if InventorySetup."Invt. Shipment Nos." = '' then
            InventorySetup.Validate("Invt. Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        if InventorySetup."Posted Invt. Shipment Nos." = '' then
            InventorySetup.Validate("Posted Invt. Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        InventorySetup.Modify(true);
    end;

    local procedure SetDirectTransferPosting(DirectTransferPosting: Option)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Direct Transfer Posting" := DirectTransferPosting;
        InventorySetup.Modify();
    end;

    local procedure PostItemJournalLine(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, EntryType, ItemNo, Quantity, UnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostItemRevaluation(ItemNo: Code[20]; NewAmount: Decimal)
    var
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        CalculatePer: Option "Item Ledger Entry",Item;
    begin
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        Item.SetRange("No.", ItemNo);
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        LibraryCosting.CreateRevaluationJournal(
          ItemJournalBatch, Item, WorkDate, LibraryUtility.GenerateGUID, CalculatePer::Item, false, false, false, 0, false);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Inventory Value (Revalued)", NewAmount);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure SetupForItemDocument(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var Location: Record Location; var DimensionValue: Record "Dimension Value")
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateSalespersonPurchaseWithDimension(SalespersonPurchaser, DimensionValue);
    end;

    local procedure VerifyDimensionCode(DimensionCode: Code[20]; DimensionValueCode: Code[20]; DimSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, DimSetID);
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(DimensionValueCode, DimensionSetEntry."Dimension Value Code", 'Dimension values should be equal');
    end;

    local procedure VerifyGLEntrySource(LocationCode: Code[10]; AcquisitionCostAccountNo: Code[20]; FixedAssetNo: Code[20])
    var
        InvtShipmentHeader: Record "Invt. Shipment Header";
        GLEntry: Record "G/L Entry";
    begin
        InvtShipmentHeader.SetRange("Location Code", LocationCode);
        InvtShipmentHeader.FindFirst();

        GLEntry.SetRange("G/L Account No.", AcquisitionCostAccountNo);
        GLEntry.SetRange("Document No.", InvtShipmentHeader."No.");
        GLEntry.FindFirst();
        GLEntry.TestField("Source Type", GLEntry."Source Type"::"Fixed Asset");
        GLEntry.TestField("Source No.", FixedAssetNo);
    end;

    local procedure VerifyItemInventory(var Item: Record Item; LocationCode: Code[10]; ExpectedQty: Decimal)
    begin
        Item.SetRange("Location Filter", LocationCode);
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, ExpectedQty);
    end;

    local procedure VerifyWarehouseEntry(LocationCode: Code[10]; ItemNo: Code[20]; EntryType: Option; ExpectedQty: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        with WarehouseEntry do begin
            SetRange("Location Code", LocationCode);
            SetRange("Item No.", ItemNo);
            SetRange("Entry Type", EntryType);
            FindFirst();
            TestField(Quantity, ExpectedQty);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger of
            ItemTrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            ItemTrackingAction::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateModalPageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK.Invoke();
    end;
}

