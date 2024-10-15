codeunit 138014 "O365 Item Price Including VAT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SMB]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        WrongUnitPriceExclVATErr: Label 'Wrong Unit Price Excl. VAT.';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        VATBusPostingGrErr: Label 'VAT Bus. Posting Gr. (Price) must have a value in Sales & Receivables Setup: Primary Key=. It cannot be zero or empty.';
        VATPostingSetupErr: Label 'The VAT Posting Setup does not exist. Identification fields and values: VAT Bus. Posting Group=''%1'',VAT Prod. Posting Group=''%2''', Comment = '%1 -  VAT Bus. Posting Group, %2 - VAT Prod. Posting Group';

    [Test]
    [Scope('OnPrem')]
    procedure ProfitOnItemZero()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();

        with Item do begin
            Init();
            "Unit Price" := 0;
            "Unit Price" := 1;
            Validate("Price/Profit Calculation", "Price/Profit Calculation"::"Profit=Price-Cost");
            Assert.AreEqual(0, "Profit %", 'Profit % should be 0 if Unit Price = 0')
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemPriceIncludesVATUpdatesVATBusPostGrPricePositive()
    var
        Item: Record Item;
        BusPostingGroupValSetup: Code[10];
    begin
        // Setup
        Initialize();

        BusPostingGroupValSetup := 'FROM_SETUP';

        CreateDefaultVATPostingSetup(BusPostingGroupValSetup, '');
        CreateSalesSetupWithVATBusPostGrPrice(BusPostingGroupValSetup);

        with Item do begin
            Init();
            Validate("Price Includes VAT", true);
            Assert.AreEqual(BusPostingGroupValSetup, "VAT Bus. Posting Gr. (Price)", 'Wrong "VAT Bus. Posting Gr. (Price)"');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemPriceIncludesVATUpdatesVATBusPostGrPriceNegativ()
    var
        Item: Record Item;
        BusPostingGroupValSetup: Code[10];
        BusPostingGroupValItem: Code[10];
    begin
        // Setup
        Initialize();

        BusPostingGroupValSetup := 'FROM_SETUP';
        BusPostingGroupValItem := 'FROM_ITEM';

        CreateDefaultVATPostingSetup(BusPostingGroupValSetup, '');
        CreateDefaultVATPostingSetup(BusPostingGroupValItem, '');

        CreateSalesSetupWithVATBusPostGrPrice(BusPostingGroupValSetup);

        with Item do begin
            Init();
            "VAT Bus. Posting Gr. (Price)" := BusPostingGroupValItem;
            Validate("Price Includes VAT", true);
            Assert.AreEqual(BusPostingGroupValSetup, "VAT Bus. Posting Gr. (Price)", 'Wrong "VAT Bus. Posting Gr. (Price)"');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemPriceIncludesVATDontUpdatesVATBusPostGrPricePositive()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();

        CreateSalesSetupWithVATBusPostGrPrice('TEST');

        with Item do begin
            Init();
            Validate("Price Includes VAT", false);
            Assert.AreEqual('', "VAT Bus. Posting Gr. (Price)", 'Wrong "VAT Bus. Posting Gr. (Price)"');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemPriceIncludesVATDontUpdatesVATBusPostGrPriceNegativ()
    var
        Item: Record Item;
        BusPostingGroupValItem: Code[10];
    begin
        // Setup
        Initialize();

        BusPostingGroupValItem := 'FROM_ITEM';

        CreateSalesSetupWithVATBusPostGrPrice('TEST');

        with Item do begin
            Init();
            "VAT Bus. Posting Gr. (Price)" := BusPostingGroupValItem;
            Validate("Price Includes VAT", false);
            Assert.AreEqual(BusPostingGroupValItem, "VAT Bus. Posting Gr. (Price)", 'Wrong "VAT Bus. Posting Gr. (Price)"');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemPriceIncludesVATFailIfNoVATPostingSetup()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();

        CreateSalesSetupWithVATBusPostGrPrice('TEST');

        with Item do begin
            Init();
            asserterror
              Validate("Price Includes VAT", true);
            Assert.ExpectedError('The VAT Posting Setup does not exist.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemPriceIncludesVATCallPriceProfitCalc()
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        BusPostingGroupValSetup: Code[10];
    begin
        // Setup
        Initialize();

        BusPostingGroupValSetup := 'ANY';

        CreateDefaultVATPostingSetup(BusPostingGroupValSetup, '');
        CreateSalesSetupWithVATBusPostGrPrice(BusPostingGroupValSetup);

        VATPostingSetup.Get(BusPostingGroupValSetup, '');
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Sales Tax";
        VATPostingSetup.Modify();

        with Item do begin
            Init();
            "Unit Price" := 2;
            "Unit Cost" := 1;
            asserterror
              Validate("Price Includes VAT", true);
            Assert.ExpectedError('Prices including VAT cannot be calculated when');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustPriceGrPriceIncludesVATUpdatesVATBusPostGrPricePositive()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        BusPostingGroupValSetup: Code[10];
    begin
        // Setup
        Initialize();

        BusPostingGroupValSetup := 'FROM_SETUP';

        CreateDefaultVATPostingSetup(BusPostingGroupValSetup, '');
        CreateSalesSetupWithVATBusPostGrPrice(BusPostingGroupValSetup);

        with CustomerPriceGroup do begin
            Init();
            Validate("Price Includes VAT", true);
            Assert.AreEqual(BusPostingGroupValSetup, "VAT Bus. Posting Gr. (Price)", 'Wrong "VAT Bus. Posting Gr. (Price)"');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustPriceGrPriceIncludesVATUpdatesVATBusPostGrPriceNegativ()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        BusPostingGroupValSetup: Code[10];
        BusPostingGroupValCPG: Code[10];
    begin
        // Setup
        Initialize();

        BusPostingGroupValSetup := 'FROM_SETUP';
        BusPostingGroupValCPG := 'FROM_CPG';

        CreateDefaultVATPostingSetup(BusPostingGroupValSetup, '');
        CreateDefaultVATPostingSetup(BusPostingGroupValCPG, '');
        CreateSalesSetupWithVATBusPostGrPrice(BusPostingGroupValSetup);

        with CustomerPriceGroup do begin
            Init();
            "VAT Bus. Posting Gr. (Price)" := BusPostingGroupValCPG;
            Validate("Price Includes VAT", true);
            Assert.AreEqual(BusPostingGroupValSetup, "VAT Bus. Posting Gr. (Price)", 'Wrong "VAT Bus. Posting Gr. (Price)"');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustPriceGrPriceIncludesVATDontUpdatesVATBusPostGrPricePositive()
    var
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        // Setup
        Initialize();

        CreateSalesSetupWithVATBusPostGrPrice('TEST');

        with CustomerPriceGroup do begin
            Init();
            Validate("Price Includes VAT", false);
            Assert.AreEqual('', "VAT Bus. Posting Gr. (Price)", 'Wrong "VAT Bus. Posting Gr. (Price)"');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustPriceGrPriceIncludesVATDontUpdatesVATBusPostGrPriceNegativ()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        BusPostingGroupValCPG: Code[10];
    begin
        // Setup
        Initialize();

        BusPostingGroupValCPG := 'FROM_CPG';

        CreateSalesSetupWithVATBusPostGrPrice('TEST');

        with CustomerPriceGroup do begin
            Init();
            "VAT Bus. Posting Gr. (Price)" := BusPostingGroupValCPG;
            Validate("Price Includes VAT", false);
            Assert.AreEqual(BusPostingGroupValCPG, "VAT Bus. Posting Gr. (Price)", 'Wrong "VAT Bus. Posting Gr. (Price)"');
        end;
    end;

#if not CLEAN23
    [Test]
    [Scope('OnPrem')]
    procedure TestForAllCustomersValidateItemNo()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
    begin
        // Setup
        Initialize();

        CreateItem(Item, 'ANYUOM', false, true, 'ANYVATGRP');

        with SalesPrice do begin
            Init();
            "Sales Type" := "Sales Type"::"All Customers";
            Validate("Item No.", Item."No.");

            Assert.AreEqual(Item."Sales Unit of Measure", "Unit of Measure Code", 'Wrong Unit of Measure.');
            TestField("Variant Code", '');

            // All values from Item
            Assert.AreEqual(Item."Allow Invoice Disc.", "Allow Invoice Disc.", 'Wrong Allow Invoice Discount.');
            Assert.AreEqual(Item."Price Includes VAT", "Price Includes VAT", 'Wrong Price Incl VAT.');
            Assert.AreEqual(Item."VAT Bus. Posting Gr. (Price)", "VAT Bus. Posting Gr. (Price)", 'Wrong VAT Post Grp Price.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestForCustomerValidateItemNo()
    var
        SalesPrice: Record "Sales Price";
    begin
        TestForSalesTypeValidateItemNo(SalesPrice."Sales Type"::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestForCustPriceGrpValidateItemNo()
    var
        SalesPrice: Record "Sales Price";
    begin
        TestForSalesTypeValidateItemNo(SalesPrice."Sales Type"::"Customer Price Group");
    end;

    local procedure TestForSalesTypeValidateItemNo(SalesType: Enum "Sales Price Type")
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
    begin
        // Setup
        Initialize();

        CreateItem(Item, 'BOX', false, true, 'DOMESTIC');

        with SalesPrice do begin
            Init();
            "Sales Type" := SalesType;
            Validate("Item No.", Item."No.");

            Assert.AreEqual(Item."Sales Unit of Measure", "Unit of Measure Code", 'Wrong Unit of Measure.');
            TestField("Variant Code", '');

            // Value from Item
            Assert.AreEqual(Item."Allow Invoice Disc.", "Allow Invoice Disc.", 'Wrong Allow Invoice Discount.');
            // Values from Sales Price Init
            Assert.AreEqual(false, "Price Includes VAT", 'Wrong Price Incl VAT.');
            Assert.AreEqual('', "VAT Bus. Posting Gr. (Price)", 'Wrong VAT Post Grp Price.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestForAllCustomersValidateSalesType()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
    begin
        // Setup
        Initialize();

        CreateItem(Item, 'BOX', false, true, 'DOMESTIC');

        with SalesPrice do begin
            Init();
            "Item No." := Item."No.";
            Validate("Sales Type", "Sales Type"::"All Customers");
            TestField("Sales Code", '');

            // All values from Item
            Assert.AreEqual(Item."Allow Invoice Disc.", "Allow Invoice Disc.", 'Wrong Allow Invoice Discount.');
            Assert.AreEqual(Item."Price Includes VAT", "Price Includes VAT", 'Wrong Price Incl VAT.');
            Assert.AreEqual(Item."VAT Bus. Posting Gr. (Price)", "VAT Bus. Posting Gr. (Price)", 'Wrong VAT Post Grp Price.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceDiscValidateItemNo()
    var
        Item: Record Item;
        SalesLineDiscount: Record "Sales Line Discount";
        Any: Boolean;
    begin
        // Setup
        Initialize();

        Any := false;
        CreateItem(Item, 'BOX', Any, Any, 'any');

        with SalesLineDiscount do begin
            Init();
            Type := Type::Item;
            Validate(Code, Item."No.");

            Assert.AreEqual(Item."Sales Unit of Measure", "Unit of Measure Code", 'Wrong Unit of Measure.');
            TestField("Variant Code", '');
        end;
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure PriceExclVATForPriceInclVatFalse()
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Item] [Price Incl. VAT]
        // [SCENARIO 361663] Item's "Unit Price Excl. VAT" is equal to "Unit Price" if "Price Includes VAT" is "No"
        // [GIVEN] Item with price VAT setup, where "VAT %" = 25 and "Unit Price" = 1250
        // Setup
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);
        Item.Init();
        Item."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        Item."VAT Bus. Posting Gr. (Price)" := VATPostingSetup."VAT Bus. Posting Group";
        Item."Unit Price" := LibraryRandom.RandDec(1000, 2);

        // [WHEN] Item's "Price Includes VAT" is set to "No"
        Item."Price Includes VAT" := false;

        // [THEN] Item's "Unit Price Excl. VAT" is equal to 1250
        Assert.AreEqual(Item."Unit Price", Item.CalcUnitPriceExclVAT(), WrongUnitPriceExclVATErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PriceExclVATForPriceInclVatTrue()
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        ExpectedUnitPriceExclVAT: Decimal;
    begin
        // [FEATURE] [Item] [Price Incl. VAT]
        // [SCENARIO 361663] Item's "Unit Price Excl. VAT" is calculated from "Unit Price" if "Price Includes VAT" is "Yes"
        // [GIVEN] Item with price VAT setup, where "VAT %" = 25
        // Setup
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);
        Item.Init();
        Item."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        Item."VAT Bus. Posting Gr. (Price)" := VATPostingSetup."VAT Bus. Posting Group";
        // [GIVEN] Item's "Unit Price" = 1250
        ExpectedUnitPriceExclVAT := LibraryRandom.RandDec(1000, 2);
        Item."Unit Price" := ExpectedUnitPriceExclVAT * (1 + VATPostingSetup."VAT %" / 100);
        // [GIVEN] Item's "Price/Profit Calculation" = "No Relationship"
        Item."Price/Profit Calculation" := Item."Price/Profit Calculation"::"No Relationship";

        // [WHEN] Item's "Price Includes VAT" is set to "Yes"
        Item."Price Includes VAT" := true;

        // [THEN] Item's "Unit Price Excl. VAT" is equal to 1000
        Assert.AreEqual(ExpectedUnitPriceExclVAT, Item.CalcUnitPriceExclVAT(), WrongUnitPriceExclVATErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PriceIncludingVATChangeWhenThereIsValueInSalesSetupVATBusPostGrPriceAndThereIsCombinationInVatPostingSetup()
    var
        Item: Record Item;
        BusPostingGroupValSetup: Code[10];
    begin
        // [FEATURE] [Item] [Price Incl. VAT]
        // [SCENARIO 376463] Change "Price Includes VAT" to True when the VAT Posting Setup and SalesSetup are created
        Initialize();

        // [GIVEN] Created Item
        LibrarySmallBusiness.CreateItem(Item);

        // [GIVEN] Created new VAT Posting Setup and SalesSetup with "VAT Bus. Post. Gr. Price"
        BusPostingGroupValSetup := LibraryUtility.GenerateGUID();
        CreateDefaultVATPostingSetup(BusPostingGroupValSetup, Item."VAT Prod. Posting Group");
        CreateSalesSetupWithVATBusPostGrPrice(BusPostingGroupValSetup);

        // [WHEN] Validate "Price Includes VAT" to True
        Item.Validate("Price Includes VAT", true);
        Item.Modify(true);

        // [THEN] "Price Includes VAT" is equal to True. There is no errors
        Item.TestField("Price Includes VAT", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PriceIncludingVATChangeWhenThereIsNoValueInSalesSetupVATBusPostGrPriceAndThereIsCombinationInVatPostingSetup()
    var
        Item: Record Item;
        BusPostingGroupValSetup: Code[10];
    begin
        // [FEATURE] [Item] [Price Incl. VAT]
        // [SCENARIO 376463] Change "Price Includes VAT" to True when the VAT Posting Setup is created
        Initialize();

        // [GIVEN] Created Item
        LibrarySmallBusiness.CreateItem(Item);

        // [GIVEN] Created new VAT Posting Setup and SalesSetup with "VAT Bus. Post. Gr. Price" where "Vat Bus. Posting Group" is empty
        BusPostingGroupValSetup := '';
        CreateDefaultVATPostingSetup(BusPostingGroupValSetup, Item."VAT Prod. Posting Group");
        CreateSalesSetupWithVATBusPostGrPrice(BusPostingGroupValSetup);

        // [WHEN] Validate "Price Includes VAT" to True
        asserterror Item.Validate("Price Includes VAT", true);

        // [THEN] Error was shown
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(VATBusPostingGrErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PriceIncludingVATChangeWhenThereIsValueInSalesSetupVATBusPostGrPriceAndThereIsNoCombinationInVatPostingSetup()
    var
        Item: Record Item;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        BusPostingGroupValSetup: Code[10];
    begin
        // [FEATURE] [Item] [Price Incl. VAT]
        // [SCENARIO 376463] Change "Price Includes VAT" to True when the VAT Posting Setup and SalesSetup are created
        Initialize();

        // [GIVEN] Created Item
        LibrarySmallBusiness.CreateItem(Item);

        // [GIVEN] Created new VAT Posting Setup and SalesSetup with "VAT Bus. Post. Gr. Price" not related to VAT Posting Setup
        BusPostingGroupValSetup := LibraryUtility.GenerateGUID();
        CreateDefaultVATPostingSetup(BusPostingGroupValSetup, Item."VAT Prod. Posting Group");
        CreateSalesSetupWithVATBusPostGrPrice(LibraryUtility.GenerateGUID());
        SalesReceivablesSetup.Get();

        // [WHEN] Validate "Price Includes VAT" to True
        asserterror Item.Validate("Price Includes VAT", true);

        // [THEN] Error was shown
        Assert.ExpectedErrorCode('DB:RecordNotFound');
        Assert.ExpectedError(StrSubstNo(
            VATPostingSetupErr, SalesReceivablesSetup."VAT Bus. Posting Gr. (Price)", Item."VAT Prod. Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PriceIncludingVATChangeWhenThereIsNoValueInSalesSetupVATBusPostGrPriceAndThereIsNoCombinationInVatPostingSetup()
    var
        Item: Record Item;
        BusPostingGroupValSetup: Code[10];
        BusProdPostingGroupValSetup: Code[10];
    begin
        // [FEATURE] [Item]
        // [SCENARIO 376463] Change "Price Includes VAT" to True when the VAT Posting Setup and SalesSetup are created
        Initialize();

        // [GIVEN] Created Item
        LibrarySmallBusiness.CreateItem(Item);

        // [GIVEN] Created SalesSetup with empty "VAT Bus. Post. Gr. Price" and new "VAT Prod. Posting Group" for Item
        BusPostingGroupValSetup := '';
        BusProdPostingGroupValSetup := LibraryUtility.GenerateGUID();
        CreateSalesSetupWithVATBusPostGrPrice(BusPostingGroupValSetup);
        Item."VAT Prod. Posting Group" := BusProdPostingGroupValSetup;

        // [WHEN] Validate "Price Includes VAT" to True
        asserterror Item.Validate("Price Includes VAT", true);

        // [THEN] Error was shown
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(VATBusPostingGrErr);
    end;

    local procedure CreateItem(var Item: Record Item; UOMCode: Code[10]; AllowInvDisc: Boolean; PriceInclVAT: Boolean; VATBusPostGrpPrice: Code[10])
    begin
        LibrarySmallBusiness.CreateItem(Item);
        Item."Sales Unit of Measure" := UOMCode;
        Item."Allow Invoice Disc." := AllowInvDisc;
        Item."Price Includes VAT" := PriceInclVAT;
        Item."VAT Bus. Posting Gr. (Price)" := VATBusPostGrpPrice;
        Item.Modify();
    end;

    local procedure CreateDefaultVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        with VATBusinessPostingGroup do begin
            if Get(VATBusPostingGroup) then
                Delete();

            Init();
            Code := VATBusPostingGroup;
            Insert();
        end;

        with VATPostingSetup do begin
            if Get(VATBusPostingGroup, VATProdPostingGroup) then
                Delete();

            Init();
            "VAT Bus. Posting Group" := VATBusPostingGroup;
            "VAT Prod. Posting Group" := VATProdPostingGroup;
            Insert();
        end;
    end;

    local procedure CreateSalesSetupWithVATBusPostGrPrice(BusPostingGroupVal: Code[20])
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        with SalesSetup do begin
            if Get() then
                Delete();

            Init();
            "VAT Bus. Posting Gr. (Price)" := BusPostingGroupVal;
            Insert();
        end;
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        with VATPostingSetup do begin
            Init();
            "VAT Bus. Posting Group" := LibraryUtility.GenerateGUID();
            "VAT Prod. Posting Group" := LibraryUtility.GenerateGUID();
            "VAT Calculation Type" := "VAT Calculation Type"::"Normal VAT";
            "VAT %" := LibraryRandom.RandInt(25);
            Insert();
        end;

        if VATProductPostingGroup.Get(VATPostingSetup."VAT Prod. Posting Group") then
            VATProductPostingGroup.Delete();
        VATProductPostingGroup.Init();
        VATProductPostingGroup.Code := VATPostingSetup."VAT Prod. Posting Group";
        VATProductPostingGroup.Insert();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Item Price Including VAT");
        LibraryApplicationArea.EnableFoundationSetup();
    end;
}

