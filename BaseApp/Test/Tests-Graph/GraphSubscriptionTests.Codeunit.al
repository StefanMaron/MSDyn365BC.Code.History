codeunit 134625 "Graph Subscription Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Subscription]
    end;

    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        NameValueBuffer: Record "Name/Value Buffer";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryGraphSync: Codeunit "Library - Graph Sync";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        GraphBackgroundSyncSubscr: Codeunit "Graph Background Sync. Subscr.";
        TelemetryBackgroundScheduler: Codeunit "Telemetry Background Scheduler";
        IsInitialized: Boolean;
        InboundConnectionName: Text;
        SubscriptionConnectionName: Text;
        SynchronizeConnectionName: Text;
        WebhookNotificationDetailsErr: Label 'The webhook notification details are not saved on %1.', Comment = 'The webhook notification details are not saved on the archiving record.';
        IntegrationMappingCode: Code[20];

    [Test]
    [Scope('OnPrem')]
    procedure ValidatyIsRecordEmpty()
    var
        Contact: Record Contact;
        GraphDataSetup: Codeunit "Graph Data Setup";
        RecordRef: RecordRef;
    begin
        // [SCENARIO 225226] We can determine whether a candidate record for syncing is empty.

        // [GIVEN] Integration mappings exist for contact table
        Initialize(DATABASE::Contact);

        // [WHEN] Empty contact record is passed
        Contact.Init();
        RecordRef.GetTable(Contact);

        // [THEN] Result of CanSyncRecord is false
        Assert.IsFalse(GraphDataSetup.CanSyncRecord(RecordRef), 'Empty records should not sync.');

        // [WHEN] Contact containing just a number is passed
        Contact."No." := LibraryUtility.GenerateGUID;
        RecordRef.GetTable(Contact);

        // [THEN] Result of CanSyncRecord is still false
        Assert.IsFalse(GraphDataSetup.CanSyncRecord(RecordRef), 'Empty records should not sync.');

        // [WHEN] Contact contains a special value
        Contact.Name := LibraryUtility.GenerateGUID;
        RecordRef.GetTable(Contact);

        // [THEN] Result of CanSyncRecord is true
        Assert.IsTrue(GraphDataSetup.CanSyncRecord(RecordRef), 'Special contact logic not called.');

        // [WHEN] Contact contains a value for a mapped field
        Contact."First Name" := LibraryUtility.GenerateGUID;
        RecordRef.GetTable(Contact);

        // [THEN] Result of CanSyncRecord is true
        Assert.IsTrue(GraphDataSetup.CanSyncRecord(RecordRef), 'Non-empty records should sync.');

        // [WHEN] Contact contains values for multiple mapped fields
        Contact."Company Name" := LibraryUtility.GenerateGUID;
        Contact.Initials := LibraryUtility.GenerateGUID;

        // [THEN] Result of CanSyncRecord is true
        Assert.IsTrue(GraphDataSetup.CanSyncRecord(RecordRef), 'Non-empty records should sync.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateNotificationUrlTest()
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        ExpectedUrl: Text;
    begin
        ExpectedUrl := GetUrl(CLIENTTYPE::OData);
        ExpectedUrl := CopyStr(ExpectedUrl, 1, StrPos(ExpectedUrl, Format(CLIENTTYPE::OData)) - 1) + 'api/webhooks';

        Assert.AreEqual(ExpectedUrl, GraphConnectionSetup.GetGraphNotificationUrl, 'NotificationUrl did not return an expected value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddSubscriptionWhenNoneExistTest()
    var
        WebhookSubscription: Record "Webhook Subscription";
        GraphSubscription: Record "Graph Subscription";
    begin
        // Add a new subscription when the Webhook Subscription table is empty
        // GIVEN Webhook and Graph Subscription tables are empty
        // WHEN  The Graph Subscription Management codeunit is run
        // THEN  A subscription entry is made into the Webhook and Graph Subscription tables
        Initialize(DATABASE::Contact);

        // Excersice
        CODEUNIT.Run(CODEUNIT::"Graph Subscription Management");

        // Verify
        VerifyWebhookAndGraphSubscriptionRecords(WebhookSubscription, GraphSubscription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshAnExistingSubscriptionTest()
    var
        WebhookSubscription: Record "Webhook Subscription";
        GraphSubscription: Record "Graph Subscription";
        BeforeRefresh: DateTime;
    begin
        // Existing subscription expiration datetime is updated if the subscription has not expired
        // GIVEN There is an entry each in Webhook and Graph Subscription tables
        // WHEN  The Graph Subscription Management codeunit is run
        // THEN  The expiration datatime on the existing subscription is extended
        Initialize(DATABASE::Contact);

        // Setup
        CODEUNIT.Run(CODEUNIT::"Graph Subscription Management");

        // Setup - Move the subscription datetime backwards to make sure we see the changes when refreshed
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SubscriptionConnectionName, true);
        GraphSubscription.FindFirst;
        BeforeRefresh := CurrentDateTime + 10000;
        GraphSubscription.ExpirationDateTime := BeforeRefresh;
        GraphSubscription.Modify();

        // Excersice
        CODEUNIT.Run(CODEUNIT::"Graph Subscription Management");

        // Verify
        VerifyWebhookAndGraphSubscriptionRecords(WebhookSubscription, GraphSubscription);
        Assert.AreNotEqual(BeforeRefresh, GraphSubscription.ExpirationDateTime, 'Expiration datetime is not updated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddNewSubscriptionWhenTheExistingOneHasExpiredTest()
    var
        WebhookSubscription: Record "Webhook Subscription";
        GraphSubscription: Record "Graph Subscription";
        ExistingSubscriptionId: Text;
    begin
        // Add a new subscription if the existing subscription has expired
        // GIVEN There is an entry each in Webhook and Graph Subscription tables
        // GIVEN Delete the entry in Graph Subscription table
        // WHEN  The Graph Subscription Management codeunit is run
        // THEN  A new subscription entry is made into the Webhook and Graph Subscription tables
        // THEN  The old entry in Webhook Subscription is deleted
        Initialize(DATABASE::Contact);

        // Setup
        CODEUNIT.Run(CODEUNIT::"Graph Subscription Management");

        // Setup - Delete the GraphSubscription record which simulates the expired subscription
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SubscriptionConnectionName, true);
        GraphSubscription.FindFirst;
        ExistingSubscriptionId := GraphSubscription.Id;
        GraphSubscription.Delete();

        // Excersice
        CODEUNIT.Run(CODEUNIT::"Graph Subscription Management");

        // Verify
        VerifyWebhookAndGraphSubscriptionRecords(WebhookSubscription, GraphSubscription);
        Assert.AreNotEqual(ExistingSubscriptionId, WebhookSubscription."Subscription ID", 'Subscription Id is not updated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewGraphContactCreatesANewNavContact()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        // Notification about a new Graph Contact creates a new Nav Contact
        // GIVEN Integration Table and Field mapping
        // GIVEN A new record in the Graph Contact table
        // WHEN  A new record is inserted into the Webhook Notification table
        // THEN  Graph to Nav Sync kicks in
        // THEN  Coupling records are created
        // THEN  A new Nav Contact is created
        Initialize(DATABASE::Contact);

        // Setup
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        CODEUNIT.Run(CODEUNIT::"Graph Subscription Management");
        LibraryGraphSync.CreateGraphPersonContact(GraphContact, SynchronizeConnectionName);

        // Exercise
        LibraryGraphSync.MockIncomingContact(GraphContact, GraphWebhookSyncToNAV.GetGraphSubscriptionCreatedChangeType);
        SyncContactDetails(IntegrationTableMapping);
        AssertContactExistsForGraphContact(GraphContact, Contact);

        // Verify
        AssertPersonNavContactDetailsEqualGraphContactDetails(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyGraphContactSyncsChangesToNavContact()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        // Notification about modification to a Graph Contact syncs the modifications to Nav Contact
        // GIVEN Integration Table and Field mapping
        // GIVEN Graph Contact record, a corresponding Nav Contact record and the coupling records
        // WHEN  The Graph record is modified and a new record is inserted into the Webhook Notification table
        // THEN  Graph to Nav Sync kicks in
        // THEN  The Nav Contact is updated
        Initialize(DATABASE::Contact);

        // Setup
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        CODEUNIT.Run(CODEUNIT::"Graph Subscription Management");
        LibraryGraphSync.CreateGraphPersonContact(GraphContact, SynchronizeConnectionName);

        SyncContactDetails(IntegrationTableMapping);
        AssertContactExistsForGraphContact(GraphContact, Contact);

        // Exercise
        LibraryGraphSync.EditGraphContactBasicDetails(GraphContact);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, InboundConnectionName, true);
        LibraryGraphSync.MockIncomingContact(GraphContact, GraphWebhookSyncToNAV.GetGraphSubscriptionUpdatedChangeType);
        SyncContactDetails(IntegrationTableMapping);
        Contact.Find;

        // Verify
        AssertPersonNavContactDetailsEqualGraphContactDetails(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyGraphBusinessProfileSyncsChangesToCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        GraphBusinessProfile: Record "Graph Business Profile";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        // Notification about modification to a Graph Contact syncs the modifications to Nav Contact
        // GIVEN Integration Table and Field mapping
        // GIVEN Graph Contact record, a corresponding Nav Contact record and the coupling records
        // WHEN  The Graph record is modified and a new record is inserted into the Webhook Notification table
        // THEN  Graph to Nav Sync kicks in
        // THEN  The Nav Contact is updated
        Initialize(DATABASE::"Company Information");

        // Setup
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        LibraryGraphSync.CreateGraphBusinessProfile(GraphBusinessProfile, SynchronizeConnectionName);

        SyncBusinessProfile(IntegrationTableMapping);
        CompanyInformation.Get();
        CompanyInformation.TestField(Name, GraphBusinessProfile.Name);

        // Exercise
        LibraryGraphSync.EditGraphBusinessProfileBasicDetails(GraphBusinessProfile);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, InboundConnectionName, true);
        SyncBusinessProfile(IntegrationTableMapping);
        CompanyInformation.Get();

        // Verify
        AssertCompanyInformationDetailsEqualGraphBusinessProfileDetails(GraphBusinessProfile, CompanyInformation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteGraphContactDeletesNavContact()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationRecord: Record "Integration Record";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        // Notification about deletion of a Graph Contact syncs the changes to the Nav Contact
        // GIVEN Integration Table and Field mapping
        // GIVEN Graph Contact record, a corresponding Nav Contact record and the coupling records
        // WHEN  The Graph record is deleted and a new record is inserted into the Webhook Notification table
        // THEN  Graph to Nav Sync kicks in
        // THEN  The Nav Contact is removed
        Initialize(DATABASE::Contact);

        // Setup
        LibraryGraphSync.CreateGraphWebhookSubscription(DATABASE::Contact);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        CODEUNIT.Run(CODEUNIT::"Graph Subscription Management");
        LibraryGraphSync.CreateGraphPersonContact(GraphContact, SynchronizeConnectionName);

        SyncContactDetails(IntegrationTableMapping);
        AssertContactExistsForGraphContact(GraphContact, Contact);
        FindIntegrationRecords(GraphIntegrationRecord, IntegrationRecord, Contact.RecordId);

        // Exercise
        DeleteLogsAndMockIncomingContact(GraphContact, GraphWebhookSyncToNAV.GetGraphSubscriptionDeletedChangeType);

        // Verify
        AssertSyncJobAndIntegrationRecords(IntegrationSynchJobErrors, GraphIntegrationRecord, IntegrationRecord);
        asserterror Contact.Get(Contact."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteGraphContactDeletesNavCustomerIfNoOpenOrPostedDocs()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationRecord: Record "Integration Record";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        Initialize(DATABASE::Contact);

        // Setup
        LibraryGraphSync.CreateGraphWebhookSubscription(DATABASE::Contact);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        CODEUNIT.Run(CODEUNIT::"Graph Subscription Management");
        LibraryGraphSync.CreateGraphPersonContact(GraphContact, SynchronizeConnectionName);
        LibraryGraphSync.SetGraphContactAsCustomer(GraphContact, SynchronizeConnectionName);

        SyncContactDetails(IntegrationTableMapping);
        AssertContactExistsForGraphContact(GraphContact, Contact);
        GetCustomerForContact(Contact, Customer);
        FindIntegrationRecords(GraphIntegrationRecord, IntegrationRecord, Contact.RecordId);

        // Exercise
        DeleteLogsAndMockIncomingContact(GraphContact, GraphWebhookSyncToNAV.GetGraphSubscriptionDeletedChangeType);

        // Verify
        AssertSyncJobAndIntegrationRecords(IntegrationSynchJobErrors, GraphIntegrationRecord, IntegrationRecord);
        asserterror Customer.Get(Customer."No.");
        asserterror Contact.Get(Contact."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteGraphContactDeletesNavContactAndBlocksCustomerIfOpenDocs()
    var
        ContBusRel: Record "Contact Business Relation";
        PaymentMethod: Record "Payment Method";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationRecord: Record "Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        // Notification about deletion of a Graph Contact syncs the changes to the Nav Contact
        // GIVEN Integration Table and Field mapping
        // GIVEN Graph Contact record, a corresponding Nav Contact record and the coupling records
        // WHEN  The Graph record is deleted and a new record is inserted into the Webhook Notification table
        // THEN  Graph to Nav Sync kicks in
        // THEN  The contacts is deleted and the linked customer is set to Blocked::All if there are any open documents
        Initialize(DATABASE::Contact);

        // Setup
        LibraryGraphSync.CreateGraphWebhookSubscription(DATABASE::Contact);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        CODEUNIT.Run(CODEUNIT::"Graph Subscription Management");
        LibraryGraphSync.CreateGraphCompanyContact(GraphContact, SynchronizeConnectionName);
        LibraryGraphSync.SetGraphContactAsCustomer(GraphContact, SynchronizeConnectionName);

        SyncContactDetails(IntegrationTableMapping);
        AssertContactExistsForGraphContact(GraphContact, Contact);

        GetCustomerForContact(Contact, Customer);
        Customer.TestField(Blocked, Customer.Blocked::" ");
        FindIntegrationRecords(GraphIntegrationRecord, IntegrationRecord, Contact.RecordId);

        // Exercise
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        LibraryERM.FindPaymentMethod(PaymentMethod);
        Customer.Validate("Customer Posting Group", LibrarySales.FindCustomerPostingGroup);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);  // Mandatory for posting in ES build
        Customer.Validate("Payment Terms Code", LibraryERM.FindPaymentTermsCode);  // Mandatory for posting in ES build
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate(Name, LibraryUtility.GenerateGUID);
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        DeleteLogsAndMockIncomingContact(GraphContact, GraphWebhookSyncToNAV.GetGraphSubscriptionDeletedChangeType);

        // Verify
        Customer.Get(Customer."No.");
        Customer.TestField(Blocked, Customer.Blocked::All);
        Assert.IsFalse(ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, Customer."No."), 'Relation is not deleted');
        asserterror Contact.Get(Contact."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteGraphContactDeletesNavContactAndBlocksCustomerIfPostedDocs()
    var
        PaymentMethod: Record "Payment Method";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationRecord: Record "Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        // Notification about deletion of a Graph Contact syncs the changes to the Nav Contact
        // GIVEN Integration Table and Field mapping
        // GIVEN Graph Contact record, a corresponding Nav Contact record and the coupling records
        // WHEN  The Graph record is deleted and a new record is inserted into the Webhook Notification table
        // THEN  Graph to Nav Sync kicks in
        // THEN  The contacts is deleted and the linked customer is set to Blocked::All if there are any posted documents
        Initialize(DATABASE::Contact);
        // Setup
        LibraryGraphSync.CreateGraphWebhookSubscription(DATABASE::Contact);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        CODEUNIT.Run(CODEUNIT::"Graph Subscription Management");
        LibraryGraphSync.CreateGraphPersonContact(GraphContact, SynchronizeConnectionName);
        LibraryGraphSync.SetGraphContactAsCustomer(GraphContact, SynchronizeConnectionName);

        SyncContactDetails(IntegrationTableMapping);
        AssertContactExistsForGraphContact(GraphContact, Contact);
        GetCustomerForContact(Contact, Customer);
        FindIntegrationRecords(GraphIntegrationRecord, IntegrationRecord, Contact.RecordId);

        // Exercise
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Customer Posting Group", LibrarySales.FindCustomerPostingGroup);
        LibraryERM.FindPaymentMethod(PaymentMethod);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);  // Mandatory for posting in ES build
        Customer.Validate("Payment Terms Code", LibraryERM.FindPaymentTermsCode);  // Mandatory for posting in ES build
        Customer.Modify(true);
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        DeleteLogsAndMockIncomingContact(GraphContact, GraphWebhookSyncToNAV.GetGraphSubscriptionDeletedChangeType);

        // Verify
        Customer.Get(Customer."No.");
        Customer.TestField(Blocked, Customer.Blocked::All);
        asserterror Contact.Get(Contact."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteGraphContactDeletesNavContactAndBlocksVendBank()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationRecord: Record "Integration Record";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        // Notification about deletion of a Graph Contact syncs the changes to the Nav Contact
        // GIVEN Integration Table and Field mapping
        // GIVEN Graph Contact record, a corresponding Nav Contact record and the coupling records
        // WHEN  The Graph record is deleted and a new record is inserted into the Webhook Notification table
        // THEN  Graph to Nav Sync kicks in
        // THEN  The contacts is deleted and the linked vendor is set to Blocked::All, Bank is set to Blocked = TRUE
        Initialize(DATABASE::Contact);

        // Setup
        LibraryGraphSync.CreateGraphWebhookSubscription(DATABASE::Contact);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        CODEUNIT.Run(CODEUNIT::"Graph Subscription Management");
        LibraryGraphSync.CreateGraphCompanyContact(GraphContact, SynchronizeConnectionName);
        LibraryGraphSync.SetGraphContactAsVendor(GraphContact, SynchronizeConnectionName);
        LibraryGraphSync.SetGraphContactAsBank(GraphContact, SynchronizeConnectionName);

        SyncContactDetails(IntegrationTableMapping);
        AssertContactExistsForGraphContact(GraphContact, Contact);

        GetVendorForContact(Contact, Vendor);
        Vendor.TestField(Blocked, Vendor.Blocked::" ");
        GetBankForContact(Contact, BankAccount);
        BankAccount.TestField(Blocked, false);
        FindIntegrationRecords(GraphIntegrationRecord, IntegrationRecord, Contact.RecordId);

        // Exercise
        DeleteLogsAndMockIncomingContact(GraphContact, GraphWebhookSyncToNAV.GetGraphSubscriptionDeletedChangeType);

        // Verify
        AssertSyncJobAndIntegrationRecords(IntegrationSynchJobErrors, GraphIntegrationRecord, IntegrationRecord);
        Vendor.Get(Vendor."No.");
        Vendor.TestField(Blocked, Vendor.Blocked::All);
        BankAccount.Get(BankAccount."No.");
        BankAccount.TestField(Blocked, true);
        asserterror Contact.Get(Contact."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogErrorForMissedSubscriptionChangeType()
    var
        GraphContact: Record "Graph Contact";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        Initialize(DATABASE::Contact);

        // Setup
        LibraryGraphSync.CreateGraphWebhookSubscription(DATABASE::Contact);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        CODEUNIT.Run(CODEUNIT::"Graph Subscription Management");
        LibraryGraphSync.CreateGraphPersonContact(GraphContact, SynchronizeConnectionName);
        SyncContactDetails(IntegrationTableMapping);

        // Exercise
        LibraryGraphSync.DeleteAllLogRecords;
        LibraryGraphSync.MockIncomingContact(GraphContact, GraphWebhookSyncToNAV.GetGraphSubscriptionMissedChangeType);

        // Verify
        AssertLogSyncErrorExists(GraphWebhookSyncToNAV.GetGraphSubscriptionMissedChangeType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogErrorForUnsupportedSubscriptionChangeType()
    var
        GraphContact: Record "Graph Contact";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        ChangeType: Text[50];
    begin
        Initialize(DATABASE::Contact);

        // Setup
        LibraryGraphSync.CreateGraphWebhookSubscription(DATABASE::Contact);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        CODEUNIT.Run(CODEUNIT::"Graph Subscription Management");
        LibraryGraphSync.CreateGraphPersonContact(GraphContact, SynchronizeConnectionName);
        SyncContactDetails(IntegrationTableMapping);

        // Exercise
        ChangeType := LibraryUtility.GenerateGUID;
        LibraryGraphSync.DeleteAllLogRecords;
        LibraryGraphSync.MockIncomingContact(GraphContact, ChangeType);

        // Verify
        AssertLogSyncErrorExists(ChangeType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditNavContactSyncsChangesToGraphContact()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        // A new nav contact(insert + modify) creates a new graph contact
        // GIVEN Integration Table and Field mapping
        // WHEN  The nav contact record is inserted and modified
        // THEN  Nav to Graph Sync kicks in
        // THEN  The graph contact record is created and the record is synced
        Initialize(DATABASE::Contact);

        // Setup
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        LibraryMarketing.CreatePersonContact(Contact);
        LibraryGraphSync.FindGraphIntegrationRecordForContact(GraphIntegrationRecord, Contact.RecordId);
        LibraryGraphSync.SetDifferentIntegrationTimestampForContact(GraphIntegrationRecord, Contact.RecordId);

        // Exercise
        LibraryGraphSync.EditContactBasicDetails(Contact);

        // Verify
        Assert.RecordIsEmpty(IntegrationSynchJobErrors);
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeConnectionName, true);
        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact);
        AssertPersonNavContactDetailsEqualGraphContactDetails(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactInsertSchedulesFutureSync()
    var
        ScheduledTask: Record "Scheduled Task";
        Contact: Record Contact;
    begin
        // [SCENARIO 255226] Inserting a contact will schedule a future sync

        // [GIVEN] Graph contact sync is set up
        Initialize(DATABASE::Contact);

        // [GIVEN] No tasks exist to refresh subscriptions
        DeleteAllSubscriptionTasks;

        // [WHEN] A contact is inserted
        Contact.Init();
        Contact.Name := CreateGuid;
        Contact.Insert(true);
        Sleep(10);

        // [THEN] A delta sync task is scheduled to run within 10 seconds
        ScheduledTask.SetRange("Run Codeunit", CODEUNIT::"Graph Subscription Management");
        ScheduledTask.FindFirst;
        Assert.IsTrue(ScheduledTask."Not Before" - CurrentDateTime < 10000, 'Task not scheduled soon enough.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactInsertEmptyDoesNotScheduleFutureSync()
    var
        ScheduledTask: Record "Scheduled Task";
        Contact: Record Contact;
    begin
        // [SCENARIO 255226] Inserting an empty contact does not schedule future sync

        // [GIVEN] Graph contact sync is set up
        Initialize(DATABASE::Contact);

        // [GIVEN] No tasks exist to refresh subscriptions
        DeleteAllSubscriptionTasks;

        // [WHEN] A contact is inserted
        Contact.Init();
        Contact.Insert(true);
        Sleep(10);

        // [THEN] Since record was empty, no sync was scheduled
        ScheduledTask.SetRange("Run Codeunit", CODEUNIT::"Graph Subscription Management");
        Assert.IsTrue(ScheduledTask.IsEmpty, 'Sync task should not have been created for empty contact.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactInsertUpdatesScheduledFutureSync()
    var
        ScheduledTask: Record "Scheduled Task";
        Contact: Record Contact;
    begin
        // [SCENARIO 255226] Inserting a contact will postpone an already scheduled sync

        // [GIVEN] Graph contact sync is set up
        Initialize(DATABASE::Contact);

        // [GIVEN] No tasks exist to refresh subscriptions
        DeleteAllSubscriptionTasks;

        // [WHEN] A contact is inserted
        Contact.Init();
        Contact.Name := CreateGuid;
        Contact.Insert(true);
        Sleep(1000);

        // [WHEN] Another contact is inserted
        Clear(Contact);
        Contact.Init();
        Contact.Name := CreateGuid;
        Contact.Insert(true);
        Sleep(10);

        // [THEN] Only one sync task is created and will run at least 9 seconds in the future
        ScheduledTask.SetRange("Run Codeunit", CODEUNIT::"Graph Subscription Management");
        Assert.AreEqual(1, ScheduledTask.Count, 'Only one task should have been created.');

        ScheduledTask.FindFirst;
        Assert.IsTrue(ScheduledTask."Not Before" - CurrentDateTime > 9000, 'Scheduled task did not get properly postponed.');
        Assert.IsTrue(ScheduledTask."Not Before" - CurrentDateTime < 10000, 'Scheduled task did not get properly postponed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactModifySchedulesFutureSync()
    var
        ScheduledTask: Record "Scheduled Task";
        Contact: Record Contact;
        IntegrationRecord: Record "Integration Record";
    begin
        // [SCENARIO 261145] Modifying a contact will schedule a contact sync task

        // [GIVEN] Graph contact sync is set up
        Initialize(DATABASE::Contact);

        // [GIVEN] A contact exists.
        Contact.Init();
        Contact."No." := LibraryUtility.GenerateGUID;
        Contact.Name := CreateGuid;
        Contact.Insert(false);

        // [WHEN] The contact is modified.
        Contact.Validate("E-Mail", 'contact@contoso.com');
        Contact.Modify(true);
        Sleep(10);

        // [THEN] A sync task for the record is created.
        IntegrationRecord.FindByRecordId(Contact.RecordId);
        ScheduledTask.SetRange("Run Codeunit", CODEUNIT::"Graph Sync. Runner - OnModify");
        ScheduledTask.SetRange(Record, IntegrationRecord.RecordId);
        ScheduledTask.FindFirst;
        Assert.IsTrue(ScheduledTask."Not Before" - CurrentDateTime < 10000, 'Task not scheduled soon enough.');

        // Cleanup
        Contact.Delete(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactModifySchedulesSeparateSyncTasks()
    var
        ScheduledTask: Record "Scheduled Task";
        Contact: array[3] of Record Contact;
        IntegrationRecord: Record "Integration Record";
        i: Integer;
    begin
        // [SCENARIO 261145] Modifying a contact will schedule a sync task per contact

        // [GIVEN] Graph contact sync is set up
        Initialize(DATABASE::Contact);

        // [GIVEN] Multiple contacts exist.
        for i := 1 to 3 do begin
            Contact[i].Init();
            Contact[i]."No." := LibraryUtility.GenerateGUID;
            Contact[i].Name := CreateGuid;
            Contact[i].Insert(false);

            // [WHEN] Each contact is modified.
            Contact[i].Validate("E-Mail", 'contact@contoso.com');
            Contact[i].Modify(true);
            Sleep(10);
        end;

        // [THEN] A sync task for each modified record is created.
        for i := 1 to 3 do begin
            IntegrationRecord.FindByRecordId(Contact[i].RecordId);
            ScheduledTask.SetRange("Run Codeunit", CODEUNIT::"Graph Sync. Runner - OnModify");
            ScheduledTask.SetRange(Record, IntegrationRecord.RecordId);
            ScheduledTask.FindFirst;
            Assert.IsTrue(ScheduledTask."Not Before" - CurrentDateTime < 10000, 'Task not scheduled soon enough.');

            // Cleanup
            Contact[i].Delete(false);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactModifyUpdatesScheduledFutureSync()
    var
        ScheduledTask: Record "Scheduled Task";
        Contact: Record Contact;
        IntegrationRecord: Record "Integration Record";
    begin
        // [SCENARIO 261145] Modifying a contact will postpone an already scheduled sync

        // [GIVEN] Graph contact sync is set up
        Initialize(DATABASE::Contact);

        // [GIVEN] A contact exists
        Contact.Init();
        Contact."No." := LibraryUtility.GenerateGUID;
        Contact.Name := CreateGuid;
        Contact.Insert(false);

        // [WHEN] The contact is modified.
        Contact.Validate(Name, CreateGuid);
        Contact.Modify(true);
        Sleep(1000);

        // [WHEN] The contact is modified again.
        Contact.Validate(Name, CreateGuid);
        Contact.Modify(true);
        Sleep(10);

        // [THEN] Only one sync task is created and will run at least 9 seconds in the future
        IntegrationRecord.FindByRecordId(Contact.RecordId);
        ScheduledTask.SetRange("Run Codeunit", CODEUNIT::"Graph Sync. Runner - OnModify");
        ScheduledTask.SetRange(Record, IntegrationRecord.RecordId);
        Assert.AreEqual(1, ScheduledTask.Count, 'Only one task should have been created.');

        ScheduledTask.FindFirst;
        Assert.IsTrue(ScheduledTask."Not Before" - CurrentDateTime > 9000, 'Sync task did not get properly scheduled.');
        Assert.IsTrue(ScheduledTask."Not Before" - CurrentDateTime < 10000, 'Sync task did not get properly scheduled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyOpenSchedulesFutureSubscriptionRefreshes()
    var
        ScheduledTask: Record "Scheduled Task";
        GraphSubscriptionManagement: Codeunit "Graph Subscription Management";
        ExpectedTasks: Integer;
    begin
        // [SCENARIO 217093] Signing into the client UI will schedule future webhook refreshes for up to 30 days

        // [GIVEN] Graph contact sync is set up
        Initialize(DATABASE::Contact);

        // [GIVEN] No tasks exist to refresh subscriptions
        DeleteAllSubscriptionTasks;

        // [WHEN] User launches client, triggering CompanyOpen
        OpenCompany;

        // [THEN] Multiple subscription refresh tasks are scheduled up to 30 days in the future and refresh after half the expiration duration
        ExpectedTasks := Round(30 / (GraphSubscriptionManagement.GetMaximumExpirationDateTimeOffset / 86400000 / 2), 1) + 1;
        ScheduledTask.SetRange("Run Codeunit", CODEUNIT::"Graph Subscription Management");
        Assert.AreEqual(ExpectedTasks, ScheduledTask.Count, 'Subscriptions are not scheduled to renew.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyOpenSchedulesFutureSubscriptionRefreshesAfterSomeHaveCompleted()
    var
        ScheduledTask: Record "Scheduled Task";
        GraphSubscriptionManagement: Codeunit "Graph Subscription Management";
        ExpectedTasks: Integer;
    begin
        // [SCENARIO 217093] Signing into the client UI will reschedule future webhook refreshes for up to 30 days

        // [GIVEN] Graph contact sync is set up with existing subscription refresh tasks
        Initialize(DATABASE::Contact);
        OpenCompany;

        // [GIVEN] Some of the tasks have already run.
        RunScheduledSubscriptionTasks(ScheduledTask);

        // [WHEN] User launches client, triggering CompanyOpen.
        OpenCompany;

        // [THEN] Multiple subscription refresh tasks are scheduled up to 30 days in the future and refresh after half the expiration duration
        ExpectedTasks := Round(30 / (GraphSubscriptionManagement.GetMaximumExpirationDateTimeOffset / 86400000 / 2), 1) + 1;
        Assert.AreNearlyEqual(ExpectedTasks, ScheduledTask.Count, 2, 'Subscriptions are not scheduled to renew.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyOpenSchedulesNextSubscriptionRefreshIn15Seconds()
    var
        ScheduledTask: Record "Scheduled Task";
    begin
        // [SCENARIO 217093] Signing into the client UI will schedule the next subscription refresh within 15 seconds if none have previously been scheduled

        // [GIVEN] Graph contact sync is set up
        Initialize(DATABASE::Contact);

        // [GIVEN] No tasks exist to refresh subscriptions
        DeleteAllSubscriptionTasks;

        // [WHEN] User launches client, triggering CompanyOpen
        OpenCompany;

        // [THEN] Multiple subscription refresh tasks are created, the next one within 15 seconds
        FilterAndSortSubscriptionTasks(ScheduledTask, true);
        ScheduledTask.FindFirst;
        Assert.AreNearlyEqual(15000, ScheduledTask."Not Before" - CurrentDateTime, 500, 'Next task should be within 15 seconds.');
    end;

    // [Test]
    [Scope('OnPrem')]
    procedure CompanyOpenDoesNotScheduleSubscriptionRefreshIfTasksAlreadyExist()
    var
        ScheduledTask: Record "Scheduled Task";
    begin
        // [SCENARIO 217093] Signing into the client UI will schedule the next subscription refresh within 15 seconds, even if there are already tasks scheduled

        // [GIVEN] Graph contact sync is set up
        Initialize(DATABASE::Contact);

        // [GIVEN] The maximum future scheduled tasks has been exceeded
        DeleteAllSubscriptionTasks;
        CreateFutureSubscriptions(14);

        // [WHEN] User launches client, triggering CompanyOpen
        OpenCompany;

        // [THEN] The next subscription refresh task is within 15 seconds
        FilterAndSortSubscriptionTasks(ScheduledTask, true);
        Assert.AreEqual(21, ScheduledTask.Count, 'Incorrect number of tasks scheduled');
        ScheduledTask.FindFirst;
        Assert.AreNearlyEqual(15000, ScheduledTask."Not Before" - CurrentDateTime, 500, 'Next task should be within 15 seconds.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyOpenSchedulesLastSubscriptionRefreshIn30Days()
    var
        ScheduledTask: Record "Scheduled Task";
        RunDateTimeOffset: BigInteger;
        RunDateTimeOffsetDays: Decimal;
    begin
        // [SCENARIO 217093] Signing into the client UI will schedule future webhook refreshes for up to 30 days

        // [GIVEN] Graph contact sync is set up with existing subscription tasks scheduled
        Initialize(DATABASE::Contact);
        OpenCompany;

        // [GIVEN] Some of the tasks have run
        RunScheduledSubscriptionTasks(ScheduledTask);

        // [WHEN] User launches client, triggering CompanyOpen
        OpenCompany;

        // [THEN] Multiple subscription refresh tasks are scheduled, the last one within 30 days into the future
        FilterAndSortSubscriptionTasks(ScheduledTask, true);
        ScheduledTask.FindLast;
        RunDateTimeOffset := ScheduledTask."Not Before" - CurrentDateTime;
        RunDateTimeOffsetDays := RunDateTimeOffset / 86400000; // Convert to days
        Assert.AreNearlyEqual(30, RunDateTimeOffsetDays, 3, 'Last subscription refresh task not set far enough out.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyOpenSchedulesLastSubscriptionRefreshIn30DaysEvenIfMaxTasks()
    var
        ScheduledTask: Record "Scheduled Task";
        RunDateTimeOffset: BigInteger;
        RunDateTimeOffsetDays: Decimal;
    begin
        // [SCENARIO 217093] Signing into the client UI will schedule a future webhook refresh in 30 days

        // [GIVEN] Graph contact sync is set up with existing subscription tasks scheduled
        Initialize(DATABASE::Contact);
        OpenCompany;

        // [GIVEN] The maximum number of tasks has been exceeded, but the last one is before the max future date.
        CreateFutureSubscriptions(28);

        // [WHEN] User launches client, triggering CompanyOpen
        OpenCompany;

        // [THEN] A new task is created that is approximately 30 days into the future
        FilterAndSortSubscriptionTasks(ScheduledTask, true);
        ScheduledTask.FindLast;
        RunDateTimeOffset := ScheduledTask."Not Before" - CurrentDateTime;
        RunDateTimeOffsetDays := RunDateTimeOffset / 86400000; // Convert to days
        Assert.AreNearlyEqual(30, RunDateTimeOffsetDays, 3, 'Last subscription refresh task not set far enough out.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScheduleMasterdataTelemetryAfterCompanyOpenDoesNotWorkOnNonSaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        GraphSubscriptionTests: Codeunit "Graph Subscription Tests";
    begin
        // [FEATURE] [SaaS] [Event]
        // [SCENARIO 278062] Telemetry event subscribers from COD1351 do not work on non-SaaS
        Initialize(DATABASE::Contact);
        NameValueBuffer.DeleteAll();
        BindSubscription(GraphSubscriptionTests);

        // [GIVEN] System setup as non-saas
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] OnAfterCompanyOpen is triggered
        OpenCompany;

        // [THEN] Subscription runs empty and doesn't create a task
        Assert.RecordIsEmpty(NameValueBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScheduleMasterdataTelemetryAfterCompanyOpenWorksOnSaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        GraphSubscriptionTests: Codeunit "Graph Subscription Tests";
    begin
        // [FEATURE] [SaaS] [Event]
        // [SCENARIO 278062] Telemetry event subscribers from COD1351 work on SaaS
        Initialize(DATABASE::Contact);
        NameValueBuffer.DeleteAll();
        BindSubscription(GraphSubscriptionTests);

        // [GIVEN] System setup as saas
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] OnAfterCompanyOpen is triggered
        OpenCompany;

        // [THEN] Subscription runs and tries to create a task
        // OnBeforeTelemetryScheduleTaskHandler runs
        Assert.RecordIsNotEmpty(NameValueBuffer);
        NameValueBuffer.DeleteAll();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure Initialize(TableID: Integer)
    var
        CompanyInformation: Record "Company Information";
        Company: Record Company;
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        GraphDataSetup: Codeunit "Graph Data Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Graph Subscription Tests");

        LibraryGraphSync.DeleteAllLogRecords();
        LibraryGraphSync.DeleteAllContactIntegrationMappingDetails();
        LibraryGraphSync.RegisterTestConnections();

        InboundConnectionName := GraphConnectionSetup.GetInboundConnectionName(TableID);
        SubscriptionConnectionName := GraphConnectionSetup.GetSubscriptionConnectionName(TableID);
        SynchronizeConnectionName := GraphConnectionSetup.GetSynchronizeConnectionName(TableID);
        IntegrationMappingCode := GraphDataSetup.GetMappingCodeForTable(TableID);
        GraphDataSetup.CreateIntegrationMapping(IntegrationMappingCode);

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Graph Subscription Tests");

        LibraryRandom.Init();
        LibraryGraphSync.EnableGraphSync();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        CompanyInformation.Get();
        CompanyInformation."Demo Company" := false;
        CompanyInformation.Modify();

        Company.Get(CompanyName);
        Company."Evaluation Company" := true;
        Company.Modify();

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();

        BindSubscription(GraphBackgroundSyncSubscr);
        BindSubscription(TelemetryBackgroundScheduler);

        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Graph Subscription Tests");
    end;

    local procedure CreateFutureSubscriptions("Count": Integer)
    var
        ScheduledTask: Record "Scheduled Task";
        i: Integer;
    begin
        for i := 1 to Count do begin
            ScheduledTask.Init();
            ScheduledTask.ID := CreateGuid;
            ScheduledTask.Company := CompanyName;
            ScheduledTask."Run Codeunit" := CODEUNIT::"Graph Subscription Management";
            ScheduledTask."Failure Codeunit" := CODEUNIT::"Graph Delta Sync";
            ScheduledTask."Not Before" := CreateDateTime(Today + i, 0T);
            ScheduledTask.Insert();
        end;
    end;

    local procedure DeleteAllSubscriptionTasks()
    var
        ScheduledTask: Record "Scheduled Task";
    begin
        ScheduledTask.SetRange("Run Codeunit", CODEUNIT::"Graph Subscription Management");
        ScheduledTask.DeleteAll();
    end;

    local procedure FilterAndSortSubscriptionTasks(var ScheduledTask: Record "Scheduled Task"; "Ascending": Boolean)
    begin
        ScheduledTask.SetRange("Run Codeunit", CODEUNIT::"Graph Subscription Management");
        ScheduledTask.SetCurrentKey("Not Before", ID);
        ScheduledTask.SetAscending("Not Before", Ascending);
    end;

    local procedure RunScheduledSubscriptionTasks(var ScheduledTask: Record "Scheduled Task")
    var
        TasksToRun: Integer;
        i: Integer;
    begin
        TasksToRun := LibraryRandom.RandIntInRange(0, 20);
        FilterAndSortSubscriptionTasks(ScheduledTask, true);
        for i := 1 to TasksToRun do begin
            ScheduledTask.FindLast;
            ScheduledTask.Delete();
        end;
    end;

    local procedure SyncBusinessProfile(var IntegrationTableMapping: Record "Integration Table Mapping")
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeConnectionName, true);
        IntegrationTableMapping.Find;
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);
    end;

    local procedure SyncContactDetails(var IntegrationTableMapping: Record "Integration Table Mapping")
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeConnectionName, true);
        IntegrationTableMapping.Find;
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);
    end;

    local procedure FindIntegrationRecords(var GraphIntegrationRecord: Record "Graph Integration Record"; var IntegrationRecord: Record "Integration Record"; ContactRecordID: RecordID)
    begin
        LibraryGraphSync.FindGraphIntegrationRecordForContact(GraphIntegrationRecord, ContactRecordID);
        LibraryGraphSync.FindIntegrationRecordForContact(IntegrationRecord, ContactRecordID);
    end;

    local procedure VerifyWebhookAndGraphSubscriptionRecords(var WebhookSubscription: Record "Webhook Subscription"; var GraphSubscription: Record "Graph Subscription")
    var
        GraphSubscriptionManagement: Codeunit "Graph Subscription Management";
        WebRequestHelper: Codeunit "Web Request Helper";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SubscriptionConnectionName, true);

        Assert.RecordCount(WebhookSubscription, 1);
        Assert.RecordCount(GraphSubscription, 1);

        WebhookSubscription.FindFirst;
        GraphSubscription.FindFirst;

        GraphSubscription.TestField(ChangeType, GraphWebhookSyncToNAV.GetGraphSubscriptionChangeTypes);
        Assert.IsTrue(GraphSubscription.ExpirationDateTime > CurrentDateTime + 1000, 'Expiration datetime is not in the future.');
        Assert.IsTrue(WebRequestHelper.IsValidUri(GraphSubscription.Resource), 'Resouce field does not contain a valid URL.');
        Assert.IsTrue(WebRequestHelper.IsValidUri(GraphSubscription.NotificationUrl),
          'Notification URL field does not contain a valid URL.');
        GraphSubscription.TestField(Type, GraphSubscriptionManagement.GetGraphSubscriptionType);

        WebhookSubscription.TestField("Subscription ID", GraphSubscription.Id);
        WebhookSubscription.TestField("Client State", GraphSubscription.ClientState);
        WebhookSubscription.TestField(Endpoint, GraphSubscription.Resource);
    end;

    local procedure AssertContactExistsForGraphContact(var GraphContact: Record "Graph Contact"; var Contact: Record Contact)
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeConnectionName, true);
        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact);
    end;

    local procedure GetCustomerForContact(Contact: Record Contact; var Customer: Record Customer)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.FindFirst;
        Customer.Get(ContactBusinessRelation."No.");
    end;

    local procedure GetVendorForContact(Contact: Record Contact; var Vendor: Record Vendor)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.FindFirst;
        Vendor.Get(ContactBusinessRelation."No.");
    end;

    local procedure GetBankForContact(Contact: Record Contact; var BankAccount: Record "Bank Account")
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::"Bank Account");
        ContactBusinessRelation.FindFirst;
        BankAccount.Get(ContactBusinessRelation."No.");
    end;

    local procedure AssertIntegrationRecordsAreArchived(GraphIntegrationRecord: Record "Graph Integration Record"; IntegrationRecord: Record "Integration Record")
    var
        IntegrationRecordArchive: Record "Integration Record Archive";
        GraphIntegrationRecArchive: Record "Graph Integration Rec. Archive";
    begin
        GraphIntegrationRecArchive.SetRange("Graph ID", GraphIntegrationRecord."Graph ID");
        GraphIntegrationRecArchive.SetRange("Integration ID", GraphIntegrationRecord."Integration ID");
        Assert.RecordCount(GraphIntegrationRecArchive, 1);
        GraphIntegrationRecArchive.FindFirst;
        Assert.IsTrue(GraphIntegrationRecArchive."Webhook Notification".HasValue,
          StrSubstNo(WebhookNotificationDetailsErr, GraphIntegrationRecArchive.TableCaption));

        IntegrationRecordArchive.SetRange("Integration ID", IntegrationRecord."Integration ID");
        Assert.RecordCount(IntegrationRecordArchive, 1);
    end;

    local procedure AssertGraphIntegrationRecordIsDeleted(GraphIntegrationRecord: Record "Graph Integration Record")
    var
        DeletedGraphIntegrationRecord: Record "Graph Integration Record";
    begin
        DeletedGraphIntegrationRecord.SetRange("Graph ID", GraphIntegrationRecord."Graph ID");
        DeletedGraphIntegrationRecord.SetRange("Integration ID", GraphIntegrationRecord."Integration ID");
        Assert.RecordIsEmpty(DeletedGraphIntegrationRecord);
    end;

    local procedure AssertIntegrationRecordExists(IntegrationRecord: Record "Integration Record")
    var
        ExistingIntegrationRecord: Record "Integration Record";
    begin
        ExistingIntegrationRecord.SetRange("Integration ID", IntegrationRecord."Integration ID");
        ExistingIntegrationRecord.SetFilter("Record ID", '');
        Assert.RecordIsNotEmpty(ExistingIntegrationRecord);
    end;

    local procedure AssertCompanyInformationDetailsEqualGraphBusinessProfileDetails(var GraphBusinessProfile: Record "Graph Business Profile"; CompanyInformation: Record "Company Information")
    begin
        // DisplayName is set in Exchange by combining Title, GivenName, MiddleName, Surname and Generation. In test mode it is not set.
        CompanyInformation.TestField(Name, GraphBusinessProfile.Name);
        CompanyInformation.TestField("Industrial Classification", GraphBusinessProfile.Industry);
    end;

    local procedure AssertPersonNavContactDetailsEqualGraphContactDetails(var GraphContact: Record "Graph Contact"; Contact: Record Contact)
    begin
        // DisplayName is set in Exchange by combining Title, GivenName, MiddleName, Surname and Generation. In test mode it is not set.
        Contact.TestField("First Name", CopyStr(GraphContact.GivenName, 1, MaxStrLen(Contact."First Name")));
        Contact.TestField("Middle Name", CopyStr(GraphContact.MiddleName, 1, MaxStrLen(Contact."Middle Name")));
        Contact.TestField(Surname, CopyStr(GraphContact.Surname, 1, MaxStrLen(Contact.Surname)));
    end;

    local procedure AssertLogSyncErrorExists(ChangeType: Text[50])
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        EmptyGuid: Guid;
    begin
        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", EmptyGuid);
        Assert.RecordCount(IntegrationSynchJobErrors, 1);
        IntegrationSynchJobErrors.FindFirst;
        Assert.ExpectedMessage(ChangeType, IntegrationSynchJobErrors.Message);
    end;

    local procedure AssertIntegrationSynchJobDeletedCount()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        IntegrationSynchJob.FindFirst;
        IntegrationSynchJob.TestField(Deleted, 1);
    end;

    local procedure AssertSyncJobAndIntegrationRecords(IntegrationSynchJobErrors: Record "Integration Synch. Job Errors"; GraphIntegrationRecord: Record "Graph Integration Record"; IntegrationRecord: Record "Integration Record")
    begin
        Assert.RecordIsEmpty(IntegrationSynchJobErrors);
        AssertIntegrationSynchJobDeletedCount;
        AssertIntegrationRecordsAreArchived(GraphIntegrationRecord, IntegrationRecord);
        AssertGraphIntegrationRecordIsDeleted(GraphIntegrationRecord);
        AssertIntegrationRecordExists(IntegrationRecord);
    end;

    local procedure DeleteLogsAndMockIncomingContact(var GraphContact: Record "Graph Contact"; ChangeTypeTxt: Text[50])
    begin
        LibraryGraphSync.DeleteAllLogRecords;
        LibraryGraphSync.DeleteAllContactIntegrationMappingDetails;
        LibraryGraphSync.MockIncomingContact(GraphContact, ChangeTypeTxt);
    end;

    local procedure OpenCompany()
    var
        O365GettingStarted: Record "O365 Getting Started";
        LogInManagement: Codeunit LogInManagement;
    begin
        // Make sure a record exists in O365 Getting Started so that the
        // system warmup doesn't run (not allowed in test runner).
        O365GettingStarted.Init();
        O365GettingStarted."User ID" := UserId;
        if not O365GettingStarted.Insert() then;

        LogInManagement.CompanyOpen;
    end;

    [EventSubscriber(ObjectType::Codeunit, 1350, 'OnBeforeTelemetryScheduleTask', '', false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeTelemetryScheduleTaskHandler(var DoNotScheduleTask: Boolean)
    begin
        NameValueBuffer.ID := LibraryUtility.GetNewRecNo(NameValueBuffer, NameValueBuffer.FieldNo(ID));
        NameValueBuffer.Insert();
        DoNotScheduleTask := true;
    end;
}

