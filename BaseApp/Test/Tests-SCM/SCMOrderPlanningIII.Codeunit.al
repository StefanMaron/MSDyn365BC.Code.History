codeunit 137088 "SCM Order Planning - III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM]
        IsInitialized := false;
    end;

    var
        LocationRed: Record Location;
        LocationBlue: Record Location;
        LocationBlue2: Record Location;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        VerifyOnGlobal: Option RequisitionLine,Orders;
        DemandTypeGlobal: Option Sales,Production;
        GlobalChildItemNo: Code[20];
        IsInitialized: Boolean;
        ValidationError: Label '%1  must be %2 in %3.';
        NoErrorText: Label 'No. must be equal to ''%1''  in Requisition Line: Worksheet Template Name=, Journal Batch Name=, Line No.';
        DateErrorText: Label 'Demand Date must be equal to ''%1''  in Requisition Line: Worksheet Template Name=, Journal Batch Name=, Line No.=';
        QuantityErrorText: Label 'Demand Quantity (Base) must be equal to ''%1''  in Requisition Line: Worksheet Template Name=, Journal Batch Name=, Line No.=';
        LocationErrorText: Label 'Location Code must be equal to ''%1''  in Requisition Line: Worksheet Template Name=, Journal Batch Name=, Line No.=';
        ErrorText: Label 'Error Message Must be same.';
        ExpectedQuantity: Decimal;
        QuantityError: Label 'Available Quantity must match.';
        OrderTrackingMessage: Label 'The change will not affect existing entries.';
        UnexpectedMessageDialog: Label 'Unexpected Message dialog.  %1';
        LineCountError: Label 'There should be '' %1 '' line(s) in the planning worksheet for item. ';
        ReserveError: Label 'Reserve must be equal to ''%1''  in Requisition Line';
        LineExistErr: Label 'Requistion line in %1 worksheet should exist for item %2';
        PurchaseLineQuantityBaseErr: Label '%1.%2 must be nearly equal to %3.', Comment = '%1 : Purchase Line, %2 : Quantity (Base), %3 : Value.';
        NoPurchOrderCreatedErr: Label 'No purchase orders are created.';

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderPlanningChangeItem()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        Item2: Record Item;
        ChildItem2: Record Item;
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning.
        Initialize;
        CreateManufacturingSetup(ParentItem, ChildItem, false, ChildItem."Order Tracking Policy"::None);
        CreateProdItem(Item2, ChildItem2);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2) +
          10);
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Change Source No in Production Order.
        ChangeDataOnProductionOrderAndRefresh(ProductionOrder, ProductionOrder.FieldNo("Source No."), Item2."No.");

        // Exercise: Run Make Supply Order.
        asserterror MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Check that error message is same as accepted during make order when change Production Order Item No. after calculate plan.
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(NoErrorText, ChildItem2."No.")) > 0, GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderPlanningChangeLocation()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning.
        Initialize;
        CreateManufacturingSetup(ParentItem, ChildItem, false, ChildItem."Order Tracking Policy"::None);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2));
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        FindRequisitionLine(RequisitionLine, ProductionOrder."No.", ChildItem."No.", LocationRed.Code);

        // Change Location On Production Order.
        ChangeDataOnProductionOrderAndRefresh(ProductionOrder, ProductionOrder.FieldNo("Location Code"), LocationBlue.Code);

        // Exercise: Run Make Supply Order.
        asserterror MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Check that error message is same as accepted during make order when change Production Order Location Code after calculate plan.
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(LocationErrorText, LocationBlue.Code)) > 0, GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderPlanningChangeQty()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning.
        Initialize;
        CreateManufacturingSetup(ParentItem, ChildItem, false, ChildItem."Order Tracking Policy"::None);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, Quantity);
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Change Source No in Production Order.
        ChangeDataOnProductionOrderAndRefresh(
          ProductionOrder, ProductionOrder.FieldNo(Quantity), Quantity + LibraryRandom.RandDec(10, 2));
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder."No.", ChildItem."No.");
        Quantity2 := ProdOrderComponent."Remaining Quantity";

        // Exercise: Run Make Supply Order.
        asserterror MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Check that error message is same as accepted during make order when change Production Order Quantity after calculate plan.
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(QuantityErrorText, Quantity2)) > 0, GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderPlanningChangeDemandDate()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning.
        Initialize;
        CreateManufacturingSetup(ParentItem, ChildItem, false, ChildItem."Order Tracking Policy"::None);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2) +
          10);
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Change Source No in Production Order.
        ProductionOrder.Find;
        ProductionOrder.SetUpdateEndDate;
        ProductionOrder.Validate("Due Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate));
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Exercise: Run Make Supply Order.
        asserterror MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Check that error message is same as accepted during make order when change Production Order Due Date after calculate plan.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(DateErrorText, ProductionOrder."Due Date" - 1)) > 0, GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('OrderTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PlanningForOrderTracking()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        OrderPlanning: TestPage "Order Planning";
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning.
        Initialize;
        CreateManufacturingSetup(ParentItem, ChildItem, false, ChildItem."Order Tracking Policy"::"Tracking Only");
        GlobalChildItemNo := ChildItem."No.";
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2) +
          10);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder."No.", ChildItem."No.");
        ExpectedQuantity := ProdOrderComponent."Remaining Quantity";
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Exercise And Verify : Open Order Tracking Page and Verification is done by Handler Method. Check That Order Tracking Line Create As expected.
        OpenOrderPlanningPage(OrderPlanning, ProductionOrder."No.", ChildItem."No.");
        OrderPlanning.OrderTracking.Invoke;
        OrderPlanning.Close;
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler,OrderTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderAndCheckOrderTrackingInPurchOrder()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseOrderNo: Code[20];
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning.
        Initialize;
        CreateManufacturingSetup(ParentItem, ChildItem, false, ChildItem."Order Tracking Policy"::"Tracking Only");
        GlobalChildItemNo := ChildItem."No.";
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2) +
          10);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder."No.", ChildItem."No.");
        ExpectedQuantity := ProdOrderComponent."Remaining Quantity";
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        PurchaseOrderNo := FindPurchaseOrderNo;

        // Exercise.
        MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Verification is done by Handler Method. Check That Order Tracking Line Create As expected when make order from Order Planning Page.
        LibraryPurchase.DisableWarningOnCloseUnpostedDoc;
        LibraryPurchase.DisableWarningOnCloseUnreleasedDoc;
        PurchaseOrder.OpenView;
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseOrderNo);
        PurchaseOrder.PurchLines.OrderTracking.Invoke;
        PurchaseOrder.Close;
    end;

    [Test]
    [HandlerFunctions('PlanningComponentPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningForProdOrderPlanningComponent()
    begin
        Initialize;
        PlanningForProductionOrder(false)
    end;

    [Test]
    [HandlerFunctions('PlanningRoutingPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningForProdOrderPlanningRouting()
    begin
        Initialize;
        PlanningForProductionOrder(true)
    end;

    local procedure PlanningForProductionOrder(PlanningRouting: Boolean)
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        OrderPlanning: TestPage "Order Planning";
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning.
        CreateManufacturingSetup(ParentItem, ChildItem, true, ChildItem."Order Tracking Policy"::None);
        GlobalChildItemNo := ChildItem."No.";
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2));
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        OpenOrderPlanningPage(OrderPlanning, ProductionOrder."No.", ChildItem."No.");

        // Exercise And Verify.
        if PlanningRouting then
            // Exercise And Verify : Open Planning Routing and Verification is done by Handler Method. Check That Planning Routing is same as Routing on child item.
            OrderPlanning."Ro&uting".Invoke
        else
            // Exercise And Verify : Open Planning Component and Verification is done by Handler Method. Check That Planning Component is same as component on child item.
            OrderPlanning.Components.Invoke;
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ChangePlanningComponentAndMakeOrder()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        Item: Record Item;
        PlanningComponent: Record "Planning Component";
        QuantityPer: Decimal;
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning and Add Planning Component.
        Initialize;
        CreateManufacturingSetup(ParentItem, ChildItem, true, ChildItem."Order Tracking Policy"::None);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2));  // Random value is Important For test.
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        FindRequisitionLine(RequisitionLine, ProductionOrder."No.", ChildItem."No.", LocationRed.Code);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        QuantityPer := LibraryRandom.RandDec(10, 2);
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        UpdatePlanningComponent(PlanningComponent, Item."No.", Item."Base Unit of Measure", QuantityPer);

        // Exercise.
        MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Check That Production Order Component is Created with the added component in Order Planning Page.
        VerifyProdOrderComponent(Item."No.", Item."Base Unit of Measure", QuantityPer);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ChangePlanningRoutingAndMakeOrder()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenter: Record "Work Center";
        OperationNo: Code[10];
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning and Add Planning Routing.
        Initialize;
        CreateManufacturingSetup(ParentItem, ChildItem, true, ChildItem."Order Tracking Policy"::None);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2));
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        FindRequisitionLine(RequisitionLine, ProductionOrder."No.", ChildItem."No.", LocationRed.Code);
        CreateWorkCenter(WorkCenter);
        OperationNo := FindLastOperationNo(ChildItem."Routing No.") + Format(LibraryRandom.RandInt(5));
        LibraryPlanning.CreatePlanningRoutingLine(PlanningRoutingLine, RequisitionLine, OperationNo);
        UpdatePlanningRoutingLine(
          PlanningRoutingLine, WorkCenter."No.", FindLastOperationNo(ChildItem."Routing No."), LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2));  // Random Value Required.

        // Exercise.
        MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Check That Production Order Routing Line is Created with the added Routing Line in Order Planning Page.
        VerifyProdOrderRoutingLine(PlanningRoutingLine, ChildItem."Routing No.", OperationNo);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticOnProductionOrderWithPlanning()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        ProductionOrderStatistics: TestPage "Production Order Statistics";
        FirmPlannedProdOrders: TestPage "Firm Planned Prod. Orders";
        ProductionOrderStatistics2: TestPage "Production Order Statistics";
        FirmPlannedProdOrders2: TestPage "Firm Planned Prod. Orders";
        ProductionOrderNo: Code[20];
    begin
        // [FEATURE] [Manufacturing]
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning ,Make Order and Open Production Order Statistics.
        Initialize;

        LibraryApplicationArea.EnablePremiumSetup;

        CreateManufacturingSetup(ParentItem, ChildItem, true, ChildItem."Order Tracking Policy"::None);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2));
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        FindRequisitionLine(RequisitionLine, ProductionOrder."No.", ChildItem."No.", LocationRed.Code);
        MakeSupplyOrdersActiveOrder(ProductionOrder."No.");
        ProductionOrderNo := FindProductionOrderNo(ChildItem."No.");
        OpenFirmPlannedProductionOrder(FirmPlannedProdOrders, ProductionOrderStatistics, ChildItem."No.", ProductionOrderNo);

        // Exercise : Create Firm Planned Production Order and Open Production Order Statistics.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ChildItem."No.", LocationRed.Code, RequisitionLine.Quantity);
        OpenFirmPlannedProductionOrder(FirmPlannedProdOrders2, ProductionOrderStatistics2, ChildItem."No.", ProductionOrder."No.");

        // Verify : Check Production Order Statistic on Firm Planned Prod. Order created from Make Order with Production Order Statistic on Firm Planned Production Order Created Directly.
        VerifyProductionOrderStatistics(ProductionOrderStatistics, ProductionOrderStatistics2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDimensionOnOrderPlanning()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup : Create Item with Dimension, Create Sales  Order.
        Initialize;
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        CreateDimensionWithValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        CreateSalesOrder(SalesHeader, Item."No.", '', LibraryRandom.RandDec(10, 2) + 10, LibraryRandom.RandDec(10, 2));  // Random Value Required.

        // Exercise : Run  Calculate Order Planning.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify : Check That Dimension on Sales Order Item Line is same as Dimension on Item.
        FindRequisitionLine(RequisitionLine, SalesHeader."No.", Item."No.", '');
        VerifyDimensionSetEntry(DimensionValue."Dimension Code", DimensionValue.Code, RequisitionLine."Dimension Set ID");

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderCheckDimensionOnPurchOrder()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderNo: Code[20];
    begin
        // Setup : Create Item with Dimension and Replenishment System Purchase, Create Sales  Order and Calculate Plan.
        Initialize;
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        CreateDimensionWithValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        CreateSalesOrder(SalesHeader, Item."No.", '', LibraryRandom.RandDec(10, 2) + 10, LibraryRandom.RandDec(10, 2));  // Random Value Required.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        PurchaseOrderNo := FindPurchaseOrderNo;

        // Exercise : Make Order for Active Order.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify : Check That Dimension On Purchase Line Created From Make Order is same as dimension on Item.
        FindPurchaseLine(PurchaseLine, PurchaseOrderNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst;
        VerifyDimensionSetEntry(DimensionValue."Dimension Code", DimensionValue.Code, PurchaseLine."Dimension Set ID");

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderCheckDimensionOnProductionOrder()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
    begin
        // Setup : Create Item with Dimension and Replenishment System Production Order, Create Sales  Order and Calculate Plan.
        Initialize;
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateProdItem(Item, ChildItem);
        CreateDimensionWithValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        CreateSalesOrder(SalesHeader, Item."No.", '', LibraryRandom.RandDec(10, 2) + 10, LibraryRandom.RandDec(10, 2));  // Random Value Required.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Exercise : Make Order for Active Order.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify : Check that Dimension On Production Order Created From Make Order is same as dimension on Item.
        ProductionOrderNo := FindProductionOrderNo(Item."No.");
        ProductionOrder.Get(ProductionOrder.Status::"Firm Planned", ProductionOrderNo);
        VerifyDimensionSetEntry(DimensionValue."Dimension Code", DimensionValue.Code, ProductionOrder."Dimension Set ID");

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReserveSalesPlanningNever()
    var
        Item: Record Item;
    begin
        // Check that Reserve is False While we create item with Reserve Never for Sales Order.
        Initialize;
        ReserveSalesOrderPlanning(Item.Reserve::Never, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReserveSalesPlanningAlways()
    var
        Item: Record Item;
    begin
        // Check that Reserve is TRUE While we create item with Reserve Always for Sales Order.
        Initialize;
        ReserveSalesOrderPlanning(Item.Reserve::Always, false);
    end;

    local procedure ReserveSalesOrderPlanning(ReserveOnItem: Option; ReserveOnRequistition: Boolean)
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Setup: Create Item with Reserve and Create Sales Order.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        UpdateItem(Item, ReserveOnItem, Item."Order Tracking Policy"::None);
        CreateSalesOrder(
          SalesHeader, Item."No.", LocationBlue.Code, LibraryRandom.RandDec(10, 2) + 10, LibraryRandom.RandDec(10, 2));  // Random Value Required.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Exercise.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify : Check that Reserve is TRUE OR False While we create child item Reserve Always and Never for Sales Order.
        FindRequisitionLine(RequisitionLine, SalesHeader."No.", Item."No.", LocationBlue.Code);
        asserterror RequisitionLine.Validate(Reserve, ReserveOnRequistition);
        if ReserveOnRequistition then
            Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(ReserveError, false)) > 0, ErrorText)
        else
            Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(ReserveError, true)) > 0, ErrorText);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderPlanAlwaysMakeOrder()
    var
        ChildItem: Record Item;
    begin
        // Check That Reservation Entry Created after Make Supply Order for Sales Order when Child Item Reserve is Always.
        Initialize;
        ReserveSalesOrderPlanMakeOrder(ChildItem.Reserve::Always);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderPlanNeverMakeOrder()
    var
        ChildItem: Record Item;
    begin
        // Check That Reservation Entry not Created after Make Supply Order for Sales Order when Child Item Reserve is Never.
        Initialize;
        ReserveSalesOrderPlanMakeOrder(ChildItem.Reserve::Never);
    end;

    local procedure ReserveSalesOrderPlanMakeOrder(ReserveOnItem: Option)
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
    begin
        // Setup : Create Item With Reservation Option and Create Sales Order.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        UpdateItem(Item, ReserveOnItem, Item."Order Tracking Policy"::None);
        Quantity := LibraryRandom.RandDec(20, 2);  // Random Value Required.
        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue.Code, Quantity, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        FindRequisitionLine(RequisitionLine, SalesHeader."No.", Item."No.", LocationBlue.Code);

        // Exercise : Run Make order from Order Planning.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify : Check That Reservation Entry Created after Make Supply Order.
        if ReserveOnItem = ChildItem.Reserve::Always then begin
            ReservationEntry.SetRange("Item No.", Item."No.");
            ReservationEntry.SetRange("Source Type", 39);  // Value important as it signifies Purchase Line Table ID.
            ReservationEntry.FindFirst;
            Assert.AreEqual(
              Quantity, ReservationEntry.Quantity,
              StrSubstNo(ValidationError, ReservationEntry.FieldCaption(Quantity), Quantity, ReservationEntry.TableCaption));
        end else begin
            // Verify : Check That Reservation Entry Not Created after Make Supply Order.
            ReservationEntry.SetRange("Item No.", Item."No.");
            asserterror ReservationEntry.FindFirst;
        end;

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveProdOrderPlanCopyToReqAlways()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries created when creating Purchase REQ Requisition Lines from Production Order Planning
        // if Item.Reserve is Always and Item."Reordering Policy" is Order
        ReserveProdOrderPlanCopyToReq(Item.Reserve::Always, Item."Reordering Policy"::Order,
          RequisitionLine."Replenishment System"::Purchase, ReqWkshTemplate.Type::"Req.");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveProdOrderPlanCopyToReqNever()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries NOT created when creating Purchase REQ Requisition Lines from Production Order Planning
        // if Item.Reserve is Never and Item."Reordering Policy" is Order
        ReserveProdOrderPlanCopyToReq(Item.Reserve::Never, Item."Reordering Policy"::Order,
          RequisitionLine."Replenishment System"::Purchase, ReqWkshTemplate.Type::"Req.");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveProdOrderPlanCopyToReqOptional1()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries created when creating Prod. Order PLANNING Requisition Lines from Production Order Planning
        // if Item.Reserve is Optional, Reserve field in Order Planning requisition line is TRUE and Item."Reordering Policy" is Fixed Reorder Qty.
        ReserveProdOrderPlanCopyToReq(Item.Reserve::Optional, Item."Reordering Policy"::"Fixed Reorder Qty.",
          RequisitionLine."Replenishment System"::"Prod. Order", ReqWkshTemplate.Type::Planning);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveProdOrderPlanCopyToReqOptional2()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries created when creating Transfer REQ Requisition Lines from Production Order Planning
        // if Item.Reserve is Optional, Reserve field in Order Planning requisition line is TRUE and Item."Reordering Policy" is Maximum Qty.
        ReserveProdOrderPlanCopyToReq(Item.Reserve::Optional, Item."Reordering Policy"::"Maximum Qty.",
          RequisitionLine."Replenishment System"::Transfer, ReqWkshTemplate.Type::"Req.");
    end;

    local procedure ReserveProdOrderPlanCopyToReq(Reserve: Option; ReorderingPolicy: Option; ReplenishmentSystem: Option; ReqWkshTemplateType: Option)
    var
        Item: Record Item;
        ProdItem: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        RequisitionLine: Record "Requisition Line";
        ProdOrder: Record "Production Order";
        ReservationEntry: Record "Reservation Entry";
        ReqWkshTemplateName: Code[10];
        ReqWkshName: Code[10];
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        // Setup : Create Production Order and Calculate Plan
        Initialize;
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        UpdateItemEx(Item, Reserve, ReorderingPolicy);

        QtyPer := LibraryRandom.RandIntInRange(10, 20);
        CreateItemWithProductionBOM(ProdItem, Item, '', QtyPer);
        Qty := LibraryRandom.RandIntInRange(10, 20);
        CreateAndRefreshProdOrder(ProdOrder, ProdOrder.Status::Released, ProdItem."No.", '', Qty);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComponent.SetRange("Item No.", Item."No.");
        ProdOrderComponent.FindFirst;
        ProdOrderComponent.Validate("Location Code", LocationBlue.Code);
        ProdOrderComponent.Modify(true);
        ProdOrder.Get(ProdOrder.Status::Released, ProdOrder."No.");
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        FindRequisitionLine(RequisitionLine, ProdOrder."No.", Item."No.", LocationBlue.Code);
        if ReplenishmentSystem <> Item."Replenishment System"::Purchase then
            ModifyRequisitionLine(RequisitionLine, Item.Reserve, ReplenishmentSystem);

        ReqWkshTemplateName := GetReqWkshTemplateName(ReqWkshTemplateType);
        ReqWkshName := GetReqWkshName(ReqWkshTemplateName, ReqWkshTemplateType);

        // Exercise : Run Make order from Order Planning.
        MakeSupplyOrdersCopyToWkshActiveOrder(ProdOrder."No.", ReqWkshTemplateName, ReqWkshName);

        // Verify : Check That Reservation Entry Created after Make Supply Order.
        // 246 indicates reserved from requisition line
        VerifyReservationEntry(RequisitionLine, Item."No.", ReqWkshTemplateName, ReqWkshName, 246, Qty * QtyPer);
        VerifyRequisitionLine(Item."No.", ReqWkshTemplateName, ReqWkshName);

        // Tear Down
        ReservationEntry.SetRange("Item No.", Item."No.");
        if ReservationEntry.FindSet then
            repeat
                ReservationEntry.Delete;
            until ReservationEntry.Next = 0;
        ProdOrder.Delete;
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComponent.FindFirst;
        ProdOrderComponent.Delete;
        ProdBOMLine.SetRange("Production BOM No.", ProdItem."Production BOM No.");
        ProdBOMLine.FindFirst;
        ProdBOMLine.Delete;

        ProdBOMHeader.SetRange("No.", ProdItem."Production BOM No.");
        ProdBOMHeader.FindFirst;
        ProdBOMHeader.Delete;
        ProdItem.Delete;
        Item.Delete;
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderPlanCopyToReqAlways()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries created when creating Purchase REQ Requisition Lines from Sales Order Planning
        // if Item.Reserve is Always and Item."Reordering Policy" is Order
        ReserveSalesOrderPlanCopyToReq(Item.Reserve::Always, Item."Reordering Policy"::Order,
          RequisitionLine."Replenishment System"::Purchase, ReqWkshTemplate.Type::"Req.");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderPlanCopyToReqNever()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries NOT created when creating Purchase REQ Requisition Lines from Sales Order Planning
        // if Item.Reserve is Never and Item."Reordering Policy" is Order
        ReserveSalesOrderPlanCopyToReq(Item.Reserve::Never, Item."Reordering Policy"::Order,
          RequisitionLine."Replenishment System"::Purchase, ReqWkshTemplate.Type::"Req.");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderPlanCopyToReqOptional1()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries created when creating Prod. Order PLANNING Requisition Lines from Sales Order Planning
        // if Item.Reserve is Optional, Reserve field in Order Planning requisition line is TRUE and Item."Reordering Policy" is Fixed Reorder Qty.
        ReserveSalesOrderPlanCopyToReq(Item.Reserve::Optional, Item."Reordering Policy"::"Fixed Reorder Qty.",
          RequisitionLine."Replenishment System"::"Prod. Order", ReqWkshTemplate.Type::Planning);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderPlanCopyToReqOptional2()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries created when creating Transfer REQ Requisition Lines from Sales Order Planning
        // if Item.Reserve is Optional, Reserve field in Order Planning requisition line is TRUE and Item."Reordering Policy" is Lot-for-Lot.
        ReserveSalesOrderPlanCopyToReq(Item.Reserve::Optional, Item."Reordering Policy"::"Lot-for-Lot",
          RequisitionLine."Replenishment System"::Transfer, ReqWkshTemplate.Type::"Req.");
    end;

    local procedure ReserveSalesOrderPlanCopyToReq(Reserve: Option; ReorderingPolicy: Option; ReplenishmentSystem: Option; ReqWkshTemplateType: Option)
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        ReqWkshTemplateName: Code[10];
        ReqWkshName: Code[10];
        Quantity: Decimal;
    begin
        // Setup : Create Sales Order and Calculate Plan
        Initialize;
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        UpdateItemEx(Item, Reserve, ReorderingPolicy);
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue.Code, Quantity, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        FindRequisitionLine(RequisitionLine, SalesHeader."No.", Item."No.", LocationBlue.Code);
        if ReplenishmentSystem <> Item."Replenishment System"::Purchase then
            ModifyRequisitionLine(RequisitionLine, Item.Reserve, ReplenishmentSystem);

        ReqWkshTemplateName := GetReqWkshTemplateName(ReqWkshTemplateType);
        ReqWkshName := GetReqWkshName(ReqWkshTemplateName, ReqWkshTemplateType);

        // Exercise : Run Make order from Order Planning.
        MakeSupplyOrdersCopyToWkshActiveOrder(SalesHeader."No.", ReqWkshTemplateName, ReqWkshName);

        // Verify : Check That Reservation Entry Created after Make Supply Order.
        // 246 indicates reserved from requisition line
        VerifyReservationEntry(RequisitionLine, Item."No.", ReqWkshTemplateName, ReqWkshName, 246, Quantity);
        VerifyRequisitionLine(Item."No.", ReqWkshTemplateName, ReqWkshName);

        // Tear Down
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
        ReservationEntry.SetRange("Item No.", Item."No.");
        if ReservationEntry.FindSet then
            repeat
                ReservationEntry.Delete;
            until ReservationEntry.Next = 0;
        SalesHeader.Delete;
        SalesLine.SetRange("No.", Item."No.");
        SalesLine.FindFirst;
        SalesLine.Delete;
        Item.Delete;
    end;

    local procedure VerifyReservationEntry(RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; SourceID: Code[10]; SourceBatchName: Code[10]; SourceType: Integer; Qty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if RequisitionLine.Reserve then begin
            ReservationEntry.SetRange("Item No.", ItemNo);
            ReservationEntry.SetRange("Source ID", SourceID);
            ReservationEntry.SetRange("Source Type", SourceType);
            ReservationEntry.SetRange("Source Batch Name", SourceBatchName);
            ReservationEntry.FindFirst;

            Assert.AreEqual(
              Qty, ReservationEntry.Quantity,
              StrSubstNo(ValidationError, ReservationEntry.FieldCaption(Quantity), Qty, ReservationEntry.TableCaption));
        end else begin
            // Verify : Check That Reservation Entry Not Created after Make Supply Order.
            ReservationEntry.SetRange("Item No.", ItemNo);
            asserterror ReservationEntry.FindFirst;
        end;
    end;

    local procedure VerifyRequisitionLine(ItemNo: Code[20]; WkshTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Worksheet Template Name", WkshTemplateName);
        RequisitionLine.SetRange("Journal Batch Name", JournalBatchName);
        RequisitionLine.SetRange("No.", ItemNo);
        Assert.IsTrue(RequisitionLine.FindFirst, StrSubstNo(LineExistErr, WkshTemplateName, ItemNo));
    end;

    local procedure ModifyRequisitionLine(var RequisitionLine: Record "Requisition Line"; Reserve: Option; ReplenishmentSystem: Option)
    var
        Item: Record Item;
    begin
        if Reserve = Item.Reserve::Optional then
            RequisitionLine.Reserve := true;
        RequisitionLine.Validate("Replenishment System", ReplenishmentSystem);
        if ReplenishmentSystem = RequisitionLine."Replenishment System"::Transfer then
            RequisitionLine.Validate("Supply From", LocationRed.Code);
        RequisitionLine.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeReplenishmentToPurchAndCheckComponent()
    var
        Item: Record Item;
    begin
        // Check That Planning Component and Planning Routing Line created after change replenishment to Production Order.
        Initialize;
        ChangeReplenishmentAndCheckComponent(Item."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeReplenishmentToProdAndCheckComponent()
    var
        Item: Record Item;
    begin
        // Check That Planning Component and Planning Routing Line Delete after change replenishment to Purchase Order.
        Initialize;
        ChangeReplenishmentAndCheckComponent(Item."Replenishment System"::Purchase);
    end;

    local procedure ChangeReplenishmentAndCheckComponent(ReplenishmentSystem: Option)
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        PlanningRoutingLine: Record "Planning Routing Line";
        ItemVendor: Record "Item Vendor";
        Quantity: Decimal;
    begin
        // Setup : Create Item With Reservation Option and Create Sales Order.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateManufacturingSetup(Item, ChildItem, true, ChildItem."Order Tracking Policy"::None);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);

        Quantity := LibraryRandom.RandDec(10, 2);  // Random Value Required.

        LibraryInventory.CreateItemVendor(ItemVendor, LibraryPurchase.CreateVendorNo, Item."No.");

        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue.Code, Quantity, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        FindRequisitionLine(RequisitionLine, SalesHeader."No.", Item."No.", LocationBlue.Code);

        if ReplenishmentSystem = Item."Replenishment System"::Purchase then begin
            ChangeReplenishmentSystem(
              RequisitionLine, ReplenishmentSystem, Item."Replenishment System"::"Prod. Order", SalesHeader."No.", ItemVendor."Vendor No.");

            // Verify : Check That Planning Component and Planning Routing Line created after change replenishment to Production Order.
            FindPlanningComponent(PlanningComponent, RequisitionLine);
            FindPlanningRoutingLine(PlanningRoutingLine, RequisitionLine);
        end else begin
            ChangeReplenishmentSystem(
              RequisitionLine, ReplenishmentSystem, Item."Replenishment System"::Purchase, SalesHeader."No.", ItemVendor."Vendor No.");

            // Verify : Check That Planning Component and Planning Routing Line Delete after change replenishment to Purchase Order.
            FindPlanningRoutingLine(PlanningRoutingLine, RequisitionLine);
            Assert.AreEqual(0, PlanningRoutingLine.Count, StrSubstNo(LineCountError, 0));
            FindPlanningComponent(PlanningComponent, RequisitionLine);
            Assert.AreEqual(0, PlanningComponent.Count, StrSubstNo(LineCountError, 0));
        end;

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningSalesOrderWithItemVariant()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ItemVariant: Record "Item Variant";
    begin
        // Setup : Create Item, Item Variant, Sale Order And Calculate Plan.
        Initialize;
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreateSalesOrder(
          SalesHeader, Item."No.", LocationBlue.Code, LibraryRandom.RandDec(10, 2) + 10, LibraryRandom.RandDec(10, 2));  // Random Value Required.
        ChangeDataOnSalesLine(SalesHeader, Item."No.", SalesLine.FieldNo("Variant Code"), ItemVariant.Code);

        // Exercise : Calculate Plan.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify : Check That Item Variant code on Order Planning Line is same as on Sales Line.
        FindRequisitionLine(RequisitionLine, SalesHeader."No.", Item."No.", LocationBlue.Code);
        RequisitionLine.TestField("Variant Code", ItemVariant.Code);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderPurchaseItemWithVariant()
    var
        Item: Record Item;
    begin
        // Check That Purchase Line Created form Make Order have same Variant Cade as on Sales Line.
        Initialize;
        MakeOrderWithItemVariant(Item."Replenishment System"::Purchase);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderProductionItemWithVariant()
    var
        Item: Record Item;
    begin
        // Check That Production Order Line Created form Make Order have same Variant Cade as on Sales Line.
        Initialize;
        MakeOrderWithItemVariant(Item."Replenishment System"::"Prod. Order");
    end;

    local procedure MakeOrderWithItemVariant(ReplenishmentSystem: Option)
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ItemVariant: Record "Item Variant";
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup : Create Item, Item Variant, Sale Order And Calculate Plan.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, ReplenishmentSystem, '', '');
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreateSalesOrder(SalesHeader, Item."No.", '', LibraryRandom.RandDec(10, 2) + 10, LibraryRandom.RandDec(10, 2));  // Random Value Required.
        ChangeDataOnSalesLine(SalesHeader, Item."No.", SalesLine.FieldNo("Variant Code"), ItemVariant.Code);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Exercise : Make Order for Active Order.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        if ReplenishmentSystem = Item."Replenishment System"::Purchase then begin
            // Verify : Check That Purchase Line Created form Make Order have same Variant Cade as on Sales Line.
            PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
            PurchaseLine.SetRange("No.", Item."No.");
            PurchaseLine.FindFirst;
            PurchaseLine.TestField("Variant Code", ItemVariant.Code);
        end else begin
            // Verify : Check That Production Order Line Created form Make Order have same Variant Cade as on Sales Line.
            ProdOrderLine.SetRange("Item No.", Item."No.");
            ProdOrderLine.FindFirst;
            ProdOrderLine.TestField("Variant Code", ItemVariant.Code);
        end;

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeQuantityAndCalculatePlan()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        OrderPlanning: TestPage "Order Planning";
        OrderPlanning2: TestPage "Order Planning";
        Quantity: Decimal;
    begin
        // Setup : Create Item ,Sale order and Calculate Plan and Open Order Planning Page ,Change Quantity To Order close Order Planning Page and Calculate Plan.
        Initialize;
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue2.Code, Quantity, Quantity);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        ChangeQuantityOnPlanning(OrderPlanning, SalesHeader."No.", Item."No.", Quantity + LibraryRandom.RandDec(10, 2));  // Random Value Required.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Exercise : Open Order Planning Page.
        OpenOrderPlanningPage(OrderPlanning2, SalesHeader."No.", Item."No.");

        // Verify : Check the value of Quantity To Order is Change to Previous State after calculate Plan.
        OrderPlanning2.Quantity.AssertEquals(Quantity);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseSpecialOrderUpdateCurrencyRetainsTheSameUnitOfMeasure()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Purchasing: Record Purchasing;
    begin
        // [FEATURE] [Unit of Measure] [Special Order]
        // [SCENARIO 207135] Updating of "Currency Code" in the Header of Purchase Order related with Sales Order with Special Order "Purchasing Code" retains the same "Unit of Measure Code" = Item."Purch. Unit of Measure" as it was created during Carry Ou
        Initialize;

        // [GIVEN] Item "I" with "Vendor No." and "Purch. Unit of Measure";
        CreateItemWithVendorNoAndPurchUnitOfMeasure(Item);

        // [GIVEN] Sales Order "SO" with single line "SL" for "I" with Special Order "Purchasing Code"
        LibraryPurchase.CreateSpecialOrderPurchasingCode(Purchasing);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", Purchasing.Code);

        // [GIVEN] Get special order and carry out for "I", Purchase Order "PO" with line "PL" is created;
        GetPurchaseSpecialOrderAtWorkdateByItemNo(PurchaseHeader, PurchaseLine, Item."No.");

        // [WHEN] Update Currency Code for "PO" through the Header
        UpdatePurchaseHeaderCurrencyCode(PurchaseHeader);

        // [THEN] "PL"."Unit of Measure Code" = "I"."Purch. Unit of Measure", "PL"."Quantity (Base)" = "SL"."Quantity (Base)"
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine.FindFirst;  // Cannot use GET because one of the key fields "Line No." could be changed while line recreation
        VerifyPurchaseLineUnitOfMeasureCodeAndQuantityBase(
          PurchaseLine, Item."Purch. Unit of Measure", SalesLine."Quantity (Base)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseDropShipmentUpdateCurrencyRetainsTheSameUnitOfMeasure()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Purchasing: Record Purchasing;
    begin
        // [FEATURE] [Unit of Measure] [Special Order]
        // [SCENARIO 207135] Updating of "Currency Code" in the Header of Purchase Order related with Sales Order with Drop Shipment "Purchasing Code" retains the same "Unit of Measure Code" = Item."Purch. Unit of Measure" as it was created during Carry Ou
        Initialize;

        // [GIVEN] Item "I" with "Vendor No." and "Purch. Unit of Measure";
        CreateItemWithVendorNoAndPurchUnitOfMeasure(Item);

        // [GIVEN] Sales Order "SO" with single line "SL" for "I" with Special Order "Purchasing Code"
        LibraryPurchase.CreateDropShipmentPurchasingCode(Purchasing);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", Purchasing.Code);

        // [GIVEN] Get drop shipment and carry out for "I", Purchase Order "PO" with line "PL" is created;
        GetPurchaseDropShipmentAtWorkdateByItemNo(PurchaseHeader, PurchaseLine, SalesLine);

        // [WHEN] Update Currency Code for "PO" through the Header
        UpdatePurchaseHeaderCurrencyCode(PurchaseHeader);

        // [THEN] "PL"."Unit of Measure Code" = "I"."Purch. Unit of Measure", "PL"."Quantity (Base)" = "SL"."Quantity (Base)"
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine.FindFirst;  // Cannot use GET because one of the key fields "Line No." could be changed while line recreation
        VerifyPurchaseLineUnitOfMeasureCodeAndQuantityBase(
          PurchaseLine, SalesLine."Unit of Measure Code", SalesLine."Quantity (Base)");
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure DeletePlanningLinesIfMakingPurchaseFromSalesIsDeclinedByUser()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReqLine: Record "Requisition Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales] [Purchase] [Order]
        // [SCENARIO 287131] Delete planning lines generated by "Purchase Order from Sales Order" functionality, if a user does not confirm creating a new purchase order.
        Initialize;

        // [GIVEN] Sales order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo,
          LibraryInventory.CreateItemNo, LibraryRandom.RandIntInRange(100, 200), '', WorkDate);

        // [WHEN] Run "Create Purchase Order" on sales order page, but do not confirm making a new purchase order.
        LibraryVariableStorage.Enqueue(false);
        SalesOrder.OpenEdit;
        SalesOrder.GotoKey(SalesHeader."Document Type", SalesHeader."No.");
        SalesOrder.CreatePurchaseOrder.Invoke;

        // [THEN] Requisition lines that were created during planning are deleted.
        ReqLine.SetRange("Worksheet Template Name", '');
        ReqLine.SetRange("User ID", UserId);
        Assert.RecordIsEmpty(ReqLine);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure CanCreatePurchaseOrderFromSalesForNonInventoryItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Sales] [Purchase] [Order] [Non-Inventory Item]
        // [SCENARIO 315342] A user can create purchase order from a sales order with non-inventory item.
        Initialize;

        LibraryInventory.CreateNonInventoryTypeItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo);
        Item.Modify(true);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), '', WorkDate);

        LibraryVariableStorage.Enqueue(true);
        PurchaseOrder.Trap;
        SalesOrder.OpenEdit;
        SalesOrder.GotoKey(SalesHeader."Document Type", SalesHeader."No.");
        SalesOrder.CreatePurchaseOrder.Invoke;

        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseHeader.TestField("Buy-from Vendor No.", Item."Vendor No.");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderWithVendorNoModalPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningLinesByAnotherUserAreNotConsideredInOrderPlanning()
    var
        Item: Record Item;
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Sales] [Purchase] [Order]
        // [SCENARIO 325237] Planning lines generated by "Purchase Order from Sales Order" functionality by another user, are not taken into consideration.
        Initialize;

        VendorNo := LibraryPurchase.CreateVendorNo;
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Two sales orders "SO1", "SO2".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader[1], SalesLine[1], SalesHeader[1]."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandIntInRange(10, 20), '', WorkDate);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader[2], SalesLine[2], SalesHeader[2]."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandIntInRange(30, 60), '', WorkDate);

        // [GIVEN] User "A":
        // [GIVEN] Create purchase order from sales order "SO1".
        PurchaseOrder.Trap;
        SalesOrder.OpenEdit;
        SalesOrder.FILTER.SetFilter("No.", SalesHeader[1]."No.");
        LibraryVariableStorage.Enqueue(LibraryPurchase.CreateVendorNo);
        SalesOrder.CreatePurchaseOrder.Invoke;
        PurchaseOrder.Close;

        RequisitionLine.SetRange("Worksheet Template Name", '');
        RequisitionLine.ModifyAll("User ID", LibraryUtility.GenerateGUID);

        // [GIVEN] User "B":
        // [THEN] Create purchase order from sales order "SO2".
        PurchaseOrder.Trap;
        SalesOrder.FILTER.SetFilter("No.", SalesHeader[2]."No.");
        LibraryVariableStorage.Enqueue(VendorNo);
        SalesOrder.CreatePurchaseOrder.Invoke;

        // [THEN] Purchase order is created.
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        Assert.RecordIsNotEmpty(PurchaseHeader);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure OtherBlockedItemDoesNotPreventCreatePurchaseFromSales()
    var
        BlockedItem: Record Item;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
        Qty: Decimal;
    begin
        // [FEATURE] [Item] [Sales] [Purchase] [Order]
        // [SCENARIO 337908] Other blocked items do not interfere with creating purchase from sales.
        Initialize;
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Items "A" and "B".
        LibraryInventory.CreateItem(BlockedItem);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo);
        Item.Modify(true);

        // [GIVEN] Sales order for item "A".
        // [GIVEN] Sales order for item "B".
        CreateSalesOrder(SalesHeader, BlockedItem."No.", '', Qty, Qty);
        CreateSalesOrder(SalesHeader, Item."No.", '', Qty, Qty);

        // [GIVEN] Block item "A".
        BlockedItem.Validate(Blocked, true);
        BlockedItem.Modify(true);

        // [WHEN] Run "Create Purchase Order" from the sales order for item "B".
        LibraryVariableStorage.Enqueue(true);
        PurchaseOrder.Trap;
        SalesOrder.OpenEdit;
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.CreatePurchaseOrder.Invoke;

        // [THEN] A new purchase order for "B" is successfully created.
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseHeader.TestField("Buy-from Vendor No.", Item."Vendor No.");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningTwoSalesOrdersOneSupplyCoversBoth()
    var
        Item: Record Item;
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
        Qty: array[2] of Decimal;
    begin
        // [FEATURE] [Item] [Sales] [Purchase] [Order]
        // [SCENARIO 348685] Planning sales order using "Purchase Order from Sales Order" functionality does not suggest purchasing when a purchase has already been planned for this sales order.
        Initialize();
        Qty[1] := LibraryRandom.RandIntInRange(50, 100);
        Qty[2] := LibraryRandom.RandInt(10);

        // [GIVEN] Item with vendor no.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        // [GIVEN] First sales order for 50 pcs.
        // [GIVEN] Plan a purchase from the sales.
        // [GIVEN] Purchase order for 50 pcs is created.
        CreateSalesOrder(SalesHeader[1], Item."No.", '', Qty[1], Qty[1]);
        LibraryVariableStorage.Enqueue(true);
        PurchaseOrder.Trap;
        SalesOrder.OpenEdit;
        SalesOrder.FILTER.SetFilter("No.", SalesHeader[1]."No.");
        SalesOrder.CreatePurchaseOrder.Invoke;
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseLine.TestField(Quantity, Qty[1]);
        PurchaseOrder.Close;

        // [GIVEN] Second sales order for 10 pcs on a later date.
        CreateSalesOrder(SalesHeader[2], Item."No.", '', Qty[2], Qty[2]);
        FindSalesLine(SalesLine, SalesHeader[2], Item."No.");
        UpdateSalesLine(SalesLine, SalesLine.FieldNo("Shipment Date"), LibraryRandom.RandDateFrom(SalesLine."Shipment Date", 10));

        // [WHEN] Plan a purchase from the first sales again.
        LibraryVariableStorage.Enqueue(true);
        PurchaseOrder.Trap;
        SalesOrder.FILTER.SetFilter("No.", SalesHeader[1]."No.");
        asserterror SalesOrder.CreatePurchaseOrder.Invoke;

        // [THEN] No purchase order is suggested as the first sales order is considered supplied.
        Assert.ExpectedError(NoPurchOrderCreatedErr);
        Assert.ExpectedErrorCode('Dialog');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Order Planning - III");
        ClearGlobals;

        LibraryApplicationArea.EnableEssentialSetup;
        LibraryVariableStorage.Clear;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Order Planning - III");
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        CreateLocationSetup;
        NoSeriesSetup;
        IsInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Order Planning - III");
    end;

    local procedure ClearGlobals()
    var
        RequisitionLine: Record "Requisition Line";
    begin
        Clear(VerifyOnGlobal);
        Clear(DemandTypeGlobal);
        Clear(GlobalChildItemNo);
        Clear(ExpectedQuantity);
        RequisitionLine.Reset;
        RequisitionLine.DeleteAll;
        ClearManufacturingUserTemplate;
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ChangeReplenishmentSystem(var RequisitionLine: Record "Requisition Line"; OldReplenishmentSystem: Option; NewReplenishmentSystem: Option; DemandOrderNo: Code[20]; VendorNo: Code[20])
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("Replenishment System", OldReplenishmentSystem);
        RequisitionLine.FindFirst;
        RequisitionLine.Validate("Replenishment System", NewReplenishmentSystem);
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Modify(true);
    end;

    local procedure CreateManufacturingSetup(var Item: Record Item; var ChildItem: Record Item; ChildWithBOM: Boolean; OrderTrackingPolicy: Option)
    var
        ChildItem2: Record Item;
    begin
        // Create Child Item with its own Production BOM hierarchy.
        if ChildWithBOM then
            CreateProdItem(ChildItem, ChildItem2)
        else
            CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, '', '');
        UpdateItem(ChildItem, ChildItem.Reserve::Optional, OrderTrackingPolicy);
        CreateItemWithProductionBOM(Item, ChildItem, '', LibraryRandom.RandDec(5, 2));
    end;

    local procedure CreateProdItem(var ParentItem: Record Item; var ChildItem: Record Item)
    begin
        // Create Child Item.
        CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, '', '');

        // Create Parent Item.
        CreateItemWithProductionBOM(ParentItem, ChildItem, '', LibraryRandom.RandDec(5, 2));
    end;

    local procedure CreateItemWithProductionBOM(var Item: Record Item; ChildItem: Record Item; VariantCode: Code[10]; QuantityPer: Decimal)
    var
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Production BOM and Routing.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem, VariantCode, QuantityPer);
        CreateRoutingSetup(RoutingHeader);

        // Create Parent Item.
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", RoutingHeader."No.", ProductionBOMHeader."No.");
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Option; RoutingHeaderNo: Code[20]; ProductionBOMNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryInventory.CreateItem(Item);
        GeneralLedgerSetup.Get;
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(20, 2));
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Rounding Precision", GeneralLedgerSetup."Amount Rounding Precision");
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo);
        Item.Validate("Routing No.", RoutingHeaderNo);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateItemWithVendorNoAndPurchUnitOfMeasure(var Item: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(12, 24));
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo);
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure UpdateItem(var Item: Record Item; Reserve: Option; OrderTrackingPolicy: Option)
    begin
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate(Reserve, Reserve);
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
    end;

    local procedure UpdateItemEx(var Item: Record Item; Reserve: Option; ReorderingPolicy: Option)
    var
        Qty: Integer;
    begin
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate(Reserve, Reserve);
        Qty := LibraryRandom.RandIntInRange(10, 20);
        if ReorderingPolicy = Item."Reordering Policy"::"Fixed Reorder Qty." then
            Item.Validate("Reorder Quantity", Qty)
        else
            if ReorderingPolicy = Item."Reordering Policy"::"Maximum Qty." then
                Item.Validate("Maximum Inventory", Qty);
        Item.Modify(true);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; VariantCode: Code[10]; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Create component lines in the BOM
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QuantityPer);
        ProductionBOMLine.Validate("Variant Code", VariantCode);
        ProductionBOMLine.Modify(true);

        // Certify BOM.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::"Under Development");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterFullWorkingWeek(WorkCenter, 080000T, 160000T);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate), CalcDate('<1M>', WorkDate));
        WorkCenter.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Modify(true);
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        // Random value important for test.
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(105, 1));
        MachineCenter.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        MachineCenter.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(5, 2));
    end;

    local procedure ClearManufacturingUserTemplate()
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        ManufacturingUserTemplate.SetRange("User ID", UserId);
        if ManufacturingUserTemplate.FindFirst then
            ManufacturingUserTemplate.Delete(true);
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; Status: Option; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateLocationSetup()
    begin
        CreateLocation(LocationRed);
        CreateLocation(LocationBlue);
        CreateLocation(LocationBlue2);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; ShipmentDate: Date; Quantity: Decimal; QuantityToShip: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Qty. to Ship", QuantityToShip);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; QtyToShip: Decimal)
    begin
        // Random values used are not important for test.
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, ItemNo, LocationCode, WorkDate, Quantity, QtyToShip);
    end;

    local procedure CreateSalesOrderWithPurchasingCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; PurchasingCode: Code[10])
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, LibraryRandom.RandInt(100), '', WorkDate);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateLocation(var Location: Record Location)
    begin
        Clear(Location);
        LibraryWarehouse.CreateLocation(Location);
    end;

    local procedure CreateDimensionWithValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure ChangeDataOnSalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; FieldNo: Integer; Value: Variant)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.ReopenSalesDocument(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader, ItemNo);
        UpdateSalesLine(SalesLine, FieldNo, Value);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure ChangeDataOnProductionOrderAndRefresh(ProductionOrder: Record "Production Order"; FieldNo: Integer; Value: Variant)
    begin
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        UpdateProductionOrder(ProductionOrder, FieldNo, Value);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure UpdateProductionOrder(var ProductionOrder: Record "Production Order"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(ProductionOrder);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(ProductionOrder);
        ProductionOrder.Modify(true);
    end;

    local procedure UpdatePurchaseHeaderCurrencyCode(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate(
          "Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2)));
        PurchaseHeader.Modify(true);
    end;

    local procedure ChangeQuantityOnPlanning(var OrderPlanning: TestPage "Order Planning"; OrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        OpenOrderPlanningPage(OrderPlanning, OrderNo, ItemNo);
        OrderPlanning.Quantity.SetValue(Quantity);
        OrderPlanning.Close;
    end;

    local procedure GetSpecialOrderAndCarryOutAtWorkdateByItemNo(ItemNo: Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, LibraryPlanning.SelectRequisitionTemplateName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, 0D, WorkDate, WorkDate, WorkDate, '');
    end;

    local procedure GetSalesOrdersAndCarryOutAtWorkdateByItemNo(SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        GetDim: Option Item,"Sales Line";
    begin
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, LibraryPlanning.SelectRequisitionTemplateName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, GetDim::"Sales Line");
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, 0D, WorkDate, WorkDate, WorkDate, '');
    end;

    local procedure GetPurchaseSpecialOrderAtWorkdateByItemNo(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        GetSpecialOrderAndCarryOutAtWorkdateByItemNo(ItemNo);
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, ItemNo);
    end;

    local procedure GetPurchaseDropShipmentAtWorkdateByItemNo(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
        GetSalesOrdersAndCarryOutAtWorkdateByItemNo(SalesLine);
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, SalesLine."No.");
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

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; No: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst;
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; DemandOrderNo: Code[20]; No: Code[20]; LocationCode: Code[10])
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.SetRange("Location Code", LocationCode);
        RequisitionLine.FindFirst;
    end;

    local procedure FindPurchaseOrderNo(): Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        PurchasesPayablesSetup.Get;
        exit(NoSeriesManagement.GetNextNo(PurchasesPayablesSetup."Order Nos.", WorkDate, false));
    end;

    local procedure FindProductionOrderNo(ItemNo: Code[20]): Code[20]
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::"Firm Planned");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst;
        exit(ProdOrderLine."Prod. Order No.");
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet;
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst;
    end;

    local procedure FindPlanningComponent(var PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line")
    begin
        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
    end;

    local procedure FindPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; RequisitionLine: Record "Requisition Line")
    begin
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
    end;

    local procedure FindPurchaseDocumentByItemNo(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst;
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    local procedure GetManufacturingUserTemplate(var ManufacturingUserTemplate: Record "Manufacturing User Template"; MakeOrder: Option; CreateProductionOrder: Option)
    begin
        if not ManufacturingUserTemplate.Get(UserId) then
            LibraryPlanning.CreateManufUserTemplate(
              ManufacturingUserTemplate, UserId, MakeOrder, ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders",
              CreateProductionOrder, ManufacturingUserTemplate."Create Transfer Order"::"Make Trans. Orders");
    end;

    local procedure GetReqWkshTemplateName(TemplateType: Option): Code[10]
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, TemplateType);
        ReqWkshTemplate.FindFirst;
        exit(ReqWkshTemplate.Name);
    end;

    local procedure GetReqWkshName(TemplateName: Code[10]; TemplateType: Option): Code[10]
    var
        ReqWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshName.SetRange("Worksheet Template Name", TemplateName);
        ReqWkshName.SetRange("Template Type", TemplateType);
        ReqWkshName.FindFirst;
        exit(ReqWkshName.Name);
    end;

    local procedure MakeSupplyOrdersActiveOrder(DemandOrderNo: Code[20])
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.FindFirst;
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");
    end;

    local procedure MakeSupplyOrdersCopyToWkshActiveOrder(DemandOrderNo: Code[20]; WkshTemplateName: Code[10]; WkshName: Code[10])
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.FindFirst;
        MakeSupplyOrdersCopyToWksh(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Order", WkshTemplateName, WkshName);
    end;

    local procedure MakeSupplyOrders(var RequisitionLine: Record "Requisition Line"; MakeOrders: Option; CreateProductionOrder: Option)
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        GetManufacturingUserTemplate(ManufacturingUserTemplate, MakeOrders, CreateProductionOrder);
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
    end;

    local procedure MakeSupplyOrdersCopyToWksh(var RequisitionLine: Record "Requisition Line"; MakeOrders: Option; WkshTemplateName: Code[10]; WkshName: Code[10])
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        // Set create order option to "Copy to Req. Wksh" for purchase, production, transfer orders
        GetManufacturingUserTemplate(ManufacturingUserTemplate, MakeOrders,
          ManufacturingUserTemplate."Create Production Order"::"Copy to Req. Wksh");
        ManufacturingUserTemplate.Validate("Create Purchase Order",
          ManufacturingUserTemplate."Create Purchase Order"::"Copy to Req. Wksh");
        ManufacturingUserTemplate.Validate("Purchase Req. Wksh. Template", WkshTemplateName);
        ManufacturingUserTemplate.Validate("Purchase Wksh. Name", WkshName);

        ManufacturingUserTemplate.Validate("Prod. Req. Wksh. Template", WkshTemplateName);
        ManufacturingUserTemplate.Validate("Prod. Wksh. Name", WkshName);

        ManufacturingUserTemplate.Validate("Create Transfer Order",
          ManufacturingUserTemplate."Create Transfer Order"::"Copy to Req. Wksh");
        ManufacturingUserTemplate.Validate("Transfer Req. Wksh. Template", WkshTemplateName);
        ManufacturingUserTemplate.Validate("Transfer Wksh. Name", WkshName);

        ManufacturingUserTemplate.Modify(true);
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
    end;

    local procedure OpenOrderPlanningPage(var OrderPlanning: TestPage "Order Planning"; DemandOrderNo: Code[20]; No: Code[20])
    begin
        OrderPlanning.OpenEdit;
        OrderPlanning.FILTER.SetFilter("Demand Order No.", DemandOrderNo);
        OrderPlanning.Expand(true);
        OrderPlanning.FILTER.SetFilter("No.", No);
    end;

    local procedure UpdateSalesLine(var SalesLine: Record "Sales Line"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(SalesLine);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(SalesLine);
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(var SalesReceivablesSetup2: Record "Sales & Receivables Setup")
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup2 := SalesReceivablesSetup;
        SalesReceivablesSetup2.Insert;

        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePlanningComponent(var PlanningComponent: Record "Planning Component"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; QuantityPer: Decimal)
    begin
        PlanningComponent.Validate("Item No.", ItemNo);
        PlanningComponent.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PlanningComponent.Validate("Quantity per", QuantityPer);
        PlanningComponent.Modify(true);
    end;

    local procedure UpdatePlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; WorkCenterNo: Code[20]; PerviousOperationNo: Code[30]; SetupTime: Decimal; Runtime: Decimal)
    begin
        PlanningRoutingLine.Validate("Previous Operation No.", PerviousOperationNo);
        PlanningRoutingLine.Validate(Type, PlanningRoutingLine.Type::"Work Center");
        PlanningRoutingLine.Validate("No.", WorkCenterNo);
        PlanningRoutingLine.Validate("Setup Time", SetupTime);
        PlanningRoutingLine.Validate("Run Time", Runtime);
        PlanningRoutingLine.Modify(true);
    end;

    local procedure OpenFirmPlannedProductionOrder(var FirmPlannedProdOrders: TestPage "Firm Planned Prod. Orders"; var ProductionOrderStatistics: TestPage "Production Order Statistics"; SourceNo: Code[20]; No: Code[20])
    begin
        FirmPlannedProdOrders.OpenEdit;
        FirmPlannedProdOrders.FILTER.SetFilter("Source No.", SourceNo);
        FirmPlannedProdOrders.FILTER.SetFilter("No.", No);
        ProductionOrderStatistics.Trap;
        FirmPlannedProdOrders.Statistics.Invoke;
    end;

    local procedure VerifyDimensionSetEntry(DimensionCode: Code[20]; DimensionValueCode: Code[20]; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.FindFirst;
        DimensionSetEntry.TestField("Dimension Value Code", DimensionValueCode);
    end;

    local procedure VerifyOrderTrackingPage(OrderTracking: TestPage "Order Tracking")
    begin
        Assert.AreEqual(
          GlobalChildItemNo, OrderTracking."Item No.".Value,
          StrSubstNo(ValidationError, OrderTracking."Item No.".Caption, GlobalChildItemNo, OrderTracking.Caption));
        Assert.AreEqual(ExpectedQuantity, OrderTracking.Quantity.AsDEcimal, QuantityError);
    end;

    local procedure VerifyProdOrderComponent(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; QuantityPer: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst;
        ProdOrderComponent.TestField("Quantity per", QuantityPer);
        ProdOrderComponent.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    local procedure VerifyProdOrderRoutingLine(PlanningRoutingLine: Record "Planning Routing Line"; RoutingNo: Code[20]; OperationNo: Code[10])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRoutingLine.FindFirst;
        ProdOrderRoutingLine.TestField(Type, ProdOrderRoutingLine.Type);
        ProdOrderRoutingLine.TestField("No.", PlanningRoutingLine."No.");
        ProdOrderRoutingLine.TestField("Setup Time", PlanningRoutingLine."Setup Time");
        ProdOrderRoutingLine.TestField("Run Time", PlanningRoutingLine."Run Time");
        ProdOrderRoutingLine.TestField("Previous Operation No.", PlanningRoutingLine."Previous Operation No.");
    end;

    local procedure VerifyProductionOrderStatistics(ProductionOrderStatistics: TestPage "Production Order Statistics"; ProductionOrderStatistics2: TestPage "Production Order Statistics")
    begin
        ProductionOrderStatistics2.MaterialCost_StandardCost.AssertEquals(ProductionOrderStatistics.MaterialCost_StandardCost.Value);
        ProductionOrderStatistics2.CapacityCost_StandardCost.AssertEquals(ProductionOrderStatistics.CapacityCost_StandardCost.Value);
        ProductionOrderStatistics2.TotalCost_StandardCost.AssertEquals(ProductionOrderStatistics.TotalCost_StandardCost.Value);

        ProductionOrderStatistics2.MaterialCost_ExpectedCost.AssertEquals(ProductionOrderStatistics.MaterialCost_ExpectedCost.Value);
        ProductionOrderStatistics2.CapacityCost_ExpectedCost.AssertEquals(ProductionOrderStatistics.CapacityCost_ExpectedCost.Value);
        ProductionOrderStatistics2.TotalCost_ExpectedCost.AssertEquals(ProductionOrderStatistics.TotalCost_ExpectedCost.Value);

        ProductionOrderStatistics2.MaterialCost_ActualCost.AssertEquals(ProductionOrderStatistics.MaterialCost_ActualCost.Value);
        ProductionOrderStatistics2.CapacityCost_ActualCost.AssertEquals(ProductionOrderStatistics.CapacityCost_ActualCost.Value);
        ProductionOrderStatistics2.TotalCost_ActualCost.AssertEquals(ProductionOrderStatistics.TotalCost_ActualCost.Value);
    end;

    local procedure VerifyPurchaseLineUnitOfMeasureCodeAndQuantityBase(PurchaseLine: Record "Purchase Line"; UnitOfMeasureCode: Code[10]; QtyBase: Decimal)
    begin
        PurchaseLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        Assert.AreNearlyEqual(
          QtyBase, PurchaseLine."Quantity (Base)", 0.01,
          StrSubstNo(PurchaseLineQuantityBaseErr, PurchaseLine.TableName, PurchaseLine.FieldName("Quantity (Base)"), QtyBase));
    end;

    local procedure RestoreSalesReceivableSetup(TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary)
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup.Validate("Credit Warnings", TempSalesReceivablesSetup."Credit Warnings");
        SalesReceivablesSetup.Validate("Stockout Warning", TempSalesReceivablesSetup."Stockout Warning");
        SalesReceivablesSetup.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MakeSupplyOrdersPageHandler(var MakeSupplyOrders: Page "Make Supply Orders"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, OrderTrackingMessage) > 0, StrSubstNo(UnexpectedMessageDialog, Message));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingPageHandler(var OrderTracking: TestPage "Order Tracking")
    begin
        VerifyOrderTrackingPage(OrderTracking);
        OrderTracking.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PlanningComponentPageHandler(var PlanningComponents: TestPage "Planning Components")
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        PlanningComponents.First;
        Item.Get(GlobalChildItemNo);
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMLine.FindFirst;

        // Verify That Operation No. And Type Is same as on Production BOM Line.
        PlanningComponents."Item No.".AssertEquals(ProductionBOMLine."No.");
        PlanningComponents."Quantity per".AssertEquals(ProductionBOMLine.Quantity);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PlanningRoutingPageHandler(var PlanningRouting: TestPage "Planning Routing")
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
    begin
        PlanningRouting.First;
        Item.Get(GlobalChildItemNo);
        RoutingLine.SetRange("Routing No.", Item."Routing No.");
        RoutingLine.FindFirst;

        // Verify That Operation No. And Type Is same as on Routing Line.
        PlanningRouting."Operation No.".AssertEquals(RoutingLine."Operation No.");
        PlanningRouting.Type.AssertEquals(RoutingLine.Type);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderFromSalesOrderModalPageHandler(var PurchOrderFromSalesOrder: TestPage "Purch. Order From Sales Order")
    begin
        if LibraryVariableStorage.DequeueBoolean then
            PurchOrderFromSalesOrder.OK.Invoke
        else
            PurchOrderFromSalesOrder.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderFromSalesOrderWithVendorNoModalPageHandler(var PurchOrderFromSalesOrder: TestPage "Purch. Order From Sales Order")
    begin
        PurchOrderFromSalesOrder.Vendor.SetValue(LibraryVariableStorage.DequeueText);
        PurchOrderFromSalesOrder.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

