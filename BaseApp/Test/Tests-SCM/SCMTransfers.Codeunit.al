codeunit 137038 "SCM Transfers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM] [Transfer Order]
        isInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        DummyTransferOrderPage: TestPage "Transfer Order";
        LocationCode: array[5] of Code[10];
        SourceDocument: Option ,"S. Order","S. Invoice","S. Credit Memo","S. Return Order","P. Order","P. Invoice","P. Credit Memo","P. Return Order","Inb. Transfer","Outb. Transfer","Prod. Consumption","Item Jnl.","Phys. Invt. Jnl.","Reclass. Jnl.","Consumption Jnl.","Output Jnl.","BOM Jnl.","Serv. Order","Job Jnl.","Assembly Consumption","Assembly Order";
        isInitialized: Boolean;
        ErrNoOfLinesMustBeEqual: Label 'No. of Line Must Be Equal.';
        TransferOrderCountErr: Label 'Wrong Transfer Order''s count';
        ItemIsNotOnInventoryErr: Label 'Item %1 is not in inventory.', Locked = true;
        UpdateFromHeaderLinesQst: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        UpdateLineDimQst: Label 'You have changed one or more dimensions on the';
        TransferOrderSubpageNotUpdatedErr: Label 'Transfer Order subpage is not updated.';
        AnotherItemWithSameDescTxt: Label 'We found an item with the description';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderCalcNetChange()
    var
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        ItemNo: array[4] of Code[20];
    begin
        // Setup  : Update Sales Setup. Create Transfer setup
        Initialize;
        UpdateSalesReceivablesSetup;
        CreateTransferSetup(SalesHeader, ItemNo, true);

        // Execute : Create Planning Worksheet and Calculate Net Change Plan.
        CreateReqLine(RequisitionLine);
        CalculateNetChangePlan(RequisitionLine, SalesHeader."Shipment Date", ItemNo);

        // Verify : Verify Seven Requisition Lines Exist in Planning Worksheet.
        // One Item Line for Item4 and Item1 each.Two Item Lines for Item3 and three Item lines for Item2.
        VerifyNumberOfRequisitionLine(ItemNo, 7);

        // Execute : Carry Out Action Message in Planning Worksheet.
        CarryOutActionMsgPlanSetup(RequisitionLine, ItemNo);

        // Verify : Verify no Requisition Lines Exist in Planning Worksheet after Carry Out Action Message in Requisition Worksheet.
        VerifyNumberOfRequisitionLine(ItemNo, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrdCalcNetChange()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        ItemNo: array[4] of Code[20];
    begin
        // Setup  : Update Sales Setup. Create Transfer setup.
        Initialize;
        UpdateSalesReceivablesSetup;
        CreateTransferSetup(SalesHeader, ItemNo, true);

        // Create and Update Purchase Order for ItemNo2 with LocationCode4.
        CreatePurchaseOrder(PurchaseHeader, ItemNo[2], LibraryRandom.RandInt(10));
        UpdatePurchaseLine(PurchaseHeader, LocationCode[4]);

        // Execute : Create Planning Worksheet and Calculate Net Change Plan.
        CreateReqLine(RequisitionLine);
        CalculateNetChangePlan(RequisitionLine, SalesHeader."Shipment Date", ItemNo);

        // Verify : Verify ItemNo exist Planning Worksheet.
        VerifyItemNoExistInReqLine(ItemNo[1]);

        // Execute : Carry Out Action Message in Planning Worksheet.
        CarryOutActionMsgPlanSetup(RequisitionLine, ItemNo);

        // Verify : Verify no Requisition Lines Exist in Planning Worksheet after Carry Out Action Message in Requisition Worksheet.
        VerifyNumberOfRequisitionLine(ItemNo, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestTransferOrderNotifications()
    var
        SalesHeader: Record "Sales Header";
        TransferLine: Record "Transfer Line";
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NbNotifs: Integer;
        ItemNo: array[4] of Code[20];
        TransferOrderNo: Code[20];
    begin
        // SCENARIO: Create a transfer order with a big quantity decrease the quantity and check the notification is recalled.
        Initialize;
        LibrarySales.SetStockoutWarning(true);
        CreateTransferSetup(SalesHeader, ItemNo, true);
        TransferOrderNo := CreateTransferOrder(
            TransferLine, LocationCode[4], LocationCode[2], ItemNo[2], CalcDate('<-1Y>', SalesHeader."Order Date"),
            LibraryRandom.RandInt(5));
        EditTransferOrderQuantity(TransferOrderNo, 1); // This will send a notification (no item in inventory)
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        NbNotifs := TempNotificationContext.Count();

        // WHEN we decrease the quantity so the item is available (0 items ordered)
        EditTransferOrderQuantity(TransferOrderNo, 0);

        // THEN the item availability notification is recalled
        Assert.AreEqual(NbNotifs - 1, TempNotificationContext.Count, 'Unexpected number of notifications after decreasing the Quantity.');

        LibrarySales.SetStockoutWarning(false);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Normal]
    local procedure EditTransferOrderQuantity(TransferOrderNo: Code[20]; TransferQuantity: Integer)
    begin
        // Method Edits Transfer Order Quantity.
        OpenTransferOrderPageByNo(TransferOrderNo, DummyTransferOrderPage);

        // EXECUTE: Change Transfer Quantity on Transfer Order Through UI.
        DummyTransferOrderPage.TransferLines.Quantity.Value(Format(TransferQuantity));
        DummyTransferOrderPage.Close;
    end;

    [Normal]
    local procedure OpenTransferOrderPageByNo(TransferOrderNoToFind: Code[20]; TransferOrderToReturn: TestPage "Transfer Order")
    begin
        // Method Opens transfer order page for the transfer order no.
        TransferOrderToReturn.OpenEdit;
        Assert.IsTrue(
          TransferOrderToReturn.GotoKey(TransferOrderNoToFind),
          'Unable to locate transfer order with transfer no');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrdCalcNetChange()
    var
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        TransferLine: Record "Transfer Line";
        RequisitionLine: Record "Requisition Line";
        ItemNo: array[4] of Code[20];
    begin
        // Setup  : Update Sales Setup. Create Transfer setup.
        Initialize;
        UpdateSalesReceivablesSetup;
        CreateTransferSetup(SalesHeader, ItemNo, true);

        // Create and Post Item Journal Line with Entry Type as Positive Adjustment.
        CreateAndPostItemJrnl(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo[3], LibraryRandom.RandInt(10) + 10);

        // Update Reordering Policy in SKU and Create Transfer Order.
        UpdateReorderingPolicy(LocationCode[4], ItemNo[2]);
        UpdateReorderingPolicy(LocationCode[2], ItemNo[2]);
        CreateTransferOrder(
          TransferLine, LocationCode[4], LocationCode[2], ItemNo[2], CalcDate('<-1Y>', SalesHeader."Order Date"),
          LibraryRandom.RandInt(5));

        // Execute : Create Planning Worksheet and Calculate Net Change Plan.
        CreateReqLine(RequisitionLine);
        CalculateNetChangePlan(RequisitionLine, SalesHeader."Shipment Date", ItemNo);

        // Verify : Verify Seven Requisition Lines Exist in Planning Worksheet.
        // One Item Line for Item4 and Item1 each.Two Item Lines for Item3 and Three Item lines for Item2.
        VerifyNumberOfRequisitionLine(ItemNo, 7);

        // Execute : Carry Out Action Message in Planning Worksheet.
        CarryOutActionMsgPlanSetup(RequisitionLine, ItemNo);

        // Verify : Verify no Requisition Lines Exist in Planning Worksheet after Carry Out Action Message in Requisition Worksheet.
        VerifyNumberOfRequisitionLine(ItemNo, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferPurchOrdeCalcNetChange()
    var
        SalesHeader: Record "Sales Header";
        TransferLine: Record "Transfer Line";
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        ItemNo: array[4] of Code[20];
    begin
        // Setup  : Update Sales Setup. Create Transfer setup.
        Initialize;
        UpdateSalesReceivablesSetup;
        CreateTransferSetup(SalesHeader, ItemNo, false);

        // Create Transfer Order.
        CreateTransferOrder(
          TransferLine, LocationCode[1], LocationCode[4], ItemNo[4], CalcDate('<3D>', WorkDate), LibraryRandom.RandInt(5));

        // Create and Update Purchase Order for ItemNo2 with LocationCode4.
        CreatePurchaseOrder(PurchaseHeader, ItemNo[2], TransferLine.Quantity);
        UpdatePurchaseLine(PurchaseHeader, LocationCode[3]);

        // Execute : Create Planning Worksheet and Calculate Net Change Plan.
        CreateReqLine(RequisitionLine);
        CalculateNetChangePlan(RequisitionLine, TransferLine."Shipment Date", ItemNo);

        // Verify : Verify 8 req. lines are generated:
        // One Prod. Order for top item.
        // One Prod. Order and one Transfer Order for subassembly.
        // Cancel Purchase for end component, recreate Purchase Order for end component in different location, 2 Transfer Orders to bring the end component at the top item prod. location.
        // One Purchase Order for subassembly end component, at the subassembly prod. location.
        VerifyNumberOfRequisitionLine(ItemNo, 8);
        VerifyReqLineActMessageCancel(ItemNo[2]);

        // Execute : Carry Out Action Message in Planning Worksheet for Order Type Purchase.
        RequisitionLine.SetRange("Ref. Order Type", RequisitionLine."Ref. Order Type"::Purchase);
        RequisitionLine.FindSet;
        CarryOutActionMsgPlanSetup(RequisitionLine, ItemNo);

        // Verify : Verify 5 Requisition Lines are left in Planning Worksheet after purchase order messages have been carried out.
        VerifyNumberOfRequisitionLine(ItemNo, 5);
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgPlanHandler')]
    [Scope('OnPrem')]
    procedure PlanningCombineTransfersSplit()
    var
        LocationCode: array[3] of Code[10];
    begin
        // Verify Transfer Orders are combined when planning transfer lines are splitted
        PlanningCombineTransfers(LocationCode, true);

        VerifyTransferOrderCount(LocationCode[1], LocationCode[2], 1);
        VerifyTransferOrderCount(LocationCode[1], LocationCode[3], 1);
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgPlanHandler')]
    [Scope('OnPrem')]
    procedure PlanningNotCombineTransfersSplit()
    var
        LocationCode: array[3] of Code[10];
    begin
        // Verify Transfer Orders are not combined when planning transfer lines are splitted
        PlanningCombineTransfers(LocationCode, false);

        VerifyTransferOrderCount(LocationCode[1], LocationCode[2], 2);
        VerifyTransferOrderCount(LocationCode[1], LocationCode[3], 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TransferChangeTransferTo()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO] Can Change "Transfer-to Code" for Transfer Order if it contains description line.

        // [GIVEN] Transfer Order with description line.
        Initialize;
        CreateUpdateLocations;
        CreateTransferRoutes;

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationCode[1], LocationCode[4], LocationCode[5]);
        LibraryInventory.CreateTransferLine(
          TransferHeader, TransferLine, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(5));
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, '', 0);

        // [WHEN] Change "Transfer-to Code" in Transfer Header.
        TransferHeader.Validate("Transfer-to Code", LocationCode[2]);

        // [THEN] Transfer Line with description "Transfer-to Code" remains empty.
        TransferLine.TestField("Transfer-to Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrdApplyToILE()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
    begin
        // [FEATURE] [Transfer] [Cost Application]
        // [SCENARIO] Field "Appl.-to Item Entry" is available for Transfer Order Lines.

        // [GIVEN] Item "I" available on Location "A", stock is positively adjusted by ILE no. "N"
        Initialize;
        CreateUpdateLocations;

        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify();

        CreateTransferRoutes;
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandIntInRange(10, 20),
          LibraryRandom.RandIntInRange(10, 20), LocationCode[4], '');

        // [GIVEN] Create Transfer Order for Item "I" from Location "A" to Location "B". Apply to ILE "N".
        CreateTransferOrder(
          TransferLine, LocationCode[4], LocationCode[2], Item."No.", WorkDate, LibraryRandom.RandInt(5));
        TransferLine.Validate("Appl.-to Item Entry", FindLastILENo(Item."No."));
        TransferLine.Modify();

        // [WHEN] Ship Transfer Order.
        TransferHeader.Get(TransferLine."Document No.");
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [THEN] Item Application Entry is created to ILE "N".
        VerifyItemApplicationEntry(Item."No.", TransferLine."Appl.-to Item Entry");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrdApplyToILECalcCost()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LastCost: Decimal;
    begin
        // [FEATURE] [Transfer] [Cost Application] [Adjust Cost Item Entries]
        // [SCENARIO] Average cost Item is not adjusted when used transfer order with fixed application.

        // [GIVEN] Item "I" available on Location "A", stock is positively adjusted by 2 ILE: "1" of cost "X" and "2" of cost "Y"
        Initialize;
        CreateUpdateLocations;

        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify();

        CreateTransferRoutes;
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandIntInRange(10, 20),
          LibraryRandom.RandIntInRange(10, 20), LocationCode[4], '');
        LastCost := LibraryRandom.RandIntInRange(30, 40);
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandIntInRange(10, 20),
          LastCost, LocationCode[4], '');

        // [GIVEN] Create Transfer Order for Item "I" from Location "A" to Location "B". Apply to ILE "N".
        CreateTransferOrder(
          TransferLine, LocationCode[4], LocationCode[2], Item."No.", WorkDate, LibraryRandom.RandInt(5));
        TransferLine.Validate("Appl.-to Item Entry", FindLastILENo(Item."No."));
        TransferLine.Modify();

        // [GIVEN] Post Transfer Order.
        TransferHeader.Get(TransferLine."Document No.");
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [WHEN] Adjust Cost - Item Entries
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Item Entries of Posted Transfer Order have cost "Y" of ILE "2".
        VerifyItemApplicationEntryCost(Item."No.", ItemLedgerEntry."Entry Type"::Transfer, LastCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToShipUpdatedManuallyOnNonWMSLocation()
    var
        Location: Record Location;
        WMSLocation: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        Qty: Decimal;
    begin
        // [FEATURE] [Transfer]
        // [SCENARIO 377487] "Qty. to Ship" in transfer order can be updated when transferring from a non-WMS location and a warehouse receipt exists in the destination location

        // [GIVEN] Location "L1" without WMS setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        // [GIVEN] Location "L2" with warehouse receipt requirement
        LibraryWarehouse.CreateLocationWMS(WMSLocation, false, false, false, true, false);

        Qty := LibraryRandom.RandIntInRange(100, 200);
        CreateItemWithPositiveInventory(Item, Location.Code, Qty * 2);

        // [GIVEN] Create transfer order from "L1" to "L2". Quantity = "Q", set "Qty. to Ship" = "Q" / 2
        CreateTransferOrderNoRoute(TransferHeader, TransferLine, Location.Code, WMSLocation.Code, Item."No.", '', Qty * 2);

        // [GIVEN] Post transfer shipment
        TransferLine.Validate("Qty. to Ship", Qty);
        TransferLine.Modify(true);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [GIVEN] Create warehouse receipt on location "L2" from transfer order
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);

        TransferOrder.OpenEdit;
        TransferOrder.GotoRecord(TransferHeader);
        // [WHEN] Change "Qty. to Ship" in transfer order line
        Qty := LibraryRandom.RandInt(TransferLine."Qty. to Ship" - 1);
        TransferOrder.TransferLines."Qty. to Ship".SetValue(Qty);
        TransferOrder.OK.Invoke;

        // [THEN] New value is accepted
        TransferLine.Find;
        TransferLine.TestField("Qty. to Ship", Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToReceiveUpdatedManuallyOnNonWMSLocation()
    var
        Location: Record Location;
        WMSLocation: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        Qty: Decimal;
    begin
        // [FEATURE] [Transfer]
        // [SCENARIO 377487] "Qty. to Receive" in transfer order can be updated when transferring to a non-WMS location and a warehouse shipment exists in the source location

        // [GIVEN] Location "L1" with warehouse shipment requirement
        LibraryWarehouse.CreateLocationWMS(WMSLocation, false, false, false, false, true);
        // [GIVEN] Location "L2" without WMS setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        Qty := LibraryRandom.RandIntInRange(100, 200);
        CreateItemWithPositiveInventory(Item, WMSLocation.Code, Qty * 2);

        // [GIVEN] Create transfer order from "L1" to "L2". Quantity = "Q"
        CreateTransferOrderNoRoute(TransferHeader, TransferLine, WMSLocation.Code, Location.Code, Item."No.", '', Qty * 2);
        // [GIVEN] Create warehouse shipment from transfer order, set "Qty. to Ship" = "Q" / 2 and post shipment
        CreateAndPostWhseShipmentFromTransferOrder(TransferHeader, Qty);

        TransferOrder.OpenEdit;
        TransferOrder.GotoRecord(TransferHeader);
        // [WHEN] Change "Qty. to Receive" in transfer order line
        Qty := LibraryRandom.RandInt(TransferLine."Quantity Shipped" - 1);
        TransferOrder.TransferLines."Qty. to Receive".SetValue(Qty);
        TransferOrder.OK.Invoke;

        // [THEN] New value is accepted
        TransferLine.Find;
        TransferLine.TestField("Qty. to Receive", Qty);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ChangeTransferLineItemNoAfterPostingError_Post()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        NewItemNo: Code[20];
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378688] TransferLine."Item No." can be changed after posting error ("Post" action)
        Initialize;

        // [GIVEN] Transfer order with two lines: item "A", item "B" (items are not available on stock)
        PrepareSimpleTransferOrderWithTwoLines(TransferHeader, TransferLine);
        // [GIVEN] Try post (ship). An error occurs: "Item "A" is not in inventory."
        TransferOrder.OpenEdit;
        TransferOrder.GotoRecord(TransferHeader);
        asserterror TransferOrder.Post.Invoke;
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));
        // [GIVEN] Enter a new "Item No." into first transfer line: item "C"
        NewItemNo := LibraryInventory.CreateItemNo;
        TransferOrder.TransferLines."Item No.".SetValue(NewItemNo);

        // [WHEN] Move to the second transfer line
        TransferOrder.TransferLines.GotoRecord(TransferLine[2]);

        // [THEN] No error is occurred and first transfer line's "Item No." = "C"
        TransferLine[1].Find;
        Assert.AreEqual(NewItemNo, TransferLine[1]."Item No.", TransferLine[1].FieldCaption("Item No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ChangeTransferLineItemNoAfterPostingError_PostAndPrint()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        NewItem1No: Code[20];
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378688] TransferLine."Item No." can be changed after posting error ("Post And Print" action)
        Initialize;

        // [GIVEN] Transfer order with two lines: item "A", item "B" (items are not available on stock)
        PrepareSimpleTransferOrderWithTwoLines(TransferHeader, TransferLine);
        // [GIVEN] Try post (ship). An error occurs: "Item "A" is not in inventory."
        TransferOrder.OpenEdit;
        TransferOrder.GotoRecord(TransferHeader);
        asserterror TransferOrder.PostAndPrint.Invoke;
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));
        // [GIVEN] Enter a new "Item No." into first transfer line: item "C"
        NewItem1No := LibraryInventory.CreateItemNo;
        TransferOrder.TransferLines."Item No.".SetValue(NewItem1No);

        // [WHEN] Move to the second transfer line
        TransferOrder.TransferLines.GotoRecord(TransferLine[2]);

        // [THEN] No error is occurred and first transfer line's "Item No." = "C"
        TransferLine[1].Find;
        Assert.AreEqual(NewItem1No, TransferLine[1]."Item No.", TransferLine[1].FieldCaption("Item No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SecondTansferOrderPostAfterPostingError_Post()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378688] Second "Post" of transfer order gets the same error as the first one: "Item X is not in inventory."
        Initialize;

        // [GIVEN] Transfer order with a new item "X" (not available on stock)
        PrepareSimpleTransferOrderWithTwoLines(TransferHeader, TransferLine);
        // [GIVEN] Try post (ship). An error occurs: "Item "X" is not in inventory."
        TransferOrder.OpenEdit;
        TransferOrder.GotoRecord(TransferHeader);
        asserterror TransferOrder.Post.Invoke;
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));

        // [WHEN] Try post again (ship).
        asserterror TransferOrder.Post.Invoke;

        // [THEN] The same error occurs: "Item "X" is not in inventory."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SecondTansferOrderPostAfterPostingError_PostAndPrint()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378688] Second "Post And Print" of transfer order gets the same error as the first one: "Item X is not in inventory."
        Initialize;

        // [GIVEN] Transfer order with a new item "X" (not available on stock)
        PrepareSimpleTransferOrderWithTwoLines(TransferHeader, TransferLine);
        // [GIVEN] Try post (ship). An error occurs: "Item "X" is not in inventory."
        TransferOrder.OpenEdit;
        TransferOrder.GotoRecord(TransferHeader);
        asserterror TransferOrder.PostAndPrint.Invoke;
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));

        // [WHEN] Try post again (ship).
        asserterror TransferOrder.PostAndPrint.Invoke;

        // [THEN] The same error occurs: "Item "X" is not in inventory."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SecondTansferOrderPostFromListPageAfterPostingError_Post()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        TransferList: TestPage "Transfer Orders";
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378688] Second "Post" of transfer order (from Transfer List page) gets the same error as the first one: "Item X is not in inventory."
        Initialize;

        // [GIVEN] Transfer order with a new item "X" (not available on stock)
        PrepareSimpleTransferOrderWithTwoLines(TransferHeader, TransferLine);
        // [GIVEN] Try post (ship) from "Transfer List" page. An error occurs: "Item "X" is not in inventory."
        TransferList.OpenEdit;
        TransferList.GotoRecord(TransferHeader);
        asserterror TransferList.Post.Invoke;
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));

        // [WHEN] Try post again (ship).
        asserterror TransferList.Post.Invoke;

        // [THEN] The same error occurs: "Item "X" is not in inventory."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SecondTansferOrderPostFromListPageAfterPostingError_PostAndPrint()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        TransferList: TestPage "Transfer Orders";
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378688] Second "Post And Print" of transfer order (from Transfer List page) gets the same error as the first one: "Item X is not in inventory."
        Initialize;

        // [GIVEN] Transfer order with a new item "X" (not available on stock)
        PrepareSimpleTransferOrderWithTwoLines(TransferHeader, TransferLine);
        // [GIVEN] Try post (ship) from "Transfer List" page. An error occurs: "Item "X" is not in inventory."
        TransferList.OpenEdit;
        TransferList.GotoRecord(TransferHeader);
        asserterror TransferList.PostAndPrint.Invoke;
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));

        // [WHEN] Try post again (ship).
        asserterror TransferList.PostAndPrint.Invoke;

        // [THEN] The same error occurs: "Item "X" is not in inventory."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForTransferHeaderDimUpdate')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderGlobalDimConfirmYes()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is updated after the change of dimension value is confirmed on Transfer Header.
        Initialize;

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(true); // to reply Yes on second confirmation
        TransferHeader.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer Yes on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForTransferHeaderDimUpdate

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        TransferLine.Find;
        VerifyDimensionOnDimSet(TransferLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForTransferHeaderDimUpdate')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderGlobalDimConfirmNo()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is not updated if the change of dimension value is not confirmed on Transfer Header.
        Initialize;

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        SavedDimSetID := TransferLine."Dimension Set ID";
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(false); // to reply No on second confirmation
        asserterror TransferHeader.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer Yes on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForTransferHeaderDimUpdate

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        TransferLine.Find;
        TransferLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForTransferHeaderDimUpdate,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderDimSetPageConfirmYes()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is updated after the change of dimension value is confirmed on Transfer Order page.
        Initialize;

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        LibraryVariableStorage.Enqueue(true); // to reply Yes on second confirmation
        TransferOrder.OpenEdit;
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");
        TransferOrder.Dimensions.Invoke;

        // [WHEN] Answer Yes on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForTransferHeaderDimUpdate

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        TransferLine.Find;
        VerifyDimensionOnDimSet(TransferLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForTransferHeaderDimUpdate,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderDimSetPageConfirmNo()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
        TransferOrder: TestPage "Transfer Order";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is not updated if the change of dimension value is not confirmed on Transfer Order page.
        Initialize;

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        SavedDimSetID := TransferLine."Dimension Set ID";
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        LibraryVariableStorage.Enqueue(false); // to reply No on second confirmation
        TransferOrder.OpenEdit;
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");
        asserterror TransferOrder.Dimensions.Invoke;

        // [WHEN] Answer Yes on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForTransferHeaderDimUpdate

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        TransferLine.Find;
        TransferLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineGlobalDimConfirmYes()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is updated after the change of dimension value is confirmed.
        Initialize;

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        LibraryVariableStorage.Enqueue(true); // to reply Yes on second confirmation
        TransferLine.Find;
        TransferLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer Yes on shipped line update confirmation

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        VerifyDimensionOnDimSet(TransferLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineGlobalDimConfirmNo()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is not updated if the change of dimension value is not confirmed.
        Initialize;

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        SavedDimSetID := TransferLine."Dimension Set ID";
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        TransferLine.Find;
        asserterror TransferLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer Yes on shipped line update confirmation

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        TransferLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineDimSetPageConfirmYes()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is updated after the change of dimension value is confirmed on Transfer Order subpage.
        Initialize;

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        TransferOrder.OpenEdit;
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");
        TransferOrder.TransferLines.Dimensions.Invoke;

        // [WHEN] Answer Yes on shipped line update confirmation

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        TransferLine.Find;
        VerifyDimensionOnDimSet(TransferLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineDimSetPageConfirmNo()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
        TransferOrder: TestPage "Transfer Order";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is not updated if the change of dimension value is not confirmed on Transfer Order subpage.
        Initialize;

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        SavedDimSetID := TransferLine."Dimension Set ID";
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        TransferOrder.OpenEdit;
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");
        asserterror TransferOrder.TransferLines.Dimensions.Invoke;

        // [WHEN] Answer Yes on shipped line update confirmation

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        TransferLine.Find;
        TransferLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequireReceiveCreatesInbdWhseRequestForShippedTransfer()
    var
        Location: Record Location;
        TransferHeader: array[2] of Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // [FEATURE] [Warehouse Request] [Warehouse Receipt]
        // [SCENARIO 381426] Warehouse Request is created for shipped not received Transfer Order when "Require Receipt" is set on destination Location. The status of the Whse. Request matches the status of the Transfer Order.
        Initialize;

        // [GIVEN] Item with inventory on Location "L1".
        // [GIVEN] Two partially shipped not received Transfer Orders "T1", "T2" from "L1" to Location "L2".
        CreateTwoPartlyShipTransferOrders(TransferHeader, true);

        // [GIVEN] "T2" is re-opened.
        LibraryWarehouse.ReopenTransferOrder(TransferHeader[2]);

        // [WHEN] Turn on "Require Receipt" on "L2".
        Location.Get(TransferHeader[1]."Transfer-to Code");
        Location.Validate("Require Receive", true);

        // [THEN] Warehouse Request with "Released" status is created for "T1".
        WarehouseRequest.Get(
          WarehouseRequest.Type::Inbound, Location.Code, DATABASE::"Transfer Line", 1, TransferHeader[1]."No.");
        WarehouseRequest.TestField("Document Status", TransferHeader[1].Status::Released);

        // [THEN] Warehouse Request with "Open" status is created for "T2".
        WarehouseRequest.Get(
          WarehouseRequest.Type::Inbound, Location.Code, DATABASE::"Transfer Line", 1, TransferHeader[2]."No.");
        WarehouseRequest.TestField("Document Status", TransferHeader[2].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequirePutAwayCreatesInbdWhseRequestForShippedTransfer()
    var
        Location: Record Location;
        TransferHeader: array[2] of Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // [FEATURE] [Warehouse Request] [Inventory Put-away]
        // [SCENARIO 381426] Warehouse Request is created for shipped not received Transfer Order when "Require Put-away" is set on destination Location. The status of the Whse. Request matches the status of the Transfer Order.
        Initialize;

        // [GIVEN] Item with inventory on Location "L1".
        // [GIVEN] Two partially shipped not received Transfer Orders "T1", "T2" from "L1" to Location "L2".
        CreateTwoPartlyShipTransferOrders(TransferHeader, true);

        // [GIVEN] "T2" is re-opened.
        LibraryWarehouse.ReopenTransferOrder(TransferHeader[2]);

        // [WHEN] Turn on "Require Put-away" on "L2".
        Location.Get(TransferHeader[1]."Transfer-to Code");
        Location.Validate("Require Put-away", true);

        // [THEN] Warehouse Request with "Released" status is created for "T1".
        WarehouseRequest.Get(
          WarehouseRequest.Type::Inbound, Location.Code, DATABASE::"Transfer Line", 1, TransferHeader[1]."No.");
        WarehouseRequest.TestField("Document Status", TransferHeader[1].Status::Released);

        // [THEN] Warehouse Request with "Open" status is created for "T2".
        WarehouseRequest.Get(
          WarehouseRequest.Type::Inbound, Location.Code, DATABASE::"Transfer Line", 1, TransferHeader[2]."No.");
        WarehouseRequest.TestField("Document Status", TransferHeader[2].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequireReceiveDoesNotCreateInbdWhseRequestForNotStartedTransfer()
    var
        Location: Record Location;
        TransferHeader: array[2] of Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // [FEATURE] [Warehouse Request]
        // [SCENARIO 381426] No Warehouse Request is created for not shipped Transfer Order when "Require Receipt" is set on destination Location.
        Initialize;

        // [GIVEN] Item with inventory on Location "L1".
        // [GIVEN] Not shipped Transfer Order "T" from "L1" to Location "L2".
        CreateTwoPartlyShipTransferOrders(TransferHeader, false);

        // [WHEN] Turn on "Require Receipt" on "L2".
        Location.Get(TransferHeader[1]."Transfer-to Code");
        Location.Validate("Require Receive", true);

        // [THEN] No Warehouse Request is created.
        WarehouseRequest.Init();
        WarehouseRequest.SetRange("Location Code", Location.Code);
        Assert.RecordIsEmpty(WarehouseRequest);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferCanBeReceivedWithNoWhseHandlingWhenRequireReceiptTurnedOnAndOff()
    var
        Location: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        // [FEATURE] [Warehouse Request]
        // [SCENARIO 381426] Transfer Order can be received with no warehouse handling when "Require Receipt" is turned on and then off on destination Location.
        Initialize;

        // [GIVEN] Item with inventory on Location "L1".
        // [GIVEN] Partly shipped Transfer Order "T" from "L1" to Location "L2".
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);

        // [GIVEN] "Require Receipt" on "L2" is turned on. This created Warehouse Request.
        Location.Get(TransferHeader."Transfer-to Code");
        Location.Validate("Require Receive", true);
        Location.Modify(true);

        // [GIVEN] "Require Receipt" on "L2" is turned off.
        Location.Validate("Require Receive", false);
        Location.Modify(true);

        // [WHEN] Post "T" with Receive option.
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [THEN] Transfer Receipt to "L2" is posted.
        TransferReceiptHeader.Init();
        TransferReceiptHeader.SetRange("Transfer-to Code", Location.Code);
        Assert.RecordIsNotEmpty(TransferReceiptHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderSubpageUpdatedAfterShipmentDateUpdatedOnHeader()
    var
        TransferOrder: TestPage "Transfer Order";
        ShipmentDateOnHeader: Date;
        ShipmentDateOnLine: Date;
    begin
        // [SCENARIO 380067] Shipment Date on Transfer Order subpage is updated after Shipment Date on the header page is updated directly.
        Initialize;
        UpdateSalesReceivablesSetup;

        // [GIVEN] Transfer Order with a new line on the subpage.
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, '');

        // [WHEN] Update Shipment Date on Transfer Order header page.
        TransferOrder."Shipment Date".SetValue(LibraryRandom.RandDate(10));

        // [THEN] Shipment Date on the subpage is updated and becomes equal to Shipment Date on the header page.
        Evaluate(ShipmentDateOnHeader, TransferOrder."Shipment Date".Value);
        Evaluate(ShipmentDateOnLine, TransferOrder.TransferLines."Shipment Date".Value);
        Assert.AreEqual(ShipmentDateOnHeader, ShipmentDateOnLine, TransferOrderSubpageNotUpdatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderSubpageUpdatedAfterShippingTimeUpdatedOnHeader()
    var
        TransferOrder: TestPage "Transfer Order";
        ShippingTime: DateFormula;
    begin
        // [SCENARIO 380067] Receipt Date on Transfer Order subpage is updated after Receipt Date on the header page is updated through new Shipping Time.
        Initialize;
        UpdateSalesReceivablesSetup;

        // [GIVEN] Transfer Order with a new line on the subpage.
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, '');

        // [WHEN] Update Shipping Time on Transfer Order header page.
        Evaluate(ShippingTime, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));
        TransferOrder."Shipping Time".SetValue(ShippingTime);

        // [THEN] Receipt Date on the subpage is updated and becomes equal to Receipt Date on the header page.
        VerifyTransferReceiptDate(TransferOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderSubpageUpdatedAfterReceiptDateUpdatedOnHeader()
    var
        TransferOrder: TestPage "Transfer Order";
    begin
        // [SCENARIO 380067] Receipt Date on Transfer Order subpage is updated after Receipt Date on the header page is updated directly.
        Initialize;
        UpdateSalesReceivablesSetup;

        // [GIVEN] Transfer Order with a new line on the subpage.
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, '');

        // [WHEN] Update Receipt Date on Transfer Order header page.
        TransferOrder."Receipt Date".SetValue(LibraryRandom.RandDate(10));

        // [THEN] Receipt Date on the subpage is updated and becomes equal to Receipt Date on the header page.
        VerifyTransferReceiptDate(TransferOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderSubpageUpdatedAfterOutboundWhseTimeUpdatedOnHeader()
    var
        TransferOrder: TestPage "Transfer Order";
        OutboundWhseHandlingTime: DateFormula;
    begin
        // [SCENARIO 380067] Receipt Date on Transfer Order subpage is updated after Receipt Date on the header page is updated through new Outbound Whse. Handling Time.
        Initialize;
        UpdateSalesReceivablesSetup;

        // [GIVEN] Transfer Order with a new line on the subpage.
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, '');

        // [WHEN] Update Outbound Whse. Handling Time on Transfer Order header page.
        Evaluate(OutboundWhseHandlingTime, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));
        TransferOrder."Outbound Whse. Handling Time".SetValue(OutboundWhseHandlingTime);

        // [THEN] Receipt Date on the subpage is updated and becomes equal to Receipt Date on the header page.
        VerifyTransferReceiptDate(TransferOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderSubpageUpdatedAfterInboundWhseTimeUpdatedOnHeader()
    var
        TransferOrder: TestPage "Transfer Order";
        InboundWhseHandlingTime: DateFormula;
    begin
        // [SCENARIO 380067] Receipt Date on Transfer Order subpage is updated after Receipt Date on the header page is updated through new Inbound Whse. Handling Time.
        Initialize;
        UpdateSalesReceivablesSetup;

        // [GIVEN] Transfer Order with a new line on the subpage.
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, '');

        // [WHEN] Update Inbound Whse. Handling Time on Transfer Order header page.
        Evaluate(InboundWhseHandlingTime, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));
        TransferOrder."Inbound Whse. Handling Time".SetValue(InboundWhseHandlingTime);

        // [THEN] Receipt Date on the subpage is updated and becomes equal to Receipt Date on the header page.
        VerifyTransferReceiptDate(TransferOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderSubpageUpdatedAfterShippingAgentUpdatedOnHeader()
    var
        TransferOrder: TestPage "Transfer Order";
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
    begin
        // [SCENARIO 380067] Receipt Date on Transfer Order subpage is updated after Receipt Date on the header page is updated through new Shipping Agent Code.
        Initialize;
        UpdateSalesReceivablesSetup;

        // [GIVEN] Shipping Agent with Shipping Agent Service.
        CreateShippingAgentCodeAndService(ShippingAgentCode, ShippingAgentServiceCode);

        // [GIVEN] Transfer Order with a new line on the subpage.
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, '');

        // [WHEN] Update Shipping Agent Code on Transfer Order header page.
        TransferOrder."Shipping Agent Code".SetValue(ShippingAgentCode);

        // [THEN] Receipt Date on the subpage is updated and becomes equal to Receipt Date on the header page.
        VerifyTransferReceiptDate(TransferOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderSubpageUpdatedAfterShippingAgentServiceUpdatedOnHeader()
    var
        TransferOrder: TestPage "Transfer Order";
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
    begin
        // [SCENARIO 380067] Receipt Date on Transfer Order subpage is updated after Receipt Date on the header page is updated through new Shipping Agent Service Code.
        Initialize;
        UpdateSalesReceivablesSetup;

        // [GIVEN] Shipping Agent with Shipping Agent Service.
        CreateShippingAgentCodeAndService(ShippingAgentCode, ShippingAgentServiceCode);

        // [GIVEN] Transfer Order with Shipping Agent and a new line on the subpage.
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, ShippingAgentCode);

        // [WHEN] Update Shipping Agent Service Code on Transfer Order header page.
        TransferOrder."Shipping Agent Service Code".SetValue(ShippingAgentServiceCode);

        // [THEN] Receipt Date on the subpage is updated and becomes equal to Receipt Date on the header page.
        VerifyTransferReceiptDate(TransferOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExistedInbdRequestForTransferIsUpdated()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
    begin
        // [FEATURE] [Warehouse Request] [UT]
        // [SCENARIO 381426] Existed inbound warehouse request is updated when CreateInboundWhseRequest function in Codeunit 5773 is called.
        Initialize;

        // [GIVEN] Transfer Order "T".
        MockTransferOrder(TransferHeader);

        // [GIVEN] Inbound warehouse request for "T".
        MockWhseRequest(WarehouseRequest.Type::Inbound, TransferHeader."Transfer-to Code", TransferHeader."No.");

        // [WHEN] Create inbound warehouse request for "T".
        WhseTransferRelease.InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status);
        WhseTransferRelease.CreateInboundWhseRequest(WarehouseRequest, TransferHeader);

        // [THEN] Existed inbound warehouse request for "T" is updated.
        TransferHeader.CalcFields("Completely Received");
        with WarehouseRequest do begin
            FilterWhseRequest(
              WarehouseRequest, Type::Inbound, TransferHeader."Transfer-to Code", 1, TransferHeader."No.");
            FindFirst;
            VerifyWhseRequest(
              WarehouseRequest, TransferHeader, SourceDocument::"Inb. Transfer", TransferHeader."Completely Received",
              "Shipment Date", TransferHeader."Receipt Date");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewInbdRequestIsNotCreatedWhenCalledFromTransferOrder()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
    begin
        // [FEATURE] [Warehouse Request] [UT]
        // [SCENARIO 381426] New inbound warehouse request is not created when CreateInboundWhseRequest function in Codeunit 5773 is called from Transfer Order.
        Initialize;

        // [GIVEN] Transfer Order "T".
        MockTransferOrder(TransferHeader);

        // [GIVEN] No inbound warehouse requests exist for "T".
        // [GIVEN] Creation of warehouse request is set to be invoked from the transfer order ("Release" button clicked on page).
        WhseTransferRelease.SetCallFromTransferOrder(true);

        // [WHEN] Create inbound warehouse request for "T".
        WhseTransferRelease.InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status);
        WhseTransferRelease.CreateInboundWhseRequest(WarehouseRequest, TransferHeader);

        // [THEN] Inbound warehouse request for "T" is not created.
        FilterWhseRequest(
          WarehouseRequest, WarehouseRequest.Type::Inbound, TransferHeader."Transfer-to Code", 1, TransferHeader."No.");
        Assert.RecordIsEmpty(WarehouseRequest);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewInbdRequestForTransferIsCreatedWhenCalledIndirectly()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
    begin
        // [FEATURE] [Warehouse Request] [UT]
        // [SCENARIO 381426] New inbound warehouse request is created when CreateInboundWhseRequest function in Codeunit 5773 is called indirectly if inbound request does not exist.
        Initialize;

        // [GIVEN] Transfer Order "T".
        MockTransferOrder(TransferHeader);

        // [GIVEN] No inbound warehouse requests exist for "T".
        // [GIVEN] Creation of warehouse request is set to be invoked not from the transfer order (i.e. on posting the transfer shipment).
        WhseTransferRelease.SetCallFromTransferOrder(false);

        // [WHEN] Create inbound warehouse request for "T".
        WhseTransferRelease.InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status);
        WhseTransferRelease.CreateInboundWhseRequest(WarehouseRequest, TransferHeader);

        // [THEN] New inbound warehouse request for "T" is created.
        TransferHeader.CalcFields("Completely Received");
        with WarehouseRequest do begin
            FilterWhseRequest(
              WarehouseRequest, Type::Inbound, TransferHeader."Transfer-to Code", 1, TransferHeader."No.");
            FindFirst;
            VerifyWhseRequest(
              WarehouseRequest, TransferHeader, SourceDocument::"Inb. Transfer", TransferHeader."Completely Received",
              0D, TransferHeader."Receipt Date");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExistedOutbdRequestForTransferUpdated()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
    begin
        // [FEATURE] [Warehouse Request] [UT]
        // [SCENARIO 381426] Existed outbound warehouse request is updated when CreateOutboundWhseRequest function in Codeunit 5773 is called.
        Initialize;

        // [GIVEN] Transfer Order "T".
        MockTransferOrder(TransferHeader);

        // [GIVEN] Outbound warehouse request for "T".
        MockWhseRequest(WarehouseRequest.Type::Outbound, TransferHeader."Transfer-from Code", TransferHeader."No.");

        // [WHEN] Create outbound warehouse request for "T".
        WhseTransferRelease.InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status);
        WhseTransferRelease.CreateOutboundWhseRequest(WarehouseRequest, TransferHeader);

        // [THEN] Existed outbound warehouse request for "T" is updated.
        TransferHeader.CalcFields("Completely Shipped");
        with WarehouseRequest do begin
            FilterWhseRequest(
              WarehouseRequest, Type::Outbound, TransferHeader."Transfer-from Code", 0, TransferHeader."No.");
            FindFirst;
            VerifyWhseRequest(
              WarehouseRequest, TransferHeader, SourceDocument::"Outb. Transfer", TransferHeader."Completely Shipped",
              "Shipment Date", "Expected Receipt Date");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewOutbdRequestForTransferCreated()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
    begin
        // [FEATURE] [Warehouse Request] [UT]
        // [SCENARIO 381426] New outbound warehouse request is created when CreateOutboundWhseRequest function in Codeunit 5773 is called if outbound request does not exist.
        Initialize;

        // [GIVEN] Transfer Order "T".
        MockTransferOrder(TransferHeader);

        // [GIVEN] No outbound warehouse requests exist for "T".

        // [WHEN] Create outbound warehouse request for "T".
        WhseTransferRelease.InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status);
        WhseTransferRelease.CreateOutboundWhseRequest(WarehouseRequest, TransferHeader);

        // [THEN] New outbound warehouse request for "T" is created.
        TransferHeader.CalcFields("Completely Shipped");
        with WarehouseRequest do begin
            FilterWhseRequest(
              WarehouseRequest, Type::Outbound, TransferHeader."Transfer-from Code", 0, TransferHeader."No.");
            FindFirst;
            VerifyWhseRequest(
              WarehouseRequest, TransferHeader, SourceDocument::"Outb. Transfer", TransferHeader."Completely Shipped",
              "Shipment Date", 0D);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewWhseReceiptForTransferAfterAdditionalQtyShippedAndReceived()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        QtyInUOM: Integer;
    begin
        // [FEATURE] [Warehouse Receipt]
        // [SCENARIO 235005] New warehouse receipt for transfer order includes only additional quantity shipped after existing warehouse receipts were created.
        Initialize;

        // [GIVEN] Location "L1" and "L2". "L2" is set up for required receipt.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWMS(LocationTo, false, false, false, true, false);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);

        // [GIVEN] Item "I" with base unit of measure "PC" and alternate unit of measure "BOX". 1 "BOX" = 5 "PC".
        QtyInUOM := LibraryRandom.RandIntInRange(2, 5);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyInUOM);

        // [GIVEN] 10 "BOX" of the item are in the inventory at location "L1".
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10 * QtyInUOM, LibraryRandom.RandDec(10, 2), LocationFrom.Code, '');

        // [GIVEN] Transfer order for 10 "BOX" from location "L1" to location "L2".
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        TransferLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);

        // [GIVEN] Partially ship the transfer order. Shipped quantity = 5 "BOX".
        UpdatePartialQuantityToShip(TransferLine, 5);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [GIVEN] Warehouse receipt "R1" at location "L2".
        // [GIVEN] Set "Qty. to Receive" = 2 "BOX" and post the receipt.
        CreateAndPostWhseReceiptFromTransferOrder(TransferHeader, 2);

        // [GIVEN] Post another partial shipment of the transfer. Shipped quantity = 3 "BOX".
        // [GIVEN] Now we have 8 "BOX" shipped and 2 "BOX" received, that is 6 "BOX" still in transit.
        // [GIVEN] 3 "BOX" out of 6 are to be posted by "R1".
        TransferLine.Find;
        UpdatePartialQuantityToShip(TransferLine, 3);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [WHEN] Create another warehouse receipt "R2".
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);

        // [THEN] Quantity on the warehouse receipt "R2" is equal to 5 "BOX" (6 "BOX" in transit + 2 "BOX" received - 3 "BOX" outstanding in "R1").
        // [THEN] "Qty. (Base)" = 25 "PC" (5 "PC" in each "BOX").
        FilterWhseReceiptLine(WarehouseReceiptLine, DATABASE::"Transfer Line", TransferHeader."No.");
        WarehouseReceiptLine.FindLast;
        WarehouseReceiptLine.TestField(Quantity, 5);
        WarehouseReceiptLine.TestField("Qty. (Base)", 5 * QtyInUOM);

        // [THEN] "Qty. to Receive" = 3 "BOX" (2 "BOX" were received by "R1").
        // [THEN] "Qty. to Receive (Base)" = 15 "PC".
        WarehouseReceiptLine.TestField("Qty. to Receive", 3);
        WarehouseReceiptLine.TestField("Qty. to Receive (Base)", 3 * QtyInUOM);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferFieldsAreReadOnlyOnPartiallyShippedTransferOrderPage()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [SCENARIO] Transfer fields are disabled on Transfer Order page when the document is partially shipped.
        Initialize;

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);

        // [WHEN] Transfer Order is opened
        TransferOrder.OpenEdit;
        TransferOrder.GotoRecord(TransferHeader);

        // [THEN] Transfer related fields are not editable
        Assert.IsFalse(TransferOrder."Transfer-from Code".Editable, 'Transfer-from Code is not expected to be editable.');
        Assert.IsFalse(TransferOrder."Transfer-to Code".Editable, 'Transfer-to Code is not expected to be editable.');
        Assert.IsFalse(TransferOrder."In-Transit Code".Editable, 'In-Transit Code is not expected to be editable.');
        Assert.IsFalse(TransferOrder."Transfer-from Address".Editable, 'Transfer-from fields are not expected to be editable.');
        Assert.IsFalse(TransferOrder."Transfer-to Address".Editable, 'Transfer-to fields are not expected to be editable.');
        Assert.IsFalse(TransferOrder."Shipping Agent Code".Editable, 'Shipment fields are not expected to be editable.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferFieldsAreEditableOnTransferOrderPageWithNoShippedLines()
    var
        TransferOrder: TestPage "Transfer Order";
    begin
        // [SCENARIO] Transfer fields are editable on Transfer Order page with no shipped lines.
        Initialize;

        // [GIVEN] Transfer Order with new transfer line initialized
        // [WHEN] Transfer Order is opened
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, '');

        // [THEN] Transfer related fields are not editable
        Assert.IsTrue(TransferOrder."Transfer-from Code".Editable, 'Transfer-from Code is expected to be editable.');
        Assert.IsTrue(TransferOrder."Transfer-to Code".Editable, 'Transfer-to Code is expected to be editable.');
        Assert.IsTrue(TransferOrder."In-Transit Code".Editable, 'In-Transit Code is expected to be editable.');
        Assert.IsTrue(TransferOrder."Transfer-from Address".Editable, 'Transfer-from fields are expected to be editable.');
        Assert.IsTrue(TransferOrder."Transfer-to Address".Editable, 'Transfer-to fields are expected to be editable.');
        Assert.IsTrue(TransferOrder."Shipping Agent Code".Editable, 'Shipment fields are expected to be editable.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingAgentServiceCodeFromWhseShpmtToTransferOrder()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ShippingAgentCode: array[2] of Code[10];
        ShippingAgentServiceCode: array[2] of Code[10];
    begin
        // [FEATURE] [Transfer Order] [Transfer Shipment] [Shipping Agent Service]
        // [SCENARIO 267371] Empty value of Shipping Agent Service Code must be transferred from Warehouse Shipment to Transfer Order when Warehouse Shipment is being posted

        Initialize;

        // [GIVEN] Create LocationFrom, LocationTo and LocationInTransit. LocationFrom is set up for Whse Shipment
        LibraryWarehouse.CreateLocationWMS(LocationFrom, false, false, false, false, true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);

        // [GIVEN] Create Item with stock
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.",
          LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandInt(100), LocationFrom.Code, '');

        // [GIVEN] Create Shipping Agent with service code
        CreateShippingAgentServiceCodeWith1YShippingTime(ShippingAgentCode[1], ShippingAgentServiceCode[1]);

        // [GIVEN] Create another Shipping Agent with empty service code
        CreateShippingAgentServiceCodeWith1YShippingTime(ShippingAgentCode[2], ShippingAgentServiceCode[2]);
        ShippingAgentServiceCode[2] := '';

        // [GIVEN] Create Transfer Order with Shipping Agent, Shipping Agent Service Code and single line
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        TransferHeader.Validate("Shipping Agent Code", ShippingAgentCode[1]);
        TransferHeader.Validate("Shipping Agent Service Code", ShippingAgentServiceCode[1]);
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(1, 5));

        // [GIVEN] Release Transfer Order and create whse. shipment
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [GIVEN] Find and modify "Shipping Agent Service Code" in whse. shipment using void value
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Transfer Line", 0, TransferHeader."No."));
        WarehouseShipmentHeader.Validate("Shipping Agent Code", ShippingAgentCode[2]);
        WarehouseShipmentHeader.Validate("Shipping Agent Service Code", ShippingAgentServiceCode[2]);
        WarehouseShipmentHeader.Modify(true);

        // [WHEN] Post whse. shipment
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Void value of Shipping Agent Service Code field is inherited from whse. shipment to Trasnsfer Header
        TransferHeader.Get(TransferHeader."No.");
        TransferHeader.TestField("Shipping Agent Service Code", ShippingAgentServiceCode[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatingItemNoOnTransferLineDoesNotSuggestChangingToAnotherItem()
    var
        Item: array[2] of Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        Desc: Code[10];
        Desc2: Code[10];
        i: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 291763] The program does not suggest changing Item No. on transfer line when there are several items with the same description.
        Initialize;

        // [GIVEN] Two items "I1", "I2" with the same Description and "Description 2".
        Desc := LibraryUtility.GenerateGUID;
        Desc2 := LibraryUtility.GenerateGUID;
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            Item[i].Description := Desc;
            Item[i]."Description 2" := Desc2;
            Item[i].Modify();
        end;

        // [GIVEN] Transfer order.
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationInTransit);
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);

        LibraryVariableStorage.Enqueue(AnotherItemWithSameDescTxt);

        // [WHEN] Open transfer order page and select item no. "I2" on a new transfer line.
        TransferOrder.OpenEdit;
        TransferOrder.GotoKey(TransferHeader."No.");
        TransferOrder.TransferLines."Item No.".SetValue(Item[2]."No.");
        TransferOrder.Close;

        // [THEN] No confirmation message is shown (the enqueued text is not handled).
        Assert.AreEqual(AnotherItemWithSameDescTxt, LibraryVariableStorage.DequeueText, 'The program must not suggest another item no.');

        // [THEN] The selected item no. is saved.
        // [THEN] Description and "Description 2" are updated on the transfer line.
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst;
        TransferLine.TestField("Item No.", Item[2]."No.");
        TransferLine.TestField(Description, Desc);
        TransferLine.TestField("Description 2", Desc2);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseReceiptsModalPageHandler,PostedPurchaseReceiptLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure GetReceiptLinesSunshine()
    var
        Location: array[3] of Record Location;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        i: Integer;
        PurchaseReceiptNo: array[3] of Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 278834] Function "Get Receipt Lines" creates transfer lines from selected purchase receipt lines
        Initialize;

        // [GIVEN] New location "LOC1"
        for i := 1 to 2 do
            LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[i]);
        LibraryWarehouse.CreateInTransitLocation(Location[3]);

        // [GIVEN] Post 3 purchase order receipts "PR1", "PR2", "PR3" on location "LOC1"
        for i := 1 to 3 do
            PurchaseReceiptNo[i] := CreatePostPurchOrder(Location[1].Code);
        // [GIVEN] purchase order "PR2" has line with item "ITEM1" and quantity "X"
        FindRandomReceiptLine(PurchaseReceiptNo[2], PurchRcptLine);

        // [GIVEN] Create transfer order from locaiton "LOC1" to "LOC2"
        LibraryWarehouse.CreateTransferHeader(TransferHeader, Location[1].Code, Location[2].Code, Location[3].Code);
        TransferOrder.OpenEdit;
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");

        // [WHEN] Run function "Get Receipt Lines"
        LibraryVariableStorage.Enqueue(PurchaseReceiptNo[2]); // Purchase Receipt to select
        LibraryVariableStorage.Enqueue(PurchRcptLine."No."); // Purchase Receipt Line to select
        TransferOrder.GetReceiptLines.Invoke;

        // [THEN] Opened list of purchase receipt headers filtered by location "LOC1"
        // [WHEN] Receipt "PR2" selected
        // [THEN] Opened list or purchase receipt lines filtered by "PR2" and location "LOC1"
        // [WHEN] Receipt line with item "ITEM1" selected
        // [THEN] Transfer line created with item "ITEM1" and quantity "X"
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindLast;
        TransferLine.TestField("Item No.", PurchRcptLine."No.");
        TransferLine.TestField(Quantity, PurchRcptLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostTransferOrderWhenLocationFromContainsSpecialChars()
    var
        Location: array[2] of Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
    begin
        // [SCENARIO 315589] Transfer Order is posted in case Transfer From Location Code contains special characters, that are used in filters (=<>.@&()"|).
        Initialize;

        // [GIVEN] Locations "L1" and "L2". "L1" Code field contains special characters, that are used in filters.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        Location[1].Rename('=A<.@ &)"|');

        // [GIVEN] Item "I" at Location "L1".
        CreateItemWithPositiveInventory(Item, Location[1].Code, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Transfer Order for Item "I" with Transfer From = "L1", Transfer To = "L2".
        CreateTransferOrderNoRoute(
          TransferHeader, TransferLine, Location[1].Code, Location[2].Code, Item."No.", '', LibraryRandom.RandIntInRange(10, 20));

        // [WHEN] Post Transfer Order.
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [THEN] Transfer Order was posted.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostTransferOrderWhenVariantContainsSpecialChars()
    var
        Location: array[2] of Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        VariantCode: Code[10];
    begin
        // [SCENARIO 315589] Transfer Order is posted in case Variant Code of an Item contains special characters, that are used in filters (=<>.@&()"|).
        Initialize;

        // [GIVEN] Locations "L1" and "L2".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // [GIVEN] Item "I" with Variant "V" at Location "L1". "V" contains special characters, that are used in filters.
        VariantCode := '=A>.C@ &D(';
        CreateItemWithVariantAndPositiveInventory(Item, Location[1].Code, VariantCode, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Transfer Order for Item "I" with Transfer From = "L1", Transfer To = "L2", Variant = "V".
        CreateTransferOrderNoRoute(
          TransferHeader, TransferLine, Location[1].Code, Location[2].Code, Item."No.", VariantCode, LibraryRandom.RandIntInRange(10, 20));

        // [WHEN] Post Transfer Order.
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [THEN] Transfer Order was posted.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDirectTransferDoesNotApplyPosIntermdEntryToExistingILE()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        QtyOnStock: Decimal;
        QtyTransferred: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Item Application]
        // [SCENARIO 321891] Intermediate item entry with blank location is not applied to existing negative item entries while posting direct transfer.
        Initialize;
        QtyOnStock := LibraryRandom.RandIntInRange(100, 200);
        QtyTransferred := LibraryRandom.RandInt(10);

        // [GIVEN] Locations "A" and "B".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Post positive inventory adjustment to location "A".
        // [GIVEN] Post negative inventory adjustment from blank location.
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", QtyOnStock, 0, LocationFrom.Code, '');
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", QtyOnStock, 0, '', '');

        // [GIVEN] Direct transfer order from "A" to "B".
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", QtyTransferred);

        // [WHEN] Post the direct transfer.
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] The transfer order is posted successfully.
        Item.SetRange("Location Filter", LocationTo.Code);
        Item.CalcFields("Net Change");
        Item.TestField("Net Change", QtyTransferred);

        // [THEN] The negative adjustment entry remains unapplied.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.SetRange("Location Code", '');
        ItemLedgerEntry.FindFirst;
        ItemLedgerEntry.TestField("Remaining Quantity", -QtyOnStock);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseReceiptsModalPageHandler,PostedPurchaseReceiptLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrderGetReceiptLinesUnitOfMeasureCodeAndVariant()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: array[3] of Record Location;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseReceiptNo: Code[20];
    begin
        // [FEATURE] [Get Receipt Lines] [Unit of Measure Code] [Item Variant]
        // [SCENARIO 328925] "Get Receipt Lines" function copies correct Unit Of Measure Code from the Receipt to Transfer Order Line
        // [SCENARIO 328925] "Get Receipt Lines" function copies correct Variant Code from the Receipt to Transfer Order Line
        Initialize;

        // [GIVEN] Item "ITEM1" with Unit of Measure Code "UOM1" and Item Variant "ITEM1V1"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] New locations "LOC1", "LOC2"
        LibraryWarehouse.CreateTransferLocations(Location[1], Location[2], Location[3]);

        // [GIVEN] Post purchase order receipt "PR1" on location "LOC1" with line for "ITEM1","UOM1","ITEM1V1"
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandIntInRange(5, 10), Location[1].Code, 0D);
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Validate("Variant Code", ItemVariant.Code);
        PurchaseLine.Modify(true);
        PurchaseReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchRcptLine.SetRange("Document No.", PurchaseReceiptNo);
        PurchRcptLine.FindFirst;

        // [GIVEN] Create transfer order from location "LOC1" to "LOC2"
        LibraryWarehouse.CreateTransferHeader(TransferHeader, Location[1].Code, Location[2].Code, Location[3].Code);

        // [WHEN] Run function "Get Receipt Lines" with Receipt "PR1" line with item "ITEM1" selected
        LibraryVariableStorage.Enqueue(PurchaseReceiptNo); // Purchase Receipt to select
        LibraryVariableStorage.Enqueue(PurchRcptLine."No."); // Purchase Receipt Line to select
        TransferHeader.GetReceiptLines;

        // [THEN] Transfer line created with item "ITEM1", Unit Of Measure Code = "UOM1", Variant Code = "ITEM1V1"
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Item No.", PurchRcptLine."No.");
        TransferLine.FindFirst;
        TransferLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
        TransferLine.TestField("Unit of Measure", PurchRcptLine."Unit of Measure");
        TransferLine.TestField("Variant Code", ItemVariant.Code);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler,PostedTransferReceiptLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure AssignPostedTransferReceiptLinesBlankItemNoToItemChargePurchase()
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Transfer Receipt] [Item Charge] [Purchase]
        // [SCENARIO 335337] Transfer Receipt Lines with blank Item No. and zero Quantity can't be assigned to Item Charges
        Initialize;

        // [GIVEN] Transfer Receipt "TR1"
        TransferReceiptHeader.Init();
        TransferReceiptHeader."No." := LibraryUtility.GenerateRandomCode(
            TransferReceiptHeader.FieldNo("No."), DATABASE::"Transfer Receipt Header");
        TransferReceiptHeader.Insert();
        LibraryVariableStorage.Enqueue(TransferReceiptHeader."No.");

        // [GIVEN] Transfer Receipt Line "TR1",10000 for Item "ITEM1" with Quantity 10
        MockTransferReceiptLine(
          TransferReceiptLine, TransferReceiptHeader."No.", LibraryUtility.GenerateGUID, '', LibraryRandom.RandDec(10, 0));
        LibraryVariableStorage.Enqueue(TransferReceiptLine."Item No.");

        // [GIVEN] Transfer Receipt Line "TR1",20000 with blank Item No., Description = "Description 1" (Comment line)
        MockTransferReceiptLine(
          TransferReceiptLine, TransferReceiptHeader."No.", '', LibraryUtility.GenerateGUID, LibraryRandom.RandDec(10, 0));

        // [GIVEN] Transfer Receipt Line "TR1",30000 for Item "ITEM2" with Quantity 0
        MockTransferReceiptLine(TransferReceiptLine, TransferReceiptHeader."No.", LibraryUtility.GenerateGUID, '', 0);

        // [GIVEN] Purchase Order with Item Charge Line "PO01",10000
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo, LibraryRandom.RandDec(100, 0));

        // [WHEN] Invoke "Get Transfer Receipt Lines" action on the "Item Charge Assignment (Purch)" page for the Purchase Line "PO01",10000
        PurchaseLine.ShowItemChargeAssgnt();

        // [THEN] Only Transfer Receipt Line 10000 shown for the Transfer Receipt "TR1"
        // Verification done in PostedTransferReceiptLinesModalPageHandler

        LibraryVariableStorage.AssertEmpty;
    end;

    [HandlerFunctions('PostedTransferShipmentLinesHandler')]
    [Test]
    procedure TransferOrderQtyShippedDrillDown()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [UI] [Transfer Order] 
        // [SCENARIO 335337] "Quantity Shipped" DrillDown filters lines by "Line No."
        Initialize;

        // [GIVEN] Partly shipped Transfer Order "T" from "L1" to Location "L2".
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);

        // [WHEN] "Quantity Shipped" DrillDown is being activated
        TransferOrder.OpenEdit();
        TransferOrder.Filter.SetFilter("No.", TransferHeader."No.");
        TransferOrder.TransferLines."Quantity Shipped".Drilldown();

        // [THEN] Opened page has filter by "Line No."
        Assert.AreEqual(Format(TransferLine."Line No."), LibraryVariableStorage.DequeueText(), 'Invalid filter');
    end;

    [HandlerFunctions('PostedTransferReceiptLinesHandler')]
    [Test]
    procedure TransferOrderQtyReceivedDrillDown()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [UI] [Transfer Order] 
        // [SCENARIO 335337] "Quantity Received" DrillDown filters lines by "Line No."
        Initialize;

        // [GIVEN] Partly Received Transfer Order "T" from "L1" to Location "L2".
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [WHEN] "Quantity Received" DrillDown is being activated
        TransferOrder.OpenEdit();
        TransferOrder.Filter.SetFilter("No.", TransferHeader."No.");
        TransferOrder.TransferLines."Quantity Received".Drilldown();

        // [THEN] Opened page has filter by "Line No."
        Assert.AreEqual(Format(TransferLine."Line No."), LibraryVariableStorage.DequeueText(), 'Invalid filter');
    end;

    [HandlerFunctions('PostedTransferShipmentLinesGetDescriptionHandler')]
    [Test]
    procedure TransferOrderQtyShippedDrillDownSecondLine()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        PostedTransferShipmentLines: TestPage "Posted Transfer Shipment Lines";
        Text: Text;
        Qty: Decimal;
    begin
        // [FEATURE] [UI] [Transfer Order] 
        // [SCENARIO 335337] "Quantity Shipped" DrillDown opens proper line when tranfer order shipped line by line
        Initialize;

        // [GIVEN] Transfer Order "T" from "L1" to Location "L2".
        CreateTransferOrderHeader(TransferHeader);
        Qty := LibraryRandom.RandIntInRange(100, 200);
        CreateItemWithPositiveInventory(Item, TransferHeader."Transfer-from Code", Qty * 2);

        // [GIVEN] Transfer order line for item "I" with "Qty to Ship" = 0 and Description = "D1"
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
        TransferLine.Validate("Qty. to Ship", 0);
        TransferLine.Description := CopyStr(Format(CreateGuid()), 1, MaxStrLen(TransferLine.Description));
        TransferLine.Modify();

        // [GIVEN] Transfer order line for item "I" with "Qty to Ship" = 10 and Description = "D2"
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
        TransferLine.Description := CopyStr(Format(CreateGuid()), 1, MaxStrLen(TransferLine.Description));
        TransferLine.Modify();

        // [GIVEN] Ship tranfer order 
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] "Quantity Shipped" DrillDown is being activated for second line
        TransferOrder.OpenEdit();
        TransferOrder.Filter.SetFilter("No.", TransferHeader."No.");
        TransferOrder.TransferLines.Filter.SetFilter(Description, TransferLine.Description);
        TransferOrder.TransferLines."Quantity Shipped".Drilldown();

        // [THEN] Opened page has Description "D2"
        Assert.AreEqual(TransferLine.Description, LibraryVariableStorage.DequeueText(), 'Invalid transfer shipment line');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Transfers");
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Transfers");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateInventoryPostingSetup();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Transfers");
    end;

    local procedure PlanningCombineTransfers(var LocationCode: array[3] of Code[10]; Combine: Boolean)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize;
        CreateTransferRouteSetup(LocationCode);
        MockReqTransferOrderLines(RequisitionLine, LocationCode);
        RunRequisitionCarryOutReport(RequisitionLine, Combine);
    end;

    local procedure UpdateSalesReceivablesSetup()
    begin
        LibrarySales.SetCreditWarningsToNoWarnings;
        LibrarySales.SetStockoutWarning(false);
    end;

    local procedure PrepareSimpleTransferOrderWithTwoLines(var TransferHeader: Record "Transfer Header"; var TransferLine: array[2] of Record "Transfer Line")
    var
        Location: array[3] of Record Location;
        i: Integer;
    begin
        for i := 1 to 2 do
            LibraryWarehouse.CreateLocation(Location[i]);
        LibraryWarehouse.CreateInTransitLocation(Location[3]);

        LibraryWarehouse.CreateTransferHeader(TransferHeader, Location[1].Code, Location[2].Code, Location[3].Code);
        for i := 1 to ArrayLen(TransferLine) do
            LibraryWarehouse.CreateTransferLine(
              TransferHeader, TransferLine[i], LibraryInventory.CreateItemNo, LibraryRandom.RandIntInRange(10, 20));
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        // Random values used are not important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method", LibraryRandom.RandDec(50, 2) + LibraryRandom.RandDec(10, 2),
          Item."Reordering Policy"::Order, Item."Flushing Method", '', '');
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);
    end;

    local procedure CreateLocations(var LocationFromCode: Code[10]; var LocationToCode: Code[10])
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
    begin
        LocationFromCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LocationToCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
    end;

    local procedure CreateUpdateLocations()
    var
        Location: Record Location;
        HandlingTime: DateFormula;
        HandlingTime2: DateFormula;
        k: Integer;
    begin
        // Values Used are important for Test.
        Evaluate(HandlingTime, '<1D>');
        Evaluate(HandlingTime2, '<0D>');

        for k := 1 to 5 do begin
            LibraryWarehouse.CreateLocation(Location);
            LocationCode[k] := Location.Code;
        end;

        // Update Locations.
        for k := 2 to 4 do
            UpdateLocation(LocationCode[k], false, HandlingTime2, HandlingTime2);

        UpdateLocation(LocationCode[1], false, HandlingTime, HandlingTime2);
        UpdateLocation(LocationCode[5], true, HandlingTime2, HandlingTime2);
    end;

    local procedure CreateUpdateStockKeepUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; ItemNo: array[4] of Code[20])
    var
        Item: Record Item;
        SKUCreationMethod: Option Location,Variant,"Location & Variant";
    begin
        Item.SetRange("No.", ItemNo[1], ItemNo[4]);
        Item.SetRange("Location Filter", LocationCode[1], LocationCode[4]);
        LibraryInventory.CreateStockKeepingUnit(Item, SKUCreationMethod::Location, false, false);

        // Update Replenishment System in Stock Keeping Unit.
        UpdateStockKeepingUnit(LocationCode[1], ItemNo[4], StockkeepingUnit."Replenishment System"::"Prod. Order", '', '');
        UpdateStockKeepingUnit(LocationCode[4], ItemNo[4], StockkeepingUnit."Replenishment System"::Purchase, '', '');
        UpdateStockKeepingUnit(LocationCode[1], ItemNo[3], StockkeepingUnit."Replenishment System"::Transfer, '', LocationCode[2]);
        UpdateStockKeepingUnit(LocationCode[2], ItemNo[3], StockkeepingUnit."Replenishment System"::"Prod. Order", '', '');
        UpdateStockKeepingUnit(LocationCode[3], ItemNo[3], StockkeepingUnit."Replenishment System"::Purchase, '', '');
        UpdateStockKeepingUnit(LocationCode[4], ItemNo[3], StockkeepingUnit."Replenishment System"::Purchase, '', '');
        UpdateStockKeepingUnit(LocationCode[1], ItemNo[2], StockkeepingUnit."Replenishment System"::Transfer, '', LocationCode[2]);
        UpdateStockKeepingUnit(LocationCode[2], ItemNo[2], StockkeepingUnit."Replenishment System"::Transfer, '', LocationCode[4]);
        UpdateStockKeepingUnit(LocationCode[3], ItemNo[2], StockkeepingUnit."Replenishment System"::Purchase, '', '');
        UpdateStockKeepingUnit(
          LocationCode[4], ItemNo[2], StockkeepingUnit."Replenishment System"::Purchase, LibraryPurchase.CreateVendorNo, '');
        UpdateStockKeepingUnit(LocationCode[1], ItemNo[1], StockkeepingUnit."Replenishment System"::Purchase, '', '');
        UpdateStockKeepingUnit(LocationCode[2], ItemNo[1], StockkeepingUnit."Replenishment System"::Purchase, '', '');
        UpdateStockKeepingUnit(LocationCode[3], ItemNo[1], StockkeepingUnit."Replenishment System"::Purchase, '', '');
        UpdateStockKeepingUnit(
          LocationCode[4], ItemNo[1], StockkeepingUnit."Replenishment System"::Purchase, LibraryPurchase.CreateVendorNo, '');
    end;

    local procedure CreateProdBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; ItemNo2: Code[20]; BaseUnitofMeasure: Code[10]; MultipleBOMLine: Boolean)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitofMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, 1);
        if MultipleBOMLine then
            LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo2, 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateShippingAgentCodeAndService(var ShippingAgentCode: Code[10]; var ShippingAgentServiceCode: Code[10])
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(ShippingTime, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
        ShippingAgentCode := ShippingAgent.Code;
        ShippingAgentServiceCode := ShippingAgentServices.Code;
    end;

    local procedure CreateShippingAgentServices(var ShippingAgent: Record "Shipping Agent"; var ShippingAgentServicesCode: array[6] of Code[10])
    var
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
        j: Integer;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);

        for j := 1 to 6 do begin
            Evaluate(ShippingTime, '<' + Format(j) + 'D>');
            LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
            ShippingAgentServicesCode[j] := ShippingAgentServices.Code;
        end;
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        // Random values used are not important for test.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Order with One Item Line. Random values used are not important for test.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateTransferRoutes()
    var
        TransferRoute: Record "Transfer Route";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServicesCode: array[6] of Code[10];
        i: Integer;
        j: Integer;
        k: Integer;
    begin
        CreateShippingAgentServices(ShippingAgent, ShippingAgentServicesCode);

        // Transfer Route for LocationCode
        k := 1;
        for i := 1 to 4 do
            for j := i + 1 to 4 do begin
                LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationCode[i], LocationCode[j]);
                UpdateTransferRoutes(TransferRoute, ShippingAgentServicesCode[k], ShippingAgent.Code);
                LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationCode[j], LocationCode[i]);
                UpdateTransferRoutes(TransferRoute, ShippingAgentServicesCode[k], ShippingAgent.Code);
                k := k + 1;
            end;
    end;

    local procedure CreateReqLine(var RequisitionLine: Record "Requisition Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::Planning);
        RequisitionWkshName.FindFirst;
        ClearReqWkshBatch(RequisitionWkshName);

        RequisitionLine.Init();
        RequisitionLine.Validate("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.Validate("Journal Batch Name", RequisitionWkshName.Name);
    end;

    local procedure CreateAndPostItemJrnl(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJrnl(ItemJournalLine, EntryType, ItemNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJnlWithCostLocationVariant(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Qty: Decimal; Cost: Decimal; LocationCode: Code[10]; VariantCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJrnl(ItemJournalLine, EntryType, ItemNo, Qty);
        with ItemJournalLine do begin
            Validate("Location Code", LocationCode);
            Validate("Variant Code", VariantCode);
            Validate("Unit Cost", Cost);
            Modify(true);
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostWhseShipmentFromTransferOrder(TransferHeader: Record "Transfer Header"; QtyToShip: Decimal)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if TransferHeader.Status = TransferHeader.Status::Open then
            LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Transfer Line");
        WarehouseShipmentLine.SetRange("Source No.", TransferHeader."No.");
        WarehouseShipmentLine.FindFirst;
        WarehouseShipmentLine.Validate("Qty. to Ship", QtyToShip);
        WarehouseShipmentLine.Modify(true);

        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure CreateAndPostWhseReceiptFromTransferOrder(TransferHeader: Record "Transfer Header"; QtyToReceive: Decimal)
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);

        FilterWhseReceiptLine(WarehouseReceiptLine, DATABASE::"Transfer Line", TransferHeader."No.");
        WarehouseReceiptLine.FindFirst;
        WarehouseReceiptLine.Validate("Qty. to Receive", QtyToReceive);
        WarehouseReceiptLine.Modify(true);

        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreatePostPurchOrder(LocationCode: Code[10]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify();

        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
              LibraryInventory.CreateItemNo, LibraryRandom.RandIntInRange(5, 10));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchRcptHeader.FindLast;
        exit(PurchRcptHeader."No.");
    end;

    local procedure CreateItemJrnl(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Qty);
    end;

    local procedure CreateItemWithPositiveInventory(var Item: Record Item; LocationCode: Code[10]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty, LibraryRandom.RandIntInRange(10, 20), LocationCode, '');
    end;

    local procedure CreateItemWithVariantAndPositiveInventory(var Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemVariant: Record "Item Variant";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateVariant(ItemVariant, Item);
        ItemVariant.Rename(Item."No.", VariantCode);
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty, LibraryRandom.RandIntInRange(10, 20), LocationCode, VariantCode);
    end;

    local procedure CreateTransferOrderAndInitializeNewTransferLine(var TransferOrder: TestPage "Transfer Order"; ShippingAgentCode: Code[10])
    var
        TransferHeader: Record "Transfer Header";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
    begin
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        TransferHeader.Validate("Shipping Agent Code", ShippingAgentCode);
        TransferHeader.Modify(true);

        TransferOrder.OpenEdit;
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");
        TransferOrder.TransferLines.New;
        TransferOrder.TransferLines."Item No.".SetValue(LibraryInventory.CreateItemNo);
    end;

    local procedure CreateTransferOrder(var TransferLine: Record "Transfer Line"; TransferfromCode: Code[10]; TransfertoCode: Code[10]; ItemNo: Code[20]; ReceiptDate: Date; Quantity: Decimal): Code[20]
    var
        TransferHeader: Record "Transfer Header";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, TransferfromCode, TransfertoCode, LocationCode[5]);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        TransferLine.Validate("Receipt Date", ReceiptDate);
        TransferLine.Validate("Planning Flexibility", TransferLine."Planning Flexibility"::None);
        TransferLine.Modify(true);
        exit(TransferHeader."No.");
    end;

    local procedure CreateTransferOrderNoRoute(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; Qty: Decimal)
    var
        InTransitLocation: Record Location;
    begin
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
        TransferLine.Validate("Variant Code", VariantCode);
        TransferLine.Modify(true);
    end;

    local procedure CreateTransferRouteSetup(var LocationCode: array[3] of Code[10])
    var
        TransferRoute: Record "Transfer Route";
        Location: Record Location;
        i: Integer;
    begin
        for i := 1 to ArrayLen(LocationCode) do begin
            LibraryWarehouse.CreateLocation(Location);
            LocationCode[i] := Location.Code;
        end;
        LibraryWarehouse.CreateInTransitLocation(Location);

        with TransferRoute do begin
            Init;
            Validate("Transfer-from Code", LocationCode[1]);
            Validate("Transfer-to Code", LocationCode[2]);
            Validate("In-Transit Code", Location.Code);
            Insert;
            Validate("Transfer-to Code", LocationCode[3]);
            Insert;
        end;
    end;

    local procedure CreateTransferSetup(var SalesHeader: Record "Sales Header"; var ItemNo: array[4] of Code[20]; CreateSalesOrderExist: Boolean)
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        i: Integer;
    begin
        // Create and Update Five Location.
        // Create Items and  Production BOMs.Attach BOM to Item.
        CreateUpdateLocations;
        for i := 1 to 4 do begin
            CreateItem(Item);
            ItemNo[i] := Item."No.";
        end;

        CreateProdBOM(ProductionBOMHeader, ItemNo[1], '', Item."Base Unit of Measure", false);
        UpdateItem(ItemNo[3], ProductionBOMHeader."No.");
        CreateProdBOM(ProductionBOMHeader, ItemNo[2], ItemNo[3], Item."Base Unit of Measure", true);
        UpdateItem(ItemNo[4], ProductionBOMHeader."No.");

        // Create Transfer Routes.
        // Create Stock keeping Unit for each Item at each Location.
        CreateTransferRoutes;
        CreateUpdateStockKeepUnit(StockkeepingUnit, ItemNo);

        // Create and Update Sales Order.
        if CreateSalesOrderExist then begin
            CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandInt(10));
            UpdateSalesLine(SalesHeader, LocationCode[1]);
        end;
    end;

    local procedure CreatePartlyShipTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    var
        LocationFromCode: Code[10];
        LocationToCode: Code[10];
    begin
        CreateLocations(LocationFromCode, LocationToCode);
        CreateAndPostPartiallyShippedTransferOrder(TransferHeader, TransferLine, LocationFromCode, LocationToCode, true);
    end;

    local procedure CreateShippingAgentServiceCodeWith1YShippingTime(var ShippingAgentCode: Code[10]; var ShippingAgentServiceCode: Code[10])
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
    begin
        Evaluate(ShippingTime, '<+1Y>');
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
        ShippingAgentCode := ShippingAgentServices."Shipping Agent Code";
        ShippingAgentServiceCode := ShippingAgentServices.Code;
    end;

    local procedure CreateTwoPartlyShipTransferOrders(var TransferHeader: array[2] of Record "Transfer Header"; Ship: Boolean)
    var
        TransferLine: Record "Transfer Line";
        LocationFromCode: Code[10];
        LocationToCode: Code[10];
    begin
        CreateLocations(LocationFromCode, LocationToCode);
        CreateAndPostPartiallyShippedTransferOrder(TransferHeader[1], TransferLine, LocationFromCode, LocationToCode, Ship);
        CreateAndPostPartiallyShippedTransferOrder(TransferHeader[2], TransferLine, LocationFromCode, LocationToCode, Ship);
    end;

    local procedure CreateAndPostPartiallyShippedTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; LocationFromCode: Code[10]; LocationToCode: Code[10]; Ship: Boolean)
    var
        Item: Record Item;
        Qty: Decimal;
    begin
        Qty := LibraryRandom.RandIntInRange(100, 200);
        CreateItemWithPositiveInventory(Item, LocationFromCode, Qty * 2);

        CreateTransferOrderNoRoute(TransferHeader, TransferLine, LocationFromCode, LocationToCode, Item."No.", '', Qty * 2);
        UpdatePartialQuantityToShip(TransferLine, TransferLine.Quantity * LibraryUtility.GenerateRandomFraction);

        LibraryWarehouse.PostTransferOrder(TransferHeader, Ship, false);
    end;

    local procedure CreateTransferOrderHeader(var TransferHeader: Record "Transfer Header")
    var
        InTransitLocation: Record Location;
        LocationFromCode: Code[10];
        LocationToCode: Code[10];
    begin
        CreateLocations(LocationFromCode, LocationToCode);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFromCode, LocationToCode, InTransitLocation.Code);
    end;

    local procedure CreateGlobal1DimensionValue(var DimensionValue: Record "Dimension Value"): Code[20]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
        exit(DimensionValue.Code);
    end;

    local procedure CarryOutActionMsgPlanSetup(var RequisitionLine: Record "Requisition Line"; ItemNo: array[4] of Code[20])
    begin
        // Update Vendor No in Requisition Worksheet and Carry Out Action Message.
        GenerateRequisitionWorksheet(RequisitionLine, ItemNo);
        RequisitionCarryOutActMessage(ItemNo);
    end;

    local procedure FilterWhseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceType: Integer; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Type", SourceType);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
    end;

    local procedure MockReqTransferOrderLines(var RequisitionLine: Record "Requisition Line"; LocationCode: array[3] of Code[10])
    var
        Item: Record Item;
        i: Integer;
    begin
        CreateReqLine(RequisitionLine);
        LibraryInventory.CreateItem(Item);

        with RequisitionLine do begin
            "Accept Action Message" := true;
            "Action Message" := "Action Message"::New;
            "Transfer-from Code" := LocationCode[1];
            Type := Type::Item;
            "No." := Item."No.";
            "Ref. Order Type" := "Ref. Order Type"::Transfer;
            "Transfer Shipment Date" := WorkDate;
            "Due Date" := WorkDate;
            Quantity := LibraryRandom.RandDec(100, 2);

            for i := 1 to 4 do begin
                "Line No." += 10000;
                "Location Code" := LocationCode[3 - i mod 2]; // 2,3,2,3
                Insert;
            end;
        end;
    end;

    local procedure MockTransferOrder(var TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
    begin
        with TransferHeader do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Transfer Header");
            "Transfer-from Code" := LibraryUtility.GenerateGUID;
            "Transfer-to Code" := LibraryUtility.GenerateGUID;
            Status := Status::Open;
            "External Document No." := LibraryUtility.GenerateGUID;
            "Shipment Method Code" := LibraryUtility.GenerateGUID;
            "Shipping Agent Code" := LibraryUtility.GenerateGUID;
            "Shipping Advice" := "Shipping Advice"::Complete;
            "Shipment Date" := LibraryRandom.RandDate(10);
            "Receipt Date" := LibraryRandom.RandDateFromInRange(WorkDate, 11, 20);
            Insert;
        end;

        with TransferLine do begin
            Init;
            "Document No." := TransferHeader."No.";
            "Transfer-from Code" := TransferHeader."Transfer-from Code";
            "Transfer-to Code" := TransferHeader."Transfer-to Code";
            Quantity := LibraryRandom.RandInt(10);
            "Quantity Shipped" := LibraryRandom.RandInt(10);
            "Quantity Received" := LibraryRandom.RandInt(10);
            "Completely Shipped" := ("Quantity Shipped" = Quantity);
            "Completely Received" := ("Quantity Received" = Quantity);
            Insert;
        end;
    end;

    local procedure MockWhseRequest(RequestType: Option; LocCode: Code[10]; SourceNo: Code[20])
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        with WarehouseRequest do begin
            Init;
            Type := RequestType;
            "Location Code" := LocCode;
            "Source Type" := DATABASE::"Transfer Line";
            "Source Subtype" := Abs(RequestType - 1);
            "Source No." := SourceNo;
            "Shipment Date" := WorkDate;
            "Expected Receipt Date" := WorkDate;
            Insert;
        end;
    end;

    local procedure FilterWhseRequest(var WarehouseRequest: Record "Warehouse Request"; RequestType: Option; LocCode: Code[10]; SourceSubtype: Option; SourceNo: Code[20])
    begin
        with WarehouseRequest do begin
            SetRange(Type, RequestType);
            SetRange("Location Code", LocCode);
            SetRange("Source Type", DATABASE::"Transfer Line");
            SetRange("Source Subtype", SourceSubtype);
            SetRange("Source No.", SourceNo);
        end;
    end;

    local procedure MockTransferReceiptLine(var TransferReceiptLine: Record "Transfer Receipt Line"; DocumentNo: Code[20]; ItemNo: Code[20]; Desc: Text[100]; Qty: Decimal)
    begin
        with TransferReceiptLine do begin
            Init;
            "Document No." := DocumentNo;
            "Line No." := LibraryUtility.GetNewRecNo(TransferReceiptLine, FieldNo("Line No."));
            "Item No." := ItemNo;
            Description := Desc;
            Quantity := Qty;
            Insert;
        end;
    end;

    local procedure CalculateNetChangePlan(var RequisitionLine: Record "Requisition Line"; StartDate: Date; ItemNo: array[4] of Code[20])
    var
        Item: Record Item;
        CalculatePlanPlanWksh: Report "Calculate Plan - Plan. Wksh.";
    begin
        Item.SetRange("No.", ItemNo[1], ItemNo[4]);
        CalculatePlanPlanWksh.SetTemplAndWorksheet(
          RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", true);
        CalculatePlanPlanWksh.SetTableView(Item);
        CalculatePlanPlanWksh.InitializeRequest(StartDate, CalcDate('<30D>', StartDate), false);
        CalculatePlanPlanWksh.UseRequestPage(false);
        CalculatePlanPlanWksh.RunModal;
        if not RequisitionLine.FindFirst then
            RequisitionLine.SetUpNewLine(RequisitionLine);
    end;

    local procedure GenerateRequisitionWorksheet(var RequisitionLine: Record "Requisition Line"; ItemNo: array[4] of Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
        NewProdOrderChoice: Option " ",Planned,"Firm Planned","Firm Planned & Print","Copy to Req. Wksh";
        NewPurchOrderChoice: Option " ","Make Purch. Orders","Make Purch. Orders & Print","Copy to Req. Wksh";
        NewTransOrderChoice: Option " ","Make Trans. Orders","Make Trans. Orders & Print","Copy to Req. Wksh";
        NewAsmOrderChioce: Option " ","Make Assembly Orders","Make Assembly Orders & Print";
    begin
        // Update Accept Action Message in Planning Worksheet.
        UpdatePlanningWorkSheet(RequisitionLine, ItemNo);

        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::"Req.");
        RequisitionWkshName.FindFirst;
        CarryOutActionMsgPlan.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgPlan.InitializeRequest2(
          NewProdOrderChoice::Planned,
          NewPurchOrderChoice::"Copy to Req. Wksh",
          NewTransOrderChoice::"Copy to Req. Wksh",
          NewAsmOrderChioce::" ",
          RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, RequisitionWkshName."Worksheet Template Name",
          RequisitionWkshName.Name);
        CarryOutActionMsgPlan.SetTableView(RequisitionLine);
        CarryOutActionMsgPlan.UseRequestPage(false);
        CarryOutActionMsgPlan.Run;
    end;

    local procedure FindRandomReceiptLine(PurchRcptNo: Code[20]; var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        PurchRcptLine.SetRange("Document No.", PurchRcptNo);
        PurchRcptLine.Next(LibraryRandom.RandInt(PurchRcptLine.Count));
    end;

    local procedure UpdateLocation("Code": Code[10]; UseAsInTransit: Boolean; OutboundWhseHandlingTime: DateFormula; InboundWhseHandlingTime: DateFormula)
    var
        Location: Record Location;
    begin
        Location.Get(Code);
        Location.Validate("Use As In-Transit", UseAsInTransit);
        Location.Validate("Outbound Whse. Handling Time", OutboundWhseHandlingTime);
        Location.Validate("Inbound Whse. Handling Time", InboundWhseHandlingTime);
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    local procedure UpdateItem(ItemNo: Code[20]; ProductionBOMNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateTransferRoutes(var TransferRoute: Record "Transfer Route"; ShippingAgentServiceCode: Code[10]; ShippingAgentCode: Code[10])
    begin
        TransferRoute.Validate("In-Transit Code", LocationCode[5]);
        TransferRoute.Validate("Shipping Agent Code", ShippingAgentCode);
        TransferRoute.Validate("Shipping Agent Service Code", ShippingAgentServiceCode);
        TransferRoute.Modify(true);
    end;

    local procedure UpdateStockKeepingUnit(LocationCode: Code[10]; ItemNo: Code[20]; ReplenishmentSystem: Enum "Replenishment System"; VendorNo: Code[20]; TransferfromCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        FindStockKeepingUnit(StockkeepingUnit, LocationCode, ItemNo);
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Validate("Transfer-from Code", TransferfromCode);
        StockkeepingUnit.Validate("Vendor No.", VendorNo);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateReorderingPolicy(LocationCode: Code[10]; ItemNo: Code[20])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        FindStockKeepingUnit(StockkeepingUnit, LocationCode, ItemNo);
        StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::"Lot-for-Lot");
        StockkeepingUnit.Validate("Include Inventory", true);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateSalesLine(SalesHeader: Record "Sales Header"; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet;
        repeat
            SalesLine.Validate("Location Code", LocationCode);
            SalesLine.Modify(true);
        until SalesLine.Next = 0;
    end;

    local procedure UpdatePurchaseLine(PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet;
        repeat
            PurchaseLine.Validate("Location Code", LocationCode);
            PurchaseLine.Validate("Expected Receipt Date", CalcDate('<CM>', PurchaseHeader."Order Date"));
            PurchaseLine.Modify(true);
        until PurchaseLine.Next = 0;
    end;

    local procedure UpdatePlanningWorkSheet(var RequisitionLine: Record "Requisition Line"; ItemNo: array[4] of Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo[1], ItemNo[4]);
        RequisitionLine.FindSet;
        repeat
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next = 0;
    end;

    local procedure UpdatePartialQuantityToShip(var TransferLine: Record "Transfer Line"; QtyToShip: Decimal)
    begin
        TransferLine.Validate("Qty. to Ship", QtyToShip);
        TransferLine.Modify(true);
    end;

    local procedure FindStockKeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        StockkeepingUnit.SetRange("Location Code", LocationCode);
        StockkeepingUnit.SetRange("Item No.", ItemNo);
        StockkeepingUnit.FindFirst;
    end;

    local procedure RequisitionCarryOutActMessage(ItemNo: array[4] of Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo[1], ItemNo[4]);
        RequisitionLine.FindSet;
        repeat
            RequisitionLine.Validate("Vendor No.", Vendor."No.");
            RequisitionLine.Modify(true);
        until RequisitionLine.Next = 0;
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
    end;

    local procedure RunRequisitionCarryOutReport(RequisitionLine: Record "Requisition Line"; CombineTransfers: Boolean)
    var
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
    begin
        Commit();
        LibraryVariableStorage.Enqueue(CombineTransfers);
        CarryOutActionMsgPlan.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgPlan.UseRequestPage(true);
        CarryOutActionMsgPlan.RunModal;
    end;

    local procedure ClearReqWkshBatch(RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.DeleteAll();
    end;

    local procedure FindLastILENo(ItemNo: Code[20]): Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgEntry do begin
            SetRange("Item No.", ItemNo);
            FindLast;
            exit("Entry No.");
        end;
    end;

    local procedure VerifyNumberOfRequisitionLine(ItemNo: array[4] of Code[20]; NoOfLines: Integer)
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::Planning);
        RequisitionWkshName.FindFirst;

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("No.", ItemNo[1], ItemNo[4]);
        Assert.AreEqual(NoOfLines, RequisitionLine.Count, ErrNoOfLinesMustBeEqual);
    end;

    local procedure VerifyItemNoExistInReqLine(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst;
    end;

    local procedure VerifyReqLineActMessageCancel(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Action Message", RequisitionLine."Action Message"::Cancel);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst;
    end;

    local procedure VerifyTransferOrderCount(LocationFromCode: Code[10]; LocationToCode: Code[10]; ExpectedCount: Integer)
    var
        TransferHeader: Record "Transfer Header";
    begin
        with TransferHeader do begin
            SetRange("Transfer-from Code", LocationFromCode);
            SetRange("Transfer-to Code", LocationToCode);
            Assert.AreEqual(ExpectedCount, Count, TransferOrderCountErr);
        end;
    end;

    local procedure VerifyTransferReceiptDate(var TransferOrder: TestPage "Transfer Order")
    var
        ReceiptDateOnHeader: Date;
        ReceiptDateOnLine: Date;
    begin
        Evaluate(ReceiptDateOnHeader, TransferOrder."Receipt Date".Value);
        Evaluate(ReceiptDateOnLine, TransferOrder.TransferLines."Receipt Date".Value);
        Assert.AreEqual(ReceiptDateOnHeader, ReceiptDateOnLine, TransferOrderSubpageNotUpdatedErr);
    end;

    local procedure VerifyItemApplicationEntry(ItemNo: Code[20]; AppliedToEntryNo: Integer)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        with ItemApplicationEntry do begin
            SetRange("Item Ledger Entry No.", FindLastILENo(ItemNo));
            FindLast;
            SetRange("Item Ledger Entry No.", "Outbound Item Entry No.");
            FindLast;
            TestField("Inbound Item Entry No.", AppliedToEntryNo);
            TestField("Cost Application", true);
        end;
    end;

    local procedure VerifyItemApplicationEntryCost(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; ExpectedCost: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgerEntry do begin
            SetRange("Item No.", ItemNo);
            SetRange("Entry Type", EntryType);
            FindSet;
            repeat
                CalcFields("Cost Amount (Actual)");
                TestField("Cost Amount (Actual)", ExpectedCost * Quantity);
            until Next = 0;
        end;
    end;

    local procedure VerifyDimensionOnDimSet(DimSetID: Integer; DimensionValue: Record "Dimension Value")
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.GetDimensionSet(TempDimensionSetEntry, DimSetID);
        TempDimensionSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        TempDimensionSetEntry.FindFirst;
        TempDimensionSetEntry.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    local procedure VerifyWhseRequest(WarehouseRequest: Record "Warehouse Request"; TransferHeader: Record "Transfer Header"; SourceDoc: Option; IsCompletelyHandled: Boolean; ShipmentDate: Date; ReceiptDate: Date)
    begin
        with WarehouseRequest do begin
            TestField("Source Document", SourceDoc);
            TestField("Document Status", TransferHeader.Status);
            TestField("External Document No.", TransferHeader."External Document No.");
            TestField("Completely Handled", IsCompletelyHandled);
            TestField("Shipment Method Code", TransferHeader."Shipment Method Code");
            TestField("Shipping Agent Code", TransferHeader."Shipping Agent Code");
            TestField("Destination Type", "Destination Type"::Location);
            TestField("Destination No.", "Location Code");
            TestField("Shipment Date", ShipmentDate);
            TestField("Expected Receipt Date", ReceiptDate);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgPlanHandler(var CarryOutActionMsgPlan: TestRequestPage "Carry Out Action Msg. - Plan.")
    var
        Variant: Variant;
        TransOrderChoice: Option " ","Make Trans. Orders","Make Trans. Orders & Print","Copy to Req. Wksh";
    begin
        LibraryVariableStorage.Dequeue(Variant);
        CarryOutActionMsgPlan.TransOrderChoice.SetValue(TransOrderChoice::"Make Trans. Orders");
        CarryOutActionMsgPlan.CombineTransferOrders.SetValue(Variant);
        CarryOutActionMsgPlan.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerForTransferHeaderDimUpdate(Question: Text[1024]; var Reply: Boolean)
    begin
        case true of
            Question = UpdateFromHeaderLinesQst:
                Reply := true;
            StrPos(Question, UpdateLineDimQst) <> 0:
                Reply := LibraryVariableStorage.DequeueBoolean;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptsModalPageHandler(var PostedPurchaseReceipts: Page "Posted Purchase Receipts"; var Response: Action)
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.Get(LibraryVariableStorage.DequeueText);
        PostedPurchaseReceipts.SetRecord(PurchRcptHeader);

        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptLinesModalPageHandler(var PostedPurchaseReceiptLines: Page "Posted Purchase Receipt Lines"; var Response: Action)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("No.", LibraryVariableStorage.DequeueText);
        PurchRcptLine.FindFirst;
        PostedPurchaseReceiptLines.SetRecord(PurchRcptLine);

        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchModalPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.GetTransferReceiptLines.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedTransferReceiptLinesModalPageHandler(var PostedTransferReceiptLines: TestPage "Posted Transfer Receipt Lines")
    begin
        PostedTransferReceiptLines.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText);
        PostedTransferReceiptLines.Last;
        PostedTransferReceiptLines."Item No.".AssertEquals(LibraryVariableStorage.DequeueText);
        Assert.IsFalse(PostedTransferReceiptLines.Previous, 'Invalid number of records on the page');
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    begin
        EditDimensionSetEntries.New;
        EditDimensionSetEntries."Dimension Code".SetValue(LibraryVariableStorage.DequeueText);
        EditDimensionSetEntries.DimensionValueCode.SetValue(LibraryVariableStorage.DequeueText);
        EditDimensionSetEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedTransferShipmentLinesHandler(var PostedTransferShipmentLines: TestPage "Posted Transfer Shipment Lines")
    begin
        LibraryVariableStorage.Enqueue(PostedTransferShipmentLines.Filter.GetFilter("Line No."));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedTransferShipmentLinesGetDescriptionHandler(var PostedTransferShipmentLines: TestPage "Posted Transfer Shipment Lines")
    begin
        LibraryVariableStorage.Enqueue(PostedTransferShipmentLines.Description.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedTransferReceiptLinesHandler(var PostedTransferReceiptLines: TestPage "Posted Transfer Receipt Lines")
    begin
        LibraryVariableStorage.Enqueue(PostedTransferReceiptLines.Filter.GetFilter("Line No."));
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1; // Ship
    end;
}

