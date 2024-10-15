codeunit 141052 "Price List Line Cost Plus"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Price] [Cost-plus %]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        UnitPriceMustBeSameMsg: Label 'Unit Price must be same.';
        IsInitialized: Boolean;

        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    [Test]
    [Scope('OnPrem')]
    procedure SingleCustomerSalesPriceCostPlusWithoutDate()
    var
        PriceListLine: Record "Price List Line";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus for single customer when Starting Date and Ending Date field is not filled on the Sales Price.
        Initialize();
        // Setup: Create Customer.
        CustomerNo := CreateCustomer;
        CustomerSalesPriceCostPlusStartingdate(PriceListLine."Source Type"::Customer, CustomerNo, CustomerNo, 0D);  // Starting Date - 0D.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllCustomerSalesPriceCostPlusWithDate()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus for all customers if Posting Date specified on the sales Order is within the date range specified on the Sales Price.
        Initialize();

        // Setup.
        CustomerSalesPriceCostPlusStartingdate(PriceListLine."Source Type"::"All Customers", '', CreateCustomer, WorkDate);  // Sales Code - blank and Starting Date - Workdate.
    end;

    local procedure CustomerSalesPriceCostPlusStartingdate(SourceType: Enum "Price Source Type"; SourceNo: Code[20]; CustomerNo: Code[20]; StartingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
    begin
        // Create Sales Price with Cost Plus.
        CreateSalesPriceWithCostPlus(PriceListLine, SourceType, SourceNo, StartingDate, LibraryRandom.RandDec(10, 2));  // Random Minimum Quantity.

        // Exercise: Create Sales Order.
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Order, CustomerNo, '', PriceListLine."Asset No.", PriceListLine."Minimum Quantity");  // Campaign Number - blank.

        // Verify: Verify Unit Price on Sales line with Unit Price of Sales Price.
        Assert.AreNearlyEqual(
          PriceListLine."Unit Price", SalesLine."Unit Price", LibraryERM.GetAmountRoundingPrecision, UnitPriceMustBeSameMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleCustomerSalesPriceCostPlusWithBelowMinQty()
    var
        PriceListLine: Record "Price List Line";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus for single customer when Quantity on Sales Line less than Minimum Quantity.
        Initialize();
        // Setup: Create Customer.
        CustomerNo := CreateCustomer;
        CustomerSalesPriceCostPlusDateRange(PriceListLine."Source Type"::Customer, CustomerNo, CustomerNo, 0D, LibraryRandom.RandInt(5));  // Starting Date - 0D and Random Quantity.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleCustomerSalesPriceCostPlusWithDateDiffCustomer()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus for single customer when Starting Date and Ending Date field is not filled on the Sales Price and different customer on sales.
        Initialize();

        // Setup.
        CustomerSalesPriceCostPlusDateRange(PriceListLine."Source Type"::Customer, CreateCustomer, CreateCustomer, 0D, 0);  // Starting Date - 0D and Quantity - 0.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllCustomerSalesPriceCostPlusWithOutsideDateRange()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus for all customers if Posting Date specified on the sales order is not within the date range specified on the Sales Price.
        Initialize();

        // Setup.
        CustomerSalesPriceCostPlusDateRange(
          PriceListLine."Source Type"::"All Customers", '', CreateCustomer,
          CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate), 0);   // Sales Code - blank, Starting Date - less than Workdate and Quantity - 0.
    end;

    local procedure CustomerSalesPriceCostPlusDateRange(SourceType: Enum "Price Source Type"; SourceNo: Code[20]; CustomerNo: Code[20]; StartingDate: Date; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
    begin
        // Create Sales Price with Cost Plus.
        CreateSalesPriceWithCostPlus(PriceListLine, SourceType, SourceNo, StartingDate, LibraryRandom.RandDecInDecimalRange(10, 20, 2));  // Random Minimum Quantity.


        // Exercise: Create Sales Order.
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Order, CustomerNo, '', PriceListLine."Asset No.", PriceListLine."Minimum Quantity" - Quantity);  // Campaign Number - blank and Sales Line Quantity less than Minimum Quantity of Sales Price.

        // Verify: Verify Unit Price on Sales line with Unit Price of Item.
        VerifyUnitPriceOnSalesLine(PriceListLine."Asset No.", SalesLine."Unit Price", 0);  // Discount Amount - 0.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure CampaignSalesPriceCostPlus()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        CustomerNo: Code[20];
        ContactNo: Code[20];
        CampaignNo: Code[20];
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus for Campaign.
        Initialize();

        // Setup: Create Contact and Customer, create and activate Campaign, create Sales Price with Cost Plus using Campaign.
        ContactNo := CreateContactWithCustomer();
        CustomerNo := FindCustomerFromContactBusinessRelation(ContactNo);
        CampaignNo := CreateAndActivateCampaign(ContactNo);
        CreateSalesPriceWithCostPlus(
          PriceListLine, PriceListLine."Source Type"::Campaign, CampaignNo, WorkDate, LibraryRandom.RandDec(10, 2));  // Random Minimum Quantity.


        // Exercise: Create Sales Order.
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Order, CustomerNo, CampaignNo, PriceListLine."Asset No.", PriceListLine."Minimum Quantity");

        // Verify: Verify Unit Price on Sales line with Unit Price of Sales Price.
        Assert.AreNearlyEqual(
          PriceListLine."Unit Price", SalesLine."Unit Price", LibraryERM.GetAmountRoundingPrecision, UnitPriceMustBeSameMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleCustomerSalesPriceCostPlusMultipleLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesLine3: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceListLine2: Record "Price List Line";
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus for single customer using different Quantity.
        Initialize();

        // Setup: Create multiple Sales Price for single customer.
        CreateSalesPriceWithCostPlus(
          PriceListLine, PriceListLine."Source Type"::Customer, CreateCustomer, 0D, LibraryRandom.RandDecInDecimalRange(10, 50, 2));  // Starting Date - 0D and Random Minimum Quantity.
        CreateSalesPriceWithCostPlus(
          PriceListLine2, PriceListLine2."Source Type"::Customer, PriceListLine."Source No.", 0D, LibraryRandom.RandDecInDecimalRange(100, 200, 2));  // Starting Date - 0D and Random Minimum Quantity.


        // Exercise: Create Sales Invoice with multiple line with different Quantitiy.
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Invoice, PriceListLine."Source No.", '', PriceListLine."Asset No.",
          PriceListLine."Minimum Quantity" - LibraryRandom.RandInt(5));  // Reduce Sales line - Quantity.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, PriceListLine."Asset No.", PriceListLine."Minimum Quantity");
        LibrarySales.CreateSalesLine(SalesLine3, SalesHeader, SalesLine3.Type::Item, PriceListLine2."Asset No.", PriceListLine2."Minimum Quantity");

        // Verify: Verify Unit Price on multiple Sales line with Unit Price of Sales Price and Item.
        VerifyUnitPriceOnSalesLine(PriceListLine."Asset No.", SalesLine."Unit Price", 0);  // Discount Amount - 0.
        Assert.AreNearlyEqual(
          PriceListLine."Unit Price", SalesLine2."Unit Price", LibraryERM.GetAmountRoundingPrecision, UnitPriceMustBeSameMsg);
        Assert.AreNearlyEqual(
          PriceListLine2."Unit Price", SalesLine3."Unit Price", LibraryERM.GetAmountRoundingPrecision, UnitPriceMustBeSameMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleCustomerSalesPriceWithDiscountAmtAndCostPlus()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Discount Amount are blank on the Sales Price when update Cost-plus.
        Initialize();

        // Setup: Create Sales Price with Discount Amount.
        CreateSalesPriceWithDiscountAmount(PriceListLine, PriceListLine."Source Type"::Customer, CreateCustomer, 0D);  // Starting Date - 0D.


        // Exercise.
        UpdateCostPlusPctOnSalesPrice(PriceListLine);

        // Verify: Verify after updating Cost-plus Pct on Sales Price, Discount Amount change to zero value.
        PriceListLine.Find();
        PriceListLine.TestField("Discount Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleCustomerSalesPriceDiscountAmtWithoutDate()
    var
        PriceListLine: Record "Price List Line";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Calculate Sales Price based on discount allowed to single customer when Starting Date and ending Date fields are blank on the Sales Price.
        Initialize();

        // Setup: Create Customer.
        CustomerNo := CreateCustomer;
        CustomerSalesPriceDiscountAmtWithStartingDate(PriceListLine."Source Type"::Customer, CustomerNo, CustomerNo, 0D);  // Starting Date - 0D.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleCustomerSalesPriceDiscountAmtWithDate()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Calculate Sales Price based on discount allowed for all customers if Posting Date specified on the sales Invoice is within the date range specified on the Sales Price.
        Initialize();

        // Setup.
        CustomerSalesPriceDiscountAmtWithStartingDate(PriceListLine."Source Type"::"All Customers", '', CreateCustomer, WorkDate);  // Sales Code - blank and Starting Date - Workdate.
    end;

    local procedure CustomerSalesPriceDiscountAmtWithStartingDate(SourceType: Enum "Price Source Type"; SourceNo: Code[20]; CustomerNo: Code[20]; StartingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
    begin
        // Create Sales Price with Discount Amount.
        CreateSalesPriceWithDiscountAmount(PriceListLine, SourceType, SourceNo, StartingDate);


        // Exercise: Create Sales Invoice.
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo, '', PriceListLine."Asset No.", PriceListLine."Minimum Quantity");  // Campaign Number - blank.

        // Verify: Verify Unit Price on Sales line with Unit Price of Item and deduct Discount Amount.
        VerifyUnitPriceOnSalesLine(PriceListLine."Asset No.", SalesLine."Unit Price", PriceListLine."Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllCustomerSalesPriceDiscountAmtWithOutsideDateRange()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Calculate Sales Price based on discount allowed for all customers if Posting Date specified on the sales Invoice is not within the date range specified on the Sales Price.
        Initialize();

        // Setup.
        CreateSalesPriceWithDiscountAmount(
          PriceListLine, PriceListLine."Source Type"::"All Customers", '',
          CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate));  // Customer Number - blank and Starting Date - less than Workdate.


        // Exercise: Create Sales Invoice.
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Invoice, CreateCustomer, '', PriceListLine."Asset No.", PriceListLine."Minimum Quantity");

        // Verify: Verify Unit Price on Sales line with Unit Price of Item.
        VerifyUnitPriceOnSalesLine(PriceListLine."Asset No.", SalesLine."Unit Price", 0);  // Discount Amount - 0.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure CampaignSalesPriceDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        CustomerNo: Code[20];
        ContactNo: Code[20];
        CampaignNo: Code[20];
    begin
        // [SCENARIO] Calculate Sales Price based on Discount allowed for Campaign.
        Initialize();

        // Setup: Create Contact and Customer, create and activate Campaign, create Sales Price with Discount Amount using Campaign.
        ContactNo := CreateContactWithCustomer;
        CampaignNo := CreateAndActivateCampaign(ContactNo);
        CustomerNo := FindCustomerFromContactBusinessRelation(ContactNo);
        CreateSalesPriceWithDiscountAmount(PriceListLine, PriceListLine."Source Type"::Campaign, CampaignNo, WorkDate);  // Starting Date - Workdate.


        // Exercise: Create Sales Order.
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Order, CustomerNo, CampaignNo, PriceListLine."Asset No.", PriceListLine."Minimum Quantity");

        // Verify: Verify Unit Price on Sales line with Unit Price of Item and deduct Discount Amount.
        VerifyUnitPriceOnSalesLine(PriceListLine."Asset No.", SalesLine."Unit Price", PriceListLine."Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceSalesPriceDiscountAmt()
    var
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        OldAutomaticCostAdjustment: Option;
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus, Verify Unit price on Posted Sales Invoice.
        Initialize();

        // Setup: Update Automatic Cost Adjustment on Inventory Setup, Create Sales Price with Cost Plus and create Sales Order.
        UpdateAutomaticCostAdjustmentOnInventorySetup(OldAutomaticCostAdjustment, InventorySetup."Automatic Cost Adjustment"::Day);
        CreateSalesPriceWithCostPlus(
          PriceListLine, PriceListLine."Source Type"::"All Customers", '', WorkDate, LibraryRandom.RandDec(10, 2));  // Customer Number - blank and Random Minimum Quantity.


        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Order, CreateCustomer, '', PriceListLine."Asset No.", PriceListLine."Minimum Quantity");  // Campaign Number - blank.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Post Sales Order.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Unit Price on Sales Invoice Line based on Sales Price - Unit Price.
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("No.", PriceListLine."Asset No.");
        SalesInvoiceLine.FindFirst;
        Assert.AreNearlyEqual(
          PriceListLine."Unit Price", SalesInvoiceLine."Unit Price", LibraryERM.GetAmountRoundingPrecision, UnitPriceMustBeSameMsg);

        // Teardown.
        UpdateAutomaticCostAdjustmentOnInventorySetup(OldAutomaticCostAdjustment, OldAutomaticCostAdjustment);
    end;

    [Test]
    procedure SalesPriceListAllowsEditingCostPlus()
    var
        Item: Record Item;
        SalesPriceList: TestPage "Sales Price List";
        PricesOverview: TestPage "Prices Overview";
    begin
        // [FEATURE] [UI]
        Initialize();

        // [GIVEN] Item 'I', where "Unit Cost" = 100, "Unit Price" = 150.
        LibraryInventory.CreateItem(Item);
        Item."Unit Cost" := LibraryRandom.RandDec(100, 2);
        Item."Unit Price" := Item."Unit Cost" * 1.5;
        Item.Modify();

        // [WHEN] New price list line for Item 'I'
        SalesPriceList.OpenNew();
        SalesPriceList.Code.SetValue('X');
        SalesPriceList.SourceType.SetValue("Price Source Type"::"All Customers");
        SalesPriceList.Lines.New();
        SalesPriceList.Lines."Asset Type".SetValue("Price Asset Type"::Item);
        SalesPriceList.Lines."Asset No.".SetValue(Item."No.");
        // [THEN] "Cost-plus %" and "Discount Amount" are editable
        SalesPriceList.Lines.Cost.AssertEquals(Item."Unit Cost");
        SalesPriceList.Lines."Published Price".AssertEquals(Item."Unit Price");
        Assert.IsTrue(SalesPriceList.Lines."Cost-plus %".Editable(), 'Cost-plus %.Editable in Item line');
        Assert.IsTrue(SalesPriceList.Lines."Discount Amount".Editable(), 'Discount Amount.Editable in Item line');

        SalesPriceList.Lines."Cost-plus %".SetValue(10);
        SalesPriceList.Lines."Discount Amount".AssertEquals(0);
        SalesPriceList.Lines."Unit Price".AssertEquals(Item."Unit Cost" * 1.1);
    end;

    [Test]
    procedure PricesOverviewAllowsEditingCostPlus()
    var
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        PricesOverview: TestPage "Prices Overview";
    begin
        // [FEATURE] [UI]
        Initialize();

        // [GIVEN] Item 'I', where "Unit Cost" = 100, "Unit Price" = 150.
        LibraryInventory.CreateItem(Item);
        Item."Unit Cost" := LibraryRandom.RandDec(100, 2);
        Item."Unit Price" := Item."Unit Cost" * 1.5;
        Item.Modify();

        // [GIVEN] Draft price list line for Item 'I'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");

        // [WHEN] Open Price overview 
        PricesOverview.OpenEdit();
        PricesOverview.SourceType.SetValue("Price Source Type"::"All Customers");
        PricesOverview.AssetType.SetValue("Price Asset Type"::Item);
        PricesOverview.AssetNo.SetValue(Item."No.");
        PricesOverview.First();
        // [THEN] "Cost-plus %" and "Discount Amount" are editable
        PricesOverview.Cost.AssertEquals(Item."Unit Cost");
        PricesOverview."Published Price".AssertEquals(Item."Unit Price");
        Assert.IsTrue(PricesOverview."Cost-plus %".Editable(), 'Cost-plus %.Editable in Item line');
        Assert.IsTrue(PricesOverview."Discount Amount".Editable(), 'Discount Amount.Editable in Item line');

        PricesOverview."Cost-plus %".SetValue(1);
        PricesOverview."Discount Amount".SetValue(10);
        PricesOverview."Cost-plus %".AssertEquals(0);
        PricesOverview."Unit Price".AssertEquals(Item."Unit Price" - 10);
    end;

    [Test]
    procedure PricesWorksheetAllowsEditingCostPlus()
    var
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PriceWorksheet: TestPage "Price Worksheet";
    begin
        // [FEATURE] [UI]
        Initialize();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Default Price List Code" := LibraryERM.CreateNoSeriesCode();
        SalesReceivablesSetup.Modify();

        // [GIVEN] Item 'I', where "Unit Cost" = 100, "Unit Price" = 150.
        LibraryInventory.CreateItem(Item);
        Item."Unit Cost" := LibraryRandom.RandDec(100, 2);
        Item."Unit Price" := Item."Unit Cost" * 1.5;
        Item.Modify();

        // [GIVEN] Draft price list line for Item 'I'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");

        // [WHEN] Open Price worksheet and add new line for Item 'I' sales price 
        PriceWorksheet.OpenEdit();
        PriceWorksheet.PriceTypeFilter.SetValue("Price Type"::Sale);
        PriceWorksheet.New();
        PriceWorksheet.CustomerSourceType.SetValue("Price Source Type"::"All Customers");
        PriceWorksheet."Asset Type".SetValue("Price Asset Type"::Item);
        PriceWorksheet."Asset No.".SetValue(Item."No.");
        PriceWorksheet.New();
        PriceWorksheet.First();
        // [THEN] "Cost-plus %" and "Discount Amount" are editable
        PriceWorksheet.Cost.AssertEquals(Item."Unit Cost");
        PriceWorksheet."Published Price".AssertEquals(Item."Unit Price");
        Assert.IsTrue(PriceWorksheet."Cost-plus %".Editable(), 'Cost-plus %.Editable in Item line');
        Assert.IsTrue(PriceWorksheet."Discount Amount".Editable(), 'Discount Amount.Editable in Item line');

        PriceWorksheet."Cost-plus %".SetValue(1);
        PriceWorksheet."Discount Amount".SetValue(10);
        PriceWorksheet."Cost-plus %".AssertEquals(0);
        PriceWorksheet."Unit Price".AssertEquals(Item."Unit Price" - 10);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Price List Line Cost Plus");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Price List Line Cost Plus");
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation handler"::"Business Central (Version 16.0)");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Price List Line Cost Plus");
    end;

    local procedure CreateAndActivateCampaign(ContactNo: Code[20]): Code[20]
    var
        Campaign: Record Campaign;
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
    begin
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", WorkDate);
        Campaign.Validate("Ending Date", WorkDate);
        Campaign.Modify(true);
        CreateSegmentHeaderWithLine(Campaign."No.", ContactNo);
        CampaignTargetGroupMgt.ActivateCampaign(Campaign);
        exit(Campaign."No.");
    end;

    local procedure CreateContactWithCustomer(): Code[20]
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Template";
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        CustomerTemplate.SetRange("Currency Code", '');
        CustomerTemplate.FindFirst;
        Contact.CreateCustomer(CustomerTemplate.Code);
        exit(Contact."No.")
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDecInDecimalRange(100, 200, 2));
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; CampaignNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Campaign No.", CampaignNo);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesPrice(var PriceListLine: Record "Price List Line"; SourceType: Enum "Price Source Type"; CustomerNo: Code[20]; StartingDate: Date; MinimumQuantity: Decimal)
    var
        Item: Record Item;
    begin
        CreateItem(Item);
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', SourceType, CustomerNo, "Price Asset Type"::Item, Item."No.");
        PriceListLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        PriceListLine.Validate("Minimum Quantity", MinimumQuantity);
        if PriceListLine."Source Type" <> PriceListLine."Source Type"::Campaign then begin
            PriceListLine.Validate("Starting Date", StartingDate);
            PriceListLine.Validate("Ending Date", PriceListLine."Starting Date");
        end;
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify(true);
    end;

    local procedure CreateSalesPriceWithCostPlus(var PriceListLine: Record "Price List Line"; SourceType: Enum "Price Source Type"; CustomerNo: Code[20]; StartingDate: Date; MinimumQuantity: Decimal)
    begin
        CreateSalesPrice(PriceListLine, SourceType, CustomerNo, StartingDate, MinimumQuantity);
        UpdateCostPlusPctOnSalesPrice(PriceListLine);
    end;

    local procedure CreateSalesPriceWithDiscountAmount(var PriceListLine: Record "Price List Line"; SourceType: Enum "Price Source Type"; CustomerNo: Code[20]; StartingDate: Date)
    begin
        CreateSalesPrice(PriceListLine, SourceType, CustomerNo, StartingDate, LibraryRandom.RandDecInDecimalRange(10, 20, 2));  // Random range for Minimum Quantity
        PriceListLine.Validate("Discount Amount", LibraryRandom.RandDec(10, 2));
        PriceListLine.Modify(true);
    end;

    local procedure CreateSegmentHeaderWithLine(CampaignNo: Code[20]; ContactNo: Code[20])
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
    begin
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Campaign No.", CampaignNo);
        SegmentHeader.Modify(true);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentLine.Validate("Contact No.", ContactNo);
        SegmentLine.Validate("Campaign Target", true);
        SegmentLine.Modify(true);
    end;

    local procedure FindCustomerFromContactBusinessRelation(ContactNo: Code[20]) CustomerNo: Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        ContactBusinessRelation.FindFirst;
        CustomerNo := ContactBusinessRelation."No.";
    end;

    local procedure UpdateAutomaticCostAdjustmentOnInventorySetup(var OldAutomaticCostAdjustment: Option; AutomaticCostAdjustment: Option)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        OldAutomaticCostAdjustment := InventorySetup."Automatic Cost Adjustment";
        InventorySetup."Automatic Cost Adjustment" := AutomaticCostAdjustment;
        InventorySetup.Modify(true);
    end;

    local procedure UpdateCostPlusPctOnSalesPrice(var PriceListLine: Record "Price List Line")
    begin
        PriceListLine.Validate("Cost-plus %", LibraryRandom.RandIntInRange(10, 20));
        PriceListLine.Modify(true);
    end;

    local procedure VerifyUnitPriceOnSalesLine(ItemNo: Code[10]; UnitPrice: Decimal; DiscountAmount: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Assert.AreNearlyEqual(UnitPrice, Item."Unit Price" - DiscountAmount, LibraryERM.GetAmountRoundingPrecision, UnitPriceMustBeSameMsg);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

