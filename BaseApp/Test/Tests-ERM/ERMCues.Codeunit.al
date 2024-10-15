codeunit 134924 "ERM Cues"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cue]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryService: Codeunit "Library - Service";
        WrongValueErr: Label 'Wrong value of the field %1 in table %2.';
        AverageDaysDelayedErr: Label 'Average Days Delayed is calculated incorrectly.';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySales: Codeunit "Library - Sales";
        ShipStatus: Option Full,Partial,"Not Shipped";
        WrongNumberOfDelayedOrdersErr: Label 'Wrong number of delayed Sales Orders.';
        RedundantSalesOnListErr: Label 'List of delayed Sales Order contains redundant documents.';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCueFlowFields()
    var
        SalesHeader: Record "Sales Header";
        SalesCue: Record "Sales Cue";
        SOActivitiesCalculate: Codeunit "SO Activities Calculate";
        Parameters: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
    begin
        // [FEATURE] [Sales Cue] [SB Owner Cue]
        // [SCENARIO 347046] Cues in Sales Cue and SB Owner Cue display number of sales documents of corresponding type, status and ship state.
        Initialize();

        // [GIVEN] Several not shipped sales documents with different types and statuses, covering all activities shown in Sales Cue and SB Owner Cue.
        // [GIVEN] Partially and fully shipped sales orders.
        CreateResponsibilityCenterAndUserSetup();
        MockSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesHeader.Status::Open);
        MockSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, SalesHeader.Status::Open);
        MockSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesHeader.Status::Released);
        MockSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader.Status::Open);
        MockSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader.Status::Open);
        CreateShippedSalesOrder(SalesHeader, ShipStatus::Full);
        CreateShippedSalesOrder(SalesHeader, ShipStatus::Partial);

        // [WHEN] Calculate flow fields in Sales Cue and SB Owner Cue.
        // [THEN] All cues display correct number of corresponding sales documents.
        VerifySalesCueFlowFields();
        VerifySBOwnerCueNestedFlowField();

        // Bug: 410793
        Parameters.Add('View', SalesCue.GetView());
        SOActivitiesCalculate.CalculateFieldValues(Parameters, Results);
        SOActivitiesCalculate.EvaluateResults(Results, SalesCue);

        VerifySalesCueNonFlowFieldCalculated(SalesCue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCueFlowFields()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase Cue]
        // [SCENARIO 347046] Cues in Purchase Cue display number of purchase documents of corresponding type, status and receive state.
        Initialize();

        // [GIVEN] Several purchase documents with different types and statutes, covering all activities shown in Purchase Cue.
        CreateResponsibilityCenterAndUserSetup();
        CreatePurchDocument(PurchHeader."Document Type"::Order, PurchHeader.Status::Open, false, false, false);
        CreatePurchDocument(PurchHeader."Document Type"::Order, PurchHeader.Status::Released, false, false, false);
        CreatePurchDocument(PurchHeader."Document Type"::Order, PurchHeader.Status::Released, true, false, false);
        CreatePurchDocument(PurchHeader."Document Type"::"Return Order", PurchHeader.Status::Released, false, false, false);
        CreatePurchDocument(PurchHeader."Document Type"::Order, PurchHeader.Status::Released, false, true, false);
        CreatePurchDocument(PurchHeader."Document Type"::Order, PurchHeader.Status::Released, false, true, true);

        // [WHEN] Calculate flow fields in Purchase Cue.
        // [THEN] All cues display correct number of corresponding purchase documents.
        VerifyPurchCueFlowFields();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SelectTemplateHandler')]
    [Scope('OnPrem')]
    procedure ServCueFlowFields()
    var
        ServHeader: Record "Service Header";
    begin
        // [FEATURE] [Service Cue]
        // [SCENARIO 347046] Cues in Service Cue display number of service documents and service contracts of corresponding type and status.
        Initialize();

        // [GIVEN] Several service documents and service contrancts with different types and statutes, covering all activities shown in Service Cue.
        CreateResponsibilityCenterAndUserSetup();
        with ServHeader do begin
            CreateServDocument("Document Type"::Order, Status::"In Process");
            CreateServDocument("Document Type"::Order, Status::Finished);
            CreateServDocument("Document Type"::Order, Status::"On Hold");
            CreateServDocument("Document Type"::Quote, Status::Pending);
        end;
        CreateServContract("Service Contract Type"::Quote);
        CreateServContract("Service Contract Type"::Contract);

        // [WHEN] Calculate flow fields in Service Cue.
        // [THEN] All cues display correct number of corresponding service documents and service contracts.
        VerifyServCueFlowFields();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCueInvoicedFlowFields()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales Cue] [Partial Shipment]
        // [SCENARIO 377251] Sales Cue "Partially Shipped" number corresponds to partially shipped orders, if one has been invoiced partially after shipment.
        Initialize();

        // [GIVEN] Create Sales Order, shipped partially, then invoice partially.
        CreateResponsibilityCenterAndUserSetup();
        CreateShippedSalesOrder(SalesHeader, ShipStatus::Partial);

        // [WHEN] Calculate flow field "Partially Shipped" in Sales Cue.
        // [THEN] Sales Cue "Partially Shipped" shows total number of 1.
        VerifySalesCueFlowFieldsPartiallyShipped();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTSalesHeaderShippedNoLines()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales Cue] [Partial Shipment] [UT]
        // [SCENARIO 377251] Sales Order with no lines has Shipped = FALSE
        Initialize();

        with SalesHeader do begin
            MockSalesHeader(SalesHeader, "Document Type"::Order, Status::Released);

            CalcFields(Shipped);

            TestField(Shipped, false);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTSalesHeaderShippedOneLineNotShipped()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales Cue] [Partial Shipment] [UT]
        // [SCENARIO 377251] Sales Order with one line with "Qty. Shipped (Base)" = 0 has Shipped = FALSE
        Initialize();

        with SalesHeader do begin
            CreateShippedSalesOrder(SalesHeader, ShipStatus::"Not Shipped");

            CalcFields(Shipped);

            TestField(Shipped, false);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTSalesHeaderShippedOneLineShipped()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales Cue] [Partial Shipment] [UT]
        // [SCENARIO 377251] Sales Order with one line with "Qty. Shipped (Base)" > 0 has Shipped = TRUE
        Initialize();

        with SalesHeader do begin
            CreateShippedSalesOrder(SalesHeader, ShipStatus::Full);

            CalcFields(Shipped);

            TestField(Shipped, true);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTSalesHeaderShippedTwoLinesOneShipped()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Qty: Integer;
    begin
        // [FEATURE] [Sales Cue] [Partial Shipment] [UT]
        // [SCENARIO 377251] Sales Order with two lines (line 1 partially shipped, line 2 not shipped) has Shipped = TRUE
        Initialize();

        Qty := LibraryRandom.RandInt(10);

        with SalesHeader do begin
            MockSalesHeader(SalesHeader, "Document Type"::Order, Status::Released);
            MockSalesLine(SalesHeader, SalesLine, WorkDate(), Qty, 0);
            MockSalesLine(SalesHeader, SalesLine, WorkDate(), Qty, Qty);

            CalcFields(Shipped);

            TestField(Shipped, true);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTSalesHeaderShippedTwoDocsOneShipped()
    var
        SalesHeader: array[2] of Record "Sales Header";
    begin
        // [FEATURE] [Sales Cue] [Partial Shipment] [UT]
        // [SCENARIO 377251] Two Sales Orders - SO1 with not shipped line, SO2 with partially shipped line, SO1 Shipped = FALSE
        Initialize();

        CreateShippedSalesOrder(SalesHeader[1], ShipStatus::"Not Shipped");
        CreateShippedSalesOrder(SalesHeader[2], ShipStatus::Partial);

        SalesHeader[1].CalcFields(Shipped);

        SalesHeader[1].TestField(Shipped, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NumberOfDelayedOrdersOnSalesCue()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesCue: Record "Sales Cue";
        Delays: array[2] of Integer;
        OldNumberOfDelayedOrders: Integer;
        NewNumberOfDelayedOrders: Integer;
    begin
        // [FEATURE] [Sales Cue]
        // [SCENARIO 380585] Sales Order is considered delayed if there is an outstanding Sales Line with "Shipment Date" < WORKDATE.
        Initialize();

        // [GIVEN] Two Sales Orders "S1" and "S2".
        // [GIVEN] "S1" has two partially shipped Sales Lines with "Shipment Date" < WORKDATE and one line with blank "Shipment Date".
        // [GIVEN] "S2" has a fully shipped line and a line with "Shipment Date" in future.
        CreateTwoSalesOrdersWithVariedDateAndShipLines(SalesHeader, Delays);

        // [GIVEN] Number of delayed orders is counted and saved.
        SalesCue.SetRange("Date Filter", 0D, WorkDate() - 1);
        OldNumberOfDelayedOrders := SalesCue.CountOrders(SalesCue.FieldNo(Delayed));

        // [GIVEN] Sales Order "S2" is deleted.
        SalesHeader[2].Delete();

        // [WHEN] Count the number of delayed orders again.
        NewNumberOfDelayedOrders := SalesCue.CountOrders(SalesCue.FieldNo(Delayed));

        // [THEN] The number of delayed sales orders does not change.
        Assert.AreEqual(OldNumberOfDelayedOrders, NewNumberOfDelayedOrders, WrongNumberOfDelayedOrdersErr);

        // [THEN] The number of delayed sales orders = 1.
        Assert.AreEqual(1, NewNumberOfDelayedOrders, WrongNumberOfDelayedOrdersErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ListOfDelayedOrdersOnSalesCue()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesCue: Record "Sales Cue";
        SalesOrderList: TestPage "Sales Order List";
        Delays: array[2] of Integer;
    begin
        // [FEATURE] [Sales Cue]
        // [SCENARIO 380585] List of delayed Sales Orders only contains documents that have lines with outstanding quantity and "Shipment Date" < WORKDATE.
        Initialize();

        // [GIVEN] Two Sales Orders "S1" and "S2".
        // [GIVEN] "S1" has two partially shipped Sales Lines with "Shipment Date" < WORKDATE and one line with blank "Shipment Date".
        // [GIVEN] "S2" has a fully shipped line and a line with "Shipment Date" in future.
        CreateTwoSalesOrdersWithVariedDateAndShipLines(SalesHeader, Delays);

        // [WHEN] Show the list of delayed orders.
        SalesOrderList.Trap();
        SalesCue.SetRange("Date Filter", 0D, WorkDate() - 1);
        SalesCue.ShowOrders(SalesCue.FieldNo(Delayed));

        // [THEN] Sales Order "S1" is on the list.
        SalesOrderList.First();
        SalesOrderList."No.".AssertEquals(SalesHeader[1]."No.");

        // [THEN] No more Sales Orders are on the list.
        Assert.IsFalse(SalesOrderList.Next(), RedundantSalesOnListErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AverageDaysDelayedOnSalesCue()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesCue: Record "Sales Cue";
        FirstDelays: array[2] of Integer;
        SecondDelays: array[2] of Integer;
        AverageDelayExpected: Decimal;
        AverageDelayActual: Decimal;
    begin
        // [FEATURE] [Sales Cue]
        // [SCENARIO 380585] "Average Days Delayed" cue is calculated as an average delay among delayed Sales Orders. Delay of Sales Order is equal to a maximum delay among Sales Lines.
        Initialize();

        // [GIVEN] Two pairs of Sales Orders ("X1", "X2") and ("Y1", "Y2").
        // [GIVEN] "X1" and "Y1" have two partially shipped Sales Lines with "Shipment Date" < WORKDATE
        // [GIVEN] (I.e. "X1" has lines with 3 and 8 days of delay, "Y1" has lines with 10 and 20 days of delay).
        // [GIVEN] "X2" and "Y2" have fully shipped lines and lines with "Shipment Date" in future.
        CreateTwoSalesOrdersWithVariedDateAndShipLines(SalesHeader, FirstDelays);
        CreateTwoSalesOrdersWithVariedDateAndShipLines(SalesHeader, SecondDelays);

        // [WHEN] Calculate "Average Days Delayed".
        SalesCue.SetRange("Date Filter", 0D, WorkDate() - 1);
        AverageDelayActual := SalesCue.CalculateAverageDaysDelayed();

        // [THEN] "Average Days Delayed" is equal to average delay of "X1" and "Y1"
        // [THEN] (In the example, average delay of "X1" = max(3, 8) = 8, "X2" = max(10, 20) = 20. "Average Days Delayed" = (8 + 20) / 2 = 14 days).
        AverageDelayExpected := (Maximum(FirstDelays[1], FirstDelays[2]) + Maximum(SecondDelays[1], SecondDelays[2])) / 2;
        Assert.AreEqual(AverageDelayExpected, AverageDelayActual, AverageDaysDelayedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AverageDaysDelayedOnSalesCueIsZeroForShippedOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCue: Record "Sales Cue";
        AverageDaysDelayed: Decimal;
        Qty: Integer;
    begin
        // [FEATURE] [Sales Cue]
        // [SCENARIO 380585] "Average Days Delayed" cue reads 0 when a Sales Line is fully shipped.
        Initialize();

        // [GIVEN] Released Sales Order with fully shipped Sales Line and "Shipment Date" < WORKDATE.
        Qty := LibraryRandom.RandInt(10);
        MockSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesHeader.Status::Released);
        MockSalesLine(SalesHeader, SalesLine, WorkDate() - LibraryRandom.RandInt(10), Qty, Qty);

        // [WHEN] Calculate "Average Days Delayed".
        SalesCue.SetRange("Date Filter", 0D, WorkDate() - 1);
        AverageDaysDelayed := SalesCue.CalculateAverageDaysDelayed();

        // [THEN] "Average Days Delayed" = 0.
        Assert.AreEqual(0, AverageDaysDelayed, AverageDaysDelayedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AverageDaysDelayedOnSalesCueIsZeroForBlankShipmentDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCue: Record "Sales Cue";
        AverageDaysDelayed: Decimal;
    begin
        // [FEATURE] [Sales Cue]
        // [SCENARIO 380585] "Average Days Delayed" cue reads 0 when a Sales Line has blank "Shipment Date".
        Initialize();

        // [GIVEN] Released Sales Order with partially shipped Sales Line and blank "Shipment Date".
        MockSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesHeader.Status::Released);
        MockSalesLine(
          SalesHeader, SalesLine, 0D, LibraryRandom.RandIntInRange(11, 20), LibraryRandom.RandInt(10));

        // [WHEN] Calculate "Average Days Delayed".
        SalesCue.SetRange("Date Filter", 0D, WorkDate() - 1);
        AverageDaysDelayed := SalesCue.CalculateAverageDaysDelayed();

        // [THEN] "Average Days Delayed" = 0.
        Assert.AreEqual(0, AverageDaysDelayed, AverageDaysDelayedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseWMSCueFlowFields()
    begin
        // [FEATURE] [Warehouse WMS Cue] [UT]
        // [SCENARIO 380096] "Posted Shipments - Today" cue in Warehouse WMS Cue shows number of Posted Whse. Shipments within period "Date Filter2".
        Initialize();

        // [GIVEN] Posted Whse. Shipment. Posting Date = WORKDATE.
        MockPostedWhseShipmentHeader();

        // [WHEN] Calculate flow field "Posted Shipments - Today" in Warehouse WMS Cue.
        // [THEN] There is one Posted Whse. Shipment within the period "Date Filter2" and no Posted Whse. Shipments within the period "Date Filter".
        VerifyWarehouseWMSCueFlowFields();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoicesDueTodayIsFoundOnSBOwnerCue()
    var
        SmallBusinessOwnerAct: TestPage "Small Business Owner Act.";
    begin
        // [FEATURE] [SB Owner Cue]
        // [SCENARIO 380096] "Purchase Invoices Due Today" on SB Owner Cue shows number of Vendor Ledger Entries with "Due Date" <= WORKDATE
        Initialize();

        // [GIVEN] Vendor Ledger Entry with Due Date <= WORKDATE.
        MockVendorLedgerEntry(WorkDate() - LibraryRandom.RandIntInRange(0, 10));

        // [WHEN] Small Business Owner Act page is shown.
        SmallBusinessOwnerAct.OpenView();

        // [THEN] "Purchase Invoices Due Today" = 1.
        SmallBusinessOwnerAct."Purchase Documents Due Today".AssertEquals(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoicesDueTodayIsNotFoundOnSBOwnerCue()
    var
        SmallBusinessOwnerAct: TestPage "Small Business Owner Act.";
    begin
        // [FEATURE] [SB Owner Cue]
        // [SCENARIO 380096] "Purchase Invoices Due Today" on SB Owner Cue shows 0 if no Vendor Ledger Entries are within the period 0D..WORKDATE.
        Initialize();

        // [GIVEN] Vendor Ledger Entry with Due Date > WORKDATE.
        MockVendorLedgerEntry(WorkDate() + LibraryRandom.RandInt(10));

        // [WHEN] Small Business Owner Act page is shown.
        SmallBusinessOwnerAct.OpenView();

        // [THEN] "Purchase Invoices Due Today" = 0.
        SmallBusinessOwnerAct."Purchase Documents Due Today".AssertEquals(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationFilterForBlankLocationOnWhseWMSCue()
    var
        WarehouseWMSCue: Record "Warehouse WMS Cue";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Warehouse WMS Cue] [Location] [UT]
        // [SCENARIO 208416] GetEmployeeLocation function in Warehouse WMS Cue should return a valid filter for blank location.
        Initialize();

        // [GIVEN] Sales Order on blank location.
        MockSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesHeader.Status::Open);

        // [WHEN] Filter Sales Orders by blank location code using the filter returned by GetEmployeeLocation function in Warehouse WMS Cue.
        SalesHeader.SetFilter("Location Code", WarehouseWMSCue.GetEmployeeLocation(''));

        // [THEN] The filter is valid. The Sales Order is within the filter.
        Assert.RecordIsNotEmpty(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationFilterFromGetEmployeeLocation()
    var
        Location: array[10] of Record Location;
        WarehouseEmployee: array[5] of Record "Warehouse Employee";
        WarehouseWMSCue: Record "Warehouse WMS Cue";
        Index: Integer;
        FilterValue: Text[1024];
        LocationRange: Text[40];
        LocationSelection: Text[30];
        ExpectedLocationFilter: Text[1024];
    begin
        // [FEATURE] [UT] [Location]
        // [SCENARIO 338933] WarehouseWMSCue.GetEmployeeLocation returns Locations filter created using SelectionFilterManagement codeunit
        Initialize();
        WarehouseEmployee[1].DeleteAll();

        // [GIVEN] 10 Locations "L001..L010" where "L001..L003" and "L007" and "L009" are assigned to a WarehouseEmployee
        for Index := 1 to ArrayLen(Location) do
            LibraryWarehouse.CreateLocation(Location[Index]);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee[1], Location[1].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee[2], Location[2].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee[3], Location[3].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee[4], Location[7].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee[5], Location[9].Code, false);

        // [WHEN] Run WarehouseWMSCue.GetEmployeeLocation to get filter for allowed Warehouse Employee locations
        FilterValue := WarehouseWMSCue.GetEmployeeLocation(UserId);

        // [THEN] Verify filter returned to contain "L001..L003" range together with "L007|L009" selections
        LocationRange := StrSubstNo('%1..%2', Location[1].Code, Location[3].Code);
        LocationSelection := StrSubstNo('%1|%2', Location[7].Code, Location[9].Code);
        ExpectedLocationFilter := StrSubstNo('%1|%2', LocationRange, LocationSelection);

        Assert.IsTrue(StrPos(FilterValue, LocationRange) > 0, 'Expected range of Locations in the filter');
        Assert.IsTrue(StrPos(FilterValue, LocationSelection) > 0, 'Expected selections of Locations in the filter');
        Assert.AreEqual(ExpectedLocationFilter, FilterValue, 'Expected filter string to contain range and selection');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationFilterFromWarehouseEmployeeOnlyBlankLoc()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseWMSCue: Record "Warehouse WMS Cue";
    begin
        // [FEATURE] [UT] [Location] [Warehouse Employee]
        // [SCENARIO 339308] WarehouseWMSCue.GetEmployeeLocation returns valid filter when a user is a warehouse employee only on blank location.
        Initialize();
        WarehouseEmployee.DeleteAll();

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, '', false);

        Assert.AreEqual('''''', WarehouseWMSCue.GetEmployeeLocation(UserId), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationFilterFromWarehouseEmployeeRealAndBlankLoc()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseWMSCue: Record "Warehouse WMS Cue";
    begin
        // [FEATURE] [UT] [Location] [Warehouse Employee]
        // [SCENARIO 339308] WarehouseWMSCue.GetEmployeeLocation returns valid filter when a user is a warehouse employee on several locations including blank.
        Initialize();
        WarehouseEmployee.DeleteAll();

        LibraryWarehouse.CreateLocation(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, '', false);

        Assert.AreEqual(StrSubstNo('%1|%2', '''''', Location.Code), WarehouseWMSCue.GetEmployeeLocation(UserId), '');
    end;

    [Test]
    procedure ProdOrderRoutingsInQueueCue()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ManufacturingCue: Record "Manufacturing Cue";
    begin
        // [FEATURE] [Manufacturing] [Routing]
        // [SCENARIO 406130] "Prod. Order Routings - in Queue" cue excludes prod. order routing lines for finished production orders.
        Initialize();
        ProdOrderRoutingLine.DeleteAll();

        MockProdOrderRoutingLine(ProdOrderRoutingLine.Status::"Firm Planned", ProdOrderRoutingLine."Routing Status"::Planned);
        MockProdOrderRoutingLine(ProdOrderRoutingLine.Status::Released, ProdOrderRoutingLine."Routing Status"::Planned);
        MockProdOrderRoutingLine(ProdOrderRoutingLine.Status::Finished, ProdOrderRoutingLine."Routing Status"::Planned);

        ManufacturingCue.CalcFields("Prod. Orders Routings-in Queue");

        ManufacturingCue.TestField("Prod. Orders Routings-in Queue", 2);
    end;

    [Test]
    procedure ProdOrderRoutingsInProgressCue()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ManufacturingCue: Record "Manufacturing Cue";
    begin
        // [FEATURE] [Manufacturing] [Routing]
        // [SCENARIO 406130] "Prod. Order Routings - in Queue" cue includes only prod. order routing lines for released production orders.
        Initialize();
        ProdOrderRoutingLine.DeleteAll();

        MockProdOrderRoutingLine(ProdOrderRoutingLine.Status::"Firm Planned", ProdOrderRoutingLine."Routing Status"::"In Progress");
        MockProdOrderRoutingLine(ProdOrderRoutingLine.Status::Released, ProdOrderRoutingLine."Routing Status"::"In Progress");
        MockProdOrderRoutingLine(ProdOrderRoutingLine.Status::Finished, ProdOrderRoutingLine."Routing Status"::"In Progress");

        ManufacturingCue.CalcFields("Prod. Orders Routings-in Prog.");

        ManufacturingCue.TestField("Prod. Orders Routings-in Prog.", 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure DelayedOrdersCountOnSalesCue()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SOProcessorActivities: TestPage "SO Processor Activities";
        SalesOrderList: TestPage "Sales Order List";
        DocumentNos: List of [Code[20]];
        ShipmentDates: List of [Date];
        i: Integer;
    begin
        // [FEATURE] [Sales Cue]
        // [SCENARIO 423683] Sales Order is considered delayed if there is an outstanding Sales Line with "Shipment Date" <= WorkDate.
        Initialize();
        SalesHeader.SetRange("Document Type", "Sales Document Type"::Order);
        SalesHeader.SetRange(Status, "Sales Document Status"::Released);
        SalesHeader.DeleteAll();

        // [GIVEN] Three released Sales Orders "S1", "S2", "S3".
        // [GIVEN] "S1" has Sales Line with "Shipment Date" = WorkDate() - 1.
        // [GIVEN] "S2" has Sales Line with "Shipment Date" = WorkDate.
        // [GIVEN] "S3" has Sales Line with "Shipment Date" = WorkDate() + 1.
        ShipmentDates.AddRange(WorkDate() - 1, WorkDate(), WorkDate() + 1);
        for i := 1 to ShipmentDates.Count do begin
            LibrarySales.CreateSalesOrder(SalesHeader);
            LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
            UpdateShipmentDateOnSalesLine(SalesLine, ShipmentDates.Get(i));
            LibrarySales.ReleaseSalesDocument(SalesHeader);
            DocumentNos.Add(SalesHeader."No.");
        end;

        // [WHEN] Open Activities page.
        SOProcessorActivities.OpenView();

        // [THEN] Orders "S1" and "S2" are treated as delayed, i.e. Delayed cue has value 2.
        Assert.AreEqual(Format(2), SOProcessorActivities.DelayedOrders.Value, '');

        // [WHEN] DrillDown to Delayed cue.
        SalesOrderList.Trap();
        SOProcessorActivities.DelayedOrders.Drilldown();

        // [THEN] Only orders "S1" and "S2" are shown on Sales Order List page.
        SalesOrderList.First();
        SalesOrderList."No.".AssertEquals(DocumentNos.Get(1));
        SalesOrderList.Next();
        SalesOrderList."No.".AssertEquals(DocumentNos.Get(2));
        Assert.IsFalse(SalesOrderList.Next(), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure CompletelyReservedFromStockSalesCue()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SOProcessorActivities: TestPage "SO Processor Activities";
        SalesOrderList: TestPage "Sales Order List";
        SalesHeaderNo: Code[20];
    begin
        // [SCENARIO 481603] Sales Cue "Completely Reserved from Stock" number corresponds to completely reserved sales orders.
        Initialize();

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 15);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 10, '', WorkDate());
        SalesHeaderNo := SalesHeader."No.";
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 10, '', WorkDate());
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 10, '', WorkDate());

        SOProcessorActivities.OpenView();
        SOProcessorActivities.SalesOrdersReservedFromStock.AssertEquals(1);

        SalesOrderList.Trap();
        SOProcessorActivities.SalesOrdersReservedFromStock.Drilldown();
        SalesOrderList.Last();
        SalesOrderList."No.".AssertEquals(SalesHeaderNo);
        Assert.IsFalse(SalesOrderList.Previous(), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure CompletelyReservedFromStockActivitiesCue()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ActivitiesCue: Record "Activities Cue";
        O365Activities: TestPage "O365 Activities";
        SalesOrderList: TestPage "Sales Order List";
        SalesHeaderNo: Code[20];
    begin
        //avd
        // [SCENARIO 481603] Activities Cue "Completely Reserved from Stock" number corresponds to completely reserved sales orders.
        Initialize();
        if not ActivitiesCue.Get() then begin
            ActivitiesCue.Init();
            ActivitiesCue.Insert();
        end;

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 15);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 10, '', WorkDate());
        SalesHeaderNo := SalesHeader."No.";
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 10, '', WorkDate());
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 10, '', WorkDate());

        O365Activities.OpenView();
        O365Activities."S. Ord. - Reserved From Stock".AssertEquals(1);

        SalesOrderList.Trap();
        O365Activities."S. Ord. - Reserved From Stock".Drilldown();
        SalesOrderList.Last();
        SalesOrderList."No.".AssertEquals(SalesHeaderNo);
        Assert.IsFalse(SalesOrderList.Previous(), '');
    end;

    local procedure Initialize()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SalesCue: Record "Sales Cue";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cues");
        SalesHeader.DeleteAll();
        SalesLine.DeleteAll();
        PurchaseHeader.DeleteAll();
        PurchaseLine.DeleteAll();
        ServiceHeader.DeleteAll();
        ServiceLine.DeleteAll();
        ServiceContractHeader.DeleteAll();
        ServiceContractLine.DeleteAll();
        PostedWhseShipmentHeader.DeleteAll();
        VendorLedgerEntry.DeleteAll();
        if SalesCue.Get() then begin
            SalesCue."Avg. Days Delayed Updated On" := 0DT;
            SalesCue.Modify();
        end;

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cues");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cues");
    end;

    local procedure CreateResponsibilityCenterAndUserSetup(): Code[10]
    var
        UserSetup: Record "User Setup";
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);
        UserSetup.Validate("Sales Resp. Ctr. Filter", ResponsibilityCenter.Code);
        UserSetup.Validate("Purchase Resp. Ctr. Filter", ResponsibilityCenter.Code);
        UserSetup.Validate("Service Resp. Ctr. Filter", ResponsibilityCenter.Code);
        UserSetup.Modify(true);
        exit(ResponsibilityCenter.Code);
    end;

    local procedure CreatePurchDocument(DocType: Enum "Purchase Document Type"; PassedStatus: Enum "Purchase Document Status"; PassedReceive: Boolean; CompletelyReceived: Boolean; PassedInvoice: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        with PurchHeader do begin
            Init();
            "Document Type" := DocType;
            Insert(true);
            Status := PassedStatus;
            Receive := PassedReceive;
            Invoice := PassedInvoice;
            Modify();
        end;

        with PurchLine do begin
            "Document Type" := PurchHeader."Document Type";
            "Document No." := PurchHeader."No.";
            Type := Type::Item;
            "Completely Received" := CompletelyReceived;
            Quantity := LibraryRandom.RandDecInRange(10, 20, 2);
            if PassedInvoice then
                "Quantity Invoiced" := Quantity / 2;
            Insert();
        end;
    end;

    local procedure CreateServDocument(DocType: Enum "Service Document Type"; PassedStatus: Enum "Service Document Status")
    var
        ServHeader: Record "Service Header";
    begin
        with ServHeader do begin
            Init();
            "Document Type" := DocType;
            Insert(true);
            Status := PassedStatus;
            Modify();
        end;
    end;

    local procedure CreateServContract(ContractType: Enum "Service Contract Type")
    var
        ServContractHeader: Record "Service Contract Header";
        UserSetup: Record "User Setup";
    begin
        UserSetup.Get(UserId);
        with ServContractHeader do begin
            Init();
            "Contract Type" := ContractType;
            "Responsibility Center" := UserSetup."Service Resp. Ctr. Filter";
            Insert(true);
        end;
    end;

    local procedure CreateShippedSalesOrder(var SalesHeader: Record "Sales Header"; OrderShipStatus: Option Full,Partial,"Not Shipped")
    var
        SalesLine: Record "Sales Line";
        ShipmentDate: Date;
        Qty: Integer;
        ShippedQty: Integer;
    begin
        Qty := LibraryRandom.RandIntInRange(10, 20);
        ShipmentDate := CalcDate('<-4D>', WorkDate());

        case OrderShipStatus of
            OrderShipStatus::Full:
                ShippedQty := Qty;
            OrderShipStatus::Partial:
                ShippedQty := Qty - LibraryRandom.RandInt(5);
            OrderShipStatus::"Not Shipped":
                ShippedQty := 0;
        end;

        with SalesHeader do begin
            MockSalesHeader(SalesHeader, "Document Type"::Order, Status::Open);
            MockSalesLine(SalesHeader, SalesLine, ShipmentDate, Qty, ShippedQty);
            "Shipment Date" := ShipmentDate;
            Ship := OrderShipStatus <> OrderShipStatus::Full;
            Status := Status::Released;
            Modify();
        end;
    end;

    local procedure CreateTwoSalesOrdersWithVariedDateAndShipLines(var SalesHeader: array[2] of Record "Sales Header"; var Delays: array[2] of Integer)
    var
        SalesLine: Record "Sales Line";
        Qty: Integer;
    begin
        Qty := LibraryRandom.RandIntInRange(10, 20);
        Delays[1] := LibraryRandom.RandInt(10);
        Delays[2] := LibraryRandom.RandInt(10);

        MockSalesHeader(SalesHeader[1], SalesHeader[1]."Document Type"::Order, SalesHeader[1].Status::Released);
        MockSalesLine(SalesHeader[1], SalesLine, WorkDate() - Delays[1], Qty, Qty - LibraryRandom.RandInt(5));
        MockSalesLine(SalesHeader[1], SalesLine, WorkDate() - Delays[2], Qty, Qty - LibraryRandom.RandInt(5));
        MockSalesLine(SalesHeader[1], SalesLine, 0D, Qty, Qty - LibraryRandom.RandInt(5));

        MockSalesHeader(SalesHeader[2], SalesHeader[2]."Document Type"::Order, SalesHeader[2].Status::Released);
        MockSalesLine(SalesHeader[2], SalesLine, WorkDate() - LibraryRandom.RandInt(10), Qty, Qty);
        MockSalesLine(SalesHeader[2], SalesLine, WorkDate() + LibraryRandom.RandInt(10), Qty, Qty - LibraryRandom.RandInt(5));
    end;

    local procedure MockSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; NewStatus: Enum "Sales Document Status")
    begin
        with SalesHeader do begin
            Init();
            "Document Type" := DocumentType;
            "No." := '';
            Insert(true);
            Status := NewStatus;
            Modify();
        end;
    end;

    local procedure MockSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShipmentDate: Date; Qty: Decimal; QtyShipped: Decimal)
    begin
        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            if FindLast() then;

            Init();
            "Document Type" := SalesHeader."Document Type";
            "Document No." := SalesHeader."No.";
            "Line No." += 10000;
            "Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
            Type := Type::Item;
            "Shipment Date" := ShipmentDate;

            "Quantity (Base)" := Qty;
            "Qty. Shipped (Base)" := QtyShipped;
            "Outstanding Quantity" := "Quantity (Base)" - "Qty. Shipped (Base)";
            "Completely Shipped" := ("Quantity (Base)" <> 0) and ("Outstanding Quantity" = 0);
            "Qty. Shipped Not Invoiced" := "Qty. Shipped (Base)" - "Qty. Invoiced (Base)";
            Insert();
        end;
    end;

    local procedure MockPostedWhseShipmentHeader()
    var
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
    begin
        with PostedWhseShipmentHeader do begin
            Init();
            "No." := '';
            Insert();
            "Posting Date" := WorkDate();
            Modify();
        end;
    end;

    local procedure MockVendorLedgerEntry(DueDate: Date)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        with VendorLedgerEntry do begin
            "Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, FieldNo("Entry No."));
            "Document Type" := "Document Type"::Invoice;
            "Due Date" := DueDate;
            Open := true;
            Insert();
        end;
    end;

    local procedure MockProdOrderRoutingLine(ProdOrderStatus: Enum "Production Order Status"; RoutingStatus: Enum "Prod. Order Routing Status")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Status := ProdOrderStatus;
        ProdOrderRoutingLine."Prod. Order No." := LibraryUtility.GenerateGUID();
        ProdOrderRoutingLine."Routing Reference No." := LibraryRandom.RandInt(10);
        ProdOrderRoutingLine."Routing No." := LibraryUtility.GenerateGUID();
        ProdOrderRoutingLine."Operation No." := LibraryUtility.GenerateGUID();
        ProdOrderRoutingLine."Routing Status" := RoutingStatus;
        ProdOrderRoutingLine.Insert();
    end;

    local procedure Maximum(a: Decimal; b: Decimal): Decimal
    begin
        if a >= b then
            exit(a);
        exit(b);
    end;

    local procedure UpdateShipmentDateOnSalesLine(var SalesLine: Record "Sales Line"; ShipmentDate: Date)
    begin
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure VerifySalesCueFlowFields()
    var
        SalesCue: Record "Sales Cue";
    begin
        SalesCue.SetRespCenterFilter();
        SalesCue.CalcFields(
          "Sales Quotes - Open", "Sales Orders - Open", "Ready to Ship",
          Delayed, "Sales Return Orders - Open", "Sales Credit Memos - Open", "Partially Shipped");
        SalesCue."Average Days Delayed" := SalesCue.CalculateAverageDaysDelayed();

        VerifySalesCueFields(SalesCue);
    end;

    local procedure VerifySalesCueFields(var SalesCue: Record "Sales Cue")
    begin
        with SalesCue do begin
            Assert.AreEqual(
              1, "Sales Quotes - Open", StrSubstNo(WrongValueErr, FieldCaption("Sales Quotes - Open"), TableCaption));
            Assert.AreEqual(
              1, "Sales Orders - Open", StrSubstNo(WrongValueErr, FieldCaption("Sales Orders - Open"), TableCaption));
            Assert.AreEqual(
              2, "Ready to Ship", StrSubstNo(WrongValueErr, FieldCaption("Ready to Ship"), TableCaption));
            Assert.AreEqual(
              1, Delayed, StrSubstNo(WrongValueErr, FieldCaption(Delayed), TableCaption));
            Assert.AreEqual(
              1, "Sales Return Orders - Open", StrSubstNo(WrongValueErr, FieldCaption("Sales Return Orders - Open"), TableCaption));
            Assert.AreEqual(
              1, "Sales Credit Memos - Open", StrSubstNo(WrongValueErr, FieldCaption("Sales Credit Memos - Open"), TableCaption));
            Assert.AreEqual(
              1, "Partially Shipped", StrSubstNo(WrongValueErr, FieldCaption("Partially Shipped"), TableCaption));

            VerifySalesCueNonFlowFieldCalculated(SalesCue);
        end;
    end;

    local procedure VerifySalesCueNonFlowFieldCalculated(var SalesCue: Record "Sales Cue")
    begin
        with SalesCue do begin
            Assert.AreEqual(
            4, "Average Days Delayed", StrSubstNo(WrongValueErr, FieldCaption("Average Days Delayed"), TableCaption));
            Assert.AreEqual(
            "Ready to Ship", CountOrders(FieldNo("Ready to Ship")), StrSubstNo(WrongValueErr, 'CountReadyToShip', TableCaption));
            Assert.AreEqual(
            Delayed, CountOrders(FieldNo(Delayed)), StrSubstNo(WrongValueErr, 'CountDelayed', TableCaption));
            Assert.AreEqual(
            "Partially Shipped", CountOrders(FieldNo("Partially Shipped")), StrSubstNo(WrongValueErr, 'CountPartiallyShipped', TableCaption));
        end;
    end;

    local procedure VerifySalesCueFlowFieldsPartiallyShipped()
    var
        SalesCue: Record "Sales Cue";
    begin
        SalesCue.SetRespCenterFilter();
        SalesCue.CalcFields("Partially Shipped");
        Assert.AreEqual(
          1, SalesCue."Partially Shipped", StrSubstNo(WrongValueErr, SalesCue.FieldCaption("Partially Shipped"), SalesCue.TableCaption));
    end;

    local procedure VerifySBOwnerCueNestedFlowField()
    var
        SBOwnerCue: Record "SB Owner Cue";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Completely Shipped", true);
        SalesHeader.SetRange("Shipped Not Invoiced", true);
        Assert.AreEqual(
          SalesHeader.Count, SBOwnerCue.CountSalesOrdersShippedNotInvoiced(),
          StrSubstNo(WrongValueErr, 'CountSOShippedNotInvoiced', SBOwnerCue.TableCaption()));
    end;

    local procedure VerifyPurchCueFlowFields()
    var
        PurchCue: Record "Purchase Cue";
    begin
        PurchCue.SetRespCenterFilter();
        PurchCue.CalcFields(
          "To Send or Confirm", "Upcoming Orders", "Outstanding Purchase Orders", "Purchase Return Orders - All",
          "Not Invoiced", "Partially Invoiced");
        Assert.AreEqual(
          1, PurchCue."To Send or Confirm", StrSubstNo(WrongValueErr, PurchCue.FieldCaption("To Send or Confirm"), PurchCue.TableCaption));
        Assert.AreEqual(
          4, PurchCue."Upcoming Orders", StrSubstNo(WrongValueErr, PurchCue.FieldCaption("Upcoming Orders"), PurchCue.TableCaption));
        Assert.AreEqual(
          2, PurchCue."Outstanding Purchase Orders", StrSubstNo(WrongValueErr, PurchCue.FieldCaption("Outstanding Purchase Orders"), PurchCue.TableCaption));
        Assert.AreEqual(
          1, PurchCue."Purchase Return Orders - All", StrSubstNo(WrongValueErr, PurchCue.FieldCaption("Purchase Return Orders - All"), PurchCue.TableCaption));
        Assert.AreEqual(
          1, PurchCue."Not Invoiced", StrSubstNo(WrongValueErr, PurchCue.FieldCaption("Not Invoiced"), PurchCue.TableCaption));
        Assert.AreEqual(
          1, PurchCue."Partially Invoiced", StrSubstNo(WrongValueErr, PurchCue.FieldCaption("Partially Invoiced"), PurchCue.TableCaption));
        // Verify replacement for nested FlowFields
        Assert.AreEqual(
          PurchCue."Outstanding Purchase Orders", PurchCue.CountOrders(PurchCue.FieldNo("Outstanding Purchase Orders")),
          StrSubstNo(WrongValueErr, 'CountOutstandingOrders', PurchCue.TableCaption));
        Assert.AreEqual(
          PurchCue."Not Invoiced", PurchCue.CountOrders(PurchCue.FieldNo("Not Invoiced")), StrSubstNo(WrongValueErr, 'CountNotInvoicedOrders', PurchCue.TableCaption));
        Assert.AreEqual(
          PurchCue."Partially Invoiced", PurchCue.CountOrders(PurchCue.FieldNo("Partially Invoiced")),
          StrSubstNo(WrongValueErr, 'CountPartiallyInvoicedOrders', PurchCue.TableCaption));
    end;

    local procedure VerifyServCueFlowFields()
    var
        ServCue: Record "Service Cue";
    begin
        ServCue.SetRespCenterFilter();
        ServCue.CalcFields(
          "Service Orders - in Process", "Service Orders - Finished", "Service Orders - Inactive",
          "Open Service Quotes", "Open Service Contract Quotes", "Service Contracts to Expire",
          "Service Orders - Today", "Service Orders - to Follow-up");
        Assert.AreEqual(
          1, ServCue."Service Orders - in Process", StrSubstNo(WrongValueErr, ServCue.FieldCaption("Service Orders - in Process"), ServCue.TableCaption));
        Assert.AreEqual(
          1, ServCue."Service Orders - Finished", StrSubstNo(WrongValueErr, ServCue.FieldCaption("Service Orders - Finished"), ServCue.TableCaption));
        Assert.AreEqual(
          1, ServCue."Service Orders - Inactive", StrSubstNo(WrongValueErr, ServCue.FieldCaption("Service Orders - Inactive"), ServCue.TableCaption));
        Assert.AreEqual(
          1, ServCue."Open Service Quotes", StrSubstNo(WrongValueErr, ServCue.FieldCaption("Open Service Quotes"), ServCue.TableCaption));
        Assert.AreEqual(
          1, ServCue."Open Service Contract Quotes", StrSubstNo(WrongValueErr, ServCue.FieldCaption("Open Service Contract Quotes"), ServCue.TableCaption));
        Assert.AreEqual(
          1, ServCue."Service Contracts to Expire", StrSubstNo(WrongValueErr, ServCue.FieldCaption("Service Contracts to Expire"), ServCue.TableCaption));
        Assert.AreEqual(
          3, ServCue."Service Orders - Today", StrSubstNo(WrongValueErr, ServCue.FieldCaption("Service Orders - Today"), ServCue.TableCaption));
        Assert.AreEqual(
          1, ServCue."Service Orders - to Follow-up", StrSubstNo(WrongValueErr, ServCue.FieldCaption("Service Orders - to Follow-up"), ServCue.TableCaption));
    end;

    local procedure VerifyWarehouseWMSCueFlowFields()
    var
        WarehouseWMSCue: Record "Warehouse WMS Cue";
    begin
        with WarehouseWMSCue do begin
            SetFilter("Date Filter", '<%1', WorkDate());
            SetFilter("Date Filter2", '>=%1', WorkDate());
            CalcFields("Posted Shipments - Today");
            Assert.AreEqual(
              1, "Posted Shipments - Today", StrSubstNo(WrongValueErr, FieldCaption("Posted Shipments - Today"), TableCaption));

            SetFilter("Date Filter", '>=%1', WorkDate());
            SetFilter("Date Filter2", '<%1', WorkDate());
            CalcFields("Posted Shipments - Today");
            Assert.AreEqual(
              0, "Posted Shipments - Today", StrSubstNo(WrongValueErr, FieldCaption("Posted Shipments - Today"), TableCaption));
        end;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    procedure MessageHandler(MessageText: Text[1024])
    begin
    end;

    [ModalPageHandler]
    procedure SelectTemplateHandler(var ServiceContractTemplateList: Page "Service Contract Template List"; var Response: Action)
    begin
        Response := ACTION::OK;
    end;
}

