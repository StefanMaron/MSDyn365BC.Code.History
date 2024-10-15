codeunit 147111 "SCM Item Documents"
{
    // // [FEATURE] [SCM]

    Subtype = Test;

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
        LibraryCDTracking: Codeunit "Library - CD Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryRUReports: Codeunit "Library RU Reports";
        isInitialized: Boolean;
        WrongQuantityErr: Label 'Wrong quantity in "Item G/L Turnover"';
        WrongAmountErr: Label 'Wrong amount in "Item G/L Turnover"';
        ItemTrackingAction: Option AssignSerialNo,SelectEntries;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReceiptWithDimension()
    var
        ItemDocumentHeader: Record "Item Document Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
    begin
        // Setup
        Initialize;
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);

        // Execute
        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Receipt, Location.Code);
        ItemDocumentHeader.Validate("Salesperson/Purchaser Code", SalespersonPurchaser.Code);
        ItemDocumentHeader.Modify(true);

        // Verify
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, ItemDocumentHeader."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReceiptWithDimensionLines()
    var
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DimensionValueItem: Record "Dimension Value";
    begin
        // Setup
        Initialize;
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValueItem);

        // Execute
        CreateItemDocumentWithLine(
          ItemDocumentHeader, ItemDocumentLine, Item, ItemDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code);

        // Verify
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, ItemDocumentLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemShipmentWithDimension()
    var
        ItemDocumentHeader: Record "Item Document Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
    begin
        // Setup
        Initialize;
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);

        // Execute
        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentHeader."Document Type"::Shipment, Location.Code);
        ItemDocumentHeader.Validate("Salesperson/Purchaser Code", SalespersonPurchaser.Code);
        ItemDocumentHeader.Modify(true);

        // Verify
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, ItemDocumentHeader."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemShipmentWithDimensionLines()
    var
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
    begin
        // Setup
        Initialize;
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValue);

        // Execute
        CreateItemDocumentWithLine(
          ItemDocumentHeader, ItemDocumentLine, Item, ItemDocumentHeader."Document Type"::Shipment, Location.Code, SalespersonPurchaser.Code);

        // Verify
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, ItemDocumentLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedItemReceiptWithDimension()
    var
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DimensionValueItem: Record "Dimension Value";
        ItemReceiptHeader: Record "Item Receipt Header";
        ItemReceiptLine: Record "Item Receipt Line";
    begin
        // Setup
        Initialize;
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValueItem);

        // Execute
        CreateItemDocumentWithLine(
          ItemDocumentHeader, ItemDocumentLine, Item, ItemDocumentHeader."Document Type"::Receipt, Location.Code, SalespersonPurchaser.Code);
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        // Verify
        ItemReceiptHeader.SetRange("Location Code", Location.Code);
        ItemReceiptHeader.FindFirst;
        Assert.AreEqual(SalespersonPurchaser.Code, ItemReceiptHeader."Purchaser Code", 'Purchaser code should be same');
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, ItemReceiptHeader."Dimension Set ID");
        ItemReceiptLine.SetRange("Document No.", ItemReceiptHeader."No.");
        ItemReceiptLine.FindFirst;
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, ItemReceiptLine."Dimension Set ID");
        VerifyDimensionCode(DimensionValueItem."Dimension Code", DimensionValueItem.Code, ItemReceiptLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedItemShipmentWithDimension()
    var
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DimensionValueItem: Record "Dimension Value";
        ItemShipmentHeader: Record "Item Shipment Header";
        ItemShipmentLine: Record "Item Shipment Line";
    begin
        // Setup
        Initialize;
        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        CreateItemWithDimension(Item, DimensionValueItem);

        // Execute
        CreateItemDocumentWithLine(
          ItemDocumentHeader, ItemDocumentLine, Item, ItemDocumentHeader."Document Type"::Shipment, Location.Code, SalespersonPurchaser.Code);
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        // Verify
        ItemShipmentHeader.SetRange("Location Code", Location.Code);
        ItemShipmentHeader.FindFirst;
        Assert.AreEqual(SalespersonPurchaser.Code, ItemShipmentHeader."Salesperson Code", 'Salesperson code should be same');
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, ItemShipmentHeader."Dimension Set ID");
        ItemShipmentLine.SetRange("Document No.", ItemShipmentHeader."No.");
        ItemShipmentLine.FindFirst;
        VerifyDimensionCode(DimensionValue."Dimension Code", DimensionValue.Code, ItemShipmentLine."Dimension Set ID");
        VerifyDimensionCode(DimensionValueItem."Dimension Code", DimensionValueItem.Code, ItemShipmentLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverCostBlank()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover]
        // [SCENARIO 376914] Inbound item entries without cost are included in "Debit Qty." in "Item G/L Turnover", outbound entries - in credit qty.

        Initialize;

        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Post inbound item entry with quantity = "X", cost amount = 0
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity * 2, 0);
        // [GIVEN] Post outbound item entry with quantity = "Y", cost amount = 0
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", Quantity, 0);

        // [WHEN] Calculate Item G/L Turnover
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit quantity = "X", credit quantity = "Y"
        Assert.AreEqual(Quantity * 2, DebitQty, WrongQuantityErr);
        Assert.AreEqual(Quantity, CreditQty, WrongQuantityErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverActualCost()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Integer;
        UnitCost: Integer;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover]
        // [SCENARIO 376914] "Item G/L Turnover" should show invoiced inbound item entries' Quantity and Amount in Debit columns, Outbound - in Credit columns

        Initialize;

        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandInt(100);
        UnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Post inbound item entry with quantity = "X", actual cost amount = "Y"
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity * 2, UnitCost);
        // [GIVEN] Post outbound item entry with quantity = "Z", actual cost amount = "W"
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", Quantity, UnitCost);

        // [WHEN] Calculate Item G/L Turnover
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit quantity = "X", debit amount = "Y", credit quantity = "Z", credit amount = "W"
        Assert.AreEqual(Quantity * 2, DebitQty, WrongQuantityErr);
        Assert.AreEqual(Quantity, CreditQty, WrongQuantityErr);
        Assert.AreEqual(UnitCost * Quantity * 2, DebitCost, WrongAmountErr);
        Assert.AreEqual(UnitCost * Quantity, CreditCost, WrongAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverExpectedCost()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover]
        // [SCENARIO 376914] Item entries with expected cost not invoiced are not included in Inventory G/L Turnover

        Initialize;

        // [GIVEN] Post inbound item entry with quantity <> 0, expected cost amount <> 0
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Post outbound item entry with quantity <> 0, expected cost amount <> 0
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Calculate Item G/L Turnover
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit quantity = 0, debit amount = 0, credit quantity = 0, credit amount = 0
        Assert.AreEqual(0, DebitCost, WrongAmountErr);
        Assert.AreEqual(0, CreditCost, WrongAmountErr);
        Assert.AreEqual(0, DebitQty, WrongQuantityErr);
        Assert.AreEqual(0, CreditQty, WrongQuantityErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverActualCostRevaluation()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Amount: array[2] of Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover] [Revaluation]
        // [SCENARIO 376914] Calculate "Item G/L Turnover" for positive item entry with negative revaluation

        Initialize;

        LibraryInventory.CreateItem(Item);
        Amount[1] := LibraryRandom.RandDecInRange(101, 200, 2);
        Amount[2] := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Post positive item entry for item "I", amount = "X"
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1, Amount[1]);
        // [GIVEN] Revaluate item "I", new value = "Y" < "X" (revaluation amount is negative)
        PostItemRevaluation(Item."No.", Amount[2]);

        // [WHEN] Calculate Item G/L Turnover
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit amount = "X", Credit amount = "X" - "Y"
        Assert.AreEqual(Amount[1], DebitCost, WrongAmountErr);
        Assert.AreEqual(Amount[1] - Amount[2], CreditCost, WrongAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverRedStornoCostBlank()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover] [Red Storno]
        // [SCENARIO 376914] Outbound item entry posted with "Red Storno" and cost amount = 0 is tallied in debit amount in "Item G/L Turnover"

        Initialize;
        EnableRedStorno;

        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandInt(100);

        // [GIVEN] Post inbound item entry: quantity = "X", cost amount = 0
        PostItemJournalLine(ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity * 2, 0);
        // [GIVEN] Post reversal item entry: quantity = -"X" / 2, "Red Storno" = TRUE, cost amount = 0
        PostItemJournalLineRedStorno(ItemJournalLine."Entry Type"::Purchase, Item."No.", -Quantity, 0);

        // [WHEN] Calculate Item G/L Turnover
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit quantity = "X" / 2, credit quantity = 0
        Assert.AreEqual(Quantity, DebitQty, WrongQuantityErr);
        Assert.AreEqual(0, CreditQty, WrongQuantityErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverActualCostRedStorno()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        UnitCost: Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover] [Red Storno]
        // [SCENARIO 376914] Outbound item entry posted with "Red Storno" and positive cost amount is tallied in debit amount in "Item G/L Turnover"

        Initialize;
        EnableRedStorno;

        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        UnitCost := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Post inbound item entry: quantity = "X", unit cost = "Y"
        PostItemJournalLine(ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity * 2, UnitCost);
        // [GIVEN] Post reversal item entry: quantity = -"X" / 2, unit cost = "Y", "Red Storno" = TRUE
        PostItemJournalLineRedStorno(ItemJournalLine."Entry Type"::Purchase, Item."No.", -Quantity, UnitCost);

        // [WHEN] Calculate Item G/L Turnover
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit Quantity = "X" / 2, credit quantity = 0
        Assert.AreEqual(Quantity, DebitQty, WrongQuantityErr);
        Assert.AreEqual(0, CreditQty, WrongQuantityErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostItemShipmentWithFA()
    var
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        FixedAssetNo: Code[20];
        DepreciationBookCode: Code[10];
        AcquisitionCostAccountNo: Code[20];
    begin
        // [FEATURE] [Item Shipment] [Fixed Asset]
        // [SCENARIO 379130] Write-off of items in the value of the fixed asset fills source info on acquisition cost G/L Entry
        Initialize;

        SetupForItemDocument(SalespersonPurchaser, Location, DimensionValue);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Fixed Asset "FA" and FA Depreciation Book with FA Posting Group where "Acquisition Cost Account" = "A"
        CreateFixedAsset(FixedAssetNo, DepreciationBookCode, AcquisitionCostAccountNo);

        // [GIVEN] Item Shipment with fixed asset "FA"
        CreateItemDocumentWithLine(
          ItemDocumentHeader, ItemDocumentLine, Item, ItemDocumentHeader."Document Type"::Shipment, Location.Code, SalespersonPurchaser.Code);
        UpdateItemDocumentLineFA(ItemDocumentHeader, FixedAssetNo, DepreciationBookCode);

        // [WHEN] Post Item Shipment
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        // [THEN] Verify "Source Type" = "Fixed Asset", "Source No." = "FA" on generated G/L Entry with "G/L Account No." = "A"
        VerifyGLEntrySource(Location.Code, AcquisitionCostAccountNo, FixedAssetNo);
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

        Initialize;

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

        // [WHEN] Post the transfer
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

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

        // [WHEN] Post the transfer
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

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
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [Item Receipt] [Item Tracking] [Warehouse]
        // [SCENARIO 307763] Posting item receipt with multiple serial nos. generates a separate warehouse entry for each serial no.
        Initialize;

        // [GIVEN] Location with a bin.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID, '', '');

        // [GIVEN] Serial no.-tracked item. "SN Warehouse Tracking" is enabled.
        CreateSNTrackedItem(Item);

        // [GIVEN] Create item receipt, assign 5 serial nos. to the line.
        CreateItemDocumentWithItemTracking(
          ItemDocumentHeader, ItemDocumentLine, ItemDocumentHeader."Document Type"::Receipt,
          Item."No.", Location.Code, Bin.Code, LibraryRandom.RandIntInRange(5, 10), ItemTrackingAction::AssignSerialNo);

        // [WHEN] Post the item receipt.
        LibraryCDTracking.PostItemDocument(ItemDocumentHeader);

        // [THEN] 5 warehouse entries are created.
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::"Positive Adjmt.");
        Assert.RecordCount(WarehouseEntry, ItemDocumentLine.Quantity);

        // [THEN] Total quantity posted in the warehouse ledger = 5.
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(ItemDocumentLine.Quantity, WarehouseEntry.Quantity, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler,ItemTrackingSummaryModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemShipmentWithMultipleSerialNos()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ReceiptItemDocumentHeader: Record "Item Document Header";
        ReceiptItemDocumentLine: Record "Item Document Line";
        ShipmentItemDocumentHeader: Record "Item Document Header";
        ShipmentItemDocumentLine: Record "Item Document Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [Item Shipment] [Item Tracking] [Warehouse]
        // [SCENARIO 307763] Posting item shipment with multiple serial nos. generates a separate warehouse entry for each serial no.
        Initialize;

        // [GIVEN] Location with a bin.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID, '', '');

        // [GIVEN] Serial no.-tracked item. "SN Warehouse Tracking" is enabled.
        CreateSNTrackedItem(Item);

        // [GIVEN] Create item receipt, assign 5 serial nos. to the line and post it.
        CreateItemDocumentWithItemTracking(
          ReceiptItemDocumentHeader, ReceiptItemDocumentLine, ReceiptItemDocumentHeader."Document Type"::Receipt,
          Item."No.", Location.Code, Bin.Code, LibraryRandom.RandIntInRange(5, 10), ItemTrackingAction::AssignSerialNo);
        LibraryCDTracking.PostItemDocument(ReceiptItemDocumentHeader);

        // [GIVEN] Create item shipment, select received 5 serial nos.
        CreateItemDocumentWithItemTracking(
          ShipmentItemDocumentHeader, ShipmentItemDocumentLine, ShipmentItemDocumentHeader."Document Type"::Shipment,
          Item."No.", Location.Code, Bin.Code, ReceiptItemDocumentLine.Quantity, ItemTrackingAction::SelectEntries);

        // [WHEN] Post the item shipment.
        LibraryCDTracking.PostItemDocument(ShipmentItemDocumentHeader);

        // [THEN] 5 warehouse entries are created.
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::"Negative Adjmt.");
        Assert.RecordCount(WarehouseEntry, ShipmentItemDocumentLine.Quantity);

        // [THEN] Total quantity posted in the warehouse ledger by warehouse shipment = -5.
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(-ShipmentItemDocumentLine.Quantity, WarehouseEntry.Quantity, '');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverWithNegativeRevaluation()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
        UnitCost: Decimal;
        NewAmount: Decimal;
        RevaluationAmount: Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover] [Revaluation]
        // [SCENARIO 379097] Debit and credit amounts on "Item G/L Turnover" page for revalued item. "Red Storno" is disabled.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        UnitCost := LibraryRandom.RandDecInRange(50, 100, 2);
        NewAmount := LibraryRandom.RandDecInRange(10, 20, 2);
        RevaluationAmount := Qty * UnitCost - NewAmount;

        // [GIVEN] Post 5 pcs, each per 150 LCY.
        // [GIVEN] Post -5 pcs. Run the cost adjustment.
        LibraryInventory.CreateItem(Item);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty, UnitCost);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", Qty, 0);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Post the revaluation of the positive inventory adjustment. Old amount = 750 LCY, revalued amount = 700 LCY. Red Storno = FALSE.
        PostItemRevaluationPerItemLedgerEntry(Item."No.", NewAmount, false);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Open "Item G/L Turnover" page.
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit quantity = credit quantity = 5.
        // [THEN] Debit amount = 800 LCY (750 original + 50 adjusted cost of the negative adjustment entry posted as debit).
        // [THEN] Debit amount = 800 LCY (750 original + 50 revaluation of the original entry posted as credit).
        Assert.AreEqual(Qty, DebitQty, WrongQuantityErr);
        Assert.AreEqual(Qty, CreditQty, WrongQuantityErr);
        Assert.AreEqual(Qty * UnitCost + RevaluationAmount, DebitCost, WrongAmountErr);
        Assert.AreEqual(Qty * UnitCost + RevaluationAmount, CreditCost, WrongAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemGLTurnoverWithNegativeRevaluationRedStorno()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
        UnitCost: Decimal;
        NewAmount: Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
        DebitQty: Decimal;
        CreditQty: Decimal;
    begin
        // [FEATURE] [Item G/L Turnover] [Revaluation] [Red Storno]
        // [SCENARIO 379097] Debit and credit amounts on "Item G/L Turnover" page for revalued item. "Red Storno" is enabled.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        UnitCost := LibraryRandom.RandDecInRange(50, 100, 2);
        NewAmount := LibraryRandom.RandDecInRange(10, 20, 2);

        // [GIVEN] Enable Red Storno.
        EnableRedStorno();

        // [GIVEN] Post 5 pcs, each per 150 LCY.
        // [GIVEN] Post -5 pcs. Run the cost adjustment.
        LibraryInventory.CreateItem(Item);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty, UnitCost);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", Qty, 0);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Post the revaluation of the positive inventory adjustment. Old amount = 750 LCY, revalued amount = 700 LCY. Red Storno = TRUE.
        PostItemRevaluationPerItemLedgerEntry(Item."No.", NewAmount, true);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Open "Item G/L Turnover" page.
        CalculateItemGLTurnover(DebitCost, CreditCost, DebitQty, CreditQty, Item."No.");

        // [THEN] Debit quantity = credit quantity = 5.
        // [THEN] Debit amount = 700 LCY (750 original - 50 revaluation of the original entry posted as debit with minus sign).
        // [THEN] Debit amount = 700 LCY (750 original - 50 adjusted cost of the negative adjustment entry posted as credit with minus sign).
        Assert.AreEqual(Qty, DebitQty, WrongQuantityErr);
        Assert.AreEqual(Qty, CreditQty, WrongQuantityErr);
        Assert.AreEqual(NewAmount, DebitCost, WrongAmountErr);
        Assert.AreEqual(NewAmount, CreditCost, WrongAmountErr);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore;
        LibraryVariableStorage.Clear;
        if isInitialized then
            exit;

        LibraryCDTracking.UpdateERMCountryData;
        UpdatePostedDirectTransfersNoSeries;

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
    end;

    local procedure CalculateItemGLTurnover(var DebitCost: Decimal; var CreditCost: Decimal; var DebitQty: Decimal; var CreditQty: Decimal; ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
        ItemGLTurnover: Page "Item G/L Turnover";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ItemGLTurnover.CalculateAmounts(ValueEntry, DebitCost, CreditCost, DebitQty, CreditQty);
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

    local procedure CreateItemDocumentWithLine(var ItemDocumentHeader: Record "Item Document Header"; var ItemDocumentLine: Record "Item Document Line"; Item: Record Item; DocumentType: Option; LocationCode: Code[10]; SalespersonPurchaserCode: Code[20])
    begin
        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, DocumentType, LocationCode);
        ItemDocumentHeader.Validate("Salesperson/Purchaser Code", SalespersonPurchaserCode);
        ItemDocumentHeader.Modify(true);
        LibraryCDTracking.CreateItemDocumentLine(
          ItemDocumentHeader, ItemDocumentLine, Item."No.", Item."Unit Cost", LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateItemDocumentWithItemTracking(var ItemDocumentHeader: Record "Item Document Header"; var ItemDocumentLine: Record "Item Document Line"; ItemDocumentType: Option; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal; ItemTrkgAction: Option)
    begin
        LibraryCDTracking.CreateItemDocument(ItemDocumentHeader, ItemDocumentType, LocationCode);
        LibraryCDTracking.CreateItemDocumentLine(ItemDocumentHeader, ItemDocumentLine, ItemNo, 0, Qty);
        ItemDocumentLine.Validate("Bin Code", BinCode);
        ItemDocumentLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrkgAction);
        ItemDocumentLine.OpenItemTrackingLines();
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

    local procedure CreateFixedAsset(var FixedAssetNo: Code[20]; var DepreciationBookCode: Code[10]; var AcquisitionCostAccountNo: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        FixedAssetNo := FixedAsset."No.";
        DepreciationBookCode := LibraryRUReports.GetFirstFADeprBook(FixedAsset."No.");
        FADepreciationBook.Get(FixedAssetNo, DepreciationBookCode);
        FAPostingGroup.Get(FADepreciationBook."FA Posting Group");
        AcquisitionCostAccountNo := FAPostingGroup."Acquisition Cost Account";
    end;

    local procedure EnableRedStorno()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Enable Red Storno" := true;
        InventorySetup.Modify();
    end;

    local procedure FindLastPositiveItemLedgEntry(ItemNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.FindLast();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure UpdateItemDocumentLineFA(var ItemDocumentHeader: Record "Item Document Header"; FixedAssetNo: Code[20]; DepreciationBookCode: Code[10])
    var
        ItemDocumentLine: Record "Item Document Line";
    begin
        ItemDocumentLine.SetRange("Document Type", ItemDocumentHeader."Document Type");
        ItemDocumentLine.SetRange("Document No.", ItemDocumentHeader."No.");
        ItemDocumentLine.FindFirst;
        ItemDocumentLine.Validate("Unit Amount", LibraryRandom.RandDecInDecimalRange(500, 1000, 2));
        ItemDocumentLine.Validate("Unit Cost", LibraryRandom.RandDecInDecimalRange(500, 1000, 2));
        ItemDocumentLine.Validate("FA No.", FixedAssetNo);
        ItemDocumentLine.Validate("Depreciation Book Code", DepreciationBookCode);
        ItemDocumentLine.Modify(true);
    end;

    local procedure UpdatePostedDirectTransfersNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Posted Direct Transfer Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        InventorySetup.Modify(true);
    end;

    local procedure PostItemJournalLine(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, EntryType, ItemNo, Quantity, UnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostItemJournalLineRedStorno(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, EntryType, ItemNo, Quantity, UnitCost);

        ItemJournalLine.Validate("Red Storno", true);
        ItemJournalLine.Modify(true);

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
        ItemJournalLine.FindFirst;
        ItemJournalLine.Validate("Inventory Value (Revalued)", NewAmount);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostItemRevaluationPerItemLedgerEntry(ItemNo: Code[20]; NewAmount: Decimal; RedStorno: Boolean)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ItemJournalLine, ItemJournalBatch, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.");
        ItemJournalLine.Validate("Value Entry Type", ItemJournalLine."Value Entry Type"::Revaluation);

        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Validate("Applies-to Entry", FindLastPositiveItemLedgEntry(ItemNo));
        ItemJournalLine."Red Storno" := RedStorno;
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
        DimensionSetEntry.FindFirst;
        Assert.AreEqual(DimensionValueCode, DimensionSetEntry."Dimension Value Code", 'Dimension values should be equal');
    end;

    local procedure VerifyGLEntrySource(LocationCode: Code[10]; AcquisitionCostAccountNo: Code[20]; FixedAssetNo: Code[20])
    var
        ItemShipmentHeader: Record "Item Shipment Header";
        GLEntry: Record "G/L Entry";
    begin
        ItemShipmentHeader.SetRange("Location Code", LocationCode);
        ItemShipmentHeader.FindFirst;

        GLEntry.SetRange("G/L Account No.", AcquisitionCostAccountNo);
        GLEntry.SetRange("Document No.", ItemShipmentHeader."No.");
        GLEntry.FindFirst;
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
            FindFirst;
            TestField(Quantity, ExpectedQty);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger of
            ItemTrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke;
            ItemTrackingAction::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateModalPageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK.Invoke;
    end;
}

