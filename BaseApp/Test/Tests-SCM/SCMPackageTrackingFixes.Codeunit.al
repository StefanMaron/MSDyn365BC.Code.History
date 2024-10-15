codeunit 137268 "SCM Package Tracking Fixes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        PackageNumberIsRequired: Label 'You must assign a package number for item %1.', Comment = '%1 - Item No.';
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LineNoTxt: Label ' Line No. = ''%1''.', Comment = '%1 - Line No.';
        IncorrectErrorMessageErr: Label 'Incorrect error message';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ItemTrackingOption: Option AssignPackageNo,ReclassPackageNo;

    [Test]
    [Scope('OnPrem')]
    procedure PostItemJnlLinePosAdjmtNoPackage()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Test case to check Positive Adjustment Item Journal Line with undefined Tracking Specification
        // for Item with Package Tracking cannot be posted

        PostItemJnlLineWithUndefinedPackageNo(ItemJnlLine."Entry Type"::"Positive Adjmt.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostItemJnlLinePurchaseNoPackage()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Test case to check Purchase Item Journal Line with undefined Tracking Specification
        // for Item with Package Tracking cannot be posted

        PostItemJnlLineWithUndefinedPackageNo(ItemJnlLine."Entry Type"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSE30275()
    var
        Location: Record Location;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        Vendor: Record Vendor;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        CopyPurchaseDocument: Report "Copy Purchase Document";
        CDNo: array[2] of Code[50];
    begin
        // Test case to check Purchase Credit Memo creation from Posted Purchase Receipt using Copy Document functionality
        // Check for CD Tracking info is correctly copied also

        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        CDNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", CDNo[1]);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify();
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1], 10);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptLine.Reset();
        PurchRcptLine.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchRcptLine.FindFirst();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        PurchaseHeader."Vendor Cr. Memo No." := PurchaseHeader."No.";
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters("Purchase Document Type From"::"Posted Receipt", PurchRcptLine."Document No.", true, true);
        CopyPurchaseDocument.Run();

        LibrarySmallBusiness.UpdatePurchHeaderDocTotal(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], -10);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPackageTrackingWithAppliedEntryNo()
    var
        Location: Record Location;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        Vendor: Record Vendor;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PackageNo: array[2] of Code[50];
        Qty: Decimal;
    begin
        // Test case to check Purchase Credit Memo creation from Posted Purchase Receipt using Copy Document functionality
        // Check for Package Tracking info is correctly copied also

        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);
        Qty := LibraryRandom.RandInt(100);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify();
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[1], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, Customer."No.", Location.Code);
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, Item."No.", Qty, Qty);
        ReservationEntry.Reset();
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', '', PackageNo[1], Qty);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLineWithUnitPrice(
          SalesLine, SalesHeader, Item."No.", LibraryRandom.RandDec(100, 2), Qty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify();
        ReservationEntry.Reset();
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', '', '', Qty);
        ReservationEntry.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Validate("Package No.", PackageNo[1]);
        ReservationEntry.UpdateItemTracking();
        ReservationEntry.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo[1], Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageWithLineNoShownWhenPostItemJnlLineWithoutPackageNo()
    var
        Item: Record Item;
        Location: Record Location;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 378978] Error message with current "Line No." is shown when post Item Journal Line without "Package No." assigned

        Initialize();

        // [GIVEN] Item "X" with "Package Specific Tracking"
        LibraryWarehouse.CreateLocation(Location);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        // [WHEN] Post Item Journal Line without "Package No." assigned
        LibraryInventory.CreateItemJnlLine(
          ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", LibraryRandom.RandInt(100), Location.Code);
        asserterror LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        // [THEN] Error Message "Package Number required. Line No. = '10000'" is shown
        Assert.AreEqual(
          GetLastErrorText, StrSubstNo(PackageNumberIsRequired, Item."No.") + StrSubstNo(LineNoTxt, ItemJnlLine."Line No."),
          IncorrectErrorMessageErr);
    end;

    [Test]
    [HandlerFunctions('ReservationModalPageHandler,AvailItemLedgEntriesModalPageHandler')]
    procedure ViewingAvailItemEntriesWithPackageTrkgForReservation()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PackageNo: Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Package Tracking] [Reservation]
        // [SCENARIO 420498] Viewing available item entries with package tracking for reservation.
        Initialize();
        PackageNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Package-tracked item.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post the item to inventory, assign package no. "P".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', Qty);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', '', PackageNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, "Sales Document Type"::Order, '', Item."No.", Qty, Location.Code, WorkDate());

        // [WHEN] Run "Reserve" on the sales order line and drill down "Total Quantity" on the Reservation page.
        LibraryVariableStorage.Enqueue(PackageNo);
        LibraryVariableStorage.Enqueue(Qty);
        SalesLine.ShowReservation();

        // [THEN] "Available - Item Ledg. Entries" page shows the item entry with package no. "P".
        // The verification is done in AvailItemLedgEntriesModalPageHandler.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandler')]
    procedure AssignNonSpecificPackageNoInWarehousePick()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
        PackageNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Package] [Warehouse Pick] [Non-Specific Tracking]
        // [SCENARIO 425815] Stan can assign non-specific package no. in warehouse pick and register it.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        PackageNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location set up for directed put-away and pick.
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Item with lot warehouse tracking and non-specific package tracking.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, false);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Validate("Package Sales Outb. Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        // [GIVEN] Post inventory, assign lot no.
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(1);
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(Item."No.", Location.Code, 1, true);

        // [GIVEN] Sales order, create warehouse shipment and pick.
        CreateSalesOrderWhseShipmentAndPick(WarehouseShipmentHeader, WarehouseActivityHeader, Item."No.", Location.Code, 1);

        // [WHEN] Select lot no. from inventory and assign new package no. on the pick lines.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Lot No.", LotNo);
            WarehouseActivityLine.Validate("Package No.", PackageNo);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;

        // [THEN] No error is thrown on validating lot no. and package no.

        // [THEN] The warehouse pick and warehouse shipment can be successfully registered.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Item entry for the sales has both lot no. and package no.
        VerifyItemLedgerEntry(Item."No.", '', LotNo, PackageNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandler')]
    procedure AssignNonSpecificLotNoInWarehousePick()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
        SerialNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Warehouse Pick] [Non-Specific Tracking]
        // [SCENARIO 425815] Stan can assign non-specific lot no. in warehouse pick and register it.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        SerialNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location set up for directed put-away and pick.
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Item with serial no. warehouse tracking and non-specific lot tracking.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, false);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Validate("Lot Sales Outbound Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        // [GIVEN] Post inventory, assign serial no.
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(1);
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(Item."No.", Location.Code, 1, true);

        // [GIVEN] Sales order, create warehouse shipment and pick.
        CreateSalesOrderWhseShipmentAndPick(WarehouseShipmentHeader, WarehouseActivityHeader, Item."No.", Location.Code, 1);

        // [WHEN] Select serial no. from inventory and assign new lot no. on the pick lines.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Serial No.", SerialNo);
            WarehouseActivityLine.Validate("Lot No.", LotNo);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;

        // [THEN] No error is thrown on validating serial no. and lot no.

        // [THEN] The warehouse pick and warehouse shipment can be successfully registered.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Item entry for the sales has both serial no. and lot no.
        VerifyItemLedgerEntry(Item."No.", SerialNo, LotNo, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Package Tracking Fixes");
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Package Tracking Fixes");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateLocalData();

        UpdateSalesSetup();
        UpdateInventorySetup();
        NoSeriesSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Package Tracking Fixes");
    end;

    local procedure AssignTrackingReclassification(var ItemJournalLine: Record "Item Journal Line"; PackageNo: Code[50]; NewPackageNo: Code[50])
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingOption::ReclassPackageNo);
        LibraryVariableStorage.Enqueue(PackageNo);
        LibraryVariableStorage.Enqueue(ItemJournalLine."Quantity (Base)");
        LibraryVariableStorage.Enqueue(NewPackageNo);
        ItemJournalLine.OpenItemTrackingLines(true);
    end;

    local procedure CreateSalesOrderWhseShipmentAndPick(var WarehouseShipmentHeader: Record "Warehouse Shipment Header";
                                                        var WarehouseActivityHeader: Record "Warehouse Activity Header";
                                                        ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, "Sales Document Type"::Order, '', ItemNo, Qty, LocationCode, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
    end;

    local procedure PostItemJnlLineWithUndefinedPackageNo(EntryType: Enum "Item Ledger Entry Type")
    var
        Location: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: array[2] of Code[50];
    begin
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        PackageNo[1] := LibraryUtility.GenerateGUID();

        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);
        LibraryInventory.CreateItemJnlLine(
          ItemJnlLine, EntryType, WorkDate(), Item."No.", LibraryRandom.RandInt(100), Location.Code);

        asserterror LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);
        Assert.ExpectedError(StrSubstNo(PackageNumberIsRequired, Item."No."));
    end;

    local procedure UpdateSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Exact Cost Reversing Mandatory" := true;
        SalesReceivablesSetup.Modify();
    end;

    local procedure NoSeriesSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibrarySales.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
    end;

    local procedure UpdateInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Location Mandatory", true);
        InventorySetup.Modify();
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; SerialNo: Code[50]; LotNo: Code[50]; PackageNo: Code[50])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Serial No.", SerialNo);
        ItemLedgerEntry.TestField("Lot No.", LotNo);
        ItemLedgerEntry.TestField("Package No.", PackageNo);
    end;

    local procedure VerifyTrackingReclassification(ItemJnlLine: Record "Item Journal Line"; ExpectedPackageNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        with ReservationEntry do begin
            SetRange("Item No.", ItemJnlLine."Item No.");
            SetRange("Source Type", DATABASE::"Item Journal Line");
            SetRange("Source ID", ItemJnlLine."Journal Template Name");
            SetRange("Source Batch Name", ItemJnlLine."Journal Batch Name");
            FindFirst();

            TestField("New Package No.", ExpectedPackageNo);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingOption: Option;
    begin
        TrackingOption := LibraryVariableStorage.DequeueInteger();
        ItemTrackingLines."Package No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        if TrackingOption = ItemTrackingOption::ReclassPackageNo then
            ItemTrackingLines."New Package No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure WhseItemTrackingLinesModalPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ReservationModalPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Total Quantity".Drilldown();
    end;


    [ModalPageHandler]
    procedure AvailItemLedgEntriesModalPageHandler(var AvailableItemLedgEntries: TestPage "Available - Item Ledg. Entries")
    begin
        AvailableItemLedgEntries."Package No.".AssertEquals(LibraryVariableStorage.DequeueText());
        AvailableItemLedgEntries."Remaining Quantity".AssertEquals(LibraryVariableStorage.DequeueDecimal());
        AvailableItemLedgEntries.OK().Invoke();
    end;
}

