codeunit 130620 "Library - Graph Sync"
{

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryUtility: Codeunit "Library - Utility";
        TestConnectionStringTxt: Label '@@test@@', Locked = true;
        MockSubscriptionIdTxt: Label 'DD17B5B8-1F51-4911-ABC7-6ED8AC94AE5E', Locked = true;
        SyncErrorsErr: Label 'Sync completed with errors (%1): %2';

    [Scope('OnPrem')]
    procedure GetTestConnectionString(): Text
    begin
        exit('@@test@@');
    end;

    [Scope('OnPrem')]
    procedure CreateGraphBusinessProfile(var GraphBusinessProfile: Record "Graph Business Profile"; ConnectionName: Text)
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName, true);
        with GraphBusinessProfile do begin
            Init;
            Id := LibraryUtility.GenerateGUID;
            Name := LibraryUtility.GenerateGUID;
            "Tax Id" := LibraryUtility.GenerateGUID;
            Industry := LibraryUtility.GenerateGUID;
            IsPrimary := true;
            BrandColor := '#3DCF0B00';
            ETag := CreateGuid;
            LastModifiedDate := CurrentDateTime;
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateGraphCompanyContact(var GraphContact: Record "Graph Contact"; ConnectionName: Text)
    var
        Contact: Record Contact;
    begin
        CreateGraphContact(GraphContact, Contact.Type::Company, ConnectionName);
    end;

    [Scope('OnPrem')]
    procedure CreateGraphPersonContact(var GraphContact: Record "Graph Contact"; ConnectionName: Text)
    var
        Contact: Record Contact;
    begin
        CreateGraphContact(GraphContact, Contact.Type::Person, ConnectionName);
    end;

    [Scope('OnPrem')]
    procedure CreateGraphPersonContactWithDeltaToken(var GraphContact: Record "Graph Contact"; ConnectionName: Text; DeltaToken: Text[250])
    begin
        CreateGraphPersonContact(GraphContact, ConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName, true);
        GraphContact.DeltaToken := DeltaToken;
        GraphContact.Modify;
    end;

    local procedure CreateGraphContact(var GRAPHContact: Record "Graph Contact"; NewContactType: Option; ConnectionName: Text)
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName, true);
        with GRAPHContact do begin
            Init;
            Id := LibraryUtility.GenerateGUID;
            SetBusinessTypeString(GraphCollectionMgtContact.AddBusinessType(NewContactType));
            SetIsContactString(GraphCollectionMgtContact.AddIsContact(true));
            SetIsNavCreatedString(GraphCollectionMgtContact.AddIsNavCreated(false));
            GivenName := LibraryUtility.GenerateGUID;
            MiddleName := LibraryUtility.GenerateGUID;
            Surname := LibraryUtility.GenerateGUID;
            DeltaToken := LibraryUtility.GenerateGUID;
            ChangeKey := LibraryUtility.GenerateGUID;
            LastModifiedDateTime := CurrentDateTime;
            CreatedDateTime := CurrentDateTime;
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetGraphContactAsCustomer(var GraphContact: Record "Graph Contact"; ConnectionName: Text)
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName, true);
        GraphContact.SetIsCustomerString(GraphCollectionMgtContact.AddIsCustomer(true));
        GraphContact.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetGraphContactAsVendor(var GraphContact: Record "Graph Contact"; ConnectionName: Text)
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName, true);
        GraphContact.SetIsVendorString(GraphCollectionMgtContact.AddIsVendor(true));
        GraphContact.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetGraphContactAsBank(var GraphContact: Record "Graph Contact"; ConnectionName: Text)
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName, true);
        GraphContact.SetIsBankString(GraphCollectionMgtContact.AddIsBank(true));
        GraphContact.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCompanyContact(var Contact: Record Contact)
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        EditContactBasicDetails(Contact);
    end;

    [Scope('OnPrem')]
    procedure CreatePersonContact(var Contact: Record Contact)
    begin
        LibraryMarketing.CreatePersonContact(Contact);
        EditContactBasicDetails(Contact);
    end;

    [Scope('OnPrem')]
    procedure EditContactBasicDetails(var Contact: Record Contact)
    begin
        with Contact do begin
            Validate("Name 2", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen("Name 2"), 1));
            Validate("First Name", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Name) div 4, 1));
            Validate("Middle Name", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Name) div 4, 1));
            Validate(Surname, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Name) div 4, 1));
            Validate(Initials, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Initials), 1));
            Validate("E-Mail", LibraryUtility.GenerateRandomEmail);
            Validate("E-Mail 2", LibraryUtility.GenerateRandomEmail);
            Validate("Home Page", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen("Home Page"), 1));
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure EditContactAddressDetails(var Contact: Record Contact)
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        PostCode.Validate(County, LibraryUtility.GenerateRandomText(MaxStrLen(PostCode.County)));
        PostCode.Modify(true);

        with Contact do begin
            Validate(Address, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Address)), 1, MaxStrLen(Address)));
            Validate("Address 2", CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen("Address 2")), 1, MaxStrLen("Address 2")));
            Validate("Post Code", PostCode.Code);
            Validate("Phone No.", CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen("Phone No.")), 1, MaxStrLen("Phone No.")));
            Validate("Fax No.", CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen("Fax No.")), 1, MaxStrLen("Fax No.")));
            Validate(Pager, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Pager)), 1, MaxStrLen(Pager)));
            Validate("Mobile Phone No.",
              CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen("Mobile Phone No.")), 1, MaxStrLen("Mobile Phone No.")));
            Validate("Home Page", CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen("Home Page")), 1, MaxStrLen("Home Page")));
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure EditContactAlternateAddress(Contact: Record Contact; AddressCode: Code[10])
    var
        ContactAltAddress: Record "Contact Alt. Address";
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        PostCode.Validate(County, LibraryUtility.GenerateRandomText(MaxStrLen(PostCode.County)));
        PostCode.Modify(true);

        LibraryMarketing.CreateContactAltAddress(ContactAltAddress, Contact."No.");
        with ContactAltAddress do begin
            Rename(Contact."No.", AddressCode);
            Validate(Address, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Address)), 1, MaxStrLen(Address)));
            Validate("Address 2", CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen("Address 2")), 1, MaxStrLen("Address 2")));
            Validate("Post Code", PostCode.Code);
            Validate("Phone No.", CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen("Phone No.")), 1, MaxStrLen("Phone No.")));
            Validate("Fax No.", CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen("Fax No.")), 1, MaxStrLen("Fax No.")));
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure EditGraphBusinessProfileBasicDetails(var GraphBusinessProfile: Record "Graph Business Profile")
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        InboundConnectionName: Text;
    begin
        InboundConnectionName := GraphConnectionSetup.GetInboundConnectionName(DATABASE::"Company Information");
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, InboundConnectionName, true);
        with GraphBusinessProfile do begin
            Validate(Name, LibraryUtility.GenerateGUID);
            Validate(Industry, LibraryUtility.GenerateGUID);
            Validate(LastModifiedDate, CurrentDateTime);
            Validate(ETag, CreateGuid);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure EditGraphContactBasicDetails(var GraphContact: Record "Graph Contact")
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        InboundConnectionName: Text;
    begin
        InboundConnectionName := GraphConnectionSetup.GetInboundConnectionName(DATABASE::Contact);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, InboundConnectionName, true);
        with GraphContact do begin
            Validate(GivenName, LibraryUtility.GenerateRandomText(MaxStrLen(GivenName)));
            Validate(MiddleName, LibraryUtility.GenerateRandomText(MaxStrLen(MiddleName)));
            Validate(Surname, LibraryUtility.GenerateRandomText(MaxStrLen(Surname)));
            Validate(Initials, LibraryUtility.GenerateRandomText(MaxStrLen(Initials)));
            Validate(DeltaToken, LibraryUtility.GenerateRandomText(MaxStrLen(DeltaToken)));
            Validate(ChangeKey, LibraryUtility.GenerateRandomText(MaxStrLen(ChangeKey)));
            Validate(LastModifiedDateTime, CurrentDateTime);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure SyncRecords(IntegrationTableMapping: Record "Integration Table Mapping")
    var
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        GraphSyncRunner.RunIntegrationTableSynch(IntegrationTableMapping);
    end;

    [Scope('OnPrem')]
    procedure FindGraphContactForContact(var GraphContact: Record "Graph Contact"; Contact: Record Contact)
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
    begin
        FindGraphIntegrationRecordForContact(GraphIntegrationRecord, Contact.RecordId);
        GraphContact.Get(GraphIntegrationRecord."Graph ID");
    end;

    [Scope('OnPrem')]
    procedure FindContactForGraphContact(var Contact: Record Contact; var GraphContact: Record "Graph Contact")
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationRecord: Record "Integration Record";
    begin
        FindGraphIntegrationRecordForGraphContact(GraphIntegrationRecord, GraphContact.Id);
        IntegrationRecord.Get(GraphIntegrationRecord."Integration ID");
        Contact.Get(IntegrationRecord."Record ID");
    end;

    [Scope('OnPrem')]
    procedure FindGraphIntegrationRecordForContact(var GraphIntegrationRecord: Record "Graph Integration Record"; ContactRecordID: RecordID)
    var
        IntegrationRecord: Record "Integration Record";
    begin
        FindIntegrationRecordForContact(IntegrationRecord, ContactRecordID);

        GraphIntegrationRecord.SetRange("Integration ID", IntegrationRecord."Integration ID");
        GraphIntegrationRecord.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure FindIntegrationRecordForContact(var IntegrationRecord: Record "Integration Record"; ContactRecordID: RecordID)
    begin
        Assert.AreEqual(DATABASE::Contact, ContactRecordID.TableNo, 'Table is not Contact.');
        IntegrationRecord.SetRange("Record ID", ContactRecordID);
        IntegrationRecord.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure FindGraphIntegrationRecordForGraphContact(var GraphIntegrationRecord: Record "Graph Integration Record"; GraphUniqueID: Text)
    begin
        GraphIntegrationRecord.SetRange("Graph ID", GraphUniqueID);
        GraphIntegrationRecord.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure FindProfileQuestionnaireValueForContact(ContactNo: Code[20]; GraphContactFieldName: Text): Text[250]
    var
        ContactProfileAnswer: Record "Contact Profile Answer";
        GraphIntQuestionnaire: Codeunit "Graph Int. - Questionnaire";
    begin
        ContactProfileAnswer.Get(ContactNo, GraphIntQuestionnaire.GetGraphSyncQuestionnaireCode,
          FindGraphSyncProfileQuestionnaireLineNo(GraphContactFieldName));

        exit(ContactProfileAnswer."Profile Questionnaire Value");
    end;

    local procedure FindGraphSyncProfileQuestionnaireLineNo(InputDescription: Text): Integer
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        GraphIntQuestionnaire: Codeunit "Graph Int. - Questionnaire";
    begin
        with ProfileQuestionnaireLine do begin
            SetRange("Profile Questionnaire Code", GraphIntQuestionnaire.GetGraphSyncQuestionnaireCode);
            SetRange(Description, CopyStr(InputDescription, 1, MaxStrLen(Description)));
            FindFirst;
            exit("Line No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure SetTableFilterOnIntegrationTableMapping(IntegrationTableMappingName: Code[20]; TableFilter: Text)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        OutStream: OutStream;
    begin
        Assert.AreNotEqual('', TableFilter, 'Table filter is missing.');

        IntegrationTableMapping.Get(IntegrationTableMappingName);
        IntegrationTableMapping."Table Filter".CreateOutStream(OutStream);
        OutStream.WriteText(TableFilter);
        IntegrationTableMapping.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetSameIntegrationTimestampForContact(var GraphIntegrationRecord: Record "Graph Integration Record"; ContactRecordID: RecordID)
    var
        IntegrationRecord: Record "Integration Record";
    begin
        FindIntegrationRecordForContact(IntegrationRecord, ContactRecordID);

        GraphIntegrationRecord.Find;
        GraphIntegrationRecord.Validate("Last Synch. Modified On", IntegrationRecord."Modified On");
        GraphIntegrationRecord.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetSameIntegrationTimestampForGraphContact(var GraphIntegrationRecord: Record "Graph Integration Record"; var GraphContact: Record "Graph Contact")
    begin
        FindGraphIntegrationRecordForGraphContact(GraphIntegrationRecord, GraphContact.Id);

        GraphIntegrationRecord.Validate("Last Synch. Graph Modified On", GraphContact.LastModifiedDateTime);
        GraphIntegrationRecord.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetDifferentIntegrationTimestampForContact(var GraphIntegrationRecord: Record "Graph Integration Record"; ContactRecordID: RecordID)
    var
        IntegrationRecord: Record "Integration Record";
        DateValue: Date;
        TimeValue: Time;
    begin
        FindIntegrationRecordForContact(IntegrationRecord, ContactRecordID);
        DateValue := DT2Date(IntegrationRecord."Modified On");
        TimeValue := DT2Time(IntegrationRecord."Modified On");

        GraphIntegrationRecord.Find;
        GraphIntegrationRecord.Validate("Last Synch. Modified On", CreateDateTime(DateValue - 1, TimeValue));
        GraphIntegrationRecord.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetDifferentIntegrationTimestampForGraphContact(var GraphIntegrationRecord: Record "Graph Integration Record"; var GraphContact: Record "Graph Contact")
    var
        DateValue: Date;
        TimeValue: Time;
    begin
        FindGraphIntegrationRecordForGraphContact(GraphIntegrationRecord, GraphContact.Id);
        DateValue := DT2Date(GraphContact.LastModifiedDateTime);
        TimeValue := DT2Time(GraphContact.LastModifiedDateTime);

        GraphIntegrationRecord.Find;
        GraphIntegrationRecord.Validate("Last Synch. Graph Modified On", CreateDateTime(CalcDate('<1D>', DateValue), TimeValue));
        GraphIntegrationRecord.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateGraphSyncProfileQuestionnaire()
    var
        GraphIntQuestionnaire: Codeunit "Graph Int. - Questionnaire";
    begin
        GraphIntQuestionnaire.CreateGraphSyncQuestionnaire;
    end;

    [Scope('OnPrem')]
    procedure DeleteAllContactProfileAnswers()
    var
        ContactProfileAnswer: Record "Contact Profile Answer";
        GraphIntQuestionnaire: Codeunit "Graph Int. - Questionnaire";
    begin
        ContactProfileAnswer.SetRange("Profile Questionnaire Code", GraphIntQuestionnaire.GetGraphSyncQuestionnaireCode);
        ContactProfileAnswer.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure DeleteAllProfileQuestionnaireDetails()
    var
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
        GraphIntQuestionnaire: Codeunit "Graph Int. - Questionnaire";
    begin
        ProfileQuestionnaireLine.SetRange("Profile Questionnaire Code", GraphIntQuestionnaire.GetGraphSyncQuestionnaireCode);
        ProfileQuestionnaireLine.SetRange(Type, ProfileQuestionnaireLine.Type::Answer);
        ProfileQuestionnaireLine.DeleteAll(true);

        ProfileQuestionnaireHeader.SetRange(Code, GraphIntQuestionnaire.GetGraphSyncQuestionnaireCode);
        ProfileQuestionnaireHeader.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure DeleteAllContactIntegrationMappingDetails()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.SetRange("Table ID", DATABASE::Contact);
        IntegrationTableMapping.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure DeleteAllIntegrationRecords()
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationRecord: Record "Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        GraphIntegrationRecord.LockTable(true);
        GraphIntegrationRecord.DeleteAll(true);
        IntegrationRecord.LockTable(true);
        IntegrationRecord.DeleteAll(true);
        IntegrationSynchJob.LockTable(true);
        IntegrationSynchJob.DeleteAll(true);
        IntegrationSynchJobErrors.LockTable(true);
        IntegrationSynchJobErrors.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure DeleteAllGraphContactRecords()
    var
        GraphContact: Record "Graph Contact";
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        SubscriptionConnectionName: Text;
    begin
        SubscriptionConnectionName := GraphConnectionSetup.GetSubscriptionConnectionName(DATABASE::Contact);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SubscriptionConnectionName, true);
        GraphContact.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure DeleteAllLogRecords()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        IntegrationSynchJob.DeleteAll;
        IntegrationSynchJobErrors.DeleteAll;
    end;

    [Scope('OnPrem')]
    procedure EnableGraphSync()
    begin
        SetGraphSyncState(true);
    end;

    [Scope('OnPrem')]
    procedure DisableGraphSync()
    begin
        SetGraphSyncState(false);
    end;

    local procedure SetGraphSyncState(SyncState: Boolean)
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get;
        MarketingSetup."Sync with Microsoft Graph" := SyncState;
        MarketingSetup.Modify(true);
    end;

    local procedure GetMockSubscriptionGUID() Result: Guid
    begin
        Evaluate(Result, MockSubscriptionIdTxt);
    end;

    [Scope('OnPrem')]
    procedure MockIncomingBusinessProfile(var GraphBusinessProfile: Record "Graph Business Profile"; ChangeType: Text[50])
    var
        TempWebhookNotification: Record "Webhook Notification" temporary;
    begin
        with TempWebhookNotification do begin
            Init;
            "Resource ID" := CopyStr(GraphBusinessProfile.Id, 1, MaxStrLen("Resource ID"));
            "Change Type" := ChangeType;
            "Subscription ID" := GetMockSubscriptionGUID;
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure MockIncomingContact(var GraphContact: Record "Graph Contact"; ChangeType: Text[50])
    begin
        MockIncomingContactId(GraphContact.Id, ChangeType);
    end;

    [Scope('OnPrem')]
    procedure MockIncomingContactId(ContactId: Text[250]; ChangeType: Text[50])
    var
        WebhookNotification: Record "Webhook Notification";
        WebhookSubscription: Record "Webhook Subscription";
        SubscriptionID: Text[150];
    begin
        WebhookSubscription.SetRange(Endpoint, GetWebhookEndpoint(DATABASE::Contact));
        if WebhookSubscription.FindFirst then
            SubscriptionID := WebhookSubscription."Subscription ID"
        else
            SubscriptionID := MockSubscriptionIdTxt;

        with WebhookNotification do begin
            Init;
            ID := CreateGuid;
            "Resource ID" := CopyStr(ContactId, 1, MaxStrLen("Resource ID"));
            "Change Type" := ChangeType;
            "Subscription ID" := SubscriptionID;
            Insert(true);
        end;
        Commit;
    end;

    [Scope('OnPrem')]
    procedure MockIncomingContactIdAsync(ContactId: Text[250]; ChangeType: Text[50])
    var
        WebhookNotificationTrigger: Record "Webhook Notification Trigger";
    begin
        WebhookNotificationTrigger.Init;
        WebhookNotificationTrigger.ContactID := ContactId;
        WebhookNotificationTrigger.ChangeType := ChangeType;
        WebhookNotificationTrigger.Insert(true);

        // Could simulate latency here by specifying the NotBefore parameter
        WebhookNotificationTrigger.TaskID :=
          TASKSCHEDULER.CreateTask(CODEUNIT::"Library - Graph Webhook", 0, true, CompanyName,
            CurrentDateTime + 200, WebhookNotificationTrigger.RecordId);
        WebhookNotificationTrigger.Modify(true);
        Commit;
    end;

    [Scope('OnPrem')]
    procedure CreateGraphWebhookSubscription(TableID: Integer)
    var
        WebhookSubscription: Record "Webhook Subscription";
    begin
        WebhookSubscription.DeleteAll;
        WebhookSubscription.Init;
        WebhookSubscription."Subscription ID" := GetMockSubscriptionGUID;
        WebhookSubscription."Company Name" := CompanyName;
        WebhookSubscription.Endpoint := GetWebhookEndpoint(TableID);
        WebhookSubscription.Insert;
    end;

    [Scope('OnPrem')]
    procedure GenerateRandomDeltaToken(): Text[250]
    begin
        exit(LibraryUtility.GenerateGUID);
    end;

    [Scope('OnPrem')]
    procedure RegisterTestConnections()
    begin
        RegisterTestConnectionsForEntity(DATABASE::Contact);
        RegisterTestConnectionsForEntity(DATABASE::"Company Information");
    end;

    [Scope('OnPrem')]
    procedure RegisterMockConnections()
    var
        ServiceUrl: Text;
    begin
        ServiceUrl := GetUrl(CLIENTTYPE::Api, CompanyName, OBJECTTYPE::Page, PAGE::"Exchange Contact API Mock");
        RegisterMockConnectionsForEntity(DATABASE::Contact, ServiceUrl);

        RegisterTestConnectionsForEntity(DATABASE::"Company Information");
    end;

    local procedure RegisterTestConnectionsForEntity(TableID: Integer)
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        InboundConnectionName: Text;
        SubscriptionConnectionName: Text;
        SynchronizeConnectionName: Text;
    begin
        InboundConnectionName := GraphConnectionSetup.GetInboundConnectionName(TableID);
        SubscriptionConnectionName := GraphConnectionSetup.GetSubscriptionConnectionName(TableID);
        SynchronizeConnectionName := GraphConnectionSetup.GetSynchronizeConnectionName(TableID);

        RegisterConnectionWithName(InboundConnectionName, TestConnectionStringTxt);
        RegisterConnectionWithName(SubscriptionConnectionName, TestConnectionStringTxt);
        RegisterConnectionWithName(SynchronizeConnectionName, TestConnectionStringTxt);
    end;

    local procedure RegisterConnectionWithName(ConnectionName: Text; ConnectionString: Text)
    begin
        UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName);
        RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionName, ConnectionString);
    end;

    local procedure RegisterMockConnectionsForEntity(TableID: Integer; ServiceUrl: Text)
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        InboundConnectionName: Text;
        SubscriptionConnectionName: Text;
        SynchronizeConnectionName: Text;
        InboundConnectionString: Text;
        SubscriptionConnectionString: Text;
        SynchronizeConnectionString: Text;
    begin
        InboundConnectionName := GraphConnectionSetup.GetInboundConnectionName(TableID);
        SynchronizeConnectionName := GraphConnectionSetup.GetSynchronizeConnectionName(TableID);
        SubscriptionConnectionName := GraphConnectionSetup.GetSubscriptionConnectionName(TableID);

        InboundConnectionString := GraphConnectionSetup.ConstructConnectionString(ServiceUrl, ServiceUrl, '', '');
        InboundConnectionString += ';{MOCK}=1';
        SynchronizeConnectionString := InboundConnectionString;
        SubscriptionConnectionString := InboundConnectionString;

        RegisterConnectionWithName(InboundConnectionName, InboundConnectionString);
        RegisterConnectionWithName(SynchronizeConnectionName, SynchronizeConnectionString);
        RegisterConnectionWithName(SubscriptionConnectionName, SubscriptionConnectionString);
    end;

    [Scope('OnPrem')]
    procedure GetSourceDestCode(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Text
    begin
        if (SourceRecordRef.Number <> 0) and (DestinationRecordRef.Number <> 0) then
            exit(StrSubstNo('%1-%2', SourceRecordRef.Name, DestinationRecordRef.Name));
        exit('');
    end;

    local procedure GetWebhookEndpoint(TableID: Integer) Endpoint: Text[250]
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        ConnectionString: Text;
        SearchString: Text;
    begin
        ConnectionString := GraphConnectionSetup.GetSynchronizeConnectionString(TableID);
        SearchString := '{ENTITYLISTENDPOINT}=';
        Endpoint := CopyStr(ConnectionString,
            StrPos(ConnectionString, SearchString) + StrLen(SearchString), StrPos(ConnectionString, ';') - 1 - StrLen(SearchString));
    end;

    [Scope('OnPrem')]
    procedure CheckContactIsCustomer(Contact: Record Contact): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        exit(ContactBusinessRelation.FindFirst);
    end;

    [Scope('OnPrem')]
    procedure CheckGraphContactIsCustomer(GraphContact: Record "Graph Contact"): Boolean
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        exit(GraphCollectionMgtContact.GetIsCustomer(GraphContact.GetIsCustomerString));
    end;

    [Scope('OnPrem')]
    procedure GraphContactAddIsCustomerTrue(var GraphContact: Record "Graph Contact")
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        GraphContact.SetIsCustomerString(GraphCollectionMgtContact.AddIsCustomer(true));
        GraphContact.Modify;
    end;

    [Scope('OnPrem')]
    procedure GraphContactAddIsCustomerFalse(var GraphContact: Record "Graph Contact")
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        GraphContact.SetIsCustomerString(GraphCollectionMgtContact.AddIsCustomer(false));
        GraphContact.Modify;
    end;

    [Scope('OnPrem')]
    procedure GraphContactAddIsContactTrue(var GraphContact: Record "Graph Contact")
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        GraphContact.SetIsContactString(GraphCollectionMgtContact.AddIsContact(true));
        GraphContact.Modify;
    end;

    [Scope('OnPrem')]
    procedure CheckContactIsVendor(Contact: Record Contact): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        exit(ContactBusinessRelation.FindFirst);
    end;

    [Scope('OnPrem')]
    procedure CheckGraphContactIsVendor(GraphContact: Record "Graph Contact"): Boolean
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        exit(GraphCollectionMgtContact.GetIsVendor(GraphContact.GetIsVendorString));
    end;

    [Scope('OnPrem')]
    procedure GraphContactAddIsVendorTrue(var GraphContact: Record "Graph Contact")
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        GraphContact.SetIsVendorString(GraphCollectionMgtContact.AddIsVendor(true));
        GraphContact.Modify;
    end;

    [Scope('OnPrem')]
    procedure GraphContactAddIsVendorFalse(var GraphContact: Record "Graph Contact")
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        GraphContact.SetIsVendorString(GraphCollectionMgtContact.AddIsVendor(false));
        GraphContact.Modify;
    end;

    [Scope('OnPrem')]
    procedure DisableDuplicateSearch()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get;
        MarketingSetup.Validate("Maintain Dupl. Search Strings", false);
        MarketingSetup.Modify;
    end;

    [Scope('OnPrem')]
    procedure AssertNoSynchErrors()
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        with IntegrationSynchJobErrors do
            if FindFirst then
                Error(SyncErrorsErr, Count, Message);
    end;

    [Scope('OnPrem')]
    procedure WebhookMockSubscriptionId() Id: Text
    begin
        Id := GetMockSubscriptionGUID
    end;
}

