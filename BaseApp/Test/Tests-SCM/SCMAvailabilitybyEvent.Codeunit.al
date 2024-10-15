codeunit 137009 "SCM Availability by Event"
{
    // // [FEATURE] [Item Availability] [SCM]
    // Case 1
    //   Simple: 1 PO, 1 SO out of resheduling period, 1 cancel PO (same date), 1 new (same date as sales), no excess inventory;

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Availability] [SCM]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        Initialized: Boolean;
        WrongReservedQtyErr: Label 'Wrong reserved quantity in Item Availability by Event';

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Availability by Event");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Availability by Event");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibraryERMCountryData.UpdateSalesReceivablesSetup;
        LibraryERMCountryData.CreateGeneralPostingSetupData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        NoSeriesSetup;

        Commit;

        Initialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Availability by Event");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CollectEventsCase1()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        Initialize;

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Evaluate(Item."Rescheduling Period", '<5D>');
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 8, CalcDate('<+5D>', WorkDate));
        CreateSalesOrder(SalesLine, Item."No.", 7, CalcDate('<+11D>', WorkDate));
        LibraryManufacturing.CalculateWorksheetPlan(Item, CalcDate('<+2D>', WorkDate), CalcDate('<+16D>', WorkDate));

        // Should give 2 lines + Cancel + New from Planning plus one per Period Type, no excess inventory
        RunPage(Item, '', false, true, 0, 6, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservedReceiptIsEqualToPurchaseQtyInAvailByEvent()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempInvtPageData: Record "Inventory Page Data" temporary;
    begin
        // [SCENARIO 361672] "Reserved Receipt" in Item Availability by Event is equal to Purchase Line qty. when sales order is reserved against purch. order
        Initialize;
        LibraryWarehouse.CreateLocation(Location);
        LibraryPatterns.MAKEItemSimple(Item, Item."Costing Method"::Standard, LibraryPatterns.RandCost(Item));

        // [GIVEN] Purchase order for item "X", quantity = "Q"
        LibraryPatterns.MAKEPurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, Location.Code, '', LibraryRandom.RandInt(100), WorkDate, Item."Unit Cost");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Sales order with reservation against purchase order, reserved quantity = "Q"
        LibraryPatterns.MAKESalesOrder(SalesHeader, SalesLine, Item, Location.Code, '', PurchaseLine.Quantity, WorkDate, Item."Unit Price");

        SalesLine.Validate("Shipment Date", PurchaseLine."Expected Receipt Date");
        SalesLine.Modify(true);
        AutoReserveSalesLine(SalesLine);

        // [WHEN] Item availability by event is calculated
        CalculateAvailabilityByEvent(TempInvtPageData, Item);

        // [THEN] "Reserved Receipt" = "Q"
        FindInvtPageData(TempInvtPageData, TempInvtPageData.Type::Purchase);
        Assert.AreEqual(PurchaseLine.Quantity, TempInvtPageData."Reserved Receipt", WrongReservedQtyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservedRequirementIsEqualToNegativePurchReturnQtyInAvailByEvent()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempInvtPageData: Record "Inventory Page Data" temporary;
        Quantity: Integer;
    begin
        // [SCENARIO 361672] "Reserved Requirement" in Item Availability by Event is equal to negative Purchase Return qty. when return is reserved against inventory
        Initialize;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryPatterns.MAKEItemSimple(Item, Item."Costing Method"::Standard, LibraryPatterns.RandCost(Item));

        // [GIVEN] "Q" units of item "X" on inventory
        Quantity := LibraryRandom.RandInt(100);
        LibraryPatterns.POSTPositiveAdjustment(Item, Location.Code, '', '', Quantity, WorkDate, Item."Unit Cost");

        // [GIVEN] Purchase return order with "Q" units of item "X" reserved on inventory
        LibraryPatterns.MAKEPurchaseReturnOrder(PurchaseHeader, PurchaseLine, Item, Location.Code, '', Quantity, WorkDate, Item."Unit Cost");
        AutoReservePurchaseLine(PurchaseLine);

        // [WHEN] Item availability by event is calculated
        CalculateAvailabilityByEvent(TempInvtPageData, Item);

        // [THEN] "Reserved Requirement" = -"Q"
        FindInvtPageData(TempInvtPageData, TempInvtPageData.Type::"Purch. Return");
        Assert.AreEqual(-PurchaseLine.Quantity, TempInvtPageData."Reserved Requirement", WrongReservedQtyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservedReceiptInAvailByEventShowsInboundAndShippedReservedQtyInTransfer()
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempInvtPageData: Record "Inventory Page Data" temporary;
        Qty: Decimal;
    begin
        // [FEATURE] [Transfer] [Reservation]
        // [SCENARIO 213103] Shipped and reserved quantity on transfer line should be included in Reserved Receipt in Item Availability by Event.
        Initialize;

        // [GIVEN] Locations "L1", "L2" and an in-transit location.
        CreateLocationsForTransfer(FromLocation, ToLocation, InTransitLocation);

        // [GIVEN] "Q" pcs of item "I" is is stock on "L1".
        LibraryPatterns.MAKEItemSimple(Item, Item."Costing Method"::Standard, LibraryPatterns.RandCost(Item));
        Qty := LibraryRandom.RandIntInRange(50, 100);
        LibraryPatterns.POSTPositiveAdjustment(Item, FromLocation.Code, '', '', Qty, WorkDate, Item."Unit Cost");

        // [GIVEN] Transfer Order from "L1" to "L2". Quantity = "Q", "Qty. to Ship" = "q" < "Q".
        LibraryPatterns.MAKETransferOrder(
          TransferHeader, TransferLine, Item, FromLocation, ToLocation, InTransitLocation, '', Qty, WorkDate, WorkDate);
        TransferLine.Validate("Qty. to Ship", LibraryRandom.RandInt(20));
        TransferLine.Modify(true);

        // [GIVEN] Sales Order for "Q" pcs is reserved from Transfer Order.
        LibraryPatterns.MAKESalesOrder(SalesHeader, SalesLine, Item, ToLocation.Code, '', Qty, WorkDate, Item."Unit Price");
        SalesLine.Validate("Shipment Date", LibraryRandom.RandDate(10));
        SalesLine.Modify(true);
        AutoReserveSalesLine(SalesLine);

        // [GIVEN] Transfer Order is shipped.
        // [GIVEN] Reserved Qty. Inbnd. (Base) becomes equal to "Q" - "q", Reserved Qty. Shipped (Base) = "q".
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        TransferLine.Find;
        TransferLine.CalcFields("Reserved Qty. Inbnd. (Base)", "Reserved Qty. Shipped (Base)");

        // [WHEN] Calculate item availability by event.
        CalculateAvailabilityByEvent(TempInvtPageData, Item);

        // [THEN] "Reserved Receipt" on the availability line representing the transfer is equal to "Q".
        FindInvtPageData(TempInvtPageData, TempInvtPageData.Type::Transfer);
        Assert.AreEqual(
          TransferLine."Reserved Qty. Inbnd. (Base)" + TransferLine."Reserved Qty. Shipped (Base)",
          TempInvtPageData."Reserved Receipt", WrongReservedQtyErr);
    end;

    [Test]
    [HandlerFunctions('DummyNotificationHandler,ItemAvailabilityByLocationPageHandler,ConfirmHadlerYes')]
    [Scope('OnPrem')]
    procedure AvailabilityNotificationAppearsInSalesOrderWhenLocationChangedByItemAvailPage()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales Order] [Availability] [Available - Sales Lines] [Notification]
        // [SCENARIO 279806] Availability notification must be called when Location Code is changed through Item Availability by Location page.
        Initialize;

        // [GIVEN] Create an Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Location
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create a Sales Order with single Sales Line, Location Code left empty
        LibraryPatterns.MAKESalesOrder(SalesHeader, SalesLine, Item, '', '', LibraryRandom.RandInt(5), WorkDate, LibraryRandom.RandInt(10));

        // [GIVEN] Open created Sales Order on test page
        SalesOrder.OpenEdit;
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] Invoke Item Availability by Location page and choose Location
        Commit;
        LibraryVariableStorage.Enqueue(Location.Code);
        SalesOrder.SalesLines.ItemAvailabilityByLocation.Invoke;

        // [THEN] DummyNotificationHandler has been invoked - Notification was called properly

        LibraryVariableStorage.AssertEmpty;
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [HandlerFunctions('DummyNotificationHandler,ItemAvailabilityByVariantPageHandler,ConfirmHadlerYes')]
    [Scope('OnPrem')]
    procedure AvailabilityNotificationAppearsInSalesOrderWhenVariantChangedByItemAvailPage()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales Order] [Availability] [Available - Sales Lines] [Notification]
        // [SCENARIO 279806] Availability notification must be called when Variant Code is changed through Item Availability by Variant page.
        Initialize;

        // [GIVEN] Create an Item with an Item Variant
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create a Sales Order with single Sales Line, Variant Code left empty
        LibraryPatterns.MAKESalesOrder(SalesHeader, SalesLine, Item, '', '', LibraryRandom.RandInt(5), WorkDate, LibraryRandom.RandInt(10));

        // [GIVEN] Open created Sales Order on test page
        SalesOrder.OpenEdit;
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] Invoke Item Availability by Variant page and choose Item Variant
        Commit;
        SalesOrder.SalesLines.ItemAvailabilityByVariant.Invoke;

        // [THEN] DummyNotificationHandler has been invoked - Notification was called properly
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityLineListPageHandler,ProdOrderComponentPageHandler')]
    [Scope('OnPrem')]
    procedure DrillingDownToGrossReqInItemAvailShowsListOfFirmPlannedProdOrders()
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByPeriod: TestPage "Item Availability by Periods";
        Qty: Decimal;
    begin
        // [FEATURE] [Item Availability] [Prod. Order Component] [Manufacturing]
        // [SCENARIO 382414] Prod. order components of Firm Planned production orders should be shown on drilling down Gross Requirements value on Item Available by Periods page.
        Initialize;
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Item "I" which is a Prod. Order Component in Firm Planned production order. "Remaining Quantity" = "X".
        LibraryInventory.CreateItem(Item);
        MockProdOrderComponent(Item."No.", Qty);

        // [GIVEN] Item Availability by Periods page is opened for "I".
        ItemCard.OpenView;
        ItemCard.GotoRecord(Item);
        ItemAvailabilityByPeriod.Trap;
        ItemCard.Period.Invoke;

        // [WHEN] Drill down Gross Requirement value on Item Availability by Periods page.
        LibraryVariableStorage.Enqueue(ProdOrderComponent.TableCaption);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(Qty);
        ItemAvailabilityByPeriod.ItemAvailLines.FILTER.SetFilter("Period Start", Format(WorkDate));
        ItemAvailabilityByPeriod.ItemAvailLines.GrossRequirement.DrillDown;

        // [THEN] Gross Requirement for "I" shows "X" units in prod. order components.
        // [THEN] Drilling down to "X" value shows "X" units of item "I" as a component of Firm Planned production order.
        // Verifications are done in ItemAvailabilityLineListPageHandler and ProdOrderComponentPageHandler.
    end;

    local procedure AutoReservePurchaseLine(PurchaseLine: Record "Purchase Line")
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        ReservMgt.SetPurchLine(PurchaseLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', WorkDate, PurchaseLine.Quantity, PurchaseLine."Quantity (Base)");
    end;

    local procedure AutoReserveSalesLine(SalesLine: Record "Sales Line")
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        ReservMgt.SetSalesLine(SalesLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', SalesLine."Shipment Date", SalesLine.Quantity, SalesLine."Quantity (Base)");
    end;

    local procedure RunPage(Item: Record Item; ForecastName: Code[10]; InclBlanketOrders: Boolean; InclPlan: Boolean; PeriodType: Option; ExpectedNoOfLines: Integer; ExpextedEndBalance: Decimal)
    var
        PageTempInvtPageData: Record "Inventory Page Data" temporary;
        TempInvtPageData: Record "Inventory Page Data" temporary;
        CalcInvtPageData: Codeunit "Calc. Inventory Page Data";
        RunningBalance: Decimal;
        RunningBalanceForecast: Decimal;
        RunningBalancePlan: Decimal;
    begin
        // Works more less like Page 5530 except for the view part
        // Initialize + get events in background table in cu
        CalcInvtPageData.Initialize(Item, ForecastName, InclBlanketOrders, 0D, InclPlan);

        // Create Period aggegation entries in Page background table
        TempInvtPageData.Reset;
        TempInvtPageData.DeleteAll;
        TempInvtPageData.SetCurrentKey("Period Start", "Line No.");
        CalcInvtPageData.CreatePeriodEntries(TempInvtPageData, PeriodType);   // got events in background table in cu

        // Get event details
        TempInvtPageData.SetRange(Level, 0);
        if TempInvtPageData.Find('-') then
            repeat
                // get one entry per involved period in tempinv
                CalcInvtPageData.DetailsForPeriodEntry(TempInvtPageData, true);
                CalcInvtPageData.DetailsForPeriodEntry(TempInvtPageData, false);
            until TempInvtPageData.Next = 0;
        TempInvtPageData.SetRange(Level);

        // Populate the view table likedon on expandall in the page
        PageTempInvtPageData.Reset;
        PageTempInvtPageData.DeleteAll;
        PageTempInvtPageData.SetCurrentKey("Period Start", "Line No.");
        if TempInvtPageData.Find('-') then
            repeat
                PageTempInvtPageData := TempInvtPageData;
                PageTempInvtPageData.UpdateInventorys(RunningBalance, RunningBalanceForecast, RunningBalancePlan);
                PageTempInvtPageData.Insert;
            until TempInvtPageData.Next = 0;

        Assert.AreEqual(ExpectedNoOfLines, PageTempInvtPageData.Count,
          'Asserting that the no. of lines match');
        Assert.AreEqual(ExpextedEndBalance, PageTempInvtPageData."Suggested Projected Inventory",
          'Asserting that the ultimo Suggested Projected Inventory match');
    end;

    local procedure NoSeriesSetup()
    var
        PurchPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        SalesReceivablesSetup.Modify(true);

        PurchPayablesSetup.Get;
        PurchPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        PurchPayablesSetup.Modify(true);
    end;

    local procedure CalculateAvailabilityByEvent(var TempInvtPageData: Record "Inventory Page Data" temporary; Item: Record Item)
    var
        CalcInventoryPageData: Codeunit "Calc. Inventory Page Data";
        PeriodType: Option Day,Week,Month,Quarter,Year;
    begin
        CalcInventoryPageData.Initialize(Item, '', false, 0D, false);
        CalcInventoryPageData.CreatePeriodEntries(TempInvtPageData, PeriodType::Day);
        TempInvtPageData.SetRange(Level, 0);
        TempInvtPageData.FindSet;
        repeat
            CalcInventoryPageData.DetailsForPeriodEntry(TempInvtPageData, true);
            CalcInventoryPageData.DetailsForPeriodEntry(TempInvtPageData, false);
        until TempInvtPageData.Next = 0;
    end;

    local procedure CreateLocationsForTransfer(var FromLocation: Record Location; var ToLocation: Record Location; var InTransitLocation: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; AvailableDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Expected Receipt Date", AvailableDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; AvailableDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Shipment Date", AvailableDate);
        SalesLine.Modify(true);
    end;

    local procedure FindInvtPageData(var InvtPageData: Record "Inventory Page Data"; DataType: Option)
    begin
        InvtPageData.SetRange(Level, 1);
        InvtPageData.SetRange(Type, DataType);
        InvtPageData.FindFirst;
    end;

    local procedure MockProdOrderComponent(ItemNo: Code[20]; Qty: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        with ProdOrderComponent do begin
            Init;
            Status := Status::"Firm Planned";
            "Item No." := ItemNo;
            "Due Date" := WorkDate;
            "Remaining Quantity" := Qty;
            "Remaining Qty. (Base)" := Qty;
            Insert;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByLocationPageHandler(var ItemAvailabilitybyLocation: TestPage "Item Availability by Location")
    begin
        ItemAvailabilitybyLocation.ItemAvailLocLines.GotoKey(LibraryVariableStorage.DequeueText);
        ItemAvailabilitybyLocation.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByVariantPageHandler(var ItemAvailabilitybyVariant: TestPage "Item Availability by Variant")
    begin
        ItemAvailabilitybyVariant.ItemAvailLocLines.First;
        ItemAvailabilitybyVariant.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityLineListPageHandler(var ItemAvailabilityLineList: TestPage "Item Availability Line List")
    begin
        ItemAvailabilityLineList.Name.AssertEquals(LibraryVariableStorage.DequeueText);
        ItemAvailabilityLineList.Quantity.AssertEquals(LibraryVariableStorage.DequeueDecimal);
        ItemAvailabilityLineList.Quantity.DrillDown;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderComponentPageHandler(var ProdOrderCompLineList: TestPage "Prod. Order Comp. Line List")
    begin
        ProdOrderCompLineList."Item No.".AssertEquals(LibraryVariableStorage.DequeueText);
        ProdOrderCompLineList."Remaining Quantity".AssertEquals(LibraryVariableStorage.DequeueDecimal);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure DummyNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHadlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

