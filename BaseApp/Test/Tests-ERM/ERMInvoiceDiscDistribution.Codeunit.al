codeunit 134098 "ERM Invoice Disc. Distribution"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Invoice Discount]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        InvoiceDiscountGeneralTabErr: Label 'Wrong invoice discount on statistic general tab.';
        InvoiceDiscountInvoicingTabErr: Label 'Wrong invoice discount on statistic invoicing tab.';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsMPHGetInvoiceDiscountAmounts')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialInvoicingInvoiceDiscountAmountOnSubtotals()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Sales] [Subtotals] [UI]
        // [SCENARIO 218622] Cassie can change invoice discount on partial invoicing sales order page.
        Initialize();

        // [GIVEN] Sales order with 3 lines
        // [GIVEN] Line[1]: Quantity = 10, "Qty. to Invoice" = 0, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[2]: Quantity = 10, "Qty. to Invoice" = 5, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[3]: Quantity = 10, "Qty. to Invoice" = 10, "Unit Price" = 1000, "Line Amount" = 10000
        Quantity := 10;
        UnitPrice := 1000;
        CreatePartialInvoicingSalesDocumentWithLines(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Quantity, UnitPrice, 2);

        // [WHEN] Set "Invoice Discount Amount Excl. VAT" = 1000 at subtotals
        SalesOrder.OpenEdit;
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(UnitPrice);

        // [THEN] Line[1]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 0
        // [THEN] Line[2]: "Invoice Discount Amount Excl. VAT" = 333.34, "Inv. Disc. Amount to Invoice" = 166.67
        // [THEN] Line[3]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 333.33
        VerifySalesLines(SalesLine, 1);

        // [THEN] "Invoice Discount Amount" on Invoicing tab of Statistics page = 500
        SalesOrder.Statistics.Invoke;

        Assert.AreEqual(UnitPrice, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountGeneralTabErr);
        Assert.AreEqual(UnitPrice / 2, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountInvoicingTabErr);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsMPHSetInvoiceDiscountGeneral')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialInvoicingInvoiceDiscountAmountOnStatisticsGeneralTab()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Sales] [Statistics] [UI]
        // [SCENARIO 218622] Cassie can change invoice discount for partial invoicing sales order on general tab of statistics page.

        // [GIVEN] Sales order with 3 lines
        // [GIVEN] Line[1]: Quantity = 10, "Qty. to Invoice" = 0, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[2]: Quantity = 10, "Qty. to Invoice" = 5, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[3]: Quantity = 10, "Qty. to Invoice" = 10, "Unit Price" = 1000, "Line Amount" = 10000
        Quantity := 10;
        UnitPrice := 1000;
        CreatePartialInvoicingSalesDocumentWithLines(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Quantity, UnitPrice, 2);

        // [WHEN] Cassie validated "Invoice Discount Amount" = 1000 on General tab of Statistics page
        EnqueueInvoiceDiscountAmountForGeneralTab(UnitPrice);
        OpenSalesOrderAndStatistics(SalesOrder, SalesHeader);

        // [THEN] "Invoice Discount Amount" = 500 on Invoicing tab
        Assert.AreEqual(UnitPrice / 2, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountInvoicingTabErr);
        LibraryVariableStorage.AssertEmpty;
        // [THEN] "Inv. Discount Amount Excl. VAT" = 1000 on subtotals part.
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(UnitPrice);

        // [THEN] Line[1]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 0
        // [THEN] Line[2]: "Invoice Discount Amount Excl. VAT" = 333.34, "Inv. Disc. Amount to Invoice" = 166.67
        // [THEN] Line[3]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 333.33
        VerifySalesLines(SalesLine, 1);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsMPHSetInvoiceDiscountInvoicing')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialInvoicingInvoiceDiscountAmountOnStatisticsInvoicingTab()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Sales] [Statistics] [UI]
        // [SCENARIO 218622] Cassie can change invoice discount for partial invoicing sales order on invoicing tab of statistics page.

        // [GIVEN] Sales order with 3 lines
        // [GIVEN] Line[1]: Quantity = 10, "Qty. to Invoice" = 0, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[2]: Quantity = 10, "Qty. to Invoice" = 5, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[3]: Quantity = 10, "Qty. to Invoice" = 10, "Unit Price" = 1000, "Line Amount" = 10000
        Quantity := 10;
        UnitPrice := 1000;
        CreatePartialInvoicingSalesDocumentWithLines(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Quantity, UnitPrice, 2);

        // [WHEN] Validate "Invoice Discount Amount" = 500 on Invoicing tab of Statistics page
        EnqueueInvoiceDiscountAmountForInvoicingTab(UnitPrice);
        OpenSalesOrderAndStatistics(SalesOrder, SalesHeader);

        // [THEN] "Invoice Discount Amount" = 0 on General tab
        Assert.AreEqual(0, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountGeneralTabErr);
        LibraryVariableStorage.AssertEmpty;
        // [THEN] "Inv. Discount Amount Excl. VAT" = 0 on subtotals part.
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(0);

        // [THEN] Line[1]: "Invoice Discount Amount Excl. VAT" = 0, "Inv. Disc. Amount to Invoice" = 0
        // [THEN] Line[2]: "Invoice Discount Amount Excl. VAT" = 0, "Inv. Disc. Amount to Invoice" = 166.67
        // [THEN] Line[3]: "Invoice Discount Amount Excl. VAT" = 0, "Inv. Disc. Amount to Invoice" = 333.33
        VerifySalesLines(SalesLine, 0);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsMPHSetInvoiceDiscountGeneral')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialInvoicingInvoiceDiscountAmountOnStatisticsGeneralTabWith11Lines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Sales] [Statistics] [UI]
        // [SCENARIO 218622] Cassie can change invoice discount for partial invoicing sales order on general tab of statistics page.

        // [GIVEN] Sales order with 11 lines (more than the lines limit so totals will not be updated automatically)
        Quantity := 10;
        UnitPrice := 1000;
        CreatePartialInvoicingSalesDocumentWithLines(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Quantity, UnitPrice, 11);

        // [WHEN] Cassie validated "Invoice Discount Amount" = 1000 on General tab of Statistics page
        EnqueueInvoiceDiscountAmountForGeneralTab(UnitPrice);
        OpenSalesOrderAndStatistics(SalesOrder, SalesHeader);

        // [THEN] "Invoice Discount Amount" = 500 on Invoicing tab
        Assert.AreEqual(UnitPrice / 2, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountInvoicingTabErr);
        LibraryVariableStorage.AssertEmpty;
        // [THEN] "Inv. Discount Amount Excl. VAT" = 1000 on subtotals part.
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(UnitPrice);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsMPHGetInvoiceDiscountAmounts,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialInvoicedInvoiceDiscountAmountOnSubtotals()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Sales] [Subtotals] [UI]
        // [SCENARIO 218622] Cassie can change invoice discount on partial invoiced sales order page.

        // [GIVEN] Sales order with 3 lines
        // [GIVEN] Line[1]: Quantity = 10, "Qty. to Invoice" = 0, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[2]: Quantity = 10, "Qty. to Invoice" = 5, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[3]: Quantity = 10, "Qty. to Invoice" = 10, "Unit Price" = 1000, "Line Amount" = 10000
        Quantity := 10;
        UnitPrice := 1000;
        CreatePartialInvoicingSalesDocumentWithLines(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Quantity, UnitPrice, 2);

        // [GIVEN] Sales order posted => "Qty. to Invoice" changed to remaning quantity in lines
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Set "Invoice Discount Amount Excl. VAT" = 1000 at subtotals
        SalesOrder.OpenEdit;
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(UnitPrice);

        // [THEN] Line[1]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 333.33
        // [THEN] Line[2]: "Invoice Discount Amount Excl. VAT" = 333.34, "Inv. Disc. Amount to Invoice" = 166.67
        // [THEN] Line[3]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 0
        SalesLine.Ascending(false);
        VerifySalesLines(SalesLine, 1);

        // [THEN] "Invoice Discount Amount" on Invoicing tab of Statistics page = 500
        SalesOrder.Statistics.Invoke;

        Assert.AreEqual(UnitPrice, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountGeneralTabErr);
        Assert.AreEqual(UnitPrice / 2, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountInvoicingTabErr);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsMPHSetInvoiceDiscountGeneral,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialInvoicedInvoiceDiscountAmountOnStatisticsGeneralTab()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Sales] [Statistics] [UI]
        // [SCENARIO 218622] Cassie can change invoice discount for partial invoiced sales order on general tab of statistics page.

        // [GIVEN] Sales order with 3 lines
        // [GIVEN] Line[1]: Quantity = 10, "Qty. to Invoice" = 0, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[2]: Quantity = 10, "Qty. to Invoice" = 5, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[3]: Quantity = 10, "Qty. to Invoice" = 10, "Unit Price" = 1000, "Line Amount" = 10000
        Quantity := 10;
        UnitPrice := 1000;
        CreatePartialInvoicingSalesDocumentWithLines(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Quantity, UnitPrice, 2);

        // [GIVEN] Sales order posted => "Qty. to Invoice" changed to remaning quantity in lines
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Cassie validated "Invoice Discount Amount" = 1000 on General tab of Statistics page
        EnqueueInvoiceDiscountAmountForGeneralTab(UnitPrice);
        OpenSalesOrderAndStatistics(SalesOrder, SalesHeader);

        // [THEN] "Invoice Discount Amount" = 500 on Invoicing tab
        Assert.AreEqual(UnitPrice / 2, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountInvoicingTabErr);
        LibraryVariableStorage.AssertEmpty;
        // [THEN] "Inv. Discount Amount Excl. VAT" = 1000 on subtotals part.
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(UnitPrice);

        // [THEN] Line[1]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 333.33
        // [THEN] Line[2]: "Invoice Discount Amount Excl. VAT" = 333.34, "Inv. Disc. Amount to Invoice" = 166.67
        // [THEN] Line[3]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 0
        SalesLine.Ascending(false);
        VerifySalesLines(SalesLine, 1);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsMPHSetInvoiceDiscountInvoicing,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialInvoicedInvoiceDiscountAmountOnStatisticsInvoicingTab()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Sales] [Statistics] [UI]
        // [SCENARIO 218622] Cassie can change invoice discount for partial invoiced sales order on invoicing tab of statistics page.

        // [GIVEN] Sales order with 3 lines
        // [GIVEN] Line[1]: Quantity = 10, "Qty. to Invoice" = 0, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[2]: Quantity = 10, "Qty. to Invoice" = 5, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[3]: Quantity = 10, "Qty. to Invoice" = 10, "Unit Price" = 1000, "Line Amount" = 10000
        Quantity := 10;
        UnitPrice := 1000;
        CreatePartialInvoicingSalesDocumentWithLines(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Quantity, UnitPrice, 2);

        // [GIVEN] Sales order posted => "Qty. to Invoice" changed to remaning quantity in lines
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Validate "Invoice Discount Amount" = 500 on Invoicing tab of Statistics page
        EnqueueInvoiceDiscountAmountForInvoicingTab(UnitPrice);
        OpenSalesOrderAndStatistics(SalesOrder, SalesHeader);

        // [THEN] "Invoice Discount Amount" = 0 on General tab
        Assert.AreEqual(0, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountGeneralTabErr);
        LibraryVariableStorage.AssertEmpty;
        // [THEN] "Inv. Discount Amount Excl. VAT" = 0 on subtotals part.
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(0);

        // [THEN] Line[1]: "Invoice Discount Amount Excl. VAT" = 0, "Inv. Disc. Amount to Invoice" = 333.33
        // [THEN] Line[2]: "Invoice Discount Amount Excl. VAT" = 0, "Inv. Disc. Amount to Invoice" = 166.67
        // [THEN] Line[3]: "Invoice Discount Amount Excl. VAT" = 0, "Inv. Disc. Amount to Invoice" = 0
        SalesLine.Ascending(false);
        VerifySalesLines(SalesLine, 0);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsMPHGetInvoiceDiscountAmounts')]
    [Scope('OnPrem')]
    procedure PurchaseOrderPartialInvoicingInvoiceDiscountAmountOnSubtotals()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Purchase] [Subtotals] [UI]
        // [SCENARIO 218622] Cassie can change invoice discount on partial invoicing purchase order page.

        // [GIVEN] Purchase order with 3 lines
        // [GIVEN] Line[1]: Quantity = 10, "Qty. to Invoice" = 0, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[2]: Quantity = 10, "Qty. to Invoice" = 5, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[3]: Quantity = 10, "Qty. to Invoice" = 10, "Unit Price" = 1000, "Line Amount" = 10000
        Quantity := 10;
        UnitPrice := 1000;
        CreatePartialInvoicingPurchaseDocumentWithLines(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Quantity, UnitPrice, 2);

        // [WHEN] Set "Invoice Discount Amount Excl. VAT" = 1000 at subtotals
        PurchaseOrder.OpenEdit;
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(UnitPrice);

        // [THEN] Line[1]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 0
        // [THEN] Line[2]: "Invoice Discount Amount Excl. VAT" = 333.34, "Inv. Disc. Amount to Invoice" = 166.67
        // [THEN] Line[3]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 333.33
        VerifyPurchaseLines(PurchaseLine, 1);

        // [THEN] "Invoice Discount Amount" on Invoicing tab of Statistics page = 500
        PurchaseOrder.Statistics.Invoke;

        Assert.AreEqual(UnitPrice, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountGeneralTabErr);
        Assert.AreEqual(UnitPrice / 2, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountInvoicingTabErr);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsMPHSetInvoiceDiscountGeneral')]
    [Scope('OnPrem')]
    procedure PurchaseOrderPartialInvoicingInvoiceDiscountAmountOnStatisticsGeneralTab()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Purchase] [Statistics] [UI]
        // [SCENARIO 218622] Cassie can change invoice discount for partial invoicing purchase order on general tab of statistics page.

        // [GIVEN] Purchase order with 3 lines
        // [GIVEN] Line[1]: Quantity = 10, "Qty. to Invoice" = 0, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[2]: Quantity = 10, "Qty. to Invoice" = 5, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[3]: Quantity = 10, "Qty. to Invoice" = 10, "Unit Price" = 1000, "Line Amount" = 10000
        Quantity := 10;
        UnitPrice := 1000;
        CreatePartialInvoicingPurchaseDocumentWithLines(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Quantity, UnitPrice, 2);

        // [WHEN] Cassie validated "Invoice Discount Amount" = 1000 on General tab of Statistics page
        EnqueueInvoiceDiscountAmountForGeneralTab(UnitPrice);
        OpenPurchasOrderAndStatistics(PurchaseOrder, PurchaseHeader);

        // [THEN] "Invoice Discount Amount" = 500 on Invoicing tab
        Assert.AreEqual(UnitPrice / 2, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountInvoicingTabErr);
        LibraryVariableStorage.AssertEmpty;
        // [THEN] "Inv. Disc. Amount Excl. VAT" on subtotals = 1000;
        PurchaseOrder.PurchLines."Invoice Discount Amount".AssertEquals(UnitPrice);

        // [THEN] Line[1]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 0
        // [THEN] Line[2]: "Invoice Discount Amount Excl. VAT" = 333.34, "Inv. Disc. Amount to Invoice" = 166.67
        // [THEN] Line[3]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 333.33
        VerifyPurchaseLines(PurchaseLine, 1);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsMPHSetInvoiceDiscountInvoicing')]
    [Scope('OnPrem')]
    procedure PurchaseOrderPartialInvoicingInvoiceDiscountAmountOnStatisticsInvoicingTab()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Purchase] [Statistics] [UI]
        // [SCENARIO 218622] Cassie can change invoice discount for partial invoicing purchase order on invoicing tab of statistics page.

        // [GIVEN] Purchase order with 3 lines
        // [GIVEN] Line[1]: Quantity = 10, "Qty. to Invoice" = 0, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[2]: Quantity = 10, "Qty. to Invoice" = 5, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[3]: Quantity = 10, "Qty. to Invoice" = 10, "Unit Price" = 1000, "Line Amount" = 10000
        Quantity := 10;
        UnitPrice := 1000;
        CreatePartialInvoicingPurchaseDocumentWithLines(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Quantity, UnitPrice, 2);

        // [WHEN] Validate "Invoice Discount Amount" = 500 on Invoicing tab of Statistics page
        EnqueueInvoiceDiscountAmountForInvoicingTab(UnitPrice);
        OpenPurchasOrderAndStatistics(PurchaseOrder, PurchaseHeader);

        // [THEN] "Invoice Discount Amount" = 1000 on General tab
        Assert.AreEqual(0, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountGeneralTabErr);
        LibraryVariableStorage.AssertEmpty;
        // [THEN] "Inv. Disc. Amount Excl. VAT" on subtotals = 0;
        PurchaseOrder.PurchLines."Invoice Discount Amount".AssertEquals(0);

        // [THEN] Line[1]: "Invoice Discount Amount Excl. VAT" = 0, "Inv. Disc. Amount to Invoice" = 0
        // [THEN] Line[2]: "Invoice Discount Amount Excl. VAT" = 0, "Inv. Disc. Amount to Invoice" = 166.67
        // [THEN] Line[3]: "Invoice Discount Amount Excl. VAT" = 0, "Inv. Disc. Amount to Invoice" = 333.33
        VerifyPurchaseLines(PurchaseLine, 0);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsMPHSetInvoiceDiscountGeneral')]
    [Scope('OnPrem')]
    procedure PurchaseOrderPartialInvoicingInvoiceDiscountAmountOnStatisticsGeneralTabWith11Lines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Purchase] [Statistics] [UI]
        // [SCENARIO 218622] Cassie can change invoice discount for partial invoicing purchase order on general tab of statistics page.

        Quantity := 10;
        UnitPrice := 1000;
        CreatePartialInvoicingPurchaseDocumentWithLines(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Quantity, UnitPrice, 11);

        // [WHEN] Cassie validated "Invoice Discount Amount" = 1000 on General tab of Statistics page
        EnqueueInvoiceDiscountAmountForGeneralTab(UnitPrice);
        OpenPurchasOrderAndStatistics(PurchaseOrder, PurchaseHeader);

        // [THEN] "Invoice Discount Amount" = 500 on Invoicing tab
        Assert.AreEqual(UnitPrice / 2, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountInvoicingTabErr);
        LibraryVariableStorage.AssertEmpty;
        // [THEN] "Inv. Disc. Amount Excl. VAT" on subtotals = 1000;
        PurchaseOrder.PurchLines."Invoice Discount Amount".AssertEquals(UnitPrice);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsMPHGetInvoiceDiscountAmounts,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseOrderPartialInvoicedInvoiceDiscountAmountOnSubtotals()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Purchase] [Subtotals] [UI]
        // [SCENARIO 218622] Cassie can change invoice discount on partial invoiced purchase order page.

        // [GIVEN] Purchase order with 3 lines
        // [GIVEN] Line[1]: Quantity = 10, "Qty. to Invoice" = 0, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[2]: Quantity = 10, "Qty. to Invoice" = 5, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[3]: Quantity = 10, "Qty. to Invoice" = 10, "Unit Price" = 1000, "Line Amount" = 10000
        Quantity := 10;
        UnitPrice := 1000;
        CreatePartialInvoicingPurchaseDocumentWithLines(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Quantity, UnitPrice, 2);

        // [GIVEN] Purchase order posted. "Qty. To Invoice" updated to remaining quantity in lines
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Set "Invoice Discount Amount Excl. VAT" = 1000 at subtotals
        PurchaseOrder.OpenEdit;
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(UnitPrice);

        // [THEN] Line[1]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 333.33
        // [THEN] Line[2]: "Invoice Discount Amount Excl. VAT" = 333.34, "Inv. Disc. Amount to Invoice" = 166.67
        // [THEN] Line[3]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 0
        PurchaseLine.Ascending(false);
        VerifyPurchaseLines(PurchaseLine, 1);

        // [THEN] "Invoice Discount Amount" on Invoicing tab of Statistics page = 500
        PurchaseOrder.Statistics.Invoke;

        Assert.AreEqual(UnitPrice, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountGeneralTabErr);
        Assert.AreEqual(UnitPrice / 2, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountInvoicingTabErr);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsMPHSetInvoiceDiscountGeneral,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseOrderPartialInvoicedInvoiceDiscountAmountOnStatisticsGeneralTab()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Purchase] [Statistics] [UI]
        // [SCENARIO 218622] Cassie can change invoice discount for partial invoiced purchase order on general tab of statistics page.

        // [GIVEN] Purchase order with 3 lines
        // [GIVEN] Line[1]: Quantity = 10, "Qty. to Invoice" = 0, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[2]: Quantity = 10, "Qty. to Invoice" = 5, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[3]: Quantity = 10, "Qty. to Invoice" = 10, "Unit Price" = 1000, "Line Amount" = 10000
        Quantity := 10;
        UnitPrice := 1000;
        CreatePartialInvoicingPurchaseDocumentWithLines(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Quantity, UnitPrice, 2);

        // [GIVEN] Purchase order posted. "Qty. To Invoice" updated to remaining quantity in lines
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Cassie validated "Invoice Discount Amount" = 1000 on General tab of Statistics page
        EnqueueInvoiceDiscountAmountForGeneralTab(UnitPrice);
        OpenPurchasOrderAndStatistics(PurchaseOrder, PurchaseHeader);

        // [THEN] "Invoice Discount Amount" = 500 on Invoicing tab
        Assert.AreEqual(UnitPrice / 2, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountInvoicingTabErr);
        LibraryVariableStorage.AssertEmpty;
        // [THEN] "Inv. Disc. Amount Excl. VAT" on subtotals = 1000;
        PurchaseOrder.PurchLines."Invoice Discount Amount".AssertEquals(UnitPrice);

        // [THEN] Line[1]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 333.33
        // [THEN] Line[2]: "Invoice Discount Amount Excl. VAT" = 333.34, "Inv. Disc. Amount to Invoice" = 166.67
        // [THEN] Line[3]: "Invoice Discount Amount Excl. VAT" = 333.33, "Inv. Disc. Amount to Invoice" = 0
        PurchaseLine.Ascending(false);
        VerifyPurchaseLines(PurchaseLine, 1);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsMPHSetInvoiceDiscountInvoicing,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseOrderPartialInvoicedInvoiceDiscountAmountOnStatisticsInvoicingTab()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Purchase] [Statistics] [UI]
        // [SCENARIO 218622] Cassie can change invoice discount for partial invoiced purchase order on invoicing tab of statistics page.

        // [GIVEN] Purchase order with 3 lines
        // [GIVEN] Line[1]: Quantity = 10, "Qty. to Invoice" = 0, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[2]: Quantity = 10, "Qty. to Invoice" = 5, "Unit Price" = 1000, "Line Amount" = 10000
        // [GIVEN] Line[3]: Quantity = 10, "Qty. to Invoice" = 10, "Unit Price" = 1000, "Line Amount" = 10000
        Quantity := 10;
        UnitPrice := 1000;
        CreatePartialInvoicingPurchaseDocumentWithLines(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Quantity, UnitPrice, 2);

        // [GIVEN] Purchase order posted. "Qty. To Invoice" updated to remaining quantity in lines
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Validate "Invoice Discount Amount" = 500 on Invoicing tab of Statistics page
        EnqueueInvoiceDiscountAmountForInvoicingTab(UnitPrice);
        OpenPurchasOrderAndStatistics(PurchaseOrder, PurchaseHeader);

        // [THEN] "Invoice Discount Amount" = 0 on General tab
        Assert.AreEqual(0, LibraryVariableStorage.DequeueDecimal, InvoiceDiscountGeneralTabErr);
        LibraryVariableStorage.AssertEmpty;
        // [THEN] "Inv. Disc. Amount Excl. VAT" on subtotals = 0;
        PurchaseOrder.PurchLines."Invoice Discount Amount".AssertEquals(0);

        // [THEN] Line[1]: "Invoice Discount Amount Excl. VAT" = 0, "Inv. Disc. Amount to Invoice" = 333.33
        // [THEN] Line[2]: "Invoice Discount Amount Excl. VAT" = 0, "Inv. Disc. Amount to Invoice" = 166.67
        // [THEN] Line[3]: "Invoice Discount Amount Excl. VAT" = 0, "Inv. Disc. Amount to Invoice" = 0
        PurchaseLine.Ascending(false);
        VerifyPurchaseLines(PurchaseLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Invoice Disc. Distribution");
        if IsInitialized then
            exit;

        IsInitialized := true;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Invoice Disc. Distribution");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateFAPostingType();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Invoice Disc. Distribution");
    end;

    local procedure CreatePartialInvoicingSalesDocumentWithLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemQauntity: Decimal; UnitPrice: Decimal; Lines: Integer)
    var
        ItemNo: Code[20];
        Index: Integer;
        "Count": Integer;
    begin
        Count := Lines;
        ItemNo := LibraryInventory.CreateItemNo();
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo);
        for Index := 0 to Count do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ItemQauntity);

            SalesLine.Validate("Unit Price", UnitPrice);
            SalesLine.Validate("Qty. to Invoice", Round(SalesLine.Quantity * Index / Count, LibraryERM.GetAmountRoundingPrecision));
            SalesLine.Modify(true);
        end;

        SalesHeader.SetRecFilter();

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
    end;

    local procedure CreatePartialInvoicingPurchaseDocumentWithLines(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemQauntity: Decimal; DirectUnitCost: Decimal; Lines: Integer)
    var
        ItemNo: Code[20];
        Index: Integer;
        "Count": Integer;
    begin
        Count := Lines;
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo);
        for Index := 0 to Count do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, ItemQauntity);

            PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
            PurchaseLine.Validate("Qty. to Invoice", Round(PurchaseLine.Quantity * Index / Count, LibraryERM.GetAmountRoundingPrecision));
            PurchaseLine.Modify(true);
        end;

        PurchaseHeader.SetRecFilter();

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
    end;

    local procedure EnqueueInvoiceDiscountAmountForGeneralTab(InvoiceDiscountAmount: Decimal)
    begin
        LibraryVariableStorage.Enqueue(InvoiceDiscountAmount);
    end;

    local procedure EnqueueInvoiceDiscountAmountForInvoicingTab(InvoiceDiscountAmount: Decimal)
    begin
        LibraryVariableStorage.Enqueue(InvoiceDiscountAmount / 2);
    end;

    local procedure OpenSalesOrderAndStatistics(var SalesOrder: TestPage "Sales Order"; var SalesHeader: Record "Sales Header")
    begin
        SalesOrder.OpenEdit;
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.Statistics.Invoke;
    end;

    local procedure OpenPurchasOrderAndStatistics(var PurchaseOrder: TestPage "Purchase Order"; var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseOrder.OpenEdit;
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.Statistics.Invoke;
    end;

    local procedure VerifySalesLines(var SalesLine: Record "Sales Line"; Multiplier: Decimal)
    begin
        with SalesLine do begin
            FindSet();
            VerifySalesLineInvoiceDiscountAmounts(SalesLine, 333.33 * Multiplier, 0);
            Next;
            VerifySalesLineInvoiceDiscountAmounts(SalesLine, 333.34 * Multiplier, 333.34 / 2);
            Next;
            VerifySalesLineInvoiceDiscountAmounts(SalesLine, 333.33 * Multiplier, 333.33);
        end;
    end;

    local procedure VerifySalesLineInvoiceDiscountAmounts(SalesLine: Record "Sales Line"; ExpectedInvoiceDiscount: Decimal; ExpectedInvoiceDiscountToInvoice: Decimal)
    begin
        SalesLine.TestField("Inv. Discount Amount", ExpectedInvoiceDiscount);
        SalesLine.TestField("Inv. Disc. Amount to Invoice", ExpectedInvoiceDiscountToInvoice);
    end;

    local procedure VerifyPurchaseLines(var PurchaseLine: Record "Purchase Line"; Multiplier: Decimal)
    begin
        with PurchaseLine do begin
            FindSet();
            VerifyPurchaseLineInvoiceDiscountAmounts(PurchaseLine, 333.33 * Multiplier, 0);
            Next;
            VerifyPurchaseLineInvoiceDiscountAmounts(PurchaseLine, 333.34 * Multiplier, 333.34 / 2);
            Next;
            VerifyPurchaseLineInvoiceDiscountAmounts(PurchaseLine, 333.33 * Multiplier, 333.33);
        end;
    end;

    local procedure VerifyPurchaseLineInvoiceDiscountAmounts(PurchaseLine: Record "Purchase Line"; ExpectedInvoiceDiscount: Decimal; ExpectedInvoiceDiscountToInvoice: Decimal)
    begin
        PurchaseLine.TestField("Inv. Discount Amount", ExpectedInvoiceDiscount);
        PurchaseLine.TestField("Inv. Disc. Amount to Invoice", ExpectedInvoiceDiscountToInvoice);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsMPHGetInvoiceDiscountAmounts(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        LibraryVariableStorage.Enqueue(SalesOrderStatistics.InvDiscountAmount_General.AsDEcimal);
        LibraryVariableStorage.Enqueue(SalesOrderStatistics.InvDiscountAmount_Invoicing.AsDEcimal);
        SalesOrderStatistics.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsMPHSetInvoiceDiscountGeneral(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.InvDiscountAmount_General.SetValue(LibraryVariableStorage.DequeueDecimal);
        LibraryVariableStorage.Enqueue(SalesOrderStatistics.InvDiscountAmount_Invoicing.AsDEcimal);
        SalesOrderStatistics.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsMPHSetInvoiceDiscountInvoicing(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.InvDiscountAmount_Invoicing.SetValue(LibraryVariableStorage.DequeueDecimal);
        LibraryVariableStorage.Enqueue(SalesOrderStatistics.InvDiscountAmount_General.AsDEcimal);
        SalesOrderStatistics.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsMPHGetInvoiceDiscountAmounts(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        LibraryVariableStorage.Enqueue(PurchaseOrderStatistics.InvDiscountAmount_General.AsDEcimal);
        LibraryVariableStorage.Enqueue(PurchaseOrderStatistics.InvDiscountAmount_Invoicing.AsDEcimal);
        PurchaseOrderStatistics.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsMPHSetInvoiceDiscountGeneral(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.InvDiscountAmount_General.SetValue(LibraryVariableStorage.DequeueDecimal);
        LibraryVariableStorage.Enqueue(PurchaseOrderStatistics.InvDiscountAmount_Invoicing.AsDEcimal);
        PurchaseOrderStatistics.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsMPHSetInvoiceDiscountInvoicing(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.InvDiscountAmount_Invoicing.SetValue(LibraryVariableStorage.DequeueDecimal);
        LibraryVariableStorage.Enqueue(PurchaseOrderStatistics.InvDiscountAmount_General.AsDEcimal);
        PurchaseOrderStatistics.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

