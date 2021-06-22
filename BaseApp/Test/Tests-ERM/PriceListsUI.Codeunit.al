codeunit 134117 "Price Lists UI"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Price List] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FeatureIsOffErr: Label 'Extended price calculation feature is not enabled.';
        IsInitialized: Boolean;
        CreateNewTxt: Label 'Create New...';
        ViewExistingTxt: Label 'View Existing Prices and Discounts...';

    [Test]
    procedure T000_SalesPriceListsPageIsNotEditable()
    var
        PriceListHeader: Record "Price List Header";
        SalesPriceLists: TestPage "Sales Price Lists";
    begin
        Initialize(true);

        // [GIVEN] Price List, where "Source Type" is 'All Customers', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');

        // [WHEN] Open page "Sales Price Lists" without filters
        SalesPriceLists.Trap();
        Page.Run(Page::"Sales Price Lists");

        // [THEN] The page is not editable, 
        Assert.IsFalse(SalesPriceLists.Editable(), 'the page is editable');
        // [THEN] The columns are Description, Status, "Currency Code", "Source Type", "Source No.", "Starting Date", "Ending Date"
        Assert.IsTrue(SalesPriceLists.Description.Visible(), 'Description is not visible');
        Assert.IsTrue(SalesPriceLists.Status.Visible(), 'Status is not visible');
        Assert.IsTrue(SalesPriceLists.SourceType.Visible(), 'SourceType is not visible');
        Assert.IsTrue(SalesPriceLists.SourceNo.Visible(), 'SourceNo is not visible');
        Assert.IsTrue(SalesPriceLists."Starting Date".Visible(), 'Starting Date is not visible');
        Assert.IsTrue(SalesPriceLists."Ending Date".Visible(), 'Ending Date is not visible');
    end;

    [Test]
    procedure T001_SalesPriceListsShowsAllCustomers()
    var
        PriceListHeader: Array[5] of Record "Price List Header";
        SalesPriceLists: TestPage "Sales Price Lists";
    begin
        // [SCENARIO] Sales Price lists page shows prices for "All Customers" if open not from a customer.
        Initialize(true);

        // [GIVEN] Price List #1, where "Source Type" is 'Campaign' 'B', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::Campaign, '');
        // [GIVEN] Price List #2, where "Source Type" is 'All Customers', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] Price List #3, where "Source Type" is 'Vendor' 'A', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Purchase, "Price Source Type"::"Vendor", '');
        // [GIVEN] Price List #4, where "Source Type" is 'Customer' 'A', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::"Customer", '');
        // [GIVEN] Price List #5, where "Source Type" is 'All Jobs', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[5], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');

        // [WHEN] Open page "Sales Price Lists" without filters
        SalesPriceLists.Trap();
        Page.Run(Page::"Sales Price Lists");

        // [THEN] There are 2 price lists with source types: "All Customers" and "Customer"
        Assert.IsTrue(SalesPriceLists.First(), 'not found first');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found second');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        Assert.IsFalse(SalesPriceLists.Next(), 'found third');
    end;

    [Test]
    procedure T002_SalesPriceListsPricesFromCustomersCard()
    var
        Customer: Array[2] of Record Customer;
        PriceListHeader: Array[4] of Record "Price List Header";
        CustomerCard: TestPage "Customer Card";
        SalesPriceLists: TestPage "Sales Price Lists";
    begin
        // [SCENARIO] Sales Price lists page shows prices for one customer open from the customer card.
        Initialize(true);
        // [GIVEN] Customers 'A' and 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Customers'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] Price List #2, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Customer' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::Customer, Customer[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[4].Modify();

        // [GIVEN] Open Customer Card for customer 'A'
        CustomerCard.OpenEdit();
        CustomerCard.Filter.SetFilter("No.", Customer[1]."No.");

        // [WHEN] Run action "Sales Price Lists"
        SalesPriceLists.Trap();
        CustomerCard.PriceLists.Invoke();

        // [THEN] There are 3 price lists - #1, #2, #4
        Assert.IsTrue(SalesPriceLists.First(), 'not found first');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found second');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found third');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[4]."Source No.");
        Assert.IsFalse(SalesPriceLists.Next(), 'found 4th');
    end;

    [Test]
    procedure T003_SalesPriceListsDiscountsFromCustomersList()
    var
        Customer: Array[2] of Record Customer;
        PriceListHeader: Array[4] of Record "Price List Header";
        CustomerList: TestPage "Customer List";
        SalesPriceLists: TestPage "Sales Price Lists";
    begin
        // [SCENARIO] Sales Price lists page shows discounts for one customer open from the customer list.
        Initialize(true);
        // [GIVEN] Customers 'A' and 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Customers'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] Price List #2, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Customer' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::Customer, Customer[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[4].Modify();

        // [GIVEN] Open Customer List for customer 'A'
        CustomerList.OpenEdit();
        CustomerList.Filter.SetFilter("No.", Customer[1]."No.");

        // [WHEN] Run action "Price Lists (Discounts)"
        SalesPriceLists.Trap();
        CustomerList.PriceListsDiscounts.Invoke();

        // [THEN] There are 2 price lists - #1 and #2
        Assert.IsTrue(SalesPriceLists.First(), 'not found first');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found second');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsFalse(SalesPriceLists.Next(), 'found third');
    end;

    [Test]
    procedure T004_SalesPriceListsPricesForPriceGroupFromCustomersCard()
    var
        Customer: Array[2] of Record Customer;
        CustomerDiscountGroup: Record "Customer Discount Group";
        CustomerPriceGroup: Record "Customer Price Group";
        PriceListHeader: Array[5] of Record "Price List Header";
        CustomerCard: TestPage "Customer Card";
        SalesPriceLists: TestPage "Sales Price Lists";
    begin
        // [SCENARIO] Sales Price lists page shows prices for one customer and its price group open from the customer card.
        Initialize(true);
        // [GIVEN] Customers 'A', where "Customer Price Group" is 'X', "Customer Disc. Group" 'Y', and Customer 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        Customer[1]."Customer Price Group" := CustomerPriceGroup.Code;
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);
        Customer[1]."Customer Disc. Group" := CustomerDiscountGroup.Code;
        Customer[1].Modify();
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Customers'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] Price List #2, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[2]."Amount Type"::Price;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Customer' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::Customer, Customer[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Customer Price Group' 'X', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code);
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[4].Modify();
        // [GIVEN] Price List #5, where "Source Type" is 'Customer Discount Group' 'Y', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[5], "Price Type"::Sale, "Price Source Type"::"Customer Disc. Group", CustomerDiscountGroup.Code);
        PriceListHeader[5]."Amount Type" := PriceListHeader[5]."Amount Type"::Discount;
        PriceListHeader[5].Modify();

        // [GIVEN] Open Customer Card for customer 'A'
        CustomerCard.OpenEdit();
        CustomerCard.Filter.SetFilter("No.", Customer[1]."No.");

        // [WHEN] Run action "Sales Price Lists"
        SalesPriceLists.Trap();
        CustomerCard.PriceLists.Invoke();

        // [THEN] There are 4 price lists - #1, #2, #4, #5
        Assert.IsTrue(SalesPriceLists.First(), 'not found first');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found second');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found third');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[4]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found 4th');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[5]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[5]."Source No.");
        Assert.IsFalse(SalesPriceLists.Next(), 'found 5th');
    end;

    [Test]
    procedure T005_SalesPriceListsDiscForDiscGroupFromCustomersCard()
    var
        Customer: Array[2] of Record Customer;
        CustomerDiscountGroup: Record "Customer Discount Group";
        CustomerPriceGroup: Record "Customer Price Group";
        PriceListHeader: Array[5] of Record "Price List Header";
        CustomerCard: TestPage "Customer Card";
        SalesPriceLists: TestPage "Sales Price Lists";
    begin
        // [SCENARIO] Sales Price lists page shows discounts for one customer and its discount group open from the customer card.
        Initialize(true);
        // [GIVEN] Customers 'A', where "Customer Price Group" is 'X', "Customer Disc. Group" 'Y', and Customer 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        Customer[1]."Customer Price Group" := CustomerPriceGroup.Code;
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);
        Customer[1]."Customer Disc. Group" := CustomerDiscountGroup.Code;
        Customer[1].Modify();
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Customers', "Amount Type" 'Any'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader[1]."Amount Type" := PriceListHeader[1]."Amount Type"::Any;
        PriceListHeader[1].Modify();
        // [GIVEN] Price List #2, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[2]."Amount Type"::Discount;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Customer' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::Customer, Customer[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Customer Price Group' 'X', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code);
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[4].Modify();
        // [GIVEN] Price List #4, where "Source Type" is 'Customer Discount Group' 'Y', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[5], "Price Type"::Sale, "Price Source Type"::"Customer Disc. Group", CustomerDiscountGroup.Code);
        PriceListHeader[5]."Amount Type" := PriceListHeader[5]."Amount Type"::Discount;
        PriceListHeader[5].Modify();

        // [GIVEN] Open Customer Card for customer 'A'
        CustomerCard.OpenEdit();
        CustomerCard.Filter.SetFilter("No.", Customer[1]."No.");

        // [WHEN] Run action "Price Lists (Discounts)"
        SalesPriceLists.Trap();
        CustomerCard.PriceListsDiscounts.Invoke();

        // [THEN] There are 3 price lists - #1, #2, #5
        Assert.IsTrue(SalesPriceLists.First(), 'not found first');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found second');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found third');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[5]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[5]."Source No.");
        Assert.IsFalse(SalesPriceLists.Next(), 'found fourth');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T010_SalesStatusFromDraftToActive()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [SCENARIO] Sales Price list page gets not editable (except Status control) if Status set to Active.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] Price List, where Status is 'Draft'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::" ", '');
        SalesPriceList.OpenEdit();
        // [GIVEN] Price list page open, where Status is 'Draft', all controls are editable
        Assert.IsTrue(SalesPriceList.Status.Editable(), 'Status.not Editable');
        Assert.IsTrue(SalesPriceList.AmountType.Editable(), 'AmountType.not Editable');
        VerifyAllControlsEditable(SalesPriceList);

        // [WHEN] Change Status to 'Active' (answer 'Yes' to confirmation)
        SalesPriceList.Status.SetValue(PriceListHeader.Status::Active);

        // [THEN] All fields and lines part are not editable,
        VerifyAllControlsNotEditable(SalesPriceList);
        // [GIVEN] Controls "Status", "View Columns For" are editable
        Assert.IsTrue(SalesPriceList.Status.Editable(), 'Active Status.not Editable');
        Assert.IsTrue(SalesPriceList.AmountType.Editable(), 'AmountType.not Editable');
    end;

    [Test]
    procedure T011_SalesStatusFromInactiveToDraft()
    var
        PriceListHeader: Record "Price List Header";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [SCENARIO] Sales Price list page gets editable if Status set to Draft.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] Price List, where Status is 'Inactive'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader.Status := PriceListHeader.Status::Inactive;
        PriceListHeader.Modify();
        SalesPriceList.OpenEdit();
        // [GIVEN] Price list page open, where Status is Inactive, all controls are not editable 
        VerifyAllControlsNotEditable(SalesPriceList);
        // [GIVEN] Controls "Status", "View Columns For" are editable
        Assert.IsTrue(SalesPriceList.Status.Editable(), 'Active Status.not Editable');
        Assert.IsTrue(SalesPriceList.AmountType.Editable(), 'AmountType.not Editable');

        // [WHEN] Change Status to 'Draft'
        SalesPriceList.Status.SetValue(PriceListHeader.Status::Draft);

        // [THEN] All fields and lines part are editable
        Assert.IsTrue(SalesPriceList.Status.Editable(), 'Status.not Editable');
        Assert.IsTrue(SalesPriceList.AmountType.Editable(), 'AmountType.not Editable');
        VerifyAllControlsEditable(SalesPriceList);
    end;

    [Test]
    procedure T020_CustomerCardPriceListsActionVisibleIfFeatureOn()
    var
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize(true);
        // [GIVEN] Feature is On

        // [WHEN] Open "Customer Card"
        CustomerCard.OpenEdit();

        // [THEN] "Sales Price Lists" action is visible, old actions are not visible
        Assert.IsTrue(CustomerCard.PriceLists.Visible(), 'PriceLists. not Visible');
        Assert.IsFalse(CustomerCard.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsFalse(CustomerCard.Prices.Visible(), 'Prices. Visible');
        Assert.IsFalse(CustomerCard."Line Discounts".Visible(), 'Line Discounts. Visible');
    end;

    [Test]
    procedure T021_CustomerCardPriceListsActionNotVisibleIfFeatureOff()
    var
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Customer Card"
        CustomerCard.OpenEdit();

        // [THEN] "Price Lists" actions are not visible, old actions are visible
        Assert.IsFalse(CustomerCard.PriceLists.Visible(), 'PriceLists. Visible');
        Assert.IsFalse(CustomerCard.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsTrue(CustomerCard.Prices.Visible(), 'Prices. not Visible');
        Assert.IsTrue(CustomerCard."Line Discounts".Visible(), 'Line Discounts. not Visible');
    end;

    [Test]
    procedure T022_CustomerListPriceListsActionVisibleIfFeatureOn()
    var
        CustomerList: TestPage "Customer List";
    begin
        Initialize(true);
        // [GIVEN] Feature is On

        // [WHEN] Open "Customer List"
        CustomerList.OpenEdit();

        // [THEN] "Sales Price Lists" action is visible, old actions are not visible
        Assert.IsTrue(CustomerList.PriceLists.Visible(), 'PriceLists. not Visible');
        Assert.IsFalse(CustomerList.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsFalse(CustomerList.Prices_Prices.Visible(), 'Prices_Prices. Visible');
        Assert.IsFalse(CustomerList.Prices_LineDiscounts.Visible(), 'Prices_LineDiscounts. Visible');
    end;

    [Test]
    procedure T023_CustomerListPriceListsActionNotVisibleIfFeatureOff()
    var
        CustomerList: TestPage "Customer List";
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Customer List"
        CustomerList.OpenEdit();

        // [THEN] "Price Lists" actions are not visible, old actions are visible
        Assert.IsFalse(CustomerList.PriceLists.Visible(), 'PriceLists. Visible');
        Assert.IsFalse(CustomerList.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsTrue(CustomerList.Prices_Prices.Visible(), 'Prices. not Visible');
        Assert.IsTrue(CustomerList.Prices_LineDiscounts.Visible(), 'Line Discounts. not Visible');
    end;

    [Test]
    procedure T024_SalesPriceListsPageNotOpenIfFeatureOff()
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Sales Price Lists" page
        asserterror Page.Run(Page::"Sales Price Lists");
        Assert.ExpectedError(FeatureIsOffErr);
    end;

    [Test]
    procedure T025_SalesPriceListPageNotOpenIfFeatureOff()
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Sales Price List" page
        asserterror Page.Run(Page::"Sales Price List");
        Assert.ExpectedError(FeatureIsOffErr);
    end;

    [Test]
    procedure T030_OpenItemCardIfItemDiscGroupDeleted()
    var
        Item: Record Item;
        ItemDiscountGroup: Record "Item Discount Group";
        PriceListLine: Record "Price List Line";
        ItemCard: TestPage "Item Card";
    begin
        Initialize(true);

        // [GIVEN] Item 'X', where "Item Disc. Group" is 'IDG'
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        Item."Item Disc. Group" := ItemDiscountGroup.Code;
        Item.Modify();

        // [GIVEN] Purchase Price List Line for Item 'X'
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, '', "Price Source Type"::"All Vendors", '',
            "Price Asset Type"::Item, Item."No.");
        // [GIVEN] Sales Price List Line for "Item Disc. Group" 'IDG'
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '',
            "Price Asset Type"::"Item Discount Group", ItemDiscountGroup.Code);

        // [GIVEN] Item Discount Group 'IDG' is removed
        ItemDiscountGroup.Delete();

        // [WHEN] Open Item card for 'X'
        ItemCard.Trap();
        Page.Run(Page::"Item Card", Item);

        // [THEN] Item card is open, where Purchase section: 'View existing prices...', Sales section: 'Create new...'
        ItemCard.SpecialPurchPriceListTxt.AssertEquals(ViewExistingTxt);
        ItemCard.SpecialSalesPriceListTxt.AssertEquals(CreateNewTxt);
        ItemCard.Close();
    end;

    [Test]
    procedure T050_PurchasePriceListsPageIsNotEditable()
    var
        PriceListHeader: Record "Price List Header";
        PurchasePriceLists: TestPage "Purchase Price Lists";
    begin
        Initialize(true);

        // [GIVEN] Price List, where "Source Type" is 'All Vendors', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');

        // [WHEN] Open page "Purchase Price Lists" without filters
        PurchasePriceLists.Trap();
        Page.Run(Page::"Purchase Price Lists");

        // [THEN] The page is not editable, 
        Assert.IsFalse(PurchasePriceLists.Editable(), 'the page is editable');
        // [THEN] The columns are Description, Status, "Currency Code", "Source Type", "Source No.", "Starting Date", "Ending Date"
        Assert.IsTrue(PurchasePriceLists.Description.Visible(), 'Description is not visible');
        Assert.IsTrue(PurchasePriceLists.Status.Visible(), 'Status is not visible');
        Assert.IsTrue(PurchasePriceLists.SourceType.Visible(), 'SourceType is not visible');
        Assert.IsTrue(PurchasePriceLists.SourceNo.Visible(), 'SourceNo is not visible');
        Assert.IsTrue(PurchasePriceLists."Starting Date".Visible(), 'Starting Date is not visible');
        Assert.IsTrue(PurchasePriceLists."Ending Date".Visible(), 'Ending Date is not visible');
    end;

    [Test]
    procedure T051_PurchasePriceListsShowsAllVendors()
    var
        PriceListHeader: Array[5] of Record "Price List Header";
        PurchasePriceLists: TestPage "Purchase Price Lists";
    begin
        // [SCENARIO] Purchase Price lists page shows prices for "All Vendors" if open not from a Vendor.
        Initialize(true);

        // [GIVEN] Price List #1, where "Source Type" is 'Campaign' 'B', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::Campaign, '');
        // [GIVEN] Price List #2, where "Source Type" is 'All Vendors', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        // [GIVEN] Price List #3, where "Source Type" is 'Customer' 'A', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::"Customer", '');
        // [GIVEN] Price List #4, where "Source Type" is 'Vendor' 'A', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Purchase, "Price Source Type"::"Vendor", '');
        // [GIVEN] Price List #5, where "Source Type" is 'All Jobs', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[5], "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');

        // [WHEN] Open page "Purchase Price Lists" without filters
        PurchasePriceLists.Trap();
        Page.Run(Page::"Purchase Price Lists");

        // [THEN] There are 2 price lists with source types: "All Vendors" and "Vendor"
        Assert.IsTrue(PurchasePriceLists.First(), 'not found first');
        PurchasePriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        Assert.IsTrue(PurchasePriceLists.Next(), 'not found second');
        PurchasePriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        Assert.IsFalse(PurchasePriceLists.Next(), 'found third');
    end;

    [Test]
    procedure T052_PurchasePriceListsPricesFromVendorsCard()
    var
        Vendor: Array[2] of Record Vendor;
        PriceListHeader: Array[4] of Record "Price List Header";
        VendorCard: TestPage "Vendor Card";
        PurchasePriceLists: TestPage "Purchase Price Lists";
    begin
        // [SCENARIO] Purchase Price lists page shows prices for one Vendor open from the Vendor card.
        Initialize(true);
        // [GIVEN] Vendors 'A' and 'B'
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Vendors'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        // [GIVEN] Price List #2, where "Source Type" is 'Vendor' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Vendor' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Vendor' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[4].Modify();

        // [GIVEN] Open Vendor Card for Vendor 'A'
        VendorCard.OpenEdit();
        VendorCard.Filter.SetFilter("No.", Vendor[1]."No.");

        // [WHEN] Run action "Price Lists (Prices)"
        PurchasePriceLists.Trap();
        VendorCard.PriceLists.Invoke();

        // [THEN] There are 3 price lists - #1, #2, #4
        Assert.IsTrue(PurchasePriceLists.First(), 'not found first');
        PurchasePriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        PurchasePriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(PurchasePriceLists.Next(), 'not found second');
        PurchasePriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        PurchasePriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsTrue(PurchasePriceLists.Next(), 'not found third');
        PurchasePriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        PurchasePriceLists.SourceNo.AssertEquals(PriceListHeader[4]."Source No.");
        Assert.IsFalse(PurchasePriceLists.Next(), 'found 4th');
    end;

    [Test]
    procedure T053_PurchasePriceListsDiscountsFromVendorsList()
    var
        Vendor: Array[2] of Record Vendor;
        PriceListHeader: Array[4] of Record "Price List Header";
        VendorList: TestPage "Vendor List";
        PurchasePriceLists: TestPage "Purchase Price Lists";
    begin
        // [SCENARIO] Purchase Price lists page shows discounts for one Vendor open from the Vendor list.
        Initialize(true);
        // [GIVEN] Vendors 'A' and 'B'
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Vendors'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        // [GIVEN] Price List #2, where "Source Type" is 'Vendor' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Vendor' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Vendor' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[4].Modify();

        // [GIVEN] Open Vendor List for Vendor 'A'
        VendorList.OpenEdit();
        VendorList.Filter.SetFilter("No.", Vendor[1]."No.");

        // [WHEN] Run action "Price Lists (Discounts)"
        PurchasePriceLists.Trap();
        VendorList.PriceListsDiscounts.Invoke();

        // [THEN] There are 2 price lists - #1 and #2
        Assert.IsTrue(PurchasePriceLists.First(), 'not found first');
        PurchasePriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        PurchasePriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(PurchasePriceLists.Next(), 'not found second');
        PurchasePriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        PurchasePriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsFalse(PurchasePriceLists.Next(), 'found third');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T060_PurchStatusFromDraftToActive()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        PurchasePriceList: TestPage "Purchase Price List";
    begin
        // [SCENARIO] Purchase Price list page gets not editable (except Status control) if Status set to Active.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] Price List, where Status is 'Draft'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::" ", '');
        PurchasePriceList.OpenEdit();
        // [GIVEN] Price list page open, where Status is 'Draft', all controls are editable
        Assert.IsTrue(PurchasePriceList.Status.Editable(), 'Status.not Editable');
        Assert.IsTrue(PurchasePriceList.AmountType.Editable(), 'AmountType.not Editable');
        VerifyAllControlsEditable(PurchasePriceList);

        // [WHEN] Change Status to 'Active' (answer 'Yes' to confirmation)
        PurchasePriceList.Status.SetValue(PriceListHeader.Status::Active);

        // [THEN] All fields and lines part are not editable,
        VerifyAllControlsNotEditable(PurchasePriceList);
        // [GIVEN] Controls "Status", "View Columns For" are editable
        Assert.IsTrue(PurchasePriceList.Status.Editable(), 'Active Status.not Editable');
        Assert.IsTrue(PurchasePriceList.AmountType.Editable(), 'AmountType.not Editable');
    end;

    [Test]
    procedure T061_PurchStatusFromInactiveToDraft()
    var
        PriceListHeader: Record "Price List Header";
        PriceListsUI: Codeunit "Price Lists UI";
        PurchasePriceList: TestPage "Purchase Price List";
    begin
        // [SCENARIO] Purchase Price list page gets editable if Status set to Draft.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] Price List, where Status is 'Inactive'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        PriceListHeader.Status := PriceListHeader.Status::Inactive;
        PriceListHeader.Modify();
        PurchasePriceList.OpenEdit();
        // [GIVEN] Price list page open, where Status is Inactive, all controls are not editable 
        VerifyAllControlsNotEditable(PurchasePriceList);
        // [GIVEN] Controls "Status", "View Columns For" are editable
        Assert.IsTrue(PurchasePriceList.Status.Editable(), 'Active Status.not Editable');
        Assert.IsTrue(PurchasePriceList.AmountType.Editable(), 'AmountType.not Editable');

        // [WHEN] Change Status to 'Draft'
        PurchasePriceList.Status.SetValue(PriceListHeader.Status::Draft);

        // [THEN] All fields and lines part are editable
        Assert.IsTrue(PurchasePriceList.Status.Editable(), 'Status.not Editable');
        Assert.IsTrue(PurchasePriceList.AmountType.Editable(), 'AmountType.not Editable');
        VerifyAllControlsEditable(PurchasePriceList);
    end;

    [Test]
    procedure T070_VendorCardPriceListsActionVisibleIfFeatureOn()
    var
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize(true);
        // [GIVEN] Feature is On

        // [WHEN] Open "Vendor Card"
        VendorCard.OpenEdit();

        // [THEN] "Purchase Price Lists" action is visible, old actions are not visible
        Assert.IsTrue(VendorCard.PriceLists.Visible(), 'PriceLists. not Visible');
        Assert.IsFalse(VendorCard.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsFalse(VendorCard.Prices.Visible(), 'Prices. Visible');
        Assert.IsFalse(VendorCard."Line Discounts".Visible(), 'Line Discounts. Visible');
    end;

    [Test]
    procedure T071_VendorCardPriceListsActionNotVisibleIfFeatureOff()
    var
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Vendor Card"
        VendorCard.OpenEdit();

        // [THEN] "Price Lists" actions are not visible, old actions are visible
        Assert.IsFalse(VendorCard.PriceLists.Visible(), 'PriceLists. Visible');
        Assert.IsFalse(VendorCard.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsTrue(VendorCard.Prices.Visible(), 'Prices. not Visible');
        Assert.IsTrue(VendorCard."Line Discounts".Visible(), 'Line Discounts. not Visible');
    end;

    [Test]
    procedure T072_VendorListPriceListsActionVisibleIfFeatureOn()
    var
        VendorList: TestPage "Vendor List";
    begin
        Initialize(true);
        // [GIVEN] Feature is On

        // [WHEN] Open "Vendor List"
        VendorList.OpenEdit();

        // [THEN] "Purchase Price Lists" action is visible, old actions are not visible
        Assert.IsTrue(VendorList.PriceLists.Visible(), 'PriceLists. not Visible');
        Assert.IsFalse(VendorList.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsFalse(VendorList.Prices.Visible(), 'Prices_Prices. Visible');
        Assert.IsFalse(VendorList."Line Discounts".Visible(), 'Prices_LineDiscounts. Visible');
    end;

    [Test]
    procedure T073_VendorListPriceListsActionNotVisibleIfFeatureOff()
    var
        VendorList: TestPage "Vendor List";
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Vendor List"
        VendorList.OpenEdit();

        // [THEN] "Price Lists" actions are not visible, old actions are visible
        Assert.IsFalse(VendorList.PriceLists.Visible(), 'PriceLists. Visible');
        Assert.IsFalse(VendorList.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsTrue(VendorList.Prices.Visible(), 'Prices. not Visible');
        Assert.IsTrue(VendorList."Line Discounts".Visible(), 'Line Discounts. not Visible');
    end;

    [Test]
    procedure T074_PurchPriceListsPageNotOpenIfFeatureOff()
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Purchase Price Lists" page
        asserterror Page.Run(Page::"Purchase Price Lists");
        Assert.ExpectedError(FeatureIsOffErr);
    end;

    [Test]
    procedure T075_PurchPriceListPageNotOpenIfFeatureOff()
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Purchase Price List" page
        asserterror Page.Run(Page::"Purchase Price List");
        Assert.ExpectedError(FeatureIsOffErr);
    end;

    [Test]
    procedure T100_SalesJobPriceListsPageIsNotEditable()
    var
        PriceListHeader: Record "Price List Header";
        SalesJobPriceLists: TestPage "Sales Job Price Lists";
    begin
        Initialize(true);

        // [GIVEN] Price List, where "Source Type" is 'All Jobs', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Jobs", '');

        // [WHEN] Open page "Sales Job Price Lists" without filters
        SalesJobPriceLists.Trap();
        Page.Run(Page::"Sales Job Price Lists");

        // [THEN] The page is not editable, 
        Assert.IsFalse(SalesJobPriceLists.Editable(), 'the page is editable');
        // [THEN] The columns are Description, Status, "Currency Code", "Source Type", "Source No.", "Parent Source No.", "Starting Date", "Ending Date"
        Assert.IsTrue(SalesJobPriceLists.Description.Visible(), 'Description is not visible');
        Assert.IsTrue(SalesJobPriceLists.Status.Visible(), 'Status is not visible');
        Assert.IsTrue(SalesJobPriceLists.SourceType.Visible(), 'SourceType is not visible');
        Assert.IsTrue(SalesJobPriceLists.SourceNo.Visible(), 'SourceNo is not visible');
        Assert.IsTrue(SalesJobPriceLists.ParentSourceNo.Visible(), 'ParentSourceNo is not visible');
        Assert.IsTrue(SalesJobPriceLists."Starting Date".Visible(), 'Starting Date is not visible');
        Assert.IsTrue(SalesJobPriceLists."Ending Date".Visible(), 'Ending Date is not visible');
    end;

    [Test]
    procedure T101_SalesJobPriceListsShowsAllJobs()
    var
        PriceListHeader: Array[5] of Record "Price List Header";
        SalesJobPriceLists: TestPage "Sales Job Price Lists";
    begin
        // [SCENARIO] Sales Job Price lists page shows prices for "All Jobs" if open not from a Job.
        Initialize(true);

        // [GIVEN] Price List #1, where "Source Type" is 'Job Task' 'B' for Job 'A', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"Job Task", '', '');
        // [GIVEN] Price List #2, where "Source Type" is 'All Jobs', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'A', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Purchase, "Price Source Type"::"Job", '');
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::"Job", '');
        // [GIVEN] Price List #5, where "Source Type" is 'Customer', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[5], "Price Type"::Sale, "Price Source Type"::"Customer", '');

        // [WHEN] Open page "Sales Price Lists" without filters
        SalesJobPriceLists.Trap();
        Page.Run(Page::"Sales Job Price Lists");

        // [THEN] There are 3 price lists with source types: "All Jobs", "Job", "Job Task" and "Amount Type" 'Sale'.
        Assert.IsTrue(SalesJobPriceLists.First(), 'not found first');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        Assert.IsTrue(SalesJobPriceLists.Next(), 'not found second');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        Assert.IsTrue(SalesJobPriceLists.Next(), 'not found third');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        Assert.IsFalse(SalesJobPriceLists.Next(), 'found fourth');
    end;

    [Test]
    procedure T102_SalesJobPriceListsPricesFromJobsCard()
    var
        Job: Array[2] of Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: Array[5] of Record "Price List Header";
        JobCard: TestPage "Job Card";
        SalesJobPriceLists: TestPage "Sales Job Price Lists";
    begin
        // [SCENARIO] Sales Job Price lists page shows prices for one job open from the job card.
        Initialize(true);
        // [GIVEN] Jobs 'A' and 'B', Job Task 'C' for Job 'A'
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJobTAsk(Job[1], JobTask);
        LibraryJob.CreateJob(Job[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Jobs'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        // [GIVEN] Price List #2, where "Source Type" is 'Job' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::Job, Job[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[4].Modify();
        // [GIVEN] Price List #5, where "Source Type" is 'Job Task' 'C', Job 'A'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[5], "Price Type"::Sale, "Price Source Type"::"Job Task", Job[1]."No.", JobTask."Job Task No.");

        // [GIVEN] Open Job Card for Job 'A'
        JobCard.OpenEdit();
        JobCard.Filter.SetFilter("No.", Job[1]."No.");

        // [WHEN] Run action "Sales Price Lists (Prices)"
        SalesJobPriceLists.Trap();
        JobCard.SalesPriceLists.Invoke();

        // [THEN] There are 4 price lists - #1, #2, #4, #5
        Assert.IsTrue(SalesJobPriceLists.First(), 'not found first');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        SalesJobPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(SalesJobPriceLists.Next(), 'not found second');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        SalesJobPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsTrue(SalesJobPriceLists.Next(), 'not found third');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        SalesJobPriceLists.SourceNo.AssertEquals(PriceListHeader[4]."Source No.");
        SalesJobPriceLists.ParentSourceNo.AssertEquals('');
        Assert.IsTrue(SalesJobPriceLists.Next(), 'not found 4th');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[5]."Source Type");
        SalesJobPriceLists.SourceNo.AssertEquals(PriceListHeader[5]."Source No.");
        SalesJobPriceLists.ParentSourceNo.AssertEquals(Job[1]."No.");
        Assert.IsFalse(SalesJobPriceLists.Next(), 'found 5th');
    end;

    [Test]
    procedure T103_SalesJobPriceListsDiscountsFromJobsList()
    var
        Job: Array[2] of Record Job;
        PriceListHeader: Array[4] of Record "Price List Header";
        JobList: TestPage "Job List";
        SalesJobPriceLists: TestPage "Sales Job Price Lists";
    begin
        // [SCENARIO] Sales Job Price lists page shows discounts for one job open from the job list.
        Initialize(true);
        // [GIVEN] Job 'A' and 'B'
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJob(Job[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Jobs'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        // [GIVEN] Price List #2, where "Source Type" is 'Job' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::Job, Job[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[4].Modify();

        // [GIVEN] Open Job List for Job 'A'
        JobList.OpenEdit();
        JobList.Filter.SetFilter("No.", Job[1]."No.");

        // [WHEN] Run action "Price Lists (Discounts)"
        SalesJobPriceLists.Trap();
        JobList.SalesPriceListsDiscounts.Invoke();

        // [THEN] There are 2 price lists - #1 and #2
        Assert.IsTrue(SalesJobPriceLists.First(), 'not found first');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        SalesJobPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(SalesJobPriceLists.Next(), 'not found second');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        SalesJobPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsFalse(SalesJobPriceLists.Next(), 'found third');
    end;

    [Test]
    procedure T120_JobCardPriceListsActionVisibleIfFeatureOn()
    var
        JobCard: TestPage "Job Card";
    begin
        Initialize(true);
        // [GIVEN] Feature is On

        // [WHEN] Open "Job Card"
        JobCard.OpenEdit();

        // [THEN] "Sales/Purchase Price Lists" actions are visible, old actions are not visible
        Assert.IsTrue(JobCard.SalesPriceLists.Visible(), 'S.PriceLists. not Visible');
        Assert.IsFalse(JobCard.SalesPriceListsDiscounts.Visible(), 'S.PriceListsDiscounts. Visible');
        Assert.IsTrue(JobCard.PurchasePriceLists.Visible(), 'P.PriceLists. not Visible');
        Assert.IsFalse(JobCard.PurchasePriceListsDiscounts.Visible(), 'P.PriceListsDiscounts. Visible');
        Assert.IsFalse(JobCard."&Resource".Visible(), '"&Resource". Visible');
        Assert.IsFalse(JobCard."&Item".Visible(), '"&Item". Visible');
        Assert.IsFalse(JobCard."&G/L Account".Visible(), '"&G/L Account". Visible');
    end;

    [Test]
    procedure T121_JobCardPriceListsActionNotVisibleIfFeatureOff()
    var
        JobCard: TestPage "Job Card";
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Job Card"
        JobCard.OpenEdit();

        // [THEN] "Price Lists" actions are not visible, old actions are visible
        Assert.IsFalse(JobCard.SalesPriceLists.Visible(), 'S.PriceLists. Visible');
        Assert.IsFalse(JobCard.SalesPriceListsDiscounts.Visible(), 'S.PriceListsDiscounts. Visible');
        Assert.IsFalse(JobCard.PurchasePriceLists.Visible(), 'P.PriceLists. Visible');
        Assert.IsFalse(JobCard.PurchasePriceListsDiscounts.Visible(), 'P.PriceListsDiscounts. Visible');
        Assert.IsTrue(JobCard."&Resource".Visible(), '"&Resource". not Visible');
        Assert.IsTrue(JobCard."&Item".Visible(), '"&Item". not Visible');
        Assert.IsTrue(JobCard."&G/L Account".Visible(), '"&G/L Account". not Visible');
    end;

    [Test]
    procedure T122_JobListPriceListsActionVisibleIfFeatureOn()
    var
        JobList: TestPage "Job List";
    begin
        Initialize(true);
        // [GIVEN] Feature is On

        // [WHEN] Open "Job List"
        JobList.OpenEdit();

        // [THEN] "Sales/Purchase Price Lists" actions are visible, old actions are not visible
        Assert.IsTrue(JobList.SalesPriceLists.Visible(), 'S.PriceLists. not Visible');
        Assert.IsFalse(JobList.SalesPriceListsDiscounts.Visible(), 'S.PriceListsDiscounts. Visible');
        Assert.IsTrue(JobList.PurchasePriceLists.Visible(), 'P.PriceLists. not Visible');
        Assert.IsFalse(JobList.PurchasePriceListsDiscounts.Visible(), 'P.PriceListsDiscounts. Visible');
        Assert.IsFalse(JobList."&Resource".Visible(), '"&Resource". Visible');
        Assert.IsFalse(JobList."&Item".Visible(), '"&Item". Visible');
        Assert.IsFalse(JobList."&G/L Account".Visible(), '"&G/L Account". Visible');
    end;

    [Test]
    procedure T123_JobListPriceListsActionNotVisibleIfFeatureOff()
    var
        JobList: TestPage "Job List";
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Job List"
        JobList.OpenEdit();

        // [THEN] "Price Lists" actions are not visible, old actions are visible
        Assert.IsFalse(JobList.SalesPriceLists.Visible(), 'S.PriceLists. Visible');
        Assert.IsFalse(JobList.SalesPriceListsDiscounts.Visible(), 'S.PriceListsDiscounts. Visible');
        Assert.IsFalse(JobList.PurchasePriceLists.Visible(), 'P.PriceLists. Visible');
        Assert.IsFalse(JobList.PurchasePriceListsDiscounts.Visible(), 'P.PriceListsDiscounts. Visible');
        Assert.IsTrue(JobList."&Resource".Visible(), '"&Resource". not Visible');
        Assert.IsTrue(JobList."&Item".Visible(), '"&Item". not Visible');
        Assert.IsTrue(JobList."&G/L Account".Visible(), '"&G/L Account". not Visible');
    end;

    [Test]
    procedure T150_PurchaseJobPriceListsPageIsNotEditable()
    var
        PriceListHeader: Record "Price List Header";
        PurchaseJobPriceLists: TestPage "Purchase Job Price Lists";
    begin
        Initialize(true);

        // [GIVEN] Price List, where "Source Type" is 'All Jobs', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');

        // [WHEN] Open page "Purchase Job Price Lists" without filters
        PurchaseJobPriceLists.Trap();
        Page.Run(Page::"Purchase Job Price Lists");

        // [THEN] The page is not editable, 
        Assert.IsFalse(PurchaseJobPriceLists.Editable(), 'the page is editable');
        // [THEN] The columns are Description, Status, "Currency Code", "Source Type", "Source No.", "Parent Source No.","Starting Date", "Ending Date"
        Assert.IsTrue(PurchaseJobPriceLists.Description.Visible(), 'Description is not visible');
        Assert.IsTrue(PurchaseJobPriceLists.Status.Visible(), 'Status is not visible');
        Assert.IsTrue(PurchaseJobPriceLists.SourceType.Visible(), 'SourceType is not visible');
        Assert.IsTrue(PurchaseJobPriceLists.SourceNo.Visible(), 'SourceNo is not visible');
        Assert.IsTrue(PurchaseJobPriceLists.ParentSourceNo.Visible(), 'ParentSourceNo is not visible');
        Assert.IsTrue(PurchaseJobPriceLists."Starting Date".Visible(), 'Starting Date is not visible');
        Assert.IsTrue(PurchaseJobPriceLists."Ending Date".Visible(), 'Ending Date is not visible');
    end;

    [Test]
    procedure T151_PurchaseJobPriceListsShowsAllJobs()
    var
        PriceListHeader: Array[5] of Record "Price List Header";
        PurchaseJobPriceLists: TestPage "Purchase Job Price Lists";
    begin
        // [SCENARIO] Purchase Job Price lists page shows prices for "All Jobs" if open not from a Job.
        Initialize(true);

        // [GIVEN] Price List #1, where "Source Type" is 'Job Task' 'B' for Job 'A', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::"Job Task", '', '');
        // [GIVEN] Price List #2, where "Source Type" is 'All Jobs', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'A', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::"Job", '');
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Purchase, "Price Source Type"::"Job", '');
        // [GIVEN] Price List #5, where "Source Type" is 'Vendor', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[5], "Price Type"::Purchase, "Price Source Type"::"Vendor", '');

        // [WHEN] Open page "Purchase Job Price Lists" without filters
        PurchaseJobPriceLists.Trap();
        Page.Run(Page::"Purchase Job Price Lists");

        // [THEN] There are 3 price lists with source types: "All Jobs", "Job", "Job Task" and "Amount Type" 'Sale'.
        Assert.IsTrue(PurchaseJobPriceLists.First(), 'not found first');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        Assert.IsTrue(PurchaseJobPriceLists.Next(), 'not found second');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        Assert.IsTrue(PurchaseJobPriceLists.Next(), 'not found third');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        Assert.IsFalse(PurchaseJobPriceLists.Next(), 'found fourth');
    end;

    [Test]
    procedure T152_PurchaseJobPriceListsPricesFromJobCard()
    var
        Job: Array[2] of Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: Array[5] of Record "Price List Header";
        JobCard: TestPage "Job Card";
        PurchaseJobPriceLists: TestPage "Purchase Job Price Lists";
    begin
        // [SCENARIO] Purchase Price lists page shows prices for one Job open from the Job card.
        Initialize(true);
        // [GIVEN] Jobs 'A' and 'B', Job  Task 'C' for Job 'A'
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJobTask(Job[1], JobTask);
        LibraryJob.CreateJob(Job[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Jobs'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');
        // [GIVEN] Price List #2, where "Source Type" is 'Job' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Purchase, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Purchase, "Price Source Type"::Job, Job[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Purchase, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[4].Modify();
        // [GIVEN] Price List #5, where "Source Type" is 'Job Task' 'C', 'Job' 'A'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[5], "Price Type"::Purchase, "Price Source Type"::"Job Task", Job[1]."No.", JobTask."Job Task No.");

        // [GIVEN] Open Job Card for Job 'A'
        JobCard.OpenEdit();
        JobCard.Filter.SetFilter("No.", Job[1]."No.");

        // [WHEN] Run action "Price Lists (Prices)"
        PurchaseJobPriceLists.Trap();
        JobCard.PurchasePriceLists.Invoke();

        // [THEN] There are 4 price lists - #1, #2, #4, #5
        Assert.IsTrue(PurchaseJobPriceLists.First(), 'not found first');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        PurchaseJobPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(PurchaseJobPriceLists.Next(), 'not found second');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        PurchaseJobPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsTrue(PurchaseJobPriceLists.Next(), 'not found third');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        PurchaseJobPriceLists.SourceNo.AssertEquals(PriceListHeader[4]."Source No.");
        PurchaseJobPriceLists.ParentSourceNo.AssertEquals('');
        Assert.IsTrue(PurchaseJobPriceLists.Next(), 'not found 4th');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[5]."Source Type");
        PurchaseJobPriceLists.SourceNo.AssertEquals(PriceListHeader[5]."Source No.");
        PurchaseJobPriceLists.ParentSourceNo.AssertEquals(Job[1]."No.");
        Assert.IsFalse(PurchaseJobPriceLists.Next(), 'found 5th');
    end;

    [Test]
    procedure T153_PurchaseJobPriceListsDiscountsFromJobList()
    var
        Job: Array[2] of Record Job;
        PriceListHeader: Array[4] of Record "Price List Header";
        JobList: TestPage "Job List";
        PurchaseJobPriceLists: TestPage "Purchase Job Price Lists";
    begin
        // [SCENARIO] Purchase Price lists page shows discounts for one Job open from the Job list.
        Initialize(true);
        // [GIVEN] Jobs 'A' and 'B'
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJob(Job[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Jobs'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');
        // [GIVEN] Price List #2, where "Source Type" is 'Job' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Purchase, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Purchase, "Price Source Type"::Job, Job[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Purchase, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[4].Modify();

        // [GIVEN] Open Job List for Job 'A'
        JobList.OpenEdit();
        JobList.Filter.SetFilter("No.", Job[1]."No.");

        // [WHEN] Run action "Price Lists (Discounts)"
        PurchaseJobPriceLists.Trap();
        JobList.PurchasePriceListsDiscounts.Invoke();

        // [THEN] There are 2 price lists - #1 and #2
        Assert.IsTrue(PurchaseJobPriceLists.First(), 'not found first');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        PurchaseJobPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(PurchaseJobPriceLists.Next(), 'not found second');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        PurchaseJobPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsFalse(PurchaseJobPriceLists.Next(), 'found third');
    end;

    [Test]
    procedure T170_ShowPriceListLinesForItemWithDiscGroup()
    var
        Item: Record Item;
        ItemDiscountGroup: Record "Item Discount Group";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
        ItemDiscGroupPriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Item]
        Initialize(true);
        // [GIVEN] Item 'X', where "Item Disc. Group" is 'A'
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        Item."Item Disc. Group" := ItemDiscountGroup.Code;
        Item.Modify();
        // [GIVEN] 12 Price list lines: combinations of Sales/Purchase, Any/Price/Discount, Customer/Vendor/Job
        CreatePriceLines(PriceListLine, "Price Asset Type"::Item, Item."No.");
        // [GIVEN] 2 sales discount lines for "Item Disc. Group" 'A'
        CreatePriceLines(ItemDiscGroupPriceListLine, "Price Asset Type"::"Item Discount Group", Item."Item Disc. Group");

        // [WHEN] Show sales prices&discounts for Item 'X'
        PriceListLineReview.Trap();
        Item.ShowPriceListLines("Price Type"::Sale, "Price Amount Type"::Any);

        // [THEN] Open Price List Line Review page, where are 6 lines #1-#6 for Item and 2 for Item Disc.Group (sorted by Code)
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[1]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[3]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[5]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(ItemDiscGroupPriceListLine[1]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[2]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[4]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[6]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(ItemDiscGroupPriceListLine[2]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 9th line');
    end;

    [Test]
    procedure T171_ShowPriceListLinesForItemDiscGroup()
    var
        ItemDiscountGroup: Record "Item Discount Group";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Item Discount Group]
        Initialize(true);
        // [GIVEN] ItemDiscountGroup 'X'
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        // [GIVEN] 2 sales discount lines for "Item Disc. Group" 'A'
        CreatePriceLines(PriceListLine, "Price Asset Type"::"Item Discount Group", ItemDiscountGroup.Code);

        // [WHEN] Show sales discounts for ItemDiscountGroup 'X'
        PriceListLineReview.Trap();
        ItemDiscountGroup.ShowPriceListLines("Price Type"::Sale, "Price Amount Type"::Discount);

        // [THEN] Open Price List Line Review page, where are 2 sales discount lines (sorted by Code)
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[1]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[2]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 3rd line');
    end;

    [Test]
    procedure T172_ShowPriceListLinesForServiceCost()
    var
        ServiceCost: Record "Service Cost";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Service Cost]
        Initialize(true);
        // [GIVEN] ServiceCost 'X'
        LibraryService.CreateServiceCost(ServiceCost);
        // [GIVEN] 12 Price list lines: combinations of Sales/Purchase, Any/Price/Discount, Customer/Vendor/Job
        CreatePriceLines(PriceListLine, "Price Asset Type"::"Service Cost", ServiceCost.Code);

        // [WHEN] Show sales prices for ServiceCost 'X'
        PriceListLineReview.Trap();
        ServiceCost.ShowPriceListLines("Price Type"::Sale, "Price Amount Type"::Price);

        // [THEN] Open Price List Line Review page, where are 4 sales price lines #1-4 (sorted by Code)
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[1]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[3]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[2]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[4]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 5th line');
    end;

    [Test]
    procedure T173_ShowPriceListLinesForResource()
    var
        Resource: Record Resource;
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Resource]
        Initialize(true);
        // [GIVEN] Resource 'X'
        LibraryResource.CreateResource(Resource, '');
        // [GIVEN] 12 Price list lines: combinations of Sales/Purchase, Any/Price/Discount, Customer/Vendor/Job
        CreatePriceLines(PriceListLine, "Price Asset Type"::Resource, Resource."No.");

        // [WHEN] Show purchase prices for Resource 'X'
        PriceListLineReview.Trap();
        Resource.ShowPriceListLines("Price Type"::Purchase, "Price Amount Type"::Price);

        // [THEN] Open Price List Line Review page, where are 4 purchase price lines #7-10 (sorted by Code)
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[7]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[9]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[8]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[10]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 5th line');
    end;

    [Test]
    procedure T174_ShowPriceListLinesForResourceGroup()
    var
        ResourceGroup: Record "Resource Group";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Resource Group]
        Initialize(true);
        // [GIVEN] Resource Group 'X'
        LibraryResource.CreateResourceGroup(ResourceGroup);
        // [GIVEN] 12 Price list lines: combinations of Sales/Purchase, Any/Price/Discount, Customer/Vendor/Job
        CreatePriceLines(PriceListLine, "Price Asset Type"::"Resource Group", ResourceGroup."No.");

        // [WHEN] Show purchase discounts for Resource 'X'
        PriceListLineReview.Trap();
        ResourceGroup.ShowPriceListLines("Price Type"::Purchase, "Price Amount Type"::Discount);

        // [THEN] Open Price List Line Review page, where are 4 purchase discount lines #7,8,11,12 (sorted by Code)
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[7]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[11]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[8]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[12]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 5th line');
    end;

    [Test]
    procedure T175_ShowPriceListLinesForGLAcount()
    var
        GLAccount: Record "G/L Account";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [G/L Account]
        Initialize(true);
        // [GIVEN] GLAccount 'X'
        LibraryERM.CreateGLAccount(GLAccount);
        // [GIVEN] 12 Price list lines: combinations of Sales/Purchase, Any/Price/Discount, Customer/Vendor/Job
        CreatePriceLines(PriceListLine, "Price Asset Type"::"G/L Account", GLAccount."No.");

        // [WHEN] Show purchase prices&discounts for GLAccount 'X'
        PriceListLineReview.Trap();
        GLAccount.ShowPriceListLines("Price Type"::Purchase, "Price Amount Type"::Any);

        // [THEN] Open Price List Line Review page, where are 6 purchase lines #7-#12 (sorted by Code)
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[7]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[9]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[11]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[8]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[10]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[12]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 7th line');
    end;

    [Test]
    procedure T180_ShowPriceListLinesPriceForItemVendor()
    var
        ItemVendor: Record "Item Vendor";
        VendorItemCatalog: TestPage "Vendor Item Catalog";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Item Vendor]
        Initialize(true);
        // [GIVEN] Item Vendor 'I'-'V', where Item 'I', Vendor 'V'
        CreateItemVendor(ItemVendor, false);
        // [GIVEN] 6 Price list lines: combinations of Sales/Purchase, Price/Discount, Customer/Vendor
        CreatePriceLines(PriceListLine, ItemVendor);

        // [GIVEN] Open "Vendor Item Catalog" on record 'I'-'V'
        VendorItemCatalog.OpenView();
        VendorItemCatalog.Filter.SetFilter("Item No.", ItemVendor."Item No.");

        // [WHEN] Show purchase prices for 'I'-'V'
        PriceListLineReview.Trap();
        VendorItemCatalog.Prices.Invoke();

        // [THEN] Open Price List Line Review page, where are two purchase lines #1, #7
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[1]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[7]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 3rd line');
    end;

    [Test]
    procedure T181_ShowPriceListLinesDiscountForItemVendor()
    var
        ItemVendor: Record "Item Vendor";
        ItemVendorCatalog: TestPage "Item Vendor Catalog";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Item Vendor]
        Initialize(true);
        // [GIVEN] Item Vendor 'I'-'V', where Item 'I', Vendor 'V'
        CreateItemVendor(ItemVendor, false);
        // [GIVEN] 12 Price list lines: combinations of Sales/Purchase, Price/Discount, Customer/Vendor
        CreatePriceLines(PriceListLine, ItemVendor);

        // [GIVEN] Open "Item Vendor Catalog" on record 'I'-'V'
        ItemVendorCatalog.OpenView();
        ItemVendorCatalog.Filter.SetFilter("Item No.", ItemVendor."Item No.");

        // [WHEN] Show purchase prices for 'I'-'V'
        PriceListLineReview.Trap();
        ItemVendorCatalog.Discounts.Invoke();

        // [THEN] Open Price List Line Review page, where are 2 purchase lines #2, #8
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[2]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[8]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 3rd line');
    end;

    [Test]
    procedure T182_ShowPriceListLinesPriceForItemVariantVendor()
    var
        ItemVendor: Record "Item Vendor";
        ItemVendorCatalog: TestPage "Item Vendor Catalog";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Item Vendor]
        Initialize(true);
        // [GIVEN] Item Vendor 'I'-'V', where Item 'I', Vendor 'V', "Variant Code" 'VC'
        CreateItemVendor(ItemVendor, true);
        // [GIVEN] 6 Price list lines: combinations of Sales/Purchase, Price/Discount, Customer/Vendor
        CreatePriceLines(PriceListLine, ItemVendor);

        // [GIVEN] Open "Item Vendor Catalog" on record 'I'-'V'
        ItemVendorCatalog.OpenView();
        ItemVendorCatalog.Filter.SetFilter("Item No.", ItemVendor."Item No.");

        // [WHEN] Show purchase prices for 'I'-'V'
        PriceListLineReview.Trap();
        ItemVendorCatalog.Prices.Invoke();

        // [THEN] Open Price List Line Review page, where is one purchase line #7
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[7]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 2nd line');
    end;

    [Test]
    procedure T183_ShowPriceListLinesDiscountForItemVariantVendor()
    var
        ItemVendor: Record "Item Vendor";
        VendorItemCatalog: TestPage "Vendor Item Catalog";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Item Vendor]
        Initialize(true);
        // [GIVEN] Item Vendor 'I'-'V', where Item 'I', Vendor 'V', "Variant Code" 'VC'
        CreateItemVendor(ItemVendor, true);
        // [GIVEN] 12 Price list lines: combinations of Sales/Purchase, Price/Discount, Customer/Vendor
        CreatePriceLines(PriceListLine, ItemVendor);

        // [GIVEN] Open "Vendor Item Catalog" on record 'I'-'V'
        VendorItemCatalog.OpenView();
        VendorItemCatalog.Filter.SetFilter("Item No.", ItemVendor."Item No.");

        // [WHEN] Show purchase prices for 'I'-'V'
        PriceListLineReview.Trap();
        VendorItemCatalog.Discounts.Invoke();

        // [THEN] Open Price List Line Review page, where is one purchase line #8
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[8]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 2nd line');
    end;

    local procedure Initialize(Enable: Boolean)
    var
        PriceListHeader: Record "Price List Header";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Price Lists UI");

        LibraryPriceCalculation.EnableExtendedPriceCalculation(Enable);
        PriceListHeader.ModifyAll(Status, PriceListHeader.Status::Draft);
        PriceListHeader.DeleteAll(true);

        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Price Lists UI");

        FillPriceListNos();

        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Price Lists UI");
    end;

    local procedure CreateItemVendor(var ItemVendor: Record "Item Vendor"; FillVariantCode: Boolean)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Vendor: Record Vendor;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendorWithVATRegNo(Vendor);
        LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");
        if FillVariantCode then
            ItemVendor.Rename(Vendor."No.", Item."No.", LibraryInventory.CreateItemVariant(ItemVariant, Item."No."));
    end;

    local procedure CreatePriceLines(var PriceListLine: array[12] of Record "Price List Line"; ItemVendor: Record "Item Vendor")
    var
        i: Integer;
    begin
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], '1', "Price Type"::Purchase, "Price Source Type"::Vendor, ItemVendor."Vendor No.",
            "Price Amount Type"::Price, "Price Asset Type"::Item, ItemVendor."Item No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], '2', "Price Type"::Purchase, "Price Source Type"::Vendor, ItemVendor."Vendor No.",
            "Price Amount Type"::Discount, "Price Asset Type"::Item, ItemVendor."Item No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[3], '3', "Price Type"::Purchase, "Price Source Type"::"All Vendors", '',
            "Price Amount Type"::Price, "Price Asset Type"::Item, ItemVendor."Item No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[4], '4', "Price Type"::Purchase, "Price Source Type"::"All Vendors", '',
            "Price Amount Type"::Discount, "Price Asset Type"::Item, ItemVendor."Item No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[5], '5', "Price Type"::Sale, "Price Source Type"::"All Customers", '',
            "Price Amount Type"::Price, "Price Asset Type"::Item, ItemVendor."Item No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[6], '6', "Price Type"::Sale, "Price Source Type"::"All Customers", '',
            "Price Amount Type"::Discount, "Price Asset Type"::Item, ItemVendor."Item No.");
        for i := 1 to 2 do begin
            PriceListLine[i + 6] := PriceListLine[i];
            PriceListLine[i + 6]."Price List Code" := Format(i + 6);
            PriceListLine[i + 6]."Variant Code" := ItemVendor."Variant Code";
            PriceListLine[i + 6].Insert();
        end;
    end;

    local procedure CreatePriceLines(var PriceListLine: array[12] of Record "Price List Line"; AssetType: Enum "Price Asset Type"; AssetNo: Code[20])
    var
        PriceType: Enum "Price Type";
        SourceType: Enum "Price Source Type";
        AmountType: array[3] of Enum "Price Amount Type";
        PriceListCode: Code[20];
        I: Integer;
        LineNo: Integer;
    begin
        AmountType[1] := "Price Amount Type"::Any;
        AmountType[2] := "Price Amount Type"::Price;
        AmountType[3] := "Price Amount Type"::Discount;
        SourceType := SourceType::"All Customers";
        for PriceType := PriceType::Sale to PriceType::Purchase do begin
            for I := 1 to ArrayLen(AmountType) do
                if ((AmountType[I] = "Price Amount Type"::Discount) and (PriceType = PriceType::Sale)) or
                    (AssetType <> AssetType::"Item Discount Group")
                then begin
                    LineNo += 1;
                    PriceListCode :=
                        StrSubstNo('%1 %2 %3 %4', PriceType.AsInteger(), SourceType.AsInteger(), AmountType[I].AsInteger(), AssetType.AsInteger());
                    LibraryPriceCalculation.CreatePriceListLine(
                        PriceListLine[LineNo], PriceListCode, PriceType, SourceType, '', AmountType[I], AssetType, AssetNo);
                    LineNo += 1;
                    PriceListCode :=
                        StrSubstNo('%1 %2 %3 %4', PriceType.AsInteger(), SourceType::"All Jobs".AsInteger(), AmountType[I].AsInteger(), AssetType.AsInteger());
                    LibraryPriceCalculation.CreatePriceListLine(
                        PriceListLine[LineNo], PriceListCode, PriceType, SourceType::"All Jobs", '', AmountType[I], AssetType, AssetNo);
                end;
            SourceType := SourceType::"All Vendors";
        end;
    end;

    local procedure FillPriceListNos()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        JobsSetup: Record "Jobs Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('SAL'));
        SalesReceivablesSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('PUR'));
        PurchasesPayablesSetup.Modify();

        JobsSetup.Get();
        JobsSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('JOB'));
        JobsSetup.Modify();
    end;

    local procedure VerifyAllControlsEditable(var SalesPriceList: TestPage "Sales Price List")
    begin
        Assert.IsTrue(SalesPriceList.Code.Editable(), 'Code.not Editable');
        Assert.IsTrue(SalesPriceList.Description.Editable(), 'Description.not Editable');
        Assert.IsTrue(SalesPriceList.SourceType.Editable(), 'SourceType.not Editable');
        Assert.IsTrue(SalesPriceList.SourceNo.Editable(), 'SourceNo.not Editable');
        Assert.IsTrue(SalesPriceList.StartingDate.Editable(), 'StartingDate.not Editable');
        Assert.IsTrue(SalesPriceList.EndingDate.Editable(), 'EndingDate.not Editable');
        Assert.IsTrue(SalesPriceList.VATBusPostingGrPrice.Editable(), 'VATBusPostingGrPrice.not Editable');
        Assert.IsTrue(SalesPriceList.PriceIncludesVAT.Editable(), 'PriceIncludesVAT.not Editable');
        Assert.IsTrue(SalesPriceList.AllowInvoiceDisc.Editable(), 'AllowInvoiceDisc.not Editable');
        Assert.IsTrue(SalesPriceList.AllowLineDisc.Editable(), 'AllowLineDisc.not Editable');
        Assert.IsTrue(SalesPriceList.Lines.Editable(), 'Lines.not Editable');
        Assert.IsTrue(SalesPriceList.SuggestLines.Enabled(), 'SuggestLines.Enabled');
        Assert.IsTrue(SalesPriceList.CopyLines.Enabled(), 'CopyLines.Enabled');
    end;

    local procedure VerifyAllControlsEditable(var PurchasePriceList: TestPage "Purchase Price List")
    begin
        Assert.IsTrue(PurchasePriceList.Code.Editable(), 'Code.not Editable');
        Assert.IsTrue(PurchasePriceList.Description.Editable(), 'Description.not Editable');
        Assert.IsTrue(PurchasePriceList.SourceType.Editable(), 'SourceType.not Editable');
        Assert.IsTrue(PurchasePriceList.SourceNo.Editable(), 'SourceNo.not Editable');
        Assert.IsTrue(PurchasePriceList.StartingDate.Editable(), 'StartingDate.not Editable');
        Assert.IsTrue(PurchasePriceList.EndingDate.Editable(), 'EndingDate.not Editable');
        Assert.IsTrue(PurchasePriceList.PriceIncludesVAT.Editable(), 'PriceIncludesVAT.not Editable');
        Assert.IsTrue(PurchasePriceList.AllowLineDisc.Editable(), 'AllowLineDisc.not Editable');
        Assert.IsTrue(PurchasePriceList.Lines.Editable(), 'Lines.not Editable');
        Assert.IsTrue(PurchasePriceList.SuggestLines.Enabled(), 'SuggestLines.Enabled');
        Assert.IsTrue(PurchasePriceList.CopyLines.Enabled(), 'CopyLines.Enabled');
    end;

    local procedure VerifyAllControlsNotEditable(var SalesPriceList: TestPage "Sales Price List")
    begin
        Assert.IsFalse(SalesPriceList.Code.Editable(), 'Code.Editable');
        Assert.IsFalse(SalesPriceList.Description.Editable(), 'Description.Editable');
        Assert.IsFalse(SalesPriceList.SourceType.Editable(), 'SourceType.Editable');
        Assert.IsFalse(SalesPriceList.SourceNo.Editable(), 'SourceNo.Editable');
        Assert.IsFalse(SalesPriceList.StartingDate.Editable(), 'StartingDate.Editable');
        Assert.IsFalse(SalesPriceList.EndingDate.Editable(), 'EndingDate.Editable');
        Assert.IsFalse(SalesPriceList.VATBusPostingGrPrice.Editable(), 'VATBusPostingGrPrice.Editable');
        Assert.IsFalse(SalesPriceList.PriceIncludesVAT.Editable(), 'PriceIncludesVAT.Editable');
        Assert.IsFalse(SalesPriceList.AllowInvoiceDisc.Editable(), 'AllowInvoiceDisc.Editable');
        Assert.IsFalse(SalesPriceList.AllowLineDisc.Editable(), 'AllowLineDisc.Editable');
        // Assert.IsFalse(SalesPriceList.Lines.Editable(), 'Lines.Editable'); test framework defect?
        Assert.IsFalse(SalesPriceList.SuggestLines.Enabled(), 'SuggestLines.Enabled');
        Assert.IsFalse(SalesPriceList.CopyLines.Enabled(), 'CopyLines.Enabled');
    end;

    local procedure VerifyAllControlsNotEditable(var PurchasePriceList: TestPage "Purchase Price List")
    begin
        Assert.IsFalse(PurchasePriceList.Code.Editable(), 'Code.Editable');
        Assert.IsFalse(PurchasePriceList.Description.Editable(), 'Description.Editable');
        Assert.IsFalse(PurchasePriceList.SourceType.Editable(), 'SourceType.Editable');
        Assert.IsFalse(PurchasePriceList.SourceNo.Editable(), 'SourceNo.Editable');
        Assert.IsFalse(PurchasePriceList.StartingDate.Editable(), 'StartingDate.Editable');
        Assert.IsFalse(PurchasePriceList.EndingDate.Editable(), 'EndingDate.Editable');
        Assert.IsFalse(PurchasePriceList.PriceIncludesVAT.Editable(), 'PriceIncludesVAT.Editable');
        Assert.IsFalse(PurchasePriceList.AllowLineDisc.Editable(), 'AllowLineDisc.Editable');
        // Assert.IsFalse(PurchasePriceList.Lines.Editable(), 'Lines.Editable'); test framework defect?
        Assert.IsFalse(PurchasePriceList.SuggestLines.Enabled(), 'SuggestLines.Enabled');
        Assert.IsFalse(PurchasePriceList.CopyLines.Enabled(), 'CopyLines.Enabled');
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure PriceListLineReviewModalHandler(var PriceListLineReview: TestPage "Price List Line Review")
    begin
        if PriceListLineReview.First() then
            repeat
                LibraryVariableStorage.Enqueue(PriceListLineReview."Price List Code");
            until not PriceListLineReview.Next();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Price List Lines", 'OnAfterSetSubFormLinkFilter', '', false, false)]
    local procedure OnAfterSetSalesSubFormLinkFilter(var Sender: Page "Price List Lines"; var SkipActivate: Boolean);
    begin
        SkipActivate := true;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Price List Lines", 'OnAfterSetSubFormLinkFilter', '', false, false)]
    local procedure OnAfterSetPurchSubFormLinkFilter(var Sender: Page "Purchase Price List Lines"; var SkipActivate: Boolean);
    begin
        SkipActivate := true;
    end;
}