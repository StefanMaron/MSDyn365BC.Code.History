codeunit 138933 "O365 Contact Lookup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [E2E] [UI]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        CustomerNotFoundErr: Label 'Customer not found.';
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Initialized: Boolean;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,ContactLookupMPH')]
    [Scope('OnPrem')]
    procedure EstimateContactLookup()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        O365SalesQuote: TestPage "O365 Sales Quote";
    begin
        // [SCENARIO 217158] Sell-to Customer Name lookup on Estimate page opens contacts list, once contact picked related customer number goes to document
        Initialize;

        // [GIVEN] Customer with name CUST has related contact CONT
        LibrarySales.CreateCustomer(Customer);
        Contact.Get(FindContactNoByCustomer(Customer."No."));

        // [GIVEN] Open Estimate page
        O365SalesQuote.OpenNew;
        O365SalesQuote."Sell-to Customer Name".Activate;

        // [WHEN] Lookup contacts from estimate and choose CONT
        LibraryVariableStorage.Enqueue(Contact."No.");
        O365SalesQuote."Sell-to Customer Name".Lookup;

        // [THEN] Estimate Sell-to Customer Name = CUST
        O365SalesQuote."Sell-to Customer Name".AssertEquals(Customer.Name);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,ContactLookupMPH')]
    [Scope('OnPrem')]
    procedure DraftInvoiceContactLookup()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        O365SalesInvoice: TestPage "O365 Sales Invoice";
    begin
        // [SCENARIO 217158] Sell-to Customer Name lookup on Draft Invoice page opens contacts list, once contact picked related customer number goes to document
        Initialize;

        // [GIVEN] Customer with name CUST has related contact CONT
        LibrarySales.CreateCustomer(Customer);
        Contact.Get(FindContactNoByCustomer(Customer."No."));

        // [GIVEN] Open Draft Invoice page
        O365SalesInvoice.OpenNew;
        O365SalesInvoice."Sell-to Customer Name".Activate;

        // [WHEN] Lookup contacts from estimate and choose CONT
        LibraryVariableStorage.Enqueue(Contact."No.");
        O365SalesInvoice."Sell-to Customer Name".Lookup;

        // [THEN] Draft Invoice Sell-to Customer Name = CUST
        O365SalesInvoice."Sell-to Customer Name".AssertEquals(Customer.Name);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,ContactLookupMPH')]
    [Scope('OnPrem')]
    procedure CreateNewCustomerFromContactLookup()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        O365SalesQuote: TestPage "O365 Sales Quote";
    begin
        // [SCENARIO 217158] Choosing contact without related customer while lookup leads to creating new customer
        Initialize;

        // [GIVEN] Contact CONT with Name = XXX, Email = YY@YY.com, Phone No. = ZZZ
        CreateContact(Contact);
        // [GIVEN] Open Estimate page
        O365SalesQuote.OpenNew;
        O365SalesQuote."Sell-to Customer Name".Activate;

        // [WHEN] Lookup contacts from estimate and choose CONT
        LibraryVariableStorage.Enqueue(Contact."No.");
        O365SalesQuote."Sell-to Customer Name".Lookup;

        // [THEN] New customer has been created
        Assert.IsTrue(Customer.Get(FindCustomerNoByContact(Contact."No.")), CustomerNotFoundErr);
        // [THEN] Created customer has Name = XXX, Email = YY@YY.com, Phone No. = ZZZ
        Customer.TestField(Name, Contact.Name);
        Customer.TestField("E-Mail", Contact."E-Mail");
        Customer.TestField("Phone No.", Contact."Phone No.");
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,ContactLookupMPH')]
    [Scope('OnPrem')]
    procedure ChangeCustomerFromEstimate()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Contact: Record Contact;
        O365SalesQuote: TestPage "O365 Sales Quote";
        NewCustomerNo: Code[20];
    begin
        // [SCENARIO 217158] Choosing new contact while lookup for estimate with existing Sell-to Customer No. updates Sell-to Customer No. with new customer number
        Initialize;

        // [GIVEN] Customer CUST1
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Estimate with customer = CUST1
        CreateQuote(SalesHeader, Customer."No.");
        // [GIVEN] Contact CONT2 without customer
        CreateContact(Contact);

        // [GIVEN] Open estimate page with created document
        O365SalesQuote.OpenEdit;
        O365SalesQuote.GotoKey(SalesHeader."Document Type"::Quote, SalesHeader."No.");

        // [WHEN] Lookup contacts from estimate and choose CONT2
        LibraryVariableStorage.Enqueue(Contact."No.");
        O365SalesQuote."Sell-to Customer Name".Lookup;

        // [THEN] Customer CUST2 linked to CONT2 created
        NewCustomerNo := FindCustomerNoByContact(Contact."No.");
        // [THEN] Estimate Sell-to Customer No. = CUST2
        SalesHeader.Find;
        SalesHeader.TestField("Sell-to Customer No.", NewCustomerNo);
    end;

    local procedure Initialize()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
    begin
        LibraryVariableStorage.Clear;
        EventSubscriberInvoicingApp.Clear;
        ApplicationArea('#Invoicing');
        if Initialized then
            exit;

        Initialized := true;

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify;
        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);
    end;

    local procedure CreateQuote(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CustomerNo);
    end;

    local procedure CreateContact(var Contact: Record Contact)
    begin
        with Contact do begin
            Init;
            Validate("No.", LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::Contact));
            Validate(Name, LibraryUtility.GenerateRandomCode(FieldNo(Name), DATABASE::Contact));
            Type := Type::Company;
            "Company No." := "No.";
            "E-Mail" := LibraryUtility.GenerateRandomEmail;
            Validate("Phone No.",
              LibraryUtility.GenerateRandomCode(FieldNo("Phone No."), DATABASE::Contact));
            Validate("Country/Region Code", 'DK');
            Insert;
        end;
    end;

    local procedure FindCustomerNoByContact(ContactNo: Code[20]): Code[20]
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        ContBusRel.FindByContact(ContBusRel."Link to Table"::Customer, ContactNo);
        exit(ContBusRel."No.");
    end;

    local procedure FindContactNoByCustomer(CustomerNo: Code[20]): Code[20]
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, CustomerNo);
        exit(ContBusRel."Contact No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactLookupMPH(var BCO365ContactLookup: TestPage "BC O365 Contact Lookup")
    begin
        BCO365ContactLookup.GotoKey(LibraryVariableStorage.DequeueText);
        BCO365ContactLookup.OK.Invoke;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

