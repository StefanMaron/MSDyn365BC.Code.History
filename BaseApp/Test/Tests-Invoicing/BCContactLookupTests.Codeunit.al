codeunit 138945 "BC Contact Lookup Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Contact] [Customer] [UI]
    end;

    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyEnterAContactNumber()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        Item: Record Item;
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] BC Invoicing has been set up and cust with contact is created
        Init;
        LibraryLowerPermissions.SetO365BusFull;
        CreateItem(Item);
        CreateCustomerWithContact(Customer, Contact);

        // [WHEN] The user creates a new invoice from business center
        BCO365SalesInvoice.OpenNew;

        // [WHEN] The user enters the contact number
        BCO365SalesInvoice."Sell-to Customer Name".Value(Format(Contact."No."));
        BCO365SalesInvoice.Lines.New;
        BCO365SalesInvoice.Lines.Description.Value(Item.Description);

        // [THEN] Correct customer is selected
        Assert.AreEqual(BCO365SalesInvoice."Sell-to Customer Name".Value, Contact.Name, 'Incorrect Customer is selected');
        BCO365SalesInvoice.Close;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyEnterAContactName()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        Item: Record Item;
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] BC Invoicing has been set up and cust with contact is created
        Init;
        LibraryLowerPermissions.SetO365BusFull;
        CreateCustomerWithContact(Customer, Contact);
        CreateItem(Item);

        // [WHEN] The user creates a new invoice from business center
        BCO365SalesInvoice.OpenNew;

        // [WHEN] The user enters the contact name
        BCO365SalesInvoice."Sell-to Customer Name".Value(Format(Contact.Name));
        BCO365SalesInvoice.Lines.New;
        BCO365SalesInvoice.Lines.Description.Value(Item.Description);

        // [THEN] Correct customer is selected
        Assert.AreEqual(BCO365SalesInvoice."Sell-to Customer Name".Value, Contact.Name, 'Incorrect Customer is selected');
        BCO365SalesInvoice.Close;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyEnterAPartialContactName()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        Item: Record Item;
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] BC Invoicing has been set up and cust with contact is created
        Init;
        LibraryLowerPermissions.SetO365BusFull;
        CreateItem(Item);
        CreateCustomerWithContact(Customer, Contact);

        // [WHEN] The user creates a new invoice from business center
        BCO365SalesInvoice.OpenNew;

        // [WHEN] The user enters the partial contact name
        BCO365SalesInvoice."Sell-to Customer Name".Value('Te');
        BCO365SalesInvoice.Lines.New;
        BCO365SalesInvoice.Lines.Description.Value(Item.Description);

        // [THEN] Correct customer is selected
        Assert.AreEqual(BCO365SalesInvoice."Sell-to Customer Name".Value, Contact.Name, 'Incorrect Customer is selected');
        BCO365SalesInvoice.Close;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyEnterAContactNumberWithoutUnderlyingCustomer()
    var
        Contact: Record Contact;
        Item: Record Item;
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] BC Invoicing has been set up and only contact is created
        Init;
        LibraryLowerPermissions.SetO365BusFull;
        CreateItem(Item);
        CreateContact(Contact, '');

        // [WHEN] The user creates a new invoice from business center
        BCO365SalesInvoice.OpenNew;

        // [WHEN] The user enters the contact number
        BCO365SalesInvoice."Sell-to Customer Name".Value(Format(Contact."No."));
        BCO365SalesInvoice.Lines.New;
        BCO365SalesInvoice.Lines.Description.Value(Item.Description);

        // [THEN] Correct customer is selected
        Assert.AreEqual(BCO365SalesInvoice."Sell-to Customer Name".Value, Contact.Name, 'Incorrect Customer is selected');
        BCO365SalesInvoice.Close;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyEnterAContactNameWithoutUnderlyingCustomer()
    var
        Contact: Record Contact;
        Item: Record Item;
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] BC Invoicing has been set up and only contact is created
        Init;
        LibraryLowerPermissions.SetO365BusFull;
        CreateItem(Item);
        CreateContact(Contact, 'Test');

        // [WHEN] The user creates a new invoice from business center
        BCO365SalesInvoice.OpenNew;

        // [WHEN] The user enters the contact number
        BCO365SalesInvoice."Sell-to Customer Name".Value(Contact.Name);
        BCO365SalesInvoice.Lines.New;
        BCO365SalesInvoice.Lines.Description.Value(Item.Description);

        // [THEN] Correct customer is selected
        Assert.AreEqual(BCO365SalesInvoice."Sell-to Customer Name".Value, Contact.Name, 'Incorrect Customer is selected');
        BCO365SalesInvoice.Close;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyEnterAContactPartialNameWithoutUnderlyingCustomer()
    var
        Contact: Record Contact;
        Item: Record Item;
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] BC Invoicing has been set up and only contact is created
        Init;
        LibraryLowerPermissions.SetO365BusFull;
        CreateItem(Item);
        CreateContact(Contact, 'Test');

        // [WHEN] The user creates a new invoice from business center
        BCO365SalesInvoice.OpenNew;

        // [WHEN] The user enters the contact number
        BCO365SalesInvoice."Sell-to Customer Name".Value('te');
        BCO365SalesInvoice.Lines.New;
        BCO365SalesInvoice.Lines.Description.Value(Item.Description);

        // [THEN] Correct customer is selected
        Assert.AreEqual(BCO365SalesInvoice."Sell-to Customer Name".Value, Contact.Name, 'Incorrect Customer is selected');
        BCO365SalesInvoice.Close;
    end;

    local procedure CreateContact(var Contact: Record Contact; Name: Text[50])
    begin
        Contact.Init;
        Contact.Validate("No.", LibraryUtility.GenerateGUID);
        Contact.Validate(Type, Contact.Type::Person);
        Contact.Validate(Name, Name);
        Contact.Insert(true);
    end;

    local procedure CreateCustomerWithContact(var Customer: Record Customer; var Contact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        MiniCustomerTemplate: Record "Mini Customer Template";
    begin
        MiniCustomerTemplate.NewCustomerFromTemplate(Customer);
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");
        ContactBusinessRelation.FindFirst;
        Contact.Get(ContactBusinessRelation."Contact No.");
        Contact.Name := 'Test';
        Contact.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        TemplateItem: Record Item;
        ItemTemplate: Record "Item Template";
        O365SalesManagement: Codeunit "O365 Sales Management";
    begin
        ItemTemplate.NewItemFromTemplate(Item);
        O365SalesManagement.SetItemDefaultValues(TemplateItem);
        Item."Unit Price" := 1;
        Item.Description := 'ItemDescription';
        Item.Modify(true);
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable;
    end;

    local procedure Init()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
    begin
        BindActiveDirectoryMockEvents;

        LibraryVariableStorage.AssertEmpty;
        EventSubscriberInvoicingApp.Clear;
        ApplicationArea('#Invoicing');
        O365SalesInitialSetup.Get;

        Customer.DeleteAll;
        Contact.DeleteAll;

        if IsInitialized then
            exit;

        LibraryInvoicingApp.SetupEmailTable;
        LibraryInvoicingApp.DisableC2Graph;

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        WorkDate(Today);
        IsInitialized := true;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

