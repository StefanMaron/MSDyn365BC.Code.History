﻿codeunit 137067 "SCM Plan-Req. Wksht"
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
        LibraryERM: Codeunit "Library - ERM";
        AvailabilityMgt: Codeunit AvailabilityManagement;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        DemandType: Option " ",Production,Sales,Service,Jobs,Assembly;
        isInitialized: Boolean;
        RequisitionLineMustNotExistTxt: Label 'Requisition Line must not exist for Item %1.', Comment = '%1 = Item No.';
        ShipmentDateMessageTxt: Label 'Shipment Date';
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
        QtyRoundingErr: Label 'is of lesser precision than expected';
        QuantityImbalanceErr: Label '%1 on %2-%3 causes the %4 and %5 to be out of balance. Rounding of the field %5 results to 0.';
        InvalidReplenishmentOptionErr: Label 'Replenishment System must be equal to';
        WrongPrecisionItemAndUOMExpectedQtyErr: Label 'The value in the Rounding Precision field on the Item page, and Qty. Rounding Precision field on the Item Unit of Measure page, are causing the rounding precision for the Expected Quantity field to be incorrect.';
        BlockedErr: Label 'You cannot choose %1 %2 because the %3 check box is selected on its %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Item No./Variant Code, %3 - Field Caption';
        ItemVariantPrimaryKeyLbl: Label '%1, %2', Comment = '%1 - Item No., %2 - Variant Code', Locked = true;

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
        Initialize();
        CreateLotForLotItem(Item, LibraryRandom.RandInt(50), GetLotAccumulationPeriod(2, 5));  // Lot Accumulation Period based on Random Quantity.
        ShipmentDate := GetRequiredDate(2, 0, WorkDate(), -1);  // Shipment Date relative to Work Date.
        PlanningEndDate := GetRequiredDate(2, 0, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate()), -1);  // Planning End Date relative to Lot Accumulation period.
        ReqWkshErrorAfterCarryOutActionMsgWithSalesOrdersLFLItem(Item, ShipmentDate, PlanningEndDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWkshErrorAfterCarryOutForSalesShipmentInLotAccumPeriodLFLItem()
    var
        Item: Record Item;
        ShipmentDate: Date;
        PlanningEndDate: Date;
    begin
        // Setup: Create LFL Item. Shipment Date within Lot Accumulation Period. Parameters: Shipment Date and Planning End Dates.
        Initialize();
        CreateLotForLotItem(Item, LibraryRandom.RandInt(50), GetLotAccumulationPeriod(2, 5));  // Lot Accumulation Period based on Random Quantity.
        ShipmentDate := GetRequiredDate(20, 0, WorkDate(), 1);  // Shipment Date relative to Work Date.
        PlanningEndDate := GetRequiredDate(10, 0, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate()), -1);  // Planning End Date relative to Lot Accumulation period.
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
        Initialize();
        CreateLotForLotItem(Item, LibraryRandom.RandInt(50), GetLotAccumulationPeriod(2, 5));  // Lot Accumulation Period based on Random Quantity.
        ShipmentDate := GetRequiredDate(20, 0, WorkDate(), -1);  // Shipment Date relative to Work Date.
        PlanningEndDate := GetRequiredDate(10, 0, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate()), 1);  // Planning End Date relative to Lot Accumulation period.
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
        if ShipmentDate < WorkDate() then
            LibraryVariableStorage.Enqueue(ShipmentDateMessageTxt);  // Required inside MessageHandler.
        UpdateShipmentDateOnSalesLine(SalesLine, ShipmentDate);  // Shipment Date value important for Test.

        // Calculate Plan for Requisition Worksheet with the required Start and End dates, Carry out Action Message.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), EndingDate);
        AcceptActionMessage(Item."No.");
        SelectRequisitionLine(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // Exercise: Calculate Plan for Requisition Worksheet again after Carry Out Action Message.
        RequisitionWkshName.FindFirst();
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, WorkDate(), EndingDate);

        // Verify: Verify that no Requisition line is created for Requisition Worksheet.
        FilterOnRequisitionLine(RequisitionLine, Item."No.");
        Assert.IsTrue(RequisitionLine.IsEmpty, StrSubstNo(RequisitionLineMustNotExistTxt, Item."No."));
    end;

    [Test]
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
        Initialize();
        CreateLotForLotItem(Item, LibraryRandom.RandInt(50), GetLotAccumulationPeriod(2, 5));  // Lot Accumulation Period based on Random Quantity.
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate(), Item."Safety Stock Quantity" - LibraryRandom.RandInt(5));  // Inventory Value required for Test.

        // Create Sales Order with multiple Lines having different Shipment Dates. Second Shipment Date is greater than first but difference less than Lot Accumulation Period.
        Quantity := LibraryRandom.RandInt(10) + 10;  // Random Quantity.
        ShipmentDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Shipment Date relative to Work Date.
        ShipmentDate2 := GetRequiredDate(5, 0, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate()), -1);  // Shipment Date relative to Lot Accumulation period.
        CreateSalesOrderWithMultipleLinesAndRequiredShipment(
          SalesLine, SalesLine2, Item."No.", Quantity - LibraryRandom.RandInt(5), Quantity - SalesLine.Quantity, ShipmentDate,
          ShipmentDate2);

        // Calculate Plan for Requisition Worksheet having End Date which excludes Shipment Date of Second Sales Line, with Planning Flexibility - Unlimited and Carry out Action Message.
        PlanningEndDate := GetRequiredDate(10, 5, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate()), -1);  // Planning End Date relative to Lot Accumulation period.
        CalcPlanAndCarryOutActionMessageWithPlanningFlexibility(
          RequisitionWkshName, Item, RequisitionLine."Planning Flexibility"::Unlimited, PlanningEndDate);

        // Exercise: Calculate Plan for Requisition Worksheet again after Carry Out Action Message, Shipment Dates are included in Start and End Date.
        RequisitionWkshName.FindFirst();
        PlanningEndDate2 := GetRequiredDate(10, 5, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate()), 1);  // Planning End Date relative to Lot Accumulation period.
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, WorkDate(), PlanningEndDate2);

        // Verify: Verify Requisition Line values.
        Item.CalcFields(Inventory);
        SelectPurchaseLine(PurchaseLine, Item."No.");
        SelectRequisitionLine(RequisitionLine, Item."No.");
        ReqLineQuantity := SalesLine.Quantity + SalesLine2.Quantity + Item."Safety Stock Quantity" - Item.Inventory;
        VerifyRequisitionLineQuantity(RequisitionLine, ReqLineQuantity, PurchaseLine.Quantity, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
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
        Initialize();
        CreateLotForLotItem(Item, LibraryRandom.RandInt(50), GetLotAccumulationPeriod(2, 5));  // Lot Accumulation Period based on Random Quantity.
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate(), Item."Safety Stock Quantity" - LibraryRandom.RandInt(5));  // Inventory Value required for Test.

        // Create Sales Order with multiple Lines have different Shipment Dates. Second Shipment Date is greater than first but difference less than Lot Accumulation Period.
        Quantity := LibraryRandom.RandInt(10) + 10;  // Random Quantity.
        ShipmentDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Shipment Date relative to Work Date.
        ShipmentDate2 := GetRequiredDate(5, 0, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate()), -1);  // Shipment Date relative to Lot Accumulation period.
        CreateSalesOrderWithMultipleLinesAndRequiredShipment(
          SalesLine, SalesLine2, Item."No.", Quantity - LibraryRandom.RandInt(5), Quantity - SalesLine.Quantity, ShipmentDate,
          ShipmentDate2);

        // Calculate Plan for Requisition Worksheet having End Date which excludes Shipment Date of Second Sales Line, Update Planning Flexibility - None and Carry out Action Message.
        PlanningEndDate := GetRequiredDate(10, 5, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate()), -1);  // Planning End Date relative to Lot Accumulation period.
        CalcPlanAndCarryOutActionMessageWithPlanningFlexibility(
          RequisitionWkshName, Item, RequisitionLine."Planning Flexibility"::None, PlanningEndDate);

        // Exercise: Calculate Plan for Requisition Worksheet again after Carry Out Action Message, Shipment Dates are included in Start and End Date.
        RequisitionWkshName.FindFirst();
        PlanningEndDate2 := GetRequiredDate(10, 5, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate()), 1);  // Planning End Date relative to Lot Accumulation period.
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, WorkDate(), PlanningEndDate2);

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
        Initialize();
        CreateFixedReorderQtyItem(Item, 3, 12, 5);
        Quantity := 12;
        UpdateLeadTimeCalculationForItem(Item, '<12D>');
        PostingDate := GetRequiredDate(10, 10, WorkDate(), -1);
        UpdateInventory(ItemJournalLine, Item."No.", PostingDate, Quantity);

        // Create Purchase Order.
        ExpectedReceiptDate := WorkDate() + 13;
        CreatePurchaseOrder(PurchaseHeader, Item."No.", ExpectedReceiptDate, 7);  // Expected Receipt date, Quantity required.

        // Create Sales Order multiple lines.
        ShipmentDate := WorkDate() + 24;  // Shipment Date relative to Work Date.
        ShipmentDate2 := WorkDate() + 39;  // Shipment Date relative to Work Date.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", ItemJournalLine.Quantity);  // Item Journal Line Quantity value required.
        UpdateShipmentDateOnSalesLine(SalesLine, ShipmentDate);
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine2, SalesHeader, SalesLine2.Type::Item, Item."No.", ShipmentDate2, 16);

        // Exercise: Calculate Plan on Requisition Worksheet.
        StartDate := ShipmentDate - 1;  // Start Date Less than Shipment Date of first Sales Line.
        EndDate := ShipmentDate2 + 1;  // End Date greater than Shipment Date of second Sales Line.
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
        Initialize();
        LotAccumulationPeriod := '<1D>';
        SalesShipmentDate := GetRequiredDate(20, 10, WorkDate(), 1);  // Shipment Date relative to Work Date.
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
        Initialize();
        LotAccumulationPeriod := '<1D>';
        SalesShipmentDate := WorkDate();
        SalesShipmentDate2 := GetRequiredDate(20, 10, WorkDate(), 1);  // Shipment Date relative to Work Date.
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
        Initialize();
        LotAccumulationPeriod := '<0D>';
        SalesShipmentDate := WorkDate();
        SalesShipmentDate2 := GetRequiredDate(20, 10, WorkDate(), 1);  // Shipment Date relative to Work Date.
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
        PlanningEndDate := GetRequiredDate(10, 30, CalcDate('<+' + Format(Item."Lot Accumulation Period"), WorkDate()), 1);
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), PlanningEndDate);

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
        Initialize();
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        Quantity := LibraryRandom.RandInt(10);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);

        // Exercise: Calculate Plan for Requisition Worksheet having Start Date less than Work Date.
        StartDate := GetRequiredDate(20, 0, WorkDate(), -1);
        EndDate := GetRequiredDate(20, 0, WorkDate(), 1);
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
        Initialize();
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
        Initialize();
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
        StartDate: Date;
        EndDate: Date;
        Quantity: Integer;
    begin
        // Create Lot for Lot Item. Create Sales order. Create Production Order from Sales Order.
        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock -0.
        Quantity := LibraryRandom.RandInt(10) + 20;  // Large Random Quantity.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);
        LibraryVariableStorage.Enqueue(ReleasedProductionOrderCreatedTxt);  // Required inside MessageHandler.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, ProductionOrder.Status::Released, "Create Production Order Type"::ItemOrder);

        // Open Production Journal and Post. Handler used -ProductionJournalHandler.
        SelectProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released);
        LibraryManufacturing.OutputJournalExplodeRouting(ProductionOrder);
        LibraryManufacturing.PostOutputJournal();

        // Change Status of Production Order from released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        UpdateQuantityOnSalesLine(SalesLine, Quantity - LibraryRandom.RandInt(10));

        // Create new sales Order.
        CreateSalesOrder(SalesHeader2, SalesLine2, Item."No.", SalesLine.Quantity - LibraryRandom.RandInt(5));

        // Exercise: Calculate Plan for Planning Worksheet.
        StartDate := GetRequiredDate(10, 0, WorkDate(), -1);
        EndDate := GetRequiredDate(5, 10, WorkDate(), 1);
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
        Initialize();
        PlanningForSalesOrderFromBlanketOrderUsingForecastOrderItem(false);  // Post Sales Order -False.
    end;

    [Test]
    [HandlerFunctions('ReservationEntryPageHandler,ConfirmHandler,CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanTwiceForSalesOrderFromBlanketOrderWithSalesShipUsingForecastOrderItem()
    begin
        // Setup.
        Initialize();
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
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", WorkDate(), true);
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
        Initialize();
        PlanningForBlanketOrderUpdatedOnSalesOrderUsingForecastOrderItem(false);  // Post Sales Order and Calculate Plan -False.
    end;

    [Test]
    [HandlerFunctions('ReservationEntryPageHandler,ConfirmHandler,CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanTwiceForBlanketOrderUpdatedOnSalesOrderWithSalesShipUsingForecastOrderItem()
    begin
        // Setup.
        Initialize();
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
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", WorkDate(), true);
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Quantity.
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, WorkDate());
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
        Initialize();
        PlanningForBlanketOrderSalesOrderForSameItemUsingForecastOrderItem(false);  // Update Blanket Order on Sales Order -False, Post Sales Order -False.
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanTwiceForBlanketOrderSalesOrderForSameItemUpdateBlanketOnSalesUsingForecastOrderItem()
    begin
        // Setup.
        Initialize();
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
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", WorkDate(), true);
        Quantity := LibraryRandom.RandInt(10) + 5;  // Random Quantity.
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, WorkDate());
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
        Initialize();
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", WorkDate(), true);
        Quantity := LibraryRandom.RandInt(10) + 5;  // Random Quantity.
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, WorkDate());
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
        Initialize();
        PlanningForBlanketOrderSalesOrderForItemAndChildItemUsingForecastOrderItem(false);  // Post Sales Order and Calculate Plan -False.
    end;

    [Test]
    [HandlerFunctions('ReservationEntryPageHandler,ConfirmHandler,CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanTwiceForBlanketOrderSalesOrderForItemAndChildItemWithSalesShipUsingForecastOrderItem()
    begin
        // Setup.
        Initialize();
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
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", WorkDate(), true);
        CreateProductionForecastSetup(ProductionForecastEntry2, ChildItem."No.", WorkDate(), true);

        // Create Blanket Order with multiple Lines of Parent and Child Item.
        Quantity := LibraryRandom.RandInt(10) + 5;  // Random Quantity.
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, WorkDate());
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
        Initialize();

        // [GIVEN] Create Item with Fixed Reorder Quantity, "Reorder Quantity" more than "Reorder Point".
        CreateItemAndSetFRQ(Item);

        // [WHEN] Calculate a regenerative Plan in Planning Worksheet without demands.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), WorkDate());

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
        Initialize();

        // [GIVEN] Set "Blank Overflow Level" in "Manufacturing Setup" as "Use Item/SKU Values Only".
        SetBlankOverflowLevelAsUseItemValues();
        // [GIVEN] Create Item with Fixed Reorder Quantity, "Reorder Quantity" more than "Reorder Point".
        CreateItemAndSetFRQ(Item);

        // [WHEN] Calculate a regenerative Plan in Planning Worksheet without demands.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), WorkDate());

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
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase);
        Quantity := LibraryRandom.RandInt(10) + 10;  // Random Quantity.

        // Create Transfer Order.
        CreateTransferOrderWithTransferRoute(TransferLine, Item."No.", LocationYellow.Code, LocationRed.Code, Quantity);

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        EndDate := GetRequiredDate(10, 20, WorkDate(), 1);  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);

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
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase);
        CreateItem(Item2, Item2."Reordering Policy"::"Lot-for-Lot", Item2."Replenishment System"::Purchase);
        Quantity := LibraryRandom.RandInt(10) + 10;  // Random Quantity.
        ExpectedReceiptDate := GetRequiredDate(10, 10, WorkDate(), 1);  // Expected Receipt Date relative to Workdate.

        // Create Purchase Order and Transfer Order for different Items.
        CreatePurchaseOrder(PurchaseHeader, Item."No.", ExpectedReceiptDate, Quantity);  // Expected Receipt date, Quantity required.
        CreateTransferOrderWithTransferRoute(
          TransferLine, Item2."No.", LocationYellow.Code, LocationRed.Code, Quantity - LibraryRandom.RandInt(5));

        // Calculate Regenerative Plan for Planning Worksheet. Modify supply for one Item.
        EndDate := GetRequiredDate(10, 20, WorkDate(), 1);  // End Date relative to Workdate.
        Item.SetFilter("No.", '%1|%2', Item."No.", Item2."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);
        UpdateQuantityOnPurchaseLine(PurchaseLine, Item."No.", Quantity - LibraryRandom.RandInt(5));

        // Exercise: Calculate Net Change Plan after change in supply pattern.
        Item.SetFilter("No.", '%1|%2', Item."No.", Item2."No.");
        LibraryPlanning.CalcNetChangePlanForPlanWksh(Item, WorkDate(), EndDate, false);

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
        Initialize();
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
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);

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
        Initialize();
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, false, SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateOrderItem(Item, '', Item."Replenishment System"::"Prod. Order");
        ForecastDate := GetRequiredDate(30, 20, WorkDate(), 1);  // Forecast Date Relative to Workdate.
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
        Initialize();
        CreateOrderItem(Item, '', Item."Replenishment System"::"Prod. Order");
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Quantity.

        // Create Blanket Order.
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, WorkDate());

        // Create Sales Order. Update Quantity and Blanket Order No.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader2, SalesLine2.Type::Item, Item."No.", Quantity - LibraryRandom.RandInt(5));
        BindSalesOrderLineToBlanketOrderLine(SalesLine2, SalesLine);

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        EndDate := GetRequiredDate(10, 20, SalesHeader."Shipment Date", 1);  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);

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
        Initialize();
        CreateOrderItem(Item, '', Item."Replenishment System"::"Prod. Order");
        ForecastDate := GetRequiredDate(30, 20, WorkDate(), 1);  // Forecast Date Relative to Workdate.
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
        Initialize();
        CreateOrderItem(Item, '', Item."Replenishment System"::"Prod. Order");
        ForecastDate := CalcDate('<1M>', WorkDate());
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, false);  // Boolean - False, for Single Forecast Entry.

        // Create Blanket Order.
        Quantity := 12;
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, WorkDate());

        // Create Sales Order with multiple lines and update Quantity and Blanket Order No.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader2, SalesLine2.Type::Item, Item."No.", 8);
        BindSalesOrderLineToBlanketOrderLine(SalesLine2, SalesLine);
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader2, SalesLine2.Type::Item, Item."No.", 3);
        BindSalesOrderLineToBlanketOrderLine(SalesLine2, SalesLine);

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Requisition Lines for Quantity.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        SelectSalesLineFromSalesDocument(SalesLine2, SalesHeader2."No.");
        SalesLineQuantity := SalesLine2.Quantity;  // Select Quantity from first Sales Line.
        VerifyRequisitionLineQuantity(RequisitionLine, SalesLineQuantity, 0, RequisitionLine."Ref. Order Type"::"Prod. Order");
        SalesLine2.Next();  // Move to second Sales Line.
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
        Initialize();
        CreateOrderItem(Item, '', Item."Replenishment System"::"Prod. Order");
        ForecastDate := GetRequiredDate(20, 20, WorkDate(), 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, false);  // Boolean - False, for Single Forecast Entry.

        // Create Blanket Order.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Quantity.
        CreateBlanketOrder(SalesHeader, SalesLine, Item."No.", Quantity, WorkDate());

        // Create Sales Order with multiple lines and update Quantity and Blanket Order No.
        CreateSalesOrderTwoLinesWithBlanketOrderNo(
          SalesHeader2, SalesHeader."No.", Item."No.", Quantity - LibraryRandom.RandInt(5));  // Quantity less then Quantity of Blanket Order.
        SelectSalesLineFromSalesDocument(SalesLine2, SalesHeader2."No.");

        // Calculate regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");
        SalesLine2.ShowReservationEntries(true);  // Cancel Reservation for first Sales Line. Handler used - ReservationEntry Handler.
        SalesLine2.Next();  // Move to second Sales Line.

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
        Initialize();
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        CreateOrderItem(Item2, '', Item2."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
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
        Initialize();
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        CreateOrderItem(Item2, '', Item2."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
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
        Initialize();
        PlanningForSalesOrderUsingForecastOrderItem(false);  // Post Sales Order and Calculate Plan - False.
    end;

    [Test]
    [HandlerFunctions('ReservationEntryPageHandler,ConfirmHandler,CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanTwiceForSalesOrderWithSalesShipUsingForecastOrderItem()
    begin
        // Setup.
        Initialize();
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
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
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
        Initialize();
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        CreateOrderItem(Item2, '', Item."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
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
        Initialize();
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.

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
        Initialize();
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        CreateOrderItem(Item2, '', Item2."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.

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
        Initialize();
        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0.
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
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
        Initialize();
        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0.
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.

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
        Initialize();
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entries.
        Quantity := LibraryRandom.RandInt(10) + 10;  // Random Integer Quantity Required.

        // Create and Post Item Journal Line.
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate(), Quantity);  // Inventory Value required for Test.

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
        Initialize();
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entries.
        Quantity := LibraryRandom.RandInt(10) + 10;  // Random Integer Quantity Required.

        // Create and Post Item Journal Line.
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate(), Quantity);  // Inventory Value required for Test.

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
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation of Manufacturing Setup -FALSE.
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
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
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation of Manufacturing Setup -FALSE.
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
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
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation of Manufacturing Setup -FALSE.
        CreateOrderItem(Item, '', Item."Replenishment System"::Purchase);

        // Create Sales Order. Update Shipment Date.
        Quantity := LibraryRandom.RandInt(10);  // Random Integer Quantity Required.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);
        EndDate := GetRequiredDate(20, 0, SalesLine."Shipment Date", 1);  // End Date related to Sales Line Shipment Date.

        // Exercise: Calculate regenerative Plan with MPS - TRUE and MRP - FALSE for Planning Worksheet.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);

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
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation of Manufacturing Setup -FALSE.
        CreateLotForLotItem(ChildItem, 0, '<0D>');  // Safety Stock - 0. Child Item.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");

        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0. Parent Item.
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");

        // Create Production Forecast with single Entry.
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, ChildItem."No.", ForecastDate, false);

        // Create Released Production Order. Create and Post Consumption Journal.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Integer Quantity Required.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released, Quantity, false, 0D);
        UpdateInventory(ItemJournalLine, ChildItem."No.", WorkDate(), Quantity);  // Inventory Value required for Test.
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
        Initialize();
        CreateLotForLotItem(ChildItem, 0, '<0D>');  // Safety Stock - 0. Child Item.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");

        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0. Parent Item.
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");

        // Create Production Forecast with single Entry.
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, ChildItem."No.", ForecastDate, false);

        // Create Released Production Order. Create and Post Consumption Journal.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Integer Quantity Required.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released, Quantity, false, 0D);
        UpdateInventory(ItemJournalLine, ChildItem."No.", WorkDate(), Quantity);  // Inventory Value required for Test.
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
        Initialize();
        CreateLotForLotItem(ChildItem, 0, '<0D>');  // Safety Stock - 0. Child Item.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");

        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0. Parent Item.
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");

        // Create Production Forecast with multiple entries.
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, ChildItem."No.", ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entries.

        // Create multiple Released Production Orders. Create and Post Consumption Journal.
        Quantity := LibraryRandom.RandInt(5) + 10;  // Random Integer Quantity Required.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released, Quantity, false, 0D);
        DueDate := GetRequiredDate(10, 0, ProductionOrder."Due Date", 1);  // Due Date Relative to Due Date of first Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder2, Item."No.", ProductionOrder.Status::Released, Quantity, true, DueDate);
        UpdateInventory(ItemJournalLine, ChildItem."No.", WorkDate(), Quantity);  // Inventory Value required for Test.
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
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation of Manufacturing Setup -FALSE.
        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0, Lot Accumulation Period - 0D.
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
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
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation of Manufacturing Setup -FALSE.
        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0, Lot Accumulation Period - 0D.

        // Create Production Forecast with multiple Entries. Update Production Forecast Quantity to - 0.
        ForecastDate := GetRequiredDate(30, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
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
        Initialize();
        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0, Lot Accumulation Period - 0D.

        // Create Sales Order. Update Shipment Date and Planned Delivery Date on Sales Line.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));  // Random quantity value not important.
        ShipmentDate := GetRequiredDate(2, 1, WorkDate(), 1);  // Shipment Date Relative to WORKDATE.
        UpdateShipmentDateOnSalesLine(SalesLine, ShipmentDate);
        UpdatePlannedDeliveryDateOnSalesLine(SalesLine, ShipmentDate);

        // Exercise: Calculate Regenerative Plan for Planning Worksheet.
        EndDate := GetRequiredDate(10, 20, SalesLine."Planned Delivery Date", 1);  // End Date relative to Planned Delivery Date.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);

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
        Initialize();
        CreateLotForLotItem(Item, 0, '<0D>');  // Safety Stock - 0, Lot Accumulation Period - 0D.
        ForecastDate := GetRequiredDate(30, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
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
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate(), LibraryRandom.RandDec(10, 2));  // Random quantity value not important.

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
        Initialize();
        CarryOutDemandInRequisitionWorksheet(Item, SalesHeader, SalesLine);

        // Exercise: Update the Promised Receipt Date in Purchase Order.
        LibraryVariableStorage.Enqueue(ModifiedPromisedReceiptDateMsg); // Required inside ConfirmHandler.
        LibraryVariableStorage.Enqueue(ReservationsExistMsg);
        SelectPurchaseLine(PurchaseLine, Item."No.");
        UpdatePromisedReceiptDateOnPurchaseHeader(PurchaseLine."Document No.", GetRequiredDate(10, 0, WorkDate(), 1));

        // Verify: Reservation Entry is removed.
        VerifyReservationEntryDeleted(Item."No.");

        // Exercise: Run Available to Promise in Sales Order.
        AvailabilityMgt.SetSalesHeader(TempOrderPromisingLine, SalesHeader);
        AvailabilityMgt.CalcAvailableToPromise(TempOrderPromisingLine);

        // Verify: Verify the Earliest Shipment date in Order Promising Table.
        PurchaseLine.FindFirst();
        TempOrderPromisingLine.TestField("Earliest Shipment Date", PurchaseLine."Expected Receipt Date");
    end;

    [Test]
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
        Initialize();
        CarryOutDemandInRequisitionWorksheet(Item, SalesHeader, SalesLine);

        // Exercise: Update the Promised Receipt Date in Purchase Order.
        LibraryVariableStorage.Enqueue(ModifiedPromisedReceiptDateMsg); // Required inside ConfirmHandler.
        LibraryVariableStorage.Enqueue(ReservationsExistMsg);
        PromisedReceiptDate := GetRequiredDate(10, 0, WorkDate(), -1);
        SelectPurchaseLine(PurchaseLine, Item."No.");
        UpdatePromisedReceiptDateOnPurchaseHeader(PurchaseLine."Document No.", PromisedReceiptDate);

        // Verify: Reservation Entry existed.
        ManufacturingSetup.Get();
        VerifyReservationEntry(Item."No.", CalcDate(ManufacturingSetup."Default Safety Lead Time", PromisedReceiptDate));

        // Exercise: Run Available to Promise in Sales Order.
        AvailabilityMgt.SetSalesHeader(TempOrderPromisingLine, SalesHeader);
        AvailabilityMgt.CalcAvailableToPromise(TempOrderPromisingLine);

        // Verify: Verify the Earliest Shipment date in Order Promising Table.
        PurchaseLine.FindFirst();
        TempOrderPromisingLine.TestField("Earliest Shipment Date", SalesLine."Shipment Date");
    end;

    [Test]
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
        Initialize();
        CarryOutDemandInRequisitionWorksheet(Item, SalesHeader, SalesLine);

        // Exercise: Update the Promised Receipt Date in Purchase Order line.
        // Verify: Promised Receipt Date changed successfully if earlier than original date
        SelectPurchaseLine(PurchaseLine, Item."No.");
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseLine."Document No.");
        PurchaseOrder.PurchLines."Promised Receipt Date".SetValue(GetRequiredDate(10, 0, WorkDate(), -1));

        // Exercise: Update the Promised Receipt Date in Purchase Order line.
        // Verify: Error message pops up if late than original date
        asserterror PurchaseOrder.PurchLines."Promised Receipt Date".SetValue(GetRequiredDate(20, 0, WorkDate(), 1));
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
        Initialize();
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
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<+CY>', WorkDate()));

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
        Initialize();
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

        Initialize();

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
              ItemJournalLine, "No.", LocationRed.Code, WorkDate(), LibraryRandom.RandDecInRange(100, 200, 2));
        end;

        // [GIVEN] Create Sales Order of Quantity = "S" + "X" / 2, delivery date = WorkDate() + 2 weeks. Calculate regeneration plan and carry out.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", ItemJournalLine.Quantity + OrderMultipleQty / 2);
        SalesLine.Validate("Location Code", LocationRed.Code);
        SalesLine.Modify(true);
        SalesHeader.Validate("Requested Delivery Date", CalcDate('<+2W>', WorkDate()));
        SalesHeader.Modify(true);
        CalculateRegenerativePlanAndCarryOut(Item."No.", Item."No.", true);

        // [GIVEN] Open created Production Order, set "Ending Date" to WorkDate() + 4 weeks.
        SelectProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::"Firm Planned");
        ProductionOrder.Validate("Ending Date", CalcDate('<+4W>', WorkDate()));
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
        Initialize();

        // [GIVEN] Manufacturing Location "ML" and Purchase Location "PL"
        CreateLocationsChain(PurchaseLocation, MnfgLocation);

        // [GIVEN] Parent Item "PI" with Child Item "CI" as BOM Component
        CreateItemAndBOMWithComponentItem(ParentItem, ChildItem);

        // [GIVEN] 3 Released Production Orders at "ML" each with Quantity = "POQ" and different due dates
        OrderQty := LibraryRandom.RandIntInRange(5000, 10000);
        DueDate := LibraryRandom.RandDateFromInRange(WorkDate(), 5, 10);
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

        // [GIVEN] Calculate Plan from Requisition Worksheet for "CI" from WorkDate() - 1 (at yerstaday) at location "ML", "Respect Planning Parameters" = TRUE
        ReqWorksheetCalculatePlan(ChildItem."No.", MnfgLocation.Code, WorkDate() - 1, DueDate, true);

        // [WHEN] Calculate Plan from Requisition Worksheet for "CI" from WorkDate() - 1 (at yerstaday) at location "PL", "Respect Planning Parameters" = TRUE
        ReqWorksheetCalculatePlan(ChildItem."No.", PurchaseLocation.Code, WorkDate() - 1, DueDate, true);

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
        Initialize();

        // [GIVEN] Sales Order for drop shipment of item "I".
        CreateSalesOrder(SalesHeader, SalesLine, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
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
        Initialize();

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
        Initialize();

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
        Item: Record Item;
        Location: Record Location;
        Vendor: Record Vendor;
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 263844] Requisition line "Location Code" is copied from vendor card when populate "Vendor No." with the field "No." of the vendor.
        Initialize();

        // [GIVEN] Location "L", vendor "V", "V"."Location Code" = "L"
        LibraryWarehouse.CreateLocation(Location);
        LibraryPurchase.CreateVendor(Vendor);
        UpdateVendorLocationCode(Vendor, Location.Code);

        // [GIVEN] Requisition Line "R"
        CreateRequisitionLine(RequisitionLine);
        RequisitionLine.Type := RequisitionLine.Type::Item;
        RequisitionLine."No." := LibraryInventory.CreateItem(Item);
        RequisitionLine.Modify(true);

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
        Initialize();

        // [GIVEN] Items "I1", "I2".
        for i := 1 to ArrayLen(ItemNo) do
            ItemNo[i] := LibraryInventory.CreateItemNo();

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
        ReqLineInReqWksh.FindFirst();
        ReqLineInReqWksh.TestField("No.", ItemNo[1]);

        // [THEN] A new line with item "I2" is inserted into the requisition worksheet after the "I1" line.
        ReqLineInReqWksh.Next();
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
        Initialize();

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
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // [THEN] Two purchase lines with "I1" are created, both in single order, and one line with "I2" in another order
        PurchaseLine.SetRange("No.", Item[1]."No.");
        Assert.RecordCount(PurchaseLine, 2);
        PurchaseLine.FindFirst();

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

        Initialize();

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
        CreateRoutingLineWithRoutingLink(RoutingHeader, RoutingLine, LibraryUtility.GenerateGUID(), WorkCenter."No.", 120, RoutingLink[1].Code);
        CreateRoutingLineWithRoutingLink(RoutingHeader, RoutingLine, LibraryUtility.GenerateGUID(), WorkCenter."No.", 60, RoutingLink[2].Code);
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        ProdItem.Validate("Reorder Quantity", 10);
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Validate("Routing No.", RoutingHeader."No.");
        ProdItem.Modify(true);

        // [WHEN] Calculate regenerative plan for the item "I"
        LibraryPlanning.CalcRegenPlanForPlanWksh(ProdItem, WorkDate(), WorkDate());

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
        Initialize();

        Qty := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Requisition line. Quantity = "X".
        CreateRequisitionLine(RequisitionLine);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", LibraryInventory.CreateItemNo());
        RequisitionLine.Validate("Starting Date", WorkDate());
        RequisitionLine.Validate("Ending Date", WorkDate());
        RequisitionLine.Validate(Quantity, Qty);
        RequisitionLine.Modify(true);

        // [GIVEN] Planning component of the requisition line. "Quantity per" = "N".
        // [GIVEN] "Expected Quantity" is now equal to "X" * "N".
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.Validate("Item No.", LibraryInventory.CreateItemNo());
        PlanningComponent.Validate("Quantity per", LibraryRandom.RandInt(10));
        PlanningComponent.Modify(true);

        // [WHEN] Open requisition worksheet page and update Quantity to "Y".
        ReqWorksheet.OpenEdit();
        ReqWorksheet.GotoRecord(RequisitionLine);
        ReqWorksheet.Quantity.SetValue(2 * Qty);

        // [THEN] "Expected Quantity" on the planning component becomes equal to "Y" * "N".
        PlanningComponent.Find();
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
        Initialize();

        // [GIVEN] An Item with Reorder Point Qty. = 1, Purchase, Reorder Point = 150, Lead Time = 2W
        CreateItemWithReorderPointAndQuantity(
          Item, Item."Reordering Policy"::"Fixed Reorder Qty.",
          Item."Replenishment System"::Purchase, LibraryRandom.RandIntInRange(100, 200), 1);
        UpdateLeadTimeCalculationForItem(Item, '<' + Format(LibraryRandom.RandIntInRange(10, 15)) + 'D>');

        // [GIVEN] Existing inventory for Item with Quantity = 70
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate() - 1, LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Sales order for this item with line Quantity = 30 and Shipment date between Start Date and Due Date for first Requisition Line
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandIntInRange(10, 50));
        UpdateShipmentDateOnSalesLine(SalesLine, WorkDate() + 1);

        // [WHEN] Calculate plan run with dates to have StartDate < Sales Order date < End Date
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), WorkDate() + 2);
        SelectRequisitionLine(RequisitionLine, Item."No.");

        // [THEN] 2 Lines are suggested
        Assert.RecordCount(RequisitionLine, 2);

        // [THEN] 1st line quantity = 150 - 70 + 1 = 81 (Exceeding Reorder Point by minimal margin)
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, Item."Reorder Point" - ItemJournalLine.Quantity + Item."Reorder Quantity");

        // [THEN] 2nd line quantity = 30 (Compensating sales order)
        RequisitionLine.FindLast();
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
        Initialize();

        // [GIVEN] An Item with Reorder Point Qty. = 1, Purchase, Reorder Point = 150, Lead Time = 2W
        CreateItemWithReorderPointAndQuantity(
          Item, Item."Reordering Policy"::"Fixed Reorder Qty.",
          Item."Replenishment System"::Purchase, LibraryRandom.RandIntInRange(100, 200), 1);
        UpdateLeadTimeCalculationForItem(Item, '<' + Format(LibraryRandom.RandIntInRange(10, 15)) + 'D>');

        // [GIVEN] Existing inventory for Item with Quantity = 70
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate() - 1, LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Purchase order for this item with line Quantity = 30 and Shipment date between Start Date and Due Date for first Requisition Line
        PurchaseOrderQuantity := LibraryRandom.RandIntInRange(20, 50);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", WorkDate() + 1, PurchaseOrderQuantity);

        // [WHEN] Calculate plan run with dates to have StartDate < Sales Order date < End Date
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), WorkDate() + 2);
        SelectRequisitionLine(RequisitionLine, Item."No.");

        // [THEN] Requisition line quantity = 150 - 70 - 30 + 1 = 51 (Exceeding Reorder Point by minimal margin)
        RequisitionLine.FindFirst();
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
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Lot-for-lot item.
        CreateLotForLotItem(Item, 0, '2W');

        // [GIVEN] Sales blanket order with two lines, each for 100 pcs, shipment dates are 01/05/20 and 01/08/20 accordingly.
        // [GIVEN] Set "Qty. to Ship" = 80 on both lines in the blanket order.
        LibrarySales.CreateSalesHeader(SalesHeaderBlanket, SalesHeaderBlanket."Document Type"::"Blanket Order", '');
        LibrarySales.CreateSalesLineWithShipmentDate(
            SalesLineBlanket, SalesHeaderBlanket, SalesLineBlanket.Type::Item, Item."No.", WorkDate() + 30, 100);
        UpdateQuantityToShipOnSalesLine(SalesLineBlanket, 80);
        LibrarySales.CreateSalesLineWithShipmentDate(
            SalesLineBlanket, SalesHeaderBlanket, SalesLineBlanket.Type::Item, Item."No.", WorkDate() + 90, 100);
        UpdateQuantityToShipOnSalesLine(SalesLineBlanket, 80);

        // [GIVEN] Make a sales order from the blanket order.
        BlanketSalesOrderToOrder.Run(SalesHeaderBlanket);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesHeaderOrder);

        // [GIVEN] Change shipment date on the first sales order line from 01/05/20 one month forward to 01/06/20.
        LibrarySales.FindFirstSalesLine(SalesLineOrder, SalesHeaderOrder);
        SalesLineOrder.Validate("Shipment Date", WorkDate() + 60);
        SalesLineOrder.Modify(true);

        // [WHEN] Calculate regenerative plan on the period covering all demands, that is 01/04/20..01/09/20.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate() + 120);

        // [THEN] A planning line to fulfill the remaining 20 pcs (100 - 80) on the first blanket order line is created.
        RequisitionLine.SetRange("Due Date", WorkDate() + 30);
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
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Lot-for-lot item.
        CreateLotForLotItem(Item, 0, '2W');

        // [GIVEN] Sales blanket order with two lines, each for 100 pcs, shipment dates are 01/05/20 and 01/08/20 accordingly.
        // [GIVEN] Set "Qty. to Ship" = 70 on both lines in the blanket order.
        LibrarySales.CreateSalesHeader(SalesHeaderBlanket, SalesHeaderBlanket."Document Type"::"Blanket Order", '');
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLineBlanket, SalesHeaderBlanket, SalesLineBlanket.Type::Item, Item."No.", WorkDate() + 30, 100);
        UpdateQuantityToShipOnSalesLine(SalesLineBlanket, 70);
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLineBlanket, SalesHeaderBlanket, SalesLineBlanket.Type::Item, Item."No.", WorkDate() + 90, 100);
        UpdateQuantityToShipOnSalesLine(SalesLineBlanket, 70);

        // [GIVEN] Make a sales order from the blanket order.
        // [GIVEN] Change shipment date on the first sales order line from 01/05/20 one month forward to 01/06/20.
        BlanketSalesOrderToOrder.Run(SalesHeaderBlanket);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesHeaderOrder);
        LibrarySales.FindFirstSalesLine(SalesLineOrder, SalesHeaderOrder);
        SalesLineOrder.Validate("Shipment Date", WorkDate() + 60);
        SalesLineOrder.Modify(true);

        // [GIVEN] Go back to the blanket sales order and set "Qty. to Ship" on the first line to 10 in order to create one more sales order.
        LibrarySales.FindFirstSalesLine(SalesLineBlanket, SalesHeaderBlanket);
        UpdateQuantityToShipOnSalesLine(SalesLineBlanket, 10);

        // [GIVEN] Make a second sales order from the blanket order.
        // [GIVEN] Change shipment date on the new sales order line from 01/05/20 on month forward to 01/06/20.
        BlanketSalesOrderToOrder.Run(SalesHeaderBlanket);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesHeaderOrder);
        LibrarySales.FindFirstSalesLine(SalesLineOrder, SalesHeaderOrder);
        SalesLineOrder.Validate("Shipment Date", WorkDate() + 60);
        SalesLineOrder.Modify(true);

        // [WHEN] Calculate regenerative plan on the period covering all demands, that is 01/04/20..01/09/20.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate() + 120);

        // [THEN] A planning line to fulfill the remaining 20 pcs (100 - 70 - 10) on the first blanket order line is created.
        RequisitionLine.SetRange("Due Date", WorkDate() + 30);
        FindRequisitionLineForItem(RequisitionLine, Item."No.");
        Assert.AreEqual(20, RequisitionLine.Quantity, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CombineTransfersOnCarryOutRequisitionWorksheet()
    var
        Location: array[3] of Record Location;
        LocationInTransit: Record Location;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        TransferRoute: Record "Transfer Route";
        i: Integer;
    begin
        // [FEATURE] [Transfer]
        // [SCENARIO 362808] Transfer orders are combined on carrying out planning lines in requisition worksheet.
        Initialize();

        // [GIVEN] Locations "From", "To-1", "To-2".
        for i := 1 to ArrayLen(Location) do
            LibraryWarehouse.CreateLocation(Location[i]);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, Location[1].Code, Location[2].Code, LocationInTransit.Code, '', '');
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, Location[1].Code, Location[3].Code, LocationInTransit.Code, '', '');

        // [GIVEN] Create transfer lines in requisition worksheet as follows:
        // [GIVEN] Line 1. Transfer from location "From" to location "To-1".
        // [GIVEN] Line 2. Transfer from location "From" to location "To-2".
        // [GIVEN] Line 3. Transfer from location "From" to location "To-1".
        // [GIVEN] Line 4. Transfer from location "From" to location "To-1".
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::"Req.");
        CreateRequisitionLineForTransfer(RequisitionLine, RequisitionWkshName, Location[1].Code, Location[2].Code);
        CreateRequisitionLineForTransfer(RequisitionLine, RequisitionWkshName, Location[1].Code, Location[3].Code);
        CreateRequisitionLineForTransfer(RequisitionLine, RequisitionWkshName, Location[1].Code, Location[2].Code);
        CreateRequisitionLineForTransfer(RequisitionLine, RequisitionWkshName, Location[1].Code, Location[2].Code);

        // [WHEN] Carry out action message.
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // [THEN] One transfer order "From" -> "To-1" is created and contains three lines.
        // [THEN] One transfer order "From" -> "To-2" is created and contains one line.
        VerifyTransferHeadersAndLinesCount(Location[1].Code, Location[2].Code, 1, 3);
        VerifyTransferHeadersAndLinesCount(Location[1].Code, Location[3].Code, 1, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineItemTypeShownOnPlanningWorksheetPage()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [SCENARIO 368399] Requisition Line with Type = Item is shown on Planning Worksheet page.
        Initialize();

        // [GIVEN] Requisition Worksheet Name "RW1" for Worksheet Template of Planning Type.
        // [GIVEN] Requisition Line with Journal Batch Name "RW1" and Type = Item.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        UpdateRequisitionLineTypeAndNo(RequisitionLine, RequisitionLine.Type::Item, LibraryInventory.CreateItemNo());

        // [WHEN] Open Planning Worksheet page.
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CurrentWkshBatchName.SetValue(RequisitionWkshName.Name);

        // [THEN] Requisition Line is shown on the page Planning Worksheet.
        PlanningWorksheet.Filter.SetFilter("No.", Format(RequisitionLine."No."));
        Assert.IsTrue(PlanningWorksheet.First(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineGLAccountTypeNotShownOnPlanningWorksheetPage()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [SCENARIO 368399] Requisition Line with Type = G/L Account is not shown on Planning Worksheet page.
        Initialize();

        // [GIVEN] Requisition Worksheet Name "RW1" for Worksheet Template of Planning Type.
        // [GIVEN] Requisition Line with Journal Batch Name "RW1" and Type = G/L Account.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        UpdateRequisitionLineTypeAndNo(RequisitionLine, RequisitionLine.Type::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [WHEN] Open Planning Worksheet page.
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CurrentWkshBatchName.SetValue(RequisitionWkshName.Name);

        // [THEN] Requisition Line is not shown on the page Planning Worksheet.
        PlanningWorksheet.Filter.SetFilter("No.", Format(RequisitionLine."No."));
        Assert.IsFalse(PlanningWorksheet.First(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineVendorNotBlockedOnLocationSKU()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        SalesLine: Record "Sales Line";
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        RequisitionLine: Record "Requisition Line";
        Purchasing: Record Purchasing;
    begin
        // [FEATURE] [Get Sales Orders] [Vendor]
        // [SCENARIO 382449] "Get Sales Orders" allows creation of Requisition Line when Vendor is only not blocked for the Location on the Sales Line
        Initialize();

        // [GIVEN] Item "I" with "Vendor No." = "V1"
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        UpdateItemVendorNo(Item, Vendor."No.");

        // [GIVEN] Location "L", Stockkeeping Unit "SKU" for Item "I", Location "L" with "Vendor No." = "V2"
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, Item."No.", '');
        StockkeepingUnit.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        StockkeepingUnit.Modify(true);

        // [GIVEN] Vendor "V1" Blocked
        Vendor.Validate(Blocked, Vendor.Blocked::All);
        Vendor.Modify(true);

        // [GIVEN] Sales order "SO" with Special Order purchasing code for "I" on the Location "L"
        LibraryPurchase.CreateSpecialOrderPurchasingCode(Purchasing);
        CreateSalesOrderWithPurchasingCode(SalesLine, '', Item."No.", Location.Code, Purchasing.Code, LibraryRandom.RandInt(10));

        // [WHEN] Get sales order to Requisition Line "R"
        CreateRequisitionLine(RequisitionLine);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, Item."No.");

        // [THEN] Requisition Line created for the Special Order "SO"
        // [THEN] "R"."Vendor No." is equal to "V2"
        FindRequisitionLineForItem(RequisitionLine, Item."No.");
        RequisitionLine.TestField("Vendor No.", StockkeepingUnit."Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineCanChangeQuantityForSpecialOrder()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Purchasing: Record Purchasing;
        NewQuantity: Decimal;
    begin
        // [FEATURE] [Get Sales Orders] [Special Order]
        // [SCENARIO 445763] "Get Sales Orders" allows creation of Requisition Line for special order and change of quantity
        Initialize();

        // [GIVEN] Item "I" with "Vendor No." = "V1"
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        UpdateItemVendorNo(Item, Vendor."No.");

        // [GIVEN] Sales order "SO" with Special Order purchasing code for "I"
        LibraryPurchase.CreateSpecialOrderPurchasingCode(Purchasing);
        CreateSalesOrderWithPurchasingCode(SalesLine, '', Item."No.", '', Purchasing.Code, LibraryRandom.RandInt(10));

        // [WHEN] Get sales order to Requisition Line "R"
        CreateRequisitionLine(RequisitionLine);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, Item."No.");

        // [THEN] Requisition Line created for the Special Order "SO" and increase Quantity
        FindRequisitionLineForItem(RequisitionLine, Item."No.");
        NewQuantity := RequisitionLine.Quantity * 2;
        RequisitionLine.Validate(Quantity, NewQuantity);
        RequisitionLine.Modify();

        // [THEN] Can run Carry Out Action Msg. action for changed quantity
        RequisitionLine.TestField(Quantity, NewQuantity);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] Requisition Line processed and deleted
        asserterror FindRequisitionLineForItem(RequisitionLine, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQtyIsRoundedTo0OnRequisitionLine()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        RequisitionLine: Record "Requisition Line";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO 392868] Throw Error while Rounding Item Quantity to 0 on Requisition Line of Type Item based on Rounding Precision.
        // [GIVEN] An item with base UoM, rounding precision and non-base UoM.
        Initialize();
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0.1;
        NonBaseQtyPerUOM := 3;
        SetupUoMTest(Item, ItemUOM, BaseUOM, NonBaseUOM, BaseQtyPerUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);

        // [WHEN] Adding an item with Base UoM and quantity 0.01 on requisition line.
        UpdateRequisitionLine(RequisitionLine, RequisitionLine.Type::Item, Item."No.", BaseUOM.Code, 0);

        // [THEN] Throw error due to rounding of quantity to 0.
        asserterror RequisitionLine.Validate(Quantity, 0.01);
        Assert.ExpectedError(QtyRoundingErr);

        SetupUoMTest(Item, ItemUOM, BaseUOM, NonBaseUOM, BaseQtyPerUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        // [WHEN] Adding an item with Non Base UoM and quantity 0.01 on requisition line.
        RequisitionLine.Init();
        UpdateRequisitionLine(RequisitionLine, RequisitionLine.Type::Item, Item."No.", NonBaseUOM.Code, 0);

        // [THEN] Throw error due to rounding of quantity to 0.
        asserterror RequisitionLine.Validate(Quantity, 0.01);
        Assert.ExpectedError(StrSubstNo(QuantityImbalanceErr,
                            RequisitionLine.FieldCaption(RequisitionLine."Qty. Rounding Precision"),
                            'Item',
                            RequisitionLine."No.",
                            RequisitionLine.FieldCaption(RequisitionLine.Quantity),
                            RequisitionLine.FieldCaption(RequisitionLine."Quantity (Base)")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionSpecifiedOnRequisitionLine()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        RequisitionLine: Record "Requisition Line";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO 392868] Item Base Quantity should be Rounded on Requisition Line of Type Item based on Specified Rounding Precision.
        // [GIVEN] An item with base UoM, rounding precision and non-base UoM.
        Initialize();
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1;
        NonBaseQtyPerUOM := 6;
        SetupUoMTest(Item, ItemUOM, BaseUOM, NonBaseUOM, BaseQtyPerUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);

        // [WHEN] Adding an item with Non Base UoM and quantity 0.5 on requisition line.
        RequisitionLine.Init();
        UpdateRequisitionLine(RequisitionLine, RequisitionLine.Type::Item, Item."No.", NonBaseUOM.Code, 0.5);

        // [THEN] The base quantity should be rounded to 3.
        Assert.AreEqual(3, RequisitionLine."Quantity (Base)", 'Base quantity is not rounded correctly.');

        // [WHEN] Adding an item with Non Base UoM and quantity 1/6 on requisition line.
        RequisitionLine.Init();
        UpdateRequisitionLine(RequisitionLine, RequisitionLine.Type::Item, Item."No.", NonBaseUOM.Code, 1 / 6);

        // [THEN] The base quantity should be rounded to 1.
        Assert.AreEqual(1, RequisitionLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionUnspecifiedOnRequisitionLine()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        RequisitionLine: Record "Requisition Line";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
    begin
        // [SCENARIO 392868] Item Base Quantity should be Rounded on Requisition Line of Type Item based on Unspecified Rounding Precision.
        // [GIVEN] An item with base UoM and non-base UoM without rounding precision.
        Initialize();
        BaseQtyPerUOM := 1;
        NonBaseQtyPerUOM := 6;
        SetupUoMTest(Item, ItemUOM, BaseUOM, NonBaseUOM, BaseQtyPerUOM, NonBaseQtyPerUOM, 0);

        // [WHEN] Adding an item with Non Base UoM and quantity 1/6 on requisition line.
        UpdateRequisitionLine(RequisitionLine, RequisitionLine.Type::Item, Item."No.", NonBaseUOM.Code, 1 / 6);

        // [THEN] The base quantity should be rounded to 1.00002.
        Assert.AreEqual(1.00002, RequisitionLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyAreRoundedWithRoundingPrecisionSpecifiedOnPlanningComponent()
    var
        ItemReqLine: Record Item;
        ItemPlanningComp: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO 392868] Item Quantities should be Rounded on Planning Component of based on Specified Rounding Precision.
        Initialize();

        // [GIVEN] Requisition line containing an item with base UoM, UoM rounding precision, non-base UoM and Quantity = "1/6".
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1;
        NonBaseQtyPerUOM := 6;
        SetupUoMTest(ItemReqLine, ItemUOM, BaseUOM, NonBaseUOM, BaseQtyPerUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        CreateRequisitionLine(RequisitionLine);
        UpdateRequisitionLine(RequisitionLine, RequisitionLine.Type::Item, ItemReqLine."No.", NonBaseUOM.Code, 4 / 6);
        RequisitionLine.Validate("Starting Date", WorkDate());
        RequisitionLine.Validate("Ending Date", WorkDate());

        //[GIVEN] Planning component for the requisition line containing an item with base UoM, UoM rounding precision, non-base UoM.
        //[GIVEN] Item's rounding precision = 0.00001.
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1;
        NonBaseQtyPerUOM := 24;
        SetupUoMTest(ItemPlanningComp, ItemUOM, BaseUOM, NonBaseUOM, BaseQtyPerUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        ItemPlanningComp."Rounding Precision" := 0.00001;
        ItemPlanningComp.Modify();
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.Validate("Item No.", ItemPlanningComp."No.");
        PlanningComponent.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Setting "Quantity per" as 16/24 on Planning Component.
        PlanningComponent.Validate("Quantity per", 16 / 24);

        // [THEN] Quantity is not rounded.
        Assert.AreEqual(16 / 24, PlanningComponent.Quantity, 'PlanningComponent.Quantity must not be rounded.');

        // [THEN] The base quantity is not rounded.
        Assert.AreEqual(16, PlanningComponent."Quantity (Base)", 'PlanningComponent."Quantity (Base)" must not be rounded.');

        // [THEN] The expected quantity should be rounded to roundup(0.66667 * 4/6, 0.00001) = 0.44445.
        Assert.AreEqual(0.44445, PlanningComponent."Expected Quantity", 'PlanningComponent."Expected Quantity" is not rounded correctly.');

        // [THEN] The base expected quantity should be rounded to round(0.44445 * 24, 1) = 11.
        Assert.AreEqual(11, PlanningComponent."Expected Quantity (Base)", 'PlanningComponent."Expected Quantity (Base)" is not rounded correctly.');

    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyAreRoundedWithRoundingPrecisionSpecifiedOnPlanningComponentAndGiveErrorOnScrap()
    var
        ItemReqLine: Record Item;
        ItemPlanningComp: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
        Scrap: Decimal;
    begin
        // [SCENARIO 410191]  Planning Components - Missing Rounding Check when calculating Expected Quantity
        Initialize();

        // [GIVEN] Requisition line containing an item with base UoM, UoM rounding precision to default 0, non-base UoM and Quantity = "1/6".
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 0;
        NonBaseQtyPerUOM := 6;
        Scrap := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        SetupUoMTest(ItemReqLine, ItemUOM, BaseUOM, NonBaseUOM, BaseQtyPerUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        CreateRequisitionLine(RequisitionLine);
        UpdateRequisitionLine(RequisitionLine, RequisitionLine.Type::Item, ItemReqLine."No.", BaseUOM.Code, LibraryRandom.RandIntInRange(1, 10));
        RequisitionLine.Validate("Scrap %", Scrap);
        RequisitionLine.Validate("Starting Date", WorkDate());
        RequisitionLine.Validate("Ending Date", WorkDate());

        //[GIVEN] Planning component for the requisition line containing an item with base UoM, UoM rounding precision, non-base UoM.
        //[GIVEN] Item's base rounding precision = 1
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1;
        NonBaseQtyPerUOM := 6;
        SetupUoMTest(ItemPlanningComp, ItemUOM, BaseUOM, NonBaseUOM, BaseQtyPerUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);

        ItemPlanningComp.Validate("Rounding Precision", 0.1); //Item rounding precision less than base UoM rounding precision.
        ItemPlanningComp.Modify();

        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.Validate("Item No.", ItemPlanningComp."No.");
        PlanningComponent.Validate("Unit of Measure Code", BaseUOM.Code);
        PlanningComponent.Validate("Scrap %", RequisitionLine."Scrap %"); //Scrapped copied from the Requisition Line

        // [WHEN] Setting "Quantity per" on Planning Component.
        // [THEN] The expected quantity should through an error due to scrap in Requisition line makes the component expected quantity be in decimals but item QtyRoundingPrecision is 1.
        asserterror PlanningComponent.Validate("Quantity per", LibraryRandom.RandIntInRange(1, 10));

        // [THEN] An error is thrown.
        Assert.ExpectedError(WrongPrecisionItemAndUOMExpectedQtyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyAreRoundedWithRoundingPrecisionUnspecifiedOnPlanningComponent()
    var
        ItemReqLine: Record Item;
        ItemPlanningComp: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO 392868] Item Quantities should be Rounded on Planning Component based on Unspecified Rounding Precision.
        Initialize();

        // [GIVEN] Requisition line containing an item with base UoM, non-base UoM, Quantity = "1/6" and unspecified UoM rounding precision.
        BaseQtyPerUOM := 1;
        NonBaseQtyPerUOM := 6;
        QtyRoundingPrecision := 0;
        SetupUoMTest(ItemReqLine, ItemUOM, BaseUOM, NonBaseUOM, BaseQtyPerUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        CreateRequisitionLine(RequisitionLine);
        UpdateRequisitionLine(RequisitionLine, RequisitionLine.Type::Item, ItemReqLine."No.", NonBaseUOM.Code, 4 / 6);
        RequisitionLine.Validate("Starting Date", WorkDate());
        RequisitionLine.Validate("Ending Date", WorkDate());

        //[GIVEN] Planning component for the requisition line containing an item with base UoM, unspecified UoM rounding precision, non-base UoM.
        //[GIVEN] Item's rounding precision = 0.00001.
        BaseQtyPerUOM := 1;
        NonBaseQtyPerUOM := 24;
        SetupUoMTest(ItemPlanningComp, ItemUOM, BaseUOM, NonBaseUOM, BaseQtyPerUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        ItemPlanningComp."Rounding Precision" := 0.00001;
        ItemPlanningComp.Modify();
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.Validate("Item No.", ItemPlanningComp."No.");
        PlanningComponent.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Setting "Quantity per" as 16/24 on Planning Component.
        PlanningComponent.Validate("Quantity per", 16 / 24);

        // [THEN] Quantity is not rounded.
        Assert.AreEqual(16 / 24, PlanningComponent.Quantity, 'PlanningComponent.Quantity must not be rounded.');

        // [THEN] The base quantity is not rounded.
        Assert.AreEqual(16, PlanningComponent."Quantity (Base)", 'PlanningComponent."Quantity (Base)" must not be rounded.');

        // [THEN] The expected quantity should be rounded to roundup(0.66667 * 4/6, 0.00001) = 0.44445.
        Assert.AreEqual(0.44445, PlanningComponent."Expected Quantity", 'PlanningComponent."Expected Quantity" is not rounded correctly.');

        // [THEN] The base expected quantity should be rounded to round(0.44445 * 24, not specified) = 10.6668.
        Assert.AreEqual(10.6668, PlanningComponent."Expected Quantity (Base)", 'PlanningComponent."Expected Quantity (Base)" is not rounded correctly.');

    end;

    [Test]
    procedure NonInventoryItemAllowedForPurchaseReplenishmentSystem()
    var
        NonInventoryItem: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO] It is possible to add non-inventory items for the purchase replenishment option.
        Initialize();

        // [GIVEN] A non-inventory item.
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] A requisition line of type item.
        CreateRequisitionLine(RequisitionLine);
        RequisitionLine.Type := RequisitionLine.Type::Item;

        // [WHEN] Setting item no for requisition line.
        RequisitionLine.Validate("No.", NonInventoryItem."No.");

        // [THEN] No error is thrown and replenish option is set to purchase.
        Assert.AreEqual(
            RequisitionLine."Replenishment System"::Purchase,
            RequisitionLine."Replenishment System",
            'Expected replenish option to be purchase'
        );

        // [WHEN] Setting setting replenish option to blank.
        asserterror RequisitionLine.Validate("Replenishment System", RequisitionLine."Replenishment System"::" ");

        // [THEN] An error is thrown.
        Assert.ExpectedError(InvalidReplenishmentOptionErr);

        // [WHEN] Setting setting replenish option to assembly.
        asserterror RequisitionLine.Validate("Replenishment System", RequisitionLine."Replenishment System"::Assembly);

        // [THEN] An error is thrown.
        Assert.ExpectedError(InvalidReplenishmentOptionErr);

        // [WHEN] Setting setting replenish option to prod. order.
        asserterror RequisitionLine.Validate("Replenishment System", RequisitionLine."Replenishment System"::"Prod. Order");

        // [THEN] An error is thrown.
        Assert.ExpectedError(InvalidReplenishmentOptionErr);

        // [WHEN] Setting setting replenish option to transfer.
        asserterror RequisitionLine.Validate("Replenishment System", RequisitionLine."Replenishment System"::Transfer);

        // [THEN] An error is thrown.
        Assert.ExpectedError(InvalidReplenishmentOptionErr);
    end;

    [Test]
    procedure LocationCodeForNonInventoryItemAllowed()
    var
        NonInventoryItem: Record Item;
        Location: Record Location;
        Vendor: Record Vendor;
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: REcord "Purchase Line";
    begin
        // [SCENARIO] It is possible to add non-inventory items for the purchase replenishment option.
        Initialize();

        // [GIVEN] A non-inventory item.
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] A location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A vendor with default location set.
        LibraryPurchase.CreateVendorWithLocationCode(Vendor, Location.Code);

        // [GIVEN] A requisition line of type item.
        CreateRequisitionLine(RequisitionLine);
        RequisitionLine.Type := RequisitionLine.Type::Item;

        // [WHEN] Setting item no for requisition line and vendor.
        RequisitionLine.Validate("No.", NonInventoryItem."No.");
        UpdateRequisitionLineVendorNo(RequisitionLine, Vendor."No.");
        RequisitionLine.Validate(Quantity, 1);
        RequisitionLine.Modify(true);

        // [THEN] Vendor default location code is set for requisition line.
        Assert.AreEqual(Location.Code, RequisitionLine."Location Code", 'Expected location code to be set.');

        // [WHEN] Carrying out the action for the requisition line.
        CarryOutActionPlan(RequisitionLine);

        // [THEN] A purchase order for the non-inventory item is created with the location set.
        SelectPurchaseLine(PurchaseLine, NonInventoryItem."No.");
        Assert.AreEqual(RequisitionLine.Quantity, PurchaseLine.Quantity, 'Expected quantity to match requisition line.');
        Assert.AreEqual(
            RequisitionLine."Location Code",
            PurchaseLine."Location Code",
            'Expected location to match requisition line.'
        );
    end;

    [Test]
    procedure RoundingPrecisionTransferedFromComponentLineToAssemblyLine()
    var
        Item: Record Item;
        ComponentItem: Record Item;
        ItemBaseUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        AssemblyLine: Record "Assembly Line";
    begin
        // [SCENARIO] It is possible to add non-inventory items for the purchase replenishment option.
        Initialize();

        // [GIVEN] An item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A component item with base UoM rounding precision 1 and a non-base UoM.
        LibraryInventory.CreateItem(ComponentItem);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemBaseUOM, ComponentItem."No.", BaseUOM.Code, 1);
        ItemBaseUOM."Qty. Rounding Precision" := 1;
        ItemBaseUOM.Modify();
        ComponentItem.Validate("Base Unit of Measure", ItemBaseUOM.Code);
        ComponentItem.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemNonBaseUOM, ComponentItem."No.", NonBaseUOM.Code, 12);

        // [GIVEN] A requisition line for the item with planning component
        CreateRequisitionLine(RequisitionLine);
        RequisitionLine.Type := RequisitionLine.Type::Item;
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate(Quantity, 3);
        RequisitionLine.Validate("Ref. Order Type", RequisitionLine."Ref. Order Type"::Assembly);
        RequisitionLine.Modify(true);

        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.Validate("Item No.", ComponentItem."No.");
        PlanningComponent.Validate("Unit of Measure Code", NonBaseUOM.Code);
        PlanningComponent.Validate("Quantity per", 1);
        PlanningComponent.Modify(true);

        // [THEN] Rounding precision is set correctly for planning component.
        Assert.AreEqual(
            ItemBaseUOM."Qty. Rounding Precision",
            PlanningComponent."Qty. Rounding Precision (Base)",
            'Expected rounding precision to match base item UoM'
        );
        Assert.AreEqual(
            ItemNonBaseUOM."Qty. Rounding Precision",
             PlanningComponent."Qty. Rounding Precision",
            'Expected rounding precision to match non-base item UoM'
        );

        // [WHEN] Carrying out action.
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] The rounding precision is transferred from planning component to assemby line.
        AssemblyLine.SetRange("No.", ComponentItem."No.");
        AssemblyLine.FindFirst();
        Assert.AreEqual(
            PlanningComponent."Qty. Rounding Precision (Base)",
            AssemblyLine."Qty. Rounding Precision (Base)",
            'Expected base rounding precision to match planning component.'
        );
        Assert.AreEqual(
            PlanningComponent."Qty. Rounding Precision",
            AssemblyLine."Qty. Rounding Precision",
            'Expected rounding precision to match planning component.'
        );
    end;

    [Test]
    procedure SkipPlanningBlockedItemsInRequisitionWorksheet()
    var
        BlockedItem: Record Item;
        NormalItem: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Item] [Blocked]
        // [SCENARIO 399387] Do not plan blocked items in requisition worksheet.
        Initialize();

        // [GIVEN] Items "A" and "B" set up for planning.
        CreateItemWithReorderPoint(
          NormalItem, NormalItem."Reordering Policy"::"Maximum Qty.", NormalItem."Replenishment System"::Purchase,
          LibraryRandom.RandInt(10), LibraryRandom.RandIntInRange(20, 40));

        // [GIVEN] Block item "B".
        CreateItemWithReorderPoint(
          BlockedItem, BlockedItem."Reordering Policy"::"Maximum Qty.", BlockedItem."Replenishment System"::Purchase,
          LibraryRandom.RandInt(10), LibraryRandom.RandIntInRange(20, 40));
        BlockedItem.Validate(Blocked, true);
        BlockedItem.Modify(true);

        // [WHEN] Calculate plan in requisition worksheet.
        NormalItem.SetFilter("No.", '%1|%2', NormalItem."No.", BlockedItem."No.");
        LibraryPlanning.CalcRequisitionPlanForReqWksh(NormalItem, WorkDate(), WorkDate());

        // [THEN] Planning line is created for item "A".
        FindRequisitionLineForItem(RequisitionLine, NormalItem."No.");

        // [THEN] The blocked item "B" is not planned.
        asserterror FindRequisitionLineForItem(RequisitionLine, BlockedItem."No.");
    end;

    [Test]
    procedure BlockedItemVariantCannotBeAddedToRequisitionLine()
    var
        Item: Record Item;
        BlockedItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [ItemVariant] [Blocked]
        // [SCENARIO 479956] User cannot add a blocked item variant to a requisition or planning worksheet (source table is RequisitionLine for both).
        Initialize();

        // [GIVEN] Requisition line, Blocked item variant
        CreateRequisitionLine(RequisitionLine);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(BlockedItemVariant, Item."No.");
        BlockedItemVariant.Validate(Blocked, true);
        BlockedItemVariant.Modify(true);

        // [WHEN] Adding item variant to requisition line
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");

        // [THEN] Error 'Blocked must be equal to 'No''
        asserterror RequisitionLine.Validate("Variant Code", BlockedItemVariant.Code);
        Assert.ExpectedError(StrSubstNo(BlockedErr, BlockedItemVariant.TableCaption(), StrSubstNo(ItemVariantPrimaryKeyLbl, BlockedItemVariant."Item No.", BlockedItemVariant.Code), BlockedItemVariant.FieldCaption(Blocked)));
    end;

    [Test]
    procedure RequestedReceiptDateInPurchaseEqualToPlanDeliveryDateOnSalesForDropShipment()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        Item: Record Item;
        Purchasing: Record Purchasing;
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        DefaultLeadTimeDateFormula: DateFormula;
    begin
        // [FEATURE] [Drop Shipment] [Get Sales Orders]
        // [SCENARIO 404883] Lead time settings are not applied when planning drop shipment.
        Initialize();
        Evaluate(DefaultLeadTimeDateFormula, '<1D>');

        // [GIVEN] Ensure "Default Safety Lead Time" is not blank in Manufacturing Setup.
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Default Safety Lead Time", DefaultLeadTimeDateFormula);
        ManufacturingSetup.Modify(true);

        // [GIVEN] Item with vendor.
        LibraryInventory.CreateItem(Item);
        UpdateItemVendorNo(Item, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Sales order for drop shipment.
        LibraryPurchase.CreateDropShipmentPurchasingCode(Purchasing);
        CreateSalesOrderWithPurchasingCode(SalesLine, '', Item."No.", '', Purchasing.Code, LibraryRandom.RandInt(10));

        // [WHEN] Open requisition worksheet and go to "Drop Shipment" - "Get Sales Orders".
        CreateRequisitionLine(RequisitionLine);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, 0);

        // [THEN] Expected receipt date on a new purchase line for drop shipment is equal to the shipment date on sales line.
        FindRequisitionLineForItem(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
        PurchaseLine.SetRange("Sales Order No.", SalesLine."Document No.");
        PurchaseLine.SetRange("Sales Order Line No.", SalesLine."Line No.");
        PurchaseLine.SetRange("No.", SalesLine."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Requested Receipt Date", SalesLine."Planned Delivery Date");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanReqWkshRequestPageHandler')]
    procedure S457091_ItemVariantQtyOnInventoryIsUsedInCalculationOfRequisitionQuantity_WithRespectPlanningParameters()
    var
        ObjectOptions: Record "Object Options";
        Item: Record Item;
        ItemVariant: array[3] of Record "Item Variant";
        StockkeepingUnit: array[3] of Record "Stockkeeping Unit";
        Customer: Record Customer;
        SalesHeader: array[6] of Record "Sales Header";
        SalesLine: array[6] of Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ItemVariantStockQty: array[3] of Decimal;
        SalesQty: array[6] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Reorder Point] [Stockkeeping Unit] [Requisition Worksheet] [Calculate Plan] [Respect Planning Parameters]
        // [SCENARIO 457091] Check that Quantities calculated in "Requisition Worksheet" respect Qty. on Inventory for Items and Variants.
        // [SCENARIO 457091] Create Item with 3 Variants and Stockkeeping Units. Put Quantity on Inventory for each Variant.
        // [SCENARIO 457091] Create 2 Sales Orders for 1st Variant, 1 Sales Order for 2nd Variant and 3 Sales Orders for 3rd Variant.
        // [SCENARIO 457091] Use "Calculate Plan" in "Requisition Worksheet" with "Respect Planning Parameters" enabled.
        Initialize();
        ObjectOptions.SetRange("Object Type", ObjectOptions."Object Type"::Report);
        ObjectOptions.SetRange("Object ID", Report::"Calculate Plan - Req. Wksh.");
        ObjectOptions.DeleteAll();

        ItemVariantStockQty[1] := LibraryRandom.RandIntInRange(1, 5);
        ItemVariantStockQty[2] := LibraryRandom.RandIntInRange(1, 5);
        ItemVariantStockQty[3] := LibraryRandom.RandIntInRange(1, 5);

        SalesQty[1] := LibraryRandom.RandIntInRange(10, 30);
        SalesQty[2] := LibraryRandom.RandIntInRange(10, 30);
        SalesQty[3] := LibraryRandom.RandIntInRange(10, 30);
        SalesQty[4] := LibraryRandom.RandIntInRange(10, 30);
        SalesQty[5] := LibraryRandom.RandIntInRange(10, 30);
        SalesQty[6] := LibraryRandom.RandIntInRange(10, 30);

        // [GIVEN] Create Item "I" with "Reordering Policy" = "Fixed Qty.", "Replenishment System" = "Purchase", "Manufacturing Policy" = "Make-to-Stock" and "Reorder Quantity" = 1
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Reorder Quantity", 1);
        Item.Modify(true);

        //  [GIVEN] Create Customer "C"
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create three Variants "V1", "V2", "V3" for Item "I"
        for i := 1 to ArrayLen(ItemVariant) do
            LibraryInventory.CreateItemVariant(ItemVariant[i], Item."No.");

        // [GIVEN] Create Stockkeeping Units for Item "I" and Variants "V1", "V2", "V3"
        for i := 1 to ArrayLen(ItemVariant) do begin
            LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit[i], '', Item."No.", ItemVariant[i].Code);
            StockkeepingUnit[i].CopyFromItem(Item);
            StockkeepingUnit[i].Modify(true);
        end;

        // [GIVEN] Put Item "I" and Variants "V1", "V2", "V3" on Inventory
        for i := 1 to ArrayLen(ItemVariant) do
            PutItemVariantInventoryOnLocation(Item."No.", ItemVariant[i].Code, '', WorkDate(), ItemVariantStockQty[i]);

        // [GIVEN] Create 1st Sales Order for Item "I", Variant "V1"
        LibrarySales.CreateSalesHeader(SalesHeader[1], SalesHeader[1]."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine[1], SalesHeader[1], SalesLine[1].Type::Item, Item."No.", WorkDate(), SalesQty[1]);
        SalesLine[1].Validate("Variant Code", ItemVariant[1].Code);
        SalesLine[1].Modify(true);

        // [GIVEN] Create 1st Sales Order for Item "I", Variant "V2"
        LibrarySales.CreateSalesHeader(SalesHeader[2], SalesHeader[2]."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine[2], SalesHeader[2], SalesLine[2].Type::Item, Item."No.", WorkDate(), SalesQty[2]);
        SalesLine[2].Validate("Variant Code", ItemVariant[2].Code);
        SalesLine[2].Modify(true);

        // [GIVEN] Create 1st Sales Order for Item "I", Variant "V3"
        LibrarySales.CreateSalesHeader(SalesHeader[3], SalesHeader[3]."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine[3], SalesHeader[3], SalesLine[3].Type::Item, Item."No.", WorkDate(), SalesQty[3]);
        SalesLine[3].Validate("Variant Code", ItemVariant[3].Code);
        SalesLine[3].Modify(true);

        // [GIVEN] Create 2nd Sales Order for Item "I", Variant "V1"
        LibrarySales.CreateSalesHeader(SalesHeader[4], SalesHeader[4]."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine[4], SalesHeader[4], SalesLine[4].Type::Item, Item."No.", WorkDate(), SalesQty[4]);
        SalesLine[4].Validate("Variant Code", ItemVariant[1].Code);
        SalesLine[4].Modify(true);

        // [GIVEN] Create 2nd Sales Order for Item "I", Variant "V3"
        LibrarySales.CreateSalesHeader(SalesHeader[5], SalesHeader[5]."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine[5], SalesHeader[5], SalesLine[5].Type::Item, Item."No.", WorkDate(), SalesQty[5]);
        SalesLine[5].Validate("Variant Code", ItemVariant[3].Code);
        SalesLine[5].Modify(true);

        // [GIVEN] Create 3rd Sales Order for Item "I", Variant "V3"
        LibrarySales.CreateSalesHeader(SalesHeader[6], SalesHeader[6]."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine[6], SalesHeader[6], SalesLine[6].Type::Item, Item."No.", WorkDate(), SalesQty[6]);
        SalesLine[6].Validate("Variant Code", ItemVariant[3].Code);
        SalesLine[6].Modify(true);

        // [WHEN] Calculate regenerative plan with "Respect Planning Parameters" = true.
        ReqWorksheetCalculatePlan(Item."No.", '', WorkDate(), WorkDate(), true);

        // [THEN] Verify that there are three Requisition Lines for Item "I"
        SelectRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordCount(RequisitionLine, ArrayLen(ItemVariant));

        // [THEN] Verify that Requisition Line Quantity for Item "I" and Variant "V1" is sum of Quantities on Sales Orders decreased by Inventory
        RequisitionLine.SetRange("Variant Code", ItemVariant[1].Code);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, SalesQty[1] + SalesQty[4] - ItemVariantStockQty[1]);

        // [THEN] Verify that Requisition Line Quantity for Item "I" and Variant "V1" is sum of Quantities on Sales Orders decreased by Inventory
        RequisitionLine.SetRange("Variant Code", ItemVariant[2].Code);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, SalesQty[2] - ItemVariantStockQty[2]);

        // [THEN] Verify that Requisition Line Quantity for Item "I" and Variant "V1" is sum of Quantities on Sales Orders decreased by Inventory
        RequisitionLine.SetRange("Variant Code", ItemVariant[3].Code);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, SalesQty[3] + SalesQty[5] + SalesQty[6] - ItemVariantStockQty[3]);
    end;

    [Test]
    procedure FastDeletionOfAllLinesInWorksheet()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StartTime: Time;
        DurationBefore: Duration;
        DurationAfter: Duration;
        i: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 451265] Fast deletion of all lines with dependencies in planning or requisition worksheet.
        Initialize();

        // [GIVEN] Manufacturing item "I" with 20 components.
        // [GIVEN] Set up the item for planning.
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        for i := 1 to 20 do
            LibraryManufacturing.CreateProductionBOMLine(
              ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item,
              LibraryInventory.CreateItemNo(), 1);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);

        // [GIVEN] Create sales order with 50 lines, each for item "I", different shipment dates.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        for i := 1 to 50 do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 50);
            SalesLine.Validate("Shipment Date", WorkDate() + 5 * i);
            SalesLine.Modify(true);
        end;

        Item.SetRecFilter();

        // [WHEN] Calculate regenerative plan for the item "I" twice and delete all lines in the planning worksheet with two different methods.
        // Use DeleteAll(true) to delete all requisition lines on the first run. Deletion time = "T1".
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordCount(RequisitionLine, 50);
        StartTime := Time;
        RequisitionLine.DeleteAll(true);
        DurationBefore := Time - StartTime;

        // Use ClearPlanningWorksheet() function to delete all requisition lines on the second run. Deletion time = "T2".
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordCount(RequisitionLine, 50);
        RequisitionLine.FindFirst();
        StartTime := Time;
        RequisitionLine.ClearPlanningWorksheet(true);
        DurationAfter := Time - StartTime;

        // [THEN] "T2" is at least 50% less than "T1".
        Assert.IsTrue(DurationAfter * 1.5 < DurationBefore, '');
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    procedure VerifyQuantityOnReqLineForCompItemWithLotToLotAndMakeToOrderSetupWhenInventoryIsAvailable()
    var
        Location: Record Location;
        ParentItem, ChildItem : Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 462567] Verify Qty. on Req. Line for Component Item with Lot-to-Lot and Make-to-Order setup when Inventory is available
        Initialize();

        // [GIVEN] Create Location
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Set Location at "Component At Location" on Manufacturing Setup
        UpdateManufacturingSetupComponentsAtLocation(Location.Code);

        // [GIVEN] Create two Manufacturing Items
        CreateManufacturingItems(ParentItem, ChildItem, '<1W>', 13);

        // [GIVEN] Create Sales Order
        CreateSalesOrder(SalesHeader, SalesLine, ParentItem."No.", 5);

        // [GIVEN] Update Shipment Date on Sales Line
        UpdateShipmentDateOnSalesLine(SalesLine, SalesLine."Shipment Date" + LibraryRandom.RandInt(5));

        // [GIVEN] Create and Post Item Journal
        CreateAndPostItemJournal(ChildItem."No.", 1, Location.Code);

        // [WHEN] Calculate Regenerative Plan
        CalculateRegenerativePlanForPlanWorksheet(ChildItem."No.", ParentItem."No.");

        // [THEN] Verify results        
        VerifyQtyOnReqLines(ParentItem, ChildItem, 5, 4);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandlerWithThreeItems')]
    procedure VerifyLinesAndQuantityOnReqLineOneCompItemAndManyParentWithLotToLotAndMakeToOrderSetupWhenInventoryIsAvailable()
    var
        Location: Record Location;
        ParentItem: array[2] of Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
    begin
        // [SCENARIO 463825] Verify No. of Lines and Qty. on Req. Line for Component Item and two BOM Item with Lot-to-Lot and Make-to-Order setup when Inventory is available
        Initialize();

        // [GIVEN] Create Location
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Set Location at "Component At Location" on Manufacturing Setup
        UpdateManufacturingSetupComponentsAtLocation(Location.Code);

        // [GIVEN] Create three Manufacturing Items
        CreateManufacturingItems(ParentItem, ChildItem, '<1W>');

        // [GIVEN] Create Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::Item, ParentItem[1]."No.", 5);
        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, ParentItem[2]."No.", 6);

        // [GIVEN] Update Shipment Date on Sales Line
        UpdateShipmentDateOnSalesLine(SalesLine[1], SalesLine[1]."Shipment Date" + LibraryRandom.RandInt(5));
        UpdateShipmentDateOnSalesLine(SalesLine[2], SalesLine[1]."Shipment Date");

        // [GIVEN] Create and Post Item Journal
        CreateAndPostItemJournal(ChildItem."No.", 1, Location.Code);

        // [WHEN] Calculate Regenerative Plan
        CalculateRegenerativePlanForPlanWorksheet(ChildItem."No.", ParentItem[1]."No.", ParentItem[2]."No.");

        // [THEN] Verify results        
        VerifyQtyOnReqLines(ParentItem, ChildItem, 5);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    procedure VerifyQuantityOnReqLineForCompItemWithMaxQtyAndMakeToOrderSetupWhenInventoryIsAvailable()
    var
        Location: Record Location;
        ParentItem, ChildItem : Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 466957] Verify Qty. on Req. Line for Component Item with Max. Qty. policy and Make-to-Order setup when Inventory is available
        Initialize();

        // [GIVEN] Create Location
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Set Location at "Component At Location" on Manufacturing Setup
        UpdateManufacturingSetupComponentsAtLocation(Location.Code);

        // [GIVEN] Create two Manufacturing Items
        CreateManufacturingItems(ParentItem, ChildItem, 5, 50);

        // [GIVEN] Create Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ParentItem."No.", 5);

        // [GIVEN] Update Shipment Date on Sales Line
        UpdateShipmentDateOnSalesLine(SalesLine, SalesLine."Shipment Date" + LibraryRandom.RandInt(5));

        // [GIVEN] Create and Post Item Journal
        CreateAndPostItemJournal(ChildItem."No.", 1, Location.Code);

        // [WHEN] Calculate Regenerative Plan
        CalculateRegenerativePlanForPlanWorksheet(ChildItem."No.", ParentItem."No.");

        // [THEN] Verify results        
        VerifyQtyOnReqLines(ParentItem, ChildItem, 5, 4, 50);
    end;

    [Test]
    procedure S472980_StartingDateTimeInPlanningWorksheetIsLessOrEqualToEndingDateTime()
    var
        ObjectOptions: Record "Object Options";
        ManufacturingSetup: Record "Manufacturing Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        BlankDateFormula: DateFormula;
    begin
        // [FEATURE] [Default Safety Lead Time] [Planning Worksheet] [Calculate Regenerative Plan]
        // [SCENARIO 472980] Verify that "Starting Date-Time" is less or equal to "Ending Date-Time" in Planning Worksheet when "Default Safety Lead Time" in "Manufacturing Setup" is blank.
        Initialize();
        ObjectOptions.SetRange("Object Type", ObjectOptions."Object Type"::Report);
        ObjectOptions.SetRange("Object ID", Report::"Calculate Plan - Req. Wksh.");
        ObjectOptions.DeleteAll();

        // [GIVEN] Set "Default Safety Lead Time" to blank and other settings to default values.
        ManufacturingSetup.Get();
        Evaluate(BlankDateFormula, '');
        if ManufacturingSetup."Default Safety Lead Time" <> BlankDateFormula then
            ManufacturingSetup.Validate("Default Safety Lead Time", BlankDateFormula);
        if ManufacturingSetup."Normal Starting Time" = 0T then
            ManufacturingSetup.Validate("Normal Starting Time", 080000T);
        if ManufacturingSetup."Normal Ending Time" = 0T then
            ManufacturingSetup.Validate("Normal Ending Time", 170000T);
        if ManufacturingSetup."Use Forecast on Locations" then
            ManufacturingSetup.Validate("Use Forecast on Locations", false);
        if ManufacturingSetup."Current Production Forecast" <> '' then
            ManufacturingSetup.Validate("Current Production Forecast", '');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create Item "I" with "Reordering Policy" = "Lot-for-Lot", "Replenishment System" = "Prod. Order".
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Evaluate(BlankDateFormula, '');
        if Item."Safety Lead Time" <> BlankDateFormula then
            Item.Validate("Safety Lead Time", BlankDateFormula);
        Item.Modify(true);

        // [GIVEN] Create Sales Order for Item "I".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 30));

        // [WHEN] Calculate Regenerative Plan with "Respect Planning Parameters" = false.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<+1D+CM>', WorkDate()));

        // [THEN] Verify that there is one Requisition Lines for Item "I".
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordCount(RequisitionLine, 1);

        // [THEN] Verify that "Quantity" is equal to Sales Line Quantity.
        RequisitionLine.FindFirst();
        Assert.AreEqual(SalesLine.Quantity, RequisitionLine.Quantity, 'Quantity must be equal to Sales Line Quantity');

        // [THEN] Verify that "Starting Date-Time" is less or equal to "Ending Date-Time".
        Assert.IsTrue(RequisitionLine."Starting Date-Time" <= RequisitionLine."Ending Date-Time", 'Starting Date-Time must be less or equal to Ending Date-Time');
    end;

    [Test]
    procedure ShowErrorIfItemVariantIsPurchasingBlockedWhenCarryOutActionMessage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        // [SCENARIO 492287] Purchase order can be created for a blocked item variant using planning worksheet for creation
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Item Variant and Validate Purchasing Blocked.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant.Validate("Purchasing Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Create Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Requisition WorkSheet Name.
        CreateRequisitionWorksheetName(RequisitionWkshName);

        // [WHEN] Create Requisition Line.
        CreateRequisitionLineWithItemVariant(
            RequisitionLine,
            RequisitionWkshName,
            Item,
            ItemVariant,
            Vendor);

        // [VERIFY] Verify Carry Out Action Message gives an error.
        asserterror CarryOutActionPlan(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderSaveAsXML')]
    [Scope('OnPrem')]
    procedure PrintMultiplePurchaseOrdersWhenUsingCarryOutActionMessage()
    var
        RequisitionPlanningLine: array[2] of Record "Requisition Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PurchaseHeader: Record "Purchase Header";
        NewPurchOrderChoice: Option " ","Make Purch. Orders","Make Purch. Orders & Print","Copy to Req. Wksh";
        ItemNo, VendorNo : array[2] of Code[20];
        i: Integer;
    begin
        // [SCENARIO 492125] Verify printing of multiple purchase orders in the "planning worksheet" sheet when using Carry Out Action Message.
        Initialize();

        // [GIVEN] Create multiple vendors and items
        for i := 1 to ArrayLen(VendorNo) do begin
            VendorNo[i] := LibraryPurchase.CreateVendorNo();
            ItemNo[i] := LibraryInventory.CreateItemNo();
        end;

        // [GIVEN] Select Planning worksheet.
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);

        // [GIVEN] Create and modify the requisition line for Vendor "A".
        LibraryPlanning.CreateRequisitionLine(RequisitionPlanningLine[1], RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionPlanningLine[1].Validate(Type, RequisitionPlanningLine[1].Type::Item);
        RequisitionPlanningLine[1].Validate("No.", ItemNo[1]);
        RequisitionPlanningLine[1].Validate("Vendor No.", VendorNo[1]);
        RequisitionPlanningLine[1].Validate("Accept Action Message", true);
        RequisitionPlanningLine[1].Validate(Quantity, LibraryRandom.RandInt(10));
        RequisitionPlanningLine[1].Modify(true);

        // [GIVEN] Create and modify the requisition line for Vendor "B".
        LibraryPlanning.CreateRequisitionLine(RequisitionPlanningLine[2], RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionPlanningLine[2].Validate(Type, RequisitionPlanningLine[2].Type::Item);
        RequisitionPlanningLine[2].Validate("No.", ItemNo[2]);
        RequisitionPlanningLine[2].Validate("Vendor No.", VendorNo[2]);
        RequisitionPlanningLine[2].Validate("Accept Action Message", true);
        RequisitionPlanningLine[2].Validate(Quantity, LibraryRandom.RandInt(10));
        RequisitionPlanningLine[2].Modify(true);

        // [GIVEN] Filter newly created requisition lines.
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.FindSet();

        // [GIVEN] Setup report selection.
        SetupReportSelections("Report Selection Usage"::"P.Order", Report::"Standard Purchase - Order");

        // [WHEN] Carry out action in planning worksheet with option "Make Purch. Orders & Print".
        LibraryPlanning.CarryOutPlanWksh(
            RequisitionLine, 0, NewPurchOrderChoice::"Make Purch. Orders & Print", 0,
            0, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, '', '');

        // [VERIFY] Verify Print of Multiple Purchase Orders When Using Carry Out Action Message.
        PurchaseHeader.SetFilter("Buy-from Vendor No.", '%1|%2', VendorNo[1], VendorNo[2]);
        VerifyPrintedPurchaseOrders(PurchaseHeader);
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
        ReservationEntry.DeleteAll();
        RequisitionLine.DeleteAll();
        RequisitionWkshName.DeleteAll();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        LibraryApplicationArea.EnableEssentialSetup();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Plan-Req. Wksht");

        AllProfile.SetRange("Profile ID", 'ORDER PROCESSOR');
        AllProfile.FindFirst();
        ConfPersonalizationMgt.SetCurrentProfile(AllProfile);

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateVATData();
        NoSeriesSetup();
        ItemJournalSetup();
        CreateLocationSetup();
        ConsumptionJournalSetup();

        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Plan-Req. Wksht");
    end;

    local procedure InitializeOrderPlanRecalculdationScenario(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy")
    var
        Qty: Decimal;
    begin
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);
        CreateItemWithReorderPoint(Item, ReorderingPolicy, Item."Replenishment System"::Purchase, Qty, Qty + 1);
        PostReceiptAndAutoReserveForSale(Item, Qty);
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Blanket Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        Clear(ItemJournalTemplate);
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        Clear(ItemJournalBatch);
        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Modify(true);
    end;

    local procedure SetBlankOverflowLevelAsUseItemValues()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        with ManufacturingSetup do begin
            Get();
            Validate("Blank Overflow Level", "Blank Overflow Level"::"Use Item/SKU Values Only");
            Modify(true);
        end;
    end;

    local procedure AutoReserveForSalesLine(SalesLine: Record "Sales Line")
    var
        Reservation: Page Reservation;
    begin
        LibraryVariableStorage.Enqueue(AutoReservNotPossibleMsg);
        Reservation.SetReservSource(SalesLine);
        Reservation.RunModal();
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
                OrderPlanningMgt.SetProdOrder();
            DemandType::Sales:
                OrderPlanningMgt.SetSalesOrder();
            DemandType::Service:
                OrderPlanningMgt.SetServOrder();
            DemandType::Jobs:
                OrderPlanningMgt.SetJobOrder();
            DemandType::Assembly:
                OrderPlanningMgt.SetAsmOrder();
        end;

        OrderPlanningMgt.GetOrdersToPlan(ReqLine);
    end;

    local procedure CarryOutActionPlan(var ReqLine: Record "Requisition Line")
    var
        MfgUserTemplate: Record "Manufacturing User Template";
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
    begin
        MfgUserTemplate.Init();
        MfgUserTemplate.Validate("Create Purchase Order", MfgUserTemplate."Create Purchase Order"::"Make Purch. Orders");

        ReqLine.SetRecFilter();
        CarryOutActionMsgPlan.UseRequestPage(false);
        CarryOutActionMsgPlan.SetDemandOrder(ReqLine, MfgUserTemplate);
        CarryOutActionMsgPlan.RunModal();
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
        ConsumptionItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ConsumptionItemJournalTemplate, ConsumptionItemJournalTemplate.Type::Consumption);

        Clear(ConsumptionItemJournalBatch);
        ConsumptionItemJournalBatch.Init();
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

    local procedure CreateItem(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateSKU(Item: Record Item; LocationCode: Code[10]; RepSystem: Enum "Replenishment System"; ReordPolicy: Enum "Reordering Policy"; FromLocation: Code[10]; IncludeInventory: Boolean; ReschedulingPeriod: Text; SafetyLeadTime: Text)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        Item.SetRange("Location Filter", LocationCode);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);
        Item.SetRange("Location Filter");
        with StockkeepingUnit do begin
            SetRange("Item No.", Item."No.");
            SetRange("Location Code", LocationCode);
            FindFirst();
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

    local procedure CreateSKUForLocationWithReplenishmentSystemAndReorderingPolicy(ItemNo: Code[20]; LocationCode: Code[10]; ReplenishmentSystem: Enum "Replenishment System"; TransferFromCode: Code[10]; ReorderingPolicy: Enum "Reordering Policy"; ReorderQuantity: Decimal; SafetyStockQuantity: Decimal)
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

    local procedure CreateItemWithReorderPoint(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System"; ReorderPoint: Decimal; MaximumInventory: Decimal)
    begin
        CreateItem(Item, ReorderingPolicy, ReplenishmentSystem);
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Modify(true);
    end;

    local procedure CreateItemWithReorderPointAndQuantity(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System"; ReorderPoint: Decimal; ReorderQuantity: Decimal)
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

    local procedure CreateFixedReorderQtyItem(var Item: Record Item; SafetyStockQty: Decimal; ReorderPoint: Decimal; ReorderQty: Decimal)
    begin
        // Create Fixed Reorder Quantity Item.
        CreateItem(Item, Item."Reordering Policy"::"Fixed Reorder Qty.", Item."Replenishment System"::Purchase);
        Item.Validate("Safety Stock Quantity", SafetyStockQty);
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Reorder Quantity", ReorderQty);
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

    local procedure CreateOrderItem(var Item: Record Item; ProductionBOMNo: Code[20]; ReplenishmentSystem: Enum "Replenishment System")
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
        LibraryPatterns.MAKEProductionOrder(ProdOrder, ProdOrder.Status::Released, ProdItem, '', '', Qty, WorkDate());
    end;

    local procedure UpdateForecastOnManufacturingSetup(CurrentProductionForecast: Code[10])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
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
        CreateBlanketOrder(SalesHeader, SalesLine, ItemNo, Quantity, WorkDate());
        BlanketSalesOrderToOrder.Run(SalesHeader);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesOrderHeader);
    end;

    local procedure CreateRequisitionLine(var RequisitionLine: Record "Requisition Line")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
    end;

    local procedure CreateRequisitionLineForTransfer(var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Record "Requisition Wksh. Name"; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    begin
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", LibraryInventory.CreateItemNo());
        RequisitionLine.Validate(Quantity, LibraryRandom.RandInt(10));
        RequisitionLine.Validate("Location Code", ToLocationCode);
        RequisitionLine.Validate("Replenishment System", RequisitionLine."Replenishment System"::Transfer);
        RequisitionLine.Validate("Transfer-from Code", FromLocationCode);
        RequisitionLine.Validate("Starting Date", WorkDate());
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
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

    local procedure PutItemVariantInventoryOnLocation(ItemNo: Code[20]; VarintCode: Code[10]; LocationCode: Code[10]; PostingDate: Date; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        if VarintCode <> '' then
            ItemJournalLine.Validate("Variant Code", VarintCode);
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
          SalesHeader, SalesLine, Item, '', '', Quantity * LibraryRandom.RandDecInDecimalRange(1.5, 2, 2), WorkDate(), Item."Unit Cost");
        AutoReserveForSalesLine(SalesLine);
    end;

    local procedure CreateSalesOrderWithPurchasingCode(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; PurchasingCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo, ItemNo, Quantity, LocationCode, WorkDate());
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
    var
        Item: Record Item;
    begin
        with ReqLine do begin
            Type := Type::Item;
            "No." := LibraryInventory.CreateItem(Item);
            "Ref. Order Type" := "Ref. Order Type"::"Prod. Order";
            "Routing No." := RoutingHeaderNo;
            "Starting Date" := StartingDate;
            "Ending Date" := EndingDate;
            Insert();
        end;
    end;

    local procedure CalcPlanAndCarryOutActionMessageWithPlanningFlexibility(var RequisitionWkshName: Record "Requisition Wksh. Name"; var Item: Record Item; PlanningFlexibility: Enum "Reservation Planning Flexibility"; EndingDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), EndingDate);
        SelectRequisitionLine(RequisitionLine, Item."No.");
        UpdatePlanningFlexiblityOnRequisitionWorksheet(RequisitionLine, Item."No.", PlanningFlexibility);
        AcceptActionMessage(Item."No.");
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure CalcRegenPlanForPlanWkshPage(var PlanningWorksheet: TestPage "Planning Worksheet"; Name: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        // Regenerative Planning using Page required where Forecast is used.
        LibraryVariableStorage.Enqueue(ItemNo);  // Set Global Value.
        LibraryVariableStorage.Enqueue(ItemNo2);  // Set Global Value.
        Commit();  // Required for Test.
        OpenPlanningWorksheetPage(PlanningWorksheet, Name);
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();  // Open report on Handler CalculatePlanPlanWkshRequestPageHandler.
        PlanningWorksheet.OK().Invoke();
    end;

    local procedure CalcRegenPlanForPlanWkshPage(var PlanningWorksheet: TestPage "Planning Worksheet"; Name: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; ItemNo3: Code[20])
    begin
        // Regenerative Planning using Page required where Forecast is used.
        LibraryVariableStorage.Enqueue(ItemNo);  // Set Global Value.
        LibraryVariableStorage.Enqueue(ItemNo2);  // Set Global Value.
        LibraryVariableStorage.Enqueue(ItemNo3);  // Set Global Value.
        Commit();  // Required for Test.
        OpenPlanningWorksheetPage(PlanningWorksheet, Name);
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();  // Open report on Handler CalculatePlanPlanWkshRequestPageHandler.
        PlanningWorksheet.OK().Invoke();
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
        Commit();
        OpenRequisitionWorksheetPage(ReqWorksheet, FindRequisitionWkshName(ReqWkshTemplate.Type::"Req."));
        ReqWorksheet.CalculatePlan.Invoke(); // Open report on Handler CalculatePlanReqWkshWithPeriodItemNoLocationParamsRequestPageHandler
        ReqWorksheet.OK().Invoke();
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
        CalcPlanAndCarryOutActionMessageWithPlanningFlexibility(
          RequisitionWkshName, Item, RequisitionLine."Planning Flexibility"::Unlimited, CalcDate('<+2M>', WorkDate()));
    end;

    local procedure CarryOutDemandAndUpdateSalesShipmentDate(var TopItem: Record Item; var MiddleItem: Record Item; var BottomItem: Record Item; var ShipmentDate: Date; var ShipmentDate2: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

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
        if not TransferRoute.FindFirst() then
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
            FindFirst();
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
        PurchaseLine.FindFirst();
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

    local procedure FilterOnRequisitionLines(var RequisitionLine: Record "Requisition Line"; ItemNoFilter: Text)
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetFilter("No.", ItemNoFilter);
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
            FindFirst();
        end;
    end;

    local procedure SelectRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        FilterOnRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.FindSet();
    end;

    local procedure SelectRequisitionLines(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        FilterOnRequisitionLines(RequisitionLine, ItemNo, ItemNo2);
        RequisitionLine.FindSet();
    end;

    local procedure SelectSalesLineFromSalesDocument(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure SelectProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Status: Enum "Production Order Status")
    begin
        ProductionOrder.SetRange("Source No.", ItemNo);
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.FindFirst();
    end;

    local procedure SelectRequisitionTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Type: Enum "Req. Worksheet Template Type")
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
    end;

    local procedure SetSupplyFromVendorOnRequisitionLine(var ReqLine: Record "Requisition Line")
    begin
        with ReqLine do begin
            Validate("Supply From", LibraryPurchase.CreateVendorNo());
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
        until RequisitionLine.Next() = 0;
    end;

    local procedure AcceptActionMessages(ItemNo: Code[20]; ItemNo2: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLines(RequisitionLine, ItemNo, ItemNo2);

        repeat
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
    end;

    local procedure UpdatePlanningFlexiblityOnRequisitionWorksheet(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; PlanningFlexibility: Enum "Reservation Planning Flexibility")
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        repeat
            RequisitionLine.Validate("Planning Flexibility", PlanningFlexibility);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
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
        SalesLine.Find();
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
        SalesReceivablesSetup.Get();
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

    local procedure UpdateRequisitionLineTypeAndNo(var RequisitionLine: Record "Requisition Line"; SourceType: Enum "Requisition Line Type"; SourceNo: Code[20])
    begin
        RequisitionLine.Validate(Type, SourceType);
        RequisitionLine.Validate("No.", SourceNo);
        RequisitionLine.Modify(true);
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
        Item.SetRecFilter();
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), WorkDate());
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

    local procedure CalculateRegenerativePlanForPlanWorksheet(ItemNo: Code[20]; ItemNo2: Code[20]; ItemNo3: Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        Clear(RequisitionWkshName);
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, ItemNo, ItemNo2, ItemNo3);
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
        GetSalesOrders.Run();
    end;

    local procedure FindRequisitionWkshName(ReqWkshTemplateType: Enum "Req. Worksheet Template Type"): Code[10]
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplateType);
        with RequisitionWkshName do begin
            SetRange("Worksheet Template Name", ReqWkshTemplate.Name);
            FindFirst();
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
        NewDate := CalcDate('<' + Format(Month) + 'M>', WorkDate());
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Status: Enum "Production Order Status"; Quantity: Decimal; NewDueDate: Boolean; DueDate: Date)
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
        ManufacturingSetup.Get();
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

    local procedure CreateItemJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal)
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
        PlanningRoutingLine.FindFirst();

        PlanningComponent.SetRange("Routing Link Code", RoutingLinkCode);
        PlanningComponent.FindFirst();

        PlanningComponent.TestField("Due Date", PlanningRoutingLine."Starting Date");
        PlanningComponent.TestField("Due Time", PlanningRoutingLine."Starting Time");
    end;

    local procedure OpenPlanningWorksheetPage(var PlanningWorksheet: TestPage "Planning Worksheet"; Name: Code[10])
    begin
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CurrentWkshBatchName.SetValue(Name);
    end;

    local procedure OpenRequisitionWorksheetPage(var ReqWorksheet: TestPage "Req. Worksheet"; Name: Code[10])
    begin
        ReqWorksheet.OpenEdit();
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
        RequisitionLine.Next();
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
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Due Date", DueDate);
    end;

    local procedure VerifyReservationEntryOfReservationExist(ItemNo: Code[20]; Exist: Boolean; RowsNumber: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);

        ReservationEntry.SetRange("Source Type", Database::"Prod. Order Component");
        Assert.AreEqual(Exist, ReservationEntry.FindFirst(), ReservationEntryErr);
        Assert.AreEqual(RowsNumber, ReservationEntry.Count, NumberOfRowsErr);

        ReservationEntry.SetRange("Source Type", Database::"Prod. Order Line");
        Assert.AreEqual(Exist, ReservationEntry.FindFirst(), ReservationEntryErr);
        Assert.AreEqual(RowsNumber, ReservationEntry.Count, NumberOfRowsErr);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; ExpectedReceiptDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Expected Receipt Date", ExpectedReceiptDate);
    end;

    local procedure VerifyReservationEntryDeleted(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    local procedure VerifyReservationEntryOfTrackingExist(ItemNo: Code[20]; ShipmentDate: Date; ShipmentDateExist: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Tracking);

        ReservationEntry.SetRange("Shipment Date", ShipmentDate);
        Assert.AreEqual(ShipmentDateExist, ReservationEntry.FindFirst(), ReservationEntryErr);
    end;

    local procedure VerifyReservedQuantity(ItemNo: Code[20]; ReservStatus: Enum "Reservation Status"; ExpectedQty: Decimal)
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
        Assert.AreEqual(DueDateExist, ProdOrderLine.FindFirst(), StrSubstNo(FirmPlannedProdOrderErr, DueDate));
    end;

    local procedure VerifySurplusReservationEntry(ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        with ReservationEntry do begin
            SetRange("Item No.", ItemNo);
            SetRange("Reservation Status", "Reservation Status"::Surplus);
            FindFirst();
            TestField(Quantity, ExpectedQuantity);
        end;
    end;

    local procedure VerifyTransferHeadersAndLinesCount(FromLocationCode: Code[10]; ToLocationCode: Code[10]; NoOfHeaders: Integer; NoOfLines: Integer)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        TransferHeader.SetRange("Transfer-from Code", FromLocationCode);
        TransferHeader.SetRange("Transfer-to Code", ToLocationCode);
        Assert.RecordCount(TransferHeader, NoOfHeaders);

        TransferLine.SetRange("Transfer-from Code", FromLocationCode);
        TransferLine.SetRange("Transfer-to Code", ToLocationCode);
        Assert.RecordCount(TransferLine, NoOfLines);
    end;

    local procedure UpdateRequisitionLine(var RequisitionLine: Record "Requisition Line"; ReqLineType: Enum "Requisition Line Type"; ItemNo: Code[20]; UoM: Code[10]; Quantity: Decimal)
    begin
        RequisitionLine.Validate(Type, ReqLineType);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Validate("Unit of Measure Code", UoM);
        RequisitionLine.Validate(Quantity, Quantity);
    end;

    local procedure SetupUoMTest(
        var Item: Record Item;
        var ItemUOM: Record "Item Unit of Measure";
        var BaseUOM: Record "Unit of Measure";
        var NonBaseUOM: Record "Unit of Measure";
        BaseQtyPerUOM: Decimal;
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);
    end;

    local procedure VerifyQtyOnReqLines(ParentItem: Record Item; var ChildItem: Record Item; ParentQty: Decimal; ChildQty: Decimal; MaxQty: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
        RefOrderNo: Code[20];
    begin
        RefOrderNo := '';
        FilterOnRequisitionLines(RequisitionLine, ChildItem."No.", ParentItem."No.");
        RequisitionLine.FindSet();
        repeat
            if RequisitionLine."No." = ParentItem."No." then
                RequisitionLine.TestField(Quantity, ParentQty);
            if RequisitionLine."No." = ChildItem."No." then
                if RefOrderNo = RequisitionLine."Ref. Order No." then
                    RequisitionLine.TestField(Quantity, ChildQty)
                else
                    RequisitionLine.TestField(Quantity, MaxQty);
            RefOrderNo := RequisitionLine."Ref. Order No.";
        until RequisitionLine.Next() = 0;
    end;

    local procedure VerifyQtyOnReqLines(ParentItem: Record Item; var ChildItem: Record Item; ParentQty: Decimal; ChildQty: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FilterOnRequisitionLines(RequisitionLine, ChildItem."No.", ParentItem."No.");
        RequisitionLine.FindSet();
        repeat
            if RequisitionLine."No." = ParentItem."No." then
                RequisitionLine.TestField(Quantity, ParentQty);
            if RequisitionLine."No." = ChildItem."No." then
                RequisitionLine.TestField(Quantity, ChildQty);
        until RequisitionLine.Next() = 0;
    end;

    local procedure VerifyQtyOnReqLines(ParentItem: array[2] of Record Item; var ChildItem: Record Item; Qty: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
        ItemNoFilter: Text;
    begin
        ItemNoFilter := ParentItem[1]."No." + '|' + ParentItem[2]."No." + '|' + ChildItem."No.";
        FilterOnRequisitionLines(RequisitionLine, ItemNoFilter);
        Assert.RecordCount(RequisitionLine, 4);
        RequisitionLine.FindSet();
        repeat
            if RequisitionLine."No." = ParentItem[1]."No." then
                RequisitionLine.TestField(Quantity, Qty);
            if RequisitionLine."No." = ParentItem[2]."No." then
                RequisitionLine.TestField(Quantity, Qty + 1);
            if RequisitionLine."No." = ChildItem."No." then
                RequisitionLine.TestField(Quantity, Qty);
        until RequisitionLine.Next() = 0;
    end;

    local procedure CreateAndPostItemJournal(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateManufacturingSetupComponentsAtLocation(NewComponentsAtLocation: Code[10])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Components at Location", NewComponentsAtLocation);
        ManufacturingSetup.Modify(true);
    end;

    local procedure CreateManufacturingItems(var ParentItem: Record Item; var ChildItem: Record Item; ReorderPoint: Decimal; MaxQty: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItem(ChildItem, ChildItem."Reordering Policy"::"Maximum Qty.", ChildItem."Replenishment System"::"Prod. Order");
        ChildItem.Validate("Manufacturing Policy", ChildItem."Manufacturing Policy"::"Make-to-Order");
        ChildItem.Validate("Reorder Point", ReorderPoint);
        ChildItem.Validate("Maximum Inventory", MaxQty);
        ChildItem.Modify(true);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");

        CreateItem(ParentItem, ParentItem."Reordering Policy"::"Lot-for-Lot", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Validate("Manufacturing Policy", ParentItem."Manufacturing Policy"::"Make-to-Order");
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
    end;

    local procedure CreateManufacturingItems(var ParentItem: Record Item; var ChildItem: Record Item; LotAccumulationPeriod: Text[30]; OrderMultiple: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        LotAccumulationPeriodDateFormula: DateFormula;
    begin
        CreateItem(ChildItem, ChildItem."Reordering Policy"::"Lot-for-Lot", ChildItem."Replenishment System"::"Prod. Order");
        ChildItem.Validate("Manufacturing Policy", ChildItem."Manufacturing Policy"::"Make-to-Order");
        Evaluate(LotAccumulationPeriodDateFormula, LotAccumulationPeriod);
        ChildItem.Validate("Lot Accumulation Period", LotAccumulationPeriodDateFormula);
        ChildItem.Validate("Order Multiple", OrderMultiple);
        ChildItem.Modify(true);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");

        CreateItem(ParentItem, ParentItem."Reordering Policy"::"Lot-for-Lot", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Validate("Manufacturing Policy", ParentItem."Manufacturing Policy"::"Make-to-Order");
        Evaluate(LotAccumulationPeriodDateFormula, LotAccumulationPeriod);
        ParentItem.Validate("Lot Accumulation Period", LotAccumulationPeriodDateFormula);
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
    end;

    local procedure CreateManufacturingItems(var ParentItem: array[2] of Record Item; var ChildItem: Record Item; LotAccumulationPeriod: Text[30])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        LotAccumulationPeriodDateFormula: DateFormula;
        i: Integer;
    begin
        CreateItem(ChildItem, ChildItem."Reordering Policy"::"Lot-for-Lot", ChildItem."Replenishment System"::"Prod. Order");
        ChildItem.Validate("Manufacturing Policy", ChildItem."Manufacturing Policy"::"Make-to-Order");
        Evaluate(LotAccumulationPeriodDateFormula, LotAccumulationPeriod);
        ChildItem.Validate("Lot Accumulation Period", LotAccumulationPeriodDateFormula);
        ChildItem.Modify(true);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");

        for i := 1 to ArrayLen(ParentItem) do begin
            CreateItem(ParentItem[i], ParentItem[i]."Reordering Policy"::"Lot-for-Lot", ParentItem[i]."Replenishment System"::"Prod. Order");
            if i = 1 then
                ParentItem[i].Validate("Manufacturing Policy", ParentItem[i]."Manufacturing Policy"::"Make-to-Order")
            else
                ParentItem[i].Validate("Manufacturing Policy", ParentItem[i]."Manufacturing Policy"::"Make-to-Stock");
            ParentItem[i].Validate("Production BOM No.", ProductionBOMHeader."No.");
            ParentItem[i].Modify(true);
        end;
    end;

    local procedure CreateRequisitionLineWithItemVariant(
        var RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Vendor: Record Vendor)
    begin
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate("Variant Code", ItemVariant.Code);
        RequisitionLine.Validate("Vendor No.", Vendor."No.");
        RequisitionLine.Validate(Quantity, LibraryRandom.RandInt(0));
        RequisitionLine.Modify(true);
    end;

    local procedure VerifyPrintedPurchaseOrders(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.FindSet();
        repeat
            LibraryReportDataset.AssertElementWithValueExists('No_PurchHeader', PurchaseHeader."No.");
            LibraryReportDataset.GetNextRow();
        until PurchaseHeader.Next() = 0;
    end;

    local procedure SetupReportSelections(ReportSelectionUsage: Enum "Report Selection Usage"; ReportId: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelectionUsage);
        ReportSelections.DeleteAll();

        ReportSelections.Init();
        ReportSelections.Validate(Usage, ReportSelectionUsage);
        ReportSelections.Validate(Sequence, LibraryRandom.RandText(2));
        ReportSelections.Validate("Report ID", ReportId);
        ReportSelections.Insert(true);
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
        CalculatePlanPlanWksh.StartingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.EndingDate.SetValue(GetRandomDateUsingWorkDate(90));
        CalculatePlanPlanWksh.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CalculatePlanPlanWkshRequestPageHandlerWithThreeItems(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    var
        ItemNo: Variant;
        ItemNo2: Variant;
        ItemNo3: Variant;
    begin
        // Calculate Regenerative Plan using page. Required where Forecast is used.
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(ItemNo2);
        LibraryVariableStorage.Dequeue(ItemNo3);
        CalculatePlanPlanWksh.Item.SetFilter("No.", StrSubstNo('%1|%2|%3', ItemNo, ItemNo2, ItemNo3));
        CalculatePlanPlanWksh.StartingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.EndingDate.SetValue(GetRandomDateUsingWorkDate(90));
        CalculatePlanPlanWksh.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanReqWkshRequestPageHandler(var CalculatePlanReqWksh: TestRequestPage "Calculate Plan - Req. Wksh.")
    begin
        CalculatePlanReqWksh.StartingDate.SetValue(LibraryVariableStorage.DequeueDate());
        CalculatePlanReqWksh.EndingDate.SetValue(LibraryVariableStorage.DequeueDate());
        CalculatePlanReqWksh.Item.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CalculatePlanReqWksh.Item.SetFilter("Location Filter", LibraryVariableStorage.DequeueText());
        CalculatePlanReqWksh.RespectPlanningParm.SetValue(LibraryVariableStorage.DequeueBoolean());
        CalculatePlanReqWksh.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationEntryPageHandler(var ReservationEntries: TestPage "Reservation Entries")
    begin
        LibraryVariableStorage.Enqueue(CancelReservationConfirmationMessageTxt);  // Required inside ConfirmHandler.
        ReservationEntries.CancelReservation.Invoke();
        ReservationEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
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

    [ReportHandler]
    procedure PurchaseOrderSaveAsXML(var StandardPurchaseOrder: Report "Standard Purchase - Order")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryReportDataset.RunReportAndLoad(Report::"Standard Purchase - Order", PurchaseHeader, '');
    end;
}
