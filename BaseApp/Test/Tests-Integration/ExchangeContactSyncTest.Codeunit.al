codeunit 133780 "Exchange Contact Sync Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Exchange Sync]
        LibraryO365Sync.SetupNavUser;
    end;

    var
        ConnectionFailureErr: Label 'The Office 365 synchronization setup record is not configured correctly.';
        ConnectionSuccessMsg: Label 'Connected successfully to Exchange.';
        UnexpectedMessageErr: Label 'Unexpected message: %1.', Comment = '%1 = Error message';
        Territory: Record Territory;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CountryRegion: Record "Country/Region";
        Assert: Codeunit Assert;
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        PasswordTxt: Label 'TFS72928!';
        NavEmail4emailcomTxt: Label 'NavEmail4@email.com';
        FirstName1Txt: Label 'FirstName1';
        MiddleName1Txt: Label 'MiddleName1';
        SurName1Txt: Label 'SurName1';
        Intials1Txt: Label 'Intials1';
        PostCode1Txt: Label 'PostCode1';
        HomePage1Txt: Label 'HomePage1';
        Phone1Txt: Label 'Phone1';
        Phone11Txt: Label 'Mobile1';
        Fax1Txt: Label 'Fax1';
        Address1Txt: Label 'Address1';
        City1Txt: Label 'City 1';
        NavEmail1emailcomTxt: Label 'NavEmail1@email.com';
        NavEmail12emailcomTxt: Label 'NavEmail12@email.com';
        Company1Txt: Label 'Company1';
        NavEmail3emailcomTxt: Label 'NavEmail3@email.com';
        NavEmail5emailcomTxt: Label 'NavEmail5@email.com';
        FirstName4Txt: Label 'FirstName4';
        MiddleName4Txt: Label 'MiddleName4';
        SurName4Txt: Label 'SurName4';
        Intials4Txt: Label 'Intials4';
        O365FirstName1Txt: Label 'O365FirstName1';
        O365MiddleName1Txt: Label 'O365MiddleName1';
        O365SurName1Txt: Label 'O365SurName1';
        O365Initials1Txt: Label 'O365Initials1';
        O365PostalCode1Txt: Label 'O365POSTALCODE1';
        O365Email1emailcomTxt: Label 'O365Email1@email.com';
        O365Email12emailcomTxt: Label 'O365Email12@email.com';
        O365BusinessHomePage1Txt: Label 'O365BusinessHomePage1';
        O365Phone1Txt: Label 'O365Phone1';
        O365Phone12Txt: Label 'O365Phone12';
        O365Phone13Txt: Label 'O365Phone13';
        O365Street1Txt: Label 'O365Street1';
        O365City1Txt: Label 'O365City1';
        O365FirstName3Txt: Label 'O365FirstName3';
        SetupO365Qst: Label 'Would you like to configure your connection to Office 365 now?';
        O365Email1emailcomNoSyncTxt: Label 'O365EmailNoSync1@email.com';
        JobTitleTxt: Label 'JobTitle';
        NavEmailContact5Txt: Label 'NavEmail5@email.com';
        StateTxt: Label 'State';
        CreateExchangeContactTxt: Label 'Create exchange contact.';
        LibraryO365Sync: Codeunit "Library - O365 Sync";
        LibraryUtility: Codeunit "Library - Utility";
        ContextTxt: Label 'Contact synchronization.';
        DescriptionTxt: Label 'Create contact. - %1', Comment = 'FIELDCAPTION("Company Name")';
        ActivityMessageTxt: Label 'The Exchange %1 is not unique in your company. %2', Comment = '%1=FIELDCAPTION("Company Name"),%2="E-mail"';
        ContactCompanyNameValidateErr: Label 'Type must be equal to ''%1''  in %2: %3=%4. Current value is ''%5''.', Comment = '%1=ExpectedType,%2=Contact,%3=FIELDCAPTION("No."),%4="No.",%5=ActualType';
        TestFieldErr: Label 'TestField';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestValidateConnectionFailure()
    var
        LocalExchangeSync: Record "Exchange Sync";
        ExchangeSyncSetup: TestPage "Exchange Sync. Setup";
        DummyGuid: Guid;
    begin
        // [SCENARIO] Test O365 connection failure logic.

        LibraryO365Sync.SetupExchangeSync(LocalExchangeSync);

        // [GIVEN] ExchangeSyncSetup form.
        // [GIVEN] Password is not set up on the user.
        LocalExchangeSync."Exchange Account Password Key" := DummyGuid;
        LocalExchangeSync.Modify(true);

        ExchangeSyncSetup.Trap;
        PAGE.Run(PAGE::"Exchange Sync. Setup", LocalExchangeSync);

        // [WHEN] O365Sync record is missing mandatory fields.
        asserterror ExchangeSyncSetup."Validate Exchange Connection".Invoke;

        // [THEN] Error "The O365 synchronization setup record is not configured correctly." is raised.
        Assert.AreEqual(ConnectionFailureErr, GetLastErrorText, 'Incorrect Error. Actual error: ' + GetLastErrorText);

        ExchangeSyncSetup.Close;
    end;

    [Test]
    [HandlerFunctions('ConnectionSuccessfulMessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestValidateConnectionSuccess()
    var
        LocalExchangeSync: Record "Exchange Sync";
        ContactSyncSetup: TestPage "Contact Sync. Setup";
    begin
        // [SCENARIO] Test O365 connection logic.

        LibraryO365Sync.SetupExchangeSync(LocalExchangeSync);

        // [GIVEN] Contact Sync Setup form.
        ContactSyncSetup.Trap;
        PAGE.Run(PAGE::"Contact Sync. Setup", LocalExchangeSync);

        // [WHEN] "Validate Exchange Connection" is clicked
        ContactSyncSetup.Trap;
        PAGE.Run(PAGE::"Contact Sync. Setup", LocalExchangeSync);
        ContactSyncSetup."Folder ID".Value('Folder');
        ContactSyncSetup."Validate Exchange Connection".Invoke;

        // [THEN] Handled by Message Handler "A connection to exchange successfully validated and completed." is raised.
    end;

    [Test]
    [HandlerFunctions('RequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSyncConnectionFromUI()
    var
        ExchangeSync: Record "Exchange Sync";
        ContactList: TestPage "Contact List";
    begin
        // [SCENARIO] Test O365 sync logic.

        Initialize;

        LibraryO365Sync.SetupExchangeSync(ExchangeSync);
        LibraryO365Sync.SetExchangeIncrementedSyncTime(ExchangeSync);

        InitializeExchangeContacts(ExchangeSync);

        // [GIVEN] ContactList form.
        ContactList.Trap;
        PAGE.Run(PAGE::"Contact List");

        // [WHEN] Sync is pressed.
        ContactList.SyncWithExchange.Invoke;

        // [THEN] Contacts are sync'd between NAV and Exchange
        ValidateResults;
    end;

    [Test]
    [HandlerFunctions('RequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSyncAllConnectionFromUI()
    var
        ExchangeSync: Record "Exchange Sync";
        ContactList: TestPage "Contact List";
    begin
        // [SCENARIO] Test O365 sync all logic.

        Initialize;

        LibraryO365Sync.SetupExchangeSync(ExchangeSync);
        LibraryO365Sync.SetExchangeIncrementedSyncTime(ExchangeSync);

        InitializeExchangeContacts(ExchangeSync);

        // [GIVEN] ContactList form.
        ContactList.Trap;
        PAGE.Run(PAGE::"Contact List");

        // [WHEN] Full Sync is pressed.
        ContactList.FullSyncWithExchange.Invoke;

        // [THEN] All contacts are sync'd between NAV and Exchange regardless of last modified date.
        ValidateSyncAllResults;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ActivityLogHandler')]
    [Scope('OnPrem')]
    procedure TestSyncFailure()
    var
        ExchangeSync: Record "Exchange Sync";
        ContactSyncSetup: TestPage "Contact Sync. Setup";
    begin
        // [SCENARIO] Test O365 sync try/catch logic.
        Initialize;

        // [GIVEN] Nav contact with duplicate email address.
        CreateContactWithSalesTerritoryDuplicate;

        LibraryO365Sync.SetupExchangeSync(ExchangeSync);
        LibraryO365Sync.SetExchangeIncrementedSyncTime(ExchangeSync);

        // [WHEN] Sync is pressed.
        ContactSyncSetup.Trap;
        PAGE.Run(PAGE::"Contact Sync. Setup", ExchangeSync);
        ContactSyncSetup.SyncO365.Invoke;

        // [THEN] A duplicate exchange contact record will be logged in the Activity Log.

        ContactSyncSetup.ActivityLog.Invoke;  // Handled by ActivityLogHandler
        TearDown;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSyncConnectionFromCodeUnit()
    var
        ExchangeSync: Record "Exchange Sync";
        O365SyncManagement: Codeunit "O365 Sync. Management";
    begin
        // [SCENARIO] Test O365 sync logic.

        Initialize;

        LibraryO365Sync.SetupExchangeSync(ExchangeSync);
        LibraryO365Sync.SetExchangeIncrementedSyncTime(ExchangeSync);

        InitializeExchangeContacts(ExchangeSync);

        // [GIVEN] Contact Sync Implementation code unit.

        // [WHEN] On Run is executed.
        O365SyncManagement.SyncExchangeContacts(ExchangeSync, false);

        // [THEN] Contacts are sync'd between NAV and Exchange
        ValidateResults;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestDeleteExchSync()
    var
        DummyExchangeSync: Record "Exchange Sync";
        LocalExchangeSync: Record "Exchange Sync";
        ExchangePassKey: Guid;
        ConnectionID: Guid;
    begin
        // [SCENARIO] Test Deletion of Exchange Sync record.
        if LocalExchangeSync.Get(UserId) then
            LocalExchangeSync.Delete();

        // This is required for the test framework to properly handle the cleanup in the labs.
        LibraryO365Sync.SetupExchangeSync(DummyExchangeSync);
        LibraryO365Sync.SetupExchangeTableConnection(DummyExchangeSync, ConnectionID);
        DummyExchangeSync.Delete(true);

        // [GIVEN] ExchangeSync record.
        LocalExchangeSync.Init();
        LocalExchangeSync."User ID" := UserId;
        LocalExchangeSync.SetExchangeAccountPassword(PasswordTxt);
        LocalExchangeSync.Insert(true);

        ExchangePassKey := LocalExchangeSync."Exchange Account Password Key";
        Assert.IsTrue(IsolatedStorageManagement.Contains(ExchangePassKey, DATASCOPE::Company),
            'Expected Record in Isolated Storage');

        // [WHEN] ExchangeSync is deleted.
        LocalExchangeSync.Delete(true);

        // [THEN] Isolated Storage record is removed.
        Assert.IsFalse(IsolatedStorageManagement.Contains(ExchangePassKey, DATASCOPE::Company),
            'Unexpected Record in Isolated Storage');

        // This is required for the test framework to properly handle the cleanup in the labs.
        LocalExchangeSync.Init();
        LibraryO365Sync.SetupExchangeSync(LocalExchangeSync);
        LibraryO365Sync.SetupExchangeTableConnection(LocalExchangeSync, ConnectionID);
    end;

    [Test]
    [HandlerFunctions('OpenExchangeSyncSetupHandler,ExchangeSyncSetupPageHandler')]
    [Scope('OnPrem')]
    procedure TestOpenSetupWindow()
    var
        LocalExchangeSync: Record "Exchange Sync";
        Contact: Record Contact;
        ContactList: TestPage "Contact List";
    begin
        // [SCENARIO] Test Open Exchange Sync page from ContactList.
        LibraryO365Sync.SetupExchangeSync(LocalExchangeSync);
        // Delete all contacts to avoid contacts being sync.
        Contact.DeleteAll();

        if LocalExchangeSync.Get(UserId) then
            LocalExchangeSync.Delete();

        // [GIVEN] ContactList Page with no ExchangeSync record.
        ContactList.Trap;
        PAGE.Run(PAGE::"Contact List");

        ClearLastError;

        // [WHEN] Sync is pressed.
        ContactList.SyncWithExchange.Invoke;

        // [THEN] The ExchangeSyncSetup page is opened and handled by page handler.

        ContactList.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferExchangeContactBlankCompanyName()
    var
        DummyExchangeSync: Record "Exchange Sync";
        ExchangeContact: Record Contact;
        Contact: Record Contact;
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
    begin
        // [SCENARIO 265991] When Contact "C1" with type Person and <blank> Company is transferred to Contact "C2" with same Type via O365 Contact Sync. Helper func TransferExchangeContactToNavContact,
        // [SCENARIO 265991] Then Contact "C2" has same Type, E-Mail, Name and Company as "C1"

        // [GIVEN] Contact "C1" with Type = Person and Company = <blank>
        PrepareExchangeContactWithCompanyName(ExchangeContact, '');

        // [GIVEN] Contact "C2" with Type = Person
        PrepareContactWithType(Contact, Contact.Type::Person, '');

        // [WHEN] Transfer "C1" to "C2" via O365 Contact Sync. Helper func TransferExchangeContactToNavContact
        O365ContactSyncHelper.TransferExchangeContactToNavContact(ExchangeContact, Contact, DummyExchangeSync);

        // [THEN] Contact "C2" has Company = <blank>
        // [THEN] Contact "C2" has same Type, E-Mail and Name as "C1"
        VerifyImportedContact(Contact, ExchangeContact.Name, ExchangeContact."E-Mail", ExchangeContact.Type, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferBookingContactBlankCompanyName()
    var
        ExchangeContact: Record Contact;
        Contact: Record Contact;
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
    begin
        // [SCENARIO 265991] When Contact "C1" with type Person and <blank> Company is transferred to Contact "C2" with same Type via O365 Contact Sync. Helper func TransferBookingContactToNavContact,
        // [SCENARIO 265991] Then Contact "C2" has same Type, E-Mail, Name and Company as "C1"

        // [GIVEN] Contact "C1" with Type = Person and Company = <blank>
        PrepareExchangeContactWithCompanyName(ExchangeContact, '');

        // [GIVEN] Contact "C2" with Type = Person
        PrepareContactWithType(Contact, Contact.Type::Person, '');

        // [WHEN] Transfer "C1" to "C2" via O365 Contact Sync. Helper func TransferBookingContactToNavContact
        O365ContactSyncHelper.TransferBookingContactToNavContact(ExchangeContact, Contact);

        // [THEN] Contact "C2" has Company = <blank>
        // [THEN] Contact "C2" has same Type, E-Mail and Name as "C1"
        VerifyImportedContact(Contact, ExchangeContact.Name, ExchangeContact."E-Mail", ExchangeContact.Type, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferExchangeContactToCompanyBlankCompanyName()
    var
        DummyExchangeSync: Record "Exchange Sync";
        ExchangeContact: Record Contact;
        Contact: Record Contact;
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
    begin
        // [SCENARIO 265991] When Contact "C1" with type Person and <blank> Company is transferred to Contact "C2" with type Company via O365 Contact Sync. Helper func TransferExchangeContactToNavContact,
        // [SCENARIO 265991] Then Contact "C2" has same E-Mail and Name as "C1", but Type and Company differ

        // [GIVEN] Contact "C1" with Name = "X", Type = Person and Company = <blank>
        PrepareExchangeContactWithCompanyName(ExchangeContact, '');

        // [GIVEN] Contact "C2" with Type = Company
        PrepareContactWithType(Contact, Contact.Type::Company, '');

        // [WHEN] Transfer "C1" to "C2" via O365 Contact Sync. Helper func TransferExchangeContactToNavContact
        O365ContactSyncHelper.TransferExchangeContactToNavContact(ExchangeContact, Contact, DummyExchangeSync);

        // [THEN] Contact "C2" has Type = Company, Company No. = "C2", "Company Name" = "X"
        // [THEN] Contact "C2" has same E-Mail and Name as "C1"
        VerifyImportedContact(
          Contact, ExchangeContact.Name, ExchangeContact."E-Mail", Contact.Type::Company, Contact."No.", ExchangeContact.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferBookingContactToCompanyBlankCompanyName()
    var
        ExchangeContact: Record Contact;
        Contact: Record Contact;
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
    begin
        // [SCENARIO 265991] When Contact "C1" with type Person and <blank> Company is transferred to Contact "C2" with type Company via O365 Contact Sync. Helper func TransferBookingContactToNavContact,
        // [SCENARIO 265991] Then Contact "C2" has same E-Mail and Name as "C1", but Type and Company differ

        // [GIVEN] Contact "C1" with Name = "X", Type = Person and Company = <blank>
        PrepareExchangeContactWithCompanyName(ExchangeContact, '');

        // [GIVEN] Contact "C2" with Type = Company
        PrepareContactWithType(Contact, Contact.Type::Company, '');

        // [WHEN] Transfer "C1" to "C2" via O365 Contact Sync. Helper func TransferBookingContactToNavContact
        O365ContactSyncHelper.TransferBookingContactToNavContact(ExchangeContact, Contact);

        // [THEN] Contact "C2" has Type = Company, Company No. = "C2", "Company Name" = "X"
        // [THEN] Contact "C2" has same E-Mail and Name as "C1"
        VerifyImportedContact(
          Contact, ExchangeContact.Name, ExchangeContact."E-Mail", Contact.Type::Company, Contact."No.", ExchangeContact.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TransferExchangeContactWhenCompanyNameNotUnique()
    var
        ExchangeSync: Record "Exchange Sync";
        ExchangeContact: Record Contact;
        Contact: Record Contact;
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
    begin
        // [SCENARIO 265991] When two Contacts type Company with same Company Name = "C" present and Contact "C1" with type Person and Company "C" is transferred to Contact "C2" with same Type
        // [SCENARIO 265991] via O365 Contact Sync. Helper func TransferExchangeContactToNavContact, then Contact "C2" has same Type, E-Mail, Name as "C1", but Company is <blank>
        // [SCENARIO 265991] Failure is registered in Activity Log
        PrepareExchangeSyncAndDeleteAllActivity(ExchangeSync);

        // [GIVEN] Two Contacts with Type = Company and Name = "Company Name" = "C"
        // [GIVEN] Contact "C1" with Type = Person, "Company Name" = "C" and e-mail = "p1@microsoft.com"
        PrepareExchangeContactWithCompanyName(ExchangeContact, PrepareTwoSimilarContactsWithTypeCompany);

        // [GIVEN] Contact "C2" with Type = Person
        PrepareContactWithType(Contact, Contact.Type::Person, '');

        // [WHEN] Transfer "C1" to "C2" via O365 Contact Sync. Helper func TransferExchangeContactToNavContact
        O365ContactSyncHelper.TransferExchangeContactToNavContact(ExchangeContact, Contact, ExchangeSync);

        // [THEN] Contact "C2" has Company = <blank>
        // [THEN] Contact "C2" has same Type, E-Mail and Name as "C1"
        VerifyImportedContact(Contact, ExchangeContact.Name, ExchangeContact."E-Mail", ExchangeContact.Type, '', '');

        // [THEN] Activity log has Failed contact synchronization Activity with Message = 'The Exchange Company Name is not unique in your company. p1@microsoft.com'
        VerifyActivityLog(ExchangeSync.RecordId, ExchangeSync."User ID", Contact.FieldCaption("Company Name"), ExchangeContact."E-Mail");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TransferBookingContactWhenCompanyNameNotUnique()
    var
        ExchangeSync: Record "Exchange Sync";
        ExchangeContact: Record Contact;
        Contact: Record Contact;
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
    begin
        // [SCENARIO 265991] When two Contacts type Company with same Company Name = "C" present and Contact "C1" with type Person and Company "C" is transferred to Contact "C2" with same Type
        // [SCENARIO 265991] via O365 Contact Sync. Helper func TransferBookingContactToNavContact, then Contact "C2" has same Type and E-Mail as "C1", but Name and Company are <blank>
        // [SCENARIO 265991] Failure is registered in Activity Log
        PrepareExchangeSyncAndDeleteAllActivity(ExchangeSync);

        // [GIVEN] Two Contacts with Type = Company and Name = "Company Name" = "C"
        // [GIVEN] Contact "C1" with Type = Person, "Company Name" = "C" and e-mail = "p1@microsoft.com"
        PrepareExchangeContactWithCompanyName(ExchangeContact, PrepareTwoSimilarContactsWithTypeCompany);

        // [GIVEN] Contact "C2" with Type = Person
        PrepareContactWithType(Contact, Contact.Type::Person, '');

        // [WHEN] Transfer "C1" to "C2" via O365 Contact Sync. Helper func TransferBookingContactToNavContact
        O365ContactSyncHelper.TransferBookingContactToNavContact(ExchangeContact, Contact);

        // [THEN] Contact "C2" has Name = <blank> and Company = <blank>
        // [THEN] Contact "C2" has same Type and E-Mail as "C1"
        VerifyImportedContact(Contact, '', ExchangeContact."E-Mail", ExchangeContact.Type, '', '');

        // [THEN] Activity log has Failed contact synchronization Activity with Message = 'The Exchange Company Name is not unique in your company. p1@microsoft.com'
        VerifyActivityLog(ExchangeSync.RecordId, ExchangeSync."User ID", Contact.FieldCaption("Company Name"), ExchangeContact."E-Mail");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TransferExchangeContactToCompanyWhenCompanyNameNotUnique()
    var
        ExchangeSync: Record "Exchange Sync";
        ExchangeContact: Record Contact;
        Contact: Record Contact;
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
    begin
        // [SCENARIO 265991] When two Contacts type Company with same Company Name = "C" present and Contact "C1" with type Person and Company "C" is transferred to Contact "C2" with type Company
        // [SCENARIO 265991] via O365 Contact Sync. Helper func TransferExchangeContactToNavContact, then Contact "C2" has same E-Mail and Name as "C1", but Type and Company differ
        // [SCENARIO 265991] Failure is registered in Activity Log
        PrepareExchangeSyncAndDeleteAllActivity(ExchangeSync);

        // [GIVEN] Two Contacts with Type = Company and Name = "Company Name" = "C"
        // [GIVEN] Contact "C1" with Type = Person, Name = "X", "Company Name" = "C" and e-mail = "p1@microsoft.com"
        PrepareExchangeContactWithCompanyName(ExchangeContact, PrepareTwoSimilarContactsWithTypeCompany);

        // [GIVEN] Contact "C2" with Type = Company
        PrepareContactWithType(Contact, Contact.Type::Company, '');

        // [WHEN] Transfer "C1" to "C2" via O365 Contact Sync. Helper func TransferExchangeContactToNavContact
        O365ContactSyncHelper.TransferExchangeContactToNavContact(ExchangeContact, Contact, ExchangeSync);

        // [THEN] Contact "C2" has Type = Company, Company No. = "C2", "Company Name" = "X"
        // [THEN] Contact "C2" has same E-Mail and Name as "C1"
        VerifyImportedContact(
          Contact, ExchangeContact.Name, ExchangeContact."E-Mail", Contact.Type::Company, Contact."No.", ExchangeContact.Name);

        // [THEN] Activity log has Failed contact synchronization Activity with Message = 'The Exchange Company Name is not unique in your company. p1@microsoft.com'
        VerifyActivityLog(ExchangeSync.RecordId, ExchangeSync."User ID", Contact.FieldCaption("Company Name"), ExchangeContact."E-Mail");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TransferBookingContactToCompanyWhenCompanyNameNotUnique()
    var
        ExchangeSync: Record "Exchange Sync";
        ExchangeContact: Record Contact;
        Contact: Record Contact;
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
    begin
        // [SCENARIO 265991] When two Contacts type Company with same Company Name = "C" present and Contact "C1" with type Person and Company "C" is transferred to Contact "C2" with type Company
        // [SCENARIO 265991] via O365 Contact Sync. Helper func TransferBookingContactToNavContact, then Contact "C2" has same E-Mail as "C1", but Type, Company and Name differ
        // [SCENARIO 265991] Failure is registered in Activity Log
        PrepareExchangeSyncAndDeleteAllActivity(ExchangeSync);

        // [GIVEN] Two Contacts with Type = Company and Name = "Company Name" = "C"
        // [GIVEN] Contact "C1" with Type = Person, Name = "X", "Company Name" = "C" and e-mail = "p1@microsoft.com"
        PrepareExchangeContactWithCompanyName(ExchangeContact, PrepareTwoSimilarContactsWithTypeCompany);

        // [GIVEN] Contact "C2" with Type = Company
        PrepareContactWithType(Contact, Contact.Type::Company, '');

        // [WHEN] Transfer "C1" to "C2" via O365 Contact Sync. Helper func TransferBookingContactToNavContact
        O365ContactSyncHelper.TransferBookingContactToNavContact(ExchangeContact, Contact);

        // [THEN] Contact "C2" has Type = Company, Company No. = "C2", Name = <blank> and "Company Name" = <blank>
        // [THEN] Contact "C2" has same E-Mail as "C1"
        VerifyImportedContact(Contact, '', ExchangeContact."E-Mail", Contact.Type::Company, Contact."No.", '');

        // [THEN] Activity log has Failed contact synchronization Activity with Message = 'The Exchange Company Name is not unique in your company. p1@microsoft.com'
        VerifyActivityLog(ExchangeSync.RecordId, ExchangeSync."User ID", Contact.FieldCaption("Company Name"), ExchangeContact."E-Mail");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferExchangeContact()
    var
        DummyExchangeSync: Record "Exchange Sync";
        ExchangeContact: Record Contact;
        Contact: Record Contact;
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
    begin
        // [SCENARIO 265991] When Contact "C1" with type Person and <non-blank> Company is transferred to Contact "C2" with same Type via O365 Contact Sync. Helper func TransferExchangeContactToNavContact,
        // [SCENARIO 265991] Then Contact "C2" has same Type, E-Mail, Name and Company as "C1"

        // [GIVEN] Contact "C1" with Type = Person, Company = "C" and e-mail = "p1@microsoft.com"
        PrepareExchangeContactWithCompany(ExchangeContact, LibraryUtility.GenerateGUID);

        // [GIVEN] Contact "C2" with Type = Person
        PrepareContactWithType(Contact, Contact.Type::Person, '');

        // [WHEN] Transfer "C1" to "C2" via O365 Contact Sync. Helper func TransferExchangeContactToNavContact
        O365ContactSyncHelper.TransferExchangeContactToNavContact(ExchangeContact, Contact, DummyExchangeSync);

        // [THEN] Contact "C2" has same Type, E-Mail, Name and Company as "C1"
        VerifyImportedContact(
          Contact, ExchangeContact.Name, ExchangeContact."E-Mail", ExchangeContact.Type, ExchangeContact."Company No.",
          ExchangeContact."Company Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferBookingContact()
    var
        ExchangeContact: Record Contact;
        Contact: Record Contact;
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
    begin
        // [SCENARIO 265991] When Contact "C1" with type Person and <non-blank> Company is transferred to Contact "C2" with same Type via O365 Contact Sync. Helper func TransferBookingContactToNavContact,
        // [SCENARIO 265991] Then Contact "C2" has same Type, E-Mail, Name and Company as "C1"

        // [GIVEN] Contact "C1" with Type = Person, Company = "C" and e-mail = "p1@microsoft.com"
        PrepareExchangeContactWithCompany(ExchangeContact, LibraryUtility.GenerateGUID);

        // [GIVEN] Contact "C2" with Type = Person
        PrepareContactWithType(Contact, Contact.Type::Person, '');

        // [WHEN] Transfer "C1" to "C2" via O365 Contact Sync. Helper func TransferBookingContactToNavContact
        O365ContactSyncHelper.TransferBookingContactToNavContact(ExchangeContact, Contact);

        // [THEN] Contact "C2" has same Type, E-Mail and Company as "C1"
        // [THEN] Contact "C2" has Name = <blank>
        VerifyImportedContact(
          Contact, '', ExchangeContact."E-Mail", ExchangeContact.Type, ExchangeContact."Company No.",
          ExchangeContact."Company Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferExchangeContactToCompany()
    var
        DummyExchangeSync: Record "Exchange Sync";
        ExchangeContact: Record Contact;
        Contact: Record Contact;
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
    begin
        // [SCENARIO 265991] When Contact "C1" with type Person and <non-blank> Company is transferred to Contact "C2" with type Company via O365 Contact Sync. Helper func TransferExchangeContactToNavContact,
        // [SCENARIO 265991] Then Contact "C2" has same Type, E-Mail, Name and Company as "C1"

        // [GIVEN] Contact "C1" with Type = Person, Company = "C" and e-mail = "p1@microsoft.com"
        PrepareExchangeContactWithCompany(ExchangeContact, LibraryUtility.GenerateGUID);

        // [GIVEN] Contact "C2" with Type = Company
        PrepareContactWithType(Contact, Contact.Type::Company, '');

        // [WHEN] Transfer "C1" to "C2" via O365 Contact Sync. Helper func TransferExchangeContactToNavContact
        O365ContactSyncHelper.TransferExchangeContactToNavContact(ExchangeContact, Contact, DummyExchangeSync);

        // [THEN] Contact "C2" has same Type, E-Mail, Name and Company as "C1"
        VerifyImportedContact(
          Contact, ExchangeContact.Name, ExchangeContact."E-Mail", ExchangeContact.Type, ExchangeContact."Company No.",
          ExchangeContact."Company Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferBookingContactToCompany()
    var
        ExchangeContact: Record Contact;
        Contact: Record Contact;
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
    begin
        // [SCENARIO 265991] When Contact "C1" with type Person and <non-blank> Company is transferred to Contact "C2" with type Company via O365 Contact Sync. Helper func TransferBookingContactToNavContact,
        // [SCENARIO 265991] Then Error happens "Type must be equal to 'Person'  in Contact: No.="C2". Current value is 'Company'."

        // [GIVEN] Contact "C1" with Type = Person, Company = "C" and e-mail = "p1@microsoft.com"
        PrepareExchangeContactWithCompany(ExchangeContact, LibraryUtility.GenerateGUID);

        // [GIVEN] Contact "C2" with Type = Company
        PrepareContactWithType(Contact, Contact.Type::Company, '');

        // [WHEN] Transfer "C1" to "C2" via O365 Contact Sync. Helper func TransferBookingContactToNavContact
        asserterror O365ContactSyncHelper.TransferBookingContactToNavContact(ExchangeContact, Contact);

        // [THEN] Then Error happens "Type must be equal to 'Person'  in Contact: No.="C2". Current value is 'Company'."
        Assert.ExpectedError(
          StrSubstNo(
            ContactCompanyNameValidateErr, ExchangeContact.Type, Contact.TableCaption, Contact.FieldCaption("No."), Contact."No.",
            Contact.Type));
        Assert.ExpectedErrorCode(TestFieldErr);
    end;

    local procedure Initialize()
    var
        ExchangeSync: Record "Exchange Sync";
        ExchangeContact: Record "Exchange Contact";
        Contact: Record Contact;
    begin
        LibraryO365Sync.SetupNavUser;

        Contact.DeleteAll();

        LibraryO365Sync.SetupExchangeSync(ExchangeSync);

        DeleteAllExchangeContacts(ExchangeContact, ExchangeSync);
        InitializeExchangeContactsThatWontSync(ExchangeSync);

        if not Territory.Get('Terr1') then begin
            Territory.Init();
            Territory.Code := 'Terr1';
            Territory.Insert();
        end;

        if not SalespersonPurchaser.Get('SP') then begin
            SalespersonPurchaser.Init();
            SalespersonPurchaser.Code := 'SP';
            SalespersonPurchaser.Insert();
        end;
        if not CountryRegion.Get('1') then begin
            CountryRegion.Init();
            CountryRegion.Code := '1';
            CountryRegion.Name := Company1Txt;
            CountryRegion.Insert();
        end;

        CreateCompanyContact;
        CreateContactPriorToLastSyncDate;
        CreateContactWithSalesTerritory;
        CreateContactWithSalesPerson;
        CreateContactWithSameEmail;

        // Clean up the sync records - each test will configure its own, since we need to also test specific sync record configurations
        ExchangeSync.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure InitializeExchangeContacts(var ExchangeSync: Record "Exchange Sync")
    var
        ExchangeContact: Record "Exchange Contact";
        LocalConnectionID: Guid;
    begin
        LibraryO365Sync.SetupExchangeTableConnection(ExchangeSync, LocalConnectionID);

        CreateExchangeContact1(ExchangeContact);
        CreateExchangeContactWithSameEmail(ExchangeContact);
        CreateExchangeContactWithSameEmailAfterLastSync(ExchangeContact);

        UnregisterTableConnection(TABLECONNECTIONTYPE::Exchange, LocalConnectionID)
    end;

    [Scope('OnPrem')]
    procedure InitializeExchangeContactsThatWontSync(var ExchangeSync: Record "Exchange Sync")
    var
        ExchangeContact: Record "Exchange Contact";
        LocalConnectionID: Guid;
    begin
        LibraryO365Sync.SetupExchangeTableConnection(ExchangeSync, LocalConnectionID);

        // Check to see if the contact already exists, don't recreate it if we don't need to.
        if not ExchangeContact.Get(O365Email1emailcomNoSyncTxt) then
            CreateExchangeContactThatWontSync;

        UnregisterTableConnection(TABLECONNECTIONTYPE::Exchange, LocalConnectionID);
    end;

    [Scope('OnPrem')]
    procedure TearDown()
    var
        ExchangeSync: Record "Exchange Sync";
        Contact: Record Contact;
    begin
        Contact.DeleteAll();
        Territory.Delete();
        SalespersonPurchaser.Delete();
        ExchangeSync.DeleteAll();
        CountryRegion.Delete();
    end;

    local procedure PrepareExchangeContactWithCompanyName(var Contact: Record Contact; CompanyName: Text[50])
    begin
        Contact."No." := '';
        CreateContact(Contact);
        Contact.Validate("Company Name", CompanyName);
        Contact.Insert(true);
    end;

    local procedure PrepareExchangeContactWithCompany(var Contact: Record Contact; CompanyName: Text[50])
    begin
        PrepareContactWithType(Contact, Contact.Type::Company, CompanyName);
        PrepareExchangeContactWithCompanyName(Contact, CompanyName);
    end;

    local procedure PrepareContactWithType(var Contact: Record Contact; ContactType: Integer; ContactName: Text[50])
    begin
        Contact.Init();
        Contact."No." := '';
        Contact.Validate(Type, ContactType);
        Contact.Validate(Name, ContactName);
        Contact.Insert(true);
    end;

    local procedure PrepareTwoSimilarContactsWithTypeCompany(): Text[50]
    var
        Contact: Record Contact;
        CompanyName: Text[50];
    begin
        CompanyName := LibraryUtility.GenerateGUID;
        PrepareContactWithType(Contact, Contact.Type::Company, CompanyName);
        PrepareContactWithType(Contact, Contact.Type::Company, CompanyName);
        exit(CompanyName);
    end;

    local procedure PrepareExchangeSyncAndDeleteAllActivity(var ExchangeSync: Record "Exchange Sync")
    var
        ActivityLog: Record "Activity Log";
    begin
        LibraryO365Sync.SetupExchangeSync(ExchangeSync);
        ActivityLog.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure FindNavContact(Email: Text[80]; var Contact: Record Contact): Boolean
    begin
        Contact.Init();
        Contact.SetRange("E-Mail", Email);
        if Contact.FindFirst then
            exit(true);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure DeleteNavContact(Email: Text[80])
    var
        LocalContact: Record Contact;
    begin
        LocalContact.Init();
        LocalContact.SetRange("E-Mail", Email);
        if LocalContact.FindFirst then
            LocalContact.Delete();
    end;

    [Scope('OnPrem')]
    procedure FindExchangeContact(Email: Text[80]; var ExchangeContact: Record "Exchange Contact"): Boolean
    begin
        if ExchangeContact.Get(Email) then
            exit(true);
    end;

    [Scope('OnPrem')]
    procedure DeleteExchangeContact(Email: Text[80])
    var
        ExchangeContact: Record "Exchange Contact";
    begin
        if ExchangeContact.Get(Email) then
            ExchangeContact.Delete();
    end;

    [Normal]
    local procedure CreateContact(var Contact: Record Contact)
    var
        UtcDateTime: DateTime;
    begin
        Contact.Validate(Type, Contact.Type::Person);
        Contact.Validate("First Name", FirstName1Txt);
        Contact.Validate("Middle Name", MiddleName1Txt);
        Contact.Validate(Surname, SurName1Txt);
        Contact.Validate(Initials, Intials1Txt);
        Contact.Validate("Post Code", PostCode1Txt);
        Contact.Validate("E-Mail", NavEmail1emailcomTxt);
        Contact.Validate("E-Mail 2", NavEmail12emailcomTxt);
        Contact.Validate("Home Page", HomePage1Txt);
        Contact.Validate("Phone No.", Phone1Txt);
        Contact.Validate("Mobile Phone No.", Phone11Txt);
        Contact.Validate("Fax No.", Fax1Txt);
        Contact.Validate(Address, Address1Txt);
        Contact.Validate(City, City1Txt);
        UtcDateTime := GetUtcDateTime(CreateDateTime(Today + 1, Time));
        Contact.Validate("Last Date Modified", DT2Date(UtcDateTime));
        Contact.Validate("Last Time Modified", DT2Time(UtcDateTime));
        Contact.Validate("Territory Code", Territory.Code);
        Contact.Validate("Job Title", JobTitleTxt);
        Contact.Validate(County, StateTxt);
    end;

    [Normal]
    local procedure CreateContactWithCompany(var Contact: Record Contact)
    begin
        CreateContact(Contact);
        Contact.Validate("Company Name", Company1Txt);
    end;

    [Scope('OnPrem')]
    procedure CreateContactWithSalesTerritory()
    var
        Contact: Record Contact;
    begin
        // This contact should sync as it is a person with an assigned TerritoryCode.
        if Contact.Get('1') then
            exit;

        Contact.Init();
        Contact."No." := '1';

        CreateContactWithCompany(Contact);
        Contact.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateContactWithSalesTerritoryDuplicate()
    var
        Contact: Record Contact;
    begin
        // This contact should not sync as it has same email address.
        if Contact.Get('6') then
            exit;

        Contact.Init();
        Contact."No." := '6';

        CreateContactWithCompany(Contact);
        Contact.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateContactPriorToLastSyncDate()
    var
        Contact: Record Contact;
        UtcDateTime: DateTime;
    begin
        if Contact.Get('5') then
            exit;

        Contact.Init();
        CreateContactWithCompany(Contact);
        Contact."No." := '5';

        Contact.Validate("E-Mail", NavEmailContact5Txt);
        Contact.Validate("First Name", O365FirstName3Txt);

        UtcDateTime := GetUtcDateTime(CreateDateTime(CalcDate('<CD-5D>', Today), Time));
        Contact.Validate("Last Date Modified", DT2Date(UtcDateTime));
        Contact.Validate("Last Time Modified", DT2Time(UtcDateTime));

        Contact.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCompanyContact()
    var
        Contact: Record Contact;
    begin
        // This record should not sync as it a Company.
        if Contact.Get('2') then
            exit;

        Contact.Init();
        Contact."No." := '2';
        CreateContact(Contact);
        Contact.Validate(Type, Contact.Type::Company);
        Contact.Validate(Name, Company1Txt);
        Contact.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateContactWithSalesPerson()
    var
        Contact: Record Contact;
    begin
        // This record should not sync as it does not have a Territory Code.
        if Contact.Get('3') then
            exit;

        Contact.Init();
        Contact."No." := '3';
        CreateContactWithCompany(Contact);
        Contact.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Contact.Validate("E-Mail", NavEmail3emailcomTxt);
        Contact.Validate("Territory Code", '');

        Contact.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateContactWithSameEmail()
    var
        Contact: Record Contact;
        UtcDateTime: DateTime;
    begin
        // This record should sync and overwrite the exchange properties.
        if Contact.Get('4') then
            exit;

        Contact.Init();
        Contact."No." := '4';
        CreateContactWithCompany(Contact);
        Contact.Validate("First Name", FirstName4Txt);
        Contact.Validate("Middle Name", MiddleName4Txt);
        Contact.Validate(Surname, SurName4Txt);
        Contact.Validate(Initials, Intials4Txt);

        // Note this is the same email as ContactWithSameEmail
        Contact.Validate("E-Mail", NavEmail4emailcomTxt);
        UtcDateTime := GetUtcDateTime(CreateDateTime(Today, Time + 360000));
        Contact.Validate("Last Date Modified", DT2Date(UtcDateTime));
        Contact.Validate("Last Time Modified", DT2Time(UtcDateTime));
        Contact.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateExchangeContact1(var ExchangeContact: Record "Exchange Contact")
    begin
        if ExchangeContact.Get(O365Email1emailcomTxt) then begin
            ExchangeContact.Modify(true);
            exit;
        end;

        // This record should sync
        ExchangeContact.Init();
        ExchangeContact.Validate(GivenName, O365FirstName1Txt);
        ExchangeContact.Validate(MiddleName, O365MiddleName1Txt);
        ExchangeContact.Validate(Surname, O365SurName1Txt);
        ExchangeContact.Validate(Initials, O365Initials1Txt);
        ExchangeContact.Validate(EMailAddress1, O365Email1emailcomTxt);
        ExchangeContact.Validate(EMailAddress2, O365Email12emailcomTxt);
        ExchangeContact.Validate(CompanyName, Company1Txt);
        ExchangeContact.Validate(BusinessHomePage, O365BusinessHomePage1Txt);
        ExchangeContact.Validate(BusinessPhone1, O365Phone1Txt);
        ExchangeContact.Validate(MobilePhone, O365Phone12Txt);
        ExchangeContact.Validate(BusinessFax, O365Phone13Txt);
        ExchangeContact.Validate(Street, O365Street1Txt);
        ExchangeContact.Validate(City, O365City1Txt);
        ExchangeContact.Validate(JobTitle, JobTitleTxt);
        ExchangeContact.Validate(State, StateTxt);
        ExchangeContact.Validate(PostalCode, O365PostalCode1Txt);
        ExchangeContact.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateExchangeContactThatWontSync()
    var
        ExchangeContact: Record "Exchange Contact";
    begin
        if ExchangeContact.Get(O365Email1emailcomNoSyncTxt) then begin
            ExchangeContact.Modify(true);
            exit;
        end;

        // This record should not sync as we will create it before last sync date time.
        ExchangeContact.Init();
        ExchangeContact.Validate(GivenName, O365FirstName1Txt);
        ExchangeContact.Validate(MiddleName, O365MiddleName1Txt);
        ExchangeContact.Validate(Surname, O365SurName1Txt);
        ExchangeContact.Validate(Initials, O365Initials1Txt);
        ExchangeContact.Validate(EMailAddress1, O365Email1emailcomNoSyncTxt);
        ExchangeContact.Validate(EMailAddress2, O365Email12emailcomTxt);
        ExchangeContact.Validate(CompanyName, Company1Txt);
        ExchangeContact.Validate(BusinessHomePage, O365BusinessHomePage1Txt);
        ExchangeContact.Validate(BusinessPhone1, O365Phone1Txt);
        ExchangeContact.Validate(MobilePhone, O365Phone12Txt);
        ExchangeContact.Validate(BusinessFax, O365Phone13Txt);
        ExchangeContact.Validate(Street, O365Street1Txt);
        ExchangeContact.Validate(City, O365City1Txt);
        ExchangeContact.Validate(PostalCode, O365PostalCode1Txt);
        ExchangeContact.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateExchangeContactWithSameEmail(var ExchangeContact: Record "Exchange Contact")
    begin
        if ExchangeContact.Get(NavEmail4emailcomTxt) then begin
            ExchangeContact.Modify(true);
            exit;
        end;

        // Note this is the same email as ContactWithSameEmail
        ExchangeContact.Init();
        ExchangeContact.Validate(EMailAddress1, NavEmail4emailcomTxt);
        ExchangeContact.Validate(GivenName, O365FirstName3Txt);
        ExchangeContact.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateExchangeContactWithSameEmailAfterLastSync(var ExchangeContact: Record "Exchange Contact")
    begin
        if ExchangeContact.Get(NavEmailContact5Txt) then begin
            ExchangeContact.Modify(true);
            exit;
        end;

        // Note this is the same email as ContactPriorToLastSyncDate
        ExchangeContact.Init();
        ExchangeContact.Validate(EMailAddress1, NavEmailContact5Txt);
        ExchangeContact.Validate(GivenName, O365FirstName3Txt);
        ExchangeContact.Insert(true);
    end;

    local procedure VerifyImportedContact(var ImportedContact: Record Contact; Name: Text[100]; Email: Text[80]; Type: Integer; CompanyNo: Code[20]; CompanyName: Text[100])
    begin
        Assert.AreEqual(Type, ImportedContact.Type, '');
        Assert.AreEqual(Email, ImportedContact."E-Mail", '');
        Assert.AreEqual(Name, ImportedContact.Name, '');
        Assert.AreEqual(CompanyNo, ImportedContact."Company No.", '');
        Assert.AreEqual(CompanyName, ImportedContact."Company Name", '');
    end;

    local procedure VerifyActivityLog(RecordId: RecordID; UserId: Code[50]; CompanyNameCptn: Text; Email: Text[80])
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.SetRange("Record ID", RecordId);
        ActivityLog.SetRange("User ID", UserId);
        ActivityLog.SetRange(Status, ActivityLog.Status::Failed);
        ActivityLog.SetRange(Context, ContextTxt);
        ActivityLog.SetRange(Description, StrSubstNo(DescriptionTxt, CompanyNameCptn));
        ActivityLog.SetRange("Activity Message", StrSubstNo(ActivityMessageTxt, CompanyNameCptn, Email));
        Assert.RecordCount(ActivityLog, 1);
    end;

    [Scope('OnPrem')]
    procedure Validate0365Email1(var Contact: Record Contact)
    begin
        Assert.AreEqual(O365FirstName1Txt, Contact."First Name", 'Unexpected First Name for Exchange Contact 1');
        Assert.AreEqual(O365MiddleName1Txt, Contact."Middle Name", 'Unexpected Middle Name for Exchange Contact 1');
        Assert.AreEqual(O365SurName1Txt, Contact.Surname, 'Unexpected Surname Name for Exchange Contact 1');
        Assert.AreEqual(O365Initials1Txt, Contact.Initials, 'Unexpected Initials for Exchange Contact 1');
        Assert.AreEqual(UpperCase(O365PostalCode1Txt), Contact."Post Code", 'Unexpected Postal Code for Exchange Contact 1');
        Assert.AreEqual(O365Email12emailcomTxt, Contact."E-Mail 2", 'Unexpected Email2 for Exchange Contact 1');
        Assert.AreEqual(Company1Txt, Contact."Company Name", 'Unexpected CompanyName for Exchange Contact 1');
        Assert.AreEqual(O365BusinessHomePage1Txt, Contact."Home Page", 'Unexpected Home Page for Exchange Contact 1');
        Assert.AreEqual(O365Phone1Txt, Contact."Phone No.", 'Unexpected Phone No for Exchange Contact 1');
        Assert.AreEqual(O365Phone12Txt, Contact."Mobile Phone No.", 'Unexpected Mobile Phone No for Exchange Contact 1');
        Assert.AreEqual(O365Phone13Txt, Contact."Fax No.", 'Unexpected Fax No for Exchange Contact 1');
        Assert.AreEqual(O365Street1Txt, Contact.Address, 'Unexpected Address for Exchange Contact 1');
        Assert.AreEqual(O365City1Txt, Contact.City, 'Unexpected City for Exchange Contact 1');
        Assert.AreEqual(JobTitleTxt, Contact."Job Title", 'Unexpected Job Title for Exchange Contact 1');
        Assert.AreEqual(StateTxt, Contact.County, 'Unexpected State for Exchange Contact 1');
    end;

    [Scope('OnPrem')]
    procedure ValidateNavEmail1(var ExchangeContact: Record "Exchange Contact")
    begin
        Assert.AreEqual(FirstName1Txt, ExchangeContact.GivenName, 'Unexpected GivenName for NavContact1');
        Assert.AreEqual(MiddleName1Txt, ExchangeContact.MiddleName, 'Unexpected MiddleName for NavContact1');
        Assert.AreEqual(SurName1Txt, ExchangeContact.Surname, 'Unexpected Surname for NavContact1');
        Assert.AreEqual(Intials1Txt, ExchangeContact.Initials, 'Unexpected Initials for NavContact1');
        Assert.AreEqual(UpperCase(PostCode1Txt), ExchangeContact.PostalCode, 'Unexpected PostalCode for NavContact1');
        Assert.AreEqual(NavEmail12emailcomTxt, ExchangeContact.EMailAddress2, 'Unexpected EMailAddress2 for NavContact1');
        Assert.AreEqual(Company1Txt, ExchangeContact.CompanyName, 'Unexpected CompanyName for NavContact1');
        Assert.AreEqual(HomePage1Txt, ExchangeContact.BusinessHomePage, 'Unexpected BusinessHomePage for NavContact1');
        Assert.AreEqual(Phone1Txt, ExchangeContact.BusinessPhone1, 'Unexpected Phone1 for NavContact1');
        Assert.AreEqual(Phone11Txt, ExchangeContact.MobilePhone, 'Unexpected Phone2 for NavContact1');
        Assert.AreEqual(Fax1Txt, ExchangeContact.BusinessFax, 'Unexpected Phone3 for NavContact1');
        Assert.AreEqual(Address1Txt, Rtrim(ExchangeContact.Street), 'Unexpected Street for NavContact1');
        Assert.AreEqual(City1Txt, ExchangeContact.City, 'Unexpected Street for NavContact1');
        Assert.AreEqual(JobTitleTxt, ExchangeContact.JobTitle, 'Unexpected Job Title for NavContact1');
        Assert.AreEqual(StateTxt, ExchangeContact.State, 'Unexpected State for NavContact1');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [FilterPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandler(var ContactRecordRef: RecordRef): Boolean
    var
        Contact: Record Contact;
    begin
        ContactRecordRef.GetTable(Contact);
        Contact.SetFilter("Territory Code", 'Terr1');
        ContactRecordRef.SetView(Contact.GetView);
        exit(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure OpenExchangeSyncSetupHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := Question = SetupO365Qst;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ConnectionSuccessfulMessageHandler(Message: Text)
    begin
        if Message <> ConnectionSuccessMsg then
            Error(UnexpectedMessageErr, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExchangeSyncSetupPageHandler(var ExchangeSyncSetup: TestPage "Exchange Sync. Setup")
    begin
        Assert.AreNotEqual(ExchangeSyncSetup."User ID".Value, '', 'Expected page to be opened.');
        ExchangeSyncSetup.ExchangeAccountPasswordTemp.Value := PasswordTxt;
    end;

    [Scope('OnPrem')]
    procedure ValidateResults()
    var
        LocalNavContact: Record Contact;
    begin
        Assert.IsTrue(
          FindNavContact(O365Email1emailcomTxt, LocalNavContact), StrSubstNo('Expected Contact with email %1', O365Email1emailcomTxt));
        Validate0365Email1(LocalNavContact);

        Clear(LocalNavContact);
        Assert.IsTrue(
          FindNavContact(NavEmail4emailcomTxt, LocalNavContact), StrSubstNo('Expected Contact with email %1', NavEmail4emailcomTxt));
        Assert.AreEqual(FirstName4Txt, LocalNavContact."First Name", 'Unexpected First Name for Nav Contact 4');
        Assert.AreEqual(Territory.Code, LocalNavContact."Territory Code", 'Unexpected Territory Code for Nav Contact 4');

        Clear(LocalNavContact);
        Assert.IsTrue(
          FindNavContact(NavEmailContact5Txt, LocalNavContact), StrSubstNo('Expected Contact with email %1', NavEmail5emailcomTxt));
        Assert.AreEqual(O365FirstName3Txt, LocalNavContact."First Name", 'Unexpected First Name for Nav Contact 5');
        Assert.AreEqual(Territory.Code, LocalNavContact."Territory Code", 'Unexpected Territory Code for Nav Contact 5');

        Clear(LocalNavContact);
        Assert.IsFalse(FindNavContact(O365Email1emailcomNoSyncTxt, LocalNavContact),
          StrSubstNo('Unexpected Contact with email %1', O365Email1emailcomNoSyncTxt));

        Validate;

        TearDown;
    end;

    [Scope('OnPrem')]
    procedure ValidateSyncAllResults()
    var
        LocalNavContact: Record Contact;
    begin
        Assert.IsTrue(
          FindNavContact(O365Email1emailcomTxt, LocalNavContact), StrSubstNo('Expected Contact with email %1', O365Email1emailcomTxt));
        Validate0365Email1(LocalNavContact);

        Clear(LocalNavContact);
        Assert.IsTrue(
          FindNavContact(NavEmail4emailcomTxt, LocalNavContact), StrSubstNo('Expected Contact with email %1', NavEmail4emailcomTxt));
        Assert.AreEqual(FirstName4Txt, LocalNavContact."First Name", 'Unexpected First Name for Nav Contact 4');
        Assert.AreEqual(Territory.Code, LocalNavContact."Territory Code", 'Unexpected Territory Code for Nav Contact 4');

        Clear(LocalNavContact);
        Assert.IsTrue(
          FindNavContact(NavEmailContact5Txt, LocalNavContact), StrSubstNo('Expected Contact with email %1', NavEmail5emailcomTxt));
        Assert.AreEqual(O365FirstName3Txt, LocalNavContact."First Name", 'Unexpected First Name for Nav Contact 5');
        Assert.AreEqual(Territory.Code, LocalNavContact."Territory Code", 'Unexpected Territory Code for Nav Contact 5');

        Clear(LocalNavContact);
        Assert.IsTrue(FindNavContact(O365Email1emailcomNoSyncTxt, LocalNavContact),
          'Expected Contact with email O365EmailNoSync1@email.com');

        Validate;

        TearDown;

        DeleteNavContact(O365Email1emailcomNoSyncTxt);
    end;

    [Scope('OnPrem')]
    procedure Validate()
    var
        ExchangeSync: Record "Exchange Sync";
        ExchangeContact: Record "Exchange Contact";
        O365SyncManagement: Codeunit "O365 Sync. Management";
        LocalConnectionID: Text;
        LocalConnectionString: Text;
    begin
        LocalConnectionID := CreateGuid;
        ExchangeSync.Get(UserId);
        LocalConnectionString := O365SyncManagement.BuildExchangeConnectionString(ExchangeSync);
        RegisterTableConnection(TABLECONNECTIONTYPE::Exchange, LocalConnectionID, LocalConnectionString);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::Exchange, LocalConnectionID);

        Assert.IsTrue(
          FindExchangeContact(NavEmail1emailcomTxt, ExchangeContact),
          StrSubstNo('Expected Exchange Contact with email %1', NavEmail1emailcomTxt));
        ValidateNavEmail1(ExchangeContact);

        Assert.IsTrue(
          FindExchangeContact(NavEmail4emailcomTxt, ExchangeContact),
          StrSubstNo('Expected Exchange Contact with email %1', NavEmail4emailcomTxt));
        Assert.AreEqual(FirstName4Txt, ExchangeContact.GivenName, 'Unexpected First Name for Nav Contact 4');

        UnregisterTableConnection(TABLECONNECTIONTYPE::Exchange, LocalConnectionID);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ActivityLogHandler(var ActivityLog: TestPage "Activity Log")
    begin
        ActivityLog.First;
        Assert.AreEqual(CreateExchangeContactTxt, ActivityLog.Description.Value, 'Unexpected activity message');
        ActivityLog.OK.Invoke;
    end;

    [Scope('OnPrem')]
    procedure Rtrim(InString: Text) OutString: Text
    var
        LineFeedPos: Integer;
        LineFeed: Char;
    begin
        LineFeed := 10;
        LineFeedPos := StrPos(InString, Format(LineFeed));
        OutString := InString;
        if LineFeedPos > 0 then
            OutString := CopyStr(InString, 1, LineFeedPos - 1);
    end;

    local procedure GetUtcDateTime(LocatDateTime: DateTime): DateTime
    var
        DotNetDateTimeOffset: DotNet DateTimeOffset;
        DotNetDateTimeOffsetNow: DotNet DateTimeOffset;
    begin
        if LocatDateTime = CreateDateTime(0D, 0T) then
            exit(CreateDateTime(0D, 0T));

        DotNetDateTimeOffset := DotNetDateTimeOffset.DateTimeOffset(LocatDateTime);
        DotNetDateTimeOffsetNow := DotNetDateTimeOffset.Now;

        exit(DotNetDateTimeOffset.LocalDateTime - DotNetDateTimeOffsetNow.Offset);
    end;

    [Normal]
    local procedure DeleteAllExchangeContacts(var ExchangeContact: Record "Exchange Contact"; var ExchangeSync: Record "Exchange Sync")
    var
        ConnectionGUID: Guid;
    begin
        LibraryO365Sync.SetupExchangeTableConnection(ExchangeSync, ConnectionGUID);

        // Don't remove the 'no sync' record, this helps us better control sync times to ensure it doesn't sync
        ExchangeContact.SetFilter(EMailAddress1, StrSubstNo('<>%1', O365Email1emailcomNoSyncTxt));

        ExchangeContact.DeleteAll(true);
        UnregisterTableConnection(TABLECONNECTIONTYPE::Exchange, ConnectionGUID);
    end;
}

