codeunit 138941 "BC O365 Test Quotes"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Web] [Quote] [Estimate]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryJobQueue: Codeunit "Library - Job Queue";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Initialized: Boolean;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestCreateQuoteUpdateFields()
    var
        Customer: Record Customer;
        Item: Record Item;
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        // [GIVEN] An existing customer wants a quote from us
        Initialize;
        CreateCustItem(Customer, Item);
        LibraryLowerPermissions.SetO365BusFull;

        // [WHEN] The user creates a new quote from business center and selects an existing user
        CreateQuote(Customer, Item, BCO365SalesQuote);

        // [THEN] The quote is populated with relevant fields.
        Assert.AreEqual(Customer."E-Mail", BCO365SalesQuote.CustomerEmail.Value, '');
        Assert.AreEqual(1, BCO365SalesQuote.Amount.AsDEcimal, '');
        Assert.AreEqual(WorkDate + 30, BCO365SalesQuote."Quote Valid Until Date".AsDate, '');

        BCO365SalesQuote.Close;
        CleanUp;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSelectUOM()
    var
        Customer: Record Customer;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
        OriginalPrice: Decimal;
        OriginalLineAmount: Decimal;
    begin
        // [GIVEN] An existing customer wants a quote from us, but we want to use a different UOM
        Initialize;
        CreateCustItem(Customer, Item);
        CreateUOM(UnitOfMeasure);
        LibraryLowerPermissions.SetO365BusFull;

        // [WHEN] The user creates a new quote from business center and selects another uom
        CreateQuote(Customer, Item, BCO365SalesQuote);
        BCO365SalesQuote.Lines."Unit Price".SetValue(BCO365SalesQuote.Lines."Unit Price".AsDEcimal + 1);
        OriginalPrice := BCO365SalesQuote.Lines."Unit Price".AsDEcimal;
        BCO365SalesQuote.Lines."Line Discount %".SetValue(BCO365SalesQuote.Lines."Line Discount %".AsDEcimal + 1);
        OriginalLineAmount := BCO365SalesQuote.Lines."Line Amount".AsDEcimal;

        BCO365SalesQuote.Lines.UnitOfMeasure.SetValue(UnitOfMeasure.Description);

        // [THEN] The quote and item are updated with the new uom, and other line amount fields are unchanged.
        Item.Find;
        Assert.AreEqual(UnitOfMeasure.Code, Item."Base Unit of Measure", '');
        Assert.AreEqual(OriginalPrice, BCO365SalesQuote.Lines."Unit Price".AsDEcimal, '');
        Assert.AreEqual(OriginalLineAmount, BCO365SalesQuote.Lines."Line Amount".AsDEcimal, '');

        BCO365SalesQuote.Close;
        CleanUp;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSelectNewCreateUOM()
    var
        Customer: Record Customer;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        // [GIVEN] An existing customer wants a quote from us, but we want to use a different UOM
        Initialize;
        CreateCustItem(Customer, Item);
        LibraryLowerPermissions.SetO365BusFull;

        // [WHEN] The user creates a new quote from business center and selects another uom
        CreateQuote(Customer, Item, BCO365SalesQuote);
        BCO365SalesQuote.Lines.UnitOfMeasure.SetValue(LibraryRandom.RandText(10));

        // [THEN] New UoM is created
        Assert.AreEqual(UnitOfMeasure.Get(BCO365SalesQuote.Lines.UnitOfMeasure.Value), true, 'New unit of measure not found');

        BCO365SalesQuote.Close;
        CleanUp;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SendEmailPageHandler')]
    [Scope('OnPrem')]
    procedure TestSendQuote()
    var
        Customer: Record Customer;
        Item: Record Item;
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        // [GIVEN] An existing customer wants a quote from us
        Initialize;
        CreateCustItem(Customer, Item);
        LibraryLowerPermissions.SetO365BusFull;

        // [WHEN] The user creates a new quote from business center and selects an existing user and clicks send
        CreateQuote(Customer, Item, BCO365SalesQuote);
        Assert.AreEqual(0DT, BCO365SalesQuote."Quote Sent to Customer".AsDateTime, '');
        BCO365SalesQuote.EmailQuote.Invoke;

        // [THEN] The "Quote Sent to Customer" field is populated.
        BCO365SalesQuote.OpenView;
        BCO365SalesQuote.Last;
        Assert.AreNotEqual(0DT, BCO365SalesQuote."Quote Sent to Customer".AsDateTime, '');
        BCO365SalesQuote.Close;
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
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        // [GIVEN] An existing customer has accepted a quote and the work is done
        Initialize;
        CreateCustItem(Customer, Item);
        CreateQuote(Customer, Item, BCO365SalesQuote);
        SalesHeader.SetRange("Sell-to Customer Name", BCO365SalesQuote."Sell-to Customer Name".Value);
        SalesInvoiceHeader.SetRange("Bill-to Name", BCO365SalesQuote."Sell-to Customer Name".Value);
        Assert.AreEqual(1, SalesHeader.Count, '');
        Assert.AreEqual(0, SalesInvoiceHeader.Count, '');
        LibraryLowerPermissions.SetO365BusFull;

        // [WHEN] The user clicks send on business center
        // BCO365SalesQuote.Post.INVOKE;

        // [THEN] The quote is deleted and a posted invoice is created.
        // Assert.AreEqual(0,SalesHeader.COUNT,'No sales header expected.');
        // Assert.AreEqual(1,SalesInvoiceHeader.COUNT,'Expected one posted invoice');
        CleanUp;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestTurnQuoteIntoAnInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] An existing customer has accepted a quote
        Initialize;
        CreateCustItem(Customer, Item);
        CreateQuote(Customer, Item, BCO365SalesQuote);
        SalesHeader.SetRange("Sell-to Customer Name", BCO365SalesQuote."Sell-to Customer Name".Value);
        SalesHeader.FindFirst;
        Assert.AreEqual(1, SalesHeader.Count, '');
        Assert.AreEqual(SalesHeader."Document Type"::Quote, SalesHeader."Document Type", 'Wrong document type');
        LibraryLowerPermissions.SetO365BusFull;

        // [WHEN] The user invokes action 'Turn quote into invoice'
        BCO365SalesInvoice.Trap;
        BCO365SalesQuote.MakeToInvoice.Invoke;
        BCO365SalesInvoice.Close;

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

    local procedure CreateQuote(var Customer: Record Customer; var Item: Record Item; var BCO365SalesQuote: TestPage "BC O365 Sales Quote")
    var
        SalesHeader: Record "Sales Header";
    begin
        BCO365SalesQuote.OpenNew;
        BCO365SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        BCO365SalesQuote.Lines.New;
        BCO365SalesQuote.Lines.Description.SetValue(Item.Description);
        BCO365SalesQuote.Lines.LineQuantity.SetValue(1);
    end;

    local procedure CreateUOM(var UnitOfMeasure: Record "Unit of Measure")
    begin
        UnitOfMeasure.Init;
        UnitOfMeasure.Description := CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(UnitOfMeasure.Description));
        UnitOfMeasure.Code := UpperCase(UnitOfMeasure.Description);
        UnitOfMeasure.Insert;
    end;

    local procedure Initialize()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        ReportSelections: Record "Report Selections";
    begin
        EnvironmentInfoTestLibrary.SetAppId('INV');
        BindSubscription(EnvironmentInfoTestLibrary);
        BindSubscription(LibraryJobQueue);

        if Initialized then
            exit;
        Initialized := true;

        if SMTPMailSetup.Get then
            SMTPMailSetup.Delete;
        SMTPMailSetup.Init;
        SMTPMailSetup."SMTP Server" := 'smtp.office365.com';
        SMTPMailSetup.Authentication := SMTPMailSetup.Authentication::Basic;
        SMTPMailSetup."User ID" := 'test@ms.com';
        SMTPMailSetup.SetPassword('pswd1');
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

