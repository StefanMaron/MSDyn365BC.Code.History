codeunit 142092 "ERM Sales/Purchase Tax III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [Sales Tax]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMTax: Codeunit "Library - ERM Tax";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        DummyTaxCountry: Option US,CA;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtAndInvDiscEqualsTo100Pct_PrepmtExclTax()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Sales]
        // [SCENARIO 229419] Sales order post in case of prepayment, invoice discount (prepayment % + discount % = 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = FALSE
        Initialize;
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Sales order with prepayment (85%), invoice discount (15%), several lines with different tax setup
        CreateSalesOrder_TFS229419(SalesHeader, 15, 85, false);
        VerifySalesHeaderTotals(SalesHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, 31.02);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtAndInvDiscEqualsTo100Pct_PrepmtInclTax()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Sales]
        // [SCENARIO 229419] Sales order post in case of prepayment, invoice discount (prepayment % + discount % = 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = TRUE
        Initialize;
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Sales order with prepayment (85%), invoice discount (15%), several lines with different tax setup
        CreateSalesOrder_TFS229419(SalesHeader, 15, 85, true);
        VerifySalesHeaderTotals(SalesHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, AmountIncludingVAT, -31.02, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtAndInvDiscMoreThan100Pct_PrepmtExclTax()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Sales]
        // [SCENARIO 229419] Sales order post in case of prepayment, invoice discount (prepayment % + discount % > 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = FALSE
        Initialize;
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Sales order with prepayment (85.01%), invoice discount (15%), several lines with different tax setup
        CreateSalesOrder_TFS229419(SalesHeader, 15, 85.01, false);
        VerifySalesHeaderTotals(SalesHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, 31.02);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtAndInvDiscMoreThan100Pct_PrepmtInclTax()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Sales]
        // [SCENARIO 229419] Sales order post in case of prepayment, invoice discount (prepayment % + discount % > 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = TRUE
        Initialize;
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Sales order with prepayment (85.01%), invoice discount (15%), several lines with different tax setup
        CreateSalesOrder_TFS229419(SalesHeader, 15, 85.01, true);
        VerifySalesHeaderTotals(SalesHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, AmountIncludingVAT, -31.02, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtAndInvDiscEqualsTo100Pct_PrepmtExclTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Purchase]
        // [SCENARIO 229419] Purchase order post in case of prepayment, invoice discount (prepayment % + discount % = 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = FALSE
        Initialize;
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Purchase order with prepayment (85%), invoice discount (15%), several lines with different tax setup
        CreatePurchaseOrder_TFS229419(PurchaseHeader, 15, 85, false);
        VerifyPurchaseHeaderTotals(PurchaseHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, 31.02);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtAndInvDiscEqualsTo100Pct_PrepmtInclTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Purchase]
        // [SCENARIO 229419] Purchase order post in case of prepayment, invoice discount (prepayment % + discount % = 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = TRUE
        Initialize;
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Purchase order with prepayment (85%), invoice discount (15%), several lines with different tax setup
        CreatePurchaseOrder_TFS229419(PurchaseHeader, 15, 85, true);
        VerifyPurchaseHeaderTotals(PurchaseHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, AmountIncludingVAT, -31.02, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtAndInvDiscMoreThan100Pct_PrepmtExclTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Purchase]
        // [SCENARIO 229419] Purchase order post in case of prepayment, invoice discount (prepayment % + discount % > 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = FALSE
        Initialize;
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Purchase order with prepayment (85.01%), invoice discount (15%), several lines with different tax setup
        CreatePurchaseOrder_TFS229419(PurchaseHeader, 15, 85.01, false);
        VerifyPurchaseHeaderTotals(PurchaseHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, 31.02);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtAndInvDiscMoreThan100Pct_PrepmtInclTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Purchase]
        // [SCENARIO 229419] Purchase order post in case of prepayment, invoice discount (prepayment % + discount % > 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = TRUE
        Initialize;
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Purchase order with prepayment (85.01%), invoice discount (15%), several lines with different tax setup
        CreatePurchaseOrder_TFS229419(PurchaseHeader, 15, 85.01, true);
        VerifyPurchaseHeaderTotals(PurchaseHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, AmountIncludingVAT, -31.02, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceTwoLinesProvTaxExpenseCapitalize()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        NoTaxAreaCode: Code[20];
        TaxAreaCode: Code[20];
        ProvTaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        GLAccountNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 231225] Purchase invoice posting in case of two lines and three tax areas: NOTAX, TAX, Provincial TAX,
        // [SCENARIO 231225] where Provincial TAX has several tax justisdictions invlucding Expense/Capitalize
        Initialize;

        // [GIVEN] "NOTAX", "TAX" ("Tax Below Maximum" = 5), "PROVTAX" ("Tax Below Maximum" = 1.6\3.4\0.56\7.44, where 1.6\0.56 have Expense/Capitalize = TRUE) areas
        CreateTaxSetup_TFS231225(NoTaxAreaCode, TaxAreaCode, ProvTaxAreaCode, TaxGroupCode);
        // [GIVEN] Purchase invoice with header's "Tax Area Code" = NOTAX and two lines:
        // [GIVEN] line1: Type = "G/L Account", "No." = "GLACC1", "Tax Area Code" = TAX, "Provincial Tax Area Code" = "", "Direct Unit Cost" = 100
        // [GIVEN] line2: Type = "G/L Account", "No." = "GLACC2", "Tax Area Code" = NOTAX, "Provincial Tax Area Code" = "PROVTAX", "Direct Unit Cost" = 300
        CreatePurchaseHeader(PurchaseHeader, LibraryPurchase.CreateVendorWithVATBusPostingGroup(''), NoTaxAreaCode, 0, false);
        GLAccountNo[1] := CreateGLAccountNoWithBlankVATSetup;
        CreatePurchaseLineGLWithProvincialTax(PurchaseHeader, GLAccountNo[1], TaxAreaCode, TaxGroupCode, '', 100);
        GLAccountNo[2] := CreateGLAccountNoWithBlankVATSetup;
        CreatePurchaseLineGLWithProvincialTax(PurchaseHeader, GLAccountNo[2], NoTaxAreaCode, TaxGroupCode, ProvTaxAreaCode, 300);

        // [WHEN] Post the invoice
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [THEN] Posted invoice has Amount = 400, Amount Including VAT = 405
        // [THEN] There is GLEntry with "G/L Account No." = "GLACC1", "Amount" = 100
        // [THEN] There is GLEntry with "G/L Account No." = "GLACC2", "Amount" = 306.48
        VerifyPostedPurchaseInvoiceTotals(PurchInvHeader, 400, 405);
        VerifyGLEntry(PurchInvHeader."No.", GLAccountNo[1], 100);
        VerifyGLEntry(PurchInvHeader."No.", GLAccountNo[2], 306.48);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,GetReceiptLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure TaxCalculationAfterGetReceipLinesOnPurcaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        VendorNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Expense/Capitalize] [Get Receipt Lines]
        // [SCENARIO 233346] Incorrect Tax Amount on the Purchase Invoice subform after Getting Receipt Lines from received not invoiced Purchase Order with "Expense/Capitalize" = TRUE in Tax Details
        Initialize;

        // [GIVEN] Tax area "BC" with "Country/Region" = CA having two lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Received not invoiced Purchase Order for Vendor "V", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        // [GIVEN] Purchase Line with Tax Amount = 100
        CreateCustomPurchaseDocWithOneLine_TFS233346(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, TaxAreaCode, TaxGroupCode[1], '');
        ValidatePurchaseOrderTaxAreaThroughPage(PurchaseHeader, TaxAreaCode);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine.Type::"G/L Account");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;

        // [GIVEN] Purchase Invoice for Vendor "V", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        CreatePurchaseHeaderWithTaxAreaForVendor(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', TaxAreaCode, VendorNo);

        // [WHEN] Get Receipt Lines
        PurchaseInvoice.OpenEdit;
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.PurchLines.GetReceiptLines.Invoke;

        // [THEN] "Total VAT" on the Purchase Invoice page = 100
        PurchaseInvoice.PurchLines."Total VAT Amount".AssertEquals(VATAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,GetReturnShipmentLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure TaxCalculationAfterGetReturnShipmentLinesOnPurcaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        VendorNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Expense/Capitalize] [Get Return Shipment Lines]
        // [SCENARIO 233346] Incorrect Tax Amount on the Purchase Cr. Memo subform after Getting Return Shipment Lines from shipped not invoiced Purchase Cr. Memo with "Expense/Capitalize" = TRUE in Tax Details
        Initialize;

        // [GIVEN] Tax area "BC" with "Country/Region" = CA having two lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Shipped not invoiced Purchase Return Order for Vendor "V", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        // [GIVEN] Purchase Line with Tax Amount = 100
        CreateCustomPurchaseDocWithOneLine_TFS233346(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", TaxAreaCode, TaxGroupCode[1], '');
        ValidatePurchaseReturnOrderTaxAreaThroughPage(PurchaseHeader, TaxAreaCode);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine.Type::"G/L Account");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;

        // [GIVEN] Purchase Credit Memo for Vendor "V", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        CreatePurchaseHeaderWithTaxAreaForVendor(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", '', TaxAreaCode, VendorNo);

        // [WHEN] Get Return Shipment Lines
        PurchaseCreditMemo.OpenEdit;
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.PurchLines.GetReturnShipmentLines.Invoke;

        // [THEN] "Total VAT" on the Purchase Credit Memo page = 100
        PurchaseCreditMemo.PurchLines."Total VAT Amount".AssertEquals(VATAmount);
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure TaxCalculationAfterGetShipmentLinesOnSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        CustNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Expense/Capitalize] [Get Shipment Lines]
        // [SCENARIO 233346] Incorrect Tax Amount on the Sales Invoice Subform after Getting Shipment Lines from shipped not invoiced Sales Order with "Expense/Capitalize" = TRUE in Tax Details
        Initialize;

        // [GIVEN] Tax area "BC" with "Country/Region" = CA having two lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Shipped not invoiced Sales Order for Customer "C", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        // [GIVEN] Sales Line with Tax Amount = 100
        CreateCustomSalesDocWithOneLine_TFS233346(
          SalesHeader, SalesHeader."Document Type"::Order, TaxAreaCode, TaxGroupCode[1], '');
        ValidateSalesOrderTaxAreaThroughPage(SalesHeader, TaxAreaCode);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        CustNo := SalesHeader."Sell-to Customer No.";
        VATAmount := SalesLine."Amount Including VAT" - SalesLine.Amount;

        // [GIVEN] Sales Invoice for Customer "C", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        CreateSalesHeaderWithTaxAreaForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, '', TaxAreaCode, CustNo);

        // [WHEN] Get Shipment Lines
        SalesInvoice.OpenEdit;
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.SalesLines.GetShipmentLines.Invoke;

        // [THEN] "Total VAT" on the Sales Invoice page = 100
        SalesInvoice.SalesLines."Total VAT Amount".AssertEquals(VATAmount);
    end;

    [Test]
    [HandlerFunctions('GetReturnReceiptLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure TaxCalculationAfterGetReturnReceiptLinesOnSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        CustNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Expense/Capitalize] [Get Return Receipt Lines]
        // [SCENARIO 233346] Incorrect Tax Amount on the Sales Cr. Memo Subform after Getting Return Receipt Lines from Received not invoiced Sales Return Order with "Expense/Capitalize" = TRUE in Tax Details
        Initialize;

        // [GIVEN] Tax area "BC" with "Country/Region" = CA having two lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Received not invoiced Sales Return Order for Customer "C", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        // [GIVEN] Sales Line with Tax Amount = 100
        CreateCustomSalesDocWithOneLine_TFS233346(
          SalesHeader, SalesHeader."Document Type"::"Return Order", TaxAreaCode, TaxGroupCode[1], '');
        ValidateSalesReturnOrderTaxAreaThroughPage(SalesHeader, TaxAreaCode);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        CustNo := SalesHeader."Sell-to Customer No.";
        VATAmount := SalesLine."Amount Including VAT" - SalesLine.Amount;

        // [GIVEN] Sales Credit Memo for Customer "C", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        CreateSalesHeaderWithTaxAreaForCustomer(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '', TaxAreaCode, CustNo);

        // [WHEN] Get Return Receipt Lines
        SalesCreditMemo.OpenEdit;
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.SalesLines."Get Return &Receipt Lines".Invoke;

        // [THEN] "Total VAT" on the Sales Credit Memo page = 100
        SalesCreditMemo.SalesLines."Total VAT Amount".AssertEquals(VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmt25PctCustomAmountsIncludeTax()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
    begin
        // [FEATURE] [Prepayment] [Rounding] [Sales]
        // [SCENARIO 262985] Sales order post in case of 25% prepayment, several lines with custom amount, prepayment include tax
        Initialize;

        // [GIVEN] Sales order with 25% prepayment, several lines with custom amount, prepayment include tax
        CreateSalesOrder_TFS262985(SalesHeader);
        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Invoice has been posted
        VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, 2008.68, 5101.55, 6025.88);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmt25PctCustomAmountsIncludeTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
    begin
        // [FEATURE] [Prepayment] [Rounding] [Purchase]
        // [SCENARIO 262985] Purchase order post in case of 25% prepayment, several lines with custom amount, prepayment include tax
        Initialize;

        // [GIVEN] Purchase order with 25% prepayment, several lines with custom amount, prepayment include tax
        CreatePurchaseOrder_TFS262985(PurchaseHeader);
        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] Invoice has been posted
        VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, 2008.68, 5101.55, 6025.88);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchExpenseCapitalizePositiveAndNegativeLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [Rounding] [Purchase] [Negative Line] [Expense/Capitalize]
        // [SCENARIO 273130] Posting purchase invoice with positive and negative lines, custom Tax setup having Expense/Capitalize, amounts with rounding
        Initialize;

        // [GIVEN] Purchase invoice with positive and negative line, Expense/Capitalize Tax setup, custom amounts with rounding (Total Tax = -829.035)
        CreatePurchaseOrder_TFS273130(PurchaseHeader);
        VerifyPurchaseVATTotalAfterRelease(PurchaseHeader, -829.04);

        // [WHEN] Post the invoice
        PurchInvHeader.Get(PostPurchaseDocument(PurchaseHeader));

        // [THEN] The invoice has been posted
        VerifyPostedPurchaseInvoiceTotals(PurchInvHeader, 1685, 855.96);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesExpenseCapitalizePositiveAndNegativeLine()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Rounding] [Sales] [Negative Line] [Expense/Capitalize]
        // [SCENARIO 273130] Posting sales invoice with positive and negative lines, custom Tax setup having Expense/Capitalize, amounts with rounding
        Initialize;

        // [GIVEN] Sales invoice with positive and negative line, Expense/Capitalize Tax setup, custom amounts with rounding (Total Tax = -829.035)
        CreateSalesOrder_TFS273130(SalesHeader);
        VerifySalesVATTotalAfterRelease(SalesHeader, -829.04);

        // [WHEN] Post the invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] The invoice has been posted
        VerifyPostedSalesInvoiceTotals(SalesInvoiceHeader, 1685, 855.96);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithPositiveAndNegativeLine_US()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Negative Line]
        // [SCENARIO 280515] Posting of sales order with positive and negative lines, custom Tax setup (Country = US)
        Initialize;

        // [GIVEN] Sales order with positive and negative lines, custom amounts with rounding (Total Tax = 21.155)
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);
        CreateSalesOrder_TFS280515(SalesHeader, TaxAreaCode, TaxGroupCode);

        // [WHEN] Post the order
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] The order has been posted
        VerifyPostedSalesInvoiceTotals(SalesInvoiceHeader, 423.1, 444.26);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithPositiveAndNegativeLine_US()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Negative Line]
        // [SCENARIO 280515] Posting of purchase order with positive and negative lines, custom Tax setup (Country = US)
        Initialize;

        // [GIVEN] Purchase order with positive and negative lines, custom amounts with rounding (Total Tax = 21.155)
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);
        CreatePurchaseOrder_TFS280515(PurchaseHeader, TaxAreaCode, TaxGroupCode);

        // [WHEN] Post the order
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [THEN] The order has been posted
        VerifyPostedPurchaseInvoiceTotals(PurchInvHeader, 423.1, 444.26);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithPositiveAndNegativeLine_US()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Rounding] [Service] [Negative Line]
        // [SCENARIO 280515] Posting of service order with positive and negative lines, custom Tax setup (Country = US)
        Initialize;

        // [GIVEN] Service order with positive and negative lines, custom amounts with rounding (Total Tax = 21.155)
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);
        CreateServiceOrder_TFS280515(ServiceHeader, TaxAreaCode, TaxGroupCode);

        // [WHEN] Post the order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] The order has been posted
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader);
        VerifyPostedServiceInvoiceTotals(ServiceInvoiceHeader, 423.1, 444.26);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithPositiveAndNegativeLine_CA()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Negative Line]
        // [SCENARIO 280515] Posting of sales order with positive and negative lines, custom Tax setup (Country = CA)
        Initialize;

        // [GIVEN] Sales order with positive and negative lines, custom amounts with rounding (Total Tax = 21.155)
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        CreateSalesOrder_TFS280515(SalesHeader, TaxAreaCode, TaxGroupCode);

        // [WHEN] Post the order
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] The order has been posted
        VerifyPostedSalesInvoiceTotals(SalesInvoiceHeader, 423.1, 444.26);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithPositiveAndNegativeLine_CA()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Negative Line]
        // [SCENARIO 280515] Posting of purchase order with positive and negative lines, custom Tax setup (Country = CA)
        Initialize;

        // [GIVEN] Purchase order with positive and negative lines, custom amounts with rounding (Total Tax = 21.155)
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        CreatePurchaseOrder_TFS280515(PurchaseHeader, TaxAreaCode, TaxGroupCode);

        // [WHEN] Post the order
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [THEN] The order has been posted
        VerifyPostedPurchaseInvoiceTotals(PurchInvHeader, 423.1, 444.26);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithPositiveAndNegativeLine_CA()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Rounding] [Service] [Negative Line]
        // [SCENARIO 280515] Posting of service order with positive and negative lines, custom Tax setup (Country = CA)
        Initialize;

        // [GIVEN] Service order with positive and negative lines, custom amounts with rounding (Total Tax = 21.155)
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        CreateServiceOrder_TFS280515(ServiceHeader, TaxAreaCode, TaxGroupCode);

        // [WHEN] Post the order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] The order has been posted
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader);
        VerifyPostedServiceInvoiceTotals(ServiceInvoiceHeader, 423.1, 444.26);
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceRPH')]
    [Scope('OnPrem')]
    procedure TaxCalculationInDraftSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Draft Sales Invoice]
        // [SCENARIO 283166] Draft Sales Invoice in case of Tax Country = CA, two taxes from different jurisdictions
        Initialize;

        // [GIVEN] Tax setup with "Country/Region" = CA and two different jurisdictions with 5% and 7% taxes
        CreateTaxSetup_TFS283166(TaxAreaCode, TaxGroupCode);

        // [GIVEN] Sales Header with custom tax setup and sales line with unit price equal to 77024.70
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerWithTaxArea(TaxAreaCode));
        with SalesLine do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type::"G/L Account", LibraryERM.CreateGLAccountNo, 1);
            Validate("Unit Price", 77024.7);
            Validate("Tax Group Code", TaxGroupCode);
            Modify(true);
        end;

        // [WHEN] Report is run
        SalesHeader.SetRecFilter;
        Commit();
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] TotalAmountIncludingVAT in report equals to 86267.67
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('TotalAmountIncludingVAT', 86267.67);
    end;

    [Test]
    [HandlerFunctions('SalesQuoteRPH')]
    [Scope('OnPrem')]
    procedure TaxCalculationInSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Sales Quote]
        // [SCENARIO 283166] Sales Quote in case of Tax Country = CA, two taxes from different jurisdictions
        Initialize;

        // [GIVEN] Tax setup with "Country/Region" = CA and two different jurisdictions with 5% and 7% taxes
        CreateTaxSetup_TFS283166(TaxAreaCode, TaxGroupCode);

        // [GIVEN] Sales Header with custom tax setup and sales line with unit price equal to 77024.70
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CreateCustomerWithTaxArea(TaxAreaCode));
        with SalesLine do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type::"G/L Account", LibraryERM.CreateGLAccountNo, 1);
            Validate("Unit Price", 77024.7);
            Validate("Tax Group Code", TaxGroupCode);
            Modify(true);
        end;

        // [WHEN] Report is run
        SalesHeader.SetRecFilter;
        Commit();
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);

        // [THEN] TotalAmountIncludingVAT in report equals to 86267.67
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('TotalAmountIncludingVAT', 86267.67);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TaxCalculationBeforeEffectiveDateOnSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Effective Date]
        // [SCENARIO 300462] Tax Amounts recalculated when set Posting Date before Effective Date of Tax Details in Sales Invoice
        Initialize;

        // [GIVEN] Sales Invoice with Amount = 100 and Tax = 5% with Effective Date = 01-01-19
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerWithTaxArea(TaxAreaCode));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountNo, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.FindFirst;

        // [WHEN] Set Posting Date 31-12-18 on Sales Invoice
        SalesHeader.Validate("Posting Date", TaxDetail."Effective Date" - 1);
        SalesHeader.Modify(true);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // [THEN] Sales Line has VAT % = 0 and "Amount Including VAT" = Amount of 100.
        SalesLine.Find;
        SalesLine.TestField("VAT %", 0);
        SalesLine.TestField("Amount Including VAT", SalesLine.Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TaxCalculationBeforeEffectiveDateOnPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TotalPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Effective Date]
        // [SCENARIO 300462] Tax Amounts recalculated when set Posting Date before Effective Date of Tax Details in Purchase Invoice
        Initialize;

        // [GIVEN] Purchase Invoice with Amount = 100 and Tax = 5% with Effective Date = 01-01-19
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);
        CreatePurchaseHeaderWithTaxAreaForVendor(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', TaxAreaCode,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(''));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccountNoWithBlankVATSetup, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.FindFirst;

        // [WHEN] Set Posting Date 31-12-18 on Purchase Invoice
        PurchaseHeader.Validate("Posting Date", TaxDetail."Effective Date" - 1);
        PurchaseHeader.Modify(true);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchaseLine);

        // [THEN] Purchase Line has VAT % = 0 and "Amount Including VAT" = Amount of 100.
        PurchaseLine.Find;
        PurchaseLine.TestField("VAT %", 0);
        PurchaseLine.TestField("Amount Including VAT", PurchaseLine.Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TaxLiablePerSalesLine()
    var
        Customer: Record Customer;
        ShipToAddressNoTax: Record "Ship-to Address";
        ShipToAddressTaxLiable: Record "Ship-to Address";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        VATEntry: Record "VAT Entry";
        ItemNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        SalesInvoiceNo: Code[20];
        TaxPercent: Decimal;
        SalesOrderAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Invoice] [Combine Shipments]
        // [SCENARIO 334744] Only sales lines up to Tax Liable are included in tax calculation.
        Initialize();
        TaxPercent := LibraryRandom.RandInt(10);

        // [GIVEN] Tax area code "TA", Tax group code = "TG", Tax = 3%.
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        TaxJurisdiction.Get(LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_CA());
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdiction.Code);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxPercent);

        // [GIVEN] A customer with tax area code "TA" and set up for combine shipments.
        Customer.Get(CreateCustomerWithTaxArea(TaxAreaCode));
        Customer.Validate("Combine Shipments", true);
        Customer.Modify(true);

        // [GIVEN] Ship-to address "ADDR1" with "Tax Liable" = FALSE.
        // [GIVEN] Ship-to address "ADDR2" with "Tax Liable" = TRUE.
        LibrarySales.CreateShipToAddress(ShipToAddressNoTax, Customer."No.");
        LibrarySales.CreateShipToAddress(ShipToAddressTaxLiable, Customer."No.");
        ShipToAddressTaxLiable.Validate("Tax Liable", true);
        ShipToAddressTaxLiable.Modify(true);

        // [GIVEN] A new item.
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Create two sales orders with tax area "TA" and tax group code "TG".
        // [GIVEN] The difference is that the first order has ship-to address "ADDR1" (no tax), and the second one - "ADDR2" (with tax).
        // [GIVEN] Amount incl. VAT of the first order = 100 LCY.
        CreateAndShipSalesOrderWithShipToAddr(SalesHeader, Customer."No.", ShipToAddressNoTax.Code, ItemNo, TaxGroupCode);
        SalesOrderAmount[1] := SalesHeader."Amount Including VAT";

        // [GIVEN] Amount incl. VAT of the second order = 110 LCY (100 line amount + 10 tax).
        // [GIVEN] Post both orders as ship.
        CreateAndShipSalesOrderWithShipToAddr(SalesHeader, Customer."No.", ShipToAddressTaxLiable.Code, ItemNo, TaxGroupCode);
        SalesOrderAmount[2] := SalesHeader."Amount Including VAT";

        // [GIVEN] Run "Combine shipments" to create a single invoice from both shipments.
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesShipmentHeader.SetRange("Sell-to Customer No.", Customer."No.");
        LibrarySales.CombineShipments(SalesHeader, SalesShipmentHeader, WorkDate, WorkDate, false, false, false, false);

        // [WHEN] Post the sales invoice.
        SalesHeaderInvoice.SetRange("Document Type", SalesHeaderInvoice."Document Type"::Invoice);
        SalesHeaderInvoice.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeaderInvoice.FindFirst();
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true);

        // [THEN] Invoiced amount = 210 LCY (100 + 110).
        Customer.CalcFields("Net Change");
        asserterror Customer.TestField("Net Change", SalesOrderAmount[1] + SalesOrderAmount[2]);

        // [THEN] VAT entry is created for the taxed amount only.
        // [THEN] "VAT Entry".Base = 100.
        // [THEN] "VAT Entry".Amount = 10.
        VATEntry.SetRange("Document No.", SalesInvoiceNo);
        Assert.RecordCount(VATEntry, 1);
        VATEntry.FindFirst();
        asserterror Assert.AreNearlyEqual(-SalesOrderAmount[2] / (1 + TaxPercent / 100), VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), '');
        asserterror Assert.AreEqual(-SalesOrderAmount[2] - VATEntry.Base, VATEntry.Amount, '');

        // [THEN] 10 LCY is posted on tax account to the general ledger.
        VerifyGLEntry(SalesInvoiceNo, TaxJurisdiction."Tax Account (Sales)", VATEntry.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxLiablePerPurchaseLine()
    var
        Vendor: Record Vendor;
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        VATEntry: Record "VAT Entry";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        ItemNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        PurchInvoiceNo: Code[20];
        TaxPercent: Decimal;
        PurchOrderAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [Get Receipt Lines]
        // [SCENARIO 334744] Only purchase lines up to Tax Liable are included in tax calculation.
        Initialize();
        TaxPercent := LibraryRandom.RandInt(10);

        // [GIVEN] Tax area code "TA", Tax group code = "TG", Tax = 3%.
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        TaxJurisdiction.Get(LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_CA());
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdiction.Code);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxPercent);

        // [GIVEN] A vendor with tax area code "TA".
        Vendor.Get(CreateVendorWithTaxArea(TaxAreaCode));

        // [GIVEN] A new item.
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Create two purchase orders with tax area "TA" and tax group code "TG".
        // [GIVEN] The first order is tax liable, the second one is not.
        // [GIVEN] Amount incl. VAT of the first order = 110 LCY (100 line amount + 10 tax).
        CreateAndReceivePurchOrder(PurchaseHeader, Vendor."No.", true, ItemNo, TaxAreaCode, TaxGroupCode);
        PurchOrderAmount[1] := PurchaseHeader."Amount Including VAT";

        // [GIVEN] Amount incl. VAT of the second order = 100 LCY (100 line amount, no tax).
        // [GIVEN] Post both orders as receive.
        CreateAndReceivePurchOrder(PurchaseHeader, Vendor."No.", false, ItemNo, TaxAreaCode, TaxGroupCode);
        PurchOrderAmount[2] := PurchaseHeader."Amount Including VAT";

        // [GIVEN] Create purchase invoice and populate lines using "Get Receipt Lines".
        PurchRcptLine.SetRange("Buy-from Vendor No.", Vendor."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        PurchaseHeaderInvoice.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeaderInvoice.Modify(true);
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [WHEN] Post the purchase invoice.
        PurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true);

        // [THEN] Invoiced amount = 210 LCY (110 + 100).
        Vendor.CalcFields("Net Change");
        asserterror Vendor.TestField("Net Change", PurchOrderAmount[1] + PurchOrderAmount[2]);

        // [THEN] VAT entry is created for the taxed amount only.
        // [THEN] "VAT Entry".Base = 100.
        // [THEN] "VAT Entry".Amount = 10.
        VATEntry.SetRange("Document No.", PurchInvoiceNo);
        Assert.RecordCount(VATEntry, 1);
        VATEntry.FindFirst();
        asserterror Assert.AreNearlyEqual(PurchOrderAmount[1] / (1 + TaxPercent / 100), VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), '');
        asserterror Assert.AreEqual(PurchOrderAmount[1] - VATEntry.Base, VATEntry.Amount, '');

        // [THEN] 10 LCY is posted on tax account to the general ledger.
        asserterror VerifyGLEntry(PurchInvoiceNo, TaxJurisdiction."Tax Account (Purchases)", VATEntry.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxLiablePerServiceLine()
    var
        Customer: Record Customer;
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
        ServiceHeaderInvoice: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATEntry: Record "VAT Entry";
        ServiceGetShipment: Codeunit "Service-Get Shipment";
        ItemNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        TaxPercent: Decimal;
        ServiceOrderAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Service] [Invoice] [Get Service Shipment Lines]
        // [SCENARIO 334744] Only service lines up to Tax Liable are included in tax calculation.
        Initialize();
        TaxPercent := LibraryRandom.RandInt(10);

        // [GIVEN] Tax area code "TA", Tax group code = "TG", Tax = 3%.
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        TaxJurisdiction.Get(LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_CA());
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdiction.Code);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxPercent);

        // [GIVEN] A customer with tax area code "TA".
        Customer.Get(CreateCustomerWithTaxArea(TaxAreaCode));

        // [GIVEN] A new item.
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Create two service orders with tax area "TA" and tax group code "TG".
        // [GIVEN] The first order is tax liable, the second one is not.
        // [GIVEN] Amount incl. VAT of the first order = 110 LCY (100 line amount + 10 tax).
        CreateAndShipServiceOrder(ServiceHeader, Customer."No.", true, ItemNo, TaxAreaCode, TaxGroupCode);
        FindServiceLine(ServiceLine, ServiceHeader);
        ServiceOrderAmount[1] := Round(ServiceLine."Line Amount" * (1 + TaxPercent / 100), LibraryERM.GetAmountRoundingPrecision());

        // [GIVEN] Amount incl. VAT of the second order = 100 LCY (100 line amount, no tax).
        // [GIVEN] Post both orders as ship.
        CreateAndShipServiceOrder(ServiceHeader, Customer."No.", false, ItemNo, TaxAreaCode, TaxGroupCode);
        FindServiceLine(ServiceLine, ServiceHeader);
        ServiceOrderAmount[2] := ServiceLine."Line Amount";

        // [GIVEN] Create service invoice and populate lines using "Get Service Shipment Lines".
        ServiceShipmentLine.SetRange("Customer No.", Customer."No.");
        LibraryService.CreateServiceHeader(ServiceHeaderInvoice, ServiceHeaderInvoice."Document Type"::Invoice, Customer."No.");
        ServiceHeaderInvoice.Validate("Tax Area Code", TaxAreaCode);
        ServiceHeaderInvoice.Modify(true);
        ServiceGetShipment.SetServiceHeader(ServiceHeaderInvoice);
        ServiceGetShipment.CreateInvLines(ServiceShipmentLine);

        // [WHEN] Post the service invoice.
        LibraryService.PostServiceOrder(ServiceHeaderInvoice, false, false, false);

        // [THEN] Invoiced amount = 210 LCY (110 + 100).
        Customer.CalcFields("Net Change");
        asserterror Customer.TestField("Net Change", ServiceOrderAmount[1] + ServiceOrderAmount[2]);

        // [THEN] VAT entry is created for the taxed amount only.
        // [THEN] "VAT Entry".Base = 100.
        // [THEN] "VAT Entry".Amount = 10.
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeaderInvoice);
        VATEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        Assert.RecordCount(VATEntry, 1);
        VATEntry.FindFirst();
        asserterror Assert.AreNearlyEqual(-ServiceOrderAmount[1] / (1 + TaxPercent / 100), VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), '');
        asserterror Assert.AreEqual(-ServiceOrderAmount[1] - VATEntry.Base, VATEntry.Amount, '');

        // [THEN] 10 LCY is posted on tax account to the general ledger.
        asserterror VerifyGLEntry(ServiceInvoiceHeader."No.", TaxJurisdiction."Tax Account (Sales)", VATEntry.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocWithNoTaxLiable()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 354041] VAT Entry with 0 amount is created for the sales invoice with Tax Liable = No
        Initialize();

        // [GIVEN] Tax setup with Tax area code "TA", Tax = 3%.
        CreateTaxSetup(TaxAreaCode, TaxGroupCode, LibraryRandom.RandInt(10));

        // [GIVEN] Sales Invoice for a customer with tax area code "TA" and Tax Liable = No.
        Customer.Get(CreateCustomerWithTaxArea(TaxAreaCode));
        Customer.Validate("Tax Liable", false);
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateSalesLineGL(
          SalesHeader, CreateGLAccNoWithTaxSetup(TaxAreaCode, TaxGroupCode, false), TaxGroupCode, LibraryRandom.RandDecInRange(100, 200, 2));
        SalesHeader.CalcFields(Amount);

        // [WHEN] Post the sales invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] VAT Entry is created for the invoice with Amount = 0
        VerifyVATEntry(Customer."No.", -SalesHeader.Amount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocWithNoTaxLiable()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Service]
        // [SCENARIO 354041] VAT Entry with 0 amount is created for the service invoice with Tax Liable = No
        Initialize();

        // [GIVEN] Tax setup with Tax area code "TA", Tax = 3%.
        CreateTaxSetup(TaxAreaCode, TaxGroupCode, LibraryRandom.RandInt(10));

        // [GIVEN] Service Invoice for a customer with tax area code "TA" and Tax Liable = No.
        Customer.Get(CreateCustomerWithTaxArea(TaxAreaCode));
        Customer.Validate("Tax Liable", false);
        Customer.Modify(true);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", CreateGLAccNoWithTaxSetup(TaxAreaCode, TaxGroupCode, false));
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        ServiceLine.Modify(true);

        // [WHEN] Post the service invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] VAT Entry is created for the invoice with Amount = 0
        VerifyVATEntry(Customer."No.", -ServiceLine."Line Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocWithNoTaxLiable()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 354041] VAT Entry with 0 amount is created for the purchase invoice with Tax Liable = No
        Initialize();

        // [GIVEN] Tax setup with Tax area code "TA", Tax = 3%.
        CreateTaxSetup(TaxAreaCode, TaxGroupCode, LibraryRandom.RandInt(10));

        // [GIVEN] Purchase Invoice for a vendor with tax area code "TA" and Tax Liable = No.
        Vendor.Get(CreateVendorWithTaxArea(TaxAreaCode));
        Vendor.Validate("Tax Liable", false);
        Vendor.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify(true);
        CreatePurchaseLineGL(
          PurchaseHeader, CreateGLAccNoWithTaxSetup(TaxAreaCode, TaxGroupCode, false), TaxGroupCode, LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseHeader.CalcFields(Amount);

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] VAT Entry is created for the invoice with Amount = 0
        VerifyVATEntry(Vendor."No.", PurchaseHeader.Amount, 0);
    end;

    local procedure Initialize()
    var
        TaxSetup: Record "Tax Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibrarySales.SetReturnOrderNoSeriesInSetup;
        LibraryPurchase.SetReturnOrderNoSeriesInSetup;
        LibraryService.SetupServiceMgtNoSeries;
        LibraryApplicationArea.EnableEssentialSetup();

        if IsInitialized then
            exit;
        IsInitialized := true;

        TaxSetup.DeleteAll();
        TaxSetup.Init();
        TaxSetup.Insert();

        UpdateSalesNoSeries;
        UpdatePurchaseNoSeries;
    end;

    local procedure PrepareTaxBelowMaximumValues_TFS229419(var TaxBelowMaximum: array[3] of Decimal)
    begin
        TaxBelowMaximum[1] := 13;
        TaxBelowMaximum[2] := 5;
        TaxBelowMaximum[3] := 5;
    end;

    local procedure PrepareUnitPrices_TFS229419(var UnitPrice: array[5] of Decimal)
    begin
        UnitPrice[1] := 99;
        UnitPrice[2] := 116.5;
        UnitPrice[3] := 86.5;
        UnitPrice[4] := 66.5;
        UnitPrice[5] := 116.5;
    end;

    local procedure PrepareUnitPrices_TFS262985(var UnitPrice: array[11] of Decimal)
    begin
        UnitPrice[1] := 198.35;
        UnitPrice[2] := 62.15;
        UnitPrice[3] := 1243.5;
        UnitPrice[4] := 8.41;
        UnitPrice[5] := 1.78;
        UnitPrice[6] := 27.08;
        UnitPrice[7] := 2.03;
        UnitPrice[8] := 1.9;
        UnitPrice[9] := 1.09;
        UnitPrice[10] := 78;
        UnitPrice[11] := 70;
    end;

    local procedure PrepareUnitPrices_TFS273130(var UnitPrice: array[2] of Decimal)
    begin
        UnitPrice[1] := 11000;
        UnitPrice[2] := -9315;
    end;

    local procedure PrepareUnitPrices_TFS280515(var UnitPrice: array[2] of Decimal)
    begin
        UnitPrice[1] := 1283.06;
        UnitPrice[2] := -859.96;
    end;

    local procedure PrepareQuantity_TFS262985(var Quantity: array[11] of Decimal)
    begin
        Quantity[1] := 18;
        Quantity[2] := 18;
        Quantity[3] := 1;
        Quantity[4] := 48;
        Quantity[5] := 48;
        Quantity[6] := 10;
        Quantity[7] := 26;
        Quantity[8] := 26;
        Quantity[9] := 18;
        Quantity[10] := 2;
        Quantity[11] := 2;
    end;

    local procedure PrepareExpectedAmounts_TFS229419(var Amount: Decimal; var AmountIncludingVAT: Decimal; var InvoiceDiscountAmount: Decimal; var VATAmount: Decimal)
    begin
        Amount := 412.25;
        AmountIncludingVAT := 443.27;
        InvoiceDiscountAmount := 72.75;
        VATAmount := 31.02;
    end;

    local procedure CreateCustomTaxSetup_TFS210430(var TaxAreaCode: Code[20]; var TaxGroupCode: array[2] of Code[20]; TaxCountry: Option)
    var
        TaxDetail: Record "Tax Detail";
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdictionCode: array[2] of Code[10];
        i: Integer;
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxAreaWithCountryRegion(TaxCountry);
        for i := 1 to ArrayLen(TaxGroupCode) do begin
            TaxGroupCode[i] := LibraryERMTax.CreateTaxGroupCode;
            TaxJurisdictionCode[i] := LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(TaxCountry);
            LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode[i]);
        end;

        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[1], TaxGroupCode[1], 5);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[1], TaxGroupCode[2], 0);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[2], '', 7);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[2], TaxGroupCode[1], 7);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[2], TaxGroupCode[2], 7);
        UpdateTaxDetailExpenseCapitalize(TaxJurisdictionCode[2], '', TaxDetail."Tax Type"::"Sales and Use Tax", true);
        UpdateTaxDetailExpenseCapitalize(TaxJurisdictionCode[2], TaxGroupCode[1], TaxDetail."Tax Type"::"Sales and Use Tax", true);
        UpdateTaxDetailExpenseCapitalize(TaxJurisdictionCode[2], TaxGroupCode[2], TaxDetail."Tax Type"::"Sales and Use Tax", true);
    end;

    local procedure CreateTaxForTaxGroup(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; CountryRegion: Option; TaxPercent: Decimal; ExpenseCapitalize: Boolean)
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: Code[10];
    begin
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(CountryRegion);
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxPercent);
        UpdateTaxDetailExpenseCapitalize(TaxJurisdictionCode, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", ExpenseCapitalize);
    end;

    local procedure CreateTaxSetup(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; TaxPct: Integer)
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        TaxJurisdiction.Get(LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_CA());
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdiction.Code);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxPct);
    end;

    local procedure CreateTaxSetup_TFS229419(var TaxAreaCode: Code[20]; var TaxGroupCode: array[3] of Code[20])
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: Code[10];
        TaxBelowMaximum: array[3] of Decimal;
        i: Integer;
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA;
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdiction_CA;
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode);
        PrepareTaxBelowMaximumValues_TFS229419(TaxBelowMaximum);
        for i := 1 to ArrayLen(TaxBelowMaximum) do begin
            TaxGroupCode[i] := LibraryERMTax.CreateTaxGroupCode;
            LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode[i], TaxBelowMaximum[i]);
        end;
    end;

    local procedure CreateTaxSetup_TFS231225(var NoTaxAreaCode: Code[20]; var TaxAreaCode: Code[20]; var ProvTaxAreaCode: Code[20]; var TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
        NoTaxJurisdictionCode: Code[10];
        ProvTaxJurisdictionCode: array[4] of Code[10];
        TaxJurisdictionCode: Code[10];
        i: Integer;
    begin
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode;

        // No Tax
        NoTaxAreaCode := LibraryERMTax.CreateTaxArea_CA;
        NoTaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_CA;
        LibraryERMTax.CreateTaxAreaLine(NoTaxAreaCode, NoTaxJurisdictionCode);
        LibraryERMTax.CreateTaxDetail(TaxDetail, NoTaxJurisdictionCode, TaxGroupCode, 0);

        // Provincial Tax
        ProvTaxAreaCode := LibraryERMTax.CreateTaxArea_CA;
        for i := 1 to ArrayLen(ProvTaxJurisdictionCode) do begin
            ProvTaxJurisdictionCode[i] := LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_CA;
            LibraryERMTax.CreateTaxAreaLine(ProvTaxAreaCode, ProvTaxJurisdictionCode[i]);
        end;
        LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, ProvTaxJurisdictionCode[1], TaxGroupCode, 1.6, true);
        LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, ProvTaxJurisdictionCode[2], TaxGroupCode, 3.4, false);
        LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, ProvTaxJurisdictionCode[3], TaxGroupCode, 0.56, true);
        LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, ProvTaxJurisdictionCode[4], TaxGroupCode, 7.44, false);

        // Tax
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA;
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_CA;
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, 5);
    end;

    local procedure CreateTaxSetup_TFS262985(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: Code[10];
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA;
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdiction_CA;
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode);
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode;
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, 13);
    end;

    local procedure CreateTaxSetup_TFS273130(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; var NonTaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: array[3] of Code[10];
        i: Integer;
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US;
        for i := 1 to ArrayLen(TaxJurisdictionCode) do begin
            TaxJurisdictionCode[i] := LibraryERMTax.CreateTaxJurisdiction_US;
            LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode[i]);
        end;

        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode;
        LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, TaxJurisdictionCode[1], TaxGroupCode, 0, false);
        LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, TaxJurisdictionCode[2], TaxGroupCode, 8.9, true);
        LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, TaxJurisdictionCode[3], TaxGroupCode, 0, false);

        NonTaxGroupCode := LibraryERMTax.CreateTaxGroupCode;
        for i := 1 to ArrayLen(TaxJurisdictionCode) do
            LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, TaxJurisdictionCode[i], NonTaxGroupCode, 0, false);
    end;

    local procedure CreateTaxSetup_TFS280515(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; CountyrRegionOption: Option)
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: array[2] of Code[10];
        i: Integer;
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxAreaWithCountryRegion(CountyrRegionOption);
        for i := 1 to ArrayLen(TaxJurisdictionCode) do begin
            TaxJurisdictionCode[i] := LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(CountyrRegionOption);
            LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode[i]);
        end;
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode;
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[1], TaxGroupCode, 0);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[2], TaxGroupCode, 5);
    end;

    local procedure CreateTaxSetup_TFS283166(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20])
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxAreaWithCountryRegion(DummyTaxCountry::CA);
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode;

        CreateTaxForTaxGroup(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA, 5, true);
        CreateTaxForTaxGroup(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA, 7, true);
    end;

    local procedure CreateSalesOrder_TFS229419(var SalesHeader: Record "Sales Header"; DiscountPct: Decimal; PrepaymentPct: Decimal; PrepmtIncludeTax: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[3] of Code[20];
        ItemNo: Code[20];
        UnitPrices: array[5] of Decimal;
    begin
        CreateTaxSetup_TFS229419(TaxAreaCode, TaxGroupCode);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesHeader(
          SalesHeader,
          CreateCustomerWithInvDiscount(GeneralPostingSetup."Gen. Bus. Posting Group", DiscountPct),
          TaxAreaCode, PrepaymentPct, PrepmtIncludeTax);
        ItemNo := CreateItemNo(GeneralPostingSetup."Gen. Prod. Posting Group");
        PrepareUnitPrices_TFS229419(UnitPrices);
        CreateSalesLineItem(SalesHeader, ItemNo, TaxGroupCode[2], UnitPrices[1]);
        CreateSalesLineItem(SalesHeader, ItemNo, TaxGroupCode[2], UnitPrices[2]);
        CreateSalesLineItem(SalesHeader, ItemNo, TaxGroupCode[1], UnitPrices[3]);
        CreateSalesLineItem(SalesHeader, ItemNo, TaxGroupCode[1], UnitPrices[4]);
        CreateSalesLineItem(SalesHeader, ItemNo, TaxGroupCode[3], UnitPrices[5]);
        LibrarySales.CalcSalesDiscount(SalesHeader);
    end;

    local procedure CreateSalesOrder_TFS262985(var SalesHeader: Record "Sales Header")
    var
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        UnitPrices: array[11] of Decimal;
        Quantity: array[11] of Decimal;
        i: Integer;
    begin
        CreateTaxSetup_TFS262985(TaxAreaCode, TaxGroupCode);
        CreateCustomerAndGLAccount(CustomerNo, GLAccountNo);
        CreateSalesHeader(SalesHeader, CustomerNo, TaxAreaCode, 25, true);
        PrepareUnitPrices_TFS262985(UnitPrices);
        PrepareQuantity_TFS262985(Quantity);
        for i := 1 to ArrayLen(Quantity) do
            CreateSalesLineGLQty(SalesHeader, GLAccountNo, TaxGroupCode, Quantity[i], UnitPrices[i]);
    end;

    local procedure CreateSalesOrder_TFS273130(var SalesHeader: Record "Sales Header")
    var
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        NonTaxGroupCode: Code[20];
        UnitPrices: array[2] of Decimal;
    begin
        CreateTaxSetup_TFS273130(TaxAreaCode, TaxGroupCode, NonTaxGroupCode);
        CreateCustomerAndGLAccount(CustomerNo, GLAccountNo);
        CreateSalesHeader(SalesHeader, CustomerNo, TaxAreaCode, 0, false);
        PrepareUnitPrices_TFS273130(UnitPrices);
        CreateSalesLineGL(SalesHeader, GLAccountNo, NonTaxGroupCode, UnitPrices[1]);
        CreateSalesLineGL(SalesHeader, GLAccountNo, TaxGroupCode, UnitPrices[2]);
    end;

    local procedure CreatePurchaseOrder_TFS262985(var PurchaseHeader: Record "Purchase Header")
    var
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        UnitPrices: array[11] of Decimal;
        Quantity: array[11] of Decimal;
        i: Integer;
    begin
        CreateTaxSetup_TFS262985(TaxAreaCode, TaxGroupCode);
        CreateVendorAndGLAccount(VendorNo, GLAccountNo);
        CreatePurchaseHeader(PurchaseHeader, VendorNo, TaxAreaCode, 25, true);
        PrepareUnitPrices_TFS262985(UnitPrices);
        PrepareQuantity_TFS262985(Quantity);
        for i := 1 to ArrayLen(Quantity) do
            CreatePurchaseLineGLQty(PurchaseHeader, GLAccountNo, TaxGroupCode, Quantity[i], UnitPrices[i]);
    end;

    local procedure CreatePurchaseOrder_TFS273130(var PurchaseHeader: Record "Purchase Header")
    var
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        NonTaxGroupCode: Code[20];
        UnitPrices: array[2] of Decimal;
    begin
        CreateTaxSetup_TFS273130(TaxAreaCode, TaxGroupCode, NonTaxGroupCode);
        CreateVendorAndGLAccount(VendorNo, GLAccountNo);
        CreatePurchaseHeader(PurchaseHeader, VendorNo, TaxAreaCode, 0, false);
        PrepareUnitPrices_TFS273130(UnitPrices);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, NonTaxGroupCode, UnitPrices[1]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, TaxGroupCode, UnitPrices[2]);
    end;

    local procedure CreateSalesOrder_TFS280515(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        UnitPrices: array[2] of Decimal;
    begin
        PrepareUnitPrices_TFS280515(UnitPrices);
        CreateSalesHeader(SalesHeader, LibrarySales.CreateCustomerWithVATBusPostingGroup(''), TaxAreaCode, 0, false);
        CreateSalesLineItem(SalesHeader, LibraryInventory.CreateItemNoWithVATProdPostingGroup(''), TaxGroupCode, UnitPrices[1]);
        CreateSalesLineItem(SalesHeader, LibraryInventory.CreateItemNoWithVATProdPostingGroup(''), TaxGroupCode, UnitPrices[2]);
    end;

    local procedure CreatePurchaseOrder_TFS280515(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        UnitPrices: array[2] of Decimal;
    begin
        PrepareUnitPrices_TFS280515(UnitPrices);
        CreatePurchaseHeader(PurchaseHeader, LibraryPurchase.CreateVendorWithVATBusPostingGroup(''), TaxAreaCode, 0, false);
        CreatePurchaseLineItem(PurchaseHeader, LibraryInventory.CreateItemNoWithVATProdPostingGroup(''), TaxGroupCode, UnitPrices[1]);
        CreatePurchaseLineItem(PurchaseHeader, LibraryInventory.CreateItemNoWithVATProdPostingGroup(''), TaxGroupCode, UnitPrices[2]);
    end;

    local procedure CreateServiceOrder_TFS280515(var ServiceHeader: Record "Service Header"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
        UnitPrices: array[2] of Decimal;
    begin
        PrepareUnitPrices_TFS280515(UnitPrices);
        CreateServiceHeader(ServiceHeader, ServiceItemLine, TaxAreaCode);
        CreateServiceLine(
          ServiceHeader, ServiceItemLine, LibraryInventory.CreateItemNoWithVATProdPostingGroup(''), TaxGroupCode, 1, UnitPrices[1]);
        CreateServiceLine(
          ServiceHeader, ServiceItemLine, LibraryInventory.CreateItemNoWithVATProdPostingGroup(''), TaxGroupCode, 1, UnitPrices[2]);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; TaxAreaCode: Code[20]; PrepaymentPct: Decimal; PrepmtIncludeTax: Boolean)
    begin
        with SalesHeader do begin
            LibrarySales.CreateSalesHeader(SalesHeader, "Document Type"::Order, CustomerNo);
            Validate("Tax Liable", true);
            Validate("Tax Area Code", TaxAreaCode);
            Validate("Prepayment %", PrepaymentPct);
            Validate("Prepmt. Include Tax", PrepmtIncludeTax);
            Modify(true);
        end;
    end;

    local procedure CreateSalesLineItem(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; TaxGroupCode: Code[20]; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type::Item, ItemNo, 1);
            Validate("Tax Group Code", TaxGroupCode);
            Validate("Unit Price", UnitPrice);
            Modify(true);
        end;
    end;

    local procedure CreateSalesLineGL(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; TaxGroupCode: Code[20]; UnitPrice: Decimal)
    begin
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, TaxGroupCode, 1, UnitPrice);
    end;

    local procedure CreateSalesLineGLQty(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; TaxGroupCode: Code[20]; NewQuantity: Decimal; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type::"G/L Account", GLAccountNo, NewQuantity);
            Validate("Unit Price", UnitPrice);
            Validate("Tax Group Code", TaxGroupCode);
            Modify(true);
        end;
    end;

    local procedure CreateCustomerWithInvDiscount(GenBusPostingGroupCode: Code[20]; DiscountPct: Decimal): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(
          CustInvoiceDisc, LibrarySales.CreateCustomerWithBusPostingGroups(GenBusPostingGroupCode, ''), '', 0);
        with CustInvoiceDisc do begin
            Validate("Discount %", DiscountPct);
            Modify(true);
            exit(Code);
        end;
    end;

    local procedure CreateCustomerWithTaxArea(TaxAreaCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibrarySales.CreateCustomer(Customer);
        with Customer do begin
            Validate("VAT Bus. Posting Group", '');
            Validate("Tax Liable", true);
            Validate("Tax Area Code", TaxAreaCode);
            Validate("Tax Identification Type", "Tax Identification Type"::"Legal Entity");
            "RFC No." := LibraryUtility.GenerateGUID;
            "CURP No." := LibraryUtility.GenerateGUID;
            Validate("Post Code", PostCode.Code);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateCustomerAndGLAccount(var CustomerNo: Code[20]; var GLAccountNo: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CustomerNo := LibrarySales.CreateCustomerWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", '');
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Modify(true);
        GLAccountNo := GLAccount."No.";
    end;

    local procedure CreatePurchaseOrder_TFS229419(var PurchaseHeader: Record "Purchase Header"; DiscountPct: Decimal; PrepaymentPct: Decimal; PrepmtIncludeTax: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[3] of Code[20];
        ItemNo: Code[20];
        UnitPrices: array[5] of Decimal;
    begin
        CreateTaxSetup_TFS229419(TaxAreaCode, TaxGroupCode);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseHeader(
          PurchaseHeader,
          CreateVendorWithInvDiscount(GeneralPostingSetup."Gen. Bus. Posting Group", DiscountPct),
          TaxAreaCode, PrepaymentPct, PrepmtIncludeTax);
        ItemNo := CreateItemNo(GeneralPostingSetup."Gen. Prod. Posting Group");
        PrepareUnitPrices_TFS229419(UnitPrices);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo, TaxGroupCode[2], UnitPrices[1]);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo, TaxGroupCode[2], UnitPrices[2]);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo, TaxGroupCode[1], UnitPrices[3]);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo, TaxGroupCode[1], UnitPrices[4]);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo, TaxGroupCode[3], UnitPrices[5]);
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; TaxAreaCode: Code[20]; PrepaymentPct: Decimal; PrepmtIncludeTax: Boolean)
    begin
        with PurchaseHeader do begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Document Type"::Order, VendorNo);
            Validate("Tax Liable", true);
            Validate("Tax Area Code", TaxAreaCode);
            Validate("Prepayment %", PrepaymentPct);
            Validate("Prepmt. Include Tax", PrepmtIncludeTax);
            Modify(true);
        end;
    end;

    local procedure CreatePurchaseHeaderWithTaxAreaForVendor(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; CurrencyCode: Code[10]; TaxAreaCode: Code[20]; VendorNo: Code[20])
    begin
        with PurchaseHeader do begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
            Validate("Ship-to Address", LibraryUtility.GenerateGUID);
            Validate("Currency Code", CurrencyCode);
            Validate("Tax Liable", true);
            Validate("Tax Area Code", TaxAreaCode);
            Modify(true);
        end;
    end;

    local procedure CreateAndReceivePurchOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; TaxLiable: Boolean; ItemNo: Code[20]; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Validate("Tax Liable", TaxLiable);
        PurchaseHeader.Modify(true);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo, TaxGroupCode, LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseHeader.CalcFields("Amount Including VAT");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateSalesHeaderWithTaxAreaForCustomer(var SalesHeader: Record "Sales Header"; DocumentType: Option; CurrencyCode: Code[10]; TaxAreaCode: Code[20]; CustomerNo: Code[20])
    begin
        with SalesHeader do begin
            LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
            Validate("Bill-to Address", LibraryUtility.GenerateGUID);
            Validate("Currency Code", CurrencyCode);
            Validate("Tax Liable", true);
            Validate("Tax Area Code", TaxAreaCode);
            Modify(true);
        end;
    end;

    local procedure CreateAndShipSalesOrderWithShipToAddr(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ShipToCode: Code[10]; ItemNo: Code[20]; TaxGroupCode: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Ship-to Code", ShipToCode);
        SalesHeader.Modify(true);
        CreateSalesLineItem(SalesHeader, ItemNo, TaxGroupCode, LibraryRandom.RandDecInRange(100, 200, 2));
        SalesHeader.CalcFields("Amount Including VAT");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreatePurchaseLineItem(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; TaxGroupCode: Code[20]; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        with PurchaseLine do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type::Item, ItemNo, 1);
            Validate("Tax Group Code", TaxGroupCode);
            Validate("Direct Unit Cost", DirectUnitCost);
            Modify(true);
        end;
    end;

    local procedure CreatePurchaseLineGLWithProvincialTax(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; ProvincialTaxAreaCode: Code[20]; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        with PurchaseLine do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type::"G/L Account", GLAccountNo, 1);
            Validate("Tax Area Code", TaxAreaCode);
            Validate("Tax Group Code", TaxGroupCode);
            Validate("Provincial Tax Area Code", ProvincialTaxAreaCode);
            Validate("Direct Unit Cost", DirectUnitCost);
            Modify(true);
        end;
    end;

    local procedure CreatePurchaseLineGL(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; TaxGroupCode: Code[20]; DirectUnitCost: Decimal)
    begin
        CreatePurchaseLineGLQty(PurchaseHeader, GLAccountNo, TaxGroupCode, 1, DirectUnitCost);
    end;

    local procedure CreatePurchaseLineGLQty(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; TaxGroupCode: Code[20]; NewQuantity: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        with PurchaseLine do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type::"G/L Account", GLAccountNo, NewQuantity);
            Validate("Direct Unit Cost", DirectUnitCost);
            Validate("Tax Group Code", TaxGroupCode);
            Modify(true);
        end;
    end;

    local procedure CreateCustomPurchaseDocWithOneLine_TFS233346(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; CurrencyCode: Code[10])
    var
        GLAccountNo: Code[20];
    begin
        LibraryPurchase.SetInvoiceRounding(false);

        CreatePurchaseHeaderWithTaxAreaForVendor(
          PurchaseHeader, DocumentType, CurrencyCode, TaxAreaCode, CreateVendorWithTaxArea(TaxAreaCode));

        GLAccountNo := CreateGLAccNoWithTaxSetup(TaxAreaCode, TaxGroupCode, false);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, TaxGroupCode, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateCustomSalesDocWithOneLine_TFS233346(var SalesHeader: Record "Sales Header"; DocumentType: Option; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; CurrencyCode: Code[10])
    var
        GLAccountNo: Code[20];
    begin
        LibrarySales.SetInvoiceRounding(false);

        CreateSalesHeaderWithTaxAreaForCustomer(
          SalesHeader, DocumentType, CurrencyCode, TaxAreaCode, CreateCustomerWithTaxArea(TaxAreaCode));

        GLAccountNo := CreateGLAccNoWithTaxSetup(TaxAreaCode, TaxGroupCode, false);
        CreateSalesLineGL(SalesHeader, GLAccountNo, TaxGroupCode, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateVendorWithInvDiscount(GenBusPostingGroupCode: Code[20]; DiscountPct: Decimal): Code[20]
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(
          VendorInvoiceDisc, LibraryPurchase.CreateVendorWithBusPostingGroups(GenBusPostingGroupCode, ''), '', 0);
        with VendorInvoiceDisc do begin
            Validate("Discount %", DiscountPct);
            Modify(true);
            exit(Code);
        end;
    end;

    local procedure CreateVendorWithTaxArea(TaxAreaCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", '');
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorAndGLAccount(var VendorNo: Code[20]; var GLAccountNo: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        CreateGeneralPostingSetup(GeneralPostingSetup);
        VendorNo := LibraryPurchase.CreateVendorWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", '');
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Modify(true);
        GLAccountNo := GLAccount."No.";
    end;

    local procedure CreateItemNo(GenProdPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithPostingSetup(Item, GenProdPostingGroupCode, '');
        exit(Item."No.");
    end;

    local procedure CreateGLAccountNoWithBlankVATSetup(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.Get('', '');
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
    end;

    local procedure CreateGLAccNoWithTaxSetup(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        with GLAccount do begin
            Validate("Tax Area Code", TaxAreaCode);
            Validate("Tax Liable", TaxLiable);
            Validate("Tax Group Code", TaxGroupCode);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPurchAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupMfgAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; TaxAreaCode: Code[20])
    begin
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerWithVATBusPostingGroup(''));
        ServiceHeader.Validate("Tax Liable", true);
        ServiceHeader.Validate("Tax Area Code", TaxAreaCode);
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate("Item No.", LibraryInventory.CreateItemNo);
        ServiceItemLine.Modify(true);
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header"; ServiceItemLine: Record "Service Item Line"; ItemNo: Code[20]; TaxGroupCode: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo, Quantity);
        ServiceLine.Validate("Tax Group Code", TaxGroupCode);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Modify(true);
    end;

    local procedure CreateAndShipServiceOrder(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; TaxLiable: Boolean; ItemNo: Code[20]; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        Clear(ServiceHeader);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        ServiceHeader.Validate("Tax Liable", TaxLiable);
        ServiceHeader.Validate("Tax Area Code", TaxAreaCode);
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate("Item No.", LibraryInventory.CreateItemNo());
        ServiceItemLine.Modify(true);

        CreateServiceLine(ServiceHeader, ServiceItemLine, ItemNo, TaxGroupCode, 1, LibraryRandom.RandDecInRange(100, 200, 2));

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Option; DocumentNo: Code[20]; LineType: Option)
    begin
        with PurchaseLine do begin
            SetRange("Document Type", DocumentType);
            SetRange("Document No.", DocumentNo);
            SetRange(Type, LineType);
            FindFirst;
        end;
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Option; DocumentNo: Code[20]; LineType: Option)
    begin
        with SalesLine do begin
            SetRange("Document Type", DocumentType);
            SetRange("Document No.", DocumentNo);
            SetRange(Type, LineType);
            FindFirst;
        end;
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
    end;

    local procedure FindServiceInvoiceHeader(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header")
    begin
        ServiceInvoiceHeader.SetRange("Customer No.", ServiceHeader."Customer No.");
        ServiceInvoiceHeader.FindFirst;
    end;

    local procedure PostPurchaseDocument(PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure UpdateSalesNoSeries()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        with SalesReceivablesSetup do begin
            Get;
            "Posted Prepmt. Inv. Nos." := LibraryERM.CreateNoSeriesCode;
            Modify;
        end;
    end;

    local procedure UpdatePurchaseNoSeries()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        with PurchasesPayablesSetup do begin
            Get;
            "Posted Prepmt. Inv. Nos." := LibraryERM.CreateNoSeriesCode;
            Modify;
        end;
    end;

    local procedure UpdateTaxDetailExpenseCapitalize(TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; TaxType: Option; NewValue: Boolean)
    var
        TaxDetail: Record "Tax Detail";
    begin
        with TaxDetail do begin
            Get(TaxJurisdictionCode, TaxGroupCode, TaxType, WorkDate);
            Validate("Expense/Capitalize", NewValue);
            Modify(true);
        end;
    end;

    local procedure ValidatePurchaseOrderTaxAreaThroughPage(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit;
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder."Tax Area Code".SetValue(TaxAreaCode);
        PurchaseOrder.Close;
        PurchaseHeader.Find;
    end;

    local procedure ValidatePurchaseReturnOrderTaxAreaThroughPage(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20])
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenEdit;
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder."Tax Area Code".SetValue(TaxAreaCode);
        PurchaseReturnOrder.Close;
        PurchaseHeader.Find;
    end;

    local procedure ValidateSalesOrderTaxAreaThroughPage(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit;
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder."Tax Area Code".SetValue(TaxAreaCode);
        SalesOrder.Close;
        SalesHeader.Find;
    end;

    local procedure ValidateSalesReturnOrderTaxAreaThroughPage(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit;
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder."Tax Area Code".SetValue(TaxAreaCode);
        SalesReturnOrder.Close;
        SalesHeader.Find;
    end;

    local procedure VerifySalesHeaderTotals(SalesHeader: Record "Sales Header"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal; ExpectedInvDiscAmount: Decimal; ExpectedPrepmtLineAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesHeader do begin
            CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
            TestField(Amount, ExpectedAmount);
            TestField("Amount Including VAT", ExpectedAmountInclVAT);
            TestField("Invoice Discount Amount", ExpectedInvDiscAmount);
        end;

        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            CalcSums("Prepmt. Line Amount", "Prepmt. Amt. Incl. VAT");
            TestField("Prepmt. Line Amount", ExpectedPrepmtLineAmount);
        end;
    end;

    local procedure VerifyPurchaseHeaderTotals(PurchaseHeader: Record "Purchase Header"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal; ExpectedInvDiscAmount: Decimal; ExpectedPrepmtLineAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        with PurchaseHeader do begin
            CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
            TestField(Amount, ExpectedAmount);
            TestField("Amount Including VAT", ExpectedAmountInclVAT);
            TestField("Invoice Discount Amount", ExpectedInvDiscAmount);
        end;

        with PurchaseLine do begin
            SetRange("Document Type", PurchaseHeader."Document Type");
            SetRange("Document No.", PurchaseHeader."No.");
            CalcSums("Prepmt. Line Amount", "Prepmt. Amt. Incl. VAT");
            TestField("Prepmt. Line Amount", ExpectedPrepmtLineAmount);
        end;
    end;

    local procedure VerifyPostedSalesInvoiceTotals(SalesInvoiceHeader: Record "Sales Invoice Header"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    begin
        with SalesInvoiceHeader do begin
            CalcFields(Amount, "Amount Including VAT", "Remaining Amount");
            TestField(Amount, ExpectedAmount);
            TestField("Amount Including VAT", ExpectedAmountInclVAT);
            TestField("Remaining Amount", ExpectedAmountInclVAT);
        end;
    end;

    local procedure VerifyPostedPurchaseInvoiceTotals(PurchInvHeader: Record "Purch. Inv. Header"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    begin
        with PurchInvHeader do begin
            CalcFields(Amount, "Amount Including VAT", "Remaining Amount");
            TestField(Amount, ExpectedAmount);
            TestField("Amount Including VAT", ExpectedAmountInclVAT);
            TestField("Remaining Amount", ExpectedAmountInclVAT);
        end;
    end;

    local procedure VerifyPostedServiceInvoiceTotals(ServiceInvoiceHeader: Record "Service Invoice Header"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    begin
        with ServiceInvoiceHeader do begin
            CalcFields(Amount, "Amount Including VAT");
            TestField(Amount, ExpectedAmount);
            TestField("Amount Including VAT", ExpectedAmountInclVAT);
        end;
    end;

    local procedure VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo: Code[20]; InvoiceDocNo: Code[20]; PrepmtAmount: Decimal; InvoiceAmount: Decimal; InvoiceAmountInclVAT: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(PrepmtDocNo);
        VerifyPostedSalesInvoiceTotals(SalesInvoiceHeader, PrepmtAmount, PrepmtAmount);
        SalesInvoiceHeader.Get(InvoiceDocNo);
        VerifyPostedSalesInvoiceTotals(SalesInvoiceHeader, InvoiceAmount, InvoiceAmountInclVAT);
    end;

    local procedure VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo: Code[20]; InvoiceDocNo: Code[20]; PrepmtAmount: Decimal; InvoiceAmount: Decimal; InvoiceAmountInclVAT: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(PrepmtDocNo);
        VerifyPostedPurchaseInvoiceTotals(PurchInvHeader, PrepmtAmount, PrepmtAmount);
        PurchInvHeader.Get(InvoiceDocNo);
        VerifyPostedPurchaseInvoiceTotals(PurchInvHeader, InvoiceAmount, InvoiceAmountInclVAT);
    end;

    local procedure VerifyGLEntry(InvoiceNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("Document Type", "Document Type"::Invoice);
            SetRange("Document No.", InvoiceNo);
            SetRange("G/L Account No.", GLAccountNo);
            FindFirst;
            TestField(Amount, ExpectedAmount);
        end;
    end;

    local procedure VerifyPurchaseVATTotalAfterRelease(PurchaseHeader: Record "Purchase Header"; ExpectedAmount: Decimal)
    begin
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT");
        Assert.AreEqual(ExpectedAmount, PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount, '');
    end;

    local procedure VerifySalesVATTotalAfterRelease(SalesHeader: Record "Sales Header"; ExpectedAmount: Decimal)
    begin
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields(Amount, "Amount Including VAT");
        Assert.AreEqual(ExpectedAmount, SalesHeader."Amount Including VAT" - SalesHeader.Amount, '');
    end;

    local procedure VerifyVATEntry(AccountNo: Code[20]; VATBase: Decimal; VATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", AccountNo);
        VATEntry.FindFirst();
        VATEntry.TestField(Base, VATBase);
        VATEntry.TestField(Amount, VATAmount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReceiptLinesModalPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    begin
        GetReceiptLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnShipmentLinesModalPageHandler(var GetReturnShipmentLines: TestPage "Get Return Shipment Lines")
    begin
        GetReturnShipmentLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesModalPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnReceiptLinesModalPageHandler(var GetReturnReceiptLines: TestPage "Get Return Receipt Lines")
    begin
        GetReturnReceiptLines.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftSalesInvoiceRPH(var DraftSalesInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        DraftSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteRPH(var SalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        SalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

