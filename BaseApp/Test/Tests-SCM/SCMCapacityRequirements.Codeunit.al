codeunit 137074 "SCM Capacity Requirements"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Capacity] [SCM]
        IsInitialized := false;
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CalendarMgt: Codeunit "Shop Calendar Management";
        IsInitialized: Boolean;
        WorkCenterEfficiencyError: Label 'Efficiency must have a value in Work Center: No.=%1. It cannot be zero or empty.';
        MachineCenterEfficiencyError: Label 'Efficiency must have a value in Machine Center: No.=%1. It cannot be zero or empty.';
        MachineCenterCapacityError: Label 'Capacity must have a value in Machine Center: No.=%1. It cannot be zero or empty.';
        WorkCenterCapacityError: Label 'Capacity must have a value in Work Center: No.=%1. It cannot be zero or empty.';
        MachineCenterBlockedError: Label 'Blocked must be equal to ''No''  in Machine Center: No.=%1. Current value is ''Yes''.';
        WorkCenterCenterBlockedError: Label 'Blocked must be equal to ''No''  in Work Center: No.=%1. Current value is ''Yes''.';
        GreaterEqualZeroError: Label 'The value must be greater than or equal to 0.';
        FirmPlannedProductionOrderCreated: Label 'Firm Planned Prod. Order';
        ProdOrderLineQuantityError: Label 'Quantity must have a value in Prod. Order Line';
        MachineCenterNoError: Label 'Operation %1 does not have a work center or a machine center defined';
        TopItemTotalCostErr: Label 'Total Cost for top item Line No. = %1 is not correct in BOM Cost Shares';
        WorkCenterWarningErr: Label 'Warning for Work Center Line No. = %1 is not correct in BOM Cost Shares';
        WorkCenterTotalCostErr: Label 'Total Cost for Work Center Line No. = %1 is not correct in BOM Cost Shares';
        BOMCostShareQtyErr: Label 'Wrong BOM Cost Share "Qty. per Parent" value';
        BOMCostShareCapCostErr: Label 'Wrong BOM Cost Share "Rolled-Up Capacity Cost"  value';
        TheGapErr: Label 'The gap for %1: %2 %3', Comment = '%1 - Work Center Code, %2 - Gap begin, %3 - Gap end.';

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterLoadWithFirmPlannedProductionOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        WorkCenterLoad: TestPage "Work Center Load";
        CapacityAvailable: Decimal;
        CapacityEfficiency: Decimal;
    begin
        // Setup: Create Production Item with Routing.
        Initialize;
        CreateProductionItemWithRoutingSetup(Item, false);
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate);

        // Calculate Capacity values for verifying Capacity on Page - Work Center Load.
        FindWorkCenter(WorkCenter, Item."Routing No.");
        CalculateCapacity(CapacityAvailable, CapacityEfficiency, WorkCenter, ProductionOrder."Starting Date");

        // Exercise: Open Work Center page.
        OpenWorkCenterLoadPage(WorkCenterLoad, WorkCenter."No.");

        // Verify: Verify Capacity Available and Capacity Efficiency on Page - Work Center Load.
        VerifyWorkCenterLoad(WorkCenterLoad, ProductionOrder."Starting Date", CapacityAvailable, CapacityEfficiency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MachineCenterWithNegativeEfficiencyError()
    begin
        // Setup.
        Initialize;
        MachineCenterWithNegativeCapacityAndEfficiency(true);  // Efficiency as True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MachineCenterWithNegativeCapacityError()
    begin
        // Setup.
        Initialize;
        MachineCenterWithNegativeCapacityAndEfficiency(false);  // Efficiency as False.
    end;

    local procedure MachineCenterWithNegativeCapacityAndEfficiency(Efficiency: Boolean)
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        MachineCenterCard: TestPage "Machine Center Card";
    begin
        // Create Work Center and Machine Center.
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");
        OpenMachineCenterCard(MachineCenterCard, MachineCenter."No.");

        // Exercise: Update Efficiency and Capacity with negative value on Machine Center Card Page. Use page because Efficiency and Capacity Field Property Min Value defined as 0.
        if Efficiency then
            asserterror MachineCenterCard.Efficiency.SetValue(-LibraryRandom.RandDec(10, 2))
        else
            asserterror MachineCenterCard.Capacity.SetValue(-LibraryRandom.RandDec(10, 2));

        // Verify: Verify Error message when updating negative value.
        Assert.ExpectedError(GreaterEqualZeroError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MachineCenterWithZeroCapacityAndCalculateMachineCenterCalendarError()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        // Setup: Create Work Center. Create Machine Center with Zero Capacity.
        Initialize;
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", 0);  // Capacity as 0 required.

        // Exercise: Calculate Machine Center Calendar.
        asserterror LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1M>', WorkDate), CalcDate('<1M>', WorkDate));

        // Verify: Verify Error message for Machine Center Capacity zero.
        Assert.ExpectedError(StrSubstNo(MachineCenterCapacityError, MachineCenter."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MachineCenterWithZeroEfficiencyAndCalculateMachineCenterCalendarError()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        // Setup: Create Work Center. Create Machine Center with Zero Efficiency.
        Initialize;
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandDec(100, 2));
        UpdateMachineCenterWithZeroEfficiency(MachineCenter);

        // Exercise: Calculate Machine Center Calendar.
        asserterror LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1M>', WorkDate), CalcDate('<1M>', WorkDate));

        // Verify: Verify Error message for Machine Center Efficiency zero.
        Assert.ExpectedError(StrSubstNo(MachineCenterEfficiencyError, MachineCenter."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterWithZeroCapacityAndCalculateWorkCenterCalendarError()
    var
        WorkCenter: Record "Work Center";
    begin
        // Setup: Create Work Center with Zero Capacity.
        Initialize;
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        UpdateWorkCenterWithZeroCapacity(WorkCenter);

        // Exercise: Calculate Work Center Calendar.
        asserterror LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate), CalcDate('<1M>', WorkDate));

        // Verify: Verify Error message for Work Center Capacity zero.
        Assert.ExpectedError(StrSubstNo(WorkCenterCapacityError, WorkCenter."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterWithZeroEfficiencyAndCalculateWorkCenterCalendarError()
    var
        WorkCenter: Record "Work Center";
    begin
        // Setup: Create Work Center with Zero Efficiency.
        Initialize;
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        UpdateWorkCenterWithZeroEfficiency(WorkCenter);

        // Exercise: Calculate Work Center Calendar.
        asserterror LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate), CalcDate('<1M>', WorkDate));

        // Verify: Verify Error message for Work Center Efficiency zero.
        Assert.ExpectedError(StrSubstNo(WorkCenterEfficiencyError, WorkCenter."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterWithNegativeEfficiencyError()
    begin
        // Setup.
        Initialize;
        WorkCenterWithNegativeCapacityAndEfficiency(true);  // Efficiency as True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterWithNegativeCapacityError()
    begin
        // Setup.
        Initialize;
        WorkCenterWithNegativeCapacityAndEfficiency(false);  // Efficiency as False.
    end;

    local procedure WorkCenterWithNegativeCapacityAndEfficiency(Efficiency: Boolean)
    var
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // Create Work Center.
        CreateWorkCenter(WorkCenter);
        OpenWorkCenterCard(WorkCenterCard, WorkCenter."No.");

        // Exercise: Update Efficiency and Capacity with negative value on Work Center Card Page. Use page because Efficiency and Capacity Field Property Min Value defined as 0.
        if Efficiency then
            asserterror WorkCenterCard.Efficiency.SetValue(-LibraryRandom.RandDec(10, 2))
        else
            asserterror WorkCenterCard.Capacity.SetValue(-LibraryRandom.RandDec(10, 2));

        // Verify: Verify Error message when updating negative value.
        Assert.ExpectedError(GreaterEqualZeroError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingWithBlockedMachineCenterError()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // Setup: Create Work Center and Create Blocked Machine Center. Create Routing Header.
        Initialize;
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandDec(100, 2));
        UpdateMachineCenterBlocked(MachineCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // Exercise: Create Routing line with Blocked Machine Center.
        asserterror CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Machine Center", MachineCenter."No.", false);

        // Verify: Verify Error message for Blocked Machine Center.
        Assert.ExpectedError(StrSubstNo(MachineCenterBlockedError, MachineCenter."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingWithBlockedWorkCenterError()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // Setup: Create Blocked Work Center. Create Routing Header.
        Initialize;
        CreateWorkCenter(WorkCenter);
        UpdateWorkCenterBlocked(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // Exercise: Create Routing line with Blocked Work Center.
        asserterror CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenter."No.", false);

        // Verify: Verify Error message for Blocked Work Center.
        Assert.ExpectedError(StrSubstNo(WorkCenterCenterBlockedError, WorkCenter."No."));
    end;

    [Test]
    [HandlerFunctions('CalculateStandardCostMenuHandler')]
    [Scope('OnPrem')]
    procedure CalculateStandardCostForItemWithRouting()
    var
        Item: Record Item;
        ChildItem: Record Item;
        RoutingLine: Record "Routing Line";
        ProductionBOMLine: Record "Production BOM Line";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        StandardCost: Decimal;
    begin
        // Setup: Create Production Item with Routing. Update Costing Method as Standard on Items.
        Initialize;
        CreateProductionItemWithRoutingSetup(Item, false);
        FindProductionBOMLine(ProductionBOMLine, Item."Production BOM No.");
        ChildItem.Get(ProductionBOMLine."No.");
        UpdateStandardCostingMethodOnItem(Item);
        UpdateStandardCostingMethodOnItem(ChildItem);

        // Update Unit Cost Per on Routing Line and update Unit Cost Calculation on Work Center.
        UpdateUnitCostPerOnRoutingLineAndReCertify(RoutingLine, Item."Routing No.");
        UpdateUnitCostCalculationOnWorkCenter(RoutingLine."No.");

        // Calculation of Standard Cost for verification.
        StandardCost := RoutingLine."Unit Cost per" + ChildItem."Standard Cost" * ProductionBOMLine."Quantity per";

        // Exercise: Calculate Standard Cost.
        CalculateStandardCost.CalcItem(Item."No.", false);  // Use Assembly List - False.

        // Verify: Verify New Standard Cost on Item record updated after Calculate Standard Cost.
        Item.Get(Item."No.");
        Item.TestField("Standard Cost", StandardCost);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingLineWithMoveAndWaitTime()
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        SalesHeader: Record "Sales Header";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Setup: Create Production Item with Routing and Sales Order.
        Initialize;
        CreateProductionItemWithRoutingSetup(Item, false);
        CreateSalesOrder(SalesHeader, Item."No.");

        // Exercise: Create Firm Planned Production Order from Sales Order.
        CreateFirmPlannedProductionOrderFromSalesOrder(SalesHeader);

        // Verify: Verify Move Time and Wait Time on Production Order Routing Line.
        FindFirmPlannedProdOrderLine(ProdOrderLine, Item."No.");
        VerifyOperationsTimeOnProdOrderRoutingLine(ProdOrderLine."Prod. Order No.", Item."Routing No.", RoutingLine.Type::"Work Center");
        VerifyOperationsTimeOnProdOrderRoutingLine(
          ProdOrderLine."Prod. Order No.", Item."Routing No.", RoutingLine.Type::"Machine Center");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingLineWithStartingDateAndTimeForFirmPlannedProdOrderFromSalesOrder()
    begin
        // Setup.
        Initialize;
        ProdOrderRoutingLineWithStartingDateAndTime(true);  // Firm Planned Prod Order From Sales Order as True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingLineWithStartingDateAndTimeForFirmPlannedProdOrder()
    begin
        // Setup.
        Initialize;
        ProdOrderRoutingLineWithStartingDateAndTime(false);  // Firm Planned Prod Order From Sales Order as False.
    end;

    local procedure ProdOrderRoutingLineWithStartingDateAndTime(FirmPlannedProdOrderFromSalesOrder: Boolean)
    var
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
    begin
        // Create Production Item with Routing and Firm Planned Production Order.
        CreateProductionItemWithRoutingSetup(Item, false);
        if FirmPlannedProdOrderFromSalesOrder then begin
            CreateSalesOrder(SalesHeader, Item."No.");
            CreateFirmPlannedProductionOrderFromSalesOrder(SalesHeader);
        end else
            CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate);
        FindFirmPlannedProdOrderLine(ProdOrderLine, Item."No.");

        // Exercise: Update Starting Date and Starting Time on Production Order Line different from previous value.
        UpdateStartingDateAndTimeOnProdOrderLine(ProdOrderLine);

        // Verify: Verify Starting Date and Starting Time on Production Order Routing Line.
        VerifyStartingDateAndTimeOnProdOrderRoutingLine(ProdOrderLine, Item."Routing No.", RoutingLine.Type::"Machine Center");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FirmPlannedProductionOrderWithoutCalculateLineZeroQuantityError()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Setup: Create Production Item with Routing and Sales Order.
        Initialize;
        CreateProductionItemWithRoutingSetup(Item, false);
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate);

        // Update Quantity as Zero on Production Order Line.
        FindFirmPlannedProdOrderLine(ProdOrderLine, Item."No.");
        UpdateProdOrderLineWithZeroQuantity(ProdOrderLine);

        // Exercise: Refresh Production Order with Calculate Line - False.
        asserterror LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // Verify: Verify Error message for Zero Production Order line Quantity.
        Assert.ExpectedError(ProdOrderLineQuantityError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderCapacityNeedWithFirmPlannedProdOrderFromSalesOrderForWorkCenter()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ProdOrderLine: Record "Prod. Order Line";
        WorkCenterLoad: TestPage "Work Center Load";
        ProdOrderCapacityNeedPage: TestPage "Prod. Order Capacity Need";
    begin
        // Setup: Create Item with routing Setup and Sales Order. Create Firm Planned Production Order from Sales Order.
        Initialize;
        CreateProductionItemWithRoutingSetup(Item, false);
        CreateSalesOrder(SalesHeader, Item."No.");
        CreateFirmPlannedProductionOrderFromSalesOrder(SalesHeader);
        FindFirmPlannedProdOrderLine(ProdOrderLine, Item."No.");

        // Open Work Center Load Page.
        FindWorkCenter(WorkCenter, Item."Routing No.");
        OpenWorkCenterLoadPage(WorkCenterLoad, WorkCenter."No.");
        FilterOnWorkCenterLoadPage(WorkCenterLoad, ProdOrderLine."Starting Date");
        ProdOrderCapacityNeedPage.Trap;

        // Exercise: Drilldown Allocated Quantity on Work Center Load Page and Open Prod Order Capacity Need Page.
        WorkCenterLoad.MachineCenterLoadLines.AllocatedQty.DrillDown;

        // Verify: Verify Allocated Time on Production Order Capacity Need Page.
        VerifyProdOrderCapacityNeed(
          ProdOrderCapacityNeedPage, ProdOrderCapacityNeed.Type::"Work Center", WorkCenter."No.", ProdOrderLine."Starting Date");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderCapacityNeedWithFirmPlannedProdOrderFromSalesOrderForMachineCenter()
    var
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ProdOrderLine: Record "Prod. Order Line";
        MachineCenterLoad: TestPage "Machine Center Load";
        ProdOrderCapacityNeedPage: TestPage "Prod. Order Capacity Need";
    begin
        // Setup: Create Item with routing Setup and Sales Order. Create Firm Planned Production Order from Sales Order.
        Initialize;
        CreateProductionItemWithRoutingSetup(Item, false);
        CreateSalesOrder(SalesHeader, Item."No.");
        CreateFirmPlannedProductionOrderFromSalesOrder(SalesHeader);
        FindFirmPlannedProdOrderLine(ProdOrderLine, Item."No.");

        // Open Machine Center Load page.
        FindRoutingLine(RoutingLine, Item."Routing No.", RoutingLine.Type::"Machine Center");
        OpenMachineCenterLoadPage(MachineCenterLoad, RoutingLine."No.");
        FilterOnMachineCenterLoadPage(MachineCenterLoad, ProdOrderLine."Starting Date");
        ProdOrderCapacityNeedPage.Trap;

        // Exercise: Drilldown Allocated Quantity on Machine Center Load Page and Open Prod Order Capacity Need Page.
        MachineCenterLoad.MachineCLoadLines.AllocatedQty.DrillDown;

        // Verify: Verify Allocated Time on Production Order Capacity Need Page.
        VerifyProdOrderCapacityNeed(
          ProdOrderCapacityNeedPage, ProdOrderCapacityNeed.Type::"Machine Center", RoutingLine."No.", ProdOrderLine."Starting Date");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingLineWithSendAheadQuantity()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Setup: Create Item with routing Setup and Sales Order. Create Firm Planned Production Order from Sales Order.
        Initialize;
        CreateProductionItemWithRoutingSetup(Item, false);
        CreateSalesOrder(SalesHeader, Item."No.");
        CreateFirmPlannedProductionOrderFromSalesOrder(SalesHeader);

        // Update Send Ahead Quantity on Routing Line.
        UpdateSendAheadQuantityOnRoutingLineAndReCertify(Item."Routing No.");
        FindFirmPlannedProdOrderLine(ProdOrderLine, Item."No.");
        ProductionOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");

        // Exercise: Refresh Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // Verify: Verify Send Ahead Quantity on Production Order Routing Line.
        VerifySendAheadQuantityOnProdOrderRoutingLine(
          ProductionOrder."No.", Item."Routing No.", ProdOrderRoutingLine.Type::"Machine Center");
        VerifySendAheadQuantityOnProdOrderRoutingLine(ProductionOrder."No.", Item."Routing No.", ProdOrderRoutingLine.Type::"Work Center");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRoutingLineWithOperationsTimeAndCalcRegenPlan()
    var
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Setup: Create Item with routing Setup and Reorder Policy as Lot For Lot. Create Sales Order.
        Initialize;
        CreateProductionItemWithRoutingSetup(Item, false);
        UpdateLotForLotReorderingPolicyOnItem(Item);
        CreateSalesOrder(SalesHeader, Item."No.");

        // Exercise: Calculate Plan for Planning Worksheet.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // Verify: Verify Move Time and Wait Time on Planning Routing Line.
        VerifyOperationsTimeOnPlanningRoutingLine(Item."Routing No.", RoutingLine.Type::"Work Center");
        VerifyOperationsTimeOnPlanningRoutingLine(Item."Routing No.", RoutingLine.Type::"Machine Center");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRoutingLineWithSendAheadQuantityAndCalcRegenPlan()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        // Setup: Create Item with routing Setup and Reorder Policy as Lot For Lot. Update Send Ahead Quantity on Routing line and Create Sales Order.
        Initialize;
        CreateProductionItemWithRoutingSetup(Item, false);
        UpdateLotForLotReorderingPolicyOnItem(Item);

        UpdateSendAheadQuantityOnRoutingLineAndReCertify(Item."Routing No.");
        CreateSalesOrder(SalesHeader, Item."No.");

        // Exercise: Calculate Plan for Planning Worksheet.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // Verify: Verify Send Ahead Quantity on Planning Routing Line.
        VerifySendAheadQuantityOnPlanningRoutingLine(Item."Routing No.", PlanningRoutingLine.Type::"Work Center");
        VerifySendAheadQuantityOnPlanningRoutingLine(Item."Routing No.", PlanningRoutingLine.Type::"Machine Center");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingWithoutMachineCenterError()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // Setup: Create Routing Header, Routing Line.
        Initialize;
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Machine Center", '', false);  // Machine Center No. should be empty.

        // Exercise: Update Routing Status to Certified.
        asserterror UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);

        // Verify: Verify Machine Center No. blank error when change Status of Routing.
        Assert.ExpectedError(StrSubstNo(MachineCenterNoError, RoutingLine."Operation No."));
    end;

    [Test]
    [HandlerFunctions('CalculateStandardCostMenuHandler,BOMCostSharesPageHandler')]
    [Scope('OnPrem')]
    procedure RunBOMCostSharesForItemWithUnitCostCalcuWorkCenterOnRtngLine()
    var
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        Item: Record Item;
        RoutingLine: Record "Routing Line";
    begin
        // Setup: Create Production Item with Routing without filling Setup Time/Run Time/Wait Time/Move Time.
        Initialize;
        CreateProductionItemWithoutRoutingTime(Item);

        // Update Unit Cost Per on Routing Line and update Unit Cost Calculation on Work Center.
        UpdateUnitCostPerOnRoutingLineAndReCertify(RoutingLine, Item."Routing No.");
        UpdateUnitCostCalculationOnWorkCenter(RoutingLine."No.");

        // Exercise: Calculate Standard Cost.
        CalculateStandardCost.CalcItem(Item."No.", false);  // Use Assembly List - False.

        Item.Get(Item."No.");
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(RoutingLine."Routing No.");
        LibraryVariableStorage.Enqueue('');

        RunBOMCostSharesPage(Item);

        // Verify: Cost fields on BOM Cost Shares page: In BOMCostSharesPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyOperationDateOnProdRoutingLine()
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        ProdOrder: Record "Production Order";
        MachineCenter: Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        StartingDateTime: DateTime;
    begin
        // Setup: Create Production Item with Routing, create and refresh Firm Planned Production Order.
        CreateProductionItemWithRoutingSetup(Item, false);
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProdOrder, Item."No.", LibraryRandom.RandIntInRange(5, 100), WorkDate);
        FindRoutingLine(RoutingLine, ProdOrder."Routing No.", RoutingLine.Type::"Machine Center");
        MachineCenter.Get(RoutingLine."No.");

        // Exercise: Update Send-Ahead Quantity, Concurrent Capacities and Starting Date-Time on the first Prod. Order Routing Line.
        UpdateProdOrderRoutingLine(
          ProdOrderRoutingLine, ProdOrder."No.", RoutingLine.Type, RoutingLine."No.",
          ProdOrder.Quantity - LibraryRandom.RandInt(4), MachineCenter.Capacity); // Send-Ahead Quantity should be less than ProdOrder.Quantity.

        StartingDateTime :=
          ProdOrderRoutingLine."Starting Date-Time" +
          Round(
            (ProdOrderRoutingLine."Setup Time" + ProdOrderRoutingLine."Wait Time" + ProdOrderRoutingLine."Move Time" +
             ProdOrderRoutingLine."Run Time" * ProdOrderRoutingLine."Send-Ahead Quantity" /
             ProdOrderRoutingLine."Concurrent Capacities") *
            CalendarMgt.TimeFactor(MachineCenter."Setup Time Unit of Meas. Code"), 1);

        // Verify: Verify Starting Date-Time on the second Production Order Routing Line.
        VerifyStartingDateTimeOnProdOrderRoutingLine(
          ProdOrder."Routing No.", ProdOrder."No.", RoutingLine.Type::"Work Center", StartingDateTime);
    end;

    [Test]
    [HandlerFunctions('BOMCostSharesVerifyQtyPageHandler')]
    [Scope('OnPrem')]
    procedure CheckBOMCostShareLineQtyWithMultipleUOM()
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        ExpectedQty: Decimal;
    begin
        // Verify BOM Cost Shares "Qty. per Parent" value when multiple UOM is used
        Initialize;
        CreateProductionItemWithRoutingSetup(Item, true);
        FindRoutingLine(RoutingLine, Item."Routing No.", RoutingLine.Type::"Machine Center");
        FindWorkCenter(WorkCenter, Item."Routing No.");

        ExpectedQty :=
          Round(
            CalcRoutingLineQtyBase(RoutingLine) /
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
            0.0001);

        LibraryVariableStorage.Enqueue(RoutingLine."No.");
        LibraryVariableStorage.Enqueue(ExpectedQty);
        RunBOMCostSharesPage(Item);

        // Verify Quantity field on BOM Cost Shares page: In BOMCostSharesVerifyQtyPageHandler.
    end;

    [Test]
    [HandlerFunctions('CalculateStandardCostMenuHandler,BOMCostSharesPageHandler')]
    [Scope('OnPrem')]
    procedure BOMCostSharePageBlankItemFilter()
    var
        ItemFilter: Record Item;
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // [FEATURE] [BOM Cost Share]
        // [SCENARIO 377878] BOM Cost Share Page should not calculate Tree for Items without BOM and Routing
        Initialize;

        // [GIVEN] Item "X" without BOM and Routing
        CreateItem(Item, Item."Replenishment System"::Purchase);

        // [GIVEN] Item "Y" with Routing and BOM
        CreateProductionItemWithoutRoutingTime(Item);
        CalculateStandardCost.CalcItem(Item."No.", false);
        FindRoutingLine(RoutingLine, Item."Routing No.", RoutingLine.Type::"Work Center");
        Item.Get(Item."No.");
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(RoutingLine."Routing No.");
        LibraryVariableStorage.Enqueue('');

        // [WHEN] Run BOM Cost Share Page with ItemFilter blank
        ItemFilter.Init();
        RunBOMCostSharesPage(ItemFilter);

        // [THEN] Cost fields for Item "Y" are calculated where Item "X" is not considered
        // Verify through BOMCostSharesPageHandler
    end;

    [Test]
    [HandlerFunctions('BOMCostSharesCapCostHandler')]
    [Scope('OnPrem')]
    procedure BOMCostShareDifferentTimeUnit()
    var
        Item: Record Item;
        RoutingNo: Code[20];
        WorkCenterNo: Code[20];
    begin
        // [FEATURE] [BOM Cost Share] [Rounding]
        // [SCENARIO 377848] BOM Cost Shares should increase rounding precision while transmission time unit
        Initialize;

        // [GIVEN] Work Center "W" with Unit of Measure Code = "Hours" and Direct Unit Cost = 10000
        WorkCenterNo := CreateWorkCenterWithDirectCost(10000);

        // [GIVEN] Routing "R" with Work Center "W" and Run time = 60 Minutes
        RoutingNo := CreateRoutingWithRunTime(WorkCenterNo, 60);

        // [GIVEN] Item "I" with Routing "R"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);

        // [WHEN] Run Cost Share for Item "I"
        LibraryVariableStorage.Enqueue(WorkCenterNo);
        LibraryVariableStorage.Enqueue(10000);
        RunBOMCostSharesPage(Item);

        // [THEN] BOM Cost Share is created with Rolled-Up Capacity Cost = 10000
        // Verify in BOMCostSharesCapCostHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConcurrentCapacitiesOnProdOrderRoutingLine()
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        ProdOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Routing] [Production Order]
        // [SCENARIO 378850] Concurrent Capacities of Prod. Order Routing Line should not be blank if Capacity is greater then 1
        Initialize;

        // [GIVEN] Machine Center "M" with "Capacity" > 1 and "Concurrent Capacities" = 0
        CreateProductionItemWithRoutingSetup(Item, false);

        // [GIVEN] Create and refresh Production Order
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProdOrder, Item."No.", LibraryRandom.RandIntInRange(5, 100), WorkDate);

        // [WHEN] Set "Routing No." to "M" on Prod. Order Routing Line
        FindRoutingLine(RoutingLine, ProdOrder."Routing No.", RoutingLine.Type::"Machine Center");
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrder."No.", RoutingLine.Type, RoutingLine."No.");
        ProdOrderRoutingLine.Validate("No.");

        // [THEN] Concurrent Capacity is 1
        ProdOrderRoutingLine.TestField("Concurrent Capacities", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshPOSerialBackward()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        WorkCenterCode: array[2] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when refresh production order backward for item with serial routing with send-ahead quantity
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithSerialRoutingReorder(Item, WorkCenterCode, Item."Reordering Policy"::"Lot-for-Lot", 0);

        // [WHEN] Refresh Planned Production Order for "I" Backward
        CreateAndRefreshPlannedProductionOrder(ProdOrder, Item."No.", 100, false);

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanPOSerialBackward()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WorkCenterCode: array[2] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when calculate regenerative plan backward for item with serial routing with send-ahead quantity
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithSerialRoutingReorder(Item, WorkCenterCode, Item."Reordering Policy"::"Lot-for-Lot", 0);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo, Item."No.", 100, '', WorkDate);

        // [WHEN] Calculate regenerative plan backward for "I" Production Order
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshPOSerialForward()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        WorkCenterCode: array[2] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when refresh production order forward for item with serial routing with send-ahead quantity
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithSerialRoutingReorder(Item, WorkCenterCode, Item."Reordering Policy"::"Lot-for-Lot", 0);

        // [WHEN] Refresh Planned Production Order for "I" Forward
        CreateAndRefreshPlannedProductionOrder(ProdOrder, Item."No.", 100, true);

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanPOSerialForward()
    var
        Item: Record Item;
        WorkCenterCode: array[2] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when calculate regenerative plan forward for item with serial routing with send-ahead quantity
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithSerialRoutingReorder(Item, WorkCenterCode, Item."Reordering Policy"::"Fixed Reorder Qty.", 100);

        // [WHEN] Calculate regenerative plan forward for "I" Production Order
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshPOParallelBackward()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        WorkCenterCode: array[4] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when refresh production order backward for item with parallel routing with send-ahead quantity
        Initialize;

        // [GIVEN] Production Item "I" with Parallel Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithParallelRouting(Item, WorkCenterCode, Item."Reordering Policy"::"Lot-for-Lot", 0);

        // [WHEN] Refresh Planned Production Order for "I" Backward
        CreateAndRefreshPlannedProductionOrder(ProdOrder, Item."No.", 100, false);

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanPOParallelBackward()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WorkCenterCode: array[4] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when calculate regenerative plan backward for item with parallel routing with send-ahead quantity
        Initialize;

        // [GIVEN] Production Item "I" with Parallel Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithParallelRouting(Item, WorkCenterCode, Item."Reordering Policy"::"Lot-for-Lot", 0);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo, Item."No.", 100, '', WorkDate);

        // [WHEN] Calculate regenerative plan backward for "I" Production Order
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshPOParallelForward()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        WorkCenterCode: array[4] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when refresh production order forward for item with parallel routing with send-ahead quantity
        Initialize;

        // [GIVEN] Production Item "I" with Parallel Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithParallelRouting(Item, WorkCenterCode, Item."Reordering Policy"::"Lot-for-Lot", 0);

        // [WHEN] Refresh Planned Production Order for "I" Forward
        CreateAndRefreshPlannedProductionOrder(ProdOrder, Item."No.", 100, true);

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanPOParallelForward()
    var
        Item: Record Item;
        WorkCenterCode: array[4] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when calculate regenerative plan forward for item with parallel routing with send-ahead quantity
        Initialize;

        // [GIVEN] Production Item "I" with Parallel Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithParallelRouting(Item, WorkCenterCode, Item."Reordering Policy"::"Fixed Reorder Qty.", 100);

        // [WHEN] Calculate regenerative plan forward for "I" Production Order
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate);

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardProdOrderWithZeroSendAhead()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 286758] Refresh Release Production Order in Backward direction in case of Send-Ahead = 0 and "Run Time" > 0.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity = 0 and "Run Time" 60, 120, 180 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 60;
            SendAheadQty[i] := 0;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200128D);

        // . |----|
        // .      |-------|
        // [THEN] "Starting Date-Time" of "Prod. Order Routing Line" is earlier than "Starting Date-Time" of the next "Prod. Order Routing Line".
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is equal to "Starting Date-Time" of the next "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardProdOrderWithNonZeroSendAhead()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 286758] Refresh Release Production Order in Backward direction in case of Send-Ahead > 0 and "Run Time" > 0.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 10, 35, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200128D);

        // . |-------|
        // .     |-----------|
        // [THEN] "Starting Date-Time" of "Prod. Order Routing Line" is earlier than "Starting Date-Time" of the next "Prod. Order Routing Line" by value "Run Time" * "Send-Ahead Qty".
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is later than "Starting Date-Time" of the next "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardProdOrderWhenSendAheadLargerOrderQty()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 286758] Refresh Release Production Order in Backward direction in case of Send-Ahead > Quantify of a Production Order.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 13, 15 and "Run Time" 60, 120, 180 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 60;
            SendAheadQty[i] := i * 2 + 11;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200128D);

        // . |----|
        // .      |-------|
        // [THEN] "Starting Date-Time" of "Prod. Order Routing Line" is earlier than "Starting Date-Time" of the next "Prod. Order Routing Line".
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is equal to "Starting Date-Time" of the next "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardProdOrderWhenEndTimePrevLargerEndTimeNext()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 286758] Refresh Release Production Order in Backward direction in case of End Time of the previous line is later than Start Time of the next line for the residual quantity.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 2, 5 and "Run Time" 70, 93, 90 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        SetRunTime(RunTime, 70, 93, 90);
        SendAheadQty[1] := 2;
        SendAheadQty[2] := 5;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200128D);

        // . |-------------|
        // .     |-------|----|
        // .             {    } --> (Residual Quantity * Run Time), i.e. 5 * 90 = 450;  Starting Time of the Residual Qty for the last Route line is 23:00 - 450 = 15:30.
        // .                               Ending Time for the Previous line with working hours 08:00 - 16:00 is (23:00 - 10 * 90) + (10 - 5) * 93 = 08:00 + 465 = 15:45.
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is earlier than or equal to "Starting Date-Time" of the next "Prod. Order Routing Line" for the residual quantity.
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardProdOrderWhenEndTimeIsOutOfWorkingHours()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 286758] Refresh Release Production Order in Backward direction in case of End Time of the line is later than "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 90, 72, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        SetRunTime(RunTime, 90, 72, 60);
        SendAheadQty[1] := 3;
        SendAheadQty[2] := 5;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200128D);

        // . {          } --> operational hours
        // .   |------------|
        // .       |------------|
        // [THEN] "Starting Time" and "Ending Time" of "Prod. Order Routing Line" are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200123D, 090000T), CreateDateTime(20200127D, 140000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200124D, 120000T), CreateDateTime(20200127D, 160000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200123D, 090000T), CreateDateTime(20200127D, 140000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200124D, 120000T), CreateDateTime(20200127D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardProdOrderWhenConcurrentCapacitiesLargerThanOne()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        WorkCenterEfficiency: array[3] of Decimal;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        ConcurrentCapacities: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Backward direction in case of "Concurrent Capacities" > 1 and Efficiency < 100.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 2, 35, 120 minutes; "Concurrent Capacities" = 1, 2, 2; Efficiency = 20, 50, 100.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            SendAheadQty[i] := i * 2 + 1;
            WorkCenterEfficiency[i] := 10 * i * i + 10;
        end;
        SetRunTime(RunTime, 2, 35, 120);
        SetConcurrentCapacities(ConcurrentCapacities, 1, 2, 2);

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingConcurrentCapacities(
          Item, WorkCenterCode, SetupTime, RunTime, SendAheadQty, ConcurrentCapacities,
          WorkCenterStartTime, WorkCenterEndTime, WorkCenterEfficiency, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200128D);

        // . |-------|
        // .     |-----------|
        // [THEN] "Concurrent Capacities" and Efficiency of Work Center are considered in calculation of "Starting Time" and "Ending Time".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardPlanningLineWithZeroSendAhead()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 286758] Refresh Planning Line in Backward direction in case of Send-Ahead = 0 and "Run Time" > 0.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity = 0 and "Run Time" 60, 120, 180 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 60;
            SendAheadQty[i] := 0;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200128D);

        // . |----|
        // .      |-------|
        // [THEN] "Starting Date-Time" of "Planning Routing Line" is earlier than "Starting Date-Time" of the next "Planning Routing Line".
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is equal to "Starting Date-Time" of the next "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardPlanningLineWithNonZeroSendAhead()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 286758] Refresh Planning Line in Backward direction in case of Send-Ahead > 0 and "Run Time" > 0.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 10, 35, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200128D);

        // . |-------|
        // .     |-----------|
        // [THEN] "Starting Date-Time" of "Planning Routing Line" is earlier than "Starting Date-Time" of the next "Planning Routing Line" by value "Run Time" * "Send-Ahead Qty".
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is later than "Starting Date-Time" of the next "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardPlanningLineWhenSendAheadLargerOrderQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 286758] Refresh Planning Line in Backward direction in case of Send-Ahead > Quantify of a Production Order.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 13, 15 and "Run Time" 60, 120, 180 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 60;
            SendAheadQty[i] := i * 2 + 11;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200128D);

        // . |----|
        // .      |-------|
        // [THEN] "Starting Date-Time" of "Planning Routing Line" is earlier than "Starting Date-Time" of the next "Planning Routing Line".
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is equal to "Starting Date-Time" of the next "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardPlanningLineWhenEndTimePrevLargerEndTimeNext()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 286758] Refresh Planning Line in Backward direction in case of End Time of the previous line is later than Start Time of the next line for the residual quantity.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 2, 5 and "Run Time" 70, 93, 90 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        SetRunTime(RunTime, 70, 93, 90);
        SendAheadQty[1] := 2;
        SendAheadQty[2] := 5;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200128D);

        // . |-------------|
        // .     |-------|----|
        // .             {    } --> (Residual Quantity * Run Time), i.e. 5 * 90 = 450;  Starting Time of the Residual Qty for the last Route line is 23:00 - 450 = 15:30.
        // .                               Ending Time for the Previous line with working hours 08:00 - 16:00 is (23:00 - 10 * 90) + (10 - 5) * 93 = 08:00 + 465 = 15:45.
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is earlier than or equal to "Starting Date-Time" of the next "Planning Routing Line" for the residual quantity.
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardPlanningLineWhenEndTimeIsOutOfWorkingHours()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 286758] Refresh Planning Line in Backward direction in case of End Time of the line is later than "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 90, 72, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        SetRunTime(RunTime, 90, 72, 60);
        SendAheadQty[1] := 3;
        SendAheadQty[2] := 5;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200128D);

        // . {          } --> operational hours
        // .  |------------|
        // .      |------------|
        // [THEN] "Starting Time" and "Ending Time" of "Planning Routing Line" are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200123D, 090000T), CreateDateTime(20200127D, 140000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200124D, 120000T), CreateDateTime(20200127D, 160000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200123D, 090000T), CreateDateTime(20200127D, 140000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200124D, 120000T), CreateDateTime(20200127D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardPlanningLineWhenConcurrentCapacitiesLargerThanOne()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        WorkCenterEfficiency: array[3] of Decimal;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        ConcurrentCapacities: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Backward direction in case of "Concurrent Capacities" > 1 and Efficiency < 100.
        Initialize;

        // [GIVEN] Production Item "I" with Send-ahead Quantity 3, 5; "Run Time" 2, 35, 120 minutes; "Concurrent Capacities" = 1, 2, 2; Efficiency = 20, 50, 100.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            SendAheadQty[i] := i * 2 + 1;
            WorkCenterEfficiency[i] := 10 * i * i + 10;
        end;
        SetRunTime(RunTime, 2, 35, 120);
        SetConcurrentCapacities(ConcurrentCapacities, 1, 2, 2);

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingConcurrentCapacities(
          Item, WorkCenterCode, SetupTime, RunTime, SendAheadQty, ConcurrentCapacities,
          WorkCenterStartTime, WorkCenterEndTime, WorkCenterEfficiency, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200128D);

        // . |-------|
        // .     |-----------|
        // [THEN] "Concurrent Capacities" and Efficiency of Work Center are considered in calculation of "Starting Time" and "Ending Time" of "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWithZeroSendAhead()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of Send-Ahead = 0 and "Run Time" > 0.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity = 0 and "Run Time" 180, 120, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 08:00 - 23:00, 08:00 - 16:00, 09:00 - 14:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := (4 - i) * 60;
            SendAheadQty[i] := 0;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 080000T, 230000T, 080000T, 160000T, 090000T, 140000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 17.01.20, Starting Time = 12:00.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200117D, 120000T);

        // . |----|
        // .      |-------|
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is equal to "Starting Date-Time" of the next "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200124D, 090000T), CreateDateTime(20200127D, 140000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200124D, 090000T), CreateDateTime(20200127D, 140000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWithNonZeroSendAhead()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of Send-Ahead > 0 and "Run Time" > 0.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 10, 35, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 08:00 - 23:00, 08:00 - 16:00, 09:00 - 14:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time = 09:35.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Starting Date-Time" of "Prod. Order Routing Line" is earlier than "Starting Date-Time" of the next "Prod. Order Routing Line" by value "Run Time" * "Send-Ahead Qty".
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is later than "Starting Date-Time" of the next "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWhenSendAheadLargerOrderQty()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of Send-Ahead > Quantify of a Production Order.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 13, 15 and "Run Time" 60, 120, 180 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 60;
            SendAheadQty[i] := i * 2 + 11;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 17.01.20, Starting Time = 12:00.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200117D, 120000T);

        // . |----|
        // .      |-------|
        // [THEN] "Starting Date-Time" of "Prod. Order Routing Line" is earlier than "Starting Date-Time" of the next "Prod. Order Routing Line".
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is equal to "Starting Date-Time" of the next "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200123D, 160000T), CreateDateTime(20200127D, 160000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200123D, 160000T), CreateDateTime(20200127D, 160000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWhenEndTimePrevLargerEndTimeNext()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of End Time of the previous line is later than Start Time of the next line for the residual quantity.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 2, 5 and "Run Time" 70, 93, 90 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        SetRunTime(RunTime, 70, 93, 90);
        SendAheadQty[1] := 2;
        SendAheadQty[2] := 5;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Due Date is 23.01.20, Starting Time is 10:44.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200123D, 104400T);

        // . |-------------|
        // .     |-------|----|
        // .             {    } --> (Residual Quantity * Run Time), i.e. 5 * 90 = 450;  Starting Time of the Residual Qty for the last Route line is 23:00 - 450 = 15:30.
        // .                               Ending Time for the Previous line with working hours 08:00 - 16:00 is (23:00 - 10 * 90) + (10 - 5) * 93 = 08:00 + 465 = 15:45.
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is earlier than or equal to "Starting Date-Time" of the next "Prod. Order Routing Line" for the residual quantity.
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWhenStartTimeIsOutOfWorkingHours()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of Start Time of the line is later than "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 6 and "Run Time" 90, 72, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 08:00 - 23:00, 08:00 - 16:00, 09:00 - 14:00.
        SetRunTime(RunTime, 90, 72, 60);
        SendAheadQty[1] := 3;
        SendAheadQty[2] := 6;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 080000T, 230000T, 080000T, 160000T, 090000T, 140000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 23.01.20, Starting Time is 12:00.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200123D, 120000T);

        // .   |------------|
        // .       |------------|
        // . {   } --> operational hours
        // [THEN] "Starting Time" and "Ending Time" of "Prod. Order Routing Line" are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200123D, 120000T), CreateDateTime(20200124D, 120000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 120000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 090000T), CreateDateTime(20200128D, 140000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200123D, 120000T), CreateDateTime(20200124D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 090000T), CreateDateTime(20200128D, 140000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWithSetupTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of "Setup Time" > 0.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Setup Time" = 3.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 3;
            WaitTime[i] := 0;
            MoveTime[i] := 0;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time = 09:35.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Setup Time" is added to the start of production period for every "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111800T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 100800T), CreateDateTime(20200128D, 080100T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 175800T), CreateDateTime(20200128D, 130100T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Prod. Order Routing Line" by value "Wait Time" + "Move Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111800T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200127D, 100800T), CreateDateTime(20200128D, 080100T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 175800T), CreateDateTime(20200128D, 130100T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], SetupTime[i] + 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWhenConcurrentCapacitiesLargerThanOne()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        WorkCenterEfficiency: array[3] of Decimal;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        ConcurrentCapacities: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of "Concurrent Capacities" > 1 and Efficiency < 100.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 2, 35, 120 minutes; "Concurrent Capacities" = 1, 2, 2; Efficiency = 20, 50, 100.
        // [GIVEN] Three Work Centers with operational hours: 08:00 - 23:00, 08:00 - 16:00, 09:00 - 14:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            SendAheadQty[i] := i * 2 + 1;
            WorkCenterEfficiency[i] := 10 * i * i + 10;
        end;
        SetRunTime(RunTime, 2, 35, 120);
        SetConcurrentCapacities(ConcurrentCapacities, 1, 2, 2);

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingConcurrentCapacities(
          Item, WorkCenterCode, SetupTime, RunTime, SendAheadQty, ConcurrentCapacities,
          WorkCenterStartTime, WorkCenterEndTime, WorkCenterEfficiency, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time = 09:35.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Concurrent Capacities" and Efficiency of Work Center are considered in calculation of "Starting Time" and "Ending Time" of "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWithWaitMoveTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of "Wait Time" > 0 and "Move Time" > 0.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Wait Time" = 2; "Move Time" = 3.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            WaitTime[i] := 2;
            MoveTime[i] := 3;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time = 09:35.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Wait Time" and "Move Time" are added to the end of production period for every "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst;
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 112000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 101000T), CreateDateTime(20200128D, 080300T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 180300T), CreateDateTime(20200128D, 130800T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Prod. Order Routing Line" by value "Wait Time" + "Move Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200127D, 101000T), CreateDateTime(20200127D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 180300T), CreateDateTime(20200128D, 130300T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWithZeroSendAhead()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of Send-Ahead = 0 and "Run Time" > 0.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity = 0 and "Run Time" 180, 120, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 08:00 - 23:00, 08:00 - 16:00, 09:00 - 14:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := (4 - i) * 60;
            SendAheadQty[i] := 0;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 080000T, 230000T, 080000T, 160000T, 090000T, 140000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 17.01.20, Starting Time is 12:00.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200117D, 120000T);

        // . |----|
        // .      |-------|
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is equal to "Starting Date-Time" of the next "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200124D, 090000T), CreateDateTime(20200127D, 140000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200124D, 090000T), CreateDateTime(20200127D, 140000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWithNonZeroSendAhead()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of Send-Ahead > 0 and "Run Time" > 0.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 10, 35, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time is 09:35.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Starting Date-Time" of "Planning Routing Line" is earlier than "Starting Date-Time" of the next "Planning Routing Line" by value "Run Time" * "Send-Ahead Qty".
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is later than "Starting Date-Time" of the next "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWhenSendAheadLargerOrderQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of Send-Ahead > Quantify of a Production Order.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 13, 15 and "Run Time" 60, 120, 180 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 60;
            SendAheadQty[i] := i * 2 + 11;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 17.01.20, Starting Time is 12:00.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200117D, 120000T);

        // . |----|
        // .      |-------|
        // [THEN] "Starting Date-Time" of "Planning Routing Line" is earlier than "Starting Date-Time" of the next "Planning Routing Line".
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is equal to "Starting Date-Time" of the next "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200123D, 160000T), CreateDateTime(20200127D, 160000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200123D, 160000T), CreateDateTime(20200127D, 160000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWhenEndTimePrevLargerEndTimeNext()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of End Time of the previous line is later than Start Time of the next line for the residual quantity.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 2, 5 and "Run Time" 70, 93, 90 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        SetRunTime(RunTime, 70, 93, 90);
        SendAheadQty[1] := 2;
        SendAheadQty[2] := 5;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 23.01.20, Starting Time is 10:44.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200123D, 104400T);

        // . |-------------|
        // .     |-------|----|
        // .             {    } --> (Residual Quantity * Run Time), i.e. 5 * 90 = 450;  Starting Time of the Residual Qty for the last Route line is 23:00 - 450 = 15:30.
        // .                               Ending Time for the Previous line with working hours 08:00 - 16:00 is (23:00 - 10 * 90) + (10 - 5) * 93 = 08:00 + 465 = 15:45.
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is earlier than or equal to "Starting Date-Time" of the next "Planning Routing Line" for the residual quantity.
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWhenStartTimeIsOutOfWorkingHours()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of Start Time of the line is later than "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 90, 72, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 08:00 - 23:00, 08:00 - 16:00, 09:00 - 14:00.
        SetRunTime(RunTime, 90, 72, 60);
        SendAheadQty[1] := 3;
        SendAheadQty[2] := 6;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 080000T, 230000T, 080000T, 160000T, 090000T, 140000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 23.01.20, Starting Time is 12:00.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200123D, 120000T);

        // .   |------------|
        // .       |------------|
        // . {   } --> operational hours
        // [THEN] "Starting Time" and "Ending Time" of "Planning Routing Line" are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200123D, 120000T), CreateDateTime(20200124D, 120000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 120000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 090000T), CreateDateTime(20200128D, 140000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200123D, 120000T), CreateDateTime(20200124D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 090000T), CreateDateTime(20200128D, 140000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWithSetupTime()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of "Setup Time" > 0.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Setup Time" = 3.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 3;
            WaitTime[i] := 0;
            MoveTime[i] := 0;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time is 09:35.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Setup Time" is added to the start of the production period for every "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111800T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 100800T), CreateDateTime(20200128D, 080100T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 175800T), CreateDateTime(20200128D, 130100T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111800T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200127D, 100800T), CreateDateTime(20200128D, 080100T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 175800T), CreateDateTime(20200128D, 130100T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to "Setup Time" + Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name",
              WorkCenterCode[i], SetupTime[i] + 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWhenConcurrentCapacitiesLargerThanOne()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        WorkCenterEfficiency: array[3] of Decimal;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        ConcurrentCapacities: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of "Concurrent Capacities" > 1 and Efficiency < 100.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 2, 35, 120 minutes; "Concurrent Capacities" = 1, 2, 2; Efficiency = 20, 50, 100.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            SendAheadQty[i] := i * 2 + 1;
            WorkCenterEfficiency[i] := 10 * i * i + 10;
        end;
        SetRunTime(RunTime, 2, 35, 120);
        SetConcurrentCapacities(ConcurrentCapacities, 1, 2, 2);

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingConcurrentCapacities(
          Item, WorkCenterCode, SetupTime, RunTime, SendAheadQty, ConcurrentCapacities,
          WorkCenterStartTime, WorkCenterEndTime, WorkCenterEfficiency, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time = 09:35.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Concurrent Capacities" and Efficiency of Work Center are considered in calculation of "Starting Time" and "Ending Time".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWithWaitMoveTime()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of "Wait Time" > 0 and "Move Time" > 0.
        Initialize;

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Wait Time" = 2; "Move Time" = 3.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            WaitTime[i] := 2;
            MoveTime[i] := 3;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time is 09:35.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Wait Time" and "Move Time" are added to the end of production period for every "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst;
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 112000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 101000T), CreateDateTime(20200128D, 080300T));   // Wait Time is out of working hours
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 180300T), CreateDateTime(20200128D, 130800T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Planning Routing Line" by value "Wait Time" + "Move Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200127D, 101000T), CreateDateTime(20200127D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 180300T), CreateDateTime(20200128D, 130300T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Capacity Requirements");
        LibraryVariableStorage.Clear;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Capacity Requirements");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        NoSeriesSetup;
        Commit();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Capacity Requirements");
    end;

    local procedure NoSeriesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Option)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Standard Cost", LibraryRandom.RandDec(10, 2));
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
    end;

    local procedure CreateProductionItem(var Item: Record Item; ReorderingPolicy: Option; ReorderQuantity: Decimal)
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Reorder Quantity", ReorderQuantity);
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithSerialRoutingReorder(var Item: Record Item; var WorkCenterCode: array[2] of Code[10]; ReorderingPolicy: Option; ReorderQuantity: Decimal)
    var
        RoutingHeader: Record "Routing Header";
    begin
        CreateProductionItem(Item, ReorderingPolicy, ReorderQuantity);
        CreateSerialRoutingWithSendAhead(RoutingHeader, WorkCenterCode);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithSerialRoutingSendAhead(var Item: Record Item; var WorkCenterCode: array[3] of Code[20]; RunTime: array[3] of Decimal; SendAheadQty: array[3] of Integer; WorkCenterStartTime: array[3] of Time; WorkCenterEndTime: array[3] of Time; DueDate: Date)
    var
        SetupTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        WorkCenterEfficiency: array[3] of Decimal;
        ConcurrentCapacities: array[3] of Decimal;
        i: Integer;
    begin
        for i := 1 to ArrayLen(RunTime) do begin
            WorkCenterEfficiency[i] := 100;
            ConcurrentCapacities[i] := 1;
            SetupTime[i] := 0;
            WaitTime[i] := 0;
            MoveTime[i] := 0;
        end;
        CreateProductionItemWithSerialRouting(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ConcurrentCapacities,
          WorkCenterStartTime, WorkCenterEndTime, WorkCenterEfficiency, DueDate);
    end;

    local procedure CreateProductionItemWithSerialRoutingSetupWaitMoveTime(var Item: Record Item; var WorkCenterCode: array[3] of Code[20]; SetupTime: array[3] of Decimal; RunTime: array[3] of Decimal; WaitTime: array[3] of Decimal; MoveTime: array[3] of Decimal; SendAheadQty: array[3] of Integer; WorkCenterStartTime: array[3] of Time; WorkCenterEndTime: array[3] of Time; DueDate: Date)
    var
        WorkCenterEfficiency: array[3] of Decimal;
        ConcurrentCapacities: array[3] of Decimal;
        i: Integer;
    begin
        for i := 1 to ArrayLen(RunTime) do begin
            WorkCenterEfficiency[i] := 100;
            ConcurrentCapacities[i] := 1;
        end;
        CreateProductionItemWithSerialRouting(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ConcurrentCapacities,
          WorkCenterStartTime, WorkCenterEndTime, WorkCenterEfficiency, DueDate);
    end;

    local procedure CreateProductionItemWithSerialRoutingConcurrentCapacities(var Item: Record Item; var WorkCenterCode: array[3] of Code[20]; SetupTime: array[3] of Decimal; RunTime: array[3] of Decimal; SendAheadQty: array[3] of Integer; ConcurrentCapacities: array[3] of Decimal; WorkCenterStartTime: array[3] of Time; WorkCenterEndTime: array[3] of Time; WorkCenterEfficiency: array[3] of Decimal; DueDate: Date)
    var
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        i: Integer;
    begin
        for i := 1 to ArrayLen(RunTime) do begin
            WaitTime[i] := 0;
            MoveTime[i] := 0;
        end;
        CreateProductionItemWithSerialRouting(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ConcurrentCapacities,
          WorkCenterStartTime, WorkCenterEndTime, WorkCenterEfficiency, DueDate);
    end;

    local procedure CreateProductionItemWithSerialRouting(var Item: Record Item; var WorkCenterCode: array[3] of Code[20]; SetupTime: array[3] of Decimal; RunTime: array[3] of Decimal; WaitTime: array[3] of Decimal; MoveTime: array[3] of Decimal; SendAheadQty: array[3] of Integer; ConcurrentCapacities: array[3] of Decimal; WorkCenterStartTime: array[3] of Time; WorkCenterEndTime: array[3] of Time; WorkCenterEfficiency: array[3] of Decimal; DueDate: Date)
    var
        RoutingHeader: Record "Routing Header";
        Type: Option " ","100/Hour",Minutes,Hours,Days;
        i: Integer;
    begin
        for i := 1 to ArrayLen(WorkCenterStartTime) do
            WorkCenterCode[i] :=
              CreateWorkCenterWithShopCalendar(
                Type::Minutes,
                LibraryManufacturing.UpdateShopCalendarWorkingDaysCustomTime(WorkCenterStartTime[i], WorkCenterEndTime[i]),
                WorkCenterEfficiency[i], ConcurrentCapacities[i], DueDate);
        CreateProductionItem(Item, Item."Reordering Policy"::"Lot-for-Lot", 0);
        CreateSerialRoutingWithSendAheadAndWorkDays(
          RoutingHeader, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ConcurrentCapacities);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithParallelRouting(var Item: Record Item; var WorkCenterCode: array[4] of Code[10]; ReorderingPolicy: Option; ReorderQuantity: Decimal)
    var
        RoutingHeader: Record "Routing Header";
    begin
        CreateProductionItem(Item, ReorderingPolicy, ReorderQuantity);
        CreateParallelRoutingWithSendAhead(RoutingHeader, WorkCenterCode);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithRoutingSetup(var Item: Record Item; IsMultipleUOM: Boolean)
    var
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateItem(Item2, Item2."Replenishment System"::Purchase);
        CreateRoutingSetup(RoutingHeader, IsMultipleUOM);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."No.", Item."Base Unit of Measure");
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithoutRoutingTime(var Item: Record Item)
    var
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateItem(Item2, Item2."Replenishment System"::Purchase);
        CreateRoutingWithoutTimeSetup(RoutingHeader);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."No.", Item."Base Unit of Measure");
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; BaseUnitOfMeasure: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, 1);  // Quantity per as 1.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header"; IsMultipleUOM: Boolean)
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Machine Center", MachineCenter."No.", IsMultipleUOM);
        CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenter."No.", IsMultipleUOM);
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateSerialRoutingWithSendAhead(var RoutingHeader: Record "Routing Header"; var WorkCenterCode: array[2] of Code[20])
    var
        RoutingLine: Record "Routing Line";
        ShopCalendarCode: Code[10];
        Type: Option ,"100/Hour",Minutes,Hours,Days;
    begin
        ShopCalendarCode := CreateThreeShiftsShopCalendar;
        WorkCenterCode[1] := CreateWorkCenterWithShopCalendar(Type::Hours, ShopCalendarCode, 100, 1, WorkDate);
        WorkCenterCode[2] := CreateWorkCenterWithShopCalendar(Type::Hours, ShopCalendarCode, 100, 1, WorkDate);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLineWithSendAhead(
          RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterCode[1], 0, 0.12121, 0, 0, 6, 1, '10', '', '');
        CreateRoutingLineWithSendAhead(
          RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterCode[2], 0, 2.5, 0, 0, 0, 1, '20', '', '');
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateSerialRoutingWithSendAheadAndWorkDays(var RoutingHeader: Record "Routing Header"; WorkCenterCode: array[3] of Code[20]; SetupTime: array[3] of Decimal; RunTime: array[3] of Decimal; WaitTime: array[3] of Decimal; MoveTime: array[3] of Decimal; SendAheadQty: array[3] of Integer; ConcurrentCapacities: array[3] of Decimal)
    var
        RoutingLine: Record "Routing Line";
        OperationNo: Code[10];
        PrevOperationNo: Code[10];
        NextOperationNo: Code[10];
        i: Integer;
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for i := 3 downto 1 do begin
            OperationNo := Format(i * 10);
            PrevOperationNo := Format((i - 1) * 10);
            CreateRoutingLineWithSendAhead(
              RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center",
              WorkCenterCode[i], SetupTime[i], RunTime[i], WaitTime[i], MoveTime[i], SendAheadQty[i], ConcurrentCapacities[i],
              OperationNo, PrevOperationNo, NextOperationNo);
            NextOperationNo := OperationNo;
        end;
        RoutingLine."Previous Operation No." := '';
        RoutingLine.Modify();
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateParallelRoutingWithSendAhead(var RoutingHeader: Record "Routing Header"; var WorkCenterCode: array[4] of Code[20])
    var
        RoutingLine: Record "Routing Line";
        ShopCalendarCode: Code[10];
        Type: Option ,"100/Hour",Minutes,Hours,Days;
        i: Integer;
    begin
        ShopCalendarCode := CreateThreeShiftsShopCalendar;
        for i := 1 to ArrayLen(WorkCenterCode) do
            WorkCenterCode[i] := CreateWorkCenterWithShopCalendar(Type::Hours, ShopCalendarCode, 100, 1, WorkDate);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        CreateRoutingLineWithSendAhead(
          RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterCode[1], 0, 2.5, 0, 0, 0, 1, '10', '', '20|30');
        CreateRoutingLineWithSendAhead(
          RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterCode[2], 0, 0.12121, 0, 0, 6, 1, '20', '', '40');
        CreateRoutingLineWithSendAhead(
          RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterCode[3], 0, 2.5, 0, 0, 0, 1, '30', '', '40');
        CreateRoutingLineWithSendAhead(
          RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterCode[4], 0, 2.5, 0, 0, 0, 1, '40', '', '');
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateRoutingWithoutTimeSetup(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
        OperationNo: Code[10];
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type::"Work Center", WorkCenter."No.");
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateRoutingWithRunTime(WorkCenterNo: Code[20]; RunTime: Decimal): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        OperationNo: Code[10];
    begin
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Minutes);
        CapacityUnitOfMeasure.FindFirst;

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type::"Work Center", WorkCenterNo);
        with RoutingLine do begin
            Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
            Validate("Run Time", RunTime);
            Modify(true);
        end;
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);

        exit(RoutingHeader."No.");
    end;

    local procedure CreateWorkCenterWithDirectCost(DirectCost: Decimal): Code[20]
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        WorkCenter: Record "Work Center";
    begin
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Hours);
        CapacityUnitOfMeasure.FindFirst;

        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        with WorkCenter do begin
            Validate("Unit of Measure Code", CapacityUnitOfMeasure.Code);
            Validate("Direct Unit Cost", DirectCost);
            Modify(true);
        end;

        exit(WorkCenter."No.");
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(100, 2));
        with MachineCenter do begin
            Validate("Setup Time", LibraryRandom.RandDec(10, 2));
            Validate("Wait Time", LibraryRandom.RandDec(10, 2));
            Validate("Move Time", LibraryRandom.RandDec(10, 2));
            Validate(Capacity, LibraryRandom.RandIntInRange(3, 5)); // Any value except 1.
            Modify(true);
        end;
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1M>', WorkDate), CalcDate('<1M>', WorkDate));
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; Type: Option; No: Code[20]; IsMultipleUOM: Boolean)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, Type, No);
        with RoutingLine do begin
            Validate("Setup Time", LibraryRandom.RandDec(10, 2));
            Validate("Run Time", LibraryRandom.RandDec(10, 2));
            Validate("Wait Time", LibraryRandom.RandDec(10, 2));
            Validate("Move Time", LibraryRandom.RandDec(10, 2));
            if IsMultipleUOM then begin
                LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::"100/Hour");
                Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
                LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Minutes);
                Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
                LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Hours);
                Validate("Wait Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
                LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Days);
                Validate("Move Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
            end;
            Modify(true)
        end;
    end;

    local procedure CreateRoutingLineWithSendAhead(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; Type: Option; No: Code[20]; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal; SendAhead: Integer; ConcurrentCapacities: Decimal; OperationNo: Code[10]; PrevOperationNo: Code[10]; NextOperationNo: Code[10])
    begin
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, Type, No);
        with RoutingLine do begin
            Validate("Setup Time", SetupTime);
            Validate("Run Time", RunTime);
            Validate("Wait Time", WaitTime);
            Validate("Move Time", MoveTime);
            Validate("Send-Ahead Quantity", SendAhead);
            Validate("Concurrent Capacities", ConcurrentCapacities);
            Validate("Previous Operation No.", PrevOperationNo);
            Validate("Next Operation No.", NextOperationNo);
            Modify(true)
        end;
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate), CalcDate('<1M>', WorkDate));
    end;

    local procedure CreateWorkCenterWithShopCalendar(UOMType: Option; ShopCalendarCode: Code[10]; Efficiency: Decimal; Capacity: Decimal; DueDate: Date): Code[20]
    var
        WorkCenter: Record "Work Center";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, UOMType);
        WorkCenter.Validate("Unit of Measure Code", CapacityUnitOfMeasure.Code);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Validate(Efficiency, Efficiency);
        WorkCenter.Validate(Capacity, Capacity);
        WorkCenter.Modify(true);

        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-2M>', DueDate), CalcDate('<+2M>', DueDate));
        exit(WorkCenter."No.");
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast then
            exit(RoutingLine."Operation No.");
        exit('');
    end;

    local procedure CreateAndRefreshBackwardFirmPlannedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; DueDate: Date)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.SetUpdateEndDate;
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndRefreshForwardFirmPlannedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; StartingDate: Date; StartingTime: Time)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.SetUpdateEndDate;
        ProductionOrder.Validate("Starting Date", StartingDate);
        ProductionOrder.Validate("Starting Time", StartingTime);
        ProductionOrder.Validate("Due Date", StartingDate + 1);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);
    end;

    local procedure CreateAndRefreshPlannedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; Forward: Boolean)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, Forward, true, true, true, false);
    end;

    local procedure CreateAndRefreshBackwardPlanningLine(var RequisitionLine: Record "Requisition Line"; SourceNo: Code[20]; Quantity: Decimal; DueDate: Date)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Direction: Option Forward,Backward;
    begin
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", SourceNo);
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.SetCurrFieldNo(RequisitionLine.FieldNo("Due Date"));
        RequisitionLine.Validate("Due Date", DueDate);
        RequisitionLine.Modify(true);
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Backward, true, true);
    end;

    local procedure CreateAndRefreshForwardPlanningLine(var RequisitionLine: Record "Requisition Line"; SourceNo: Code[20]; Quantity: Decimal; StartingDate: Date; StartingTime: Time)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Direction: Option Forward,Backward;
    begin
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", SourceNo);
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.Validate("Starting Date", StartingDate);
        RequisitionLine.Validate("Starting Time", StartingTime);
        RequisitionLine.Modify(true);
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Forward, true, true);
    end;

    local procedure CreateThreeShiftsShopCalendar(): Code[10]
    var
        ShopCalendar: Record "Shop Calendar";
        WorkShiftCodes: array[3] of Code[10];
    begin
        LibraryManufacturing.CreateShopCalendarCode(ShopCalendar);
        CreateThreeWorkShifts(WorkShiftCodes);
        UpdateThreeShiftsShopCalendarWorkingDays(ShopCalendar.Code, WorkShiftCodes);
        exit(ShopCalendar.Code);
    end;

    local procedure CreateThreeWorkShifts(var WorkShiftCodes: array[3] of Code[10])
    var
        WorkShift: Record "Work Shift";
        i: Integer;
    begin
        for i := 1 to ArrayLen(WorkShiftCodes) do begin
            LibraryManufacturing.CreateWorkShiftCode(WorkShift);
            WorkShiftCodes[i] := WorkShift.Code;
        end;
    end;

    local procedure OpenWorkCenterLoadPage(var WorkCenterLoad: TestPage "Work Center Load"; WorkCenterNo: Code[20])
    var
        WorkCenterCard: TestPage "Work Center Card";
    begin
        OpenWorkCenterCard(WorkCenterCard, WorkCenterNo);
        WorkCenterLoad.Trap;
        WorkCenterCard."Lo&ad".Invoke;
    end;

    local procedure OpenMachineCenterLoadPage(var MachineCenterLoad: TestPage "Machine Center Load"; MachineCenterNo: Code[20])
    var
        MachineCenterCard: TestPage "Machine Center Card";
    begin
        OpenMachineCenterCard(MachineCenterCard, MachineCenterNo);
        MachineCenterLoad.Trap;
        MachineCenterCard."Lo&ad".Invoke;
    end;

    local procedure OpenMachineCenterCard(var MachineCenterCard: TestPage "Machine Center Card"; No: Code[20])
    begin
        MachineCenterCard.OpenEdit;
        MachineCenterCard.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenWorkCenterCard(var WorkCenterCard: TestPage "Work Center Card"; No: Code[20])
    begin
        WorkCenterCard.OpenEdit;
        WorkCenterCard.FILTER.SetFilter("No.", No);
    end;

    local procedure UpdateMachineCenterBlocked(var MachineCenter: Record "Machine Center")
    begin
        // Block Machine Center.
        MachineCenter.Validate(Blocked, true);
        MachineCenter.Modify(true);
    end;

    local procedure UpdateWorkCenterBlocked(var WorkCenter: Record "Work Center")
    begin
        // Block Work Center.
        WorkCenter.Validate(Blocked, true);
        WorkCenter.Modify(true);
    end;

    local procedure UpdateMachineCenterWithZeroEfficiency(var MachineCenter: Record "Machine Center")
    begin
        MachineCenter.Validate(Efficiency, 0);  // Set Zero Efficiency.
        MachineCenter.Modify(true);
    end;

    local procedure UpdateWorkCenterWithZeroEfficiency(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.Validate(Efficiency, 0);  // Set Zero Efficiency.
        WorkCenter.Modify(true);
    end;

    local procedure UpdateWorkCenterWithZeroCapacity(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.Validate(Capacity, 0);  // Set Zero Capacity.
        WorkCenter.Modify(true);
    end;

    local procedure UpdateThreeShiftsShopCalendarWorkingDays(ShopCalendarCode: Code[10]; WorkShiftCodes: array[3] of Code[10])
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        DoW: Integer;
    begin
        for DoW := ShopCalendarWorkingDays.Day::Monday to ShopCalendarWorkingDays.Day::Sunday do begin
            LibraryManufacturing.CreateShopCalendarWorkingDays(
              ShopCalendarWorkingDays, ShopCalendarCode, DoW, WorkShiftCodes[1], 000000T, 080000T);
            LibraryManufacturing.CreateShopCalendarWorkingDays(
              ShopCalendarWorkingDays, ShopCalendarCode, DoW, WorkShiftCodes[2], 080000T, 160000T);
            LibraryManufacturing.CreateShopCalendarWorkingDays(
              ShopCalendarWorkingDays, ShopCalendarCode, DoW, WorkShiftCodes[3], 160000T, 235959T);
        end;
    end;

    local procedure CalculateCapacity(var CapacityAvailable: Decimal; var CapacityEfficiency: Decimal; WorkCenter: Record "Work Center"; StartingDate: Date)
    begin
        // Calculate Capacity Available and Capacity Efficiency values.
        WorkCenter.SetRange("Date Filter", StartingDate);
        WorkCenter.CalcFields("Capacity (Effective)", "Prod. Order Need (Qty.)");
        CapacityAvailable := WorkCenter."Capacity (Effective)" - WorkCenter."Prod. Order Need (Qty.)";
        if WorkCenter."Capacity (Effective)" <> 0 then
            CapacityEfficiency := Round(WorkCenter."Prod. Order Need (Qty.)" / WorkCenter."Capacity (Effective)" * 100, 0.1);  // Calculation formula taken from Page - Work Center Load Lines.
    end;

    local procedure CalcRoutingLineQtyBase(RoutingLine: Record "Routing Line"): Decimal
    begin
        with RoutingLine do
            exit(
              "Setup Time" * CalendarMgt.TimeFactor("Setup Time Unit of Meas. Code") +
              "Run Time" * CalendarMgt.TimeFactor("Run Time Unit of Meas. Code") +
              "Wait Time" * CalendarMgt.TimeFactor("Wait Time Unit of Meas. Code") +
              "Move Time" * CalendarMgt.TimeFactor("Move Time Unit of Meas. Code"));
    end;

    local procedure FindWorkCenter(var WorkCenter: Record "Work Center"; RoutingNo: Code[20])
    var
        RoutingLine: Record "Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, RoutingLine.Type::"Work Center");
        WorkCenter.Get(RoutingLine."No.");
    end;

    local procedure FindRoutingLine(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20]; Type: Option)
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange(Type, Type);
        RoutingLine.FindFirst;
    end;

    local procedure SetWorkCentersOperationalHours(var StartTime: array[3] of Time; var EndTime: array[3] of Time; FromTime1: Time; ToTime1: Time; FromTime2: Time; ToTime2: Time; FromTime3: Time; ToTime3: Time)
    begin
        StartTime[1] := FromTime1;
        EndTime[1] := ToTime1;
        StartTime[2] := FromTime2;
        EndTime[2] := ToTime2;
        StartTime[3] := FromTime3;
        EndTime[3] := ToTime3;
    end;

    local procedure SetRunTime(var RunTime: array[3] of Decimal; RunTime1: Decimal; RunTime2: Decimal; RunTime3: Decimal)
    begin
        RunTime[1] := RunTime1;
        RunTime[2] := RunTime2;
        RunTime[3] := RunTime3;
    end;

    local procedure SetConcurrentCapacities(var ConcurrentCapacities: array[3] of Decimal; ConcurrCap1: Decimal; ConcurrCap2: Decimal; ConcurrCap3: Decimal)
    begin
        ConcurrentCapacities[1] := ConcurrCap1;
        ConcurrentCapacities[2] := ConcurrCap2;
        ConcurrentCapacities[3] := ConcurrCap3;
    end;

    local procedure UpdateStatusOnRoutingHeader(var RoutingHeader: Record "Routing Header"; Status: Option)
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    local procedure UpdateStandardCostingMethodOnItem(var Item: Record Item)
    begin
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Modify(true);
    end;

    local procedure UpdateUnitCostCalculationOnWorkCenter(WorkCenterNo: Code[20])
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.Get(WorkCenterNo);
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Units);
        WorkCenter.Validate("Specific Unit Cost", true);
        WorkCenter.Modify(true);
    end;

    local procedure FindProductionBOMLine(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMNo: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.FindFirst;
    end;

    local procedure UpdateUnitCostPerOnRoutingLine(var RoutingLine: Record "Routing Line")
    begin
        RoutingLine.Validate("Unit Cost per", LibraryRandom.RandDec(10, 2));
        RoutingLine.Modify(true);
    end;

    local procedure UpdateUnitCostPerOnRoutingLineAndReCertify(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
    begin
        RoutingHeader.Get(RoutingNo);
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::New);
        FindRoutingLine(RoutingLine, RoutingNo, RoutingLine.Type::"Work Center");
        UpdateUnitCostPerOnRoutingLine(RoutingLine);
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure UpdateSendAheadQuantityOnRoutingLineAndReCertify(RoutingNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        RoutingHeader.Get(RoutingNo);
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::New);
        UpdateSendAheadQuantityOnRoutingLine(RoutingNo, RoutingLine.Type::"Work Center");
        UpdateSendAheadQuantityOnRoutingLine(RoutingNo, RoutingLine.Type::"Machine Center");
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure UpdateSendAheadQuantityOnRoutingLine(RoutingNo: Code[20]; Type: Option)
    var
        RoutingLine: Record "Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, Type);
        RoutingLine.Validate("Send-Ahead Quantity", LibraryRandom.RandDec(10, 2));
        RoutingLine.Modify(true);
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderNo: Code[20]; Type: Option; No: Code[20])
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange(Type, Type);
        ProdOrderRoutingLine.SetRange("No.", No);
        ProdOrderRoutingLine.FindFirst;
    end;

    local procedure FindFirmPlannedProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::"Firm Planned");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst;
    end;

    local procedure FindPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; Type: Option; No: Code[20])
    begin
        PlanningRoutingLine.SetRange(Type, Type);
        PlanningRoutingLine.SetRange("No.", No);
        PlanningRoutingLine.FindFirst;
    end;

    local procedure GetNextProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; NextOperationNo: Code[30])
    begin
        ProdOrderRoutingLine.SetRange("Operation No.", CopyStr(NextOperationNo, 1, MaxStrLen(ProdOrderRoutingLine."Operation No.")));
        ProdOrderRoutingLine.FindFirst;
    end;

    local procedure GetNextPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; NextOperationNo: Code[30])
    begin
        PlanningRoutingLine.SetRange("Operation No.", CopyStr(NextOperationNo, 1, MaxStrLen(PlanningRoutingLine."Operation No.")));
        PlanningRoutingLine.FindFirst;
    end;

    local procedure UpdateStartingDateAndTimeOnProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderLine.Validate("Starting Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate));
        ProdOrderLine.Validate("Starting Time", Time);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateProdOrderLineWithZeroQuantity(var ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderLine.Validate(Quantity, 0);  // Set Zero Quantity.
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderNo: Code[20]; Type: Option; RoutingLineNo: Code[20]; SendAheadQuantity: Decimal; ConcurrentCapacities: Decimal)
    begin
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderNo, Type, RoutingLineNo);
        with ProdOrderRoutingLine do begin
            Validate("Send-Ahead Quantity", SendAheadQuantity);
            Validate("Concurrent Capacities", ConcurrentCapacities);
            Validate("Starting Date", CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate));
            Validate("Starting Time", 080000T); // To make sure the Starting Time of the next Operation won't exceed the ending time of current working day.
            Modify(true);
        end;
    end;

    local procedure CreateFirmPlannedProductionOrderFromSalesOrder(SalesHeader: Record "Sales Header")
    var
        ProductionOrder: Record "Production Order";
        OrderType: Option ItemOrder,ProjectOrder;
    begin
        LibraryVariableStorage.Enqueue(FirmPlannedProductionOrderCreated);  // Enqueue value for Message Handler.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
          SalesHeader, ProductionOrder.Status::"Firm Planned", OrderType::ProjectOrder);
    end;

    local procedure FilterOnWorkCenterLoadPage(var WorkCenterLoad: TestPage "Work Center Load"; PeriodStart: Date)
    var
        PeriodType: Option Day,Week,Month,Quarter,Year,Period;
        AmountType: Option "Net Change","Balance at Date";
    begin
        WorkCenterLoad.PeriodType.SetValue(PeriodType::Day);
        WorkCenterLoad.AmountType.SetValue(AmountType::"Net Change");
        WorkCenterLoad.MachineCenterLoadLines.FILTER.SetFilter("Period Start", Format(PeriodStart));
    end;

    local procedure FilterOnMachineCenterLoadPage(var MachineCenterLoad: TestPage "Machine Center Load"; PeriodStart: Date)
    var
        PeriodType: Option Day,Week,Month,Quarter,Year,Period;
        AmountType: Option "Net Change","Balance at Date";
    begin
        MachineCenterLoad.PeriodType.SetValue(PeriodType::Day);
        MachineCenterLoad.AmountType.SetValue(AmountType::"Net Change");
        MachineCenterLoad.MachineCLoadLines.FILTER.SetFilter("Period Start", Format(PeriodStart));
    end;

    local procedure UpdateLotForLotReorderingPolicyOnItem(var Item: Record Item)
    begin
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);
    end;

    local procedure VerifyWorkCenterLoad(WorkCenterLoad: TestPage "Work Center Load"; PeriodStart: Date; CapacityAvailable: Decimal; CapacityEfficiency: Decimal)
    begin
        // Verify Work Center Load Page.
        FilterOnWorkCenterLoadPage(WorkCenterLoad, PeriodStart);
        WorkCenterLoad.MachineCenterLoadLines.CapacityAvailable.AssertEquals(CapacityAvailable);
        WorkCenterLoad.MachineCenterLoadLines.CapacityEfficiency.AssertEquals(CapacityEfficiency);
    end;

    local procedure VerifyOperationsTimeOnProdOrderRoutingLine(ProductionOrderNo: Code[20]; RoutingNo: Code[20]; Type: Option)
    var
        RoutingLine: Record "Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, Type);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrderNo, Type, RoutingLine."No.");
        ProdOrderRoutingLine.TestField("Wait Time", RoutingLine."Wait Time");
        ProdOrderRoutingLine.TestField("Move Time", RoutingLine."Move Time");
    end;

    local procedure VerifyOperationsTimeOnPlanningRoutingLine(RoutingNo: Code[20]; Type: Option)
    var
        RoutingLine: Record "Routing Line";
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, Type);
        FindPlanningRoutingLine(PlanningRoutingLine, Type, RoutingLine."No.");
        PlanningRoutingLine.TestField("Wait Time", RoutingLine."Wait Time");
        PlanningRoutingLine.TestField("Move Time", RoutingLine."Move Time");
    end;

    local procedure VerifySendAheadQuantityOnPlanningRoutingLine(RoutingNo: Code[20]; Type: Option)
    var
        RoutingLine: Record "Routing Line";
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, Type);
        FindPlanningRoutingLine(PlanningRoutingLine, Type, RoutingLine."No.");
        PlanningRoutingLine.TestField("Send-Ahead Quantity", RoutingLine."Send-Ahead Quantity");
    end;

    local procedure VerifySendAheadQuantityOnProdOrderRoutingLine(ProdOrderNo: Code[20]; RoutingNo: Code[20]; Type: Option)
    var
        RoutingLine: Record "Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, Type);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderNo, Type, RoutingLine."No.");
        ProdOrderRoutingLine.TestField("Send-Ahead Quantity", RoutingLine."Send-Ahead Quantity");
    end;

    local procedure VerifyStartingDateAndTimeOnProdOrderRoutingLine(ProdOrderLine: Record "Prod. Order Line"; RoutingNo: Code[20]; Type: Option)
    var
        RoutingLine: Record "Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, Type);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine."Prod. Order No.", Type, RoutingLine."No.");
        ProdOrderRoutingLine.TestField("Starting Time", ProdOrderLine."Starting Time");
        ProdOrderRoutingLine.TestField("Starting Date", ProdOrderLine."Starting Date");
    end;

    local procedure VerifyProdOrderCapacityNeed(ProdOrderCapacityNeedPage: TestPage "Prod. Order Capacity Need"; Type: Option; No: Code[20]; StartingDate: Date)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeedPage.FILTER.SetFilter(Type, Format(Type));
        ProdOrderCapacityNeed.SetRange("Requested Only", false);
        ProdOrderCapacityNeed.SetRange("No.", No);
        ProdOrderCapacityNeed.SetRange(Date, StartingDate);
        ProdOrderCapacityNeed.FindSet;
        repeat
            ProdOrderCapacityNeedPage.FILTER.SetFilter("Time Type", Format(ProdOrderCapacityNeed."Time Type"));
            ProdOrderCapacityNeedPage."Allocated Time".AssertEquals(ProdOrderCapacityNeed."Allocated Time");
        until ProdOrderCapacityNeed.Next = 0;
    end;

    local procedure VerifyStartingDateTimeOnProdOrderRoutingLine(RoutingNo: Code[20]; ProdOrderNo: Code[20]; Type: Option; StartingDateTime: DateTime)
    var
        RoutingLine: Record "Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, Type);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderNo, Type, RoutingLine."No.");
        ProdOrderRoutingLine.TestField("Starting Date-Time", StartingDateTime);
    end;

    local procedure VerifyProdOrderCapacityNeedTime(WorkCenterCode: array[4] of Code[10]; WorkCenterCount: Integer)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        i: Integer;
        EndingDateTime: DateTime;
        ZeroEndingDateTime: DateTime;
    begin
        ProdOrderCapacityNeed.SetCurrentKey(Type, "No.", "Starting Date-Time", "Ending Date-Time", Active);
        for i := 1 to WorkCenterCount do begin
            ProdOrderCapacityNeed.SetRange("Work Center No.", WorkCenterCode[i]);
            ProdOrderCapacityNeed.FindSet;
            EndingDateTime := ProdOrderCapacityNeed."Starting Date-Time";
            if DT2Time(EndingDateTime) = 235959T then
                ZeroEndingDateTime := CreateDateTime(DT2Date(EndingDateTime) + 1, 0T);
            repeat
                Assert.IsTrue(
                  (ProdOrderCapacityNeed."Starting Date-Time" = EndingDateTime) or
                  (ProdOrderCapacityNeed."Starting Date-Time" = ZeroEndingDateTime),
                  StrSubstNo(TheGapErr, WorkCenterCode[i], ProdOrderCapacityNeed."Starting Date-Time", EndingDateTime));
                EndingDateTime := ProdOrderCapacityNeed."Ending Date-Time";
                ZeroEndingDateTime := 0DT;
                if DT2Time(EndingDateTime) - 235959T < 1000 then
                    ZeroEndingDateTime := CreateDateTime(DT2Date(EndingDateTime) + 1, 0T);
            until ProdOrderCapacityNeed.Next = 0;
        end;
    end;

    local procedure VerifyCapacityNeedFirstStartLastEndDateTime(ProdOrderNo: Code[20]; WorksheetTemplateName: Code[10]; WorkCenterCode: Code[20]; ExpectedFirstCapNeedStartDateTime: DateTime; ExpectedLastCapNeedEndDateTime: DateTime)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.SetCurrentKey(Type, "No.", "Starting Date-Time", "Ending Date-Time", Active);
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderCapacityNeed.SetRange("Worksheet Template Name", WorksheetTemplateName);
        ProdOrderCapacityNeed.SetRange("Work Center No.", WorkCenterCode);
        ProdOrderCapacityNeed.FindFirst;
        ProdOrderCapacityNeed.TestField(Date, DT2Date(ExpectedFirstCapNeedStartDateTime));
        ProdOrderCapacityNeed.TestField("Starting Time", DT2Time(ExpectedFirstCapNeedStartDateTime));
        ProdOrderCapacityNeed.FindLast;
        ProdOrderCapacityNeed.TestField(Date, DT2Date(ExpectedLastCapNeedEndDateTime));
        ProdOrderCapacityNeed.TestField("Ending Time", DT2Time(ExpectedLastCapNeedEndDateTime));
    end;

    local procedure VerifyCapacityNeedTotalAllocatedTime(ProdOrderNo: Code[20]; WorksheetTemplateName: Code[10]; WorkCenterCode: Code[20]; ExpectedTotalAllocatedTime: Decimal)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderCapacityNeed.SetRange("Worksheet Template Name", WorksheetTemplateName);
        ProdOrderCapacityNeed.SetRange("Work Center No.", WorkCenterCode);
        ProdOrderCapacityNeed.CalcSums("Allocated Time");
        Assert.AreEqual(
          ExpectedTotalAllocatedTime, ProdOrderCapacityNeed."Allocated Time",
          'Wrong allocated time in capacity need for the production order or the planning line.');
    end;

    local procedure VerifyProdOrderStartEndDateTime(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ExpectedStartingDateTime: DateTime; ExpectedEndingDateTime: DateTime)
    begin
        ProdOrderRoutingLine.TestField("Starting Date-Time", ExpectedStartingDateTime);
        ProdOrderRoutingLine.TestField("Ending Date-Time", ExpectedEndingDateTime);
    end;

    local procedure VerifyPlanningLineStartEndDateTime(PlanningRoutingLine: Record "Planning Routing Line"; ExpectedStartingDateTime: DateTime; ExpectedEndingDateTime: DateTime)
    begin
        PlanningRoutingLine.TestField("Starting Date-Time", ExpectedStartingDateTime);
        PlanningRoutingLine.TestField("Ending Date-Time", ExpectedEndingDateTime);
    end;

    local procedure RunBOMCostSharesPage(var Item: Record Item)
    var
        BOMCostShares: Page "BOM Cost Shares";
    begin
        BOMCostShares.InitItem(Item);
        BOMCostShares.Run;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalculateStandardCostMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Calculate Standard Cost for All Level.
        Choice := 2;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BOMCostSharesPageHandler(var BOMCostShares: TestPage "BOM Cost Shares")
    var
        Item: Record Item;
        BOMBuffer: Record "BOM Buffer";
        RoutingLine: Record "Routing Line";
        VariantVar1: Variant;
        VariantVar2: Variant;
        VariantVar3: Variant;
        ItemNo: Code[20];
        RoutingNo: Code[20];
        ExpWarning: Text;
    begin
        LibraryVariableStorage.Dequeue(VariantVar1);
        LibraryVariableStorage.Dequeue(VariantVar2);
        LibraryVariableStorage.Dequeue(VariantVar3);

        ItemNo := VariantVar1;
        Item.Get(ItemNo);
        RoutingNo := VariantVar2;
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindFirst;
        ExpWarning := VariantVar3;

        BOMCostShares.FILTER.SetFilter(Type, Format(BOMBuffer.Type::Item));
        BOMCostShares.FILTER.SetFilter("No.", ItemNo);
        BOMCostShares.First;
        Assert.AreEqual(Item."Standard Cost", BOMCostShares."Total Cost".AsDEcimal, StrSubstNo(TopItemTotalCostErr, ItemNo));

        BOMCostShares.FILTER.SetFilter(Type, Format(BOMBuffer.Type::"Work Center"));
        BOMCostShares.FILTER.SetFilter("No.", RoutingLine."Work Center No.");
        BOMCostShares.First;

        Assert.AreEqual(ExpWarning, Format(BOMCostShares.HasWarning), StrSubstNo(WorkCenterWarningErr, RoutingLine."Work Center No."));
        Assert.AreEqual(
          RoutingLine."Unit Cost per", BOMCostShares."Total Cost".AsDEcimal,
          StrSubstNo(WorkCenterTotalCostErr, RoutingLine."Work Center No."));
        BOMCostShares.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BOMCostSharesVerifyQtyPageHandler(var BOMCostShares: TestPage "BOM Cost Shares")
    var
        BOMBuffer: Record "BOM Buffer";
        Variant: Variant;
        MachineCenterNo: Code[20];
        ExpectedQty: Decimal;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        MachineCenterNo := Variant;
        LibraryVariableStorage.Dequeue(Variant);
        ExpectedQty := Variant;

        BOMCostShares.FILTER.SetFilter(Type, Format(BOMBuffer.Type::"Machine Center"));
        BOMCostShares.FILTER.SetFilter("No.", MachineCenterNo);
        BOMCostShares.First;
        Assert.AreEqual(ExpectedQty, BOMCostShares."Qty. per Parent".AsDEcimal, BOMCostShareQtyErr);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BOMCostSharesCapCostHandler(var BOMCostShares: TestPage "BOM Cost Shares")
    var
        BOMBuffer: Record "BOM Buffer";
        WorkCenterNo: Text;
        ExpectedCapCost: Decimal;
    begin
        WorkCenterNo := LibraryVariableStorage.DequeueText;
        ExpectedCapCost := LibraryVariableStorage.DequeueDecimal;

        BOMCostShares.FILTER.SetFilter(Type, Format(BOMBuffer.Type::"Work Center"));
        BOMCostShares.FILTER.SetFilter("No.", WorkCenterNo);
        BOMCostShares.First;
        Assert.AreEqual(ExpectedCapCost, BOMCostShares."Rolled-up Capacity Cost".AsDEcimal, BOMCostShareCapCostErr);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(AreSameMessages(Message, ExpectedMessage), Message);
    end;
}

