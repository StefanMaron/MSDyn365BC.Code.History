codeunit 137050 "SCM Sales Order Management"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Order] [Shipment Date] [Sales] [SCM]
        IsInitialised := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        CalendarMgt: Codeunit "Calendar Management";
        IsInitialised: Boolean;
        SuggestAssignmentErr: Label 'Qty. to Invoice must have a value in Sales Line';

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithoutOutboundTime()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShippingAgentServices: Record "Shipping Agent Services";
        BaseCalendar: Record "Base Calendar";
        BaseCalendarChange: Record "Base Calendar Change";
        ShippingTime: DateFormula;
        ExpectedDeliveryDate: Date;
        PlannedShipmentDate: Date;
    begin
        // Setup: Create Shipping agent and its services. Take random shipping time.
        Initialize();
        Evaluate(ShippingTime, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CreateBaseCalendar(BaseCalendar);
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange."Recurring System"::"Weekly Recurring", 0D,
          BaseCalendarChange.Day::Monday);
        CreateShippingAgentWithService(ShippingAgentServices, ShippingTime, BaseCalendar.Code);

        // Exercise: Create a Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, CreateCustomer(ShippingAgentServices, BaseCalendar.Code));

        // Verification: Verify Shipment Date, Planned Shipment Date, Planned Delivery Date.
        CalculatePlannedDate(PlannedShipmentDate, ExpectedDeliveryDate, SalesLine);
        VerifySalesLine(SalesLine, WorkDate(), PlannedShipmentDate, ExpectedDeliveryDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithOutboundTime()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShippingAgentServices: Record "Shipping Agent Services";
        Item: Record Item;
        Shippingtime: DateFormula;
        PlannedShipmentDate: Date;
        PlannedDeliveryDate: Date;
    begin
        // Setup: Create Shipping agent services with random shipping time and Create Sales Header and Calculate Dates.
        Initialize();
        Evaluate(Shippingtime, '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        CreateItem(Item);
        CreateShippingAgentWithService(ShippingAgentServices, Shippingtime, '');
        CreateSalesHeader(SalesHeader, CreateCustomer(ShippingAgentServices, ShippingAgentServices."Base Calendar Code"), '');

        // Exercise: Create a Sales Line.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Verify: Verify various dates in Sales Order Line.
        CalculatePlannedDate(PlannedShipmentDate, PlannedDeliveryDate, SalesLine);
        VerifySalesLine(SalesLine, SalesHeader."Shipment Date", PlannedShipmentDate, PlannedDeliveryDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithNoWorkingDate()
    var
        SalesLine: Record "Sales Line";
        ShippingAgentServices: Record "Shipping Agent Services";
        BaseCalendar: Record "Base Calendar";
        BaseCalendarChange: Record "Base Calendar Change";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        ShippingTime: DateFormula;
        PlannedShipmentDate: Date;
        PlannedDeliveryDate: Date;
    begin
        // Setup: Create Shipping agent and its services. Take random shipping time and Create Sales Header and calculate dates.
        Initialize();
        Evaluate(ShippingTime, '<0D>');
        CreateItem(Item);
        CreateBaseCalendar(BaseCalendar);
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange."Recurring System"::"Weekly Recurring", 0D,
          BaseCalendarChange.Day::Monday);
        CreateShippingAgentWithService(ShippingAgentServices, ShippingTime, '');
        CreateSalesHeaderWithRandomShippingTime(SalesHeader, CreateCustomer(ShippingAgentServices, BaseCalendar.Code), '');

        // Exercise: Create a Sales Line.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Verification: Verify Shipment Date, Planned Shipment Date, Planned Delivery Date.
        CalculatePlannedDate(PlannedShipmentDate, PlannedDeliveryDate, SalesLine);
        VerifySalesLine(SalesLine, SalesHeader."Shipment Date", PlannedShipmentDate, PlannedDeliveryDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesWithOutboundWhseHandling()
    var
        SalesLine: Record "Sales Line";
        ShippingAgentServices: Record "Shipping Agent Services";
        BaseCalendar: Record "Base Calendar";
        SalesHeader: Record "Sales Header";
        ShippingTime: DateFormula;
        PlannedShipmentDate: Date;
        PlannedDeliveryDate: Date;
        ShipmentDate: Date;
    begin
        // Setup: Create Shipping agent and its services. Take random shipping time and Calculate Dates.
        Initialize();
        Evaluate(ShippingTime, '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        CreateBaseCalendar(BaseCalendar);
        CreateShippingAgentWithService(ShippingAgentServices, ShippingTime, BaseCalendar.Code);

        // Exercise
        CreateSalesOrder(SalesHeader, SalesLine, CreateCustomer(ShippingAgentServices, ''));

        // Calculate Planned Shipment Date And Planned Delivery Date with No Working Day.
        ShipmentDate := SalesHeader."Shipment Date";
        CalculatePlannedDate(PlannedShipmentDate, PlannedDeliveryDate, SalesLine);

        // Verify: Verify Shipment Date, Planned Shipment Date, Planned Delivery Date.
        VerifySalesLine(SalesLine, ShipmentDate, PlannedShipmentDate, PlannedDeliveryDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesWithLocationNoWorking()
    var
        SalesLine: Record "Sales Line";
        ShippingAgentServices: Record "Shipping Agent Services";
        BaseCalendar: Record "Base Calendar";
        BaseCalendarChange: Record "Base Calendar Change";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        BaseCalendar2: Record "Base Calendar";
        Location: Record Location;
        ShippingTime: DateFormula;
        PlannedShipmentDate: Date;
        PlannedDeliveryDate: Date;
        ShipmentDate: Date;
    begin
        // Setup: Create Shipping agent and its services. Take random shipping time.
        Initialize();
        CreateItem(Item);
        CreateBaseCalendar(BaseCalendar);
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange."Recurring System"::"Weekly Recurring", 0D,
          BaseCalendarChange.Day::Monday);
        CreateBaseCalendar(BaseCalendar2);
        Evaluate(ShippingTime, '<0D>');  // Evaluating Shipping Time to Blank .
        CreateShippingAgentWithService(ShippingAgentServices, ShippingTime, '');
        CreateLocation(Location, BaseCalendar2.Code);
        CreateSalesHeaderWithRandomShippingTime(SalesHeader, CreateCustomer(ShippingAgentServices, BaseCalendar.Code), Location.Code);
        ShipmentDate := SalesHeader."Shipment Date";

        // Exercise: Create a Sales Line.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Verify: Verify Shipment Date, Planned Shipment Date, Planned Delivery Date.
        CalculatePlannedDate(PlannedShipmentDate, PlannedDeliveryDate, SalesLine);
        VerifySalesLine(SalesLine, ShipmentDate, PlannedShipmentDate, PlannedDeliveryDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithOutboundTimeCustomCalendar()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShippingAgentServices: Record "Shipping Agent Services";
        Item: Record Item;
        Location: Record Location;
        BaseCalendar: Record "Base Calendar";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        Shippingtime: DateFormula;
        ExpectedShipmentDate: Date;
        OutboundShippingDays: Integer;
    begin
        // [FEATURE] [Shipment Date] [Shipping Agent Service] [Planning]
        // [SCENARIO 361950] Shipment Date in Sales order is calculated as "Planned Shipment Date" - "Outbound Whse. Shipping Time" with Location calendar, but not with Shipping Agent's one.

        // [GIVEN] Create Shipping Agent Service with custom calendar, 1 working day a week.
        Initialize();
        Evaluate(Shippingtime, '<0D>');  // Evaluating Shipping Time to Blank.
        CreateItem(Item);

        LibraryService.CreateBaseCalendar(BaseCalendar);
        // [GIVEN] Location having regular calendar, 7 working days a week.
        CreateLocation(Location, BaseCalendar.Code);
        CreateShippingAgentWithService(ShippingAgentServices, Shippingtime, BaseCalendar.Code);
        CustomizeCalendar(ShippingAgentServices, BaseCalendar.Code, CustomizedCalendarChange.Day::Monday);

        // [GIVEN] Create Sales Order with Shipping Agent usage, "Shipping Time" = 0D, "Outbound Warehouse Handling Time" >= 1D.
        OutboundShippingDays :=
          CreateSalesHeaderWithRequestedDelivery(
            SalesHeader, CreateCustomer(ShippingAgentServices, ShippingAgentServices."Base Calendar Code"), Location.Code);

        // [WHEN] Create a Sales Line with type of Item.
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // [THEN] Shipment Date in Sales Line is calculated with Location's calendar, but not with Shipping Agent's calendar.
        ExpectedShipmentDate :=
          CalcDate('<-' + Format(OutboundShippingDays) + 'D>', SalesLine."Planned Shipment Date");
        Assert.AreEqual(ExpectedShipmentDate, SalesLine."Shipment Date", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestingItemChargeAsmgtNotAllowedWithZeroQtyToInvoiceOnSalesLine()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
        SalesShpmtNo: Code[20];
    begin
        // [FEATURE] [Sales Order] [Item Charge]
        // [SCENARIO 231399] Suggesting item charge assignment must lead to "Qty. to Invoice must have a value." error when Qty to Invoice is zero

        Initialize();

        // [GIVEN] Create new Item and random stock of it, then post sale of the item
        SalesShpmtNo := CreateItemStockAndSalesShipment(Customer, Item);

        // [GIVEN] Create Sales Order with single line of "Charge (Item)" type and create Item Charge Assignment for it
        CreateItemChargeSalesOrderWithAssignment(ItemChargeAssignmentSales, SalesLine, Customer."No.", Item."No.", 1, SalesShpmtNo);

        // [GIVEN] Set "Qty. to Invoice" to 0 in sales line
        SalesLine.Validate("Qty. to Invoice", 0);
        SalesLine.Modify(true);

        // [WHEN] Trying to Suggest Item Charge Assignment
        asserterror ItemChargeAssgntSales.SuggestAssignment(SalesLine, 0, 0);

        // [THEN] Expected error: "Qty. to Invoice must have a value."
        Assert.ExpectedError(SuggestAssignmentErr);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler')]
    [Scope('OnPrem')]
    procedure CreatingItemChargeAsmgtNotAllowedWithZeroQtyToInvoiceOnSalesLine()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales Order] [Item Charge]
        // [SCENARIO 231399] Creating item charge assignment by Get Shipment Lines action must lead to "Qty. to Invoice must have a value." error when Qty to Invoice is zero

        Initialize();

        // [GIVEN] Create Sales Order with single line of "Charge (Item)" type
        LibrarySales.CreateCustomer(Customer);
        CreateItemChargeSalesOrder(SalesLine, Customer."No.", 1);

        // [GIVEN] Set "Qty. to Invoice" to 0 in sales line
        SalesLine.Validate("Qty. to Invoice", 0);
        SalesLine.Modify(true);

        // [WHEN] Start item assignment page and invoke Get Shipment Lines action
        asserterror SalesLine.ShowItemChargeAssgnt();

        // [THEN] Expected error: "Qty. to Invoice must have a value."
        Assert.ExpectedError(SuggestAssignmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillingInQtyToAssgnItemChargeAsmgtNotAllowedWithZeroQtyToInvoiceOnSalesLine()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesShpmtNo: Code[20];
    begin
        // [FEATURE] [Sales Order] [Item Charge]
        // [SCENARIO 231399] Filling in Qty. to Assign field in existing item charge assignment must lead to "Qty. to Invoice must have a value." error when Qty to Invoice is zero

        Initialize();

        // [GIVEN] Create new Item and random stock of it, then post sale of the item
        SalesShpmtNo := CreateItemStockAndSalesShipment(Customer, Item);

        // [GIVEN] Create Sales Order with single line of "Charge (Item)" type and create Item Charge Assignment for it
        CreateItemChargeSalesOrderWithAssignment(ItemChargeAssignmentSales, SalesLine, Customer."No.", Item."No.", 1, SalesShpmtNo);

        // [GIVEN] Set "Qty. to Invoice" to 0 in sales line
        SalesLine.Validate("Qty. to Invoice", 0);
        SalesLine.Modify(true);

        // [WHEN] Trying to set Qty. to Assign
        asserterror ItemChargeAssignmentSales.Validate("Qty. to Assign", LibraryRandom.RandInt(100));

        // [THEN] Expected error: "Qty. to Invoice must have a value."
        Assert.ExpectedError(SuggestAssignmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLinePlannedShipmentDateDoesntUseCustomerCalendar()
    var
        BaseCalendar: array[2] of Record "Base Calendar";
        BaseCalendarChange: Record "Base Calendar Change";
        ShippingAgentServices: Record "Shipping Agent Services";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShippingTime: DateFormula;
        CustomerNo: Code[20];
    begin
        // [SCENARIO 292658] Sales Line Planned Shipment Date is not affected by Customer Calendar
        Initialize();

        Evaluate(ShippingTime, '<1D>');

        // [GIVEN] Customer with Base Calendar where 16-01-2020 is non-working, Shipping time = 1D
        LibraryService.CreateBaseCalendar(BaseCalendar[1]);
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendar[1].Code, BaseCalendarChange."Recurring System"::" ", WorkDate() + 1, BaseCalendarChange.Day::" ");
        CreateShippingAgentWithService(ShippingAgentServices, ShippingTime, '');
        CustomerNo := CreateCustomer(ShippingAgentServices, BaseCalendar[1].Code);

        // [GIVEN] Location with Base Calendar
        LibraryService.CreateBaseCalendar(BaseCalendar[2]);
        CreateLocation(Location, BaseCalendar[2].Code);

        // [GIVEN] A Sales Line for Customer with Location
        CreateSalesHeader(SalesHeader, CustomerNo, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Location Code", Location.Code);

        // [WHEN] Validating Planned Delivery Date to 17-01-2020
        SalesLine.Validate("Planned Delivery Date", WorkDate() + 2);

        // [THEN] Planned Shipment Date = 16-01-2020
        SalesLine.TestField("Planned Shipment Date", WorkDate() + 1);

        // [THEN] Shipment Date = 16-01-2020
        SalesLine.TestField("Shipment Date", WorkDate() + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLinePlannedShipmentDateUsesLocationCalendar()
    var
        BaseCalendar: array[2] of Record "Base Calendar";
        BaseCalendarChange: Record "Base Calendar Change";
        ShippingAgentServices: Record "Shipping Agent Services";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShippingTime: DateFormula;
        CustomerNo: Code[20];
    begin
        // [SCENARIO 292658] Sales Line Planned Shipment Date uses Location Calendar
        Initialize();

        Evaluate(ShippingTime, '<1D>');

        // [GIVEN] Customer with Base Calendar, Shipping time = 1D
        LibraryService.CreateBaseCalendar(BaseCalendar[1]);
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendar[1].Code, BaseCalendarChange."Recurring System"::" ", WorkDate() + 1, BaseCalendarChange.Day::" ");
        CreateShippingAgentWithService(ShippingAgentServices, ShippingTime, '');
        CustomerNo := CreateCustomer(ShippingAgentServices, BaseCalendar[1].Code);

        // [GIVEN] Location with Base Calendar where 16-01-2020 is non-working
        LibraryService.CreateBaseCalendar(BaseCalendar[2]);
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendar[2].Code, BaseCalendarChange."Recurring System"::" ", WorkDate() + 1, BaseCalendarChange.Day::" ");
        CreateLocation(Location, BaseCalendar[2].Code);

        // [GIVEN] A Sales Line for Customer with Location
        CreateSalesHeader(SalesHeader, CustomerNo, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Location Code", Location.Code);

        // [WHEN] Validating Planned Delivery Date to 17-01-2020
        SalesLine.Validate("Planned Delivery Date", WorkDate() + 2);

        // [THEN] Planned Shipment Date = 15-01-2020
        SalesLine.TestField("Planned Shipment Date", WorkDate());

        // [THEN] Shipment Date = 15-01-2020
        SalesLine.TestField("Shipment Date", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLinePlannedShipmentDateUsesAgentCalendarForShippingTime()
    var
        BaseCalendar: array[2] of Record "Base Calendar";
        BaseCalendarChange: Record "Base Calendar Change";
        ShippingAgentServices: Record "Shipping Agent Services";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShippingTime: DateFormula;
        CustomerNo: Code[20];
    begin
        // [SCENARIO 292658] When calculating Sales Line Planned Shipment Date use only Agent's calendar for Shipping Time.
        Initialize();

        // [GIVEN] Shipping Agent with Base Calendar where 17-01-2020 in non-working and Shipping Time 2D
        LibraryService.CreateBaseCalendar(BaseCalendar[2]);
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendar[2].Code, BaseCalendarChange."Recurring System"::" ", WorkDate() + 2, BaseCalendarChange.Day::" ");
        Evaluate(ShippingTime, '<2D>');
        CreateShippingAgentWithService(ShippingAgentServices, ShippingTime, BaseCalendar[2].Code);

        // [GIVEN] Customer with Base Calendar, using Shipping Agent
        LibraryService.CreateBaseCalendar(BaseCalendar[1]);
        CustomerNo := CreateCustomer(ShippingAgentServices, BaseCalendar[1].Code);

        // [GIVEN] Location with Base Calendar
        CreateLocation(Location, BaseCalendar[1].Code);

        // [GIVEN] A Sales Line for Customer with Location
        CreateSalesHeaderWithCustomerAndLocation(SalesHeader, CustomerNo, Location.Code);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));

        // [WHEN] Validating Planned Delivery Date to 19-01-2020
        SalesLine.Validate("Planned Delivery Date", WorkDate() + 4);

        // [THEN] Planned Shipment Date = 16-01-2020
        SalesLine.TestField("Planned Shipment Date", WorkDate() + 1);

        // [THEN] Shipment Date = 16-01-2020
        SalesLine.TestField("Shipment Date", WorkDate() + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPreviewDoesNotCommitShipment()
    var
        BaseCalendar: array[2] of Record "Base Calendar";
        ShippingAgentServices: Record "Shipping Agent Services";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SCMSalesOrderManagement: Codeunit "SCM Sales Order Management";
        ErrorMessagesPage: TestPage "Error Messages";
        CustomerNo: Code[20];
    begin
        Initialize();
        BindSubscription(SCMSalesOrderManagement);

        // [GIVEN] Customer with Base Calendar, using Shipping Agent
        LibraryService.CreateBaseCalendar(BaseCalendar[1]);
        CustomerNo := CreateCustomer(ShippingAgentServices, BaseCalendar[1].Code);

        // [GIVEN] A Sales Line for Customer with Location
        CreateSalesHeader(SalesHeader, CustomerNo, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        Commit();

        // [WHEN] Run the Preview
        ErrorMessagesPage.Trap();
        asserterror LibrarySales.PreviewPostSalesDocument(SalesHeader);

        // [THEN] The COMMIT in the subscriber is stopped because of a transaction error
        Assert.ExpectedError('');
        Assert.ExpectedMessage('Commit is prohibited in the current scope.', ErrorMessagesPage.Description.Value);
    end;

    [Test]
    procedure PlannedDeliveryDateUpdatedWhenShippingAgentServiceCodeIsCleared()
    var
        Item: Record Item;
        ShippingAgentServices: Record "Shipping Agent Services";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShippingTime: array[2] of DateFormula;
    begin
        // [FEATURE] [Shipping Agent Service]
        // [SCENARIO 433870] Planned Delivery Date is updated when a user clears Shipping Agent Service Code on sales line so that Shipping Time is inherited from the header.
        Initialize();
        Evaluate(ShippingTime[1], '<' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'D>');
        Evaluate(ShippingTime[2], '<' + Format(LibraryRandom.RandIntInRange(11, 20)) + 'D>');

        // [GIVEN] Shipping Agent Service Code "X". Set "Shipping Time" = 5D.
        CreateItem(Item);
        CreateShippingAgentWithService(ShippingAgentServices, ShippingTime[1], '');

        // [GIVEN] Sales order header. Set "Shipping Time" = 15D.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Shipping Time", ShippingTime[2]);
        SalesHeader.Modify(true);

        // [GIVEN] Sales order line. Select Shipping Agent Service Code = "X".
        // [GIVEN] Ensure that "Shipping Time" = 5D, "Planned Delivery Date" = WorkDate() + 5 days.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Shipping Agent Code", ShippingAgentServices."Shipping Agent Code");
        SalesLine.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);
        SalesLine.TestField("Shipping Time", ShippingTime[1]);
        SalesLine.TestField("Planned Delivery Date", CalcDate(ShippingTime[1], SalesLine."Shipment Date"));

        // [GIVEN] Clear "Shipping Time" on the sales order line.
        Clear(Salesline."Shipping Time");

        // [WHEN] Now clear "Shipping Agent Service Code" too.
        SalesLine.Validate("Shipping Agent Service Code", '');

        // [THEN] "Shipping Time" got updated from the sales header (= 15D).
        // [THEN] "Planned Delivery Date" = WorkDate() + 15 days.
        SalesLine.TestField("Shipping Time", ShippingTime[2]);
        SalesLine.TestField("Planned Delivery Date", CalcDate(ShippingTime[2], SalesLine."Shipment Date"));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Sales Order Management");
        // Lazy Setup.
        if IsInitialised then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Sales Order Management");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialised := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Sales Order Management");
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateShippingAgentServices(var ShippingAgentServices: Record "Shipping Agent Services"; ShippingAgentCode: Code[10]; BaseCalendarCode: Code[10]; ShippingTime: DateFormula)
    begin
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgentCode, ShippingTime);
        ShippingAgentServices.Validate("Base Calendar Code", BaseCalendarCode);
        ShippingAgentServices.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Modify(true);
    end;

    local procedure CreateItemChargeAssignmentSales(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; SalesLine: Record "Sales Line"; AppliesToDocNo: Code[20]; AppliesToDocLineNo: Integer; ItemNo: Code[20]; QtyToAssign: Decimal)
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.Get(SalesLine."No.");
        LibrarySales.CreateItemChargeAssignment(ItemChargeAssignmentSales, SalesLine, ItemCharge,
          ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment, AppliesToDocNo, AppliesToDocLineNo,
          ItemNo, QtyToAssign, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateItemChargeSalesOrderWithAssignment(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; SalesShpmtNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        CreateItemChargeSalesOrder(SalesLine, CustomerNo, Quantity);

        SalesShipmentLine.SetRange("Document No.", SalesShpmtNo);
        SalesShipmentLine.FindFirst();
        CreateItemChargeAssignmentSales(ItemChargeAssignmentSales, SalesLine, SalesShpmtNo, SalesShipmentLine."Line No.", ItemNo, 1);
    end;

    local procedure CreateItemChargeSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", '', Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateItemStockAndSalesShipment(var Customer: Record Customer; var Item: Record Item): Code[20]
    var
        Quantity: Decimal;
    begin
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandInt(100);
        CreateAndPostItemJournalLine(Item."No.", Quantity, '');

        LibrarySales.CreateCustomer(Customer);
        exit(CreateSalesOrderAndPost(Customer."No.", Item."No.", Quantity));
    end;

    local procedure CreateCustomer(ShippingAgentServices: Record "Shipping Agent Services"; BaseCalanderCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Shipping Advice", Customer."Shipping Advice"::Partial);
        Customer.Validate("Shipping Agent Code", ShippingAgentServices."Shipping Agent Code");
        Customer.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);
        Customer.Validate("Base Calendar Code", BaseCalanderCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    var
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        Evaluate(SalesHeader."Outbound Whse. Handling Time", '<0D>');  // Evaluating Handling Time to Blank .
        SalesHeader.Validate("Outbound Whse. Handling Time");
        SalesHeader.Modify(true);
        CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesOrderAndPost(CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure CreateSalesHeaderWithRandomShippingTime(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; LocationCode: Code[10])
    var
        ShippingTime: DateFormula;
    begin
        Evaluate(ShippingTime, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CreateSalesHeader(SalesHeader, CustomerNo, LocationCode, ShippingTime);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; LocationCode: Code[10])
    var
        OutboundWhseHandlingTime: DateFormula;
        ShipmentDate: Date;
    begin
        Evaluate(OutboundWhseHandlingTime, '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        ShipmentDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Validate("Outbound Whse. Handling Time", OutboundWhseHandlingTime);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; LocationCode: Code[10]; ShippingTime: DateFormula)
    begin
        CreateSalesHeader(SalesHeader, CustomerNo, LocationCode);
        SalesHeader.Validate("Shipping Time", ShippingTime);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesHeaderWithCustomerAndLocation(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; AssignType: Enum "Sales Line Type"; AssignNo: Code[20]; AssignQuantity: Decimal)
    var
        RecRef: RecordRef;
    begin
        with SalesLine do begin
            Init();
            Validate("Document Type", SalesHeader."Document Type");
            Validate("Document No.", SalesHeader."No.");
            RecRef.GetTable(SalesLine);
            Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No.")));
            Insert(true);

            Validate(Type, AssignType);
            Validate("No.", AssignNo);
            Validate(Quantity, AssignQuantity);
            Modify(true);
        end;
    end;

    local procedure CreateSalesHeaderWithRequestedDelivery(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; LocationCode: Code[10]) OutboundHandlingDays: Integer
    var
        OutboundWhseHandlingTime: DateFormula;
        ShippingTime: DateFormula;
        RequestedDeliveryDate: Date;
    begin
        Evaluate(ShippingTime, '<0D>');
        OutboundHandlingDays := LibraryRandom.RandIntInRange(1, 3);
        Evaluate(OutboundWhseHandlingTime, '<' + Format(OutboundHandlingDays) + 'D>');
        RequestedDeliveryDate := CalcDate('<' + Format(LibraryRandom.RandIntInRange(30, 50)) + 'D>', WorkDate());
        with SalesHeader do begin
            LibrarySales.CreateSalesHeader(SalesHeader, "Document Type"::Order, CustomerNo);
            Validate("Location Code", LocationCode);
            Validate("Shipment Date", 0D);
            Validate("Outbound Whse. Handling Time", OutboundWhseHandlingTime);
            Validate("Shipping Time", ShippingTime);
            Validate("Requested Delivery Date", RequestedDeliveryDate);
            Modify(true);
        end;
    end;

    local procedure CreateLocation(var Location: Record Location; BaseCalendarCode: Code[10])
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Base Calendar Code", BaseCalendarCode);
        Location.Modify(true);
    end;

    local procedure CreateShippingAgentWithService(var ShippingAgentServices: Record "Shipping Agent Services"; ShippingTime: DateFormula; BaseCalendarCode: Code[10])
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        CreateShippingAgentServices(ShippingAgentServices, ShippingAgent.Code, BaseCalendarCode, ShippingTime);
    end;

    local procedure CreateBaseCalendar(var BaseCalendar: Record "Base Calendar")
    var
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange."Recurring System"::"Weekly Recurring", 0D,
          BaseCalendarChange.Day::Sunday);
    end;

    local procedure CustomizeCalendar(ShippingAgentServices: Record "Shipping Agent Services"; BaseCalendarCode: Code[10]; SetWorkingDay: Option)
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
        WeekDay: Option;
    begin
        with CustomizedCalendarChange do
            for WeekDay := Day::Monday to Day::Sunday do
                if WeekDay <> SetWorkingDay then
                    LibraryService.CreateCustomizedCalendarChange(
                      BaseCalendarCode, CustomizedCalendarChange, "Source Type"::"Shipping Agent".AsInteger(),
                      ShippingAgentServices."Shipping Agent Code", ShippingAgentServices.Code,
                      "Recurring System"::"Weekly Recurring", WeekDay, true);
    end;

    local procedure CalculatePlannedDate(var PlannedShipmentDate: Date; var PlannedDeliveryDate: Date; SalesLine: Record "Sales Line")
    var
        CustomizedCalendarChange: array[2] of Record "Customized Calendar Change";
    begin
        CustomizedCalendarChange[1].SetSource(CustomizedCalendarChange[1]."Source Type"::Location, SalesLine."Location Code", '', '');
        CustomizedCalendarChange[2].SetSource(
            CustomizedCalendarChange[2]."Source Type"::"Shipping Agent", SalesLine."Shipping Agent Code", SalesLine."Shipping Agent Service Code", '');
        PlannedShipmentDate :=
            CalendarMgt.CalcDateBOC(Format(SalesLine."Outbound Whse. Handling Time"), SalesLine."Shipment Date", CustomizedCalendarChange, true);

        CustomizedCalendarChange[1].SetSource(
            CustomizedCalendarChange[1]."Source Type"::"Shipping Agent", SalesLine."Shipping Agent Code", SalesLine."Shipping Agent Service Code", '');
        CustomizedCalendarChange[2].SetSource(CustomizedCalendarChange[2]."Source Type"::Customer, SalesLine."Sell-to Customer No.", '', '');
        PlannedDeliveryDate :=
            CalendarMgt.CalcDateBOC(Format(SalesLine."Shipping Time"), SalesLine."Planned Shipment Date", CustomizedCalendarChange, true);
    end;

    local procedure VerifySalesLine(SalesLine: Record "Sales Line"; ShipmentDate: Date; PlannedShipmentDate: Date; PlannedDeliveryDate: Date)
    begin
        SalesLine.TestField("Shipment Date", ShipmentDate);
        SalesLine.TestField("Planned Shipment Date", PlannedShipmentDate);
        SalesLine.TestField("Planned Delivery Date", PlannedDeliveryDate);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales.GetShipmentLines.Invoke();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Shipment Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnInsertShipmentHeader(var Rec: Record "Sales Shipment Header"; RunTrigger: Boolean)
    begin
        Commit();
    end;
}

