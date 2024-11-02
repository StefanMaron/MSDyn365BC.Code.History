#if not CLEAN25
codeunit 142060 "ERM Misc. Report"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Moved to IRS Forms App.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    trigger OnRun()
    begin
        // [FEATURE] [Reports]
    end;

    var
        Assert: Codeunit Assert;
#if not CLEAN23
        LibraryCosting: Codeunit "Library - Costing";
#endif
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        AvgCostControlLbl: Label 'AvgCost_Control1480001';
        AmountExclInvDiscLbl: Label 'AmountExclInvDisc';
        AmountIncVATLbl: Label 'VATBaseAmount___VATAmount';
        AmountPurchLineLbl: Label 'AmountExclInvDisc_PurchLine';
        BuyFromVendLbl: Label 'BuyFromAddr1';
        CompanyAddrLbl: Label 'CompanyAddr1';
        CompanyNameLbl: Label 'CompanyAddress1';
        CustomerNoLbl: Label 'Customer__No__';
        CustNameLbl: Label 'Cust_Name';
#if not CLEAN23
        CustNoLbl: Label 'CustNo';
#endif
        DescPurchCrMemoLineLbl: Label 'Desc_PurchCrMemoLine';
        DescPurchInvLineLbl: Label 'Description_PurchInvLine';
        DescPurchLineLbl: Label 'Desc_PurchLine';
        DescPurchRcptLineLbl: Label 'Desc_PurchRcptLine';
        DescPrintPurchLineLbl: Label 'Desc_PrintPurchLine';
        FilterTxt: Label '%1: %2';
        ItemFilterLbl: Label 'ItemFilter';
        ItemNoCapLbl: Label 'Item__No__';
        ItemNoPurchaseLinePOLbl: Label 'No_PurchLine';
        ItemDescriptionControl63Lbl: Label 'Item_Description_Control63';
        ItemInvLbl: Label 'Item_Inventory';
        ItemStandardCostLbl: Label 'Item__Standard_Cost_';
        ItemSalesQtyLbl: Label 'Item__Sales__Qty___';
        ItemTaxGroupCodeLbl: Label 'Item_Tax_Group_Code';
        ItemUnitPriceLbl: Label 'Item__Unit_Price_';
        ItemVariantCodeLbl: Label 'Item_Variant_Code';
        ItemLastDirectCostLbl: Label 'Item__Last_Direct_Cost_';
        ItemLedgerEntryLotNoLbl: Label 'Item_Ledger_Entry__Lot_No__';
        ItemLedgerEntrySerialNoLbl: Label 'Item_Ledger_Entry__Serial_No__';
        ItemLedgerEntryVariantCodeLbl: Label 'Item_Ledger_Entry_Variant_Code';
        ItemLedgerEntryLbl: Label 'ItemLedgEntryFilter';
        ItemLedgerEntryInvoicedQuantityLbl: Label 'Item_Ledger_Entry__Invoiced_Quantity_';
        ItemNoPrintLbl: Label 'ItemNumberToPrint';
        ItemNoToPrintPurchLineLbl: Label 'ItemNoToPrint_PurchLine';
        ItemNoPurchRcptLineLbl: Label 'ItemNumberToPrint_PurchRcptLine';
        ItemNoPrintPurchLineLbl: Label 'ItemNoTo_PrintPurchLine';
        InventoryItemLbl: Label 'Inventory_Item';
        LeadTimeCalculationLbl: Label 'LeadTimeCalculation_Item';
        LineAmountLbl: Label 'VATBaseAmount';
        LineAmtTaxAmtInvDiscountLbl: Label 'LineAmtTaxAmtInvDiscountAmt';
        NoItemLbl: Label 'No_Item';
        NoPurchCrMemoHdrLbl: Label 'No_PurchCrMemoHdr';
        NoPurchInvHeaderLbl: Label 'No_PurchInvHeader';
        NoPurchHeaderLbl: Label 'No_PurchHeader';
        NoPurchRcptHeaderLbl: Label 'No_PurchRcptHeader';
        OrderedQtyPurchRcptLineLbl: Label 'OrderedQty_PurchRcptLine';
        ParentItemNoCapLbl: Label 'ParentItemNo_BOMComponent';
        ProfitLbl: Label 'Profit';
        Profit1Lbl: Label 'Profit___1_';
        QuantityPerLbl: Label 'Quantityper_BOMComponent';
        QuantitySold1Lbl: Label 'QuantitySold_1_';
        QtyAvailableLbl: Label 'QtyAvailable';
        QuantityPurchCrMemoLineLbl: Label 'Quantity_PurchCrMemoLine';
        QuantityPurchInvLineLbl: Label 'Quantity_PurchInvLine';
        QtyPurchLineLbl: Label 'Qty_PurchLine';
        QtyPrintPurchLineLbl: Label 'Qty_PrintPurchLine';
        SalesLineFilterLbl: Label 'SalesLineFilter';
        SalesHeaderNoLbl: Label 'Sales_Header_No_';
        SalesLineNoLbl: Label 'Sales_Line__No__';
        SalesLineQuantityLbl: Label 'Sales_Line_Quantity';
        SalesLineDocumentNoLbl: Label 'Sales_Line__Document_No__';
        SalesLineOutstandingQuantityLbl: Label 'Sales_Line__Outstanding_Quantity_';
        SalesLineOutstandingAmountLbl: Label 'Sales_Line__Outstanding_Amount_';
        SalesLineVariantCodeLbl: Label 'Sales_Line__Variant_Code_';
#if not CLEAN23
        SalesPriceSalesCodeLbl: Label 'Sales_Price__Sales_Code_';
        SalesPriceUnitPriceLbl: Label 'Sales_Price__Unit_Price_';
#endif
        SalesLineUnitPriceLbl: Label 'Sales_Line__Unit_Price_';
        StockkeepingUnitItemNoCapLbl: Label 'Stockkeeping_Unit__Item_No__';
        StockkeepingUnitLocationCodeLbl: Label 'Stockkeeping_Unit__Location_Code_';
        StockkeepingUnitVariantCodeLbl: Label 'Stockkeeping_Unit__Variant_Code_';
        TotalValueLbl: Label 'TotalValue';
        UOMPurchCrMemoLineLbl: Label 'UOM_PurchCrMemoLine';
        UOMPurchInvLineLbl: Label 'UnitofMeasure_PurchInvLine';
        UOMPurchLineLbl: Label 'UnitofMeasure_PurchLine';
        UOMPurchRcptLineLbl: Label 'UnitofMeasure_PurchRcptLine';
        UMOPrintPurchLineLbl: Label 'umo_PrintPurchLine';
        UOMPurchLinePOLbl: Label 'UOM_PurchLine';
        ValueEntrySalesAmountActualControl29Lbl: Label 'ValueEntry__Sales_Amount__Actual___Control29';
        ValueMustMatchTxt: Label 'Value must match.';
        VendorNameLbl: Label 'BuyFromAddress1';
        VendorNamePOLbl: Label 'BuyFromAddr1';
        IRS1099CodeMiscLbl: Label 'MISC-07';
        IRS1099CodeMisc01Lbl: Label 'MISC-01';
        IRS1099CodeMisc04Lbl: Label 'MISC-04';
        IncorrectPaymentCountErr: Label 'Applied payment list contains incorrect entries';
        PaymentNotFoundErr: Label 'Payment %1 was not found';
        GetAmtMisc07Misc15BTxt: Label 'GetAmtMISC07MISC15B';
        NotHandledErr: Label 'Not Handled';

    [Test]
    [HandlerFunctions('WhereUsedListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhereUsedListReport()
    var
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        ParentItem: Record Item;
    begin
        // Verify Where-Used List report.

        // Setup: Create Item with Item Component. Create and update  BOM Component.
        Initialize();
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(Item);
        CreateAndUpdateBOMComponent(BOMComponent, ParentItem."No.", Item."No.");
        LibraryVariableStorage.Enqueue(Item."No.");
        Commit();  // Commit required.

        // Exercise: Run Where-Used List Report.
        REPORT.Run(REPORT::"Where-Used List");

        // Verify: Verify Where-Used List report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(ParentItem."No.", ParentItemNoCapLbl, QuantityPerLbl, BOMComponent."Quantity per");
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMSubAssembliesHandler')]
    [Scope('OnPrem')]
    procedure BOMSubAssembliesReportWithStockKeepingExistAsTrue()
    var
        Item: Record Item;
    begin
        // Verify Assembly BOM - Subassemblies report with Stock Keeping Exist as True.

        // Setup.
        Initialize();

        // Exercise;
        BOMSubAssembliesReportWithStockKeepingExist(Item, true);  // StockKeepingExist as True.

        // Verify: Verify Assembly BOM - Subssemblies report with Stock Keeping Exist as True.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(Item."No.", NoItemLbl, InventoryItemLbl, 0);  // Value 0 required.
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMSubAssembliesHandler')]
    [Scope('OnPrem')]
    procedure BOMSubAssembliesReportWithStockKeepingExistAsFalse()
    var
        Item: Record Item;
    begin
        // Verify Assembly BOM - Subassemblies report with Stock Keeping Exist as False.

        // Setup.
        Initialize();

        // Exercise.
        BOMSubAssembliesReportWithStockKeepingExist(Item, false);  // StockKeepingExist as False.

        // Verify: Verify Assembly BOM - Subassemblies report with Stock Keeping Exist as False.
        LibraryReportDataset.LoadDataSetFile();
        asserterror LibraryReportDataset.AssertElementWithValueExists('No_Item', Item."No.");
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMRawMaterialsHandler')]
    [Scope('OnPrem')]
    procedure BOMRawMaterialsReportWithStockKeepingExistAsTrue()
    var
        Item: Record Item;
    begin
        // Verify Assembly BOM - Raw Materials with Stock Keeping Exist as True.

        // Setup.
        Initialize();

        // Exercise.
        BOMRawMaterialsReportWithStockKeepingExist(Item, true);  // StockKeepingExist as True.

        // Verify: Verify Assembly BOM - Raw Materials with Stock Keeping Exist as True.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(Item."No.", NoItemLbl, InventoryItemLbl, 0);  // Value 0 required.
        LibraryReportDataset.AssertCurrentRowValueEquals(LeadTimeCalculationLbl, Format(Item."Lead Time Calculation"));
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMRawMaterialsHandler')]
    [Scope('OnPrem')]
    procedure BOMRawMaterialsReportWithStockKeepingExistAsFalse()
    var
        Item: Record Item;
    begin
        // Verify Assembly BOM - Raw Materials with Stock Keeping Exist as True.

        // Setup.
        Initialize();

        // Exercise.
        BOMRawMaterialsReportWithStockKeepingExist(Item, false);  // StockKeepingExist as False.

        // Verify: Verify Assembly BOM - Raw Materials with Stock Keeping Exist as False.
        LibraryReportDataset.LoadDataSetFile();
        asserterror LibraryReportDataset.AssertElementWithValueExists('Item_No', Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemCostAndPriceListReportHandler')]
    [Scope('OnPrem')]
    procedure ItemCostAndPriceListReport()
    var
        Item: Record Item;
        ValueEntry: Record "Value Entry";
    begin
        // Verify Item Cost and Price List Report with Stockkeeping Unit False.

        // Setup:
        Initialize();
        CreateAndModifyItem(Item);
        SetupForItemCostAndPriceReport(Item."No.");

        // Exercise.
        REPORT.Run(REPORT::"Item Cost and Price List");

        // Verify: Verify various cost and price on Item Cost and Price List Report.
        Item.Get(Item."No.");
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.CalcSums("Item Ledger Entry Quantity", "Cost Amount (Actual)");
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(Item."No.", ItemNoCapLbl, ItemStandardCostLbl, Item."Standard Cost");
        VerifyValuesOnReport(Item."No.", ItemNoCapLbl, ItemUnitPriceLbl, Item."Unit Price");
        VerifyValuesOnReport(Item."No.", ItemNoCapLbl, ItemLastDirectCostLbl, Item."Last Direct Cost");
        VerifyValuesOnReport(
          Item."No.", ItemNoCapLbl, AvgCostControlLbl, ValueEntry."Cost Amount (Actual)" / ValueEntry."Item Ledger Entry Quantity");
    end;

    [Test]
    [HandlerFunctions('ItemCostAndPriceListReportHandler')]
    [Scope('OnPrem')]
    procedure ItemCostAndPriceListReportSKUTrue()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // Verify Item Cost and Price List Report with Stockkeeping Unit True.

        // Setup:
        Initialize();
        CreateAndModifyItem(Item);
        CreateItemWithStockkeepingUnit(StockkeepingUnit, Item."No.", CreateLocation());
        SetupForItemCostAndPriceReport(StockkeepingUnit."Item No.");

        // Exercise.
        REPORT.Run(REPORT::"Item Cost and Price List");

        // Verify: Verify Location Code and Item Variant code on Item Cost and Price List Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(
          StockkeepingUnit."Item No.", ItemNoCapLbl, StockkeepingUnitLocationCodeLbl, StockkeepingUnit."Location Code");
        VerifyValuesOnReport(
          StockkeepingUnit."Item No.", ItemNoCapLbl, StockkeepingUnitVariantCodeLbl, StockkeepingUnit."Variant Code");
    end;

    [Test]
    [HandlerFunctions('BackOrderFillByItemHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BackOrderFillByItemReport()
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Verify Back Order Fill by Item Report.

        // Setup: Create and post Sales Order.
        Initialize();
        CreateAndPostSalesOrder(
          SalesLine, CreateAndUpdateTaxGroupOnItem(), '', CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Added random days to Workdate
        LibraryVariableStorage.Enqueue(SalesLine."No.");  // Enqueue for BackOrderFillByItemHandler.
        Commit();  // COMMIT required to run the report.

        // Exercise.
        REPORT.Run(REPORT::"Back Order Fill by Item");

        // Verify: Verify Quantity, Outstanding Quantity, Customer No on Back Order Fill by Item Report.
        Item.Get(SalesLine."No.");
        Item.CalcFields(Inventory);
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, ItemInvLbl, Item.Inventory);
        VerifyValuesOnReport(Item."No.", ItemNoCapLbl, CustNameLbl, SalesLine."Sell-to Customer No.");
        VerifySalesLineValuesOnBackOrderReport(Item."No.", ItemNoCapLbl, SalesLine);
    end;

    [Test]
    [HandlerFunctions('BackOrderFillbyCustomerHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BackOrderFillByCustomerReport()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Back Order Fill by Customer Report.

        // Setup: Create and post Sales Order.
        Initialize();
        CreateAndPostSalesOrder(
          SalesLine, CreateAndUpdateTaxGroupOnItem(), '', CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Added random days to Workdate
        LibraryVariableStorage.Enqueue(SalesLine."Sell-to Customer No.");  // Enqueue for BackOrderFillbyCustomerHandler.
        Commit();  // COMMIT required to run the report.

        // Exercise.
        REPORT.Run(REPORT::"Back Order Fill by Customer");

        // Verify Quantity, Outstanding Quantity, Customer No on Back Order Fill by Item Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(SalesLine."Sell-to Customer No.", CustomerNoLbl, SalesLineNoLbl, SalesLine."No.");
        VerifySalesLineValuesOnBackOrderReport(SalesLine."Sell-to Customer No.", CustomerNoLbl, SalesLine);
    end;

    [Test]
    [HandlerFunctions('ItemListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemListReportWithSKUFalse()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
    begin
        // Verify Item List Report with Stockkeeping Unit False.

        // Setup: Create Item, create and post Purchase Order.
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        CreateAndPostPurchaseDocument(ItemNo, PurchaseHeader."Document Type"::Order, true);
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(false);  // Enqueue for ItemListRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Item List");

        // Verify: Verify Inventory and Inventory value on Item List Report
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo);
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(ItemNo, ItemNoCapLbl, ItemInvLbl, ItemLedgerEntry.Quantity);
        VerifyValuesOnReport(ItemNo, ItemNoCapLbl, TotalValueLbl, ItemLedgerEntry."Cost Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('ItemListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemListReportWithSKUTrue()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // Verify Item List Report with Stockkeeping Unit True.

        // Setup: Create Item with Stockkeeping Unit, create and post Purchase Order.
        Initialize();
        CreateAndModifyItem(Item);
        CreateItemWithStockkeepingUnit(StockkeepingUnit, Item."No.", CreateLocation());
        CreateAndPostPurchaseDocument(StockkeepingUnit."Item No.", PurchaseHeader."Document Type"::Order, true);
        LibraryVariableStorage.Enqueue(StockkeepingUnit."Item No.");
        LibraryVariableStorage.Enqueue(true);  // Enqueue for ItemListRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Item List");

        // Verify: Verify Location Code and Variant Code on Item List Report
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(
          StockkeepingUnit."Item No.", StockkeepingUnitItemNoCapLbl, StockkeepingUnitLocationCodeLbl,
          StockkeepingUnit."Location Code");
        VerifyValuesOnReport(
          StockkeepingUnit."Item No.", StockkeepingUnitItemNoCapLbl, StockkeepingUnitVariantCodeLbl,
          StockkeepingUnit."Variant Code");
    end;

#if not CLEAN23
    [Test]
    [HandlerFunctions('SalesPromotionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesPromotionReport()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
    begin
        // Verify Sales Promotion Report.

        // Create Item, Sales Price.
        Initialize();
        CreateAndModifyItem(Item);
        CreateAndModifySalesPrice(
          SalesPrice, Item, SalesPrice."Sales Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryERM.CreateCurrencyWithRandomExchRates());
        LibraryVariableStorage.Enqueue(Item."No.");  // Enqueue for SalesPromotionRequestPageHandler.
        Commit();  // COMMIT required to run the report.

        // Exercise.
        REPORT.Run(REPORT::"Sales Promotion");

        // verify Sales Code, Unit Price and Sales Price on Sales Promotion Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(Item."No.", ItemNoCapLbl, SalesPriceSalesCodeLbl, SalesPrice."Sales Code");
        VerifyValuesOnReport(Item."No.", ItemNoCapLbl, ItemUnitPriceLbl, Item."Unit Price");
        VerifyValuesOnReport(Item."No.", ItemNoCapLbl, SalesPriceUnitPriceLbl, SalesPrice."Unit Price");
    end;
#endif

    [Test]
    [HandlerFunctions('SalesOrderStatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderStatusReportWithputCurr()
    begin
        // Verify Sales Order Status Report Without Currency.
        SalesOrderStatusReport('');
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderStatusReportWithCurr()
    begin
        // Verify Sales Order Status Report With Currency.
        SalesOrderStatusReport(LibraryERM.CreateCurrencyWithRandomExchRates())
    end;

    local procedure SalesOrderStatusReport(CurrencyCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create and post Sales Order.
        Initialize();
        CreateAndPostSalesOrder(SalesLine, CreateAndUpdateTaxGroupOnItem(), CurrencyCode, WorkDate());
        LibraryVariableStorage.Enqueue(SalesLine."No.");  // Enqueue for SalesOrderStatusRequestPageHandler
        Commit();  // COMMIT required to run the report.

        // Exercise.
        REPORT.Run(REPORT::"Sales Order Status");

        // Verify: Verify Outstandin Quantity, Unit Price and Outstanding Amount on Sales Order Status Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, SalesLineOutstandingQuantityLbl, SalesLine."Outstanding Quantity");
        VerifyValuesOnReport(
          SalesLine."No.", ItemNoCapLbl, SalesLineUnitPriceLbl,
          LibraryERM.ConvertCurrency(SalesLine."Unit Price", CurrencyCode, '', WorkDate()));
        VerifyValuesOnReport(
          SalesLine."No.", ItemNoCapLbl, SalesLineOutstandingAmountLbl,
          LibraryERM.ConvertCurrency(SalesLine."Outstanding Amount", CurrencyCode, '', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ItemsBySalesTaxGroupRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemsBySalesTaxGroupReport()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Items by Sales Tax Group Report.

        // Setup: Create and post Sales Order.
        Initialize();
        CreateAndPostSalesOrder(SalesLine, CreateAndUpdateTaxGroupOnItem(), '', WorkDate());
        LibraryVariableStorage.Enqueue(SalesLine."No.");  // Enqueue for ItemsBySalesTaxGroupRequestPageHandler.
        Commit();  // COMMIT required to run the report.

        // Exercise.
        REPORT.Run(REPORT::"Items by Sales Tax Group");

        // Verify: Verify Item No on Items by Sales Tax Group Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, ItemTaxGroupCodeLbl, SalesLine."Tax Group Code");
    end;

#if not CLEAN23
    [Test]
    [HandlerFunctions('ListPriceSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ListPriceSheetCustomerNoError()
    var
        SalesType: Enum "Sales Price Type";
    begin
        // Verify error on List Price Sheet Report for blank Customer No.
        ListPriceSheetReportError(SalesType::Customer);
    end;

    [Test]
    [HandlerFunctions('ListPriceSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ListPriceSheetCustPriceGroupError()
    var
        SalesType: Enum "Sales Price Type";
    begin
        // Verify error on List Price Sheet Report for blank Customer Price Group.
        ListPriceSheetReportError(SalesType::"Customer Price Group");
    end;

    [Test]
    [HandlerFunctions('ListPriceSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ListPriceSheetCampaignNoError()
    var
        SalesType: Enum "Sales Price Type";
    begin
        // Verify error on List Price Sheet Report for blank Campaign No.
        ListPriceSheetReportError(SalesType::Campaign);
    end;

    local procedure ListPriceSheetReportError(SalesType: Enum "Sales Price Type")
    begin
        // Setup.
        Initialize();
        EnqueueValuesForListPriceSheetReport(SalesType, '', '');
        Commit();  // COMMIT required to run the report.

        // Exercise.
        asserterror REPORT.Run(REPORT::"List Price Sheet");

        // Verify: Verify error on List Price Sheet Report.
        case SalesType of
            "Sales Price Type"::Customer:
                Assert.ExpectedErrorCannotFind(Database::Customer);
            "Sales Price Type"::Campaign:
                Assert.ExpectedErrorCannotFind(Database::Campaign);
            "Sales Price Type"::"Customer Price Group":
                Assert.ExpectedErrorCannotFind(Database::"Customer Price Group");
            else
                Error(NotHandledErr);
        end;
    end;

    [Test]
    [HandlerFunctions('ListPriceSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ListPriceSheetReportForSalesTypeCustomer()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        SalesType: Enum "Sales Price Type";
    begin
        // Verify List Price Sheet Report for Sales Type Customer.

        // Setup.
        Initialize();
        CreateAndModifyItem(Item);
        CreateAndModifySalesPrice(
          SalesPrice, Item, SalesPrice."Sales Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryERM.CreateCurrencyWithRandomExchRates());
        EnqueueValuesForListPriceSheetReport(SalesType::Customer, SalesPrice."Sales Code", Item."No.");
        Commit();  // COMMIT required to run the report.

        // Exercise.
        REPORT.Run(REPORT::"List Price Sheet");

        // Verify: Verify Customer No. on List Price Sheet Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(Item."No.", ItemNoCapLbl, CustNoLbl, SalesPrice."Sales Code");
    end;
#endif

    [Test]
    [HandlerFunctions('AvailabilityStatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AvailabilityStatusReport()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        SalesLine: Record "Sales Line";
    begin
        // Verify Availability Status Report.

        // Setup: Create Item, create and post Purchase order.
        Initialize();
        Item.Get(CreateAndUpdateTaxGroupOnItem());
        CreateAndPostPurchaseDocument(Item."No.", PurchaseHeader."Document Type"::Order, true);

        // Create and refresh Production Order, create Sales Order.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandDec(10, 2));  // Taken random value for Quantity.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        CreateAndModifySalesDocument(
          SalesLine, SalesLine."Document Type"::Order, Item."No.", '', WorkDate(), '', '', LibrarySales.CreateCustomerNo());
        LibraryVariableStorage.Enqueue(Item."No.");
        Commit();  // COMMIT required to run the report.

        // Exercise.
        REPORT.Run(REPORT::"Availability Status");

        // Verify Quanity Available on Availability Status Report.
        Item.CalcFields(Inventory);
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(
          Item."No.", ItemNoCapLbl, QtyAvailableLbl, Item.Inventory + ProductionOrder.Quantity - SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('PickingListByItemRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PickingListByItemReportItemNoFilter()
    var
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // Verify Picking List by Item Report with Item No. filter.
        Initialize();
        ItemNo := CreateAndUpdateTaxGroupOnItem();
        PickingListByItemReport(
          ItemNo, '', LibrarySales.CreateCustomerNo(), '', ItemNo, '', ItemFilterLbl, StrSubstNo(FilterTxt, Item.FieldCaption("No."), ItemNo));
    end;

    [Test]
    [HandlerFunctions('PickingListByItemRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PickingListByItemReportLocationFilter()
    var
        SalesLine: Record "Sales Line";
        LocationCode: Code[10];
    begin
        // Verify Picking List by Item Report with Location filter.
        Initialize();
        LocationCode := CreateLocation();
        PickingListByItemReport(
          CreateAndUpdateTaxGroupOnItem(), LocationCode, LibrarySales.CreateCustomerNo(), '', '', '', SalesLineFilterLbl, StrSubstNo(
            FilterTxt, SalesLine.FieldCaption("Location Code"), LocationCode));
    end;

    [Test]
    [HandlerFunctions('PickingListByItemRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PickingListByItemReportSellToCustNoFilter()
    var
        SalesLine: Record "Sales Line";
        SellToCustNo: Code[20];
    begin
        // Verify Picking List by Item Report with Sell To Customer No. filter.
        Initialize();
        SellToCustNo := LibrarySales.CreateCustomerNo();
        PickingListByItemReport(
          CreateAndUpdateTaxGroupOnItem(), '', SellToCustNo, '', '', SellToCustNo, SalesLineFilterLbl, StrSubstNo(
            FilterTxt, SalesLine.FieldCaption("Sell-to Customer No."), SellToCustNo));
    end;

    [Test]
    [HandlerFunctions('PickingListByItemRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PickingListByItemReportDocNoFilter()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesLine: Record "Sales Line";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
    begin
        // Verify Picking List by Item Report with Sales Line Document No. filter.
        Initialize();
        SalesReceivablesSetup.Get();
        DocumentNo := NoSeries.PeekNextNo(SalesReceivablesSetup."Order Nos.");
        PickingListByItemReport(
          CreateAndUpdateTaxGroupOnItem(), '', LibrarySales.CreateCustomerNo(), DocumentNo, '', '', SalesLineFilterLbl, StrSubstNo(
            FilterTxt, SalesLine.FieldCaption("Document No."), DocumentNo));
    end;

    local procedure PickingListByItemReport(ItemNo: Code[20]; LocationCode: Code[10]; SellToCustomerNo: Code[20]; DocumentNo: Code[20]; ItemFilter: Code[20]; SellToCusomerNoFilter: Code[20]; FilterTxtCaption: Text[50]; FilterTxtValue: Text[50])
    var
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Sales Order.
        CreateAndModifySalesDocument(SalesLine, SalesLine."Document Type"::Order, ItemNo, '', WorkDate(), '', LocationCode, SellToCustomerNo);
        LibraryVariableStorage.Enqueue(ItemFilter);
        LibraryVariableStorage.Enqueue(LocationCode);
        LibraryVariableStorage.Enqueue(SellToCusomerNoFilter);
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue for PickingListByItemRequestPageHandler.
        Commit();  // COMMIT required for running report.

        // Exercise.
        REPORT.Run(REPORT::"Picking List by Item");

        // Verify: Verify filter text, Sales Line Quantity on Picking List by Item Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(FilterTxtCaption, FilterTxtValue);
        VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, SalesLineQuantityLbl, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,PickingListbyOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PickingListByOrderReport()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Picking List by Order Report after creating Sales Order with Item Tracking.

        // Setup: Create Sales Order with Tracked Item.
        Initialize();
        CreateSalesOrderWithItemTracking(SalesLine);
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");

        // Exercise.
        REPORT.Run(REPORT::"Picking List by Order");

        // Verify: Verify Item No, Quantity and Variant code on Picking List by Order Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(SalesLine."Document No.", SalesHeaderNoLbl, SalesLineNoLbl, SalesLine."No.");
        VerifyValuesOnReport(SalesLine."Document No.", SalesHeaderNoLbl, SalesLineQuantityLbl, SalesLine.Quantity);
        VerifyValuesOnReport(SalesLine."Document No.", SalesHeaderNoLbl, SalesLineVariantCodeLbl, SalesLine."Variant Code");
    end;

    [Test]
    [HandlerFunctions('GetFiltersOnPickingListbyOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvokingPickingListByOrderReportFromCurrentSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales] [Order] [Picking List by Order]
        // [SCENARIO 274369] "Picking List by Order" report invoked from a sales order should refer to this order.
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Sales order "X".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        Commit();

        // [WHEN] Invoke "Picking List by Order" on the sales order page for "X".
        SalesOrder.OpenView();
        SalesOrder.GotoKey(SalesHeader."Document Type", SalesHeader."No.");
        SalesOrder."Report Picking List by Order".Invoke();

        // [THEN] The report's request page has "Sales Header" data item filtered by "X"."Document Type" and "X"."No.".
        Assert.AreEqual(
          SalesHeader."Document Type", LibraryVariableStorage.DequeueInteger(),
          'Picking List by Order report refers to wrong sales document type.');
        Assert.AreEqual(
          SalesHeader."No.", LibraryVariableStorage.DequeueText(),
          'Picking List by Order report refers to wrong sales document no.');
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,SerialNumberSoldHistoryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SerialNoSoldHistoryReport()
    var
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Verify Serial No. Sold History Report after posting Sales Order with Item Tracking.

        // Setup: Create Sales Order with Tracked Item.
        Initialize();
        CreateSalesOrderWithItemTracking(SalesLine);
        ReservationEntry.SetRange("Item No.", SalesLine."No.");
        ReservationEntry.FindFirst();
        PostSalesDocument(SalesLine);

        // Enqueue for SerialNumberSoldHistoryRequestPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."No.");
        LibraryVariableStorage.Enqueue(SalesLine."Variant Code");

        // Exercise.
        REPORT.Run(REPORT::"Serial Number Sold History");

        // Verify: Verify Serial No, Lot No, Variant code on Serial No. Sold History Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, ItemLedgerEntryLotNoLbl, ReservationEntry."Lot No.");
        VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, ItemLedgerEntrySerialNoLbl, ReservationEntry."Serial No.");
        VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, ItemLedgerEntryVariantCodeLbl, SalesLine."Variant Code");
    end;

    [Test]
    [HandlerFunctions('ItemSalesByCustomerHandler')]
    [Scope('OnPrem')]
    procedure ItemSalesByCustomerReportItemNoFilter()
    var
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // Verify Item Sales By Customer Report with Item No. filter.
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ItemSalesByCustomerReport(
          ItemNo, LibrarySales.CreateCustomerNo(), ItemNo, '', ItemFilterLbl, StrSubstNo(FilterTxt, Item.FieldCaption("No."), ItemNo));
    end;

    [Test]
    [HandlerFunctions('ItemSalesByCustomerHandler')]
    [Scope('OnPrem')]
    procedure ItemSalesByCustomerReportCustNoFilter()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        CustomerNo: Code[20];
    begin
        // Verify Item Sales By Customer Report with Customer No. filter.
        Initialize();
        CustomerNo := LibrarySales.CreateCustomerNo();
        ItemSalesByCustomerReport(
          LibraryInventory.CreateItemNo(), CustomerNo, '', CustomerNo, ItemLedgerEntryLbl,
          StrSubstNo(FilterTxt, ItemLedgerEntry.FieldCaption("Source No."), CustomerNo));
    end;

    local procedure ItemSalesByCustomerReport(ItemNo: Code[20]; CustomerNo: Code[20]; ItemFilter: Code[20]; CustomerFilter: Code[20]; FilterTxtCaption: Text[50]; FilterTxtValue: Text[50])
    var
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Setup: Create and post Sales Order.
        CreateAndModifySalesDocument(SalesLine, SalesLine."Document Type"::Order, ItemNo, '', WorkDate(), '', '', CustomerNo);
        PostSalesDocument(SalesLine);
        EnqueueValuesForItemSalesByCustomerReport(
          SalesLine.Quantity * SalesLine."Unit Price" - 1, SalesLine.Quantity * SalesLine."Unit Price" + 1, SalesLine.Quantity - 1,
          SalesLine.Quantity + 1, ItemFilter, CustomerFilter, false);

        // Exercise.
        REPORT.Run(REPORT::"Item Sales by Customer");

        // Verify: Verify Filter text, Quantity, Sales Amount and Profit on Item Sales By Customer Report.
        FindItemLedgerEntry(ItemLedgerEntry, SalesLine."No.");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(FilterTxtCaption, FilterTxtValue);
        VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, ItemLedgerEntryInvoicedQuantityLbl, SalesLine.Quantity);
        VerifyValuesOnReport(
          SalesLine."No.", ItemNoCapLbl, ValueEntrySalesAmountActualControl29Lbl, ItemLedgerEntry."Sales Amount (Actual)");
        VerifyValuesOnReport(
          SalesLine."No.", ItemNoCapLbl, ProfitLbl, ItemLedgerEntry."Sales Amount (Actual)" + ItemLedgerEntry."Cost Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('ItemSalesByCustomerHandler')]
    [Scope('OnPrem')]
    procedure ItemSalesByCustomerReportIncludeReturnsTrue()
    var
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Verify Item Sales By Customer Report with Include Returns True.

        // Setup: Create and post Sales Order, create and post Sales Return Order
        Initialize();
        CreateAndPostSalesOrder(SalesLine, LibraryInventory.CreateItemNo(), '', WorkDate());
        Quantity := SalesLine."Quantity Shipped";

        // Create and post Sales Return Order.
        CreateAndModifySalesDocument(
          SalesLine, SalesLine."Document Type"::"Return Order", SalesLine."No.", '', WorkDate(), '', '', SalesLine."Sell-to Customer No.");
        PostSalesDocument(SalesLine);
        EnqueueValuesForItemSalesByCustomerReport(0, 0, 0, 0, SalesLine."No.", '', true);

        // Exercise.
        REPORT.Run(REPORT::"Item Sales by Customer");

        // Verify: Verify Sales Quantity and return Quantity on Item Sales By Customer Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(ItemNoCapLbl, SalesLine."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ItemLedgerEntryInvoicedQuantityLbl, Quantity);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ItemLedgerEntryInvoicedQuantityLbl, -SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemSalesStatisticsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemSalesStatisticsReportWithVariantFalse()
    begin
        // Verify Item Sales Statistics Report with Variant and Description False.
        Initialize();
        ItemSalesStatisticsReport(LibraryInventory.CreateItemNo(), '', false, false, '');
    end;

    [Test]
    [HandlerFunctions('ItemSalesStatisticsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemSalesStatisticsReportWithVariantTrue()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        // Verify Item Sales Statistics Report with Variant and Description True.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemSalesStatisticsReport(Item."No.", ItemVariant.Code, true, true, Item.Description);
    end;

    local procedure ItemSalesStatisticsReport(ItemNo: Code[20]; VariantCode: Code[10]; IncludeDescription: Boolean; BreakdownByVariant: Boolean; Description: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create and post Sales Order.
        CreateAndModifySalesDocument(
          SalesLine, SalesLine."Document Type"::Order, ItemNo, '', WorkDate(), VariantCode, '', LibrarySales.CreateCustomerNo());
        PostSalesDocument(SalesLine);
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(IncludeDescription);
        LibraryVariableStorage.Enqueue(BreakdownByVariant);  // Enqueue for ItemSalesStatisticsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Item Sales Statistics");
        Commit();

        // Verify: Verify Variant code, Item description and Quantity on Item Sales Statistics Report.
        LibraryReportDataset.LoadDataSetFile();
        if BreakdownByVariant then
            VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, ItemVariantCodeLbl, VariantCode)
        else
            asserterror VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, ItemVariantCodeLbl, VariantCode);
        if BreakdownByVariant then
            VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, ItemDescriptionControl63Lbl, Description)
        else
            asserterror VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, ItemDescriptionControl63Lbl, Description);
        VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, ItemSalesQtyLbl, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('SalesHistoryRequestPagehandler')]
    [Scope('OnPrem')]
    procedure SalesHistoryReportAfterPostingSalesOrder()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales History Report after posting Sales Order.

        // Setup: Create and post Sales Order.
        Initialize();
        CreateAndPostSalesOrder(SalesLine, LibraryInventory.CreateItemNo(), '', WorkDate());
        LibraryVariableStorage.Enqueue(SalesLine."No.");  // Enqueue for SalesHistoryRequestPagehandler.

        // Exercise.
        REPORT.Run(REPORT::"Sales History");

        // Verify: Verify Quantity sold and Profit percent on Sales History Report.
        Item.Get(SalesLine."No.");
        Item.CalcFields("COGS (LCY)", "Sales (LCY)", "Sales (Qty.)");
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, QuantitySold1Lbl, SalesLine."Quantity Shipped");
        VerifyValuesOnReport(
          SalesLine."No.", ItemNoCapLbl, Profit1Lbl,
          Round((Item."Sales (LCY)" - Item."COGS (LCY)") / Item."Sales (LCY)" * 100, LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [HandlerFunctions('PurchCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoReportWithPrintCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Purchase Cr. Memo Report with Print Company and without Log Interaction option.
        CompanyInformation.Get();
        PurchaseCrMemoReport(true, false, true, CompanyInformation.Name);
    end;

    [Test]
    [HandlerFunctions('PurchCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoReportWithLogInteraction()
    begin
        // Verify Purchase Cr. Memo Report without Print Company and with Log Interaction option.
        PurchaseCrMemoReport(false, true, false, '');
    end;

    [Test]
    [HandlerFunctions('PurchCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoReportWithPrintCompAndLogInt()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Purchase Cr. Memo Report with Print Company and Log Interaction option.
        CompanyInformation.Get();
        PurchaseCrMemoReport(true, true, false, CompanyInformation.Name);
    end;

    local procedure PurchaseCrMemoReport(PrintCompanyAddress: Boolean; LogInteraction: Boolean; ActualLogInteraction: Boolean; CompanyName: Text[100])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Purchse Cr. Memo, open and execute Purch. Cr. Memo report from posted Cr. Memo.
        Initialize();
        LibraryInventory.CreateItem(Item);
        DocumentNo := CreateAndPostPurchaseDocument(Item."No.", PurchaseHeader."Document Type"::"Credit Memo", true);
        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.FILTER.SetFilter("No.", DocumentNo);
        Vendor.SetRange(Name, PostedPurchaseCreditMemo."Buy-from Vendor Name".Value);
        Vendor.FindFirst();
        EnqueueValuesforPurchaseDocument(Vendor."No.", PrintCompanyAddress, LogInteraction);  // Enqueue values for PurchCrMemoRequestPageHandler.

        // Exercise.
        PostedPurchaseCreditMemo."&Print".Invoke();  // Print.

        // Verify: Verify Purch. Cr. Memo report with Print Company and Lot Interaction.
        VerifyPurchaseDocument(
          Item, DocumentNo, CompanyName, PostedPurchaseCreditMemo."Buy-from Vendor Name".Value,
          NoPurchCrMemoHdrLbl, DescPurchCrMemoLineLbl, UOMPurchCrMemoLineLbl, ItemNoPrintLbl,
          CompanyNameLbl, VendorNameLbl);

        VerifyAmtAndQtyOnPurchDocument(
          Item."No.", ItemNoPrintLbl, QuantityPurchCrMemoLineLbl, PostedPurchaseCreditMemo.PurchCrMemoLines.Quantity.AsDecimal(),
          AmountExclInvDiscLbl, PostedPurchaseCreditMemo.PurchCrMemoLines."Line Amount".AsDecimal());

        VerifyLogInteraction(DocumentNo, ActualLogInteraction);
    end;

    [Test]
    [HandlerFunctions('PurchInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceReportWithPrintCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Purchase Invoice Report with Print Company and without Log Interaction option.
        CompanyInformation.Get();
        PurchaseInvoiceReport(true, false, true, CompanyInformation.Name);
    end;

    [Test]
    [HandlerFunctions('PurchInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceReportWithLogInteraction()
    begin
        // Verify Purchase Invoice Report without Print Company and with Log Interaction option.
        PurchaseInvoiceReport(false, true, false, '');
    end;

    [Test]
    [HandlerFunctions('PurchInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceReportWithPrintCompAndLogInt()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Purchase Invoice Report with Print Company and Log Interaction option.
        CompanyInformation.Get();
        PurchaseInvoiceReport(true, true, false, CompanyInformation.Name);
    end;

    local procedure PurchaseInvoiceReport(PrintCompanyAddress: Boolean; LogInteraction: Boolean; ActualLogInteraction: Boolean; CompanyName: Text[100])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Purchse Invoice, open and execute Purch. Invoice report from posted invoice.
        Initialize();
        LibraryInventory.CreateItem(Item);
        DocumentNo := CreateAndPostPurchaseDocument(Item."No.", PurchaseHeader."Document Type"::Invoice, true);
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.FILTER.SetFilter("No.", DocumentNo);
        EnqueueValuesforPurchaseDocument(PurchaseHeader."Buy-from Vendor No.", PrintCompanyAddress, LogInteraction);  // Enqueue values for PurchInvoiceRequestPageHandler.

        // Exercise.
        PostedPurchaseInvoice.Print.Invoke();  // Print.

        // Verify: Verify Purchase Invoice report with Print Company and Log Interaction.
        VerifyPurchaseDocument(
          Item, DocumentNo, CompanyName, PostedPurchaseInvoice."Buy-from Vendor Name".Value,
          NoPurchInvHeaderLbl, DescPurchInvLineLbl, UOMPurchInvLineLbl, ItemNoPrintLbl,
          CompanyNameLbl, VendorNameLbl);

        VerifyAmtAndQtyOnPurchDocument(
          Item."No.", ItemNoPrintLbl, QuantityPurchInvLineLbl, PostedPurchaseInvoice.PurchInvLines.Quantity.AsDecimal(),
          AmountExclInvDiscLbl, PostedPurchaseInvoice.PurchInvLines."Line Amount".AsDecimal());

        VerifyLogInteraction(DocumentNo, ActualLogInteraction);
    end;

    [Test]
    [HandlerFunctions('PurchOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderReportWithPrintCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Purchase Order Report with Print Company and without Log Interaction option.
        CompanyInformation.Get();
        PurchaseOrderReport(true, false, true, CompanyInformation.Name);
    end;

    [Test]
    [HandlerFunctions('PurchOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderReportWithLogInteraction()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Purchase Order Report without Print Company and with Log Interaction option.
        // With the new default 1322 Report there is NO option to generate report without Print Company.
        CompanyInformation.Get();
        PurchaseOrderReport(false, true, false, CompanyInformation.Name);
    end;

    [Test]
    [HandlerFunctions('PurchOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderReportWithPrintCompAndLogInt()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Purchase Order Report with Print Company and Log Interaction option.
        CompanyInformation.Get();
        PurchaseOrderReport(true, true, false, CompanyInformation.Name);
    end;

    local procedure PurchaseOrderReport(PrintCompanyAddress: Boolean; LogInteraction: Boolean; ActualLogInteraction: Boolean; CompanyName: Text[100])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Setup: Create Purchse Order, open and execute Purch. Order report.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, Item."No.", PurchaseHeader."Document Type"::Order);
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        Commit();  // Commit required for Run Purchase Order Report.
        EnqueueValuesforPurchaseDocument(PurchaseHeader."Buy-from Vendor No.", PrintCompanyAddress, LogInteraction);  // Enqueue values for PurchOrderRequestPageHandler.

        // Exercise.
        PurchaseOrder."&Print".Invoke();  // Print.

        // Verify: Verify Purchase Order report with Print Company and Log Interaction.
        VerifyPurchaseDocument(
          Item, PurchaseHeader."No.", CompanyName, PurchaseHeader."Buy-from Vendor Name",
          NoPurchHeaderLbl, DescPurchLineLbl, UOMPurchLinePOLbl, ItemNoPurchaseLinePOLbl,
          CompanyNameLbl, VendorNamePOLbl);

        VerifyAmtAndQtyOnPurchDocument(
          Item."No.", ItemNoPurchaseLinePOLbl, QtyPurchLineLbl, PurchaseOrder.PurchLines.Quantity.Value,
          LineAmtTaxAmtInvDiscountLbl, PurchaseOrder.PurchLines."Line Amount".AsDecimal());

        VerifyLogInteraction(PurchaseHeader."No.", ActualLogInteraction);
    end;

    [Test]
    [HandlerFunctions('PurchOrderSimpleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderReportWithFields()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorInvoiceNo: Code[35];
        VendorOrderNo: Code[35];
    begin
        // [FEATURE] [Purchase Order]
        // [SCENARIO 258015] REP10122 "Purchase Order" now shows "Vendor Invoice No." and "Vendor Order No." fields.
        Initialize();

        // [GIVEN] Purchase Order "PO" with filled "Vendor Invoice No." = "AAA" and "Vendor Order No." = "BBB".
        // [GIVEN] "PO" card page is opened.
        VendorInvoiceNo := LibraryUtility.GenerateGUID();
        VendorOrderNo := LibraryUtility.GenerateGUID();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.Validate("Vendor Invoice No.", VendorInvoiceNo);
        PurchaseHeader.Validate("Vendor Order No.", VendorOrderNo);
        PurchaseHeader.Modify(true);
        Commit();

        // [WHEN] REP10122 "Purchase Order" is invoked to print "PO".
        REPORT.Run(REPORT::"Purchase Order", true, false, PurchaseHeader);

        // [THEN] Printed report dataset contains "AAA" and "BBB" values for "Vendor Invoice No" and "Vendor Order No." fields respectively.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendorInvoiceNo', VendorInvoiceNo);
        LibraryReportDataset.AssertElementWithValueExists('VendorOrderNo', VendorOrderNo);
    end;

    [Test]
    [HandlerFunctions('PurchQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchQuoteReportWithPrintCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Purchase Quote Report with Print Company and without Log Interaction option.
        CompanyInformation.Get();
        PurchaseQuoteReport(true, false, true, CompanyInformation.Name);
    end;

    [Test]
    [HandlerFunctions('PurchQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchQuoteReportWithLogInteraction()
    begin
        // Verify Purchase Quote Report without Print Company and with Log Interaction option.
        PurchaseQuoteReport(false, true, false, '');
    end;

    [Test]
    [HandlerFunctions('PurchQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchQuoteReportWithPrintCompAndLogInt()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Purchase Quote Report with Print Company and Log Interaction option.
        CompanyInformation.Get();
        PurchaseQuoteReport(true, true, false, CompanyInformation.Name);
    end;

    local procedure PurchaseQuoteReport(PrintCompanyAddress: Boolean; LogInteraction: Boolean; ActualLogInteraction: Boolean; CompanyName: Text[100])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // Setup: Create Purchse Quote, open and execute Purch. Quote report.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, Item."No.", PurchaseHeader."Document Type"::Quote);
        PurchaseQuote.OpenView();
        PurchaseQuote.FILTER.SetFilter("No.", PurchaseHeader."No.");
        Commit();  // Commit required for Run Purchase Quote Report.
        EnqueueValuesforPurchaseDocument(PurchaseHeader."Buy-from Vendor No.", PrintCompanyAddress, LogInteraction);  // Enqueue values for PurchQuoteRequestPageHandler.

        // Exercise.
        PurchaseQuote.Print.Invoke();  // Print.

        // Verify: Verify Purchase Quote report with Print Company and Log Interaction.
        VerifyPurchaseDocument(
          Item, PurchaseHeader."No.", CompanyName, PurchaseHeader."Buy-from Vendor Name", NoPurchHeaderLbl,
          DescPurchLineLbl, UOMPurchLineLbl, ItemNoToPrintPurchLineLbl, CompanyNameLbl, VendorNameLbl);

        VerifyAmtAndQtyOnPurchDocument(
          Item."No.", ItemNoToPrintPurchLineLbl, QtyPurchLineLbl, PurchaseQuote.PurchLines.Quantity.AsDecimal(),
          AmountPurchLineLbl, PurchaseQuote.PurchLines."Line Amount".AsDecimal());

        VerifyLogInteraction(PurchaseHeader."No.", ActualLogInteraction);
    end;

    [Test]
    [HandlerFunctions('PurchReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchReceiptReportWithPrintCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Purchase Receipt Report with Print Company and without Log Interaction option.
        CompanyInformation.Get();
        PurchaseReceiptReport(true, false, true, CompanyInformation.Name);
    end;

    [Test]
    [HandlerFunctions('PurchReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchReceiptReportWithLogInteraction()
    begin
        // Verify Purchase Receipt Report without Print Company and with Log Interaction option.
        PurchaseReceiptReport(false, true, false, '');
    end;

    [Test]
    [HandlerFunctions('PurchReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchReceiptReportWithPrintCompAndLogInt()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Purchase Receipt Report with Print Company and Log Interaction option.
        CompanyInformation.Get();
        PurchaseReceiptReport(true, true, false, CompanyInformation.Name);
    end;

    local procedure PurchaseReceiptReport(PrintCompanyAddress: Boolean; LogInteraction: Boolean; ActualLogInteraction: Boolean; CompanyName: Text[100])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
        DocumentNo: Code[20];
    begin
        // Setup: Create and receipt Purchse Order, open and execute Purch. Receipt report from posted receipt.
        Initialize();
        LibraryInventory.CreateItem(Item);
        DocumentNo := CreateAndPostPurchaseDocument(Item."No.", PurchaseHeader."Document Type"::Order, false);
        PostedPurchaseReceipt.OpenView();
        PostedPurchaseReceipt.FILTER.SetFilter("No.", DocumentNo);
        EnqueueValuesforPurchaseDocument(PostedPurchaseReceipt."Buy-from Vendor No.".Value, PrintCompanyAddress, LogInteraction);  // Enqueue values for PurchReceiptRequestPageHandler.

        // Exercise.
        PostedPurchaseReceipt."&Print".Invoke();  // Print.

        // Verify: Verify Purchase Receipt report with Print Company and Log Interaction.
        VerifyPurchaseDocument(
          Item, DocumentNo, CompanyName, PostedPurchaseReceipt."Buy-from Vendor No.".Value, NoPurchRcptHeaderLbl,
          DescPurchRcptLineLbl, UOMPurchRcptLineLbl, ItemNoPurchRcptLineLbl, CompanyAddrLbl, BuyFromVendLbl);

        VerifyValuesOnReport(
          Item."No.", ItemNoPurchRcptLineLbl, OrderedQtyPurchRcptLineLbl,
          PostedPurchaseReceipt.PurchReceiptLines.Quantity.AsDecimal());

        VerifyLogInteraction(DocumentNo, ActualLogInteraction);
    end;

    [Test]
    [HandlerFunctions('PurchRetOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchRetOrderReportWithPrintCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Purchase Purch. Return Order Confirm Report with Print Company and without Log Interaction option.
        CompanyInformation.Get();
        PurchaseRetOrderReport(true, false, true, CompanyInformation.Name);
    end;

    [Test]
    [HandlerFunctions('PurchRetOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchRetOrderReportWithLogInteraction()
    begin
        // Verify Purchase Purch. Return Order Confirm  Report without Print Company and with Log Interaction option.
        PurchaseRetOrderReport(false, true, false, '');
    end;

    [Test]
    [HandlerFunctions('PurchRetOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchRetOrderReportWithPrintCompAndLogInt()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Purchase Purch. Return Order Confirm  Report with Print Company and Log Interaction option.
        CompanyInformation.Get();
        PurchaseRetOrderReport(true, true, false, CompanyInformation.Name);
    end;

    local procedure PurchaseRetOrderReport(PrintCompanyAddress: Boolean; LogInteraction: Boolean; ActualLogInteraction: Boolean; CompanyName: Text[100])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // Setup: Create Purchse Return Order, open and execute Purch. Return Order Confirm report.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, Item."No.", PurchaseHeader."Document Type"::"Return Order");
        PurchaseReturnOrder.OpenView();
        PurchaseReturnOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        Commit();  // Commit required for Run Purchase Order Report.
        EnqueueValuesforPurchaseDocument(PurchaseHeader."Buy-from Vendor No.", PrintCompanyAddress, LogInteraction);  // Enqueue values for PurchRetOrderRequestPageHandler.
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");    // Enqueue value for PurchRetOrderRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Return Order Confirm");

        // Verify: Verify Purchase Return Order Confirm report with Print Company and Log Interaction.
        VerifyPurchaseDocument(
          Item, PurchaseHeader."No.", CompanyName, PurchaseHeader."Buy-from Vendor Name",
          NoPurchHeaderLbl, DescPrintPurchLineLbl, UMOPrintPurchLineLbl, ItemNoPrintPurchLineLbl,
          CompanyNameLbl, VendorNameLbl);

        VerifyValuesOnReport(
          Item."No.", ItemNoPrintPurchLineLbl, QtyPrintPurchLineLbl, PurchaseReturnOrder.PurchLines.Quantity.AsDecimal());
        VerifyLogInteraction(PurchaseHeader."No.", ActualLogInteraction);
    end;

    [Test]
    [HandlerFunctions('PurchDocTestRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcVATOnPurchInvoiceTestReport()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify  Amount Excluding VAT and Amount Including VAT on Purchase Invoice Test Report.
        CalcVATOnPurchDocTestReport(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('PurchDocTestRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcVATOnPurchCrMemoTestReport()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Amount Excluding VAT and Amount Including VAT on Purchase Cr. Memo Test Report.
        CalcVATOnPurchDocTestReport(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    local procedure CalcVATOnPurchDocTestReport(DocumentType: Enum "Purchase Document Type")
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Document with multiple Item.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, Item."No.", DocumentType);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item2."No.", LibraryRandom.RandDec(10, 2));  // Using random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Using random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");    // Enqueue values for PurchDocTestRepRequestPageHandler.
        Commit();

        // Exercise.
        REPORT.Run(REPORT::"Purchase Document - Test");

        // Verify: Verify Amount Excluding VAT and Amount Including VAT on Purchase Doc. Test Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(LineAmountLbl, GetPurchLineAmount(PurchaseHeader, 0));
        LibraryReportDataset.AssertElementWithValueExists(AmountIncVATLbl, GetPurchLineAmount(PurchaseHeader, PurchaseLine."VAT %"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostApplWithPartialAndFullRemAmountsOfInvCustLedgerEntry()
    var
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJounalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        GenJournalDocumentNo: Code[20];
        Amount: Decimal;
        AmountToApply: Decimal;
    begin
        // Verify Remaining Amount on Invoice Customer Ledger Entry when Inv Cust. Ledger Entry Remaining Amount paid
        // with Partially And fully for Post application.

        // Setup: Post Sales Document and Post Application from Inv. Customer Ledger Entry
        // by Selecting Applies to Id With Partial And Full Remaining Amount on Invoice Customer Ledger Entry.
        Initialize();
        CreateAndModifySalesDocument(SalesLine, SalesLine."Document Type"::Order, CreateAndUpdateTaxGroupOnItem(), '',
          WorkDate(), '', '', LibrarySales.CreateCustomerNo());
        DocumentNo := PostSalesDocument(SalesLine);
        Amount := LibraryRandom.RandDecInRange(500, 1000, 2);
        CreateAndPostGenJournalLine(DocumentNo, -Amount, SalesLine."Amount Including VAT" - LibraryRandom.RandInt(5),
          GenJounalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.", true);
        GenJournalDocumentNo := CreateAndPostGenJournalLine(DocumentNo, -Amount, 0,
            GenJounalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.", false);
        ApplyAndPostCustomerEntry(DocumentNo, GenJournalDocumentNo, CustLedgerEntry."Document Type"::Invoice,
          CustLedgerEntry."Document Type"::Payment);

        // Exercise: Get Amount To Apply from Temp Applied Cust. Ledge Entry.
        AmountToApply := GetAmountToApplyFromTempAppliedCustLedgerEntry(DocumentNo);

        // Verify: Verify Remaining Amount on Customer Ledger Entry.
        VerifyRemainingAmountOnInvCustLedgerEntry(DocumentNo, SalesLine."Amount Including VAT" + AmountToApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostApplWithPartialRemAmountsOfInvCustLedgerEntry()
    var
        SalesLine: Record "Sales Line";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceCustLedgerEntry: Record "Cust. Ledger Entry";
        GenJounalLine: Record "Gen. Journal Line";
        AmountToApply: Decimal;
        DocumentNo: Code[20];
        GenJournalDocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify Remaining Amount on Invoice Customer Ledger Entry when Inv Cust. Ledger Entry Remaining Amount paid
        // with Partially for Post application.

        // Setup: Post Sales Document and Post Application from Inv. Customer Ledger Entry
        // by Selecting Applies to Id With Partially Remaining Amount on Invoice Customer Ledger Entry.
        Initialize();
        CreateAndModifySalesDocument(SalesLine, SalesLine."Document Type"::Order,
          CreateAndUpdateTaxGroupOnItem(), '', WorkDate(), '', '', LibrarySales.CreateCustomerNo());
        DocumentNo := PostSalesDocument(SalesLine);
        Amount := LibraryRandom.RandDecInRange(500, 1000, 2);
        CreateAndPostGenJournalLine(DocumentNo, -Amount, SalesLine."Amount Including VAT" - LibraryRandom.RandInt(5),
          GenJounalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.", true);
        GenJournalDocumentNo := CreateAndPostGenJournalLine(DocumentNo, -Amount, 0,
            GenJounalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.", false);
        GetRemainingAmountOnCustomer(InvoiceCustLedgerEntry, InvoiceCustLedgerEntry."Document Type"::Invoice, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(InvoiceCustLedgerEntry, InvoiceCustLedgerEntry."Remaining Amount");
        LibraryERM.FindCustomerLedgerEntry(PaymentCustLedgerEntry, PaymentCustLedgerEntry."Document Type"::Payment, GenJournalDocumentNo);
        SetAppliesAfterValidatingAmountToApply(PaymentCustLedgerEntry,
          -(InvoiceCustLedgerEntry."Remaining Amount" + LibraryRandom.RandInt(5)));
        LibraryERM.PostCustLedgerApplication(InvoiceCustLedgerEntry);

        // Exercise: Get Amount To Apply from Temp Applied Cust. Ledge Entry.
        AmountToApply := GetAmountToApplyFromTempAppliedCustLedgerEntry(DocumentNo);

        // Verify: Verify Remaining Amount on Customer Ledger Entry.
        VerifyRemainingAmountOnInvCustLedgerEntry(DocumentNo, SalesLine."Amount Including VAT" + AmountToApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostApplWithFullRemAmountOfInvCustLedgerEntry()
    var
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJounalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        GenJournalDocumentNo: Code[20];
        AmountToApply: Decimal;
    begin
        // Verify Remaining Amount on Invoice Customer Ledger Entry when Inv Cust. Ledger Entry Remaining Amount paid
        // with fully for Post application.

        // Setup: Post Sales Document and Post Application from Inv. Customer Ledger Entry
        // by Selecting Applies to Id With Full Remaining Amount on Invoice Customer Ledger Entry.
        Initialize();
        CreateAndModifySalesDocument(SalesLine, SalesLine."Document Type"::Order,
          CreateAndUpdateTaxGroupOnItem(), '', WorkDate(), '', '', LibrarySales.CreateCustomerNo());
        DocumentNo := PostSalesDocument(SalesLine);
        CreateAndPostGenJournalLine(DocumentNo, -LibraryRandom.RandDecInRange(500, 1000, 2),
          SalesLine."Amount Including VAT" - LibraryRandom.RandInt(5),
          GenJounalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.", true);
        GenJournalDocumentNo := CreateAndPostGenJournalLine(DocumentNo, -LibraryRandom.RandDecInRange(1001, 1500, 2), 0,
            GenJounalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.", false);
        ApplyAndPostCustomerEntry(DocumentNo, GenJournalDocumentNo, CustLedgerEntry."Document Type"::Invoice,
          CustLedgerEntry."Document Type"::Payment);

        // Exercise: Get Amount To Apply from Temp Applied Cust. Ledge Entry.
        AmountToApply := GetAmountToApplyFromTempAppliedCustLedgerEntry(DocumentNo);

        // Verify: Verify Remaining Amount on Customer Ledger Entry.
        VerifyRemainingAmountOnInvCustLedgerEntry(DocumentNo, SalesLine."Amount Including VAT" + AmountToApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostApplForCustomerWithPaymentsRemainingAmount()
    var
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJounalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify Remaining Amount on Invoice Customer Ledger Entry when Payment Cust. Ledger Entry Remaining Amount paid with Post application.

        // Setup: Post Sales Document and Post Application from Inv. Customer Ledger Entry
        // by Selecting Applies to Id With Remaining Amount on Payment Customer Ledger Entries.
        Initialize();
        CreateAndModifySalesDocument(SalesLine, SalesLine."Document Type"::Order,
          CreateAndUpdateTaxGroupOnItem(), '', WorkDate(), '', '', LibrarySales.CreateCustomerNo());
        DocumentNo := PostSalesDocument(SalesLine);
        Amount := LibraryRandom.RandDec(50, 2);
        CreateAndPostGenJournalLine(DocumentNo, -Amount, Amount,
          GenJounalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.", true);
        CreateAndPostGenJournalLine(DocumentNo, -Amount, Amount,
          GenJounalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.", true);

        // Exercise.
        GetAmountToApplyFromTempAppliedCustLedgerEntry(DocumentNo);

        // Verify: Verify Remaining Amount.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        VerifyRemainingAmountOnInvCustLedgerEntry(DocumentNo, SalesLine."Amount Including VAT" +
          GetAmountAppliedFromDetailCustLedgerEntry(SalesLine."Sell-to Customer No.", CustLedgerEntry."Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostApplicationForCustomerWithRemainingAmount()
    var
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempAppliedCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        EntryApplicationManagement: Codeunit "Entry Application Management";
        DocumentNo: Code[20];
        PostedGenJournalDocumentNo: Code[20];
    begin
        // Verify Amount To Apply On Customer Ledger Entry when remaining Amount paid with partial application.

        // Setup: Post Sales Document and Post Partial Payment using Gen. Journal with Apply Entry
        // Also Post Application from Customer Ledger Entries by Selecting Applies to Id.
        Initialize();
        CreateAndModifySalesDocument(SalesLine, SalesLine."Document Type"::Order,
          CreateAndUpdateTaxGroupOnItem(), '', WorkDate(), '', '', LibrarySales.CreateCustomerNo());
        DocumentNo := PostSalesDocument(SalesLine);
        PostedGenJournalDocumentNo :=
          CreateAndPostGenJournalLine(DocumentNo, -SalesLine."Amount Including VAT",
            SalesLine."Amount Including VAT" - LibraryRandom.RandInt(5),
            GenJournalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.", true);
        ApplyAndPostCustomerEntry(PostedGenJournalDocumentNo, DocumentNo, CustLedgerEntry."Document Type"::Payment,
          CustLedgerEntry."Document Type"::Invoice);

        // Exercise.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PostedGenJournalDocumentNo);
        EntryApplicationManagement.GetAppliedCustEntries(TempAppliedCustLedgerEntry, CustLedgerEntry, true);

        // Verify: Verify Remaining Amount
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        TempAppliedCustLedgerEntry.CalcFields("Remaining Amount");
        TempAppliedCustLedgerEntry.TestField("Remaining Amount", SalesLine."Amount Including VAT" +
          GetAmountAppliedFromDetailCustLedgerEntry(SalesLine."Sell-to Customer No.", CustLedgerEntry."Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostApplWithPartialAndFullRemAmountsOfInvVendLedgerEntry()
    var
        Item: Record Item;
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
        GenJournalDocumentNo: Code[20];
        Amount: Decimal;
        AmountToApply: Decimal;
    begin
        // Verify Remaining Amount on Invoice Vendor Ledger Entry when Inv Vendor Ledger Entry Remaining Amount paid
        // with Partially And fully for Post application.

        // Setup: Post Sales Document and Post Application from Inv. Vendor Ledger Entry
        // by Selecting Applies to Id With Partial And Full Remaining Amount on Invoice Vendor Ledger Entry.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, Item."No.", PurchaseHeader."Document Type"::Order);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Amount := LibraryRandom.RandDecInRange(500, 1000, 2);
        CreateAndPostGenJournalLine(DocumentNo, Amount, PurchaseLine."Amount Including VAT" - LibraryRandom.RandInt(5),
          GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.", true);
        GenJournalDocumentNo := CreateAndPostGenJournalLine(DocumentNo, Amount, 0,
            GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.", false);
        ApplyAndPostVendorEntry(DocumentNo, GenJournalDocumentNo, VendorLedgerEntry."Document Type"::Invoice,
          VendorLedgerEntry."Document Type"::Payment);

        // Exercise: Get Amount To Apply from Temp Applied Vendor Ledger Entry.
        AmountToApply := GetAmountToApplyFromTempAppliedVendorLedgerEntry(DocumentNo);

        // Verify: Verify Remaining Amount on Vendor Ledger Entry.
        VerifyRemainingAmountOnInvVendorLedgerEntry(DocumentNo, PurchaseLine."Amount Including VAT" - AmountToApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostApplWithFullRemAmountOfInvVendLedgerEntry()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AmountToApply: Decimal;
        DocumentNo: Code[20];
        GenJournalDocumentNo: Code[20];
    begin
        // Verify Remaining Amount on Invoice Vendor Ledger Entry when Inv Vendor Ledger Entry Remaining Amount paid
        // with fully for Post application.

        // Setup: Post Purchase Document and Post Application from Inv. Vendor Ledger Entry
        // by Selecting Applies to Id With Full Remaining Amount on Invoice Vendor Ledger Entry.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, Item."No.", PurchaseHeader."Document Type"::Order);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateAndPostGenJournalLine(DocumentNo, LibraryRandom.RandDecInRange(500, 1000, 2),
          PurchaseLine."Amount Including VAT" - LibraryRandom.RandInt(5),
          GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.", true);
        GenJournalDocumentNo := CreateAndPostGenJournalLine(DocumentNo, LibraryRandom.RandDecInRange(1001, 1500, 2), 0,
            GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.", false);
        ApplyAndPostVendorEntry(DocumentNo, GenJournalDocumentNo, VendorLedgerEntry."Document Type"::Invoice,
          VendorLedgerEntry."Document Type"::Payment);

        // Exercise: Get Amount To Apply from Temp Applied Vendor Ledger Entry.
        AmountToApply := GetAmountToApplyFromTempAppliedVendorLedgerEntry(DocumentNo);

        // Verify: Verify Remaining Amount On Temporary Vendor Ledger Entry.
        VerifyRemainingAmountOnInvVendorLedgerEntry(DocumentNo, PurchaseLine."Amount Including VAT" - AmountToApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostApplForVendorWithPaymentsRemainingAmount()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify Remaining Amount on Invoice Vendor Ledger Entry when Payment Vendor Ledger Entry Remaining Amount paid with Post application.

        // Setup: Post Purchase Document and Post Application from Inv. Vendor Ledger Entry
        // by Selecting Applies to Id With Remaining Amount on Payment Vendor Ledger Entries.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, Item."No.", PurchaseHeader."Document Type"::Order);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Amount := LibraryRandom.RandDec(50, 2);
        CreateAndPostGenJournalLine(DocumentNo, Amount, -Amount, GenJournalLine."Account Type"::Vendor,
          PurchaseLine."Buy-from Vendor No.", true);
        CreateAndPostGenJournalLine(DocumentNo, Amount, -Amount, GenJournalLine."Account Type"::Vendor,
          PurchaseLine."Buy-from Vendor No.", true);

        // Exercise.
        GetAmountToApplyFromTempAppliedVendorLedgerEntry(DocumentNo);

        // Verify: Verify Remaining Amount On Invoice Vendor Ledger Entry.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VerifyRemainingAmountOnInvVendorLedgerEntry(DocumentNo, GetAmountAppliedFromDetailVendorLedgerEntry
          (PurchaseLine."Buy-from Vendor No.", VendorLedgerEntry."Entry No.") - PurchaseLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostApplicationForVendorWithRemainingAmount()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        TempAppliedVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EntryApplicationManagement: Codeunit "Entry Application Management";
        DocumentNo: Code[20];
        GenJournalDocumentNo: Code[20];
    begin
        // Verify Amount To Apply On Vendor Ledger Entry when remaining Amount paid with partial application.

        // Setup: Post Purchase Document and Post Partial Payment using Gen. Journal with Apply Entry
        // Also Post Application from Vendor Ledger Entries by Selecting Applies to Id.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, Item."No.", PurchaseHeader."Document Type"::Order);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        GenJournalDocumentNo := CreateAndPostGenJournalLine(DocumentNo, PurchaseLine."Amount Including VAT",
            -(PurchaseLine."Amount Including VAT" - LibraryRandom.RandInt(5)),
            GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.", true);
        ApplyAndPostVendorEntry(GenJournalDocumentNo, DocumentNo, VendorLedgerEntry."Document Type"::Payment,
          VendorLedgerEntry."Document Type"::Invoice);

        // Exercise.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalDocumentNo);
        EntryApplicationManagement.GetAppliedVendEntries(TempAppliedVendorLedgerEntry, VendorLedgerEntry, true);

        // Verify: Verify Remaining Amount on Temp Applied Vendor Ledger Entry.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        TempAppliedVendorLedgerEntry.CalcFields("Remaining Amount");
        TempAppliedVendorLedgerEntry.TestField("Remaining Amount", GetAmountAppliedFromDetailVendorLedgerEntry
          (PurchaseLine."Buy-from Vendor No.", VendorLedgerEntry."Entry No.") - PurchaseLine."Amount Including VAT");
    end;

#if not CLEAN23
    [Test]
    [HandlerFunctions('ListPriceSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckUnitPriceOnListPriceSheetReport()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
    begin
        // Verify unit price on List Price Sheet report.

        // Setup: Create Item and Sales Price.
        Initialize();
        CreateAndModifyItem(Item);
        CreateAndModifySalesPrice(SalesPrice, Item, SalesPrice."Sales Type"::"All Customers", '', '');
        EnqueueValuesForListPriceSheetReport(SalesPrice."Sales Type"::"All Customers", '', Item."No.");
        Commit();

        // Exercise: Run report List Price Sheet.
        REPORT.Run(REPORT::"List Price Sheet");

        // Verify: Verifying the unit price on List Price Sheet report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Sales_Price__Unit_Price_', SalesPrice."Unit Price")
    end;
#endif

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,Vendor1099MiscRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Vendor1099MiscReportWithPaymentDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Misc 07 Amount on Vendor 1099 Misc. Test Report with Payment Discount.

        // Setup: Create and Post Purchase order with Payment Discount and Run Suggest Vendor Payment with Pmt. Discount Date .
        Initialize();
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine);
        PostGenJournalLineAfterSuggestVendorPayment(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Pmt. Discount Date");

        // Exercise: Run Vendor 1099 Misc Report.
        REPORT.Run(REPORT::"Vendor 1099 Misc");

        // Verify: Verify Misc 07 Amount on Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(
          GetAmtMISC07MISC15BTxt, PurchaseLine."Line Amount" - (PurchaseLine."Line Amount" * PurchaseHeader."Payment Discount %" / 100));
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,Vendor1099MiscRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Vendor1099MiscReportWithoutPaymentDisc()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Misc 07 Amount on Vendor 1099 Misc. Test Report without Payment Discount.

        // Setup: Create and Post Purchase order with Payment Discount and Run Suggest Vendor Payment with greater than Due date .
        Initialize();
        PostPurchOrderWithPmtGreaterThanDueDate(PurchaseLine);

        // Exercise: Run Vendor 1099 Misc Report.
        REPORT.Run(REPORT::"Vendor 1099 Misc");

        // Verify: Verify Misc 07 Amount on Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(GetAmtMISC07MISC15BTxt, PurchaseLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAppliedEntriesTwoCustomersManualApplication()
    var
        TempCustLedgerEntryApplied: Record "Cust. Ledger Entry" temporary;
        CustomerNo: Code[20];
        InvoiceXNo: Code[20];
        InvoiceYNo: Code[20];
        PaymentXNo: Code[20];
        PaymentYNo: Code[20];
    begin
        // [FEATURE] [ERM] [Sales] [Non-G/L Application]
        // [SCENARIO 118319.1] Get applied customer entries for applications that were not posted to G/L.
        Initialize();
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Two pairs of Invoice and Payment for one Customer: "Invoice X" - "Payment X", "Invoice Y" - "Payment Y".
        // [GIVEN] Documents applied so both application transactions are not posted to G/L.
        PostManualApplicationSalesInvoiceToPayment(CustomerNo, InvoiceXNo, PaymentXNo);
        PostManualApplicationSalesInvoiceToPayment(CustomerNo, InvoiceYNo, PaymentYNo);

        // [WHEN] Get a list of entries applied to "Invoice X" (by Entry Application Management)
        GetAppliedCustomerEntries(TempCustLedgerEntryApplied, InvoiceXNo);

        // [THEN] The list of applied entries to Invvoice X includes one entry of "Payment X". "Payment Y" is excluded.
        VerifyAppliedCustomerEntries(TempCustLedgerEntryApplied, PaymentXNo, CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAppliedEntriesTwoVendorsManualApplication()
    var
        TempVendorLedgerEntryApplied: Record "Vendor Ledger Entry" temporary;
        VendorNo: Code[20];
        InvoiceXNo: Code[20];
        InvoiceYNo: Code[20];
        PaymentXNo: Code[20];
        PaymentYNo: Code[20];
    begin
        // [FEATURE] [ERM] [Purchase] [Non-G/L Application]
        // [SCENARIO 118319.2] Get applied Get applied customer entries for applications that were not posted to G/L.
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Two pairs of Invoice and Payment for one Customer: "Invoice X" - "Payment X", "Invoice Y" - "Payment Y".
        // [GIVEN] Documents applied so both application transactions are not posted to G/L.
        PostManualApplicationPurchaseInvoiceToPayment(VendorNo, InvoiceXNo, PaymentXNo);
        PostManualApplicationPurchaseInvoiceToPayment(VendorNo, InvoiceYNo, PaymentYNo);

        // [WHEN] Get a list of entries applied to "Invoice X" (by Entry Application Management)
        GetAppliedVendorEntries(TempVendorLedgerEntryApplied, InvoiceXNo);

        // [THEN] The list of applied entries to Invvoice X includes one entry of "Payment X". "Payment Y" is excluded.
        VerifyAppliedVendorEntries(TempVendorLedgerEntryApplied, PaymentXNo, VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAppliedEntriesForTheFirstOfTwoCustomersAutoApplication()
    var
        TempCustLedgerEntryApplied: Record "Cust. Ledger Entry" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceDocNo: array[2] of Code[20];
        PaymentDocNo: Code[20];
        CustomerNo: array[2] of Code[20];
    begin
        // [FEATURE] [ERM] [Application] [Sales]
        // [SCENARIO 376688] Get applied customer entries for the first of two customers after auto applilcation with the same document no.
        Initialize();

        // [GIVEN] Two posted invoices: "I1" for Customer "C1", "I2" for Customer "C2".
        CreatePostTwoInvForTwoAccounts(CustomerNo, InvoiceDocNo, GenJournalLine."Account Type"::Customer);
        // [GIVEN] Posted payment journal  with following lines:
        // [GIVEN] Line1: "Document No." = "P", "Account No." = "C1", "Applies-to Doc. No." = "I1", "Bal. Account No." = ""
        // [GIVEN] Line2: "Document No." = "P", "Account No." = "C2", "Applies-to Doc. No." = "I2", "Bal. Account No." = ""
        // [GIVEN] Line3: "Document No." = "P", "Account No." = <Bank Account>, "Applies-to Doc. No." = "", "Bal. Account No." = ""
        PaymentDocNo := CreatePostTwoPmtForTwoAccounts(CustomerNo, InvoiceDocNo, GenJournalLine."Account Type"::Customer);

        // [WHEN] Get a list of entries applied to invoice "I1" (run COD 10202 "Entry Application Management".GetAppliedCustEntries()).
        GetAppliedCustomerEntries(TempCustLedgerEntryApplied, InvoiceDocNo[1]);

        // [THEN] The list of applied entries to invoice "I1" includes one entry with "Document No." = "P", "Customer No." = "C1"
        VerifyAppliedCustomerEntries(TempCustLedgerEntryApplied, PaymentDocNo, CustomerNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAppliedEntriesForTheSecondOfTwoCustomersAutoApplication()
    var
        TempCustLedgerEntryApplied: Record "Cust. Ledger Entry" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceDocNo: array[2] of Code[20];
        PaymentDocNo: Code[20];
        CustomerNo: array[2] of Code[20];
    begin
        // [FEATURE] [ERM] [Application] [Sales]
        // [SCENARIO 376688] Get applied customer entries for the second of two customers after auto applilcation with the same document no.
        Initialize();

        // [GIVEN] Two posted invoices: "I1" for Customer "C1", "I2" for Customer "C2".
        CreatePostTwoInvForTwoAccounts(CustomerNo, InvoiceDocNo, GenJournalLine."Account Type"::Customer);
        // [GIVEN] Posted payment journal  with following lines:
        // [GIVEN] Line1: "Document No." = "P", "Account No." = "C1", "Applies-to Doc. No." = "I1", "Bal. Account No." = ""
        // [GIVEN] Line2: "Document No." = "P", "Account No." = "C2", "Applies-to Doc. No." = "I2", "Bal. Account No." = ""
        // [GIVEN] Line3: "Document No." = "P", "Account No." = <Bank Account>, "Applies-to Doc. No." = "", "Bal. Account No." = ""
        PaymentDocNo := CreatePostTwoPmtForTwoAccounts(CustomerNo, InvoiceDocNo, GenJournalLine."Account Type"::Customer);

        // [WHEN] Get a list of entries applied to invoice "I2" (run COD 10202 "Entry Application Management".GetAppliedCustEntries()).
        GetAppliedCustomerEntries(TempCustLedgerEntryApplied, InvoiceDocNo[2]);

        // [THEN] The list of applied entries to invoice "I2" includes one entry with "Document No." = "P", "Customer No." = "C2"
        VerifyAppliedCustomerEntries(TempCustLedgerEntryApplied, PaymentDocNo, CustomerNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAppliedEntriesForTheFirstOfTwoVendorsAutoApplication()
    var
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceDocNo: array[2] of Code[20];
        PaymentDocNo: Code[20];
        VendorNo: array[2] of Code[20];
    begin
        // [FEATURE] [ERM] [Application] [Purchase]
        // [SCENARIO 376688] Get applied vendor entries for the first of two vendors after auto applilcation with the same document no.
        Initialize();

        // [GIVEN] Two posted invoices: "I1" for Vendor "V1", "I2" for Vendor "V2".
        CreatePostTwoInvForTwoAccounts(VendorNo, InvoiceDocNo, GenJournalLine."Account Type"::Vendor);
        // [GIVEN] Posted payment journal  with following lines:
        // [GIVEN] Line1: "Document No." = "P", "Account No." = "C1", "Applies-to Doc. No." = "I1", "Bal. Account No." = ""
        // [GIVEN] Line2: "Document No." = "P", "Account No." = "C2", "Applies-to Doc. No." = "I2", "Bal. Account No." = ""
        // [GIVEN] Line3: "Document No." = "P", "Account No." = <Bank Account>, "Applies-to Doc. No." = "", "Bal. Account No." = ""
        PaymentDocNo := CreatePostTwoPmtForTwoAccounts(VendorNo, InvoiceDocNo, GenJournalLine."Account Type"::Vendor);

        // [WHEN] Get a list of entries applied to invoice "I1" (run COD 10202 "Entry Application Management".GetAppliedVendEntries()).
        GetAppliedVendorEntries(TempVendorLedgerEntry, InvoiceDocNo[1]);

        // [THEN] The list of applied entries to invoice "I1" includes one entry with "Document No." = "P", "Vendor No." = "V1"
        VerifyAppliedVendorEntries(TempVendorLedgerEntry, PaymentDocNo, VendorNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAppliedEntriesForTheSecondOfTwoVendorsAutoApplication()
    var
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceDocNo: array[2] of Code[20];
        PaymentDocNo: Code[20];
        VendorNo: array[2] of Code[20];
    begin
        // [FEATURE] [ERM] [Application] [Purchase]
        // [SCENARIO 376688] Get applied vendor entries for the second of two vendors after auto applilcation with the same document no.
        Initialize();

        // [GIVEN] Two posted invoices: "I1" for Vendor "V1", "I2" for Vendor "V2".
        CreatePostTwoInvForTwoAccounts(VendorNo, InvoiceDocNo, GenJournalLine."Account Type"::Vendor);
        // [GIVEN] Posted payment journal  with following lines:
        // [GIVEN] Line1: "Document No." = "P", "Account No." = "C1", "Applies-to Doc. No." = "I1", "Bal. Account No." = ""
        // [GIVEN] Line2: "Document No." = "P", "Account No." = "C2", "Applies-to Doc. No." = "I2", "Bal. Account No." = ""
        // [GIVEN] Line3: "Document No." = "P", "Account No." = <Bank Account>, "Applies-to Doc. No." = "", "Bal. Account No." = ""
        PaymentDocNo := CreatePostTwoPmtForTwoAccounts(VendorNo, InvoiceDocNo, GenJournalLine."Account Type"::Vendor);

        // [WHEN] Get a list of entries applied to invoice "I2" (run COD 10202 "Entry Application Management".GetAppliedVendEntries()).
        GetAppliedVendorEntries(TempVendorLedgerEntry, InvoiceDocNo[2]);

        // [THEN] The list of applied entries to invoice "I2" includes one entry with "Document No." = "P", "Vendor No." = "V2"
        VerifyAppliedVendorEntries(TempVendorLedgerEntry, PaymentDocNo, VendorNo[2]);
    end;

    [Test]
    [HandlerFunctions('CashReceiptRPH')]
    [Scope('OnPrem')]
    procedure CashAppliedReportForOneOfTwoCustomersAutoApplication()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceDocNo: array[2] of Code[20];
        CustomerNo: array[2] of Code[20];
    begin
        // [FEATURE] [ERM] [Application] [Sales]
        // [SCENARIO 376688] Cash applied report for one of two customers after auto applilcation with the same document no.
        Initialize();

        // [GIVEN] Two posted invoices: "I1" for Customer "C1", "I2" for Customer "C2".
        CreatePostTwoInvForTwoAccounts(CustomerNo, InvoiceDocNo, GenJournalLine."Account Type"::Customer);
        // [GIVEN] Posted payment journal  with following lines:
        // [GIVEN] Line1: "Document No." = "P", "Account No." = "C1", "Applies-to Doc. No." = "I1", "Bal. Account No." = ""
        // [GIVEN] Line2: "Document No." = "P", "Account No." = "C2", "Applies-to Doc. No." = "I2", "Bal. Account No." = ""
        // [GIVEN] Line3: "Document No." = "P", "Account No." = <Bank Account>, "Applies-to Doc. No." = "", "Bal. Account No." = ""
        CreatePostTwoPmtForTwoAccounts(CustomerNo, InvoiceDocNo, GenJournalLine."Account Type"::Customer);

        // [WHEN] Run "Cash Applied" report with filter "Customer No." = "C1"
        CustLedgerEntry.SetRange("Customer No.", CustomerNo[1]);
        REPORT.Run(REPORT::"Cash Applied", true, false, CustLedgerEntry);

        // [THEN] Report prints only one Payment to Invoice application for customer "C1"
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), IncorrectPaymentCountErr);
    end;

    [Test]
    [HandlerFunctions('PickingListbyOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PickingListByOrderReportComment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Report Layout]
        // [SCENARIO 277324] Description field from Sales Line of a void type must be displayed in Picking List by Order report

        Initialize();

        // [GIVEN] Create Sales Order with single line of Item type
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        // [GIVEN] Create another Sales Line with not empty Description and Type=" "
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::" ", '', 0);
        SalesLine.Validate(Description, LibraryRandom.RandText(MaxStrLen(SalesLine.Description)));
        SalesLine.Modify(true);

        // [WHEN] Run Picking List by Order report
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        Commit();
        REPORT.Run(REPORT::"Picking List by Order", true, false, SalesHeader);

        // [THEN] Description from Sales Line with Type=" " is displayed in 'Sales_Line_Comment' report field
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Sales_Line_Comment', SalesLine.Description);
    end;

    [Test]
    [HandlerFunctions('GLRegisterReportHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLRegisterWhenPostAndPrint()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DimensionValue: Record "Dimension Value";
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [G/L Register] [Post and Print]
        // [SCENARIO 312175] Report G/L Register shows Dimensions when codeunit "Gen. Jnl.-Post+Print" is run
        Initialize();

        // [GIVEN] Gen. Journal Line with Dimension
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccountNo,
          LibraryRandom.RandInt(10));
        GenJournalLine.Validate("Dimension Set ID", LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code));
        GenJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");

        // [WHEN] Run codeunit "Gen. Jnl.-Post+Print"
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post+Print", GenJournalLine);

        // [THEN] Report "G/L Register" dataset has Dimension
        LibraryReportDataset.LoadDataSetFileWithNoSchema();
        LibraryReportDataset.AssertElementTagWithValueExists('Column', DimensionValue."Dimension Code");
        LibraryReportDataset.AssertElementTagWithValueExists('Column', DimensionValue.Code);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,Vendor1099MiscRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Vendor1099MiscReportWithPaymentMadeAfterDiscountDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Payment Discount]
        // [SCENARIO 345272] Report "Vendor 1099 Misc" is showing Amount without discount applied when payment was made after Payment Discount Date.
        Initialize();

        // [GIVEN] Vendor with "IRS 1099 Code" = "MISC-07".
        VendorNo := CreateVendorWithPaymentTerms();

        // [GIVEN] Posted Purchase Invoice with Payment Discount and Payment Discount Date = "01.01.20".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandInt(10));
        PurchaseHeader.Validate("Pmt. Discount Date", LibraryRandom.RandDate(10));
        PurchaseHeader.Validate("Due Date", LibraryRandom.RandDateFromInRange(WorkDate(), 11, 20));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 15000));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Payment for posted Invoice, posted after Payment Discount Date on "10.01.20".
        PostGenJournalLineAfterSuggestVendorPayment(VendorNo, PurchaseHeader."Due Date");

        // [WHEN] Report "Vendor 1099 Misc" is run for Vendor.
        REPORT.Run(REPORT::"Vendor 1099 Misc");

        // [THEN] In resulting dataset 'GetAmtMisc07Misc15B' is equal to Purchase Invoice Amount withoud discount.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtMisc07Misc15BTxt, PurchaseLine."Line Amount");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemSalesStatisticsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemSalesStatisticsQtyReturnedWithoutItemVariants()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Item Statistics] [Return]
        // [SCENARIO 353708] "Quantity Returned" and "Profit" are shown on "Item Sales Statistics" report without breakdown by Item Variants
        Initialize();

        // [GIVEN] Posted Sales Return Order for Item "I01" with Quantity = 10 and "Unit Price" = 300
        CreateAndModifySalesDocument(
          SalesLine, SalesLine."Document Type"::"Return Order", LibraryInventory.CreateItemNo(),
          '', WorkDate(), '', '', LibrarySales.CreateCustomerNo());
        PostSalesDocument(SalesLine);

        // [WHEN] Run Report "Item Sales Statistics" with "Breakdown By Variants" disabled
        LibraryVariableStorage.Enqueue(SalesLine."No.");
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Item Sales Statistics");

        // [THEN] "Quantity Returned" = 10 for Item "I01"
        // [THEN] "Profit" = -3000 for Item "I01"
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, 'QuantityReturned', SalesLine.Quantity);
        VerifyValuesOnReport(SalesLine."No.", ItemNoCapLbl, 'Profit', -SalesLine.Quantity * SalesLine."Unit Price");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler,Vendor1099Misc2020RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Vendor1099Misc2020ReportDoesNotContainMISC07()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 374401] A "Vendor 1099 Misc 2020" report does not contain the "MISC-07" code

        // [GIVEN] Purchase invoice with MISC-07 code
        Initialize();
        PostPurchOrderWithPmtGreaterThanDueDate(PurchaseLine);

        // [WHEN] Run Vendor 1099 Misc 2020 Report
        REPORT.Run(REPORT::"Vendor 1099 Misc 2020");

        // [THEN] "Misc 07" values does not exists in the Report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist('GetAmtMISC07MISC15B', PurchaseLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('Vendor1099MiscRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnlyPositiveValuesGeneratedInMISC2019Report()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        VendNo: Code[20];
    begin
        // [SCENARIO 399767] Only positive values are generated in the MISC 2019 report

        Initialize();

        // [GIVEN] Vendor "X"
        VendNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Purchase invoice with "MISC-01" code and amount = 100
        CreateAndPostPurchaseDocWithVendorAndIRS1099Code(
          PurchaseHeader, PurchaseLine[1], PurchaseHeader."Document Type"::Order, VendNo, IRS1099CodeMisc01Lbl);

        // [GIVEN] Purchase credit memo with "MISC-04" code and amount = 50
        CreateAndPostPurchaseDocWithVendorAndIRS1099Code(
          PurchaseHeader, PurchaseLine[2], PurchaseHeader."Document Type"::"Credit Memo", VendNo, IRS1099CodeMisc04Lbl);
        LibraryVariableStorage.Enqueue(VendNo);

        // [WHEN] Run Vendor 1099 Misc 2019 Report
        REPORT.Run(REPORT::"Vendor 1099 Misc");

        LibraryReportDataset.LoadDataSetFile();
        // [THEN] "MISC-01" has value of 100
        LibraryReportDataset.AssertElementWithValueNotExist('GetAmtMISC01', PurchaseLine[1]."Line Amount");
        // [THEN] "MISC-50" has value of 50
        LibraryReportDataset.AssertElementWithValueNotExist('GetAmtMISC04', PurchaseLine[2]."Line Amount");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2020RequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnlyPositiveValuesGeneratedInMISC2020Report()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        VendNo: Code[20];
    begin
        // [SCENARIO 399767] Only positive values are generated in the MISC 2020 report

        Initialize();

        // [GIVEN] Vendor "X"
        VendNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Purchase invoice with "MISC-01" code and amount = 100
        CreateAndPostPurchaseDocWithVendorAndIRS1099Code(
          PurchaseHeader, PurchaseLine[1], PurchaseHeader."Document Type"::Order, VendNo, IRS1099CodeMisc01Lbl);

        // [GIVEN] Purchase credit memo with "MISC-04" code and amount = 50
        CreateAndPostPurchaseDocWithVendorAndIRS1099Code(
          PurchaseHeader, PurchaseLine[2], PurchaseHeader."Document Type"::"Credit Memo", VendNo, IRS1099CodeMisc04Lbl);
        LibraryVariableStorage.Enqueue(VendNo);

        // [WHEN] Run Vendor 1099 Misc 2020 Report
        REPORT.Run(REPORT::"Vendor 1099 Misc 2020");

        LibraryReportDataset.LoadDataSetFile();
        // [THEN] "MISC-01" has value of 100
        LibraryReportDataset.AssertElementWithValueNotExist('GetAmtMISC01', PurchaseLine[1]."Line Amount");
        // [THEN] "MISC-50" has value of 50
        LibraryReportDataset.AssertElementWithValueNotExist('GetAmtMISC04', PurchaseLine[2]."Line Amount");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemSalesByCustomerHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemSalesByCustomerReportByUndoShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        Quantity: Decimal;
        PstdDocNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO 444496] Item Sales by Customer report is not calculating correctly when an 'Undo shipment' is performed

        Initialize();

        // [GIVEN] Create Sales Order and post the shipment.
        CreateSalesOrder(SalesHeader, SalesLine);
        PstdDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        Quantity := SalesLine.Quantity;
        ItemNo := SalesLine."No.";

        // [THEN] Undo Shipment.
        SalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentLine.FindLast();
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
        Commit();

        // [THEN] Enqueue values to report Item Sales by Customer.
        EnqueueValuesForItemSalesByCustomerReport(0, 0, 0, 0, SalesLine."No.", SalesHeader."Sell-to Customer No.", false);

        // [THEN] Run Item Sales By Customer report.
        REPORT.Run(REPORT::"Item Sales by Customer");

        // [VERIFY]: Verify Invoiced Quantity on Item Sales By Customer Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(ItemNoCapLbl, SalesLine."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ItemLedgerEntryInvoicedQuantityLbl, Quantity);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ItemLedgerEntryInvoicedQuantityLbl, -Quantity);
    end;

    [Test]
    [HandlerFunctions('TrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunTrialBalanceReportWithClosingDate()
    var
        DateFilterText: Text;
        ToDate: Date;
        FromDate: Date;
    begin
        // [SCENARIO 544390] When Stan runs Trial Balance Report with Closing Date then Report is executed.
        Initialize();

        // [GIVEN] Generate To Date and save it in a Variable.
        ToDate := CalcDate('<CY>', Today());

        // [GIVEN] Generate From Date and save it in a Variable.
        FromDate := CalcDate('<-1Y>', ToDate + 1);

        // [GIVEN] Generate Date Filter and save it in a Variable.
        DateFilterText := Format(FromDate) + '..' + Format(ClosingDate(ToDate));

        // [GIVEN] Run Purchase Invoice Book Report.
        LibraryVariableStorage.Enqueue(DateFilterText);
        LibraryVariableStorage.Enqueue(true);
        Commit();
        Report.Run(Report::"Trial Balance");
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        Clear(LibraryReportDataset);
        LibraryVariableStorage.Clear();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.CreateVATData();
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; DocumentNo2: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        GetRemainingAmountOnCustomer(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");
        GetRemainingAmountOnCustomer(CustLedgerEntry2, DocumentType2, DocumentNo2);
        SetAppliesAfterValidatingAmountToApply(CustLedgerEntry2, CustLedgerEntry2."Remaining Amount");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyAndPostVendorEntry(DocumentNo: Code[20]; DocumentNo2: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        GetRemainingAmountOnVendor(VendorLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");
        GetRemainingAmountOnVendor(VendorLedgerEntry2, DocumentType2, DocumentNo2);
        SetAppliesAfterValidatingAmountToApplyVendor(VendorLedgerEntry2, VendorLedgerEntry2."Remaining Amount");
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure BOMRawMaterialsReportWithStockKeepingExist(var Item: Record Item; StockKeepingExist: Boolean)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // Create Item with lead time calculation. Create StockKeeping Unit with Variant.
        CreateItemWithLeadTimeCalculation(Item);
        CreateItemWithStockkeepingUnit(StockkeepingUnit, Item."No.", '');
        EnqueueValuesForAssemblyBOMHandlers(Item."No.", StockKeepingExist);
        Commit();  // Commit required.
        REPORT.Run(REPORT::"Assembly BOM - Raw Materials");
    end;

    local procedure BOMSubAssembliesReportWithStockKeepingExist(var Item: Record Item; StockKeepingExist: Boolean)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // Create multiple BOM Component. Create Stock Keeping Unit with Location.
        CreateMultipleBOMComponent(Item);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, CreateLocation(), Item."No.", '');
        EnqueueValuesForAssemblyBOMHandlers(Item."No.", StockKeepingExist);
        Commit();  // Commit required.
        REPORT.Run(REPORT::"Assembly BOM - Subassemblies");
    end;

    local procedure CreateAndModifyItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Taken random for Unit Price.
        Item.Validate("Standard Cost", LibraryRandom.RandDec(10, 2));  // Taken random for Standard Cost.
        Item.Modify(true);
    end;

    local procedure CreateAndUpdateTaxGroupOnItem(): Code[20]
    var
        Item: Record Item;
        TaxGroup: Record "Tax Group";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateTaxGroup(TaxGroup);
        Item.Validate("Tax Group Code", TaxGroup.Code);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndPostPurchaseDocument(ItemNo: Code[20]; DocumentType: Enum "Purchase Document Type"; Invoice: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, ItemNo, DocumentType);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice));
    end;

    local procedure CreateAndUpdateBOMComponent(var BOMComponent: Record "BOM Component"; ParentItemNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryManufacturing.CreateBOMComponent(
          BOMComponent, ParentItemNo, BOMComponent.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2), '');
    end;

#if not CLEAN23
    local procedure CreateAndModifySalesPrice(var SalesPrice: Record "Sales Price"; Item: Record Item; SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; CurrencyCode: Code[10])
    begin
        LibraryCosting.CreateSalesPrice(
          SalesPrice, SalesType, SalesCode, Item."No.", WorkDate(),
          CurrencyCode, '', '', LibraryRandom.RandDec(10, 2));
        SalesPrice.Validate("Unit Price", Item."Unit Price" + LibraryRandom.RandDec(10, 2));  // Taken Sales Price more than Item Unit Price.
        SalesPrice.Modify(true);
    end;
#endif

    local procedure CreateItemWithStockkeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemVariant: Record "Item Variant";
    begin
        LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, ItemVariant.Code);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        CreatePurchaseDocumentWithVendor(PurchaseHeader, PurchaseLine, ItemNo, DocumentType, LibraryPurchase.CreateVendorNo());
    end;

    local procedure CreatePurchaseDocumentWithVendor(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Taken random for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Taken random for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateTrackedItem(): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);
        exit(Item."No.");
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        exit(Location.Code);
    end;

    local procedure CreateAndModifySalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; CurrencyCode: Code[10]; ShipmentDate: Date; VariantCode: Code[10]; LocationCode: Code[10]; SellToCustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, SellToCustomerNo);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ShipmentDate, LibraryRandom.RandInt(10));  // Taken random for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Taken random Unit Price.
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure CreatePostTwoInvForTwoAccounts(var AccountNo: array[2] of Code[20]; var DocumentNo: array[2] of Code[20]; AccountType: Enum "Gen. Journal Account Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Sign: Integer;
        i: Integer;
    begin
        CreateGenJournalBatchWithTemplate(GenJournalBatch, true);
        for i := 1 to ArrayLen(AccountNo) do begin
            if AccountType = GenJournalLine."Account Type"::Customer then begin
                AccountNo[i] := LibrarySales.CreateCustomerNo();
                Sign := 1;
            end else begin
                AccountNo[i] := LibraryPurchase.CreateVendorNo();
                Sign := -1;
            end;
            LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              GenJournalLine."Document Type"::Invoice, AccountType, AccountNo[i], Sign * LibraryRandom.RandDecInRange(1000, 2000, 2));
            DocumentNo[i] := GenJournalLine."Document No.";
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostTwoPmtForTwoAccounts(AccountNo: array[2] of Code[20]; InvoiceDocNo: array[2] of Code[20]; AccountType: Enum "Gen. Journal Account Type") DocumentNo: Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Sign: Integer;
        i: Integer;
        BalanceAmount: Decimal;
    begin
        CreateGenJournalBatchWithTemplate(GenJournalBatch, false);
        if AccountType = GenJournalLine."Account Type"::Customer then
            Sign := -1
        else
            Sign := 1;
        for i := 1 to ArrayLen(AccountNo) do begin
            LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              GenJournalLine."Document Type"::Payment, AccountType, AccountNo[i], Sign * LibraryRandom.RandDecInRange(1000, 2000, 2));
            GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
            GenJournalLine.Validate("Applies-to Doc. No.", InvoiceDocNo[i]);
            if i = 1 then
                DocumentNo := GenJournalLine."Document No."
            else
                GenJournalLine.Validate("Document No.", DocumentNo);
            GenJournalLine.Modify(true);
            BalanceAmount += GenJournalLine.Amount;
        end;
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(), -BalanceAmount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGenJournalLine(DocumentNo: Code[20]; Amount: Decimal; AmountToApply: Decimal; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; SetApplies: Boolean): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalBatchWithTemplate(GenJournalBatch, true);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, AccountType, AccountNo, Amount);
        if SetApplies then
            if AccountType = GenJournalLine."Account Type"::Customer then begin
                UpdateCustomerLedgerEntryWithAppliesToId(GenJournalLine."Document No.", DocumentNo, AmountToApply);
                GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
                GenJournalLine.Modify(true);
            end else begin
                UpdateVendorLedgerEntryWithAppliesToId(GenJournalLine."Document No.", DocumentNo, AmountToApply);
                GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
                GenJournalLine.Modify(true);
            end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostSimpleGenJournalLine(DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalBatchWithTemplate(GenJournalBatch, true);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, AccountType, AccountNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; CurrencyCode: Code[10]; ShipmentDate: Date)
    begin
        CreateAndModifySalesDocument(
          SalesLine, SalesLine."Document Type"::Order, ItemNo, CurrencyCode, ShipmentDate, '', '', LibrarySales.CreateCustomerNo());
        ModifyQtyToShipOnSalesLine(SalesLine);
        PostSalesDocument(SalesLine);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithPaymentTerms());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(5));
        PurchaseLine.Validate("VAT %", 0);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(5000, 10000));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseDocWithVendorAndIRS1099Code(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; VendNo: Code[20]; IRS1099Code: Code[10])
    var
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendNo);
        PurchaseHeader.Validate("IRS 1099 Code", IRS1099Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(5));
        PurchaseLine.Validate("VAT %", 0);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(5000, 10000));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateItemWithLeadTimeCalculation(var Item: Record Item)
    var
        LeadTimeCalculation: DateFormula;
    begin
        LibraryInventory.CreateItem(Item);
        Evaluate(LeadTimeCalculation, '<' + Format(LibraryRandom.RandInt(10)) + 'D>');  // Random value for Days.
        Item.Validate("Lead Time Calculation", LeadTimeCalculation);
        Item.Modify(true);
    end;

    local procedure CreateMultipleBOMComponent(var Item: Record Item)
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(ComponentItem);
        LibraryInventory.CreateItem(ParentItem);
        CreateAndUpdateBOMComponent(BOMComponent, Item."No.", ComponentItem."No.");
        CreateAndUpdateBOMComponent(BOMComponent, ParentItem."No.", Item."No.");
    end;

    local procedure CreateSalesOrderWithItemTracking(var SalesLine: Record "Sales Line")
    var
        ItemVariant: Record "Item Variant";
    begin
        LibraryInventory.CreateItemVariant(ItemVariant, CreateTrackedItem());
        CreateAndModifySalesDocument(
          SalesLine, SalesLine."Document Type"::Order, ItemVariant."Item No.", '',
          WorkDate(), ItemVariant.Code, '', LibrarySales.CreateCustomerNo());
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateGenJournalBatchWithTemplate(var GenJournalBatch: Record "Gen. Journal Batch"; IsBalanceAccount: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        if IsBalanceAccount then begin
            GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
            GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateBankAccountNo());
            GenJournalBatch.Modify(true);
        end;
    end;

    local procedure CreateVendorWithPaymentTerms(): Code[20]
    var
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
    begin
        LibraryERM.FindPaymentMethod(PaymentMethod);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Validate("IRS 1099 Code", IRS1099CodeMiscLbl);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure EnqueueValuesforPurchaseDocument(BuyFromVendorNo: Code[20]; PrintCompanyAddress: Boolean; LogInteraction: Boolean)
    begin
        LibraryVariableStorage.Enqueue(BuyFromVendorNo);
        LibraryVariableStorage.Enqueue(PrintCompanyAddress);
        LibraryVariableStorage.Enqueue(LogInteraction);
    end;

    local procedure SetupForItemCostAndPriceReport(ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateAndPostPurchaseDocument(ItemNo, PurchaseHeader."Document Type"::Order, true);
        CreateAndPostPurchaseDocument(ItemNo, PurchaseHeader."Document Type"::Order, true);
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(true);  // Enqueue for ItemCostAndPriceListReportHandler.
        Commit();  // COMMIT is required to run the report.
    end;

    local procedure EnqueueValuesForAssemblyBOMHandlers(ItemNo: Code[20]; StockKeepingExist: Boolean)
    begin
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(StockKeepingExist);
    end;

    local procedure EnqueueValuesForListPriceSheetReport(SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; ItemNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(SalesType);
        LibraryVariableStorage.Enqueue(SalesCode);
        LibraryVariableStorage.Enqueue(ItemNo);  // Enqueue for ListPriceSheetRequestPageHandler.
    end;

    local procedure EnqueueValuesForItemSalesByCustomerReport(GreaterThanValue: Decimal; LessThanValue: Decimal; GreaterThanQty: Decimal; LessThanQty: Decimal; ItemNo: Code[20]; CusomerNo: Code[20]; IncludeReturns: Boolean)
    begin
        LibraryVariableStorage.Enqueue(GreaterThanValue);
        LibraryVariableStorage.Enqueue(LessThanValue);
        LibraryVariableStorage.Enqueue(GreaterThanQty);
        LibraryVariableStorage.Enqueue(LessThanQty);
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(CusomerNo);
        LibraryVariableStorage.Enqueue(IncludeReturns);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Sales Amount (Actual)", "Cost Amount (Actual)");
    end;

    local procedure FindAndPostGenJourLineAfterSuggestVendorPayment(GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure GetAmountToApplyFromTempAppliedCustLedgerEntry(DocumentNo: Code[20]): Decimal
    var
        TempAppliedCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryApplicationManagement: Codeunit "Entry Application Management";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        EntryApplicationManagement.GetAppliedCustEntries(TempAppliedCustLedgerEntry, CustLedgerEntry, true);
        TempAppliedCustLedgerEntry.CalcSums(TempAppliedCustLedgerEntry."Amount to Apply");
        exit(TempAppliedCustLedgerEntry."Amount to Apply");
    end;

    local procedure GetAmountAppliedFromDetailCustLedgerEntry(CustomerNo: Code[20]; EntryNo: Integer): Decimal
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", EntryNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Payment);
        DetailedCustLedgEntry.CalcSums(Amount);
        exit(DetailedCustLedgEntry.Amount);
    end;

    local procedure GetAmountToApplyFromTempAppliedVendorLedgerEntry(DocumentNo: Code[20]): Decimal
    var
        TempAppliedVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EntryApplicationManagement: Codeunit "Entry Application Management";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        EntryApplicationManagement.GetAppliedVendEntries(TempAppliedVendorLedgerEntry, VendorLedgerEntry, true);
        TempAppliedVendorLedgerEntry.CalcSums(TempAppliedVendorLedgerEntry."Amount to Apply");
        exit(TempAppliedVendorLedgerEntry."Amount to Apply");
    end;

    local procedure GetAmountAppliedFromDetailVendorLedgerEntry(VendorNo: Code[20]; EntryNo: Integer): Decimal
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", EntryNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.SetRange("Document Type", DetailedVendorLedgEntry."Document Type"::Payment);
        DetailedVendorLedgEntry.CalcSums(Amount);
        exit(DetailedVendorLedgEntry.Amount);
    end;

    local procedure GetPurchLineAmount(PurchaseHeader: Record "Purchase Header"; VATPercent: Decimal) Amount: Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
        repeat
            Amount += PurchaseLine.Amount;
        until PurchaseLine.Next() = 0;
        Amount := Amount + Round(Amount * (VATPercent / 100), LibraryERM.GetAmountRoundingPrecision());
    end;

    local procedure GetRemainingAmountOnCustomer(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
    end;

    local procedure GetRemainingAmountOnVendor(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
    end;

    local procedure GetAppliedCustomerEntries(var TempCustLedgerEntryApplied: Record "Cust. Ledger Entry" temporary; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryApplicationManagement: Codeunit "Entry Application Management";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        EntryApplicationManagement.GetAppliedCustEntries(TempCustLedgerEntryApplied, CustLedgerEntry, false);
    end;

    local procedure GetAppliedVendorEntries(var TempVendorLedgerEntryApplied: Record "Vendor Ledger Entry" temporary; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EntryApplicationManagement: Codeunit "Entry Application Management";
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        EntryApplicationManagement.GetAppliedVendEntries(TempVendorLedgerEntryApplied, VendorLedgerEntry, false);
    end;

    local procedure ModifyQtyToShipOnSalesLine(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Qty. to Ship", SalesLine."Qty. to Ship" / 2);  // Taken partial Quantity.
        SalesLine.Modify(true);
    end;

    local procedure PostSalesDocument(SalesLine: Record "Sales Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostGenJournalLineAfterSuggestVendorPayment(VendorNo: Code[20]; PmtDiscountDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(PmtDiscountDate);
        SuggestVendorPaymentUsingPageMsg(GenJournalLine);
        FindAndPostGenJourLineAfterSuggestVendorPayment(GenJournalLine);
        LibraryVariableStorage.Enqueue(VendorNo);
    end;

    local procedure PostManualApplicationSalesInvoiceToPayment(CustomerNo: Code[20]; var InvoiceNo: Code[20]; var PaymentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        LineAmount: Decimal;
    begin
        LineAmount := LibraryRandom.RandDec(100, 2);
        InvoiceNo :=
          CreateAndPostSimpleGenJournalLine(GenJournalLine."Document Type"::Invoice, LineAmount, GenJournalLine."Account Type"::Customer, CustomerNo);
        PaymentNo :=
          CreateAndPostSimpleGenJournalLine(GenJournalLine."Document Type"::Payment, -LineAmount, GenJournalLine."Account Type"::Customer, CustomerNo);
        ApplyAndPostCustomerEntry(
          InvoiceNo, PaymentNo,
          CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::Payment);
    end;

    local procedure PostManualApplicationPurchaseInvoiceToPayment(VendorNo: Code[20]; var InvoiceNo: Code[20]; var PaymentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        LineAmount: Decimal;
    begin
        LineAmount := LibraryRandom.RandDec(100, 2);
        InvoiceNo :=
          CreateAndPostSimpleGenJournalLine(GenJournalLine."Document Type"::Invoice, -LineAmount, GenJournalLine."Account Type"::Vendor, VendorNo);
        PaymentNo :=
          CreateAndPostSimpleGenJournalLine(GenJournalLine."Document Type"::Payment, LineAmount, GenJournalLine."Account Type"::Vendor, VendorNo);
        ApplyAndPostVendorEntry(
          InvoiceNo, PaymentNo, VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Document Type"::Payment);
    end;

    local procedure PostPurchOrderWithPmtGreaterThanDueDate(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine);
        PostGenJournalLineAfterSuggestVendorPayment(PurchaseHeader."Buy-from Vendor No.",
          CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandIntInRange(2, 5)), PurchaseHeader."Pmt. Discount Date"));
    end;

    local procedure SetAppliesAfterValidatingAmountToApply(var CustLedgerEntry: Record "Cust. Ledger Entry"; AmountToApply: Decimal)
    begin
        CustLedgerEntry.Validate("Amount to Apply", AmountToApply);
        CustLedgerEntry.Modify(true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
    end;

    local procedure SetAppliesAfterValidatingAmountToApplyVendor(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AmountToApply: Decimal)
    begin
        VendorLedgerEntry.Validate("Amount to Apply", AmountToApply);
        VendorLedgerEntry.Modify(true);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure SuggestVendorPaymentUsingPageMsg(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        Commit();
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.Run();
    end;

    local procedure UpdateCustomerLedgerEntryWithAppliesToId(AppliesToId: Code[20]; InvDocumentNo: Code[20]; AmountToApply: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvDocumentNo);
        CustLedgerEntry.Validate("Applies-to ID", AppliesToId);
        CustLedgerEntry.Validate("Amount to Apply", AmountToApply);
        CustLedgerEntry.Modify(true);
    end;

    local procedure UpdateVendorLedgerEntryWithAppliesToId(AppliesToId: Code[20]; InvDocumentNo: Code[20]; AmountToApply: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvDocumentNo);
        VendorLedgerEntry.Validate("Applies-to ID", AppliesToId);
        VendorLedgerEntry.Validate("Amount to Apply", AmountToApply);
        VendorLedgerEntry.Modify(true);
    end;

    local procedure VerifyAmtAndQtyOnPurchDocument(No: Code[20]; ItemNoCapLbl: Text[50]; QuantityCaption: Text[50]; Quantity: Variant; AmountCaption: Text[50]; AmountExclInvDisc: Decimal)
    begin
        VerifyValuesOnReport(No, ItemNoCapLbl, QuantityCaption, Quantity);
        VerifyValuesOnReport(No, ItemNoCapLbl, AmountCaption, AmountExclInvDisc);
    end;

    local procedure VerifyPurchaseDocument(Item: Record Item; DocumentNo: Text[20]; CompanyName: Text[100]; BuyfromVendorName: Text[100]; NoPurchHeader: Text[50]; DescriptionPurchInvLine: Text[100]; UnitofMeasurePurchInvLine: Text[50]; ItemNoCapLbl: Text[50]; CompNameCaption: Text[50]; VendNameCaption: Text[50])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Get(Item."Base Unit of Measure");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(NoPurchHeader, DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists(CompNameCaption, CompanyName);
        LibraryReportDataset.AssertElementWithValueExists(VendNameCaption, BuyfromVendorName);
        VerifyValuesOnReport(Item."No.", ItemNoCapLbl, DescriptionPurchInvLine, Item.Description);
        VerifyValuesOnReport(Item."No.", ItemNoCapLbl, UnitofMeasurePurchInvLine, UnitOfMeasure.Description);
    end;

    local procedure VerifyLogInteraction(DocumentNo: Code[20]; ActualLogInteraction: Boolean)
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        ExpLogInteraction: Boolean;
    begin
        InteractionLogEntry.SetRange("Document No.", DocumentNo);
        ExpLogInteraction := InteractionLogEntry.IsEmpty();
        Assert.AreEqual(ExpLogInteraction, ActualLogInteraction, ValueMustMatchTxt)
    end;

    local procedure VerifyValuesOnReport(ItemNo: Text[50]; ItemCaption: Text[50]; ValueCaption: Text[100]; Value: Variant)
    begin
        LibraryReportDataset.SetRange(ItemCaption, ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ValueCaption, Value);
    end;

    local procedure VerifySalesLineValuesOnBackOrderReport(RowValue: Text[50]; RowCaption: Text[50]; SalesLine: Record "Sales Line")
    begin
        VerifyValuesOnReport(RowValue, RowCaption, SalesLineDocumentNoLbl, SalesLine."Document No.");
        VerifyValuesOnReport(RowValue, RowCaption, SalesLineOutstandingQuantityLbl, SalesLine."Outstanding Quantity");
        VerifyValuesOnReport(RowValue, RowCaption, SalesLineQuantityLbl, SalesLine.Quantity);
    end;

    local procedure VerifyRemainingAmountOnInvCustLedgerEntry(DocumentNo: Code[20]; RemainingAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", RemainingAmount);
    end;

    local procedure VerifyRemainingAmountOnInvVendorLedgerEntry(DocumentNo: Code[20]; RemainingAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", RemainingAmount);
    end;

    local procedure VerifyAppliedCustomerEntries(var TempCustLedgerEntryApplied: Record "Cust. Ledger Entry" temporary; PaymentXNo: Code[20]; ExpectedCustomerNo: Code[20])
    begin
        TempCustLedgerEntryApplied.SetRange("Document Type", TempCustLedgerEntryApplied."Document Type"::Payment);
        Assert.AreEqual(1, TempCustLedgerEntryApplied.Count, IncorrectPaymentCountErr);
        TempCustLedgerEntryApplied.FindFirst();
        Assert.AreEqual(PaymentXNo, TempCustLedgerEntryApplied."Document No.", StrSubstNo(PaymentNotFoundErr, PaymentXNo));
        Assert.AreEqual(ExpectedCustomerNo, TempCustLedgerEntryApplied."Customer No.", TempCustLedgerEntryApplied.FieldCaption("Customer No."));
    end;

    local procedure VerifyAppliedVendorEntries(var TempVendorLedgerEntryApplied: Record "Vendor Ledger Entry" temporary; PaymentXNo: Code[20]; ExpectedVendorNo: Code[20])
    begin
        TempVendorLedgerEntryApplied.SetRange("Document Type", TempVendorLedgerEntryApplied."Document Type"::Payment);
        Assert.AreEqual(1, TempVendorLedgerEntryApplied.Count, IncorrectPaymentCountErr);
        TempVendorLedgerEntryApplied.FindFirst();
        Assert.AreEqual(PaymentXNo, TempVendorLedgerEntryApplied."Document No.", StrSubstNo(PaymentNotFoundErr, PaymentXNo));
        Assert.AreEqual(ExpectedVendorNo, TempVendorLedgerEntryApplied."Vendor No.", TempVendorLedgerEntryApplied.FieldCaption("Vendor No."));
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        LibrarySales.CreateSalesOrder(SalesHeader);
        GetSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity);
        SalesLine.Modify(true);
    end;

    local procedure GetSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AssemblyBOMSubAssembliesHandler(var AssemblyBOMSubassemblies: TestRequestPage "Assembly BOM - Subassemblies")
    var
        No: Variant;
        StockKeepingExist: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(StockKeepingExist);  // Dequeue variable.
        AssemblyBOMSubassemblies.Item.SetFilter("No.", No);
        AssemblyBOMSubassemblies.Item.SetFilter("Stockkeeping Unit Exists", Format(StockKeepingExist));
        AssemblyBOMSubassemblies.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AssemblyBOMRawMaterialsHandler(var AssemblyBOMRawMaterials: TestRequestPage "Assembly BOM - Raw Materials")
    var
        No: Variant;
        StockKeepingExist: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(StockKeepingExist);  // Dequeue variable.
        AssemblyBOMRawMaterials.Item.SetFilter("No.", No);
        AssemblyBOMRawMaterials.Item.SetFilter("Stockkeeping Unit Exists", Format(StockKeepingExist));
        AssemblyBOMRawMaterials.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AvailabilityStatusRequestPageHandler(var AvailabilityStatus: TestRequestPage "Availability Status")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        AvailabilityStatus.Item.SetFilter("No.", ItemNo);
        AvailabilityStatus.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BackOrderFillByItemHandler(var BackOrderFillbyItem: TestRequestPage "Back Order Fill by Item")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        BackOrderFillbyItem.Item.SetFilter("No.", ItemNo);
        BackOrderFillbyItem.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BackOrderFillbyCustomerHandler(var BackOrderFillbyCustomer: TestRequestPage "Back Order Fill by Customer")
    var
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        BackOrderFillbyCustomer.Customer.SetFilter("No.", CustomerNo);
        BackOrderFillbyCustomer.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantitytoCreatePageHandler(var EnterQuantitytoCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantitytoCreate.CreateNewLotNo.SetValue(true);
        EnterQuantitytoCreate.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemListRequestPageHandler(var ItemList: TestRequestPage "Item List")
    var
        AddInfo: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(AddInfo);
        ItemList.MoreInfo.SetValue(AddInfo);
        ItemList.UseSKU.SetValue(AddInfo);
        ItemList.Item.SetFilter("No.", ItemNo);
        ItemList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Serial No.".Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemCostAndPriceListReportHandler(var ItemCostandPriceList: TestRequestPage "Item Cost and Price List")
    var
        ItemNo: Variant;
        UseStockkeepingUnit: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(UseStockkeepingUnit);
        ItemCostandPriceList.UseSKU.SetValue(UseStockkeepingUnit);  // Setting value for control 'Use Stockkeeping Unit'.
        ItemCostandPriceList.Item.SetFilter("No.", ItemNo);
        ItemCostandPriceList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemSalesByCustomerHandler(var ItemSalesByCustomer: TestRequestPage "Item Sales by Customer")
    var
        GreaterThanValue: Variant;
        LessThanValue: Variant;
        GreaterThanQty: Variant;
        LessThanQty: Variant;
        No: Variant;
        SourceNo: Variant;
        IncludeReturns: Variant;
    begin
        LibraryVariableStorage.Dequeue(GreaterThanValue);
        LibraryVariableStorage.Dequeue(LessThanValue);
        LibraryVariableStorage.Dequeue(GreaterThanQty);
        LibraryVariableStorage.Dequeue(LessThanQty);
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(SourceNo);
        LibraryVariableStorage.Dequeue(IncludeReturns);

        ItemSalesByCustomer.IncludeReturns.SetValue(IncludeReturns);  // Setting value for Include Returns.
        ItemSalesByCustomer.MinSales.SetValue(GreaterThanValue);  // Setting value for Item with Net Sales($) Greater than.
        ItemSalesByCustomer.MaxSales.SetValue(LessThanValue);  // Setting value for Item with Net Sales($) Less than.
        ItemSalesByCustomer.MinQty.SetValue(GreaterThanQty);  // Setting value for Item with Net Sales(Qty) Greater than.
        ItemSalesByCustomer.MaxQty.SetValue(LessThanQty);  // Setting value for Item with Net Sales(Qty) Less than.
        ItemSalesByCustomer.Item.SetFilter("No.", No);
        ItemSalesByCustomer."Item Ledger Entry".SetFilter("Source No.", SourceNo);
        ItemSalesByCustomer.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemSalesStatisticsRequestPageHandler(var ItemSalesStatistics: TestRequestPage "Item Sales Statistics")
    var
        No: Variant;
        IncludeItemDescription: Variant;
        BreakdownByVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(IncludeItemDescription);
        LibraryVariableStorage.Dequeue(BreakdownByVariant);
        ItemSalesStatistics.IncludeItemDescriptions.SetValue(IncludeItemDescription);  // Setting value for Include Item Description.
        ItemSalesStatistics.BreakdownByVariant.SetValue(BreakdownByVariant);  // Setting value for Breakdown by Variant.
        ItemSalesStatistics.Item.SetFilter("No.", No);
        ItemSalesStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemsBySalesTaxGroupRequestPageHandler(var ItemsbySalesTaxGroup: TestRequestPage "Items by Sales Tax Group")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        ItemsbySalesTaxGroup.Item.SetFilter("No.", ItemNo);
        ItemsbySalesTaxGroup.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

#if not CLEAN23
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ListPriceSheetRequestPageHandler(var ListPriceSheet: TestRequestPage "List Price Sheet")
    var
        SalesType: Variant;
        SalesCode: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SalesType);
        LibraryVariableStorage.Dequeue(SalesCode);
        LibraryVariableStorage.Dequeue(ItemNo);
        ListPriceSheet.SalesType.SetValue(SalesType);  // Setting value for control Sales Type.
        ListPriceSheet.SalesCodeCtrl.SetValue(SalesCode);
        ListPriceSheet.Item.SetFilter("No.", ItemNo);
        ListPriceSheet.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
#endif

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PickingListbyOrderRequestPageHandler(var PickingListbyOrder: TestRequestPage "Picking List by Order")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PickingListbyOrder."Sales Header".SetFilter("No.", No);
        PickingListbyOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetFiltersOnPickingListbyOrderRequestPageHandler(var PickingListbyOrder: TestRequestPage "Picking List by Order")
    begin
        LibraryVariableStorage.Enqueue(PickingListbyOrder."Sales Header".GetFilter("Document Type"));
        LibraryVariableStorage.Enqueue(PickingListbyOrder."Sales Header".GetFilter("No."));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PickingListByItemRequestPageHandler(var PickingListbyItem: TestRequestPage "Picking List by Item")
    var
        No: Variant;
        LocationCode: Variant;
        SellToCustomerNo: Variant;
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(LocationCode);
        LibraryVariableStorage.Dequeue(SellToCustomerNo);
        LibraryVariableStorage.Dequeue(DocumentNo);

        PickingListbyItem.Item.SetFilter("No.", No);
        PickingListbyItem."Sales Line".SetFilter("Location Code", LocationCode);
        PickingListbyItem."Sales Line".SetFilter("Sell-to Customer No.", SellToCustomerNo);
        PickingListbyItem."Sales Line".SetFilter("Document No.", DocumentNo);
        PickingListbyItem.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchCrMemoRequestPageHandler(var PurchaseCreditMemo: TestRequestPage "Purchase Credit Memo NA")
    var
        BuyfromVendorNo: Variant;
        LogInteraction: Variant;
        PrintCompanyAddress: Variant;
    begin
        LibraryVariableStorage.Dequeue(BuyfromVendorNo);
        LibraryVariableStorage.Dequeue(PrintCompanyAddress);
        LibraryVariableStorage.Dequeue(LogInteraction);
        PurchaseCreditMemo.NumberOfCopies.SetValue(1);
        PurchaseCreditMemo.PrintCompanyAddress.SetValue(PrintCompanyAddress);  // Print Company Address.
        PurchaseCreditMemo.LogInteraction.SetValue(LogInteraction);  // Log Interaction.
        PurchaseCreditMemo."Purch. Cr. Memo Hdr.".SetFilter("Buy-from Vendor No.", BuyfromVendorNo);
        PurchaseCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchInvoiceRequestPageHandler(var PurchaseInvoice: TestRequestPage "Purchase Invoice NA")
    var
        BuyfromVendorNo: Variant;
        LogInteraction: Variant;
        PrintCompanyAddress: Variant;
    begin
        LibraryVariableStorage.Dequeue(BuyfromVendorNo);
        LibraryVariableStorage.Dequeue(PrintCompanyAddress);
        LibraryVariableStorage.Dequeue(LogInteraction);
        PurchaseInvoice.NumberOfCopies.SetValue(1);  // No. of Copies.
        PurchaseInvoice.PrintCompanyAddress.SetValue(PrintCompanyAddress);  // Print Company Address.
        PurchaseInvoice.LogInteraction.SetValue(LogInteraction);  // Log Interaction.
        PurchaseInvoice."Purch. Inv. Header".SetFilter("Buy-from Vendor No.", BuyfromVendorNo);
        PurchaseInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchDocTestRepRequestPageHandler(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseDocumentTest."Purchase Header".SetFilter("No.", No);
        PurchaseDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderRequestPageHandler(var StandardPurchaseOrder: TestRequestPage "Standard Purchase - Order")
    var
        BuyfromVendorNo: Variant;
        LogInteraction: Variant;
        PrintCompanyAddress: Variant;
    begin
        LibraryVariableStorage.Dequeue(BuyfromVendorNo);
        LibraryVariableStorage.Dequeue(PrintCompanyAddress);
        LibraryVariableStorage.Dequeue(LogInteraction);
        StandardPurchaseOrder.LogInteraction.SetValue(LogInteraction);  // Log Interaction.
        StandardPurchaseOrder."Purchase Header".SetFilter("Buy-from Vendor No.", BuyfromVendorNo);
        StandardPurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderSimpleRequestPageHandler(var PurchaseOrder: TestRequestPage "Purchase Order")
    begin
        PurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchQuoteRequestPageHandler(var PurchaseQuote: TestRequestPage "Purchase Quote NA")
    var
        BuyfromVendorNo: Variant;
        LogInteraction: Variant;
        PrintCompanyAddress: Variant;
    begin
        LibraryVariableStorage.Dequeue(BuyfromVendorNo);
        LibraryVariableStorage.Dequeue(PrintCompanyAddress);
        LibraryVariableStorage.Dequeue(LogInteraction);
        PurchaseQuote.NumberOfCopies.SetValue(1);
        PurchaseQuote.PrintCompanyAddress.SetValue(PrintCompanyAddress);  // Print Company Address.
        PurchaseQuote.LogInteraction.SetValue(LogInteraction);  // Log Interaction.
        PurchaseQuote."Purchase Header".SetFilter("Buy-from Vendor No.", BuyfromVendorNo);
        PurchaseQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchReceiptRequestPageHandler(var PurchaseReceipt: TestRequestPage "Purchase Receipt NA")
    var
        BuyfromVendorNo: Variant;
        LogInteraction: Variant;
        PrintCompanyAddress: Variant;
    begin
        LibraryVariableStorage.Dequeue(BuyfromVendorNo);
        LibraryVariableStorage.Dequeue(PrintCompanyAddress);
        LibraryVariableStorage.Dequeue(LogInteraction);
        PurchaseReceipt.NumberOfCopies.SetValue(1);
        PurchaseReceipt.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        PurchaseReceipt.LogInteraction.SetValue(LogInteraction);  // Log Interaction.
        PurchaseReceipt."Purch. Rcpt. Header".SetFilter("Buy-from Vendor No.", BuyfromVendorNo);
        PurchaseReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchRetOrderRequestPageHandler(var ReturnOrderConfirm: TestRequestPage "Return Order Confirm")
    var
        BuyfromVendorNo: Variant;
        LogInteraction: Variant;
        PrintCompanyAddress: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(BuyfromVendorNo);
        LibraryVariableStorage.Dequeue(PrintCompanyAddress);
        LibraryVariableStorage.Dequeue(LogInteraction);
        LibraryVariableStorage.Dequeue(No);
        ReturnOrderConfirm.NumberOfCopies.SetValue(1);
        ReturnOrderConfirm.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        ReturnOrderConfirm.LogInteraction.SetValue(LogInteraction);  // Log Interaction.
        ReturnOrderConfirm."Purchase Header".SetFilter("Buy-from Vendor No.", BuyfromVendorNo);
        ReturnOrderConfirm."Purchase Header".SetFilter("No.", No);
        ReturnOrderConfirm.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesHistoryRequestPagehandler(var SalesHistory: TestRequestPage "Sales History")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesHistory."DateRange[1]".SetValue(WorkDate());  // Setting value for Starting Date.
        SalesHistory.Item.SetFilter("No.", No);
        SalesHistory.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

#if not CLEAN23
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesPromotionRequestPageHandler(var SalesPromotion: TestRequestPage "Sales Promotion")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        SalesPromotion.Item.SetFilter("No.", ItemNo);
        SalesPromotion.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
#endif

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatusRequestPageHandler(var SalesOrderStatus: TestRequestPage "Sales Order Status")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        SalesOrderStatus.Item.SetFilter("No.", ItemNo);
        SalesOrderStatus.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SerialNumberSoldHistoryRequestPageHandler(var SerialNumberSoldHistory: TestRequestPage "Serial Number Sold History")
    var
        No: Variant;
        VariantFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(VariantFilter);
        SerialNumberSoldHistory.Item.SetFilter("No.", No);
        SerialNumberSoldHistory.Item.SetFilter("Variant Filter", VariantFilter);
        SerialNumberSoldHistory.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedListRequestPageHandler(var WhereUsedList: TestRequestPage "Where-Used List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);  // Dequeue variable.
        WhereUsedList.Item.SetFilter("No.", No);
        WhereUsedList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        BankAccount: Record "Bank Account";
        No: Variant;
        LastPaymentDate: Variant;
        BalAccountType: Option "G/L Account",Customer,Vendor,"Bank Account";
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(LastPaymentDate);
        LibraryERM.FindBankAccount(BankAccount);
        SuggestVendorPayments.LastPaymentDate.SetValue(LastPaymentDate);
        SuggestVendorPayments.FindPaymentDiscounts.SetValue(true);
        SuggestVendorPayments.PostingDate.SetValue(SuggestVendorPayments.LastPaymentDate.Value);
        SuggestVendorPayments.NewDocNoPerLine.SetValue(true);
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));
        SuggestVendorPayments.BalAccountType.SetValue(BalAccountType::"Bank Account");
        SuggestVendorPayments.BalAccountNo.SetValue(BankAccount."No.");
        SuggestVendorPayments.Vendor.SetFilter("No.", No);
        SuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099MiscRequestPageHandler(var Vendor1099Misc: TestRequestPage "Vendor 1099 Misc")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        Vendor1099Misc.Vendor.SetFilter("No.", No);
        Vendor1099Misc.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Misc2020RequestPageHandler(var Vendor1099Misc2020: TestRequestPage "Vendor 1099 Misc 2020")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        Vendor1099Misc2020.Vendor.SetFilter("No.", No);
        Vendor1099Misc2020.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CashReceiptRPH(var CashApplied: TestRequestPage "Cash Applied")
    begin
        CashApplied.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalanceRequestPageHandler(var TrialBalance: TestRequestPage "Trial Balance")
    var
        DateFilterText: Variant;
    begin
        LibraryVariableStorage.Dequeue(DateFilterText);
        TrialBalance.ActualBalances.SetValue(LibraryVariableStorage.DequeueBoolean());
        TrialBalance."G/L Account".SetFilter("Date Filter", Format(DateFilterText));
        TrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure GLRegisterReportHandler(var GLRegister: Report "G/L Register")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", LibraryVariableStorage.DequeueText());
        GLRegister.SetTableView(GLEntry);
        GLRegister.SaveAsXml(LibraryReportDataset.GetFileName());
    end;
}
#endif