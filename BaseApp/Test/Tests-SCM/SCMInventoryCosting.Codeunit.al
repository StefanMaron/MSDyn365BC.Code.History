codeunit 137007 "SCM Inventory Costing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
    end;

    var
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        AverageCostCalcType: Option " ",Item,"Item & Location & Variant";
        AverageCostPeriod: Option " ",Day,Week,Month,Quarter,Year,"Accounting Period";
        CalculatePerValues: Option "Item Ledger Entry",Item;
        CalculationBaseValues: Option " ","Last Direct Unit Cost","Standard Cost - Assembly List","Standard Cost - Manufacturing";
        isInitialized: Boolean;
        ErrMessageGLEntryNoRowExist: Label 'G/L Entry for WIP Account must not exist.';
        ErrMessageInvAmountDoNotMatch: Label 'The Inventory amount totals must be equal.';
        StandardCostRolledUpMessage: Label 'The standard costs have been rolled up successfully';
        AutomaticCostPostingMessage: Label 'The field Automatic Cost Posting should not be set to Yes';
        BOMStructureErr: Label 'The BOM Structure should contain only one line for Item';
        QtyPerTopItemErr: Label 'The field Qty. Per Top Item is not correct.';
        PlanningComponentErr: Label 'Planning Component is not correct for Sales Order %1 ';
        IncorrectCostPostedToGLErr: Label 'Incorrect Cost Posted to G/L.';
        UnexpectedCostAmtErr: Label '%1 does not match %2 posted by Revaluation Journal.', Comment = '%1: Field(Cost Amount (Actual)), %2: Field(Inventory Value (Revalued))';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';

    [Test]
    [Scope('OnPrem')]
    procedure PostCostYes()
    begin
        // Covers documents 3477.
        // Automatic Cost Post True.
        FIFOAutomaticCostPostToGL(true, true, false, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PostCostNo()
    begin
        // Covers documents 3478.
        // Automatic Cost Post False.
        FIFOAutomaticCostPostToGL(false, true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCostYesCostDiff()
    begin
        // Covers documents 3479.
        // Automatic Cost Post True,Fasle if Cost different from expected.
        FIFOAutomaticCostPostToGL(true, false, false, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PostCostNoCostDiff()
    begin
        // Covers documents 3480.
        // Automatic Cost Post False, False if Cost different from expected.
        FIFOAutomaticCostPostToGL(false, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCostYesPartialRecvInv()
    begin
        // Covers documents 3481.
        // Automatic Cost Post True, partial receive and Invoice of Purchase Order.
        FIFOAutomaticCostPostToGL(true, true, true, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PostCostNoPartialRecvInv()
    begin
        // Covers documents 3482.
        // Automatic Cost Post False, partial receive and Invoice of Purchase Order.
        FIFOAutomaticCostPostToGL(false, true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCostYesTwicePartialRecvInv()
    begin
        // Covers documents 3483.
        // Automatic Cost Post True, twice partial receive and Invoice of Purchase Order.
        FIFOAutomaticCostPostToGL(true, true, true, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PostCostNoTwicePartialRecvInv()
    begin
        // Covers documents 3484.
        // Automatic Cost Post False, twice partial receive and Invoice of Purchase Order.
        FIFOAutomaticCostPostToGL(false, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderLineAfterUpdateUnitCostOnComponent()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        ChildItem: Record Item;
        UnitAmount: Decimal;
        CalcMethod: Option "One Level","All Levels";
    begin
        // Setup: Create Parent and Child Items in a Production BOM and certify it. Create Released Production Order and Refresh it. Create and Post Item Journal line with Unit Amount.
        Initialize;
        CreateItemsSetup(Item, ChildItem);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.");
        UnitAmount := CreateAndPostItemJournalLine(ChildItem."No.", ProductionOrder.Quantity, '');

        // Exercise: Run Update Unit Cost batch Report.
        LibraryCosting.UpdateUnitCost(ProductionOrder, CalcMethod::"One Level", false);

        // Verify: Verify that Unit Cost on Prod. Order Line is updated from Child Item Unit Amount.
        VerifyUnitCostInProductionOrderLine(ProductionOrder, UnitAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RollUpStandardCostWithProdBOMVersionClosed()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup.
        Initialize;
        RollUpStandardCostWithDifferentVersionStatus(ProductionBOMVersion.Status::Closed, true);  // Prod BOM Version as True.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RollUpStandardCostWithProdBOMVersionUnderDevelopment()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup.
        Initialize;
        RollUpStandardCostWithDifferentVersionStatus(ProductionBOMVersion.Status::"Under Development", true);  // Prod BOM Version as True.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RollUpStandardCostWithProdBOMVersionNew()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup.
        Initialize;
        RollUpStandardCostWithDifferentVersionStatus(ProductionBOMVersion.Status::New, true);  // Prod BOM Version as True.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RollUpStandardCostWithProdBOMVersionCertified()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup.
        Initialize;
        RollUpStandardCostWithDifferentVersionStatus(ProductionBOMVersion.Status::Certified, true);  // Prod BOM Version as True.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RollUpStandardCostWithRoutingVersionClosed()
    var
        RoutingVersion: Record "Routing Version";
    begin
        // Setup.
        Initialize;
        RollUpStandardCostWithDifferentVersionStatus(RoutingVersion.Status::Closed, false);  // Prod BOM Version as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RollUpStandardCostWithRoutingVersionUnderDevelopment()
    var
        RoutingVersion: Record "Routing Version";
    begin
        // Setup.
        Initialize;
        RollUpStandardCostWithDifferentVersionStatus(RoutingVersion.Status::"Under Development", false);  // Prod BOM Version as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RollUpStandardCostWithRoutingVersionNew()
    var
        RoutingVersion: Record "Routing Version";
    begin
        // Setup.
        Initialize;
        RollUpStandardCostWithDifferentVersionStatus(RoutingVersion.Status::New, false);  // Prod BOM Version as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RollUpStandardCostWithRoutingVersionCertified()
    var
        RoutingVersion: Record "Routing Version";
    begin
        // Setup.
        Initialize;
        RollUpStandardCostWithDifferentVersionStatus(RoutingVersion.Status::Certified, false);  // Prod BOM Version as False.
    end;

    local procedure RollUpStandardCostWithDifferentVersionStatus(VersionStatus: Option; ProdBOMVersion: Boolean)
    var
        Item: Record Item;
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        RoutingHeader: Record "Routing Header";
        ChildItem: Record Item;
        StandardCostWkshName: Code[10];
    begin
        // Create Item and Production BOM.
        CreateItemsSetup(Item, ChildItem);
        UpdateStandardCostOnItem(Item);

        // Create Production BOM Version and update Status or create Routing Setup, Routing Version and update Status.
        if ProdBOMVersion then
            CreateProductionBOMVersionAndUpdateStatus(Item."Production BOM No.", VersionStatus)
        else begin
            CreateRoutingSetup(RoutingHeader);
            UpdateRoutingNoOnItem(Item, RoutingHeader."No.");
            CreateRoutingVersionAndUpdateStatus(RoutingHeader, VersionStatus);
        end;

        // Create Standard Cost Worksheet Name. Run Suggest Item Standard Cost and update New Standard Cost value.
        StandardCostWkshName := CreateAndUpdateStandardCostWorksheet(Item);
        LibraryVariableStorage.Enqueue(StandardCostRolledUpMessage);

        // Exercise: Run Roll Up Standard Cost.
        LibraryManufacturing.RunRollUpStandardCost(Item, StandardCostWkshName);

        // Verify: Verify that Roll Up Standard Cost run without any error and verify New Standard Cost on Standard Cost Worksheet.
        FindStandardCostWorksheet(StandardCostWorksheet, StandardCostWkshName, Item."No.");
        StandardCostWorksheet.TestField("New Standard Cost", 0);  // Value required.
    end;

    [Test]
    [HandlerFunctions('BOMStructurePageHandler')]
    [Scope('OnPrem')]
    procedure BOMStructureWithMultipleBOMVersion()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMVersion2: Record "Production BOM Version";
        ProductionBOMHeader: Record "Production BOM Header";
        ChildItemNo: array[2] of Code[20];
        i: Integer;
    begin
        // Verify BOM Structure shows correct Active Version with Starting Date = Work Date when there are different BOM Versions with different Starting Date.

        // Setup: Create certified BOM with Item. Create other two items.
        CreateItemsSetup(Item, ChildItem);
        for i := 1 to 2 do
            ChildItemNo[i] := LibraryInventory.CreateItem(ChildItem);

        // Create Production BOM Version with diffrent Starting Date.
        ProductionBOMHeader.Get(Item."Production BOM No.");
        CreateProdBOMVersionWithStartingDate(
          ProductionBOMVersion, ProductionBOMHeader, Item."Base Unit of Measure", ChildItemNo[1], WorkDate);
        CreateProdBOMVersionWithStartingDate(
          ProductionBOMVersion2, ProductionBOMHeader, Item."Base Unit of Measure", ChildItemNo[2],
          CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate));

        // Exercise: Run BOM Structure page.
        // Verify: Verify BOM Structure in BOMStructurePageHandler Handler.
        LibraryVariableStorage.Enqueue(ChildItemNo[1]);
        RunBOMStructurePage(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BOMStructureWithProductionBOMTypeComponent()
    var
        Item: Record Item;
        Item2: Record Item;
        QtyPerTopItem: Integer;
    begin
        // Verify BOM Structure shows correct "Qty. Per Top Item" when there is Production Item with Production BOM Type component.

        // Setup: Create Production BOM with Production BOM Type component, Create item with the Production BOM.
        QtyPerTopItem := CreateItemsSetupWithProductionBOMTypeComponent(Item, Item2);

        // Exercise: Create BOM Tree on BOM Buffer to show the data in BOM Structure page
        // due to "Qty. Per Top Item" in BOM Structure page is hidden by default.
        CreateBOMTree(Item);

        // Verify: Verify the field Qty. Per Top Item on BOM Buffer.
        VerifyQtyPerTopItemOnBOMBuffer(Item2."No.", QtyPerTopItem);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentIsActiveBOMVersionInOrderPlanning()
    var
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        ChildItem2: Record Item;
        Item: Record Item;
        PlanningComponent: Record "Planning Component";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        SalesHeader: Record "Sales Header";
    begin
        // Test Component Item is from Active BOM version when running Order Planning

        // Setup: Create Item with Production BOM
        Initialize;
        CreateItemsSetup(Item, ChildItem);
        ProductionBOMHeader.Get(Item."Production BOM No.");

        // Create a new Production BOM Version with diffrent Child Item and Starting Date.
        LibraryInventory.CreateItem(ChildItem2);
        CreateProdBOMVersionWithStartingDate(
          ProductionBOMVersion, ProductionBOMHeader, Item."Base Unit of Measure", ChildItem2."No.",
          CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate));

        // Create a Sales Order
        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandDec(20, 2));

        // Exercise: Calculate Plan in Order Planning
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify: Component Item is Active BOM version item
        PlanningComponent.SetRange("Item No.", ChildItem2."No.");
        Assert.IsFalse(PlanningComponent.IsEmpty, StrSubstNo(PlanningComponentErr, SalesHeader."No."));
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PostCostToGLAfterDropExpectCostPostingToGL()
    var
        Item: Record Item;
        CostAmount: Decimal;
    begin
        // Test expected cost is posted to G/L after implementing RFH 245349

        // Setup
        Initialize;

        // set "Expected Cost Posting to G/L" = Yes
        LibraryInventory.SetExpectedCostPosting(true);
        // create item and make a few incoming operations without posting cost to G/L
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Standard);
        CreatePostPositiveAdjustment(Item, LibraryRandom.RandInt(10));
        CreatePostRevaluation(Item, CostAmount);
        LibraryInventory.SetExpectedCostPosting(false);

        // Exercise: run report Post Inventory Cost to G/L
        LibraryVariableStorage.Enqueue(ValueEntriesWerePostedTxt);
        LibraryCosting.PostInvtCostToGL(false, WorkDate, '');

        // Verify:
        VerifyValueEntryCostPostedToGL(Item."No.", CostAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestItemStandardCostCopiesCostsFromItemCardMfgItem()
    var
        Item: Record Item;
        StandardCostWkshName: Code[10];
    begin
        // [FEATURE] [Standard Cost Worksheet] [Suggest Item Standard Cost]
        // [SCENARIO 377601] "Suggest Item Standard Cost" should copy manufacturing costs from item card if item's replenishment system is "Prod. Order"

        // [GIVEN] Create item with replenishment system = "Prod. Order"
        MockItemWithManufacturingCosts(Item, Item."Replenishment System"::"Prod. Order");

        // [WHEN] Open standard cost worksheet and run "Suggest Item Standard Cost"
        StandardCostWkshName := CreateAndUpdateStandardCostWorksheet(Item);
        LibraryCosting.SuggestItemStandardCost(Item, StandardCostWkshName, 1, '');

        // [THEN] Manufacturing cost components are copied from item card
        VerifyStdCostWorksheet(StandardCostWkshName, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestItemStandardCostZeroCostsPurchasedItem()
    var
        Item: Record Item;
        StandardCostWkshName: Code[10];
    begin
        // [FEATURE] [Standard Cost Worksheet] [Suggest Item Standard Cost]
        // [SCENARIO 377601] "Suggest Item Standard Cost" should copy standard cost from item card and leave other costs 0 if item's replenishment system is "Purchase"

        // [GIVEN] Create item with replenishment system = "Purchase"
        MockItemWithManufacturingCosts(Item, Item."Replenishment System"::Purchase);

        // [WHEN] Open standard cost worksheet and run "Suggest Item Standard Cost"
        StandardCostWkshName := CreateAndUpdateStandardCostWorksheet(Item);
        LibraryCosting.SuggestItemStandardCost(Item, StandardCostWkshName, 1, '');

        // [THEN] Standard cost amount is copied from item card, other cost components are 0
        VerifyStdCostWorksheetPurchItem(StandardCostWkshName, Item."No.", Item."Standard Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevaluateItemWithAvgCostingMethodAndBigStockQuantityWhenAvgCalcIsBasedOnItem()
    var
        ItemJournalLine: Record "Item Journal Line";
        RevaluedAmount: Decimal;
    begin
        // [FEATURE] [Revaluation] [Average Costing Method]
        // [SCENARIO 379224] Cost Amount of Item with Average Costing Method and big Inventory should be equal to what was posted by Revaluation Journal. Average Cost is calculated by Item.
        Initialize;

        LibraryInventory.SetAverageCostSetup(AverageCostCalcType::Item, AverageCostPeriod::Week);

        // [GIVEN] Item with Average Costing Method and big Inventory.
        // [GIVEN] Calculated Inventory Value by Item in Revaluation Journal, "Inventory Value (Revalued)" field is updated to 'R'.
        CreateAndRevalueInventory(ItemJournalLine, RevaluedAmount, false, false);

        // [WHEN] Post Revaluation.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Sum of "Cost Amount (Actual)" in Value Entry is equal to 'R'.
        VerifyValueEntryCostAmount(ItemJournalLine, RevaluedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevaluateItemWithAvgCostingMethodAndBigStockQuantityWhenAvgCalcIsBasedOnItemLocVar()
    var
        ItemJournalLine: Record "Item Journal Line";
        RevaluedAmount: Decimal;
    begin
        // [FEATURE] [Revaluation] [Average Costing Method]
        // [SCENARIO 379224] Cost Amount of Item with Average Costing Method and big Inventory should be equal to what was posted by Revaluation Journal. Average Cost is calculated by Item & Location & Variant.
        Initialize;

        LibraryInventory.SetAverageCostSetup(AverageCostCalcType::"Item & Location & Variant", AverageCostPeriod::Week);

        // [GIVEN] Item with Average Costing Method and big Inventory.
        // [GIVEN] Calculated Inventory Value by Item & Location & Variant in Revaluation Journal, "Inventory Value (Revalued)" field is updated to 'R'.
        CreateAndRevalueInventory(ItemJournalLine, RevaluedAmount, true, true);

        // [WHEN] Post Revaluation.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Sum of "Cost Amount (Actual)" in Value Entry is equal to 'R'.
        VerifyValueEntryCostAmount(ItemJournalLine, RevaluedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostDoesNotUpdateSKULastDirectCost()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        UnitCost: array[2] of Decimal;
    begin
        // [FEATURE] [Transfer] [Adjust Cost - Item Entries] [Last Direct Cost] [Stockkeeping Unit]
        // [SCENARIO 379749] "Adjust Cost - Item Entries" should not not update last direct cost of a stockkeeping unit

        Initialize;

        // [GIVEN] Item "I" with Average costing method
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Average);

        // [GIVEN] Two locations "L1" and "L2" with stockkeeping unit for item "I" on each location ("SKU1" and "SKU2")
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        Item.SetRecFilter;
        Item.SetFilter("Location Filter", '%1|%2', Location[1].Code, Location[2].Code);
        LibraryInventory.CreateStockKeepingUnit(Item, 0, false, true); // Create stockkeeping units per location

        // [GIVEN] Post item stock on location "L1". Unit cost = "X1"
        UnitCost[1] := CreateAndPostItemJournalLine(Item."No.", LibraryRandom.RandInt(10), Location[1].Code);
        // [GIVEN] Post item stock on location "L2". Unit cost = "X2"
        UnitCost[2] := CreateAndPostItemJournalLine(Item."No.", LibraryRandom.RandInt(10), Location[2].Code);

        // [GIVEN] Transfer item from location "L1" to location "L2"
        CreatePostTransferJournalLine(Item."No.", 1, Location[1].Code, Location[2].Code);

        // [WHEN] Run "Adjust Cost - Item Entries"
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Last direct cost in "SKU1" = "X1", Last direct cost in "SKU2" = "X2"
        VerifySKULastDirectCost(Item."No.", Location[1].Code, UnitCost[1]);
        VerifySKULastDirectCost(Item."No.", Location[2].Code, UnitCost[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SKUUnitCostIsUpdatedByTransferWithAvgCostCalcTypeItem()
    var
        Item: Record Item;
        Location: array[3] of Record Location;
        UnitAmount: Decimal;
    begin
        // [FEATURE] [Transfer] [Last Direct Cost] [Stockkeeping Unit]
        // [SCENARIO 170483] "Unit Cost" of the stockkeeping unit is updated by transfer order when average cost calc. type = Item

        Initialize;

        // [GIVEN] Set "Average Cost Calcultion Type" = "Item"
        LibraryInventory.SetAverageCostSetup(AverageCostCalcType::Item, AverageCostPeriod::Day);

        // [GIVEN] Item "I" with 2 stockkeeping units on locations "L1" and "L2"
        CreateItemAndLocationSetup(Item, Location);

        // [GIVEN] Item "I" is purchased on location "L1" with unit cost = "X" and location "L2", unit cost = "Y"
        UnitAmount := CreateAndPostItemJournalLine(Item."No.", LibraryRandom.RandIntInRange(50, 100), Location[1].Code);
        CreateAndPostItemJournalLine(Item."No.", LibraryRandom.RandInt(100), Location[2].Code);

        // [WHEN] Item "I" is transferred from location "L1" to location "L2"
        CreateAndPostTransferOrder(Location[1].Code, Location[2].Code, Location[3].Code, Item."No.", LibraryRandom.RandInt(50));

        // [THEN] Unit cost of SKU on location "L2" is "X"
        VerifySKUUnitCost(Item."No.", Location[2].Code, UnitAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SKUUnitCostIsNotUpdatedByTransferWithAvgCostCalcTypeItemLocationVariant()
    var
        Item: Record Item;
        Location: array[3] of Record Location;
        UnitAmount: Decimal;
    begin
        // [FEATURE] [Transfer] [Last Direct Cost] [Stockkeeping Unit]
        // [SCENARIO 170483] "Unit Cost" of the stockkeeping unit is not updated by transfer order when average cost calc. type = "Item & Location & Variant"
        Initialize;

        // [GIVEN] Set "Average Cost Calcultion Type" = "Item & Location & Variant"
        LibraryInventory.SetAverageCostSetup(AverageCostCalcType::"Item & Location & Variant", AverageCostPeriod::Day);

        // [GIVEN] Item "I" with 2 stockkeeping units on locations "L1" and "L2"
        CreateItemAndLocationSetup(Item, Location);

        // [GIVEN] Item "I" is purchased on location "L1" with unit cost = "X" and location "L2", unit cost = "Y"
        CreateAndPostItemJournalLine(Item."No.", LibraryRandom.RandIntInRange(50, 100), Location[1].Code);
        UnitAmount := CreateAndPostItemJournalLine(Item."No.", LibraryRandom.RandInt(100), Location[2].Code);

        // [WHEN] Item "I" is transferred from location "L1" to location "L2"
        CreateAndPostTransferOrder(Location[1].Code, Location[2].Code, Location[3].Code, Item."No.", LibraryRandom.RandInt(50));

        // [THEN] Unit cost of SKU on location "L2" is "Y"
        VerifySKUUnitCost(Item."No.", Location[2].Code, UnitAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliedToAdjustRemovedWhenInboundInvoicedAndOpenOutboundHasOtherCostSource()
    var
        Item: Record Item;
        Location: array[3] of Record Location;
        PurchaseHeader: array[2] of Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        PurchInvoiceNo: Code[20];
    begin
        // [FEATURE] [Adjust Cost - Item Entries]
        // [SCENARIO 380442] "Applied Enry to Adjust" mark should be removed when the entry is closed and invoiced, and all open applied outbounds have other cost sources

        Initialize;
        // [GIVEN] Item "I" with FIFO costing method
        CreateItemWithCostingMethod(Item, Item."Costing Method"::FIFO);

        // [GIVEN] Two locations "L1" and "L2", and a transit location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        LibraryWarehouse.CreateInTransitLocation(Location[3]);

        // [GIVEN] Purchase 3 pcs of item "I" on location "L1". Unit cost = 2.4875. Receive only.
        CreatePurchaseOrderPostReceipt(PurchaseHeader[1], LibraryPurchase.CreateVendorNo, Location[1].Code, Item."No.", 3, 2.4875);
        // [GIVEN] Purchase 3 pcs of item "I" on location "L2". Unit cost = 2.48827. Receive only.
        CreatePurchaseOrderPostReceipt(PurchaseHeader[2], PurchaseHeader[1]."Buy-from Vendor No.", Location[1].Code, Item."No.", 3, 2.48827);

        // [GIVEN] Create a transfer order from location "L1" to "L2". Split transfer into 5 lines with quantitues: 1, 1, 2, 1, 1
        // [GIVEN] Post transfer
        LibraryInventory.CreateTransferHeader(TransferHeader, Location[1].Code, Location[2].Code, Location[3].Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 2);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [GIVEN] Invoice the first purchase order
        PurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], false, true);

        // [WHEN] Run cost adjustment
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] First receipt item ledger entry is rounded
        // [THEN] Receipt entry is not marked as "Applied entry to adjust"
        VerifyAppliedEntryToAdjust(Item."No.");
        VerifyItemLedgerEntryRounding(PurchInvoiceNo);

        // [WHEN] Invoice remaining purchase quantity, adjust cost
        PurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], false, true);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Second receipt item ledger entry is rounded
        VerifyAppliedEntryToAdjust(Item."No.");
        VerifyItemLedgerEntryRounding(PurchInvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSelectedStdCostWorksheetNameIsSaved()
    var
        StdCostWorksheetName: Record "Standard Cost Worksheet Name";
        StandardCostWorksheet: TestPage "Standard Cost Worksheet";
    begin
        // [FEATURE] [Standard Cost Worksheet] [UI]
        // [SCENARIO 210317] Standard Cost Worksheet (SCW) is opened with last selected SCW Name.
        Initialize;

        // [GIVEN] New SCW Name "X" is created.
        LibraryInventory.CreateStandardCostWorksheetName(StdCostWorksheetName);

        // [GIVEN] SCW Name is updated to "X" on the worksheet, and the page is closed.
        StandardCostWorksheet.OpenEdit;
        StandardCostWorksheet.CurrWkshName.SetValue(StdCostWorksheetName.Name);
        StandardCostWorksheet.Close;

        // [WHEN] Open SCW page again.
        StandardCostWorksheet.OpenView;

        // [THEN] SCW Name on the page = "X".
        StandardCostWorksheet.CurrWkshName.AssertEquals(StdCostWorksheetName.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdCostWorksheetIsOpenedWithFirstFoundNameIfSavedNameDeleted()
    var
        StdCostWorksheetName: Record "Standard Cost Worksheet Name";
        StandardCostWorksheet: TestPage "Standard Cost Worksheet";
    begin
        // [FEATURE] [Standard Cost Worksheet] [UI]
        // [SCENARIO 210317] Standard Cost Worksheet (SCW) is opened with the first found SCW Name is the last used SCW Name has been deleted.
        Initialize;

        // [GIVEN] New SCW Name "X" is created.
        LibraryInventory.CreateStandardCostWorksheetName(StdCostWorksheetName);

        // [GIVEN] SCW Name is updated to "X" on the worksheet, and the page is closed.
        StandardCostWorksheet.OpenEdit;
        StandardCostWorksheet.CurrWkshName.SetValue(StdCostWorksheetName.Name);
        StandardCostWorksheet.Close;

        // [GIVEN] Delete "X".
        StdCostWorksheetName.Delete(true);

        // [WHEN] Open SCW page again.
        StandardCostWorksheet.OpenView;

        // [THEN] SCW Name on the page is equal to the first found SCW Name on the table.
        StdCostWorksheetName.FindFirst;
        StandardCostWorksheet.CurrWkshName.AssertEquals(StdCostWorksheetName.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdCostWorksheetIsOpenedWithDefaultNameIfAllNamesDeleted()
    var
        StdCostWorksheetName: Record "Standard Cost Worksheet Name";
        StandardCostWorksheet: TestPage "Standard Cost Worksheet";
    begin
        // [FEATURE] [Standard Cost Worksheet] [UI]
        // [SCENARIO 210317] Standard Cost Worksheet (SCW) Name with Name = 'DEFAULT' is created when SCW is opened and no SCW Name existed.
        Initialize;

        // [GIVEN] Delete all SCW names.
        StdCostWorksheetName.DeleteAll(true);

        // [WHEN] Open SCW page.
        StandardCostWorksheet.OpenEdit;

        // [THEN] SCW Name on the page is equal to the default name.
        StdCostWorksheetName.FindFirst;
        StdCostWorksheetName.TestField(Name, UpperCase('Default'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdCostWorksheetIsOpenedWithSelectedNameOnEditWorksheetAction()
    var
        StdCostWorksheetName: Record "Standard Cost Worksheet Name";
        StandardCostWorksheet: TestPage "Standard Cost Worksheet";
        StandardCostWorksheetNames: TestPage "Standard Cost Worksheet Names";
    begin
        // [FEATURE] [Standard Cost Worksheet] [UI]
        // [SCENARIO 210317] Standard Cost Worksheet (SCW) is opened with selected SCW Name when Edit Worksheet is invoked on SCW Names page.
        Initialize;

        // [GIVEN] New SCW Name "X" is created.
        LibraryInventory.CreateStandardCostWorksheetName(StdCostWorksheetName);

        // [GIVEN] "X" is selected on SCW Names page.
        StandardCostWorksheetNames.OpenView;
        StandardCostWorksheetNames.FILTER.SetFilter(Name, StdCostWorksheetName.Name);

        // [WHEN] Click "Edit Worksheet" on the page.
        StandardCostWorksheet.Trap;
        StandardCostWorksheetNames.EditWorksheet.Invoke;

        // [THEN] SCW is opened. SCW Name on the worksheet is equal to "X".
        StandardCostWorksheet.CurrWkshName.AssertEquals(StdCostWorksheetName.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRevaluationWithPurchInvoiceBeforeReceipt()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        UnitCostOriginal: Decimal;
        UnitCostRevalued: Decimal;
        Quantity: Integer;
    begin
        // [FEATURE] [Revaluation]
        // [SCENARIO 206777] Item revaluation can be posted when a purchase order invoiced on a revaluation date has a receipt in a later period

        Initialize;

        LibraryInventory.SetAverageCostSetup(AverageCostCalcType::Item, AverageCostPeriod::Day);

        // [GIVEN] Item "I" with Average costing method, Unit Cost = 100
        UnitCostOriginal := LibraryRandom.RandDec(100, 2);
        UnitCostRevalued := UnitCostOriginal + LibraryRandom.RandDec(50, 2);
        Quantity := LibraryRandom.RandInt(20);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Validate("Unit Cost", UnitCostOriginal);
        Item.Validate("Last Direct Cost", UnitCostOriginal);
        Item.Modify(true);

        // [GIVEN] Purchase order for 10 pcs of item "I". Posting Date = 01/01/17. Post receipt without invoicing.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Posting Date", WorkDate + 1);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Invoice the purchase on 31/12/16
        PurchaseHeader.Validate("Posting Date", WorkDate);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID);
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Post positive adjustment for another 10 pcs of item "I" on 31/12/16
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Run cost adjustment to be able to revalue the item
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Calculate inventory value for item "I" on 31/12/16, set "Unit Cost (Revalued)" = 150, and post revaluation
        CreatePostRevaluation(Item, UnitCostRevalued);

        // [THEN] "Cost Amount (Actual)" on 31/12/16 is 150 * 10 = 1500 - revalued
        // [THEN] "Cost Amount (Actual)" on 01/01/17 is 100 * 10 = 1000 - not revalued
        VerifyActualCostAmount(ItemJournalLine."Item No.", WorkDate, UnitCostRevalued * Quantity);
        VerifyActualCostAmount(ItemJournalLine."Item No.", WorkDate + 1, UnitCostOriginal * Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcInvValueManufCalcBase()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        TotalQuantity: Decimal;
    begin
        // [FEATURE] [Costing] [Revaluation]
        // [SCENARIO 230443] Running calculating inventory function in revaluation journal shouldn't cause an error message about existing SKU

        Initialize;

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create stock for new item
        Quantity := LibraryRandom.RandInt(100);
        CreateAndPostItemJournalLine(Item."No.", Quantity, '');
        TotalQuantity += Quantity;

        // [GIVEN] Create another stock entry for the same item
        Quantity := LibraryRandom.RandInt(100);
        CreateAndPostItemJournalLine(Item."No.", Quantity, '');
        TotalQuantity += Quantity;

        // [WHEN] Calling calculate inventory value function
        CreateRevalutionJournal(Item, ItemJournalLine, false, false,
          CalculatePerValues::"Item Ledger Entry", CalculationBaseValues::"Standard Cost - Manufacturing");

        ItemJournalLine.CalcSums(Quantity);

        // [THEN] Total quantity of revaluation journal for the item must be equal to whole stock of the item
        ItemJournalLine.TestField(Quantity, TotalQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInitInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [UT] [Adjust Cost Item Entries]
        // [SCENARIO 255365] Default value for "Average Cost Calc. Type" in inventory setup should be "Item & Location & Variant"

        InventorySetup.Init;
        InventorySetup.TestField("Average Cost Calc. Type", InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Costing");
        // Initialize setup.
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Costing");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateSalesReceivablesSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Costing");
    end;

    local procedure FIFOAutomaticCostPostToGL(AutomaticCostPosting: Boolean; CostExpected: Boolean; PartialRecvInv: Boolean; MultiplePartialRecvInv: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ItemNo3: Code[20];
        FlushingMethod: Option Manual,Forward,Backward;
    begin
        // Steps describing the sequence of actions for Test Case.

        // 1. Create required Inventory setups.
        // Update Inventory Setup True if Automatic cost posting.
        Initialize;
        LibraryVariableStorage.Enqueue(AutomaticCostPostingMessage);  // Enqueue for Message Handler.
        LibraryERM.SetUseLegacyGLEntryLocking(AutomaticCostPosting);

        LibraryInventory.SetAutomaticCostPosting(AutomaticCostPosting);
        LibraryInventory.SetExpectedCostPosting(false);
        LibraryInventory.SetAutomaticCostAdjmtNever;
        LibraryInventory.SetAverageCostSetup(AverageCostCalcType::Item, AverageCostPeriod::Day);

        // Create Items with Costing Method FIFO, False if Cost is different from expected.
        CreateItem(Item, Item."Costing Method"::FIFO, Item."Reordering Policy"::"Lot-for-Lot", FlushingMethod::Forward, '', '', CostExpected);
        ItemNo := Item."No.";
        Clear(Item);
        CreateItem(Item, Item."Costing Method"::FIFO, Item."Reordering Policy"::"Lot-for-Lot", FlushingMethod::Forward, '', '', CostExpected);
        ItemNo2 := Item."No.";
        Clear(Item);
        CreateItem(Item, Item."Costing Method"::FIFO, Item."Reordering Policy"::"Lot-for-Lot", FlushingMethod::Forward, '', '', CostExpected);
        ItemNo3 := Item."No.";

        // 2.1 Execute: Create and Post Purchase Order, True if partial receive and Invoice.
        // Post Inventory Cost to GL if Automatic Cost Posting True.
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, ItemNo, ItemNo2, ItemNo3, LibraryRandom.RandInt(100) + 50, PartialRecvInv);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        if not AutomaticCostPosting then
            LibraryCosting.PostInvtCostToGL(false, WorkDate, '');

        // 3.1 Verify: Verify General Ledger Entries that WIP Account does not exist and Total Inventory amount equals calculated amount.
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst;
        VerifyInvtAmountGLEntry(PurchInvHeader."No.", ItemNo);

        // 2.2. Execute: Update and Post Purchase Order with Partial Quantity.
        // Post Inventory Cost to GL if Automatic Cost Posting True.
        // 3.2. Verify: Verify General Ledger Entries that WIP Account does not exist and Total Inventory amount equals calculated amount.
        if MultiplePartialRecvInv then begin
            UpdatePurchaseHeader(PurchaseHeader."No.", ItemNo, ItemNo2, ItemNo3);
            if not AutomaticCostPosting then
                LibraryCosting.PostInvtCostToGL(false, WorkDate, '');
            PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
            PurchInvHeader.FindLast;
            VerifyInvtAmountGLEntry(PurchInvHeader."No.", ItemNo);
        end;
    end;

    local procedure CreateAndPostTransferOrder(FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocationCode);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);
    end;

    local procedure CreateItem(var Item: Record Item; ItemCostingMethod: Option Standard,"Average"; ItemReorderPolicy: Option; FlushingMethod: Option; RoutingNo: Code[20]; ProductionBOMNo: Code[20]; CostExpected: Boolean)
    begin
        // Create Item with required fields where random and other values are not important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, ItemCostingMethod, 0, ItemReorderPolicy, FlushingMethod, RoutingNo, ProductionBOMNo);
        Item.Validate("Overhead Rate", LibraryRandom.RandInt(5));
        Item.Validate("Indirect Cost %", LibraryRandom.RandInt(5));
        if not CostExpected then
            Item.Validate("Unit Cost", LibraryRandom.RandInt(10));
        Item.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; BuyfromVendorNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyfromVendorNo);
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; ItemNo2: Code[20]; ItemNo3: Code[20]; Quantity: Decimal; PartialRecvInv: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, Quantity, PartialRecvInv);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo2, Quantity, PartialRecvInv);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo3, Quantity, PartialRecvInv);
    end;

    local procedure CreatePurchaseOrderPostReceipt(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo, LocationCode);
        CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity, UnitCost);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Qty: Decimal; PartialRecvInv: Boolean)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        if PartialRecvInv then
            PurchaseLine.Validate("Qty. to Receive", Qty - 5);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithUnitCost(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Option; No: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateItemAndLocationSetup(var Item: Record Item; var Location: array[3] of Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        LibraryWarehouse.CreateInTransitLocation(Location[3]);
        CreateItemWithStockkeepingUnitsPerLocation(Item);
    end;

    local procedure CreateItemJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; EntryType: Option; ItemNo: Code[20]; Quantity: Decimal)
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
    end;

    local procedure CreateManufacturingItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        with Item do begin
            Validate("Production BOM No.", ProductionBOMNo);
            Validate("Replenishment System", "Replenishment System"::"Prod. Order");
            Validate("Costing Method", "Costing Method"::FIFO);
            Modify(true);
        end;
    end;

    local procedure CreateItemsSetup(var Item: Record Item; var Item2: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Create Child Item.
        LibraryInventory.CreateItem(Item2);

        // Create Production BOM, Parent Item and attach Production BOM.
        CreateCertifiedProductionBOM(ProductionBOMHeader, Item2."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", 1); // Value 1 is important.
        CreateManufacturingItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateItemsSetupWithProductionBOMTypeComponent(var Item: Record Item; var Item2: Record Item): Integer
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        QtyPer: Integer;
        QtyPer2: Integer;
    begin
        // Create Child Item.
        LibraryInventory.CreateItem(Item2);

        // Create Production BOM, Create Production BOM with Production BOM Component, Create Parent Item and attach Production BOM.
        QtyPer := LibraryRandom.RandIntInRange(2, 100); // Value is not important, but should not be 1.
        QtyPer2 := LibraryRandom.RandIntInRange(1, 100);
        CreateCertifiedProductionBOM(
          ProductionBOMHeader, Item2."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", QtyPer);
        CreateCertifiedProductionBOM(
          ProductionBOMHeader, ProductionBOMHeader."Unit of Measure Code",
          ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader."No.", QtyPer2); // Value is not important
        CreateManufacturingItem(Item, ProductionBOMHeader."No.");
        exit(QtyPer * QtyPer2);
    end;

    local procedure CreateItemWithCostingMethod(var Item: Record Item; CostingMethod: Option)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
    end;

    local procedure CreateItemWithStockkeepingUnitsPerLocation(var Item: Record Item)
    begin
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Average);
        LibraryInventory.CreateStockKeepingUnit(Item, 0, false, true); // Create stockkeeping units per location
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; UnitOfMeasure: Code[10]; ProductionBOMLineType: Option; No: Code[20]; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLineType, No, QuantityPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandInt(10));  // Taking Random Quantity.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]): Decimal
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandDec(100, 2));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(ItemJournalLine."Unit Amount");
    end;

    local procedure CreateProductionBOMVersion(var ProductionBOMVersion: Record "Production BOM Version"; ProductionBOMHeader: Record "Production BOM Header"; ItemBaseUnitOfMeasure: Code[10]; ItemNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMVersion(ProductionBOMVersion, ProductionBOMHeader."No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(ProductionBOMVersion.FieldNo("Version Code"), DATABASE::"Production BOM Version"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Production BOM Version", ProductionBOMVersion.FieldNo("Version Code"))),
          ItemBaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, ProductionBOMVersion."Version Code", ProductionBOMLine.Type::Item, ItemNo,
          LibraryRandom.RandInt(10)); // Random Quantity.
    end;

    local procedure CreateProdBOMVersionWithStartingDate(var ProductionBOMVersion: Record "Production BOM Version"; ProductionBOMHeader: Record "Production BOM Header"; ItemBaseUnitOfMeasure: Code[10]; ChildItemNo: Code[20]; StartingDate: Date)
    begin
        CreateProductionBOMVersion(ProductionBOMVersion, ProductionBOMHeader, ItemBaseUnitOfMeasure, ChildItemNo);
        UpdateStartingDateOnProductionBOMVersion(ProductionBOMVersion, StartingDate);
        UpdateStatusOnProductionBOMVersion(ProductionBOMVersion, ProductionBOMVersion.Status::Certified);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateRevalutionItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectRevaluationItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateRevalutionJournal(var Item: Record Item; var ItemJournalLine: Record "Item Journal Line"; ByLocation: Boolean; ByVariant: Boolean; CalculatePer: Option; CalculationBase: Option)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        CalculateInventoryValue: Report "Calculate Inventory Value";
    begin
        CreateRevalutionItemJournalBatch(ItemJournalBatch);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        CalculateInventoryValue.InitializeRequest(WorkDate, ItemJournalLine."Document No.", true,
          CalculatePer, ByLocation, ByVariant, true, CalculationBase, false);
        Commit;
        CalculateInventoryValue.UseRequestPage(false);
        CalculateInventoryValue.SetItemJnlLine(ItemJournalLine);
        Item.SetRange("No.", Item."No.");
        CalculateInventoryValue.SetTableView(Item);
        CalculateInventoryValue.RunModal;

        ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst;
    end;

    local procedure CreatePostTransferJournalLine(ItemNo: Code[20]; Quantity: Decimal; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Transfer, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", FromLocationCode);
        ItemJournalLine.Validate("New Location Code", ToLocationCode);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreatePostPositiveAdjustment(var Item: Record Item; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreatePostPositiveAdjustmentWithUnitAmount(var Item: Record Item) PostedAmount: Decimal
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        UnitAmount: Decimal;
    begin
        Quantity := LibraryRandom.RandIntInRange(500000, 3000000);
        UnitAmount := LibraryRandom.RandDec(10, 2);
        PostedAmount := Quantity * UnitAmount;

        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreatePostRevaluation(var Item: Record Item; var CostAmount: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateRevalutionJournal(Item, ItemJournalLine, false, false, CalculatePerValues::Item, CalculationBaseValues::" ");
        CostAmount := LibraryRandom.RandInt(10);
        ItemJournalLine.Validate("Unit Cost (Revalued)", CostAmount);
        ItemJournalLine.Modify;
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure MockItemWithManufacturingCosts(var Item: Record Item; ReplenishmentSystem: Option)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Costing Method" := Item."Costing Method"::Standard;
        Item."Replenishment System" := ReplenishmentSystem;

        Item."Single-Level Material Cost" := LibraryRandom.RandDec(1000, 2);
        Item."Single-Level Capacity Cost" := LibraryRandom.RandDec(1000, 2);
        Item."Single-Level Subcontrd. Cost" := LibraryRandom.RandDec(1000, 2);
        Item."Single-Level Cap. Ovhd Cost" := LibraryRandom.RandDec(1000, 2);
        Item."Single-Level Mfg. Ovhd Cost" := LibraryRandom.RandDec(1000, 2);

        Item."Rolled-up Material Cost" := Item."Single-Level Material Cost";
        Item."Rolled-up Capacity Cost" := Item."Single-Level Capacity Cost";
        Item."Rolled-up Subcontracted Cost" := Item."Single-Level Subcontrd. Cost";
        Item."Rolled-up Cap. Overhead Cost" := Item."Single-Level Cap. Ovhd Cost";
        Item."Rolled-up Mfg. Ovhd Cost" := Item."Single-Level Mfg. Ovhd Cost";

        Item."Standard Cost" :=
          Item."Single-Level Material Cost" +
          Item."Single-Level Mfg. Ovhd Cost" +
          Item."Single-Level Capacity Cost" +
          Item."Single-Level Subcontrd. Cost" +
          Item."Single-Level Cap. Ovhd Cost";

        Item.Modify;
    end;

    local procedure UpdatePurchaseHeader(PurchaseOrderNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20]; ItemNo3: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Update Purchase Header with new vendor Invoice.
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrderNo);
        PurchaseHeader.Validate(
          "Vendor Invoice No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);

        // Update Purchase Lines with partial quantity,value used are important for test.
        UpdatePurchaseLine(PurchaseHeader."No.", ItemNo, 2);
        UpdatePurchaseLine(PurchaseHeader."No.", ItemNo2, 0);
        UpdatePurchaseLine(PurchaseHeader."No.", ItemNo3, 5);

        // Post Purchase order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure UpdatePurchaseLine(PurchaseOrderNo: Code[20]; ItemNo: Code[20]; QtyToReceive: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseOrderNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst;
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine."Qty. to Receive" - QtyToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure SelectGLEntry(var GLEntry: Record "G/L Entry"; InventoryPostingSetupAccount: Code[20]; PurchaseInvoiceNo: Code[20])
    begin
        // Select set of G/L Entries for the specified Account.
        GLEntry.SetRange("Document No.", PurchaseInvoiceNo);
        GLEntry.SetRange("G/L Account No.", InventoryPostingSetupAccount);
        GLEntry.FindSet;
    end;

    local procedure SelectInventoryPostingSetup(var InventoryPostingSetup: Record "Inventory Posting Setup"; ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", Item."Inventory Posting Group");
        InventoryPostingSetup.FindFirst;
    end;

    local procedure SelectRevaluationItemJournalTemplate(var ItemJournalTemplate: Record "Item Journal Template")
    begin
        // Select Item Journal Template Name for General Journal Line.
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Revaluation);
        if not ItemJournalTemplate.FindFirst then begin
            ItemJournalTemplate.Init;
            ItemJournalTemplate.Validate(
              Name, CopyStr(LibraryUtility.GenerateRandomCode(ItemJournalTemplate.FieldNo(Name), DATABASE::"Item Journal Template"), 1,
                MaxStrLen(ItemJournalTemplate.Name)));
            ItemJournalTemplate.Insert(true);
        end;
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure CalculateGLEntryTotalAmount(var GLEntry: Record "G/L Entry"): Decimal
    var
        TotalAmount: Decimal;
    begin
        repeat
            TotalAmount += GLEntry.Amount;
        until GLEntry.Next = 0;
        exit(TotalAmount);
    end;

    local procedure DirectIndirectItemCost(PurchaseInvoiceNo: Code[20]): Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
        DirectIndirectPOCost: Decimal;
    begin
        // Calculate Direct and Indirect Cost purchase order Cost.
        PurchInvLine.SetRange("Document No.", PurchaseInvoiceNo);
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        if PurchInvLine.FindSet then
            repeat
                DirectIndirectPOCost +=
                  (PurchInvLine.Quantity * PurchInvLine."Direct Unit Cost") +
                  (PurchInvLine.Quantity *
                   ((PurchInvLine."Indirect Cost %" / 100) * PurchInvLine."Direct Unit Cost" + PurchInvLine."Overhead Rate"));
            until PurchInvLine.Next = 0;

        exit(DirectIndirectPOCost);
    end;

    local procedure UpdateStatusOnProductionBOMVersion(ProductionBOMVersion: Record "Production BOM Version"; Status: Option)
    begin
        ProductionBOMVersion.Validate(Status, Status);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure UpdateStartingDateOnProductionBOMVersion(var ProductionBOMVersion: Record "Production BOM Version"; StartingDate: Date)
    begin
        ProductionBOMVersion.Validate("Starting Date", StartingDate);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure FindStandardCostWorksheet(var StandardCostWorksheet: Record "Standard Cost Worksheet"; StandardCostWorksheetName: Code[10]; ItemNo: Code[20])
    begin
        StandardCostWorksheet.SetRange("Standard Cost Worksheet Name", StandardCostWorksheetName);
        StandardCostWorksheet.SetRange(Type, StandardCostWorksheet.Type::Item);
        StandardCostWorksheet.SetRange("No.", ItemNo);
        StandardCostWorksheet.FindFirst;
    end;

    local procedure UpdateNewStandardCostOnStandardCostWorksheet(StandardCostWorksheetName: Code[10]; ItemNo: Code[20])
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
    begin
        FindStandardCostWorksheet(StandardCostWorksheet, StandardCostWorksheetName, ItemNo);
        StandardCostWorksheet.Validate(
          "New Standard Cost", StandardCostWorksheet."New Standard Cost" + LibraryRandom.RandDec(10, 2));
        StandardCostWorksheet.Modify(true);
    end;

    local procedure CreateProductionBOMVersionAndUpdateStatus(ProductionBOMNo: Code[20]; Status: Option)
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        ProductionBOMHeader.Get(ProductionBOMNo);
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ProductionBOMHeader."No.", Format(LibraryRandom.RandInt(10)),
          ProductionBOMHeader."Unit of Measure Code");  // Use Random Version Code.
        ProductionBOMCopy.CopyBOM(ProductionBOMVersion."Production BOM No.", '', ProductionBOMHeader, ProductionBOMVersion."Version Code");
        UpdateStatusOnProductionBOMVersion(ProductionBOMVersion, Status);
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(5)), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
    end;

    local procedure UpdateStatusOnRoutingVersion(RoutingVersion: Record "Routing Version"; Status: Option)
    begin
        RoutingVersion.Validate(Status, Status);
        RoutingVersion.Modify(true);
    end;

    local procedure CreateRoutingVersionAndUpdateStatus(RoutingHeader: Record "Routing Header"; Status: Option)
    var
        RoutingVersion: Record "Routing Version";
        RoutingLineCopyLines: Codeunit "Routing Line-Copy Lines";
    begin
        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", Format(LibraryRandom.RandInt(10)));  // Use Random Version Code.
        RoutingLineCopyLines.CopyRouting(RoutingVersion."Routing No.", '', RoutingHeader, RoutingVersion."Version Code");
        UpdateStatusOnRoutingVersion(RoutingVersion, Status);
    end;

    local procedure UpdateRoutingNoOnItem(var Item: Record Item; RoutingNo: Code[20])
    begin
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure UpdateStandardCostOnItem(var Item: Record Item)
    begin
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
    end;

    local procedure CreateAndUpdateStandardCostWorksheet(Item: Record Item): Code[10]
    var
        StandardCostWorksheetName: Record "Standard Cost Worksheet Name";
    begin
        // Create Standard Cost Worksheet Name. Run Suggest Item Standard Cost and update New Standard Cost value.
        LibraryInventory.CreateStandardCostWorksheetName(StandardCostWorksheetName);
        LibraryCosting.SuggestItemStandardCost(Item, StandardCostWorksheetName.Name, LibraryRandom.RandInt(5), '');  // Use random value for Standard Cost Adjustment Factor.
        UpdateNewStandardCostOnStandardCostWorksheet(StandardCostWorksheetName.Name, Item."No.");
        exit(StandardCostWorksheetName.Name);
    end;

    local procedure CreateAndRevalueInventory(var ItemJournalLine: Record "Item Journal Line"; var RevaluedAmount: Decimal; ByLocation: Boolean; ByVariant: Boolean)
    var
        Item: Record Item;
        PostedAmount: Decimal;
    begin
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Average);

        PostedAmount := CreatePostPositiveAdjustmentWithUnitAmount(Item);
        PostedAmount += CreatePostPositiveAdjustmentWithUnitAmount(Item);
        RevaluedAmount := PostedAmount + LibraryRandom.RandInt(100);

        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        CreateRevalutionJournal(Item, ItemJournalLine, ByLocation, ByVariant, CalculatePerValues::Item, CalculationBaseValues::" ");
        ItemJournalLine.Validate("Inventory Value (Revalued)", RevaluedAmount);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateBOMTree(Item: Record Item)
    var
        BOMBuffer: Record "BOM Buffer";
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
        TreeType: Option " ",Availability,Cost;
    begin
        Item.SetRange("Date Filter", 0D, WorkDate);
        CalculateBOMTree.SetShowTotalAvailability(true);
        CalculateBOMTree.GenerateTreeForItems(Item, BOMBuffer, TreeType::Availability);
    end;

    local procedure RunBOMStructurePage(var Item: Record Item)
    var
        BOMStructure: Page "BOM Structure";
    begin
        BOMStructure.InitItem(Item);
        BOMStructure.Run;
    end;

    local procedure VerifyActualCostAmount(ItemNo: Code[20]; ValuationDate: Date; ExpectedAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
        ItemJournalLine: Record "Item Journal Line";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Valuation Date", ValuationDate);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        Assert.AreEqual(
          ExpectedAmount, ValueEntry."Cost Amount (Actual)",
          StrSubstNo(
            UnexpectedCostAmtErr, ValueEntry.FieldCaption("Cost Amount (Actual)"),
            ItemJournalLine.FieldCaption("Inventory Value (Revalued)")));
    end;

    local procedure VerifyAppliedEntryToAdjust(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.FindSet;
        repeat
            ItemLedgerEntry.TestField("Applied Entry to Adjust", not ItemLedgerEntry."Completely Invoiced");
        until ItemLedgerEntry.Next = 0;
    end;

    local procedure VerifyWIPAccountNotInGLEntry(PurchaseInvoiceNo: Code[20]; ItemNo: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        SelectInventoryPostingSetup(InventoryPostingSetup, ItemNo);
        GLEntry.SetRange("Document No.", PurchaseInvoiceNo);
        GLEntry.SetRange("G/L Account No.", InventoryPostingSetup."WIP Account");

        // Verify no row exist for WIP Account in G/L Entry.
        Assert.IsFalse(GLEntry.FindFirst, ErrMessageGLEntryNoRowExist);
    end;

    local procedure VerifyInvtAmountGLEntry(PurchaseInvoiceNo: Code[20]; ItemNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        SelectInventoryPostingSetup(InventoryPostingSetup, ItemNo);

        // Verify that no row exists for WIP Account.
        VerifyWIPAccountNotInGLEntry(PurchaseInvoiceNo, ItemNo);

        // Verify sum of Inventory Account amounts equal to calculated amount.
        SelectGLEntry(GLEntry, InventoryPostingSetup."Inventory Account", PurchaseInvoiceNo);
        VerifyTotalInvtAmount(CalculateGLEntryTotalAmount(GLEntry), PurchaseInvoiceNo);
    end;

    local procedure VerifyItemLedgerEntryRounding(DocumentNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindLast;
        ValueEntry.TestField("Entry Type", ValueEntry."Entry Type"::Rounding);
    end;

    local procedure VerifyTotalInvtAmount(TotalAmount: Decimal; PurchaseInvoiceNo: Code[20])
    var
        CalculatedInventoryAmount: Decimal;
    begin
        CalculatedInventoryAmount := DirectIndirectItemCost(PurchaseInvoiceNo);

        // Verify Inventory Account amounts and calculated Inventory amounts are equal.
        Assert.AreEqual(TotalAmount, CalculatedInventoryAmount, ErrMessageInvAmountDoNotMatch);
    end;

    local procedure VerifyUnitCostInProductionOrderLine(ProductionOrder: Record "Production Order"; UnitCost: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst;
        ProdOrderLine.TestField("Unit Cost", UnitCost);
    end;

    local procedure VerifyQtyPerTopItemOnBOMBuffer(ItemNo: Code[20]; QtyPerTopItem: Decimal)
    var
        BOMBuffer: Record "BOM Buffer";
    begin
        with BOMBuffer do begin
            SetRange(Type, Type::Item);
            SetRange("No.", ItemNo);
            FindFirst;
            Assert.AreEqual(QtyPerTopItem, "Qty. per Top Item", QtyPerTopItemErr);
        end;
    end;

    local procedure VerifyValueEntryCostPostedToGL(ItemNo: Code[20]; ExpectedCostAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindLast;
        Assert.AreEqual(ExpectedCostAmount, ValueEntry."Cost Posted to G/L", IncorrectCostPostedToGLErr);
    end;

    local procedure VerifyStdCostWorksheet(StandardCostWkshName: Code[10]; Item: Record Item)
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
    begin
        FindStandardCostWorksheet(StandardCostWorksheet, StandardCostWkshName, Item."No.");

        with StandardCostWorksheet do begin
            TestField("Single-Lvl Material Cost", Item."Single-Level Material Cost");
            TestField("New Single-Lvl Material Cost", Item."Single-Level Material Cost");
            TestField("Single-Lvl Cap. Cost", Item."Single-Level Capacity Cost");
            TestField("New Single-Lvl Cap. Cost", Item."Single-Level Capacity Cost");
            TestField("Single-Lvl Subcontrd Cost", Item."Single-Level Subcontrd. Cost");
            TestField("New Single-Lvl Subcontrd Cost", Item."Single-Level Subcontrd. Cost");
            TestField("Single-Lvl Cap. Ovhd Cost", Item."Single-Level Cap. Ovhd Cost");
            TestField("New Single-Lvl Cap. Ovhd Cost", Item."Single-Level Cap. Ovhd Cost");
            TestField("Single-Lvl Mfg. Ovhd Cost", Item."Single-Level Mfg. Ovhd Cost");
            TestField("New Single-Lvl Mfg. Ovhd Cost", Item."Single-Level Mfg. Ovhd Cost");

            TestField("Rolled-up Material Cost", Item."Rolled-up Material Cost");
            TestField("New Rolled-up Material Cost", Item."Rolled-up Material Cost");
            TestField("Rolled-up Cap. Cost", Item."Rolled-up Capacity Cost");
            TestField("New Rolled-up Cap. Cost", Item."Rolled-up Capacity Cost");
            TestField("Rolled-up Subcontrd Cost", Item."Rolled-up Subcontracted Cost");
            TestField("New Rolled-up Subcontrd Cost", Item."Rolled-up Subcontracted Cost");
            TestField("Rolled-up Cap. Ovhd Cost", Item."Rolled-up Cap. Overhead Cost");
            TestField("New Rolled-up Cap. Ovhd Cost", Item."Rolled-up Cap. Overhead Cost");
            TestField("Rolled-up Mfg. Ovhd Cost", Item."Rolled-up Mfg. Ovhd Cost");
            TestField("New Rolled-up Mfg. Ovhd Cost", Item."Rolled-up Mfg. Ovhd Cost");
        end;
    end;

    local procedure VerifyStdCostWorksheetPurchItem(StandardCostWkshName: Code[10]; ItemNo: Code[20]; StandardCost: Decimal)
    var
        Item: Record Item;
    begin
        Item.Init;
        Item."No." := ItemNo;
        Item."Single-Level Material Cost" := StandardCost;
        Item."Rolled-up Material Cost" := StandardCost;

        VerifyStdCostWorksheet(StandardCostWkshName, Item);
    end;

    local procedure VerifySKULastDirectCost(ItemNo: Code[20]; LocationCode: Code[10]; ExpectedAmount: Decimal)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        with StockkeepingUnit do begin
            SetRange("Item No.", ItemNo);
            SetRange("Location Code", LocationCode);
            FindFirst;
            TestField("Last Direct Cost", ExpectedAmount);
        end;
    end;

    local procedure VerifySKUUnitCost(ItemNo: Code[20]; LocationCode: Code[10]; ExpectedUnitCost: Decimal)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.Get(LocationCode, ItemNo, '');
        StockkeepingUnit.TestField("Unit Cost", ExpectedUnitCost);
    end;

    local procedure VerifyValueEntryCostAmount(ItemJournalLine: Record "Item Journal Line"; RevaluedAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetRange("Item No.", ItemJournalLine."Item No.");
            CalcSums("Cost Amount (Actual)");
            Assert.AreEqual(
              RevaluedAmount, "Cost Amount (Actual)",
              StrSubstNo(
                UnexpectedCostAmtErr, FieldCaption("Cost Amount (Actual)"), ItemJournalLine.FieldCaption("Inventory Value (Revalued)")));
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerOK(Message: Text[1024])
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BOMStructurePageHandler(var BOMStructure: TestPage "BOM Structure")
    var
        BOMBuffer: Record "BOM Buffer";
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        with BOMStructure do begin
            FILTER.SetFilter(Type, Format(BOMBuffer.Type::Item));
            Expand(true);
            Next;
            "No.".AssertEquals(ItemNo);
        end;
        Assert.IsFalse(BOMStructure.Next, BOMStructureErr);
    end;
}

