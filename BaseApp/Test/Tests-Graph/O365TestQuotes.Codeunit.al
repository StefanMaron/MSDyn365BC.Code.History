codeunit 138921 "O365 Test Quotes"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Quote]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        LibraryJobQueue: Codeunit "Library - Job Queue";
        O365TestQuotes: Codeunit "O365 Test Quotes";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Initialized: Boolean;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestCreateQuoteUpdateFields()
    var
        Customer: Record Customer;
        Item: Record Item;
        O365SalesQuote: TestPage "O365 Sales Quote";
    begin
        // [GIVEN] An existing customer wants a quote from us
        Initialize;
        CreateCustItem(Customer, Item);
        LibraryLowerPermissions.SetO365BusFull;

        // [WHEN] The user creates a new quote and selects an existing user
        CreateQuote(Customer, Item, O365SalesQuote);

        // [THEN] The quote is populated with relevant fields.
        Assert.AreEqual(Customer."E-Mail", O365SalesQuote.CustomerEmail.Value, '');
        Assert.AreEqual(1, O365SalesQuote.Amount.AsDEcimal, '');
        Assert.AreEqual(WorkDate + 30, O365SalesQuote."Quote Valid Until Date".AsDate, '');

        O365SalesQuote.Close;
        CleanUp;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SendEmailPageHandler,MessageHandlerMailSent')]
    [Scope('OnPrem')]
    procedure TestSendQuote()
    var
        Customer: Record Customer;
        Item: Record Item;
        O365SalesQuote: TestPage "O365 Sales Quote";
    begin
        // [GIVEN] An existing customer wants a quote from us
        Initialize;
        CreateCustItem(Customer, Item);
        LibraryLowerPermissions.SetO365BusFull;

        // [WHEN] The user creates a new quote and selects an existing user and clicks send
        CreateQuote(Customer, Item, O365SalesQuote);
        Assert.AreEqual(0DT, O365SalesQuote."Quote Sent to Customer".AsDateTime, '');
        O365SalesQuote.EmailQuote.Invoke;

        // [THEN] The "Quote Sent to Customer" field is populated.
        O365SalesQuote.OpenView;
        O365SalesQuote.Last;
        Assert.AreNotEqual(0DT, O365SalesQuote."Quote Sent to Customer".AsDateTime, '');
        O365SalesQuote.Close;
        CleanUp;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SendEmailPageHandler,MessageHandlerMailSent')]
    [Scope('OnPrem')]
    procedure TestSendFinalInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        O365SalesQuote: TestPage "O365 Sales Quote";
    begin
        // [GIVEN] An existing customer has accepted a quote and the work is done
        Initialize;
        CreateCustItem(Customer, Item);
        CreateQuote(Customer, Item, O365SalesQuote);
        SalesHeader.SetRange("Sell-to Customer Name", O365SalesQuote."Sell-to Customer Name".Value);
        SalesInvoiceHeader.SetRange("Bill-to Name", O365SalesQuote."Sell-to Customer Name".Value);
        Assert.AreEqual(1, SalesHeader.Count, '');
        Assert.AreEqual(0, SalesInvoiceHeader.Count, '');
        LibraryLowerPermissions.SetO365BusFull;

        // [WHEN] The user clicks send
        O365SalesQuote.Post.Invoke;

        // [THEN] The quote is deleted and a posted invoice is created.
        Assert.AreEqual(0, SalesHeader.Count, 'No sales header expected.');
        Assert.AreEqual(1, SalesInvoiceHeader.Count, 'Expected one posted invoice');
        CleanUp;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,DraftInvoicePageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestTurnQuoteIntoAnInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        O365SalesQuote: TestPage "O365 Sales Quote";
    begin
        // [GIVEN] An existing customer has accepted a quote
        Initialize;
        CreateCustItem(Customer, Item);
        CreateQuote(Customer, Item, O365SalesQuote);
        SalesHeader.SetRange("Sell-to Customer Name", O365SalesQuote."Sell-to Customer Name".Value);
        SalesHeader.FindFirst;
        Assert.AreEqual(1, SalesHeader.Count, '');
        Assert.AreEqual(SalesHeader."Document Type"::Quote, SalesHeader."Document Type", 'Wrong document type');
        LibraryLowerPermissions.SetO365BusFull;

        // [WHEN] The user invokes action 'Turn quote into invoice'
        O365SalesQuote.MakeToInvoice.Invoke;

        // [THEN] The quote is deleted and a draft invoice is created.
        SalesHeader.FindFirst;
        Assert.AreEqual(1, SalesHeader.Count, '');
        Assert.AreEqual(SalesHeader."Document Type"::Invoice, SalesHeader."Document Type", 'Wrong document type');
        CleanUp;
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

    local procedure CreateQuote(var Customer: Record Customer; var Item: Record Item; var O365SalesQuote: TestPage "O365 Sales Quote")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        O365SalesInvoiceLineCard: TestPage "O365 Sales Invoice Line Card";
    begin
        O365SalesQuote.OpenNew;

        O365SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.FindLast;

        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Modify(true);

        O365SalesInvoiceLineCard.OpenEdit;
        O365SalesInvoiceLineCard.GotoRecord(SalesLine);
        O365SalesInvoiceLineCard.Description.SetValue(Item.Description);
        O365SalesInvoiceLineCard.LineQuantity.SetValue(1);
        O365SalesInvoiceLineCard.Close;

        O365SalesQuote.GotoRecord(SalesHeader);
    end;

    local procedure Initialize()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        ReportSelections: Record "Report Selections";
    begin
        EnvironmentInfoTestLibrary.SetAppId('INV');
        BindSubscription(EnvironmentInfoTestLibrary);
        BindSubscription(LibraryJobQueue);
        BindSubscription(O365TestQuotes);
        if Initialized then
            exit;
        Initialized := true;

        if SMTPMailSetup.Get then
            SMTPMailSetup.Delete;
        SMTPMailSetup.Init;
        SMTPMailSetup."SMTP Server" := 'smtp.office365.com';
        SMTPMailSetup.Authentication := SMTPMailSetup.Authentication::Basic;
        SMTPMailSetup."User ID" := 'a@b.c';
        SMTPMailSetup.SetPassword('password');
        SMTPMailSetup.Insert;

        ReportSelections.SetRange(Usage, 0); // "S.Quote". work-around to avoid RU modification
        ReportSelections.DeleteAll;
        ReportSelections.Init;
        ReportSelections.Usage := 0; // "S.Quote"
        ReportSelections."Report ID" := REPORT::"Standard Sales - Quote";
        ReportSelections.Insert;
    end;

    local procedure CleanUp()
    begin
        UnbindSubscription(O365TestQuotes);
        UnbindSubscription(LibraryJobQueue);
        UnbindSubscription(EnvironmentInfoTestLibrary);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SendEmailPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        O365SalesEmailDialog.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerMailSent(MessageTxt: Text)
    begin
        Assert.IsTrue(StrPos(MessageTxt, 'is being sent') > 0, '');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure DraftInvoicePageHandler(var O365SalesInvoice: TestPage "O365 Sales Invoice")
    begin
        O365SalesInvoice.Close;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

