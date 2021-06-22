codeunit 134159 "Test Price Calculation - V16"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Lowest Price]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Price Calculation - V16");
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Price Calculation - V16");
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Price Calculation - V16");
    end;

    [Test]
    procedure T010_SalesLineAddsActivatedCampaignOnHeaderAsSource()
    var
        Campaign: Array[5] of Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceType: Enum "Price Type";
    begin
        // [FEATURE] [Sales] [Campaign] [UT]
        Initialize();
        // [GIVEN] Customer 'A' has one activated Campaign 'CustCmp', "Primary Contact No." is 'C'
        // [GIVEN] Contact 'C' has one activated Campaign 'ContCmp'
        CreateCustomerWithContactAndActivatedCampaigns(Customer, Contact, Campaign, False);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Invoice for customer 'A', where 'Campaign No.' is 'HdrCmp'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Campaign No.", Campaign[1]."No.");
        SalesHeader.Modify(true);
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X'
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Modify(true);

        // [WHEN] SetLine()
        SalesLinePrice.SetLine(PriceType::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources contains one Campaign 'HdrCmp'
        VerifyCampaignSource(SalesLinePrice, Campaign[1]."No.", 1);
    end;

    [Test]
    procedure T011_SalesLineAddsActivatedCustomerCampaignAsSource()
    var
        Campaign: Array[5] of Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceType: Enum "Price Type";
    begin
        // [FEATURE] [Sales] [Campaign] [UT]
        Initialize();
        // [GIVEN] Customer 'A' has one activated Campaign 'CustCmp', "Primary Contact No." is 'C'
        // [GIVEN] Contact 'C' has one activated Campaign 'ContCmp'
        CreateCustomerWithContactAndActivatedCampaigns(Customer, Contact, Campaign, False);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Invoice for customer 'A', where 'Campaign No.' is <blank>
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X'
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Modify(true);

        // [WHEN] SetLine()
        SalesLinePrice.SetLine(PriceType::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources contains one Campaign 'CustCmp'
        VerifyCampaignSource(SalesLinePrice, Campaign[2]."No.", 2);
        VerifyCampaignSource(SalesLinePrice, Campaign[3]."No.", 2);
    end;

    [Test]
    procedure T012_SalesLineAddsActivatedContactCampaignAsSource()
    var
        Campaign: Array[5] of Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceType: Enum "Price Type";
    begin
        // [FEATURE] [Sales] [Campaign] [UT]
        Initialize();
        // [GIVEN] Customer 'A' has none activated Campaigns, "Primary Contact No." is 'C'
        // [GIVEN] Contact 'C' has one activated Campaign 'ContCmp'
        CreateCustomerWithContactAndActivatedCampaigns(Customer, Contact, Campaign, True);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Invoice for customer 'A', where 'Campaign No.' is <blank>
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X'
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Modify(true);

        // [WHEN] SetLine()
        SalesLinePrice.SetLine(PriceType::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources contains one Campaign 'ContCmp'
        VerifyCampaignSource(SalesLinePrice, Campaign[4]."No.", 2);
        VerifyCampaignSource(SalesLinePrice, Campaign[5]."No.", 2);
    end;

    local procedure CreateCustomerWithContactAndActivatedCampaigns(var Customer: Record Customer; var Contact: Record Contact; var Campaign: Array[5] of Record Campaign; SkipCustomerCampaign: Boolean)
    var
        CampaignTargetGr: Record "Campaign Target Group";
        i: Integer;
    begin
        LibraryMarketing.CreateCampaign(Campaign[1]);

        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        if not SkipCustomerCampaign then begin

            CampaignTargetGr.Init();
            CampaignTargetGr.Type := CampaignTargetGr.Type::Customer;
            CampaignTargetGr."No." := Customer."No.";
            for i := 2 to 3 do begin
                LibraryMarketing.CreateCampaign(Campaign[i]);
                CampaignTargetGr."Campaign No." := Campaign[i]."No.";
                CampaignTargetGr.Insert();
            end;
        end;

        CampaignTargetGr.Init();
        CampaignTargetGr.Type := CampaignTargetGr.Type::Contact;
        CampaignTargetGr."No." := Contact."No.";
        for i := 4 to 5 do begin
            LibraryMarketing.CreateCampaign(Campaign[i]);
            CampaignTargetGr."Campaign No." := Campaign[i]."No.";
            CampaignTargetGr.Insert();
        end;
    end;

    local procedure VerifyCampaignSource(SalesLinePrice: Codeunit "Sales Line - Price"; CampaignNo: code[20]; ExpectedCount: Integer)
    var
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        TempPriceSource: Record "Price Source" temporary;
    begin
        SalesLinePrice.CopyToBuffer(PriceCalculationBufferMgt);
        PriceCalculationBufferMgt.GetSources(TempPriceSource);
        TempPriceSource.SetRange("Source Type", TempPriceSource."Source Type"::Campaign);
        Assert.RecordCount(TempPriceSource, ExpectedCount);
        TempPriceSource.SetRange("Source No.", CampaignNo);
        TempPriceSource.FindFirst();
    end;

    [Test]
    procedure T050_ApplyDiscountSalesLineCalculateDiscIfAllowLineDiscFalseV15()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceCalculationSetup: Record "Price Calculation Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineDiscount: Record "Sales Line Discount";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculation: interface "Price Calculation";
        LineWithPrice: Interface "Line With Price";
        PriceCalculationHandler: Enum "Price Calculation Handler";
        ExpectedDiscount: Decimal;
        Line: Variant;
    begin
        // [FEATURE] [Sales] [Discount] [UT] [V15]
        // [SCENARIO] ApplyDiscount() updates 'Line Discount %' in sales line even if "Allow Line Disc." is false.
        Initialize();
        // [GIVEN] "Sales Line discount" record for Customer and Item 'X': 15%
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        ExpectedDiscount := LibraryRandom.RandInt(50);
        CreateCustomerItemDiscount(SalesLineDiscount, Customer."No.", Item, ExpectedDiscount);

        // [GIVEN] Invoice, where "Price Calculation Method" is "Lowest Price" 
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', and "Line Discount %" is 0
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine."Bill-to Customer No." := SalesHeader."Bill-to Customer No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine."Allow Line Disc." := false;
        SalesLine.Modify(true);

        // [WHEN] ApplyDiscount() for the sales line
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, PriceCalculationSetup.Method::"Lowest Price",
            PriceCalculationSetup.Type::Sale, PriceCalculationSetup."Asset Type"::" ",
            Codeunit::"Price Calculation - V15", true);

        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine(PriceCalculationSetup.Type::Sale, SalesHeader, SalesLine);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.Init(LineWithPrice, PriceCalculationSetup);
        PriceCalculation.ApplyDiscount();

        // [THEN] Line, where "Line Discount %" is 15%
        PriceCalculation.GetLine(Line);
        SalesLine := Line;
        SalesLine.TestField("Allow Line Disc.", false);
        SalesLine.TestField("Line Discount %", ExpectedDiscount);
    end;

    [Test]
    procedure T051_ApplyDiscountSalesLineCalculateDiscIfAllowLineDiscFalseV16()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineDiscount: Record "Sales Line Discount";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculation: interface "Price Calculation";
        LineWithPrice: Interface "Line With Price";
        PriceCalculationHandler: Enum "Price Calculation Handler";
        ExpectedDiscount: Decimal;
        Line: Variant;
    begin
        // [FEATURE] [Sales] [Discount] [UT]
        // [SCENARIO] ApplyDiscount() updates 'Line Discount %' in sales line even if "Allow Line Disc." is false.
        Initialize();
        // [GIVEN] "Sales Line discount" record for Customer and Item 'X': 15%
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        ExpectedDiscount := LibraryRandom.RandInt(50);
        CreateCustomerItemDiscount(SalesLineDiscount, Customer."No.", Item, ExpectedDiscount);
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);

        // [GIVEN] Invoice, where "Price Calculation Method" is "Lowest Price" 
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', and "Line Discount %" is 0
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine."Bill-to Customer No." := SalesHeader."Bill-to Customer No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine."Allow Line Disc." := false;
        SalesLine.Modify(true);

        // [WHEN] ApplyDiscount() for the sales line
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, PriceCalculationSetup.Method::"Lowest Price",
            PriceCalculationSetup.Type::Sale, PriceCalculationSetup."Asset Type"::" ",
            Codeunit::"Price Calculation - V16", true);

        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine(PriceCalculationSetup.Type::Sale, SalesHeader, SalesLine);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.Init(LineWithPrice, PriceCalculationSetup);
        PriceCalculation.ApplyDiscount();

        // [THEN] Line, where "Line Discount %" is 15%
        PriceCalculation.GetLine(Line);
        SalesLine := Line;
        SalesLine.TestField("Allow Line Disc.", false);
        SalesLine.TestField("Line Discount %", ExpectedDiscount);
    end;

    [Test]
    procedure T060_CalcBestAmountPicksBestPriceOfTwoBestFirst()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        PriceSourceList: codeunit "Price Source List";
        AmountType: Enum "Price Amount Type";
    begin
        // [FEATURE] [UT]
        // [GIVEN] Buffer where Quantity = 1, "Currency Code" = <blank>
        MockBuffer('', 1, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is blank, "Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, '', '', 15);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount(AmountType::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #1 is picked
        TempPriceListLine.TestField("Line No.", 1);
    end;

    [Test]
    procedure T061_CalcBestAmountPicksBestPriceOfTwoBestSecond()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        PriceSourceList: codeunit "Price Source List";
        AmountType: Enum "Price Amount Type";
    begin
        // [FEATURE] [UT]
        // [GIVEN] Buffer where Quantity = 1, "Currency Code" = <blank>
        MockBuffer('', 1, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Unit Price" is 15 (is worse that the second price line)
        AddPriceLine(TempPriceListLine, '', '', 15);
        // [GIVEN] Price line #2, where "Currency Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, '', '', 10);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount(AmountType::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #2 is picked
        TempPriceListLine.TestField("Line No.", 2);
    end;

    [Test]
    procedure T062_CalcBestAmountWorsePriceButFilledCurrencyCode()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        AmountType: Enum "Price Amount Type";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer(CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, CurrencyCode, '', 15);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount(AmountType::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #2 is picked
        TempPriceListLine.TestField("Line No.", 2);
    end;

    [Test]
    procedure T063_CalcBestAmountAmongPricesWhereFilledCurrencyCode()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        AmountType: Enum "Price Amount Type";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer(CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, CurrencyCode, '', 15);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Unit Price" is 16 (is worse that the second price line)
        AddPriceLine(TempPriceListLine, CurrencyCode, '', 16);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount(AmountType::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #2 is picked
        TempPriceListLine.TestField("Line No.", 2);
    end;

    [Test]
    procedure T064_CalcBestAmountAmongPricesWhereFilledCurrencyCodeOrVariantCodeSecond()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        AmountType: Enum "Price Amount Type";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        VariantCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Variant code 'A'
        VariantCode := 'A';
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer(CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Variant Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Variant Code" is blank,"Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, CurrencyCode, '', 15);
        // [GIVEN] Price line #3, where "Currency Code" is blank, "Variant Code" is 'A', "Unit Price" is 16 (is worse that the second price line)
        AddPriceLine(TempPriceListLine, '', VariantCode, 16);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount(AmountType::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #2 is picked
        TempPriceListLine.TestField("Line No.", 2);
    end;

    [Test]
    procedure T065_CalcBestAmountAmongPricesWhereFilledCurrencyCodeOrVariantCodeThird()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        AmountType: Enum "Price Amount Type";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        VariantCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Variant code 'A'
        VariantCode := 'A';
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer(CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Variant Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Variant Code" is blank,"Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, CurrencyCode, '', 15);
        // [GIVEN] Price line #3, where "Currency Code" is blank, "Variant Code" is 'A', "Unit Price" is 11 (is better that the second price line)
        AddPriceLine(TempPriceListLine, '', VariantCode, 11);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount(AmountType::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #3 is picked
        TempPriceListLine.TestField("Line No.", 3);
    end;

    [Test]
    procedure T066_CalcBestAmountAmongPricesWhereFilledCurrencyCodeAndVariantCode()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        AmountType: Enum "Price Amount Type";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        VariantCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Variant code 'A'
        VariantCode := 'A';
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer(CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Variant Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Variant Code" is blank,"Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, CurrencyCode, '', 15);
        // [GIVEN] Price line #3, where "Currency Code" is blank, "Variant Code" is 'A', "Unit Price" is 14 (is better that the second price line)
        AddPriceLine(TempPriceListLine, '', VariantCode, 14);
        // [GIVEN] Price line #4, where "Currency Code" is 'X', "Variant Code" is 'A', "Unit Price" is 20 (is worse of all price lines)
        AddPriceLine(TempPriceListLine, CurrencyCode, VariantCode, 20);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount(AmountType::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #4 is picked
        TempPriceListLine.TestField("Line No.", 4);
    end;

    [Test]
    procedure T067_CalcBestAmountAmongPricesWhereFilledCurrencyCodeAndVariantCodeOfTwo()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        AmountType: Enum "Price Amount Type";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        VariantCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Variant code 'A'
        VariantCode := 'A';
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer(CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is 'X', "Variant Code" is 'A', "Unit Price" is 10
        AddPriceLine(TempPriceListLine, CurrencyCode, VariantCode, 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Variant Code" is blank,"Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, CurrencyCode, '', 15);
        // [GIVEN] Price line #3, where "Currency Code" is blank, "Variant Code" is 'A', "Unit Price" is 14 (is better that the second price line)
        AddPriceLine(TempPriceListLine, '', VariantCode, 14);
        // [GIVEN] Price line #4, where "Currency Code" is 'X', "Variant Code" is 'A', "Unit Price" is 20 (is worse of all price lines)
        AddPriceLine(TempPriceListLine, CurrencyCode, VariantCode, 20);
        // [GIVEN] Price line #5, where "Currency Code" is blank, "Variant Code" is blank, "Unit Price" is 7 (the best)
        AddPriceLine(TempPriceListLine, '', '', 7);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount(AmountType::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #1 is picked
        TempPriceListLine.TestField("Line No.", 1);
    end;

    [Test]
    procedure T110_ApplyDiscountSalesLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineDiscount: Record "Sales Line Discount";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PriceCalculation: interface "Price Calculation";
        PriceType: Enum "Price Type";
        ExpectedDiscount: Decimal;
        Header: Variant;
        Line: Variant;
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] ApplyDiscount() updates 'Line Discount %' in sales line.
        Initialize();
        // [GIVEN] 2 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'A' - default
        with PriceCalculationSetup[5] do begin
            DeleteAll();
            LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], Method::"Lowest Price", Type::Sale, "Asset Type"::" ", Codeunit::"Price Calculation - V15", true);
            LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], Method::"Lowest Price", Type::Sale, "Asset Type"::" ", Codeunit::"Price Calculation - V16", false);
        end;
        // [GIVEN] Two "Sales Line discount" records for Item 'X': 15% and 14.99%
        SalesLineDiscount.DeleteAll();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        ExpectedDiscount := LibraryRandom.RandInt(50);
        CreateCustomerItemDiscount(SalesLineDiscount, Customer."No.", Item, ExpectedDiscount - 0.01);
        CreateAllCustomerItemDiscount(SalesLineDiscount, Item, ExpectedDiscount);

        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);

        // [GIVEN] Invoice, where "Price Calculation Method" is "Lowest Price" 
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', and "Line Discount %" is 0
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine."Bill-to Customer No." := SalesHeader."Bill-to Customer No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Modify(true);

        // [WHEN] ApplyDiscount() for the sales line
        SalesLinePrice.SetLine(PriceType::Sale, SalesHeader, SalesLine);
        PriceCalculationMgt.GetHandler(SalesLinePrice, PriceCalculation);
        PriceCalculation.ApplyDiscount();
        PriceCalculation.GetLine(Line);
        SalesLine := Line;

        // [THEN] Line, where "Line Discount %" is 15%
        SalesLine.TestField("Line Discount %", ExpectedDiscount);
    end;

    [Test]
    procedure T111_ApplyPriceSalesLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PriceCalculation: interface "Price Calculation";
        PriceType: Enum "Price Type";
        AmountType: enum "Price Amount Type";
        ExpectedPrice: Decimal;
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] ApplyPrice() updates 'Unit Price' in sales line.
        Initialize();
        // [GIVEN] 2 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'A' - default
        with PriceCalculationSetup[5] do begin
            DeleteAll();
            LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], Method::"Lowest Price", Type::Sale, "Asset Type"::" ", Codeunit::"Price Calculation - V15", true);
            LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], Method::"Lowest Price", Type::Sale, "Asset Type"::" ", Codeunit::"Price Calculation - V16", false);
        end;

        // [GIVEN] Item 'X', where "Unit Price" is 100
        ExpectedPrice := LibraryRandom.RandDec(1000, 2);
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := ExpectedPrice + 0.02;
        Item.Modify();
        // [GIVEN] Sales prices for Item 'X': 99.99 and 99.98
        LibrarySales.CreateCustomer(Customer);
        SalesPrice.DeleteAll();
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", SalesPrice."Sales Type"::Customer, Customer."No.",
            WorkDate, '', '', Item."Base Unit of Measure", 0, ExpectedPrice);
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", SalesPrice."Sales Type"::"All Customers", '',
            WorkDate, '', '', Item."Base Unit of Measure", 0, ExpectedPrice + 0.01);
        //if TestPriceCalculationSwitch.IsNativeDisabled() then
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // [GIVEN] Invoice, where "Price Calculation Method" is not defined 
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', and "Unit Price" is 0
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Quantity := 1;
        SalesLine.Modify(true);

        // [WHEN] ApplyPrice for the sales line
        SalesLinePrice.SetLine(PriceType::Sale, SalesHeader, SalesLine);
        PriceCalculationMgt.GetHandler(SalesLinePrice, PriceCalculation);
        SalesLine.ApplyPrice(SalesLine.FieldNo(Quantity), PriceCalculation);

        // [THEN] Line, where "Unit Price" is 99.98, "Price Calculation Method" is 'Lowest Price'
        SalesLine.TestField("Unit Price", ExpectedPrice);
        // SalesLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method"::"Lowest Price");
    end;

    [Test]
    procedure T120_ApplyDiscountServiceLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        ServiceLinePrice: Codeunit "Service Line - Price";
        PriceCalculationMgt: codeunit "Price Calculation Mgt.";
        PriceCalculation: interface "Price Calculation";
        Line: Variant;
        PriceType: Enum "Price Type";
        ExpectedDiscount: Decimal;
    begin
        // [FEATURE] [Service] [Discount]
        // [SCENARIO] ApplyDiscount updates 'Unit Price' in service line.
        Initialize();
        // [GIVEN] 2 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'A' - default
        with PriceCalculationSetup[5] do begin
            DeleteAll();
            LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], Method::"Lowest Price", Type::Sale, "Asset Type"::" ", Codeunit::"Price Calculation - V15", true);
            LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], Method::"Lowest Price", Type::Sale, "Asset Type"::" ", Codeunit::"Price Calculation - V16", false);
        end;
        ExpectedDiscount := LibraryRandom.RandInt(100);
        /*
        ServiceLine."Price Calculation Method" := ServiceLine."Price Calculation Method"::" ";

        ServiceLinePrice.SetLine(PriceType::Sale, ServiceHeader, ServiceLine);
        PriceCalculationMgt.GetHandler(ServiceLinePrice, PriceCalculation);
        PriceCalculation.ApplyDiscount();
        PriceCalculation.GetLine(Line);
        ServiceLine := Line;
        */
        // [THEN] Line, where "Line Discount %" is 15%
        asserterror ServiceLine.TestField("Line Discount %", ExpectedDiscount);
        Assert.KnownFailure('Line Discount % must be equal to', 303311);
    end;

    [Test]
    procedure T130_ApplyDiscountPurchLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
        PriceCalculationMgt: codeunit "Price Calculation Mgt.";
        PriceCalculation: interface "Price Calculation";
        PriceType: Enum "Price Type";
        Line: Variant;
        ExpectedDiscount: Decimal;
    begin
        // [FEATURE] [Purchase] [Discount]
        // [SCENARIO] ApplyDiscount updates 'Direct Unit Cost' in purchase line.
        Initialize();
        // [GIVEN] 2 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'A' - default
        with PriceCalculationSetup[5] do begin
            DeleteAll();
            LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], Method::"Lowest Price", Type::Purchase, "Asset Type"::" ", Codeunit::"Price Calculation - V15", true);
            LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], Method::"Lowest Price", Type::Purchase, "Asset Type"::" ", Codeunit::"Price Calculation - V16", false);
        end;
        ExpectedDiscount := LibraryRandom.RandInt(100);
        /*
        PurchaseLinePrice.SetLine(PriceType::Purchase, PurchaseHeader, PurchaseLine);
        PriceCalculationMgt.GetHandler(PurchaseLinePrice, PriceCalculation);
        PriceCalculation.ApplyDiscount();
        PriceCalculation.GetLine(Line);
        PurchaseLine := Line;
        */
        // [THEN] Line, where "Line Discount %" is 15%
        asserterror PurchaseLine.TestField("Line Discount %", ExpectedDiscount);
        Assert.KnownFailure('Line Discount % must be equal to', 303311);
    end;

    [Test]
    procedure T140_ApplyDiscountRequisitionLine()
    var
        RequisitionLine: Record "Requisition Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        PriceCalculationMgt: codeunit "Price Calculation Mgt.";
        RequisitionLinePrice: Codeunit "Requisition Line - Price";
        PriceCalculation: interface "Price Calculation";
        PriceType: Enum "Price Type";
        Line: Variant;
        ExpectedDiscount: Decimal;
    begin
        // [FEATURE] [Requisition] [Discount]
        // [SCENARIO] ApplyDiscount updates 'Unit Amount' in requisition line.
        Initialize();
        with PriceCalculationSetup[5] do begin
            DeleteAll();
            LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], Method::"Lowest Price", Type::Purchase, "Asset Type"::" ", Codeunit::"Price Calculation - V15", true);
            LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], Method::"Lowest Price", Type::Purchase, "Asset Type"::" ", Codeunit::"Price Calculation - V16", false);
        end;
        ExpectedDiscount := LibraryRandom.RandInt(100);
        /*
        RequisitionLinePrice.SetLine(PriceType::Purchase, RequisitionLine);
        PriceCalculationMgt.GetHandler(RequisitionLinePrice, PriceCalculation);
        PriceCalculation.ApplyDiscount();
        PriceCalculation.GetLine(Line);
        RequisitionLine := Line;
        */
        // [THEN] Line, where "Line Discount %" is 15%
        asserterror RequisitionLine.TestField("Line Discount %", ExpectedDiscount);
        Assert.KnownFailure('Line Discount % must be equal to', 303311);
    end;

    local procedure AddPriceLine(var TempPriceListLine: Record "Price List Line" temporary; CurrencyCode: code[10]; VarianCode: Code[10]; Price: Decimal)
    begin
        TempPriceListLine.Init();
        TempPriceListLine."Currency Code" := CurrencyCode;
        TempPriceListLine."Variant Code" := VarianCode;
        TempPriceListLine."Unit Price" := Price;
        TempPriceListLine.Insert(true);
    end;

    local procedure CreateCustomerItemDiscount(var SalesLineDiscount: Record "Sales Line Discount"; CustomerCode: Code[20]; Item: Record Item; Discount: Decimal)
    begin
        LibraryERM.CreateLineDiscForCustomer(
            SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.", SalesLineDiscount."Sales Type"::Customer, CustomerCode,
            WorkDate, '', '', Item."Base Unit of Measure", 0);
        SalesLineDiscount.Validate("Line Discount %", Discount);
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateAllCustomerItemDiscount(var SalesLineDiscount: Record "Sales Line Discount"; Item: Record Item; Discount: Decimal)
    begin
        LibraryERM.CreateLineDiscForCustomer(
            SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.", SalesLineDiscount."Sales Type"::"All Customers", '',
            WorkDate, '', '', Item."Base Unit of Measure", 0);
        SalesLineDiscount.Validate("Line Discount %", Discount);
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateCustomerItemPrice(var SalesPrice: Record "Sales Price"; CustomerCode: Code[20]; Item: Record Item; Price: Decimal)
    begin
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", SalesPrice."Sales Type"::Customer, CustomerCode, WorkDate, '', '', Item."Base Unit of Measure", 0, Price);
    end;

    local procedure MockBuffer(CurrencyCode: Code[10]; CurrencyFactor: Decimal; var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.")
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        DummyPriceSourceList: Codeunit "Price Source List";
    begin
        PriceCalculationBuffer.Init();
        PriceCalculationBuffer."Qty. per Unit of Measure" := 1;
        PriceCalculationBuffer.Quantity := 1;
        PriceCalculationBuffer."Currency Code" := CurrencyCode;
        PriceCalculationBuffer."Currency Factor" := CurrencyFactor;
        PriceCalculationBufferMgt.Set(PriceCalculationBuffer, DummyPriceSourceList);
    end;
}