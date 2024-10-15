codeunit 141018 "UT PAG Sales Tax Statistics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Statistics] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        AmountMustEqualMsg: Label 'Amount must be equal';
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMTax: Codeunit "Library - ERM Tax";

    [Test]
    [HandlerFunctions('ServiceStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsServiceCreditMemos()
    var
        ServiceLine: Record "Service Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
        OldInvoiceRounding: Boolean;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9320, Service Credit Memos without Tax Area.

        // Setup: Create Service Credit Memo. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        OldInvoiceRounding := UpdateInvoiceRoundingOnSalesReceivablesSetup(false);  // Update Invoice Rounding to FALSE on Sales & Receivables Setup.
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::"Credit Memo", '', '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := ServiceLine.Quantity * ServiceLine."Unit Price" * ServiceLine."VAT %" / 100;
        AmountIncVAT := ServiceLine.Quantity * ServiceLine."Unit Price" + VATAmount;

        // Enqueue values for use in ServiceStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Page Service Credit Memos and verify the VAT Amount and Amount Incl. VAT on Statistics page in ServiceStatisticsPageHandler.
        OpenStatisticsPageForServiceCreditMemo(ServiceLine."Document No.");

        // Tear Down.
        UpdateInvoiceRoundingOnSalesReceivablesSetup(OldInvoiceRounding);
    end;

    [Test]
    [HandlerFunctions('ServiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaServiceCreditMemos()
    var
        TaxDetail: Record "Tax Detail";
        ServiceLine: Record "Service Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
        OldInvoiceRounding: Boolean;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9320, Service Credit Memos with Tax Area.

        // Setup: Create Tax Setup and Service Credit Memo. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        OldInvoiceRounding := UpdateInvoiceRoundingOnSalesReceivablesSetup(false);  // Update Invoice Rounding to FALSE on Sales & Receivables Setup.
        CreateTaxDetail(TaxDetail, CreateTaxGroup, LibraryRandom.RandDec(10, 2));
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::"Credit Memo", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        TaxAmount := ServiceLine.Quantity * ServiceLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := ServiceLine.Quantity * ServiceLine."Unit Price" + TaxAmount;

        // Enqueue values for use in ServiceStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Page Service Credit Memos and verify the Tax Amount and Amount Incl. Tax on Statistics page in ServiceStatsPageHandler.
        OpenStatisticsPageForServiceCreditMemo(ServiceLine."Document No.");

        // Tear Down.
        UpdateInvoiceRoundingOnSalesReceivablesSetup(OldInvoiceRounding);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesQuotes()
    var
        SalesLine: Record "Sales Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9300, Sales Quotes without Tax Area.

        // Setup: Create a Sales Quote. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote, '', '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Page on Sales Quotes and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesStatisticsPageHandler.
        OpenStatisticsPageForSalesQuote(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesQuotesStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesQuotes()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9300, Sales Quotes with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Quote. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateTaxDetail(TaxDetail, CreateTaxGroup, LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote, TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesQuotesStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Page Sales Quotes and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesQuotesStatsPageHandler.
        OpenStatisticsPageForSalesQuote(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesOrderList()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9305, Sales Order List without Tax Area.

        // Setup: Create a Sales Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Sales Order List and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenStatisticsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesOrderList()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9305, Sales Order List with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateTaxDetail(TaxDetail, CreateTaxGroup, LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics Sales Order List and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenStatisticsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesInvoiceList()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9301, Sales Invoice List without Tax Area.

        // Setup: Create a Sales Invoice. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Sales Invoice List and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesStatisticsPageHandler.
        OpenStatisticsPageForSalesInvoice(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesInvoiceList()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9301, Sales Invoice List with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Invoice. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateTaxDetail(TaxDetail, CreateTaxGroup, LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Sales Invoice List and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenStatisticsPageForSalesInvoice(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsBlanketSalesOrders()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9303, Blanket Sales Orders without Tax Area.

        // Setup: Create a Blanket Sales Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order", TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Blanket Sales Orders and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenStatisticsPageForBlanketSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaBlanketSalesOrders()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9303, Blanket Sales Orders with Tax Area.

        // Setup: Create Tax Setup. Create a Blanket Sales Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateTaxDetail(TaxDetail, CreateTaxGroup, LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order", TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Blanket Sales Orders and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenStatisticsPageForBlanketSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesReturnOrderList()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9304, Sales Return Order List without Tax Area.

        // Setup: Create a Sales Return Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Sales Return Order List and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenStatisticsPageForSalesReturnOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesReturnOrderList()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9304, Sales Return Order List with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Return Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateTaxDetail(TaxDetail, CreateTaxGroup, LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Sales Return Order List and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenStatisticsPageForSalesReturnOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesCreditMemos()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9302, Sales Credit Memos without Tax Area.

        // Setup: Create a Sales Credit Memo. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Sales Credit Memos and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesStatisticsPageHandler.
        OpenStatisticsPageForSalesCreditMemo(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesCreditMemos()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9302, Sales Credit Memos with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Credit Memo. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateTaxDetail(TaxDetail, CreateTaxGroup, LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Sales Credit Memos and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenStatisticsPageForSalesCreditMemo(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchaseOrderList()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9307 Purchase Order List.

        // Setup: Create Purchase Order with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateTaxDetail(TaxDetail, CreateTaxGroup, LibraryRandom.RandDec(10, 2));
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order, CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Order List and verify Tax Amount and Amount Inclusive Tax on PurchaseOrderStatsPageHandler.
        OpenStatisticsPageForPurchaseOrder(PurchaseLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchaseOrderList()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9307 Purchase Order List.

        // Setup: Create Purchase Order without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Order List and verify VAT Amount and Amount Inclusive VAT on PurchaseOrderStatisticsPageHandler.
        OpenStatisticsPageForPurchaseOrder(PurchaseLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchaseReturnOrderList()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9311 Purchase Return Order List.

        // Setup: Create Purchase Return Order with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateTaxDetail(TaxDetail, CreateTaxGroup, LibraryRandom.RandDec(10, 2));
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Return Order List and verify Tax Amount and Amount Inclusive Tax on PurchaseOrderStatsPageHandler.
        OpenStatisticsPageForPurchaseReturnOrder(PurchaseLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchaseReturnOrderList()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9311 Purchase Return Order List.

        // Setup: Create Purchase Return Order without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Return Order List and verify VAT Amount and Amount Inclusive VAT on PurchaseOrderStatisticsPageHandler.
        OpenStatisticsPageForPurchaseReturnOrder(PurchaseLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaBlanketPurchaseOrders()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9310 Blanket Purchase Order List.

        // Setup: Create Blanket Purchase Order with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateTaxDetail(TaxDetail, CreateTaxGroup, LibraryRandom.RandDec(10, 2));
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Blanket Order", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Blanket Purchase Order List and verify Tax Amount and Amount Inclusive Tax on PurchaseOrderStatsPageHandler.
        OpenStatisticsPageForBlanketPurchaseOrder(PurchaseLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsBlanketPurchaseOrders()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9310 Blanket Purchase Order List.

        // Setup: Create Blanket Purchase Order without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Blanket Order", '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Blanket Purchase Order List and verify VAT Amount and Amount Inclusive VAT on PurchaseOrderStatisticsPageHandler.
        OpenStatisticsPageForBlanketPurchaseOrder(PurchaseLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchaseQuotes()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9306 Purchase Quotes.

        // Setup: Create Purchase Quote with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateTaxDetail(TaxDetail, CreateTaxGroup, LibraryRandom.RandDec(10, 2));
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Quote, CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := PurchaseLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Quotes and verify Tax Amount and Amount Inclusive Tax on PurchaseStatsPageHandler.
        OpenStatisticsPageForPurchaseQuote(PurchaseLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchaseQuotes()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9306 Purchase Quotes.

        // Setup: Create Purchase Quote without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Quote, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Quotes and verify VAT Amount and Amount Inclusive VAT on PurchaseStatisticsPageHandler.
        OpenStatisticsPageForPurchaseQuote(PurchaseLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchaseCreditMemos()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9309 Purchase Credit Memos.

        // Setup: Create Purchase Credit Memo with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateTaxDetail(TaxDetail, CreateTaxGroup, LibraryRandom.RandDec(10, 2));
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := PurchaseLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Credit Memos and verify Tax Amount and Amount Inclusive Tax on PurchaseStatsPageHandler.
        OpenStatisticsPageForPurchaseCreditMemo(PurchaseLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchaseCreditMemos()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9309 Purchase Credit Memos.

        // Setup: Create Purchase Credit Memo without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Credit Memos and verify VAT Amount and Amount Inclusive VAT on PurchaseStatisticsPageHandler.
        OpenStatisticsPageForPurchaseCreditMemo(PurchaseLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchaseInvoices()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9308 Purchase Invoices.

        // Setup: Create Purchase Invoice with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreateTaxDetail(TaxDetail, CreateTaxGroup, LibraryRandom.RandDec(10, 2));
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := PurchaseLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Invoices and verify Tax Amount and Amount Inclusive Tax on PurchaseStatsPageHandler.
        OpenStatisticsPageForPurchaseInvoice(PurchaseLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchaseInvoices()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9308 Purchase Invoices.

        // Setup: Create Purchase Invoice without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."VAT %" * PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Invoices and verify VAT Amount and Amount Inclusive VAT on PurchaseStatisticsPageHandler.
        OpenStatisticsPageForPurchaseInvoice(PurchaseLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ServiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaServiceInvoices()
    var
        ServiceLine: Record "Service Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
        OldInvoiceRounding: Boolean;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9319 Service Invoices.

        // Setup: Create Service Invoice with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        OldInvoiceRounding := UpdateInvoiceRoundingOnSalesReceivablesSetup(false);  // Update Invoice Rounding to FALSE on Sales & Receivables Setup.
        CreateTaxDetail(TaxDetail, CreateTaxGroup, LibraryRandom.RandDec(10, 2));
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Invoice, CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := ServiceLine."Unit Price" * ServiceLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := ServiceLine."Unit Price" * ServiceLine.Quantity + TaxAmount;

        // Enqueue required inside ServiceStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Service Invoices and verify Tax Amount and Amount Inclusive Tax on ServiceStatsPageHandler.
        OpenStatisticsPageForServiceInvoice(ServiceLine."Document No.");

        // Tear Down.
        UpdateInvoiceRoundingOnSalesReceivablesSetup(OldInvoiceRounding);
    end;

    [Test]
    [HandlerFunctions('ServiceStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsServiceInvoices()
    var
        ServiceLine: Record "Service Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
        OldInvoiceRounding: Boolean;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9319 Service Invoices.

        // Setup: Create Service Invoice without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize;
        OldInvoiceRounding := UpdateInvoiceRoundingOnSalesReceivablesSetup(false);  // Update Invoice Rounding to FALSE on Sales & Receivables Setup.
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Invoice, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := ServiceLine."Unit Price" * ServiceLine.Quantity * ServiceLine."VAT %" / 100;
        AmountIncVAT := ServiceLine."Unit Price" * ServiceLine.Quantity + VATAmount;

        // Enqueue required inside ServiceStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Service Invoices and verify VAT Amount and Amount Inclusive VAT on ServiceStatisticsPageHandler.
        OpenStatisticsPageForServiceInvoice(ServiceLine."Document No.");

        // Tear Down.
        UpdateInvoiceRoundingOnSalesReceivablesSetup(OldInvoiceRounding);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler2')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: array[2] of Record "Tax Detail";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Sales Tax]
        // [SCENARIO 375493] Statistics for Sales Order shows correct Tax Amount when complex fractional tax percents present for Tax Area.

        // [GIVEN] Tax Area with two Tax Jurisdictions, each with fractional tax percents: 6.875 % and 0.25 %.
        Initialize;
        TaxGroupCode := CreateTaxGroup;
        CreateTaxDetail(TaxDetail[1], TaxGroupCode, 6.875); // specific value needed for test
        CreateTaxDetail(TaxDetail[2], TaxGroupCode, 0.25); // specific value needed for test
        TaxAreaCode := CreateTaxAreaWithLine(TaxDetail[1]."Tax Jurisdiction Code");
        CreateTaxAreaLine(TaxAreaCode, TaxDetail[2]."Tax Jurisdiction Code");

        // [GIVEN] Sales Order with Tax Area and Unit Price = 75
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, TaxAreaCode);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, 1, TaxGroupCode, TaxAreaCode, true, 0, 75, 75); // specific values needed for test

        // [WHEN] Statistics opened for Sales Order
        // [THEN] On Statistics page: Tax Amount = 5.34
        LibraryVariableStorage.Enqueue(5.34); // specific value for SalesOrderStatsPageHandler2 verification
        OpenStatisticsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler2')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesOrderThreeTaxAreas()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Sales Tax]
        // [SCENARIO 375322] Statistics for Sales Order shows correct Tax Amount when there are three Tax Area with fractional tax Amounts.

        // [GIVEN] Three Tax Areas with with tax percents: 10 %.
        Initialize;
        TaxGroupCode := CreateTaxGroup;
        CreateTaxDetail(TaxDetail, TaxGroupCode, 10); // specific value needed for test
        for i := 1 to 3 do
            TaxAreaCode[i] := CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code");

        // [GIVEN] Sales Order with three lines with Tax Areas, each Unit Price = 13.333
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, TaxAreaCode[1]);
        for i := 1 to 3 do
            CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, 1, TaxGroupCode, TaxAreaCode[i], true, 0, 13.333, 13.333); // specific values needed for test

        // [WHEN] Statistics opened for Sales Order
        // [THEN] On Statistics page: Tax Amount = 4 (13.333 * 10% * 3 => 3.9999, rounded to 4.00)
        LibraryVariableStorage.Enqueue(4); // specific value for SalesOrderStatsPageHandler2 verification
        OpenStatisticsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler2')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesOrderCanadaRounding()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxArea: Record "Tax Area";
        TaxDetail: array[2] of Record "Tax Detail";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Sales Tax]
        // [SCENARIO 381348] Statistics for Sales Order shows correct Tax Amount by rounding each Sales Tax Line per Tax Jurisdiction

        // [GIVEN] Tax Area with two Tax Jurisdictions for Country/Region = "CA", each with fractional tax percents: 6.875 % and 0.25 %.
        Initialize;
        TaxGroupCode := CreateTaxGroup;
        CreateTaxDetail(TaxDetail[1], TaxGroupCode, 6.875); // specific value needed for test
        CreateTaxDetail(TaxDetail[2], TaxGroupCode, 0.25); // specific value needed for test
        TaxAreaCode := CreateTaxAreaWithSpecificCountryRegionAndLine(TaxDetail[1]."Tax Jurisdiction Code", TaxArea."Country/Region"::CA);
        CreateTaxAreaLine(TaxAreaCode, TaxDetail[2]."Tax Jurisdiction Code");

        // [GIVEN] Sales Order with Tax Area and Unit Price = 75
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, TaxAreaCode);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, 1, TaxGroupCode, TaxAreaCode, true, 0, 75, 75); // specific values needed for test

        // [WHEN] Statistics opened for Sales Order
        // [THEN] On Statistics page: Tax Amount = 5.35 (75 * 6.875 / 100 = 5.15625 (rounded = 5.16); 75 * 0.25 / 100 = 0.1875 (rounded = 0.19); Total = 5.16 + 0.19 = 5.35)
        LibraryVariableStorage.Enqueue(5.35); // specific value for SalesOrderStatsPageHandler2 verification
        OpenStatisticsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler2')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesInvoiceWithPositiveAndNegativeAmounts()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO 318205] Statistics for Sales Invoice with positive and negative Line Amounts shows correct Tax Amount.
        Initialize;

        // [GIVEN] Tax setup with Tax Detail having "Tax Below Maximum" := 1, "Maximum Amount/Qty." = 5000.
        TaxGroupCode := CreateTaxGroup;
        CreateTaxDetail(TaxDetail, TaxGroupCode, 1);
        TaxDetail."Maximum Amount/Qty." := 5000;
        TaxDetail.Modify();
        TaxAreaCode := CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code");

        // [GIVEN] G/L Account with Tax setup.
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Tax Group Code" := TaxGroupCode;
        GLAccount.Modify();

        // [GIVEN] Sales Invoice with:
        // [GIVEN] Sales Line with Type = "Item", Qty = 1, Amount = 6000;
        // [GIVEN] Sales Line with Type = "G/L Account"", Qty = -1, Amount = 1000.
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, TaxAreaCode);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, 1, TaxGroupCode, TaxAreaCode, true, 0, 6000, 6000);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", -1, TaxGroupCode, TaxAreaCode, true, 0, 1000, 1000);
        SalesLine."No." := GLAccount."No.";
        SalesLine.Modify();

        // [WHEN] Statistics opened for Sales Invoice.
        // [THEN] On Statistics page: Tax Amount = 50 ((6000 - 1000) / 100 = 50)
        LibraryVariableStorage.Enqueue(50);
        OpenStatisticsPageForSalesInvoice(SalesHeader."No.");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Option; TaxGroupCode: Code[20]; TaxAreaCode: Code[20]; TaxLiable: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, DocumentType, TaxAreaCode);
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 2),
          TaxGroupCode, TaxAreaCode, TaxLiable, LibraryRandom.RandInt(3), LibraryRandom.RandDec(2, 2),
          LibraryRandom.RandDec(2, 2));
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Option; TaxAreaCode: Code[20])
    begin
        with SalesHeader do begin
            "Document Type" := DocumentType;
            "No." := LibraryUTUtility.GetNewCode;
            "Tax Area Code" := TaxAreaCode;
            Insert;
        end;
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineType: Option; Qty: Decimal; TaxGroupCode: Code[20]; TaxAreaCode: Code[20]; TaxLiable: Boolean; VATPct: Decimal; UnitPrice: Decimal; LineAmount: Decimal)
    begin
        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            if FindLast then;

            "Document Type" := SalesHeader."Document Type";
            "Document No." := SalesHeader."No.";
            "Line No." += 10000;
            Type := LineType;
            Quantity := Qty;
            "Tax Group Code" := TaxGroupCode;
            "Tax Area Code" := TaxAreaCode;
            "Tax Liable" := TaxLiable;
            "VAT %" := VATPct;
            "Unit Price" := UnitPrice;
            "Line Amount" := LineAmount;
            Amount := LineAmount;
            Insert;
        end;
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Option; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode;
        PurchaseHeader."Tax Area Code" := TaxAreaCode;
        PurchaseHeader.Insert();

        PurchaseLine."Document Type" := DocumentType;
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := LibraryInventory.CreateItemNo;
        PurchaseLine."Direct Unit Cost" := LibraryRandom.RandDec(10, 2);
        PurchaseLine.Quantity := LibraryRandom.RandDec(10, 2);
        PurchaseLine."Line Amount" := LibraryRandom.RandDec(10, 2);
        PurchaseLine."VAT %" := LibraryRandom.RandInt(10);
        PurchaseLine."Tax Area Code" := TaxAreaCode;
        PurchaseLine."Tax Group Code" := TaxGroupCode;
        PurchaseLine."Tax Liable" := TaxLiable;
        PurchaseLine.Insert();
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; DocumentType: Option; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader."Document Type" := DocumentType;
        ServiceHeader."No." := LibraryUTUtility.GetNewCode;
        ServiceHeader."Tax Area Code" := TaxAreaCode;
        ServiceHeader.Insert();

        ServiceLine."Document Type" := ServiceHeader."Document Type";
        ServiceLine."Document No." := ServiceHeader."No.";
        ServiceLine."Line No." := LibraryRandom.RandInt(100);
        ServiceLine.Type := ServiceLine.Type::Item;
        ServiceLine."Unit Price" := LibraryRandom.RandDec(10, 2);
        ServiceLine.Quantity := LibraryRandom.RandDec(10, 2);
        ServiceLine."Tax Area Code" := TaxAreaCode;
        ServiceLine."Tax Group Code" := TaxGroupCode;
        ServiceLine."Tax Liable" := TaxLiable;
        ServiceLine."VAT %" := LibraryRandom.RandInt(10);
        ServiceLine.Insert();
    end;

    local procedure CreateTaxAreaWithSpecificCountryRegionAndLine(TaxJurisdictionCode: Code[10]; CountryRegion: Option) TaxAreaCode: Code[20]
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxAreaWithCountryRegion(CountryRegion);
        CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode);
    end;

    local procedure CreateTaxAreaWithLine(TaxJurisdictionCode: Code[10]): Code[10]
    var
        TaxArea: Record "Tax Area";
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        CreateTaxAreaLine(TaxArea.Code, TaxJurisdictionCode);
        exit(TaxArea.Code);
    end;

    local procedure CreateTaxAreaLine(TaxAreaCode: Code[20]; TaxJurisdictionCode: Code[10])
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        with TaxAreaLine do begin
            Init;
            "Tax Area" := TaxAreaCode;
            "Tax Jurisdiction Code" := TaxJurisdictionCode;
            Insert;
        end;
    end;

    local procedure CreateTaxDetail(var TaxDetail: Record "Tax Detail"; TaxGroupCode: Code[20]; TaxBelowMax: Decimal)
    begin
        TaxDetail."Tax Jurisdiction Code" := CreateTaxJurisdiction;
        TaxDetail."Tax Group Code" := TaxGroupCode;
        TaxDetail."Tax Below Maximum" := TaxBelowMax;
        TaxDetail.Insert();
    end;

    local procedure CreateTaxGroup(): Code[10]
    var
        TaxGroup: Record "Tax Group";
    begin
        TaxGroup.Code := LibraryUTUtility.GetNewCode10;
        TaxGroup.Insert();
        exit(TaxGroup.Code);
    end;

    local procedure CreateTaxJurisdiction(): Code[10]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Code := LibraryUTUtility.GetNewCode10;
        TaxJurisdiction.Insert();
        exit(TaxJurisdiction.Code);
    end;

    local procedure OpenStatisticsPageForServiceCreditMemo(No: Code[20])
    var
        ServiceCreditMemos: TestPage "Service Credit Memos";
    begin
        ServiceCreditMemos.OpenEdit;
        ServiceCreditMemos.FILTER.SetFilter("No.", No);
        ServiceCreditMemos.Statistics.Invoke;  // Opens Handler - ServiceStatisticsPageHandler and ServiceStatsPageHandler.
        ServiceCreditMemos.Close;
    end;

    local procedure OpenStatisticsPageForSalesQuote(No: Code[20])
    var
        SalesQuotes: TestPage "Sales Quotes";
    begin
        SalesQuotes.OpenEdit;
        SalesQuotes.FILTER.SetFilter("No.", No);
        SalesQuotes.Statistics.Invoke;  // Opens Handler - SalesStatisticsPageHandler and SalesQuotesStatsPageHandler.
        SalesQuotes.Close;
    end;

    local procedure OpenStatisticsPageForSalesOrder(No: Code[20])
    var
        SalesOrderList: TestPage "Sales Order List";
    begin
        SalesOrderList.OpenEdit;
        SalesOrderList.FILTER.SetFilter("No.", No);
        SalesOrderList.Statistics.Invoke;  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesOrderList.Close;
    end;

    local procedure OpenStatisticsPageForSalesInvoice(No: Code[20])
    var
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        SalesInvoiceList.OpenEdit;
        SalesInvoiceList.FILTER.SetFilter("No.", No);
        SalesInvoiceList.Statistics.Invoke;  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesInvoiceList.Close;
    end;

    local procedure OpenStatisticsPageForBlanketSalesOrder(No: Code[20])
    var
        BlanketSalesOrders: TestPage "Blanket Sales Orders";
    begin
        BlanketSalesOrders.OpenEdit;
        BlanketSalesOrders.FILTER.SetFilter("No.", No);
        BlanketSalesOrders.Statistics.Invoke;  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        BlanketSalesOrders.Close;
    end;

    local procedure OpenStatisticsPageForSalesReturnOrder(No: Code[20])
    var
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        SalesReturnOrderList.OpenEdit;
        SalesReturnOrderList.FILTER.SetFilter("No.", No);
        SalesReturnOrderList.Statistics.Invoke;  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesReturnOrderList.Close;
    end;

    local procedure OpenStatisticsPageForSalesCreditMemo(No: Code[20])
    var
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        SalesCreditMemos.OpenEdit;
        SalesCreditMemos.FILTER.SetFilter("No.", No);
        SalesCreditMemos.Statistics.Invoke;  // Opens Handler - SalesStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesCreditMemos.Close;
    end;

    local procedure OpenStatisticsPageForPurchaseOrder(No: Code[20])
    var
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        PurchaseOrderList.OpenEdit;
        PurchaseOrderList.FILTER.SetFilter("No.", No);
        PurchaseOrderList.Statistics.Invoke;  // Opens Handler - PurchaseOrderStatsPageHandler and PurchaseOrderStatisticsPageHandler.
        PurchaseOrderList.Close;
    end;

    local procedure OpenStatisticsPageForPurchaseReturnOrder(No: Code[20])
    var
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        PurchaseReturnOrderList.OpenEdit;
        PurchaseReturnOrderList.FILTER.SetFilter("No.", No);
        PurchaseReturnOrderList.Statistics.Invoke;  // Opens Handler - PurchaseOrderStatsPageHandler and PurchaseOrderStatisticsPageHandler.
        PurchaseReturnOrderList.Close;
    end;

    local procedure OpenStatisticsPageForBlanketPurchaseOrder(No: Code[20])
    var
        BlanketPurchaseOrders: TestPage "Blanket Purchase Orders";
    begin
        BlanketPurchaseOrders.OpenEdit;
        BlanketPurchaseOrders.FILTER.SetFilter("No.", No);
        BlanketPurchaseOrders.Statistics.Invoke;  // Opens Handler - PurchaseOrderStatisticsPageHandler and PurchaseOrderStatsPageHandler.
        BlanketPurchaseOrders.Close;
    end;

    local procedure OpenStatisticsPageForPurchaseQuote(No: Code[20])
    var
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        PurchaseQuotes.OpenEdit;
        PurchaseQuotes.FILTER.SetFilter("No.", No);
        PurchaseQuotes.Statistics.Invoke;  // Opens Handler - PurchaseStatsPageHandler and PurchaseStatisticsPageHandler.
        PurchaseQuotes.Close;
    end;

    local procedure OpenStatisticsPageForPurchaseCreditMemo(No: Code[20])
    var
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        PurchaseCreditMemos.OpenEdit;
        PurchaseCreditMemos.FILTER.SetFilter("No.", No);
        PurchaseCreditMemos.Statistics.Invoke;  // Opens Handler-  PurchaseStatsPageHandler and PurchaseStatisticsPageHandler..
        PurchaseCreditMemos.Close;
    end;

    local procedure OpenStatisticsPageForPurchaseInvoice(No: Code[20])
    var
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        PurchaseInvoices.OpenEdit;
        PurchaseInvoices.FILTER.SetFilter("No.", No);
        PurchaseInvoices.Statistics.Invoke;  // Opens Handler - PurchaseStatsPageHandler and PurchaseStatisticsPageHandler.
        PurchaseInvoices.Close;
    end;

    local procedure OpenStatisticsPageForServiceInvoice(No: Code[20])
    var
        ServiceInvoices: TestPage "Service Invoices";
    begin
        ServiceInvoices.OpenEdit;
        ServiceInvoices.FILTER.SetFilter("No.", No);
        ServiceInvoices.Statistics.Invoke;  // Opens Handler - ServiceStatsPageHandler and ServiceStatisticsPageHandler.
        ServiceInvoices.Close;
    end;

    local procedure UpdateInvoiceRoundingOnSalesReceivablesSetup(InvoiceRounding: Boolean) OldInvoiceRounding: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldInvoiceRounding := SalesReceivablesSetup."Invoice Rounding";
        SalesReceivablesSetup.Validate("Invoice Rounding", InvoiceRounding);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure VerifyTaxOnStatisticsPage(TaxAmount: Decimal; AmountIncTax: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ExpectedTaxAmount: Variant;
        ExpectedAmountIncTax: Variant;
    begin
        GeneralLedgerSetup.Get();
        LibraryVariableStorage.Dequeue(ExpectedTaxAmount);
        LibraryVariableStorage.Dequeue(ExpectedAmountIncTax);
        Assert.AreNearlyEqual(ExpectedTaxAmount, TaxAmount, GeneralLedgerSetup."Amount Rounding Precision", AmountMustEqualMsg);
        Assert.AreNearlyEqual(ExpectedAmountIncTax, AmountIncTax, GeneralLedgerSetup."Amount Rounding Precision", AmountMustEqualMsg);
        Assert.AreNotEqual(ExpectedTaxAmount, 0, 'Tax Amount must not be zero');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsPageHandler(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        VerifyTaxOnStatisticsPage(SalesOrderStats."VATAmount[2]".AsDEcimal, SalesOrderStats."TotalAmount2[1]".AsDEcimal);
        SalesOrderStats.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsPageHandler2(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        SalesOrderStats.TaxAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal);
        SalesOrderStats.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuotesStatsPageHandler(var SalesStats: TestPage "Sales Stats.")
    begin
        VerifyTaxOnStatisticsPage(SalesStats.TaxAmount.AsDEcimal, SalesStats.TotalAmount2.AsDEcimal);
        SalesStats.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    begin
        VerifyTaxOnStatisticsPage(SalesStatistics.VATAmount.AsDEcimal, SalesStatistics.TotalAmount2.AsDEcimal);
        SalesStatistics.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        VerifyTaxOnStatisticsPage(SalesOrderStatistics.VATAmount.AsDEcimal, SalesOrderStatistics."TotalAmount2[1]".AsDEcimal);
        SalesOrderStatistics.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatsPageHandler(var ServiceStats: TestPage "Service Stats.")
    begin
        VerifyTaxOnStatisticsPage(ServiceStats.VATAmount.AsDEcimal, ServiceStats."TotalAmount2[1]".AsDEcimal);
        ServiceStats.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatisticsPageHandler(var ServiceStatistics: TestPage "Service Statistics")
    begin
        VerifyTaxOnStatisticsPage(ServiceStatistics."VAT Amount_General".AsDEcimal, ServiceStatistics."Total Incl. VAT_General".AsDEcimal);
        ServiceStatistics.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatsPageHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    begin
        VerifyTaxOnStatisticsPage(PurchaseOrderStats."VATAmount[2]".AsDEcimal, PurchaseOrderStats."TotalAmount2[1]".AsDEcimal);
        PurchaseOrderStats.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatsPageHandler(var PurchaseStats: TestPage "Purchase Stats.")
    begin
        VerifyTaxOnStatisticsPage(PurchaseStats.TaxAmount.AsDEcimal, PurchaseStats.TotalAmount2.AsDEcimal);
        PurchaseStats.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        VerifyTaxOnStatisticsPage(PurchaseOrderStatistics."VATAmount[1]".AsDEcimal, PurchaseOrderStatistics.TotalInclVAT_General.AsDEcimal);
        PurchaseOrderStatistics.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    begin
        VerifyTaxOnStatisticsPage(PurchaseStatistics.VATAmount.AsDEcimal, PurchaseStatistics.TotalAmount2.AsDEcimal);
        PurchaseStatistics.OK.Invoke;
    end;
}

