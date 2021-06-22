codeunit 134167 "Copy Price Data Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Price List Line] [Upgrade]
    end;

    var
        Assert: Codeunit Assert;
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryMarketing: codeunit "Library - Marketing";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    procedure T001_CopySalesPriceToSeparateHeaders()
    var
        Currency: Record Currency;
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPrice: Record "Sales Price";
        PriceListCode: Code[20];
    begin
        Initialize();
        SalesPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] 2 Sales Prices, for All Customers, Item, with/without Currency.
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateCurrency(Currency);
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", "Sales Price Type"::"All Customers", '',
            Today(), Currency.Code, '', Item."Base Unit of Measure", 5, LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", "Sales Price Type"::"All Customers", '',
            Today(), '', '', Item."Base Unit of Measure", 5, LibraryRandom.RandDec(1000, 2));

        // [WHEN] Copy SalesPrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // [THEN] Added 2 Price List Lines and 2 Headers with/without "Currency Code"
        PriceListLine.FindFirst();
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        PriceListLine.Next();
        Assert.AreNotEqual(PriceListCode, PriceListLine."Price List Code", 'Same price list code');
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T002_CopySalesPriceToSameHeader()
    var
        Currency: Record Currency;
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPrice: Record "Sales Price";
        PriceListCode: Code[20];
    begin
        Initialize();
        SalesPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] 2 Sales Prices, for All Customers, different Items, same Currency.
        LibraryERM.CreateCurrency(Currency);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", "Sales Price Type"::"All Customers", '',
            Today(), Currency.Code, '', Item."Base Unit of Measure", 5, LibraryRandom.RandDec(1000, 2));
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", "Sales Price Type"::"All Customers", '',
            Today(), Currency.Code, '', Item."Base Unit of Measure", 10, LibraryRandom.RandDec(1000, 2));

        // [WHEN] Copy SalesPrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // [THEN] Added 2 Price List Lines to one Header with "Currency Code"
        PriceListLine.FindFirst();
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        PriceListLine.Next();
        Assert.AreEqual(PriceListCode, PriceListLine."Price List Code", 'different price list code');
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T003_CopySalesPriceDiscoutToSeparateHeaders()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        PriceListCode: Code[20];
    begin
        Initialize();
        SalesPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] Sales Price and Discount, for Customer 'C', Item
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateCurrency(Currency);
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", "Sales Price Type"::Customer, Customer."No.",
            Today(), Currency.Code, '', Item."Base Unit of Measure", 5, LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreateLineDiscForCustomer(
            SalesLineDiscount, "Sales Line Discount Type"::Item, Item."No.",
            "Sales Price Type"::Customer, Customer."No.", Today(), '', '', Item."Base Unit of Measure", 10);

        // [WHEN] Copy SalesPrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);

        // [THEN] Added 2 Price List Lines and 2 Headers with Amount Type "Price" and "Discount"
        PriceListLine.FindFirst();
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() <> 0, 'not found second line');
        Assert.AreNotEqual(PriceListCode, PriceListLine."Price List Code", 'Same price list code');
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T011_CopyPurchPriceToSeparateHeaders()
    var
        Currency: Record Currency;
        Item: Record Item;
        Vendor: Record Vendor;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchasePrice: Record "Purchase Price";
        PriceListCode: Code[20];
    begin
        Initialize();
        PurchasePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] 2 Purchase Prices, for Vendor 'V', Item, with/without Currency.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateCurrency(Currency);
        LibraryCosting.CreatePurchasePrice(
            PurchasePrice, Vendor."No.", Item."No.", Today(), Currency.Code, '', Item."Base Unit of Measure", 5);
        LibraryCosting.CreatePurchasePrice(
            PurchasePrice, Vendor."No.", Item."No.", Today(), '', '', Item."Base Unit of Measure", 10);

        // [WHEN] Copy PurchasePrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(PurchasePrice, PriceListLine);

        // [THEN] Added 2 Price List Lines and 2 Headers with/without "Currency Code"
        PriceListLine.FindFirst();
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        PriceListLine.Next();
        Assert.AreNotEqual(PriceListCode, PriceListLine."Price List Code", 'Same price list code');
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T012_CopyPurchPriceToSameHeader()
    var
        Currency: Record Currency;
        Item: Record Item;
        Vendor: Record Vendor;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchasePrice: Record "Purchase Price";
        PriceListCode: Code[20];
    begin
        Initialize();
        PurchasePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] 2 Purchase Prices, for Vendor 'V', different Items, same Currency.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateCurrency(Currency);
        LibraryInventory.CreateItem(Item);
        LibraryCosting.CreatePurchasePrice(
            PurchasePrice, Vendor."No.", Item."No.", Today(), Currency.Code, '', Item."Base Unit of Measure", 5);
        LibraryInventory.CreateItem(Item);
        LibraryCosting.CreatePurchasePrice(
            PurchasePrice, Vendor."No.", Item."No.", Today(), Currency.Code, '', Item."Base Unit of Measure", 5);

        // [WHEN] Copy PurchasePrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(PurchasePrice, PriceListLine);

        // [THEN] Added 2 Price List Lines to one Header with "Currency Code"
        PriceListLine.FindFirst();
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        PriceListLine.Next();
        Assert.AreEqual(PriceListCode, PriceListLine."Price List Code", 'different price list code');
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T013_CopyPurchPriceDiscoutToSeparateHeaders()
    var
        Currency: Record Currency;
        Vendor: Record Vendor;
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PriceListCode: Code[20];
    begin
        Initialize();
        PurchasePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] Purchase Price and Discount, for Vendor 'V', Item
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateCurrency(Currency);
        LibraryCosting.CreatePurchasePrice(
            PurchasePrice, Vendor."No.", Item."No.", Today(), Currency.Code, '', Item."Base Unit of Measure", 5);
        LibraryERM.CreateLineDiscForVendor(
            PurchaseLineDiscount, Item."No.", Vendor."No.", Today(), '', '', Item."Base Unit of Measure", 10);

        // [WHEN] Copy PurchasePrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(PurchasePrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        // [THEN] Added 2 Price List Lines and 2 Headers with Amount Type "Price" and "Discount"
        PriceListLine.FindFirst();
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() <> 0, 'not found second line');
        Assert.AreNotEqual(PriceListCode, PriceListLine."Price List Code", 'Same price list code');
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T020_CopyJobItemPriceToNone()
    var
        JobItemPrice: Record "Job Item Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        JobItemPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where both "Apply Job Price" and "Apply Job Discount" are false.
        CreateJobItemPrice(JobItemPrice, false, false);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);

        // [THEN] None price list lines added.
        Assert.RecordIsEmpty(PriceListHeader);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    [Test]
    procedure T021_CopyJobItemPriceToOnePriceLine()
    var
        JobItemPrice: Record "Job Item Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobItemPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where "Apply Job Price" is true, "Apply Job Discount" is false.
        CreateJobItemPrice(JobItemPrice, true, false);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);

        // [THEN] One price list line added, where Amount Type is 'Price'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", JobItemPrice."Unit Price");
        PriceListLine.TestField("Cost Factor", JobItemPrice."Unit Cost Factor");
        PriceListLine.TestField("Line Discount %", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T022_CopyJobItemPriceToOneDiscountLine()
    var
        JobItemPrice: Record "Job Item Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobItemPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where "Apply Job Price" is true, "Apply Job Discount" is false.
        CreateJobItemPrice(JobItemPrice, false, true);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);

        // [THEN] One price list line added, where Amount Type is  'Discount'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Line Discount %", JobItemPrice."Line Discount %");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T023_CopyJobItemPriceToTwoHeaders()
    var
        JobItemPrice: Record "Job Item Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobItemPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where "Apply Job Price" is true, "Apply Job Discount" is false.
        CreateJobItemPrice(JobItemPrice, true, true);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);

        // [THEN] Added 2 Price List Lines and 2 Headers with Amount Type "Price" and "Discount"
        PriceListLine.FindFirst();
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", JobItemPrice."Unit Price");
        PriceListLine.TestField("Cost Factor", JobItemPrice."Unit Cost Factor");
        PriceListLine.TestField("Line Discount %", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() <> 0, 'not found second line');
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Line Discount %", JobItemPrice."Line Discount %");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T030_CopyJobGLAccPriceToTwoHeaders()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobGLAccountPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobGLAccountPrice, where Price, Cost and Discount are set
        CreateJobGLAccPrice(
            JobGLAccountPrice, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(50, 2), LibraryRandom.RandDec(100, 2));

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [THEN] Added 1st Price List Header, where "Price Type" 'Sale', "Amount Type" 'Any'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Any);
        PriceListLine.TestField("Unit Price", JobGLAccountPrice."Unit Price");
        PriceListLine.TestField("Cost Factor", JobGLAccountPrice."Unit Cost Factor");
        PriceListLine.TestField("Line Discount %", JobGLAccountPrice."Line Discount %");
        PriceListLine.TestField("Unit Cost", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        // [THEN] Added 2nd Price List Header, where "Price Type" 'Purchase', "Amount Type" 'Price'
        Assert.IsTrue(PriceListLine.Next() <> 0, 'not found second line');
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Line Discount %", 0);
        PriceListLine.TestField("Unit Cost", JobGLAccountPrice."Unit Cost");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T031_CopyJobGLAccPriceToSalesHeader()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobGLAccountPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where Price and Discount are set
        CreateJobGLAccPrice(JobGLAccountPrice, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(50, 2), 0);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [THEN] Added one Price List Header, where "Price Type" 'Sale', "Amount Type" 'Any'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Any);
        PriceListLine.TestField("Unit Price", JobGLAccountPrice."Unit Price");
        PriceListLine.TestField("Cost Factor", JobGLAccountPrice."Unit Cost Factor");
        PriceListLine.TestField("Line Discount %", JobGLAccountPrice."Line Discount %");
        PriceListLine.TestField("Unit Cost", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    [Test]
    procedure T032_CopyJobGLAccPriceToPurchHeader()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobGLAccountPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where Cost is set
        CreateJobGLAccPrice(JobGLAccountPrice, 0, 0, LibraryRandom.RandDec(100, 2));

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [THEN] Added 2nd Price List Header, where "Price Type" 'Purchase', "Amount Type" 'Price'
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Line Discount %", 0);
        PriceListLine.TestField("Unit Cost", JobGLAccountPrice."Unit Cost");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    [Test]
    procedure T033_CopyJobGLAccPriceDiscToSalesHeader()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobGLAccountPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where Discount is set
        CreateJobGLAccPrice(JobGLAccountPrice, 0, LibraryRandom.RandDec(50, 2), 0);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [THEN] Added one Price List Header, where "Price Type" 'Sale', "Amount Type" 'Discount'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Line Discount %", JobGLAccountPrice."Line Discount %");
        PriceListLine.TestField("Unit Cost", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    [Test]
    procedure T040_CopyJobResourcePriceToTwoHeaders()
    var
        JobResourcePrice: Record "Job Resource Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobResourcePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobResourcePrice, where "Apply Job Price" is true, "Apply Job Discount" is true.
        CreateJobResourcePrice(JobResourcePrice, true, true);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);

        // [THEN] Added 1st Price List Header, where "Price Type" 'Sale', "Amount Type" 'Price'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", JobResourcePrice."Unit Price");
        PriceListLine.TestField("Cost Factor", JobResourcePrice."Unit Cost Factor");
        PriceListLine.TestField("Line Discount %", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        // [THEN] Added 2nd Price List Header, where "Price Type" 'Sale', "Amount Type" 'Discount'
        Assert.IsTrue(PriceListLine.Next() <> 0, 'not found second line');
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Line Discount %", JobResourcePrice."Line Discount %");
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T041_CopyJobResourcePriceToPriceHeader()
    var
        JobResourcePrice: Record "Job Resource Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobResourcePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobResourcePrice, where "Apply Job Price" is true, "Apply Job Discount" is false.
        CreateJobResourcePrice(JobResourcePrice, true, false);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);

        // [THEN] Added one Price List Header, where "Price Type" 'Sale', "Amount Type" 'Price'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", JobResourcePrice."Unit Price");
        PriceListLine.TestField("Cost Factor", JobResourcePrice."Unit Cost Factor");
        PriceListLine.TestField("Line Discount %", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    [Test]
    procedure T042_CopyJobResourcePriceToDiscHeaders()
    var
        JobResourcePrice: Record "Job Resource Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobResourcePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobResourcePrice, where "Apply Job Price" is false, "Apply Job Discount" is true.
        CreateJobResourcePrice(JobResourcePrice, false, true);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);

        // [THEN] Added one Price List Header, where "Price Type" 'Sale', "Amount Type" 'Discount'
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Line Discount %", JobResourcePrice."Line Discount %");
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    [Test]
    procedure T043_CopyJobResourcePriceToNone()
    var
        JobResourcePrice: Record "Job Resource Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobResourcePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobResourcePrice, where "Apply Job Price" is false, "Apply Job Discount" is false.
        CreateJobResourcePrice(JobResourcePrice, false, false);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);

        // [THEN] Added zero Price List Header/Line
        Assert.RecordIsEmpty(PriceListHeader);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    [Test]
    procedure T050_CopyResourcePriceToPriceHeader()
    var
        ResourcePrice: Record "Resource Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        ResourcePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] ResourceCost
        CreateResourcePrice(ResourcePrice);

        // [WHEN] Copy ResourceCost with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(ResourcePrice, PriceListLine);

        // [THEN] Added one Price List Header, where "Price Type" 'Sale', "Amount Type" 'Price'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", ResourcePrice."Unit Price");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    [Test]
    procedure T060_CopyResourceCostToPriceHeader()
    var
        ResourceCost: Record "Resource Cost";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        ResourceCost.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] ResourceCost
        CreateResourceCost(ResourceCost);

        // [WHEN] Copy ResourceCost with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(ResourceCost, PriceListLine);

        // [THEN] Added one Price List Header, where "Price Type" 'Purchase', "Amount Type" 'Price'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Cost", ResourceCost."Unit Cost");
        PriceListLine.TestField("Unit Price", ResourceCost."Direct Unit Cost");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        JobsSetup: Record "Jobs Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Copy Price Data Test");
        LibraryVariableStorage.Clear;
        Clear(CopyFromToPriceListLine);

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Copy Price Data Test");

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('SAL'));
        SalesReceivablesSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('PUR'));
        PurchasesPayablesSetup.Modify();

        JobsSetup.Get();
        JobsSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('JOB'));
        JobsSetup.Modify();

        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Copy Price Data Test");
    end;

    local procedure CreateJobGLAccPrice(var JobGLAccountPrice: Record "Job G/L Account Price"; Price: Decimal; Discount: Decimal; Cost: Decimal)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobGLAccountPrice(
            JobGLAccountPrice, Job."No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountNo(), '');
        JobGLAccountPrice."Unit Price" := Price;
        if Price <> 0 then
            JobGLAccountPrice."Unit Cost Factor" := LibraryRandom.RandDec(10, 2);
        JobGLAccountPrice."Line Discount %" := Discount;
        JobGLAccountPrice."Unit Cost" := Cost;
        JobGLAccountPrice.Modify();
    end;

    local procedure CreateJobItemPrice(var JobItemPrice: Record "Job Item Price"; ApplyJobPrice: Boolean; ApplyJobDisc: Boolean)
    var
        Job: Record Job;
        Item: Record Item;
    begin
        LibraryJob.CreateJob(Job);
        LibraryInventory.CreateItem(Item);
        LibraryJob.CreateJobItemPrice(JobItemPrice, Job."No.", '', Item."No.", '', '', Item."Base Unit of Measure");
        JobItemPrice."Unit Price" := LibraryRandom.RandDec(100, 2);
        JobItemPrice."Unit Cost Factor" := LibraryRandom.RandDec(10, 2);
        JobItemPrice."Line Discount %" := LibraryRandom.RandDec(50, 2);
        JobItemPrice."Apply Job Price" := ApplyJobPrice;
        JobItemPrice."Apply Job Discount" := ApplyJobDisc;
        JobItemPrice.Modify();
    end;

    local procedure CreateJobResourcePrice(var JobResourcePrice: Record "Job Resource Price"; ApplyJobPrice: Boolean; ApplyJobDisc: Boolean)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Resource: Record Resource;
        WorkType: Record "Work Type";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryResource.CreateResource(Resource, '');
        LibraryResource.CreateWorkType(WorkType);
        LibraryJob.CreateJobResourcePrice(
            JobResourcePrice, Job."No.", JobTask."Job Task No.",
            JobResourcePrice.Type::Resource, Resource."No.", WorkType.Code, '');
        JobResourcePrice."Apply Job Price" := ApplyJobPrice;
        JobResourcePrice."Apply Job Discount" := ApplyJobDisc;
        JobResourcePrice."Unit Price" := LibraryRandom.RandDec(1000, 2);
        JobResourcePrice."Unit Cost Factor" := LibraryRandom.RandDec(10, 2);
        JobResourcePrice."Line Discount %" := LibraryRandom.RandDec(50, 2);
        JobResourcePrice.Modify();
    end;

    local procedure CreateResourcePrice(var ResourcePrice: Record "Resource Price")
    var
        Resource: Record Resource;
        WorkType: Record "Work Type";
    begin
        LibraryResource.CreateResource(Resource, '');
        LibraryResource.CreateWorkType(WorkType);
        LibraryResource.CreateResourcePrice(ResourcePrice, ResourcePrice.Type::Resource, Resource."No.", WorkType.Code, '');
        ResourcePrice."Unit Price" := LibraryRandom.RandDec(1000, 2);
        ResourcePrice.Modify();
    end;

    local procedure CreateResourceCost(var ResourceCost: Record "Resource Cost")
    var
        Resource: Record Resource;
        WorkType: Record "Work Type";
    begin
        LibraryResource.CreateResource(Resource, '');
        LibraryResource.CreateWorkType(WorkType);
        ResourceCost.Type := ResourceCost.Type::Resource;
        ResourceCost.Code := Resource."No.";
        ResourceCost."Work Type Code" := WorkType.Code;
        ResourceCost."Direct Unit Cost" := LibraryRandom.RandDec(1000, 2);
        ResourceCost."Unit Cost" := LibraryRandom.RandDec(1000, 2);
        ResourceCost.Insert();
    end;

    local procedure VerifyHeader(PriceListLine: Record "Price List Line")
    var
        PriceListHeader: Record "Price List Header";
    begin
        PriceListLine.TestField("Price List Code");
        PriceListHeader.Get(PriceListLine."Price List Code");
        PriceListHeader.TestField("Amount Type", PriceListLine."Amount Type");
        PriceListHeader.TestField("Price Type", PriceListLine."Price Type");
        PriceListHeader.TestField("Currency Code", PriceListLine."Currency Code");
        PriceListHeader.TestField("Starting Date", PriceListLine."Starting Date");
        PriceListHeader.TestField("Ending Date", PriceListLine."Ending Date");
        PriceListHeader.TestField("Source Type", PriceListLine."Source Type");
        PriceListHeader.TestField("Source No.", PriceListLine."Source No.");
        PriceListHeader.TestField("Parent Source No.", PriceListLine."Parent Source No.");
    end;
}