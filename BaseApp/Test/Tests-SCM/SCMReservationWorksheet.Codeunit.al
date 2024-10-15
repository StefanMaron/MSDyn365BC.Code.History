codeunit 137023 "SCM Reservation Worksheet"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Fulfillment] [Reservation Worksheet]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        DefaultBatchTok: Label 'DEFAULT';
        QtyCannotExceedErr: Label 'Qty. to Reserve cannot exceed';
        DateSequenceErr: Label 'Start Date Formula must be less than or equal to End Date Formula';

    [Test]
    [HandlerFunctions('GetDemandToReserveRequestPageHandler')]
    procedure GettingDemandAndValidateFields()
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        ReservationWkshLine: Record "Reservation Wksh. Line";
        SalesLine: Record "Sales Line";
        ItemList: List of [Code[20]];
        LocationList: List of [Code[10]];
        SalesOrderList: List of [Code[20]];
        NoOfLines: Integer;
    begin
        // [SCENARIO] Get Demand and validate editable fields in Reservation Worksheet.
        Initialize();

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        PrepareInventory(ItemList, LocationList);
        PrepareSetOfSalesOrders(SalesOrderList, ItemList, LocationList);

        // [GIVEN] Run "Get Demand" filtered by these 3 items in a default reservation worksheet batch.
        ReservationWkshBatch.FindFirst();
        GetDemand(ReservationWkshBatch.Name, ItemList);

        // [GIVEN] Find reservation worksheet line related to the first sales order.
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWkshLine.SetRange("Source ID", SalesOrderList.Get(1));
        ReservationWkshLine.FindFirst();

        // [GIVEN] Verify "Remaining Qty. to Reserve", "Available Qty. to Reserve", and "Qty. per Unit of Measure" fields.
        SalesLine.Get(ReservationWkshLine."Source Subtype", ReservationWkshLine."Source ID", ReservationWkshLine."Source Ref. No.");
        ReservationWkshLine.TestField("Remaining Qty. to Reserve", 1);
        ReservationWkshLine.TestField("Rem. Qty. to Reserve (Base)", 1);
        ReservationWkshLine.TestField("Available Qty. to Reserve", 10);
        ReservationWkshLine.TestField("Avail. Qty. to Reserve (Base)", 10);
        ReservationWkshLine.TestField("Qty. per Unit of Measure", 1);
        ReservationWkshLine.TestField("Qty. to Reserve", 0);

        // [WHEN] Update "Qty. to Reserve" = 1.
        ReservationWkshLine.Validate("Qty. to Reserve", 1);
        ReservationWkshLine.Modify();

        // [THEN] Verify that "Qty. to Reserve (Base)" is updated.
        // [THEN] Verify that "Available Qty. to Reserve" is decreased by 1.
        ReservationWkshLine.TestField("Qty. to Reserve (Base)", 1);
        ReservationWkshLine.TestField("Available Qty. to Reserve", 9);
        ReservationWkshLine.TestField("Avail. Qty. to Reserve (Base)", 9);

        // [THEN] Verify that "Available Qty. to Reserve" on other lines with the same item and location is decreased by 1.
        ReservationWkshLine.SetRange("Item No.", ReservationWkshLine."Item No.");
        ReservationWkshLine.SetRange("Location Code", ReservationWkshLine."Location Code");
        NoOfLines := ReservationWkshLine.Count();
        ReservationWkshLine.SetRange("Available Qty. to Reserve", 9);
        Assert.RecordCount(ReservationWkshLine, NoOfLines);

        // [WHEN] Update "Qty. to Reserve" = 0.
        ReservationWkshLine.Reset();
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWkshLine.SetRange("Source ID", SalesOrderList.Get(1));
        ReservationWkshLine.FindFirst();
        ReservationWkshLine.Validate("Qty. to Reserve", 0);
        ReservationWkshLine.Modify();

        // [THEN] Verify that "Available Qty. to Reserve" on other lines with the same item and location is increased by 1.
        ReservationWkshLine.SetRange("Item No.", ReservationWkshLine."Item No.");
        ReservationWkshLine.SetRange("Location Code", ReservationWkshLine."Location Code");
        NoOfLines := ReservationWkshLine.Count();
        ReservationWkshLine.SetRange("Available Qty. to Reserve", 10);
        Assert.RecordCount(ReservationWkshLine, NoOfLines);

        // [WHEN] Update "Qty. to Reserve" = 2, which is greater than "Remaining Qty. to Reserve".
        Commit();
        ReservationWkshLine.Find();
        asserterror ReservationWkshLine.Validate("Qty. to Reserve", 2);

        // [THEN] Verify that error message is shown.
        Assert.ExpectedError(QtyCannotExceedErr);
    end;

    [Test]
    [HandlerFunctions('GetDemandToReserveRequestPageHandler,ConfirmNoHandler')]
    procedure CheckingOutstandingQtyReservedQtyReservedFromStock()
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        ReservationWkshLine: Record "Reservation Wksh. Line";
        SalesLine: Record "Sales Line";
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        ItemList: List of [Code[20]];
        LocationList: List of [Code[10]];
        SalesOrderList: List of [Code[20]];
        OutstandingQty: Decimal;
        ReservedQty: Decimal;
        ReservedFromStockQty: Decimal;
    begin
        // [SCENARIO] Check Outstanding Qty, Reserved Qty, and Reserved From Stock fields.
        Initialize();

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        PrepareInventory(ItemList, LocationList);
        PrepareSetOfSalesOrders(SalesOrderList, ItemList, LocationList);

        // [GIVEN] Run "Get Demand" filtered by these 3 items in a default reservation worksheet batch.
        ReservationWkshBatch.FindFirst();
        GetDemand(ReservationWkshBatch.Name, ItemList);

        // [GIVEN] Find reservation worksheet line related to the sales order "8".
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWkshLine.SetRange("Source ID", SalesOrderList.Get(8));
        ReservationWkshLine.FindFirst();

        // [GIVEN] Reserve sales order "8" from inventory.
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderList.Get(8));
        SalesLine.FindFirst();
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [WHEN] Get "Outstanding Qty.", "Reserved Qty.", and "Reserved From Stock" values for the reservation worksheet line.
        ReservationWorksheetMgt.GetSourceDocumentLineQuantities(ReservationWkshLine, OutstandingQty, ReservedQty, ReservedFromStockQty);

        // [THEN] "Outstanding Qty." = SalesLine."Outstanding Quantity".
        // [THEN] "Reserved Qty." = SalesLine."Reserved Quantity".
        // [THEN] "Reserved From Stock" = SalesLine."Reserved Quantity".
        SalesLine.Find();
        SalesLine.CalcFields("Reserved Quantity");
        Assert.AreEqual(SalesLine."Outstanding Quantity", OutstandingQty, 'Outstanding Qty. for demand');
        Assert.AreEqual(SalesLine."Reserved Quantity", ReservedQty, 'Reserved Qty. for demand');
        Assert.AreEqual(SalesLine."Reserved Quantity", ReservedFromStockQty, 'Reserved from Stock for demand');
    end;

    [Test]
    [HandlerFunctions('GetDemandToReserveRequestPageHandler')]
    procedure CheckingCurrentStockAndReservedQty()
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        ReservationWkshLine: Record "Reservation Wksh. Line";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemList: List of [Code[20]];
        LocationList: List of [Code[10]];
        SalesOrderList: List of [Code[20]];
    begin
        // [SCENARIO] Check Current Stock and Reserved Qty in Stock fields.
        Initialize();

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        PrepareInventory(ItemList, LocationList);
        PrepareSetOfSalesOrders(SalesOrderList, ItemList, LocationList);

        // [GIVEN] Reserve sales order "6" from inventory.
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderList.Get(6));
        SalesLine.FindFirst();
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [WHEN] Run "Get Demand" filtered by these 3 items in a default reservation worksheet batch.
        ReservationWkshBatch.FindFirst();
        GetDemand(ReservationWkshBatch.Name, ItemList);

        // [THEN] Find reservation worksheet line related to the item and location from sales order "6".
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWkshLine.SetRange("Item No.", SalesLine."No.");
        ReservationWkshLine.SetRange("Location Code", SalesLine."Location Code");
        ReservationWkshLine.FindLast();

        Item.Get(SalesLine."No.");
        Item.SetRange("Location Filter", SalesLine."Location Code");
        Item.CalcFields("Inventory", "Reserved Qty. on Inventory");

        // [THEN] "Qty. in Stock" = Item.Inventory.
        // [THEN] "Qty. Reserv. in Stock" = Item."Reserved Qty. on Inventory".
        ReservationWkshLine.TestField("Qty. in Stock", Item.Inventory);
        ReservationWkshLine.TestField("Qty. in Stock (Base)", Item.Inventory);
        ReservationWkshLine.TestField("Qty. Reserved in Stock", Item."Reserved Qty. on Inventory");
        ReservationWkshLine.TestField("Qty. Reserv. in Stock (Base)", Item."Reserved Qty. on Inventory");
    end;

    [Test]
    [HandlerFunctions('GetDemandToReserveRequestPageHandler')]
    procedure ShowingSourceDocument()
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        ReservationWkshLine: Record "Reservation Wksh. Line";
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        SalesLines: TestPage "Sales Lines";
        ItemList: List of [Code[20]];
        LocationList: List of [Code[10]];
        SalesOrderList: List of [Code[20]];
    begin
        // [SCENARIO] View source document for the demand line in Reservation Worksheet.
        Initialize();

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        PrepareInventory(ItemList, LocationList);
        PrepareSetOfSalesOrders(SalesOrderList, ItemList, LocationList);

        // [GIVEN] Run "Get Demand" filtered by these 3 items in a default reservation worksheet batch.
        ReservationWkshBatch.FindFirst();
        GetDemand(ReservationWkshBatch.Name, ItemList);

        // [GIVEN] Find reservation worksheet line related to the sales order "2".
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWkshLine.SetRange("Source ID", SalesOrderList.Get(2));
        ReservationWkshLine.FindFirst();

        // [WHEN] Show source document for the reservation worksheet line.
        SalesLines.Trap();
        ReservationWorksheetMgt.ShowSourceDocument(ReservationWkshLine);

        // [THEN] Sales Order "2" is shown.
        SalesLines."Document No.".AssertEquals(SalesOrderList.Get(2));
        SalesLines.Close();
    end;

    [Test]
    procedure ShowingReservationEntries()
    begin
        // TODO:
        // [SCENARIO] View reservation entries for the demand line in Reservation Worksheet.

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.

        // [GIVEN] Run "Get Demand" filtered by these 3 items in a default reservation worksheet batch.
        // [GIVEN] Reserve sales order "6".

        // [WHEN] Go to reservation worksheet line for sales order "6" and invoke "Reservation Entries" action.
        // [THEN] Reservation entries for the sales order "6" are shown.
    end;

    [Test]
    [HandlerFunctions('GetDemandToReserveRequestPageHandler')]
    procedure GettingDemandWithLocationFilter()
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        ReservationWkshLine: Record "Reservation Wksh. Line";
        ReservationWkshBatchCard: TestPage "Reservation Wksh. Batch Card";
        ItemList: List of [Code[20]];
        LocationList: List of [Code[10]];
        SalesOrderList: List of [Code[20]];
    begin
        // [SCENARIO] Get Demand with location filter set up in the worksheet batch.
        Initialize();

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        PrepareInventory(ItemList, LocationList);
        PrepareSetOfSalesOrders(SalesOrderList, ItemList, LocationList);

        // [GIVEN] Set "Location Filter" = location "1" on the default reservation worksheet batch via UI.
        ReservationWkshBatch.FindFirst();
        ReservationWkshBatchCard.OpenEdit();
        ReservationWkshBatchCard.GoToRecord(ReservationWkshBatch);
        ReservationWkshBatchCard."Location Filter".SetValue(LocationList.Get(1));
        ReservationWkshBatchCard.Close();

        // [WHEN] Run "Get Demand" filtered by these 3 items in the default batch.
        GetDemand(ReservationWkshBatch.Name, ItemList);

        // [THEN] Reservation worksheet lines are created only for the location "1".
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWkshLine.SetRange("Location Code", LocationList.Get(1));
        Assert.RecordIsNotEmpty(ReservationWkshLine);
        ReservationWkshLine.SetFilter("Location Code", '<>%1', LocationList.Get(1));
        Assert.RecordIsEmpty(ReservationWkshLine);
    end;

    [Test]
    [HandlerFunctions('GetDemandToReserveRequestPageHandler')]
    procedure GettingDemandWithDateFilter()
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        ReservationWkshLine: Record "Reservation Wksh. Line";
        DtFormula: DateFormula;
        ItemList: List of [Code[20]];
        LocationList: List of [Code[10]];
        SalesOrderList: List of [Code[20]];
    begin
        // [SCENARIO] Get Demand with date filter set up in the worksheet batch.
        Initialize();

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        PrepareInventory(ItemList, LocationList);
        PrepareSetOfSalesOrders(SalesOrderList, ItemList, LocationList);

        // [GIVEN] Set "Start Date Formula" = 10D, "End Date Formula" = 20D on the default reservation worksheet batch.
        ReservationWkshBatch.FindFirst();
        Evaluate(DtFormula, '<10D>');
        ReservationWkshBatch.Validate("Start Date Formula", DtFormula);
        Evaluate(DtFormula, '<20D>');
        ReservationWkshBatch.Validate("End Date Formula", DtFormula);
        ReservationWkshBatch.Modify();

        // [WHEN] Run "Get Demand" filtered by these 3 items in the default batch.
        GetDemand(ReservationWkshBatch.Name, ItemList);

        // [THEN] Reservation worksheet lines are created only the period WorkDate() + 10 days .. WorkDate() + 20 days.
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWkshLine.SetFilter("Demand Date", '<%1|>%2', WorkDate() + 10, WorkDate() + 20);
        Assert.RecordIsEmpty(ReservationWkshLine);
        ReservationWkshLine.SetFilter("Demand Date", '%1..%2', WorkDate() + 10, WorkDate() + 20);
        Assert.RecordIsNotEmpty(ReservationWkshLine);

        // [WHEN] Incorrectly set "Start Date Formula" > "End Date Formula" on the default reservation worksheet batch.
        // [THEN] Verify that error is shown.
        Evaluate(DtFormula, '<5D>');
        asserterror ReservationWkshBatch.Validate("End Date Formula", DtFormula);
        Assert.ExpectedError(DateSequenceErr);
    end;

    [Test]
    [HandlerFunctions('GetDemandToReserveRequestPageHandler')]
    procedure GettingDemandAddAndUpdateLines()
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        ReservationWkshLine: Record "Reservation Wksh. Line";
        ItemList: List of [Code[20]];
        ItemList12: List of [Code[20]];
        ItemList23: List of [Code[20]];
        LocationList: List of [Code[10]];
        SalesOrderList: List of [Code[20]];
    begin
        // [SCENARIO] Get Demand in non-empty worksheet, add new lines and update existing ones.
        Initialize();

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        PrepareInventory(ItemList, LocationList);
        PrepareSetOfSalesOrders(SalesOrderList, ItemList, LocationList);

        ItemList12.Add(ItemList.Get(1));
        ItemList12.Add(ItemList.Get(2));

        ItemList23.Add(ItemList.Get(2));
        ItemList23.Add(ItemList.Get(3));

        // [GIVEN] Run "Get Demand" filtered by items "1" and "2" in the default batch.
        ReservationWkshBatch.FindFirst();
        GetDemand(ReservationWkshBatch.Name, ItemList12);

        // [GIVEN] Set "Qty. to Reserve" = 1 on a reservation worksheet line for item "1".
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWkshLine.SetRange("Item No.", ItemList.Get(1));
        ReservationWkshLine.FindFirst();
        ReservationWkshLine.Validate("Qty. to Reserve", 1);
        ReservationWkshLine.Modify();

        // [GIVEN] Set "Qty. to Reserve" = 1 on a reservation worksheet line for item "2"
        ReservationWkshLine.SetRange("Item No.", ItemList.Get(2));
        ReservationWkshLine.FindFirst();
        ReservationWkshLine.Validate("Qty. to Reserve", 1);
        ReservationWkshLine.Modify();

        // [GIVEN] Ensure that reservation worksheet lines for item "3" do not exist.
        ReservationWkshLine.SetRange("Item No.", ItemList.Get(3));
        Assert.RecordIsEmpty(ReservationWkshLine);

        // [WHEN] Run "Get Demand" filtered by items "2" and "3" in the default batch.
        GetDemand(ReservationWkshBatch.Name, ItemList23);

        // [THEN] Reservation worksheet lines for item "1" remain untouched.
        ReservationWkshLine.SetRange("Item No.", ItemList.Get(1));
        ReservationWkshLine.FindFirst();
        ReservationWkshLine.TestField("Qty. to Reserve", 1);

        // [THEN] Reservation worksheet lines for item "2" are recreated.
        ReservationWkshLine.SetRange("Item No.", ItemList.Get(2));
        ReservationWkshLine.FindFirst();
        ReservationWkshLine.TestField("Qty. to Reserve", 0);

        // [THEN] Reservation worksheet lines for item "3" are created.
        ReservationWkshLine.SetRange("Item No.", ItemList.Get(3));
        ReservationWkshLine.FindFirst();
    end;

    [Test]
    procedure GettingDemandDeleteOutdatedLines()
    begin
        // TODO:
        // [SCENARIO] Get Demand in non-empty worksheet, delete outdated lines.

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        // [GIVEN] Run "Get Demand" filtered by these 3 items in the default batch.
        // [GIVEN] Go to sales orders for item "1" and change Location Code to another one.

        // [WHEN] Run "Get Demand" filtered by items "2" and "3" in the default batch.

        // [THEN] Reservation worksheet lines for item "1" are deleted.
    end;

    [Test]
    [HandlerFunctions('GetDemandToReserveRequestPageHandler')]
    procedure AllocatingQuantityWithBasicRule()
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        ReservationWkshLine: Record "Reservation Wksh. Line";
        AllocationPolicy: Record "Allocation Policy";
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        ItemList: List of [Code[20]];
        LocationList: List of [Code[10]];
        SalesOrderList: List of [Code[20]];
    begin
        // [SCENARIO] Distribute available stock among reservation worksheet lines using "Basic (No Conflicts)" allocation rule.
        Initialize();

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        PrepareInventory(ItemList, LocationList);
        PrepareSetOfSalesOrders(SalesOrderList, ItemList, LocationList);

        // [GIVEN] Set up single allocation rule = "Basic (No Conflicts)" for the batch.
        ReservationWkshBatch.FindFirst();
        AllocationPolicy.Init();
        AllocationPolicy."Journal Batch Name" := ReservationWkshBatch.Name;
        AllocationPolicy."Line No." := 10000;
        AllocationPolicy."Allocation Rule" := "Allocation Rules Impl."::"Basic (No Conflicts)";
        AllocationPolicy.Insert();

        // [GIVEN] Run "Get Demand" filtered by these 3 items in the default batch.
        GetDemand(ReservationWkshBatch.Name, ItemList);

        // [WHEN] Allocate quantity in the batch.
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWorksheetMgt.AllocateQuantity(ReservationWkshLine);

        // [THEN] Verify that all sales orders that can be unambiguously fulfilled are fulfilled.
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(1), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(1)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(2), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(2)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(3), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(4), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(4)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(5), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(5)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(6), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(7), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(8), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(10), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(10)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(11), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(11)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(12), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(12)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(13), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(14), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(15), 0);
    end;

    [Test]
    [HandlerFunctions('GetDemandToReserveRequestPageHandler')]
    procedure AllocatingQuantityWithNoRules()
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        ReservationWkshLine: Record "Reservation Wksh. Line";
        AllocationPolicy: Record "Allocation Policy";
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        ItemList: List of [Code[20]];
        LocationList: List of [Code[10]];
        SalesOrderList: List of [Code[20]];
    begin
        // [SCENARIO] Distribute available stock among reservation worksheet lines when allocation rules are not defined.
        Initialize();

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        PrepareInventory(ItemList, LocationList);
        PrepareSetOfSalesOrders(SalesOrderList, ItemList, LocationList);

        // [GIVEN] Check that no allocation rules are defined.
        ReservationWkshBatch.FindFirst();
        AllocationPolicy.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        Assert.RecordIsEmpty(AllocationPolicy);

        // [GIVEN] Run "Get Demand" filtered by these 3 items in the default batch.
        GetDemand(ReservationWkshBatch.Name, ItemList);

        // [WHEN] Allocate quantity in the batch.
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWorksheetMgt.AllocateQuantity(ReservationWkshLine);

        // [THEN] Verify that all sales orders that can be unambiguously fulfilled are fulfilled (Allocation Policy = "Basic (No Conflicts)" is used by default).
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(1), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(1)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(2), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(2)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(3), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(4), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(4)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(5), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(5)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(6), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(7), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(8), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(10), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(10)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(11), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(11)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(12), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(12)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(13), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(14), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(15), 0);

        // [THEN] Verify that reservation worksheet line for the sales order "9" does not exist because the quantity on the sales line is 0.
        ReservationWkshLine.SetRange("Source ID", SalesOrderList.Get(9));
        Assert.RecordIsEmpty(ReservationWkshLine);

        // [WHEN] Delete allocation.
        // [THEN] Check that all "Qty. to Reserve" are reset to 0.
        ReservationWkshLine.Reset();
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWorksheetMgt.DeleteAllocation(ReservationWkshLine);
        ReservationWkshLine.CalcSums("Qty. to Reserve");
        ReservationWkshLine.TestField("Qty. to Reserve", 0);
    end;

    [Test]
    [HandlerFunctions('GetDemandToReserveRequestPageHandler')]
    procedure AllocatingQuantityWithEquallyRule()
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        ReservationWkshLine: Record "Reservation Wksh. Line";
        AllocationPolicy: Record "Allocation Policy";
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        ItemList: List of [Code[20]];
        LocationList: List of [Code[10]];
        SalesOrderList: List of [Code[20]];
    begin
        // [SCENARIO] Distribute available stock among reservation worksheet lines using "Equally" allocation rule.
        Initialize();

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        PrepareInventory(ItemList, LocationList);
        PrepareSetOfSalesOrders(SalesOrderList, ItemList, LocationList);

        // [GIVEN] Set up single allocation rule = "Equally" for the batch.
        ReservationWkshBatch.FindFirst();
        AllocationPolicy.Init();
        AllocationPolicy."Journal Batch Name" := ReservationWkshBatch.Name;
        AllocationPolicy."Line No." := 10000;
        AllocationPolicy."Allocation Rule" := "Allocation Rules Impl."::Equally;
        AllocationPolicy.Insert();

        // [GIVEN] Run "Get Demand" filtered by these 3 items in the default batch.
        GetDemand(ReservationWkshBatch.Name, ItemList);

        // [WHEN] Allocate quantity in the batch.
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWorksheetMgt.AllocateQuantity(ReservationWkshLine);

        // [THEN] Verify that available inventory is distributed equally among salers orders.
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(1), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(1)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(2), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(2)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(3), 2);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(4), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(4)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(5), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(5)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(6), 2.3);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(7), 2.3);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(8), 2.4);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(10), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(10)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(11), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(11)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(12), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(12)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(13), 1.33);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(14), 1.333);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(15), 1.3333);
    end;

    [Test]
    [HandlerFunctions('GetDemandToReserveRequestPageHandler')]
    procedure AllocatingQuantityWithBasicAndEquallyRules()
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        ReservationWkshLine: Record "Reservation Wksh. Line";
        AllocationPolicy: Record "Allocation Policy";
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        ItemList: List of [Code[20]];
        LocationList: List of [Code[10]];
        SalesOrderList: List of [Code[20]];
    begin
        // [SCENARIO] Distribute available stock among reservation worksheet lines using "Basic (No Conflicts)" and "Equally" allocation rules.
        Initialize();

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        PrepareInventory(ItemList, LocationList);
        PrepareSetOfSalesOrders(SalesOrderList, ItemList, LocationList);

        // [GIVEN] Set up two allocation rules - first "Basic (No Conflicts)", then "Equally" for the batch.
        ReservationWkshBatch.FindFirst();
        AllocationPolicy.Init();
        AllocationPolicy."Journal Batch Name" := ReservationWkshBatch.Name;
        AllocationPolicy."Line No." := 10000;
        AllocationPolicy."Allocation Rule" := "Allocation Rules Impl."::"Basic (No Conflicts)";
        AllocationPolicy.Insert();
        AllocationPolicy."Line No." := 20000;
        AllocationPolicy."Allocation Rule" := "Allocation Rules Impl."::Equally;
        AllocationPolicy.Insert();

        // [GIVEN] Run "Get Demand" filtered by these 3 items in the default batch.
        GetDemand(ReservationWkshBatch.Name, ItemList);

        // [WHEN] Allocate quantity in the batch.
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWorksheetMgt.AllocateQuantity(ReservationWkshLine);

        // [THEN] Verify that available inventory is distributed among salers orders.
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(1), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(1)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(2), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(2)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(3), 2);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(4), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(4)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(5), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(5)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(6), 2.3);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(7), 2.3);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(8), 2.4);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(10), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(10)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(11), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(11)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(12), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(12)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(13), 1.33);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(14), 1.333);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(15), 1.3333);
    end;

    [Test]
    procedure AllocatingQuantityWithBasicAndEquallyRulesTwice()
    begin
        // TODO:        
        // [SCENARIO] Distribute available stock among reservation worksheet lines using "Basic (No Conflicts)" and "Equally" allocation rules twice.

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        // [GIVEN] Set up two allocation rules - first "Basic (No Conflicts)", then "Equally" for the batch.
        // [GIVEN] Run "Get Demand" filtered by these 3 items in the default batch.
        // [GIVEN] Allocate quantity in the batch.

        // [WHEN] Allocate quantity in the batch for the second time.

        // [THEN] Verify that result of allocation has not changed since the first run.
    end;

    [Test]
    procedure AllocatingQuantityWithPartiallyAcceptedLines()
    begin
        // TODO:        
        // [SCENARIO] Distribute available stock among reservation worksheet lines when some of the lines are partially accepted.

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        // [GIVEN] Run "Get Demand" filtered by these 3 items in the default batch.
        // [GIVEN] Set "Accept" flag on some of the reservation worksheet lines.

        // [WHEN] Allocate quantity in the batch.

        // [THEN] Verify that previously accepted lines are not changed.
    end;

    [Test]
    procedure AllocatingQuantityOnGetDemand()
    begin
        // TODO:        
        // [SCENARIO] Distribute available stock among reservation worksheet lines when getting demand.

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.

        // [WHEN] Run "Get Demand" with "Allocate after populate" flag set.
        // [THEN] Verify that allocation is done.
    end;

    [Test]
    [HandlerFunctions('GetDemandToReserveRequestPageHandler,CarryOutReservationRequestPageHandler')]
    procedure MakingReservation()
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        ReservationWkshLine: Record "Reservation Wksh. Line";
        SalesLine: Record "Sales Line";
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        ItemList: List of [Code[20]];
        LocationList: List of [Code[10]];
        SalesOrderList: List of [Code[20]];
    begin
        // [SCENARIO] Make reservation for the selected demand lines in Reservation Worksheet.
        Initialize();

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        PrepareInventory(ItemList, LocationList);
        PrepareSetOfSalesOrders(SalesOrderList, ItemList, LocationList);

        // [GIVEN] Run "Get Demand" filtered by these 3 items in the default batch.
        ReservationWkshBatch.FindFirst();
        GetDemand(ReservationWkshBatch.Name, ItemList);

        // [GIVEN] Set "Qty. to Reserve" and "Accept = true" on reservation worksheet lines for sales orders "1" and "15".
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWkshLine.SetRange("Source ID", SalesOrderList.Get(1));
        ReservationWkshLine.FindFirst();
        ReservationWkshLine.Validate("Qty. to Reserve", ReservationWkshLine."Remaining Qty. to Reserve");
        ReservationWkshLine.Validate(Accept, true);
        ReservationWkshLine.Modify();

        ReservationWkshLine.SetRange("Source ID", SalesOrderList.Get(15));
        ReservationWkshLine.FindFirst();
        ReservationWkshLine.Validate("Qty. to Reserve", ReservationWkshLine."Remaining Qty. to Reserve");
        ReservationWkshLine.Validate(Accept, true);
        ReservationWkshLine.Modify();

        // [WHEN] Make reservation for the selected demand lines in Reservation Worksheet.
        Commit();
        ReservationWkshLine.Reset();
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWorksheetMgt.CarryOutAction(ReservationWkshLine);

        // [THEN] Accepted reservation worksheet lines are deleted.
        ReservationWkshLine.SetRange("Source ID", SalesOrderList.Get(1));
        Assert.RecordIsEmpty(ReservationWkshLine);
        ReservationWkshLine.SetRange("Source ID", SalesOrderList.Get(15));
        Assert.RecordIsEmpty(ReservationWkshLine);

        // [THEN] Sales orders "1" and "15" are reserved.
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderList.Get(1));
        SalesLine.FindFirst();
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", SalesLine."Outstanding Quantity");
        SalesLine.SetRange("Document No.", SalesOrderList.Get(15));
        SalesLine.FindFirst();
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", SalesLine."Outstanding Quantity");
    end;

    [Test]
    procedure RecentChangesAfterMakeReservation()
    begin
        // TODO:
        // [SCENARIO] Check Recent Changes after making reservation.

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        // [GIVEN] Run "Get Demand" filtered by these 3 items in the default batch.        
        // [GIVEN] Set "Qty. to Reserve" and "Accept = true" on some reservation worksheet lines.

        // [WHEN] Make reservation for the selected demand lines in Reservation Worksheet.

        // [THEN] Check that reservation worksheet log contains just reserved orders.
        // [THEN] Use "Show Document" to jump to the reserved sales order.
        // [THEN] Use "Empty Log" to empty reservation worksheet log.
    end;

    [Test]
    procedure MakingReservationOfOutdatedLines()
    begin
        // TODO:        
        // [SCENARIO] Make reservation for the selected demand lines in Reservation Worksheet when some of the lines are out of date.

        // [GIVEN] Post 3 items to inventory at 2 locations.
        // [GIVEN] Prepare set of 15 sales orders.
        // [GIVEN] Run "Get Demand" filtered by these 3 items in the default batch.
        // [GIVEN] Go to sales order "1" and reserve it directly.

        // [GIVEN] Set "Qty. to Reserve" and "Accept = true" on reservation worksheet line for the sales order "1".

        // [WHEN] Reserve the sales order "1" in Reservation Worksheet.

        // [THEN] Check that reservation worksheet line for the sales order "1" is deleted.
        // [THEN] Check that sales order "1" stays reserved for correct quantity.
    end;

    [Test]
    procedure EmptyingBatchAndRecentChanges()
    begin
        // TODO:
        // [SCENARIO] Empty worksheet batch and check that Recent Changes are empty.

        // [GIVEN] Populate reservation worksheet batch with some lines.
        // [GIVEN] Populate reservation worksheet log with some lines.
        // [GIVEN] Populate allocation policy with some lines.

        // [WHEN] Empty reservation worksheet batch.

        // [THEN] All reservation worksheet lines for this batch are deleted.
        // [THEN] All reservation worksheet log lines for this batch are deleted.
        // [THEN] All allocation policy lines for this batch are deleted.
    end;

    [Test]
    [HandlerFunctions('GetDemandToReserveRequestPageHandler')]
    procedure AllocatingQuantityByCustomerPriorityRule()
    var
        ItemJournalLine: Record "Item Journal Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        ReservationWkshLine: Record "Reservation Wksh. Line";
        AllocationPolicy: Record "Allocation Policy";
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        ItemList: List of [Code[20]];
        SalesOrderList: List of [Code[20]];
        i: Integer;
    begin
        // [SCENARIO] Distribute available stock among reservation worksheet lines using "By Customer Priority" allocation rule.
        Initialize();

        // [GIVEN] Item with 130 units in inventory.
        ItemList.Add(LibraryInventory.CreateItemNo());
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemList.Get(1), '', '', 130);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Prepare set of 6 sales orders for 3 customers. Each order is for 50 units.
        // [GIVEN] Assign priority 1 to the first customer, priority 2 to the second customer, priority 3 to the third customer.
        for i := 1 to 3 do begin
            LibrarySales.CreateCustomer(Customer);
            Customer.Validate(Priority, i);
            Customer.Modify(true);

            LibrarySales.CreateSalesDocumentWithItem(
              SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", ItemList.Get(1), 50, '', WorkDate());
            SalesOrderList.Add(SalesHeader."No.");
            LibrarySales.CreateSalesDocumentWithItem(
              SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", ItemList.Get(1), 50, '', WorkDate());
            SalesOrderList.Add(SalesHeader."No.");
        end;

        // [GIVEN] Set up the only allocation rule = "By Customer Priority".
        ReservationWkshBatch.FindFirst();
        AllocationPolicy.Init();
        AllocationPolicy."Journal Batch Name" := ReservationWkshBatch.Name;
        AllocationPolicy."Line No." := 10000;
        AllocationPolicy."Allocation Rule" := "Allocation Rules Impl."::"By Customer Priority";
        AllocationPolicy.Insert();

        // [GIVEN] Open Reservation Worksheet and run "Get Demand" filtered by the item.
        GetDemand(ReservationWkshBatch.Name, ItemList);

        // [WHEN] Allocate quantity.
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWorksheetMgt.AllocateQuantity(ReservationWkshLine);

        // [THEN] Verify that only sales orders for the customer with the highest priority 3 are fulfilled.
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(1), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(2), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(3), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(4), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(5), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(5)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(6), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(6)));

        // [THEN] Post 130 more units to inventory.
        // [THEN] Run "Get Demand" and allocate quantity.
        // [THEN] Verify that sales orders for the customers with priorities 3 and 2 are fulfilled.
        // [THEN] The system allocates 0 units for the customer with priority 1 because their sales orders cannot be fully fulfilled.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemList.Get(1), '', '', 130);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        GetDemand(ReservationWkshBatch.Name, ItemList);
        ReservationWkshLine.Reset();
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWorksheetMgt.AllocateQuantity(ReservationWkshLine);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(1), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(2), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(3), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(3)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(4), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(4)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(5), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(5)));
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(6), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(6)));
    end;

    [Test]
    [HandlerFunctions('GetDemandToReserveRequestPageHandler')]
    procedure AllocatingQuantityByCustomerDontJumpOverPriority()
    var
        ItemJournalLine: Record "Item Journal Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        ReservationWkshLine: Record "Reservation Wksh. Line";
        AllocationPolicy: Record "Allocation Policy";
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        ItemList: List of [Code[20]];
        SalesOrderList: List of [Code[20]];
        SalesQtys: List of [Decimal];
        i: Integer;
    begin
        // [SCENARIO] Stop distribution by customer priority if the current priority cannot be fulfilled.
        Initialize();

        // [GIVEN] Item with 100 units in inventory.
        ItemList.Add(LibraryInventory.CreateItemNo());
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemList.Get(1), '', '', 100);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Prepare set of 3 sales orders for 3 customers:
        // [GIVEN] Customer "A", lowest priority, 40 units.
        // [GIVEN] Customer "B", middle priority, 80 units.
        // [GIVEN] Customer "C", highest priority, 40 units.
        SalesQtys.Add(40);
        SalesQtys.Add(80);
        SalesQtys.Add(40);

        for i := 1 to 3 do begin
            LibrarySales.CreateCustomer(Customer);
            Customer.Validate(Priority, i);
            Customer.Modify(true);

            LibrarySales.CreateSalesDocumentWithItem(
              SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", ItemList.Get(1), SalesQtys.Get(i), '', WorkDate());
            SalesOrderList.Add(SalesHeader."No.");
        end;

        // [GIVEN] Set up the only allocation rule = "By Customer Priority".
        ReservationWkshBatch.FindFirst();
        AllocationPolicy.Init();
        AllocationPolicy."Journal Batch Name" := ReservationWkshBatch.Name;
        AllocationPolicy."Line No." := 10000;
        AllocationPolicy."Allocation Rule" := "Allocation Rules Impl."::"By Customer Priority";
        AllocationPolicy.Insert();

        // [GIVEN] Open Reservation Worksheet and run "Get Demand" filtered by the item.
        GetDemand(ReservationWkshBatch.Name, ItemList);

        // [WHEN] Allocate quantity.
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWorksheetMgt.AllocateQuantity(ReservationWkshLine);

        // [THEN] Verify that only sales order for the customer with the highest priority is fulfilled.
        // [THEN] Since it isn't possible to fulfill the customer with the middle priority, the allocation process stops.
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(1), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(2), 0);
        VerifyQtyToReserveOnReservWkshLine(ReservationWkshLine, SalesOrderList.Get(3), GetOutstandingQtyOnSalesLine(SalesOrderList.Get(3)));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Reservation Worksheet");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        ClearReservationWorksheets();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Reservation Worksheet");

        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Reservation Worksheet");
    end;

    local procedure ClearReservationWorksheets()
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
    begin
        ReservationWkshBatch.DeleteAll(true);

        ReservationWkshBatch.Init();
        ReservationWkshBatch.Name := DefaultBatchTok;
        ReservationWkshBatch.Insert();
    end;

    local procedure PrepareInventory(var ItemList: List of [Code[20]]; var LocationList: List of [Code[10]])
    var
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
    begin
        Clear(ItemList);
        Clear(LocationList);

        ItemList.Add(LibraryInventory.CreateItemNo());
        ItemList.Add(LibraryInventory.CreateItemNo());
        ItemList.Add(LibraryInventory.CreateItemNo());

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LocationList.Add(Location.Code);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LocationList.Add(Location.Code);

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemList.Get(1), LocationList.Get(1), '', 10);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemList.Get(1), LocationList.Get(2), '', 2.5);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemList.Get(2), LocationList.Get(1), '', 15);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemList.Get(2), LocationList.Get(2), '', 7);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemList.Get(3), LocationList.Get(1), '', 0.66);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemList.Get(3), LocationList.Get(2), '', 4);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PrepareSetOfSalesOrders(var SalesOrderList: List of [Code[20]]; ItemList: List of [Code[20]]; LocationList: List of [Code[10]])
    begin
        Clear(SalesOrderList);

        CreateSalesOrder(SalesOrderList, ItemList.Get(1), 1, LocationList.Get(1), WorkDate() + 5);
        CreateSalesOrder(SalesOrderList, ItemList.Get(1), 2, LocationList.Get(1), WorkDate() + 5);
        CreateSalesOrder(SalesOrderList, ItemList.Get(1), 3, LocationList.Get(2), WorkDate() + 15);
        CreateSalesOrder(SalesOrderList, ItemList.Get(2), 4.1, LocationList.Get(1), WorkDate() + 20);
        CreateSalesOrder(SalesOrderList, ItemList.Get(2), 5.2, LocationList.Get(1), WorkDate() + 25);
        CreateSalesOrder(SalesOrderList, ItemList.Get(2), 6.3, LocationList.Get(2), WorkDate() + 30);
        CreateSalesOrder(SalesOrderList, ItemList.Get(2), 7.4, LocationList.Get(2), WorkDate() + 35);
        CreateSalesOrder(SalesOrderList, ItemList.Get(2), 8.5, LocationList.Get(2), WorkDate() + 40);
        CreateSalesOrder(SalesOrderList, ItemList.Get(3), 0, LocationList.Get(1), WorkDate() + 45);
        CreateSalesOrder(SalesOrderList, ItemList.Get(3), 0.1, LocationList.Get(1), WorkDate() + 50);
        CreateSalesOrder(SalesOrderList, ItemList.Get(3), 0.01, LocationList.Get(1), WorkDate() + 55);
        CreateSalesOrder(SalesOrderList, ItemList.Get(3), 0.001, LocationList.Get(1), WorkDate() + 60);
        CreateSalesOrder(SalesOrderList, ItemList.Get(3), 1.98, LocationList.Get(2), WorkDate() + 65);
        CreateSalesOrder(SalesOrderList, ItemList.Get(3), 1.876, LocationList.Get(2), WorkDate() + 70);
        CreateSalesOrder(SalesOrderList, ItemList.Get(3), 1.7654, LocationList.Get(2), WorkDate() + 75);
    end;

    local procedure CreateSalesOrder(var SalesOrderList: List of [Code[20]]; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; ShipmentDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, Qty, LocationCode, ShipmentDate);
        SalesOrderList.Add(SalesHeader."No.");
    end;

    local procedure GetDemand(ReservationWkshBatchName: Code[10]; ItemList: List of [Code[20]])
    var
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        ItemNo: Code[20];
        ItemNoFilter: Text;
    begin
        foreach ItemNo in ItemList do
            ItemNoFilter += ItemNo + '|';
        ItemNoFilter := CopyStr(ItemNoFilter, 1, StrLen(ItemNoFilter) - 1);

        Commit();
        LibraryVariableStorage.Enqueue(ItemNoFilter);
        ReservationWorksheetMgt.CalculateDemand(ReservationWkshBatchName);
    end;

    local procedure VerifyQtyToReserveOnReservWkshLine(var ReservationWkshLine: Record "Reservation Wksh. Line"; SalesOrderNo: Code[20]; QtyToReserve: Decimal)
    begin
        ReservationWkshLine.SetRange("Source ID", SalesOrderNo);
        ReservationWkshLine.FindFirst();
        ReservationWkshLine.TestField("Qty. to Reserve", QtyToReserve);
    end;

    local procedure GetOutstandingQtyOnSalesLine(SalesOrderNo: Code[20]): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderNo);
        SalesLine.FindFirst();
        exit(SalesLine."Outstanding Quantity");
    end;

    [RequestPageHandler]
    procedure GetDemandToReserveRequestPageHandler(var GetDemandToReserve: TestRequestPage "Get Demand To Reserve")
    begin
        GetDemandToReserve.FilterItem.SetFilter("No.", LibraryVariableStorage.DequeueText());
        GetDemandToReserve.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CarryOutReservationRequestPageHandler(var CarryOutReservation: TestRequestPage "Carry Out Reservation")
    begin
        CarryOutReservation."Demand Type".SetValue("Reservation Demand Type"::All);
        CarryOutReservation.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [StrMenuHandler]
    procedure StrMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Option);
        Choice := 1;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

