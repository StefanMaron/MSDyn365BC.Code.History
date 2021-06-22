codeunit 134622 "Sync Contact Related Tables"
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
        LibraryERM: Codeunit "Library - ERM";
        LibraryGraphSync: Codeunit "Library - Graph Sync";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        GraphBackgroundSyncSubscr: Codeunit "Graph Background Sync. Subscr.";
        IsInitialized: Boolean;
        SynchronizeContactConnectionName: Text;
        AddressExistsErr: Label '%1 address exists.', Comment = 'Home address exists.';
        ContactMappingCode: Code[20];

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactWithMultipleAddressesToGraph()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphIntContactAddresses: Codeunit "Graph Int. - Contact Addresses";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        BindSubscription(SyncContactRelatedTables);
        CreatePersonContactWithAddress(Contact);
        LibraryGraphSync.EditContactAlternateAddress(Contact, GraphIntContactAddresses.GetContactAlternativeHomeAddressCode);
        LibraryGraphSync.EditContactAlternateAddress(Contact, GraphIntContactAddresses.GetContactAlternativeOtherAddressCode);
        UnbindSubscription(SyncContactRelatedTables);

        // Exercise
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);
        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact);
        VerifyMultipleAddressesAreSyncedToGraph(GraphContact, Contact);
        AssertPersonContactAlternateOtherAddressEqualsGraphContactOtherAddress(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactWithOnlyHomeAddressToGraph()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphIntContactAddresses: Codeunit "Graph Int. - Contact Addresses";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        BindSubscription(SyncContactRelatedTables);
        CreatePersonContactWithAddress(Contact);
        LibraryGraphSync.EditContactAlternateAddress(Contact, GraphIntContactAddresses.GetContactAlternativeHomeAddressCode);
        UnbindSubscription(SyncContactRelatedTables);

        // Exercise
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);
        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact);
        VerifyMultipleAddressesAreSyncedToGraph(GraphContact, Contact);
        Assert.IsFalse(HasOtherAddress(GraphContact),
          StrSubstNo(AddressExistsErr, GraphIntContactAddresses.GetContactAlternativeOtherAddressCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactWithComment()
    var
        Contact: Record Contact;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        BindSubscription(SyncContactRelatedTables);
        LibraryMarketing.CreatePersonContact(Contact);
        CreatePersonContactComment(RlshpMgtCommentLine, Contact."No.");
        UnbindSubscription(SyncContactRelatedTables);

        // Exercise
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);
        Assert.AreEqual(RlshpMgtCommentLine.Comment, GraphCollectionMgtContact.GetContactComments(Contact), 'Wrong comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactOnInsertComment()
    var
        Contact: Record Contact;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        BindSubscription(SyncContactRelatedTables);
        LibraryMarketing.CreatePersonContact(Contact);
        UnbindSubscription(SyncContactRelatedTables);

        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);
        LibraryGraphSync.DeleteAllLogRecords;

        // Exercise
        CreatePersonContactComment(RlshpMgtCommentLine, Contact."No.");

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);
        Assert.AreEqual(RlshpMgtCommentLine.Comment, GraphCollectionMgtContact.GetContactComments(Contact), 'Wrong comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactOnModyComment()
    var
        Contact: Record Contact;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        BindSubscription(SyncContactRelatedTables);
        LibraryMarketing.CreatePersonContact(Contact);
        CreatePersonContactComment(RlshpMgtCommentLine, Contact."No.");
        UnbindSubscription(SyncContactRelatedTables);

        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);
        LibraryGraphSync.DeleteAllLogRecords;

        // Exercise
        ModifyPersonContactComment(RlshpMgtCommentLine);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);
        Assert.AreEqual(RlshpMgtCommentLine.Comment, GraphCollectionMgtContact.GetContactComments(Contact), 'Wrong comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactOnDeleteComment()
    var
        Contact: Record Contact;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        BindSubscription(SyncContactRelatedTables);
        LibraryMarketing.CreatePersonContact(Contact);
        CreatePersonContactComment(RlshpMgtCommentLine, Contact."No.");
        UnbindSubscription(SyncContactRelatedTables);

        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);
        LibraryGraphSync.DeleteAllLogRecords;

        // Exercise
        RlshpMgtCommentLine.Delete(true);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);
        Assert.AreEqual('', GraphCollectionMgtContact.GetContactComments(Contact), 'Wrong comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactOnRenameComment()
    var
        Contact: Record Contact;
        Contact2: Record Contact;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        BindSubscription(SyncContactRelatedTables);
        LibraryMarketing.CreatePersonContact(Contact);
        CreatePersonContactComment(RlshpMgtCommentLine, Contact."No.");
        LibraryMarketing.CreatePersonContact(Contact2);
        UnbindSubscription(SyncContactRelatedTables);

        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);
        LibraryGraphSync.DeleteAllLogRecords;

        // Exercise
        RlshpMgtCommentLine.Rename(
          RlshpMgtCommentLine."Table Name", Contact2."No.", RlshpMgtCommentLine."Sub No.", RlshpMgtCommentLine."Line No.");

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);
        Assert.AreEqual(RlshpMgtCommentLine.Comment, GraphCollectionMgtContact.GetContactComments(Contact2), 'Wrong comment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactWithOnlyHomeAddressAfterAddingOtherAddressToGraph()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphIntContactAddresses: Codeunit "Graph Int. - Contact Addresses";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        BindSubscription(SyncContactRelatedTables);
        CreatePersonContactWithAddress(Contact);
        LibraryGraphSync.EditContactAlternateAddress(Contact, GraphIntContactAddresses.GetContactAlternativeHomeAddressCode);
        UnbindSubscription(SyncContactRelatedTables);

        // Exercise
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        LibraryGraphSync.DeleteAllLogRecords;
        LibraryGraphSync.EditContactAlternateAddress(Contact, GraphIntContactAddresses.GetContactAlternativeOtherAddressCode);
        UpdateContactSlowlyOccurringAtDifferentTimestamp(Contact.RecordId);

        IntegrationTableMapping.Find;
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);
        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact);
        AssertPersonContactAlternateHomeAddressEqualsGraphContactHomeAddress(GraphContact, Contact);
        AssertPersonContactAlternateOtherAddressEqualsGraphContactOtherAddress(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactWithMultipleAddressesFromGraph()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        BindSubscription(SyncContactRelatedTables);
        CreateGraphContactWithBusinessAddress(GraphContact);
        SetGraphContactHomeAddress(GraphContact);
        SetGraphContactOtherAddress(GraphContact);
        UnbindSubscription(SyncContactRelatedTables);

        // Exercise
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact);
        VerifyMultipleAddressesAreSyncedFromGraph(GraphContact, Contact);
        AssertPersonContactAlternateHomeAddressEqualsGraphContactHomeAddress(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactWithOnlyOtherAddressFromGraph()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphIntContactAddresses: Codeunit "Graph Int. - Contact Addresses";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        BindSubscription(SyncContactRelatedTables);
        CreateGraphContactWithBusinessAddress(GraphContact);
        SetGraphContactOtherAddress(GraphContact);
        UnbindSubscription(SyncContactRelatedTables);

        // Exercise
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact);
        VerifyMultipleAddressesAreSyncedFromGraph(GraphContact, Contact);
        Assert.IsFalse(HasHomeAddress(GraphContact),
          StrSubstNo(AddressExistsErr, GraphIntContactAddresses.GetContactAlternativeHomeAddressCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactWithOnlyOtherAddressAfterAddingHomeAddressFromGraph()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphIntContactAddresses: Codeunit "Graph Int. - Contact Addresses";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        BindSubscription(SyncContactRelatedTables);
        CreateGraphContactWithBusinessAddress(GraphContact);
        SetGraphContactOtherAddress(GraphContact);
        UnbindSubscription(SyncContactRelatedTables);

        // Exercise
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        Assert.IsFalse(HasHomeAddress(GraphContact),
          StrSubstNo(AddressExistsErr, GraphIntContactAddresses.GetContactAlternativeHomeAddressCode));
        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact);
        AssertPersonContactAlternateOtherAddressEqualsGraphContactOtherAddress(GraphContact, Contact);

        // Setup
        LibraryGraphSync.DeleteAllLogRecords;
        SetGraphContactHomeAddress(GraphContact);
        UpdateGraphContactDeltaTokenAndChangeKey(GraphContact);

        // Exercise
        IntegrationTableMapping.Find;
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact);
        AssertPersonContactAlternateHomeAddressEqualsGraphContactHomeAddress(GraphContact, Contact);
        AssertPersonContactAlternateOtherAddressEqualsGraphContactOtherAddress(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactWithProfileQuestionnaireDetailsToGraph()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        BindSubscription(SyncContactRelatedTables);
        LibraryGraphSync.CreateGraphSyncProfileQuestionnaire;
        CreatePersonContactWithExtraDetailsUsingProfileQuestionnaire(Contact);
        UnbindSubscription(SyncContactRelatedTables);

        // Exercise
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact);
        AssertPersonContactExtraDetailsOnQuestionnaireEqualGraphContactExtraDetails(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactWithProfileQuestionnaireDetailsAfterUpdatingPhoneticNamesToGraph()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        BindSubscription(SyncContactRelatedTables);
        LibraryGraphSync.CreateGraphSyncProfileQuestionnaire;
        CreatePersonContactWithExtraDetailsUsingProfileQuestionnaire(Contact);
        UnbindSubscription(SyncContactRelatedTables);

        // Exercise
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        LibraryGraphSync.DeleteAllLogRecords;
        UpdatePersonContactPhoneticNames(Contact);
        UpdateContactSlowlyOccurringAtDifferentTimestamp(Contact.RecordId);

        IntegrationTableMapping.Find;
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact);
        AssertPersonContactExtraDetailsOnQuestionnaireEqualGraphContactExtraDetails(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactWithProfileQuestionnaireDetailsFromGraph()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        BindSubscription(SyncContactRelatedTables);
        LibraryGraphSync.CreateGraphSyncProfileQuestionnaire;
        CreateGraphContactWithExtraDetailsForProfileQuestionnaire(GraphContact);
        UnbindSubscription(SyncContactRelatedTables);

        // Exercise
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact);
        AssertPersonContactExtraDetailsOnQuestionnaireEqualGraphContactExtraDetails(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactWithProfileQuestionnaireDetailsAfterUpdatingWorkDetailsFromGraph()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        Initialize;

        // Setup
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        BindSubscription(SyncContactRelatedTables);
        LibraryGraphSync.CreateGraphSyncProfileQuestionnaire;
        CreateGraphContactWithExtraDetailsForProfileQuestionnaire(GraphContact);
        UnbindSubscription(SyncContactRelatedTables);

        // Exercise
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        LibraryGraphSync.DeleteAllLogRecords;
        SetGraphContactWorkDetailsForProfileQuestionnaire(GraphContact);
        UpdateGraphContactDeltaTokenAndChangeKey(GraphContact);
        IntegrationTableMapping.Find;
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // Verify
        LibraryGraphSync.AssertNoSynchErrors;
        Assert.RecordIsNotEmpty(IntegrationSynchJob);

        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact);
        AssertPersonContactExtraDetailsOnQuestionnaireEqualGraphContactExtraDetails(GraphContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavCreatedContactClearsBusinessTypesWhenNoRelatedRecordsExistForContact()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 217738] Sync engine clears BusinessType flags on NavCreated Graph Contact when no related records exists.
        Initialize;
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        // [GIVEN] NAV contact exists (with no related records) and is linked to a Graph contact
        CreateNavContactAndSync(Contact);

        // [GIVEN] Graph contact has IsBank, IsCustomer, IsVendor, and IsNavCreated set to 1
        SetGraphContactBusinessTypes(Contact, true, true);

        // [WHEN] Contact is modified and a sync is triggered
        ModifyAndSyncContact(Contact);

        // [THEN] The BusinessType flags on the graph contact are cleared since there is no related records.
        VerifyGraphBusinessTypes(Contact, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonNavCreatedContactClearsBusinessTypesWhenNoRelatedRecordsExistForContact()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 217738] Sync engine clears BusinessType flags on NonNavCreated Graph Contact when no related records exist.
        Initialize;
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        // [GIVEN] NAV contact exists (with no related records) and is linked to a Graph contact
        CreateNavContactAndSync(Contact);

        // [GIVEN] Graph contact has IsBank, IsCustomer, IsVendor = 1 and IsNavCreated = 0
        SetGraphContactBusinessTypes(Contact, true, false);

        // [WHEN] Contact is modified and a sync is triggered
        ModifyAndSyncContact(Contact);

        // [THEN] The BusinessType flags on the graph contact are set to 0
        VerifyGraphBusinessTypes(Contact, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavCreatedContactSetsBusinessTypesWhenRelatedRecordsExistForContact()
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
    begin
        // [SCENARIO 217738] Sync engine sets BusinessType flags on NavCreated Graph Contact when the related records exist.
        Initialize;
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        // [GIVEN] NAV contact exists and is linked to a Graph contact
        // [GIVEN] Graph contact has IsBank, IsCustomer, IsVendor, and IsNavCreated set to 0
        CreateNavContactAndSync(Contact);

        // [WHEN] Contact is linked to a bank, customer, and a vendor
        CreateContactBusinessRelation(Contact, ContactBusinessRelation."Link to Table"::"Bank Account");
        CreateContactBusinessRelation(Contact, ContactBusinessRelation."Link to Table"::Customer);
        CreateContactBusinessRelation(Contact, ContactBusinessRelation."Link to Table"::Vendor);

        // [WHEN] Contact is modified and a sync is triggered
        ModifyAndSyncContact(Contact);

        // [THEN] The BusinessType flags on the graph contact are set since there are related records.
        VerifyGraphBusinessTypes(Contact, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonNavCreatedContactSetsBusinessTypesWhenRelatedRecordsExistForContact()
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
    begin
        // [SCENARIO 217738] Sync engine sets BusinessType flags on NonNavCreated Graph Contact when the related records exist.
        Initialize;
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        // [GIVEN] NAV contact exists and is linked to a Graph contact
        CreateNavContactAndSync(Contact);

        // [GIVEN] Graph contact has IsBank, IsCustomer, IsVendor, and IsNavCreated set to 0
        SetGraphContactBusinessTypes(Contact, false, false);

        // [WHEN] Contact is linked to a bank, customer, and a vendor
        CreateContactBusinessRelation(Contact, ContactBusinessRelation."Link to Table"::"Bank Account");
        CreateContactBusinessRelation(Contact, ContactBusinessRelation."Link to Table"::Customer);
        CreateContactBusinessRelation(Contact, ContactBusinessRelation."Link to Table"::Vendor);

        // [WHEN] Contact is modified and a sync is triggered
        ModifyAndSyncContact(Contact);

        // [THEN] The BusinessType flags on the graph contact are set since there are related records.
        VerifyGraphBusinessTypes(Contact, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetBusinessTypesInGraphCreatesRelatedRecordsOnModify()
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        // [SCENARIO 217985] Sync engine creates related records when business types change in graph
        Initialize;
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        // [GIVEN] NAV contact exists (with no related records) and is linked to a Graph contact
        CreateNavContactAndSync(Contact);

        // [GIVEN] The NAV contact is a company contact
        Contact.Validate(Type, Contact.Type::Company);
        Contact."Company No." := Contact."No.";
        ModifyAndSyncContact(Contact);

        // [GIVEN] Graph contact has IsBank, IsCustomer, IsVendor, and IsNavCreated set to 1
        SetGraphContactBusinessTypes(Contact, true, true);
        FindGraphContactForContact(Contact, GraphContact);
        UpdateGraphContactDeltaTokenAndChangeKey(GraphContact);

        // [WHEN] A delta sync is triggered
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // [THEN] The BusinessType flags on the graph contact are unchanged
        VerifyGraphBusinessTypes(Contact, true);

        // [THEN] Related records are created on the NAV side
        VerifyRelatedRecordsOnContact(Contact, true);
    end;

    local procedure Initialize()
    var
        Contact: Record Contact;
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        LibraryGraphSync.DeleteAllLogRecords;
        LibraryGraphSync.DeleteAllContactIntegrationMappingDetails;
        Contact.DeleteAll;

        if IsInitialized then
            exit;

        LibraryGraphSync.RegisterTestConnections;
        ContactMappingCode := GraphDataSetup.GetMappingCodeForTable(DATABASE::Contact);
        SynchronizeContactConnectionName := GraphConnectionSetup.GetSynchronizeConnectionName(DATABASE::Contact);

        LibraryGraphSync.EnableGraphSync;
        LibraryGraphSync.DisableDuplicateSearch;
        BindSubscription(GraphBackgroundSyncSubscr);

        IsInitialized := true;
    end;

    local procedure CheckContactBusinessRelation(Contact: Record Contact; LinkToTable: Option; ShouldExist: Boolean)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        Assert.AreEqual(ShouldExist, ContactBusinessRelation.FindFirst, 'Incorrect contact business relation.');
    end;

    local procedure CreateContactBusinessRelation(Contact: Record Contact; LinkToTable: Integer)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.Init;
        ContactBusinessRelation."Contact No." := Contact."No.";
        ContactBusinessRelation."Business Relation Code" := StrSubstNo('%1%2', Contact."No.", LinkToTable);
        ContactBusinessRelation."Link to Table" := LinkToTable;
        ContactBusinessRelation.Insert;
    end;

    local procedure CreateNavContactAndSync(var Contact: Record Contact)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncContactRelatedTables: Codeunit "Sync Contact Related Tables";
    begin
        BindSubscription(SyncContactRelatedTables);
        LibraryMarketing.CreatePersonContact(Contact);
        UnbindSubscription(SyncContactRelatedTables);

        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);
    end;

    local procedure CreatePersonContactWithAddress(var Contact: Record Contact)
    begin
        LibraryMarketing.CreatePersonContact(Contact);
        LibraryGraphSync.EditContactAddressDetails(Contact);
    end;

    local procedure CreateGraphContactWithBusinessAddress(var GraphContact: Record "Graph Contact")
    var
        PostCode: Record "Post Code";
        DummyContact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        LibraryERM.CreatePostCode(PostCode);
        PostCode.Validate(County, LibraryUtility.GenerateRandomText(MaxStrLen(PostCode.County)));
        PostCode.Modify(true);

        LibraryGraphSync.CreateGraphPersonContact(GraphContact, SynchronizeContactConnectionName);

        GraphContact.SetPostalAddressesString(
          GraphCollectionMgtContact.UpdateBusinessAddress(
            GraphContact.GetPostalAddressesString,
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContact.Address)), 1, MaxStrLen(DummyContact.Address)),
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContact."Address 2")), 1, MaxStrLen(DummyContact."Address 2")),
            PostCode.City, PostCode.County, PostCode."Country/Region Code", PostCode.Code));

        GraphContact.SetPhonesString(
          GraphCollectionMgtContact.UpdateBusinessPhone(
            GraphContact.GetPhonesString,
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContact."Phone No.")), 1, MaxStrLen(DummyContact."Phone No."))));

        GraphContact.SetPhonesString(
          GraphCollectionMgtContact.UpdateBusinessFaxPhone(
            GraphContact.GetPhonesString,
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContact."Fax No.")), 1, MaxStrLen(DummyContact."Fax No."))));

        GraphContact.SetPhonesString(
          GraphCollectionMgtContact.UpdateMobilePhone(
            GraphContact.GetPhonesString,
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContact."Mobile Phone No.")),
              1, MaxStrLen(DummyContact."Mobile Phone No."))));

        GraphContact.SetPhonesString(
          GraphCollectionMgtContact.UpdatePagerPhone(
            GraphContact.GetPhonesString,
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContact.Pager)), 1, MaxStrLen(DummyContact.Pager))));

        GraphContact.SetWebsitesString(
          GraphCollectionMgtContact.UpdateWorkWebsite(
            GraphContact.GetWebsitesString,
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContact."Home Page")), 1, MaxStrLen(DummyContact."Home Page"))));

        GraphContact.Modify(true);
    end;

    local procedure FindGraphContactForContact(Contact: Record Contact; var GraphContact: Record "Graph Contact")
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphID: Text[250];
    begin
        GraphIntegrationRecord.FindIDFromRecordID(Contact.RecordId, GraphID);
        GraphContact.Get(GraphID);
    end;

    local procedure ModifyAndSyncContact(var Contact: Record Contact)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        Contact.Modify(true);
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);
    end;

    local procedure SetGraphContactHomeAddress(var GraphContact: Record "Graph Contact")
    var
        PostCode: Record "Post Code";
        DummyContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        LibraryERM.CreatePostCode(PostCode);
        PostCode.Validate(County, LibraryUtility.GenerateRandomText(MaxStrLen(PostCode.County)));
        PostCode.Modify(true);

        GraphContact.SetPostalAddressesString(
          GraphCollectionMgtContact.UpdateHomeAddress(
            GraphContact.GetPostalAddressesString,
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContactAltAddress.Address)),
              1, MaxStrLen(DummyContactAltAddress.Address)),
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContactAltAddress."Address 2")),
              1, MaxStrLen(DummyContactAltAddress."Address 2")),
            PostCode.City, PostCode.County, PostCode."Country/Region Code", PostCode.Code));

        GraphContact.SetPhonesString(
          GraphCollectionMgtContact.UpdateHomePhone(
            GraphContact.GetPhonesString,
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContactAltAddress."Phone No.")),
              1, MaxStrLen(DummyContactAltAddress."Phone No."))));

        GraphContact.SetPhonesString(
          GraphCollectionMgtContact.UpdateHomeFaxPhone(
            GraphContact.GetPhonesString,
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContactAltAddress."Fax No.")),
              1, MaxStrLen(DummyContactAltAddress."Fax No."))));

        GraphContact.Modify(true);
    end;

    local procedure SetGraphContactOtherAddress(var GraphContact: Record "Graph Contact")
    var
        PostCode: Record "Post Code";
        DummyContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        LibraryERM.CreatePostCode(PostCode);
        PostCode.Validate(County, LibraryUtility.GenerateRandomText(MaxStrLen(PostCode.County)));
        PostCode.Modify(true);

        GraphContact.SetPostalAddressesString(
          GraphCollectionMgtContact.UpdateOtherAddress(
            GraphContact.GetPostalAddressesString,
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContactAltAddress.Address)),
              1, MaxStrLen(DummyContactAltAddress.Address)),
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContactAltAddress."Address 2")),
              1, MaxStrLen(DummyContactAltAddress."Address 2")),
            PostCode.City, PostCode.County, PostCode."Country/Region Code", PostCode.Code));

        GraphContact.SetPhonesString(
          GraphCollectionMgtContact.UpdateOtherPhone(
            GraphContact.GetPhonesString,
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContactAltAddress."Phone No.")),
              1, MaxStrLen(DummyContactAltAddress."Phone No."))));

        GraphContact.SetPhonesString(
          GraphCollectionMgtContact.UpdateOtherFaxPhone(
            GraphContact.GetPhonesString,
            CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummyContactAltAddress."Fax No.")),
              1, MaxStrLen(DummyContactAltAddress."Fax No."))));

        GraphContact.Modify(true);
    end;

    local procedure CreatePersonContactWithExtraDetailsUsingProfileQuestionnaire(var Contact: Record Contact)
    var
        GraphIntQuestionnaire: Codeunit "Graph Int. - Questionnaire";
        ProfileQuestionnaireCode: Code[10];
    begin
        LibraryGraphSync.CreatePersonContact(Contact);
        ProfileQuestionnaireCode := GraphIntQuestionnaire.GetGraphSyncQuestionnaireCode;

        SetPersonContactNameDetailsUsingProfileQuestionnaire(Contact."No.", ProfileQuestionnaireCode);
        SetPersonContactAnniversariesUsingProfileQuestionnaire(Contact."No.", ProfileQuestionnaireCode);
        SetPersonContactPhoneticNamesUsingProfileQuestionnaire(Contact."No.", ProfileQuestionnaireCode);
        SetPersonContactWorkDetailsUsingProfileQuestionnaire(Contact."No.", ProfileQuestionnaireCode);
    end;

    local procedure SetPersonContactNameDetailsUsingProfileQuestionnaire(ContactNo: Code[20]; ProfileQuestionnaireCode: Code[10])
    var
        GraphContact: Record "Graph Contact";
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        LibraryMarketing.CreateContactProfileAnswer(ContactNo, ProfileQuestionnaireCode,
          GetProfileQuestionnaireLineNo(GraphContact.FieldName(NickName)),
          LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.NickName)));

        LibraryMarketing.CreateContactProfileAnswer(ContactNo, ProfileQuestionnaireCode,
          GetProfileQuestionnaireLineNo(GraphContact.FieldName(Generation)),
          LibraryUtility.GenerateRandomText(LibraryRandom.RandInt(5)));
    end;

    local procedure SetPersonContactAnniversariesUsingProfileQuestionnaire(ContactNo: Code[20]; ProfileQuestionnaireCode: Code[10])
    var
        GraphContact: Record "Graph Contact";
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        LibraryMarketing.CreateContactProfileAnswer(ContactNo, ProfileQuestionnaireCode,
          GetProfileQuestionnaireLineNo(GraphContact.FieldName(Birthday)),
          Format(LibraryUtility.GenerateRandomDate(WorkDate - 100, WorkDate + 100)));

        LibraryMarketing.CreateContactProfileAnswer(ContactNo, ProfileQuestionnaireCode,
          GetProfileQuestionnaireLineNo(GraphContact.FieldName(WeddingAnniversary)),
          Format(LibraryUtility.GenerateRandomDate(WorkDate - 100, WorkDate + 100)));

        LibraryMarketing.CreateContactProfileAnswer(ContactNo, ProfileQuestionnaireCode,
          GetProfileQuestionnaireLineNo(GraphContact.FieldName(SpouseName)),
          LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.SpouseName)));
    end;

    local procedure SetPersonContactPhoneticNamesUsingProfileQuestionnaire(ContactNo: Code[20]; ProfileQuestionnaireCode: Code[10])
    var
        GraphContact: Record "Graph Contact";
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        LibraryMarketing.CreateContactProfileAnswer(ContactNo, ProfileQuestionnaireCode,
          GetProfileQuestionnaireLineNo(GraphContact.FieldName(YomiGivenName)),
          LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.YomiGivenName)));

        LibraryMarketing.CreateContactProfileAnswer(ContactNo, ProfileQuestionnaireCode,
          GetProfileQuestionnaireLineNo(GraphContact.FieldName(YomiSurname)),
          LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.YomiSurname)));
    end;

    local procedure SetPersonContactWorkDetailsUsingProfileQuestionnaire(ContactNo: Code[20]; ProfileQuestionnaireCode: Code[10])
    var
        GraphContact: Record "Graph Contact";
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        LibraryMarketing.CreateContactProfileAnswer(ContactNo, ProfileQuestionnaireCode,
          GetProfileQuestionnaireLineNo(GraphContact.FieldName(Profession)),
          LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.Profession)));

        LibraryMarketing.CreateContactProfileAnswer(ContactNo, ProfileQuestionnaireCode,
          GetProfileQuestionnaireLineNo(GraphContact.FieldName(Department)),
          LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.Department)));

        LibraryMarketing.CreateContactProfileAnswer(ContactNo, ProfileQuestionnaireCode,
          GetProfileQuestionnaireLineNo(GraphContact.FieldName(OfficeLocation)),
          LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.OfficeLocation)));

        LibraryMarketing.CreateContactProfileAnswer(ContactNo, ProfileQuestionnaireCode,
          GetProfileQuestionnaireLineNo(GraphContact.FieldName(AssistantName)),
          LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.AssistantName)));

        LibraryMarketing.CreateContactProfileAnswer(ContactNo, ProfileQuestionnaireCode,
          GetProfileQuestionnaireLineNo(GraphContact.FieldName(Manager)),
          LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.Manager)));
    end;

    local procedure CreateGraphContactWithExtraDetailsForProfileQuestionnaire(var GraphContact: Record "Graph Contact")
    begin
        LibraryGraphSync.CreateGraphPersonContact(GraphContact, SynchronizeContactConnectionName);
        LibraryGraphSync.EditGraphContactBasicDetails(GraphContact);

        SetGraphContactNameDetailsForProfileQuestionnaire(GraphContact);
        SetGraphContactAnniversariesForProfileQuestionnaire(GraphContact);
        SetGraphContactPhoneticNamesForProfileQuestionnaire(GraphContact);
        SetGraphContactWorkDetailsForProfileQuestionnaire(GraphContact);
    end;

    local procedure SetGraphContactBusinessTypes(Contact: Record Contact; SetBusinessTypes: Boolean; IsNavCreated: Boolean)
    var
        GraphContact: Record "Graph Contact";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        FindGraphContactForContact(Contact, GraphContact);
        GraphContact.SetIsBankString(GraphCollectionMgtContact.AddIsBank(SetBusinessTypes));
        GraphContact.SetIsCustomerString(GraphCollectionMgtContact.AddIsCustomer(SetBusinessTypes));
        GraphContact.SetIsVendorString(GraphCollectionMgtContact.AddIsVendor(SetBusinessTypes));
        GraphContact.SetIsNavCreatedString(GraphCollectionMgtContact.AddIsNavCreated(IsNavCreated));
        GraphContact.Modify;
    end;

    local procedure SetGraphContactNameDetailsForProfileQuestionnaire(var GraphContact: Record "Graph Contact")
    begin
        GraphContact.Validate(NickName, LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.NickName)));
        GraphContact.Validate(Generation, LibraryUtility.GenerateRandomText(LibraryRandom.RandInt(5)));
        GraphContact.Modify(true);
    end;

    local procedure SetGraphContactAnniversariesForProfileQuestionnaire(var GraphContact: Record "Graph Contact")
    begin
        GraphContact.Validate(Birthday, CreateDateTime(LibraryUtility.GenerateRandomDate(WorkDate - 100, WorkDate + 100), Time));
        GraphContact.Validate(WeddingAnniversary, CreateDateTime(LibraryUtility.GenerateRandomDate(WorkDate - 100, WorkDate + 100), Time));
        GraphContact.Validate(SpouseName, LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.SpouseName)));
        GraphContact.Modify(true);
    end;

    local procedure SetGraphContactPhoneticNamesForProfileQuestionnaire(var GraphContact: Record "Graph Contact")
    begin
        GraphContact.Validate(YomiGivenName, LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.YomiGivenName)));
        GraphContact.Validate(YomiSurname, LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.YomiSurname)));
        GraphContact.Modify(true);
    end;

    local procedure SetGraphContactWorkDetailsForProfileQuestionnaire(var GraphContact: Record "Graph Contact")
    begin
        GraphContact.Validate(Profession, LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.Profession)));
        GraphContact.Validate(Department, LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.Department)));
        GraphContact.Validate(OfficeLocation, LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.OfficeLocation)));
        GraphContact.Validate(AssistantName, LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.AssistantName)));
        GraphContact.Validate(Manager, LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.Manager)));
        GraphContact.Modify(true);
    end;

    local procedure GetProfileQuestionnaireLineNo(InputDescription: Text): Integer
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        GraphIntQuestionnaire: Codeunit "Graph Int. - Questionnaire";
    begin
        with ProfileQuestionnaireLine do begin
            SetRange("Profile Questionnaire Code", GraphIntQuestionnaire.GetGraphSyncQuestionnaireCode);
            SetRange(Type, Type::Answer);
            SetRange(Description, CopyStr(InputDescription, 1, MaxStrLen(Description)));
            FindFirst;
            exit("Line No.");
        end;
    end;

    local procedure UpdatePersonContactPhoneticNames(Contact: Record Contact)
    var
        ContactProfileAnswer: Record "Contact Profile Answer";
        GraphContact: Record "Graph Contact";
        GraphIntQuestionnaire: Codeunit "Graph Int. - Questionnaire";
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);

        ContactProfileAnswer.Get(Contact."No.", GraphIntQuestionnaire.GetGraphSyncQuestionnaireCode,
          GetProfileQuestionnaireLineNo(GraphContact.FieldName(YomiGivenName)));
        ContactProfileAnswer.Validate("Profile Questionnaire Value",
          LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.YomiGivenName)));
        ContactProfileAnswer.Modify(true);

        ContactProfileAnswer.Get(Contact."No.", GraphIntQuestionnaire.GetGraphSyncQuestionnaireCode,
          GetProfileQuestionnaireLineNo(GraphContact.FieldName(YomiSurname)));
        ContactProfileAnswer.Validate("Profile Questionnaire Value",
          LibraryUtility.GenerateRandomText(MaxStrLen(GraphContact.YomiSurname)));
        ContactProfileAnswer.Modify(true);
    end;

    local procedure UpdateGraphContactDeltaTokenAndChangeKey(var GraphContact: Record "Graph Contact")
    begin
        GraphContact.Validate(DeltaToken, LibraryGraphSync.GenerateRandomDeltaToken);
        GraphContact.Validate(ChangeKey, LibraryGraphSync.GenerateRandomDeltaToken);
        GraphContact.Modify(true);
    end;

    local procedure UpdateContactSlowlyOccurringAtDifferentTimestamp(ContactRecordID: RecordID)
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeContactConnectionName, true);
        LibraryGraphSync.FindGraphIntegrationRecordForContact(GraphIntegrationRecord, ContactRecordID);
        LibraryGraphSync.SetDifferentIntegrationTimestampForContact(GraphIntegrationRecord, ContactRecordID);
    end;

    local procedure HasHomeAddress(GraphContact: Record "Graph Contact"): Boolean
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        exit(GraphCollectionMgtContact.HasHomeAddressOrPhone(
            GraphContact.GetPostalAddressesString, GraphContact.GetPhonesString, GraphContact.GetWebsitesString));
    end;

    local procedure HasOtherAddress(GraphContact: Record "Graph Contact"): Boolean
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        exit(GraphCollectionMgtContact.HasOtherAddressOrPhone(
            GraphContact.GetPostalAddressesString, GraphContact.GetPhonesString, GraphContact.GetWebsitesString));
    end;

    local procedure VerifyGraphBusinessTypes(Contact: Record Contact; ExpectedValue: Boolean)
    var
        GraphContact: Record "Graph Contact";
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        GraphID: Text[250];
        GraphIsBank: Boolean;
        GraphIsCustomer: Boolean;
        GraphIsVendor: Boolean;
    begin
        GraphIntegrationRecord.FindIDFromRecordID(Contact.RecordId, GraphID);
        GraphContact.Get(GraphID);
        GraphIsBank := GraphCollectionMgtContact.GetIsBank(GraphContact.GetIsBankString);
        GraphIsCustomer := GraphCollectionMgtContact.GetIsCustomer(GraphContact.GetIsCustomerString);
        GraphIsVendor := GraphCollectionMgtContact.GetIsVendor(GraphContact.GetIsVendorString);

        Assert.AreEqual(ExpectedValue, GraphIsBank, 'IsBank is not set correctly.');
        Assert.AreEqual(ExpectedValue, GraphIsCustomer, 'IsCustomer is not set correctly.');
        Assert.AreEqual(ExpectedValue, GraphIsVendor, 'IsVendor is not set correctly.');
    end;

    local procedure VerifyMultipleAddressesAreSyncedToGraph(GraphContact: Record "Graph Contact"; Contact: Record Contact)
    begin
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact);
        AssertPersonContactAddressEqualsGraphContactBusinessAddress(GraphContact, Contact);
        AssertPersonContactAlternateHomeAddressEqualsGraphContactHomeAddress(GraphContact, Contact);
    end;

    local procedure VerifyMultipleAddressesAreSyncedFromGraph(GraphContact: Record "Graph Contact"; Contact: Record Contact)
    begin
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact);
        AssertPersonContactAddressEqualsGraphContactBusinessAddress(GraphContact, Contact);
        AssertPersonContactAlternateOtherAddressEqualsGraphContactOtherAddress(GraphContact, Contact);
    end;

    local procedure VerifyRelatedRecordsOnContact(Contact: Record Contact; RecordsExist: Boolean)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        CheckContactBusinessRelation(Contact, ContactBusinessRelation."Link to Table"::"Bank Account", RecordsExist);
        CheckContactBusinessRelation(Contact, ContactBusinessRelation."Link to Table"::Customer, RecordsExist);
        CheckContactBusinessRelation(Contact, ContactBusinessRelation."Link to Table"::Vendor, RecordsExist);
    end;

    local procedure AssertPersonContactDetailsEqualGraphContactDetails(var GraphContact: Record "Graph Contact"; Contact: Record Contact)
    begin
        // DisplayName is set in Exchange by combining Title, GivenName, MiddleName, Surname and Generation. In test mode it is not set.
        Contact.TestField("First Name", CopyStr(GraphContact.GivenName, 1, MaxStrLen(Contact."First Name")));
        Contact.TestField("Middle Name", CopyStr(GraphContact.MiddleName, 1, MaxStrLen(Contact."Middle Name")));
        Contact.TestField(Surname, CopyStr(GraphContact.Surname, 1, MaxStrLen(Contact.Surname)));
    end;

    local procedure AssertPersonContactExtraDetailsOnQuestionnaireEqualGraphContactExtraDetails(GraphContact: Record "Graph Contact"; Contact: Record Contact)
    begin
        AssertPersonContactNameDetailsOnQuestionnaireEqualGraphContactExtraDetails(GraphContact, Contact);
        AssertPersonContactAnniversariesOnQuestionnaireEqualGraphContactExtraDetails(GraphContact, Contact);
        AssertPersonContactPhoneticNamesOnQuestionnaireEqualGraphContactExtraDetails(GraphContact, Contact);
        AssertPersonContactWorkDetailsOnQuestionnaireEqualGraphContactExtraDetails(GraphContact, Contact);
    end;

    local procedure AssertPersonContactNameDetailsOnQuestionnaireEqualGraphContactExtraDetails(GraphContact: Record "Graph Contact"; Contact: Record Contact)
    begin
        GraphContact.TestField(NickName,
          LibraryGraphSync.FindProfileQuestionnaireValueForContact(Contact."No.", GraphContact.FieldName(NickName)));
        GraphContact.TestField(Generation,
          LibraryGraphSync.FindProfileQuestionnaireValueForContact(Contact."No.", GraphContact.FieldName(Generation)));
    end;

    local procedure AssertPersonContactAnniversariesOnQuestionnaireEqualGraphContactExtraDetails(GraphContact: Record "Graph Contact"; Contact: Record Contact)
    var
        BirthdayDate: Date;
        WeddingAnniversaryDate: Date;
    begin
        Evaluate(BirthdayDate,
          LibraryGraphSync.FindProfileQuestionnaireValueForContact(Contact."No.", GraphContact.FieldName(Birthday)));
        Assert.AreEqual(BirthdayDate, DT2Date(GraphContact.Birthday), 'Wrong birthday date.');

        Evaluate(WeddingAnniversaryDate,
          LibraryGraphSync.FindProfileQuestionnaireValueForContact(Contact."No.", GraphContact.FieldName(WeddingAnniversary)));
        Assert.AreEqual(WeddingAnniversaryDate, DT2Date(GraphContact.WeddingAnniversary), 'Wrong weddding anniversary date.');

        GraphContact.TestField(SpouseName,
          LibraryGraphSync.FindProfileQuestionnaireValueForContact(Contact."No.", GraphContact.FieldName(SpouseName)));
    end;

    local procedure AssertPersonContactPhoneticNamesOnQuestionnaireEqualGraphContactExtraDetails(GraphContact: Record "Graph Contact"; Contact: Record Contact)
    begin
        GraphContact.TestField(YomiGivenName,
          LibraryGraphSync.FindProfileQuestionnaireValueForContact(Contact."No.", GraphContact.FieldName(YomiGivenName)));
        GraphContact.TestField(YomiSurname,
          LibraryGraphSync.FindProfileQuestionnaireValueForContact(Contact."No.", GraphContact.FieldName(YomiSurname)));
    end;

    local procedure AssertPersonContactWorkDetailsOnQuestionnaireEqualGraphContactExtraDetails(GraphContact: Record "Graph Contact"; Contact: Record Contact)
    begin
        GraphContact.TestField(Profession,
          LibraryGraphSync.FindProfileQuestionnaireValueForContact(Contact."No.", GraphContact.FieldName(Profession)));
        GraphContact.TestField(Department,
          LibraryGraphSync.FindProfileQuestionnaireValueForContact(Contact."No.", GraphContact.FieldName(Department)));
        GraphContact.TestField(OfficeLocation,
          LibraryGraphSync.FindProfileQuestionnaireValueForContact(Contact."No.", GraphContact.FieldName(OfficeLocation)));
        GraphContact.TestField(AssistantName,
          LibraryGraphSync.FindProfileQuestionnaireValueForContact(Contact."No.", GraphContact.FieldName(AssistantName)));
        GraphContact.TestField(Manager,
          LibraryGraphSync.FindProfileQuestionnaireValueForContact(Contact."No.", GraphContact.FieldName(Manager)));
    end;

    local procedure AssertPersonContactAddressEqualsGraphContactBusinessAddress(GraphContact: Record "Graph Contact"; Contact: Record Contact)
    var
        DummyContact: Record Contact;
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        GraphCollectionMgtContact.GetBusinessAddress(GraphContact.GetPostalAddressesString, DummyContact.Address, DummyContact."Address 2",
          DummyContact.City, DummyContact.County, DummyContact."Country/Region Code", DummyContact."Post Code");
        GraphCollectionMgtContact.GetBusinessPhone(GraphContact.GetPhonesString, DummyContact."Phone No.");
        GraphCollectionMgtContact.GetBusinessFaxPhone(GraphContact.GetPhonesString, DummyContact."Fax No.");
        GraphCollectionMgtContact.GetMobilePhone(GraphContact.GetPhonesString, DummyContact."Mobile Phone No.");
        GraphCollectionMgtContact.GetPagerPhone(GraphContact.GetPhonesString, DummyContact.Pager);
        GraphCollectionMgtContact.GetWorkWebsite(GraphContact.GetWebsitesString, DummyContact."Home Page");

        AssertContactAddressesAreEqual(Contact, DummyContact);
        AssertContactCommunicationDetailsAreEqual(Contact, DummyContact);
    end;

    local procedure AssertPersonContactAlternateHomeAddressEqualsGraphContactHomeAddress(GraphContact: Record "Graph Contact"; Contact: Record Contact)
    var
        ContactAltAddress: Record "Contact Alt. Address";
        DummyContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        GraphIntContactAddresses: Codeunit "Graph Int. - Contact Addresses";
    begin
        GraphCollectionMgtContact.GetHomeAddress(
          GraphContact.GetPostalAddressesString, DummyContactAltAddress.Address, DummyContactAltAddress."Address 2",
          DummyContactAltAddress.City, DummyContactAltAddress.County, DummyContactAltAddress."Country/Region Code",
          DummyContactAltAddress."Post Code");
        GraphCollectionMgtContact.GetHomePhone(GraphContact.GetPhonesString, DummyContactAltAddress."Phone No.");
        GraphCollectionMgtContact.GetHomeFaxPhone(GraphContact.GetPhonesString, DummyContactAltAddress."Fax No.");

        ContactAltAddress.Get(Contact."No.", GraphIntContactAddresses.GetContactAlternativeHomeAddressCode);
        AssertContactAlternativeAddressesAreEqual(ContactAltAddress, DummyContactAltAddress);
        AssertContactAlternativeCommunicationDetailsAreEqual(ContactAltAddress, DummyContactAltAddress);
    end;

    local procedure AssertPersonContactAlternateOtherAddressEqualsGraphContactOtherAddress(GraphContact: Record "Graph Contact"; Contact: Record Contact)
    var
        ContactAltAddress: Record "Contact Alt. Address";
        DummyContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        GraphIntContactAddresses: Codeunit "Graph Int. - Contact Addresses";
    begin
        GraphCollectionMgtContact.GetOtherAddress(
          GraphContact.GetPostalAddressesString, DummyContactAltAddress.Address, DummyContactAltAddress."Address 2",
          DummyContactAltAddress.City, DummyContactAltAddress.County, DummyContactAltAddress."Country/Region Code",
          DummyContactAltAddress."Post Code");
        GraphCollectionMgtContact.GetOtherPhone(GraphContact.GetPhonesString, DummyContactAltAddress."Phone No.");
        GraphCollectionMgtContact.GetOtherFaxPhone(GraphContact.GetPhonesString, DummyContactAltAddress."Fax No.");

        ContactAltAddress.Get(Contact."No.", GraphIntContactAddresses.GetContactAlternativeOtherAddressCode);
        AssertContactAlternativeAddressesAreEqual(ContactAltAddress, DummyContactAltAddress);
        AssertContactAlternativeCommunicationDetailsAreEqual(ContactAltAddress, DummyContactAltAddress);
    end;

    local procedure AssertContactAddressesAreEqual(Contact: Record Contact; Contact2: Record Contact)
    begin
        Contact.TestField(Address);
        Contact.TestField("Address 2");
        Contact.TestField(City);
        Contact.TestField(County);
        Contact.TestField("Country/Region Code");
        Contact.TestField("Post Code");

        Contact2.TestField(Address, Contact.Address);
        Contact2.TestField("Address 2", Contact."Address 2");
        Contact2.TestField(City, Contact.City);
        Contact2.TestField(County, Contact.County);
        Contact2.TestField("Country/Region Code", Contact."Country/Region Code");
        Contact2.TestField("Post Code", Contact."Post Code");
    end;

    local procedure AssertContactCommunicationDetailsAreEqual(Contact: Record Contact; Contact2: Record Contact)
    begin
        Contact.TestField("Phone No.");
        Contact.TestField("Fax No.");
        Contact.TestField("Mobile Phone No.");
        Contact.TestField(Pager);
        // Contact.TESTFIELD("Home Page");

        Contact2.TestField("Phone No.", Contact."Phone No.");
        Contact2.TestField("Fax No.", Contact."Fax No.");
        Contact2.TestField("Mobile Phone No.", Contact."Mobile Phone No.");
        Contact2.TestField(Pager, Contact.Pager);
        // Contact2.TESTFIELD("Home Page",Contact."Home Page");
        asserterror Error('');
        Assert.KnownFailure('', 194567);
    end;

    local procedure AssertContactAlternativeAddressesAreEqual(ContactAltAddress: Record "Contact Alt. Address"; ContactAltAddress2: Record "Contact Alt. Address")
    begin
        ContactAltAddress.TestField(Address);
        ContactAltAddress.TestField("Address 2");
        ContactAltAddress.TestField(City);
        ContactAltAddress.TestField(County);
        ContactAltAddress.TestField("Country/Region Code");
        ContactAltAddress.TestField("Post Code");

        ContactAltAddress2.TestField(Address, ContactAltAddress.Address);
        ContactAltAddress2.TestField("Address 2", ContactAltAddress."Address 2");
        ContactAltAddress2.TestField(City, ContactAltAddress.City);
        ContactAltAddress2.TestField(County, ContactAltAddress.County);
        ContactAltAddress2.TestField("Country/Region Code", ContactAltAddress."Country/Region Code");
        ContactAltAddress2.TestField("Post Code", ContactAltAddress."Post Code");
    end;

    local procedure AssertContactAlternativeCommunicationDetailsAreEqual(ContactAltAddress: Record "Contact Alt. Address"; ContactAltAddress2: Record "Contact Alt. Address")
    begin
        ContactAltAddress.TestField("Phone No.");
        ContactAltAddress.TestField("Fax No.");

        ContactAltAddress2.TestField("Phone No.", ContactAltAddress."Phone No.");
        ContactAltAddress2.TestField("Fax No.", ContactAltAddress."Fax No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, 5451, 'OnBeforeSynchronizationStart', '', false, false)]
    [Scope('OnPrem')]
    procedure SkipRecordSyncingOnBeforeSyncHandler(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
        IgnoreRecord := true;
    end;

    local procedure CreatePersonContactComment(var RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line"; ContactNo: Code[20])
    var
        LibraryMarketing: Codeunit "Library - Marketing";
    begin
        LibraryMarketing.CreateRlshpMgtCommentContact(RlshpMgtCommentLine, ContactNo);
        ModifyPersonContactComment(RlshpMgtCommentLine);
    end;

    local procedure ModifyPersonContactComment(var RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line")
    var
        CommentLength: Integer;
        Comment: Text[80];
    begin
        CommentLength := MaxStrLen(RlshpMgtCommentLine.Comment);
        Comment := CopyStr(LibraryUtility.GenerateRandomText(CommentLength), 1, CommentLength);
        RlshpMgtCommentLine.Validate(Comment, Comment);
        RlshpMgtCommentLine.Modify(true);
    end;
}

