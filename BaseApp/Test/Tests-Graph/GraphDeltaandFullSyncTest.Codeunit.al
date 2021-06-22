codeunit 134624 "Graph Delta and Full Sync Test"
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
        IsInitialized: Boolean;
        SyncContactConnectionName: Text;
        ContactMappingCode: Code[20];
        SyncBizProfileConnectionName: Text;
        BizProfileMappingCode: Code[20];
        BusinessTypeTxt: Label 'Business';
        ShippingTypeTxt: Label 'Shipping';

    [Test]
    [Scope('OnPrem')]
    procedure FullSyncNewContactToGraph()
    var
        Contact1: Record Contact;
        Contact2: Record Contact;
        Contact3: Record Contact;
        GraphContact: Record "Graph Contact";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
        GraphDeltaAndFullSyncTest: Codeunit "Graph Delta and Full Sync Test";
    begin
        // FullSync creates new Nav Contacts in the graph
        // GIVEN Few new Nav Contacts
        // WHEN  Full Sync is run
        // THEN  The Nav contacts are synced to the graph table

        // Setup
        Initialize;
        BindSubscription(GraphDeltaAndFullSyncTest);
        CreatePersonContactWithNameDetails(Contact1);
        CreatePersonContactWithNameDetails(Contact2);
        CreatePersonContactWithNameDetails(Contact3);
        UnbindSubscription(GraphDeltaAndFullSyncTest);
        LibraryGraphSync.DeleteAllLogRecords;

        // Exercise
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::Contact);

        // Verify Graph Contacts
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncContactConnectionName, true);
        Assert.RecordCount(GraphContact, 3);
        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact1);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact1);

        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact2);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact2);

        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact3);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullSyncNewContactFromGraph()
    var
        Contact: Record Contact;
        GraphContact1: Record "Graph Contact";
        GraphContact2: Record "Graph Contact";
        GraphContact3: Record "Graph Contact";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
        GraphDeltaAndFullSyncTest: Codeunit "Graph Delta and Full Sync Test";
    begin
        // FullSync creates new Graph Contacts in Nav
        // GIVEN Few new Graph Contacts
        // WHEN  Full Sync is run
        // THEN  The Graph contacts are synced to Nav

        // Setup
        Initialize;
        BindSubscription(GraphDeltaAndFullSyncTest);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact1, SyncContactConnectionName);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact2, SyncContactConnectionName);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact3, SyncContactConnectionName);
        UnbindSubscription(GraphDeltaAndFullSyncTest);
        LibraryGraphSync.DeleteAllLogRecords;

        // Exercise
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::Contact);

        // Verify
        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact1);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact1, Contact);

        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact2);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact2, Contact);

        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact3);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact3, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullSyncNewGraphAndNavContacts()
    var
        Contact: Record Contact;
        Contact1: Record Contact;
        Contact2: Record Contact;
        GraphContact: Record "Graph Contact";
        GraphContact1: Record "Graph Contact";
        GraphContact2: Record "Graph Contact";
        GraphContact3: Record "Graph Contact";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
        GraphDeltaAndFullSyncTest: Codeunit "Graph Delta and Full Sync Test";
    begin
        // FullSync creates new Graph Contacts in Nav and new Nav Contacts in Graph
        // GIVEN Few new Graph Contacts and Nav Contacts
        // WHEN  Full Sync is run
        // THEN  The Graph contacts are synced to Nav and Nav contacts are synced to Graph

        // Setup
        Initialize;
        BindSubscription(GraphDeltaAndFullSyncTest);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact1, SyncContactConnectionName);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact2, SyncContactConnectionName);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact3, SyncContactConnectionName);
        LibraryMarketing.CreatePersonContact(Contact1);
        LibraryMarketing.CreatePersonContact(Contact2);
        UnbindSubscription(GraphDeltaAndFullSyncTest);
        LibraryGraphSync.DeleteAllLogRecords;

        // Exercise
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::Contact);

        // Verify
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncContactConnectionName, true);
        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact1);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact1);

        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact2);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact2);

        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact1);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact1, Contact);

        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact2);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact2, Contact);

        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact3);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact3, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullSyncEditGraphAndNavContacts()
    var
        Contact: Record Contact;
        Contact1: Record Contact;
        Contact2: Record Contact;
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphContact: Record "Graph Contact";
        GraphContact1: Record "Graph Contact";
        GraphContact2: Record "Graph Contact";
        GraphContact3: Record "Graph Contact";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
        GraphDeltaAndFullSyncTest: Codeunit "Graph Delta and Full Sync Test";
    begin
        // FullSync with edited non conflicting records on both Nav and Graph syncs successfully
        // GIVEN Few Graph Contacts and few Nav contacts
        // GIVEN Edit a Graph Contact and a Nav Contact which are not the same
        // WHEN  Full Sync is run
        // THEN  The edited Graph contact is synced to Nav and edited Nav contact synced to Graph

        // Setup
        Initialize;
        BindSubscription(GraphDeltaAndFullSyncTest);
        LibraryMarketing.CreatePersonContact(Contact1);
        LibraryMarketing.CreatePersonContact(Contact2);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact1, SyncContactConnectionName);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact2, SyncContactConnectionName);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact3, SyncContactConnectionName);
        UnbindSubscription(GraphDeltaAndFullSyncTest);
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::Contact);
        LibraryGraphSync.FindGraphIntegrationRecordForContact(GraphIntegrationRecord, Contact1.RecordId);

        UpdateContactSlowlyOccurringAtDifferentTimestamp(Contact1, GraphIntegrationRecord);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncContactConnectionName, true);
        LibraryGraphSync.EditGraphContactBasicDetails(GraphContact1);
        LibraryGraphSync.DeleteAllLogRecords;

        // Exercise
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::Contact);

        // Verify
        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact1);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact1, Contact);

        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact1);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullSyncEditGraphAndNavContactsWithConflicts()
    var
        Contact1: Record Contact;
        Contact2: Record Contact;
        GraphContact: Record "Graph Contact";
        GraphContact1: Record "Graph Contact";
        GraphContact2: Record "Graph Contact";
        GraphContact3: Record "Graph Contact";
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        // FullSync with edited conflicting records causes the Graph changes to override the Nav changes
        // GIVEN Few Graph Contacts and few Nav contacts
        // GIVEN Edit a Graph Contact and the corresponding Nav Contact
        // WHEN  Full Sync is run
        // THEN  The sync from Nav to Graph is skipped and sync from Graph ro Nav is done

        // Setup
        Initialize;
        LibraryMarketing.CreatePersonContact(Contact1);
        LibraryMarketing.CreatePersonContact(Contact2);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact1, SyncContactConnectionName);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact2, SyncContactConnectionName);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact3, SyncContactConnectionName);
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::Contact);
        LibraryGraphSync.FindGraphIntegrationRecordForContact(GraphIntegrationRecord, Contact1.RecordId);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncContactConnectionName, true);
        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact1);
        UpdateContactSlowlyOccurringAtDifferentTimestamp(Contact1, GraphIntegrationRecord);
        LibraryGraphSync.FindGraphIntegrationRecordForGraphContact(GraphIntegrationRecord, GraphContact.Id);
        UpdateGraphContactSlowlyOccurringAtDifferentTimestamp(GraphContact, GraphIntegrationRecord);
        LibraryGraphSync.DeleteAllLogRecords;

        // Exercise
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::Contact);

        // Verify
        Contact1.Find;
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullSyncEditGraphAndNavBusinessProfileWithConflicts()
    var
        CompanyInformation: Record "Company Information";
        GraphBusinessProfile: Record "Graph Business Profile";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
        NewName: Code[10];
    begin
        // [SCENARIO 123456] Performing a full sync with conflicting records causes the Graph changes to override the NAV changes.
        Initialize;

        // [GIVEN] Company information table and Graph Business Profile records exist and are synchronized.
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, BizProfileMappingCode);
        LibraryGraphSync.CreateGraphBusinessProfile(GraphBusinessProfile, SyncBizProfileConnectionName);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // [GIVEN] Company Information and Business Profile both have Name field changed.
        CompanyInformation.Get;
        CompanyInformation.Validate(Name, LibraryUtility.GenerateGUID);
        CompanyInformation.Modify;

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncBizProfileConnectionName, true);
        NewName := LibraryUtility.GenerateGUID;
        GraphBusinessProfile.Validate(Name, NewName);
        GraphBusinessProfile.Validate(ETag, CreateGuid);
        GraphBusinessProfile.Modify;

        // [WHEN] Full sync is run for business profile.
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::"Company Information");

        // [THEN] The GraphBusinessProfile change prevails.
        CompanyInformation.Get;
        CompanyInformation.TestField(Name, NewName);
        LibraryGraphSync.AssertNoSynchErrors;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullSyncEditGraphBusinessProfile()
    var
        CompanyInformation: Record "Company Information";
        GraphBusinessProfile: Record "Graph Business Profile";
        IntegrationTableMapping: Record "Integration Table Mapping";
        O365SocialNetwork: Record "O365 Social Network";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
        PictureStream: InStream;
        Address: Text;
        Address2: Text;
        City: Text;
        CountryRegionCode: Code[10];
        PostCode: Code[10];
        Email: Text;
        Phone: Text;
        Website: Text;
        ExpectedPicture: Text;
        ActualPicture: Text;
    begin
        // [SCENARIO 123456] Performing a full sync with only Graph changes transfers data to NAV.
        Initialize;

        // [GIVEN] Company information table and Graph Business Profile records exist.
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, BizProfileMappingCode);
        LibraryGraphSync.CreateGraphBusinessProfile(GraphBusinessProfile, SyncBizProfileConnectionName);

        Sleep(1000);

        // [GIVEN] Graph Business Profile has its fields changed.
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncBizProfileConnectionName, true);
        GraphBusinessProfile.FindFirst;
        GraphBusinessProfile.Name := LibraryUtility.GenerateGUID;
        GraphBusinessProfile.Industry := LibraryUtility.GenerateGUID;
        GraphBusinessProfile.BrandColor := '#EF12A000';
        GraphBusinessProfile.CountryCode := 'DE';
        SetBusinessProfileLogo(GraphBusinessProfile, ExpectedPicture);
        Address := LibraryUtility.GenerateGUID;
        Address2 := LibraryUtility.GenerateGUID;
        City := LibraryUtility.GenerateGUID;
        PostCode := LibraryUtility.GenerateGUID;
        CountryRegionCode := LibraryUtility.GenerateGUID;
        Email := StrSubstNo('%1@example.com', LibraryUtility.GenerateGUID);
        Phone := LibraryUtility.GenerateGUID;
        Website := LibraryUtility.GenerateGUID;

        GraphBusinessProfile.SetAddressesString('[' +
          '        {' +
          '          "city": "' + City + '",' +
          '          "countryOrRegion": "US",' +
          '          "postalCode": "' + PostCode + '",' +
          '          "street": "' + StrSubstNo('%1\r\n%2', Address, Address2) + '",' +
          '          "countryOrRegion": "' + CountryRegionCode + '",' +
          '          "type": "Business"' +
          '        },' +
          '        {' +
          '          "city": "' + City + '",' +
          '          "countryOrRegion": "US",' +
          '          "postalCode": "' + PostCode + '",' +
          '          "street": "' + StrSubstNo('%1\r\n%2', Address, Address2) + '",' +
          '          "countryOrRegion": "' + CountryRegionCode + '",' +
          '          "type": "Shipping"' +
          '        }' +
          '      ]');

        GraphBusinessProfile.SetSocialLinksString('[{ "address" : "http://facebook.com", "displayName":"Facebook" }]');
        GraphBusinessProfile.SetEmailAddressesString('[{ "type": "Business", "address" : "' + Email + '" }]');
        GraphBusinessProfile.SetPhoneNumbersString('[{ "type":"Business","number" : "' + Phone + '" }]');
        GraphBusinessProfile.SetWebsitesString('{ "address" : "' + Website + '" }');
        GraphBusinessProfile.LastModifiedDate := CurrentDateTime;
        GraphBusinessProfile.ETag := CreateGuid;
        GraphBusinessProfile.Modify;

        // [WHEN] Full sync is run for business profile.
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::"Company Information");
        LibraryGraphSync.AssertNoSynchErrors;

        // [THEN] The NAV Company Information is updated to reflect the Graph changes.
        CompanyInformation.Get;
        CompanyInformation.TestField(Name, GraphBusinessProfile.Name);
        CompanyInformation.TestField("Industrial Classification", GraphBusinessProfile.Industry);
        CompanyInformation.TestField("Brand Color Value", '#21A610');
        CompanyInformation.TestField(Address, Address);
        CompanyInformation.TestField("Ship-to Address", Address);
        CompanyInformation.TestField("Address 2", Address2);
        CompanyInformation.TestField("Ship-to Address 2", Address2);
        CompanyInformation.TestField(City, City);
        CompanyInformation.TestField("Ship-to City", City);
        CompanyInformation.TestField("Post Code", PostCode);
        CompanyInformation.TestField("Ship-to Post Code", PostCode);
        CompanyInformation.TestField("E-Mail", Email);
        CompanyInformation.TestField("Phone No.", Phone);
        CompanyInformation.TestField("Home Page", Website);
        CompanyInformation.TestField("Country/Region Code", 'DE');
        with CompanyInformation do
            Assert.IsTrue("Last Modified Date Time" - "Picture - Last Mod. Date Time" < 1000,
              'Picture last modified date time should be set.');
        CompanyInformation.CalcFields(Picture);
        CompanyInformation.Picture.CreateInStream(PictureStream);
        PictureStream.Read(ActualPicture);
        Assert.AreEqual(ExpectedPicture, ActualPicture, 'Picture did not get set properly.');

        O365SocialNetwork.Get('FACEBOOK');
        O365SocialNetwork.TestField(URL, 'http://facebook.com');
        O365SocialNetwork.TestField(Name, 'Facebook');

        VerifyCompanyBusinessProfileId(GraphBusinessProfile.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullSyncEditNavCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        GraphBusinessProfile: Record "Graph Business Profile";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        InStream: InStream;
        OutStream: OutStream;
        Address: Text[50];
        Address2: Text[50];
        City: Text[30];
        County: Text[30];
        CountryRegionCode: Code[10];
        PostCode: Code[10];
        Email: Text;
        Phone: Text;
        Website: Text;
        ExpectedPicture: Text;
        ActualPicture: Text;
    begin
        // [SCENARIO 123456] Performing a full sync with only NAV changes transfers data to Graph.
        Initialize;

        // [GIVEN] Company information table and Graph Business Profile records exist and are synchronized.
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, BizProfileMappingCode);
        LibraryGraphSync.CreateGraphBusinessProfile(GraphBusinessProfile, SyncBizProfileConnectionName);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // [GIVEN] Company Information has Name field changed.
        CompanyInformation.Get;
        CompanyInformation.Validate(Name, LibraryUtility.GenerateGUID);
        CompanyInformation."E-Mail" := StrSubstNo('%1@abc.com', LibraryUtility.GenerateGUID);
        CompanyInformation.Address := LibraryUtility.GenerateGUID;
        CompanyInformation."Address 2" := LibraryUtility.GenerateGUID;
        CompanyInformation.City := LibraryUtility.GenerateGUID;
        CompanyInformation."Ship-to Address" := LibraryUtility.GenerateGUID;
        CompanyInformation."Ship-to City" := LibraryUtility.GenerateGUID;
        CompanyInformation."Industrial Classification" := LibraryUtility.GenerateGUID;
        CompanyInformation."Brand Color Value" := '#00FFDD00';
        CompanyInformation."Home Page" := LibraryUtility.GenerateGUID;
        CompanyInformation."Phone No." := LibraryUtility.GenerateGUID;
        CompanyInformation.Picture.CreateOutStream(OutStream);
        ExpectedPicture := CreateGuid;
        OutStream.WriteText(ExpectedPicture);
        CompanyInformation.Validate(Picture); // update picture last datetime
        CompanyInformation.Modify(true);

        // [WHEN] Full sync is run for business profile.
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::"Company Information");
        LibraryGraphSync.AssertNoSynchErrors;

        // [THEN] The GraphBusinessProfile is updated to reflect the company information changes.
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncBizProfileConnectionName, true);
        GraphBusinessProfile.FindFirst;
        GraphBusinessProfile.TestField(Name, CompanyInformation.Name);
        GraphBusinessProfile.TestField(Industry, CompanyInformation."Industrial Classification");
        GraphBusinessProfile.TestField(BrandColor, CompanyInformation."Brand Color Value");

        // Business address
        GraphMgtCompanyInfo.GetPostalAddress(GraphBusinessProfile.GetAddressesString, BusinessTypeTxt, Address, Address2,
          City, County, CountryRegionCode, PostCode);
        CompanyInformation.TestField(Address, Address);
        CompanyInformation.TestField("Address 2", Address2);
        CompanyInformation.TestField(City, City);

        // Shipping address
        GraphMgtCompanyInfo.GetPostalAddress(GraphBusinessProfile.GetAddressesString, ShippingTypeTxt, Address, Address2,
          City, County, CountryRegionCode, PostCode);
        CompanyInformation.TestField("Ship-to Address", Address);
        CompanyInformation.TestField("Ship-to Address 2", Address2);
        CompanyInformation.TestField("Ship-to City", City);

        GraphMgtCompanyInfo.GetEmailAddress(GraphBusinessProfile.GetEmailAddressesString, BusinessTypeTxt, Email);
        CompanyInformation.TestField("E-Mail", Email);

        GraphMgtCompanyInfo.GetWebsite(GraphBusinessProfile.GetWebsiteString, Website);
        CompanyInformation.TestField("Home Page", Website);

        GraphMgtCompanyInfo.GetPhone(GraphBusinessProfile.GetPhoneNumbersString, BusinessTypeTxt, Phone);
        CompanyInformation.TestField("Phone No.", Phone);

        GraphBusinessProfile.CalcFields(LogoContent);
        GraphBusinessProfile.LogoContent.CreateInStream(InStream);
        InStream.ReadText(ActualPicture);
        Assert.AreEqual(ExpectedPicture, ActualPicture, 'Logo did not get set.');

        VerifyCompanyBusinessProfileId(GraphBusinessProfile.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncRecoversAfterDeleteBusinessProfile()
    var
        CompanyInformation: Record "Company Information";
        GraphBusinessProfile: Record "Graph Business Profile";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        // [SCENARIO 213296] After deleting the graph business profile, a full sync recreates it with the NAV data.
        Initialize;

        // [GIVEN] Company information table and Graph Business Profile records exist and are synchronized.
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, BizProfileMappingCode);
        LibraryGraphSync.CreateGraphBusinessProfile(GraphBusinessProfile, SyncBizProfileConnectionName);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // [GIVEN] Graph business profile has been deleted.
        GraphBusinessProfile.Delete(true);

        // [GIVEN] Company Information has Name field changed.
        CompanyInformation.Get;
        CompanyInformation.Validate(Name, LibraryUtility.GenerateGUID);
        CompanyInformation.Modify(true);

        // [WHEN] Full sync is run for business profile.
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::"Company Information");
        LibraryGraphSync.AssertNoSynchErrors;

        // [THEN] The sync process creates a new business profile.
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncBizProfileConnectionName, true);
        GraphBusinessProfile.FindFirst;
        GraphBusinessProfile.TestField(Name, CompanyInformation.Name);

        VerifyCompanyBusinessProfileId(GraphBusinessProfile.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncRecoversAfterRenameBusinessProfile()
    var
        CompanyInformation: Record "Company Information";
        GraphBusinessProfile: Record "Graph Business Profile";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        // [SCENARIO 213296] After the graph business profile is renamed, the sync can relink the graph integration record and continue.
        Initialize;

        // [GIVEN] Company information table and Graph Business Profile records exist and are synchronized.
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, BizProfileMappingCode);
        LibraryGraphSync.CreateGraphBusinessProfile(GraphBusinessProfile, SyncBizProfileConnectionName);
        LibraryGraphSync.SyncRecords(IntegrationTableMapping);

        // [GIVEN] Graph Business Profile is renamed (by deletion and recreation)
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncBizProfileConnectionName, true);
        GraphBusinessProfile.Rename(CreateGuid);

        // [WHEN] Company Information has Name field changed.
        CompanyInformation.Get;
        CompanyInformation.Validate(Name, LibraryUtility.GenerateGUID);
        CompanyInformation.Modify(true);

        // [WHEN] Full sync is run for business profile.
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::"Company Information");
        LibraryGraphSync.AssertNoSynchErrors;

        // [THEN] The sync process relinks to the new business profile and syncs changes from graph.
        CompanyInformation.Get;
        GraphBusinessProfile.FindFirst;
        GraphBusinessProfile.TestField(Name, CompanyInformation.Name);

        VerifyCompanyBusinessProfileId(GraphBusinessProfile.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeltaSyncEditGraphContacts()
    var
        GraphContact1: Record "Graph Contact";
        GraphContact2: Record "Graph Contact";
        GraphContact3: Record "Graph Contact";
        Contact: Record Contact;
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
        DeltaToken: Text[250];
    begin
        // DeltaSync from Graph to Nav syncs only records with different delta token
        // GIVEN Few Graph Contacts
        // GIVEN Edit a Graph Contact and make sure it has a different delta token and changekey
        // WHEN  Delta Sync is run
        // THEN  Only edited Graph contact is synced

        // Setup
        Initialize;
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncContactConnectionName, true);
        DeltaToken := LibraryGraphSync.GenerateRandomDeltaToken;
        LibraryGraphSync.CreateGraphPersonContactWithDeltaToken(GraphContact1, SyncContactConnectionName, DeltaToken);
        LibraryGraphSync.CreateGraphPersonContactWithDeltaToken(GraphContact2, SyncContactConnectionName, DeltaToken);
        LibraryGraphSync.CreateGraphPersonContactWithDeltaToken(GraphContact3, SyncContactConnectionName, DeltaToken);
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::Contact);

        GraphContact2.DeltaToken := LibraryGraphSync.GenerateRandomDeltaToken;
        GraphContact2.ChangeKey := LibraryGraphSync.GenerateRandomDeltaToken;
        GraphContact2.Modify;
        LibraryGraphSync.DeleteAllLogRecords;

        // Exercise
        GraphSyncRunner.RunDeltaSyncForEntity(DATABASE::Contact);

        // Verify
        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact2);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact2, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeltaSyncEditNavContacts()
    var
        Contact1: Record Contact;
        Contact2: Record Contact;
        GraphContact: Record "Graph Contact";
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        // DeltaSync from Nav to Sync syncs only records with different timestamp newer than last sync
        // GIVEN Few Nav Contacts
        // GIVEN Edit a Nav Contact
        // WHEN  Delta Sync is run
        // THEN  Only edited Nav Contact is synced

        // Setup
        Initialize;
        LibraryMarketing.CreatePersonContact(Contact1);
        LibraryMarketing.CreatePersonContact(Contact2);
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::Contact);
        LibraryGraphSync.FindGraphIntegrationRecordForContact(GraphIntegrationRecord, Contact1.RecordId);

        UpdateContactSlowlyOccurringAtDifferentTimestamp(Contact1, GraphIntegrationRecord);
        LibraryGraphSync.DeleteAllLogRecords;

        // Exercise
        GraphSyncRunner.RunDeltaSyncForEntity(DATABASE::Contact);

        // Verify
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncContactConnectionName, true);
        LibraryGraphSync.FindGraphContactForContact(GraphContact, Contact1);
        AssertPersonContactDetailsEqualGraphContactDetails(GraphContact, Contact1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncUpdatedContactFromGraphSameChangekey()
    var
        GraphContact1: Record "Graph Contact";
        GraphContact2: Record "Graph Contact";
        GraphContact3: Record "Graph Contact";
        Contact: Record Contact;
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
        ChangeKey: Text[250];
        OldContactDetails: Text;
    begin
        // DeltaSync from Graph to Nav but no change in changekey skips the syncing
        // GIVEN Few Graph Contacts
        // GIVEN Edit a Graph Contact and make sure changekey is not changed
        // WHEN  Delta Sync is run
        // THEN  No Graph Contact is synced

        // Setup
        Initialize;
        LibraryGraphSync.CreateGraphPersonContact(GraphContact1, SyncContactConnectionName);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact2, SyncContactConnectionName);
        LibraryGraphSync.CreateGraphPersonContact(GraphContact3, SyncContactConnectionName);
        GraphSyncRunner.RunFullSyncForEntity(DATABASE::Contact);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SyncContactConnectionName, true);

        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact2);
        OldContactDetails := Format(Contact);
        ChangeKey := GraphContact2.ChangeKey;
        LibraryGraphSync.EditGraphContactBasicDetails(GraphContact2);
        GraphContact2.DeltaToken := LibraryGraphSync.GenerateRandomDeltaToken;
        GraphContact2.ChangeKey := ChangeKey;
        GraphContact2.Modify;
        LibraryGraphSync.DeleteAllLogRecords;

        // Exercise
        GraphSyncRunner.RunDeltaSyncForEntity(DATABASE::Contact);

        // Verify
        LibraryGraphSync.FindContactForGraphContact(Contact, GraphContact2);
        Assert.AreEqual(OldContactDetails, Format(Contact), 'The contact seemed to have been modified');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFullSyncRunsOnlyOnce()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        // Setup
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);
        IntegrationTableMapping.TestField("Full Sync is Running", false);
        Assert.IsTrue(IntegrationTableMapping.IsFullSyncAllowed, '');

        // Exercise // Verify
        IntegrationTableMapping.SetFullSyncStartAndCommit;
        IntegrationTableMapping.TestField("Full Sync is Running", true);
        Assert.IsFalse(IntegrationTableMapping.IsFullSyncAllowed, '');
        IntegrationTableMapping.SetFullSyncEndAndCommit;
        IntegrationTableMapping.TestField("Full Sync is Running", false);
        Assert.IsTrue(IntegrationTableMapping.IsFullSyncAllowed, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFullSyncCanRestartAfter24H()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        // Setup
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);

        // Exercise
        IntegrationTableMapping.SetFullSyncStartAndCommit;
        IntegrationTableMapping."Last Full Sync Start DateTime" :=
          CreateDateTime(CalcDate('<-1D>', DT2Date(IntegrationTableMapping."Last Full Sync Start DateTime")),
            DT2Time(IntegrationTableMapping."Last Full Sync Start DateTime") - 3601000); // Go back an extra hour for DST issues
        IntegrationTableMapping.Modify;

        // Verify
        Assert.IsTrue(IntegrationTableMapping.IsFullSyncAllowed, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFullSyncCanRestartIfSessionClosed()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        // Setup
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, ContactMappingCode);

        // Exercise
        IntegrationTableMapping.SetFullSyncStartAndCommit;
        IntegrationTableMapping."Full Sync Session ID" := 0;
        IntegrationTableMapping.Modify;

        // Verify
        Assert.IsTrue(IntegrationTableMapping.IsFullSyncAllowed, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncWithNoAccessToGraphFailsGracefully()
    begin
        // [SCENARIO 258674] Don't attempt to sync to graph if unauthorized or forbidden.

        // [GIVEN] No test connections exist for the tables
        ReregisterConnections(DATABASE::Contact);
        ReregisterConnections(DATABASE::"Company Information");

        // Attempts to sync should fail gracefully.
        AttemptRegularSync(DATABASE::Contact);
        AttemptRegularSync(DATABASE::"Company Information");
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        Contact: Record Contact;
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        GraphDataSetup: Codeunit "Graph Data Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        LibraryGraphSync.RegisterTestConnections;
        LibraryGraphSync.DeleteAllIntegrationRecords;
        LibraryGraphSync.DeleteAllGraphContactRecords;
        LibraryGraphSync.DeleteAllLogRecords;
        LibraryGraphSync.DeleteAllContactIntegrationMappingDetails;
        Contact.DeleteAll;

        CompanyInformation.Get;
        CompanyInformation."Demo Company" := false;
        CompanyInformation.Modify;

        if IsInitialized then
            exit;

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SyncContactConnectionName := GraphConnectionSetup.GetSynchronizeConnectionName(DATABASE::Contact);
        ContactMappingCode := GraphDataSetup.GetMappingCodeForTable(DATABASE::Contact);
        SyncBizProfileConnectionName := GraphConnectionSetup.GetSynchronizeConnectionName(DATABASE::"Company Information");
        BizProfileMappingCode := GraphDataSetup.GetMappingCodeForTable(DATABASE::"Company Information");
        LibraryGraphSync.EnableGraphSync;
        BindSubscription(GraphBackgroundSyncSubscr);

        IsInitialized := true;
    end;

    local procedure UpdateContactSlowlyOccurringAtDifferentTimestamp(var Contact: Record Contact; var GraphIntegrationRecord: Record "Graph Integration Record")
    begin
        LibraryGraphSync.EditContactBasicDetails(Contact);
        LibraryGraphSync.SetDifferentIntegrationTimestampForContact(GraphIntegrationRecord, Contact.RecordId);
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

    [EventSubscriber(ObjectType::Codeunit, 5451, 'OnBeforeSynchronizationStart', '', false, false)]
    local procedure SkipRecordSyncingOnBeforeSyncHandler(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
        IgnoreRecord := true;
    end;

    local procedure CreatePersonContactWithNameDetails(var Contact: Record Contact)
    var
        MaxPartLength: Integer;
    begin
        LibraryMarketing.CreatePersonContact(Contact);
        MaxPartLength := (MaxStrLen(Contact.Name) - 2) div 3;
        Contact.Validate("First Name", CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact."First Name")), 1, MaxPartLength));
        Contact.Validate("Middle Name", CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact."Middle Name")), 1, MaxPartLength));
        Contact.Validate(Surname, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact.Surname)), 1, MaxPartLength));
        Contact.Modify(true);
    end;

    local procedure SetBusinessProfileLogo(var GraphBusinessProfile: Record "Graph Business Profile"; var Picture: Text)
    var
        OutStream1: OutStream;
        OutStream2: OutStream;
    begin
        GraphBusinessProfile.Logo.CreateOutStream(OutStream1);
        OutStream1.WriteText('{ "lastModifiedDate" : "' + Format(CurrentDateTime, 0, 9) + '" }');

        Picture := CreateGuid;
        GraphBusinessProfile.LogoContent.CreateOutStream(OutStream2);
        OutStream2.WriteText(Picture);
    end;

    local procedure VerifyCompanyBusinessProfileId(GraphBusinessProfileId: Text[250])
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName);
        Company.TestField("Business Profile Id", GraphBusinessProfileId);
    end;

    local procedure AttemptRegularSync(TableID: Integer)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        SyncMappingCode: Code[20];
    begin
        // [GIVEN] The default sync mapping and connections are set up for the table
        SyncMappingCode := GraphDataSetup.GetMappingCodeForTable(TableID);
        GraphDataSetup.CreateIntegrationMapping(SyncMappingCode);

        // [WHEN] A manual sync is run for the table
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, SyncMappingCode);
        CODEUNIT.Run(CODEUNIT::"Graph Integration Table Sync", IntegrationTableMapping);

        // [THEN] The errors thrown are caught and the sync fails gracefully.
    end;

    local procedure ReregisterConnections(TableID: Integer)
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        ConnectionName: Text;
        ConnectionString: Text;
    begin
        ConnectionName := GraphConnectionSetup.GetInboundConnectionName(TableID);
        ConnectionString := GraphConnectionSetup.GetInboundConnectionString(TableID);
        RegisterConnection(ConnectionName, ConnectionString);

        ConnectionName := GraphConnectionSetup.GetSynchronizeConnectionName(TableID);
        ConnectionString := GraphConnectionSetup.GetSynchronizeConnectionString(TableID);
        RegisterConnection(ConnectionName, ConnectionString);

        ConnectionName := GraphConnectionSetup.GetSubscriptionConnectionName(TableID);
        ConnectionString := GraphConnectionSetup.GetSubscriptionConnectionString(TableID);
        RegisterConnection(ConnectionName, ConnectionString);
    end;

    local procedure RegisterConnection(ConnectionName: Text; BaseConnectionString: Text)
    var
        NewConnectionString: DotNet String;
    begin
        if HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName) then
            UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName);

        NewConnectionString := BaseConnectionString + ';{REQUESTHEADERS}=Authorization: Bearer 1234';
        NewConnectionString :=
          NewConnectionString.Replace('{SHAREDCONTACTS}', 'SystemMailbox{18468D8D-B060-4A89-AB6A-B2FA0D65C07A}@test.onmicrosoft.com');

        RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName, NewConnectionString);
    end;
}

