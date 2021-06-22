codeunit 138942 "BC O365 Contact Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [BC] [Contacts]
    end;

    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyBCSalesInvoiceVisibilityForViewContactDetails()
    var
        Customer: Record Customer;
        Item: Record Item;
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] BC Invoicing has been set up and cust and item is created
        Init;
        LibraryLowerPermissions.SetO365BusFull;
        CreateCustItem(Customer, Item);

        // [WHEN]  The user creates a new invoice from business center
        BCO365SalesInvoice.OpenNew;

        // [THEN] Visibility of View Contact Details is visible to allow for a 'next' tab after Name
        Assert.IsTrue(
          BCO365SalesInvoice.ViewContactCard.Visible, '"View contact details" should be visible');

        // [WHEN] when the user selects the contact
        BCO365SalesInvoice."Sell-to Customer Name".Value(Customer.Name);
        BCO365SalesInvoice.Lines.New;
        BCO365SalesInvoice.Lines.Description.Value(Item.Description);

        // [THEN] Visibility of View Contact Details is shown
        Assert.IsTrue(BCO365SalesInvoice.ViewContactCard.Visible, '"View contact details" should be visible when customer is selected');
        BCO365SalesInvoice.Close;
    end;

    [Test]
    [HandlerFunctions('CustomerCardPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyBCOpenContactCardfromSalesInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        CustomerName: Text;
    begin
        // [GIVEN] BC Invoicing has been set up and cust and item is created
        Init;
        LibraryLowerPermissions.SetO365BusFull;
        CreateCustItem(Customer, Item);

        // [WHEN] The user creates a new invoice from business center and selects an existing user
        CreateInvoice(Customer, Item, BCO365SalesInvoice);

        // [WHEN] View Contact details is clicekd
        BCO365SalesInvoice.ViewContactCard.DrillDown;

        // [THEN] Page "Contact card" is open, where "Name" is 'Sell to Customer Name'
        CustomerName := LibraryVariableStorage.DequeueText; // sent by CustomerCardPageHandler
        Assert.AreEqual(BCO365SalesInvoice."Sell-to Customer Name".Value, CustomerName, 'Wrong customer card opened');
        BCO365SalesInvoice.Close;
    end;

    [Test]
    [HandlerFunctions('SendEmailPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyBCPostedSalesInvoiceVisibilityForViewContactDetails()
    var
        Customer: Record Customer;
        Item: Record Item;
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] BC Invoicing has been set up and cust and item is created
        Init;
        LibraryLowerPermissions.SetO365BusFull;
        CreateCustItem(Customer, Item);

        // [WHEN] The user creates and sends an invoice from business center
        CreateInvoice(Customer, Item, BCO365SalesInvoice);
        BCO365SalesInvoice.Post.Invoke;

        // [WHEN] the user opens the posted invoice
        BCO365PostedSalesInvoice.OpenEdit;

        // [THEN] Visibility of View Contact Details is shown
        Assert.IsTrue(BCO365PostedSalesInvoice.ViewContactCard.Visible, '"View contact details" should be visible on posted invoice');
        BCO365PostedSalesInvoice.Close;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('SendEmailPageHandler,CustomerCardPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyBCOpenContactCardfromPostedSalesInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
        CustomerName: Text;
    begin
        // [GIVEN] BC Invoicing has been set up and cust and item is created
        Init;
        LibraryLowerPermissions.SetO365BusFull;
        CreateCustItem(Customer, Item);

        // [WHEN] The user creates and sends an invoice from business center
        CreateInvoice(Customer, Item, BCO365SalesInvoice);
        BCO365SalesInvoice.Post.Invoke;

        // [WHEN] the user opens the posted invoice
        BCO365PostedSalesInvoice.OpenEdit;

        // [WHEN] View Contact details is clicekd
        BCO365PostedSalesInvoice.ViewContactCard.DrillDown;

        // [THEN] Page "Contact card" is open, where "Name" is 'Sell to Customer Name'
        CustomerName := LibraryVariableStorage.DequeueText; // sent by CustomerCardPageHandler
        Assert.AreEqual(BCO365PostedSalesInvoice."Sell-to Customer Name".Value, CustomerName, 'Wrong customer card opened');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyBCSalesQuoteVisibilityForViewContactDetails()
    var
        Customer: Record Customer;
        Item: Record Item;
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        // [GIVEN] BC Invoicing has been set up and cust and item is created
        Init;
        InitializeQuotesReportSelection;
        LibraryLowerPermissions.SetO365BusFull;
        CreateCustItem(Customer, Item);

        // [WHEN]  The user creates a new quote from business center
        BCO365SalesQuote.OpenNew;

        // [THEN] Visibility of View Contact Details is visible to allow for tabbing after Name
        Assert.IsTrue(
          BCO365SalesQuote.ViewContactCard.Visible, '"View contact details" should be visible');

        // [WHEN] when the user selects the contact
        BCO365SalesQuote."Sell-to Customer Name".Value(Customer.Name);
        BCO365SalesQuote.Lines.New;
        BCO365SalesQuote.Lines.Description.Value(Item.Description);

        // [THEN] Visibility of View Contact Details is shown
        Assert.IsTrue(BCO365SalesQuote.ViewContactCard.Visible, '"View contact details" should be visible when customer is selected');
        BCO365SalesQuote.Close;
    end;

    [Test]
    [HandlerFunctions('CustomerCardPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyBCOpenContactCardfromSalesQuote()
    var
        Customer: Record Customer;
        Item: Record Item;
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
        CustomerName: Text;
    begin
        // [GIVEN] BC Invoicing has been set up and cust and item is created
        Init;
        InitializeQuotesReportSelection;
        LibraryLowerPermissions.SetO365BusFull;
        CreateCustItem(Customer, Item);

        // [WHEN] The user creates a new invoice from business center and selects an existing user
        BCO365SalesQuote.OpenNew;
        BCO365SalesQuote."Sell-to Customer Name".Value(Customer.Name);
        BCO365SalesQuote.Lines.New;
        BCO365SalesQuote.Lines.Description.Value(Item.Description);

        // [WHEN] View Contact details is clicekd
        BCO365SalesQuote.ViewContactCard.DrillDown;

        // [THEN] Page "Contact card" is open, where "Name" is 'Sell to Customer Name'
        CustomerName := LibraryVariableStorage.DequeueText; // sent by CustomerCardPageHandler
        Assert.AreEqual(BCO365SalesQuote."Sell-to Customer Name".Value, CustomerName, 'Wrong customer card opened');
        BCO365SalesQuote.Close;
    end;

    local procedure CreateCustItem(var Customer: Record Customer; var Item: Record Item)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := CopyStr(Format(CreateGuid), 1, MaxStrLen(Customer.Address));
        Customer."E-Mail" := 'a@b.c';
        Customer.Modify;

        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := 1;
        Item.Modify;
    end;

    local procedure CreateInvoice(var Customer: Record Customer; var Item: Record Item; var BCO365SalesInvoice: TestPage "BC O365 Sales Invoice")
    begin
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);
        BCO365SalesInvoice.Lines.New;
        BCO365SalesInvoice.Lines.Description.SetValue(Item.Description);
        BCO365SalesInvoice.Lines.LineQuantity.SetValue(1);
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SendEmailPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        O365SalesEmailDialog.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerCardPageHandler(var BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card")
    begin
        LibraryVariableStorage.Enqueue(BCO365SalesCustomerCard.Name.Value);
        BCO365SalesCustomerCard.OK.Invoke;
    end;

    local procedure Init()
    var
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
    begin
        BindActiveDirectoryMockEvents;

        LibraryVariableStorage.AssertEmpty;
        EventSubscriberInvoicingApp.Clear;
        EventSubscriberInvoicingApp.SetAvoidExcessiveRecursion(true);
        ApplicationArea('#Invoicing');
        O365SalesInitialSetup.Get;

        if IsInitialized then
            exit;

        LibraryInvoicingApp.SetupEmailTable;
        LibraryInvoicingApp.DisableC2Graph;

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        WorkDate(Today);
        IsInitialized := true;
    end;

    local procedure InitializeQuotesReportSelection()
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, 0); // "S.Quote". work-around to avoid RU modification
        ReportSelections.DeleteAll;
        ReportSelections.Init;
        ReportSelections.Usage := 0; // "S.Quote"
        ReportSelections."Report ID" := REPORT::"Standard Sales - Quote";
        ReportSelections.Insert;
    end;
}

