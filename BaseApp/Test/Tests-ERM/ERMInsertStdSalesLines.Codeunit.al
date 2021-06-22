codeunit 134563 "ERM Insert Std. Sales Lines"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Standard Lines]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUTUtility: Codeunit "Library UT Utility";
        ValueMustExistMsg: Label '%1 must exist.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryERM: Codeunit "Library - ERM";
        isInitialized: Boolean;
        InvalidNotificationIdMsg: Label 'Invalid notification ID';
        RefDocType: Option Quote,"Order",Invoice,"Credit Memo";
        RefMode: Option Manual,Automatic,"Always Ask";
        FieldNotVisibleErr: Label 'Field must be visible.';

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoManualSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Manual mode] [Order]
        // [SCENARIO] There is no sales standard codes notification on order validate Sell-to Customer No. when Insert Rec. Lines On Orders = Manual
        Initialize;

        // [GIVEN] Customer CUST with standard sales code where Insert Rec. Lines On Orders = Manual
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::Order, RefMode::Manual);
        // [GIVEN] Create new sales order
        CreateSalesOrder(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesOrderCustomerNo(SalesHeader, CustomerNo);

        // [THEN] There is no sales standard codes notification
        VerifyNoSalesStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoAutomaticSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Automatic mode] [Order]
        // [SCENARIO] Recurring sales line created on order validate Sell-to Customer No. when Insert Rec. Lines On Orders = Automatic
        Initialize;

        // [GIVEN] Customer CUST with standard sales code where Insert Rec. Lines On Orders = Automatic
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::Order, RefMode::Automatic);
        // [GIVEN] Create new sales order
        CreateSalesOrder(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesOrderCustomerNo(SalesHeader, CustomerNo);

        // [THEN] Recurring sales line created
        VerifySalesLine(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoAlwaysAskSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Always Ask mode] [Order]
        // [SCENARIO] Standard codes notification created on order validate Sell-to Customer No. when Insert Rec. Lines On Orders = "Always Ask"
        Initialize;

        // [GIVEN] Customer CUST with standard sales code where Insert Rec. Lines On Orders = "Always Ask"
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::Order, RefMode::"Always Ask");
        // [GIVEN] Create new sales order
        CreateSalesOrder(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesOrderCustomerNo(SalesHeader, CustomerNo);

        // [THEN] Standard sales code notification created
        VerifySalesStdCodesNotification(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoWithoutSalesCodeOrder()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Order]
        // [SCENARIO] There is no sales standard codes notification on order validate Sell-to Customer No. for customer without Standard Sales Codes
        Initialize;

        // [GIVEN] Customer CUST without standard sales codes
        CustomerNo := LibrarySales.CreateCustomerNo;
        // [GIVEN] Create new sales order
        CreateSalesOrder(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesOrderCustomerNo(SalesHeader, CustomerNo);

        // [THEN] There is no sales standard codes notification
        VerifyNoSalesStdCodesNotification;
    end;

    [Test]
    [HandlerFunctions('StandardCustomerSalesCodesCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure SellToCustNoAutomaticSalesCodesCancelOrder()
    var
        SalesHeader: Record "Sales Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Automatic mode] [Order]
        // [SCENARIO] There is no sales standard codes notification on order validate Sell-to Customer No. for customer with multiple Standard Sales Codes where Insert Rec. Lines On Orders = Automatic and cancel lookup list of standard codes
        Initialize;

        // [GIVEN] Customer CUST without standard codes
        CustomerNo := LibrarySales.CreateCustomerNo;

        // [GIVEN] New sales order
        CreateSalesOrder(SalesHeader);

        // [GIVEN] Set Sell-to Customer No. = CUST
        UpdateSalesHeaderSellToCustomerNo(SalesHeader, CustomerNo);

        // [GIVEN] Create multiple standard sales codes where Insert Rec. Lines On Orders = Automatic
        CreateMultipleStandardCustomerSalesCodesForCustomer(RefDocType::Order, RefMode::Automatic, CustomerNo);

        // [WHEN] Function GetSalesRecurringLines is being run and push Cancel button in the lookup list of standard codes
        StandardCodesMgt.GetSalesRecurringLines(SalesHeader);

        // [THEN] There is no sales standard codes notification
        VerifyNoSalesStdCodesNotification;
    end;

    [Test]
    [HandlerFunctions('StandardCustomerSalesCodesCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure SellToCustNoAlwaysAskSalesCodesCancelOrder()
    var
        SalesHeader: Record "Sales Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Always Ask mode] [Order]
        // [SCENARIO] There is no sales standard codes notification on GetSalesRecurringLines run for customer with multiple Standard Sales Codes where Insert Rec. Lines On Orders = "Always Ask" and cancel lookup list of standard codes
        Initialize;

        // [GIVEN] Customer CUST without standard codes
        CustomerNo := LibrarySales.CreateCustomerNo;
        // [GIVEN] New sales order
        CreateSalesOrder(SalesHeader);

        // [GIVEN] Set Sell-to Customer No. = CUST
        UpdateSalesHeaderSellToCustomerNo(SalesHeader, CustomerNo);

        // [GIVEN] Create multiple standard sales codes where Insert Rec. Lines On Orders = "Always Ask"
        CreateMultipleStandardCustomerSalesCodesForCustomer(RefDocType::Order, RefMode::"Always Ask", CustomerNo);

        // [WHEN] Function GetSalesRecurringLines is being run and push Cancel button in the lookup list of standard codes
        StandardCodesMgt.GetSalesRecurringLines(SalesHeader);

        // [THEN] There is no sales standard codes notification
        VerifyNoSalesStdCodesNotification;
    end;

    [Test]
    [HandlerFunctions('StandardCustomerSalesCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure SellToCustNoAutomaticMultipleSalesCodesOrder()
    var
        SalesHeader: Record "Sales Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Automatic mode] [Order]
        // [SCENARIO] Sales line created by GetSalesRecurringLines for customer with multiple Standard Sales Codes when Insert Rec. Lines On Orders = Automatic
        Initialize;

        // [GIVEN] Customer CUST without standard codes
        CustomerNo := LibrarySales.CreateCustomerNo;
        // [GIVEN] New sales order
        CreateSalesOrder(SalesHeader);
        // [GIVEN] Set Sell-to Customer No. = CUST
        UpdateSalesHeaderSellToCustomerNo(SalesHeader, CustomerNo);
        // [GIVEN] Create multiple standard sales codes where Insert Rec. Lines On Orders = Automatic
        CreateMultipleStandardCustomerSalesCodesForCustomer(RefDocType::Order, RefMode::Automatic, CustomerNo);

        // [WHEN] StandardCodesMgt.GetSalesRecurringLines is being run
        StandardCodesMgt.GetSalesRecurringLines(SalesHeader);

        // [THEN] Sales line created with Item from standard sales code
        VerifySalesLine(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('StandardCustomerSalesCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure SellToCustNoAlwaysAskMultipleSalesCodesOrder()
    var
        SalesHeader: Record "Sales Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Always Ask mode] [Order]
        // [SCENARIO] Sales line created by GetSalesRecurringLines for customer with multiple Standard Sales Codes when Insert Rec. Lines On Cr. Memos = "Always Ask"
        Initialize;

        // [GIVEN] Customer CUST without standard codes
        CustomerNo := LibrarySales.CreateCustomerNo;
        // [GIVEN] New sales order
        CreateSalesOrder(SalesHeader);
        // [GIVEN] Set Sell-to Customer No. = CUST
        UpdateSalesHeaderSellToCustomerNo(SalesHeader, CustomerNo);
        // [GIVEN] Create multiple standard sales codes where Insert Rec. Lines On Orders = "Always Ask"
        CreateMultipleStandardCustomerSalesCodesForCustomer(RefDocType::Order, RefMode::"Always Ask", CustomerNo);

        // [WHEN] StandardCodesMgt.GetSalesRecurringLines is being run
        StandardCodesMgt.GetSalesRecurringLines(SalesHeader);

        // [THEN] Sales line created with Item from standard sales code
        VerifySalesLine(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoManualSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Manual mode] [Quote]
        // [SCENARIO] There is no sales standard codes notification on quote validate Sell-to Customer No. when Insert Rec. Lines On Quotes = Manual
        Initialize;

        // [GIVEN] Customer CUST with standard sales code where Insert Rec. Lines On Quotes = Manual
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::Quote, RefMode::Manual);
        // [GIVEN] Create new sales quote
        CreateSalesQuote(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesQuoteCustomerNo(SalesHeader, CustomerNo);

        // [THEN] There is no sales standard codes notification
        VerifyNoSalesStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoAutomaticSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Automatic mode] [Quote]
        // [SCENARIO] Standard codes notification created on quote validate Sell-to Customer No. when Insert Rec. Lines On Quotes = Automatic
        Initialize;

        // [GIVEN] Customer CUST with standard sales code where Insert Rec. Lines On Quotes = Automatic
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::Quote, RefMode::Automatic);
        // [GIVEN] Create new sales quote
        CreateSalesQuote(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesQuoteCustomerNo(SalesHeader, CustomerNo);

        // [THEN] Recurring sales line created
        VerifySalesLine(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoAlwaysAskSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Always Ask mode] [Quote]
        // [SCENARIO] Standard codes notification created on quote validate Sell-to Customer No. when Insert Rec. Lines On Quotes = "Always Ask"
        Initialize;

        // [GIVEN] Customer CUST with standard sales code where Insert Rec. Lines On Quotes = "Always Ask"
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::Quote, RefMode::"Always Ask");
        // [GIVEN] Create new sales quote
        CreateSalesQuote(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesQuoteCustomerNo(SalesHeader, CustomerNo);

        // [THEN] Standard sales code notification created
        VerifySalesStdCodesNotification(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoWithoutSalesCodeQuote()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Quote]
        // [SCENARIO] There is no sales standard codes notification on quote validate Sell-to Customer No. for customer without Standard Sales Codes
        Initialize;

        // [GIVEN] Customer CUST without standard sales codes
        CustomerNo := LibrarySales.CreateCustomerNo;
        // [GIVEN] Create new sales quote
        CreateSalesQuote(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesQuoteCustomerNo(SalesHeader, CustomerNo);

        // [THEN] There is no sales standard codes notification
        VerifyNoSalesStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoManualSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Manual mode] [Invoice]
        // [SCENARIO] There is no sales standard codes notification on invoice validate Sell-to Customer No. when Insert Rec. Lines On Invoices = Manual
        Initialize;

        // [GIVEN] Customer CUST with standard sales code where Insert Rec. Lines On Invoices = Manual
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::Invoice, RefMode::Manual);
        // [GIVEN] Create new sales invoice
        CreateSalesInvoice(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesInvoiceCustomerNo(SalesHeader, CustomerNo);

        // [THEN] There is no sales standard codes notification
        VerifyNoSalesStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoAutomaticSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Automatic mode] [Invoice]
        // [SCENARIO] Standard codes notification created on invoice validate Sell-to Customer No. when Insert Rec. Lines On Invoices = Automatic
        Initialize;

        // [GIVEN] Customer CUST with standard sales code where Insert Rec. Lines On Invoices = Automatic
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::Invoice, RefMode::Automatic);
        // [GIVEN] Create new sales invoice
        CreateSalesInvoice(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesInvoiceCustomerNo(SalesHeader, CustomerNo);

        // [THEN] Recurring sales line created
        VerifySalesLine(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoAlwaysAskSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Always Ask mode] [Invoice]
        // [SCENARIO] Standard codes notification created on invoice validate Sell-to Customer No. when Insert Rec. Lines On Invoices = "Always Ask"
        Initialize;

        // [GIVEN] Customer CUST with standard sales code where Insert Rec. Lines On Invoices = "Always Ask"
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::Invoice, RefMode::"Always Ask");
        // [GIVEN] Create new sales invoice
        CreateSalesInvoice(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesInvoiceCustomerNo(SalesHeader, CustomerNo);

        // [THEN] Standard sales code notification created
        VerifySalesStdCodesNotification(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoWithoutSalesCodeInvoice()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO] There is no sales standard codes notification on invoice validate Sell-to Customer No. for customer without Standard Sales Codes
        Initialize;

        // [GIVEN] Customer CUST without standard sales codes
        CustomerNo := LibrarySales.CreateCustomerNo;
        // [GIVEN] Create new sales invoice
        CreateSalesInvoice(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesInvoiceCustomerNo(SalesHeader, CustomerNo);

        // [THEN] There is no sales standard codes notification
        VerifyNoSalesStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoManualSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Manual mode] [Credit memo]
        // [SCENARIO] There is no sales standard codes notification on cr memo validate Sell-to Customer No. when Insert Rec. Lines On Cr. Memos = Manual
        Initialize;

        // [GIVEN] Customer CUST with standard sales code where Insert Rec. Lines On Cr. Memos = Manual
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::"Credit Memo", RefMode::Manual);
        // [GIVEN] Create new sales credit memo
        CreateSalesCrMemo(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesCrMemoCustomerNo(SalesHeader, CustomerNo);

        // [THEN] There is no sales standard codes notification
        VerifyNoSalesStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoAutomaticSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Automatic mode] [Credit memo]
        // [SCENARIO] There is no sales standard codes notification on cr memo validate Sell-to Customer No. when Insert Rec. Lines On Cr. Memos = Automatic
        Initialize;

        // [GIVEN] Customer CUST with standard sales code where Insert Rec. Lines On Cr. Memos = Automatic
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::"Credit Memo", RefMode::Automatic);
        // [GIVEN] Open new sales credit memo card
        CreateSalesCrMemo(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesCrMemoCustomerNo(SalesHeader, CustomerNo);

        // [THEN] Recurring sales line created
        VerifySalesLine(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoAlwaysAskSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Always Ask mode] [Credit memo]
        // [SCENARIO] There is no sales standard codes notification on cr memo validate Sell-to Customer No. when Insert Rec. Lines On Cr. Memos = "Always Ask"
        Initialize;

        // [GIVEN] Customer CUST with standard sales code where Insert Rec. Lines On Cr. Memos = "Always Ask"
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::"Credit Memo", RefMode::"Always Ask");
        // [GIVEN] Open new sales credit memo card
        CreateSalesCrMemo(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesCrMemoCustomerNo(SalesHeader, CustomerNo);

        // [THEN] Standard sales code notification created
        VerifySalesStdCodesNotification(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoWithoutSalesCodeCrMemo()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Credit memo]
        // [SCENARIO] There is no sales standard codes notification on cr memo validate Sell-to Customer No. for customer without Standard Sales Codes
        Initialize;

        // [GIVEN] Customer CUST without standard sales codes
        CustomerNo := LibrarySales.CreateCustomerNo;
        // [GIVEN] Open new sales credit memo card
        CreateSalesCrMemo(SalesHeader);

        // [WHEN] Set Sell-to Customer No. = CUST
        SetSalesCrMemoCustomerNo(SalesHeader, CustomerNo);

        // [THEN] There is no sales standard codes notification
        VerifyNoSalesStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoInsertStdCustSalesLinesWhenCreateNewSalesOrderFromCustomerList()
    var
        Customer: Record Customer;
        CustomerList: TestPage "Customer List";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI] [Automatic mode] [Order]
        // [SCENARIO 209394] Standard sales code notification created when new Sales Order is created from Customer List
        Initialize;

        // [GIVEN] Customer "C" with Std. Sales Code where Insert Rec. Lines On Orders = Automatic
        Customer.Get(GetNewCustNoWithStandardSalesCode(RefDocType::Order, RefMode::Automatic));

        // [GIVEN] Customer List on customer "C" record
        CustomerList.OpenEdit;
        CustomerList.GotoRecord(Customer);

        // [GIVEN] Perform page action: New Sales Document -> Sales Order
        SalesOrder.Trap;
        CustomerList.NewSalesOrder.Invoke;

        // [WHEN] Activate "Sell-to Customer No." field
        SalesOrder."Sell-to Customer No.".Activate;

        // [THEN] Standard sales code notification created
        // Verify only notification ID due to test limitations
        VerifySalesStdCodesNotificationId;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoInsertStdCustSalesLinesWhenCreateNewSalesInvoiceFromCustomerList()
    var
        Customer: Record Customer;
        CustomerList: TestPage "Customer List";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI] [Automatic mode] [Invoice]
        // [SCENARIO 211206] Standard sales code notification created when new Sales Invoice is created from Customer List
        Initialize;

        // [GIVEN] Customer "C" with Std. Sales Code where Insert Rec. Lines On Invoices = Automatic
        Customer.Get(GetNewCustNoWithStandardSalesCode(RefDocType::Invoice, RefMode::Automatic));

        // [GIVEN] Customer List on customer "C" record
        CustomerList.OpenEdit;
        CustomerList.GotoRecord(Customer);

        // [GIVEN] Perform page action: New Sales Document -> Sales Invoice
        SalesInvoice.Trap;
        CustomerList.NewSalesInvoice.Invoke;

        // [WHEN] Activate "Sell-to Customer No." field
        SalesInvoice."Sell-to Customer No.".Activate;

        // [THEN] Standard sales code notification created
        // Verify only notification ID due to test limitations
        VerifySalesStdCodesNotificationId;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoInsertStdCustSalesLinesWhenCreateNewSalesQuoteFromCustomerList()
    var
        Customer: Record Customer;
        CustomerList: TestPage "Customer List";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI] [Automatic mode] [Quote]
        // [SCENARIO 211206] Standard sales code notification created when new Sales Quote is created from Customer List
        Initialize;

        // [GIVEN] Customer "C" with Std. Sales Code where Insert Rec. Lines On Quotes = Automatic
        Customer.Get(GetNewCustNoWithStandardSalesCode(RefDocType::Quote, RefMode::Automatic));

        // [GIVEN] Customer List on customer "C" record
        CustomerList.OpenEdit;
        CustomerList.GotoRecord(Customer);

        // [GIVEN] Perform page action: New Sales Document -> Sales Quote
        SalesQuote.Trap;
        CustomerList.NewSalesQuote.Invoke;

        // [WHEN] Activate "Sell-to Customer No." field
        SalesQuote."Sell-to Customer No.".Activate;

        // [THEN] Standard sales code notification created
        // Verify only notification ID due to test limitations
        VerifySalesStdCodesNotificationId;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoInsertStdCustSalesLinesWhenCreateNewSalesCrMemoFromCustomerList()
    var
        Customer: Record Customer;
        CustomerList: TestPage "Customer List";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [UI] [Automatic mode] [Credit Memo]
        // [SCENARIO 211206] Standard sales code notification created when new Sales Cr.Memo is created from Customer List
        Initialize;

        // [GIVEN] Customer "C" with Std. Sales Code where Insert Rec. Lines On Cr. Memos = Automatic
        Customer.Get(GetNewCustNoWithStandardSalesCode(RefDocType::"Credit Memo", RefMode::Automatic));

        // [GIVEN] Customer List on customer "C" record
        CustomerList.OpenEdit;
        CustomerList.GotoRecord(Customer);

        // [GIVEN] Perform page action: New Sales Document -> Sales Credit Memo
        SalesCreditMemo.Trap;
        CustomerList.NewSalesCrMemo.Invoke;

        // [WHEN] Activate "Sell-to Customer No." field
        SalesCreditMemo."Sell-to Customer No.".Activate;

        // [THEN] Standard sales code notification created
        // Verify only notification ID due to test limitations
        VerifySalesStdCodesNotificationId;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardCustomerSalesCodesFieldsVisibleForSuiteAppArea()
    var
        StandardCustomerSalesCodes: TestPage "Standard Customer Sales Codes";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Standard Customer Sales Codes new fields are visible for application area #Suite

        // [GIVEN] Enable #suite application area
        LibraryApplicationArea.EnableFoundationSetup;

        // [WHEN] Open page Standard Customer Sales Codes
        StandardCustomerSalesCodes.OpenEdit;

        // [THEN] Fields "Insert Rec Lines On..." are visible
        Assert.IsTrue(StandardCustomerSalesCodes."Insert Rec. Lines On Quotes".Visible, FieldNotVisibleErr);
        Assert.IsTrue(StandardCustomerSalesCodes."Insert Rec. Lines On Orders".Visible, FieldNotVisibleErr);
        Assert.IsTrue(StandardCustomerSalesCodes."Insert Rec. Lines On Invoices".Visible, FieldNotVisibleErr);
        Assert.IsTrue(StandardCustomerSalesCodes."Insert Rec. Lines On Cr. Memos".Visible, FieldNotVisibleErr);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Blanket Order] [UT]
        // [SCENARIO 283678] Standard codes notification is not created for blanket order
        Initialize;

        // [GIVEN] Customer CUST with standard sales code where Insert Rec. Lines On Orders = Manual
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::Order, RefMode::Manual);

        // [GIVEN] Create new sales blanket order
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order");

        // [GIVEN] Specify "Sell-to Customer No." = CUST
        SetSalesBlanketOrderCustomerNo(SalesHeader, CustomerNo);

        // [THEN] Standard sales code notification is not created
        VerifyNoSalesStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCustNoSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Return Order] [UT]
        // [SCENARIO 283678] Standard codes notification is not created for return order
        Initialize;

        // [GIVEN] Customer CUST with standard sales code where Insert Rec. Lines On Orders = Manual
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::Order, RefMode::Manual);

        // [GIVEN] Create new sales return order
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order");

        // [GIVEN] Specify "Sell-to Customer No." = CUST
        SetSalesReturnOrderCustomerNo(SalesHeader, CustomerNo);

        // [THEN] Standard sales code notification is not created
        VerifyNoSalesStdCodesNotification;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardSalesCodeAndSalesOrderWithDifferentCurrency()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Order] [UT]
        // [SCENARIO 311677] Standard codes notification is not created when Standard Sales Code currency code <> currency code of sales document
        Initialize;

        // [GIVEN] Local currency customer CUST with standard sales code "AA" where Insert Rec. Lines On Orders = "Always Ask"
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::Order, RefMode::"Always Ask");

        // [GIVEN] Set Currency Code = "XXX" for standard sales code "AA"
        UpdateStandardSalesCodeWithNewCurrencyCode(CustomerNo, LibraryERM.CreateCurrencyWithRandomExchRates());

        // [GIVEN] Create new sales order
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order);

        // [GIVEN] Specify "Sell-to Customer No." = CUST
        SetSalesOrderCustomerNo(SalesHeader, CustomerNo);

        // [THEN] Standard sales code notification is not created
        VerifyNoSalesStdCodesNotification;
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesCodeNotificationOnCurrencyCodeValidate()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        CurrencyCode: Code[10];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Order] [UT]
        // [SCENARIO 311677] Standard codes notification created when currency code of sales document became same with Standard Sales Code currency code
        Initialize;

        // [GIVEN] Local currency customer CUST with standard sales code "AA" where Insert Rec. Lines On Orders = "Always Ask"
        CustomerNo := GetNewCustNoWithStandardSalesCode(RefDocType::Order, RefMode::"Always Ask");

        // [GIVEN] Set Currency Code = "XXX" for standard sales code "AA"
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        UpdateStandardSalesCodeWithNewCurrencyCode(CustomerNo, CurrencyCode);

        // [GIVEN] Create new sales order for customer CUST
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order);
        SalesOrder.OpenEdit();
        SalesOrder.Filter.setfilter("No.", SalesHeader."No.");
        SalesOrder."Sell-to Customer No.".SetValue(CustomerNo);

        // [WHEN] Specify SalesHeader."Currency Code" = "XXX"
        SalesOrder."Currency Code".SetValue(CurrencyCode);

        // [THEN] Standard sales code notification created
        Assert.AreEqual(SalesHeader."Document Type", LibraryVariableStorage.DequeueInteger, 'Unexpected document type');
        Assert.AreEqual(SalesHeader."No.", LibraryVariableStorage.DequeueText, 'Unexpected document number');
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Insert Std. Sales Lines");
        LibraryVariableStorage.Clear;
        LibrarySales.DisableWarningOnCloseUnpostedDoc;
        LibraryNotificationMgt.ClearTemporaryNotificationContext;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Insert Std. Sales Lines");

        LibraryERMCountryData.CreateVATData;
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Insert Std. Sales Lines");
    end;

    local procedure CreateMultipleStandardCustomerSalesCodesForCustomer(DocType: Option; Mode: Integer; CustomerNo: Code[20])
    var
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do
            CreateNewStandardCustomerSalesCodeForCustomer(DocType, Mode, CustomerNo);
    end;

    local procedure CreateNewStandardCustomerSalesCodeForCustomer(DocType: Option; Mode: Integer; CustomerNo: Code[20])
    var
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
    begin
        StandardCustomerSalesCode.Init();
        StandardCustomerSalesCode."Customer No." := CustomerNo;
        StandardCustomerSalesCode.Code := CreateStandardSalesCodeWithItemLine;
        case DocType of
            RefDocType::Quote:
                StandardCustomerSalesCode."Insert Rec. Lines On Quotes" := Mode;
            RefDocType::Order:
                StandardCustomerSalesCode."Insert Rec. Lines On Orders" := Mode;
            RefDocType::Invoice:
                StandardCustomerSalesCode."Insert Rec. Lines On Invoices" := Mode;
            RefDocType::"Credit Memo":
                StandardCustomerSalesCode."Insert Rec. Lines On Cr. Memos" := Mode;
        end;
        StandardCustomerSalesCode.Insert();
        LibraryVariableStorage.Enqueue(StandardCustomerSalesCode.Code);  // Enqueue value for StandardCustomerSalesCodesModalPageHandler or StandardCustomerSalesCodesCancelModalPageHandler.
    end;

    local procedure CreateStandardSalesCode(): Code[10]
    var
        StandardSalesCode: Record "Standard Sales Code";
    begin
        LibrarySales.CreateStandardSalesCode(StandardSalesCode);
        exit(StandardSalesCode.Code);
    end;

    local procedure CreateStandardSalesCodeWithItemLine(): Code[10]
    var
        StandardSalesLine: Record "Standard Sales Line";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        StandardSalesLine."Standard Sales Code" := CreateStandardSalesCode;
        StandardSalesLine.Type := StandardSalesLine.Type::Item;
        StandardSalesLine."No." := LibraryInventory.CreateItemNo;
        StandardSalesLine.Quantity := LibraryRandom.RandDec(10, 2);
        StandardSalesLine.Insert();
        exit(StandardSalesLine."Standard Sales Code")
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Option)
    begin
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := LibraryUTUtility.GetNewCode;
        SalesHeader."Document Date" := WorkDate;
        SalesHeader.Insert();
    end;

    local procedure CreateSalesQuote(var SalesHeader: Record "Sales Header")
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header")
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header")
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
    end;

    local procedure CreateSalesCrMemo(var SalesHeader: Record "Sales Header")
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
    end;

    local procedure FilterOnSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
    end;

    local procedure FindStandardSalesLine(var StandardSalesLine: Record "Standard Sales Line"; CustomerNo: Code[20])
    var
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
    begin
        StandardCustomerSalesCode.SetRange("Customer No.", CustomerNo);
        StandardCustomerSalesCode.FindFirst;
        StandardSalesLine.SetRange("Standard Sales Code", StandardCustomerSalesCode.Code);
        StandardSalesLine.FindFirst;
    end;

    local procedure GetNewCustNoWithStandardSalesCode(DocType: Option; Mode: Integer): Code[20]
    var
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
    begin
        StandardCustomerSalesCode.Init();
        StandardCustomerSalesCode."Customer No." := LibrarySales.CreateCustomerNo;
        StandardCustomerSalesCode.Code := CreateStandardSalesCodeWithItemLine;
        case DocType of
            RefDocType::Quote:
                StandardCustomerSalesCode."Insert Rec. Lines On Quotes" := Mode;
            RefDocType::Order:
                StandardCustomerSalesCode."Insert Rec. Lines On Orders" := Mode;
            RefDocType::Invoice:
                StandardCustomerSalesCode."Insert Rec. Lines On Invoices" := Mode;
            RefDocType::"Credit Memo":
                StandardCustomerSalesCode."Insert Rec. Lines On Cr. Memos" := Mode;
        end;
        StandardCustomerSalesCode.Insert();

        LibraryVariableStorage.Enqueue(StandardCustomerSalesCode.Code);  // Enqueue value for StandardCustomerSalesCodesModalPageHandler or StandardCustomerSalesCodesCancelModalPageHandler.
        exit(StandardCustomerSalesCode."Customer No.");
    end;

    local procedure SetSalesQuoteCustomerNo(SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.Filter.setfilter("No.", SalesHeader."No.");
        SalesQuote."Sell-to Customer No.".SetValue(CustomerNo);
    end;

    local procedure SetSalesInvoiceCustomerNo(SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.setfilter("No.", SalesHeader."No.");
        SalesInvoice."Sell-to Customer No.".SetValue(CustomerNo);
    end;

    local procedure SetSalesOrderCustomerNo(SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.Filter.setfilter("No.", SalesHeader."No.");
        SalesOrder."Sell-to Customer No.".SetValue(CustomerNo);
    end;

    local procedure SetSalesCrMemoCustomerNo(SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.Filter.setfilter("No.", SalesHeader."No.");
        SalesCreditMemo."Sell-to Customer No.".SetValue(CustomerNo);
    end;

    local procedure SetSalesBlanketOrderCustomerNo(SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.Filter.setfilter("No.", SalesHeader."No.");
        BlanketSalesOrder."Sell-to Customer No.".SetValue(CustomerNo);
    end;

    local procedure SetSalesReturnOrderCustomerNo(SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.Filter.setfilter("No.", SalesHeader."No.");
        SalesReturnOrder."Sell-to Customer No.".SetValue(CustomerNo);
    end;

    local procedure UpdateSalesHeaderSellToCustomerNo(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    begin
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Modify();
    end;

    local procedure UpdateStandardSalesCodeWithNewCurrencyCode(CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        StandardSalesCode: Record "Standard Sales Code";
    begin
        StandardCustomerSalesCode.SetRange("Customer No.", CustomerNo);
        StandardCustomerSalesCode.FindFirst();
        StandardSalesCode.Get(StandardCustomerSalesCode.Code);
        StandardSalesCode.Validate("Currency Code", CurrencyCode);
        StandardSalesCode.Modify();
    end;

    local procedure VerifySalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        StandardSalesLine: Record "Standard Sales Line";
    begin
        FilterOnSalesLine(SalesLine, SalesHeader);
        Assert.IsTrue(SalesLine.FindFirst, StrSubstNo(ValueMustExistMsg, SalesLine.TableCaption));
        FindStandardSalesLine(StandardSalesLine, SalesLine."Sell-to Customer No.");
        SalesLine.TestField("No.", StandardSalesLine."No.");
        SalesLine.TestField(Quantity, StandardSalesLine.Quantity);
    end;

    local procedure VerifyNoSalesStdCodesNotification()
    var
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
    begin
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        TempNotificationContext.SetRange("Notification ID", StandardCodesMgt.GetSalesRecurringLinesNotificationId);
        Assert.RecordIsEmpty(TempNotificationContext);
    end;

    local procedure VerifySalesStdCodesNotification(SalesHeader: Record "Sales Header")
    var
        TempNotificationContext: Record "Notification Context" temporary;
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        TempNotificationContext.SetRange("Record ID", SalesHeader.RecordId);
        Assert.IsTrue(TempNotificationContext.FindFirst, 'Notification not found');
        Assert.AreEqual(
          StandardCodesMgt.GetSalesRecurringLinesNotificationId,
          TempNotificationContext."Notification ID",
          InvalidNotificationIdMsg);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    local procedure VerifySalesStdCodesNotificationId()
    var
        TempNotificationContext: Record "Notification Context" temporary;
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        Assert.AreEqual(
          StandardCodesMgt.GetSalesRecurringLinesNotificationId,
          TempNotificationContext."Notification ID",
          InvalidNotificationIdMsg);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StandardCustomerSalesCodesModalPageHandler(var StandardCustomerSalesCodes: TestPage "Standard Customer Sales Codes")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        StandardCustomerSalesCodes.FILTER.SetFilter(Code, Code);
        StandardCustomerSalesCodes.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StandardCustomerSalesCodesCancelModalPageHandler(var StandardCustomerSalesCodes: TestPage "Standard Customer Sales Codes")
    begin
        StandardCustomerSalesCodes.Cancel.Invoke;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    var
        SalesHeader: Record "Sales Header";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
    begin
        if not (Notification.Id = StandardCodesMgt.GetSalesRecurringLinesNotificationId()) then
            exit;
        LibraryVariableStorage.Clear;
        Evaluate(SalesHeader."Document Type", Notification.GetData(SalesHeader.FieldName("Document Type")));
        SalesHeader."No." := Notification.GetData(SalesHeader.FieldName("No."));
        LibraryVariableStorage.Enqueue(SalesHeader."Document Type");
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
    end;
}

