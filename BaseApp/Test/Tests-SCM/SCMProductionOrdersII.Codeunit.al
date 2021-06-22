codeunit 137072 "SCM Production Orders II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Production Order] [SCM]
        IsInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        RevaluationItemJournalTemplate: Record "Item Journal Template";
        RevaluationItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        LocationGreen: Record Location;
        LocationRed: Record Location;
        LocationYellow: Record Location;
        LocationWhite: Record Location;
        LocationGreen2: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        HandlingError: Label 'Nothing to handle';
        ValidationError: Label '%1 must be %2.';
        PickActivitiesCreated: Label 'Number of Invt. Pick activities created';
        FinishProductionOrder: Label 'Do you still want to finish the order?';
        StartingDateMessage: Label 'Starting Date must be less or equal.';
        EndingDateMessage: Label 'Ending Date must be greater or equal.';
        TrackingMessage: Label 'The change will not affect existing entries';
        NewWorksheetMessage: Label 'You are now in worksheet';
        RequisitionLineMustNotExist: Label 'Requisition Line must not exist for Item %1.';
        ItemFilter: Label '%1|%2';
        DeleteItemTrackingQst: Label 'has item reservation. Do you want to delete it anyway?';
        ItemTrackingMode: Option " ","Assign Lot No.","Select Entries","Update Quantity";
        ProdOrderRtngLineNotUpdatedMsg: Label 'Prod. Order Routing Line is not updated.';
        TotalDurationExceedsAvailTimeErr: Label 'The sum of setup, move and wait time exceeds the available time in the period.';
        CancelReservationTxt: Label 'Cancel reservation';
        Direction: Option Forward,Backward;
        CalcMethod: Option "No Levels","One level","All levels";
        IncorrectValueErr: Label 'Incorrect value of %1.%2.';
        ExpectedQuantityErr: Label 'Expected Quantity is wrong.';
        ConfirmStatusFinishTxt: Label 'has not been finished. Some output is still missing. Do you still want to finish the order?';
        TimeShiftedOnParentLineMsg: Label 'The production starting date-time of the end item has been moved forward because a subassembly is taking longer than planned.';

    [Test]
    [Scope('OnPrem')]
    procedure FinishedQuantityOnProductionOrderLineWithoutTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Production Order] [Warehouse]
        // [SCENARIO] Verify Finished Quantity is correct after posting Output and finishing the Production Order on Location with Bins.

        // Setup: Update Components at a Location. Create parent and child Items in a Production BOM and certify it. Update Inventory for child Item. Create and refresh a Released Production Order.
        Initialize;
        UpdateManufacturingSetupComponentsAtLocation(LocationRed.Code);
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        Quantity := LibraryRandom.RandInt(100);  // Large Random Value required for Test.
        CreateItemsSetup(Item, Item2);
        CreateAndPostItemJournalLine(Item2."No.", Quantity, Bin.Code, LocationRed.Code, false);  // Using Tracking FALSE.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationRed.Code, Bin.Code);
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Create and post Consumption with Tracking FALSE.

        // Exercise: Create and post Output Journal for the Production Order. Change Status from Released to Finished.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);  // Use Tracking FALSE.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");  // Change Status from Released to Finished.

        // Verify: Verify the Finished Quantity after posting Output and finishing the Production Order.
        FindProductionOrderLine(ProdOrderLine, Item."No.");
        ProdOrderLine.TestField("Finished Quantity", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ReservationHandler')]
    [Scope('OnPrem')]
    procedure ReserveProdComponentAndPostOutputWithLotTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Setup: Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for Items with Tracking. Create and refresh a Released Production Order. Reserve Component.
        Initialize;
        UpdateManufacturingSetupComponentsAtLocation(LocationGreen.Code);
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetupWithProductionAndTracking(Item, Item2, ProductionOrder, Quantity, LocationGreen.Code);
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        ProdOrderComponent.ShowReservation;  // Invokes ReservationHandler.

        // Exercise: Create and post the Output Journal with Tracking.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, Quantity);

        // Verify: Verify the Item Ledger Entry for the Output posted with Tracking.
        VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, Item2."No.", Quantity, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ReservationHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderComponentReservationWithLotTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // Setup: Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for child Item with Tracking. Create and refresh a Released Production Order.
        Initialize;
        UpdateManufacturingSetupComponentsAtLocation(LocationGreen.Code);
        Quantity := LibraryRandom.RandInt(100);  // Large Random Value required for Test.
        CreateItemsSetupWithProductionAndTracking(Item, Item2, ProductionOrder, Quantity, LocationGreen.Code);

        // Exercise: Reserve Production Order Component.
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        ProdOrderComponent.ShowReservation;  // Invokes ReservationHandler.

        // Verify: Verify the Reserved Quantity on Production Order Component.
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status::Released, Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostConsumptionAndOutputWithLotTrackingAndFinishedProductionOrder()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO] Verify the Item Ledger Entry for Output and Tracking after finishing Production Order with tracked Items.

        // Setup: Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for child Item with Tracking. Create and refresh a Released Production Order.
        Initialize;
        UpdateManufacturingSetupComponentsAtLocation(LocationGreen.Code);
        Quantity := LibraryRandom.RandInt(100);  // Large Random Value required for Test.
        CreateItemsSetupWithProductionAndTracking(Item, Item2, ProductionOrder, Quantity, LocationGreen.Code);

        // Create and post Consumption and Output Journal with Tracking.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", true);  // Use Tracking TRUE.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, Quantity);  // Use Tracking TRUE.

        // Exercise: Change status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify that Production Order Status is successfully changed to Finished. Verify the Item Ledger Entry for Output and Tracking.
        VerifyProductionOrder(ProductionOrder, ProductionOrder.Status::Finished, ProductionOrder.Quantity, WorkDate);
        VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, Item2."No.", Quantity, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickWithHandlingErrorFromProductionOrderWithBin()
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Update Components at a Location. Create parent and child Items in a Production BOM and certify it. Update Inventory for Items. Create and refresh a Released Production Order.
        Initialize;
        UpdateManufacturingSetupComponentsAtLocation(LocationRed.Code);
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        CreateItemsSetup(Item, Item2);
        CreateAndPostItemJournalLine(Item2."No.", LibraryRandom.RandInt(100), Bin.Code, LocationRed.Code, false);  // Using Tracking FALSE.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), LocationRed.Code, Bin.Code);

        // Exercise: Create Pick from Released Production Order.
        asserterror LibraryWarehouse.CreateWhsePickFromProduction(ProductionOrder);

        // Verify: Verify that Pick is not created.
        Assert.ExpectedError(HandlingError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostConsumptionWithLocationAndBin()
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create parent and child Items in a Production BOM and certify it. Update Inventory for Child Item. Create and refresh a Released Production Order.
        Initialize;
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        CreateItemsSetup(Item, Item2);
        CreateAndPostItemJournalLine(Item2."No.", LibraryRandom.RandInt(100), Bin.Code, LocationRed.Code, false);  // Using Tracking FALSE.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), LocationRed.Code, Bin.Code);

        // Exercise: Create and post Consumption.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Using Tracking FALSE.

        // Verify: Verify the posted Consumption.
        VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Consumption, Item2."No.", -ProductionOrder.Quantity, false);  // Use Tracking FALSE.
    end;

    [Test]
    [HandlerFunctions('ReservationHandler')]
    [Scope('OnPrem')]
    procedure ReservationOnPlannedProductionOrderComponent()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProdOrderComponent: Record "Prod. Order Component";
        Quantity: Decimal;
    begin
        // Setup: Create parent and child Items, create Production BOM. Create and release Purchase Order and post as Receive and Invoice. Create a Planned Production Order.
        Initialize;
        CreateItemsSetup(Item, Item2);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, Item2."No.", Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Planned, Item."No.", Quantity, '', '');

        // Exercise: Reserve Components on Planned Production Order.
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        ProdOrderComponent.ShowReservation;  // Invokes ReservationHandler.

        // Verify: Verify that Quantity is not reserved.
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status::Planned, Item2."No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FirmPlannedProductionOrderWithLocation()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Setup: Create parent and child Items and update Inventory for child Item. Create Production BOM and certify it.
        Initialize;
        CreateItemsSetup(Item, Item2);

        // Exercise: Create and refresh Firm Planned Production Order.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Item2."No.", LibraryRandom.RandDec(100, 2), LocationGreen.Code, '');

        // Verify: Verify that Firm Planned Production Order Line is updated with correct Location Code and correct Quantity.
        FindProductionOrderLine(ProdOrderLine, Item2."No.");
        ProdOrderLine.TestField("Location Code", LocationGreen.Code);
        ProdOrderLine.TestField(Quantity, ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickFromProductionOrderWithLotTracking()
    begin
        // Verify the Inventory Pick is created from Released Production Order with Lot Tracking and Bins.
        // Setup.
        Initialize;
        WarehouseActivityFromProductionOrderWithLotTracking(false);  // Post Inventory Pick FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedPartialInventoryPickFromProductionOrderWithLotTracking()
    begin
        // Verify that Inventory Pick is posted successfully from Released Production Order with Lot Tracking, Partial quantity and Bins.
        // Setup.
        Initialize;
        WarehouseActivityFromProductionOrderWithLotTracking(true);  // Post Inventory Pick TRUE.
    end;

    local procedure WarehouseActivityFromProductionOrderWithLotTracking(PostInventoryPick: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for child Item with Tracking. Create and refresh a Released Production Order.
        UpdateManufacturingSetupComponentsAtLocation(LocationYellow.Code);
        LibraryWarehouse.FindBin(Bin, LocationYellow.Code, '', 1);  // Find Bin of Index 1.
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemSetupWithLotTracking(Item, Item2);
        CreateAndPostItemJournalLine(Item."No.", Quantity, Bin.Code, LocationYellow.Code, true);  // Using Tracking TRUE.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item2."No.", Quantity, LocationYellow.Code, Bin.Code);

        // Exercise: Create Inventory Pick from the Released Production Order.
        LibraryVariableStorage.Enqueue(PickActivitiesCreated);  // Enqueue variable required inside MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);
        if PostInventoryPick then begin
            // Auto fill Quantity To Handle for whole Quantity. Update Lot No and partial quantity on Whse Activity Line and post Inventory Pick.
            WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
            UpdateQuantityAndLotNoOnWarehouseActivityLine(
              Item."No.", ProductionOrder."No.", WarehouseActivityLine."Action Type"::Take, Quantity / 2);
            FindWarehouseActivityHeader(
              WarehouseActivityHeader, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption",
              WarehouseActivityLine."Action Type"::Take);
            LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);  // Post as Invoice False.
        end;

        if PostInventoryPick then
            // Verify: Verify that Inventory Pick posted successfully with partial Quantity and Lot Tracking.
            VerifyPostedInventoryPickLine(ProductionOrder."No.", Item."No.", Bin.Code, Quantity / 2, LocationYellow.Code)
        else
            // Verify that Inventory Pick created successfully.
            VerifyWarehouseActivityLine(
            ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", Item."No.", Quantity,
            WarehouseActivityLine."Action Type"::Take);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanFirmPlannedProductionOrderWithRouting()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Setup: Create parent and child Items, create Production BOM. Create Routing Setup and update Routing on Item. Create and refresh a Firm Planned Production Order.
        Initialize;
        CreateItemsSetup(Item, Item2);
        CreateRoutingAndUpdateItem(Item);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Exercise: Replan Production Order.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // Verify: Verify the Input Quantity remains same on Replan Production Order.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderRoutingLine.TestField("Input Quantity", ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationHandler')]
    [Scope('OnPrem')]
    procedure PartialAutoReservationOnSalesOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Update Inventory for the Item.
        Initialize;
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", Quantity, '', '', false);  // Using Tracking FALSE.

        // Exercise: Create and release a Sales Order with partial reservation.
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item."No.", Quantity / 2, '');  // Partial Auto Reservation.

        // Verify: Verify the Quantity reserved on Sales Line.
        VerifyReservationQtyOnSalesLine(SalesHeader."No.", Quantity / 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterWarehousePickFromProductionOrderWithComponent()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        Quantity: Decimal;
        AlwaysCreatePickLine: Boolean;
    begin
        // Setup: Update Location Setup, update Components at Location. Create parent and child Items in a Production BOM and certify it. Update Inventory for Child Item. Create and refresh a Released Production Order.
        // Create Warehouse Pick from the Released Production Order.
        Initialize;
        AlwaysCreatePickLine := UpdateLocationSetup(LocationWhite, true);  // Always Create Pick Line as TRUE.
        UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandInt(100);  // Integer value required.
        CreateItemsSetup(Item, Item2);
        UpdateInventoryWithWhseItemJournal(Item2, LocationWhite, Quantity);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationWhite.Code,
          LocationWhite."To-Production Bin Code");
        LibraryWarehouse.CreateWhsePickFromProduction(ProductionOrder);

        // Exercise: Update Bin on Warehouse Activity Line. Register the Pick created.
        UpdateBinCodeOnWarehouseActivityLine(ProductionOrder."No.");
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", WarehouseActivityLine."Action Type"::Take);

        // Verify: Verify that Pick is registered successfully.
        VerifyRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", Item2."No.", Quantity,
          RegisteredWhseActivityLine."Action Type"::Take);
        VerifyRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", Item2."No.", Quantity,
          RegisteredWhseActivityLine."Action Type"::Place);

        // Tear Down.
        UpdateLocationSetup(LocationWhite, AlwaysCreatePickLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostConsumptionWithProductionOrderAfterRegisterPick()
    begin
        // Verify the Item Ledger Entry for the consumption posted after register Warehouse Pick from Production Order.
        // Setup.
        Initialize;
        PostJournalsWithProductionOrder(false);  // Post Output -FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputWithProductionOrderWarehousePick()
    begin
        // Verify the Item Ledger Entry for the Output posted after register Warehouse Pick from Production Order.
        // Setup.
        Initialize;
        PostJournalsWithProductionOrder(true);  // Post Output -TRUE.
    end;

    local procedure PostJournalsWithProductionOrder(PostOutput: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        AlwaysCreatePickLine: Boolean;
    begin
        // Update Components at a Location. Create parent and child Items in a Production BOM and certify it. Update Inventory for child Item. Create and refresh a Released Production Order, create and register Pick from it.
        AlwaysCreatePickLine := UpdateLocationSetup(LocationWhite, true);  // Always Create Pick Line as TRUE.
        UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandInt(100);  // Integer value required.
        CreateItemsSetup(Item, Item2);
        UpdateInventoryWithWhseItemJournal(Item2, LocationWhite, Quantity);
        CreateAndRegisterPickWithProductionOrderSetup(ProductionOrder, LocationWhite, Item."No.", Quantity);

        // Exercise: Post Consumption for the Production Order.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Create and post Consumption with Tracking FALSE.

        if PostOutput then begin
            // Create and post Output Journal.
            CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);  // Use Tracking FALSE.

            // Verify: Verify the Item Ledger Entry for the Output and Consumption posted after register Warehouse Pick from Production Order.
            VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, Item."No.", Quantity, false);  // Use Tracking FALSE.
        end else
            VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Consumption, Item2."No.", -Quantity, false);  // Use Tracking FALSE.

        // Tear Down.
        UpdateLocationSetup(LocationWhite, AlwaysCreatePickLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustItemCostWithProductionOrderAndWarehouseActivity()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Production] [Warehouse]
        // [SCENARIO] Verify the Item Ledger Entry after Adjust Cost Item Entries is run with consumption posted with Production Order.

        // Setup.
        Initialize;
        ItemsWithProductionOrderAndWarehouseActivity(false);  // Calculate Inventory -FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryValueWithProductionOrderAndWarehouseActivity()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Revaluation] [Production] [Warehouse]
        // [SCENARIO] Verify the Revaluation Journal Line after Calculate Inventory is run with consumption and output posted with Production Order.

        // Setup.
        Initialize;
        ItemsWithProductionOrderAndWarehouseActivity(true);  // Calculate Inventory -TRUE.
    end;

    local procedure ItemsWithProductionOrderAndWarehouseActivity(InventoryValue: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        AlwaysCreatePickLine: Boolean;
    begin
        // Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for Items with Tracking. Create and refresh a Released Production order.
        AlwaysCreatePickLine := UpdateLocationSetup(LocationWhite, true);  // Always Create Pick Line as TRUE.
        UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandInt(100);  // Integer value required.
        CreateItemsSetup(Item, Item2);
        UpdateInventoryWithWhseItemJournal(Item2, LocationWhite, Quantity);
        CreateAndRegisterPickWithProductionOrderSetup(ProductionOrder, LocationWhite, Item."No.", Quantity);
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Use Tracking FALSE.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);  // Use Tracking FALSE.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Exercise: Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(Item2."No.", '');

        if InventoryValue then begin
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, RevaluationItemJournalTemplate.Name, RevaluationItemJournalBatch.Name, ItemJournalLine."Entry Type",
              Item2."No.", 0);
            CalculateInventoryValue(Item2);

            // Verify:
            VerifyRevaluationJournalLine(Item2."No.", Quantity);
        end else
            VerifyItemLedgerEntryCostAmountActual(
              ItemJournalLine."Entry Type"::"Positive Adjmt.", Item2."No.", Quantity * Item2."Unit Cost", LocationWhite.Code);

        // Tear Down.
        UpdateLocationSetup(LocationWhite, AlwaysCreatePickLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputPostFromReleasedProductionOrderWithLocation()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create parent and child Items in a Production BOM and certify it. Create and post Purchase Order as Receive and Invoice. Create and refresh a Released Production Order.
        Initialize;
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        CreateItemsSetup(Item, ChildItem);
        CreateAndPostPurchaseOrderWithLocationAndBin(PurchaseLine, ChildItem."No.", LocationRed.Code, Bin.Code);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", PurchaseLine.Quantity, LocationRed.Code, Bin.Code);

        // Exercise: Create and post Output Journal for the Production Order.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, PurchaseLine.Quantity);  // Use Tracking FALSE.

        // Verify: Verify the Location Code in Item Ledger Entry for the posted Output. Verify the Cost Amount Actual as Zero without Adjust Cost.
        VerifyItemLedgerEntryCostAmountActual(ItemJournalLine."Entry Type"::Output, Item."No.", 0, LocationRed.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryForConsumptionAfterAdjustCostWithProductionOrder()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Production] [Warehouse]
        // [SCENARIO] Verify Item Ledger Entry Cost Amount is correct after posting Consumption of Released Production Order (with Bins used) and run Adjust Cost.

        // Setup: Update Components at a Location. Create parent and child Items in a Production BOM and certify it. Create and post Purchase Order as Receive and Invoice. Create and refresh a Released Production Order.
        Initialize;
        UpdateManufacturingSetupComponentsAtLocation(LocationRed.Code);
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        CreateItemsSetup(Item, ChildItem);
        UpdateUnitCostOnItem(ChildItem);
        CreateAndPostPurchaseOrderWithLocationAndBin(PurchaseLine, ChildItem."No.", LocationRed.Code, Bin.Code);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", PurchaseLine.Quantity, LocationRed.Code, Bin.Code);
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Create and post Consumption with Tracking FALSE.

        // Exercise: Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify: Verify the Consumption Entry for the Child Item in Item Ledger Entry after Cost adjustment.
        VerifyItemLedgerEntryCostAmountActual(
          ItemJournalLine."Entry Type"::Consumption, ChildItem."No.", -PurchaseLine.Quantity * ChildItem."Unit Cost", LocationRed.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure FinishedProductionOrderForLessOutputWithLocationAndBin()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Production] [Warehouse]
        // [SCENARIO] Verify that Status can be changed to Finished for Released Production Order, when Output is posted (Order uses Location with Bins).

        // Setup: Create parent and child Items in a Production BOM and certify it. Create and post Item  Journal. Create and refresh a Released Production Order.
        Initialize;
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        CreateItemsSetup(Item, ChildItem);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandDec(100, 2), Bin.Code, LocationRed.Code, false);  // Use Tracking FALSE.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), LocationRed.Code, Bin.Code);

        // Create and post Output Journal for the Production Order.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, ProductionOrder.Quantity);  // Use Tracking FALSE.

        // Exercise: Change Production Order Status from Released to Finished.
        LibraryVariableStorage.Enqueue(FinishProductionOrder);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify the Status successfully changed to Finished.
        VerifyProductionOrder(ProductionOrder, ProductionOrder.Status::Finished, ProductionOrder.Quantity, WorkDate);
        ProductionOrder.TestField("Location Code", LocationRed.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputPostFromReleasedProductionOrderWithoutLocation()
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify the Output Quantity posted from Released Production Order without Location.

        // Setup.
        Initialize;
        JournalsPostFromReleasedProductionOrderWithoutLocation(false);  // Adjust Cost Item Entries FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryForOutputAfterAdjustCostWithReleasedProductionOrder()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Production]
        // [SCENARIO] Verify the Output Entry for the Parent Item in Item Ledger Entry after Cost adjustment from Released Production Order without Location.

        // Setup.
        Initialize;
        JournalsPostFromReleasedProductionOrderWithoutLocation(true);  // Adjust Cost Item Entries TRUE.
    end;

    local procedure JournalsPostFromReleasedProductionOrderWithoutLocation(AdjustCost: Boolean)
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Create parent and child Items in a Production BOM and certify it. Update Inventory for child Item. Create and refresh a Released Production Order.
        CreateItemsSetup(Item, ChildItem);
        UpdateUnitCostOnItem(ChildItem);
        Quantity := LibraryRandom.RandInt(100);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity, '', '', false);  // Use Tracking FALSE.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, '', '');
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Create and post Consumption with Tracking FALSE.

        // Exercise: Create and post Output Journal for the Production Order.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);  // Use Tracking FALSE.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");  // Change Status from Released to Finished.
        if AdjustCost then
            // Adjust Cost Item Entries.
            LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify: Verify the Output Entry for the Parent Item in Item Ledger Entry after Cost Adjustment. Verify the Output posted.
        if AdjustCost then
            VerifyItemLedgerEntryCostAmountActual(ItemJournalLine."Entry Type"::Output, Item."No.", Quantity * ChildItem."Unit Cost", '') // Cost for the Parent Item calculated from the Child Item.
        else
            VerifyItemLedgerEntryCostAmountActual(ItemJournalLine."Entry Type"::Output, Item."No.", 0, '');  // The Cost Amount Actual is zero without Adjust Cost.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumptionPostFromReleasedProductionOrderWithoutLocation()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create parent and child Items in a Production BOM and certify it. Update Inventory of Child Item. Create and refresh a Released Production Order.
        Initialize;
        CreateItemsSetup(Item, ChildItem);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandInt(100) + 100, '', '', false);  // Using Tracking FALSE. Large Quantity required for positive Inventory.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), '', '');

        // Exercise: Create and Post Consumption.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Use Tracking FALSE.

        // Verify: Verify the Item Ledger Entry for the Posted Consumption without Location.
        VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Consumption, ChildItem."No.", -ProductionOrder.Quantity, false);  // Use Tracking FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedProductionOrderWithFamily()
    var
        ParentItem: Record Item;
        ParentItem2: Record Item;
        ChildItem: Record Item;
        ChildItem2: Record Item;
        Family: Record Family;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        FamilyItemQuantity: Decimal;
    begin
        // Setup: Create parent and child Items for a Family. Update Inventory for child Items. Create a Family.
        Initialize;
        FamilyItemQuantity := LibraryRandom.RandDec(10, 2);
        CreateItemHierarchyForFamily(ParentItem, ParentItem2, ChildItem, ChildItem2);
        CreateFamily(Family, ParentItem."No.", ParentItem2."No.", FamilyItemQuantity);

        // Exercise: Create and refresh a Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithSourceTypeFamily(ProductionOrder, Family."No.", FamilyItemQuantity);

        // Verify: Verify the Production Order Lines.
        FindProductionOrderLine(ProdOrderLine, ParentItem."No.");
        ProdOrderLine.TestField(Quantity, FamilyItemQuantity * FamilyItemQuantity);  // Production Order Quantity calculated from Family Item Quantity.
        FindProductionOrderLine(ProdOrderLine, ParentItem2."No.");
        ProdOrderLine.TestField(Quantity, FamilyItemQuantity * FamilyItemQuantity);  // Production Order Quantity calculated from Family Item Quantity.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActualCostOnFinishedProductionOrderStatisticsPageForFamily()
    var
        ParentItem: Record Item;
        ParentItem2: Record Item;
        ChildItem: Record Item;
        ChildItem2: Record Item;
        Family: Record Family;
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
        FamilyItemQuantity: Decimal;
        ActualCost: Decimal;
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify that Cost Amount is correct on Finished Production Order which source is Family, and Consumption and Output is posted.

        // Setup: Create parent and child Items for a Family. Update Inventory for child Items. Create a Family. Create and refresh a Released Production Order.
        Initialize;
        Quantity := LibraryRandom.RandDec(100, 2) + 100;  // Large Quantity required for positive Inventory.
        FamilyItemQuantity := LibraryRandom.RandInt(10);
        CreateItemHierarchyForFamily(ParentItem, ParentItem2, ChildItem, ChildItem2);
        CreateFamily(Family, ParentItem."No.", ParentItem2."No.", FamilyItemQuantity);
        CreateAndRefreshReleasedProductionOrderWithSourceTypeFamily(ProductionOrder, Family."No.", FamilyItemQuantity);

        // Create and post Consumption and Output journals.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Using Tracking FALSE.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);  // Using Tracking FALSE.

        // Exercise: Change Production Order Status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify the correct Actual Cost Amount on Finished Production Order Statistics page.
        ActualCost := FamilyItemQuantity * (FamilyItemQuantity * ChildItem."Unit Cost" + FamilyItemQuantity * ChildItem2."Unit Cost");
        VerifyCostAmountActualOnFinishedProductionOrderStatisticsPage(ProductionOrder."No.", ActualCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostConsumptionForReleasedProductionOrderWithFamily()
    begin
        // Verify the correct Item Ledger entries for the Consumption posted for the Production Order using Items in a Family.
        // Setup.
        Initialize;
        PostConsumptionAndOutputForReleasedProductionOrderWithFamily(false);  // Post Output FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputForReleasedProductionOrderWithFamily()
    begin
        // Verify the correct Item Ledger entries for the Output posted for the Production Order using Items in a Family.
        // Setup.
        Initialize;
        PostConsumptionAndOutputForReleasedProductionOrderWithFamily(true);  // Post Output TRUE.
    end;

    local procedure PostConsumptionAndOutputForReleasedProductionOrderWithFamily(PostOutput: Boolean)
    var
        ParentItem: Record Item;
        ParentItem2: Record Item;
        ChildItem: Record Item;
        ChildItem2: Record Item;
        Family: Record Family;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        FamilyItemQuantity: Decimal;
    begin
        // Create parent and child Items for a Family. Update Inventory for child Items. Create a Family. Create and refresh a Released Production Order.
        Quantity := LibraryRandom.RandDec(100, 2) + 100;  // Large Quantity required for positive Inventory.
        FamilyItemQuantity := LibraryRandom.RandInt(10);
        CreateItemHierarchyForFamily(ParentItem, ParentItem2, ChildItem, ChildItem2);
        CreateFamily(Family, ParentItem."No.", ParentItem2."No.", FamilyItemQuantity);
        CreateAndRefreshReleasedProductionOrderWithSourceTypeFamily(ProductionOrder, Family."No.", FamilyItemQuantity);

        // Exercise: Create and post Consumption Journal for the Production Order.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Using Tracking FALSE.
        if PostOutput then
            // Create and post Output Journal for the Production Order.
            CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);  // Using Tracking FALSE.

        // Verify: Verify the Item Ledger Entries for the posted Output of Parent Items. Verify the Consumption Entries for the Posted Consumption.
        if PostOutput then begin
            VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, ParentItem."No.", Quantity, false);  // Using Tracking FALSE.
            VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, ParentItem2."No.", FamilyItemQuantity * FamilyItemQuantity, false);  // Using Tracking FALSE.
        end else begin
            VerifyItemLedgerEntry(
              ItemJournalLine."Entry Type"::Consumption, ChildItem."No.", -FamilyItemQuantity * FamilyItemQuantity, false);  // Using Tracking FALSE.
            VerifyItemLedgerEntry(
              ItemJournalLine."Entry Type"::Consumption, ChildItem2."No.", -FamilyItemQuantity * FamilyItemQuantity, false);  // Using Tracking FALSE.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingQuantityWithMultipleProductionOrderComponents()
    begin
        // Verify the total Remaining Quantity on Production Order Component with multiple Components.
        // Setup.
        Initialize;
        RemainingQuantityOnProductionOrderComponents(false);  // Delete Production Order Component FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingQuantityAfterDeleteProductionComponent()
    begin
        // Verify the total Remaining Quantity on Production Order Components is correct when deleting one Production Order Component.
        // Setup.
        Initialize;
        RemainingQuantityOnProductionOrderComponents(true);  // Delete Production Order Component TRUE.
    end;

    local procedure RemainingQuantityOnProductionOrderComponents(DeleteComponent: Boolean)
    var
        Item: Record Item;
        ChildItem: Record Item;
        ChildItem2: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Create parent and multiple child Items in a Production BOM and certify it. Update Inventory of Child Items. Create and refresh a Released Production Order.
        CreateProdBOMSetupMultipleComponents(Item, ChildItem, ChildItem2);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandInt(100), '', '', false);  // Using Tracking FALSE.
        CreateAndPostItemJournalLine(ChildItem2."No.", LibraryRandom.RandInt(100), '', '', false);  // Using Tracking FALSE.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), '', '');

        // Exercise: Calculate Consumption.
        LibraryManufacturing.CalculateConsumption(
          ProductionOrder."No.", ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        if DeleteComponent then begin
            // Delete First Production Order Compnent and Calculate Consumption.
            DeleteProductionOrderComponent(ProductionOrder."No.");
            LibraryManufacturing.CalculateConsumption(
              ProductionOrder."No.", ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        end;

        // Verify: Verify total Remaining Quantity on Production Order Component is reduced after deleting Component. Verify total Remaining Quantity on Production Order Component.
        if DeleteComponent then
            VerifyRemainingQuantityOnProdOrderComponents(
              ProductionOrder."No.", ProductionOrder.Status::Released, ChildItem2."No.", ProductionOrder.Quantity)
        else
            VerifyRemainingQuantityOnProdOrderComponents(
              ProductionOrder."No.", ProductionOrder.Status::Released, ChildItem."No.", ProductionOrder.Quantity + ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingOnAllocatedCapacityForFirmPlannedProductionOrder()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
    begin
        // Setup: Create parent and child Items, create Production BOM. Create Routing Setup and update Routing on Item.
        Initialize;
        CreateItemsSetup(Item, Item2);
        CreateRoutingAndUpdateItem(Item);

        // Exercise: Create and refresh a Firm Planned Production Order.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Verify: Verify the Routing and Work Center on Production Order Allocated Capacity.
        VerifyRoutingOnAllocatedCapacity(ProductionOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingOnAllocatedCapacityForFirmPlannedProductionOrderAfterCalcPlanAndCarryOut()
    var
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Item2: Record Item;
    begin
        // Setup: Create parent and child Items, create Production BOM. Update Planning parameters on Item. Create Routing Setup and update Routing on Item. Create and release Sales Order.
        Initialize;
        CreateItemsSetup(Item, Item2);
        UpdateItemParametersForPlanning(Item);
        CreateRoutingAndUpdateItem(Item);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandDec(100, 2));

        // Calculate Regenerative Plan on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // Exercise: Accept and Carry Out Action Message.
        AcceptAndCarryOutActionMessage(Item."No.");

        // Verify: Verify the Routing and Work Center on Production Order Allocated Capacity.
        FilterFirmPlannedProductionOrder(ProductionOrder, Item."No.");
        VerifyRoutingOnAllocatedCapacity(ProductionOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendAheadQuantityForFirmPlannedProdOrderAfterCalcPlanAndCarryOut()
    var
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Item2: Record Item;
        SendAheadQuantity: Decimal;
    begin
        // Setup: Create parent and child Items, create Production BOM. Update Planning parameters on Item. Create Routing Setup and update Routing on Item. Update Send Ahead Quantity on Routing Line. Create and release a Sales Order.
        Initialize;
        CreateItemsSetup(Item, Item2);
        UpdateItemParametersForPlanning(Item);
        CreateRoutingAndUpdateItem(Item);
        SendAheadQuantity := LibraryRandom.RandDec(100, 2);
        UpdateRoutingLineSendAheadQty(Item."Routing No.", SendAheadQuantity);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandDec(100, 2));

        // Calculate Regenerative Plan on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // Exercise: Accept and Carry Out Action Message.
        AcceptAndCarryOutActionMessage(Item."No.");

        // Verify: Verify the Send Ahead Quantity and Routing on Production Order Routing Line.
        FilterFirmPlannedProductionOrder(ProductionOrder, Item."No.");
        VerifyProductionOrderRoutingLine(ProductionOrder."No.", Item."Routing No.", SendAheadQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendAheadQuantityForFirmPlannedProductionOrderWithRouting()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        SendAheadQuantity: Decimal;
    begin
        // Setup: Create parent and child Items, create Production BOM. Create Routing Setup and update Routing on Item. Update Send Ahead Quantity on Routing Line.
        Initialize;
        CreateItemsSetup(Item, Item2);
        CreateRoutingAndUpdateItem(Item);
        SendAheadQuantity := LibraryRandom.RandDec(100, 2);
        UpdateRoutingLineSendAheadQty(Item."Routing No.", SendAheadQuantity);

        // Exercise: Create and refresh a Firm Planned Production Order.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Verify: Verify the Send Ahead Quantity and Routing on Production Order Routing Line.
        VerifyProductionOrderRoutingLine(ProductionOrder."No.", Item."Routing No.", SendAheadQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingDateOnRoutingAfterProdOrderRefreshSchedulingBack()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Setup: Create parent and child Items, create Production BOM. Create Routing Setup and update Routing on Item. Create a Firm Planned Production Order.
        Initialize;
        CreateItemsSetup(Item, Item2);
        CreateRoutingAndUpdateItem(Item);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandDec(100, 2) + 100);  // Large Quantity required.

        // Exercise: Refresh Firm Planned Production Order with Scheduling Direction Back.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify that the Starting Date is less than or equal to the Due Date on Production Order Routing Line.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        Assert.IsTrue(ProdOrderRoutingLine."Starting Date" <= ProductionOrder."Due Date", StartingDateMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EndingDateOnRoutingAfterProdOrderRefreshSchedulingForward()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Setup: Create parent and child Items, create Production BOM. Create Routing Setup and update Routing on Item. Create a Firm Planned Production Order.
        Initialize;
        CreateItemsSetup(Item, Item2);
        CreateRoutingAndUpdateItem(Item);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandDec(100, 2) + 1000);  // Large Quantity required.

        // Exercise: Refresh Firm Planned Production Order with Scheduling Direction Forward.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);

        // Verify: Verify that the Ending Date is greater than or equal to the Due Date on Production Order Routing Line.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        Assert.IsTrue(ProdOrderRoutingLine."Ending Date" >= ProductionOrder."Due Date", EndingDateMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRoutingLineAfterCalculateRegenPlan()
    begin
        // Verify that the Input Quantity on Planning Routing Line is same as Quantity on Requisition Line.
        // Setup.
        Initialize;
        PlanningRoutingLineAfterCalculatePlan(false);  // Update Quantity on Requisition Line FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRoutingLineWithUpdatedReqLineAfterCalculateRegenPlan()
    begin
        // Verify that the Input Quantity on Planning Routing Line is same as Quantity on Requisition Line after update Quantity on Requisition Line and refresh it.
        // Setup.
        Initialize;
        PlanningRoutingLineAfterCalculatePlan(true);  // Update Quantity on Requisition Line TRUE.
    end;

    local procedure PlanningRoutingLineAfterCalculatePlan(UpdateRequisitionLine: Boolean)
    var
        Item: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
    begin
        // Create Parent and Child Items in a Production BOM with Routing. Update Planning parameters on Item. Create and release Sales Order.
        CreateItemsSetup(Item, ChildItem);
        UpdateItemParametersForPlanning(Item);
        CreateRoutingAndUpdateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity);

        // Exercise: Calculate Regenerative Plan on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);
        FindRequisitionLine(RequisitionLine, Item."No.");
        if UpdateRequisitionLine then begin
            // Update Quantity On Requisition Line and refresh the Planning Line.
            UpdateQuantityOnRequisitionLine(RequisitionLine, 2 * Quantity);  // Change Quantity on Requisition Line.
            LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Backward, true, true);
        end;

        // Verify: Verify the Input Quantity on Planning Routing Line is same as the Quantity on Requisition Line.
        VerifyInputQuantityOnPlanningRoutingLine(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingLineFirmPlannedProdOrderAfterCalcRegenPlanAndCarryOut()
    var
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        ChildItem: Record Item;
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Quantity: Decimal;
    begin
        // Setup: Create Parent and Child Items in a Production BOM with Routing. Update Planning parameters on Item. Create and release Sales Order.
        Initialize;
        CreateItemsSetup(Item, ChildItem);
        UpdateItemParametersForPlanning(Item);
        CreateRoutingAndUpdateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity);

        // Calculate Regenerative Plan on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // Exercise: Accept and Carry Out Action Message.
        AcceptAndCarryOutActionMessage(Item."No.");

        // Verify: Verify the Production Order Quantity and Input Quantity on Prod Order Routing Line is same as Initial Sales Order Quantity.
        FilterFirmPlannedProductionOrder(ProductionOrder, Item."No.");
        ProductionOrder.TestField(Quantity, Quantity);
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderRoutingLine.TestField("Input Quantity", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservationEntryAfterCalculateRegenPlan()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Update Planning Parameters for Item. Create and release a Sales Order.
        Initialize;
        CreateLotForLotItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity);

        // Exercise: Calculate Regenerative Plan on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // Verify: Verify Reservation Entry for the Item after Calculate Plan.
        VerifyReservationEntry(Item."No.", Quantity, ReservationEntry."Reservation Status"::Tracking, false, true);  // Positive Reservation Entry TRUE.
        VerifyReservationEntry(Item."No.", -Quantity, ReservationEntry."Reservation Status"::Tracking, false, false);  // Positive Reservation Entry FALSE.
    end;

    [Test]
    [HandlerFunctions('ReservationHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryForProdOrderReservationAfterCalculatePlanAndCarryOutAction()
    var
        Item: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Update Planning Parameters for Item. Create and release a Sales Order.
        Initialize;
        CreateLotForLotItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateDemandForCalculatePlanAndCarryOutAction(Item."No.", Quantity);

        // Exercise: Reserve Production Order Line created.
        FindProductionOrderLine(ProdOrderLine, Item."No.");
        ProdOrderLine.ShowReservation;  // Invokes ReservationHandler.

        // Verify: Verify the Reservation Entry after Reservation On Production Order Line.
        VerifyReservationEntry(Item."No.", Quantity, ReservationEntry."Reservation Status"::Reservation, false, true);  // Positive Reservation Entry TRUE.
        VerifyReservationEntry(Item."No.", -Quantity, ReservationEntry."Reservation Status"::Reservation, false, false);  // Positive Reservation Entry FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryAfterAssignTrackingOnProdOrderWithCalculatePlanAndCarryOutAction()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
    begin
        // Setup: Create Parent and Child Items in a Production BOM with Lot Tracking. Update Planning parameters on Parent Item. Create and release a Sales Order.
        Initialize;
        CreateItemSetupWithLotTracking(ChildItem, Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateItemParametersForPlanning(Item);
        CreateDemandForCalculatePlanAndCarryOutAction(Item."No.", Quantity);

        // Exercise: Assign Lot Tracking on Production Order created.
        FindProductionOrderLine(ProdOrderLine, Item."No.");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Assign Lot No.
        ProdOrderLine.OpenItemTrackingLines;  // Invokes ItemTrackingPageHandler.

        // Verify: Verify the Reservation Entry after assign Lot Tracking on Production Order Line.
        VerifyReservationEntry(Item."No.", Quantity, ReservationEntry."Reservation Status"::Tracking, true, true);  // Positive Reservation Entry and Tracking TRUE.
        VerifyReservationEntry(Item."No.", -Quantity, ReservationEntry."Reservation Status"::Tracking, false, false);  // Positive Reservation Entry and Tracking FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingLineAfterRoutingLinkCodeUpdateOnRoutingLine()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RoutingLinkCode: Code[20];
    begin
        // Setup: Create Parent and Child Items. Create Certified Production BOM with Routing Link Code for Child Items. Create Production Item with Routing.
        Initialize;
        CreateItemsSetup(Item, ChildItem);
        RoutingLinkCode := CreateRoutingAndUpdateItem(Item);

        // Exercise: Create and Refresh a Released Production Order.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Verify: Verify the Production Order Routing Line is populated with Routing Link Code from Routing Line.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderRoutingLine.TestField("Routing Link Code", RoutingLinkCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeOutputPostedForProductionOrderWithMultipleComponents()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create parent and child Items in a Production BOM with Routing and certify it. Create and refresh a Released Production Order.
        Initialize;
        CreateItemsSetup(Item, ChildItem);
        CreateRoutingAndUpdateItem(Item);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Exercise: Create and post negative Output for the Production Order.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, -ProductionOrder.Quantity);  // Use Tracking FALSE.

        // Verify: Verify the negative Output Entry for the posted Output in Item Ledger Entry.
        VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, Item."No.", -ProductionOrder.Quantity, false);  // Using Tracking FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservationEntryForPickAndReleasedProductionOrderAfterCalculatePlanAndCarryOutAction()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
        ProductionOrderNo: Code[20];
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO] Verify that tracking Reservation Entries are there and correct after Warehouse Pick created from Released Production Order, which is a supply to demanded Sales Order, respectively planned and carried out.

        // Setup: Update Components at Location. Create Parent and Child Items in a Production BOM and certify it. Update Item Planning Parameters. Update Inventory for Child Item. Create and release a Sales Order. Calculate Plan and Carry Out Action.
        Initialize;
        UpdateManufacturingSetupComponentsAtLocation(LocationGreen2.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemsSetup(Item, ChildItem);
        UpdateItemParametersForPlanning(Item);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity, '', LocationGreen2.Code, false);  // Using Tracking FALSE.
        CreateDemandForCalculatePlanAndCarryOutAction(Item."No.", Quantity);
        ProductionOrderNo := ChangeStatusFromFirmPlannedToReleased(Item."No.");  // Change Status from Firm Planned to Released.

        // Exercise: Create Pick from Production Order.
        CreatePickFromReleasedProductionOrder(ProductionOrderNo);

        // Verify: Verify the Reservation Entry after Create Pick from Production Order.
        VerifyReservationEntry(Item."No.", Quantity, ReservationEntry."Reservation Status"::Tracking, false, true);  // Positive Reservation Entry TRUE.
        VerifyReservationEntry(Item."No.", -Quantity, ReservationEntry."Reservation Status"::Tracking, false, false);  // Positive Reservation Entry FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseActivityLineForReleasedProductionOrderAfterCalculatePlanAndCarryOutAction()
    var
        Item: Record Item;
        ChildItem: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        ProductionOrderNo: Code[20];
    begin
        // [FEATURE] [Warehouse]
        // [SCENARIO] Verify the Pick is created successfully for the Child Item, when Production Order is a supply for Sales Order demand, respectively planned and carried out.

        // Setup: Update Components at Location. Create Parent and Child Items in a Production BOM and certify it. Update Item Planning Parameters. Update Inventory for Child Item. Create and release a Sales Order. Calculate Plan and Carry Out Action.
        Initialize;
        UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateLotForLotItemSetupWithInventoryOnLocation(Item, ChildItem, LocationWhite, Quantity);
        CreateDemandForCalculatePlanAndCarryOutAction(Item."No.", Quantity);
        ProductionOrderNo := ChangeStatusFromFirmPlannedToReleased(Item."No.");  // Change Production Order Status from Firm Planned to Released.

        // Exercise: Create Pick from Production Order.
        CreatePickFromReleasedProductionOrder(ProductionOrderNo);

        // Verify: Verify the Pick is created successfully for the Child Item.
        VerifyWarehouseActivityLine(
          ProductionOrderNo, WarehouseActivityLine."Source Document"::"Prod. Consumption", ChildItem."No.", Quantity,
          WarehouseActivityLine."Action Type"::Take);
        VerifyWarehouseActivityLine(
          ProductionOrderNo, WarehouseActivityLine."Source Document"::"Prod. Consumption", ChildItem."No.", Quantity,
          WarehouseActivityLine."Action Type"::Place);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPickFromReleasedProductionOrderAfterCalculatePlanAndCarryOutAction()
    var
        Item: Record Item;
        ChildItem: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        Quantity: Decimal;
        ProductionOrderNo: Code[20];
    begin
        // [FEATURE] [Warehouse]
        // [SCENARIO] Verify the Registered Pick for the Child Item, when: Production Order is a supply for Sales Order demand, respectively planned and carried out, then Pick created, then Bin Code updated, then Registered.

        // Stup: Update Components at Location. Create Parent and Child Items in a Production BOM and certify it. Update Item Planning Parameters. Update Inventory for Child Item. Create and release a Sales Order. Calculate Plan and Carry Out Action.
        Initialize;
        UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateLotForLotItemSetupWithInventoryOnLocation(Item, ChildItem, LocationWhite, Quantity);
        CreateDemandForCalculatePlanAndCarryOutAction(Item."No.", Quantity);
        ProductionOrderNo := ChangeStatusFromFirmPlannedToReleased(Item."No.");  // Change Production Order Status from Firm Planned to Released.
        CreatePickFromReleasedProductionOrder(ProductionOrderNo);  // Create Pick from Released Production Order.

        // Exercise: Update Bin on Warehouse Activity Line. Register the Pick created.
        UpdateBinCodeOnWarehouseActivityLine(ProductionOrderNo);
        RegisterWarehouseActivity(
          ProductionOrderNo, WarehouseActivityLine."Source Document"::"Prod. Consumption", WarehouseActivityLine."Action Type"::Take);

        // Verify: Verify the Registered Pick for the Child Item.
        VerifyRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrderNo, ChildItem."No.", Quantity,
          RegisteredWhseActivityLine."Action Type"::Take);
        VerifyRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrderNo, ChildItem."No.", Quantity,
          RegisteredWhseActivityLine."Action Type"::Place);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForPlannedProductionOrder()
    var
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        ChildItem: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Create Parent and Child Items in a Production BOM. Update Order Tracking Policy on Item. Create and release Sales Order.
        Initialize;
        CreateItemsSetup(Item, ChildItem);
        UpdateOrderTrackingPolicyOnItem(Item, Item."Order Tracking Policy"::"Tracking Only");
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity);

        // Exercise: Create and refresh a Planned Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Planned, Item."No.", Quantity, '', '');

        // Verify: Verify the ItemNo and Quantity on Order Tracking Page.
        VerifyOrderTrackingForProductionOrder(Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForFirmPlannedProductionOrderAfterCalculatePlanAndCarryOutAction()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Create Parent and Child Items in a Production BOM. Update Planning parameters on Item.
        Initialize;
        CreateItemsSetup(Item, ChildItem);
        UpdateOrderTrackingPolicyOnItem(Item, Item."Order Tracking Policy"::"Tracking & Action Msg.");
        UpdateItemParametersForPlanning(Item);
        Quantity := LibraryRandom.RandDec(100, 2);

        // Exercise: Create Demand, calculate Plan and Carry Out Action Message.
        CreateDemandForCalculatePlanAndCarryOutAction(Item."No.", Quantity);

        // Verify: Verify the ItemNo and Quantity on Order Tracking Page.
        VerifyOrderTrackingForProductionOrder(Item."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineAfterCalcPlanReqWkshWithLocationAndSKUMaximumQuantityItem()
    begin
        // Verify the Location, Action Message and Quantity on Requisition Line created.
        // Setup.
        Initialize;
        CalcPlanReqWkshWithLocationAndSKUMaximumQuantityItem(false);  // Accept and Carry Out Action FALSE.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLineAfterCalcPlanReqWkshWithLocationAndSKUMaximumQuantityItem()
    begin
        // Verify the Location Code and Quantity on Purchase Line created.
        // Setup.
        Initialize;
        CalcPlanReqWkshWithLocationAndSKUMaximumQuantityItem(true);  // Accept and Carry Out Action TRUE.
    end;

    local procedure CalcPlanReqWkshWithLocationAndSKUMaximumQuantityItem(AcceptAndCarryOutAction: Boolean)
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        RequisitionLine: Record "Requisition Line";
    begin
        // Create item with Reordering Policy. Create StockKeeping Unit for Location. Update Inventory for Item. Create and post Sales Order with Item Maximum Quantity.
        CreateMaximumQtyItem(Item, LibraryRandom.RandDec(100, 2) + 100);  // Large Quantity required for Item Maximum Inventory.
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationGreen.Code, Item."No.", '');
        CreateAndPostItemJournalLine(Item."No.", Item."Maximum Inventory", '', LocationGreen.Code, false);  // Using Tracking FALSE.
        CreateAndPostSalesOrderWithUpdatedQuantityToShip(
          Item, Item."Maximum Inventory" + LibraryRandom.RandDec(10, 2), LocationGreen.Code);  // Large Quantity required.

        // Exercise: Calculate Plan for Requisition Worksheet on WORKDATE. Accept and Carry Out Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);
        if AcceptAndCarryOutAction then
            AcceptAndCarryOutActionMessageForRequisitionWorksheet(Item."No.");

        // Verify: Verify the Location Code and Quantity on Purchase Line created.
        if AcceptAndCarryOutAction then
            VerifyLocationAndQuantityOnPurchaseLine(Item."No.", LocationGreen.Code, Item."Maximum Inventory")
        else
            // Verify the Location, Action Message and Quantity on Requisition Line created.
            VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::New, Item."Maximum Inventory", LocationGreen.Code);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionLineComponentItemAfterCalcRegenPlanOnPlanningWkshWithMRP()
    var
        Item: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine2: Record "Requisition Line";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        Quantity: Decimal;
    begin
        // Setup: Create Lot for Lot Items in a Production BOM and certify it. Update Inventory for the Parent Item. Create and post Sales Order.
        Initialize;
        CreateLotForLotItemsSetup(Item, ChildItem);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostItemJournalLine(Item."No.", Quantity, '', '', false);  // Using Tracking FALSE.
        CreateSalesOrder(SalesHeader, SalesLine, ChildItem."No.", Quantity, '');
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship only.

        // Exercise: Calculate Regenerative Plan with MRP - TRUE for Planning Worksheet through CalculatePlanPlanWkshRequestPageHandler.
        CalcRegenPlanForPlanningWorksheetPage(PlanningWorksheet, ChildItem."No.", ChildItem."No.", false);

        // Verify: Verify the Action Message and Quantity on Requisition Line for Child Item. Verify that Requisition Line is not created for Parent Item.
        VerifyRequisitionLine(ChildItem."No.", RequisitionLine."Action Message"::New, Quantity, '');
        FilterRequisitionLine(RequisitionLine2, Item."No.");
        Assert.IsTrue(RequisitionLine2.IsEmpty, StrSubstNo(RequisitionLineMustNotExist, Item."No."));
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler,CarryOutActionMessageHandler')]
    [Scope('OnPrem')]
    procedure FirmPlannedProductionOrderWithParentAndChild()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // Setup: Create Parent and Child Items. Create Sales Order for Parent Item.
        Initialize;
        CreateBomItemsWithReorderingPolicy(ParentItem, ChildItem);
        CreateSalesOrder(SalesHeader, SalesLine, ParentItem."No.", LibraryRandom.RandInt(10), '');

        // Exercise: Carry Out Planning Worksheet as Firm Planned Production Order.
        CalcRegenPlanForPlanningWorksheetPage(PlanningWorksheet, ParentItem."No.", ChildItem."No.", true);

        // Verify Parent and Child items are carried out into one Firm Planned Production Order.
        FilterFirmPlannedProductionOrder(ProductionOrder, ParentItem."No.");
        FindProductionOrderLine(ProdOrderLine, ChildItem."No.");
        ProductionOrder.TestField("No.", ProdOrderLine."Prod. Order No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure FinishProdOrderWithExistingItemTrackingEntry()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify that Production order can be finished with existing item tracking entries.

        // Setup: Create Item with Lot Tracking No. Create and refresh Releashed Production Order, assign Item Tracking on Prod. Order Line.
        Initialize;
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCode);
        CreateRleasedProdOrderWithItemTracking(ProductionOrder, Item."No.", ItemTrackingMode::"Assign Lot No.");

        // Create Output Journal for Production Order and reduce the quantity on Journal Line.
        CreateAndPostOutputJnlWithUpdateQtyAndItemTracking(ProductionOrder."No.", ProductionOrder.Quantity / 2); // 2 is not important, just to get a partial quantity

        // Exercise: Change Production Order Status from Released to Finished.
        // Verify: No error pops up.
        LibraryVariableStorage.Enqueue(FinishProductionOrder); // Enqueue for Confirm Handler
        LibraryVariableStorage.Enqueue(DeleteItemTrackingQst); // Enqueue for Confirm Handler
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify the Quantity and Finished Quantity on Finished Production Order Line.
        VerifyProdOrderLine(
          Item."No.", ProductionOrder.Status::Finished, ProductionOrder.Quantity, ProductionOrder.Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdOrderWithItemTrackingForBackwardFlushingComp()
    var
        Item: Record Item;
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify that Production order can be finished with component item tracking entries when Flushing Method = Backward.

        // Setup: Create parent and child Item in a Production BOM and certify it. Update Inventory for child Item.
        // Create and refresh a Released Production Order, update Flushing Method on Prod. Order Component
        Initialize;
        CreateItemsSetupWithProductionAndTracking(Item, ParentItem, ProductionOrder, LibraryRandom.RandInt(100), '');
        UpdateFlushingMethodOnProdComp(ProductionOrder."No.", Item."Flushing Method"::Backward);

        // Open Components and add an existing Item Tracking.
        SelectItemTrackingForProdOrderComponents(Item."No.");

        // Create and post the Output Journal.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, ProductionOrder.Quantity); // Tracking = TRUE

        // Exercise: Change the Production Order Status to Finished
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify change status successfully. The Finished Quantity is correct and finishing the Production Order.
        VerifyProdOrderLine(
          ParentItem."No.", ProductionOrder.Status::Finished, ProductionOrder.Quantity, ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IncreaseDurationOfOperationsInManuallyScheduledProdOrderRoutingLine()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        NewSetupTime: Decimal;
    begin
        // [SCENARIO 379761] An error should occur when total duration of setup-wait-move operations exceeds the period between Starting and Ending Dates in Prod. Order Routing Line with "Schedule Manually" flag on.
        Initialize;

        // [GIVEN] Released Production Order.
        // [GIVEN] "Schedule Manually" flag is set to TRUE in Prod. Order Routing Line "L".
        CreateReleasedProdOrderWithManuallyScheduledRoutingLine(ProdOrderRoutingLine);

        // [WHEN] Increase Setup Time in "L".
        NewSetupTime := ProdOrderRoutingLine."Setup Time" + LibraryRandom.RandInt(5);
        asserterror UpdateSetupTimeInProdOrderRoutingLine(ProdOrderRoutingLine, NewSetupTime);

        // [THEN] Error message of exceeding duration of operations is shown.
        Assert.ExpectedError(TotalDurationExceedsAvailTimeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotChangeDurationOfOperationsInManuallyScheduledProdOrderRoutingLine()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        NewSetupTime: Decimal;
    begin
        // [SCENARIO 379761] Leaving total duration of setup-wait-move operations unchanged within the period between Starting and Ending Dates should not cause errors in Prod. Order Routing Line with "Schedule Manually" flag on.
        Initialize;

        // [GIVEN] Released Production Order.
        // [GIVEN] "Schedule Manually" flag is set to TRUE in Prod. Order Routing Line "L".
        CreateReleasedProdOrderWithManuallyScheduledRoutingLine(ProdOrderRoutingLine);

        // [WHEN] Setup Time in "L" is revalidated with the same value.
        NewSetupTime := ProdOrderRoutingLine."Setup Time";
        UpdateSetupTimeInProdOrderRoutingLine(ProdOrderRoutingLine, NewSetupTime);

        // [THEN] Validation causes no error. Setup Time in "L" is left unchanged.
        Assert.AreEqual(NewSetupTime, ProdOrderRoutingLine."Setup Time", ProdOrderRtngLineNotUpdatedMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanTwoLevelProdOrderWithChildLineReservedToParentLineComponent()
    var
        ProductionOrder: Record "Production Order";
        ItemNo: array[5] of Code[20];
        ReducedQty: Decimal;
    begin
        // [FEATURE] [Make-to-Order] [Replan Production Order]
        // [SCENARIO 381078] Reducing quantity on a parent line in two level Production Order reduces quantity on a child line. It also reduces the quantity of the component to be produced in other Production Order.
        Initialize;

        // [GIVEN] Production chain - a purchased component and three levels of manufacturing items "I1", "I2", "I3". "I3" is the highest level.
        // [GIVEN] Items "I2" and "I3" have Make-to-Order manufacturing policy.
        CreateProductionChainOfItems(ItemNo, 3);

        // [GIVEN] Firm planned two level Production Order "PO" for items "I3" and "I2". Quantity = "Q".
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ItemNo[3], LibraryRandom.RandIntInRange(11, 20), '', '');

        // [GIVEN] Replan procedure is run for "PO".
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [GIVEN] Quantity on Prod. Order Line for "I3" is reduced to "q".
        ReducedQty := LibraryRandom.RandInt(10);
        UpdateQuantityOnProdOrderLine(ItemNo[3], ReducedQty);

        // [WHEN] Replan the Production Order "PO" for all levels of manufacturing.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [THEN] Quantity on Prod. Order Line for "I2" is reduced to "q".
        VerifyOneProdOrderLine(ItemNo[2], ReducedQty);

        // [THEN] Production Order for "I1" created by the replanning of "PO", has one line with reduced quantity "q".
        VerifyOneProdOrderLine(ItemNo[1], ReducedQty);
    end;

    [Test]
    [HandlerFunctions('ReservationEntriesModalPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ReplanTwoLevelProdOrderWithChildLineNotReserved()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemNo: array[5] of Code[20];
        ReducedQty: Decimal;
    begin
        // [FEATURE] [Make-to-Order] [Replan Production Order]
        // [SCENARIO 381078] Reducing quantity on a parent line in two level Production Order with removed binding between the lines, reduces quantity on a child line. It also reduces the quantity of the component to be produced in other Production Order.
        Initialize;

        // [GIVEN] Production chain - a purchased component and three levels of manufacturing items "I1", "I2", "I3". "I3" is the highest level.
        // [GIVEN] Items "I2" and "I3" have Make-to-Order manufacturing policy.
        CreateProductionChainOfItems(ItemNo, 3);

        // [GIVEN] Firm planned two level Production Order "PO" for items "I3" and "I2". Quantity = "Q".
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ItemNo[3], LibraryRandom.RandIntInRange(11, 20), '', '');

        // [GIVEN] Replan procedure is run for "PO".
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [GIVEN] Reservation of Prod. Order Line for "I2" is canceled.
        FindProductionOrderLine(ProdOrderLine, ItemNo[2]);
        ProdOrderLine.ShowReservationEntries(true);

        // [GIVEN] Quantity on Prod. Order Line for "I3" is reduced to "q".
        ReducedQty := LibraryRandom.RandInt(10);
        UpdateQuantityOnProdOrderLine(ItemNo[3], ReducedQty);

        // [WHEN] Replan the Production Order "PO" for all levels of manufacturing.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [THEN] Quantity on Prod. Order Line for "I2" is reduced to "q".
        VerifyOneProdOrderLine(ItemNo[2], ReducedQty);

        // [THEN] Production Order for "I1" created by the replanning of "PO", has one line with reduced quantity "q".
        VerifyOneProdOrderLine(ItemNo[1], ReducedQty);
    end;

    [Test]
    [HandlerFunctions('ReservationEntriesModalPageHandler,ReservationHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ReplanTwoLevelProdOrderWithChildLineReservedForExternalDemand()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: array[5] of Code[20];
        ProductionQty: Decimal;
        SalesQty: Decimal;
    begin
        // [FEATURE] [Make-to-Order] [Replan Production Order]
        // [SCENARIO 381078] When child line in two level Production Order is reserved to Sales Order, replanning of the Production Order increases the quantity of the child line to supply the parent line and the Sales Order.
        Initialize;

        // [GIVEN] Production chain - a purchased component and three levels of manufacturing items "I1", "I2", "I3". "I3" is the highest level.
        // [GIVEN] Items "I2" and "I3" have Make-to-Order manufacturing policy.
        CreateProductionChainOfItems(ItemNo, 3);

        // [GIVEN] Firm planned two level Production Order "PO" for items "I3" and "I2". Quantity = "Q".
        ProductionQty := LibraryRandom.RandIntInRange(11, 20);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ItemNo[3], ProductionQty, '', '');

        // [GIVEN] Replan procedure is run for "PO".
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [GIVEN] Reservation of Prod. Order Line for "I2" is canceled.
        FindProductionOrderLine(ProdOrderLine, ItemNo[2]);
        ProdOrderLine.ShowReservationEntries(true);

        // [GIVEN] Quantity "q" is reserved from Prod. Order Line for "I2" by a Sales Line.
        SalesQty := LibraryRandom.RandInt(10);
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo[2], SalesQty, '');
        SalesLine.ShowReservation;

        // [WHEN] Replan the Production Order "PO" for all levels of manufacturing.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [THEN] Quantity of production of "I2" is equal to "Q" + "q".
        VerifyOneProdOrderLine(ItemNo[2], ProductionQty + SalesQty);

        // [THEN] Production Order for "I1" created by the replanning of "PO", has one line with quantity = "Q" + "q".
        VerifyOneProdOrderLine(ItemNo[1], ProductionQty + SalesQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentPlanningLevelDecreasedWhenSupplyProdOrderLineDeleted()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemNo: array[5] of Code[20];
    begin
        // [FEATURE] [Make-to-Order]
        // [SCENARIO 210802] Planning Level Code on prod. order component should be decreased if prod. order line that supplies this component is deleted.
        Initialize;

        // [GIVEN] BOM structure of 4 items "I1".."I4" created with "Make-to-Order" manufacturing policy.
        // [GIVEN] "I1" is a component of "I2", "I2" is a component of "I3", "I3" is a component of "I4".
        CreateProductionChainOfItems(ItemNo, 4);

        // [GIVEN] Released production order for "I4".
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ItemNo[4], LibraryRandom.RandInt(10), '', '');

        // [WHEN] Delete the lowest level prod. order line (with Item No. = "I2" and Planning Level Code = 2).
        FindProductionOrderLine(ProdOrderLine, ItemNo[2]);
        ProdOrderLine.Delete(true);

        // [THEN] Item "I2" in the list of prod. order components for "I3" has Planning Level Code = 1.
        FindProductionOrderLine(ProdOrderLine, ItemNo[3]);
        FindProdOrderComponentByItem(ProdOrderComponent, ProdOrderLine, ItemNo[2]);
        ProdOrderComponent.TestField("Planning Level Code", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanProdOrderWithAddedProdOrderCompRecalculatesMTOStructure()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemNo: array[3] of Code[20];
        NewItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Make-to-Order] [Replan Production Order]
        // [SCENARIO 230435] When you run Replan Production Order after adding prod. order component for the finished item, this component is inserted in the prod. order lines tree.
        Initialize;

        // [GIVEN] BOM structure of 3 items "I1".."I3" with Make-to-Order manufacturing policy.
        // [GIVEN] "I1" is a component of "I2", "I2" is a component of "I3".
        CreateProductionChainOfItems(ItemNo, 3);

        // [GIVEN] BOM structure of 2 items "J1".."J2". "J2" has a Make-to-Order manufacturing policy, "J1" is a component of "J2".
        CreateProductionChainOfItems(NewItemNo, 2);

        // [GIVEN] Released production order for "I3".
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ItemNo[3], LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Add "J2" to the list of prod. order components for "I3".
        FindProductionOrderLine(ProdOrderLine, ItemNo[3]);
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", NewItemNo[2]);
        ProdOrderComponent.Validate("Quantity per", 1);
        ProdOrderComponent.Modify(true);

        // [WHEN] Replan the production order for all levels of manufacturing.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [THEN] A new multi-level structure of the production order is as follows:
        // [THEN]   I3
        // [THEN]  /  \
        // [THEN] I2  J2
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        FindProductionOrderLine(ProdOrderLine, ItemNo[3]);
        ProdOrderLine.TestField("Planning Level Code", 0);

        FindProductionOrderLine(ProdOrderLine, ItemNo[2]);
        ProdOrderLine.TestField("Planning Level Code", 1);

        FindProductionOrderLine(ProdOrderLine, NewItemNo[2]);
        ProdOrderLine.TestField("Planning Level Code", 1);

        // [THEN] Planning Level Code of component "J2" is equal to 1.
        ProdOrderComponent.Find;
        ProdOrderComponent.TestField("Planning Level Code", 1);

        // [THEN] No additional production order is created for "J2".
        ProdOrderLine.SetFilter("Prod. Order No.", '<>%1', ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", NewItemNo[2]);
        Assert.RecordIsEmpty(ProdOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLinedProdOrderKeepsItsStructureAfterReplan()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemNo: array[5] of Code[20];
        BOMStructureDepth: Integer;
        i: Integer;
    begin
        // [FEATURE] [Make-to-Order] [Replan Production Order]
        // [SCENARIO 210802] A multi-level production order should keep its structure of prod. order lines after Replan Production Order function is carried out.
        Initialize;

        // [GIVEN] BOM structure of 4 items "I1".."I4" created with "Make-to-Order" manufacturing policy.
        // [GIVEN] "I1" is a component of "I2", "I2" is a component of "I3", "I3" is a component of "I4".
        BOMStructureDepth := 4;
        CreateProductionChainOfItems(ItemNo, BOMStructureDepth);

        // [GIVEN] Released production order for "I4". It has 3-level structure with "I4" at the highest level, then "I3", and "I2" at the lowest.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ItemNo[BOMStructureDepth], LibraryRandom.RandInt(10), '', '');

        // [WHEN] Replan the production order for all levels of manufacturing.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [THEN] The production order keeps its 3-level structure of prod. order lines.
        for i := 2 to BOMStructureDepth do begin
            FindProductionOrderLine(ProdOrderLine, ItemNo[i]);
            ProdOrderLine.TestField("Prod. Order No.", ProductionOrder."No.");
            ProdOrderLine.TestField("Planning Level Code", BOMStructureDepth - i);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderLineWithAlternateUOMReplan()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemNo: array[3] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Make-to-Order] [Replan Production Order] [Unit of Measure]
        // [SCENARIO 218585] Production Order can be replanned if there is a prod. order line with "Qty. per Unit of Measure" > 1 in it.
        Initialize;

        // [GIVEN] Production BOM structure of 3 items "I1", "I2", "I3" created with "Make-to-Order" manufacturing policy.
        // [GIVEN] "I1" is a component of "I2", "I2" is a component of "I3".
        CreateProductionChainOfItems(ItemNo, 3);

        // [GIVEN] BOM for "I3" is modified - Unit of Measure Code for component "I2" is changed.
        UpdateUOMOnProdBOMLineByItemNo(ItemNo[3], ItemNo[2], LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Released production order for "I3". It has 2-level structure with "I3" at the high level and "I2" at the low.
        Qty := LibraryRandom.RandIntInRange(11, 20);
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ItemNo[3], Qty, '', '');

        // [GIVEN] Quantity on prod. order line for "I3" is doubled.
        FindProductionOrderLine(ProdOrderLine, ItemNo[3]);
        ProdOrderLine.Validate(Quantity, Qty * 2);
        ProdOrderLine.Modify(true);

        // [WHEN] Replan the production order for all levels of manufacturing.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [THEN] Prod. order line for "I2" is replanned, quantity is doubled.
        FindProductionOrderLine(ProdOrderLine, ItemNo[2]);
        ProdOrderLine.TestField(Quantity, Round(Qty * 2 / ProdOrderLine."Qty. per Unit of Measure", 0.00001));
    end;

    [Test]
    [HandlerFunctions('AllLevelsStrMenuHandler')]
    [Scope('OnPrem')]
    procedure StandardCostWithScrapCalculation()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        FixedScrapQuantity: Decimal;
        ParentItemScrapPercent: Decimal;
        LotSize: Decimal;
        ProductionBOMScrapPercent: Decimal;
    begin
        // [FEATURE] [Standard Cost]
        // [SCENARIO 221770] "Fixed Scrap Quantity" is an additional member in "Standard Cost" calculation formula
        Initialize;

        // [GIVEN] "MachineCenter" "MC" with "Fixed Scrap Quantity" = 20
        // [GIVEN] Production Item "PI" with Child Item as Production BOM with "Scrap %" = 10
        // [GIVEN] "PI" has Routing with "MC", "PI"."Scrap %" = 5, PI."Lot Size" = 50
        FixedScrapQuantity := LibraryRandom.RandIntInRange(10, 20);
        ParentItemScrapPercent := LibraryRandom.RandInt(5);
        LotSize := LibraryRandom.RandIntInRange(50, 100);
        ProductionBOMScrapPercent := LibraryRandom.RandIntInRange(5, 10);
        CreateItemCostingMethodFIFO(ChildItem);
        CreateProdOrderItemWithScrapPercent(
          ParentItem, CreateRoutingWithMachineCenter(CreateMachineCenterWithFixedScrap(FixedScrapQuantity)),
          CreateProductionBOMWitScrapPercent(ChildItem, ProductionBOMScrapPercent), ParentItemScrapPercent, LotSize);

        // [WHEN] Calculate Standard Cost for "PI"
        CalculateStandardCost.CalcItem(ParentItem."No.", false);

        // [THEN] "PI"."Standard Cost" = (1 + 5 / 100) * (1 + 10 / 100) + 20 / 50 = 1.555
        ParentItem.Find;
        AssertNearlyEqual(
          (1 + ParentItemScrapPercent / 100) * (1 + ProductionBOMScrapPercent / 100) + FixedScrapQuantity / LotSize,
          ParentItem."Standard Cost", StrSubstNo(IncorrectValueErr, ParentItem.TableName, ParentItem.FieldName("Standard Cost")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemScrapPercentForProdOrderComponentCalculationWhenRefresh()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ParentProductionBOMHeader: Record "Production BOM Header";
        ChildProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ScrapPercent: Integer;
        ChildQtyPer: Integer;
        ParentQtyPer: Integer;
        Qty: Integer;
    begin
        // [FEATURE] [Production Order] [Item Scrap %]
        // [SCENARIO 222911] "Scrap %" from Item Card participates in calculation of field "Expected Quantity" and doesn't participate in calculation of field "Quantity Per" of "Prod. Order Component"
        Initialize;

        // [GIVEN] 2-level structure of "Production BOM" "PB" of Parent Item "PI", "CI" is Child Item at level 2
        ScrapPercent := LibraryRandom.RandIntInRange(5, 10);
        ChildQtyPer := LibraryRandom.RandIntInRange(10, 15);
        ParentQtyPer := LibraryRandom.RandIntInRange(15, 20);
        Qty := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] For "PB" "Quantity Per" of first level is 10, "Quantity Per" of second level is 15
        LibraryInventory.CreateItem(ChildItem);
        CreateCertifiedProductionBOMWithQtyPer(
          ChildProductionBOMHeader, ChildItem."Base Unit of Measure", ProductionBOMLine.Type::Item, ChildItem."No.", ChildQtyPer);
        CreateCertifiedProductionBOMWithQtyPer(
          ParentProductionBOMHeader, ChildProductionBOMHeader."Unit of Measure Code",
          ProductionBOMLine.Type::"Production BOM", ChildProductionBOMHeader."No.", ParentQtyPer);

        // [GIVEN] "PI"."Scrap %" is 5
        CreateProductionItemWithScrapPercent(ParentItem, ParentProductionBOMHeader."No.", ScrapPercent);

        // [GIVEN] Production Order "PO" for "I" with Quantity 100
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItem."No.", Qty);

        // [WHEN] Refresh Production Order "PO"
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Component of "PO" for "CI" has "Quantity per" = 10 * 15 = 150, "Expected Quantity" = 10 * 15 * 100 * (1 + 5 / 100) = 15750
        FindProdOrderComponentByOrderNoAndItem(ProdOrderComponent, ProductionOrder."No.", ChildItem."No.");
        ProdOrderComponent.TestField("Quantity per", ParentQtyPer * ChildQtyPer);
        Assert.AreNearlyEqual(
          ParentQtyPer * ChildQtyPer * Qty * (1 + ScrapPercent / 100), ProdOrderComponent."Expected Quantity", 0.0001, ExpectedQuantityErr);
    end;

    [Test]
    [HandlerFunctions('AllLevelsStrMenuHandler')]
    [Scope('OnPrem')]
    procedure FixedScrapQtyMultipliedByQtyPerUoM()
    var
        ChildItem: Record Item;
        ProdItem: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        QtyPerUoM: Decimal;
        QtyPerBOMLine: Decimal;
        FixedScrapQty: Decimal;
        LotSize: Decimal;
    begin
        // [FEATURE] [Routing] [Scrap]
        // [SCENARIO 225829] Standard lot size and fixed scrap quantity should be multiplied by "Quantity per UoM" of the production BOM line when calculating component quantity

        Initialize;

        QtyPerUoM := LibraryRandom.RandIntInRange(5, 10);
        QtyPerBOMLine := LibraryRandom.RandIntInRange(5, 10);
        FixedScrapQty := LibraryRandom.RandIntInRange(5, 10);
        LotSize := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] BOM component item "C" with unit cost = 10
        LibraryInventory.CreateItem(ChildItem);
        UpdateUnitCostOnItem(ChildItem);

        // [GIVEN] Production BOM "B". Item "C" is included in the BOM in additional unit of measure with quantity per UOM = 3, "Quantity" in BOM line is 4
        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMHeader, ChildItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProdBOMHeader, ProdBOMLine, '', ProdBOMLine.Type::Item, ChildItem."No.", QtyPerBOMLine);
        UpdateUOMOnProdBOMLine(ProdBOMHeader."No.", ChildItem."No.", QtyPerUoM);

        // [GIVEN] Routing "R" with fixed scrap quantity = 7
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', '', RoutingLine.Type::"Machine Center", CreateMachineCenterWithFixedScrap(FixedScrapQty));
        RoutingLine.Modify(true);

        // [GIVEN] Manufactured item "P" with lot size = 20. Production BOM and routing for the item are "B" and "R", respectievely
        CreateProductionItem(ProdItem, ProdBOMHeader."No.");
        ProdItem.Validate("Routing No.", CreateRoutingWithMachineCenter(CreateMachineCenterWithFixedScrap(FixedScrapQty)));
        ProdItem.Validate("Lot Size", LotSize);
        ProdItem.Modify(true);

        // [WHEN] Calculate standard cost for the item "P"
        CalculateStandardCost.CalcItem(ProdItem."No.", false);

        // [THEN] Standard cost is (20 + 7) * 3 * 4 * 10 / 20 = 162
        ProdItem.Find;
        AssertNearlyEqual(
          (LotSize + FixedScrapQty) * QtyPerUoM * QtyPerBOMLine * ChildItem."Unit Cost" / LotSize,
          ProdItem."Standard Cost",
          StrSubstNo(IncorrectValueErr, ProdItem.TableName, ProdItem.FieldName("Standard Cost")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeOnChildPlanningLineInMakeToOrderStructureEqualsBinCodeOnPlanningComp()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ItemNo: array[3] of Code[20];
        LocationCode: Code[10];
        ProdBinCode: Code[20];
        OpenShopFloorBin: Code[20];
    begin
        // [FEATURE] [Make-to-Order] [Planning Component] [Planning Worksheet] [Bin]
        // [SCENARIO 229617] Bin Code on requisition line representing a child item in make-to-order structure, shows the bin, that the child item is placed into before being consumed by the production of the parent item.
        Initialize;

        // [GIVEN] Make-to-order structure - item "I1" is a component of "I2", and "I2" is a component of "I3".
        // [GIVEN] "From-production Bin Code" is "B3" at location. The output of "I3" will be placed into this bin.
        // [GIVEN] The bin code where the child item "I2" will be consumed from is set up in "Open Shop Floor Bin Code" ("B2") in work center, linked to the production BOM of "I3".
        CreateMakeToOrderProdItemWithComponentsTakenFromOpenShopFloorBin(ItemNo, LocationCode, ProdBinCode, OpenShopFloorBin);

        // [GIVEN] Demand for "X" pcs of item "I3".
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo[3], LibraryRandom.RandInt(10), LocationCode);

        // [WHEN] Calculate regenerative plan in planning worksheet for items "I2" and "I3".
        Item.SetFilter("No.", '%1|%2', ItemNo[2], ItemNo[3]);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // [THEN] Bin Code on the requisition line for parent item "I3" is equal to "B3".
        FindRequisitionLine(RequisitionLine, ItemNo[3]);
        RequisitionLine.TestField("Bin Code", ProdBinCode);

        // [THEN] Bin Code on the requisition line for child item "I2" is equal to "B2".
        FindRequisitionLine(RequisitionLine, ItemNo[2]);
        RequisitionLine.TestField("Bin Code", OpenShopFloorBin);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeOnChildMakeToOrderProdOrderLineEqualsBinCodeOnSuppliedProdOrderComp()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemNo: array[3] of Code[20];
        LocationCode: Code[10];
        ProdBinCode: Code[20];
        OpenShopFloorBin: Code[20];
    begin
        // [FEATURE] [Make-to-Order] [Bin]
        // [SCENARIO 229617] Bin Code on prod. order line representing a child item in make-to-order structure is equal to Bin Code on the prod. order component the child item supplies, when the production order is created via planning worksheet.
        Initialize;

        // [GIVEN] Make-to-order structure - item "I1" is a component of "I2", and "I2" is a component of "I3".
        // [GIVEN] "From-production Bin Code" is "B3" at location. The output of "I3" will be placed into this bin.
        // [GIVEN] The bin code where the child item "I2" will be consumed from is set up in "Open Shop Floor Bin Code" ("B2") in work center, linked to the production BOM of "I3".
        CreateMakeToOrderProdItemWithComponentsTakenFromOpenShopFloorBin(ItemNo, LocationCode, ProdBinCode, OpenShopFloorBin);

        // [GIVEN] Demand for "X" pcs of item "I3".
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo[3], LibraryRandom.RandInt(10), LocationCode);

        // [GIVEN] Regenerative plan in planning worksheet is calculated for items "I2" and "I3".
        Item.SetFilter("No.", '%1|%2', ItemNo[2], ItemNo[3]);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // [WHEN] Carry out action message - create a production order.
        AcceptActionMessage(RequisitionLine, ItemNo[2]);
        AcceptActionMessage(RequisitionLine, ItemNo[3]);
        Item.CopyFilter("No.", RequisitionLine."No.");
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] Bin Code on the parent prod order line is equal to "B3".
        FindProductionOrderLine(ProdOrderLine, ItemNo[3]);
        ProdOrderLine.TestField("Bin Code", ProdBinCode);

        // [THEN] Bin Code on prod. order component for the parent line is equal to "B2".
        FindProdOrderComponentByItem(ProdOrderComponent, ProdOrderLine, ItemNo[2]);
        ProdOrderComponent.TestField("Bin Code", OpenShopFloorBin);

        // [THEN] Bin Code on the child prod order line is equal to "B2".
        FindProductionOrderLine(ProdOrderLine, ItemNo[2]);
        ProdOrderLine.TestField("Bin Code", OpenShopFloorBin);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickingMTOItemAfterPlanning()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: array[3] of Code[20];
        Quantity: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Make-to-Order] [Component]
        // [SCENARIO 252705] A component which has sufficient stock must be picked up from stock when planning.

        Initialize;

        // [GIVEN] Update Manuf. Setup: setting "Components at Location" field with 'white' location code.
        UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);

        // [GIVEN] BOM structure of 3 items "I1".."I3" created with "Make-to-Order" manufacturing policy.
        // [GIVEN] "I1" is a component of "I2", "I2" is a component of "I3". I1 - 'Grandchild', I2 - 'Child', I3 - 'Parent'
        CreateProductionChainOfItems(ItemNo, 3);
        for i := 1 to 3 do begin
            Item.Get(ItemNo[i]);
            Item.Validate("Flushing Method", Item."Flushing Method"::Manual);
            Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
            Item.Modify(true);
        end;

        // [GIVEN] Create Inventory for Child Item on the 'white' location which was set to "Components at Location" above.
        Quantity := LibraryRandom.RandInt(10);
        Item.Get(ItemNo[2]);
        UpdateInventoryWithWhseItemJournal(Item, LocationWhite, Quantity);

        // [GIVEN] Create and release Sales Order for the Parent item.
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo[3], LibraryRandom.RandInt(Quantity), LocationWhite.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Calculate Regenerative Plan for the Parent item and its components (Child and Grandchild items).
        Item.SetFilter("No.", '%1|%2|%3', ItemNo[1], ItemNo[2], ItemNo[3]);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CM>', WorkDate), CalcDate('<CM>', WorkDate));

        // [GIVEN] Accept and Carry Out Action Message. 'Firm Planned Prod. Order' is created as a result.
        AcceptAndCarryOutActionMessage(ItemNo[3]);
        FilterFirmPlannedProductionOrder(ProductionOrder, ItemNo[3]);

        // [GIVEN] Release Prod. Order
        ProductionOrder.Get(
          ProductionOrder.Status::Released,
          LibraryManufacturing.ChangeStatusFirmPlanToReleased(
            ProductionOrder."No.", ProductionOrder.Status::"Firm Planned", ProductionOrder.Status::Released));

        // [WHEN] Create Whse. Pick from Released Prod. Order
        LibraryWarehouse.CreateWhsePickFromProduction(ProductionOrder);
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption",
          WarehouseActivityLine."Action Type"::Take);

        // [THEN] Whse. Pick must contain 2 lines of Child Item, which must be picked up from stock.
        WarehouseActivityLine.TestField("Item No.", ItemNo[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ProductionOrderStatusToFinishedWhenLastOutputJournalLineForFamilyIsPosted()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Family: Record Family;
        FamilyLine: Record "Family Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        i: Integer;
    begin
        // [FEATURE] [Output Journal] [Family] [Production Order Status]
        // [SCENARIO 265553] Can change production order status to Finished when last output journal line for family is posted
        Initialize;

        // [GIVEN] Routing "R" with two lines
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for i := 1 to 2 do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID, RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Family "F" with two items
        LibraryManufacturing.CreateFamily(Family);
        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);

        for i := 1 to 2 do begin
            CreateProductionItemWithRoutingNo(Item, RoutingHeader."No.");
            LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", Item."No.", 1);
        end;

        // [GIVEN] Production Order "O" with Source = "F"
        CreateAndRefreshReleasedProductionOrderWithSourceTypeFamily(ProductionOrder, Family."No.", 1);

        // [GIVEN] Post output journal with only one line - last "Operation No." for last item of family
        FindLastProdOrderLine(ProdOrderLine, ProductionOrder);
        CreateAndPostOutputJnlForProdOrderLine(ProdOrderLine, RoutingHeader."No.", RoutingLine."Operation No.", 0, 1);

        // [WHEN] Change "O" Status from Released to Finished
        LibraryVariableStorage.Enqueue(ConfirmStatusFinishTxt);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate, false);

        // [THEN] Production Order with Status = Finished and "No." = "O"."No." exists
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesSeparatesItems()
    var
        Item: array[2] of Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[2] of Record "Routing Line";
        Family: Record Family;
        FamilyLine: Record "Family Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ValueEntry: Record "Value Entry";
        i: Integer;
        WorkCenterUnitCost: Decimal;
        RunTime: array[2] of Decimal;
    begin
        // [FEATURE] [Adjust cost item entries] [Capacity] [Family]
        // [SCENARIO 266023] Adjust cost item entries separates capacity cost for different items from family with single routing.
        Initialize;

        // [GIVEN] Routing "R" with two lines, "Unit Cost" "U" = 1
        WorkCenterUnitCost := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Unit Cost", WorkCenterUnitCost);
        WorkCenter.Modify(true);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for i := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[i], '', LibraryUtility.GenerateGUID, RoutingLine[i].Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Family "F" with two items
        LibraryManufacturing.CreateFamily(Family);
        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);

        for i := 1 to ArrayLen(Item) do begin
            CreateProductionItemWithRoutingNo(Item[i], RoutingHeader."No.");
            LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", Item[i]."No.", 1);
        end;

        // [GIVEN] Production Order "O" with Source = "F" and with two lines - "L1" for "I1" and "L2" for "I2"
        CreateAndRefreshReleasedProductionOrderWithSourceTypeFamily(ProductionOrder, Family."No.", 1);

        // [GIVEN] Post output journal line - last "Operation No." for "L1" with quantity one and zero run time
        FindFirstProdOrderLine(ProdOrderLine, ProductionOrder);
        CreateAndPostOutputJnlForProdOrderLine(ProdOrderLine, RoutingHeader."No.", RoutingLine[2]."Operation No.", 0, 1);

        // [GIVEN] Post output journal line - last "Operation No." for "L2" with quantity one and zero run time
        FindLastProdOrderLine(ProdOrderLine, ProductionOrder);
        CreateAndPostOutputJnlForProdOrderLine(ProdOrderLine, RoutingHeader."No.", RoutingLine[2]."Operation No.", 0, 1);

        for i := 1 to ArrayLen(RunTime) do
            RunTime[i] := Power(10, i * i) * LibraryRandom.RandInt(10);

        // [GIVEN] Post output journal line - last "Operation No." for "L1" with zero quantity and "Run Time" "T1" = 10
        FindFirstProdOrderLine(ProdOrderLine, ProductionOrder);
        CreateAndPostOutputJnlForProdOrderLine(ProdOrderLine, RoutingHeader."No.", RoutingLine[1]."Operation No.", RunTime[1], 0);

        // [GIVEN] Post output journal line - last "Operation No." for "L2" with zero quantity and "Run Time" "T2" = 10000
        FindLastProdOrderLine(ProdOrderLine, ProductionOrder);
        CreateAndPostOutputJnlForProdOrderLine(ProdOrderLine, RoutingHeader."No.", RoutingLine[1]."Operation No.", RunTime[2], 0);

        // [GIVEN] Change "O" Status from Released to Finished
        LibraryVariableStorage.Enqueue(ConfirmStatusFinishTxt);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate, false);

        // [WHEN] Adjust cost item entries
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', Item[1]."No.", Item[2]."No."), '');

        // [THEN] "Value Entry" for "I1" with "Expected Cost" = FALSE has "Cost Amount (Actual)" = "U" * "T1" = 10
        ValueEntryCalcSumsCostAmountActual(ValueEntry, Item[1]."No.");
        ValueEntry.TestField("Cost Amount (Actual)", RunTime[1] * WorkCenterUnitCost);

        // [THEN] "Value Entry" for "I2" with "Expected Cost" = FALSE has "Cost Amount (Actual)" = "U" * "T2" = 10000
        ValueEntryCalcSumsCostAmountActual(ValueEntry, Item[2]."No.");
        ValueEntry.TestField("Cost Amount (Actual)", RunTime[2] * WorkCenterUnitCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderWithMakeToOrderComponentAndComponentAtLocation()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [FEATURE] [Make-to-Order] [Component]
        // [SCENARIO 285899] Refresh Prod Order with Make-To-Order component and Components at Location using Bin Code
        Initialize;

        // [GIVEN] Manufacturing Setup with "Components at Location" = "Loc"
        CreateAndUpdateLocation(Location, false, false, false, false);
        UpdateManufacturingSetupComponentsAtLocation(Location.Code);

        // [GIVEN] Make-To Order Item "Comp Item" has an item as component
        // [GIVEN] Make-To Order Item "Prod Item" has "Comp Item" as component
        CreateItemsSetup(CompItem, Item);
        CreateMakeToOrderProductionItem(ProdItem, CompItem);
        CompItem.Validate("Manufacturing Policy", CompItem."Manufacturing Policy"::"Make-to-Order");
        CompItem.Modify(true);

        // [GIVEN] Production Order for "Prod Item" with Location "Red" and Bin Code = "123"
        // [WHEN] Refresh Production Order
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProdItem."No.", LibraryRandom.RandInt(100),
          LocationRed.Code, Bin.Code);

        // [THEN] Prod Order Line for "Prod Item" has Location "Red" and Bin Code "123"
        // [THEN] Prod Order Line for "Comp Item" has Location "Loc" and blank Bin Code
        VerifyProdOrderLineWithLocationAndBin(ProdItem."No.", LocationRed.Code, Bin.Code);
        VerifyProdOrderLineWithLocationAndBin(CompItem."No.", Location.Code, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure EliminationOfTimeOverlapOnOneParentTwoChildAndSeparateGrandchildMTOLines()
    var
        GrandChildItem: array[2] of Record Item;
        ChildItem: array[2] of Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        EndingDateTime: DateTime;
        OriginalEndingDateTime: array[2] of DateTime;
        i: Integer;
    begin
        // [FEATURE] [Make-to-Order] [Routing]
        // [SCENARIO 286683] Increasing processing time of a semi-finished item in multilined production order shifts the starting date-time of the finished item forward. Case "one parent - two children - two separate grandchildren".
        Initialize;

        // [GIVEN] Make-to-order production tree of items.
        // [GIVEN] Parent item "A".
        // [GIVEN] Child items "B1" and "B2" are the components of "A".
        // [GIVEN] Grandchild item "C1" is a component of "B1", grandchild item "C2" is a component of "B2".
        // [GIVEN] Routings with defined Run Time are assigned to the grandchild items.
        // [GIVEN]      A
        // [GIVEN]     / \
        // [GIVEN]   B1   B2
        // [GIVEN]   /     \
        // [GIVEN]  C1     C2
        for i := 1 to ArrayLen(GrandChildItem) do begin
            CreateProductionItem(GrandChildItem[i], '');
            GrandChildItem[i].Validate("Manufacturing Policy", GrandChildItem[i]."Manufacturing Policy"::"Make-to-Order");
            GrandChildItem[i].Modify(true);
            CreateRoutingAndUpdateItem(GrandChildItem[i]);

            CreateCertifiedProductionBOM(ProductionBOMHeader, GrandChildItem[i]);
            CreateProductionItem(ChildItem[i], ProductionBOMHeader."No.");
            ChildItem[i].Validate("Manufacturing Policy", ChildItem[i]."Manufacturing Policy"::"Make-to-Order");
            ChildItem[i].Modify(true);
        end;

        CreateCertifiedProductionBOMWithMultipleItems(ProductionBOMHeader, ChildItem[1], ChildItem[2]);
        CreateProductionItem(ParentItem, ProductionBOMHeader."No.");
        ParentItem.Validate("Manufacturing Policy", ParentItem."Manufacturing Policy"::"Make-to-Order");
        ParentItem.Modify(true);

        // [GIVEN] Released production order for parent item "A".
        // [GIVEN] The production order has 5 lines:
        // [GIVEN] Item "A", starting date-time 25/01 8:00, ending date-time 25/01 23:00
        // [GIVEN] Item "B1", starting date-time 25/01 8:00, ending date-time 25/01 8:00
        // [GIVEN] Item "B2", starting date-time 25/01 8:00, ending date-time 25/01 8:00
        // [GIVEN] Item "C1", starting date-time 24/01 22:00, ending date-time 24/01 23:00
        // [GIVEN] Item "C2", starting date-time 24/01 22:00, ending date-time 24/01 23:00
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", LibraryRandom.RandInt(10), '', '');

        FindProductionOrderLine(ProdOrderLine, GrandChildItem[1]."No.");
        OriginalEndingDateTime[1] := ProdOrderLine."Ending Date-Time";

        FindProductionOrderLine(ProdOrderLine, ChildItem[1]."No.");
        OriginalEndingDateTime[2] := ProdOrderLine."Ending Date-Time";

        FindProductionOrderLine(ProdOrderLine, GrandChildItem[2]."No.");
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine);

        // [WHEN] Increase Run Time on prod. order routing line only for grandchild item "C2".
        LibraryVariableStorage.Enqueue(TimeShiftedOnParentLineMsg);
        ProdOrderRoutingLine.Validate("Run Time", ProdOrderRoutingLine."Run Time" * 2);
        ProdOrderRoutingLine.Modify(true);

        // [THEN] Ending date-time on production order line for "C2" is updated to 25/01 9:00.
        FindProductionOrderLine(ProdOrderLine, GrandChildItem[2]."No.");
        EndingDateTime := ProdOrderRoutingLine."Ending Date-Time";

        // [THEN] Starting date-time on production order line for item "B2" is updated to 25/01 9:00.
        // [THEN] Ending date-time on prod. order line for item "B2" is updated to 25/01 9:00.
        FindProductionOrderLine(ProdOrderLine, ChildItem[2]."No.");
        ProdOrderLine.TestField("Starting Date-Time", EndingDateTime);
        ProdOrderLine.TestField("Ending Date-Time", ProdOrderLine."Starting Date-Time");
        EndingDateTime := ProdOrderLine."Ending Date-Time";

        // [THEN] Starting date-time on prod. order line for parent item "A" is updated to 25/01 9:00.
        // [THEN] Thus, we ensure continuous manufacturing process in "C2" - "B2" - "A" chain.
        FindProductionOrderLine(ProdOrderLine, ParentItem."No.");
        ProdOrderLine.TestField("Starting Date-Time", EndingDateTime);

        // [THEN] Time adjustment for "C2" item does not have any impact on "C1" - "B1" chain.
        // [THEN] Starting date-time on "B1" and "C1" lines does not change.
        FindProductionOrderLine(ProdOrderLine, GrandChildItem[1]."No.");
        ProdOrderLine.TestField("Ending Date-Time", OriginalEndingDateTime[1]);

        FindProductionOrderLine(ProdOrderLine, ChildItem[1]."No.");
        ProdOrderLine.TestField("Starting Date-Time", OriginalEndingDateTime[2]);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure EliminationOfTimeOverlapOnOneParentTwoChildAndCommonGrandchildMTOLines()
    var
        GrandChildItem: Record Item;
        ChildItem: array[2] of Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        EndingDateTime: DateTime;
        i: Integer;
    begin
        // [FEATURE] [Make-to-Order] [Routing]
        // [SCENARIO 286683] Increasing processing time of a semi-finished item in multilined production order shifts the starting date-time of the finished item forward. Case "one parent - two children - one common grandchild".
        Initialize;

        // [GIVEN] Make-to-order production tree of items.
        // [GIVEN] Parent item "A".
        // [GIVEN] Child items "B1" and "B2" are the components of "A".
        // [GIVEN] Grandchild item "C" is a component of both "B1" and "B2" items.
        // [GIVEN] Routing with defined Run Time are assigned to the grandchild item.
        // [GIVEN]     A
        // [GIVEN]    / \
        // [GIVEN]  B1   B2
        // [GIVEN]    \ /
        // [GIVEN]     C
        CreateProductionItem(GrandChildItem, '');
        GrandChildItem.Validate("Manufacturing Policy", GrandChildItem."Manufacturing Policy"::"Make-to-Order");
        GrandChildItem.Modify(true);
        CreateRoutingAndUpdateItem(GrandChildItem);

        for i := 1 to ArrayLen(ChildItem) do begin
            CreateCertifiedProductionBOM(ProductionBOMHeader, GrandChildItem);
            CreateProductionItem(ChildItem[i], ProductionBOMHeader."No.");
            ChildItem[i].Validate("Manufacturing Policy", ChildItem[i]."Manufacturing Policy"::"Make-to-Order");
            ChildItem[i].Modify(true);
        end;

        CreateCertifiedProductionBOMWithMultipleItems(ProductionBOMHeader, ChildItem[1], ChildItem[2]);
        CreateProductionItem(ParentItem, ProductionBOMHeader."No.");
        ParentItem.Validate("Manufacturing Policy", ParentItem."Manufacturing Policy"::"Make-to-Order");
        ParentItem.Modify(true);

        // [GIVEN] Released production order for parent item "A".
        // [GIVEN] The production order has 4 lines:
        // [GIVEN] Item "A", starting date-time 25/01 8:00, ending date-time 25/01 23:00
        // [GIVEN] Item "B1", starting date-time 25/01 8:00, ending date-time 25/01 8:00
        // [GIVEN] Item "B2", starting date-time 25/01 8:00, ending date-time 25/01 8:00
        // [GIVEN] Item "C", starting date-time 24/01 22:00, ending date-time 24/01 23:00
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", LibraryRandom.RandInt(10), '', '');

        FindProductionOrderLine(ProdOrderLine, GrandChildItem."No.");
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine);

        // [WHEN] Increase Run Time on prod. order routing line for grandchild item "C".
        LibraryVariableStorage.Enqueue(TimeShiftedOnParentLineMsg);
        ProdOrderRoutingLine.Validate("Run Time", ProdOrderRoutingLine."Run Time" * 2);
        ProdOrderRoutingLine.Modify(true);

        // [THEN] Ending date-time on production order line for "C" is updated to 25/01 9:00.
        FindProductionOrderLine(ProdOrderLine, GrandChildItem."No.");
        EndingDateTime := ProdOrderLine."Ending Date-Time";

        // [THEN] Starting date-time on production order line for item "B1" is updated to 25/01 9:00.
        // [THEN] Ending date-time on prod. order line for item "B1" is updated to 25/01 9:00.
        FindProductionOrderLine(ProdOrderLine, ChildItem[1]."No.");
        ProdOrderLine.TestField("Starting Date-Time", EndingDateTime);
        ProdOrderLine.TestField("Ending Date-Time", ProdOrderLine."Starting Date-Time");

        // [THEN] Starting date-time on production order line for item "B2" is updated to 25/01 9:00.
        // [THEN] Ending date-time on prod. order line for item "B2" is updated to 25/01 9:00.
        FindProductionOrderLine(ProdOrderLine, ChildItem[2]."No.");
        ProdOrderLine.TestField("Starting Date-Time", EndingDateTime);
        ProdOrderLine.TestField("Ending Date-Time", ProdOrderLine."Starting Date-Time");
        EndingDateTime := ProdOrderLine."Ending Date-Time";

        // [THEN] Starting date-time on production order line for item "A" is updated to 25/01 9:00.
        FindProductionOrderLine(ProdOrderLine, ParentItem."No.");
        ProdOrderLine.TestField("Starting Date-Time", EndingDateTime);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure WarningOfEliminatedTimeOverlapIsRaisedOnceForSeveralRoutingAdjustments()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ErrorMessage: Record "Error Message";
    begin
        // [FEATURE] [Make-to-Order] [Routing] [UI]
        // [SCENARIO 286683] A message that warns a user of changed starting date-time in production order is raised only once, although the time is adjusted several times.
        Initialize;

        // [GIVEN] Make-to-order production chain - finished item "A" and its component "B".
        CreateProductionItem(ChildItem, '');
        ChildItem.Validate("Manufacturing Policy", ChildItem."Manufacturing Policy"::"Make-to-Order");
        ChildItem.Modify(true);
        CreateRoutingAndUpdateItem(ChildItem);

        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem);
        CreateProductionItem(ParentItem, ProductionBOMHeader."No.");
        ParentItem.Validate("Manufacturing Policy", ParentItem."Manufacturing Policy"::"Make-to-Order");
        ParentItem.Modify(true);

        // [GIVEN] Released production order for parent item "A".
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", LibraryRandom.RandInt(10), '', '');

        FindProductionOrderLine(ProdOrderLine, ChildItem."No.");
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine);

        // [WHEN] Increase Run Time twice on prod. order routing line for component item "B".
        LibraryVariableStorage.Enqueue(TimeShiftedOnParentLineMsg);
        LibraryVariableStorage.Enqueue(TimeShiftedOnParentLineMsg);
        ProdOrderRoutingLine.Validate("Run Time", ProdOrderRoutingLine."Run Time" * 2);
        ProdOrderRoutingLine.Validate("Run Time", ProdOrderRoutingLine."Run Time" * 4);
        ProdOrderRoutingLine.Modify(true);

        // [THEN] Only one warning message of changed starting date-time for finished item is shown to a user.
        Assert.AreEqual(
          TimeShiftedOnParentLineMsg, LibraryVariableStorage.DequeueText,
          'Warning of changed date-time in the production order must be raised only once.');

        // [THEN] Message log for the prod. order routing line is clear.
        ErrorMessage.SetRange("Record ID", ProdOrderRoutingLine.RecordId);
        Assert.RecordIsEmpty(ErrorMessage);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipmentDateOnReservEntriesMatchDueDateOnProdOrderLineAfterEndingDateShiftedForward()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Make-to-Order] [Routing] [Reservation]
        // [SCENARIO 286683] When changing date on prod. order routing line moves the due date on semi-production item to a later date than the end item was initially planned, no date conflict error occurs. "Shipment Date" on reservation entries are update
        Initialize;

        // [GIVEN] Make-to-order production chain - finished item "A" and its component "B".
        CreateProductionItem(ChildItem, '');
        ChildItem.Validate("Manufacturing Policy", ChildItem."Manufacturing Policy"::"Make-to-Order");
        ChildItem.Modify(true);
        CreateRoutingAndUpdateItem(ChildItem);

        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem);
        CreateProductionItem(ParentItem, ProductionBOMHeader."No.");
        ParentItem.Validate("Manufacturing Policy", ParentItem."Manufacturing Policy"::"Make-to-Order");
        ParentItem.Modify(true);

        // [GIVEN] Released production order for parent item "A".
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", LibraryRandom.RandInt(10), '', '');

        FindProductionOrderLine(ProdOrderLine, ChildItem."No.");
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine);

        // [WHEN] Move Starting Date 10 days forward on prod. order routing line for component item "B".
        LibraryVariableStorage.Enqueue(TimeShiftedOnParentLineMsg);
        ProdOrderRoutingLine.Validate(
          "Starting Date", LibraryRandom.RandDateFromInRange(ProdOrderRoutingLine."Starting Date", 10, 20));
        ProdOrderRoutingLine.Modify(true);

        // [THEN] No "Date conflict during reservation..." error message is thrown.
        // [THEN] "Shipment Date" on reservation entries between output of semi-production item and its consumption are moved 10 days forward.
        ProdOrderLine.Find;
        ReservationEntry.SetSourceFilter(
          DATABASE::"Prod. Order Line", ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", 0, false);
        ReservationEntry.SetSourceFilter('', ProdOrderLine."Line No.");
        ReservationEntry.FindFirst;
        ReservationEntry.TestField("Shipment Date", ProdOrderRoutingLine."Ending Date");
        ReservationEntry.TestField("Shipment Date", ProdOrderLine."Due Date");

        ReservationEntry.Reset;
        ReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
        ReservationEntry.TestField("Shipment Date", ProdOrderRoutingLine."Ending Date");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ReservationHandler,AllLevelsStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ShipmentDateOnReservEntriesMatchDueDateOnProdOrderCompWhenReserveFromTransfer()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
    begin
        // [FEATURE] [Reservation] [Shipment Date] [Prod. Order Component] [Transfer]
        // [SCENARIO 298983] Shipment Date in Reservation Entry respects Prod. Order Component Due Date when reserve from Transfer Line
        Initialize;
        Quantity := LibraryRandom.RandInt(100);

        // [GIVEN] Item X was a production component of Item Y (1 PCS of X required to produce 1 PCS of Y)
        LibraryInventory.CreateItem(ChildItem);
        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem);
        CreateProductionItem(ParentItem, ProductionBOMHeader."No.");

        // [GIVEN] Item X had 100 PCS in Location RED
        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity, '', FromLocation.Code, false);

        // [GIVEN] Released Production Order with 100 PCS of Item Y in Location BLUE, Due Date was 28/1/2020 (Due Date = 27/1/2020 in Prod. Order Component)
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", Quantity, ToLocation.Code, '');

        // [GIVEN] Released Transfer Order from RED to BLUE with 100 PCS of Item X and Shipment Date = 21/1/2020
        CreateTransferOrderWithQtyAndShipmentDate(
          TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, ChildItem."No.",
          ProductionOrder.Quantity, CalcDate('<-1W>', WorkDate));
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Auto-reserve Inbound Transfer for the Prod. Order Component (done in ReservationHandler and AllLevelsStrMenuHandler)
        TransferLine.ShowReservation;

        // [THEN] Both Reservation Entries for Item X have Shipment Date = 27/1/2020
        ReservationEntry.SetRange("Item No.", ChildItem."No.");
        Assert.RecordCount(ReservationEntry, 2);
        ReservationEntry.FindSet;
        repeat
            ReservationEntry.TestField("Shipment Date", CalcDate('<-1D>', WorkDate))
        until ReservationEntry.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdBOMComponentWithZeroQtyPerAddedToProdOrderComponent()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Production BOM] [Prod. Order Component]
        // [SCENARIO 315417] Production BOM component with "Quantity per" = 0 is added to prod. order components on production order refresh.
        Initialize;

        // [GIVEN] Component item "C", production item "P".
        // [GIVEN] Set "Quantity per" = 0 on the production BOM line for component "C".
        LibraryInventory.CreateItem(CompItem);
        CreateCertifiedProductionBOMWithQtyPer(
          ProductionBOMHeader, CompItem."Base Unit of Measure", ProductionBOMLine.Type::Item, CompItem."No.", 0);
        CreateProductionItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Released production order for "P".
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", LibraryRandom.RandInt(10));

        // [WHEN] Refresh the production order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Component "C" is added to the prod. order components with "Quantity per" = 0.
        FindProdOrderComponentByOrderNoAndItem(ProdOrderComponent, ProductionOrder."No.", CompItem."No.");
        ProdOrderComponent.TestField("Quantity per", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdBOMComponentForMTOAndZeroQtyNotAddedToProdOrderComponent()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Production BOM] [Prod. Order Component] [Make-to-Order]
        // [SCENARIO 315417] Production BOM component set up to be a child production item in Make-to-Order tree is not added to prod. order components of the parent item, if the component has "Quantity per" = 0 in the production BOM.
        Initialize;

        // [GIVEN] Component item "C" is a production item and set up for "Make-to-Order" manufacturing policy.
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::"Prod. Order");
        CompItem.Validate("Manufacturing Policy", CompItem."Manufacturing Policy"::"Make-to-Order");
        CompItem.Modify(true);

        // [GIVEN] Production item "P" also set up for "Make-to-Order".
        // [GIVEN] Make item "C" a component of "P" with "Quantity per" = 0.
        CreateCertifiedProductionBOMWithQtyPer(
          ProductionBOMHeader, CompItem."Base Unit of Measure", ProductionBOMLine.Type::Item, CompItem."No.", 0);
        CreateProductionItem(ProdItem, ProductionBOMHeader."No.");
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Order");
        ProdItem.Modify(true);

        // [GIVEN] Released production order for "P".
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", LibraryRandom.RandInt(10));

        // [WHEN] Refresh the production order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Component "C" is not added to the prod. order components because there is no child prod. order line for "C" in the make-to-order tree.
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        Assert.RecordIsEmpty(ProdOrderComponent);

        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", CompItem."No.");
        Assert.RecordIsEmpty(ProdOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnnecessaryDueDateRefreshOnProdOrderComponent()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Production BOM] [Prod. Order Component] [Due Date]
        // [SCENARIO 319012] Due Date/Time fields for Production BOM Component isn't unnecessary refreshed on validating "Quantity per"
        Initialize;

        // [GIVEN] Created Component and Production Items
        LibraryInventory.CreateItem(CompItem);
        CreateCertifiedProductionBOMWithQtyPer(
          ProductionBOMHeader, CompItem."Base Unit of Measure", ProductionBOMLine.Type::Item,
          CompItem."No.", LibraryRandom.RandIntInRange(1, 5));
        CreateProductionItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Released and refreshed Production Order
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", LibraryRandom.RandInt(10));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Modified Due Date and Due Time and assign Routing Link Code on Prod. Order Component
        FindProdOrderComponentByOrderNoAndItem(ProdOrderComponent, ProductionOrder."No.", CompItem."No.");
        ProdOrderComponent.Validate("Due Date", ProdOrderComponent."Due Date" + 1);
        ProdOrderComponent.Validate("Due Time", ProdOrderComponent."Due Time" + 1);
        ProdOrderComponent.Modify(true);

        // [WHEN] Modify Quantity per on Prod. Order Component
        ProdOrderComponent.Validate("Quantity per", LibraryRandom.RandIntInRange(6, 10));

        // [GIVEN] Due Date/time fields aren't refreshed
        ProdOrderComponent.TestField("Due Date", ProductionOrder."Starting Date" + 1);
        ProdOrderComponent.TestField("Due Time", ProductionOrder."Starting Time" + 1);
        ProdOrderComponent.TestField(
          "Due Date-Time", CreateDateTime(ProductionOrder."Starting Date" + 1, ProductionOrder."Starting Time" + 1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningLevelCodeZeroMTSSKUForMTOProdOrderComponent()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        SKU: Record "Stockkeeping Unit";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Make-to-Order] [Make-to-Stock] [Prod. Order Component]
        // [SCENARIO 333008] Production Order Component for an MTO Item with an MTS SKU has zero Planning Level Code
        Initialize;

        // [GIVEN] Component MTO Item "COMP" With Make-to-Stock Stockkeeping Unit for location "RED"
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::"Prod. Order");
        CompItem.Validate("Manufacturing Policy", CompItem."Manufacturing Policy"::"Make-to-Order");
        CompItem.Modify(true);
        CreateStockkkeepingUnit(SKU, CompItem."No.", LocationRed.Code, SKU."Manufacturing Policy"::"Make-to-Stock");

        // [GIVEN] Production MTO Item "PROD" with Component "COMP"
        CreateMakeToOrderProductionItem(ProdItem, CompItem);

        // [WHEN] Create And Refresh Released Production Order for Item "PROD" and location "RED"
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProdItem."No.", LibraryRandom.RandDec(10, 2), LocationRed.Code, '');

        // [THEN] Production Order Component for Item "COMP" has Plannning Level Code = 0
        FindProdOrderComponentByOrderNoAndItem(ProdOrderComponent, ProductionOrder."No.", CompItem."No.");
        ProdOrderComponent.TestField("Planning Level Code", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningLevelCodeIncreasedMTOSKUForMTOProdOrderComponent()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        SKU: Record "Stockkeeping Unit";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Make-to-Order] [Prod. Order Component]
        // [SCENARIO 333008] Production Order Component for an MTO Item with an MTO SKU has Planning Level Code increased
        Initialize;

        // [GIVEN] Component MTO Item "COMP" With Make-to-Order Stockkeeping Unit for location "RED"
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::"Prod. Order");
        CompItem.Validate("Manufacturing Policy", CompItem."Manufacturing Policy"::"Make-to-Order");
        CompItem.Modify(true);
        CreateStockkkeepingUnit(SKU, CompItem."No.", LocationRed.Code, SKU."Manufacturing Policy"::"Make-to-Order");

        // [GIVEN] Production MTO Item "PROD" with Component "COMP"
        CreateMakeToOrderProductionItem(ProdItem, CompItem);

        // [WHEN] Create And Refresh Released Production Order for Item "PROD" and location "RED"
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProdItem."No.", LibraryRandom.RandDec(10, 2), LocationRed.Code, '');

        // [THEN] Production Order Component for Item "COMP" has Plannning Level Code = 1
        FindProdOrderComponentByOrderNoAndItem(ProdOrderComponent, ProductionOrder."No.", CompItem."No.");
        ProdOrderComponent.TestField("Planning Level Code", 1);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Production Orders II");
        LibraryVariableStorage.Clear;

        LibrarySetupStorage.Restore;

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Production Orders II");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;

        NoSeriesSetup;
        CreateLocationSetup;
        ItemJournalSetup;
        OutputJournalSetup;
        ConsumptionJournalSetup;
        RevaluationJournalSetup;
        IsInitialized := true;

        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");

        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Production Orders II");
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);

        CreateAndUpdateLocation(LocationGreen, false, false, false, false);  // Location Green.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen.Code, false);

        CreateAndUpdateLocation(LocationRed, false, false, false, true);  // Location Red.
        LibraryWarehouse.CreateNumberOfBins(LocationRed.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value  required for Number of Bins.

        CreateAndUpdateLocation(LocationYellow, true, true, false, true);  // Location Yellow.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationYellow.Code, false);
        LibraryWarehouse.CreateNumberOfBins(LocationYellow.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value  required for Number of Bins.

        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);

        CreateAndUpdateLocation(LocationGreen2, true, true, true, false);  // Location Green.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen2.Code, false);
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        SalesSetup.Get;
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesSetup.Modify(true);

        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        PurchasesPayablesSetup.Modify(true);

        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
    end;

    local procedure ItemJournalSetup()
    begin
        ItemJournalTemplate.Init;
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        ItemJournalTemplate.Modify(true);

        ItemJournalBatch.Init;
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", '');  // Value required to avoid the Document No mismatch.
        ItemJournalBatch.Modify(true);
    end;

    local procedure OutputJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
    end;

    local procedure ConsumptionJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ConsumptionItemJournalTemplate, ConsumptionItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
          ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type, ConsumptionItemJournalTemplate.Name);
    end;

    local procedure RevaluationJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(RevaluationItemJournalTemplate, RevaluationItemJournalTemplate.Type::Revaluation);
        LibraryInventory.SelectItemJournalBatchName(
          RevaluationItemJournalBatch, RevaluationItemJournalTemplate.Type, RevaluationItemJournalTemplate.Name);
    end;

    local procedure AssertNearlyEqual(Expected: Decimal; Actual: Decimal; Msg: Text)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        Assert.AreNearlyEqual(Expected, Actual, GeneralLedgerSetup."Unit-Amount Rounding Precision", Msg);
    end;

    local procedure AssignNoSeriesForItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure AcceptAndCarryOutActionMessage(No: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, No);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireShipment: Boolean; BinMandatory: Boolean)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, false, RequireShipment);
    end;

    local procedure CreateLocationWithBins(var Location: Record Location; var BinCode: array[5] of Code[20]; NoOfBins: Integer)
    var
        Bin: Record Bin;
        i: Integer;
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', NoOfBins, false);
        for i := 1 to NoOfBins do begin
            LibraryWarehouse.FindBin(Bin, Location.Code, '', i);
            BinCode[i] := Bin.Code;
        end;
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10])
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateItemsSetup(var Item: Record Item; var Item2: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Child Item.
        LibraryInventory.CreateItem(Item2);

        // Create Production BOM, Parent item and Attach Production BOM.
        CreateCertifiedProductionBOM(ProductionBOMHeader, Item2);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateProductionItemWithScrapPercent(var Item: Record Item; ProductionBOMNo: Code[20]; ScrapPercent: Integer)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Validate("Scrap %", ScrapPercent);
        Item.Modify(true);
    end;

    local procedure CreateMachineCenterWithFixedScrap(FixedScrapQuantity: Decimal): Code[20]
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenter."No.", 1);
        MachineCenter.Validate("Fixed Scrap Quantity", FixedScrapQuantity);
        MachineCenter.Modify(true);
        exit(MachineCenter."No.");
    end;

    local procedure CreateRoutingWithMachineCenter(MachineCenterNo: Code[20]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '',
          LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"),
          RoutingLine.Type::"Machine Center", MachineCenterNo);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateItemCostingMethodFIFO(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Unit Cost", 1);
        Item.Validate("Rounding Precision", 0.01);
        Item.Modify(true);
    end;

    local procedure CreateProductionBOMWitScrapPercent(Item: Record Item; ScrapPercent: Decimal): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);
        ProductionBOMLine.Validate("Scrap %", ScrapPercent);
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreateProdOrderItemWithScrapPercent(var Item: Record Item; RoutingNo: Code[20]; ProductionBOMNo: Code[20]; ScrapPercent: Decimal; LotSize: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Rounding Precision", 0.01);
        Item.Validate("Routing No.", RoutingNo);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Validate("Scrap %", ScrapPercent);
        Item.Validate("Lot Size", LotSize);
        Item.Modify(true);
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);  // Value important.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateCertifiedProductionBOMWithQtyPer(var ProductionBOMHeader: Record "Production BOM Header"; UnitOfMeasureCode: Code[10]; Type: Option; No: Code[20]; QtyPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, No, QtyPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateProductionItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithRoutingNo(var Item: Record Item; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateMakeToOrderProductionItem(var Item: Record Item; CompItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Flushing Method", Item."Flushing Method"::Backward);
        Item.Modify(true);
    end;

    local procedure CreateProductionChainOfItems(var ItemNo: array[5] of Code[20]; BOMStructureDepth: Integer)
    var
        CompItem: Record Item;
        ProdItem: array[5] of Record Item;
        i: Integer;
    begin
        CreateItemsSetup(ProdItem[1], CompItem);
        ItemNo[1] := ProdItem[1]."No.";

        for i := 2 to BOMStructureDepth do begin
            CreateMakeToOrderProductionItem(ProdItem[i], ProdItem[i - 1]);
            ItemNo[i] := ProdItem[i]."No.";
        end;
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Option; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateItemSetupWithLotTracking(var Item: Record Item; var Item2: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCode);
        CreateItemWithItemTrackingCode(Item2, CreateItemTrackingCode);
        CreateCertifiedProductionBOM(ProductionBOMHeader, Item);
        Item2.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item2.Modify(true);
    end;

    local procedure CreateItemsSetupWithProductionAndTracking(var Item: Record Item; var Item2: Record Item; var ProductionOrder: Record "Production Order"; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreateItemSetupWithLotTracking(Item, Item2);
        CreateAndPostItemJournalLine(Item."No.", Quantity, '', LocationCode, true);  // Using Tracking TRUE.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item2."No.", Quantity, LocationCode, '');
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        Item.Modify(true);
    end;

    local procedure CreateItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateBomItemsWithReorderingPolicy(var ParentItem: Record Item; var ChildItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Parent and Child Item.
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(ChildItem);
        UpdateItemParametersForPlanningWorksheet(
          ParentItem, ParentItem."Manufacturing Policy"::"Make-to-Order",
          ParentItem."Reordering Policy"::Order, ParentItem."Replenishment System"::"Prod. Order");
        UpdateItemParametersForPlanningWorksheet(
          ChildItem, ChildItem."Manufacturing Policy"::"Make-to-Order",
          ChildItem."Reordering Policy"::Order, ChildItem."Replenishment System"::"Prod. Order");

        // Create Production BOM and attach Production BOM to Parent Item.
        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem);
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
    end;

    local procedure CreateMakeToOrderProdItemWithComponentsTakenFromOpenShopFloorBin(var ItemNo: array[3] of Code[20]; var LocationCode: Code[10]; var ProdBinCode: Code[20]; var OpenShopFloorBin: Code[20])
    var
        Location: Record Location;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLink: Record "Routing Link";
        BinCode: array[5] of Code[20];
    begin
        CreateLocationWithBins(Location, BinCode, 2);
        LocationCode := Location.Code;
        ProdBinCode := BinCode[1];
        OpenShopFloorBin := BinCode[2];
        Location.Validate("From-Production Bin Code", ProdBinCode);
        Location.Modify(true);

        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Location Code", LocationCode);
        WorkCenter.Validate("Open Shop Floor Bin Code", OpenShopFloorBin);
        WorkCenter.Modify(true);

        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        CreateRoutingWithRoutingLink(RoutingHeader, WorkCenter."No.", RoutingLink.Code);

        CreateProductionChainOfItems(ItemNo, 3);
        UpdateRoutingOnItem(ItemNo[3], RoutingHeader."No.");
        UpdateRoutingLinkOnProductionBOMLine(ItemNo[3], ItemNo[2], RoutingLink.Code);
    end;

    local procedure CreateAndPostOutputJournalWithItemTracking(ProductionOrderNo: Code[20]; Tracking: Boolean; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExlpodeRouting(ItemJournalLine, ProductionOrderNo);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Assign Lot No.
            ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        end;
        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateAndPostConsumptionJournalWithItemTracking(ProductionOrderNo: Code[20]; Tracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Select Tracking Entries TRUE.
            ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        end;
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure CreateOutputJournalWithExlpodeRouting(var ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProductionOrderNo);
        LibraryInventory.OutputJnlExplRoute(ItemJournalLine);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10]; Tracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity, BinCode, LocationCode);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Assign Lot No TRUE.
            ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndReleaseSalesOrderWithReservation(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        SalesLine.ShowReservation;  // Invokes ReservationHandler.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Quantity, '');
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateRoutingAndUpdateItem(var Item: Record Item): Code[10]
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLink: Record "Routing Link";
    begin
        RoutingLink.FindFirst;
        CreateWorkCenter(WorkCenter);
        CreateRoutingWithRoutingLink(RoutingHeader, WorkCenter."No.", RoutingLink.Code);

        // Update Routing No on Item.
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
        exit(RoutingLink.Code);
    end;

    local procedure CreateRoutingWithRoutingLink(var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; RoutingLinkCode: Code[10])
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo);
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateRoutingWithSetupWaitAndMoveTime(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        with RoutingLine do begin
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(5)), Type::"Work Center", WorkCenter."No.");
            Validate("Setup Time", LibraryRandom.RandInt(10));
            Validate("Wait Time", LibraryRandom.RandInt(10));
            Validate("Move Time", LibraryRandom.RandInt(10));
            Modify(true);
        end;

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Quantity, '', 0D);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CalculateInventoryValue(var Item: Record Item)
    var
        ItemJournalLine: Record "Item Journal Line";
        CalculatePer: Option "Item Ledger Entry",Item;
        CalcBase: Option " ","Last Direct Unit Cost","Standard Cost - Assembly List","Standard Cost - Manufacturing";
    begin
        SelectItemJournalLine(ItemJournalLine, RevaluationItemJournalTemplate.Name, RevaluationItemJournalBatch.Name);
        Item.SetRange("No.", Item."No.");
        LibraryCosting.CalculateInventoryValue(
          ItemJournalLine, Item, WorkDate, ItemJournalLine."Journal Batch Name" + Format(ItemJournalLine."Line No."),
          CalculatePer::"Item Ledger Entry", false, false, false, CalcBase::" ", false);
    end;

    local procedure CreateAndRegisterPickWithProductionOrderSetup(var ProductionOrder: Record "Production Order"; Location: Record Location; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ItemNo, Quantity, Location.Code, Location."To-Production Bin Code");
        LibraryWarehouse.CreateWhsePickFromProduction(ProductionOrder);
        UpdateBinCodeOnWarehouseActivityLine(ProductionOrder."No.");
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", WarehouseActivityLine."Action Type"::Take);
    end;

    local procedure CreateWarehouseJournalLine(var Item: Record Item; var WarehouseJournalLine: Record "Warehouse Journal Line"; Location: Record Location; Quantity: Decimal)
    var
        Bin: Record Bin;
    begin
        Bin.Get(Location.Code, Location."Cross-Dock Bin Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, Bin."Zone Code",
          Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
    end;

    local procedure CreateAndPostPurchaseOrderWithLocationAndBin(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
    end;

    local procedure CreateAndRefreshReleasedProductionOrderWithSourceTypeFamily(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Family, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateFamily(var Family: Record Family; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal)
    var
        FamilyLine: Record "Family Line";
    begin
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo, Quantity);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo2, Quantity);
    end;

    local procedure CreateItemHierarchyForFamily(var ParentItem: Record Item; var ParentItem2: Record Item; var ChildItem: Record Item; var ChildItem2: Record Item)
    begin
        CreateItemsSetup(ParentItem, ChildItem);
        CreateItemsSetup(ParentItem2, ChildItem2);
        UpdateUnitCostOnItem(ChildItem);
        UpdateUnitCostOnItem(ChildItem2);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandInt(100) + 100, '', '', false);  // Use Tracking FALSE.
        CreateAndPostItemJournalLine(ChildItem2."No.", LibraryRandom.RandInt(100) + 100, '', '', false);  // Use Tracking FALSE.
    end;

    local procedure CalculateRemainingQuantityOnProductionOrderComponent(ProductionOrderNo: Code[20]) TotalRemainingQuantity: Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrderNo);
        repeat
            TotalRemainingQuantity += ProdOrderComponent."Remaining Quantity";
        until ProdOrderComponent.Next = 0;
    end;

    local procedure CreateProdBOMSetupMultipleComponents(var Item: Record Item; var Item2: Record Item; var Item3: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Child Items.
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItem(Item3);

        // Create Production BOM, Parent item and Attach Production BOM.
        CreateCertifiedProductionBOMWithMultipleItems(ProductionBOMHeader, Item2, Item3);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateCertifiedProductionBOMWithMultipleItems(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; Item2: Record Item)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);  // Value important.
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item2."No.", 1);  // Value important.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateDemandForCalculatePlanAndCarryOutAction(ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        CreateAndReleaseSalesOrder(SalesHeader, ItemNo, Quantity);

        // Calculate Regenerative Plan on WORKDATE. Accept and Carry Out Action Message.
        Item.Get(ItemNo);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);
        AcceptAndCarryOutActionMessage(ItemNo);
    end;

    local procedure CreateLotForLotItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        UpdateItemParametersForPlanning(Item);
    end;

    local procedure ChangeStatusFromFirmPlannedToReleased(ItemNo: Code[20]) ProductionOrderNo: Code[20]
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        ProductionOrder.Get(ProdOrderLine.Status::"Firm Planned", ProdOrderLine."Prod. Order No.");

        // Change Production Order Status from Firm Planned to Released.
        ProductionOrderNo :=
          LibraryManufacturing.ChangeStatusFirmPlanToReleased(
            ProductionOrder."No.", ProductionOrder.Status::"Firm Planned", ProductionOrder.Status::Released);
    end;

    local procedure CreatePickFromReleasedProductionOrder(ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryWarehouse.CreateWhsePickFromProduction(ProductionOrder);
    end;

    local procedure CreateLotForLotItemSetupWithInventoryOnLocation(var Item: Record Item; var ChildItem: Record Item; Location: Record Location; Quantity: Decimal)
    begin
        CreateItemsSetup(Item, ChildItem);
        UpdateItemParametersForPlanning(Item);
        UpdateInventoryWithWhseItemJournal(ChildItem, Location, Quantity);
    end;

    local procedure CreateMaximumQtyItem(var Item: Record Item; MaximumInventory: Decimal)
    begin
        CreateManufacturingItem(Item, Item."Reordering Policy"::"Maximum Qty.", Item."Replenishment System"::Purchase);
        Item.Validate("Reorder Point", LibraryRandom.RandDec(10, 2) + 10);  // Large Random Value required for test.
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Validate("Minimum Order Quantity", LibraryRandom.RandDec(10, 2));  // Minimum Order Quantity less than Reorder Point Quantity.
        Item.Validate("Maximum Order Quantity", MaximumInventory + LibraryRandom.RandDec(100, 2));  // Maximum Order Quantity more than Maximum Inventory.
        Item.Modify(true);
    end;

    local procedure CreateAndPostSalesOrderWithUpdatedQuantityToShip(var Item: Record Item; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity, LocationCode);
        UpdateQuantityToShipOnSalesLine(SalesLine, Item."Maximum Inventory");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship only.
    end;

    local procedure AcceptActionMessage(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
    end;

    local procedure AcceptAndCarryOutActionMessageForRequisitionWorksheet(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryVariableStorage.Enqueue(NewWorksheetMessage);  // Required inside MessageHandler.
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate, WorkDate, WorkDate, WorkDate, '');
    end;

    local procedure CalculatePlanForRequisitionWorksheet(var Item: Record Item)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName, RequisitionWkshName."Template Type"::"Req.");
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, WorkDate, WorkDate);
    end;

    local procedure CreateManufacturingItem(var Item: Record Item; ReorderingPolicy: Option; ReplenishmentSystem: Option)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo);
        Item.Modify(true);
    end;

    local procedure CreateLotForLotItemsSetup(var Item: Record Item; var ChildItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateManufacturingItem(ChildItem, ChildItem."Reordering Policy"::"Lot-for-Lot", ChildItem."Replenishment System"::Purchase);
        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem);
        CreateManufacturingItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase);
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name"; Type: Option)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, Type);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateRleasedProdOrderWithItemTracking(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; ItemTrackingMode: Option)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ItemNo, LibraryRandom.RandInt(10), '', '');

        // Assign Item Tracking On Production Order Line
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode);
        ProdOrderLine.OpenItemTrackingLines;
    end;

    local procedure CreateReleasedProdOrderWithManuallyScheduledRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
    begin
        LibraryInventory.CreateItem(Item);
        CreateRoutingWithSetupWaitAndMoveTime(RoutingHeader);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderRoutingLine.Validate("Schedule Manually", true);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure CreateAndPostOutputJnlWithUpdateQtyAndItemTracking(ProductionOrderNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExlpodeRouting(ItemJournalLine, ProductionOrderNo);
        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJournalLine.Modify(true);

        // Update the quantity on Item Tracking Line of Output Journal
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Update Quantity");
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);

        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateAndPostOutputJnlForProdOrderLine(ProdOrderLine: Record "Prod. Order Line"; RoutingNo: Code[20]; OperationNo: Code[10]; RunTime: Decimal; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProdOrderLine."Prod. Order No.");
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        ItemJournalLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJournalLine.Validate("Item No.", ProdOrderLine."Item No.");
        ItemJournalLine.Validate("Routing No.", RoutingNo);
        ItemJournalLine.Validate("Operation No.", OperationNo);
        ItemJournalLine.Validate("Run Time", RunTime);
        ItemJournalLine.Validate("Output Quantity", Quantity);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateTransferOrderWithQtyAndShipmentDate(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitLocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal; ShipmentDate: Date)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocationCode);
        TransferHeader.Validate("Posting Date", ShipmentDate);
        TransferHeader.Validate("Shipment Date", ShipmentDate);
        TransferHeader.Modify(true);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
    end;

    local procedure CreateStockkkeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; ItemNo: Code[20]; LocationCode: Code[10]; ManufacturingPolicy: Option)
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::"Prod. Order");
        StockkeepingUnit.Validate("Manufacturing Policy", ManufacturingPolicy);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CalcRegenPlanForPlanningWorksheetPage(var PlanningWorksheet: TestPage "Planning Worksheet"; ItemNo: Code[20]; ItemNo2: Code[20]; Accept: Boolean)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ProductionOrderType: Option " ",Planned,"Firm Planned","Firm Planned & Print";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryVariableStorage.Enqueue(ItemNo);  // Required for CalculatePlanPlanWkshRequestPageHandler.
        LibraryVariableStorage.Enqueue(ItemNo2);  // Required for CalculatePlanPlanWkshRequestPageHandler.
        Commit;  // Required for Test.
        OpenPlanningWorksheetPage(PlanningWorksheet, RequisitionWkshName.Name);
        PlanningWorksheet.CalculateRegenerativePlan.Invoke;  // Open report on Handler CalculatePlanPlanWkshRequestPageHandler.

        if Accept then begin
            // Accept Action Message and Carry Out Action Message
            LibraryVariableStorage.Enqueue(ProductionOrderType::"Firm Planned"); // Required for CarryOutActionMessageHandler.
            AcceptActionMessage(RequisitionLine, ItemNo);
            AcceptActionMessage(RequisitionLine, ItemNo2);
            Commit; // Required for Test.
            PlanningWorksheet.CarryOutActionMessage.Invoke; // Invoke Carry Out Action Message handler.
        end;
        PlanningWorksheet.OK.Invoke;
    end;

    local procedure DeleteProductionOrderComponent(ProductionOrderNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrderNo);
        ProdOrderComponent.Delete(true);
    end;

    local procedure FindProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20])
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindFirst;
    end;

    local procedure FindProdOrderComponentByItem(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        with ProdOrderComponent do begin
            SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
            SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
            SetRange("Item No.", ItemNo);
            FindFirst;
        end;
    end;

    local procedure FindProdOrderComponentByOrderNoAndItem(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst;
    end;

    local procedure FindProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst;
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Line No.");
        ProdOrderRoutingLine.FindFirst;
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Option; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet;
    end;

    local procedure FindProductionOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrderNo: Code[20])
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.FindFirst;
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20]; SourceDocument: Option; ActionType: Option)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceNo, SourceDocument, ActionType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; SourceDocument: Option; ActionType: Option)
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindSet;
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast then
            exit(RoutingLine."Operation No.");
    end;

    local procedure FindRegisteredWarehouseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; SourceDocument: Option; SourceNo: Code[20]; ActionType: Option)
    begin
        RegisteredWhseActivityLine.SetRange("Source Document", SourceDocument);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.FindSet;
    end;

    local procedure FilterFirmPlannedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20])
    begin
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.FindFirst;
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        FilterRequisitionLine(RequisitionLine, No);
        RequisitionLine.FindFirst;
    end;

    local procedure FindPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; RequisitionLine: Record "Requisition Line")
    begin
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
    end;

    local procedure FindFirstProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst;
    end;

    local procedure FindLastProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindLast;
    end;

    local procedure ValueEntryCalcSumsCostAmountActual(var ValueEntry: Record "Value Entry"; ItemNo: Code[20])
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.CalcSums("Cost Amount (Actual)");
    end;

    local procedure FilterRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
    end;

    local procedure OpenPlanningWorksheetPage(var PlanningWorksheet: TestPage "Planning Worksheet"; Name: Code[10])
    begin
        PlanningWorksheet.OpenEdit;
        PlanningWorksheet.CurrentWkshBatchName.SetValue(Name);
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; SourceDocument: Option; ActionType: Option)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, SourceNo, SourceDocument, ActionType);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst;
    end;

    local procedure SelectItemTrackingForProdOrderComponents(ItemNo: Code[20])
    var
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        ProdOrderComponents.OpenEdit;
        ProdOrderComponents.FILTER.SetFilter("Item No.", ItemNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries"); // Enqueue ItemTrackingMode for ItemTrackingPageHandler.
        ProdOrderComponents.ItemTrackingLines.Invoke;
    end;

    local procedure SelectRequisitionTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Type: Option)
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst;
    end;

    local procedure UpdateFlushingMethodOnProdComp(ProductionOrderNo: Code[20]; FlushingMethod: Option)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrderNo);
        ProdOrderComponent.Validate("Flushing Method", FlushingMethod);
        ProdOrderComponent.Modify(true);
    end;

    local procedure UpdateManufacturingSetupComponentsAtLocation(NewComponentsAtLocation: Code[10])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get;
        ManufacturingSetup.Validate("Components at Location", NewComponentsAtLocation);
        ManufacturingSetup.Modify(true);
    end;

    local procedure UpdateQuantityAndLotNoOnWarehouseActivityLine(ItemNo: Code[20]; ProductionOrderNo: Code[20]; ActionType: Option; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemNo);
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrderNo, WarehouseActivityLine."Source Document"::"Prod. Consumption", ActionType);
        WarehouseActivityLine.FindSet;
        repeat
            WarehouseActivityLine.Validate(Quantity, Quantity);
            WarehouseActivityLine.Validate("Lot No.", ItemLedgerEntry."Lot No.");
            WarehouseActivityLine.Modify(true);
            ItemLedgerEntry.Next;
        until WarehouseActivityLine.Next = 0;
    end;

    local procedure UpdateLocationSetup(var Location: Record Location; NewAlwaysCreatePickLine: Boolean) AlwaysCreatePickLine: Boolean
    begin
        AlwaysCreatePickLine := Location."Always Create Pick Line";
        Location.Validate("Always Create Pick Line", NewAlwaysCreatePickLine);
        Location.Modify(true);
    end;

    local procedure UpdateInventoryWithWhseItemJournal(var Item: Record Item; Location: Record Location; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Register the Warehouse Item Journal Lines.
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        CreateWarehouseJournalLine(Item, WarehouseJournalLine, Location, Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);

        // Calculate Warehouse adjustment and post Item Journal.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, '');  // Value required to avoid the Document No mismatch.
    end;

    local procedure UpdateBinCodeOnWarehouseActivityLine(SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
    begin
        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");
        FindWarehouseActivityLine(
          WarehouseActivityLine, SourceNo, WarehouseActivityLine."Source Document"::"Prod. Consumption",
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateUnitCostOnItem(var Item: Record Item)
    begin
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure UpdateRoutingOnItem(ItemNo: Code[20]; RoutingNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure UpdateRoutingStatus(var RoutingHeader: Record "Routing Header"; Status: Option)
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    local procedure UpdateRoutingLineSendAheadQty(RoutingNo: Code[20]; SendAheadQuantity: Decimal)
    var
        RoutingLine: Record "Routing Line";
        RoutingHeader: Record "Routing Header";
    begin
        RoutingHeader.Get(RoutingNo);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::"Under Development");
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindFirst;
        RoutingLine.Validate("Send-Ahead Quantity", SendAheadQuantity);
        RoutingLine.Modify(true);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure UpdateRoutingLinkOnProductionBOMLine(ProdItemNo: Code[20]; CompItemNo: Code[20]; RoutingLinkCode: Code[10])
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        Item.Get(ProdItemNo);
        ProductionBOMHeader.Get(Item."Production BOM No.");
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::"Under Development");
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.SetRange("No.", CompItemNo);
        ProductionBOMLine.FindFirst;
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure UpdateSetupTimeInProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; NewSetupTime: Decimal)
    begin
        ProdOrderRoutingLine.Validate("Setup Time", NewSetupTime);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure UpdateItemParametersForPlanning(var Item: Record Item)
    var
        Vendor: Record Vendor;
    begin
        Item.Find;  // Used to avoid the Transaction error.
        LibraryPurchase.CreateVendor(Vendor);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);
    end;

    local procedure UpdateItemParametersForPlanningWorksheet(var Item: Record Item; ManufacturingPolicy: Option; ReorderingPolicy: Option; ReplenishmentSystem: Option)
    begin
        with Item do begin
            Validate("Manufacturing Policy", ManufacturingPolicy);
            Validate("Reordering Policy", ReorderingPolicy);
            Validate("Replenishment System", ReplenishmentSystem);
            Modify(true);
        end
    end;

    local procedure UpdateQuantityOnRequisitionLine(var RequisitionLine: Record "Requisition Line"; Quantity: Decimal)
    begin
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.Modify(true);
    end;

    local procedure UpdateOrderTrackingPolicyOnItem(var Item: Record Item; OrderTrackingPolicy: Option)
    begin
        LibraryVariableStorage.Enqueue(TrackingMessage);  // Enqueue variable for use in MessageHandler.
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
    end;

    local procedure UpdateQuantityToShipOnSalesLine(var SalesLine: Record "Sales Line"; QtytoShip: Decimal)
    begin
        SalesLine.Validate("Qty. to Ship", QtytoShip);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQuantityOnProdOrderLine(ItemNo: Code[20]; Qty: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.Validate("Quantity (Base)", Qty);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateUOMOnProdBOMLine(ProdBOMNo: Code[20]; CompItemNo: Code[20]; QtyPerUoM: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, CompItemNo, QtyPerUoM);
        ProductionBOMHeader.Get(ProdBOMNo);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::"Under Development");
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.SetRange("No.", CompItemNo);
        ProductionBOMLine.FindFirst;
        ProductionBOMLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure UpdateUOMOnProdBOMLineByItemNo(ProdItemNo: Code[20]; CompItemNo: Code[20]; QtyPerUoM: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ProdItemNo);
        UpdateUOMOnProdBOMLine(Item."Production BOM No.", CompItemNo, QtyPerUoM);
    end;

    local procedure VerifyItemLedgerEntryCostAmountActual(EntryType: Option; ItemNo: Code[20]; CostAmountActual: Decimal; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreNearlyEqual(
          CostAmountActual, ItemLedgerEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(ValidationError, ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual));
        ItemLedgerEntry.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyProdOrderComponent(ProdOrderNo: Code[20]; Status: Option; ItemNo: Code[20]; ReservedQuantity: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindFirst;
        ProdOrderComponent.TestField(Status, Status);
        ProdOrderComponent.TestField("Item No.", ItemNo);
        ProdOrderComponent.CalcFields("Reserved Quantity");
        ProdOrderComponent.TestField("Reserved Quantity", ReservedQuantity);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Option; ItemNo: Code[20]; Quantity: Decimal; Tracking: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify the Item Ledger Entry has correct Quantity and has Tracking.
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        repeat
            ItemLedgerEntry.TestField(Quantity, Quantity);
            if Tracking then
                ItemLedgerEntry.TestField("Lot No.");
        until ItemLedgerEntry.Next = 0;
    end;

    local procedure VerifyProductionOrder(ProductionOrder: Record "Production Order"; Status: Option; Quantity: Decimal; DueDate: Date)
    begin
        ProductionOrder.Get(Status, ProductionOrder."No.");
        ProductionOrder.TestField(Quantity, Quantity);
        ProductionOrder.TestField("Due Date", DueDate);
    end;

    local procedure VerifyReservationQtyOnSalesLine(DocumentNo: Code[20]; ReservedQuantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst;
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", ReservedQuantity);
    end;

    local procedure VerifyWarehouseActivityLine(SourceNo: Code[20]; SourceDocument: Option; ItemNo: Code[20]; Quantity: Decimal; ActionType: Option)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceNo, SourceDocument, ActionType);
        repeat
            WarehouseActivityLine.TestField("Item No.", ItemNo);
            WarehouseActivityLine.TestField(Quantity, Quantity);
        until WarehouseActivityLine.Next = 0;
    end;

    local procedure VerifyPostedInventoryPickLine(SourceNo: Code[20]; ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        PostedInvtPickLine.SetRange("Source No.", SourceNo);
        PostedInvtPickLine.FindFirst;
        PostedInvtPickLine.TestField("Item No.", ItemNo);
        PostedInvtPickLine.TestField("Bin Code", BinCode);
        PostedInvtPickLine.TestField(Quantity, Quantity);
        PostedInvtPickLine.TestField("Location Code", LocationCode);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemNo);
        PostedInvtPickLine.TestField("Lot No.", ItemLedgerEntry."Lot No.");
    end;

    local procedure VerifyRegisteredWarehouseActivityLine(SourceDocument: Option; SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; ActionType: Option)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisteredWarehouseActivityLine(RegisteredWhseActivityLine, SourceDocument, SourceNo, ActionType);
        RegisteredWhseActivityLine.TestField("Item No.", ItemNo);
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyRevaluationJournalLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst;
        ItemJournalLine.TestField("Unit Cost (Revalued)", Item."Last Direct Cost");
        ItemJournalLine.TestField("Inventory Value (Revalued)", Round(Quantity * Item."Last Direct Cost"));
    end;

    local procedure VerifyCostAmountActualOnFinishedProductionOrderStatisticsPage(ProductionOrderNo: Code[20]; ActualCost: Decimal)
    var
        FinishedProductionOrder: TestPage "Finished Production Order";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
    begin
        FinishedProductionOrder.OpenEdit;
        FinishedProductionOrder.FILTER.SetFilter("No.", ProductionOrderNo);
        ProductionOrderStatistics.Trap;
        FinishedProductionOrder.Statistics.Invoke;
        ProductionOrderStatistics.MaterialCost_ActualCost.AssertEquals(ActualCost);
    end;

    local procedure VerifyRemainingQuantityOnProdOrderComponents(ProdOrderNo: Code[20]; Status: Option; ItemNo: Code[20]; RemainingQuantity: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        TotalRemainingQuantity: Decimal;
    begin
        FindProductionOrderComponent(ProdOrderComponent, ProdOrderNo);
        ProdOrderComponent.TestField(Status, Status);
        ProdOrderComponent.TestField("Item No.", ItemNo);
        TotalRemainingQuantity := CalculateRemainingQuantityOnProductionOrderComponent(ProdOrderNo);
        Assert.AreEqual(TotalRemainingQuantity, RemainingQuantity, ValidationError);
    end;

    local procedure VerifyRoutingOnAllocatedCapacity(ProductionOrder: Record "Production Order")
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderCapacityNeed.FindSet;
        repeat
            ProdOrderCapacityNeed.TestField("Routing No.", ProductionOrder."Routing No.");
            ProdOrderCapacityNeed.TestField("Work Center No.", ProdOrderRoutingLine."Work Center No.");
        until ProdOrderCapacityNeed.Next = 0;
    end;

    local procedure VerifyProductionOrderRoutingLine(ProductionOrderNo: Code[20]; RoutingNo: Code[20]; SendAheadQuantity: Decimal)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrderNo);
        ProdOrderRoutingLine.TestField("Routing No.", RoutingNo);
        ProdOrderRoutingLine.TestField("Send-Ahead Quantity", SendAheadQuantity);
    end;

    local procedure VerifyInputQuantityOnPlanningRoutingLine(RequisitionLine: Record "Requisition Line")
    var
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        FindPlanningRoutingLine(PlanningRoutingLine, RequisitionLine);
        PlanningRoutingLine.TestField("Input Quantity", RequisitionLine.Quantity);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; Quantity: Decimal; ReservationStatus: Option; Tracking: Boolean; Positive: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange(Positive, Positive);
        ReservationEntry.FindSet;
        repeat
            ReservationEntry.TestField(Quantity, Quantity);
            ReservationEntry.TestField("Reservation Status", ReservationStatus);
            if Tracking then
                ReservationEntry.TestField("Lot No.");
        until ReservationEntry.Next = 0;
    end;

    local procedure VerifyLocationAndQuantityOnPurchaseLine(No: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst;
        PurchaseLine.TestField("Location Code", LocationCode);
        PurchaseLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyRequisitionLine(No: Code[20]; ActionMessage: Option; Quantity: Decimal; LocationCode: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, No);
        RequisitionLine.TestField("Location Code", LocationCode);
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Action Message", ActionMessage);
    end;

    local procedure VerifyOrderTrackingForProductionOrder(ItemNo: Code[20]; Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        OrderTracking: Page "Order Tracking";
        OrderTracking2: TestPage "Order Tracking";
    begin
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        OrderTracking.SetProdOrderLine(ProdOrderLine);
        OrderTracking2.Trap;
        OrderTracking.Run;
        OrderTracking2."Item No.".AssertEquals(ItemNo);
        OrderTracking2.Quantity.AssertEquals(Quantity);
    end;

    local procedure VerifyProdOrderLine(ItemNo: Code[20]; Status: Option; Quantity: Decimal; FinishedQuantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField(Status, Status);
        ProdOrderLine.TestField(Quantity, Quantity);
        ProdOrderLine.TestField("Finished Quantity", FinishedQuantity);
    end;

    local procedure VerifyProdOrderLineWithLocationAndBin(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField("Location Code", LocationCode);
        ProdOrderLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyOneProdOrderLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        Assert.RecordCount(ProdOrderLine, 1);
        ProdOrderLine.TestField(Quantity, Quantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);  // Dequeue variable.
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::"Assign Lot No.":
                ItemTrackingLines."Assign Lot No.".Invoke;
            ItemTrackingMode::"Select Entries":
                ItemTrackingLines."Select Entries".Invoke;
            ItemTrackingMode::"Update Quantity":
                begin
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ItemTrackingLines."Quantity (Base)".SetValue(DequeueVariable);
                end;
        end;
        ItemTrackingLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanPlanWkshRequestPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    var
        ItemNo: Variant;
        ItemNo2: Variant;
    begin
        // Calculate Regenerative Plan on WORKDATE.
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(ItemNo2);
        CalculatePlanPlanWksh.Item.SetFilter("No.", StrSubstNo(ItemFilter, ItemNo, ItemNo2));
        CalculatePlanPlanWksh.MRP.SetValue(true);  // Use MRP True.
        CalculatePlanPlanWksh.StartingDate.SetValue(WorkDate);
        CalculatePlanPlanWksh.EndingDate.SetValue(WorkDate);
        CalculatePlanPlanWksh.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationEntriesModalPageHandler(var ReservationEntries: TestPage "Reservation Entries")
    begin
        LibraryVariableStorage.Enqueue(CancelReservationTxt);
        ReservationEntries.CancelReservation.Invoke;
        ReservationEntries.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, ConfirmMessage);
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CarryOutActionMessageHandler(var CarryOutActionMsgPlan: TestRequestPage "Carry Out Action Msg. - Plan.")
    var
        ProductionOrderType: Variant;
    begin
        LibraryVariableStorage.Dequeue(ProductionOrderType);
        CarryOutActionMsgPlan.ProductionOrder.SetValue(ProductionOrderType); // Production Order field of page.
        CarryOutActionMsgPlan.OK.Invoke;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure AllLevelsStrMenuHandler(StrMenuText: Text; var Choice: Integer; InstructionText: Text)
    begin
        Choice := 2; // All levels
    end;
}

