codeunit 138048 "O365 Inv. Item Availability"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Availability] [Inventory]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        ItemNotFoundErr: Label 'Item not found.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Inv. Item Availability");
        LibraryVariableStorage.Clear;
        LibraryApplicationArea.EnableFoundationSetup;

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Inv. Item Availability");

        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.CreateVATData;
        IsInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Inv. Item Availability");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailabilityByPeriod()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByPeriod: TestPage "Item Availability by Periods";
        ExistingQuantity: Integer;
        DemandQuantity: Integer;
    begin
        // SETUP: Create an item and demand for the item on the workdate of the system.
        Initialize;
        ExistingQuantity := LibraryRandom.RandIntInRange(20, 100);
        DemandQuantity := LibraryRandom.RandInt(ExistingQuantity - 1);

        CreateItem(Item, ExistingQuantity);
        CreateSalesDemand(Item."No.", DemandQuantity);

        // EXECUTE: Open the Item Availability By Period page.
        ViewItemCard(ItemCard, Item);

        ItemAvailabilityByPeriod.Trap;
        ItemCard.Period.Invoke;
        SetDemandByPeriodFilters(ItemAvailabilityByPeriod, Item."No.", WorkDate);

        // VERIFY: The quantities in demand by period grid columns for the demand date
        AssertDemandByPeriodQuantities(ExistingQuantity - DemandQuantity, ItemAvailabilityByPeriod);
        ItemAvailabilityByPeriod.Close;
    end;

    [Test]
    [HandlerFunctions('ItemAvailByEventHandler')]
    [Scope('OnPrem')]
    procedure AvailabilityByEvent()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ExistingQuantity: Integer;
        DemandQuantity: Integer;
    begin
        // SETUP: Create an item and demand for the item on the workdate of the system.
        Initialize;
        ExistingQuantity := LibraryRandom.RandIntInRange(20, 100);
        DemandQuantity := LibraryRandom.RandInt(ExistingQuantity - 1);

        CreateItem(Item, ExistingQuantity);
        CreateSalesDemand(Item."No.", DemandQuantity);

        // SETUP: Enqueue value for ItemAvailByEventHandler.
        LibraryVariableStorage.Enqueue(ExistingQuantity - DemandQuantity);

        // EXECUTE: Open the Item Availability By Event page.
        ViewItemCard(ItemCard, Item);
        ItemCard."<Action110>".Invoke;

        // VERIFY: Verification is in the handler
    end;

    [Test]
    [HandlerFunctions('VendorListPickVendorModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchInvOpensVendorSelectionPageWhenVendorNoIsEmpty()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemAvailabilityCheck: TestPage "Item Availability Check";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize;

        // [GIVEN] Item "ITEM" with empty Vendor No.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", '');
        Item.Modify(true);

        // [GIVEN] Vendor "VEND"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Open Item Availability Check page for item "ITEM"
        ItemAvailabilityCheck.OpenEdit;
        ItemAvailabilityCheck.GotoRecord(Item);

        // [WHEN] Invoke 'Create Purchase Order' action and pick vendor VEND
        LibraryVariableStorage.Enqueue(Vendor."No.");
        PurchaseInvoice.Trap;
        ItemAvailabilityCheck."Purchase Invoice".Invoke;

        // [THEN] Purchase invoice created for vendor "VEND"
        PurchaseInvoice."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        // [THEN] Purchase invoice has line with item "ITEM"
        PurchaseInvoice.PurchLines."No.".AssertEquals(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchInvUsesTheVendorNoFromItem()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemAvailabilityCheck: TestPage "Item Availability Check";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize;

        // [GIVEN] Item "ITEM" with Vendor No. = "VEND"
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);

        // [GIVEN] Open Item Availability Check page for item "ITEM"
        ItemAvailabilityCheck.OpenEdit;
        ItemAvailabilityCheck.GotoRecord(Item);

        // [WHEN] Invoke 'Create Purchase Order' action
        PurchaseInvoice.Trap;
        ItemAvailabilityCheck."Purchase Invoice".Invoke;

        // [THEN] Purchase invoice created for vendor "VEND"
        PurchaseInvoice."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        // [THEN] Purchase invoice has line with item "ITEM"
        PurchaseInvoice.PurchLines."No.".AssertEquals(Item."No.");
    end;

    [Test]
    [HandlerFunctions('VendorListPickVendorModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchOrderItemVendorNoIsEmptyVendorSelected()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemAvailabilityCheck: TestPage "Item Availability Check";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 264628] Create Purchase Order action for item with empty Vendor No after vendor selection creates and opens a new purchase order
        Initialize;

        // [GIVEN] Item "ITEM" with empty Vendor No.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", '');
        Item.Modify(true);

        // [GIVEN] Vendor "VEND"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Open Item Availability Check page for item "ITEM"
        ItemAvailabilityCheck.OpenEdit;
        ItemAvailabilityCheck.GotoRecord(Item);

        // [WHEN] Invoke 'Create Purchase Order' action and pick vendor VEND
        LibraryVariableStorage.Enqueue(Vendor."No.");
        PurchaseOrder.Trap;
        ItemAvailabilityCheck."Purchase Order".Invoke;

        // [THEN] Purchase order created for vendor "VEND"
        PurchaseOrder."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        // [THEN] Purchase order has line with item "ITEM"
        PurchaseOrder.PurchLines."No.".AssertEquals(Item."No.");
    end;

    [Test]
    [HandlerFunctions('VendorListCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchOrderItemVendorNoIsEmptyVendorSelectionCanceled()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemAvailabilityCheck: TestPage "Item Availability Check";
        PurchDocQty: Integer;
    begin
        // [SCENARIO 264628] Create Purchase Order action for item with empty Vendor No and vendor selection canceled a new purchase order is not created
        Initialize;

        // [GIVEN] Item "ITEM" with empty Vendor No.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", '');
        Item.Modify(true);
        PurchDocQty := PurchaseHeader.Count;

        // [GIVEN] Open Item Availability Check page for item "ITEM"
        ItemAvailabilityCheck.OpenEdit;
        ItemAvailabilityCheck.GotoRecord(Item);

        // [WHEN] Invoke 'Create Purchase Order' action and cancel vendor selection
        ItemAvailabilityCheck."Purchase Order".Invoke;

        // [THEN] Purchase order is not created
        Assert.AreEqual(PurchDocQty, PurchaseHeader.Count, 'Purchase document should not be created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchOrderUsesTheVendorNoFromItem()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemAvailabilityCheck: TestPage "Item Availability Check";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 264628] Create Purchase Order action for item with Vendor No makes a new purchase order
        Initialize;

        // [GIVEN] Item "ITEM" with Vendor No. = "VEND"
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);

        // [GIVEN] Open Item Availability Check page for item "ITEM"
        ItemAvailabilityCheck.OpenEdit;
        ItemAvailabilityCheck.GotoRecord(Item);

        // [WHEN] Invoke 'Create Purchase Order' action
        PurchaseOrder.Trap;
        ItemAvailabilityCheck."Purchase Order".Invoke;

        // [THEN] Purchase order created for vendor "VEND"
        PurchaseOrder."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        // [THEN] Purchase order has line with item "ITEM"
        PurchaseOrder.PurchLines."No.".AssertEquals(Item."No.");
    end;

    [Normal]
    local procedure CreateItem(var Item: Record Item; Quantity: Integer)
    var
        AdjustItemInventory: Codeunit "Adjust Item Inventory";
    begin
        // Creates a new item. Wrapper for the library method.
        LibraryInventory.CreateItem(Item);
        AdjustItemInventory.PostAdjustmentToItemLedger(Item, Quantity);
    end;

    local procedure CreateSalesDemandBasis(ItemNo: Code[20]; ItemQty: Integer; NeededBy: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, NeededBy, ItemQty);
        SalesLine.Validate("Shipment Date", NeededBy);
        SalesLine.Modify(true);

        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesDemand(ItemNo: Code[20]; Quantity: Integer): Code[20]
    begin
        exit(CreateSalesDemandBasis(ItemNo, Quantity, WorkDate));
    end;

    [Normal]
    local procedure ViewItemCard(var ItemCard: TestPage "Item Card"; Item: Record Item)
    begin
        ItemCard.OpenView;

        if not ItemCard.GotoRecord(Item) then
            Error(ItemNotFoundErr);
    end;

    [Normal]
    local procedure SetDemandByPeriodFilters(ItemAvailabilityByPeriod: TestPage "Item Availability by Periods"; ItemNo: Code[20]; FilterDate: Date)
    var
        StartDate: Date;
    begin
        ItemAvailabilityByPeriod.FILTER.SetFilter("No.", ItemNo);
        ItemAvailabilityByPeriod.ItemAvailLines.FILTER.SetFilter("Period Start", Format(FilterDate));
        ItemAvailabilityByPeriod.PeriodType.Value := 'Day';
        ItemAvailabilityByPeriod.ItemAvailLines.First;
        StartDate := ItemAvailabilityByPeriod.ItemAvailLines."Period Start".AsDate;
        Assert.AreEqual(FilterDate, StartDate, 'SetFilter returned record with correct date');
    end;

    [Normal]
    local procedure AssertDemandByPeriodQuantities(Forecasted: Integer; var ItemAvailabilityByPeriod: TestPage "Item Availability by Periods")
    begin
        ItemAvailabilityByPeriod.ItemAvailLines.ProjAvailableBalance.AssertEquals(Forecasted);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailByEventHandler(var ItemAvailabilityByEvent: TestPage "Item Availability by Event")
    begin
        ItemAvailabilityByEvent.FILTER.SetFilter("Period Start", Format(WorkDate));
        ItemAvailabilityByEvent.First;
        ItemAvailabilityByEvent."Projected Inventory".AssertEquals(LibraryVariableStorage.DequeueInteger);

        ItemAvailabilityByEvent.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorListPickVendorModalPageHandler(var VendorList: TestPage "Vendor List")
    begin
        VendorList.GotoKey(LibraryVariableStorage.DequeueText);
        VendorList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorListCancelModalPageHandler(var VendorList: TestPage "Vendor List")
    begin
        VendorList.Cancel.Invoke;
    end;
}

