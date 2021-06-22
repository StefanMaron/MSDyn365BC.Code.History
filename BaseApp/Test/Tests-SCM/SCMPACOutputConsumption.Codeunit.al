codeunit 137006 "SCM PAC Output Consumption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        ErrMessageConsumptionMissing: Label 'The Actual consumption Quantity must be same as Expected Consumption quantity';
        ErrMessagePartialOutput: Label 'There must be some Output Missing';
        ErrMessageRefreshComponentEql: Label 'No of Component must be equal';
        ErrMessageRefreshNotEql: Label 'Number of Component cannot be equal';
        ErrMessageRefreshRoutingEql: Label 'Number of Routing must be equal';
        ErrMessageRefreshRoutingNotEql: Label 'Number of Routing cannot be equal';

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure StdForwardPostOutput()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ItemJournalBatch: Record "Item Journal Batch";
        ManufacturingSetup: Record "Manufacturing Setup";
        WorkCenterGroup: Record "Work Center Group";
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        RoutingLink: Record "Routing Link";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ShopCalendarCode: Code[10];
        ProductionBOMNo: Code[20];
        RoutingLinkCode: Code[10];
        MachineCenterNo: Code[20];
        WorkCenterNo: Code[20];
        WorkCenterNo2: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ItemNo3: Code[20];
        ReleasedProductionOrderNo: Code[20];
        UnitCostCalculation: Option Time,Units;
        ProdOrderQuantity: Decimal;
    begin
        // [FEATURE] [Output] [Flushing Method] [Forward]
        // Covers documents TFS_TC_ID 3282 and 11842.
        // Steps describing the sequence of actions for Test Case.

        // 1. Create required setups.
        // Update Manufacturing Setup, Inventory Setup and Update Shop Calendar Working Days based on Work Shift code.
        Initialize;
        LibraryManufacturing.CreateWorkCenterGroup(WorkCenterGroup);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        LibraryERM.SetUseLegacyGLEntryLocking(true);
        UpdateInventorySetup;

        LibraryManufacturing.UpdateManufacturingSetup(ManufacturingSetup, '', '', true, true, true);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays;

        // Create Work Centers and Machine Center with Flushing method -Manual.
        // Create Routing Link code and Routing.
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, "Flushing Method"::Manual, UnitCostCalculation::Time);
        CreateMachineCenter(MachineCenterNo, WorkCenterNo, "Flushing Method"::Manual);
        CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::Manual, UnitCostCalculation::Time);
        RoutingLinkCode := CreateRoutingLinkCode(RoutingLink);
        CreateRouting(RoutingNo, MachineCenterNo, WorkCenterNo, WorkCenterNo2, RoutingLinkCode, '', false);

        // Create Items with Flushing method - Forward with the third Item containing Routing No. and Production BOM No.
        // Update Routing link Code on specified BOM component Lines.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, '', '');
        ItemNo := Item."No.";
        Clear(Item);
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, '', '');
        ItemNo2 := Item."No.";
        Clear(Item);
        ProductionBOMNo :=
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ItemNo, ItemNo2, LibraryRandom.RandInt(1));
        UpdateBOMHeader(ProductionBOMNo, ItemNo2, RoutingLinkCode);
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, RoutingNo, ProductionBOMNo);
        ItemNo3 := Item."No.";

        // Calculate Standard Cost for third Item.
        // Calculate Calendar for Work Center with dates having a difference of 5 weeks.
        // Create and Post Purchase Order as Receive and Invoice.
        // Create Refresh and Update Planned Production Order.
        CalculateStandardCost.CalcItem(ItemNo3, false);
        CalculateMachCenterCalendar(MachineCenterNo, WorkCenterNo, WorkCenterNo2);
        CreatePurchOrderTwoPurchLine(
          PurchaseHeader, PurchaseLine, ItemNo, ItemNo2, LibraryRandom.RandInt(100) + 10, LibraryRandom.RandInt(100) + 10);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ProdOrderQuantity := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, ItemNo3, ProdOrderQuantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        UpdatePlannedProductionOrder(ProductionOrder."No.");

        // 2.1 Execute : Change Status of Production Order from Planned to Released.
        ReleasedProductionOrderNo := ChangeStatusPlannedToReleased(ProductionOrder."No.");

        // 3.1 Verify Item Ledger Entry : Consumption booked for Item without Routing Link Code.
        VerifyConsumptionQuantity(ReleasedProductionOrderNo, ItemNo, '', "Production Order Status"::Released, false);

        // 2.2 Execute : Create, Calculate and Post Consumption Journal.
        // Create, Explode Routing, Update and Post Output Journal.
        LibraryInventory.CreateItemJournal(
          ItemJournalBatch, ItemNo, ItemJournalBatch."Template Type"::Consumption, ReleasedProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryInventory.CreateItemJournal(ItemJournalBatch, ItemNo3, ItemJournalBatch."Template Type"::Output, ReleasedProductionOrderNo);
        UpdateLessQtyOutputJournal(ReleasedProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // 3.2 Verify Item Ledger Entry : All Consumption booked.
        VerifyConsumptionQuantity(ReleasedProductionOrderNo, '', '', "Production Order Status"::Released, false);

        // 2.3 Execute : Change Status of Production Order from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ReleasedProductionOrderNo);

        // 3.3 Verify Item Ledger Entry : Partial output.
        VerifyFinishedItemLedgerEntry(ReleasedProductionOrderNo, ItemNo3, ProdOrderQuantity);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure StdBackwardPostOutput()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ItemJournalBatch: Record "Item Journal Batch";
        ManufacturingSetup: Record "Manufacturing Setup";
        WorkCenterGroup: Record "Work Center Group";
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        RoutingLink: Record "Routing Link";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ShopCalendarCode: Code[10];
        ProductionBOMNo: Code[20];
        RoutingLinkCode: Code[10];
        MachineCenterNo: Code[20];
        WorkCenterNo: Code[20];
        WorkCenterNo2: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ItemNo3: Code[20];
        ProductionOrderNo: Code[20];
        UnitCostCalculation: Option Time,Units;
        ProductionOrderQuantity: Decimal;
    begin
        // [FEATURE] [Output] [Flushing Method] [Backward]
        // Covers documents TFS_TC_ID 3283 and 11842.
        // Steps describing the sequence of actions for Test Case.

        // 1. Create required setups.
        // Update Manufacturing Setup, Inventory Setup and Update Shop Calendar Working Days based on Work Shift code.
        Initialize;
        LibraryManufacturing.CreateWorkCenterGroup(WorkCenterGroup);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        LibraryERM.SetUseLegacyGLEntryLocking(true);
        UpdateInventorySetup;

        LibraryManufacturing.UpdateManufacturingSetup(ManufacturingSetup, '', '', true, true, true);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays;

        // Create Work Centers and Machine Center with Flushing method -Manual.
        // Create Routing Link code and Routing.
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, "Flushing Method"::Manual, UnitCostCalculation::Time);
        CreateMachineCenter(MachineCenterNo, WorkCenterNo, "Flushing Method"::Manual);
        CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::Manual, UnitCostCalculation::Time);
        RoutingLinkCode := CreateRoutingLinkCode(RoutingLink);
        CreateRouting(RoutingNo, MachineCenterNo, WorkCenterNo, WorkCenterNo2, RoutingLinkCode, '', false);

        // Create Items with Flushing method - Backward with the third Item containing Routing No. and Production BOM No.
        // Update Routing link Code on specified BOM component Lines.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Backward, '', '');
        ItemNo := Item."No.";
        Clear(Item);
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Backward, '', '');
        ItemNo2 := Item."No.";
        Clear(Item);
        ProductionBOMNo :=
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ItemNo, ItemNo2, LibraryRandom.RandInt(10));
        UpdateBOMHeader(ProductionBOMNo, ItemNo2, RoutingLinkCode);
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Backward, RoutingNo, ProductionBOMNo);
        ItemNo3 := Item."No.";

        // Calculate Standard Cost for third Item.
        // Calculate Calendar for Work Center with dates having a difference of 5 weeks.
        // Create and Post Purchase Order as Receive and Invoice.
        // Create Refresh and Update Planned Production Order.
        CalculateStandardCost.CalcItem(ItemNo3, false);
        CalculateMachCenterCalendar(MachineCenterNo, WorkCenterNo, WorkCenterNo2);
        CreatePurchOrderTwoPurchLine(
          PurchaseHeader, PurchaseLine, ItemNo, ItemNo2, LibraryRandom.RandInt(100) + 10, LibraryRandom.RandInt(100) + 10);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ProductionOrderQuantity := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, ItemNo3, ProductionOrderQuantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        UpdatePlannedProductionOrder(ProductionOrder."No.");

        // 2.1 Execute : Change Status of Production Order from Planned to Released.
        // Create, Explode Routing, Update and Post Output Journal.
        ProductionOrderNo := ChangeStatusPlannedToReleased(ProductionOrder."No.");
        LibraryInventory.CreateItemJournal(ItemJournalBatch, ItemNo3, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        UpdateLessQtyOutputJournal(ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // 3.1 Verify Item Ledger Entry : Consumption booked for Item with Routing Link Code.
        VerifyConsumptionQuantity(ProductionOrderNo, ItemNo2, RoutingLinkCode, "Production Order Status"::Released, true);

        // 2.2 Execute : Change Status of Production Order from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // 3.2 Verify Item Ledger Entry : All Consumption booked with or without Routing Link Code.
        // Verify Item Ledger Entry : Partial output.
        VerifyConsumptionQuantity(ProductionOrderNo, '', RoutingLinkCode, "Production Order Status"::Finished, false);
        VerifyFinishedItemLedgerEntry(ProductionOrderNo, ItemNo3, ProductionOrderQuantity);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure StdManualPostConsumption()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ItemJournalBatch: Record "Item Journal Batch";
        ManufacturingSetup: Record "Manufacturing Setup";
        WorkCenterGroup: Record "Work Center Group";
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        RoutingLink: Record "Routing Link";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ShopCalendarCode: Code[10];
        ProductionBOMNo: Code[20];
        RoutingLinkCode: Code[10];
        MachineCenterNo: Code[20];
        WorkCenterNo: Code[20];
        WorkCenterNo2: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ItemNo3: Code[20];
        ReleasedProductionOrderNo: Code[20];
        UnitCostCalculation: Option Time,Units;
        Status: Option Simulated,Planned,"Firm Planned",Released,Finished;
        ProductionOrderQuantity: Decimal;
    begin
        // [FEATURE] [Output] [Flushing Method] [Manual]
        // Covers documents TFS_TC_ID 3284 and 11842.
        // Steps describing the sequence of actions for Test Case.

        // 1. Create required setups.
        // Update Manufacturing Setup, Inventory Setup and Update Shop Calendar Working Days based on Work Shift code.
        Initialize;
        LibraryManufacturing.CreateWorkCenterGroup(WorkCenterGroup);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        LibraryERM.SetUseLegacyGLEntryLocking(true);
        UpdateInventorySetup;

        LibraryManufacturing.UpdateManufacturingSetup(ManufacturingSetup, '', '', true, true, true);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays;

        // Create Work Centers and Machine Center with Flushing method -Forward.
        // Create Routing Link code and Routing.
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, "Flushing Method"::Forward, UnitCostCalculation::Time);
        CreateMachineCenter(MachineCenterNo, WorkCenterNo, "Flushing Method"::Forward);
        CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::Forward, UnitCostCalculation::Time);
        RoutingLinkCode := CreateRoutingLinkCode(RoutingLink);
        CreateRouting(RoutingNo, MachineCenterNo, WorkCenterNo, WorkCenterNo2, RoutingLinkCode, '', false);

        // Create Items with Flushing method - Manual with the third Item containing Routing No. and Production BOM No.
        // Update Routing link Code on required BOM component Lines.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Manual, '', '');
        ItemNo := Item."No.";
        Clear(Item);
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Manual, '', '');
        ItemNo2 := Item."No.";
        Clear(Item);
        ProductionBOMNo :=
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ItemNo, ItemNo2, LibraryRandom.RandInt(1));
        UpdateBOMHeader(ProductionBOMNo, ItemNo2, RoutingLinkCode);
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Manual,
          RoutingNo, ProductionBOMNo);
        ItemNo3 := Item."No.";

        // Calculate Standard Cost for third Item.
        // Calculate Calendar for Work Center with dates having a difference of 5 weeks.
        // Create and Post Purchase Order as Receive and Invoice.
        // Create Refresh and Update Planned Production Order.
        CalculateStandardCost.CalcItem(ItemNo3, false);
        CalculateMachCenterCalendar(MachineCenterNo, WorkCenterNo, WorkCenterNo2);
        CreatePurchOrderTwoPurchLine(
          PurchaseHeader, PurchaseLine, ItemNo, ItemNo2, LibraryRandom.RandInt(100) + 10, LibraryRandom.RandInt(100) + 10);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ProductionOrderQuantity := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, ItemNo3, ProductionOrderQuantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        UpdatePlannedProductionOrder(ProductionOrder."No.");

        // 2. Execute : Change Status of Production Order from Planned to Released.
        // Create, Calculate and Post Consumption Journal,Explode Routing and Post Output Journal.
        ReleasedProductionOrderNo := ChangeStatusPlannedToReleased(ProductionOrder."No.");
        LibraryInventory.CreateItemJournal(
          ItemJournalBatch, ItemNo, ItemJournalBatch."Template Type"::Consumption, ReleasedProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // 3. Verify Item Ledger Entry : All Consumption booked with or without Routing Link Code.
        VerifyConsumptionQuantity(ReleasedProductionOrderNo, '', RoutingLinkCode, "Production Order Status"::Released, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdForwardTwoRoutingLinkCode()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ManufacturingSetup: Record "Manufacturing Setup";
        WorkCenterGroup: Record "Work Center Group";
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        RoutingLink: Record "Routing Link";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ShopCalendarCode: Code[10];
        ProductionBOMNo: Code[20];
        RoutingLinkCode: Code[10];
        RoutingLinkCode2: Code[10];
        MachineCenterNo: Code[20];
        WorkCenterNo: Code[20];
        WorkCenterNo2: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ItemNo3: Code[20];
        ItemNo4: Code[20];
        ReleasedProductionOrderNo: Code[20];
        UnitCostCalculation: Option Time,Units;
        Status: Option Simulated,Planned,"Firm Planned",Released,Finished;
        ProductionOrderQuantity: Decimal;
    begin
        // [FEATURE] [Output] [Flushing Method] [Forward]
        // Covers documents TFS_TC_ID 3285, 3286 and 11842.
        // Steps describing the sequence of actions for Test Case.

        // 1. Create required setups.
        // Update Manufacturing Setup, Inventory Setup and Update Shop Calendar Working Days based on Work Shift code.
        Initialize;
        LibraryManufacturing.CreateWorkCenterGroup(WorkCenterGroup);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        LibraryERM.SetUseLegacyGLEntryLocking(true);
        UpdateInventorySetup;

        LibraryManufacturing.UpdateManufacturingSetup(ManufacturingSetup, '', '', true, true, true);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays;

        // Create Work Centers and Machine Center with Flushing method -Backward.
        // Create Routing Link code and Routing.
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, "Flushing Method"::Backward, UnitCostCalculation::Time);
        CreateMachineCenter(MachineCenterNo, WorkCenterNo, "Flushing Method"::Backward);
        CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::Backward, UnitCostCalculation::Time);
        RoutingLinkCode := CreateRoutingLinkCode(RoutingLink);
        RoutingLinkCode2 := CreateRoutingLinkCode(RoutingLink);
        CreateRouting(RoutingNo, MachineCenterNo, WorkCenterNo, WorkCenterNo2, RoutingLinkCode, RoutingLinkCode2, true);

        // Create Items with Flushing method - Forward with the Fourth Item containing Routing No. and Production BOM No.
        // Update Routing link Code on required BOM component Lines.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, '', '');
        ItemNo := Item."No.";
        Clear(Item);
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, '', '');
        ItemNo2 := Item."No.";
        Clear(Item);
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, '', '');
        ItemNo3 := Item."No.";
        Clear(Item);
        ProductionBOMNo :=
          CreateProductionBOM(
            ProductionBOMHeader, ProductionBOMLine, ItemNo, ItemNo2, ItemNo3, LibraryRandom.RandInt(1));
        UpdateBOMHeader(ProductionBOMNo, ItemNo2, RoutingLinkCode);
        UpdateBOMHeader(ProductionBOMNo, ItemNo3, RoutingLinkCode2);
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, RoutingNo, ProductionBOMNo);
        ItemNo4 := Item."No.";

        // Calculate Standard Cost for third Item.
        // Calculate Calendar for Work Center with dates having a difference of 5 weeks.
        // Create and Post Purchase Order as Receive and Invoice.
        // Create Refresh and Update Planned Production Order.
        CalculateStandardCost.CalcItem(ItemNo3, false);
        CalculateMachCenterCalendar(MachineCenterNo, WorkCenterNo, WorkCenterNo2);
        CreatePurchOrderThreePurchLine(
          PurchaseHeader, PurchaseLine, ItemNo, ItemNo2, ItemNo3, LibraryRandom.RandInt(100) + 10,
          LibraryRandom.RandInt(100) + 10, LibraryRandom.RandInt(100) + 10);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ProductionOrderQuantity := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, ItemNo4, ProductionOrderQuantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        UpdatePlannedProductionOrder(ProductionOrder."No.");

        // 2. Execute : Change Status of Production Order from Planned to Released.
        ReleasedProductionOrderNo := ChangeStatusPlannedToReleased(ProductionOrder."No.");

        // 3. Verify Item Ledger Entry : All Consumption booked with or without Routing Link Code.
        VerifyConsumptionQuantity(ReleasedProductionOrderNo, '', RoutingLinkCode, "Production Order Status"::Released, false);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure RefreshComponentRouting()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ManufacturingSetup: Record "Manufacturing Setup";
        WorkCenterGroup: Record "Work Center Group";
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ShopCalendarCode: Code[10];
        ProductionBOMNo: Code[20];
        MachineCenterNo: Code[20];
        WorkCenterNo: Code[20];
        WorkCenterNo2: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ItemNo3: Code[20];
        Type: Enum "Capacity Unit of Measure";
        UnitCostCalculation: Option Time,Units;
        CountProductionOrderComponent: Integer;
        CountProductionOrderRouting: Integer;
        ProductionOrderQuantity: Decimal;
    begin
        // [FEATURE] [Component] [Routing]
        // Covers documents TFS_TC_ID 3287, 3288 and 11842.
        // Steps describing the sequence of actions for Test Case.

        // 1. Create required setups.
        // Update Manufacturing Setup, Inventory Setup and Update Shop Calendar Working Days based on Work Shift code.
        Initialize;
        LibraryManufacturing.CreateWorkCenterGroup(WorkCenterGroup);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, Type::Minutes);
        LibraryERM.SetUseLegacyGLEntryLocking(true);
        UpdateInventorySetup;

        LibraryManufacturing.UpdateManufacturingSetup(ManufacturingSetup, '', '', true, true, true);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays;

        // Create Work Centers and Machine Center with Flushing method -Forward.
        // Create Routing Link code and Routing.
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, "Flushing Method"::Forward, UnitCostCalculation::Time);
        CreateMachineCenter(MachineCenterNo, WorkCenterNo, "Flushing Method"::Forward);
        CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::Forward, UnitCostCalculation::Time);
        CreateRouting(RoutingNo, MachineCenterNo, WorkCenterNo, WorkCenterNo2, '', '', false);

        // Create Items with Flushing method - Forward with the third Item containing Routing No. and Production BOM No.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, '', '');
        ItemNo := Item."No.";
        Clear(Item);
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, '', '');
        ItemNo2 := Item."No.";
        Clear(Item);
        ProductionBOMNo :=
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ItemNo, ItemNo2, LibraryRandom.RandInt(10));
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, RoutingNo, ProductionBOMNo);
        ItemNo3 := Item."No.";

        // Calculate Standard Cost for third Item.
        // Calculate Calendar for Work Center with dates having a difference of 5 weeks.
        // Create and Post Purchase Order as Receive and Invoice.
        // Create Refresh and Update Planned Production Order.
        CalculateStandardCost.CalcItem(ItemNo3, false);
        CalculateMachCenterCalendar(MachineCenterNo, WorkCenterNo, WorkCenterNo2);
        CreatePurchOrderTwoPurchLine(
          PurchaseHeader, PurchaseLine, ItemNo, ItemNo2, LibraryRandom.RandInt(100) + 10, LibraryRandom.RandInt(100) + 10);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ProductionOrderQuantity := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, ItemNo3, ProductionOrderQuantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // 2. Execute: Remove Component and Routing from Production Order,Refresh Production Order.
        // Count number of Production order component and Routing.
        RemoveProdOrderComponent(ProductionOrder."No.", ItemNo);
        RemoveProdOrderRoutingLine(ProductionOrder."No.", WorkCenterNo);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        CountProductionOrderComponent := CountProductionComponents(ProductionOrder."No.");
        CountProductionOrderRouting := CountProductionRoutingLines(ProductionOrder."No.");

        // 3. Verify : Production Components and Routing Lines.
        VerifyComponentAfterRefresh(ProductionBOMNo, CountProductionOrderComponent, true);
        VerifyRoutingAfterRefresh(RoutingNo, CountProductionOrderRouting, true);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure RefreshComponent()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ManufacturingSetup: Record "Manufacturing Setup";
        WorkCenterGroup: Record "Work Center Group";
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ShopCalendarCode: Code[10];
        ProductionBOMNo: Code[20];
        MachineCenterNo: Code[20];
        WorkCenterNo: Code[20];
        WorkCenterNo2: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ItemNo3: Code[20];
        UnitCostCalculation: Option Time,Units;
        CountProductionOrderComponent: Integer;
        ProductionOrderQuantity: Decimal;
    begin
        // [FEATURE] [Component]
        // Covers documents TFS_TC_ID 3282..3288 and 11842.
        // Steps describing the sequence of actions for Test Case.

        // 1. Create required setups.
        // Update Manufacturing Setup, Inventory Setup and Update Shop Calendar Working Days based on Work Shift code.
        Initialize;
        LibraryManufacturing.CreateWorkCenterGroup(WorkCenterGroup);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        LibraryERM.SetUseLegacyGLEntryLocking(true);
        UpdateInventorySetup;

        LibraryManufacturing.UpdateManufacturingSetup(ManufacturingSetup, '', '', true, true, true);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays;

        // Create Work Centers and Machine Center with Flushing method -Forward.
        // Create Routing Link code and Routing.
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, "Flushing Method"::Forward, UnitCostCalculation::Time);
        CreateMachineCenter(MachineCenterNo, WorkCenterNo, "Flushing Method"::Forward);
        CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::Forward, UnitCostCalculation::Time);
        CreateRouting(RoutingNo, MachineCenterNo, WorkCenterNo, WorkCenterNo2, '', '', false);

        // Create Items with Flushing method - Forward with the third Item containing Routing No. and Production BOM No.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, '', '');
        ItemNo := Item."No.";
        Clear(Item);
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, '', '');
        ItemNo2 := Item."No.";
        Clear(Item);
        ProductionBOMNo :=
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ItemNo, ItemNo2, LibraryRandom.RandInt(1));
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward,
          RoutingNo, ProductionBOMNo);
        ItemNo3 := Item."No.";

        // Calculate Standard Cost for third Item.
        // Calculate Calendar for Work Center with dates having a difference of 5 weeks.
        // Create and Post Purchase Order as Receive and Invoice.
        // Create Refresh and Update Planned Production Order.
        CalculateStandardCost.CalcItem(ItemNo3, false);
        CalculateMachCenterCalendar(MachineCenterNo, WorkCenterNo, WorkCenterNo2);
        CreatePurchOrderTwoPurchLine(
          PurchaseHeader, PurchaseLine, ItemNo, ItemNo2, LibraryRandom.RandInt(100) + 10, LibraryRandom.RandInt(100) + 10);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ProductionOrderQuantity := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, ItemNo3, ProductionOrderQuantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // 2. Execute: Remove one Component from Production Order and Refresh Production Order.
        // Count number of Production order component.
        RemoveProdOrderComponent(ProductionOrder."No.", ItemNo);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, false, false);
        CountProductionOrderComponent := CountProductionComponents(ProductionOrder."No.");

        // 3. Verify : Production Order Components.
        VerifyComponentAfterRefresh(ProductionBOMNo, CountProductionOrderComponent, false);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure RefreshRouting()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ManufacturingSetup: Record "Manufacturing Setup";
        WorkCenterGroup: Record "Work Center Group";
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ShopCalendarCode: Code[10];
        ProductionBOMNo: Code[20];
        MachineCenterNo: Code[20];
        WorkCenterNo: Code[20];
        WorkCenterNo2: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ItemNo3: Code[20];
        UnitCostCalculation: Option Time,Units;
        CountProdOrderRouting: Integer;
        ProductionOrderQuantity: Decimal;
    begin
        // [FEATURE] [Routing]
        // Covers documents TFS_TC_ID 3282..3288 and 11842.
        // Steps describing the sequence of actions for Test Case.

        // 1. Create required setups.
        // Update Manufacturing Setup, Inventory Setup and Update Shop Calendar Working Days based on Work Shift code.
        Initialize;
        LibraryManufacturing.CreateWorkCenterGroup(WorkCenterGroup);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        LibraryERM.SetUseLegacyGLEntryLocking(true);
        UpdateInventorySetup;

        LibraryManufacturing.UpdateManufacturingSetup(ManufacturingSetup, '', '', true, true, true);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays;

        // Create Work Centers and Machine Center with Flushing method -Forward.
        // Create Routing Link code and Routing.
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, "Flushing Method"::Forward, UnitCostCalculation::Time);
        CreateMachineCenter(MachineCenterNo, WorkCenterNo, "Flushing Method"::Forward);
        CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::Forward, UnitCostCalculation::Time);
        CreateRouting(RoutingNo, MachineCenterNo, WorkCenterNo, WorkCenterNo2, '', '', false);

        // Create Items with Flushing method - Forward with the third Item containing Routing No. and Production BOM No.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, '', '');
        ItemNo := Item."No.";
        Clear(Item);
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, '', '');
        ItemNo2 := Item."No.";
        Clear(Item);
        ProductionBOMNo :=
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ItemNo, ItemNo2, LibraryRandom.RandInt(1));
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot",
          "Flushing Method"::Forward, RoutingNo, ProductionBOMNo);
        ItemNo3 := Item."No.";

        // Calculate Standard Cost for third Item.
        // Calculate Calendar for Work Center with dates having a difference of 5 weeks.
        // Create and Post Purchase Order as Receive and Invoice.
        // Create Refresh and Update Planned Production Order.
        CalculateStandardCost.CalcItem(ItemNo3, false);
        CalculateMachCenterCalendar(MachineCenterNo, WorkCenterNo, WorkCenterNo2);
        CreatePurchOrderTwoPurchLine(
          PurchaseHeader, PurchaseLine, ItemNo, ItemNo2, LibraryRandom.RandInt(100) + 10, LibraryRandom.RandInt(100) + 10);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ProductionOrderQuantity := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, ItemNo3, ProductionOrderQuantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // 2. Execute : Remove one Routing from Production Order and Refresh Production Order.
        // Count number of Production order Routing.
        RemoveProdOrderRoutingLine(ProductionOrder."No.", WorkCenterNo);
        UpdateOperationNo(ProductionOrder."No.");
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, false, true, false);
        CountProdOrderRouting := CountProductionRoutingLines(ProductionOrder."No.");

        // 3. Verify : Production Order Routing Lines.
        VerifyRoutingAfterRefresh(RoutingNo, CountProdOrderRouting, false);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM PAC Output Consumption");
        // Lazy Setup.
        LibrarySetupStorage.Restore;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM PAC Output Consumption");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM PAC Output Consumption");
    end;

    [Normal]
    local procedure CreateWorkCenter(var WorkCenterNo: Code[20]; ShopCalendarCode: Code[10]; FlushingMethod: Enum "Flushing Method"; UnitCostCalculation: Option)
    var
        WorkCenter: Record "Work Center";
    begin
        // Create Work Center with required fields where Capacity value : 1,  important for test.
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        WorkCenter.Validate("Indirect Cost %", 0);
        WorkCenter.Validate("Overhead Rate", 0);
        WorkCenter.Validate(Capacity, 1);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Validate("Unit Cost Calculation", UnitCostCalculation);
        WorkCenter.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    [Normal]
    local procedure CreateMachineCenter(var MachineCenterNo: Code[20]; WorkCenterNo: Code[20]; FlushingMethod: Enum "Flushing Method")
    var
        MachineCenter: Record "Machine Center";
    begin
        // Create Machine Center with required fields where random is used, random values and other values not important for test.
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenterNo, LibraryRandom.RandInt(10));
        MachineCenter.Validate(Name, MachineCenter."No.");
        MachineCenter.Validate("Direct Unit Cost", 0);
        MachineCenter.Validate("Indirect Cost %", 0);
        MachineCenter.Validate("Overhead Rate", 1);
        MachineCenter.Validate("Flushing Method", FlushingMethod);
        MachineCenter.Validate(Efficiency, 100); // Value important to test
        MachineCenter.Modify(true);
        MachineCenterNo := MachineCenter."No.";
    end;

    [Normal]
    local procedure CreateRoutingLinkCode(var RoutingLink: Record "Routing Link"): Code[10]
    begin
        // Create Routing Link Code.
        RoutingLink.Init();
        RoutingLink.Validate(
          Code, LibraryUtility.GenerateRandomCode(RoutingLink.FieldNo(Code), DATABASE::"Routing Link"));
        RoutingLink.Insert(true);
        RoutingLink.Validate(Description, RoutingLink.Code);
        RoutingLink.Modify(true);
        exit(RoutingLink.Code);
    end;

    [Normal]
    local procedure CreateRouting(var RoutingNo: Code[20]; MachineCenterNo: Code[20]; WorkCenterNo: Code[20]; WorkCenterNo2: Code[20]; RoutingLinkCode: Code[10]; RoutingLinkCode2: Code[10]; MultipleRoutingLinkCode: Boolean)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // Create Routing With Single and Multiple Routing Link Code.
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        if MultipleRoutingLinkCode then begin
            RoutingLine.Type := RoutingLine.Type::"Work Center";
            CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo2, RoutingLinkCode);
            CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo, '');
            RoutingLine.Type := RoutingLine.Type::"Machine Center";
            CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenterNo, RoutingLinkCode2);
        end else begin
            RoutingLine.Type := RoutingLine.Type::"Work Center";
            CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo2, '');
            CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo, RoutingLinkCode);
            RoutingLine.Type := RoutingLine.Type::"Machine Center";
            CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenterNo, '');
        end;

        // Certify Routing after Routing lines creation.
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        RoutingNo := RoutingHeader."No.";
    end;

    [Normal]
    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20]; RoutingLinkCode: Code[10])
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        OperationNo: Code[10];
    begin
        // Create Routing Lines with required fields where random is used, values not important for test.
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Minutes);
        CapacityUnitOfMeasure.FindFirst;
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random is used, values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));

        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);
    end;

    [Normal]
    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast then
            exit(RoutingLine."Operation No.");
    end;

    [Normal]
    local procedure UpdateBOMHeader(ProductionBOMNo: Code[20]; ItemNo: Code[20]; RoutingLinkCode: Code[10])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Update Routing link Code on specified BOM component Lines.
        ProductionBOMHeader.SetRange("No.", ProductionBOMNo);
        ProductionBOMHeader.FindFirst;
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::"Under Development");
        ProductionBOMHeader.Modify(true);
        UpdateBOMLineRoutingLinkCode(ProductionBOMHeader, ProductionBOMLine, ItemNo, RoutingLinkCode);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    [Normal]
    local procedure UpdateBOMLineRoutingLinkCode(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; ItemNo: Code[20]; RoutingLinkCode: Code[10])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", ItemNo);
        ProductionBOMLine.FindFirst;
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
    end;

    [Normal]
    local procedure CalculateMachCenterCalendar(MachineCenterNo: Code[20]; WorkCenterNo: Code[20]; WorkCenterNo2: Code[20])
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        MachineCenter.Get(MachineCenterNo);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-3W>', WorkDate), CalcDate('<2W>', WorkDate));
        WorkCenter.Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-3W>', WorkDate), CalcDate('<2W>', WorkDate));
        Clear(WorkCenter);
        WorkCenter.Get(WorkCenterNo2);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-3W>', WorkDate), CalcDate('<2W>', WorkDate));
    end;

    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; ItemNo: Code[20]; ItemNo2: Code[20]; ItemNo3: Code[20]; QuantityPer: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        // Create Production BOM.
        Item.Get(ItemNo);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, QuantityPer);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo2, QuantityPer);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo3, QuantityPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreatePurchOrderThreePurchLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; ItemNo2: Code[20]; ItemNo3: Code[20]; Quantity: Decimal; Quantity2: Decimal; Quantity3: Decimal)
    begin
        CreatePurchaseHeader(PurchaseHeader);

        // Create Three Purchase Lines.
        CreatePurchaseLines(PurchaseLine, PurchaseHeader, ItemNo, ItemNo2, Quantity, Quantity2);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, ItemNo3, Quantity3);
    end;

    local procedure CreatePurchOrderTwoPurchLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; Quantity2: Decimal)
    begin
        CreatePurchaseHeader(PurchaseHeader);

        // Create Two Purchase Lines.
        CreatePurchaseLines(PurchaseLine, PurchaseHeader, ItemNo, ItemNo2, Quantity, Quantity2);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
    end;

    local procedure CreatePurchaseLines(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; Quantity2: Decimal)
    begin
        // Create Two Purchase Lines.
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, ItemNo, Quantity);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, ItemNo2, Quantity2);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; ItemNo: Code[20]; Qty: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, ItemNo, Qty);
    end;

    local procedure UpdateInventorySetup()
    var
        AverageCostCalcType: Option " ",Item,"Item & Location & Variant";
        AverageCostPeriod: Option " ",Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(false);
        LibraryInventory.SetAutomaticCostAdjmtNever;
        LibraryInventory.SetAverageCostSetup(AverageCostCalcType::Item, AverageCostPeriod::Day);
    end;

    [Normal]
    local procedure UpdatePlannedProductionOrder(ProductionOrderNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Create Planned Production Order with Random Quantity Greater than 1 and in Proportion to Purchased Items.
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Planned);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.FindFirst;
        ProdOrderLine.Validate("Planning Flexibility", ProdOrderLine."Planning Flexibility"::None);
        ProdOrderLine.Modify(true);
    end;

    [Normal]
    local procedure RemoveProdOrderComponent(ProductionOrderNo: Code[20]; ItemNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Planned);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst;
        ProdOrderComponent.Delete(true);
        Commit();
    end;

    [Normal]
    local procedure RemoveProdOrderRoutingLine(ProductionOrderNo: Code[20]; WorkCenterNo: Code[20])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Planned);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Work Center");
        ProdOrderRoutingLine.SetRange("No.", WorkCenterNo);
        ProdOrderRoutingLine.FindFirst;
        ProdOrderRoutingLine.Delete(true);
        Commit();
    end;

    [Normal]
    local procedure UpdateOperationNo(ProductionOrderNo: Code[20])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Planned);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.FindSet;
        repeat
            ProdOrderRoutingLine.Validate("Next Operation No.", '');
            ProdOrderRoutingLine.Validate("Previous Operation No.", '');
            ProdOrderRoutingLine.Modify(true);
        until ProdOrderRoutingLine.Next = 0;
    end;

    [Normal]
    local procedure CountProductionComponents(ProductionNo: Code[20]): Integer
    var
        ProdOrderComponent: Record "Prod. Order Component";
        CountComponent: Integer;
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Planned);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionNo);
        CountComponent := ProdOrderComponent.Count();
        exit(CountComponent);
    end;

    [Normal]
    local procedure CountProductionRoutingLines(ProductionNo: Code[20]): Integer
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        CountRoutingLine: Integer;
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Planned);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionNo);
        CountRoutingLine := ProdOrderRoutingLine.Count();
        exit(CountRoutingLine);
    end;

    local procedure ChangeStatusPlannedToReleased(ProductionOrderNo: Code[20]): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.Get(ProductionOrder.Status::Planned, ProductionOrderNo);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Released, WorkDate, false);
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        ProductionOrder.SetRange("Source No.", ProductionOrder."Source No.");
        ProductionOrder.FindFirst;
        exit(ProductionOrder."No.");
    end;

    [Normal]
    local procedure UpdateLessQtyOutputJournal(ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindSet;
        repeat
            ItemJournalLine.Validate("Output Quantity", ProductionOrder.Quantity - 1);
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next = 0;
    end;

    [Normal]
    local procedure CountBOMComponents(ProductionBOMNo: Code[20]): Integer
    var
        ProductionBOMLine: Record "Production BOM Line";
        CountBOMComponents: Integer;
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        CountBOMComponents := ProductionBOMLine.Count();
        exit(CountBOMComponents);
    end;

    [Normal]
    local procedure CountRoutingLines(RoutingNo: Code[20]): Integer
    var
        RoutingLine: Record "Routing Line";
        CountRoutingLines: Integer;
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        CountRoutingLines := RoutingLine.Count();
        exit(CountRoutingLines);
    end;

    [Normal]
    local procedure ActProdOrderComponentQuantity(ProductionOrderNo: Code[20]; RoutingLinkCode: Code[20]; Status: Enum "Production Order Status"; RoutingLinkCodeExist: Boolean): Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ActualProdOrderQuantity: Decimal;
    begin
        if Status <> Status::Released then
            ProdOrderComponent.SetRange(Status, Status::Finished)
        else
            ProdOrderComponent.SetRange(Status, Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        if RoutingLinkCodeExist then
            ProdOrderComponent.SetRange("Routing Link Code", RoutingLinkCode);
        ProdOrderComponent.FindSet;
        repeat
            ProdOrderComponent.CalcFields("Act. Consumption (Qty)");
            ActualProdOrderQuantity += ProdOrderComponent."Act. Consumption (Qty)";
        until ProdOrderComponent.Next = 0;
        exit(ActualProdOrderQuantity);
    end;

    [Normal]
    local procedure ItemLedgerConsumptionQuantity(var ItemLedgerEntry: Record "Item Ledger Entry"; ProductionOrderNo: Code[20]; ItemNo: Code[20]; RoutingLinkCodeExists: Boolean): Decimal
    var
        Quantity: Decimal;
    begin
        // Select Item Ledger Entry with specified filters.
        ItemLedgerEntry.SetRange("Document No.", ProductionOrderNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        if RoutingLinkCodeExists then
            ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet;
        repeat
            Quantity += ItemLedgerEntry.Quantity;
        until ItemLedgerEntry.Next = 0;
        exit(Abs(Quantity));
    end;

    [Normal]
    local procedure ItemLedgerOutputQuantity(var ItemLedgerEntry: Record "Item Ledger Entry"; ProductionOrderNo: Code[20]; ItemNo: Code[20]): Decimal
    var
        Quantity: Decimal;
    begin
        // Select Item Ledger Entry with specified filters.
        ItemLedgerEntry.SetRange("Document No.", ProductionOrderNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet;
        repeat
            Quantity += ItemLedgerEntry.Quantity;
        until ItemLedgerEntry.Next = 0;
        exit(Quantity);
    end;

    local procedure VerifyConsumptionQuantity(ProductionOrderNo: Code[20]; ItemNo: Code[20]; RoutingLinkCode: Code[10]; Status: Enum "Production Order Status"; RoutingLinkCodeExist: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Assert: Codeunit Assert;
        CalculatedQuantity: Decimal;
        ActualConsumptionQuantity: Decimal;
    begin
        // Select set of Item Ledger Entries for the specified Consumption Quantity.
        CalculatedQuantity := ItemLedgerConsumptionQuantity(ItemLedgerEntry, ProductionOrderNo, ItemNo, RoutingLinkCodeExist);

        if RoutingLinkCodeExist then
            ActualConsumptionQuantity := ActProdOrderComponentQuantity(ProductionOrderNo, RoutingLinkCode, Status, true)
        else
            ActualConsumptionQuantity := ActProdOrderComponentQuantity(ProductionOrderNo, RoutingLinkCode, Status, false);

        Assert.AreEqual(ActualConsumptionQuantity, CalculatedQuantity, ErrMessageConsumptionMissing);
    end;

    [Normal]
    local procedure VerifyFinishedItemLedgerEntry(ProductionOrderNo: Code[20]; ItemNo: Code[20]; ProductionOrderQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        CalulatedOutputQuantity: Decimal;
    begin
        CalulatedOutputQuantity := ItemLedgerOutputQuantity(ItemLedgerEntry, ProductionOrderNo, ItemNo);
        Assert.AreNotEqual(CalulatedOutputQuantity, ProductionOrderQuantity, ErrMessagePartialOutput)
    end;

    [Normal]
    local procedure VerifyComponentAfterRefresh(ProductionBOMNo: Code[20]; CountProductionBomComponent: Integer; RefreshComponents: Boolean)
    var
        CountComponents: Integer;
    begin
        // Count BOM Components of Item
        CountComponents := CountBOMComponents(ProductionBOMNo);

        // Verify :Compare BOM components with Production Order Components.
        if RefreshComponents then
            Assert.AreEqual(CountProductionBomComponent, CountComponents, ErrMessageRefreshComponentEql)
        else
            Assert.AreNotEqual(CountComponents, CountProductionBomComponent, ErrMessageRefreshNotEql);
    end;

    [Normal]
    local procedure VerifyRoutingAfterRefresh(RoutingNo: Code[20]; CountProductionRouting: Integer; RefreshRouting: Boolean)
    var
        CountRoutingLine: Integer;
    begin
        // Count Routing Line of Item
        CountRoutingLine := CountRoutingLines(RoutingNo);

        // Verify :Compare Routing lines with Production Order routing line.
        if RefreshRouting then
            Assert.AreEqual(CountProductionRouting, CountRoutingLine, ErrMessageRefreshRoutingEql)
        else
            Assert.AreNotEqual(CountRoutingLine, CountProductionRouting, ErrMessageRefreshRoutingNotEql);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalcStdCostMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Calculate Standard Cost for All Level.
        Choice := 2;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmText: Text[1024]; var Confirm: Boolean)
    begin
        Confirm := true;
    end;
}

