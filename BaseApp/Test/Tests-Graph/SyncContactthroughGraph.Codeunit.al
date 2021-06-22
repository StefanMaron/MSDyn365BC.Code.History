codeunit 134620 "Sync Contact through Graph"
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
        GraphBackgroundSyncSubscr: Codeunit "Graph Background Sync. Subscr.";
        GraphDataSetup: Codeunit "Graph Data Setup";
        IsInitialized: Boolean;
        InboundConnectionName: Text;
        SubscriptionConnectionName: Text;
        SynchronizeConnectionName: Text;
        IntegrationMappingCode: Code[20];

    [Test]
    [Scope('OnPrem')]
    procedure SkipSyncingTemporaryContactToGraph()
    var
        GraphContact: Record "Graph Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationRecord: Record "Integration Record";
        TempContact: Record Contact temporary;
        SyncContactThroughGraph: Codeunit "Sync Contact through Graph";
    begin
        Initialize;

        // Setup
        BindSubscription(SyncContactThroughGraph);
        TempContact.Init;
        TempContact."First Name" := LibraryUtility.GenerateGUID;
        TempContact.Insert;
        UnbindSubscription(SyncContactThroughGraph);

        // Exercise
        TempContact.Surname := LibraryUtility.GenerateGUID;
        TempContact.Modify;

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsEmpty(IntegrationSynchJob);

        IntegrationRecord.SetRange("Record ID", TempContact.RecordId);
        Assert.RecordIsEmpty(IntegrationRecord);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SubscriptionConnectionName, true);
        GraphContact.SetRange(GivenName, TempContact."First Name");
        GraphContact.SetRange(Surname, TempContact.Surname);
        Assert.RecordIsEmpty(GraphContact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SkipSyncingContactWhenGraphSyncDisabledButBusinessProfileSyncIsEnabled()
    var
        GraphContact: Record "Graph Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Contact: Record Contact;
        CompanyInformation: Record "Company Information";
        MarketingSetup: Record "Marketing Setup";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        Initialize;

        // Setup
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        CompanyInformation.Get;
        CompanyInformation."Sync with O365 Bus. profile" := true;
        CompanyInformation.Modify;

        MarketingSetup.Get;
        MarketingSetup."Sync with Microsoft Graph" := false;
        MarketingSetup.Modify;

        // Exercise
        LibraryMarketing.CreatePersonContact(Contact);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsEmpty(IntegrationSynchJob);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SubscriptionConnectionName, true);
        GraphContact.SetRange(GivenName, Contact."First Name");
        GraphContact.SetRange(Surname, Contact.Surname);
        Assert.RecordIsEmpty(GraphContact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncNewContactToGraph()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactThroughGraph: Codeunit "Sync Contact through Graph";
    begin
        Initialize;

        // Setup
        BindSubscription(SyncContactThroughGraph);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        LibraryGraphSync.EnableGraphSync;
        UnbindSubscription(SyncContactThroughGraph);

        // Exercise
        LibraryMarketing.CreatePersonContact(Contact);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeConnectionName, true);
        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncNewContactFromGraph()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactThroughGraph: Codeunit "Sync Contact through Graph";
    begin
        Initialize;

        // Setup
        BindSubscription(SyncContactThroughGraph);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact, SynchronizeConnectionName);
        LibraryGraphSync.EnableGraphSync;
        UnbindSubscription(SyncContactThroughGraph);

        // Exercise
        IntegrationTableMapping.Find;
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeConnectionName);
        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncUpdatedContactToGraphSameTimestampSkipped()
    var
        Contact: Record Contact;
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphContact: Record "Graph Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactThroughGraph: Codeunit "Sync Contact through Graph";
    begin
        Initialize;

        // Setup
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        CreatePersonContactSyncedToGraph(Contact, GraphIntegrationRecord, IntegrationTableMapping);

        BindSubscription(SyncContactThroughGraph);
        UpdateContactQuicklyOccurringAtSameTimestamp(Contact, GraphIntegrationRecord);
        UnbindSubscription(SyncContactThroughGraph);

        // Exercise
        IntegrationTableMapping.Find;
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeConnectionName, true);
        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact);
        AssertPersonContactDetailsNotEqualGraphContactDetails(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncUpdatedContactFromGraphSameTimestampForceSynced()
    begin
        SyncUpdatedContactFromGraphWithTimestampChanges(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncUpdatedContactFromGraphDifferentTimestampSynced()
    begin
        SyncUpdatedContactFromGraphWithTimestampChanges(false);
    end;

    local procedure SyncUpdatedContactFromGraphWithTimestampChanges(QuickUpdate: Boolean)
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactThroughGraph: Codeunit "Sync Contact through Graph";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        Initialize;

        // Setup
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        CreateGraphContactSyncedFromGraph(GraphContact, GraphIntegrationRecord, IntegrationTableMapping);

        BindSubscription(SyncContactThroughGraph);
        if QuickUpdate then
            UpdateGraphContactQuicklyOccurringAtSameTimestamp(GraphContact, GraphIntegrationRecord)
        else
            UpdateGraphContactSlowlyOccurringAtDifferentTimestamp(GraphContact, GraphIntegrationRecord);
        UnbindSubscription(SyncContactThroughGraph);

        // Exercise
        LibraryGraphSync.MockIncomingContact(GraphContact, GraphWebhookSyncToNAV.GetGraphSubscriptionUpdatedChangeType);
        IntegrationTableMapping.Find;
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncUpdatedContactBidirectionallyWithoutConflicts()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactThroughGraph: Codeunit "Sync Contact through Graph";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
        FirstName: Text[10];
        MiddleName: Text[15];
    begin
        Initialize;

        // Setup
        LibraryGraphSync.CreateGraphWebhookSubscription(DATABASE::Contact);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        LibraryGraphSync.EnableGraphSync;
        CreatePersonContactSyncedFromGraphContact(GraphContact, Contact);

        // Exercise
        FirstName := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 1), 1, 10);
        MiddleName := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(15, 1), 1, 15);

        BindSubscription(SyncContactThroughGraph);
        Contact.Validate("First Name", FirstName);
        Contact.Modify(true);
        UnbindSubscription(SyncContactThroughGraph);

        SetMiddleNameOnGraph(GraphContact, MiddleName);
        LibraryGraphSync.MockIncomingContact(GraphContact, GraphWebhookSyncToNAV.GetGraphSubscriptionUpdatedChangeType);
        IntegrationTableMapping.Find;
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        Contact.Get(Contact."No.");
        Contact.TestField("Middle Name", GraphContact.MiddleName);
        Contact.TestField("First Name", GraphContact.GivenName);

        GraphContact.Get(GraphContact.Id);
        GraphContact.TestField(GivenName, Contact."First Name");
        GraphContact.TestField(MiddleName, MiddleName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncUpdatedContactBidirectionallyOverridingConflictsFromGraph()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        Initialize;

        // Setup
        LibraryGraphSync.CreateGraphWebhookSubscription(DATABASE::Contact);
        LibraryGraphSync.EnableGraphSync;
        CreatePersonContactSyncedFromGraphContact(GraphContact, Contact);
        LibraryGraphSync.EditContactBasicDetails(Contact);
        LibraryGraphSync.EditGraphContactBasicDetails(GraphContact);

        // Exercise
        LibraryGraphSync.MockIncomingContact(GraphContact, GraphWebhookSyncToNAV.GetGraphSubscriptionUpdatedChangeType);

        // Verify
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, InboundConnectionName, true);
        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncDeletedContact()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationRecord: Record "Integration Record";
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphId: Text[250];
    begin
        Initialize;

        // Setup
        LibraryGraphSync.EnableGraphSync;
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        CreateGraphContactSyncedFromGraph(GraphContact, GraphIntegrationRecord, IntegrationTableMapping);
        IntegrationRecord.FindByIntegrationId(GraphIntegrationRecord."Integration ID");
        Contact.Get(IntegrationRecord."Record ID");
        GraphId := GraphContact.Id;
        IntegrationRecord.FindByRecordId(Contact.RecordId);

        // Exercise
        Contact.Delete;
        Commit;

        // Verify
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeConnectionName, true);
        IntegrationRecord.Get(IntegrationRecord."Integration ID");
        IntegrationRecord.TestField("Deleted On");

        asserterror GraphIntegrationRecord.Get(GraphId, IntegrationRecord."Integration ID");
        asserterror GraphContact.Get(GraphId);
    end;

    local procedure Initialize()
    var
        Contact: Record Contact;
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
    begin
        LibraryGraphSync.DisableGraphSync;
        LibraryGraphSync.DeleteAllLogRecords;
        LibraryGraphSync.DeleteAllContactIntegrationMappingDetails;
        LibraryGraphSync.RegisterTestConnections;
        Contact.DeleteAll;

        InboundConnectionName := GraphConnectionSetup.GetInboundConnectionName(DATABASE::Contact);
        SubscriptionConnectionName := GraphConnectionSetup.GetSubscriptionConnectionName(DATABASE::Contact);
        SynchronizeConnectionName := GraphConnectionSetup.GetSynchronizeConnectionName(DATABASE::Contact);
        IntegrationMappingCode := GraphDataSetup.GetMappingCodeForTable(DATABASE::Contact);

        if IsInitialized then
            exit;

        BindSubscription(GraphBackgroundSyncSubscr);

        IsInitialized := true;
    end;

    local procedure CreatePersonContactSyncedToGraph(var Contact: Record Contact; var GraphIntegrationRecord: Record "Graph Integration Record"; IntegrationTableMapping: Record "Integration Table Mapping")
    begin
        LibraryMarketing.CreatePersonContact(Contact);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);
        LibraryGraphSync.FindGraphIntegrationRecordForContact(GraphIntegrationRecord, Contact.RecordId);
    end;

    local procedure CreateGraphContactSyncedFromGraph(var GraphContact: Record "Graph Contact"; var GraphIntegrationRecord: Record "Graph Integration Record"; IntegrationTableMapping: Record "Integration Table Mapping")
    var
        GraphSubscriptionMgt: Codeunit "Graph Subscription Management";
    begin
        LibraryGraphSync.CreateGraphPersonContact(GraphContact, SynchronizeConnectionName);
        LibraryGraphSync.MockIncomingContact(GraphContact, GraphSubscriptionMgt.GetGraphSubscriptionCreatedChangeType);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);
        LibraryGraphSync.FindGraphIntegrationRecordForGraphContact(GraphIntegrationRecord, GraphContact.Id);
    end;

    local procedure CreatePersonContactSyncedFromGraphContact(var GraphContact: Record "Graph Contact"; var Contact: Record Contact)
    var
        GraphSubscriptionMgt: Codeunit "Graph Subscription Management";
    begin
        LibraryGraphSync.CreateGraphPersonContact(GraphContact, InboundConnectionName);
        LibraryGraphSync.MockIncomingContact(GraphContact, GraphSubscriptionMgt.GetGraphSubscriptionCreatedChangeType);
        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact);
    end;

    local procedure SetMiddleNameOnGraph(var GraphContact: Record "Graph Contact"; NewMiddleName: Text)
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, InboundConnectionName, true);
        GraphContact.MiddleName := CopyStr(NewMiddleName, 1, MaxStrLen(GraphContact.MiddleName));
        GraphContact.DeltaToken := LibraryGraphSync.GenerateRandomDeltaToken;
        GraphContact.ChangeKey := LibraryGraphSync.GenerateRandomDeltaToken;
        GraphContact.Modify(true);
    end;

    local procedure UpdateContactQuicklyOccurringAtSameTimestamp(var Contact: Record Contact; var GraphIntegrationRecord: Record "Graph Integration Record")
    begin
        LibraryGraphSync.EditContactBasicDetails(Contact);
        LibraryGraphSync.SetSameIntegrationTimestampForContact(GraphIntegrationRecord, Contact.RecordId);
    end;

    local procedure UpdateGraphContactQuicklyOccurringAtSameTimestamp(var GraphContact: Record "Graph Contact"; var GraphIntegrationRecord: Record "Graph Integration Record")
    begin
        LibraryGraphSync.EditGraphContactBasicDetails(GraphContact);
        LibraryGraphSync.SetSameIntegrationTimestampForGraphContact(GraphIntegrationRecord, GraphContact);
    end;

    local procedure UpdateGraphContactSlowlyOccurringAtDifferentTimestamp(var GraphContact: Record "Graph Contact"; var GraphIntegrationRecord: Record "Graph Integration Record")
    begin
        LibraryGraphSync.EditGraphContactBasicDetails(GraphContact);
        LibraryGraphSync.SetDifferentIntegrationTimestampForGraphContact(GraphIntegrationRecord, GraphContact);
    end;

    local procedure AssertPersonContactDetailsEqualGraphContactDetails(var GraphContact: Record "Graph Contact"; Contact: Record Contact)
    begin
        // DisplayName is set in Exchange by combining Title, GivenName, MiddleName, Surname and Generation. In test mode it is not set.
        Contact.TestField("First Name", CopyStr(GraphContact.GivenName, 1, MaxStrLen(Contact."First Name")));
        Contact.TestField("Middle Name", CopyStr(GraphContact.MiddleName, 1, MaxStrLen(Contact."Middle Name")));
        Contact.TestField(Surname, CopyStr(GraphContact.Surname, 1, MaxStrLen(Contact.Surname)));
    end;

    local procedure AssertPersonContactDetailsNotEqualGraphContactDetails(var GraphContact: Record "Graph Contact"; Contact: Record Contact)
    begin
        Assert.AreNotEqual(CopyStr(GraphContact.DisplayName, 1, MaxStrLen(Contact.Name)), Contact.Name, '');
        Assert.AreNotEqual(CopyStr(GraphContact.GivenName, 1, MaxStrLen(Contact."First Name")), Contact."First Name", '');
        Assert.AreNotEqual(CopyStr(GraphContact.MiddleName, 1, MaxStrLen(Contact."Middle Name")), Contact."Middle Name", '');
        Assert.AreNotEqual(CopyStr(GraphContact.Surname, 1, MaxStrLen(Contact.Surname)), Contact.Surname, '');
    end;

    [EventSubscriber(ObjectType::Codeunit, 5451, 'OnBeforeSynchronizationStart', '', false, false)]
    [Scope('OnPrem')]
    procedure SkipRecordSyncingOnBeforeSyncHandler(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
        IgnoreRecord := true;
    end;
}

