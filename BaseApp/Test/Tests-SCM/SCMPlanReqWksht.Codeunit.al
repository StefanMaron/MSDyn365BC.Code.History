codeunit 137067 "SCM Plan-Req. Wksht"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [Requisition Worksheet] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        LocationYellow: Record Location;
        LocationRed: Record Location;
        LocationInTransit: Record Location;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        AvailabilityMgt: Codeunit AvailabilityManagement;
        DemandType: Option " ",Production,Sales,Service,Jobs,Assembly;
        isInitialized: Boolean;
        RequisitionLineMustNotExistTxt: Label 'Requisition Line must not exist for Item %1.', Comment = '%1 = Item No.';
        ShipmentDateMessageTxt: Label 'Shipment Date';
        NewWorksheetMessageTxt: Label 'You are now in worksheet';
        ReleasedProductionOrderCreatedTxt: Label 'Released Prod. Order';
        CancelReservationConfirmationMessageTxt: Label 'Cancel reservation';
        NumberOfRowsErr: Label 'Number of rows must match.';
        ReservationEntryErr: Label 'Reservation Entry is not correct';
        FirmPlannedProdOrderErr: Label 'Firm Planned Prod. Order line with Due Date %1 is not correct.', Comment = '%1 = Due Date';
        ModifiedPromisedReceiptDateMsg: Label 'You have modified Promised Receipt Date.';
        ReservationsExistMsg: Label 'Reservations exist for this order. These reservations will be canceled if a date conflict is caused by this change.';
        DateConflictWithExistingReservationsErr: Label 'The change leads to a date conflict with existing reservations.';
        WillNotAffectExistingMsg: Label 'The change will not affect existing entries';
        AutoReservNotPossibleMsg: Label 'Full automatic Reservation is not possible.';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReqWkshErrorAfterCarryOutForSalesShipmentOutsideLotAccumPeriodLFLItem()
    var
        Item: Record Item;
        ShipmentDate: Date;
        PlanningEndDate: Date;
    begin
        // Setup: Create LFL Item. Shipment Date outside Lot Accumulation Period. Parameters: Shipment Date and Planning End Dates.
        Initialize;
        CreateLotForLotItem(Item, LibraryRandom.RandInt(50), GetLotAccumulationPeriod(2, 5));  // Lot Accumulation Period based on Random Quantity.
        ShipmentDate := GetRequiredDate(2, 0, WorkDate, -1);  // Shipment Date relative to Work Date.
        PlanningEndDate := GetRequiredDate(2, 0, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate), -1);  // Planning End Date relative to Lot Accumulation period.
        ReqWkshErrorAfterCarryOutActionMsgWithSalesOrdersLFLItem(Item, ShipmentDate, PlanningEndDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReqWkshErrorAfterCarryOutForSalesShipmentInLotAccumPeriodLFLItem()
    var
        Item: Record Item;
        ShipmentDate: Date;
        PlanningEndDate: Date;
    begin
        // Setup: Create LFL Item. Shipment Date within Lot Accumulation Period. Parameters: Shipment Date and Planning End Dates.
        Initialize;
        CreateLotForLotItem(Item, LibraryRandom.RandInt(50), GetLotAccumulationPeriod(2, 5));  // Lot Accumulation Period based on Random Quantity.
        ShipmentDate := GetRequiredDate(20, 0, WorkDate, 1);  // Shipment Date relative to Work Date.
        PlanningEndDate := GetRequiredDate(10, 0, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate), -1);  // Planning End Date relative to Lot Accumulation period.
        ReqWkshErrorAfterCarryOutActionMsgWithSalesOrdersLFLItem(Item, ShipmentDate, PlanningEndDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReqWkshErrorAfterCarryOutForSalesPlanningEndDateGreaterThanLotAccumPeriodLFLItem()
    var
        Item: Record Item;
        ShipmentDate: Date;
        PlanningEndDate: Date;
    begin
        // Setup: Create LFL Item. Planning Ending Date greater than Lot Accumulation Period. Parameters: Shipment Date and Planning End Dates.
        Initialize;
        CreateLotForLotItem(Item, LibraryRandom.RandInt(50), GetLotAccumulationPeriod(2, 5));  // Lot Accumulation Period based on Random Quantity.
        ShipmentDate := GetRequiredDate(20, 0, WorkDate, -1);  // Shipment Date relative to Work Date.
        PlanningEndDate := GetRequiredDate(10, 0, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate), 1);  // Planning End Date relative to Lot Accumulation period.
        ReqWkshErrorAfterCarryOutActionMsgWithSalesOrdersLFLItem(Item, ShipmentDate, PlanningEndDate);
    end;

    local procedure ReqWkshErrorAfterCarryOutActionMsgWithSalesOrdersLFLItem(Item: Record Item; ShipmentDate: Date; EndingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        // Create Sales Order and Update Shipment Date.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandInt(20));
        if ShipmentDate < WorkDate then
            LibraryVariableStorage.Enqueue(ShipmentDateMessageTxt);  // Required inside MessageHandler.
        UpdateShipmentDateOnSalesLine(SalesLine, ShipmentDate);  // Shipment Date value important for Test.

        // Calculate Plan for Requisition Worksheet with the required Start and End dates, Carry out Action Message.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate, EndingDate);
        AcceptActionMessage(Item."No.");
        SelectRequisitionLine(RequisitionLine, Item."No.");
        LibraryVariableStorage.Enqueue(NewWorksheetMessageTxt);  // Required inside MessageHandler.
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate, WorkDate, WorkDate, WorkDate, '');

        // Exercise: Calculate Plan for Requisition Worksheet again after Carry Out Action Message.
        RequisitionWkshName.FindFirst;
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, WorkDate, EndingDate);

        // Verify: Verify that no Requisition line is created for Requisition Worksheet.
        FilterOnRequisitionLine(RequisitionLine, Item."No.");
        Assert.IsTrue(RequisitionLine.IsEmpty, StrSubstNo(RequisitionLineMustNotExistTxt, Item."No."));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PlanningFlexibilityUnlimitedAndCarryOutCalcPlanTwiceWithSalesOrderLFLItem()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ItemJournalLine: Record "Item Journal Line";
        PurchaseLine: Record "Purchase Line";
        ShipmentDate: Date;
        ShipmentDate2: Date;
        PlanningEndDate: Date;
        PlanningEndDate2: Date;
        Quantity: Integer;
        ReqLineQuantity: Integer;
    begin
        // Setup: Create LFL Item  with Lot Accumulation Period and update Inventory.
        Initialize;
        CreateLotForLotItem(Item, LibraryRandom.RandInt(50), GetLotAccumulationPeriod(2, 5));  // Lot Accumulation Period based on Random Quantity.
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate, Item."Safety Stock Quantity" - LibraryRandom.RandInt(5));  // Inventory Value required for Test.

        // Create Sales Order with multiple Lines having different Shipment Dates. Second Shipment Date is greater than first but difference less than Lot Accumulation Period.
        Quantity := LibraryRandom.RandInt(10) + 10;  // Random Quantity.
        ShipmentDate := GetRequiredDate(10, 0, WorkDate, 1);  // Shipment Date relative to Work Date.
        ShipmentDate2 := GetRequiredDate(5, 0, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate), -1);  // Shipment Date relative to Lot Accumulation period.
        CreateSalesOrderWithMultipleLinesAndRequiredShipment(
          SalesLine, SalesLine2, Item."No.", Quantity - LibraryRandom.RandInt(5), Quantity - SalesLine.Quantity, ShipmentDate,
          ShipmentDate2);

        // Calculate Plan for Requisition Worksheet having End Date which excludes Shipment Date of Second Sales Line, with Planning Flexibility - Unlimited and Carry out Action Message.
        PlanningEndDate := GetRequiredDate(10, 5, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate), -1);  // Planning End Date relative to Lot Accumulation period.
        LibraryVariableStorage.Enqueue(NewWorksheetMessageTxt);  // Required inside MessageHandler.
        CalcPlanAndCarryOutActionMessageWithPlanningFlexibility(
          RequisitionWkshName, Item, RequisitionLine."Planning Flexibility"::Unlimited, PlanningEndDate);

        // Exercise: Calculate Plan for Requisition Worksheet again after Carry Out Action Message, Shipment Dates are included in Start and End Date.
        RequisitionWkshName.FindFirst;
        PlanningEndDate2 := GetRequiredDate(10, 5, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate), 1);  // Planning End Date relative to Lot Accumulation period.
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, WorkDate, PlanningEndDate2);

        // Verify: Verify Requisition Line values.
        Item.CalcFields(Inventory);
        SelectPurchaseLine(PurchaseLine, Item."No.");
        SelectRequisitionLine(RequisitionLine, Item."No.");
        ReqLineQuantity := SalesLine.Quantity + SalesLine2.Quantity + Item."Safety Stock Quantity" - Item.Inventory;
        VerifyRequisitionLineQuantity(RequisitionLine, ReqLineQuantity, PurchaseLine.Quantity, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PlanningFlexibilityNoneAndCarryOutCalcPlanTwiceWithSalesOrderLFLItem()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
        ShipmentDate: Date;
        ShipmentDate2: Date;
        PlanningEndDate: Date;
        PlanningEndDate2: Date;
        Quantity: Integer;
    begin
        // Setup: Create LFL Item with Lot Accumulation Period and update Inventory.
        Initialize;
        CreateLotForLotItem(Item, LibraryRandom.RandInt(50), GetLotAccumulationPeriod(2, 5));  // Lot Accumulation Period based on Random Quantity.
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate, Item."Safety Stock Quantity" - LibraryRandom.RandInt(5));  // Inventory Value required for Test.

        // Create Sales Order with multiple Lines have different Shipment Dates. Second Shipment Date is greater than first but difference less than Lot Accumulation Period.
        Quantity := LibraryRandom.RandInt(10) + 10;  // Random Quantity.
        ShipmentDate := GetRequiredDate(10, 0, WorkDate, 1);  // Shipment Date relative to Work Date.
        ShipmentDate2 := GetRequiredDate(5, 0, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate), -1);  // Shipment Date relative to Lot Accumulation period.
        CreateSalesOrderWithMultipleLinesAndRequiredShipment(
          SalesLine, SalesLine2, Item."No.", Quantity - LibraryRandom.RandInt(5), Quantity - SalesLine.Quantity, ShipmentDate,
          ShipmentDate2);

        // Calculate Plan for Requisition Worksheet having End Date which excludes Shipment Date of Second Sales Line, Update Planning Flexibility - None and Carry out Action Message.
        PlanningEndDate := GetRequiredDate(10, 5, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate), -1);  // Planning End Date relative to Lot Accumulation period.
        LibraryVariableStorage.Enqueue(NewWorksheetMessageTxt);  // Required inside MessageHandler.
        CalcPlanAndCarryOutActionMessageWithPlanningFlexibility(
          RequisitionWkshName, Item, RequisitionLine."Planning Flexibility"::None, PlanningEndDate);

        // Exercise: Calculate Plan for Requisition Worksheet again after Carry Out Action Message, Shipment Dates are included in Start and End Date.
        RequisitionWkshName.FindFirst;
        PlanningEndDate2 := GetRequiredDate(10, 5, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate), 1);  // Planning End Date relative to Lot Accumulation period.
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, WorkDate, PlanningEndDate2);

        // Verify: Verify Requisition Line values.
        SelectPurchaseLine(PurchaseLine, Item."No.");
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLine2.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanForReqWkshWithSalesAndPurchaseFRQItem()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        PostingDate: Date;
        ExpectedReceiptDate: Date;
        ShipmentDate: Date;
        ShipmentDate2: Date;
        StartDate: Date;
        EndDate: Date;
        Quantity: Integer;
        FirstOrderQuantity: Integer;
    begin
        // Setup: Create Fixed Reorder Quantity Item.
        Initialize;
        CreateFixedReorderQtyItem(Item);
        Quantity := LibraryRandom.RandInt(10) + 5;  // Random Quantity.
        UpdateLeadTimeCalculationForItem(Item, '<' + Format(LibraryRandom.RandInt(5) + 10) + 'D>');  // Random Lead Time Calculation.
        PostingDate := GetRequiredDate(10, 10, WorkDate, -1);
        UpdateInventory(ItemJournalLine, Item."No.", PostingDate, Quantity);

        // Create Purchase Order.
        ExpectedReceiptDate := GetRequiredDate(5, 10, WorkDate, 1);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", ExpectedReceiptDate, Quantity - LibraryRandom.RandInt(5));  // Expected Receipt date, Quantity required.

        // Create Sales Order multiple lines.
        ShipmentDate := GetRequiredDate(20, 10, WorkDate, 1);  // Shipment Date relative to Work Date.
        ShipmentDate2 := GetRequiredDate(20, 20, WorkDate, 1);  // Shipment Date relative to Work Date.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", ItemJournalLine.Quantity);  // Item Journal Line Quantity value required.
        UpdateShipmentDateOnSalesLine(SalesLine, ShipmentDate);
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine2, SalesHeader, SalesLine2.Type::Item, Item."No.", ShipmentDate2, Quantity + LibraryRandom.RandInt(5));

        // Exercise: Calculate Plan on Requisition Worksheet.
        StartDate := GetRequiredDate(5, 0, ShipmentDate, -1);  // Start Date Less than Shipment Date of first Sales Line.
        EndDate := GetRequiredDate(5, 0, ShipmentDate2, 1);  // End Date greater than Shipment Date of second Sales Line.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, StartDate, EndDate);

        // Verify: Verify Entries in Requisition Worksheet.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        SelectPurchaseLine(PurchaseLine, Item."No.");
        FirstOrderQuantity := Item."Reorder Point" - PurchaseLine.Quantity + Item."Reorder Quantity";
        VerifyRequisitionLineQuantity(
          RequisitionLine, FirstOrderQuantity, 0,
          RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, PurchaseLine.Quantity - Item."Reorder Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ItemJournalLine.Quantity + Item."Safety Stock Quantity" + Item."Reorder Quantity" - FirstOrderQuantity, 0,
          RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanForSalesShipmentDatesSameForSalesLinesLFLItem()
    var
        SalesShipmentDate: Date;
        SalesShipmentDate2: Date;
        LotAccumulationPeriod: Text[30];
    begin
        // Setup: Check Requisition Worksheet when Calculating Plan for Item having Lot Accumulation Period (1 Day) and Sales Order with multiple lines having same Shipment Dates.
        Initialize;
        LotAccumulationPeriod := '<1D>';
        SalesShipmentDate := GetRequiredDate(20, 10, WorkDate, 1);  // Shipment Date relative to Work Date.
        SalesShipmentDate2 := SalesShipmentDate;  // Shipment Dates on Sales Line must be same.
        CalcPlanOnSalesOrderMultipleLinesLotAccumPeriodLFLItem(LotAccumulationPeriod, SalesShipmentDate, SalesShipmentDate2, true, false);  // Lot Accumulation Period and shipment Date important for test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanForSalesShipmentDatesDiffForSalesLinesLFLItem()
    var
        SalesShipmentDate: Date;
        SalesShipmentDate2: Date;
        LotAccumulationPeriod: Text[30];
    begin
        // Setup: Check Requisition Worksheet when Calculating Plan for Item having Lot Accumulation Period (1 Day) and Sales Order with multiple lines having different Shipment Dates.
        Initialize;
        LotAccumulationPeriod := '<1D>';
        SalesShipmentDate := WorkDate;
        SalesShipmentDate2 := GetRequiredDate(20, 10, WorkDate, 1);  // Shipment Date relative to Work Date.
        CalcPlanOnSalesOrderMultipleLinesLotAccumPeriodLFLItem(LotAccumulationPeriod, SalesShipmentDate, SalesShipmentDate2, false, true);  // Lot Accumulation Period and shipment Date important for test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanForSalesShipmentDatesDiffForSalesLinesWithNoLotAccumPeriodLFLItem()
    var
        SalesShipmentDate: Date;
        SalesShipmentDate2: Date;
        LotAccumulationPeriod: Text[30];
    begin
        // Setup: Check Requisition Worksheet when Calculating Plan for Item having Lot Accumulation Period (0 Day) and Sales Order with multiple lines having different Shipment Dates.
        Initialize;
        LotAccumulationPeriod := '<0D>';
        SalesShipmentDate := WorkDate;
        SalesShipmentDate2 := GetRequiredDate(20, 10, WorkDate, 1);  // Shipment Date relative to Work Date.
        CalcPlanOnSalesOrderMultipleLinesLotAccumPeriodLFLItem(LotAccumulationPeriod, SalesShipmentDate, SalesShipmentDate2, false, true);  // Lot Accumulation Period and shipment Date important for test.
    end;

    local procedure CalcPlanOnSalesOrderMultipleLinesLotAccumPeriodLFLItem(LotAccumulationPeriod: Text[30]; ShipmentDate: Date; ShipmentDate2: Date; SameShipmentDate: Boolean; PurchaseOrder: Boolean)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        ExpectedReceiptDate: Date;
        PlanningEndDate: Date;
        Quantity: Integer;
    begin
        // Create Lot for Lot Item and Sales Order with multiple lines.
        CreateLotForLotItem(Item, LibraryRandom.RandInt(50), LotAccumulationPeriod);
        UpdateLeadTimeCalculationForItem(Item, '<1D>');
        Quantity := LibraryRandom.RandInt(10) + 100;  // Large Random Quantity.
        CreateSalesOrderWithMultipleLinesAndRequiredShipment(
          SalesLine, SalesLine2, Item."No.", Quantity, Quantity, ShipmentDate, ShipmentDate2);

        if PurchaseOrder then begin
            ExpectedReceiptDate := GetRequiredDate(10, 0, ShipmentDate2, 1);
            CreatePurchaseOrder(PurchaseHeader, Item."No.", ExpectedReceiptDate, SalesLine.Quantity + SalesLine2.Quantity);  // Expected Receipt date, Quantity required.
        end;

        // Exercise: Calculate Plan for Requisition Worksheet.
        PlanningEndDate := GetRequiredDate(10, 30, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate), 1);
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate, PlanningEndDate);

        // Verify: Verify Entries in Requisition Worksheet.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        if SameShipmentDate then begin
            VerifyRequisitionLineQuantity(RequisitionLine, Item."Safety Stock Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
            VerifyRequisitionLineQuantity(
              RequisitionLine, SalesLine.Quantity + SalesLine2.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
        end else begin
            VerifyRequisitionLineQuantity(
              RequisitionLine, Item."Safety Stock Quantity" + SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
            VerifyRequisitionLineQuantity(RequisitionLine, SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
            VerifyRequisitionLineQuantity(
              RequisitionLine, 0, SalesLine.Quantity + SalesLine2.Quantity, RequisitionLine."Ref. Order Type"::Purchase);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanOnSalesAndOrderItemWithReservedQuantity()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StartDate: Date;
        EndDate: Date;
        Quantity: Integer;
    begin
        // Setup: Create Item of Order Type Reordering Policy. Create Sales order.
        Initialize;
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        Quantity := LibraryRandom.RandInt(10);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);

        // Exercise: Calculate Plan for Requisition Worksheet having Start Date less than Work Date.
        StartDate := GetRequiredDate(20, 0, WorkDate, -1);
        EndDate := GetRequiredDate(20, 0, WorkDate, 1);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, StartDate, EndDate);

        // Verify: Verify Reserved Quantity is updated same as quantity on Sales Line.
        SelectSalesLineFromSalesDocument(SalesLine, SalesHeader."No.");
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForLFLItemFinishProductionOrderFromSalesOrder()
    begin
        // [FEATURE] [Calculate Regenerative Plan] [Production]
        // [SCENARIO] Verify Quantity on Requisition Line: Lot-for-Lot Item, Sales Order - Production Order from sales - post Prod Jnl - finish Prod Order - reduce sales Qty - create 2nd Sales Order - calc Regen plan.

        // Setup.
        Initialize;
        CalcPlanForLFLItemProductionOrderCreatedFromSalesOrder(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanTwiceForLFLItemFinishProductionOrderFromSalesOrderWithSalesShip()
    begin
        // [FEATURE] [Calculate Regenerative Plan] [Production]
        // [SCENARIO] Verify Quantity on Requisition Line: Lot-for-Lot Item, Sales Order - Production Order from sales - post Prod Jnl - finish Prod Order - reduce sales Qty - create 2nd Sales Order - calc Regen plan - post 1st Sales - calc Regen plan.

        // Setup.
        Initialize;
        CalcPlanForLFLItemProductionOrderCreatedFromSalesOrder(true);
    end;

    local procedure CalcPlanForLFLItemProductionOrderCreatedFromSalesOrder(PostSalesAndCalcPlan: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        OrderType: Option ItemOrder,ProjectOrder;
        StartDate: Date;
        EndDate: Date;
        Quantity: Integer;
    begin
        // Create Lot for Lot Item. Create Sales order. Create Production Order from Sales Order.
        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock -0.
        Quantity := LibraryRandom.RandInt(10) + 20;  // Large Random Quantity.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);
        LibraryVariableStorage.Enqueue(ReleasedProductionOrderCreatedTxt);  // Required inside MessageHandler.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(SalesHeader, ProductionOrder.Status::Released, OrderType::ItemOrder);

        // Open Production Journal and Post. Handler used -ProductionJournalHandler.
        SelectProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released);
        LibraryManufacturing.OutputJournalExplodeRouting(ProductionOrder);
        LibraryManufacturing.PostOutputJournal;

        // Change Status of Production Order from released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        UpdateQuantityOnSalesLine(SalesLine, Quantity - LibraryRandom.RandInt(10));

        // Create new sales Order.
        CreateSalesOrder(SalesHeader2, SalesLine2, Item."No.", SalesLine.Quantity - LibraryRandom.RandInt(5));

        // Exercise: Calculate Plan for Planning Worksheet.
        StartDate := GetRequiredDate(10, 0, WorkDate, -1);
        EndDate := GetRequiredDate(5, 10, WorkDate, 1);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, StartDate, EndDate);

        // Exercise: Calculate Plan for Planning Worksheet after First Sales Order Posting.
        if PostSalesAndCalcPlan then begin
            LibrarySales.PostSalesDocument(SalesHeader, true, false);
            LibraryPlanning.CalcRegenPlanForPlanWksh(Item, StartDate, EndDate);
        end;

        // Verify: Verify Quantity on Requisition Line.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        SelectProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Finished);
        VerifyRequisitionLineQuantity(
          RequisitionLine, SalesLine.Quantity + SalesLine2.Quantity - ProductionOrder.Quantity, 0,
          RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForSalesOrderFromBlanketOrderUsingForecastOrderItem()
    begin
        // Setup.
        Initialize;
        PlanningForSalesOrderFromBlanketOrderUsingForecastOrderItem(false);  // Post Sales Order -False.
    end;

    [Test]
    [HandlerFunctions('ReservationEntryPageHandler,ConfirmHandler,CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanTwiceForSalesOrderFromBlanketOrderWithSalesShipUsingForecastOrderItem()
    begin
        // Setup.
        Initialize;
        PlanningForSalesOrderFromBlanketOrderUsingForecastOrderItem(true);  // Post Sales Order -True.
    end;

    local procedure PlanningForSalesOrderFromBlanketOrderUsingForecastOrderItem(PostSalesAndCalcPlan: Boolean)
    var
        Item: Record Item;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
        OldStockoutWarning: Boolean;
        OldCreditWarnings: Option;
        Quantity: Integer;
    begin
        // Create Item, Production Forecast, Create Sales Order from Blanket Order.
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, false, SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", WorkDate, true);
        Quantity := LibraryRandom.RandInt(10);  // Random Quantity.
        CreateSalesOrderFromBlanketOrder(SalesHeader, SalesOrderHeader, Item."No.", Quantity);
        CreateRequisitionWorksheetName(RequisitionWkshName);

        // Exercise: Calculate regenerative Plan for Planning Worksheet. Calculate regenerative Plan again if required after posting Sales Order.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");
        SelectSalesLineFromSalesDocument(SalesLine, SalesOrderHeader."No.");
        if PostSalesAndCalcPlan then
            PostSalesAndCalcRegenPlan(SalesLine, SalesOrderHeader, PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Entries in Planning Worksheet.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        if not PostSalesAndCalcPlan then
            VerifyRequisitionLineQuantity(RequisitionLine, SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[2]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[3]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::Purchase);

        // Teardown.
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, OldStockoutWarning, OldCreditWarnings);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForBlanketOrderUpdatedOnSalesOrderUsingForecastOrderItem()
    begin
        // Setup.
        Initialize;
        PlanningForBlanketOrderUpdatedOnSalesOrderUsingForecastOrderItem(false);  // Post Sales Order and Calculate Plan -False.
    end;

    [Test]
    [HandlerFunctions('ReservationEntryPageHandler,ConfirmHandler,CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanTwiceForBlanketOrderUpdatedOnSalesOrderWithSalesShipUsingForecastOrderItem()
    begin
        // Setup.
        Initialize;
        PlanningForBlanketOrderUpdatedOnSalesOrderUsingForecastOrderItem(true);  // Post Sales Order and Calculate Plan -True.
    end;

    local procedure PlanningForBlanketOrderUpdatedOnSalesOrderUsingForecastOrderItem(PostSalesAndCalcPlan: Boolean)
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
        Quantity: Integer;
    begin
        // Create Item of Order Type Reordering Policy. Create Production Forecast. Create Blanket Order and Sales Order.
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", WorkDate, true);
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Quantity.
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, WorkDate);
        CreateSalesOrder(SalesHeader2, SalesLine2, Item."No.", Quantity - LibraryRandom.RandInt(5));  // Quantity less than Blanket Order.
        UpdateBlanketOrderNoOnSalesLine(SalesLine, SalesHeader."No.");  // Update Blanket Order No on Sales Order.
        CreateRequisitionWorksheetName(RequisitionWkshName);

        // Exercise: Calculate regenerative Plan for Planning Worksheet. Calculate regenerative Plan again if required after posting Sales Order.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");
        if PostSalesAndCalcPlan then
            PostSalesAndCalcRegenPlan(SalesLine2, SalesHeader2, PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Entries in Planning Worksheet.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        if not PostSalesAndCalcPlan then
            VerifyRequisitionLineQuantity(RequisitionLine, SalesLine2.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, (SalesLine.Quantity - SalesLine2.Quantity) + ProductionForecastEntry[1]."Forecast Quantity (Base)", 0,
          RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[2]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[3]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForBlanketOrderSalesOrderForSameItemUsingForecastOrderItem()
    begin
        // Setup.
        Initialize;
        PlanningForBlanketOrderSalesOrderForSameItemUsingForecastOrderItem(false);  // Update Blanket Order on Sales Order -False, Post Sales Order -False.
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanTwiceForBlanketOrderSalesOrderForSameItemUpdateBlanketOnSalesUsingForecastOrderItem()
    begin
        // Setup.
        Initialize;
        PlanningForBlanketOrderSalesOrderForSameItemUsingForecastOrderItem(true);  // Update Blanket Order on Sales Order -True, Post Sales Order -False.
    end;

    local procedure PlanningForBlanketOrderSalesOrderForSameItemUsingForecastOrderItem(BlanketOnSales: Boolean)
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
        Quantity: Integer;
    begin
        // Create Order Item, Create Production Forecast, Create Blanket Order and Create Sales Order.
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", WorkDate, true);
        Quantity := LibraryRandom.RandInt(10) + 5;  // Random Quantity.
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, WorkDate);
        CreateSalesOrder(SalesHeader2, SalesLine2, Item."No.", Quantity - LibraryRandom.RandInt(5));  // Quantity less than Blanket order.
        CreateRequisitionWorksheetName(RequisitionWkshName);

        // Exercise: Calculate regenerative Plan for Planning Worksheet. Calculate regenerative Plan again after updating Blanket Order no on posting Sales Order.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");
        if BlanketOnSales then
            UpdateBlanketOnSalesAndCalcRegenPlan(
              SalesLine, PlanningWorksheet, SalesHeader."No.", RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Requisition Lines for Quantity.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLine2.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, (SalesLine.Quantity - SalesLine2.Quantity) + ProductionForecastEntry[1]."Forecast Quantity (Base)", 0,
          RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[2]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[3]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('ReservationEntryPageHandler,ConfirmHandler,CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanThriceForBlanketOrderSalesOrderForSameOrderItemUpdateBlanketOnSalesWithSalesShipUsingForecast()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
        Quantity: Integer;
    begin
        // Setup: Create Order Item, Create Production Forecast, Create Blanket Order and Create Sales Order.
        Initialize;
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", WorkDate, true);
        Quantity := LibraryRandom.RandInt(10) + 5;  // Random Quantity.
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, WorkDate);
        CreateSalesOrder(SalesHeader2, SalesLine2, Item."No.", Quantity - LibraryRandom.RandInt(5));  // Quantity less than Blanket order.
        CreateRequisitionWorksheetName(RequisitionWkshName);

        // Calculate regenerative Plan for Planning Worksheet. Calculate regenerative Plan again after updating Blanket Order no on posting Sales Order.Calculate Plan again after Posting Sales Order.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");
        UpdateBlanketOnSalesAndCalcRegenPlan(
          SalesLine2, PlanningWorksheet, SalesHeader."No.", RequisitionWkshName.Name, Item."No.", Item."No.");
        PostSalesAndCalcRegenPlan(SalesLine2, SalesHeader2, PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Requisition Lines for Quantity.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(
          RequisitionLine, SalesLine.Quantity + ProductionForecastEntry[1]."Forecast Quantity (Base)", 0,
          RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[2]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[3]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForBlanketOrderSalesOrderForItemAndChildItemOfUsingForecastOrderItem()
    begin
        // Setup.
        Initialize;
        PlanningForBlanketOrderSalesOrderForItemAndChildItemUsingForecastOrderItem(false);  // Post Sales Order and Calculate Plan -False.
    end;

    [Test]
    [HandlerFunctions('ReservationEntryPageHandler,ConfirmHandler,CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanTwiceForBlanketOrderSalesOrderForItemAndChildItemWithSalesShipUsingForecastOrderItem()
    begin
        // Setup.
        Initialize;
        PlanningForBlanketOrderSalesOrderForItemAndChildItemUsingForecastOrderItem(true);  // Post Sales Order and Calculate Plan -True.
    end;

    local procedure PlanningForBlanketOrderSalesOrderForItemAndChildItemUsingForecastOrderItem(PostSalesAndCalcPlan: Boolean)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        Item: Record Item;
        ChildItem: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        ProductionForecastEntry2: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesLine3: Record "Sales Line";
        SalesLine4: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        RequisitionLine2: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        Quantity: Integer;
    begin
        // Create Item and Child Item. Create Production BOM, Create Production Forecast.
        CreateOrderItem(ChildItem, '', ChildItem."Replenishment System"::Purchase);  // Child Item.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");  // Parent Item.
        CreateOrderItem(Item, ProductionBOMHeader."No.", Item."Replenishment System"::"Prod. Order");
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", WorkDate, true);
        CreateProductionForecastSetup(ProductionForecastEntry2, ChildItem."No.", WorkDate, true);

        // Create Blanket Order with multiple Lines of Parent and Child Item.
        Quantity := LibraryRandom.RandInt(10) + 5;  // Random Quantity.
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, WorkDate);
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, ChildItem."No.", Quantity);

        // Create Sales Order with multiple Lines of Parent and Child Item.
        CreateSalesOrder(SalesHeader2, SalesLine3, Item."No.", Quantity - LibraryRandom.RandInt(5));
        LibrarySales.CreateSalesLine(SalesLine4, SalesHeader2, SalesLine4.Type::Item, ChildItem."No.", SalesLine.Quantity);

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", ChildItem."No.");

        // Calculate regenerative Plan again after posting Sales Order.
        if PostSalesAndCalcPlan then begin
            SalesLine3.ShowReservationEntries(true);  // Cancel Reservation. Handler used -ReservationEntry Handler.
            PostSalesAndCalcRegenPlan(SalesLine4, SalesHeader2, PlanningWorksheet, RequisitionWkshName.Name, Item."No.", ChildItem."No.");
        end;

        // Verify: Verify Requisition Lines for Quantity.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        SelectRequisitionLine(RequisitionLine2, ChildItem."No.");
        if PostSalesAndCalcPlan then begin
            VerifyRequisitionLineQuantity(RequisitionLine, SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::"Prod. Order");
            VerifyRequisitionLineQuantity(RequisitionLine2, SalesLine2.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
        end else begin
            VerifyRequisitionLineQuantity(RequisitionLine, SalesLine3.Quantity, 0, RequisitionLine."Ref. Order Type"::"Prod. Order");
            VerifyRequisitionLineQuantity(RequisitionLine, SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::"Prod. Order");
            VerifyRequisitionLineQuantity(RequisitionLine2, SalesLine3.Quantity, 0, RequisitionLine2."Ref. Order Type"::Purchase);
            VerifyRequisitionLineQuantity(RequisitionLine2, SalesLine.Quantity, 0, RequisitionLine2."Ref. Order Type"::Purchase);
            VerifyRequisitionLineQuantity(RequisitionLine2, SalesLine4.Quantity, 0, RequisitionLine2."Ref. Order Type"::Purchase);
        end;

        VerifyRequisitionLineQuantity(
          RequisitionLine2, ProductionForecastEntry2[1]."Forecast Quantity (Base)" - (SalesLine4.Quantity - SalesLine2.Quantity), 0,
          RequisitionLine2."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine2, ProductionForecastEntry2[2]."Forecast Quantity (Base)", 0, RequisitionLine2."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine2, ProductionForecastEntry2[3]."Forecast Quantity (Base)", 0, RequisitionLine2."Ref. Order Type"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanForReqWkshWithoutAnyDemandFRQItem()
    var
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Planning Worksheet]
        // [SCENARIO 127791] Calc a regenerative Plan without demands when default "Blank Overflow Level".
        Initialize;

        // [GIVEN] Create Item with Fixed Reorder Quantity, "Reorder Quantity" more than "Reorder Point".
        CreateItemAndSetFRQ(Item);

        // [WHEN] Calculate a regenerative Plan in Planning Worksheet without demands.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate, WorkDate);

        // [THEN] Planning Wksht contains 2 Entries with Quantity equal "Reorder Quantity" and "Safety Stock Quantity" from Item.
        VerifyQtyInTwoRequisitionLines(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanForReqWkshUseItemValuesFRQItemNoDemand()
    var
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Planning Worksheet]
        // [SCENARIO 378374] Calc a regenerative Plan without demands when "Blank Overflow Level" is "Use Item/SKU Values Only".
        Initialize;

        // [GIVEN] Set "Blank Overflow Level" in "Manufacturing Setup" as "Use Item/SKU Values Only".
        SetBlankOverflowLevelAsUseItemValues;
        // [GIVEN] Create Item with Fixed Reorder Quantity, "Reorder Quantity" more than "Reorder Point".
        CreateItemAndSetFRQ(Item);

        // [WHEN] Calculate a regenerative Plan in Planning Worksheet without demands.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate, WorkDate);

        // [THEN] Planning Wksht contains 2 Entries with Quantity equal "Reorder Quantity" and "Safety Stock Quantity" from Item.
        VerifyQtyInTwoRequisitionLines(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenerativePlanForTransferOrder()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        RequisitionLine: Record "Requisition Line";
        Quantity: Integer;
        EndDate: Date;
    begin
        // Setup: Create Lot for Lot Item, Create Transfer Order.
        Initialize;
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase);
        Quantity := LibraryRandom.RandInt(10) + 10;  // Random Quantity.

        // Create Transfer Order.
        CreateTransferOrderWithTransferRoute(TransferLine, Item."No.", LocationYellow.Code, LocationRed.Code, Quantity);

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        EndDate := GetRequiredDate(10, 20, WorkDate, 1);  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, EndDate);

        // Verify: Verify Entries in Planning Worksheet.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, 0, TransferLine.Quantity, RequisitionLine."Ref. Order Type"::Transfer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanForTransferOrder()
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionLine2: Record "Requisition Line";
        Quantity: Integer;
        ExpectedReceiptDate: Date;
        EndDate: Date;
    begin
        // Setup : Create Lot for Lot Items.
        Initialize;
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase);
        CreateItem(Item2, Item2."Reordering Policy"::"Lot-for-Lot", Item2."Replenishment System"::Purchase);
        Quantity := LibraryRandom.RandInt(10) + 10;  // Random Quantity.
        ExpectedReceiptDate := GetRequiredDate(10, 10, WorkDate, 1);  // Expected Receipt Date relative to Workdate.

        // Create Purchase Order and Transfer Order for different Items.
        CreatePurchaseOrder(PurchaseHeader, Item."No.", ExpectedReceiptDate, Quantity);  // Expected Receipt date, Quantity required.
        CreateTransferOrderWithTransferRoute(
          TransferLine, Item2."No.", LocationYellow.Code, LocationRed.Code, Quantity - LibraryRandom.RandInt(5));

        // Calculate Regenerative Plan for Planning Worksheet. Modify supply for one Item.
        EndDate := GetRequiredDate(10, 20, WorkDate, 1);  // End Date relative to Workdate.
        Item.SetFilter("No.", '%1|%2', Item."No.", Item2."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, EndDate);
        UpdateQuantityOnPurchaseLine(PurchaseLine, Item."No.", Quantity - LibraryRandom.RandInt(5));

        // Exercise: Calculate Net Change Plan after change in supply pattern.
        Item.SetFilter("No.", '%1|%2', Item."No.", Item2."No.");
        LibraryPlanning.CalcNetChangePlanForPlanWksh(Item, WorkDate, EndDate, false);

        // Verify: Verify Entries after Net change planning in Planning Worksheet.
        SelectPurchaseLine(PurchaseLine, Item."No.");
        SelectRequisitionLine(RequisitionLine, Item2."No.");
        SelectRequisitionLine(RequisitionLine2, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, 0, TransferLine.Quantity, RequisitionLine."Ref. Order Type"::Transfer);
        VerifyRequisitionLineQuantity(RequisitionLine2, 0, PurchaseLine.Quantity, RequisitionLine2."Ref. Order Type"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanForSalesOrderFromBlanketOrderForProductionOrderOrderItem()
    var
        Item: Record Item;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        OldStockoutWarning: Boolean;
        OldCreditWarnings: Option;
        ShipmentDate: Date;
        EndDate: Date;
        Quantity: Integer;
    begin
        // Setup: Create Order Item.
        Initialize;
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, false, SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateOrderItem(Item, '', Item."Replenishment System"::"Prod. Order");
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Quantity.

        // Create Sales Order from Blanket Order.
        CreateSalesOrderFromBlanketOrder(SalesHeader, SalesOrderHeader, Item."No.", Quantity);

        // Update Shipment Date in newly created Sales Order from Blanket Order.
        ShipmentDate := GetRequiredDate(5, 0, SalesHeader."Shipment Date", 1);  // Shipment Date more than Shipment Date Of Blanket Order.
        UpdateShipmentDateOnSalesHeader(SalesOrderHeader, ShipmentDate);

        // Exercise: Calculate Regenerative Plan for Planning Worksheet.
        EndDate := GetRequiredDate(10, 20, ShipmentDate, 1);  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, EndDate);

        // Verify: Verify Requisition Lines for Quantity.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        SelectSalesLineFromSalesDocument(SalesLine, SalesOrderHeader."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::"Prod. Order");

        // Teardown.
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, OldStockoutWarning, OldCreditWarnings);
    end;

    [Test]
    [HandlerFunctions('ReservationEntryPageHandler,ConfirmHandler,CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanTwiceForSalesOrderFromBlanketOrderWithSalesShipUsingForecastForProductionOrderOrderItem()
    var
        Item: Record Item;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderHeader: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
        OldStockoutWarning: Boolean;
        OldCreditWarnings: Option;
        ForecastDate: Date;
        ShipmentDate: Date;
        ShipmentDate2: Date;
        Quantity: Integer;
    begin
        // Setup: Create Order Item, Create Production Forecast for Production Order.
        Initialize;
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, false, SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateOrderItem(Item, '', Item."Replenishment System"::"Prod. Order");
        ForecastDate := GetRequiredDate(30, 20, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, false);  // Boolean -False, for Single Forecast Entry.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Quantity.
        ShipmentDate := GetRequiredDate(10, 0, ProductionForecastEntry[1]."Forecast Date", -1);  // Shipment Date relative to Forecast Date.

        // Create Sales Order from Blanket Order.
        CreateSalesOrderFromBlanketOrderWithNewQuantityToShip(SalesHeader, SalesOrderHeader, SalesLine, Item."No.", Quantity, ShipmentDate);

        // Update Shipment date in newly created Sales Order from Blanket Order.
        ShipmentDate2 := GetRequiredDate(5, 0, SalesHeader."Shipment Date", -1);  // Shipment Date less than Shipment Date Of Blanket Order.
        UpdateShipmentDateOnSalesHeader(SalesOrderHeader, ShipmentDate2);
        CreateRequisitionWorksheetName(RequisitionWkshName);

        // Calculate Regenerative Plan for Planning Worksheet.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Exercise: Calculate Regenerative Plan again after posting Sales Order.
        SelectSalesLineFromSalesDocument(SalesLine2, SalesOrderHeader."No.");
        PostSalesAndCalcRegenPlan(SalesLine2, SalesOrderHeader, PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Requisition Lines for Quantity.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(
          RequisitionLine, SalesLine.Quantity - SalesLine2.Quantity, 0, RequisitionLine."Ref. Order Type"::"Prod. Order");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::"Prod. Order");

        // Teardown.
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, OldStockoutWarning, OldCreditWarnings);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanForBlanketOrderUpdatedOnSalesOrderForProductionOrderOrderItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        EndDate: Date;
        Quantity: Integer;
    begin
        // Setup: Create Order Item.
        Initialize;
        CreateOrderItem(Item, '', Item."Replenishment System"::"Prod. Order");
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Quantity.

        // Create Blanket Order.
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, WorkDate);

        // Create Sales Order. Update Quantity and Blanket Order No.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader2, SalesLine2.Type::Item, Item."No.", Quantity - LibraryRandom.RandInt(5));
        BindSalesOrderLineToBlanketOrderLine(SalesLine2, SalesLine);

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        EndDate := GetRequiredDate(10, 20, SalesHeader."Shipment Date", 1);  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, EndDate);

        // Verify: Verify Requisition Lines for Quantity.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLine2.Quantity, 0, RequisitionLine."Ref. Order Type"::"Prod. Order");
        VerifyRequisitionLineQuantity(
          RequisitionLine, SalesLine.Quantity - SalesLine2.Quantity, 0, RequisitionLine."Ref. Order Type"::"Prod. Order");
    end;

    [Test]
    [HandlerFunctions('ReservationEntryPageHandler,ConfirmHandler,CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanTwiceForBlanketOrderUpdatedOnSalesOrderWithSalesShipUsingForecastProductionOrderOrderItem()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
        ShipmentDate: Date;
        Quantity: Integer;
    begin
        // Setup: Create Order Item, Create Production Forecast for Production Order.
        Initialize;
        CreateOrderItem(Item, '', Item."Replenishment System"::"Prod. Order");
        ForecastDate := GetRequiredDate(30, 20, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, false);  // Boolean -False, for Single Forecast Entry.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Quantity.

        // Create Blanket Order.
        ShipmentDate := GetRequiredDate(10, 0, ProductionForecastEntry[1]."Forecast Date", -1);  // Shipment Date relative to Forecast Date.
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, ShipmentDate);

        // Create Sales Order. Update Quantity and Blanket Order No.
        CreateSalesOrder(SalesHeader2, SalesLine2, Item."No.", Quantity - LibraryRandom.RandInt(5));  // Quantity less than Blanket Order.
        UpdateQuantityOnSalesLine(SalesLine2, SalesLine2.Quantity - LibraryRandom.RandInt(5));  // Quantity less than Quantity of first Sales Line.
        UpdateBlanketOrderNoOnSalesLine(SalesLine2, SalesHeader."No.");  // Update Blanket Order No on Sales Order.

        // Calculate regenerative Plan for Planning Worksheet
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Exercise: Calculate regenerative Plan again after posting Sales Order.
        PostSalesAndCalcRegenPlan(SalesLine2, SalesHeader2, PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Requisition Lines for Quantity.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::"Prod. Order");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::"Prod. Order");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForBlanketOrderUpdatedOnSalesOrderWithForecastProductionOrderOrderItem()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        RequisitionLine2: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
        Quantity: Integer;
        SalesLineQuantity: Integer;
    begin
        // Setup: Create Order Item, Create Production Forecast.
        Initialize;
        CreateOrderItem(Item, '', Item."Replenishment System"::"Prod. Order");
        ForecastDate := GetRequiredDate(20, 20, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, false);  // Boolean - False, for Single Forecast Entry.

        // Create Blanket Order.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Quantity.
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, WorkDate);

        // Create Sales Order with multiple lines and update Quantity and Blanket Order No.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(
          SalesLine2, SalesHeader2, SalesLine2.Type::Item, Item."No.", Quantity - LibraryRandom.RandInt(5));
        BindSalesOrderLineToBlanketOrderLine(SalesLine2, SalesLine);
        LibrarySales.CreateSalesLine(
          SalesLine2, SalesHeader2, SalesLine2.Type::Item, Item."No.", SalesLine2.Quantity - LibraryRandom.RandInt(5));
        BindSalesOrderLineToBlanketOrderLine(SalesLine2, SalesLine);

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Requisition Lines for Quantity.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        SelectSalesLineFromSalesDocument(SalesLine2, SalesHeader2."No.");
        SalesLineQuantity := SalesLine2.Quantity;  // Select Quantity from first Sales Line.
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLineQuantity, 0, RequisitionLine."Ref. Order Type"::"Prod. Order");
        SalesLine2.Next;  // Move to second Sales Line.
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLine2.Quantity, 0, RequisitionLine."Ref. Order Type"::"Prod. Order");
        VerifyRequisitionLineQuantity(
          RequisitionLine, SalesLine.Quantity - SalesLineQuantity - SalesLine2.Quantity, 0,
          RequisitionLine2."Ref. Order Type"::"Prod. Order");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::"Prod. Order");
    end;

    [Test]
    [HandlerFunctions('ReservationEntryPageHandler,ConfirmHandler,CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanTwiceForBlanketOrderUpdatedOnMultiLineSalesOrderSalesShipUsingForecastProductionOrderOrderItem()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
        Quantity: Integer;
    begin
        // Setup: Create Order Items, Create Production Forecast.
        Initialize;
        CreateOrderItem(Item, '', Item."Replenishment System"::"Prod. Order");
        ForecastDate := GetRequiredDate(20, 20, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, false);  // Boolean - False, for Single Forecast Entry.

        // Create Blanket Order.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Quantity.
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, WorkDate);

        // Create Sales Order with multiple lines and update Quantity and Blanket Order No.
        CreateSalesOrderTwoLinesWithBlanketOrderNo(
          SalesHeader2, SalesHeader."No.", Item."No.", Quantity - LibraryRandom.RandInt(5));  // Quantity less then Quantity of Blanket Order.
        SelectSalesLineFromSalesDocument(SalesLine2, SalesHeader2."No.");

        // Calculate regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");
        SalesLine2.ShowReservationEntries(true);  // Cancel Reservation for first Sales Line. Handler used - ReservationEntry Handler.
        SalesLine2.Next;  // Move to second Sales Line.

        // Exercise: Calculate regenerative Plan again after posting Sales Order.
        PostSalesAndCalcRegenPlan(SalesLine2, SalesHeader2, PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Requisition Lines for Quantity.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::"Prod. Order");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::"Prod. Order");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForMultiLineSalesOrderUsingForecastOrderItems()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        ProductionForecastEntry2: array[3] of Record "Production Forecast Entry";
        RequisitionLine: Record "Requisition Line";
        RequisitionLine2: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
        ForecastDate2: Date;
        Quantity: Integer;
    begin
        // Setup: Create Order Item, Create Production Forecast for multiple Items.
        Initialize;
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        CreateOrderItem(Item2, '', Item2."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        ForecastDate2 := GetRequiredDate(2, 1, ForecastDate, 1);  // Forecast Date Relative to Forecast Date of first Item.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, false);  // Boolean - False, for Single Forecast Entry.
        CreateProductionForecastSetup(ProductionForecastEntry2, Item2."No.", ForecastDate2, false);  // Boolean - False, for Single Forecast Entry.

        // Create Sales Order with multiple Lines.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Integer Quantity Required.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);
        LibrarySales.CreateSalesLine(
          SalesLine2, SalesHeader, SalesLine2.Type::Item, Item2."No.", SalesLine.Quantity - LibraryRandom.RandInt(5));  // Quantity less than first Sales Line Quantity.
        CreateRequisitionWorksheetName(RequisitionWkshName);

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item2."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        SelectRequisitionLine(RequisitionLine2, Item2."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(RequisitionLine2, SalesLine2.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine2, ProductionForecastEntry2[1]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForForecastAndSalesForDifferentOrderItems()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        RequisitionLine2: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
        Quantity: Integer;
    begin
        // Setup: Create Order Item, Create Production Forecast.
        Initialize;
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        CreateOrderItem(Item2, '', Item2."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, false);  // Boolean - False, for Single Forecast Entry.

        // Create Sales Order for different Item.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Integer Quantity Required.
        CreateSalesOrder(SalesHeader, SalesLine, Item2."No.", Quantity);
        CreateRequisitionWorksheetName(RequisitionWkshName);

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item2."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        SelectRequisitionLine(RequisitionLine2, Item2."No.");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(RequisitionLine2, SalesLine.Quantity, 0, RequisitionLine2."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForSalesOrderUsingForecastOrderItem()
    begin
        // Setup.
        Initialize;
        PlanningForSalesOrderUsingForecastOrderItem(false);  // Post Sales Order and Calculate Plan - False.
    end;

    [Test]
    [HandlerFunctions('ReservationEntryPageHandler,ConfirmHandler,CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanTwiceForSalesOrderWithSalesShipUsingForecastOrderItem()
    begin
        // Setup.
        Initialize;
        PlanningForSalesOrderUsingForecastOrderItem(true);  // Post Sales Order and Calculate Plan - True.
    end;

    local procedure PlanningForSalesOrderUsingForecastOrderItem(PostSalesAndCalcPlan: Boolean)
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
        ShipmentDate: Date;
        Quantity: Integer;
    begin
        // Create Order Item, Create Production Forecast.
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entries.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Integer Quantity Required.

        // Create Sales Order. Update Shipment Date on Sales Line.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);
        ShipmentDate := GetRequiredDate(2, 1, ForecastDate, 1);  // Shipment Date Relative to Forecast Date.
        UpdateShipmentDateOnSalesLine(SalesLine, ShipmentDate);

        // Exercise: Calculate regenerative Plan for Planning Worksheet. Calculate regenerative Plan again if required after posting Sales Order.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");
        if PostSalesAndCalcPlan then
            PostSalesAndCalcRegenPlan(SalesLine, SalesHeader, PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        if not PostSalesAndCalcPlan then begin
            VerifyRequisitionLineQuantity(RequisitionLine, SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
            VerifyRequisitionLineQuantity(
              RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity (Base)" - SalesLine.Quantity, 0,
              RequisitionLine."Ref. Order Type"::Purchase);
        end else
            VerifyRequisitionLineQuantity(
              RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[2]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[3]."Forecast Quantity (Base)", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForSalesOrderUsingForecastOrderItemsForZeroQuantity()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        ProductionForecastEntry2: array[3] of Record "Production Forecast Entry";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
        Quantity: Integer;
    begin
        // Setup: Create Order Items.
        Initialize;
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        CreateOrderItem(Item2, '', Item."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Integer Quantity Required.

        // Create Production Forecasts for different Items with single entry.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, false);  // Boolean - False, for Single Forecast Entry.
        CreateAndUpdateProductionForecastSetup(ProductionForecastEntry2, Item2."No.", ForecastDate, 0, false);  // Update Production Forecast Quantity to - 0. Boolean - False, for Single Forecast Entry.

        // Create Sales Order for first Item.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);

        // Exercise: Calculate Regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item2."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForForecastOrderItemForNegativeQuantity()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
    begin
        // Setup: Create Order Item.
        Initialize;
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.

        // Create Production Forecasts for different Item with single entry.
        CreateAndUpdateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, -LibraryRandom.RandInt(10), false);  // Boolean - False, for Single Forecast Entry. Update Production Forecast Quantity to Negative Quantity.

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify that no Requisition line is created for Requisition Worksheet.
        FilterOnRequisitionLine(RequisitionLine, Item."No.");
        Assert.IsTrue(RequisitionLine.IsEmpty, StrSubstNo(RequisitionLineMustNotExistTxt, Item."No."));
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanUsingDifferentForecastEntriesForDifferentOrderItem()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        ProductionForecastEntry2: array[3] of Record "Production Forecast Entry";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
    begin
        // Setup: Create Order Item.
        Initialize;
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        CreateOrderItem(Item2, '', Item2."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.

        // Create Production Forecasts for same Item with multiple entries.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entries.
        CreateProductionForecastSetup(ProductionForecastEntry2, Item2."No.", ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entries.

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item2."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item2."No.");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry2[1]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry2[2]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry2[3]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForSalesOrdersWithFirmAndReleasedProdOrderUsingForecastTypeSalesItem()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        ProductionOrder: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
        Quantity: Integer;
    begin
        // Setup: Create Lot for Lot Item.
        Initialize;
        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0.
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entries.

        // Create Released Production Order.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Integer Quantity Required.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released, Quantity, false, 0D);

        // Create Firm Planned Production Order.
        CreateAndRefreshProductionOrder(
          ProductionOrder2, Item."No.", ProductionOrder2.Status::"Firm Planned", Quantity - LibraryRandom.RandInt(5), false, 0D);  // Quantity less than Released Production Order.

        // Create Sales Order with multiple Lines.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);
        LibrarySales.CreateSalesLine(
          SalesLine2, SalesHeader, SalesLine2.Type::Item, Item."No.", SalesLine.Quantity - LibraryRandom.RandInt(5));  // Quantity less than First Sales Line.

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(
          RequisitionLine, SalesLine.Quantity + SalesLine2.Quantity, ProductionOrder.Quantity,
          RequisitionLine."Ref. Order Type"::"Prod. Order");
        VerifyRequisitionLineQuantity(RequisitionLine, 0, ProductionOrder2.Quantity, RequisitionLine."Ref. Order Type"::"Prod. Order");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[2]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[3]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForFirmAndReleasedProdOrderUsingForecastTypeComponent()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        ProductionOrder: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
        Quantity: Integer;
    begin
        // Setup:  Create Lot for Lot Item.
        Initialize;
        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0.
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.

        // Create Production Forecast. Update Production Forecast Type - Component.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entries.
        UpdateProductionForecastType(ProductionForecastEntry, true);

        // Create Released Production Order.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Integer Quantity Required.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released, Quantity, false, 0D);

        // Create Firm Planned Production Order.
        CreateAndRefreshProductionOrder(
          ProductionOrder2, Item."No.", ProductionOrder2.Status::"Firm Planned", Quantity - LibraryRandom.RandInt(5), false, 0D);  // Quantity less than Released Production Order.

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, 0, ProductionOrder.Quantity, RequisitionLine."Ref. Order Type"::"Prod. Order");
        VerifyRequisitionLineQuantity(RequisitionLine, 0, ProductionOrder2.Quantity, RequisitionLine."Ref. Order Type"::"Prod. Order");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[2]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[3]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForOrderItemWithInventoryUsingForecast()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        ItemJournalLine: Record "Item Journal Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
        Quantity: Integer;
    begin
        // Setup: Create Order Item. Create Production forecast for multiple entries.
        Initialize;
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entries.
        Quantity := LibraryRandom.RandInt(10) + 10;  // Random Integer Quantity Required.

        // Create and Post Item Journal Line.
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate, Quantity);  // Inventory Value required for Test.

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[2]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[3]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForOrderItemWithInventoryAndReleasedProdOrderUsingForecast()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
        Quantity: Integer;
    begin
        // Setup: Create Order Item. Create Production forecast for multiple entries.
        Initialize;
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entries.
        Quantity := LibraryRandom.RandInt(10) + 10;  // Random Integer Quantity Required.

        // Create and Post Item Journal Line.
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate, Quantity);  // Inventory Value required for Test.

        // Create Released Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released, Quantity, false, 0D);

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, 0, ProductionOrder.Quantity, RequisitionLine."Ref. Order Type"::"Prod. Order");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[2]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[3]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanWithMPSForSalesOrderOrderItemUsingForecast()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        OldCombinedMPSMRPCalculation: Boolean;
        Quantity: Integer;
        ForecastDate: Date;
        ShipmentDate: Date;
    begin
        // Setup: Create Order Item. Create Production Forecast.
        Initialize;
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation of Manufacturing Setup -FALSE.
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, false);

        // Create Sales Order. Update Shipment Date.
        Quantity := LibraryRandom.RandInt(10);
        ShipmentDate := GetRequiredDate(10, 0, ForecastDate, 1);  // Shipment Date Relative to Forecast Date.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);
        UpdateShipmentDateOnSalesLine(SalesLine, ShipmentDate);

        // Exercise: Calculate regenerative Plan with MPS - TRUE and MRP - FALSE for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity" - SalesLine.Quantity, 0,
          RequisitionLine."Ref. Order Type"::Purchase);

        // Teardown.
        UpdateManufacturingSetup(OldCombinedMPSMRPCalculation);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanWithMPSForProductionForecastOrderItem()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
        OldCombinedMPSMRPCalculation: Boolean;
    begin
        // Setup: Create Order Item. Create Production Forecast.
        Initialize;
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation of Manufacturing Setup -FALSE.
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, false);

        // Exercise: Calculate regenerative Plan with MPS - TRUE and MRP - FALSE for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);

        // Teardown.
        UpdateManufacturingSetup(OldCombinedMPSMRPCalculation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanWithMPSForSalesOrderOrderItem()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldCombinedMPSMRPCalculation: Boolean;
        EndDate: Date;
        Quantity: Integer;
    begin
        // Setup: Create Order Item.
        Initialize;
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation of Manufacturing Setup -FALSE.
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);

        // Create Sales Order. Update Shipment Date.
        Quantity := LibraryRandom.RandInt(10);  // Random Integer Quantity Required.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);
        EndDate := GetRequiredDate(20, 0, SalesLine."Shipment Date", 1);  // End Date related to Sales Line Shipment Date.

        // Exercise: Calculate regenerative Plan with MPS - TRUE and MRP - FALSE for Planning Worksheet.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, EndDate);

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);

        // Teardown.
        UpdateManufacturingSetup(OldCombinedMPSMRPCalculation);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanWithMPSForReleasedProdOrderWithConsumptionJournalLFLItemUsingForecast()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ItemJournalLine: Record "Item Journal Line";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        OldCombinedMPSMRPCalculation: Boolean;
        ForecastDate: Date;
        Quantity: Integer;
    begin
        // Setup: Create Lot for Lot Parent and Child Item. Create And Certify Production BOM.
        Initialize;
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation of Manufacturing Setup -FALSE.
        CreateLotForLotItem(ChildItem, 0, '<0D>');  // Safety Stock - 0. Child Item.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");

        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0. Parent Item.
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");

        // Create Production Forecast with single Entry.
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, ChildItem."No.", ForecastDate, false);

        // Create Released Production Order. Create and Post Consumption Journal.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Integer Quantity Required.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released, Quantity, false, 0D);
        UpdateInventory(ItemJournalLine, ChildItem."No.", WorkDate, Quantity);  // Inventory Value required for Test.
        CreateAndPostConsumptionJournal(ProductionOrder."No.");

        // Exercise: Calculate regenerative Plan with MPS - TRUE and MRP - FALSE for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", ChildItem."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, ChildItem."No.");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);

        // Teardown.
        UpdateManufacturingSetup(OldCombinedMPSMRPCalculation);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForReleasedProdOrderWithConsumptionJournalLFLItemUsingForecast()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ItemJournalLine: Record "Item Journal Line";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
        Quantity: Integer;
    begin
        // Setup: Create Lot for Lot Parent and Child Item. Create And Certify Production BOM.
        Initialize;
        CreateLotForLotItem(ChildItem, 0, '<0D>');  // Safety Stock - 0. Child Item.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");

        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0. Parent Item.
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");

        // Create Production Forecast with single Entry.
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, ChildItem."No.", ForecastDate, false);

        // Create Released Production Order. Create and Post Consumption Journal.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Integer Quantity Required.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released, Quantity, false, 0D);
        UpdateInventory(ItemJournalLine, ChildItem."No.", WorkDate, Quantity);  // Inventory Value required for Test.
        CreateAndPostConsumptionJournal(ProductionOrder."No.");

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", ChildItem."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, ChildItem."No.");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForMultipleReleasedProdOrdersWithConsumptionJournalLFLItemUsingMultipleForecastEntries()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ItemJournalLine: Record "Item Journal Line";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
        DueDate: Date;
        Quantity: Integer;
    begin
        // Setup: Create Lot for Lot Parent and Child Item. Create And Certify Production BOM.
        Initialize;
        CreateLotForLotItem(ChildItem, 0, '<0D>');  // Safety Stock - 0. Child Item.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");

        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0. Parent Item.
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");

        // Create Production Forecast with multiple entries.
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, ChildItem."No.", ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entries.

        // Create multiple Released Production Orders. Create and Post Consumption Journal.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Integer Quantity Required.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released, Quantity, false, 0D);
        DueDate := GetRequiredDate(10, 0, ProductionOrder."Due Date", 1);  // Due Date Relative to Due Date of first Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder2, Item."No.", ProductionOrder.Status::Released, Quantity, true, DueDate);
        UpdateInventory(ItemJournalLine, ChildItem."No.", WorkDate, Quantity);  // Inventory Value required for Test.
        CreateAndPostConsumptionJournal(ProductionOrder."No.");

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", ChildItem."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, ChildItem."No.");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[2]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[3]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanWithMPSNegativeSalesUsingForecastLFLItemForZeroQuantity()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        OldCombinedMPSMRPCalculation: Boolean;
        ForecastDate: Date;
    begin
        // Setup: Create Lot for Lot  Item. Create Production Forecast with multiple Entries.
        Initialize;
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation of Manufacturing Setup -FALSE.
        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0, Lot Accumulation Period - 0D.
        ForecastDate := GetRequiredDate(10, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateAndUpdateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, 0, true); // Boolean - TRUE, for multiple Forecast Entries. Update Production Forecast Quantity to - 0.

        // Create Sales Order with Negative Quantity.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", -LibraryRandom.RandDec(10, 2));  // Negative Random Quantity Required.

        // Exercise: Calculate regenerative Plan with MPS - TRUE and MRP - FALSE for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[2]."Forecast Quantity" + SalesLine.Quantity, 0,
          RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[3]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);

        // Teardown.
        UpdateManufacturingSetup(OldCombinedMPSMRPCalculation);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanWithMPSSalesShipUsingForecastLFLItemForZeroQuantity()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        OldCombinedMPSMRPCalculation: Boolean;
        ForecastDate: Date;
    begin
        // Setup: Create Lot for Lot  Item.
        Initialize;
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation of Manufacturing Setup -FALSE.
        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0, Lot Accumulation Period - 0D.

        // Create Production Forecast with multiple Entries. Update Production Forecast Quantity to - 0.
        ForecastDate := GetRequiredDate(30, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateAndUpdateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, 0, true); // Boolean - TRUE, for multiple Forecast Entries.

        // Create Sales Order with Negative Quantity.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", -LibraryRandom.RandDec(10, 2));  // Negative Random Quantity Required.

        // Calculate regenerative Plan with MPS - TRUE and MRP - FALSE for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");
        UpdateQuantityOnSalesLine(SalesLine, LibraryRandom.RandDec(10, 2));  // Update random quantity On Sales Line.

        // Exercise: Calculate Plan for Planning Worksheet after Sales Order Posting.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[2]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[3]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);

        // Teardown.
        UpdateManufacturingSetup(OldCombinedMPSMRPCalculation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanWithSalesForNewPlannedDeliveryDateLFLItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ShipmentDate: Date;
        EndDate: Date;
    begin
        // Setup: Create Lot for Lot  Item. Create Production Forecast with multiple Entries.
        Initialize;
        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0, Lot Accumulation Period - 0D.

        // Create Sales Order. Update Shipment Date and Planned Delivery Date on Sales Line.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));  // Random quantity value not important.
        ShipmentDate := GetRequiredDate(2, 1, WorkDate, 1);  // Shipment Date Relative to WORKDATE.
        UpdateShipmentDateOnSalesLine(SalesLine, ShipmentDate);
        UpdatePlannedDeliveryDateOnSalesLine(SalesLine, ShipmentDate);

        // Exercise: Calculate Regenerative Plan for Planning Worksheet.
        EndDate := GetRequiredDate(10, 20, SalesLine."Planned Delivery Date", 1);  // End Date relative to Planned Delivery Date.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, EndDate);

        // Verify: Verify Planned Delivery Date, Quantities and Reference Order Type on Planning Worksheet.
        VerifyPlannedDeliveryDate(Item."No.", SalesLine."Planned Delivery Date");
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLine.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanWithSalesPostForNewPlannedDeliveryDateUsingForecastLFLItem()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ShipmentDate: Date;
        ForecastDate: Date;
    begin
        // Setup: Create Lot for Lot  Item. Create Production Forecast with multiple Entries.
        Initialize;
        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0, Lot Accumulation Period - 0D.
        ForecastDate := GetRequiredDate(30, 0, WorkDate, 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entries.

        // Create Sales Order. Update Shipment Date and Planned Delivery Date on Sales Line.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));  // Random quantity value not important.
        ShipmentDate := GetRequiredDate(2, 1, ForecastDate, 1);  // Shipment Date Relative to Forecast Date.
        UpdateShipmentDateOnSalesLine(SalesLine, ShipmentDate);
        UpdatePlannedDeliveryDateOnSalesLine(SalesLine, ShipmentDate);

        // Calculate Regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Update Item inventory.
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate, LibraryRandom.RandDec(10, 2));  // Random quantity value not important.

        // Exercise: Calculate Plan for Planning Worksheet after Sales Order Posting.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Ship and Invoice - TRUE.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(
          RequisitionLine, SalesLine.Quantity - ItemJournalLine.Quantity, 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[1]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[2]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(
          RequisitionLine, ProductionForecastEntry[3]."Forecast Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReCalcPlanForUpdateSalesShipmentDateAndDeletePlanningLines()
    var
        TopItem: Record Item;
        MiddleItem: Record Item;
        BottomItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ShipmentDate: Date;
        ShipmentDate2: Date;
    begin
        // Setup: Plan and carry out the Demand. Change shipment date.
        CarryOutDemandAndUpdateSalesShipmentDate(TopItem, MiddleItem, BottomItem, ShipmentDate, ShipmentDate2);

        // Re-calculate.
        CalculateRegenerativePlanForPlanWorksheet(MiddleItem."No.", TopItem."No.");

        // Exercise: Delete the Requisition Worksheet lines.
        FilterOnRequisitionLines(RequisitionLine, MiddleItem."No.", TopItem."No.");
        RequisitionLine.DeleteAll(true);

        // Verify: Reservation Entry.
        // Reservation lines existed with Source Type = Prod. Order Component (1 record) / Prod. Order Line (1 record).
        // No Tracking lines existed.
        VerifyReservationEntryOfReservationExist(MiddleItem."No.", true, 1);
        VerifyReservationEntryOfTrackingExist(MiddleItem."No.", ShipmentDate, false);
        VerifyReservationEntryOfTrackingExist(MiddleItem."No.", ShipmentDate2, false);

        // Verify: Firm Planned Prod. Order lines existed.
        VerifyFirmPlannedProdOrderExist(TopItem."No.", ShipmentDate, true);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReCalcPlanForUpdateSalesShipmentDateAndCarryOut()
    var
        TopItem: Record Item;
        MiddleItem: Record Item;
        BottomItem: Record Item;
        ShipmentDate: Date;
        ShipmentDate2: Date;
    begin
        // Setup: Plan and carry out the Demand. Change shipment date.
        CarryOutDemandAndUpdateSalesShipmentDate(TopItem, MiddleItem, BottomItem, ShipmentDate, ShipmentDate2);

        // Exercise: Re-calculate and Carry out.
        CalculateRegenerativePlanAndCarryOut(MiddleItem."No.", TopItem."No.", false); // Default Accept Action Message is False for "Cancel" lines, True for "New" lines

        // Verify: Reservation Entry.
        // Reservation lines existed with Source Type = Prod. Order Component (2 records) / Prod. Order Line (2 records).
        // Tracking lines existed with Shipment Date = original Shipment Date.
        // Tracking lines existed with Shipment Date = Updated Shipment Date.
        VerifyReservationEntryOfReservationExist(MiddleItem."No.", true, 2);
        VerifyReservationEntryOfTrackingExist(TopItem."No.", ShipmentDate, true);
        VerifyReservationEntryOfTrackingExist(TopItem."No.", ShipmentDate2, true);

        // Verify: Firm Planned Prod. Order.
        // Firm Planned Prod. Order existed with Due Date = Original Shipment Date.
        // Firm Planned Prod. Order existed with Due Date = Updated Shipment Date.
        VerifyFirmPlannedProdOrderExist(TopItem."No.", ShipmentDate, true);
        VerifyFirmPlannedProdOrderExist(TopItem."No.", ShipmentDate2, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdatePromisedReceiptDateLateThanExpectedReceiptDate()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
    begin
        // Setup: Create Sales Order. Calculate Plan for Requisition Worksheet and Carry out Action Message.
        Initialize;
        CarryOutDemandInRequisitionWorksheet(Item, SalesHeader, SalesLine);

        // Exercise: Update the Promised Receipt Date in Purchase Order.
        LibraryVariableStorage.Enqueue(ModifiedPromisedReceiptDateMsg); // Required inside ConfirmHandler.
        LibraryVariableStorage.Enqueue(ReservationsExistMsg);
        SelectPurchaseLine(PurchaseLine, Item."No.");
        UpdatePromisedReceiptDateOnPurchaseHeader(PurchaseLine."Document No.", GetRequiredDate(10, 0, WorkDate, 1));

        // Verify: Reservation Entry is removed.
        VerifyReservationEntry(Item."No.", false, WorkDate);

        // Exercise: Run Available to Promise in Sales Order.
        AvailabilityMgt.SetSalesHeader(TempOrderPromisingLine, SalesHeader);
        AvailabilityMgt.CalcAvailableToPromise(TempOrderPromisingLine);

        // Verify: Verify the Earliest Shipment date in Order Promising Table.
        PurchaseLine.FindFirst;
        TempOrderPromisingLine.TestField("Earliest Shipment Date", PurchaseLine."Expected Receipt Date");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdatePromisedReceiptDateEarlyThanExpectedReceiptDate()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        ManufacturingSetup: Record "Manufacturing Setup";
        PromisedReceiptDate: Date;
    begin
        // Setup: Create Sales Order. Calculate Plan for Requisition Worksheet and Carry out Action Message.
        Initialize;
        CarryOutDemandInRequisitionWorksheet(Item, SalesHeader, SalesLine);

        // Exercise: Update the Promised Receipt Date in Purchase Order.
        LibraryVariableStorage.Enqueue(ModifiedPromisedReceiptDateMsg); // Required inside ConfirmHandler.
        LibraryVariableStorage.Enqueue(ReservationsExistMsg);
        PromisedReceiptDate := GetRequiredDate(10, 0, WorkDate, -1);
        SelectPurchaseLine(PurchaseLine, Item."No.");
        UpdatePromisedReceiptDateOnPurchaseHeader(PurchaseLine."Document No.", PromisedReceiptDate);

        // Verify: Reservation Entry existed.
        ManufacturingSetup.Get;
        VerifyReservationEntry(Item."No.", true, CalcDate(ManufacturingSetup."Default Safety Lead Time", PromisedReceiptDate));

        // Exercise: Run Available to Promise in Sales Order.
        AvailabilityMgt.SetSalesHeader(TempOrderPromisingLine, SalesHeader);
        AvailabilityMgt.CalcAvailableToPromise(TempOrderPromisingLine);

        // Verify: Verify the Earliest Shipment date in Order Promising Table.
        PurchaseLine.FindFirst;
        TempOrderPromisingLine.TestField("Earliest Shipment Date", SalesLine."Shipment Date");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdatePromisedReceiptDateInPurchaseOrderLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Setup: Create Sales Order. Calculate Plan for Requisition Worksheet and Carry out Action Message.
        Initialize;
        CarryOutDemandInRequisitionWorksheet(Item, SalesHeader, SalesLine);

        // Exercise: Update the Promised Receipt Date in Purchase Order line.
        // Verify: Promised Receipt Date changed successfully if earlier than original date
        SelectPurchaseLine(PurchaseLine, Item."No.");
        PurchaseOrder.OpenEdit;
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseLine."Document No.");
        PurchaseOrder.PurchLines."Promised Receipt Date".SetValue(GetRequiredDate(10, 0, WorkDate, -1));

        // Exercise: Update the Promised Receipt Date in Purchase Order line.
        // Verify: Error message pops up if late than original date
        asserterror PurchaseOrder.PurchLines."Promised Receipt Date".SetValue(GetRequiredDate(20, 0, WorkDate, 1));
        Assert.ExpectedError(DateConflictWithExistingReservationsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithOppositeTransferOrder()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Calculate Regeneration Plan]
        // [SCENARIO 363209] Can calculate regeneration plan for Item with opposite Transfer Order.

        // [GIVEN] Item with two SKUs.
        Initialize;
        LibraryInventory.CreateItem(Item);
        Item.SetRange("No.", Item."No.");
        SelectTransferRoute(LocationYellow.Code, LocationRed.Code);

        // [GIVEN] SKU for location "A" with Purchase replenishment.
        CreateSKU(
          Item, LocationYellow.Code, StockkeepingUnit."Replenishment System"::Purchase,
          StockkeepingUnit."Reordering Policy"::"Lot-for-Lot", '', true,
          '<' + Format(LibraryRandom.RandIntInRange(7, 14)) + 'D>',
          '<' + Format(LibraryRandom.RandIntInRange(1, 5)) + 'D>');

        // [GIVEN] SKU for location "B" with Transfer from "A" replenishment.
        CreateSKU(
          Item, LocationRed.Code, StockkeepingUnit."Replenishment System"::Transfer,
          StockkeepingUnit."Reordering Policy"::Order, LocationYellow.Code, false,
          '', '<' + Format(LibraryRandom.RandIntInRange(1, 5)) + 'W>');

        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Create Transfer from "B" to "A", with 1 day shipping time, no stock available.
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationRed.Code, LocationYellow.Code, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Quantity);
        Item.SetFilter("Location Filter", '%1|%2', LocationYellow.Code, LocationRed.Code);

        // [WHEN] Calculate Regeneration Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate), CalcDate('<+CY>', WorkDate));

        // [THEN] Requisition Line created successfully.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, Quantity, 0, RequisitionLine."Ref. Order Type"::Transfer);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TFS358446_RecalcReqPlanWithOrderToOrderBinding()
    var
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
    begin
        InitializeOrderPlanRecalculdationScenario(Item, Item."Reordering Policy"::"Lot-for-Lot");
        RecalculateReqPlanAfterOrderPlan(DemandType::Sales, Item);

        Item.CalcFields("Qty. on Sales Order");
        VerifyReservedQuantity(Item."No.", ReservEntry."Reservation Status"::Reservation, Item."Qty. on Sales Order");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TFS358867_CalcOrderPlanRecalculateReqPlanMaxQtyReplenishment()
    var
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
    begin
        InitializeOrderPlanRecalculdationScenario(Item, Item."Reordering Policy"::"Maximum Qty.");
        RecalculateReqPlanAfterOrderPlan(DemandType::Sales, Item);

        Item.CalcFields("Qty. on Sales Order");
        VerifyReservedQuantity(Item."No.", ReservEntry."Reservation Status"::Reservation, Item."Qty. on Sales Order");
        VerifyReservedQuantity(Item."No.", ReservEntry."Reservation Status"::Surplus, Item."Maximum Inventory");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TFS358867_CalcOrderPlanRecalculateReqPlanForIncreasedSalesQuantity()
    var
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
    begin
        InitializeOrderPlanRecalculdationScenario(Item, Item."Reordering Policy"::"Maximum Qty.");
        CalculateOrderPlanAndCarryOut(DemandType::Sales, Item."No.");

        RecalculateReqPlanForIncreasedSalesQty(Item);

        Item.CalcFields("Qty. on Sales Order");
        VerifyReservedQuantity(Item."No.", ReservEntry."Reservation Status"::Reservation, Item."Qty. on Sales Order");
        VerifyReservedQuantity(Item."No.", ReservEntry."Reservation Status"::Surplus, Item."Maximum Inventory");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TFS358867_CalculateReqPlanOnlyForIncreasedSalesQuantity()
    var
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
    begin
        InitializeOrderPlanRecalculdationScenario(Item, Item."Reordering Policy"::"Maximum Qty.");

        RecalculateReqPlanForIncreasedSalesQty(Item);

        Item.CalcFields("Qty. on Sales Order", Inventory);
        VerifyReservedQuantity(Item."No.", ReservEntry."Reservation Status"::Tracking, Item."Qty. on Sales Order" - Item.Inventory);
        VerifyReservedQuantity(Item."No.", ReservEntry."Reservation Status"::Surplus, Item."Maximum Inventory");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS359949_CalcOrderPlanRecalculateReqPlanForProductionComponent()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ReservEntry: Record "Reservation Entry";
        Qty: Integer;
    begin
        // Setup: Create production order. Component's reordering policy is "Maximum quantity"
        Initialize;
        Qty := LibraryRandom.RandInt(100);
        CreateItemWithReorderPoint(
          CompItem, CompItem."Reordering Policy"::"Maximum Qty.", CompItem."Replenishment System"::Purchase, Qty, Qty + 1);
        LibraryPatterns.MAKEItemSimple(ProdItem, ProdItem."Costing Method"::FIFO, 0);

        CreateReleasedProdOrder(ProdItem, CompItem, Qty);

        // Exercise: Recalculate requisition plan for component item
        RecalculateReqPlanAfterOrderPlan(DemandType::Production, CompItem);

        // Verify: Demand from production order is reserved, safety stock quantity purchase is planned
        CompItem.CalcFields("Qty. on Component Lines");
        VerifyReservedQuantity(CompItem."No.", ReservEntry."Reservation Status"::Reservation, CompItem."Qty. on Component Lines");
        VerifyReservedQuantity(CompItem."No.", ReservEntry."Reservation Status"::Surplus, CompItem."Maximum Inventory");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure StartingDateForRoutingHeaderWithNoLines()
    var
        ReqLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
    begin
        // [FEATURE] [Requisition Line] [Routing]
        // [SCENARIO 375131] "Starting Date" field of "Requisition Line" table should be updated if appropriate Routing Header has no lines

        // [GIVEN] Routing Header "R" without Routing Lines
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // [GIVEN] Requisition Line for "R" with "Ending Date" = "X", "Starting Date" = "0D"
        MockRequisitionLine(ReqLine, RoutingHeader."No.", 0D, Today);

        // [WHEN] Run CalcStartingDate
        ReqLine.CalcStartingDate('');

        // [THEN] "Starting Date" = "X"
        ReqLine.TestField("Starting Date", ReqLine."Ending Date");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EndingDateForRoutingHeaderWithNoLines()
    var
        ReqLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
    begin
        // [FEATURE] [Requisition Line] [Routing]
        // [SCENARIO 375131] "Ending Date" field of "Requisition Line" table should be updated if appropriate Routing Header has no lines

        // [GIVEN] Routing Header "R" without Routing Lines
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // [GIVEN] Requisition Line for "R" with "Starting Date" = "X", "Ending Date" = "0D"
        MockRequisitionLine(ReqLine, RoutingHeader."No.", Today, 0D);

        // [WHEN] Run CalcEndingDate
        ReqLine.CalcEndingDate('');

        // [THEN] "Ending Date" = "X"
        ReqLine.TestField("Ending Date", ReqLine."Starting Date");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SurplusEntryOnShipmentDateUpdateProduction()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        OrderMultipleQty: Decimal;
    begin
        // [FEATURE] [Planning Worksheet] [Item Tracking] [Manufacturing]
        // [SCENARIO 376248] Surplus Reservation Entry exists after recalculation of Production Item supply and surplus exists because of "Order Multiple" rounding.

        Initialize;

        // [GIVEN] Production Item with Order Multiple = "X", "Order Tracking Policy" = "Tracking Only", available stock = "S".
        OrderMultipleQty := LibraryRandom.RandDecInRange(10, 50, 1);
        with Item do begin
            LibraryVariableStorage.Enqueue(WillNotAffectExistingMsg);
            CreateItem(Item, "Reordering Policy"::"Lot-for-Lot", "Replenishment System"::"Prod. Order");
            Validate("Minimum Order Quantity", OrderMultipleQty);
            Validate("Order Multiple", OrderMultipleQty);
            Validate("Order Tracking Policy", "Order Tracking Policy"::"Tracking Only");
            Modify(true);
            LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(
              StockkeepingUnit, LocationRed.Code, "No.", '');
            LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, LocationRed.Code, "Inventory Posting Group");
            LibraryInventory.UpdateInventoryPostingSetup(LocationRed);
            UpdateInventoryOnLocation(
              ItemJournalLine, "No.", LocationRed.Code, WorkDate, LibraryRandom.RandDecInRange(100, 200, 2));
        end;

        // [GIVEN] Create Sales Order of Quantity = "S" + "X" / 2, delivery date = WORKDATE + 2 weeks. Calculate regeneration plan and carry out.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", ItemJournalLine.Quantity + OrderMultipleQty / 2);
        SalesLine.Validate("Location Code", LocationRed.Code);
        SalesLine.Modify(true);
        SalesHeader.Validate("Requested Delivery Date", CalcDate('<+2W>', WorkDate));
        SalesHeader.Modify(true);
        CalculateRegenerativePlanAndCarryOut(Item."No.", Item."No.", true);

        // [GIVEN] Open created Production Order, set "Ending Date" to WORKDATE + 4 weeks.
        SelectProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::"Firm Planned");
        ProductionOrder.Validate("Ending Date", CalcDate('<+4W>', WorkDate));
        ProductionOrder.Modify(true);

        // [WHEN] Calculate regeneration plan and carry out.
        CalcRegenPlanAcceptAndCarryOut(
          FindRequisitionWkshName(ReqWkshTemplate.Type::Planning), Item."No.");

        // [THEN] Surplus Reservation Entry is present of Quantity = "X" / 2.
        VerifySurplusReservationEntry(Item."No.", OrderMultipleQty / 2);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanReqWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculatePlanFromReqWrkshtWithRespectPlanningParamsForCompItemSeparetelyForTransferAndPurchase()
    var
        MnfgLocation: Record Location;
        PurchaseLocation: Record Location;
        ParentItem: Record Item;
        ChildItem: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        RequisitionLine: Record "Requisition Line";
        DueDate: Date;
        ReorderQty: Decimal;
        SafetyStockQty: Decimal;
        OrderQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [SKU] [Planning Parameters]
        // [SCENARIO 202033] Calculating plan from requisition worksheet with "Respect Planning Parameters" for component item separetely for transfer and purchase replenishment systems.
        Initialize;

        // [GIVEN] Manufacturing Location "ML" and Purchase Location "PL"
        CreateLocationsChain(PurchaseLocation, MnfgLocation);

        // [GIVEN] Parent Item "PI" with Child Item "CI" as BOM Component
        CreateItemAndBOMWithComponentItem(ParentItem, ChildItem);

        // [GIVEN] 3 Released Production Orders at "ML" each with Quantity = "POQ" and different due dates
        OrderQty := LibraryRandom.RandIntInRange(5000, 10000);
        DueDate := LibraryRandom.RandDateFromInRange(WorkDate, 5, 10);
        for i := 1 to 3 do begin
            CreateReleasedProductionOrderAtLocationWithDueDateAndRefresh(ParentItem."No.", OrderQty, DueDate, MnfgLocation.Code);
            DueDate := LibraryRandom.RandDateFromInRange(DueDate, 5, 10);
        end;

        // [GIVEN] SKU for "CI" at "PL" with "Replenishment System" = Purchase, "Reordering Policy" = "Fixed Reorder Qty.", "Reorder Quantity" "RQ" = 4 * "POQ", "Safety Stock Quantity" "SSQ" = 5 * "POQ"
        ReorderQty := OrderQty * 4;
        SafetyStockQty := OrderQty * 5;
        CreateSKUForLocationWithReplenishmentSystemAndReorderingPolicy(
          ChildItem."No.", PurchaseLocation.Code, StockkeepingUnit."Replenishment System"::Purchase, '',
          StockkeepingUnit."Reordering Policy"::"Fixed Reorder Qty.", ReorderQty, SafetyStockQty);

        // [GIVEN] SKU for "CI" at "ML" with "Replenishment System" = Transfer, "Transfer-from Code" = "PL", "Reordering Policy" = Order
        CreateSKUForLocationWithReplenishmentSystemAndReorderingPolicy(
          ChildItem."No.", MnfgLocation.Code, StockkeepingUnit."Replenishment System"::Transfer, PurchaseLocation.Code,
          StockkeepingUnit."Reordering Policy"::Order, 0, 0);

        // [GIVEN] Calculate Plan from Requisition Worksheet for "CI" from WORKDATE - 1 (at yerstaday) at location "ML", "Respect Planning Parameters" = TRUE
        ReqWorksheetCalculatePlan(ChildItem."No.", MnfgLocation.Code, WorkDate - 1, DueDate, true);

        // [WHEN] Calculate Plan from Requisition Worksheet for "CI" from WORKDATE - 1 (at yerstaday) at location "PL", "Respect Planning Parameters" = TRUE
        ReqWorksheetCalculatePlan(ChildItem."No.", PurchaseLocation.Code, WorkDate - 1, DueDate, true);

        FilterRequisitionLineByLocationAndPurchaseItem(RequisitionLine, PurchaseLocation.Code, ChildItem."No.");
        // [THEN] Two Requisition Lines at Location "PL" for Item "CI" with "Replenishment System" = Purchase are created
        Assert.RecordCount(RequisitionLine, 2);

        // [THEN] One of them has Quantity = "RQ", second of them has Quantity = 2 * "RQ"
        RequisitionLine.SetRange(Quantity, ReorderQty);
        Assert.RecordCount(RequisitionLine, 1);

        RequisitionLine.SetRange(Quantity, ReorderQty * 2);
        Assert.RecordCount(RequisitionLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculatePlanDoesNotIncludeDropShipmentSalesOrders()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Order Planning] [Sales] [Drop Shipment]
        // [SCENARIO 214007] Sales orders for drop shipment should not be included in the list of demands when Calculate Plan is run on Order Planning page.
        Initialize;

        // [GIVEN] Sales Order for drop shipment of item "I".
        CreateSalesOrder(SalesHeader, SalesLine, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10));
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);

        // [WHEN] Calculate plan for sales demand.
        CalculateOrderPlan(RequisitionLine, DemandType::Sales);

        // [THEN] Requisition line for item "I" is not created.
        FilterOnRequisitionLine(RequisitionLine, SalesLine."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineLocationCodeFromSpecialOrder()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        Vendor: array[2] of Record Vendor;
        Purchasing: Record Purchasing;
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Special Order]
        // [SCENARIO 263844] Location code in requisition line is not copied from the vendor card when the vendor No. is updated if the requisition line refers to a special order.
        Initialize;

        // [GIVEN] Item "I", locations "L1" and "L2", vendors "V1" and "V2", "I"."Vendor No." = "V1", "V2"."Location Code" = "L2"
        CreateItemLocationVendorSetup(Item, Location, Vendor);

        // [GIVEN] Sales order with special order purchasing code for "I"
        LibraryPurchase.CreateSpecialOrderPurchasingCode(Purchasing);
        CreateSalesOrderWithPurchasingCode(SalesLine, '', Item."No.", Location[1].Code, Purchasing.Code, LibraryRandom.RandInt(10));

        // [GIVEN] Get special order to "Requisition Line" "R"
        CreateRequisitionLine(RequisitionLine);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, Item."No.");

        FindRequisitionLineForItem(RequisitionLine, Item."No.");
        RequisitionLine.TestField("Vendor No.", Vendor[1]."No.");

        // [WHEN] Update "R"."Vendor No." to "V2"
        UpdateRequisitionLineVendorNo(RequisitionLine, Vendor[2]."No.");

        // [THEN] "R"."Location Code" is equal to "L1"
        RequisitionLine.TestField("Location Code", Location[1].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineLocationCodeFromDropShipment()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        Vendor: array[2] of Record Vendor;
        Purchasing: Record Purchasing;
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 263844] Location code in requisition line is not copied from the vendor card when the vendor No. is updated if the requisition line refers to a sales order with drop shipment purchasing code.
        Initialize;

        // [GIVEN] Item "I", locations "L1" and "L2", vendors "V1" and "V2", "I"."Vendor No." = "V1", "V2"."Location Code" = "L2"
        CreateItemLocationVendorSetup(Item, Location, Vendor);

        // [GIVEN] Sales order with drop shipment purchasing code for "I"
        LibraryPurchase.CreateDropShipmentPurchasingCode(Purchasing);
        CreateSalesOrderWithPurchasingCode(SalesLine, '', Item."No.", Location[1].Code, Purchasing.Code, LibraryRandom.RandInt(10));

        // [GIVEN] Get drop shipment sales order to "Requisition Line" "R"
        CreateRequisitionLine(RequisitionLine);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, 0);

        FindRequisitionLineForItem(RequisitionLine, Item."No.");
        RequisitionLine.TestField("Vendor No.", Vendor[1]."No.");

        // [WHEN] Update "R"."Vendor No." to "V2"
        UpdateRequisitionLineVendorNo(RequisitionLine, Vendor[2]."No.");

        // [THEN] "R"."Location Code" is equal to "L1"
        RequisitionLine.TestField("Location Code", Location[1].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineLocationCodeFromVendor()
    var
        Location: Record Location;
        Vendor: Record Vendor;
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 263844] Requisition line "Location Code" is copied from vendor card when populate "Vendor No." with the field "No." of the vendor.
        Initialize;

        // [GIVEN] Location "L", vendor "V", "V"."Location Code" = "L"
        LibraryWarehouse.CreateLocation(Location);
        LibraryPurchase.CreateVendor(Vendor);
        UpdateVendorLocationCode(Vendor, Location.Code);

        // [GIVEN] Requisition Line "R"
        CreateRequisitionLine(RequisitionLine);

        // [WHEN] Update "R"."Vendor No." = "V"
        UpdateRequisitionLineVendorNo(RequisitionLine, Vendor."No.");

        // [THEN] "R"."Location Code" = "L"
        RequisitionLine.TestField("Location Code", Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyingFromPlanWkshtToReqWkshtAddsNewRequisitionLines()
    var
        ReqLineInReqWksh: Record "Requisition Line";
        ReqLineInPlanWksh: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        NewPurchOrderChoice: Option " ","Make Purch. Orders","Make Purch. Orders & Print","Copy to Req. Wksh";
        ItemNo: array[2] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Planning Worksheet]
        // [SCENARIO 264807] When user chooses to copy planning lines to requisition lines by carrying out action, the new lines are added after existing lines in requisition worksheet.
        Initialize;

        // [GIVEN] Items "I1", "I2".
        for i := 1 to ArrayLen(ItemNo) do
            ItemNo[i] := LibraryInventory.CreateItemNo;

        // [GIVEN] A line in requisition worksheet with item "I1".
        CreateRequisitionLine(ReqLineInReqWksh);
        ReqLineInReqWksh.Validate(Type, ReqLineInReqWksh.Type::Item);
        ReqLineInReqWksh.Validate("No.", ItemNo[1]);
        ReqLineInReqWksh.Modify(true);

        // [GIVEN] A line in planning worksheet with item "I2".
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(ReqLineInPlanWksh, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        ReqLineInPlanWksh.Validate(Type, ReqLineInPlanWksh.Type::Item);
        ReqLineInPlanWksh.Validate("No.", ItemNo[2]);
        ReqLineInPlanWksh.Validate("Accept Action Message", true);
        ReqLineInPlanWksh.Validate(Quantity, LibraryRandom.RandInt(10));
        ReqLineInPlanWksh.Modify(true);

        // [WHEN] Carry out action in planning worksheet with option "Copy to Req. Worksheet".
        LibraryPlanning.CarryOutPlanWksh(
          ReqLineInPlanWksh, 0, NewPurchOrderChoice::"Copy to Req. Wksh", 0, 0,
          ReqLineInReqWksh."Worksheet Template Name", ReqLineInReqWksh."Journal Batch Name", '', '');

        // [THEN] The line with "I1" is not deleted from the requisition worksheet.
        ReqLineInReqWksh.SetRange("Worksheet Template Name", ReqLineInReqWksh."Worksheet Template Name");
        ReqLineInReqWksh.SetRange("Journal Batch Name", ReqLineInReqWksh."Journal Batch Name");
        ReqLineInReqWksh.FindFirst;
        ReqLineInReqWksh.TestField("No.", ItemNo[1]);

        // [THEN] A new line with item "I2" is inserted into the requisition worksheet after the "I1" line.
        ReqLineInReqWksh.Next;
        ReqLineInReqWksh.TestField("No.", ItemNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionWorksheetCarryOutActionMessagesSameVendorNoDifferentPurchasingCodes()
    var
        Purchasing: array[2] of Record Purchasing;
        Item: array[2] of Record Item;
        Customer: Record Customer;
        Vendor: Record Vendor;
        SalesLine: array[3] of Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        i: Integer;
    begin
        // [FEATURE] [Carry Out Action Message]
        // [SCENARIO 268443] When carry out action messages in requisition worksheet the items are placed correctly by purchase orders with different Purchasing Codes when "Vendor No." is the same
        Initialize;

        // [GIVEN] Create 2 purchasing codes ("P1" and "P2"), 2 items ("I1" and "I2"). Both of them with the same "Vendor No."
        // [GIVEN] Create 3 sales orders: "S1" has "I1" and "P1", "S2" has "I2" and "P2", "S3" has "I1" and "P1", Customer is the same for all sales orders.
        LibrarySales.CreateCustomer(Customer);
        LibraryPurchase.CreateVendor(Vendor);
        for i := 1 to 2 do begin
            CreateItem(Item[i], Item[i]."Reordering Policy"::"Lot-for-Lot", Item[i]."Replenishment System"::Purchase);
            Item[i].Validate("Vendor No.", Vendor."No.");
            Item[i].Modify(true);
            LibraryPurchase.CreateDropShipmentPurchasingCode(Purchasing[i]);
            CreateSalesOrderWithPurchasingCode(SalesLine[i], Customer."No.", Item[i]."No.", '', Purchasing[i].Code, LibraryRandom.RandInt(10));
        end;
        CreateSalesOrderWithPurchasingCode(SalesLine[3], Customer."No.", Item[1]."No.", '', Purchasing[1].Code, LibraryRandom.RandInt(10));

        // [GIVEN] In requisition worksheet page invoke "Drop Shipment - Get Sales Orders"
        CreateRequisitionLine(RequisitionLine);
        GetDropShipmentSalesOrders(
          RequisitionLine, StrSubstNo('%1|%2|%3', SalesLine[1]."Document No.", SalesLine[2]."Document No.", SalesLine[3]."Document No."));

        // [WHEN] Carry out action messages
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate, WorkDate, WorkDate, WorkDate, '');

        // [THEN] Two purchase lines with "I1" are created, both in single order, and one line with "I2" in another order
        PurchaseLine.SetRange("No.", Item[1]."No.");
        Assert.RecordCount(PurchaseLine, 2);
        PurchaseLine.FindFirst;

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        Assert.RecordCount(PurchaseLine, 2);

        PurchaseLine.SetRange("Document No.");
        PurchaseLine.SetRange("No.", Item[2]."No.");
        Assert.RecordCount(PurchaseLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningComponentDueDateTimeSynchedWithPlanningRoutingLine()
    var
        ProdItem: Record Item;
        CompItem: array[2] of Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: array[2] of Record "Routing Link";
    begin
        // [FEATURE] [Routing Link] [Due Date-Time] [Planning Component]
        // [SCENARIO 269798] When planning production components, "Due Date" and "Due Time" fields of the component are copied from "Starting Date" and "Starting Time" of the linked routing line

        Initialize;

        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);

        // [GIVEN] Manufactured item "I" with planning setup, replenished via production order
        CreateItem(ProdItem, ProdItem."Reordering Policy"::"Fixed Reorder Qty.", ProdItem."Replenishment System"::"Prod. Order");

        LibraryManufacturing.CreateRoutingLink(RoutingLink[1]);
        LibraryManufacturing.CreateRoutingLink(RoutingLink[2]);

        // [GIVEN] Production BOM for the item "I" with 2 components. BOM lines have routing links "R1" and "R2"
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItem."Base Unit of Measure");
        CreateProdBOMLineWithRoutingLink(ProductionBOMHeader, ProductionBOMLine, CompItem[1]."No.", 1, RoutingLink[1].Code);
        CreateProdBOMLineWithRoutingLink(ProductionBOMHeader, ProductionBOMLine, CompItem[2]."No.", 1, RoutingLink[2].Code);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        // [GIVEN] Routing with 2 operations, lines have routing links "R1" and "R2" assigned to link them with respective BOM lines
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        // Run time is hardcoded to ensure that "Due Datetime" is different on component lines
        CreateRoutingLineWithRoutingLink(RoutingHeader, RoutingLine, LibraryUtility.GenerateGUID, WorkCenter."No.", 120, RoutingLink[1].Code);
        CreateRoutingLineWithRoutingLink(RoutingHeader, RoutingLine, LibraryUtility.GenerateGUID, WorkCenter."No.", 60, RoutingLink[2].Code);
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        ProdItem.Validate("Reorder Quantity", 10);
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Validate("Routing No.", RoutingHeader."No.");
        ProdItem.Modify(true);

        // [WHEN] Calculate regenerative plan for the item "I"
        LibraryPlanning.CalcRegenPlanForPlanWksh(ProdItem, WorkDate, WorkDate);

        // [THEN] Value of "Due Date" and "Due Time" in planning component lines are in synch with "Starting Date" and "Starting Time" of the linked planning routing lines
        VerifyPlanningDueDateTime(RoutingLink[1].Code);
        VerifyPlanningDueDateTime(RoutingLink[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningComponentQtyIsRecalculatedOnChangeQtyOnParentRequisitionLine()
    var
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        ReqWorksheet: TestPage "Req. Worksheet";
        Qty: Decimal;
    begin
        // [FEATURE] [Planning Component]
        // [SCENARIO 279595] The program recalculates "Expected Quantity" on planning component when a user changes Quantity on parent requisition line.
        Initialize;

        Qty := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Requisition line. Quantity = "X".
        CreateRequisitionLine(RequisitionLine);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", LibraryInventory.CreateItemNo);
        RequisitionLine.Validate("Starting Date", WorkDate);
        RequisitionLine.Validate("Ending Date", WorkDate);
        RequisitionLine.Validate(Quantity, Qty);
        RequisitionLine.Modify(true);

        // [GIVEN] Planning component of the requisition line. "Quantity per" = "N".
        // [GIVEN] "Expected Quantity" is now equal to "X" * "N".
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.Validate("Item No.", LibraryInventory.CreateItemNo);
        PlanningComponent.Validate("Quantity per", LibraryRandom.RandInt(10));
        PlanningComponent.Modify(true);

        // [WHEN] Open requisition worksheet page and update Quantity to "Y".
        ReqWorksheet.OpenEdit;
        ReqWorksheet.GotoRecord(RequisitionLine);
        ReqWorksheet.Quantity.SetValue(2 * Qty);

        // [THEN] "Expected Quantity" on the planning component becomes equal to "Y" * "N".
        PlanningComponent.Find;
        PlanningComponent.TestField("Expected Quantity", 2 * Qty * PlanningComponent."Quantity per");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWkshCalculatePlanDoesntOversupplyWithReOrderPointAndDemandInsideLeadTime()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Reorder Point]
        // [SCENARIO 287931] Calculate Plan for item with reorder point doesn't order too much when there is demand between last reorder and it's due date
        Initialize;

        // [GIVEN] An Item with Reorder Point Qty. = 1, Purchase, Reorder Point = 150, Lead Time = 2W
        CreateItemWithReorderPointAndQuantity(
          Item, Item."Reordering Policy"::"Fixed Reorder Qty.",
          Item."Replenishment System"::Purchase, LibraryRandom.RandIntInRange(100, 200), 1);
        UpdateLeadTimeCalculationForItem(Item, '<' + Format(LibraryRandom.RandIntInRange(10, 15)) + 'D>');

        // [GIVEN] Existing inventory for Item with Quantity = 70
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate - 1, LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Sales order for this item with line Quantity = 30 and Shipment date between Start Date and Due Date for first Requisition Line
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandIntInRange(10, 50));
        UpdateShipmentDateOnSalesLine(SalesLine, WorkDate + 1);

        // [WHEN] Calculate plan run with dates to have StartDate < Sales Order date < End Date
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate, WorkDate + 2);
        SelectRequisitionLine(RequisitionLine, Item."No.");

        // [THEN] 2 Lines are suggested
        Assert.RecordCount(RequisitionLine, 2);

        // [THEN] 1st line quantity = 150 - 70 + 1 = 81 (Exceeding Reorder Point by minimal margin)
        RequisitionLine.FindFirst;
        RequisitionLine.TestField(Quantity, Item."Reorder Point" - ItemJournalLine.Quantity + Item."Reorder Quantity");

        // [THEN] 2nd line quantity = 30 (Compensating sales order)
        RequisitionLine.FindLast;
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWkshCalculatePlanDoesntOversupplyWithReOrderPointAndSupplyInsideLeadTime()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PurchaseOrderQuantity: Integer;
    begin
        // [FEATURE] [Reorder Point]
        // [SCENARIO 287931] Calculate Plan for item with reorder point doesn't order too much when there is supply between last reorder and it's due date
        Initialize;

        // [GIVEN] An Item with Reorder Point Qty. = 1, Purchase, Reorder Point = 150, Lead Time = 2W
        CreateItemWithReorderPointAndQuantity(
          Item, Item."Reordering Policy"::"Fixed Reorder Qty.",
          Item."Replenishment System"::Purchase, LibraryRandom.RandIntInRange(100, 200), 1);
        UpdateLeadTimeCalculationForItem(Item, '<' + Format(LibraryRandom.RandIntInRange(10, 15)) + 'D>');

        // [GIVEN] Existing inventory for Item with Quantity = 70
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate - 1, LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Purchase order for this item with line Quantity = 30 and Shipment date between Start Date and Due Date for first Requisition Line
        PurchaseOrderQuantity := LibraryRandom.RandIntInRange(20, 50);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", WorkDate + 1, PurchaseOrderQuantity);

        // [WHEN] Calculate plan run with dates to have StartDate < Sales Order date < End Date
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate, WorkDate + 2);
        SelectRequisitionLine(RequisitionLine, Item."No.");

        // [THEN] Requisition line quantity = 150 - 70 - 30 + 1 = 51 (Exceeding Reorder Point by minimal margin)
        RequisitionLine.FindFirst;
        RequisitionLine.TestField(
          Quantity, Item."Reorder Point" - ItemJournalLine.Quantity - PurchaseOrderQuantity + Item."Reorder Quantity");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandFromBlanketOrderLineIsFulfilledByPlanningAfterBeenUtilizedForOneOrderLine()
    var
        Item: Record Item;
        SalesHeaderBlanket: Record "Sales Header";
        SalesHeaderOrder: Record "Sales Header";
        SalesLineBlanket: Record "Sales Line";
        SalesLineOrder: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
    begin
        // [FEATURE] [Sales] [Order] [Blanket Order] [Lot-for-Lot]
        // [SCENARIO 314222] The planning takes into account a sales blanket order line that is partially utilized for one sales order line.
        Initialize;
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Lot-for-lot item.
        CreateLotForLotItem(Item, 0, '2W');

        // [GIVEN] Sales blanket order with two lines, each for 100 pcs, shipment dates are 01/05/20 and 01/08/20 accordingly.
        // [GIVEN] Set "Qty. to Ship" = 80 on both lines in the blanket order.
        LibrarySales.CreateSalesHeader(SalesHeaderBlanket, SalesHeaderBlanket."Document Type"::"Blanket Order", '');
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLineBlanket, SalesHeaderBlanket, SalesLineBlanket.Type::Item, Item."No.", WorkDate + 30, 100);
        UpdateQuantityToShipOnSalesLine(SalesLineBlanket, 80);
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLineBlanket, SalesHeaderBlanket, SalesLineBlanket.Type::Item, Item."No.", WorkDate + 90, 100);
        UpdateQuantityToShipOnSalesLine(SalesLineBlanket, 80);

        // [GIVEN] Make a sales order from the blanket order.
        BlanketSalesOrderToOrder.Run(SalesHeaderBlanket);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesHeaderOrder);

        // [GIVEN] Change shipment date on the first sales order line from 01/05/20 one month forward to 01/06/20.
        LibrarySales.FindFirstSalesLine(SalesLineOrder, SalesHeaderOrder);
        SalesLineOrder.Validate("Shipment Date", WorkDate + 60);
        SalesLineOrder.Modify(true);

        // [WHEN] Calculate regenerative plan on the period covering all demands, that is 01/04/20..01/09/20.
        Item.SetRecFilter;
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate + 120);

        // [THEN] A planning line to fulfill the remaining 20 pcs (100 - 80) on the first blanket order line is created.
        RequisitionLine.SetRange("Due Date", WorkDate + 30);
        FindRequisitionLineForItem(RequisitionLine, Item."No.");
        Assert.AreEqual(20, RequisitionLine.Quantity, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandFromBlanketOrderLineIsFulfilledByPlanningAfterBeenUtilizedForSeveralOrderLines()
    var
        Item: Record Item;
        SalesHeaderBlanket: Record "Sales Header";
        SalesHeaderOrder: Record "Sales Header";
        SalesLineBlanket: Record "Sales Line";
        SalesLineOrder: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
    begin
        // [FEATURE] [Sales] [Order] [Blanket Order] [Lot-for-Lot]
        // [SCENARIO 314222] The planning takes into account a sales blanket order line that is partially utilized for several sales order lines.
        Initialize;
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Lot-for-lot item.
        CreateLotForLotItem(Item, 0, '2W');

        // [GIVEN] Sales blanket order with two lines, each for 100 pcs, shipment dates are 01/05/20 and 01/08/20 accordingly.
        // [GIVEN] Set "Qty. to Ship" = 70 on both lines in the blanket order.
        LibrarySales.CreateSalesHeader(SalesHeaderBlanket, SalesHeaderBlanket."Document Type"::"Blanket Order", '');
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLineBlanket, SalesHeaderBlanket, SalesLineBlanket.Type::Item, Item."No.", WorkDate + 30, 100);
        UpdateQuantityToShipOnSalesLine(SalesLineBlanket, 70);
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLineBlanket, SalesHeaderBlanket, SalesLineBlanket.Type::Item, Item."No.", WorkDate + 90, 100);
        UpdateQuantityToShipOnSalesLine(SalesLineBlanket, 70);

        // [GIVEN] Make a sales order from the blanket order.
        // [GIVEN] Change shipment date on the first sales order line from 01/05/20 one month forward to 01/06/20.
        BlanketSalesOrderToOrder.Run(SalesHeaderBlanket);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesHeaderOrder);
        LibrarySales.FindFirstSalesLine(SalesLineOrder, SalesHeaderOrder);
        SalesLineOrder.Validate("Shipment Date", WorkDate + 60);
        SalesLineOrder.Modify(true);

        // [GIVEN] Go back to the blanket sales order and set "Qty. to Ship" on the first line to 10 in order to create one more sales order.
        LibrarySales.FindFirstSalesLine(SalesLineBlanket, SalesHeaderBlanket);
        UpdateQuantityToShipOnSalesLine(SalesLineBlanket, 10);

        // [GIVEN] Make a second sales order from the blanket order.
        // [GIVEN] Change shipment date on the new sales order line from 01/05/20 on month forward to 01/06/20.
        BlanketSalesOrderToOrder.Run(SalesHeaderBlanket);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesHeaderOrder);
        LibrarySales.FindFirstSalesLine(SalesLineOrder, SalesHeaderOrder);
        SalesLineOrder.Validate("Shipment Date", WorkDate + 60);
        SalesLineOrder.Modify(true);

        // [WHEN] Calculate regenerative plan on the period covering all demands, that is 01/04/20..01/09/20.
        Item.SetRecFilter;
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate, WorkDate + 120);

        // [THEN] A planning line to fulfill the remaining 20 pcs (100 - 70 - 10) on the first blanket order line is created.
        RequisitionLine.SetRange("Due Date", WorkDate + 30);
        FindRequisitionLineForItem(RequisitionLine, Item."No.");
        Assert.AreEqual(20, RequisitionLine.Quantity, '');
    end;

    local procedure Initialize()
    var
        AllProfile: Record "All Profile";
        ReservationEntry: Record "Reservation Entry";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Plan-Req. Wksht");
        ReservationEntry.DeleteAll;
        RequisitionLine.DeleteAll;
        RequisitionWkshName.DeleteAll;
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        LibraryApplicationArea.EnableEssentialSetup;

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Plan-Req. Wksht");

        AllProfile.SetRange("Profile ID", 'ORDER PROCESSOR');
        AllProfile.FindFirst();
        ConfPersonalizationMgt.SetCurrentProfile(AllProfile);

        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.CreateVATData;
        NoSeriesSetup;
        ItemJournalSetup;
        CreateLocationSetup;
        ConsumptionJournalSetup;

        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Plan-Req. Wksht");
    end;

    local procedure InitializeOrderPlanRecalculdationScenario(var Item: Record Item; ReorderingPolicy: Option)
    var
        Qty: Decimal;
    begin
        Initialize;
        Qty := LibraryRandom.RandIntInRange(10, 20);
        CreateItemWithReorderPoint(Item, ReorderingPolicy, Item."Replenishment System"::Purchase, Qty, Qty + 1);
        PostReceiptAndAutoReserveForSale(Item, Qty);
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get;
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesReceivablesSetup.Validate("Blanket Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesReceivablesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        Clear(ItemJournalTemplate);
        ItemJournalTemplate.Init;
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        ItemJournalTemplate.Modify(true);

        Clear(ItemJournalBatch);
        ItemJournalBatch.Init;
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Modify(true);
    end;

    local procedure SetBlankOverflowLevelAsUseItemValues()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        with ManufacturingSetup do begin
            Get;
            Validate("Blank Overflow Level", "Blank Overflow Level"::"Use Item/SKU Values Only");
            Modify(true);
        end;
    end;

    local procedure AutoReserveForSalesLine(SalesLine: Record "Sales Line")
    var
        Reservation: Page Reservation;
    begin
        LibraryVariableStorage.Enqueue(AutoReservNotPossibleMsg);
        Reservation.SetSalesLine(SalesLine);
        Reservation.RunModal;
    end;

    local procedure BindSalesOrderLineToBlanketOrderLine(var SalesLineOrder: Record "Sales Line"; SalesLineBlanketOrder: Record "Sales Line")
    begin
        SalesLineOrder.Validate("Blanket Order No.", SalesLineBlanketOrder."Document No.");
        SalesLineOrder.Validate("Blanket Order Line No.", SalesLineBlanketOrder."Line No.");
        SalesLineOrder.Modify(true);
    end;

    local procedure CalculateOrderPlan(var ReqLine: Record "Requisition Line"; FilterOnDemandType: Option)
    var
        OrderPlanningMgt: Codeunit "Order Planning Mgt.";
    begin
        case FilterOnDemandType of
            DemandType::Production:
                OrderPlanningMgt.SetProdOrder;
            DemandType::Sales:
                OrderPlanningMgt.SetSalesOrder;
            DemandType::Service:
                OrderPlanningMgt.SetServOrder;
            DemandType::Jobs:
                OrderPlanningMgt.SetJobOrder;
            DemandType::Assembly:
                OrderPlanningMgt.SetAsmOrder;
        end;

        OrderPlanningMgt.GetOrdersToPlan(ReqLine);
    end;

    local procedure CarryOutActionPlan(var ReqLine: Record "Requisition Line")
    var
        MfgUserTemplate: Record "Manufacturing User Template";
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
    begin
        MfgUserTemplate.Init;
        MfgUserTemplate.Validate("Create Purchase Order", MfgUserTemplate."Create Purchase Order"::"Make Purch. Orders");

        ReqLine.SetRecFilter;
        CarryOutActionMsgPlan.UseRequestPage(false);
        CarryOutActionMsgPlan.SetDemandOrder(ReqLine, MfgUserTemplate);
        CarryOutActionMsgPlan.RunModal;
    end;

    local procedure CreateLocationSetup()
    begin
        LibraryWarehouse.CreateLocation(LocationYellow);
        LibraryWarehouse.CreateLocation(LocationRed);
        LibraryWarehouse.CreateLocation(LocationInTransit);
        LocationInTransit.Validate("Use As In-Transit", true);
        LocationInTransit.Modify(true);
    end;

    local procedure CreateLocationsChain(var FromLocation: Record Location; var ToLocation: Record Location)
    var
        TransitLocation: Record Location;
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        LibraryInventory.CreateTransferRoute(TransferRoute, FromLocation.Code, ToLocation.Code);
        TransferRoute.Validate("In-Transit Code", TransitLocation.Code);
        TransferRoute.Modify(true);
    end;

    local procedure ConsumptionJournalSetup()
    begin
        Clear(ConsumptionItemJournalTemplate);
        ConsumptionItemJournalTemplate.Init;
        LibraryInventory.SelectItemJournalTemplateName(ConsumptionItemJournalTemplate, ConsumptionItemJournalTemplate.Type::Consumption);

        Clear(ConsumptionItemJournalBatch);
        ConsumptionItemJournalBatch.Init;
        LibraryInventory.SelectItemJournalBatchName(
          ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type, ConsumptionItemJournalTemplate.Name);
    end;

    local procedure CreateItemLocationVendorSetup(var Item: Record Item; var Location: array[2] of Record Location; var Vendor: array[2] of Record Vendor)
    var
        i: Integer;
    begin
        LibraryInventory.CreateItem(Item);
        for i := 1 to 2 do begin
            LibraryWarehouse.CreateLocation(Location[i]);
            LibraryPurchase.CreateVendor(Vendor[i]);
        end;
        UpdateVendorLocationCode(Vendor[2], Location[2].Code);
        UpdateItemVendorNo(Item, Vendor[1]."No.");
    end;

    local procedure CreateItem(var Item: Record Item; ReorderingPolicy: Option; ReplenishmentSystem: Option)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo);
        Item.Modify(true);
    end;

    local procedure CreateSKU(Item: Record Item; LocationCode: Code[10]; RepSystem: Option; ReordPolicy: Option; FromLocation: Code[10]; IncludeInventory: Boolean; ReschedulingPeriod: Text; SafetyLeadTime: Text)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        SKUCreationMethod: Option Location,Variant,"Location & Variant";
    begin
        Item.SetRange("Location Filter", LocationCode);
        LibraryInventory.CreateStockKeepingUnit(Item, SKUCreationMethod::Location, false, false);
        Item.SetRange("Location Filter");
        with StockkeepingUnit do begin
            SetRange("Item No.", Item."No.");
            SetRange("Location Code", LocationCode);
            FindFirst;
            Validate("Replenishment System", RepSystem);
            Evaluate(
              "Lead Time Calculation",
              '<' + Format(LibraryRandom.RandIntInRange(8, 10)) + 'W>');
            Validate("Flushing Method", "Flushing Method"::Backward);
            Validate("Reordering Policy", ReordPolicy);
            Validate("Transfer-from Code", FromLocation);
            Validate("Include Inventory", IncludeInventory);
            Evaluate("Rescheduling Period", ReschedulingPeriod);
            Evaluate("Safety Lead Time", SafetyLeadTime);
            Modify(true);
        end;
    end;

    local procedure CreateSKUForLocationWithReplenishmentSystemAndReorderingPolicy(ItemNo: Code[20]; LocationCode: Code[10]; ReplenishmentSystem: Option; TransferFromCode: Code[10]; ReorderingPolicy: Option; ReorderQuantity: Decimal; SafetyStockQuantity: Decimal)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Validate("Transfer-from Code", TransferFromCode);
        StockkeepingUnit.Validate("Reordering Policy", ReorderingPolicy);
        StockkeepingUnit.Validate("Reorder Quantity", ReorderQuantity);
        StockkeepingUnit.Validate("Safety Stock Quantity", SafetyStockQuantity);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateItemWithReorderPoint(var Item: Record Item; ReorderingPolicy: Option; ReplenishmentSystem: Option; ReorderPoint: Decimal; MaximumInventory: Decimal)
    begin
        CreateItem(Item, ReorderingPolicy, ReplenishmentSystem);
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Modify(true);
    end;

    local procedure CreateItemWithReorderPointAndQuantity(var Item: Record Item; ReorderingPolicy: Option; ReplenishmentSystem: Option; ReorderPoint: Decimal; ReorderQuantity: Decimal)
    begin
        CreateItem(Item, ReorderingPolicy, ReplenishmentSystem);
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Reorder Quantity", ReorderQuantity);
        Item.Modify(true);
    end;

    local procedure CreateLotForLotItem(var Item: Record Item; SafetyStockQuantity: Integer; LotAccumulationPeriod: Text[30])
    var
        LotAccumulationPeriod2: DateFormula;
    begin
        // Create Lot-for-Lot Item.
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase);
        Item.Validate("Safety Stock Quantity", SafetyStockQuantity);
        Evaluate(LotAccumulationPeriod2, LotAccumulationPeriod);
        Item.Validate("Lot Accumulation Period", LotAccumulationPeriod2);
        Item.Validate("Include Inventory", true);
        Item.Modify(true);
    end;

    local procedure CreateFixedReorderQtyItem(var Item: Record Item)
    begin
        // Create Fixed Reorder Quantity Item.
        CreateItem(Item, Item."Reordering Policy"::"Fixed Reorder Qty.", Item."Replenishment System"::Purchase);
        Item.Validate("Safety Stock Quantity", LibraryRandom.RandInt(10));
        Item.Validate("Reorder Point", LibraryRandom.RandInt(10) + 10);  // Reorder Point more than Safety Stock Quantity or Reorder Quantity.
        Item.Validate("Reorder Quantity", LibraryRandom.RandInt(5));
        Item.Modify(true);
    end;

    local procedure CreateItemAndSetFRQ(var Item: Record Item)
    begin
        with Item do begin
            CreateItem(Item, "Reordering Policy"::"Fixed Reorder Qty.", "Replenishment System"::Purchase);
            Validate("Safety Stock Quantity", LibraryRandom.RandInt(30));
            Validate("Reorder Point", LibraryRandom.RandInt(100));
            Validate("Reorder Quantity", LibraryRandom.RandInt(50) + "Reorder Point");
            Modify(true);
        end;
    end;

    local procedure CreateOrderItem(var Item: Record Item; ProductionBOMNo: Code[20]; ReplenishmentSystem: Option)
    begin
        // Create Order Item.
        CreateItem(Item, Item."Reordering Policy"::Order, ReplenishmentSystem);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateManufacturingTreeItem(var TopItem: Record Item; var MiddleItem: Record Item; var BottomItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMHeader2: Record "Production BOM Header";
    begin
        CreateItem(BottomItem, BottomItem."Reordering Policy"::" ", BottomItem."Replenishment System"::Purchase);
        BottomItem.Validate("Manufacturing Policy", MiddleItem."Manufacturing Policy"::"Make-to-Stock");
        BottomItem.Modify(true);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, BottomItem."No.");

        CreateItem(MiddleItem, MiddleItem."Reordering Policy"::Order, MiddleItem."Replenishment System"::"Prod. Order");
        MiddleItem.Validate("Manufacturing Policy", MiddleItem."Manufacturing Policy"::"Make-to-Order");
        MiddleItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        MiddleItem.Modify(true);

        CreateAndCertifyProductionBOM(ProductionBOMHeader2, MiddleItem."No.");
        CreateItem(TopItem, TopItem."Reordering Policy"::"Lot-for-Lot", TopItem."Replenishment System"::"Prod. Order");
        TopItem.Validate("Manufacturing Policy", TopItem."Manufacturing Policy"::"Make-to-Order");
        TopItem.Validate("Production BOM No.", ProductionBOMHeader2."No.");
        TopItem.Modify(true);
    end;

    local procedure CreateItemAndBOMWithComponentItem(var ParentItem: Record Item; var ChildItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItem(ChildItem);
        LibraryInventory.CreateItem(ParentItem);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
    end;

    local procedure CreateProductionForecastSetup(var ProductionForecastEntry: array[3] of Record "Production Forecast Entry"; ItemNo: Code[20]; ForecastDate: Date; MultipleLine: Boolean)
    var
        ProductionForecastName: Record "Production Forecast Name";
    begin
        // Using Random Value and Dates based on WORKDATE.
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        UpdateForecastOnManufacturingSetup(ProductionForecastName.Name);
        CreateAndUpdateProductionForecast(
          ProductionForecastEntry[1], ProductionForecastName.Name, ForecastDate, ItemNo, LibraryRandom.RandDec(10, 2) + 100);  // Large Random Quantity Required.
        if MultipleLine then begin
            CreateAndUpdateProductionForecast(
              ProductionForecastEntry[2], ProductionForecastName.Name, GetRandomDateUsingWorkDate(1), ItemNo,
              LibraryRandom.RandDec(10, 2) + 100);  // Large Random Quantity Required.
            CreateAndUpdateProductionForecast(
              ProductionForecastEntry[3], ProductionForecastName.Name, GetRandomDateUsingWorkDate(2), ItemNo,
              LibraryRandom.RandDec(10, 2) + 100);  // Large Random Quantity Required.
        end;
    end;

    local procedure CreateReleasedProdOrder(ProdItem: Record Item; CompItem: Record Item; Qty: Decimal)
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdOrder: Record "Production Order";
    begin
        LibraryPatterns.MAKEProductionBOM(ProdBOMHeader, ProdItem, CompItem, 1, '');
        LibraryPatterns.MAKEProductionOrder(ProdOrder, ProdOrder.Status::Released, ProdItem, '', '', Qty, WorkDate);
    end;

    local procedure UpdateForecastOnManufacturingSetup(CurrentProductionForecast: Code[10])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get;
        ManufacturingSetup.Validate("Current Production Forecast", CurrentProductionForecast);
        ManufacturingSetup.Modify(true);
    end;

    local procedure CreateAndUpdateProductionForecast(var ProductionForecastEntry: Record "Production Forecast Entry"; Name: Code[10]; Date: Date; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionForecastEntry(ProductionForecastEntry, Name, ItemNo, '', Date, false);
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", Quantity);
        ProductionForecastEntry.Modify(true);
    end;

    local procedure CreateBlanketOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');
        UpdateShipmentDateOnSalesHeader(SalesHeader, ShipmentDate);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateProdBOMLineWithRoutingLink(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; ItemNo: Code[20]; QtyPer: Decimal; RoutingLinkCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, QtyPer);
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
    end;

    local procedure CreateRoutingLineWithRoutingLink(var RoutingHeader: Record "Routing Header"; var RoutingLine: Record "Routing Line"; OperationNo: Code[10]; WorkCenterNo: Code[20]; RunTime: Decimal; RoutingLinkCode: Code[10])
    begin
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Modify(true);
    end;

    local procedure CreateSalesOrderFromBlanketOrder(var SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
    begin
        CreateBlanketOrder(SalesHeader, SalesLine, ItemNo, Quantity, WorkDate);
        BlanketSalesOrderToOrder.Run(SalesHeader);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesOrderHeader);
    end;

    local procedure CreateRequisitionLine(var RequisitionLine: Record "Requisition Line")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst;
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
    end;

    local procedure UpdateInventory(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; PostingDate: Date; Quantity: Decimal)
    begin
        UpdateInventoryOnLocation(ItemJournalLine, ItemNo, '', PostingDate, Quantity);
    end;

    local procedure UpdateInventoryOnLocation(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; PostingDate: Date; Quantity: Decimal)
    begin
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, ItemNo, Quantity);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateSalesOrderFromBlanketOrderWithNewQuantityToShip(var SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date)
    var
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
    begin
        CreateBlanketOrder(SalesHeader, SalesLine, ItemNo, Quantity, ShipmentDate);
        UpdateQuantityToShipOnSalesLine(SalesLine, Quantity - LibraryRandom.RandInt(5));  // Quantity to Ship less than Sales Line Quantity.
        BlanketSalesOrderToOrder.Run(SalesHeader);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesOrderHeader);
    end;

    local procedure CreateSalesOrderTwoLinesWithBlanketOrderNo(var SalesHeader: Record "Sales Header"; DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Integer)
    var
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Create Sales Order with multiple Lines and Update Blanket Order No.
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Quantity);
        UpdateBlanketOrderNoOnSalesLine(SalesLine, DocumentNo);
        LibrarySales.CreateSalesLine(
          SalesLine2, SalesHeader, SalesLine2.Type::Item, ItemNo, SalesLine.Quantity - LibraryRandom.RandInt(5));  // Quantity less than first Sales Line of Sales Order.
        UpdateBlanketOrderNoOnSalesLine(SalesLine2, DocumentNo);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesOrderWithAutoReservation(Item: Record Item; Quantity: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryPatterns.MAKESalesOrder(
          SalesHeader, SalesLine, Item, '', '', Quantity * LibraryRandom.RandDecInDecimalRange(1.5, 2, 2), WorkDate, Item."Unit Cost");
        AutoReserveForSalesLine(SalesLine);
    end;

    local procedure CreateSalesOrderWithPurchasingCode(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; PurchasingCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo, ItemNo, Quantity, LocationCode, WorkDate);
        UpdateSalesLinePurchasingCode(SalesLine, PurchasingCode);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; ExpectedReceiptDate: Date; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::Planning);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure MockRequisitionLine(var ReqLine: Record "Requisition Line"; RoutingHeaderNo: Code[20]; StartingDate: Date; EndingDate: Date)
    begin
        with ReqLine do begin
            "Ref. Order Type" := "Ref. Order Type"::"Prod. Order";
            "Routing No." := RoutingHeaderNo;
            "Starting Date" := StartingDate;
            "Ending Date" := EndingDate;
            Insert;
        end;
    end;

    local procedure CalcPlanAndCarryOutActionMessageWithPlanningFlexibility(var RequisitionWkshName: Record "Requisition Wksh. Name"; var Item: Record Item; PlanningFlexibility: Option; EndingDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate, EndingDate);
        SelectRequisitionLine(RequisitionLine, Item."No.");
        UpdatePlanningFlexiblityOnRequisitionWorksheet(RequisitionLine, Item."No.", PlanningFlexibility);
        AcceptActionMessage(Item."No.");
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate, WorkDate, WorkDate, WorkDate, '');
    end;

    local procedure CalcRegenPlanForPlanWkshPage(var PlanningWorksheet: TestPage "Planning Worksheet"; Name: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        // Regenerative Planning using Page required where Forecast is used.
        LibraryVariableStorage.Enqueue(ItemNo);  // Set Global Value.
        LibraryVariableStorage.Enqueue(ItemNo2);  // Set Global Value.
        Commit;  // Required for Test.
        OpenPlanningWorksheetPage(PlanningWorksheet, Name);
        PlanningWorksheet.CalculateRegenerativePlan.Invoke;  // Open report on Handler CalculatePlanPlanWkshRequestPageHandler.
        PlanningWorksheet.OK.Invoke;
    end;

    local procedure ReqWorksheetCalculatePlan(ItemFilter: Text; LocationFilter: Text; FromDate: Date; ToDate: Date; RespectPlanningParm: Boolean)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        LibraryVariableStorage.Enqueue(FromDate);
        LibraryVariableStorage.Enqueue(ToDate);
        LibraryVariableStorage.Enqueue(ItemFilter);
        LibraryVariableStorage.Enqueue(LocationFilter);
        LibraryVariableStorage.Enqueue(RespectPlanningParm);
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::"Req.");
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        Commit;
        OpenRequisitionWorksheetPage(ReqWorksheet, FindRequisitionWkshName(ReqWkshTemplate.Type::"Req."));
        ReqWorksheet.CalculatePlan.Invoke; // Open report on Handler CalculatePlanReqWkshWithPeriodItemNoLocationParamsRequestPageHandler
        ReqWorksheet.OK.Invoke;
    end;

    local procedure CreateSalesOrderWithMultipleLinesAndRequiredShipment(var SalesLine: Record "Sales Line"; var SalesLine2: Record "Sales Line"; ItemNo: Code[20]; SalesLineQuantity: Integer; SalesLineQuantity2: Integer; ShipmentDate: Date; ShipmentDate2: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, SalesLineQuantity);
        UpdateShipmentDateOnSalesLine(SalesLine, ShipmentDate);
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, ItemNo, SalesLineQuantity2);
        UpdateShipmentDateOnSalesLine(SalesLine2, ShipmentDate2);
    end;

    local procedure CarryOutDemandInRequisitionWorksheet(var Item: Record Item; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        // Create Sales Order.
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandInt(20));

        // Calculate Plan for Requisition Worksheet with the required Start and End dates, Carry out Action Message.
        LibraryVariableStorage.Enqueue(NewWorksheetMessageTxt);  // Required inside MessageHandler.
        CalcPlanAndCarryOutActionMessageWithPlanningFlexibility(
          RequisitionWkshName, Item, RequisitionLine."Planning Flexibility"::Unlimited, CalcDate('<+2M>', WorkDate));
    end;

    local procedure CarryOutDemandAndUpdateSalesShipmentDate(var TopItem: Record Item; var MiddleItem: Record Item; var BottomItem: Record Item; var ShipmentDate: Date; var ShipmentDate2: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize;

        // Setup: Create the manufacturing tree. Create demand. Plan and carry out the Demand.
        CreateManufacturingTreeItem(TopItem, MiddleItem, BottomItem);
        CreateSalesOrder(SalesHeader, SalesLine, TopItem."No.", LibraryRandom.RandInt(20));
        ShipmentDate := SalesLine."Shipment Date";
        CalculateRegenerativePlanAndCarryOut(MiddleItem."No.", TopItem."No.", true); // Default Accept Action Message is False for 2 "New" lines

        // Change shipment date, replan and carry out.
        UpdateShipmentDateOnSalesLine(SalesLine, SalesLine."Shipment Date" + LibraryRandom.RandInt(5));
        ShipmentDate2 := SalesLine."Shipment Date";
    end;

    local procedure RecalculateReqPlanAfterOrderPlan(FilterOnDemandType: Option; var Item: Record Item)
    begin
        CalculateOrderPlanAndCarryOut(FilterOnDemandType, Item."No.");
        CalculateReqWorksheetPlanForItem(Item);
    end;

    local procedure RecalculateReqPlanForIncreasedSalesQty(var Item: Record Item)
    begin
        IncreaseQuantityOnSalesLine(Item."No.");
        CalculateReqWorksheetPlanForItem(Item);
    end;

    local procedure UpdateShipmentDateOnSalesLine(var SalesLine: Record "Sales Line"; ShipmentDate: Date)
    begin
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure SelectTransferRoute(TransferFrom: Code[10]; TransferTo: Code[10])
    var
        TransferRoute: Record "Transfer Route";
    begin
        TransferRoute.SetRange("Transfer-from Code", TransferFrom);
        TransferRoute.SetRange("Transfer-to Code", TransferTo);

        // If Transfer Not Found then Create it.
        if not TransferRoute.FindFirst then
            LibraryWarehouse.CreateTransferRoute(TransferRoute, TransferFrom, TransferTo);
    end;

    local procedure CreateTransferOrderWithTransferRoute(var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; TransferFrom: Code[10]; TransferTo: Code[10]; Quantity: Integer)
    var
        TransferHeader: Record "Transfer Header";
    begin
        SelectTransferRoute(TransferFrom, TransferTo);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, TransferFrom, TransferTo, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
    end;

    local procedure IncreaseQuantityOnSalesLine(ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            SetRange("No.", ItemNo);
            FindFirst;
            Validate(Quantity, Quantity * LibraryRandom.RandDecInRange(2, 10, 2));
            Modify(true);
        end;
    end;

    local procedure PostReceiptAndAutoReserveForSale(Item: Record Item; Quantity: Decimal)
    begin
        PostPurchaseOrderReceipt(Item, Quantity);
        CreateSalesOrderWithAutoReservation(Item, Quantity);
    end;

    local procedure SelectPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst;
    end;

    local procedure FilterOnRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
    end;

    local procedure FilterOnRequisitionLines(var RequisitionLine: Record "Requisition Line"; No: Code[20]; No2: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No, No2);
    end;

    local procedure FilterRequisitionLineByLocationAndPurchaseItem(var RequisitionLine: Record "Requisition Line"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        RequisitionLine.SetRange("Replenishment System", RequisitionLine."Replenishment System"::Purchase);
        RequisitionLine.SetRange("Location Code", LocationCode);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
    end;

    local procedure FindRequisitionLineForItem(var ReqLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        with ReqLine do begin
            FilterOnRequisitionLine(ReqLine, ItemNo);
            FindFirst;
        end;
    end;

    local procedure SelectRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        FilterOnRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.FindSet;
    end;

    local procedure SelectRequisitionLines(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        FilterOnRequisitionLines(RequisitionLine, ItemNo, ItemNo2);
        RequisitionLine.FindSet;
    end;

    local procedure SelectSalesLineFromSalesDocument(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst;
    end;

    local procedure SelectProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Status: Option)
    begin
        ProductionOrder.SetRange("Source No.", ItemNo);
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.FindFirst;
    end;

    local procedure SelectRequisitionTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Type: Option)
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst;
    end;

    local procedure SetSupplyFromVendorOnRequisitionLine(var ReqLine: Record "Requisition Line")
    begin
        with ReqLine do begin
            Validate("Supply From", LibraryPurchase.CreateVendorNo);
            Validate(Reserve, true);
            Modify(true);
        end;
    end;

    local procedure AcceptActionMessage(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        repeat
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next = 0;
    end;

    local procedure AcceptActionMessages(ItemNo: Code[20]; ItemNo2: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLines(RequisitionLine, ItemNo, ItemNo2);

        repeat
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next = 0;
    end;

    local procedure UpdatePlanningFlexiblityOnRequisitionWorksheet(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; PlanningFlexibility: Option)
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        repeat
            RequisitionLine.Validate("Planning Flexibility", PlanningFlexibility);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next = 0;
    end;

    local procedure UpdateLeadTimeCalculationForItem(var Item: Record Item; LeadTimeCalculation: Text[30])
    var
        LeadTimeCalculation2: DateFormula;
    begin
        Evaluate(LeadTimeCalculation2, LeadTimeCalculation);
        Item.Validate("Lead Time Calculation", LeadTimeCalculation2);
        Item.Modify(true);
    end;

    local procedure UpdateQuantityOnSalesLine(var SalesLine: Record "Sales Line"; Quantity: Decimal)
    begin
        SalesLine.Find;
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
    end;

    local procedure UpdateBlanketOrderNoOnSalesLine(var SalesLine: Record "Sales Line"; BlanketOrderNo: Code[20])
    begin
        SalesLine.Validate("Blanket Order No.", BlanketOrderNo);
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(var OldStockoutWarning: Boolean; var OldCreditWarnings: Option; NewStockoutWarning: Boolean; NewCreditWarnings: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        OldStockoutWarning := SalesReceivablesSetup."Stockout Warning";
        OldCreditWarnings := SalesReceivablesSetup."Credit Warnings";
        SalesReceivablesSetup.Validate("Stockout Warning", NewStockoutWarning);
        SalesReceivablesSetup.Validate("Credit Warnings", NewCreditWarnings);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateBlanketOnSalesAndCalcRegenPlan(var SalesLine: Record "Sales Line"; PlanningWorksheet: TestPage "Planning Worksheet"; DocumentNo: Code[20]; RequisitionWkshNameName: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        UpdateBlanketOrderNoOnSalesLine(SalesLine, DocumentNo);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshNameName, ItemNo, ItemNo2);
    end;

    local procedure PostSalesAndCalcRegenPlan(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; PlanningWorksheet: TestPage "Planning Worksheet"; RequisitionWkshNameName: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        SalesLine.ShowReservationEntries(true);  // Cancel Reservation. Handler used -ReservationEntry Handler.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshNameName, ItemNo, ItemNo2);
    end;

    local procedure CalculateReqWorksheetPlanForItem(var Item: Record Item)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        Item.SetRecFilter;
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate, WorkDate);
    end;

    local procedure CalculatePlanForRequisitionWorksheet(var RequisitionWkshName: Record "Requisition Wksh. Name"; Item: Record Item; StartDate: Date; EndDate: Date)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::"Req.");
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, StartDate, EndDate);
    end;

    local procedure CalculateRegenerativePlanForPlanWorksheet(ItemNo: Code[20]; ItemNo2: Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        Clear(RequisitionWkshName);
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, ItemNo, ItemNo2);
    end;

    local procedure CalculateRegenerativePlanAndCarryOut(ItemNo: Code[20]; ItemNo2: Code[20]; CheckAllAcceptActionMessage: Boolean)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        CalculateRegenerativePlanForPlanWorksheet(ItemNo, ItemNo2);

        if CheckAllAcceptActionMessage then
            AcceptActionMessages(ItemNo, ItemNo2);

        SelectRequisitionLines(RequisitionLine, ItemNo, ItemNo2);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CalcRegenPlanAcceptAndCarryOut(ReqWkshName: Code[10]; ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, ReqWkshName, ItemNo, ItemNo);
        AcceptActionMessages(ItemNo, ItemNo);
        SelectRequisitionLines(RequisitionLine, ItemNo, ItemNo);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure GetDropShipmentSalesOrders(RequisitionLine: Record "Requisition Line"; OrderNoFilter: Text)
    var
        SalesLine: Record "Sales Line";
        GetSalesOrders: Report "Get Sales Orders";
    begin
        SalesLine.SetFilter("Document No.", OrderNoFilter);
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 0);
        GetSalesOrders.SetTableView(SalesLine);
        GetSalesOrders.InitializeRequest(0);
        GetSalesOrders.UseRequestPage(false);
        GetSalesOrders.Run;
    end;

    local procedure FindRequisitionWkshName(ReqWkshTemplateType: Option): Code[10]
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplateType);
        with RequisitionWkshName do begin
            SetRange("Worksheet Template Name", ReqWkshTemplate.Name);
            FindFirst;
            exit(Name);
        end;
    end;

    local procedure CalculateOrderPlanAndCarryOut(FilterOnDemandType: Option; ItemNo: Code[20])
    var
        ReqLine: Record "Requisition Line";
    begin
        CalculateOrderPlan(ReqLine, FilterOnDemandType);
        FindRequisitionLineForItem(ReqLine, ItemNo);
        SetSupplyFromVendorOnRequisitionLine(ReqLine);
        CarryOutActionPlan(ReqLine);
    end;

    local procedure GetRequiredDate(Days: Integer; IncludeAdditionalPeriod: Integer; RelativeDate: Date; SignFactor: Integer) NewDate: Date
    begin
        // Calculating a New Date relative to WorkDate or Lot Accumulation period dates.
        NewDate :=
          CalcDate('<' + Format(SignFactor * LibraryRandom.RandInt(Days) + IncludeAdditionalPeriod) + 'D>', RelativeDate);
    end;

    local procedure GetLotAccumulationPeriod(Days: Integer; IncludeAdditionalPeriod: Integer): Text[30]
    begin
        exit('<' + Format(LibraryRandom.RandInt(Days) + IncludeAdditionalPeriod) + 'W>');
    end;

    local procedure GetRandomDateUsingWorkDate(Month: Integer) NewDate: Date
    begin
        // Calculating a New Date relative to work date for different supply and demands.
        NewDate := CalcDate('<' + Format(Month) + 'M>', WorkDate);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Status: Option; Quantity: Decimal; NewDueDate: Boolean; DueDate: Date)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        if NewDueDate then begin
            ProductionOrder.Validate("Due Date", DueDate);
            ProductionOrder.Modify(true);
        end;
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateReleasedProductionOrderAtLocationWithDueDateAndRefresh(ItemNo: Code[20]; Quantity: Decimal; DueDate: Date; LocationCode: Code[10])
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure UpdateShipmentDateOnSalesHeader(var SalesHeader: Record "Sales Header"; ShipmentDate: Date)
    begin
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateQuantityToShipOnSalesLine(var SalesLine: Record "Sales Line"; QtytoShip: Decimal)
    begin
        SalesLine.Validate("Qty. to Ship", QtytoShip);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQuantityOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Integer)
    begin
        SelectPurchaseLine(PurchaseLine, ItemNo);
        PurchaseLine.Validate(Quantity, Quantity);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePromisedReceiptDateOnPurchaseHeader(PurchaseHeaderNo: Code[20]; PromisedReceiptDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        with PurchaseHeader do begin
            Get("Document Type"::Order, PurchaseHeaderNo);
            Validate("Promised Receipt Date", PromisedReceiptDate);
            Modify(true);
        end;
    end;

    local procedure UpdateProductionForecastType(var ProductionForecastEntry: array[3] of Record "Production Forecast Entry"; ComponentForecast: Boolean)
    begin
        // Update Forecast Type on first available Forecast Entry.
        ProductionForecastEntry[1].Validate("Component Forecast", ComponentForecast);
        ProductionForecastEntry[1].Modify(true);
    end;

    local procedure UpdateProductionForecastQuantity(var ProductionForecastEntry: array[3] of Record "Production Forecast Entry"; ForecastQuantity: Decimal)
    begin
        // Update Forecast Quantity on first available Forecast Entry.
        ProductionForecastEntry[1].Validate("Forecast Quantity", ForecastQuantity);
        ProductionForecastEntry[1].Modify(true);
    end;

    local procedure UpdateManufacturingSetup(NewCombinedMPSMRPCalculation: Boolean) OldCombinedMPSMRPCalculation: Boolean
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get;
        OldCombinedMPSMRPCalculation := ManufacturingSetup."Combined MPS/MRP Calculation";
        ManufacturingSetup.Validate("Combined MPS/MRP Calculation", NewCombinedMPSMRPCalculation);
        ManufacturingSetup.Modify(true);
    end;

    local procedure CreateAndPostConsumptionJournal(ProductionOrderNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure UpdateProductionBOMNoOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateAndUpdateProductionForecastSetup(var ProductionForecastEntry: array[3] of Record "Production Forecast Entry"; ItemNo: Code[20]; ForecastDate: Date; ForecastQuantity: Decimal; MultipleLine: Boolean)
    begin
        CreateProductionForecastSetup(ProductionForecastEntry, ItemNo, ForecastDate, MultipleLine);
        UpdateProductionForecastQuantity(ProductionForecastEntry, ForecastQuantity);
    end;

    local procedure UpdatePlannedDeliveryDateOnSalesLine(var SalesLine: Record "Sales Line"; PlannedDeliveryDate: Date)
    begin
        SalesLine.Validate("Planned Delivery Date", PlannedDeliveryDate);
        SalesLine.Modify(true);
    end;

    local procedure UpdateVendorLocationCode(var Vendor: Record Vendor; LocationCode: Code[10])
    begin
        Vendor.Validate("Location Code", LocationCode);
        Vendor.Modify(true);
    end;

    local procedure UpdateItemVendorNo(var Item: Record Item; VendorNo: Code[20])
    begin
        Item.Validate("Vendor No.", VendorNo);
        Item.Modify(true);
    end;

    local procedure UpdateSalesLinePurchasingCode(var SalesLine: Record "Sales Line"; PurchasingCode: Code[10])
    begin
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateRequisitionLineVendorNo(var RequisitionLine: Record "Requisition Line"; VendorNo: Code[20])
    begin
        RequisitionLine.SetCurrFieldNo(RequisitionLine.FieldNo("Vendor No."));
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Modify(true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; EntryType: Option; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    local procedure VerifyPlanningDueDateTime(RoutingLinkCode: Code[10])
    var
        PlanningRoutingLine: Record "Planning Routing Line";
        PlanningComponent: Record "Planning Component";
    begin
        PlanningRoutingLine.SetRange("Routing Link Code", RoutingLinkCode);
        PlanningRoutingLine.FindFirst;

        PlanningComponent.SetRange("Routing Link Code", RoutingLinkCode);
        PlanningComponent.FindFirst;

        PlanningComponent.TestField("Due Date", PlanningRoutingLine."Starting Date");
        PlanningComponent.TestField("Due Time", PlanningRoutingLine."Starting Time");
    end;

    local procedure OpenPlanningWorksheetPage(var PlanningWorksheet: TestPage "Planning Worksheet"; Name: Code[10])
    begin
        PlanningWorksheet.OpenEdit;
        PlanningWorksheet.CurrentWkshBatchName.SetValue(Name);
    end;

    local procedure OpenRequisitionWorksheetPage(var ReqWorksheet: TestPage "Req. Worksheet"; Name: Code[10])
    begin
        ReqWorksheet.OpenEdit;
        ReqWorksheet.CurrentJnlBatchName.SetValue(Name);
    end;

    local procedure PostPurchaseOrderReceipt(Item: Record Item; Quantity: Integer)
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure VerifyRequisitionLineQuantity(var RequisitionLine: Record "Requisition Line"; Quantity: Decimal; OriginalQuantity: Decimal; RefOrderType: Option)
    begin
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Original Quantity", OriginalQuantity);
        RequisitionLine.TestField("Ref. Order Type", RefOrderType);
        RequisitionLine.Next;
    end;

    local procedure VerifyQtyInTwoRequisitionLines(var RequisitionLine: Record "Requisition Line"; Item: Record Item)
    begin
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLineQuantity(RequisitionLine, Item."Reorder Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        VerifyRequisitionLineQuantity(RequisitionLine, Item."Safety Stock Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    local procedure VerifyPlannedDeliveryDate(No: Code[20]; DueDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FilterOnRequisitionLine(RequisitionLine, No);
        RequisitionLine.FindFirst;
        RequisitionLine.TestField("Due Date", DueDate);
    end;

    local procedure VerifyReservationEntryOfReservationExist(ItemNo: Code[20]; Exist: Boolean; RowsNumber: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);

        ReservationEntry.SetRange("Source Type", DATABASE::"Prod. Order Component");
        Assert.AreEqual(Exist, ReservationEntry.FindFirst, ReservationEntryErr);
        Assert.AreEqual(RowsNumber, ReservationEntry.Count, NumberOfRowsErr);

        ReservationEntry.SetRange("Source Type", DATABASE::"Prod. Order Line");
        Assert.AreEqual(Exist, ReservationEntry.FindFirst, ReservationEntryErr);
        Assert.AreEqual(RowsNumber, ReservationEntry.Count, NumberOfRowsErr);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; ReservationEntryExist: Boolean; ExpectedReceiptDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);

        if ReservationEntryExist then begin
            ReservationEntry.FindFirst;
            ReservationEntry.TestField("Expected Receipt Date", ExpectedReceiptDate);
        end else
            asserterror ReservationEntry.FindFirst;
    end;

    local procedure VerifyReservationEntryOfTrackingExist(ItemNo: Code[20]; ShipmentDate: Date; ShipmentDateExist: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Tracking);

        ReservationEntry.SetRange("Shipment Date", ShipmentDate);
        Assert.AreEqual(ShipmentDateExist, ReservationEntry.FindFirst, ReservationEntryErr);
    end;

    local procedure VerifyReservedQuantity(ItemNo: Code[20]; ReservStatus: Option; ExpectedQty: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        with ReservEntry do begin
            SetRange("Item No.", ItemNo);
            SetRange(Positive, true);
            SetRange("Reservation Status", ReservStatus);
            CalcSums("Quantity (Base)");
            Assert.AreEqual(ExpectedQty, "Quantity (Base)", ReservationEntryErr);
        end;
    end;

    local procedure VerifyFirmPlannedProdOrderExist(ItemNo: Code[20]; DueDate: Date; DueDateExist: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::"Firm Planned");

        ProdOrderLine.SetRange("Due Date", DueDate);
        Assert.AreEqual(DueDateExist, ProdOrderLine.FindFirst, StrSubstNo(FirmPlannedProdOrderErr, DueDate));
    end;

    local procedure VerifySurplusReservationEntry(ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        with ReservationEntry do begin
            SetRange("Item No.", ItemNo);
            SetRange("Reservation Status", "Reservation Status"::Surplus);
            FindFirst;
            TestField(Quantity, ExpectedQuantity);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanPlanWkshRequestPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    var
        ItemNo: Variant;
        ItemNo2: Variant;
    begin
        // Calculate Regenerative Plan using page. Required where Forecast is used.
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(ItemNo2);
        CalculatePlanPlanWksh.Item.SetFilter("No.", StrSubstNo('%1|%2', ItemNo, ItemNo2));
        CalculatePlanPlanWksh.StartingDate.SetValue(WorkDate);
        CalculatePlanPlanWksh.EndingDate.SetValue(GetRandomDateUsingWorkDate(90));
        CalculatePlanPlanWksh.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanReqWkshRequestPageHandler(var CalculatePlanReqWksh: TestRequestPage "Calculate Plan - Req. Wksh.")
    begin
        CalculatePlanReqWksh.StartingDate.SetValue(LibraryVariableStorage.DequeueDate);
        CalculatePlanReqWksh.EndingDate.SetValue(LibraryVariableStorage.DequeueDate);
        CalculatePlanReqWksh.Item.SetFilter("No.", LibraryVariableStorage.DequeueText);
        CalculatePlanReqWksh.Item.SetFilter("Location Filter", LibraryVariableStorage.DequeueText);
        CalculatePlanReqWksh.RespectPlanningParm.SetValue(LibraryVariableStorage.DequeueBoolean);
        CalculatePlanReqWksh.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationEntryPageHandler(var ReservationEntries: TestPage "Reservation Entries")
    begin
        LibraryVariableStorage.Enqueue(CancelReservationConfirmationMessageTxt);  // Required inside ConfirmHandler.
        ReservationEntries.CancelReservation.Invoke;
        ReservationEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(AreSameMessages(ConfirmMessage, ExpectedMessage), ConfirmMessage);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        QueuedMsg: Variant;
    begin
        LibraryVariableStorage.Dequeue(QueuedMsg);
        Assert.IsTrue(AreSameMessages(Message, QueuedMsg), Message);
    end;
}

