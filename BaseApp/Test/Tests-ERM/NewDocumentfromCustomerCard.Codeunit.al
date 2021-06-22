codeunit 134771 "New Document from CustomerCard"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Customer] [UI]
        IsInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"New Document from CustomerCard");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"New Document from CustomerCard");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"New Document from CustomerCard");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewBlanketSalesOrderFromCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // Setup
        Initialize;
        CreateCustomer(Customer);

        // Execute
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);

        BlanketSalesOrder.Trap;
        CustomerCard.NewBlanketSalesOrder.Invoke;

        // Verification
        Assert.AreEqual(
          Customer.Name, BlanketSalesOrder."Sell-to Customer Name".Value, 'Customername is not carried over to the document');
        Assert.AreEqual(
          Customer.Address, BlanketSalesOrder."Sell-to Address".Value, 'Customer address is not carried over to the document');
        Assert.AreEqual(Customer."Post Code", BlanketSalesOrder."Sell-to Post Code".Value,
          'Customer postcode is not carried over to the document');
        Assert.AreEqual(
          Customer.Contact, BlanketSalesOrder."Sell-to Contact".Value, 'Customer contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewSalesQuoteFromCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        SalesQuote: TestPage "Sales Quote";
    begin
        // Setup
        Initialize;
        CreateCustomer(Customer);

        // Execute
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);

        SalesQuote.Trap;
        CustomerCard.NewSalesQuote.Invoke;

        // Verification
        Assert.AreEqual(Customer.Name, SalesQuote."Sell-to Customer Name".Value, 'Customername is not carried over to the document');
        Assert.AreEqual(Customer.Address, SalesQuote."Bill-to Address".Value, 'Customer address is not carried over to the document');
        Assert.AreEqual(Customer."Post Code", SalesQuote."Bill-to Post Code".Value,
          'Customer postcode is not carried over to the document');
        Assert.AreEqual(Customer.Contact, SalesQuote."Sell-to Contact".Value, 'Customer contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewSalesInvoiceFromCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize;
        CreateCustomer(Customer);

        // Execute
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);

        SalesInvoice.Trap;
        CustomerCard.NewSalesInvoice.Invoke;

        // Verification
        Assert.AreEqual(Customer.Name, SalesInvoice."Sell-to Customer Name".Value, 'Customername is not carried over to the document');
        Assert.AreEqual(Customer.Address, SalesInvoice."Sell-to Address".Value, 'Customer address is not carried over to the document');
        Assert.AreEqual(Customer."Post Code", SalesInvoice."Sell-to Post Code".Value,
          'Customer postcode is not carried over to the document');
        Assert.AreEqual(Customer.Contact, SalesInvoice."Sell-to Contact".Value, 'Customer contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewSalesOrderFromCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        SalesOrder: TestPage "Sales Order";
    begin
        // Setup
        Initialize;
        CreateCustomer(Customer);

        // Execute
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);

        SalesOrder.Trap;
        CustomerCard.NewSalesOrder.Invoke;

        // Verification
        SalesOrder."Sell-to Customer Name".Activate;
        Assert.AreEqual(Customer.Name, SalesOrder."Sell-to Customer Name".Value, 'Customername is not carried over to the document');
        Assert.AreEqual(Customer.Address, SalesOrder."Sell-to Address".Value, 'Customer address is not carried over to the document');
        Assert.AreEqual(Customer."Post Code", SalesOrder."Sell-to Post Code".Value,
          'Customer postcode is not carried over to the document');
        Assert.AreEqual(Customer.Contact, SalesOrder."Sell-to Contact".Value, 'Customer contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewSalesCrMemoFromCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Setup
        Initialize;
        CreateCustomer(Customer);

        // Execute
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);

        SalesCreditMemo.Trap;
        CustomerCard.NewSalesCreditMemo.Invoke;

        // Verification
        Assert.AreEqual(Customer.Name, SalesCreditMemo."Sell-to Customer Name".Value, 'Customername is not carried over to the document');
        Assert.AreEqual(Customer.Address, SalesCreditMemo."Sell-to Address".Value, 'Customer address is not carried over to the document');
        Assert.AreEqual(Customer."Post Code", SalesCreditMemo."Sell-to Post Code".Value,
          'Customer postcode is not carried over to the document');
        Assert.AreEqual(Customer.Contact, SalesCreditMemo."Sell-to Contact".Value, 'Customer contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewSalesReturnOrderFromCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // Setup
        Initialize;
        CreateCustomer(Customer);

        // Execute
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);

        SalesReturnOrder.Trap;
        CustomerCard.NewSalesReturnOrder.Invoke;

        // Verification
        Assert.AreEqual(Customer.Name, SalesReturnOrder."Sell-to Customer Name".Value, 'Customername is not carried over to the document');
        Assert.AreEqual(
          Customer.Address, SalesReturnOrder."Sell-to Address".Value, 'Customer address is not carried over to the document');
        Assert.AreEqual(Customer."Post Code", SalesReturnOrder."Sell-to Post Code".Value,
          'Customer postcode is not carried over to the document');
        Assert.AreEqual(
          Customer.Contact, SalesReturnOrder."Sell-to Contact".Value, 'Customer contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewServiceQuoteFromCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        ServiceQuote: TestPage "Service Quote";
    begin
        // Setup
        Initialize;
        CreateCustomer(Customer);

        // Execute
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);

        ServiceQuote.Trap;
        CustomerCard.NewServiceQuote.Invoke;

        // Verification
        ServiceQuote.Description.Activate;
        Assert.AreEqual(Customer."No.", ServiceQuote."Customer No.".Value, 'Customername is not carried over to the document');
        Assert.AreEqual(Customer.Name, ServiceQuote.Name.Value, 'Customername is not carried over to the document');
        Assert.AreEqual(Customer.Address, ServiceQuote.Address.Value, 'Customer address is not carried over to the document');
        Assert.AreEqual(Customer."Post Code", ServiceQuote."Post Code".Value,
          'Customer postcode is not carried over to the document');
        Assert.AreEqual(Customer.Contact, ServiceQuote."Contact Name".Value, 'Customer contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewServiceInvoiceFromCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Setup
        Initialize;
        CreateCustomer(Customer);

        // Execute
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);

        ServiceInvoice.Trap;
        CustomerCard.NewServiceInvoice.Invoke;

        // Verification
        ServiceInvoice.Name.Activate;
        Assert.AreEqual(Customer."No.", ServiceInvoice."Customer No.".Value, 'Customername is not carried over to the document');
        Assert.AreEqual(Customer.Name, ServiceInvoice.Name.Value, 'Customername is not carried over to the document');
        Assert.AreEqual(Customer.Address, ServiceInvoice.Address.Value, 'Customer address is not carried over to the document');
        Assert.AreEqual(Customer."Post Code", ServiceInvoice."Post Code".Value,
          'Customer postcode is not carried over to the document');
        Assert.AreEqual(Customer.Contact, ServiceInvoice."Contact Name".Value, 'Customer contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewServiceOrderFromCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        ServiceOrder: TestPage "Service Order";
    begin
        // Setup
        Initialize;
        CreateCustomer(Customer);

        // Execute
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);

        ServiceOrder.Trap;
        CustomerCard.NewServiceOrder.Invoke;

        // Verification
        ServiceOrder.Description.Activate;
        Assert.AreEqual(Customer."No.", ServiceOrder."Customer No.".Value, 'Customername is not carried over to the document');
        Assert.AreEqual(Customer.Address, ServiceOrder.Address.Value, 'Customer address is not carried over to the document');
        Assert.AreEqual(Customer."Post Code", ServiceOrder."Post Code".Value,
          'Customer postcode is not carried over to the document');
        Assert.AreEqual(Customer.Contact, ServiceOrder."Contact Name".Value, 'Customer contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewServiceCrMemoFromCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Setup
        Initialize;
        CreateCustomer(Customer);

        // Execute
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);

        ServiceCreditMemo.Trap;
        CustomerCard.NewServiceCreditMemo.Invoke;

        // Verification
        Assert.AreEqual(Customer."No.", ServiceCreditMemo."Customer No.".Value, 'Customername is not carried over to the document');
        Assert.AreEqual(Customer.Address, ServiceCreditMemo.Address.Value, 'Customer address is not carried over to the document');
        Assert.AreEqual(Customer."Post Code", ServiceCreditMemo."Post Code".Value,
          'Customer postcode is not carried over to the document');
        Assert.AreEqual(Customer.Contact, ServiceCreditMemo."Contact Name".Value, 'Customer contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewRemainderFromCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        Reminder: TestPage Reminder;
    begin
        // Setup
        Initialize;
        CreateCustomer(Customer);

        // Execute
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);

        Reminder.Trap;
        CustomerCard.NewReminder.Invoke;

        // Verification
        Assert.AreEqual(Customer."No.", Reminder."Customer No.".Value, 'Customername is not carried over to the document');
        Assert.AreEqual(Customer.Address, Reminder.Address.Value, 'Customer address is not carried over to the document');
        Assert.AreEqual(Customer."Post Code", Reminder."Post Code".Value,
          'Customer postcode is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewFinChrgMemoFromCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        FinanceChargeMemo: TestPage "Finance Charge Memo";
    begin
        // Setup
        Initialize;
        CreateCustomer(Customer);

        // Execute
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);

        FinanceChargeMemo.Trap;
        CustomerCard.NewFinanceChargeMemo.Invoke;

        // Verification
        Assert.AreEqual(Customer."No.", FinanceChargeMemo."Customer No.".Value, 'Customername is not carried over to the document');
        Assert.AreEqual(Customer.Address, FinanceChargeMemo.Address.Value, 'Customer address is not carried over to the document');
        Assert.AreEqual(Customer."Post Code", FinanceChargeMemo."Post Code".Value,
          'Customer postcode is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoNewSalesDocFromCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        FirstSalesInvoice: TestPage "Sales Invoice";
        SecondSalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 219136] User can create two or more new sales documents at the same time from customer card
        // Cover TFS ID 102659

        // [GIVEN] Opening Customer card
        Initialize;
        CreateCustomer(Customer);
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);

        // [GIVEN] Opening First New Sales Invoice
        FirstSalesInvoice.Trap;
        CustomerCard.NewSalesInvoice.Invoke;
        VerifySalesInvoicePage(Customer, FirstSalesInvoice);

        // [WHEN] Opening Second New Sales Invoice
        SecondSalesInvoice.Trap;
        CustomerCard.NewSalesInvoice.Invoke;

        // [THEN] Fields on the page "Sales Invoice" have been filled
        VerifySalesInvoicePage(Customer, SecondSalesInvoice);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)));
        Customer.Validate(Address, LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Address)));
        Customer.Validate("Post Code", PostCode.Code);
        Customer.Contact := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Contact)), 1, MaxStrLen(Customer.Contact));
        Customer.Modify(true);
    end;

    local procedure VerifySalesInvoicePage(Customer: Record Customer; SalesInvoice: TestPage "Sales Invoice")
    begin
        SalesInvoice."Sell-to Customer Name".AssertEquals(Customer.Name);
        SalesInvoice."Sell-to Address".AssertEquals(Customer.Address);
        SalesInvoice."Sell-to Post Code".AssertEquals(Customer."Post Code");
        SalesInvoice."Sell-to Contact".AssertEquals(Customer.Contact);
    end;
}

