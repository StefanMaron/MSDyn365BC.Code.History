codeunit 134628 "Test Graph Cont. Bus. Relation"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Contact]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphSync: Codeunit "Library - Graph Sync";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphContactMockEvents: Codeunit "Graph Contact Mock Events";
        GraphBackgroundSyncSubscr: Codeunit "Graph Background Sync. Subscr.";
        IsInitialized: Boolean;
        SyncronizeContactConnectionName: Text;
        InboundContactConnectionName: Text;

    local procedure Initialize()
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
    begin
        LibraryGraphSync.RegisterTestConnections;
        SyncronizeContactConnectionName := GraphConnectionSetup.GetSynchronizeConnectionName(DATABASE::Contact);
        InboundContactConnectionName := GraphConnectionSetup.GetInboundConnectionName(DATABASE::Contact);

        if IsInitialized then
            exit;

        LibraryGraphSync.EnableGraphSync;
        BindSubscription(GraphBackgroundSyncSubscr);
        LibraryGraphSync.CreateGraphWebhookSubscription(DATABASE::Contact);
        IsInitialized := true;
        Commit;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSetIsCustomerOnGraphContactTrue()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        TestGraphContBusRelation: Codeunit "Test Graph Cont. Bus. Relation";
    begin
        // [GIVEN] User is connected to NAV using a compatible client
        // [WHEN]  User creates a new contact which is linked to a Customer
        // [THEN]  The contact is created in Graph with IsCustomer = TRUE
        Initialize;

        // Setup
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncronizeContactConnectionName, true);
        BindSubscription(TestGraphContBusRelation);
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.CreateCustomer('');
        UnbindSubscription(TestGraphContBusRelation);

        // Exercise
        RunGraphSyncToIntegrationTable(Contact);

        // Verify
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncronizeContactConnectionName);
        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact);
        Assert.IsTrue(LibraryGraphSync.CheckGraphContactIsCustomer(GraphContact), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetIsCustomerOnGraphContactFalse()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        TestGraphContBusRelation: Codeunit "Test Graph Cont. Bus. Relation";
    begin
        // [GIVEN] User is connected to NAV using a compatible client
        // [WHEN]  User creates a new contact which is NOT linked to a Customer
        // [THEN]  The contact is created in Graph with IsCustomer = FALSE
        Initialize;

        // Setup
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncronizeContactConnectionName, true);
        BindSubscription(TestGraphContBusRelation);
        LibraryMarketing.CreatePersonContact(Contact);
        UnbindSubscription(TestGraphContBusRelation);

        // Exercise
        RunGraphSyncToIntegrationTable(Contact);

        // Verify
        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact);
        Assert.IsFalse(LibraryGraphSync.CheckGraphContactIsCustomer(GraphContact), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateCustomerIfGraphContactIsCustomerFalse()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
    begin
        // [GIVEN] User is connected to NAV using a compatible client
        // [GIVEN] A Graph Contact exists and is not linked to a NAV Contact
        // [GIVEN] IsCustomer is False on the Graph Contact
        // [WHEN]  The record is synchronized,
        // [THEN]  The contact is created in NAV, no Customer is created
        Initialize;

        // Setup
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncronizeContactConnectionName, true);
        LibraryGraphSync.CreateGraphCompanyContact(GraphContact, SyncronizeContactConnectionName);
        LibraryGraphSync.GraphContactAddIsCustomerFalse(GraphContact);

        // Exercise
        RunGraphSyncFromIntegrationTable(GraphContact);

        // Verify
        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact);
        Assert.IsFalse(LibraryGraphSync.CheckGraphContactIsCustomer(GraphContact), '');
        Assert.IsFalse(LibraryGraphSync.CheckContactIsCustomer(Contact), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateCustomerIfGraphContactIsCustomerTrue()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
    begin
        // [GIVEN] User is connected to NAV using a compatible client
        // [GIVEN] A Graph Contact exists and is not linked to a NAV Contact
        // [GIVEN] IsCustomer is TRUE on the Graph Contact
        // [WHEN]  The record is synchronized,
        // [THEN]  The contact is created in NAV, a Customer is created
        Initialize;

        // Setup
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncronizeContactConnectionName, true);
        LibraryGraphSync.CreateGraphCompanyContact(GraphContact, SyncronizeContactConnectionName);
        LibraryGraphSync.GraphContactAddIsCustomerTrue(GraphContact);

        // Exercise
        RunGraphSyncFromIntegrationTable(GraphContact);

        // Verify
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncronizeContactConnectionName);
        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact);
        Assert.IsTrue(LibraryGraphSync.CheckGraphContactIsCustomer(GraphContact), '');
        Assert.IsTrue(LibraryGraphSync.CheckContactIsCustomer(Contact), '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestChangeGraphContactIsCustomerToFalse()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        TestGraphContBusRelation: Codeunit "Test Graph Cont. Bus. Relation";
    begin
        // [GIVEN] User is connected to NAV using a compatible client
        // [GIVEN] A Graph Contact exists and is linked to a NAV Contact
        // [GIVEN] The NAV Contact is linked to a Customer
        // [GIVEN] IsCustomer is TRUE on the Graph Contact
        // [WHEN]  IsCustomer is set to FALSE on the Graph Contact
        // [WHEN]  The record is synchronized,
        // [THEN]  The Customer is not deleted and the Graph Contact is updated with IsCustomer = TRUE
        Initialize;

        // Setup
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncronizeContactConnectionName, true);
        BindSubscription(TestGraphContBusRelation);
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.CreateCustomer('');
        UnbindSubscription(TestGraphContBusRelation);
        RunGraphSyncToIntegrationTable(Contact);

        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact);

        // Exercise
        LibraryGraphSync.GraphContactAddIsCustomerFalse(GraphContact);
        LibraryGraphSync.GraphContactAddIsContactTrue(GraphContact);
        GraphContact.ChangeKey :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.ChangeKey)), 1, MaxStrLen(GraphContact.ChangeKey));
        GraphContact.Modify;
        RunGraphSyncFromIntegrationTable(GraphContact);

        // Verify
        Contact.Get(Contact."No.");
        GraphContact.Get(GraphContact.Id);
        Assert.IsTrue(LibraryGraphSync.CheckContactIsCustomer(Contact), '');
        Assert.IsTrue(LibraryGraphSync.CheckGraphContactIsCustomer(GraphContact), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNewCustomerCreatesNewGraphContact()
    var
        Customer: Record Customer;
        GraphContact: Record "Graph Contact";
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [GIVEN] Enabled Graph Sync
        // [WHEN]  A new Customer is created in Nav
        // [THEN]  The Customer is synced to Graph through the contact
        Initialize;

        // Excercise - Create a new Customer. Set the name in page so that modify carries the correct xrec
        BindSubscription(GraphContactMockEvents);
        LibrarySales.CreateCustomer(Customer);
        SetCustomerNameUsingCustomerCard(Customer);
        UnbindSubscription(GraphContactMockEvents);

        // Verify
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");

        ContactBusinessRelation.FindFirst;
        Contact.Get(ContactBusinessRelation."Contact No.");

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncronizeContactConnectionName, true);
        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact);

        Assert.IsTrue(LibraryGraphSync.CheckContactIsCustomer(Contact), '');
        Assert.IsTrue(LibraryGraphSync.CheckGraphContactIsCustomer(GraphContact), '');
        GraphContact.TestField(DisplayName, Contact.Name);
        GraphContact.TestField(DisplayName, Customer.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNewGraphCustomerCreatesNewCustomer()
    var
        Customer: Record Customer;
        GraphContact: Record "Graph Contact";
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [GIVEN] Enabled Graph Sync
        // [WHEN]  A new graph Customer is created
        // [THEN]  The sync creates a new Customer in NAV
        Initialize;

        // Excercise - Create a new graph contact and set IsCustomer to true.
        LibraryGraphSync.CreateGraphCompanyContact(GraphContact, InboundContactConnectionName);
        LibraryGraphSync.SetGraphContactAsCustomer(GraphContact, InboundContactConnectionName);
        LibraryGraphSync.MockIncomingContact(GraphContact, 'Created');

        // Verify
        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact);
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");

        ContactBusinessRelation.FindFirst;
        Customer.Get(ContactBusinessRelation."No.");

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, InboundContactConnectionName, true);
        Assert.IsTrue(LibraryGraphSync.CheckContactIsCustomer(Contact), '');
        Contact.TestField(Name, CopyStr(GraphContact.DisplayName, 1, MaxStrLen(Contact.Name)));
        Customer.TestField(Name, CopyStr(GraphContact.DisplayName, 1, MaxStrLen(Customer.Name)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNewVendorCreatesNewGraphContact()
    var
        Vendor: Record Vendor;
        GraphContact: Record "Graph Contact";
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [GIVEN] Enabled Graph Sync
        // [WHEN]  A new Vendor is created in Nav
        // [THEN]  The Vendor is synced to Graph through the contact
        Initialize;

        // Excercise - Create a new Customer. Set the name in page so that modify carries the correct xrec
        BindSubscription(GraphContactMockEvents);
        LibraryPurchase.CreateVendor(Vendor);
        UnbindSubscription(GraphContactMockEvents);

        // Verify
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetRange("No.", Vendor."No.");

        ContactBusinessRelation.FindFirst;
        Contact.Get(ContactBusinessRelation."Contact No.");

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncronizeContactConnectionName, true);
        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact);

        Assert.IsTrue(LibraryGraphSync.CheckContactIsVendor(Contact), '');
        Assert.IsTrue(LibraryGraphSync.CheckGraphContactIsVendor(GraphContact), '');
        GraphContact.TestField(DisplayName, Contact.Name);
        GraphContact.TestField(DisplayName, Vendor.Name);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure RunGraphSyncToIntegrationTable(Contact: Record Contact)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphIntegrationTableSync: Codeunit "Graph Integration Table Sync";
        SourceRecRef: RecordRef;
        MappingCode: Code[20];
    begin
        MappingCode := GraphDataSetup.GetMappingCodeForTable(DATABASE::Contact);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, MappingCode);
        SourceRecRef.GetTable(Contact);
        GraphIntegrationTableSync.PerformRecordSynchToIntegrationTable(IntegrationTableMapping, SourceRecRef);
    end;

    local procedure RunGraphSyncFromIntegrationTable(GraphContact: Record "Graph Contact")
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphIntegrationTableSync: Codeunit "Graph Integration Table Sync";
        SourceRecRef: RecordRef;
        MappingCode: Code[20];
    begin
        MappingCode := GraphDataSetup.GetMappingCodeForTable(DATABASE::Contact);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, MappingCode);
        SourceRecRef.GetTable(GraphContact);
        GraphIntegrationTableSync.PerformRecordSynchFromIntegrationTable(IntegrationTableMapping, SourceRecRef);
    end;

    local procedure SetCustomerNameUsingCustomerCard(var Customer: Record Customer)
    var
        CustomerCard: TestPage "Customer Card";
    begin
        CustomerCard.OpenEdit;
        CustomerCard.GotoRecord(Customer);
        CustomerCard.Name.SetValue(LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer));
        CustomerCard.OK.Invoke;
        Customer.Find;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5451, 'OnBeforeSynchronizationStart', '', false, false)]
    local procedure IgnoreRecordOnBeforeSynchronizationStart(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
        IgnoreRecord := true;
    end;
}

