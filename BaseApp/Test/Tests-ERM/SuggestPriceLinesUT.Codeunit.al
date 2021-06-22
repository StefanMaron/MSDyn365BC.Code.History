codeunit 134168 "Suggest Price Lines UT"
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
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        SameFromListCodeErr: Label '%1 must not be the same as %2.', Comment = '%1 and %2 - captions of the fields From Price List Code and To Price List Code';
        CannotFindDocErr: Label 'Cannot find document in the list.';

    [Test]
    procedure T001_PriceLineFiltersReplaceAllWithItem()
    var
        PriceLineFilters: Record "Price Line Filters";
        PriceListHeader: Record "Price List Header";
    begin
        Initialize(false);

        // [GIVEN] PriceLineFilters, where "Asset Type" is 'Resource', "Asset Filter" is '*'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceLineFilters.Initialize(PriceListHeader, false);
        PriceLineFilters.Validate("Asset Type", "Price Asset Type"::Resource);
        PriceLineFilters."Asset Filter" := '*';
        PriceLineFilters.TestField("Table Id", Database::Resource);

        // [WHEN] set "Asset Type" to 'All'
        PriceLineFilters.Validate("Asset Type", "Price Asset Type"::" ");

        // [THEN] "Asset Type" is 'Item', "Table Id" is 'Item', "Asset Filter" is <blank>
        PriceLineFilters.TestField("Asset Type", "Price Asset Type"::Item);
        PriceLineFilters.TestField("Table Id", Database::Item);
        PriceLineFilters.TestField("Asset Filter", '');
    end;

    [Test]
    procedure T002_PriceLineFiltersInitializeForAdd()
    var
        PriceLineFilters: Record "Price Line Filters";
        PriceListHeader: Record "Price List Header";
        RoundingMethod: Record "Rounding Method";
    begin
        Initialize(false);

        // [GIVEN] "Rounding Method" 'X', where Precision is 1
        RoundingMethod.DeleteAll();
        RoundingMethod.Code := '0';
        RoundingMethod.Precision := 10;
        RoundingMethod.Insert();
        RoundingMethod.Code := '1';
        RoundingMethod.Precision := 1;
        RoundingMethod.Insert();

        // [WHEN] run Initialize()
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceLineFilters.Initialize(PriceListHeader, false);

        // [THEN] "Asset Type" is 'Item', "Adjustment Factor" = 1, "Rounding Method Code" is ''
        PriceLineFilters.TestField("Asset Type", "Price Asset Type"::Item);
        PriceLineFilters.TestField("Asset Filter", '');
        PriceLineFilters.TestField("Table Id", Database::Item);
        PriceLineFilters.TestField("Minimum Quantity", 0);
        PriceLineFilters.TestField("Adjustment Factor", 1);
        PriceLineFilters.TestField("Rounding Method Code", '');
    end;

    [Test]
    procedure T003_PriceLineFiltersInitializeForCopy()
    var
        PriceLineFilters: Record "Price Line Filters";
        PriceListHeader: Record "Price List Header";
    begin
        Initialize(false);

        // [GIVEN] New Sales Price List 'X'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');

        // [WHEN] run Initialize() for Price List 'X'
        PriceLineFilters.Initialize(PriceListHeader, true);

        // [THEN] "To Price List Code" is 'X', "Asset Type" is 'All', "Adjustment Factor" = 1, 
        PriceLineFilters.TestField("Price Type", PriceListHeader."Price Type");
        PriceLineFilters.TestField("Source Group", PriceListHeader."Source Group");
        PriceLineFilters.TestField("To Price List Code", PriceListHeader.Code);
        PriceLineFilters.TestField("From Price List Code", '');
        PriceLineFilters.TestField("Asset Type", "Price Asset Type"::" ");
        PriceLineFilters.TestField("Asset Filter", '');
        PriceLineFilters.TestField("Table Id", 0);
        PriceLineFilters.TestField("Minimum Quantity", 0);
        PriceLineFilters.TestField("Adjustment Factor", 1);
    end;

    [Test]
    [HandlerFunctions('SuggestPriceLinesModalHandler')]
    procedure T010_SalesPriceListCannotCopySamePriceList()
    var
        Item: Record Item;
        PriceLineFilters: Record "Price Line Filters";
        FromPriceListHeader: Record "Price List Header";
        FromPriceListLine: Record "Price List Line";
        ToPriceListHeader: Record "Price List Header";
        ToPriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
        SuggestPriceLinesUT: Codeunit "Suggest Price Lines UT";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Error message if "From Price List Code" is equal to "To Price List Code".
        Initialize(true);
        BindSubscription(SuggestPriceLinesUT);

        // [GIVEN] Sales Price List 'A' with 'Item' line
        LibraryPriceCalculation.CreatePriceHeader(FromPriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryInventory.CreateItem(Item);
        LibraryPriceCalculation.CreateSalesPriceLine(
            FromPriceListLine, FromPriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
        // [GIVEN] New Sales Price List 'X'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] Open sales prrice list page for 'X'
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, ToPriceListHeader.Code);

        // [WHEN] run "Copy Price List.." on Price List 'X', set "To Price List Code" as 'X', click 'Ok'
        LibraryVariableStorage.Enqueue(ToPriceListHeader.Code); // to SuggestPriceLinesModalHandler
        LibraryVariableStorage.Enqueue(1); // to set Adjustment Factor
        LibraryVariableStorage.Enqueue(true); // click OK
        asserterror SalesPriceList.CopyLines.Invoke();

        // [THEN] Error message SameFromListCodeErr
        Assert.ExpectedError(
            StrSubstNo(
                SameFromListCodeErr,
                PriceLineFilters.FieldCaption("From Price List Code"), PriceLineFilters.FieldCaption("To Price List Code")));
    end;

    [Test]
    [HandlerFunctions('SuggestPriceLinesModalHandler')]
    procedure T011_SalesPriceListCopyLinesCancel()
    var
        Item: Record Item;
        PriceLineFilters: Record "Price Line Filters";
        FromPriceListHeader: Record "Price List Header";
        FromPriceListLine: Record "Price List Line";
        ToPriceListHeader: Record "Price List Header";
        ToPriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
        SuggestPriceLinesUT: Codeunit "Suggest Price Lines UT";
    begin
        // [FEATURE] [UI] [Sales]
        Initialize(true);
        BindSubscription(SuggestPriceLinesUT);

        // [GIVEN] Sales Price List 'A' with 'Item' line
        LibraryPriceCalculation.CreatePriceHeader(FromPriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryInventory.CreateItem(Item);
        LibraryPriceCalculation.CreateSalesPriceLine(
            FromPriceListLine, FromPriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
        // [GIVEN] New Sales Price List 'X'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] Open sales price list page for 'X'
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, ToPriceListHeader.Code);

        // [WHEN] run "Copy Price List.." on Price List 'X' and click 'Cancel'
        LibraryVariableStorage.Enqueue(FromPriceListHeader.Code); // to SuggestPriceLinesModalHandler
        LibraryVariableStorage.Enqueue(2); // to set Adjustment Factor
        LibraryVariableStorage.Enqueue(false); // click Cancel
        SalesPriceList.CopyLines.Invoke();

        // [THEN] Page "Suggest Price Line" is open, closed, no new lines got created.
        ToPriceListLine.SetRange("Price List Code", ToPriceListHeader.Code);
        Assert.RecordIsEmpty(ToPriceListLine);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestPriceLinesModalHandler')]
    procedure T012_SalesPriceListCopyLinesOk()
    var
        Item: Record Item;
        PriceLineFilters: Record "Price Line Filters";
        FromPriceListHeader: Record "Price List Header";
        FromPriceListLine: Record "Price List Line";
        ToPriceListHeader: Record "Price List Header";
        ToPriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
        SuggestPriceLinesUT: Codeunit "Suggest Price Lines UT";
        AdjFactor: Decimal;
    begin
        // [FEATURE] [UI] [Sales]
        Initialize(true);
        BindSubscription(SuggestPriceLinesUT);

        // [GIVEN] Sales Price List 'A' with 'Item' line, where "Minimum Quantity" is 12
        LibraryPriceCalculation.CreatePriceHeader(FromPriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryInventory.CreateItem(Item);
        LibraryPriceCalculation.CreateSalesPriceLine(
            FromPriceListLine, FromPriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
        FromPriceListLine."Minimum Quantity" := 12;
        FromPriceListLine.Modify();
        // [GIVEN] New Sales Price List 'X'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] Open sales prrice list page for 'X'
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, ToPriceListHeader.Code);

        // [WHEN] run "Copy Price List.." on Price List 'X', set "Adjustment Factor" to 2 and click 'Ok'
        LibraryVariableStorage.Enqueue(FromPriceListHeader.Code); // to SuggestPriceLinesModalHandler
        AdjFactor := 2;
        LibraryVariableStorage.Enqueue(AdjFactor); // to set Adjustment Factor
        LibraryVariableStorage.Enqueue(true); // click OK
        SalesPriceList.CopyLines.Invoke();

        // [THEN] Page "Suggest Price Line" is open, closed, no one new line is created, where "Minimum Quantity" is 12, "Unit Price" is doubled
        ToPriceListLine.SetRange("Price List Code", ToPriceListHeader.Code);
        Assert.IsTrue(ToPriceListLine.FindFirst(), 'The line is not copied.');
        ToPriceListLine.Testfield("Asset No.", FromPriceListLine."Asset No.");
        ToPriceListLine.Testfield("Minimum Quantity", FromPriceListLine."Minimum Quantity");
        ToPriceListLine.TestField("Unit Price", FromPriceListLine."Unit Price" * AdjFactor);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestPriceLinesModalHandler')]
    procedure T013_PurchasePriceListCopyLinesOk()
    var
        Item: Record Item;
        PriceLineFilters: Record "Price Line Filters";
        FromPriceListHeader: Record "Price List Header";
        FromPriceListLine: Record "Price List Line";
        ToPriceListHeader: Record "Price List Header";
        ToPriceListLine: Record "Price List Line";
        PurchasePriceList: TestPage "Purchase Price List";
        SuggestPriceLinesUT: Codeunit "Suggest Price Lines UT";
        AdjFactor: Decimal;
    begin
        // [FEATURE] [UI] [Purchase]
        Initialize(true);
        BindSubscription(SuggestPriceLinesUT);

        // [GIVEN] Purchase Price List 'A' with 'Item' line, where "Minimum Quantity" is 13
        LibraryPriceCalculation.CreatePriceHeader(FromPriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        LibraryInventory.CreateItem(Item);
        LibraryPriceCalculation.CreatePurchPriceLine(
            FromPriceListLine, FromPriceListHeader.Code, "Price Source Type"::"All Vendors", '', "Price Asset Type"::Item, Item."No.");
        FromPriceListLine."Minimum Quantity" := 13;
        FromPriceListLine.Modify();
        // [GIVEN] New Purchase Price List 'X'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        // [GIVEN] Open Purchase price list page for 'X'
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, ToPriceListHeader.Code);

        // [WHEN] run "Copy Price List.." on Price List 'X', set "Adjustment Factor" to 2 and click 'Ok'
        LibraryVariableStorage.Enqueue(FromPriceListHeader.Code); // to SuggestPriceLinesModalHandler
        AdjFactor := 2;
        LibraryVariableStorage.Enqueue(AdjFactor); // to set Adjustment Factor
        LibraryVariableStorage.Enqueue(true); // click OK
        PurchasePriceList.CopyLines.Invoke();

        // [THEN] Page "Suggest Price Line" is open, closed, no one new line is created, where "Minimum Quantity" is 13, "Unit Price" is doubled
        ToPriceListLine.SetRange("Price List Code", ToPriceListHeader.Code);
        Assert.IsTrue(ToPriceListLine.FindFirst(), 'The line is not copied.');
        ToPriceListLine.Testfield("Asset No.", FromPriceListLine."Asset No.");
        ToPriceListLine.Testfield("Minimum Quantity", FromPriceListLine."Minimum Quantity");
        ToPriceListLine.TestField("Unit Price", FromPriceListLine."Unit Price" * AdjFactor);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestPriceLinesFCYModalHandler')]
    procedure T015_PurchasePriceListFCY1CopyLinesFCY2()
    var
        PriceLineFilters: Record "Price Line Filters";
        FromPriceListHeader: Record "Price List Header";
        FromPriceListLine: Record "Price List Line";
        ToPriceListHeader: Record "Price List Header";
        ToPriceListLine: Record "Price List Line";
        PurchasePriceList: TestPage "Purchase Price List";
        SuggestPriceLinesUT: Codeunit "Suggest Price Lines UT";
        CurrencyCode: array[2] of Code[10];
        AdjFactor: Decimal;
    begin
        // [FEATURE] [UI] [FCY]
        Initialize(true);
        BindSubscription(SuggestPriceLinesUT);

        // [GIVEN] Currency 'C1', where rates are 2 on 01.01, 3 on 02.01
        CurrencyCode[1] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate() - 1, 2, 2);
        LibraryERM.CreateExchangeRate(CurrencyCode[1], WorkDate(), 3, 3);
        // [GIVEN] Currency 'C2', where rates are 3 on 01.01, 4 on 02.01
        CurrencyCode[2] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate() - 1, 3, 3);
        LibraryERM.CreateExchangeRate(CurrencyCode[2], WorkDate(), 4, 4);

        // [GIVEN] Purchase Price List 'A' with 'Item' line, where "Unit Cost" is 10, "Currncy Code" is 'C1'
        LibraryPriceCalculation.CreatePriceHeader(FromPriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        FromPriceListHeader."Currency Code" := CurrencyCode[1];
        FromPriceListHeader.Modify();
        LibraryPriceCalculation.CreatePurchPriceLine(
            FromPriceListLine, FromPriceListHeader.Code, "Price Source Type"::"All Vendors", '',
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        FromPriceListLine.Modify();
        // [GIVEN] New Purchase Price List 'X', where "Currncy Code" is 'C2'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        ToPriceListHeader."Currency Code" := CurrencyCode[2];
        ToPriceListHeader.Modify();
        // [GIVEN] Open Purchase price list page for 'X'
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, ToPriceListHeader.Code);

        // [WHEN] run "Copy Price List.." on Price List 'X', set "From Price List Code" 'A', "Adjustment Factor" to 2 and click 'Ok'
        LibraryVariableStorage.Enqueue(FromPriceListHeader.Code); // to SuggestPriceLinesModalHandler
        AdjFactor := 2;
        LibraryVariableStorage.Enqueue(AdjFactor); // to set Adjustment Factor
        LibraryVariableStorage.Enqueue(WorkDate() - 1); // Exch. Rate Date
        PurchasePriceList.CopyLines.Invoke();

        // [THEN] Page "Suggest Price Line" is open, closed, no one new line is created, where "Direct Unit Cost" is 30
        ToPriceListLine.SetRange("Price List Code", ToPriceListHeader.Code);
        Assert.IsTrue(ToPriceListLine.FindFirst(), 'The line is not copied.');
        ToPriceListLine.Testfield("Asset No.", FromPriceListLine."Asset No.");
        ToPriceListLine.Testfield("Minimum Quantity", FromPriceListLine."Minimum Quantity");
        ToPriceListLine.TestField("Direct Unit Cost", FromPriceListLine."Direct Unit Cost" * 3);
        ToPriceListLine.TestField("Unit Price", 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestPriceLinesFCYLookupModalHandler,PurchasePriceListsModalHandler')]
    procedure T016_PurchasePriceListLCYCopyLinesFCY()
    var
        PriceLineFilters: Record "Price Line Filters";
        FromPriceListHeader: Record "Price List Header";
        FromPriceListLine: Record "Price List Line";
        ToPriceListHeader: Record "Price List Header";
        ToPriceListLine: Record "Price List Line";
        PurchasePriceList: TestPage "Purchase Price List";
        SuggestPriceLinesUT: Codeunit "Suggest Price Lines UT";
        CurrencyCode: array[2] of Code[10];
        AdjFactor: Decimal;
    begin
        // [FEATURE] [UI] [FCY]
        Initialize(true);
        BindSubscription(SuggestPriceLinesUT);

        // [GIVEN] Currency 'C1', where rates are 2 on 01.01, 3 on 02.01
        CurrencyCode[1] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate() - 1, 2, 2);
        LibraryERM.CreateExchangeRate(CurrencyCode[1], WorkDate(), 3, 3);

        // [GIVEN] Purchase Price List 'A' with 'Item' line, where "Unit Cost" is 10, "Currncy Code" is 'C1'
        LibraryPriceCalculation.CreatePriceHeader(FromPriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        FromPriceListHeader.Description := FromPriceListHeader.Code;
        FromPriceListHeader."Currency Code" := CurrencyCode[1];
        FromPriceListHeader.Modify();
        LibraryPriceCalculation.CreatePurchPriceLine(
            FromPriceListLine, FromPriceListHeader.Code, "Price Source Type"::"All Vendors", '',
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        FromPriceListLine.Modify();
        // [GIVEN] New Purchase Price List 'X', where "Currncy Code" is 'LCY'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        // [GIVEN] Open Purchase price list page for 'X'
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, ToPriceListHeader.Code);

        // [WHEN] run "Copy Price List.." on Price List 'X', set "From Price List Code" 'A', "Adjustment Factor" to 3 and click 'Ok'
        LibraryVariableStorage.Enqueue(true); // to PurchasePriceListsModalHandler
        LibraryVariableStorage.Enqueue(FromPriceListHeader.Description); // to PurchasePriceListsModalHandler
        AdjFactor := 3;
        LibraryVariableStorage.Enqueue(AdjFactor); // to set Adjustment Factor
        LibraryVariableStorage.Enqueue(WorkDate() - 1); // Exch. Rate Date
        PurchasePriceList.CopyLines.Invoke();

        // [THEN] Page "Suggest Price Line" is open, closed, no one new line is created, where "Direct Unit Cost" is 15
        ToPriceListLine.SetRange("Price List Code", ToPriceListHeader.Code);
        Assert.IsTrue(ToPriceListLine.FindFirst(), 'The line is not copied.');
        ToPriceListLine.Testfield("Asset No.", FromPriceListLine."Asset No.");
        ToPriceListLine.Testfield("Minimum Quantity", FromPriceListLine."Minimum Quantity");
        ToPriceListLine.TestField("Direct Unit Cost", FromPriceListLine."Direct Unit Cost" * 1.5);
        ToPriceListLine.TestField("Unit Price", 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestPriceLinesFCYModalHandler')]
    procedure T017_PurchasePriceListFCYCopyLinesLCY()
    var
        PriceLineFilters: Record "Price Line Filters";
        FromPriceListHeader: Record "Price List Header";
        FromPriceListLine: Record "Price List Line";
        ToPriceListHeader: Record "Price List Header";
        ToPriceListLine: Record "Price List Line";
        PurchasePriceList: TestPage "Purchase Price List";
        SuggestPriceLinesUT: Codeunit "Suggest Price Lines UT";
        CurrencyCode: array[2] of Code[10];
        AdjFactor: Decimal;
    begin
        // [FEATURE] [UI] [FCY]
        Initialize(true);
        BindSubscription(SuggestPriceLinesUT);

        // [GIVEN] Currency 'C1', where rates are 2 on 01.01, 3 on 02.01
        CurrencyCode[1] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate() - 1, 2, 2);
        LibraryERM.CreateExchangeRate(CurrencyCode[1], WorkDate(), 3, 3);

        // [GIVEN] Purchase Price List 'A' with 'Item' line, where "Unit Cost" is 10, "Currncy Code" is 'LCY'
        LibraryPriceCalculation.CreatePriceHeader(FromPriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreatePurchPriceLine(
            FromPriceListLine, FromPriceListHeader.Code, "Price Source Type"::"All Vendors", '',
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        FromPriceListLine.Modify();
        // [GIVEN] New Purchase Price List 'X', where "Currncy Code" is 'C1'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        ToPriceListHeader."Currency Code" := CurrencyCode[1];
        ToPriceListHeader.Modify();
        // [GIVEN] Open Purchase price list page for 'X'
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, ToPriceListHeader.Code);

        // [WHEN] run "Copy Price List.." on Price List 'X', set "From Price List Code" 'A', "Adjustment Factor" to 3 and click 'Ok'
        LibraryVariableStorage.Enqueue(FromPriceListHeader.Code); // to SuggestPriceLinesModalHandler
        AdjFactor := 3;
        LibraryVariableStorage.Enqueue(AdjFactor); // to set Adjustment Factor
        LibraryVariableStorage.Enqueue(WorkDate() - 1); // Exch. Rate Date
        PurchasePriceList.CopyLines.Invoke();

        // [THEN] Page "Suggest Price Line" is open, closed, no one new line is created, where "Direct Unit Cost" is 60
        ToPriceListLine.SetRange("Price List Code", ToPriceListHeader.Code);
        Assert.IsTrue(ToPriceListLine.FindFirst(), 'The line is not copied.');
        ToPriceListLine.Testfield("Asset No.", FromPriceListLine."Asset No.");
        ToPriceListLine.Testfield("Minimum Quantity", FromPriceListLine."Minimum Quantity");
        ToPriceListLine.TestField("Direct Unit Cost", FromPriceListLine."Direct Unit Cost" * 6);
        ToPriceListLine.TestField("Unit Price", 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TwoDuplicatePriceLinesModalHandler,ConfirmYesHandler')]
    procedure T030_DuplicatePriceLineInTheSamePriceList()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
    begin
        Initialize(true);
        // [GIVEN] Item 'X'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Two duplicate lines in the 'Draft' price list, where "Asset No." is 'X', "Minimum Quantity" is 0, prices are different.
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], PriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], PriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");

        // [WHEN] Activate the price list
        PriceListHeader.Validate(Status, "Price Status"::Active);

        // [THEN] "Duplicate Prices" page is open, where are two lines for Item 'X'
        // [THEN] The first line, where "Remove" is 'No'
        Assert.AreEqual(PriceListLine[1]."Line No.", LibraryVariableStorage.DequeueInteger(), 'wrong line number in 1st line');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'wrong Remove in 1st line');
        // [THEN] The second line, where "Remove" is 'Yes'
        Assert.AreEqual(PriceListLine[2]."Line No.", LibraryVariableStorage.DequeueInteger(), 'wrong line number in 2nd line');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'wrong Remove in 2nd line');

        // [THEN] Price list is active, where is one (first) line.
        Assert.IsTrue(PriceListLine[1].Find(), 'active first line is not found');
        PriceListLine[1].TestField(Status, "Price Status"::Active);
        Assert.IsFalse(PriceListLine[2].Find(), 'active second line is found');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ThreeDuplicatePriceLinesModalHandler,ConfirmYesHandler')]
    procedure T031_ThreeDuplicatePriceLinesInTheSamePriceList()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[3] of Record "Price List Line";
    begin
        Initialize(true);
        // [GIVEN] Item 'X'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Three duplicate lines in the 'Draft' price list, where "Asset No." is 'X', "Minimum Quantity" is 0, prices are different.
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], PriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], PriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[3], PriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");

        // [WHEN] Activate the price list
        PriceListHeader.Validate(Status, "Price Status"::Active);

        // [THEN] "Duplicate Prices" page is open, where are three lines for Item 'X'
        // [THEN] The first line, where "Remove" is 'No'
        Assert.AreEqual(PriceListLine[1]."Line No.", LibraryVariableStorage.DequeueInteger(), 'wrong line number in 1st line');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'wrong Remove in 1st line');
        // [THEN] The second line, where "Remove" is 'Yes'
        Assert.AreEqual(PriceListLine[2]."Line No.", LibraryVariableStorage.DequeueInteger(), 'wrong line number in 2nd line');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'wrong Remove in 2nd line');
        // [THEN] The 3rd line, where "Remove" is 'Yes'
        Assert.AreEqual(PriceListLine[3]."Line No.", LibraryVariableStorage.DequeueInteger(), 'wrong line number in 2nd line');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'wrong Remove in 2nd line');

        // [THEN] Price list is active, where is one (first) line.
        Assert.IsTrue(PriceListLine[1].Find(), 'active first line is not found');
        PriceListLine[1].TestField(Status, "Price Status"::Active);
        Assert.IsFalse(PriceListLine[2].Find(), 'active second line is found');
        Assert.IsFalse(PriceListLine[3].Find(), 'active 3rd line is found');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TwoDuplicatePriceLinesModalHandler,ConfirmYesHandler')]
    procedure T032_TwoDuplicatePriceLinesInTwoPriceLists()
    var
        Item: Record Item;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
    begin
        Initialize(true);
        // [GIVEN] Item 'X'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Active Price List #1, where is one line with "Asset No." is 'X', "Minimum Quantity" is 0
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], PriceListHeader[1].Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
        PriceListHeader[1].Validate(Status, "Price Status"::Active);
        PriceListHeader[1].Modify(true);

        // [GIVEN] One duplicate line in the 'Draft' price list #2, where "Asset No." is 'X', "Minimum Quantity" is 0
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], PriceListHeader[2].Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");

        // [WHEN] Activate the price list #2
        PriceListHeader[2].Validate(Status, "Price Status"::Active);

        // [THEN] "Duplicate Prices" page is open, where are two lines for Item 'X' of two price lists
        // [THEN] The first line of price list #2, where "Remove" is 'No'
        Assert.AreEqual(PriceListLine[2]."Line No.", LibraryVariableStorage.DequeueInteger(), '(1) wrong line number in 1st line');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'wrong Remove in 1st line');
        // [THEN] The first line of price list #1, where "Remove" is 'Yes'
        Assert.AreEqual(PriceListLine[1]."Line No.", LibraryVariableStorage.DequeueInteger(), '(1) wrong line number in 2nd line');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'wrong Remove in 2nd line');

        // [THEN] Price list #2 is active, where is one (first) line.
        Assert.IsTrue(PriceListLine[2].Find(), 'active first line is not found');
        PriceListLine[2].TestField(Status, "Price Status"::Active);
        // [THEN] The first line of price list #1 is removed
        Assert.IsFalse(PriceListLine[1].Find(), 'active line of price list #2 is found');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TwoDuplicatePriceLinesModalHandler,ConfirmYesHandler')]
    procedure T033_ThreeDuplicatePriceLinesInTwoPriceLists()
    var
        Item: Record Item;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[3] of Record "Price List Line";
        SuggestPriceLinesUT: Codeunit "Suggest Price Lines UT";
        SalesPriceList: TestPage "Sales Price List";
    begin
        Initialize(true);
        BindSubscription(SuggestPriceLinesUT);
        // [GIVEN] Item 'X'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Active Price List #1, where is one line with "Asset No." is 'X', "Minimum Quantity" is 0
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], PriceListHeader[1].Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
        PriceListHeader[1].Validate(Status, "Price Status"::Active);
        PriceListHeader[1].Modify(true);

        // [GIVEN] Two duplicate lines in the 'Draft' price list #2, where "Asset No." is 'X', "Minimum Quantity" is 0, prices are different.
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], PriceListHeader[2].Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[3], PriceListHeader[2].Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");

        // [WHEN] Activate the price list #2
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader[2].Code);
        SalesPriceList.Status.SetValue("Price Status"::Active);

        // [THEN] "Duplicate Prices" page is open, where are two lines for Item 'X' of the same price list
        // [THEN] The first line of price list #2, where "Remove" is 'No'
        Assert.AreEqual(PriceListLine[2]."Line No.", LibraryVariableStorage.DequeueInteger(), '(1) wrong line number in 1st line');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'wrong Remove in 1st line');
        // [THEN] The second line of price list #2, where "Remove" is 'Yes'
        Assert.AreEqual(PriceListLine[3]."Line No.", LibraryVariableStorage.DequeueInteger(), '(1) wrong line number in 2nd line');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'wrong Remove in 2nd line');

        // [THEN] "Duplicate Prices" page is open, where are two lines for Item 'X' of different price lists
        // [THEN] The first line of price list #2, where "Remove" is 'No'
        Assert.AreEqual(PriceListLine[2]."Line No.", LibraryVariableStorage.DequeueInteger(), '(2) wrong line number in 1st line');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'wrong Remove in 1st line');
        // [THEN] The first line of price list #1, where "Remove" is 'Yes'
        Assert.AreEqual(PriceListLine[1]."Line No.", LibraryVariableStorage.DequeueInteger(), '(2) wrong line number in 2nd line');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'wrong Remove in 2nd line');

        // [THEN] Price list #2 is active, where is one (first) line.
        Assert.IsTrue(PriceListLine[2].Find(), 'active first line is not found');
        PriceListLine[2].TestField(Status, "Price Status"::Active);
        Assert.IsFalse(PriceListLine[3].Find(), 'active second line is found');
        // [THEN] The first line of price list #1 is removed
        Assert.IsFalse(PriceListLine[1].Find(), 'active line of price list #1 is found');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TwoDuplicatePriceLinesModalHandler,ConfirmYesHandler')]
    procedure T034_DuplicatePriceLineInTheSamePriceList()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
    begin
        Initialize(true);
        // [GIVEN] Item 'X'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Two duplicate lines in the 'Draft' price list, where "Asset No." is 'X', "Minimum Quantity" is 0, prices are different.
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], PriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], PriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");

        // [WHEN] Activate the price list
        PriceListHeader.Validate(Status, "Price Status"::Active);

        // [THEN] "Duplicate Prices" page is open, where are two lines for Item 'X'
        // [THEN] The first line, where "Remove" is 'No'
        Assert.AreEqual(PriceListLine[1]."Line No.", LibraryVariableStorage.DequeueInteger(), 'wrong line number in 1st line');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'wrong Remove in 1st line');
        // [THEN] The second line, where "Remove" is 'Yes'
        Assert.AreEqual(PriceListLine[2]."Line No.", LibraryVariableStorage.DequeueInteger(), 'wrong line number in 2nd line');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'wrong Remove in 2nd line');

        // [THEN] Price list is active, where is one (first) line.
        Assert.IsTrue(PriceListLine[1].Find(), 'active first line is not found');
        PriceListLine[1].TestField(Status, "Price Status"::Active);
        Assert.IsFalse(PriceListLine[2].Find(), 'active second line is found');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T035_ActivePriceListToDraft()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
    begin
        Initialize(true);
        // [GIVEN] Item 'X'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] 'Draft' price list, where "Asset No." is 'X', "Minimum Quantity" is 0, prices are different.
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], PriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");
        // [GIVEN] Activate the price list
        PriceListHeader.Validate(Status, "Price Status"::Active);

        // [WHEN] Deactivate the price list to 'Draft', answer 'Yes' to confirmation.
        PriceListHeader.Validate(Status, "Price Status"::Draft);

        // [THEN] Price list is active, where is one (first) line.
        Assert.IsTrue(PriceListLine[1].Find(), 'active first line is not found');
        PriceListLine[1].TestField(Status, "Price Status"::Draft);
    end;

    [Test]
    procedure T050_CanTurnRemoveOffInDuplicatePriceLine()
    var
        DuplicatePriceLine: Record "Duplicate Price Line";
        PriceListLine: array[2] of Record "Price List Line";
        LineNo: Integer;
    begin
        Initialize(false);

        // [GIVEN] Two duplicate price lines, where #2 has "Remove" as 'Yes'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, '');
        PriceListLine[2] := PriceListLine[1];
        PriceListLine[2]."Line No." := 0;
        PriceListLine[2].Insert();
        DuplicatePriceLine.Add(lineNo, PriceListLine[1], PriceListLine[2]);

        // [WHEN] Set "Remove" to 'No' in line #2
        DuplicatePriceLine.TestField(Remove, true);
        DuplicatePriceLine.Validate(Remove, false);

        // [THEN] "Remove" values are changed:
        // [THEN] Duplicate line #2, where "Remove" is 'No' 
        DuplicatePriceLine.TestField(Remove, false);
        // [THEN] Duplicate line #1, where "Remove" is 'Yes' 
        DuplicatePriceLine.Get(PriceListLine[1]."Price List Code", PriceListLine[1]."Line No.");
        DuplicatePriceLine.TestField(Remove, true);
    end;

    [Test]
    procedure T051_CannotTurnRemoveOnInDuplicatePriceLine()
    var
        DuplicatePriceLine: Record "Duplicate Price Line";
        PriceListLine: array[2] of Record "Price List Line";
        LineNo: Integer;
    begin
        Initialize(false);

        // [GIVEN] Two duplicate price lines, where #2 has "Remove" as 'Yes'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, '');
        PriceListLine[2] := PriceListLine[1];
        PriceListLine[2]."Line No." := 0;
        PriceListLine[2].Insert();
        DuplicatePriceLine.Add(lineNo, PriceListLine[1], PriceListLine[2]);

        // [WHEN] Set "Remove" to 'Yes' in the line #1
        DuplicatePriceLine.Get(PriceListLine[1]."Price List Code", PriceListLine[1]."Line No.");
        DuplicatePriceLine.TestField(Remove, false);
        DuplicatePriceLine.Validate(Remove, true);

        // [THEN] "Remove" values are not changed:
        // [THEN] Duplicate line #1, where "Remove" is 'No' 
        DuplicatePriceLine.TestField(Remove, false);
        // [THEN] Duplicate line #2, where "Remove" is 'Yes' 
        DuplicatePriceLine.Get(PriceListLine[2]."Price List Code", PriceListLine[2]."Line No.");
        DuplicatePriceLine.TestField(Remove, true);
    end;

    [Test]
    procedure T052_RevalidationOfRemoveDoesNotChangeDuplicatePriceLine()
    var
        DuplicatePriceLine: Record "Duplicate Price Line";
        PriceListLine: array[2] of Record "Price List Line";
        LineNo: Integer;
    begin
        Initialize(false);

        // [GIVEN] Two duplicate price lines, where #2 has "Remove" as 'Yes'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, '');
        PriceListLine[2] := PriceListLine[1];
        PriceListLine[2]."Line No." := 0;
        PriceListLine[2].Insert();
        DuplicatePriceLine.Add(lineNo, PriceListLine[1], PriceListLine[2]);
        // [WHEN] Revalidate "Remove" as 'Yes' in line #2
        DuplicatePriceLine.TestField(Remove, true);
        DuplicatePriceLine.Validate(Remove, true);

        // [THEN] "Remove" values are not changed:
        // [THEN] Duplicate line #2, where "Remove" is 'Yes' 
        DuplicatePriceLine.TestField(Remove, true);
        // [THEN] Duplicate line #1, where "Remove" is 'No' 
        DuplicatePriceLine.Get(PriceListLine[1]."Price List Code", PriceListLine[1]."Line No.");
        DuplicatePriceLine.TestField(Remove, false);
    end;

    [Test]
    procedure T053_ChangeRemoveOnThreeDuplicatePriceLines()
    var
        DuplicatePriceLine: Record "Duplicate Price Line";
        PriceListLine: array[3] of Record "Price List Line";
        LineNo: Integer;
    begin
        Initialize(false);

        // [GIVEN] Three duplicate price lines, where #2 and #3 have "Remove" as 'Yes'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, '');
        PriceListLine[2] := PriceListLine[1];
        PriceListLine[2]."Line No." := 0;
        PriceListLine[2].Insert();
        PriceListLine[3] := PriceListLine[1];
        PriceListLine[3]."Line No." := 0;
        PriceListLine[3].Insert();
        DuplicatePriceLine.Add(LineNo, PriceListLine[1], PriceListLine[2]);
        DuplicatePriceLine.Add(LineNo, 1, PriceListLine[3]);
        // [WHEN] Set "Remove" to 'No' in the line #2
        DuplicatePriceLine.Get(PriceListLine[2]."Price List Code", PriceListLine[2]."Line No.");
        DuplicatePriceLine.Validate(Remove, false);

        // [THEN] Duplicate line #2, where "Remove" is 'No' 
        DuplicatePriceLine.TestField(Remove, false);
        // [THEN] Duplicate line #1, where "Remove" is 'Yes' 
        DuplicatePriceLine.Get(PriceListLine[1]."Price List Code", PriceListLine[1]."Line No.");
        DuplicatePriceLine.TestField(Remove, true);
        // [THEN] Duplicate line #3, where "Remove" is 'Yes' 
        DuplicatePriceLine.Get(PriceListLine[3]."Price List Code", PriceListLine[3]."Line No.");
        DuplicatePriceLine.TestField(Remove, true);

        // [WHEN] Set "Remove" to 'No' in the line #3
        DuplicatePriceLine.Validate(Remove, false);

        // [THEN] Duplicate line #3, where "Remove" is 'No' 
        DuplicatePriceLine.TestField(Remove, false);
        // [THEN] Duplicate line #1, where "Remove" is 'Yes' 
        DuplicatePriceLine.Get(PriceListLine[1]."Price List Code", PriceListLine[1]."Line No.");
        DuplicatePriceLine.TestField(Remove, true);
        // [THEN] Duplicate line #2, where "Remove" is 'Yes' 
        DuplicatePriceLine.Get(PriceListLine[2]."Price List Code", PriceListLine[2]."Line No.");
        DuplicatePriceLine.TestField(Remove, true);
    end;

    [Test]
    procedure T055_DuplicatePriceLinesAddTwoLine()
    var
        DuplicatePriceLine: Record "Duplicate Price Line";
        PriceListLine: array[2] of Record "Price List Line";
        LineNo: Integer;
    begin
        Initialize(false);

        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, '');

        // [WHEN] Add two lines
        DuplicatePriceLine.Add(LineNo, PriceListLine[1], PriceListLine[2]);

        DuplicatePriceLine.FindSet();
        DuplicatePriceLine.TestField("Line No.", 1);
        DuplicatePriceLine.TestField("Duplicate To Line No.", 1);
        DuplicatePriceLine.TestField("Price List Code", PriceListLine[1]."Price List Code");
        DuplicatePriceLine.TestField("Price List Line No.", PriceListLine[1]."Line No.");
        DuplicatePriceLine.TestField(Remove, false);
        DuplicatePriceLine.Next();
        DuplicatePriceLine.TestField("Line No.", 2);
        DuplicatePriceLine.TestField("Duplicate To Line No.", 1);
        DuplicatePriceLine.TestField("Price List Code", PriceListLine[2]."Price List Code");
        DuplicatePriceLine.TestField("Price List Line No.", PriceListLine[2]."Line No.");
        DuplicatePriceLine.TestField(Remove, true);
    end;

    [Test]
    procedure T056_DuplicatePriceLinesAddOneLine()
    var
        DuplicatePriceLine: Record "Duplicate Price Line";
        PriceListLine: array[3] of Record "Price List Line";
        LineNo: Integer;
    begin
        Initialize(false);

        // [GIVEN] Two duplicate lines #1 and #2, where #2 is duplicate to #1.
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, '');
        DuplicatePriceLine.Add(LineNo, PriceListLine[1], PriceListLine[2]);

        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[3], '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, '');

        // [WHEN] Add one line as duplicate to #1
        DuplicatePriceLine.Add(LineNo, 1, PriceListLine[3]);

        // [THEN] Line #3, where "Line No." is 3, "Remove" is 'Yes'
        DuplicatePriceLine.Get(PriceListLine[3]."Price List Code", PriceListLine[3]."Line No.");
        DuplicatePriceLine.TestField("Line No.", 3);
        DuplicatePriceLine.TestField("Duplicate To Line No.", 1);
        DuplicatePriceLine.TestField(Remove, true);
    end;


    [Test]
    [HandlerFunctions('SalesPriceListsModalHandler')]
    procedure T090_LookupSalesPriceListsCancel()
    var
        PriceUXManagement: Codeunit "Price UX Management";
        PriceListCode: code[20];
    begin
        Initialize(true);

        // [WHEN] LookupPriceLists for Sale , Customer, <blank> Price List Code and click 'Cancel'
        LibraryVariableStorage.Enqueue(false); // to click Cancel
        Assert.IsFalse(
            PriceUXManagement.LookupPriceLists("Price Source Group"::Customer, "Price Type"::Sale, PriceListCode), 'Lookup result');

        // [THEN] Price List Code is blank.
        Assert.AreEqual('', PriceListCode, 'PriceListCode must be blank');
    end;

    [Test]
    [HandlerFunctions('SalesPriceListsModalHandler')]
    procedure T091_LookupSameSalesPriceList()
    var
        ToPriceListHeader: Record "Price List Header";
        PriceUXManagement: Codeunit "Price UX Management";
        PriceListCode: code[20];
    begin
        Initialize(true);

        // [GIVEN] New Sales Price List 'X'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        ToPriceListHeader.Description := ToPriceListHeader.Code;
        ToPriceListHeader.Modify();

        // [WHEN] LookupPriceLists for Price List Code 'X' 
        PriceListCode := ToPriceListHeader.Code;
        LibraryVariableStorage.Enqueue(true); // to click Ok
        LibraryVariableStorage.Enqueue(ToPriceListHeader.Description); // Description to pick
        asserterror PriceUXManagement.LookupPriceLists(ToPriceListHeader."Source Group", ToPriceListHeader."Price Type", PriceListCode);

        // [THEN] Error message: 'Cannot find document in the list'
        Assert.ExpectedError(CannotFindDocErr);
    end;

    [Test]
    [HandlerFunctions('SalesPriceListsModalHandler')]
    procedure T092_LookupSalesPriceListsOK()
    var
        FromPriceListHeader: Record "Price List Header";
        FromPriceListLine: Record "Price List Line";
        ToPriceListHeader: Record "Price List Header";
        PriceUXManagement: Codeunit "Price UX Management";
        PriceListCode: code[20];
    begin
        Initialize(true);

        // [GIVEN] Sales Price List 'A' with 'Item' line
        LibraryPriceCalculation.CreatePriceHeader(FromPriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        FromPriceListHeader.Description := FromPriceListHeader.Code;
        FromPriceListHeader.Modify();
        LibraryPriceCalculation.CreateSalesPriceLine(
            FromPriceListLine, FromPriceListHeader.Code, "Price Source Type"::"All Customers", '',
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        // [GIVEN] New Sales Price List 'X'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');

        // [WHEN] LookupPriceLists for Price List Code 'X' and click 'OK'
        PriceListCode := ToPriceListHeader.Code;
        LibraryVariableStorage.Enqueue(true); // to click Ok
        LibraryVariableStorage.Enqueue(FromPriceListHeader.Description); // Description to pick
        Assert.IsTrue(
            PriceUXManagement.LookupPriceLists(ToPriceListHeader."Source Group", ToPriceListHeader."Price Type", PriceListCode), 'Lookup result');

        // [THEN] returned Price List Code is 'A'.
        Assert.AreEqual(FromPriceListHeader.Code, PriceListCode, 'PriceListCode must be blank');
    end;

    [Test]
    [HandlerFunctions('SalesJobPriceListsModalHandler')]
    procedure T093_LookupSameSalesJobPriceList()
    var
        ToPriceListHeader: Record "Price List Header";
        PriceUXManagement: Codeunit "Price UX Management";
        PriceListCode: code[20];
    begin
        Initialize(true);

        // [GIVEN] New Sales Job Price List 'X'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        ToPriceListHeader.Description := ToPriceListHeader.Code;
        ToPriceListHeader.Modify();

        // [WHEN] LookupPriceLists for Price List Code 'X' 
        PriceListCode := ToPriceListHeader.Code;
        LibraryVariableStorage.Enqueue(true); // to click Ok
        LibraryVariableStorage.Enqueue(ToPriceListHeader.Description); // Description to pick
        asserterror PriceUXManagement.LookupPriceLists(ToPriceListHeader."Source Group", ToPriceListHeader."Price Type", PriceListCode);

        // [THEN] Error message: 'Cannot find document in the list'
        Assert.ExpectedError(CannotFindDocErr);
    end;

    [Test]
    [HandlerFunctions('SalesJobPriceListsModalHandler')]
    procedure T094_LookupSalesJobPriceListsOK()
    var
        FromPriceListHeader: Record "Price List Header";
        FromPriceListLine: Record "Price List Line";
        ToPriceListHeader: Record "Price List Header";
        PriceUXManagement: Codeunit "Price UX Management";
        PriceListCode: code[20];
    begin
        Initialize(true);

        // [GIVEN] Sales Job Price List 'A' with 'Item' line
        LibraryPriceCalculation.CreatePriceHeader(FromPriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        FromPriceListHeader.Description := FromPriceListHeader.Code;
        FromPriceListHeader.Modify();
        LibraryPriceCalculation.CreateSalesPriceLine(
            FromPriceListLine, FromPriceListHeader.Code, "Price Source Type"::"All Jobs", '',
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        // [GIVEN] New Sales Price List 'X'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Jobs", '');

        // [WHEN] LookupPriceLists for Price List Code 'X' and click 'OK'
        PriceListCode := ToPriceListHeader.Code;
        LibraryVariableStorage.Enqueue(true); // to click Ok
        LibraryVariableStorage.Enqueue(FromPriceListHeader.Description); // Description to pick
        Assert.IsTrue(
            PriceUXManagement.LookupPriceLists(ToPriceListHeader."Source Group", ToPriceListHeader."Price Type", PriceListCode), 'Lookup result');

        // [THEN] returned Price List Code is 'A'.
        Assert.AreEqual(FromPriceListHeader.Code, PriceListCode, 'PriceListCode must be blank');
    end;

    [Test]
    [HandlerFunctions('PurchasePriceListsModalHandler')]
    procedure T095_LookupSamePurchasePriceList()
    var
        ToPriceListHeader: Record "Price List Header";
        PriceUXManagement: Codeunit "Price UX Management";
        PriceListCode: code[20];
    begin
        Initialize(true);

        // [GIVEN] New Purchase Price List 'X'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        ToPriceListHeader.Description := ToPriceListHeader.Code;
        ToPriceListHeader.Modify();

        // [WHEN] LookupPriceLists for Price List Code 'X' 
        PriceListCode := ToPriceListHeader.Code;
        LibraryVariableStorage.Enqueue(true); // to click Ok
        LibraryVariableStorage.Enqueue(ToPriceListHeader.Description); // Description to pick
        asserterror PriceUXManagement.LookupPriceLists(ToPriceListHeader."Source Group", ToPriceListHeader."Price Type", PriceListCode);

        // [THEN] Error message: 'Cannot find document in the list'
        Assert.ExpectedError(CannotFindDocErr);
    end;

    [Test]
    [HandlerFunctions('PurchasePriceListsModalHandler')]
    procedure T096_LookupPurchasePriceListsOK()
    var
        FromPriceListHeader: Record "Price List Header";
        FromPriceListLine: Record "Price List Line";
        ToPriceListHeader: Record "Price List Header";
        PriceUXManagement: Codeunit "Price UX Management";
        PriceListCode: code[20];
    begin
        Initialize(true);

        // [GIVEN] Purchase Price List 'A' with 'Item' line
        LibraryPriceCalculation.CreatePriceHeader(FromPriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        FromPriceListHeader.Description := FromPriceListHeader.Code;
        FromPriceListHeader.Modify();
        LibraryPriceCalculation.CreatePurchPriceLine(
            FromPriceListLine, FromPriceListHeader.Code, "Price Source Type"::"All Vendors", '',
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        // [GIVEN] New Purchase Price List 'X'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');

        // [WHEN] LookupPriceLists for Price List Code 'X' and click 'OK'
        PriceListCode := ToPriceListHeader.Code;
        LibraryVariableStorage.Enqueue(true); // to click Ok
        LibraryVariableStorage.Enqueue(FromPriceListHeader.Description); // Description to pick
        Assert.IsTrue(
            PriceUXManagement.LookupPriceLists(ToPriceListHeader."Source Group", ToPriceListHeader."Price Type", PriceListCode), 'Lookup result');

        // [THEN] returned Price List Code is 'A'.
        Assert.AreEqual(FromPriceListHeader.Code, PriceListCode, 'PriceListCode must be blank');
    end;

    [Test]
    [HandlerFunctions('PurchaseJobPriceListsModalHandler')]
    procedure T097_LookupSamePurchaseJobPriceList()
    var
        ToPriceListHeader: Record "Price List Header";
        PriceUXManagement: Codeunit "Price UX Management";
        PriceListCode: code[20];
    begin
        Initialize(true);

        // [GIVEN] New Purchase Job Price List 'X'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');
        ToPriceListHeader.Description := ToPriceListHeader.Code;
        ToPriceListHeader.Modify();

        // [WHEN] LookupPriceLists for Price List Code 'X' 
        PriceListCode := ToPriceListHeader.Code;
        LibraryVariableStorage.Enqueue(true); // to click Ok
        LibraryVariableStorage.Enqueue(ToPriceListHeader.Description); // Description to pick
        asserterror PriceUXManagement.LookupPriceLists(ToPriceListHeader."Source Group", ToPriceListHeader."Price Type", PriceListCode);

        // [THEN] Error message: 'Cannot find document in the list'
        Assert.ExpectedError(CannotFindDocErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseJobPriceListsModalHandler')]
    procedure T098_LookupPurchaseJobPriceListsOK()
    var
        FromPriceListHeader: Record "Price List Header";
        FromPriceListLine: Record "Price List Line";
        ToPriceListHeader: Record "Price List Header";
        PriceUXManagement: Codeunit "Price UX Management";
        PriceListCode: code[20];
    begin
        Initialize(true);

        // [GIVEN] Purchase Job Price List 'A' with 'Item' line
        LibraryPriceCalculation.CreatePriceHeader(FromPriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');
        FromPriceListHeader.Description := FromPriceListHeader.Code;
        FromPriceListHeader.Modify();
        LibraryPriceCalculation.CreatePurchPriceLine(
            FromPriceListLine, FromPriceListHeader.Code, "Price Source Type"::"All Jobs", '',
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        // [GIVEN] New Purchase Price List 'X'
        LibraryPriceCalculation.CreatePriceHeader(ToPriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');

        // [WHEN] LookupPriceLists for Price List Code 'X' and click 'OK'
        PriceListCode := ToPriceListHeader.Code;
        LibraryVariableStorage.Enqueue(true); // to click Ok
        LibraryVariableStorage.Enqueue(FromPriceListHeader.Description); // Description to pick
        Assert.IsTrue(
            PriceUXManagement.LookupPriceLists(ToPriceListHeader."Source Group", ToPriceListHeader."Price Type", PriceListCode), 'Lookup result');

        // [THEN] returned Price List Code is 'A'.
        Assert.AreEqual(FromPriceListHeader.Code, PriceListCode, 'PriceListCode must be blank');
    end;

    [Test]
    [HandlerFunctions('SuggestLinesModalHandler')]
    procedure T100_SalesPriceAddItemLines()
    var
        Item: array[2] of Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListManagement: Codeunit "Price List Management";
        SuggestPriceLinesUT: Codeunit "Suggest Price Lines UT";
        SalesPriceList: TestPage "Sales Price List";
        MinQty: Decimal;
    begin
        // [FEATURE] [Sales]
        Initialize(true);
        BindSubscription(SuggestPriceLinesUT);
        // [GIVEN] Items 'A' and 'B' , where "Unit Price" is 'X' and 'Y'
        LibraryInventory.CreateItem(Item[1]);
        Item[1]."Unit Price" := LibraryRandom.RandDec(1000, 2);
        item[1].Modify();
        LibraryInventory.CreateItem(Item[2]);
        Item[2]."Unit Price" := LibraryRandom.RandDec(1000, 2);
        item[2].Modify();
        // [GIVEN] Sales Price List, where "Currency Code" is <blank>
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] Open sales price list page on Price List 'X' and run "Suggest Lines.." 
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [WHEN] Set "Asset Type" is 'Item', "Asset Filter" is 'A|B', "Minimum Quantity" is 5, no rounding and click 'Ok'
        Item[1].SetRange("No.", Item[1]."No.", Item[2]."No.");
        LibraryVariableStorage.Enqueue(Item[1].GetView()); // to "Asset Filter"
        MinQty := LibraryRandom.RandDec(100, 2);
        LibraryVariableStorage.Enqueue(MinQty); // "Minimum Quantity"
        SalesPriceList.SuggestLines.Invoke();

        // [THEN] Two price lines are added for Items 'A' and 'B' , where "Unit Price" is 'X' and 'Y', "Minimum Quantity" is 5
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        Assert.IsTrue(PriceListLine.FindSet(), 'The list is blank.');
        VerifyPriceLine(PriceListLine, Item[1], MinQty);
        Assert.IsTrue(PriceListLine.Next() <> 0, 'The second line not found.');
        VerifyPriceLine(PriceListLine, Item[2], MinQty);
        Assert.IsTrue(PriceListLine.Next() = 0, 'The third line must not exist.');
    end;

    [Test]
    [HandlerFunctions('SuggestLinesModalHandler')]
    procedure T101_PurchPriceAddItemLines()
    var
        Item: array[2] of Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListManagement: Codeunit "Price List Management";
        SuggestPriceLinesUT: Codeunit "Suggest Price Lines UT";
        PurchasePriceList: TestPage "Purchase Price List";
        MinQty: Decimal;
    begin
        // [FEATURE] [Purchase]
        Initialize(true);
        BindSubscription(SuggestPriceLinesUT);
        // [GIVEN] Items 'A' and 'B' , where "Last Direct Cost" is 'X' and 'Y'
        LibraryInventory.CreateItem(Item[1]);
        Item[1]."Last Direct Cost" := LibraryRandom.RandDec(1000, 2);
        item[1].Modify();
        LibraryInventory.CreateItem(Item[2]);
        Item[2]."Last Direct Cost" := LibraryRandom.RandDec(1000, 2);
        item[2].Modify();
        // [GIVEN] Purchase Price List, where "Currency Code" is <blank>
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        // [GIVEN] Open purchase price list page on Price List 'X' and run "Suggest Lines.." 
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [WHEN] Set "Asset Type" is 'Item', "Asset Filter" is 'A|B', "Minimum Quantity" is 5, no rounding and click 'Ok'
        Item[1].SetRange("No.", Item[1]."No.", Item[2]."No.");
        LibraryVariableStorage.Enqueue(Item[1].GetView()); // to "Asset Filter"
        MinQty := LibraryRandom.RandDec(100, 2);
        LibraryVariableStorage.Enqueue(MinQty); // "Minimum Quantity"
        PurchasePriceList.SuggestLines.Invoke();

        // [THEN] Two price lines are added for Items 'A' and 'B' , where "Unit Cost" is 'X' and 'Y', "Minimum Quantity" is 5
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        Assert.IsTrue(PriceListLine.FindSet(), 'The list is blank.');
        VerifyPriceLine(PriceListLine, Item[1], MinQty);
        Assert.IsTrue(PriceListLine.Next() <> 0, 'The second line not found.');
        VerifyPriceLine(PriceListLine, Item[2], MinQty);
        Assert.IsTrue(PriceListLine.Next() = 0, 'The third line must not exist.');
    end;

    [Test]
    procedure T102_SalesPriceAddResourceLines()
    var
        Resource: array[2] of Record Resource;
        PriceLineFilters: Record "Price Line Filters";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListManagement: Codeunit "Price List Management";
    begin
        // [FEATURE] [Sales] [Resource]
        Initialize(true);
        // [GIVEN] Resource 'A' and 'B' , where "Unit Price" is 'X' and 'Y'
        LibraryResource.CreateResource(Resource[1], '');
        Resource[1]."Unit Price" := LibraryRandom.RandDec(1000, 2);
        Resource[1].Modify();
        LibraryResource.CreateResource(Resource[2], '');
        Resource[2]."Unit Price" := LibraryRandom.RandDec(1000, 2);
        Resource[2].Modify();
        // [GIVEN] Sales Price List, where "Currency Code" is <blank>
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] PriceLineFilters, where "Asset Type" is 'Resource', "Asset Filter" is 'A|B', "Minimum Quantity" is 5, no rounding
        PriceLineFilters.Initialize(PriceListHeader, false);
        PriceLineFilters.Validate("Asset Type", "Price Asset Type"::Resource);
        Resource[1].SetRange("No.", Resource[1]."No.", Resource[2]."No.");
        PriceLineFilters."Asset Filter" := Resource[1].GetView();
        PriceLineFilters."Minimum Quantity" := 5;

        // [WHEN] AddLines()
        PriceListManagement.AddLines(PriceListHeader, PriceLineFilters);

        // [THEN] Two price lines are added for Resources 'A' and 'B' , where "Unit Price" is 'X' and 'Y', "Minimum Quantity" is 5
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        Assert.IsTrue(PriceListLine.FindSet(), 'The list is blank.');
        VerifyPriceLine(PriceListLine, Resource[1], 5);
        Assert.IsTrue(PriceListLine.Next() <> 0, 'The second line not found.');
        VerifyPriceLine(PriceListLine, Resource[2], 5);
        Assert.IsTrue(PriceListLine.Next() = 0, 'The third line must not exist.');
    end;

    [Test]
    procedure T103_PurchPriceAddResourceLines()
    var
        Resource: array[2] of Record Resource;
        PriceLineFilters: Record "Price Line Filters";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListManagement: Codeunit "Price List Management";
    begin
        // [FEATURE] [Purchase] [Resource]
        Initialize(true);
        // [GIVEN] Resources 'A' and 'B' , where "Direct Unit Cost" is 'X' and 'Y'
        LibraryResource.CreateResource(Resource[1], '');
        Resource[1]."Direct Unit Cost" := LibraryRandom.RandDec(1000, 2);
        Resource[1]."Unit Cost" := LibraryRandom.RandDec(1000, 2);
        Resource[1].Modify();
        LibraryResource.CreateResource(Resource[2], '');
        Resource[2]."Direct Unit Cost" := LibraryRandom.RandDec(1000, 2);
        Resource[2]."Unit Cost" := LibraryRandom.RandDec(1000, 2);
        Resource[2].Modify();
        // [GIVEN] Purchase Price List, where "Currency Code" is <blank>
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        // [GIVEN] PriceLineFilters, where "Asset Type" is 'Resource', "Asset Filter" is 'A|B', "Minimum Quantity" is 5, no rounding
        PriceLineFilters.Initialize(PriceListHeader, false);
        PriceLineFilters.Validate("Asset Type", "Price Asset Type"::Resource);
        Resource[1].SetRange("No.", Resource[1]."No.", Resource[2]."No.");
        PriceLineFilters."Asset Filter" := Resource[1].GetView();
        PriceLineFilters."Minimum Quantity" := 5;

        // [WHEN] AddLines()
        PriceListManagement.AddLines(PriceListHeader, PriceLineFilters);

        // [THEN] Two price lines are added for Resources 'A' and 'B' , where "Unit Cost" is 'X' and 'Y', "Minimum Quantity" is 5
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        Assert.IsTrue(PriceListLine.FindSet(), 'The list is blank.');
        VerifyPriceLine(PriceListLine, Resource[1], 5);
        Assert.IsTrue(PriceListLine.Next() <> 0, 'The second line not found.');
        VerifyPriceLine(PriceListLine, Resource[2], 5);
        Assert.IsTrue(PriceListLine.Next() = 0, 'The third line must not exist.');
    end;

    [Test]
    [HandlerFunctions('SuggestLinesExchRateDateModalHandler')]
    procedure T110_PriceListFCYAddLines()
    var
        CurrencyCode: Code[10];
        Item: Record Item;
        PriceLineFilters: Record "Price Line Filters";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListManagement: Codeunit "Price List Management";
        SuggestPriceLinesUT: Codeunit "Suggest Price Lines UT";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Purchase] [Item]
        Initialize(true);
        BindSubscription(SuggestPriceLinesUT);
        // [GIVEN] Currency 'C', where exchange rate is '2' on 01.01, '3' on 02.01.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 2, 2);
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 1, 3, 3);
        // [GIVEN] Items 'A', where "Unit Price" is 10.00
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := LibraryRandom.RandDec(1000, 2);
        item.Modify();
        // [GIVEN] Sales Price List, where "Currency Code" is 'C'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader.Validate("Currency Code", CurrencyCode);
        PriceListHeader.Modify(true);
        // [GIVEN] Open sales price list page on Price List 'X' and run "Suggest Lines.." 
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [WHEN] Set "Asset Type" is 'Item', "Asset Filter" is 'A', no rounding and click 'Ok'
        Item.SetRange("No.", Item."No.");
        LibraryVariableStorage.Enqueue(Item.GetView()); // to "Asset Filter"
        LibraryVariableStorage.Enqueue(WorkDate() + 1); // "Exchange Rate Date"
        SalesPriceList.SuggestLines.Invoke();

        // [THEN] One price line is added for Items 'A', where "Unit Price" is 30.00 
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        Assert.IsTrue(PriceListLine.FindFirst(), 'The list is blank.');
        PriceListLine.TestField("Unit Price", Item."Unit Price" * 3);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T111_PriceListFCYAddLinesWithAdjustment()
    var
        CurrencyCode: Code[10];
        Item: Record Item;
        PriceLineFilters: Record "Price Line Filters";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListManagement: Codeunit "Price List Management";
    begin
        Initialize(true);
        // [GIVEN] Currency 'C', where exchange rate is '2' 
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 2, 2);
        // [GIVEN] Items 'A', where "Unit Price" is 17.09
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := LibraryRandom.RandDec(1000, 2);
        item.Modify();
        // [GIVEN] Sales Price List, where "Currency Code" is 'C'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader.Validate("Currency Code", CurrencyCode);
        PriceListHeader.Modify(true);
        // [GIVEN] PriceLineFilters, where "Asset Type" is 'Item', "Asset Filter" is 'A|B', "Adjustment Factor" is 5, no rounding
        PriceLineFilters.Initialize(PriceListHeader, false);
        Item.SetRange("No.", Item."No.");
        PriceLineFilters."Asset Filter" := Item.GetView();
        PriceLineFilters."Adjustment Factor" := 5;

        // [WHEN] AddLines()
        PriceListManagement.AddLines(PriceListHeader, PriceLineFilters);

        // [THEN] One price line is added for Items 'A', where "Unit Price" is 170.90
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        Assert.IsTrue(PriceListLine.FindFirst(), 'The list is blank.');
        PriceListLine.TestField("Unit Price", Item."Unit Price" * PriceLineFilters."Adjustment Factor" * 2);
    end;

    [Test]
    procedure T112_PriceListFCYAddLinesWithCurrencyRounding()
    var
        Currency: Record Currency;
        Item: Record Item;
        PriceLineFilters: Record "Price Line Filters";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListManagement: Codeunit "Price List Management";
        ExpectedPrice: Decimal;
    begin
        Initialize(true);
        // [GIVEN] Currency 'C', where "Unit-Amount Rounding Precision" is 1
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));
        Currency."Unit-Amount Rounding Precision" := 1;
        Currency.Modify();
        // [GIVEN] Items 'A', where "Unit Price" is 158.12323
        LibraryInventory.CreateItem(Item);
        ExpectedPrice := LibraryRandom.RandInt(1000);
        Item."Unit Price" := ExpectedPrice + LibraryRandom.RandInt(5000) / 10000;
        item.Modify();
        // [GIVEN] Sales Price List, where "Currency Code" is 'C'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader.Validate("Currency Code", Currency.Code);
        PriceListHeader.Modify(true);
        // [GIVEN] PriceLineFilters, where "Asset Type" is 'Item', "Asset Filter" is 'A|B', no rounding method
        PriceLineFilters.Initialize(PriceListHeader, false);
        Item.SetRange("No.", Item."No.");
        PriceLineFilters."Asset Filter" := Item.GetView();

        // [WHEN] AddLines()
        PriceListManagement.AddLines(PriceListHeader, PriceLineFilters);

        // [THEN] One price line is added for Items 'A', where "Unit Price" is 158.00
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        Assert.IsTrue(PriceListLine.FindFirst(), 'The list is blank.');
        PriceListLine.TestField("Unit Price", ExpectedPrice);
    end;

    [Test]
    procedure T113_PriceListAddLinesWithRoundingMethod100()
    var
        Item: Record Item;
        PriceLineFilters: Record "Price Line Filters";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        RoundingMethod: Record "Rounding Method";
        PriceListManagement: Codeunit "Price List Management";
        ExpectedPrice: Decimal;
    begin
        Initialize(true);
        // [GIVEN] Rounding Method '100.99', where Precision is 100, "Amount Added After" is -0.01
        RoundingMethod.Code := '100.99';
        RoundingMethod.Precision := 100;
        RoundingMethod."Amount Added After" := -0.01;
        RoundingMethod.Insert();
        // [GIVEN] Item 'A', where "Unit Price" is 237.46
        LibraryInventory.CreateItem(Item);
        ExpectedPrice := LibraryRandom.RandInt(100) * 100;
        Item."Unit Price" := ExpectedPrice + LibraryRandom.RandInt(49) + LibraryRandom.RandInt(50) / 100;
        item.Modify();
        // [GIVEN] Sales Price List, where "Currency Code" is 'C'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] PriceLineFilters, where "Asset Type" is 'Item', "Asset Filter" is 'A|B', "Rounding Method Code" is '100.99'
        PriceLineFilters.Initialize(PriceListHeader, false);
        Item.SetRange("No.", Item."No.");
        PriceLineFilters."Asset Filter" := Item.GetView();
        PriceLineFilters."Rounding Method Code" := RoundingMethod.Code;

        // [WHEN] AddLines()
        PriceListManagement.AddLines(PriceListHeader, PriceLineFilters);

        // [THEN] One price line is added for Items 'A', where "Unit Price" is 199.99
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        Assert.IsTrue(PriceListLine.FindFirst(), 'The list is blank.');
        PriceListLine.TestField("Unit Price", ExpectedPrice - 0.01);
    end;

    local procedure Initialize(Enable: Boolean)
    var
        PriceListHeader: Record "Price List Header";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Suggest Price Lines UT");

        LibraryPriceCalculation.EnableExtendedPriceCalculation(Enable);
        PriceListHeader.ModifyAll(Status, PriceListHeader.Status::Draft);
        PriceListHeader.DeleteAll(true);

        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Suggest Price Lines UT");

        FillPriceListNos();

        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Suggest Price Lines UT");
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

    local procedure VerifyPriceLine(PriceListLine: Record "Price List Line"; Item: Record Item; MinQty: Decimal)
    begin
        PriceListLine.TestField("Asset Type", "Price Asset Type"::Item);
        PriceListLine.TestField("Asset No.", Item."No.");
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Minimum Quantity", MinQty);
        case PriceListLine."Price Type" of
            "Price Type"::Sale:
                begin
                    PriceListLine.TestField("Unit Price", Item."Unit Price");
                    PriceListLine.TestField("Direct Unit Cost", 0);
                    PriceListLine.TestField("Unit Cost", 0);
                end;
            "Price Type"::Purchase:
                begin
                    PriceListLine.TestField("Unit Price", 0);
                    PriceListLine.TestField("Direct Unit Cost", Item."Last Direct Cost");
                    PriceListLine.TestField("Unit Cost", Item."Unit Cost");
                end;
        end;
    end;

    local procedure VerifyPriceLine(PriceListLine: Record "Price List Line"; Resource: Record Resource; MinQty: Decimal)
    begin
        PriceListLine.TestField("Asset Type", "Price Asset Type"::Resource);
        PriceListLine.TestField("Asset No.", Resource."No.");
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Minimum Quantity", MinQty);
        case PriceListLine."Price Type" of
            "Price Type"::Sale:
                begin
                    PriceListLine.TestField("Unit Price", Resource."Unit Price");
                    PriceListLine.TestField("Direct Unit Cost", 0);
                    PriceListLine.TestField("Unit Cost", 0);
                end;
            "Price Type"::Purchase:
                begin
                    PriceListLine.TestField("Unit Price", 0);
                    PriceListLine.TestField("Unit Cost", Resource."Unit Cost");
                    PriceListLine.TestField("Direct Unit Cost", Resource."Direct Unit Cost");
                end;
        end;
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure SuggestPriceLinesModalHandler(var SuggestPriceLines: TestPage "Suggest Price Lines")
    begin
        Assert.IsTrue(SuggestPriceLines."Adjustment Factor".Visible(), '"Adjustment Factor".Visible');
        Assert.IsTrue(SuggestPriceLines."Rounding Method Code".Visible(), '"Rounding Method Code".Visible');

        Assert.IsTrue(SuggestPriceLines."From Price List Code".Visible(), '"From Price List Code".Visible');
        Assert.IsTrue(SuggestPriceLines."Price Line Filter".Visible(), '"Price Line Filter".Visible');

        Assert.IsFalse(SuggestPriceLines."Minimum Quantity".Visible(), '"Minimum Quantity".Visible');
        Assert.IsFalse(SuggestPriceLines."Product Type".Visible(), '"Product Type".Visible');
        Assert.IsFalse(SuggestPriceLines."Product Filter".Visible(), '"Product Filter".Visible');
        Assert.IsFalse(SuggestPriceLines."Exchange Rate Date".Visible(), '"Exchange Rate Date".Visible');

        SuggestPriceLines."From Price List Code".SetValue(LibraryVariableStorage.DequeueText());
        SuggestPriceLines."Adjustment Factor".SetValue(LibraryVariableStorage.DequeueDecimal());
        if LibraryVariableStorage.DequeueBoolean() then
            SuggestPriceLines.OK().Invoke()
        else
            SuggestPriceLines.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure SuggestLinesModalHandler(var SuggestPriceLines: TestPage "Suggest Price Lines")
    begin
        Assert.IsTrue(SuggestPriceLines."Adjustment Factor".Visible(), '"Adjustment Factor".Visible');
        Assert.IsTrue(SuggestPriceLines."Rounding Method Code".Visible(), '"Rounding Method Code".Visible');

        Assert.IsTrue(SuggestPriceLines."Product Type".Visible(), '"Product Type".Visible');
        Assert.IsTrue(SuggestPriceLines."Product Filter".Visible(), '"Product Filter".Visible');
        Assert.IsTrue(SuggestPriceLines."Minimum Quantity".Visible(), '"Minimum Quantity".Visible');

        Assert.IsFalse(SuggestPriceLines."From Price List Code".Visible(), '"From Price List Code".Visible');
        Assert.IsFalse(SuggestPriceLines."Price Line Filter".Visible(), '"Price Line Filter".Visible');
        Assert.IsFalse(SuggestPriceLines."Exchange Rate Date".Visible(), '"Exchange Rate Date".Visible');

        SuggestPriceLines."Product Type".SetValue('Item');
        SuggestPriceLines."Product Filter".SetValue(LibraryVariableStorage.DequeueText());
        SuggestPriceLines."Minimum Quantity".SetValue(LibraryVariableStorage.DequeueDecimal());
        SuggestPriceLines.OK().Invoke()
    end;

    [ModalPageHandler]
    procedure SuggestLinesExchRateDateModalHandler(var SuggestPriceLines: TestPage "Suggest Price Lines")
    begin
        Assert.IsTrue(SuggestPriceLines."Exchange Rate Date".Visible(), '"Exchange Rate Date".Visible');

        SuggestPriceLines."Product Type".SetValue('Item');
        SuggestPriceLines."Product Filter".SetValue(LibraryVariableStorage.DequeueText());
        SuggestPriceLines."Exchange Rate Date".SetValue(LibraryVariableStorage.DequeueDate());
        SuggestPriceLines.OK().Invoke()
    end;

    [ModalPageHandler]
    procedure SuggestPriceLinesFCYModalHandler(var SuggestPriceLines: TestPage "Suggest Price Lines")
    begin
        SuggestPriceLines."From Price List Code".SetValue(LibraryVariableStorage.DequeueText());

        Assert.IsTrue(SuggestPriceLines."Exchange Rate Date".Visible(), '"Exchange Rate Date".Visible');
        SuggestPriceLines."Exchange Rate Date".AssertEquals(WorkDate());

        SuggestPriceLines."Adjustment Factor".SetValue(LibraryVariableStorage.DequeueDecimal());
        SuggestPriceLines."Exchange Rate Date".SetValue(LibraryVariableStorage.DequeueDate());
        SuggestPriceLines.OK().Invoke()
    end;

    [ModalPageHandler]
    procedure SuggestPriceLinesFCYLookupModalHandler(var SuggestPriceLines: TestPage "Suggest Price Lines")
    begin
        SuggestPriceLines."From Price List Code".Lookup();//.SetValue(LibraryVariableStorage.DequeueText());

        Assert.IsTrue(SuggestPriceLines."Exchange Rate Date".Visible(), '"Exchange Rate Date".Visible');
        SuggestPriceLines."Exchange Rate Date".AssertEquals(WorkDate());

        SuggestPriceLines."Adjustment Factor".SetValue(LibraryVariableStorage.DequeueDecimal());
        SuggestPriceLines."Exchange Rate Date".SetValue(LibraryVariableStorage.DequeueDate());
        SuggestPriceLines.OK().Invoke()
    end;

    [ModalPageHandler]
    procedure PurchasePriceListsModalHandler(var PurchasePriceLists: TestPage "Purchase Price Lists")
    begin
        if LibraryVariableStorage.DequeueBoolean() then begin
            PurchasePriceLists.Filter.SetFilter(Description, LibraryVariableStorage.DequeueText());
            Assert.IsTrue(PurchasePriceLists.First(), CannotFindDocErr);
            PurchasePriceLists.OK().Invoke()
        end else
            PurchasePriceLists.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure PurchaseJobPriceListsModalHandler(var PurchaseJobPriceLists: TestPage "Purchase Job Price Lists")
    begin
        if LibraryVariableStorage.DequeueBoolean() then begin
            PurchaseJobPriceLists.Filter.SetFilter(Description, LibraryVariableStorage.DequeueText());
            Assert.IsTrue(PurchaseJobPriceLists.First(), CannotFindDocErr);
            PurchaseJobPriceLists.OK().Invoke()
        end else
            PurchaseJobPriceLists.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure SalesPriceListsModalHandler(var SalesPriceLists: TestPage "Sales Price Lists")
    begin
        if LibraryVariableStorage.DequeueBoolean() then begin
            SalesPriceLists.Filter.SetFilter(Description, LibraryVariableStorage.DequeueText());
            Assert.IsTrue(SalesPriceLists.First(), CannotFindDocErr);
            SalesPriceLists.OK().Invoke()
        end else
            SalesPriceLists.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure SalesJobPriceListsModalHandler(var SalesJobPriceLists: TestPage "Sales Job Price Lists")
    begin
        if LibraryVariableStorage.DequeueBoolean() then begin
            SalesJobPriceLists.Filter.SetFilter(Description, LibraryVariableStorage.DequeueText());
            Assert.IsTrue(SalesJobPriceLists.First(), CannotFindDocErr);
            SalesJobPriceLists.OK().Invoke()
        end else
            SalesJobPriceLists.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure TwoDuplicatePriceLinesModalHandler(var DuplicatePriceLines: TestPage "Duplicate Price Lines")
    begin
        // Expects two lines, returns two pairs : (LineNo, Remove)
        Assert.IsTrue(DuplicatePriceLines.First(), 'not found the first line');
        StoreVarLineNoRemove(DuplicatePriceLines);

        Assert.IsTrue(DuplicatePriceLines.Next(), 'not found the second line');
        StoreVarLineNoRemove(DuplicatePriceLines);

        Assert.IsFalse(DuplicatePriceLines.Next(), 'found the 3rd line');
        DuplicatePriceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ThreeDuplicatePriceLinesModalHandler(var DuplicatePriceLines: TestPage "Duplicate Price Lines")
    begin
        // Expects two lines, returns two pairs : (LineNo, Remove)
        Assert.IsTrue(DuplicatePriceLines.First(), 'not found the first line');
        StoreVarLineNoRemove(DuplicatePriceLines);

        Assert.IsTrue(DuplicatePriceLines.Next(), 'not found the second line');
        StoreVarLineNoRemove(DuplicatePriceLines);

        Assert.IsTrue(DuplicatePriceLines.Next(), 'not found the third line');
        StoreVarLineNoRemove(DuplicatePriceLines);

        Assert.IsFalse(DuplicatePriceLines.Next(), 'found the 4th line');
        DuplicatePriceLines.OK().Invoke();
    end;

    local procedure StoreVarLineNoRemove(var DuplicatePriceLines: TestPage "Duplicate Price Lines")
    var
        LineNo: Integer;
        Remove: Boolean;
    begin
        Evaluate(LineNo, DuplicatePriceLines."Price List Line No.".Value());
        LibraryVariableStorage.Enqueue(LineNo);
        Evaluate(Remove, DuplicatePriceLines.Remove.Value());
        LibraryVariableStorage.Enqueue(Remove);
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
