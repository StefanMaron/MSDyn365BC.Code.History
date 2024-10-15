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
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        isInitialized: Boolean;
        ItemTrackingAction: Option AssignSerialNo,SelectEntries;
        RoundingTo0Err: Label 'Rounding of the field';
        RoundingErr: Label 'is of lesser precision than expected';
        ItemNoErr: Label 'Item No. are not equal';
        UnitOfMeasureCodeErr: Label 'Unit of Measure Code are not equal';
        UnitCostErr: Label 'Unit Cost are not equal';
        DimensionErr: Label 'Expected dimension should be %1.', Comment = '%1=Value';
        SourceCodeErr: Label 'Source Code should not be blank in %1.', Comment = '%1=TableCaption()';
        DimensionValueErr: Label 'Dimension Value must match with %1', Comment = '%1= Dimension Value';
        ReorderingPolicyShouldBeVisibleErr: Label 'Reordering Policy should be visible.';
        SpecialEquipmentCodeShouldBeVisibleErr: Label 'Special Equipment Code should be visible.';

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
        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // Verify
        ItemReceiptHeader.Get(InvtDocumentHeader."Posting No.");
        ItemReceiptHeader.TestField("Location Code", Location.Code);
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
        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // Verify
        InvtShipmentHeader.Get(InvtDocumentHeader."Posting No.");
        InvtShipmentHeader.TestField("Location Code", Location.Code);
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
        Qty: Integer;
    begin
        // [FEATURE] [Location] [Warehouse] [Direct Transfer]
        // [SCENARIO 253751] Direct transfer to location with inbound warehouse handling should not be posted

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
        asserterror LibraryInventory.PostDirectTransferOrder(TransferHeader);
        SetDirectTransferPosting(0);
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

        Initialize();

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
        TransferLine.Validate("Qty. to Ship", TransferLine.Quantity);
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
    [Scope('OnPrem')]
    procedure PostDirectTransferWithDirectedPutawayAndPickForToLocation()
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        Bin: Record Bin;
        TransferHeader: Record "Transfer Header";
        Qty: Integer;
    begin
        // [FEATURE] [Location] [Warehouse] [Direct Transfer] 
        // [SCENARIO 449256] Direct transfer to location with directed put-away and pick cannot be posted

        Initialize();

        // [GIVEN] Two locations: "A" without warehouse setup, and "B" with "Directed Put-Away and Pick" enabled
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWMS(ToLocation, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, ToLocation.Code, '', '', '');
        ToLocation."Directed Put-away and Pick" := true;
        ToLocation.Modify();

        // [GIVEN] Item "I" with stock of 100 pcs on location "A"
        Qty := CreateAndPostItemJournalLine(Item."No.", FromLocation.Code, '');

        // [GIVEN] Create a direct transfer order from location "A" to location "B"
        asserterror CreateDirectTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code);
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
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

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
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

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
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler')]
    [Scope('OnPrem')]
    procedure CopyInvReceiptFromPostedInvReceiptWithItemTrackedLines()
    var
        Location: Record Location;
        Item: Record Item;
        SNTrackedItem: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        InvtRcptHeader: Record "Invt. Receipt Header";
        CopyInvtDocMgt: Codeunit "Copy Invt. Document Mgt.";
    begin
        // [FEATURE] [Item Receipt] [Item Tracking] [Copy Document]
        // [SCENARIO 307763] Posting item receipt with multiple serial nos. generates a separate warehouse entry for each serial no.
        Initialize();

        // [GIVEN] Location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Serial No. tracked item and item without tracking.
        CreateSNTrackedItem(SNTrackedItem);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create item receipt, with 2 lines, assign 5 serial nos. to the line with tracking.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, SNTrackedItem."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
        InvtDocumentLine.OpenItemTrackingLines();

        // [GIVEN] Post the item receipt.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [GIVEN] Find posted Inventory Receipt.
        InvtRcptHeader.SetRange("Receipt No.", InvtDocumentHeader."No.");
        InvtRcptHeader.FindLast();

        // [GIVEN] Init new Inventory Receipt.
        InvtDocumentHeader.Init();
        InvtDocumentHeader."Document Type" := InvtDocumentHeader."Document Type"::Receipt;
        InvtDocumentHeader.InitRecord();
        InvtDocumentHeader.Insert();

        // [WHEN] [THAN] Coping from posted Inventory Receipt with NewFillAppliesFields = true will be done without error
        CopyInvtDocMgt.SetProperties(true, false, false, false, true);
        CopyInvtDocMgt.CopyItemDoc(Enum::"Invt. Doc. Document Type From"::"Posted Receipt", InvtRcptHeader."No.", InvtDocumentHeader);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler')]
    [Scope('OnPrem')]
    procedure CopyCorrectionInvReceiptFromPostedInvReceiptWithItemTrackedLines()
    var
        Location: Record Location;
        Item: Record Item;
        SNTrackedItem: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        InvtRcptHeader: Record "Invt. Receipt Header";
        CopyInvtDocMgt: Codeunit "Copy Invt. Document Mgt.";
    begin
        // [FEATURE] [Inventory Receipt] [Item Tracking] [Copy Document]
        // [SCENARIO 474794] Posting correction inventory receipt with multiple serial nos. for posted inventory receipt 

        Initialize();

        // [GIVEN] Location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Serial No. tracked item and item without tracking.
        CreateSNTrackedItem(SNTrackedItem);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create item receipt, with 2 lines, assign 5 serial nos. to the line with tracking.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, SNTrackedItem."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
        InvtDocumentLine.OpenItemTrackingLines();

        // [GIVEN] Post the item receipt.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [GIVEN] Find posted Inventory Receipt.
        InvtRcptHeader.SetRange("Receipt No.", InvtDocumentHeader."No.");
        InvtRcptHeader.FindLast();

        // [GIVEN] Init new Inventory Receipt.
        InvtDocumentHeader.Init();
        InvtDocumentHeader."Document Type" := InvtDocumentHeader."Document Type"::Receipt;
        InvtDocumentHeader.InitRecord();
        InvtDocumentHeader.Insert(true);

        // [GIVEN] Update inventory receipt with location and correction.
        InvtDocumentHeader.Validate("Location Code", Location.Code);
        InvtDocumentHeader.Validate("Correction", true);
        InvtDocumentHeader.Modify();

        // [WHEN]  Coping lines from posted Inventory Receipt with item tracking data and apllies values 
        CopyInvtDocMgt.SetProperties(false, true, false, false, true);
        CopyInvtDocMgt.SetCopyItemTracking(true);
        CopyInvtDocMgt.CopyItemDoc(Enum::"Invt. Doc. Document Type From"::"Posted Receipt", InvtRcptHeader."No.", InvtDocumentHeader);

        // [THEN] Posting should be done without error
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler')]
    [Scope('OnPrem')]
    procedure CopyInvShipmentFromPostedInvReceiptWithItemTrackedLines()
    var
        Location: Record Location;
        Item: Record Item;
        SNTrackedItem: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        InvtRcptHeader: Record "Invt. Receipt Header";
        CopyInvtDocMgt: Codeunit "Copy Invt. Document Mgt.";
    begin
        // [FEATURE] [Inventory Receipt] [Inventory Shipment] [Item Tracking] [Copy Document]
        // [SCENARIO 474794] Posting inventory receipt with multiple serial nos.

        Initialize();

        // [GIVEN] Location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Serial No. tracked item and item without tracking.
        CreateSNTrackedItem(SNTrackedItem);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create item receipt, with 2 lines, assign 5 serial nos. to the line with tracking.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, SNTrackedItem."No.", LibraryRandom.RandInt(100), LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
        InvtDocumentLine.OpenItemTrackingLines();

        // [GIVEN] Post the item receipt.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [GIVEN] Find posted Inventory Receipt.
        InvtRcptHeader.SetRange("Receipt No.", InvtDocumentHeader."No.");
        InvtRcptHeader.FindLast();

        // [GIVEN] Init new Inventory Receipt.
        InvtDocumentHeader.Init();
        InvtDocumentHeader."Document Type" := InvtDocumentHeader."Document Type"::Shipment;
        InvtDocumentHeader.InitRecord();
        InvtDocumentHeader.Insert(true);

        // [WHEN] Coping lines from posted Inventory Receipt with item tracking data and apllies values
        CopyInvtDocMgt.SetProperties(true, false, false, false, true);
        CopyInvtDocMgt.SetCopyItemTracking(true);
        CopyInvtDocMgt.CopyItemDoc(Enum::"Invt. Doc. Document Type From"::"Posted Receipt", InvtRcptHeader."No.", InvtDocumentHeader);

        // [THEN] Posting should be done without error
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NotCopiedAppliesValuesMessageHandler(Msg: Text[1024])
    var
        InvDocCopyIssue: Label 'Inventory Document copying issue.';
        LinesNotAppliedMsg: Label 'There is 1 document line(s) with Item Tracking which requires manual specify of apply to/from numbers within Item Tracking Lines';
    begin
        Assert.IsTrue(StrPos(Msg, LinesNotAppliedMsg) > 0, InvDocCopyIssue);
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
        Initialize();
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
        Initialize();
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
        Initialize();
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
    begin
        Initialize();
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
        Initialize();
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
        Item: Record Item;
        LocationReceipt: Record Location;
        LocationPutAwayAndPick: Record Location;
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
        Item: Record Item;
        LocationShipment: Record Location;
        LocationPutAwayAndPick: Record Location;
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

    [Test]
    procedure AutoReserveSalesLineFromInventoryReceipt()
    var
        Item: Record Item;
        Location: Record Location;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 426870] Auto reserve sales line from inventory receipt.
        Initialize();
        AllowInvtDocReservationInInventorySetup();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(Item);

        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, LibraryInventory.CreateItemNo(), 0, LibraryRandom.RandIntInRange(20, 40));
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, LibraryRandom.RandIntInRange(20, 40));

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandInt(10), Location.Code, WorkDate());

        LibrarySales.AutoReserveSalesLine(SalesLine);

        ReservationEntry.SetSourceFilter(
          Database::"Invt. Document Line", InvtDocumentLine."Document Type".AsInteger(), InvtDocumentLine."Document No.",
          InvtDocumentLine."Line No.", false);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Item No.", Item."No.");
        ReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
        ReservationEntry.TestField("Item No.", Item."No.");
        ReservationEntry.TestField("Source Type", Database::"Sales Line");
        ReservationEntry.TestField("Source ID", SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ReservationModalPageHandler,AvailableInvtDocLinesModalPageHandler')]
    procedure AutoReservePurchaseLineForInventoryShipment()
    var
        Item: Record Item;
        Location: Record Location;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 426870] Auto reserve purchase line for inventory shipment.
        Initialize();
        AllowInvtDocReservationInInventorySetup();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(Item);

        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, LibraryInventory.CreateItemNo(), 0, LibraryRandom.RandIntInRange(20, 40));
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, LibraryRandom.RandInt(10));

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandIntInRange(20, 40), Location.Code, WorkDate());

        PurchaseLine.ShowReservation();

        ReservationEntry.SetSourceFilter(
          Database::"Invt. Document Line", InvtDocumentLine."Document Type".AsInteger(), InvtDocumentLine."Document No.",
          InvtDocumentLine."Line No.", false);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Item No.", Item."No.");
        ReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
        ReservationEntry.TestField("Item No.", Item."No.");
        ReservationEntry.TestField("Source Type", Database::"Purchase Line");
        ReservationEntry.TestField("Source ID", PurchaseLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostInventoryReceiptWithUOM()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO 467540] Unit Cost is not updated as per Unit of Measure in Inventory Receipt line
        Initialize();

        // [GIVEN] Create Location with Inventory Posting Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Item and one Item Unit of Measure Code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 2);

        // [GIVEN] Create Inventory Receipt with Location Code and update Posting No. on Inventory Receipt Document.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();

        // [GIVEN] Create Inventory Receipt Line and update Unit of Measure Code other than Base Unit of Measure Code
        LibraryInventory.CreateInvtDocumentLine(
        InvtDocumentHeader, InvtDocumentLine, Item."No.", Item."Unit Cost", LibraryRandom.RandDec(10, 2));
        InvtDocumentLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        InvtDocumentLine.Modify();

        // [WHEN] Post the Inventory Receipt
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [VERIFY] Verify the Item Ledger Entry Created by last Inventory Receipt.
        ItemLedgerEntry.FindLast();
        Assert.AreEqual(Item."No.", ItemLedgerEntry."Item No.", ItemNoErr);
        Assert.AreEqual(ItemUnitOfMeasure.Code, ItemLedgerEntry."Unit of Measure Code", UnitOfMeasureCodeErr);
        Assert.AreEqual(Item."Unit Cost" * 2, ItemLedgerEntry."Cost Amount (Actual)", UnitCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure ValidateDimensionUpdatedInInventoryShipmentDocumentLine()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        InvtShipment: TestPage "Invt. Shipment";
    begin
        // [SCENARIO 468226] Dimension is not update in the inventory shipment document
        Initialize();
        GeneralLedgerSetup.Get();

        // [GIVEN] Setup item document, create an item, and dimension
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        LibraryInventory.CreateItem(Item);
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");

        // [GIVEN] Create Inventory Shipment Line for type item, with Location, and Salesperson/Purchaser
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Shipment, Location.Code, SalespersonPurchaser.Code);

        // [WHEN] Open Inventory Shipment Page, and update Shortcut Dimension 1 Code field value
        InvtShipment.OpenEdit();
        InvtShipment.Filter.SetFilter("No.", InvtDocumentHeader."No.");
        InvtShipment."Shortcut Dimension 1 Code".SetValue(DimensionValue.Code);

        // [THEN] Find the first Inventory Shipment Line
        InvtShipment.ShipmentLines.First();

        // [VERIFY] Verify: The dimension on the Inventory Shipment line should be the same as its Inventory Shipment document dimension
        Assert.AreEqual(
            InvtShipment."Shortcut Dimension 1 Code".Value,
            InvtShipment.ShipmentLines."Shortcut Dimension 1 Code".Value,
            StrSubstNo(DimensionErr, InvtShipment."Shortcut Dimension 1 Code".Value));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUnitCostWithDiffBaseUOM()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [SCENARIO 469309] Unit cost is not populated when item no. is entered or Uom is changed in Inventory receipt lines
        Initialize();

        // [GIVEN] Create Location with Inventory Posting Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Item and one Item Unit of Measure Code
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Add Unit cost in the Item
        Item."Unit Cost" := LibraryRandom.RandDec(10, 2);
        Item.Modify();

        // [GIVEN] Create New Unit of Measure Code.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Create new Item Unit of Measure Code.
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 2);

        // [GIVEN] Create Inventory Receipt with Location Code and update Posting No. on Inventory Receipt Document.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();

        // [GIVEN] Create Inventory Receipt Line and update Unit of Measure Code other than Base Unit of Measure Code
        LibraryInventory.CreateInvtDocumentLine(
        InvtDocumentHeader, InvtDocumentLine, Item."No.", Item."Unit Cost", LibraryRandom.RandDec(10, 2));
        InvtDocumentLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        InvtDocumentLine.Modify();

        // [VERIFY] Verify Unit Cost will update when Base Unit Of Measure Code is Change to new Unit of Measure Code. 
        Assert.AreEqual(Item."Unit Cost" * ItemUnitOfMeasure."Qty. per Unit of Measure", InvtDocumentLine."Unit Cost", UnitCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUnitCostWhenUsingItemSKUAndChangingUOMInInventoryReceipt()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: array[2] of Record "Item Unit of Measure";
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // [SCENARIO 473495] Unit Cost is not updated when using Item SKU and changing UoM in Inventory Receipt
        Initialize();

        // [GIVEN] Create Location with Inventory Posting Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Item and Item Unit of Measure Code
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Add Unit cost in the Item
        Item."Unit Cost" := LibraryRandom.RandDec(10, 2);
        Item.Modify(true);

        // [GIVEN] Create Item Unit of Measure Code 1.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure[1], Item."No.", UnitOfMeasure.Code, 1);

        // [GIVEN] Create Item Unit of Measure Code 2.
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure[2], Item."No.", 2);

        // [GIVEN] Create Stock Keeping Unit for Item
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, Item."No.", '');

        // [GIVEN] Create Inventory Receipt with Location Code and update Posting No. on Inventory Receipt Document.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify(true);

        // [GIVEN] Create Inventory Receipt Line and update Unit of Measure Code other than Base Unit of Measure Code
        LibraryInventory.CreateInvtDocumentLine(
        InvtDocumentHeader, InvtDocumentLine, Item."No.", Item."Unit Cost", LibraryRandom.RandDec(10, 2));
        InvtDocumentLine.Validate("Unit of Measure Code", ItemUnitOfMeasure[1].Code);
        InvtDocumentLine.Modify(true);

        // [VERIFY] Verify: Unit Cost will when Unit Of Measure Code 1 applied.
        Assert.AreEqual(Item."Unit Cost" * ItemUnitOfMeasure[1]."Qty. per Unit of Measure", InvtDocumentLine."Unit Cost", UnitCostErr);

        // [THEN] Update Unit of Measure Code on Inventory Receipt Line as 2.
        InvtDocumentLine.Validate("Unit of Measure Code", ItemUnitOfMeasure[2].Code);
        InvtDocumentLine.Modify(true);

        // [VERIFY] Verify: Unit Cost will update when Unit Of Measure Code 2 applied.
        Assert.AreEqual(Item."Unit Cost" * ItemUnitOfMeasure[2]."Qty. per Unit of Measure", InvtDocumentLine."Unit Cost", UnitCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyShortcutDimensionOnPostedInventoryReceiptSubForm()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        InvtReceiptHeader: Record "Invt. Receipt Header";
        InvtReceiptLine: Record "Invt. Receipt Line";
        InvtReceiptSubform: TestPage "Invt. Receipt Subform";
        PostedInvtReceiptSubform: TestPage "Posted Invt. Receipt Subform";
        DimValue: Code[20];
    begin
        // [SCENARIO 482799] Shortcut dimension value does not appear on the column of Posted Inventory Shipment Line and Posted Inventory Receipt Line
        Initialize();

        // [GIVEN] Create Dimension with Values "V1"
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimValue := DimensionValue.Code;

        // [GIVEN] Set Dimension V1 as Shortcut Dimension 3 in General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Create Setup for Item Document
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        LibraryInventory.CreateItem(Item);

        // [THEN] Create Inventory Receipt Document
        CreateInvtDocumentWithLine(
            InvtDocumentHeader,
            InvtDocumentLine,
            Item,
            InvtDocumentHeader."Document Type"::Receipt,
            Location.Code,
            SalespersonPurchaser.Code);

        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();

        // [GIVEN] Set ShortcutDimCode3 = "V1" in Invt. Shipment Subform Order Subform
        InvtReceiptSubform.OpenEdit();
        InvtReceiptSubform.GoToRecord(InvtDocumentLine);
        InvtReceiptSubform."ShortcutDimCode[3]".SetValue(DimValue);
        InvtReceiptSubform.Close();


        // [WHEN] Posted Inventory Shipment Document
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [THEN] Get Posted Invt. Shipment Document and Open Posted Invt. Shipment Subform
        InvtReceiptHeader.Get(InvtDocumentHeader."Posting No.");
        InvtReceiptLine.SetRange("Document No.", InvtReceiptHeader."No.");
        InvtReceiptLine.FindFirst();
        PostedInvtReceiptSubform.OpenView();
        PostedInvtReceiptSubform.GoToRecord(InvtReceiptLine);

        // [VERIFY] Verify: Shortcut Dimension 3 on Posted Invt. Shipment Subform
        PostedInvtReceiptSubform."ShortcutDimCode[3]".AssertEquals(DimValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyShortcutDimensionOnPostedInventoryShipmentSubForm()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        InvtShipmentHeader: Record "Invt. Shipment Header";
        InvtShipmentLine: Record "Invt. Shipment Line";
        InvtShipmentSubform: TestPage "Invt. Shipment Subform";
        PostedInvtShipmentSubform: TestPage "Posted Invt. Shipment Subform";
        DimValue: Code[20];
    begin
        // [SCENARIO 482799] Shortcut dimension value does not appear on the column of Posted Inventory Shipment Line and Posted Inventory Receipt Line
        Initialize();

        // [GIVEN] Create Dimension with Values "V1"
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimValue := DimensionValue.Code;

        // [GIVEN] Set Dimension V1 as Shortcut Dimension 3 in General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Create Setup for Item Document
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        LibraryInventory.CreateItem(Item);

        // [THEN] Create Inventory Shipment Document
        CreateInvtDocumentWithLine(
            InvtDocumentHeader,
            InvtDocumentLine,
            Item,
            InvtDocumentHeader."Document Type"::Shipment,
            Location.Code,
            SalespersonPurchaser.Code);

        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();

        // [GIVEN] Set ShortcutDimCode3 = "V1" in Invt. Shipment Subform Order Subform
        InvtShipmentSubform.OpenEdit();
        InvtShipmentSubform.GoToRecord(InvtDocumentLine);
        InvtShipmentSubform."ShortcutDimCode[3]".SetValue(DimValue);
        InvtShipmentSubform.Close();


        // [WHEN] Posted Inventory Shipment Document
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [THEN] Get Posted Invt. Shipment Document and Open Posted Invt. Shipment Subform
        InvtShipmentHeader.Get(InvtDocumentHeader."Posting No.");
        InvtShipmentLine.SetRange("Document No.", InvtShipmentHeader."No.");
        InvtShipmentLine.FindFirst();
        PostedInvtShipmentSubform.OpenView();
        PostedInvtShipmentSubform.GoToRecord(InvtShipmentLine);

        // [VERIFY] Verify: Shortcut Dimension 3 on Posted Invt. Shipment Subform
        PostedInvtShipmentSubform."ShortcutDimCode[3]".AssertEquals(DimValue);
    end;

    [Test]
    procedure InventoryReceiptDoesNotRequireWarehouseHandling()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [Item Receipt] [Warehouse]
        // [SCENARIO 481855] Inventory Receipt does not require warehouse handling.
        Initialize();

        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, true, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, 1);
        InvtDocumentLine.Validate("Bin Code", Bin.Code);
        InvtDocumentLine.Modify(true);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        Item.CalcFields(Inventory);
        Item.TestField(Inventory, 1);

        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.CalcSums("Qty. (Base)");
        WarehouseEntry.TestField("Qty. (Base)", 1);
    end;

    [Test]
    procedure InventoryShipmentDoesNotRequireWarehouseHandling()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        WarehouseEntry: Record "Warehouse Entry";
        QtyInStock: Decimal;
    begin
        // [FEATURE] [Item Shipment] [Warehouse]
        // [SCENARIO 481855] Inventory Shipment does not require warehouse handling.
        Initialize();

        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        QtyInStock := CreateAndPostItemJournalLine(Item."No.", Location.Code, Bin.Code);

        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, Item."No.", 0, 1);
        InvtDocumentLine.Validate("Bin Code", Bin.Code);
        InvtDocumentLine.Modify(true);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        Item.Get(InvtDocumentLine."Item No.");
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, QtyInStock - 1);

        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.CalcSums("Qty. (Base)");
        WarehouseEntry.TestField("Qty. (Base)", QtyInStock - 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure VerifyDimIsNotUpdatedOnLineAfterLocationCodeIsValidatedOnHeaderAndUserDontWantToUpdateDimOnLines()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        InvtShipment: TestPage "Invt. Shipment";
    begin
        // [SCENARIO 486635] Dimension is not updated on the inventory shipment line after location code is validated on the header and user don't want to update dimension on the lines
        Initialize();

        // [GIVEN] Create Dimension Value for Global Dimension 1
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Location with Inventory Posting Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Default Dimension for Location
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Create Inventory Shipment header without Location
        InvtDocumentHeader.Init();
        InvtDocumentHeader."Document Type" := InvtDocumentHeader."Document Type"::Shipment;
        InvtDocumentHeader.Insert(true);

        // [GIVEN] Create Inventory Shipment Line for Item type
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, Item."No.", Item."Unit Cost", LibraryRandom.RandDec(10, 2));

        // [GIVEN] Open Inventory Shipment Page
        InvtShipment.OpenEdit();
        InvtShipment.Filter.SetFilter("No.", InvtDocumentHeader."No.");

        // [WHEN] Set Location Code on Inventory Shipment Page
        InvtShipment."Location Code".SetValue(Location.Code);

        // [THEN] Find the first Inventory Shipment Line
        InvtShipment.ShipmentLines.First();

        // [VERIFY] Verify: The dimension on the Inventory Shipment line should be empty        
        Assert.AreEqual('', InvtShipment.ShipmentLines."Shortcut Dimension 1 Code".Value, StrSubstNo(DimensionErr, ''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySourceCodeOnInvDocLineWhenInventoryDocumentWithDefaultDimensionPriority()
    var
        SourceCode: Record "Source Code";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        Location: Record Location;
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        // [SCENARIO 491906] Inventory documents - source code is not added to the document which results in wrong dimension.
        Initialize();

        // [GIVEN] Create Source Code.
        LibraryERM.CreateSourceCode(SourceCode);
        OpenSourceCodeSetupPage(SourceCode);

        // [GIVEN] Create Dimension Value for Global Dimension 1
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue2, LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Default Dimension for Location.
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Create Default Dimension for Item.
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension, Database::Item, Item."No.", DimensionValue2."Dimension Code", DimensionValue2.Code);

        // [GIVEN] Set Dimension Priority.
        SetupDimensionPriority(SourceCode.Code, LibraryRandom.RandIntInRange(1, 5), LibraryRandom.RandIntInRange(6, 10));

        // [GIVEN] Create Inventory Document Header.
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);

        // [GIVEN] Create Inventory Document Line.
        LibraryInventory.CreateInvtDocumentLine(
            InvtDocumentHeader, InvtDocumentLine, Item."No.", Item."Unit Cost", LibraryRandom.RandInt(10));

        // [VERIFY] Verify: Source Code exists on the Invt Document Line Table.
        Assert.AreEqual(SourceCode.Code, InvtDocumentLine."Source Code", StrSubstNo(SourceCodeErr, InvtDocumentLine.TableCaption()));

        // [THEN] Post the document.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [VERIFY] Verify: Source Code was not blank in Invt. Receipt Line Table.
        VerifySourceCodeNotBlankInInvtReceiptLine(InvtDocumentHeader, SourceCode);

        // [VERIFY] Verify: Source Code was not blank in Value Entry Table.
        VerifySourceCodeNotBlankInValueEntry(InvtDocumentHeader, SourceCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionAddedIntoTrackingItem()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        ItemNo: Code[20];
        InvtDocType: Enum "Invt. Doc. Document Type";
        Qty: Decimal;
    begin
        // [SCENARIO 497363]  Post the Inventory Document Receipt with Item has Item tracking Code and modify Dimension after updating the Tracking
        Initialize();

        // [GIVEN] Create Item Tracking Code
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);

        // [GIVEN]  Create Item with Item Tracking Code
        ItemNo := CreateItemWithItemTrackingCode(ItemTrackingCode.Code);

        // [GIVEN] Create Location with Inventory Posting Setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Invt. Document Receipt
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocType::Receipt, Location.Code);

        // [GIVEN] Let the quantity to be assign
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Create Invt. Document Line
        LibraryInventory.CreateInvtDocumentLine(InvtDocumentHeader, InvtDocumentLine, ItemNo, LibraryRandom.RandDec(100, 2), Qty);

        // [GIVEN] Define Item Tracking on Invt Document Line
        LibraryItemTracking.CreateItemReceiptItemTracking(ReservationEntry, InvtDocumentLine, '', '', '', Qty);

        // [GIVEN] Create Dimension Value of Global Dimension 1
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));

        // [THEN] Assign the Dimension Value to Invt. Document Line
        InvtDocumentLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        InvtDocumentLine.Modify(true);

        // [THEN] Post the Invt. Document Receipt
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [VERIFY] Posted Invt. Document Line has Dimesnion Value same as defined.
        VerifyInvtDocumentLineWithDimensionValue(DimensionValue.Code, InvtDocumentHeader);
    end;

    [Test]
    procedure PlanningAndWarehouseTabsVisibleForTypeInventorySKUCardAfterItemInsert()
    var
        Item: Record Item;
        Location: Record Location;
        StocKkeepingUnitCard: TestPage "Stockkeeping Unit Card";
    begin
        // [SCENARIO 524116] When creating new stockkeeping unit card initially only General, Invoicing and Replenishment are visible, and Planning and Warehouse are not.
        Initialize();

        // [GIVEN] Create an Item and Validate Type as Inventory.
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Inventory);
        Item.Modify(true);

        // [GIVEN] Create a Location.
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] Open Stockkeeping Unit Card page.
        StocKkeepingUnitCard.OpenNew();
        StocKkeepingUnitCard."Item No.".SetValue(Item."No.");
        StocKkeepingUnitCard."Location Code".SetValue(Location.Code);

        // [THEN] Verify Planning tab is visible.
        Assert.IsTrue(
            StocKkeepingUnitCard."Reordering Policy".Visible(),
            ReorderingPolicyShouldBeVisibleErr);

        // [THEN] Verify Warehouse tab is visible.
        Assert.IsTrue(
            StocKkeepingUnitCard."Special Equipment Code".Visible(),
            SpecialEquipmentCodeShouldBeVisibleErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Inventory Documents");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Inventory Documents");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();

        SetupInvtDocumentsNoSeries();
        SetupPostedDirectTransfersNoSeries();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Inventory Documents");
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
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);
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
        InventorySetup.Validate("Posted Direct Trans. Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Validate("Direct Transfer Posting", InventorySetup."Direct Transfer Posting"::"Direct Transfer");
        InventorySetup.Modify(true);
    end;

    local procedure SetupInvtDocumentsNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if InventorySetup."Invt. Receipt Nos." = '' then
            InventorySetup.Validate("Invt. Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if InventorySetup."Posted Invt. Receipt Nos." = '' then
            InventorySetup.Validate("Posted Invt. Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if InventorySetup."Invt. Shipment Nos." = '' then
            InventorySetup.Validate("Invt. Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if InventorySetup."Posted Invt. Shipment Nos." = '' then
            InventorySetup.Validate("Posted Invt. Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
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

    local procedure AllowInvtDocReservationInInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Allow Invt. Doc. Reservation" := true;
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
    begin
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        Item.SetRange("No.", ItemNo);
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        LibraryCosting.CreateRevaluationJournal(
          ItemJournalBatch, Item, WorkDate(), LibraryUtility.GenerateGUID(), "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", false);
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

    local procedure OpenSourceCodeSetupPage(SourceCode: Record "Source Code")
    var
        SourceCodeSetupPage: TestPage "Source Code Setup";
    begin
        SourceCodeSetupPage.OpenEdit();
        SourceCodeSetupPage."Invt. Receipt".SetValue(SourceCode.Code);
        SourceCodeSetupPage.Close();
    end;

    local procedure SetupDimensionPriority(SourceCode: Code[10]; ItemPriority: Integer; LocationPriority: Integer)
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        DefaultDimensionPriority.SetRange("Source Code", SourceCode);
        DefaultDimensionPriority.DeleteAll();

        DefaultDimensionPriority.Validate("Source Code", SourceCode);
        CreateDefaultDimPriority(DefaultDimensionPriority, Database::Item, ItemPriority);
        CreateDefaultDimPriority(DefaultDimensionPriority, Database::Location, LocationPriority);
    end;

    local procedure CreateDefaultDimPriority(var DefaultDimPriority: Record "Default Dimension Priority"; TableID: Integer; Priority: Integer)
    begin
        if (TableID = 0) or (Priority = 0) then
            exit;

        DefaultDimPriority.Validate("Table ID", TableID);
        DefaultDimPriority.Validate(Priority, Priority);
        DefaultDimPriority.Insert(true);
    end;

    local procedure VerifySourceCodeNotBlankInInvtReceiptLine(InvtDocumentHeader: Record "Invt. Document Header"; SourceCode: Record "Source Code")
    var
        InvtReceiptLine: Record "Invt. Receipt Line";
    begin
        InvtReceiptLine.SetRange("Receipt No.", InvtDocumentHeader."No.");
        InvtReceiptLine.FindFirst();
        Assert.AreEqual(SourceCode.Code, InvtReceiptLine."Source Code", StrSubstNo(SourceCodeErr, InvtReceiptLine.TableCaption()));
    end;

    local procedure VerifySourceCodeNotBlankInValueEntry(InvtDocumentHeader: Record "Invt. Document Header"; SourceCode: Record "Source Code")
    var
        ValueEntry: Record "Value Entry";
        InvtReceiptHeader: Record "Invt. Receipt Header";
    begin
        InvtReceiptHeader.SetRange("Receipt No.", InvtDocumentHeader."No.");
        InvtReceiptHeader.FindFirst();
        ValueEntry.SetRange("Document No.", InvtReceiptHeader."No.");
        ValueEntry.FindFirst();
        Assert.AreEqual(SourceCode.Code, ValueEntry."Source Code", StrSubstNo(SourceCodeErr, ValueEntry.TableCaption()));
    end;

    local procedure CreateItemWithItemTrackingCode(ItemTrackingCode: Code[10]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure VerifyInvtDocumentLineWithDimensionValue(DimensionValueCode: Code[20]; InvtDocumentHeader: Record "Invt. Document Header")
    var
        InvtReceiptLine: Record "Invt. Receipt Line";
    begin
        InvtReceiptLine.SetRange("Receipt No.", InvtDocumentHeader."No.");
        InvtReceiptLine.FindFirst();
        Assert.AreEqual(DimensionValueCode, InvtReceiptLine."Shortcut Dimension 1 Code", DimensionValueErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
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
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ReservationModalPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.AvailableToReserve.Invoke();
    end;

    [ModalPageHandler]
    procedure AvailableInvtDocLinesModalPageHandler(var AvailableInvtDocLines: TestPage "Available - Invt. Doc. Lines")
    begin
        AvailableInvtDocLines.Reserve.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

