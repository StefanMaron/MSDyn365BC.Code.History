#if not CLEAN23
#pragma warning disable AS0072
codeunit 138019 "O365 Item Prices"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Not used.';
    ObsoleteState = Pending;
    ObsoleteTag = '23.0';

    trigger OnRun()
    begin
        // [FEATURE] [SMB] [Item] [Sales Price and Line Discount]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    local procedure Initialize()
    var
        InvtSetup: Record "Inventory Setup";
        NoSeriesLine: Record "No. Series Line";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Item Prices");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Item Prices");

        LibraryERMCountryData.CreateVATData();

        InvtSetup.Get();
        NoSeriesLine.SetRange("Series Code", InvtSetup."Item Nos.");
        NoSeriesLine.ModifyAll("Warning No.", '');

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Item Prices");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SafeReset()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        CreateBlankItem(Item);
        Item."Item Disc. Group" := GetGroupCode(Item."No.");
        Item.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        TempSalesPriceAndLineDiscBuff.SetRange("Unit Price", LibraryRandom.RandDec(10, 2));

        TempSalesPriceAndLineDiscBuff.Reset();

        Assert.AreEqual(Item."No.", TempSalesPriceAndLineDiscBuff."Loaded Item No.", '<Item No.> was reseted');
        Assert.AreEqual('', TempSalesPriceAndLineDiscBuff."Loaded Customer No.", '<Customer No.> is incorrect');
        Assert.AreEqual(
          Item."Item Disc. Group", TempSalesPriceAndLineDiscBuff."Loaded Disc. Group", '<Disc. Group> was reseted');
        Assert.AreEqual(
          '', TempSalesPriceAndLineDiscBuff."Loaded Price Group", '<Price Group> was reseted');
        Assert.AreEqual('', TempSalesPriceAndLineDiscBuff.GetFilters, 'Filters was not removed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyLoad()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        // nor rec check;
        Initialize();

        CreateBlankItem(Item);

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Incorrect load. TempSalesPriceAndLineDiscBuff should be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDiscountLinesInsertedIntoBufferForItem()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        // Validation part
        SetFiltersForBufferAndGetFreshSLDiscounts(
          SalesLineDiscount, TempSalesPriceAndLineDiscBuff, SalesLineDiscount.Type::Item, Item."No.");

        CompareBuffAgainstDiscLines(SalesLineDiscount, TempSalesPriceAndLineDiscBuff);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDiscountLinesInsertedIntoBufferForItemWithDiscGroup()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);
        Item."Item Disc. Group" := GetGroupCode(Item."No.");
        Item.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        // Validation part
        SetFiltersForBufferAndGetFreshSLDiscounts(
          SalesLineDiscount, TempSalesPriceAndLineDiscBuff, SalesLineDiscount.Type::Item, Item."No.");
        CompareBuffAgainstDiscLines(SalesLineDiscount, TempSalesPriceAndLineDiscBuff);

        SetFiltersForBufferAndGetFreshSLDiscounts(
          SalesLineDiscount, TempSalesPriceAndLineDiscBuff, SalesLineDiscount.Type::"Item Disc. Group", GetGroupCode(Item."No."));
        CompareBuffAgainstDiscLines(SalesLineDiscount, TempSalesPriceAndLineDiscBuff);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDiscountLinesInsertedIntoBufferForItem_NegForCamp()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        TempSalesPriceAndLineDiscBuff.SetRange("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::Campaign);
        Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Campaign should not be inserted to the Buffer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDiscountLinesInsertedIntoBufferForItemWithDiscGroup_NegForCamp()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);
        Item."Item Disc. Group" := GetGroupCode(Item."No.");
        Item.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        TempSalesPriceAndLineDiscBuff.SetRange("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::Campaign);
        Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Campaign should not be inserted to the Buffer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDiscountLinesInsertedIntoBuffer_NegForOtherItem()
    var
        WrongItem: Record Item;
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);
        CreateBlankItem(WrongItem);

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        TempSalesPriceAndLineDiscBuff.SetRange(Type, TempSalesPriceAndLineDiscBuff.Type::Item);
        TempSalesPriceAndLineDiscBuff.SetFilter(Code, '<>%1', Item."No.");
        Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Lines for wrong Item in the Buffer table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDiscountLinesInsertedIntoBuffer_NegForOtherItemAndTheSameDiscGr()
    var
        Item: Record Item;
        WrongItem: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);
        Item."Item Disc. Group" := GetGroupCode(Item."No.");
        Item.Modify();

        // Wrong Item with the same Disc. Group
        CreateBlankItem(WrongItem);
        WrongItem."Item Disc. Group" := GetGroupCode(Item."No.");
        WrongItem.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        TempSalesPriceAndLineDiscBuff.SetRange(Type, TempSalesPriceAndLineDiscBuff.Type::Item);
        TempSalesPriceAndLineDiscBuff.SetFilter(Code, '<>%1', Item."No.");
        Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Lines for wrong Item in the Buffer table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDiscountLinesInsertedIntoBuffer_NegForOtherItemDiscGr()
    var
        Item: Record Item;
        WrongItem: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);
        Item."Item Disc. Group" := GetGroupCode(Item."No.");
        Item.Modify();

        // Wrong Item with the same Disc. Group
        CreateBlankItem(WrongItem);
        WrongItem."Item Disc. Group" := Item."Item Disc. Group";
        WrongItem.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        TempSalesPriceAndLineDiscBuff.SetRange(Type, TempSalesPriceAndLineDiscBuff.Type::"Item Disc. Group");
        TempSalesPriceAndLineDiscBuff.SetFilter(Code, '<>%1', Item."Item Disc. Group");
        Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Lines for wrong Item Disc Group in the Buffer table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePriceLinesInsertedIntoBufferForItem()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        SalesPrice: Record "Sales Price";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        // Validation part
        SetFiltersForBufferAndGetFreshSPrices(SalesPrice, TempSalesPriceAndLineDiscBuff, Item."No.");

        CompareBuffAgainstPrices(SalesPrice, TempSalesPriceAndLineDiscBuff);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePriceLinesInsertedIntoBufferForItem_NegForCamp()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        TempSalesPriceAndLineDiscBuff.SetRange("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::Campaign);
        Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Campaign should not be inserted to the Buffer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePriceLinesInsertedIntoBufferForItemWithDiscGroup_NegForCamp()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);
        Item."Item Disc. Group" := GetGroupCode(Item."No.");
        Item.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        TempSalesPriceAndLineDiscBuff.SetRange("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::Campaign);
        Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Campaign should not be inserted to the Buffer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePriceLinesInsertedIntoBuffer_NegForOtherItem()
    var
        WrongItem: Record Item;
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);
        CreateBlankItem(WrongItem);

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        TempSalesPriceAndLineDiscBuff.SetRange(Type, TempSalesPriceAndLineDiscBuff.Type::Item);
        TempSalesPriceAndLineDiscBuff.SetFilter(Code, '<>%1', Item."No.");
        Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Lines for wrong Item in the Buffer table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePriceLinesInsertedIntoBuffer_NegForOtherItemAndTheSameDiscGr()
    var
        Item: Record Item;
        WrongItem: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);
        Item."Item Disc. Group" := GetGroupCode(Item."No.");
        Item.Modify();

        // Wrong Item with the same Disc. Group
        CreateBlankItem(WrongItem);
        WrongItem."Item Disc. Group" := GetGroupCode(Item."No.");
        WrongItem.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        TempSalesPriceAndLineDiscBuff.SetRange(Type, TempSalesPriceAndLineDiscBuff.Type::Item);
        TempSalesPriceAndLineDiscBuff.SetFilter(Code, '<>%1', Item."No.");
        Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Lines for wrong Item in the Buffer table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Added_ItemDiscountLine()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ActualSalesLineDiscount: Record "Sales Line Discount";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff, false);

        DuplicateLineInBuffer(TempSalesPriceAndLineDiscBuff, TempSalesPriceAndLineDiscBuff.Type::Item);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff, false);

        GetSLDiscounts(ActualSalesLineDiscount, ActualSalesLineDiscount.Type::Item, Item."No.");
        CompareDiscLinesAgainstBuff(TempSalesPriceAndLineDiscBuff, ActualSalesLineDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Modif_ItemDiscountLine()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ActualSalesLineDiscount: Record "Sales Line Discount";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff, false);

        UpdateLinesInBuffer(TempSalesPriceAndLineDiscBuff, TempSalesPriceAndLineDiscBuff.Type::Item);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff, false);

        GetSLDiscounts(ActualSalesLineDiscount, ActualSalesLineDiscount.Type::Item, Item."No.");
        CompareDiscLinesAgainstBuff(TempSalesPriceAndLineDiscBuff, ActualSalesLineDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Del_ItemDiscountLine()
    var
        Item: Record Item;
        ActualTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ExpectedTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ActualSalesLineDiscount: Record "Sales Line Discount";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);

        ExpectedTempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        SetBufferOnlyToSLDiscounts(ExpectedTempSalesPriceAndLineDiscBuff, false);

        DeleteLineInBuffer(ExpectedTempSalesPriceAndLineDiscBuff);

        SetBufferOnlyToSLDiscounts(ExpectedTempSalesPriceAndLineDiscBuff, false);

        ActualTempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        SetBufferOnlyToSLDiscounts(ActualTempSalesPriceAndLineDiscBuff, false);

        Assert.AreEqual(ExpectedTempSalesPriceAndLineDiscBuff.Count, ActualTempSalesPriceAndLineDiscBuff.Count, 'Record was not deleted');
        GetSLDiscounts(ActualSalesLineDiscount, ActualSalesLineDiscount.Type::Item, Item."No.");
        // in case of error: <The Sales Price and Line Disc Buff does not exist...> Record was not deleted from original table.
        CompareBuffAgainstDiscLines(ActualSalesLineDiscount, ExpectedTempSalesPriceAndLineDiscBuff);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Added_ItemDiscountGrLine()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ActualSalesLineDiscount: Record "Sales Line Discount";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);
        Item."Item Disc. Group" := GetGroupCode(Item."No.");
        Item.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff, true);

        DuplicateLineInBuffer(TempSalesPriceAndLineDiscBuff, TempSalesPriceAndLineDiscBuff.Type::"Item Disc. Group");
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff, true);

        GetSLDiscounts(ActualSalesLineDiscount, ActualSalesLineDiscount.Type::"Item Disc. Group", GetGroupCode(Item."No."));
        CompareDiscLinesAgainstBuff(TempSalesPriceAndLineDiscBuff, ActualSalesLineDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Modif_ItemDiscountGrLine()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ActualSalesLineDiscount: Record "Sales Line Discount";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);
        Item."Item Disc. Group" := GetGroupCode(Item."No.");
        Item.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff, true);

        UpdateLinesInBuffer(TempSalesPriceAndLineDiscBuff, TempSalesPriceAndLineDiscBuff.Type::"Item Disc. Group");
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff, true);

        GetSLDiscounts(ActualSalesLineDiscount, ActualSalesLineDiscount.Type::"Item Disc. Group", GetGroupCode(Item."No."));
        CompareDiscLinesAgainstBuff(TempSalesPriceAndLineDiscBuff, ActualSalesLineDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Del_ItemDiscountGrLine()
    var
        Item: Record Item;
        ActualTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ExpectedTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ActualSalesLineDiscount: Record "Sales Line Discount";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);
        Item."Item Disc. Group" := GetGroupCode(Item."No.");
        Item.Modify();

        ExpectedTempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        SetBufferOnlyToSLDiscounts(ExpectedTempSalesPriceAndLineDiscBuff, true);

        DeleteLineInBuffer(ExpectedTempSalesPriceAndLineDiscBuff);

        SetBufferOnlyToSLDiscounts(ExpectedTempSalesPriceAndLineDiscBuff, true);

        ActualTempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        SetBufferOnlyToSLDiscounts(ActualTempSalesPriceAndLineDiscBuff, true);

        Assert.AreEqual(ExpectedTempSalesPriceAndLineDiscBuff.Count, ActualTempSalesPriceAndLineDiscBuff.Count, 'Record was not deleted');
        GetSLDiscounts(ActualSalesLineDiscount, ActualSalesLineDiscount.Type::"Item Disc. Group", GetGroupCode(Item."No."));
        // in case of error: <The Sales Price and Line Disc Buff does not exist...> Record was not deleted from original table.
        CompareBuffAgainstDiscLines(ActualSalesLineDiscount, ExpectedTempSalesPriceAndLineDiscBuff);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Added_ItemPriceLine()
    var
        Item: Record Item;
        ExpectedTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ActualSalesPrice: Record "Sales Price";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);

        ExpectedTempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        SetBufferOnlyToSPrices(ExpectedTempSalesPriceAndLineDiscBuff);

        DuplicateLineInBuffer(ExpectedTempSalesPriceAndLineDiscBuff, ExpectedTempSalesPriceAndLineDiscBuff.Type::Item);
        SetBufferOnlyToSPrices(ExpectedTempSalesPriceAndLineDiscBuff);

        GetSPrices(ActualSalesPrice, Item."No.");
        Assert.AreEqual(ExpectedTempSalesPriceAndLineDiscBuff.Count, ActualSalesPrice.Count, 'Record was not inserted');

        ComparePricesAgainstBuff(ExpectedTempSalesPriceAndLineDiscBuff, ActualSalesPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Modif_ItemPriceLine()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ActualSalesPrice: Record "Sales Price";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        SetBufferOnlyToSPrices(TempSalesPriceAndLineDiscBuff);

        UpdateLinesInBuffer(TempSalesPriceAndLineDiscBuff, TempSalesPriceAndLineDiscBuff.Type::Item);
        SetBufferOnlyToSPrices(TempSalesPriceAndLineDiscBuff);

        GetSPrices(ActualSalesPrice, Item."No.");
        ComparePricesAgainstBuff(TempSalesPriceAndLineDiscBuff, ActualSalesPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Del_ItemPriceLine()
    var
        Item: Record Item;
        ExpectedTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ActualTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ActualSalesPrice: Record "Sales Price";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);

        ExpectedTempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        SetBufferOnlyToSPrices(ExpectedTempSalesPriceAndLineDiscBuff);

        DeleteLineInBuffer(ExpectedTempSalesPriceAndLineDiscBuff);

        SetBufferOnlyToSPrices(ExpectedTempSalesPriceAndLineDiscBuff);

        ActualTempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        SetBufferOnlyToSPrices(ActualTempSalesPriceAndLineDiscBuff);

        Assert.AreEqual(ExpectedTempSalesPriceAndLineDiscBuff.Count, ActualTempSalesPriceAndLineDiscBuff.Count, 'Record was not deleted');
        GetSPrices(ActualSalesPrice, Item."No.");
        // in case of error: <The Sales Price and Line Disc Buff does not exist...> Record was not deleted from original table.
        CompareBuffAgainstPrices(ActualSalesPrice, ExpectedTempSalesPriceAndLineDiscBuff);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_TheSameValuesForPrices()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ExpectedSalesPrice: Record "Sales Price";
        ActualSalesPrice: Record "Sales Price";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);

        GetSPrices(ExpectedSalesPrice, Item."No.");

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        TempSalesPriceAndLineDiscBuff.Modify(true);

        GetSPrices(ActualSalesPrice, Item."No.");

        CompareSalesPriceRec(ExpectedSalesPrice, ActualSalesPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_TheSameValuesForItemDiscounts()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ExpectedSalesLnDisc: Record "Sales Line Discount";
        ActualSalesLnDisc: Record "Sales Line Discount";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);

        GetSLDiscounts(ExpectedSalesLnDisc, ExpectedSalesLnDisc.Type::Item, Item."No.");

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        TempSalesPriceAndLineDiscBuff.Modify(true);

        GetSLDiscounts(ActualSalesLnDisc, ActualSalesLnDisc.Type::Item, Item."No.");

        CompareSLDiscountsRec(ExpectedSalesLnDisc, ActualSalesLnDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_TheSameValuesForItemDiscGroup()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ExpectedSalesLnDisc: Record "Sales Line Discount";
        ActualSalesLnDisc: Record "Sales Line Discount";
    begin
        Initialize();

        InitItemAndDiscAndPrices(Item);

        GetSLDiscounts(ExpectedSalesLnDisc, ExpectedSalesLnDisc.Type::"Item Disc. Group", GetGroupCode(Item."No."));

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        GetSLDiscounts(ActualSalesLnDisc, ActualSalesLnDisc.Type::"Item Disc. Group", GetGroupCode(Item."No."));

        CompareSLDiscountsRec(ExpectedSalesLnDisc, ActualSalesLnDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineType_vs_Type()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        with TempSalesPriceAndLineDiscBuff do begin
            ValidateFieldsForLineType_vs_Type(
              "Line Type"::"Sales Line Discount",
              "Line Type"::"Sales Price");

            ValidateFieldsForLineType_vs_Type(
              "Line Type"::"Sales Line Discount",
              Type::"Item Disc. Group".AsInteger());

            ValidateFieldsForLineType_vs_Type(
              "Line Type"::"Sales Price",
              Type::Item.AsInteger());

            Init();
            "Loaded Item No." := 'LIN';
            "Line Type" := "Line Type"::"Sales Price";
            "Loaded Disc. Group" := 'LDG';
            asserterror
              Validate(Type, Type::"Item Disc. Group");
            Assert.ExpectedError('Line Type must be equal to');
        end;
    end;

    local procedure ValidateFieldsForLineType_vs_Type(NewLineType: Integer; NewType: Integer)
    var
        SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff";
    begin
        SalesPriceAndLineDiscBuff.Init();
        SalesPriceAndLineDiscBuff.Validate("Line Type", NewLineType);
        SalesPriceAndLineDiscBuff.Validate(Type, NewType);
        Assert.AreEqual(SalesPriceAndLineDiscBuff."Line Type", NewLineType, 'Line Type should not be changed');
        Assert.AreEqual(SalesPriceAndLineDiscBuff.Type, NewType, 'Type should not be changed');
        if SalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Type_vs_LineType()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        with TempSalesPriceAndLineDiscBuff do begin
            ValidateFieldsForType_vs_LineType(
              Type::Item,
              "Line Type"::"Sales Line Discount");

            ValidateFieldsForType_vs_LineType(
              Type::"Item Disc. Group",
              "Line Type"::"Sales Line Discount");

            ValidateFieldsForType_vs_LineType(
              Type::Item,
              "Line Type"::"Sales Price");

            Init();
            Validate(Type, Type::"Item Disc. Group");
            asserterror
              Validate("Line Type", "Line Type"::"Sales Price");
            Assert.ExpectedError('Type must be equal to ''Item''  in Sales Price and Line Disc Buff');
        end;
    end;

    local procedure ValidateFieldsForType_vs_LineType(NewType: Enum "Sales Line Discount Type"; NewLineType: Integer)
    var
        SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff";
    begin
        SalesPriceAndLineDiscBuff.Init();
        SalesPriceAndLineDiscBuff.Validate(Type, NewType);
        SalesPriceAndLineDiscBuff.Validate("Line Type", NewLineType);
        Assert.AreEqual(SalesPriceAndLineDiscBuff."Line Type", NewLineType, 'Line Type should not be changed');
        Assert.AreEqual(SalesPriceAndLineDiscBuff.Type, NewType, 'Type should not be changed');
        if SalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdatePriceInclVatOnItem_SetTrue()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        TempSalesPriceAndLineDiscBuff2: Record "Sales Price and Line Disc Buff" temporary;
        SalesPrice: Record "Sales Price";
        VATPostingSetup: Record "VAT Posting Setup";
        OldUnitPrice: Decimal;
        ExpectedUnitPrice: Decimal;
        VAT: Decimal;
        OldPriceIncludesVAT: Boolean;
    begin
        Initialize();
        LibraryApplicationArea.EnableVATSetup();
        OldPriceIncludesVAT := false;

        CreateBlankItem(Item);
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify();

        CreateSalesPrices(Item."No.");
        SalesPrice.ModifyAll("Price Includes VAT", OldPriceIncludesVAT);
        SalesPrice.ModifyAll("VAT Bus. Posting Gr. (Price)", GetRealisticVATBusPostingGrPrice(Item."VAT Prod. Posting Group"));

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        PlaceFilterOn_TempSalesPriceAndLineDiscBuff_ForPriceInclVat(TempSalesPriceAndLineDiscBuff, OldPriceIncludesVAT);

        OldUnitPrice := TempSalesPriceAndLineDiscBuff."Unit Price";

        VATPostingSetup.Get(TempSalesPriceAndLineDiscBuff."VAT Bus. Posting Gr. (Price)", Item."VAT Prod. Posting Group");

        VAT := VATPostingSetup."VAT %";

        ExpectedUnitPrice := OldUnitPrice * (100 + VAT) / 100;
        TempSalesPriceAndLineDiscBuff.Reset();

        // Validation part
        TempSalesPriceAndLineDiscBuff.UpdatePriceIncludesVatAndPrices(Item, not OldPriceIncludesVAT);

        TempSalesPriceAndLineDiscBuff2.LoadDataForItem(Item);
        PlaceFilterOn_TempSalesPriceAndLineDiscBuff_ForPriceInclVat(TempSalesPriceAndLineDiscBuff2, not OldPriceIncludesVAT);

        Assert.AreEqual(ExpectedUnitPrice, TempSalesPriceAndLineDiscBuff2."Unit Price", 'Incorrectly updated unit price.');
        Assert.AreEqual(
          not OldPriceIncludesVAT, TempSalesPriceAndLineDiscBuff2."Price Includes VAT", 'Incorrectly updated Price Includes VAT.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdatePriceInclVatOnItem_SetFalse()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        TempSalesPriceAndLineDiscBuff2: Record "Sales Price and Line Disc Buff" temporary;
        SalesPrice: Record "Sales Price";
        VATPostingSetup: Record "VAT Posting Setup";
        OldUnitPrice: Decimal;
        ExpectedUnitPrice: Decimal;
        VAT: Decimal;
        OldPriceIncludesVAT: Boolean;
    begin
        Initialize();
        LibraryApplicationArea.EnableVATSetup();
        OldPriceIncludesVAT := true;

        CreateBlankItem(Item);
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify();

        CreateSalesPrices(Item."No.");
        SalesPrice.ModifyAll("Price Includes VAT", OldPriceIncludesVAT);
        SalesPrice.ModifyAll("VAT Bus. Posting Gr. (Price)", GetRealisticVATBusPostingGrPrice(Item."VAT Prod. Posting Group"));

        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);
        PlaceFilterOn_TempSalesPriceAndLineDiscBuff_ForPriceInclVat(TempSalesPriceAndLineDiscBuff, OldPriceIncludesVAT);

        OldUnitPrice := TempSalesPriceAndLineDiscBuff."Unit Price";
        VATPostingSetup.Get(TempSalesPriceAndLineDiscBuff."VAT Bus. Posting Gr. (Price)", Item."VAT Prod. Posting Group");
        VAT := VATPostingSetup."VAT %";

        ExpectedUnitPrice := OldUnitPrice * 100 / (100 + VAT);
        TempSalesPriceAndLineDiscBuff.Reset();

        // Validation part
        TempSalesPriceAndLineDiscBuff.UpdatePriceIncludesVatAndPrices(Item, not OldPriceIncludesVAT);

        TempSalesPriceAndLineDiscBuff2.LoadDataForItem(Item);
        PlaceFilterOn_TempSalesPriceAndLineDiscBuff_ForPriceInclVat(TempSalesPriceAndLineDiscBuff2, not OldPriceIncludesVAT);

        Assert.AreEqual(ExpectedUnitPrice, TempSalesPriceAndLineDiscBuff2."Unit Price", 'Incorrectly updated unit price.');
        Assert.AreEqual(
          not OldPriceIncludesVAT, TempSalesPriceAndLineDiscBuff2."Price Includes VAT", 'Incorrectly updated Price Includes VAT.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePriceInclVatOnItem_SetTheSame()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        ItemCard: TestPage "Item Card";
    begin
        Initialize();
        LibraryApplicationArea.EnableVATSetup();

        CreateItem(Item);
        CreateSalesPrices(Item."No.");
        SalesPrice.ModifyAll("Price Includes VAT", Item."Price Includes VAT");

        ItemCard.OpenEdit();
        ItemCard.Filter.SetFilter("No.", Item."No.");

        // Validation part
        ItemCard."Price Includes VAT".Value := Format(Item."Price Includes VAT");

        ItemCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePriceInclVatOnItem_SetTrueIfAllTrue()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        ItemCard: TestPage "Item Card";
    begin
        Initialize();
        LibraryApplicationArea.EnableVATSetup();

        CreateItem(Item);
        CreateSalesPrices(Item."No.");
        SalesPrice.ModifyAll("Price Includes VAT", not Item."Price Includes VAT");
        EditSalesSetupWithVATBusPostGrPrice();

        ItemCard.OpenEdit();
        ItemCard.Filter.SetFilter("No.", Item."No.");

        // Validation part
        ItemCard."Price Includes VAT".Value := Format(not Item."Price Includes VAT");

        ItemCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePriceInclVatOnItem_SetFalseAllFalse()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        ItemCard: TestPage "Item Card";
    begin
        Initialize();
        LibraryApplicationArea.EnableVATSetup();

        CreateItem(Item);
        CreateSalesPrices(Item."No.");
        SalesPrice.ModifyAll("Price Includes VAT", not Item."Price Includes VAT");
        EditSalesSetupWithVATBusPostGrPrice();

        ItemCard.OpenEdit();
        ItemCard.Filter.SetFilter("No.", Item."No.");

        // Validation part
        ItemCard."Price Includes VAT".Value := Format(not Item."Price Includes VAT");

        ItemCard.Close();
    end;

    [Test]
    [HandlerFunctions('SalesPricesOverviewSetPricesHandler')]
    [Scope('OnPrem')]
    procedure TestLaunchPricesDiscountsOverviewViaActionOnItemCardNoPriceData()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        SalesLineDiscount: Record "Sales Line Discount";
        ItemType: Text;
        CodeFilter: Text;
    begin
        Initialize();
        SalesLineDiscount.DeleteAll();

        CreateItem(Item);

        ItemCard.OpenEdit();
        ItemCard.Filter.SetFilter("No.", Item."No.");
        ItemCard.PricesDiscountsOverview.Invoke();
        ItemCard.Close();

        ItemType := LibraryVariableStorage.DequeueText();
        CodeFilter := LibraryVariableStorage.DequeueText();
        Assert.AreEqual('Item', ItemType, 'wrong Item Type filter');
        Assert.AreEqual(Item."No.", CodeFilter, 'wrong Code filter');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesPricesOverviewHandler')]
    [Scope('OnPrem')]
    procedure TestLaunchPricesDiscountsOverviewViaActionOnItemCard()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        Initialize();

        CreateItem(Item);
        CreateSalesPrices(Item."No.");

        ItemCard.OpenEdit();
        ItemCard.Filter.SetFilter("No.", Item."No.");

        LibraryVariableStorage.Enqueue(Item); // verify correct item in the handler
        ItemCard.PricesDiscountsOverview.Invoke();
        ItemCard.Close();
    end;

    [Test]
    [HandlerFunctions('SalesPricesOverviewHandler')]
    [Scope('OnPrem')]
    procedure TestLaunchPricesDiscountsOverviewViaActionOnItemList()
    var
        Item: Record Item;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        ItemList: TestPage "Item List";
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        CreateItem(Item);
        CreateSalesPrices(Item."No.");

        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);

        LibraryVariableStorage.Enqueue(Item); // verify correct item in the handler
        ItemList.PricesDiscountsOverview.Invoke();
        ItemList.Close();
    end;

    [Test]
    [HandlerFunctions('SalesPricesOverviewHandler')]
    [Scope('OnPrem')]
    procedure TestLaunchPricesDiscountsOverviewViaDrilldownOnItemCard()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        Initialize();

        CreateItem(Item);
        CreateSalesPrices(Item."No.");

        ItemCard.OpenEdit();
        ItemCard.Filter.SetFilter("No.", Item."No.");

        LibraryVariableStorage.Enqueue(Item); // verify correct item in the handler
        ItemCard.SpecialPricesAndDiscountsTxt.DrillDown();
        ItemCard.Close();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,SalesPricesHandler')]
    [Scope('OnPrem')]
    procedure TestLaunchCreateNewSpecialPriceViaDrilldownOnItemCard()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        Initialize();

        CreateItem(Item);

        ItemCard.OpenEdit();
        ItemCard.Filter.SetFilter("No.", Item."No.");

        LibraryVariableStorage.Enqueue(1); // choose to create a new special price
        LibraryVariableStorage.Enqueue(Item); // verify correct item in the handler
        ItemCard.SpecialPricesAndDiscountsTxt.DrillDown();
        ItemCard.Close();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,SalesLineDiscountsHandler')]
    [Scope('OnPrem')]
    procedure TestLaunchCreateNewSpecialDiscountViaDrilldownOnItemCard()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        Initialize();

        CreateItem(Item);

        ItemCard.OpenEdit();
        ItemCard.Filter.SetFilter("No.", Item."No.");

        LibraryVariableStorage.Enqueue(2); // choose to create a new special discount
        LibraryVariableStorage.Enqueue(Item); // verify correct item in the handler
        ItemCard.SpecialPricesAndDiscountsTxt.DrillDown();
        ItemCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemHasLinesNoDiscount()
    var
        Item: Record Item;
        SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff";
    begin
        Initialize();

        // [WHEN] A blank item with no discounts is created
        CreateBlankItem(Item);

        // [THEN] ItemHasLines returns false
        Assert.IsFalse(SalesPriceAndLineDiscBuff.ItemHasLines(Item), 'Item should not have any discount lines');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemHasLinesDiscount()
    var
        Item: Record Item;
        SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff";
    begin
        Initialize();

        // [WHEN] An Item with discounts is created
        InitItemAndDiscAndPrices(Item);

        // [THEN] ItemHasLines returns true
        Assert.IsTrue(SalesPriceAndLineDiscBuff.ItemHasLines(Item), 'Item should have discount lines');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemHasLinesDiscountGroup()
    var
        Item: Record Item;
        SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff";
    begin
        Initialize();

        // [WHEN] An Item with discount group exists
        InitItemAndDiscAndPrices(Item);
        Item."Item Disc. Group" := GetGroupCode(Item."No.");
        Item.Modify();

        // [THEN] ItemHasLines returns true
        Assert.IsTrue(SalesPriceAndLineDiscBuff.ItemHasLines(Item), 'Item should have discount lines');
    end;

    local procedure CompareBuffAgainstDiscLines(var SalesLineDiscount: Record "Sales Line Discount"; var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary)
    begin
        with SalesLineDiscount do begin
            FindFirst();

            repeat
                TempSalesPriceAndLineDiscBuff.SetRange("Line Type", TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Line Discount");
                TempSalesPriceAndLineDiscBuff.SetRange(Type, Type);
                TempSalesPriceAndLineDiscBuff.SetRange(Code, Code);
                TempSalesPriceAndLineDiscBuff.SetRange("Sales Type", "Sales Type");
                TempSalesPriceAndLineDiscBuff.SetRange("Sales Code", "Sales Code");
                TempSalesPriceAndLineDiscBuff.SetRange("Sales Code", "Sales Code");
                TempSalesPriceAndLineDiscBuff.SetRange("Currency Code", "Currency Code");
                TempSalesPriceAndLineDiscBuff.SetRange("Variant Code", "Variant Code");
                TempSalesPriceAndLineDiscBuff.SetRange("Unit of Measure Code", "Unit of Measure Code");
                TempSalesPriceAndLineDiscBuff.SetRange("Minimum Quantity", "Minimum Quantity");
                TempSalesPriceAndLineDiscBuff.FindFirst();

                TempSalesPriceAndLineDiscBuff.Get(
                  TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Line Discount",
                  Type,
                  Code,
                  "Sales Type",
                  "Sales Code",
                  "Starting Date",
                  "Currency Code",
                  "Variant Code",
                  "Unit of Measure Code",
                  "Minimum Quantity",
                  TempSalesPriceAndLineDiscBuff."Loaded Item No.",
                  TempSalesPriceAndLineDiscBuff."Loaded Disc. Group",
                  '',
                  TempSalesPriceAndLineDiscBuff."Loaded Price Group");

                Assert.AreEqual("Ending Date", TempSalesPriceAndLineDiscBuff."Ending Date", 'Wrong value');
                Assert.AreEqual("Line Discount %", TempSalesPriceAndLineDiscBuff."Line Discount %", 'Wrong value');
            until Next() = 0;
        end;
    end;

    local procedure CompareBuffAgainstPrices(var SalesPrice: Record "Sales Price"; var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary)
    begin
        with SalesPrice do begin
            FindFirst();

            repeat
                TempSalesPriceAndLineDiscBuff.Get(
                  TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Price",
                  TempSalesPriceAndLineDiscBuff.Type::Item,
                  "Item No.",
                  "Sales Type",
                  "Sales Code",
                  "Starting Date",
                  "Currency Code",
                  "Variant Code",
                  "Unit of Measure Code",
                  "Minimum Quantity",
                  TempSalesPriceAndLineDiscBuff."Loaded Item No.",
                  TempSalesPriceAndLineDiscBuff."Loaded Disc. Group",
                  '',
                  TempSalesPriceAndLineDiscBuff."Loaded Price Group");

                Assert.AreEqual(
                  "Allow Invoice Disc.", TempSalesPriceAndLineDiscBuff."Allow Invoice Disc.", 'Wrong value in Allow Invoice Disc.');
                Assert.AreEqual("Allow Line Disc.", TempSalesPriceAndLineDiscBuff."Allow Line Disc.", 'Wrong value in Allow Line Disc.');
                Assert.AreEqual("Ending Date", TempSalesPriceAndLineDiscBuff."Ending Date", 'Wrong value in Ending Date');
                Assert.AreEqual(
                  "Price Includes VAT", TempSalesPriceAndLineDiscBuff."Price Includes VAT", 'Wrong value in Price Includes VAT');
                Assert.AreEqual("Unit Price", TempSalesPriceAndLineDiscBuff."Unit Price", 'Wrong value in Unit Price');
                Assert.AreEqual(
                  "VAT Bus. Posting Gr. (Price)", TempSalesPriceAndLineDiscBuff."VAT Bus. Posting Gr. (Price)",
                  'Wrong value in VAT Bus. Posting Gr. (Price)');

            until Next() = 0;
        end;
    end;

    local procedure CompareDiscLinesAgainstBuff(var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary; var SalesLineDiscount: Record "Sales Line Discount")
    begin
        with TempSalesPriceAndLineDiscBuff do begin
            FindFirst();

            repeat
                SalesLineDiscount.Get(
                  Type,
                  Code,
                  "Sales Type",
                  "Sales Code",
                  "Starting Date",
                  "Currency Code",
                  "Variant Code",
                  "Unit of Measure Code",
                  "Minimum Quantity");

                Assert.AreEqual("Ending Date", SalesLineDiscount."Ending Date", 'Wrong value in Ending Date');
                Assert.AreEqual("Line Discount %", SalesLineDiscount."Line Discount %", 'Wrong value in Line Discount %');
            until Next() = 0;
        end;
    end;

    local procedure ComparePricesAgainstBuff(var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary; var SalesPrice: Record "Sales Price")
    begin
        with TempSalesPriceAndLineDiscBuff do begin
            FindFirst();

            repeat
                SalesPrice.Get(
                  Code,
                  "Sales Type",
                  "Sales Code",
                  "Starting Date",
                  "Currency Code",
                  "Variant Code",
                  "Unit of Measure Code",
                  "Minimum Quantity");

                Assert.AreEqual("Ending Date", SalesPrice."Ending Date", 'Wrong value in Ending Date');
                Assert.AreEqual("Unit Price", SalesPrice."Unit Price", 'Wrong value in Unit Price');
                Assert.AreEqual(
                  "Allow Invoice Disc.", SalesPrice."Allow Invoice Disc.", 'Wrong value in Allow Invoice Disc.');
                Assert.AreEqual("Allow Line Disc.", SalesPrice."Allow Line Disc.", 'Wrong value in Allow Line Disc.');
                Assert.AreEqual(
                  "Price Includes VAT", SalesPrice."Price Includes VAT", 'Wrong value in Price Includes VAT');
                Assert.AreEqual(
                  "VAT Bus. Posting Gr. (Price)", SalesPrice."VAT Bus. Posting Gr. (Price)",
                  'Wrong value in VAT Bus. Posting Gr. (Price)');

            until Next() = 0;
        end;
    end;

    local procedure CompareSalesPriceRec(ExpectedSalesPrice: Record "Sales Price"; ActualSalesPrice: Record "Sales Price")
    begin
        with ExpectedSalesPrice do begin
            Assert.AreEqual(Count, ActualSalesPrice.Count, 'Wrong count before and after for Sales Prices');
            FindSet();
            repeat
                ActualSalesPrice.Get(
                  "Item No.",
                  "Sales Type",
                  "Sales Code",
                  "Starting Date",
                  "Currency Code",
                  "Variant Code",
                  "Unit of Measure Code",
                  "Minimum Quantity");

                Assert.AreEqual("Unit Price", ActualSalesPrice."Unit Price", 'Wrong Unit Price');
                Assert.AreEqual("Ending Date", ActualSalesPrice."Ending Date", 'Wrong Ending Date');
                Assert.AreEqual("Allow Invoice Disc.", ActualSalesPrice."Allow Invoice Disc.", 'Wrong Allow Invoice Disc.');
                Assert.AreEqual("Allow Line Disc.", ActualSalesPrice."Allow Line Disc.", 'Wrong Allow Line Disc.');
                Assert.AreEqual("Price Includes VAT", ActualSalesPrice."Price Includes VAT", 'Wrong Price Includes VAT');
                Assert.AreEqual(
                  "VAT Bus. Posting Gr. (Price)", ActualSalesPrice."VAT Bus. Posting Gr. (Price)", 'Wrong VAT Bus. Posting Gr. (Price)');
            until Next() = 0;
        end;
    end;

    local procedure CompareSLDiscountsRec(ExpectedSalesLnDisc: Record "Sales Line Discount"; ActualSalesLnDisc: Record "Sales Line Discount")
    begin
        with ExpectedSalesLnDisc do begin
            Assert.AreEqual(Count, ActualSalesLnDisc.Count, 'Wrong count before and after for Sales Prices');
            FindSet();
            repeat
                ActualSalesLnDisc.Get(
                  Type,
                  Code,
                  "Sales Type",
                  "Sales Code",
                  "Starting Date",
                  "Currency Code",
                  "Variant Code",
                  "Unit of Measure Code",
                  "Minimum Quantity");

                Assert.AreEqual("Line Discount %", ActualSalesLnDisc."Line Discount %", 'Wrong Line Discount %');
                Assert.AreEqual("Ending Date", ActualSalesLnDisc."Ending Date", 'Wrong Ending Date');
            until Next() = 0;
        end;
    end;

    local procedure CreateBlankItem(var Item: Record Item)
    begin
        Item.Init();
        Item.Insert(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        Item2: Record Item;
    begin
        LibraryInventory.CreateItem(Item2);
        CreateBlankItem(Item);
        Item.Validate("Base Unit of Measure", Item2."Base Unit of Measure");
        Item.Validate("Inventory Posting Group", Item2."Inventory Posting Group");
        Item.Validate("Gen. Prod. Posting Group", Item2."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", Item2."VAT Prod. Posting Group");
        Item.Modify(true);
        LibrarySmallBusiness.SetVATBusPostingGrPriceSetup(Item."VAT Prod. Posting Group", true);
    end;

    local procedure InitItemAndDiscAndPrices(var Item: Record Item)
    begin
        CreateBlankItem(Item);
        CreateSalesLineDiscounts(Item."No.");
        CreateSalesPrices(Item."No.");
    end;

    local procedure CreateSalesPrices(ItemNo: Code[20])
    var
        SalesPrice: Record "Sales Price";
        i: Integer;
    begin
        SalesPrice.DeleteAll();

        // at least 3 lines and one in the past
        for i := 0 to 3 do begin
            // Correct Item/Group Prise
            CreateSalesPriceLine(ItemNo, i = 0);
            CreateSalesPriceLine(GetGroupCode(ItemNo), i = 0);

            // Incorrect lines
            CreateSalesPriceLine('TEST', i = 0);
        end;
    end;

    local procedure CreateSalesLineDiscounts(ItemNo: Code[20])
    var
        SalesLineDiscount: Record "Sales Line Discount";
        i: Integer;
    begin
        SalesLineDiscount.DeleteAll();

        // at least 3 lines and one in the past
        for i := 0 to 3 do begin
            // Correct lines
            CreateSalesLineDiscountLine(ItemNo, SalesLineDiscount.Type::Item, i = 0);
            CreateSalesLineDiscountLine(GetGroupCode(ItemNo), SalesLineDiscount.Type::"Item Disc. Group", i = 0);

            // Incorrect lines
            CreateSalesLineDiscountLine(ItemNo, SalesLineDiscount.Type::"Item Disc. Group", i = 0);
            CreateSalesLineDiscountLine(GetGroupCode(ItemNo), SalesLineDiscount.Type::Item, i = 0);

            CreateSalesLineDiscountLine('TEST', SalesLineDiscount.Type::Item, i = 0);
            CreateSalesLineDiscountLine('TEST', SalesLineDiscount.Type::"Item Disc. Group", i = 0);
        end;
    end;

    local procedure CreateSalesLineDiscountLine(LineCode: Code[20]; LineType: Enum "Sales Line Discount Type"; InThePast: Boolean)
    var
        SalesLineDiscount: Record "Sales Line Discount";
        i: Integer;
    begin
        for i := 0 to 3 do
            with SalesLineDiscount do begin
                Init();
                "Sales Type" := i;
                if i = "Sales Type"::"All Customers" then
                    "Sales Code" := ''
                else
                    "Sales Code" := 'SC' + Format(LibraryRandom.RandInt(100));

                Type := LineType;
                Code := LineCode;
                "Currency Code" := 'CC' + Format(LibraryRandom.RandInt(100));
                "Starting Date" := Today - LibraryRandom.RandIntInRange(2, 10);
                "Line Discount %" := LibraryRandom.RandDec(10, 2);
                "Minimum Quantity" := LibraryRandom.RandInt(100);
                if InThePast then
                    "Ending Date" := Today - 1
                else
                    "Ending Date" := Today + LibraryRandom.RandInt(100);
                "Unit of Measure Code" := 'UMC' + Format(LibraryRandom.RandInt(100));
                "Variant Code" := 'VC' + Format(LibraryRandom.RandInt(100));

                Insert();
            end;
    end;

    local procedure CreateSalesPriceLine(ItemNo: Code[20]; InThePast: Boolean)
    var
        SalesPrice: Record "Sales Price";
        i: Integer;
    begin
        // what about the Price Groups?
        for i := 0 to 3 do
            with SalesPrice do begin
                Init();
                "Item No." := ItemNo;
                "Sales Type" := "Sales Price Type".FromInteger(i);
                if i = "Sales Type"::"All Customers".AsInteger() then
                    "Sales Code" := ''
                else
                    "Sales Code" := 'SC' + Format(LibraryRandom.RandInt(100));

                "Currency Code" := 'CC' + Format(LibraryRandom.RandInt(100));
                "Starting Date" := Today - LibraryRandom.RandIntInRange(2, 100);
                "Unit Price" := LibraryRandom.RandDec(100, 2);
                "Price Includes VAT" := true;
                "Allow Invoice Disc." := true;
                "VAT Bus. Posting Gr. (Price)" := 'VAT BPG' + Format(LibraryRandom.RandInt(100));

                "Minimum Quantity" := LibraryRandom.RandInt(100);
                if InThePast then
                    "Ending Date" := Today - 1
                else
                    "Ending Date" := Today + LibraryRandom.RandInt(100);
                "Unit of Measure Code" := 'UMC' + Format(LibraryRandom.RandInt(100));
                "Variant Code" := 'VC' + Format(LibraryRandom.RandInt(100));
                "Allow Line Disc." := true;

                Insert();
            end;
    end;

    local procedure GetGroupCode(ItemNo: Code[20]): Code[10]
    begin
        exit(CopyStr('GR_' + ItemNo, 1, 10))
    end;

    local procedure GetRealisticVATBusPostingGrPrice(VATProdPostingGroup: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        VATPostingSetup.SetRange("VAT %", 1, 1000);
        VATPostingSetup.FindFirst();
        exit(VATPostingSetup."VAT Bus. Posting Group");
    end;

    local procedure PlaceFilterOn_TempSalesPriceAndLineDiscBuff_ForPriceInclVat(TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary; PriceIncludesVAT: Boolean)
    begin
        TempSalesPriceAndLineDiscBuff.SetRange("Price Includes VAT", PriceIncludesVAT);
        TempSalesPriceAndLineDiscBuff.SetRange("Line Type", TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Price");
    end;

    local procedure SetFiltersForBufferAndGetFreshSLDiscounts(var SalesLineDiscount: Record "Sales Line Discount"; var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary; SalesLineDiscountType: Enum "Sales Line Discount Type"; SalesLineDiscountCode: Code[20])
    begin
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff, false);

        GetSLDiscounts(SalesLineDiscount, SalesLineDiscountType, SalesLineDiscountCode);
    end;

    local procedure SetBufferOnlyToSLDiscounts(var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary; SetToItemGroup: Boolean)
    begin
        TempSalesPriceAndLineDiscBuff.SetRange("Line Type", TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Line Discount");
        if SetToItemGroup then
            TempSalesPriceAndLineDiscBuff.SetRange(Type, TempSalesPriceAndLineDiscBuff.Type::"Item Disc. Group");
        TempSalesPriceAndLineDiscBuff.FindSet();
    end;

    local procedure GetSLDiscounts(var SalesLineDiscount: Record "Sales Line Discount"; SalesLineDiscountType: Enum "Sales Line Discount Type"; SalesLineDiscountCode: Code[20])
    begin
        with SalesLineDiscount do begin
            Reset();
            SetRange(Type, SalesLineDiscountType);
            SetRange(Code, SalesLineDiscountCode);
            SetFilter(
              "Sales Type", '%1|%2|%3',
              "Sales Type"::Customer,
              "Sales Type"::"Customer Disc. Group",
              "Sales Type"::"All Customers");
            FindSet();
        end;
    end;

    local procedure SetFiltersForBufferAndGetFreshSPrices(var SalesPrice: Record "Sales Price"; var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary; ItemNo: Code[20])
    begin
        SetBufferOnlyToSPrices(TempSalesPriceAndLineDiscBuff);
        GetSPrices(SalesPrice, ItemNo);
    end;

    local procedure SetBufferOnlyToSPrices(var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary)
    begin
        TempSalesPriceAndLineDiscBuff.SetRange("Line Type", TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Price");
        TempSalesPriceAndLineDiscBuff.FindSet();
    end;

    local procedure GetSPrices(var SalesPrice: Record "Sales Price"; ItemNo: Code[20])
    begin
        with SalesPrice do begin
            Reset();
            SetRange("Item No.", ItemNo);
            SetFilter(
              "Sales Type", '%1|%2|%3',
              "Sales Type"::Customer,
              "Sales Type"::"Customer Price Group",
              "Sales Type"::"All Customers");
            FindSet();
        end;
    end;

    local procedure DuplicateLineInBuffer(var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary; LineDiscType: Enum "Sales Line Discount Type")
    begin
        with TempSalesPriceAndLineDiscBuff do begin
            SetRange(Type, LineDiscType);
            FindFirst();

            "Minimum Quantity" := LibraryRandom.RandInt(100);
            "Starting Date" := Today - LibraryRandom.RandIntInRange(2, 100);
            "Ending Date" := Today + LibraryRandom.RandInt(100);

            if "Line Type" = "Line Type"::"Sales Line Discount" then
                "Line Discount %" := LibraryRandom.RandDecInRange(10, 90, 2)
            else begin
                "Unit Price" := LibraryRandom.RandDecInRange(10, 100, 2);
                "Price Includes VAT" := not "Price Includes VAT";
                "Allow Invoice Disc." := not "Allow Invoice Disc.";
                "VAT Bus. Posting Gr. (Price)" := 'VBP' + Format(LibraryRandom.RandDecInRange(10, 90, 2));
                "Allow Line Disc." := not "Allow Line Disc.";
            end;

            Insert(true);

            SetRange(Type);
        end;
    end;

    local procedure UpdateLinesInBuffer(var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary; LineDiscType: Enum "Sales Line Discount Type")
    var
        i: Integer;
    begin
        with TempSalesPriceAndLineDiscBuff do begin
            SetRange(Type, LineDiscType);
            FindFirst();

            for i := 0 to 1 do begin
                "Ending Date" := "Ending Date" + LibraryRandom.RandIntInRange(1, 10);
                if "Line Type" = "Line Type"::"Sales Line Discount" then
                    "Line Discount %" := LibraryRandom.RandDecInRange(10, 90, 2)
                else begin
                    "Unit Price" := LibraryRandom.RandDecInRange(10, 100, 2);
                    "Price Includes VAT" := not "Price Includes VAT";
                    "Allow Invoice Disc." := not "Allow Invoice Disc.";
                    "VAT Bus. Posting Gr. (Price)" := 'VBP' + Format(LibraryRandom.RandDecInRange(10, 90, 2));
                    "Allow Line Disc." := not "Allow Line Disc.";
                end;

                Modify(true);
                Next();
            end;
        end;
    end;

    local procedure DeleteLineInBuffer(var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary)
    begin
        with TempSalesPriceAndLineDiscBuff do begin
            FindFirst();

            Delete(true);
            Next();
            Delete(true);
            Next();
        end;
    end;

    local procedure EditSalesSetupWithVATBusPostGrPrice()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        SalesSetup.Get();
        SalesSetup."VAT Bus. Posting Gr. (Price)" := VATPostingSetup."VAT Bus. Posting Group";
        SalesSetup.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesPricesOverviewSetPricesHandler(var SalesPriceAndLineDiscounts: TestPage "Sales Price and Line Discounts")
    var
        SalesLineDiscounts: TestPage "Sales Line Discounts";
    begin
        SalesLineDiscounts.Trap();
        SalesPriceAndLineDiscounts."Set Special Discounts".Invoke();
        LibraryVariableStorage.Enqueue(SalesLineDiscounts.ItemTypeFilter.Value());
        LibraryVariableStorage.Enqueue(SalesLineDiscounts.CodeFilterCtrl.Value());
        SalesLineDiscounts.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesPricesOverviewHandler(var SalesPriceAndLineDiscounts: TestPage "Sales Price and Line Discounts")
    var
        Item: Record Item;
        ItemVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemVar);
        Item := ItemVar;
        Assert.AreEqual(Item."No.", SalesPriceAndLineDiscounts.Code.Value, '');
        SalesPriceAndLineDiscounts.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    var
        ChoiceVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(ChoiceVar);
        Choice := ChoiceVar;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesPricesHandler(var SalesPrices: TestPage "Sales Prices")
    var
        Item: Record Item;
        ItemVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemVar);
        Item := ItemVar;
        Assert.AreEqual(Item."No.", SalesPrices."Item No.".Value, '');
        SalesPrices.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesLineDiscountsHandler(var SalesLineDiscounts: TestPage "Sales Line Discounts")
    var
        Item: Record Item;
        ItemVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemVar);
        Item := ItemVar;
        Assert.AreEqual(Item."No.", SalesLineDiscounts.Code.Value, '');
        SalesLineDiscounts.OK().Invoke();
    end;
}
#endif
