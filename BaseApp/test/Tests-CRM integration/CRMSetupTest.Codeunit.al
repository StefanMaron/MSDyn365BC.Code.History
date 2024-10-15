codeunit 139160 "CRM Setup Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Connection Setup]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        URLNamePswNeededErr: Label 'A %1 URL, user name and password are required to enable a connection';
        ConnectionErr: Label 'The connection setup cannot be validated. Verify the settings and try again.';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        OnlyBasicAppAreaMsg: Label 'You do not have access to this page, because your experience is set to Basic.';
        UnfavorableCRMSolutionInstalledMsg: Label 'The %1 Integration Solution was not detected.';
        FavorableCRMSolutionInstalledMsg: Label 'The %1 Integration Solution is installed in %2.';
        WebClientUrlResetMsg: Label 'The %1 Web Client URL has been reset to the default value.';
        CurrentuserIsNotMappedToCRMUserMsg: Label 'the authentication email must match the primary email of a %1 user.', Comment = '%1 = Current User ID';
        ConnectionSuccessNotEnabledForCurrentUserMsg: Label '%2 integration is not enabled for %1.', Comment = '%1 = Current User ID';
        LCYMustMatchBaseCurrencyErr: Label 'LCY Code %1 does not match ISO Currency Code %2 of the CRM base currency.', Comment = '%1,%2 - ISO currency codes';
        CRMSetupTest: Codeunit "CRM Setup Test";
        JobQueueEntryStatusReadyErr: Label 'Job Queue Entry status should be Ready.';
        JobQueueEntryStatusOnHoldErr: Label 'Job Queue Entry status should be On Hold.';
        CRMSOIntegrationDisabledMsg: Label 'Sales Order Integration with %1 is disabled.';
        CRMProductName: Codeunit "CRM Product Name";
        SetupSuccessfulMsg: Label 'The default setup for %1 synchronization has completed successfully.';
        NotMatchCurrencyCodeErr: Label 'does not match ISO Currency Code';
        CRMIntegrationEnabledStateErr: Label 'CRMIntegrationEnabledState is wrong';
        ConnectionDisabledMsg: Label 'Connection to Dynamics 365 is broken and that it has been disabled due to an error: %1';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure NoCRMConnectionOnCompanyOpen()
    var
        LogInManagement: Codeunit LogInManagement;
    begin
        // [FEATURE] [LogIn]
        // [SCENARIO] On opening the company there should be no attempt to connect to CRM
        // [GIVEN] CRM Connection is set, but not registered
        Initialize;
        LibraryCRMIntegration.RegisterTestTableConnection;
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST');
        Assert.AreEqual('', GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM), 'Default CRM connection');

        // [WHEN] COD40.CompanyOpen
        LogInManagement.CompanyOpen;
        // [THEN] Should be no registered CRM connection
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, ''), 'Should be no <blank> connection');
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST'), 'Should be no TEST connection');
        Assert.AreEqual('', GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM), 'Default CRM connection');
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,HandleDataEncryptionManagementPage')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DataEncryptionMgtPageShownIfPwdFilled()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI] [Encryption]
        // [GIVEN] Encryption is disabled
        Initialize;
        // [GIVEN] CRM Connection is not enabled
        InitSetup(false, '');

        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit;
        // [WHEN] Enter a new Password
        CRMConnectionSetupPage.Password.SetValue('password');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleDataEncryptionManagementPage(var DataEncryptionManagementPage: TestPage "Data Encryption Management")
    begin
        Assert.IsFalse(DataEncryptionManagementPage.EncryptionEnabledState.AsBoolean, 'Encryption should be disabled on the page');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IsCRMIntegrationEnabled()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [CRM Integration Management]
        // [SCENARIO] IsCRMIntegrationEnabled() returns if CRM Integration is enabled
        Initialize;

        // [GIVEN] Disabled or Missing CRM Connection
        // [WHEN] Asking if CRM Integration Is Enabled
        // [THEN] Response is false
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM));
        Assert.IsFalse(CRMIntegrationManagement.IsCRMIntegrationEnabled, 'Did not expect integration to be enabled');

        LibraryCRMIntegration.CreateCRMConnectionSetup('', 'host', false);
        Assert.IsFalse(CRMIntegrationManagement.IsCRMIntegrationEnabled, 'Did not expect integration to be enabled');

        // [GIVEN] Enabled CRM Connection
        LibraryCRMIntegration.ResetEnvironment;
        // [GIVEN] CRM Connection is registered
        LibraryCRMIntegration.ConfigureCRM;
        // [WHEN] Asking if CRM Integration Is Enabled
        CRMIntegrationManagement.ClearState;
        Assert.IsTrue(
          CRMIntegrationManagement.IsCRMIntegrationEnabled,
          'Expected Integration to be enabled when a connection is enabled and registered.');
        // [THEN] Response is TRUE

        // [GIVEN] Enabled CRM Connection
        // [GIVEN] CRM Connection is not registered
        CRMConnectionSetup.Get;
        CRMConnectionSetup.TestField("Is Enabled", true);
        CRMConnectionSetup.UnregisterConnection;
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM));

        // [WHEN] Asking if CRM Integration Is Enabled
        CRMIntegrationManagement.ClearState;
        Assert.IsTrue(
          CRMIntegrationManagement.IsCRMIntegrationEnabled,
          'Expected Integration to be enabled when a connection is enabled but not registered.');
        // [THEN] Response is TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsCRMIntegrationEnabledValidConnectionFailedOnStart()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [CRM Integration Management] [Restore Connection]
        // [SCENARIO] IsCRMIntegrationEnabled() not enabled connection, if CRMConnectionSetup."Restore Connection" is 'Yes' and connection setup is valid, but failed.
        Initialize;

        // [GIVEN] Valid CRM Connection is disabled, "Restore Connection" is 'Yes'
        InitSetup(true, '');
        LibraryCRMIntegration.RegisterTestTableConnection;
        LibraryCRMIntegration.EnsureCRMSystemUser;
        LibraryCRMIntegration.CreateCRMOrganization;
        MockCRMConnectionSetupWithEnableValidConnection;

        // [GIVEN] "LCY Code" doesn't match ISO code og CRM base currency (cause failure on connection enabling)
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup."LCY Code" := 'XXX';
        GeneralLedgerSetup.Modify;

        // [WHEN] running IsCRMIntegrationEnabled()
        CRMIntegrationManagement.ClearState;
        asserterror CRMIntegrationManagement.IsCRMIntegrationEnabled;
        // [THEN] Runtime error on enabling connection: '...does not match ISO Currency Code...'
        Assert.ExpectedError(NotMatchCurrencyCodeErr);
        // [THEN] Response is 'Yes', "Is Enabled" is 'No', "Restore Connection" is 'No'
        CRMConnectionSetup.Get;
        CRMConnectionSetup.TestField("Restore Connection", false);
        CRMConnectionSetup.TestField("Is Enabled", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsCRMIntegrationEnabledValidConnectionOnStart()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [CRM Integration Management] [Restore Connection]
        // [SCENARIO] IsCRMIntegrationEnabled() enabled connection, if CRMConnectionSetup."Restore Connection" is 'Yes' and connection setup is valid.
        Initialize;

        // [GIVEN] CRM Connection is disabled, "Restore Connection" is 'Yes'
        // [GIVEN] CRM Connection is valid
        LibraryCRMIntegration.RegisterTestTableConnection;
        LibraryCRMIntegration.EnsureCRMSystemUser;
        LibraryCRMIntegration.CreateCRMOrganization;
        MockCRMConnectionSetupWithEnableValidConnection;

        // [WHEN] running IsCRMIntegrationEnabled()
        CRMIntegrationManagement.ClearState;
        Assert.IsTrue(
          CRMIntegrationManagement.IsCRMIntegrationEnabled,
          'Expected Integration to be enabled.');

        // [THEN] Response is 'Yes', "Is Enabled" is 'Yes', "Restore Connection" is 'No'
        CRMConnectionSetup.Get;
        CRMConnectionSetup.TestField("Restore Connection", false);
        CRMConnectionSetup.TestField("Is Enabled", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsCRMIntegrationEnabledInvalidConnectionOnStart()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [CRM Integration Management] [Restore Connection]
        // [SCENARIO] IsCRMIntegrationEnabled() does not enable connection, if CRMConnectionSetup."Restore Connection" is 'Yes', but connection setup is invalid.
        Initialize;

        // [GIVEN] CRM Connection is disabled, "Restore Connection" is 'Yes'
        // [GIVEN] CRM Connection is invalid (failing on connection test)
        MockCRMConnectionSetupWithEnableValidConnection;

        // [WHEN] running IsCRMIntegrationEnabled()
        CRMIntegrationManagement.ClearState;
        Assert.IsFalse(
          CRMIntegrationManagement.IsCRMIntegrationEnabled,
          'Expected Integration to be disabled.');

        // [THEN] Response is 'No', "Is Enabled" is 'No', "Restore Connection" is 'No'
        CRMConnectionSetup.Get;
        CRMConnectionSetup.TestField("Restore Connection", false);
        CRMConnectionSetup.TestField("Is Enabled", false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RegisterConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionName: Code[10];
    begin
        Initialize;

        ConnectionName := 'No. 1';
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName);

        // Get a disabled and unregistered connection
        LibraryCRMIntegration.CreateCRMConnectionSetup(ConnectionName, 'invalid.dns.int', false);
        AssertConnectionNotRegistered(ConnectionName);

        // Enable it without registering it
        CRMConnectionSetup.Get(ConnectionName);
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup.Modify(false);

        AssertConnectionNotRegistered(ConnectionName);

        // Register
        CRMConnectionSetup.RegisterConnection;
        // Second attempt of registration skips registration if it exists
        CRMConnectionSetup.RegisterConnection;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UnregisterConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionName: Code[10];
    begin
        Initialize;

        ConnectionName := 'No. 1';
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName);

        // Get an enabled and registered connection
        LibraryCRMIntegration.CreateCRMConnectionSetup(ConnectionName, 'invalid.dns.int', true);
        CRMConnectionSetup.Get(ConnectionName);
        CRMConnectionSetup.RegisterConnection;

        // Unregister and check
        CRMConnectionSetup.UnregisterConnection;
        AssertConnectionNotRegistered(ConnectionName);
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    [Scope('OnPrem')]
    procedure ConnectionRegistrationMirrorsEnabledCheckbox()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        Initialize;
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        LibraryCRMIntegration.RegisterTestTableConnection;
        // [GIVEN] There is no connection to CRM
        CRMConnectionSetup.UnregisterConnection;
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, ''), 'HASTABLECONNECTION before');

        // [WHEN] Enter details in the setup page and enable the connection
        CRMConnectionSetupPage.OpenEdit;
        CRMConnectionSetupPage."Server Address".SetValue('@@test@@');
        CRMConnectionSetupPage."Authentication Type".SetValue('Office365');
        CRMConnectionSetupPage."User Name".SetValue('tester@domain.net');
        CRMConnectionSetupPage.Password.SetValue('T3sting!');
        CRMConnectionSetupPage."Is User Mapping Required".SetValue(false);
        CRMConnectionSetupPage."Is Enabled".SetValue(true);
        // [THEN] Connection is enabled
        Assert.IsTrue(HasTableConnection(TABLECONNECTIONTYPE::CRM, ''), 'HASTABLECONNECTION when enabled');

        // [WHEN] Disable the connection on the page
        CRMConnectionSetupPage."Is Enabled".SetValue(false);
        CRMConnectionSetupPage.Close;
        // [THEN] Connection is disabled
        Assert.IsFalse(HasTableConnection(TABLECONNECTIONTYPE::CRM, ''), 'HASTABLECONNECTION when disabled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ServerAddressRequiredToEnable()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [UT]
        Initialize;

        CRMConnectionSetup.Init;
        CRMConnectionSetup."User Name" := 'tester@domain.net';
        CRMConnectionSetup.SetPassword('T3sting!');
        CRMConnectionSetup.Insert;

        asserterror CRMConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError(StrSubstNo(URLNamePswNeededErr, CRMProductName.SHORT));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserNameRequiredToEnable()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [UT]
        Initialize;

        CRMConnectionSetup.Init;
        CRMConnectionSetup."Server Address" := '@@test@@';
        CRMConnectionSetup.SetPassword('T3sting!');
        CRMConnectionSetup.Insert;

        asserterror CRMConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError(StrSubstNo(URLNamePswNeededErr, CRMProductName.SHORT));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PasswordRequiredToEnable()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [UT]
        Initialize;

        CRMConnectionSetup.Init;
        CRMConnectionSetup."Server Address" := '@@test@@';
        CRMConnectionSetup."User Name" := 'tester@domain.net';
        CRMConnectionSetup.Insert;

        asserterror CRMConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError(StrSubstNo(URLNamePswNeededErr, CRMProductName.SHORT));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure WorkingConnectionRequiredToEnable()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [UT]
        Initialize;
        LibraryCRMIntegration.UnbindMockConnection;

        // Enter details in the page and enable the connection
        CRMConnectionSetup.Init;
        CRMConnectionSetup."Server Address" := 'https://nocrmhere.gov';
        CRMConnectionSetup.Validate("User Name", 'tester@domain.net');
        CRMConnectionSetup.SetPassword('T3sting!');
        CRMConnectionSetup.Insert;

        asserterror CRMConnectionSetup.Validate("Is Enabled", true);
        Assert.ExpectedError(ConnectionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnableConnectionCanResetIntegrationTableMappingsIfEmpty()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [Table Mapping] [UI]
        Initialize;
        LibraryCRMIntegration.RegisterTestTableConnection;
        LibraryCRMIntegration.EnsureCRMSystemUser;
        LibraryCRMIntegration.CreateCRMOrganization;
        // [GIVEN] Table Mapping is empty
        Assert.TableIsEmpty(DATABASE::"Integration Table Mapping");

        // [GIVEN] Connection is disabled
        CRMConnectionSetup.DeleteAll;
        InitSetup(false, '');

        // [WHEN] Enable the connection
        CRMConnectionSetup.Get;
        CRMConnectionSetup.Validate("Is Enabled", true);

        // [THEN] Table Mapping is filled
        Assert.TableIsNotEmpty(DATABASE::"Integration Table Mapping");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnableDisableConnectionUpdatesBaseCurrencyData()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMOrganization: Record "CRM Organization";
    begin
        // [FEATURE] [Currency] [UT]
        // [SCENARIO] CRM Connection Setup collects(clears) base currency data from CRM Organization if connection enabled(disabled)
        Initialize;
        LibraryCRMIntegration.ConfigureCRM;

        // [GIVEN] CRM Organization, where BaseCurrencySymbol = 'ABC', BaseCurrencyId = 'X', BaseCurrencyPrecision = 2
        LibraryCRMIntegration.CreateCRMOrganizationWithCurrencyPrecision(2);
        CRMConnectionSetup.Get;
        // [GIVEN] CRM Connection Setup, where BaseCurrencySymbol = '', BaseCurrencyId = <null>, BaseCurrencyPrecision = 0
        Clear(CRMOrganization);
        VerifyCurrencyData(CRMConnectionSetup, CRMOrganization);

        // [WHEN] Enable connection on CRM Connection Setup
        CRMConnectionSetup.Validate("Is Enabled", true);

        // [THEN] CRM Connection Setup, where BaseCurrencySymbol = 'ABC', BaseCurrencyId = 'X', BaseCurrencyPrecision = 2
        CRMOrganization.FindFirst;
        VerifyCurrencyData(CRMConnectionSetup, CRMOrganization);

        // [WHEN] Disable connection on CRM Connection Setup
        CRMConnectionSetup.Validate("Is Enabled", false);

        // [THEN] CRM Connection Setup, where BaseCurrencySymbol = '', BaseCurrencyId = <null>, BaseCurrencyPrecision = 0
        Clear(CRMOrganization);
        VerifyCurrencyData(CRMConnectionSetup, CRMOrganization);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnableConnectionShouldFailIfBaseCurrencyNotEqualLCY()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMOrganization: Record "CRM Organization";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        GLSetup: Record "General Ledger Setup";
        User: Record User;
    begin
        // [FEATURE] [Currency] [LCY] [UT]
        // [SCENARIO] Connection cannot be enabled if CRM base currencydoes not match LCY
        Initialize;
        User.ModifyAll("Authentication Email", '');
        LibraryCRMIntegration.ConfigureCRM;

        // [GIVEN] CRM Organization, where "BaseCurrencyId" = 'X'
        LibraryCRMIntegration.CreateCRMOrganizationWithCurrencyPrecision(2);
        // [GIVEN] CRM Transactioncurrency 'X', where "ISO Currency Code" = 'USD'
        CRMOrganization.FindFirst;
        CRMTransactioncurrency.Get(CRMOrganization.BaseCurrencyId);
        CRMTransactioncurrency.ISOCurrencyCode := 'USD';
        CRMTransactioncurrency.Modify;

        // [GIVEN] LCY is 'GBP'
        GLSetup.Get;
        GLSetup."LCY Code" := 'GBP';
        GLSetup.Modify;

        // [GIVEN] CRM Connection Setup is set, but not enabled
        LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', false);
        CRMConnectionSetup.Get;
        CRMConnectionSetup.SetPassword('value');
        CRMConnectionSetup.Modify;

        // [WHEN] Enable connection on CRM Connection Setup
        asserterror CRMConnectionSetup.Validate("Is Enabled", true);

        // [THEN] Error message: "LCY Code GBP does not match ISO Currency Code USD of the CRM base currency."
        Assert.ExpectedError(
          StrSubstNo(LCYMustMatchBaseCurrencyErr, GLSetup."LCY Code", CRMTransactioncurrency.ISOCurrencyCode));
    end;

    [Test]
    [HandlerFunctions('MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CanTestConnectionWhenNotIsEnabled()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        Initialize;
        LibraryCRMIntegration.RegisterTestTableConnection;
        LibraryCRMIntegration.EnsureCRMSystemUser;
        CRMConnectionSetup.DeleteAll;
        CRMConnectionSetup.Init;
        CRMConnectionSetup."Server Address" := '@@test@@';
        CRMConnectionSetup.Validate("User Name", 'tester@domain.net');
        CRMConnectionSetup.SetPassword('value');
        CRMConnectionSetup.Insert;

        CRMConnectionSetup.PerformTestConnection;
    end;

    [Test]
    [HandlerFunctions('CRMOptionMappingModalHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntTableUIDFieldTypeShowsTypeOnListPage()
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
        ShippingAgent: Record "Shipping Agent";
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
    begin
        // [FEATURE] [Option Mapping] [UI]
        Initialize;

        // [GIVEN] Two Table Mappings, where "Integration Table UID Fld. No." is of type GUID and Option.
        IntegrationTableMapping.DeleteAll(true);

        IntegrationTableMapping.Init;
        IntegrationTableMapping.Name := '1';
        IntegrationTableMapping."Table ID" := DATABASE::Customer;
        IntegrationTableMapping."Integration Table ID" := DATABASE::"CRM Account";
        IntegrationTableMapping.Validate("Integration Table UID Fld. No.", 1);
        IntegrationTableMapping.Insert(true);

        IntegrationTableMapping.Init;
        IntegrationTableMapping.Name := '2';
        IntegrationTableMapping."Table ID" := DATABASE::"Shipping Agent";
        IntegrationTableMapping."Integration Table ID" := DATABASE::"CRM Account";
        IntegrationTableMapping.Validate("Integration Table UID Fld. No.", 16);
        IntegrationTableMapping.Insert(true);

        // [GIVEN] The mapping to the option field has one related record in "CRM Option Mapping" table
        ShippingAgent.Init;
        ShippingAgent.Code := LibraryUtility.GenerateGUID;
        ShippingAgent.Insert;

        CRMOptionMapping.Init;
        CRMOptionMapping."Record ID" := ShippingAgent.RecordId;
        CRMOptionMapping."Table ID" := DATABASE::"Shipping Agent";
        CRMOptionMapping."Option Value" := -1;
        CRMOptionMapping."Option Value Caption" := Format(CRMOptionMapping."Option Value") + ShippingAgent.Code;
        CRMOptionMapping.Insert;
        // Expected values for CRMOptionMappingModalHandler
        LibraryVariableStorage.Enqueue(Format(ShippingAgent.RecordId));
        LibraryVariableStorage.Enqueue(CRMOptionMapping."Option Value");
        LibraryVariableStorage.Enqueue(CRMOptionMapping."Option Value Caption");

        // [WHEN] Open page "Integration Table Mapping List" in edit mode
        IntegrationTableMappingList.OpenEdit;

        // [THEN] "Integration Field" and "Integration Field Type" columns are not enabled
        Assert.IsFalse(
          IntegrationTableMappingList.IntegrationFieldCaption.Editable,
          'IntegrationFieldCaption should not be enabled');
        Assert.IsFalse(
          IntegrationTableMappingList.IntegrationFieldType.Editable,
          'IntegrationFieldType should not be enabled');
        // [THEN] Two records, where "Integration Field Type" is 'GUID' and 'Option'
        IntegrationTableMappingList.IntegrationFieldType.AssertEquals('GUID');
        // [THEN] Drill Down on "Integration Field" of 'GUID' type does nothing
        IntegrationTableMappingList.IntegrationFieldCaption.DrillDown;
        IntegrationTableMappingList.Next;
        IntegrationTableMappingList.IntegrationFieldType.AssertEquals('Option');
        // [THEN] Drill Down on "Integration Field" of 'Option' field opens "CRM Option Mapping" page
        IntegrationTableMappingList.IntegrationFieldCaption.DrillDown;
        // verified by CRMOptionMappingModalHandler
        IntegrationTableMappingList.Close;
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InvokeResetConfigurationCreatesNewMappings()
    var
        JobQueueEntry: Record "Job Queue Entry";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Table Mapping] [UI]
        Initialize;

        // [GIVEN] Connection to CRM established
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        LibraryCRMIntegration.ConfigureCRM;

        // [GIVEN] No Integration Table Mapping records
        // [GIVEN] No Job Queue Entry records
        IntegrationTableMapping.DeleteAll(true);
        JobQueueEntry.DeleteAll;

        LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', true);

        // [GIVEN] CRM Connection Setup page
        CRMConnectionSetup.OpenEdit;

        // [WHEN] "Use Default Synchronization Setup" action is invoked
        CRMConnectionSetup.ResetConfiguration.Invoke;

        // [THEN] Integration Table Mapping and Job Queue Entry tables are not empty
        Assert.AreNotEqual(0, IntegrationTableMapping.Count, 'Expected the reset mappings to create new mappings');
        Assert.AreNotEqual(0, JobQueueEntry.Count, 'Expected the reset mappings to create new job queue entries');

        // [THEN] Message "The default setup for Dynamics 365 Sales synchronization has completed successfully." appears
        Assert.ExpectedMessage(StrSubstNo(SetupSuccessfulMsg, CRMProductName.SHORT), LibraryVariableStorage.DequeueText);
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InvokeResetIntegrationIdsCreatesNewIntegrationIds()
    var
        IntegrationRecord: Record "Integration Record";
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        Initialize;
        LibraryCRMIntegration.ConfigureCRM;

        IntegrationRecord.DeleteAll;

        LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', true);
        CRMConnectionSetup.OpenEdit;

        CRMConnectionSetup."Generate Integration IDs".Invoke;

        Assert.AreNotEqual(0, IntegrationRecord.Count, 'Expected the generate integration ids action to generate integration ids');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UrlValidationIsNotCaseSensitive()
    var
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Server Address] [UI]
        // [SCENARIO] The user-entered server address URL is not case sensitive

        // [GIVEN] A camel case server address URL
        // [WHEN] The user sets the value
        Initialize;
        CRMConnectionSetup.OpenEdit;
        CRMConnectionSetup."Server Address".SetValue('https://CamelCaseUrl.crm4.dynamics.com');

        // [THEN] No confirm dialog pops-up asking to auro-replace the URL with the lowercase version
        // This test succeeds if no confirm dialog shows up to ask user for agreement to replace the URL.
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UrlValidationWhenMissingHTTPS()
    var
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Server Address] [UI]
        // [SCENARIO] The user-entered server address URL is prefixed with 'https://' if needed

        // [GIVEN] A server address URL
        // [WHEN] The user sets the value, omitting the beginning 'https://'
        Initialize;
        CRMConnectionSetup.OpenEdit;
        CRMConnectionSetup."Server Address".SetValue('company.crm4.dynamics.com');

        // [THEN] A confirmation dialog opens (the handler is exercised simulating the user clicking Yes)
        // [THEN] The URL is prefixed with 'https://'
        Assert.AreEqual('https://company.crm4.dynamics.com', CRMConnectionSetup."Server Address".Value, 'Incorrect URL auto-completion');
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CannotOpenPageIfAppAreaBasic()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        // [FEATURE] [UI]
        // [GIVEN] Application Area is set to Basic for the current user
        ApplicationAreaSetup.SetRange("User ID", UserId);
        ApplicationAreaSetup.DeleteAll;

        ApplicationAreaSetup.Init;
        ApplicationAreaSetup."User ID" := UserId;
        ApplicationAreaSetup.Basic := true;
        ApplicationAreaSetup.Insert;
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // [WHEN] Open CRM Connection Setup page
        LibraryVariableStorage.Enqueue(OnlyBasicAppAreaMsg);
        asserterror PAGE.Run(PAGE::"CRM Connection Setup");

        // [THEN] A message: "You do not have access to this page." and silent error
        // handled by MessageDequeue
        Assert.ExpectedError('');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ActionSyncJobs()
    var
        CRMConnectionSetup: TestPage "CRM Connection Setup";
        JobQueueEntries: TestPage "Job Queue Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Synch. Job Queue Entries" opens page with CRM synch. jobs.
        Initialize;
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = Yes
        InitSetup(true, '');
        // [GIVEN] 4 Job Queue Entries: 3 are for CRM Integration, 3 of them active
        InsertJobQueueEntries;
        // [WHEN] Run action "Synch. Job Queue Entries" on CRM Connection Setup page
        CRMConnectionSetup.OpenView;
        JobQueueEntries.Trap;
        CRMConnectionSetup."Synch. Job Queue Entries".Invoke;
        // [THEN] Page "Job Queue Entries" is open, where are 3 jobs
        Assert.IsTrue(JobQueueEntries.First, 'First');
        Assert.IsTrue(JobQueueEntries.Next, 'Second');
        Assert.IsTrue(JobQueueEntries.Next, 'Third');
        Assert.IsFalse(JobQueueEntries.Next, 'Fourth should fail');
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AllJobsActive()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Connection Setup page shows '3 of 3' when all jobs are active
        Initialize;
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = Yes
        InitSetup(true, '');
        // [GIVEN] 4 Job Queue Entries: 3 are for CRM Integration, 3 of them active
        InsertJobQueueEntries;

        // [WHEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView;

        // [THEN] Control "Active scheduled synchronization jobs" is '3 of 3'
        CRMConnectionSetupPage.ScheduledSynchJobsActive.AssertEquals('3 of 3');

        // [WHEN] DrillDown on '3 of 3'
        LibraryVariableStorage.Enqueue('all scheduled synchronization jobs are ready or already processing.');
        CRMConnectionSetupPage.ScheduledSynchJobsActive.DrillDown;
        // [THEN] Message : "all scheduled synchronization jobs are ready or already processing."
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoActiveJobs()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Connection Setup page shows '0 of 0' when connection is disabled
        Initialize;
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = No
        InitSetup(false, '');
        // [GIVEN] 4 Job Queue Entries: 3 are for CRM Integration, 3 of them active
        InsertJobQueueEntries;

        // [WHEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView;
        // [THEN] Control "Active scheduled synchronization jobs" is '0 of 0'
        CRMConnectionSetupPage.ScheduledSynchJobsActive.AssertEquals('0 of 0');

        // [WHEN] DrillDown on '0 of 0'
        LibraryVariableStorage.Enqueue('There is no job queue started.');
        CRMConnectionSetupPage.ScheduledSynchJobsActive.DrillDown;
        // [THEN] Message : "There is no job queue started"
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NotAllJobsActive()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Connection Setup page shows '3 of 4' when part of jobs are active
        Initialize;
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = Yes
        InitSetup(true, '');
        // [GIVEN] 6 Job Queue Entries: 4 are for CRM Integration, 3 of them active
        InsertJobQueueEntries;
        InsertJobQueueEntriesWithError;

        // [WHEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView;

        // [THEN] Control "Active scheduled synchronization jobs" is '3 of 4'
        CRMConnectionSetupPage.ScheduledSynchJobsActive.AssertEquals('3 of 4');

        // [WHEN] DrillDown on '3 of 4'
        LibraryVariableStorage.Enqueue('An active job queue is available but only 3 of the 4');
        CRMConnectionSetupPage.ScheduledSynchJobsActive.DrillDown;
        // [THEN] Message : "An active job queue is available but only 3 of the 4"
        // handled by MessageDequeue
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMStatJobExcludedIfSolutionNotInstalled()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ActiveJobs: Integer;
        TotalJobs: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] CRM Connection Setup page excludes jobs running "CRM Statistics Job".
        Initialize;
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = Yes, "Is CRM Solution Installed" = No
        InitSetup(true, '');
        CRMConnectionSetup.Get;
        CRMConnectionSetup."Is CRM Solution Installed" := false;

        // [GIVEN] 4 Job Queue Entries: 3 are for CRM Integration, 3 of them active, 1 are running "CRM Statistics Job"
        InsertJobQueueEntries;

        // [WHEN] Run CountCRMJobQueueEntries that returns ActiveJobs and TotalJobs
        CRMConnectionSetup.CountCRMJobQueueEntries(ActiveJobs, TotalJobs);

        // [THEN] Active Jobs = 2, Total Jobs = 2; "CRM Statistics Job" is not included
        Assert.AreEqual(2, ActiveJobs, 'ActiveJobs');
        Assert.AreEqual(2, TotalJobs, 'TotalJobs');
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NAVSolutionIsInstalledDrillDown()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Connection Setup page shows a message on drilldown if the solution is installed
        Initialize;
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = Yes
        InitSetup(true, '');
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView;
        // [GIVEN] "Is CRM Solution Installed" is Yes
        CRMConnectionSetupPage."Is CRM Solution Installed".AssertEquals(true);
        // [WHEN] DrillDown on "Is CRM Solution Installed" control
        LibraryVariableStorage.Enqueue(StrSubstNo(FavorableCRMSolutionInstalledMsg, PRODUCTNAME.Short, CRMProductName.SHORT));
        CRMConnectionSetupPage."Is CRM Solution Installed".DrillDown;
        // [THEN] The message: "Solution is installed."
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('MessageDequeue,ConfirmYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NAVSolutionIsNotInstalledDrillDown()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Connection Setup page shows a message on drilldown if the solution is not installed
        Initialize;
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = No
        InitSetup(false, '');
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView;
        // [GIVEN] "Is CRM Solution Installed" is No
        CRMConnectionSetupPage."Is CRM Solution Installed".AssertEquals(false);
        // [WHEN] DrillDown on "Is CRM Solution Installed" control
        LibraryVariableStorage.Enqueue(StrSubstNo(UnfavorableCRMSolutionInstalledMsg, PRODUCTNAME.Short));
        CRMConnectionSetupPage."Is CRM Solution Installed".DrillDown;
        // [THEN] The message: "Solution was not detected."
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMVersionNotValid()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Connection Setup page shows message 'CRM might not work correctly' on drilldown on the CRM Version '7.1'
        Initialize;
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = Yes, "CRM Version" = '7.1'
        InitSetup(true, '7.1');
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView;

        // [WHEN] DrillDown on "CRM Version" control
        CRMConnectionSetupPage."CRM Version".AssertEquals('7.1');
        LibraryVariableStorage.Enqueue(StrSubstNo('This version of %1 might not work correctly with %2',
            CRMProductName.SHORT, PRODUCTNAME.Short));
        CRMConnectionSetupPage."CRM Version".DrillDown;
        // [THEN] Message: 'This version of Dynamics CRM might not work correctly with Dynamics NAV'
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMVersionValid()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Connection Setup page shows message 'The version is valid' on drilldown on the CRM Version '7.2'
        Initialize;
        // [GIVEN] CRM Connection Setup, where "Is Enabled" = Yes, "CRM Version" = '7.2'
        InitSetup(true, '7.2');

        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView;

        // [WHEN] DrillDown on Version control
        CRMConnectionSetupPage."CRM Version".AssertEquals('7.2');
        LibraryVariableStorage.Enqueue(StrSubstNo('The version of %1 is valid.', CRMProductName.SHORT));
        CRMConnectionSetupPage."CRM Version".DrillDown;
        // [THEN] Message: 'The version of Dynamics CRM is valid.'
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ResetWebClientURLAction()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Reset Web Client URL" action show a message "URL has been reset"
        Initialize;
        InitSetup(true, '');
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit;
        // [WHEN] Run "Reset Web Client URL" action
        LibraryVariableStorage.Enqueue(StrSubstNo(WebClientUrlResetMsg, PRODUCTNAME.Short));
        CRMConnectionSetupPage."Reset Web Client URL".Invoke;
        CRMConnectionSetupPage.Close;
        // [THEN] Message: "URL has been reset"
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserNotMappedToCRMUserDrillDown()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        Initialize;
        InitSetup(true, '');
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit;
        // [GIVEN] "Is User Mapped To CRM User" is "No"
        CRMConnectionSetupPage."Is User Mapped To CRM User".AssertEquals(false);
        // [WHEN] DrillDown on "Is User Mapped To CRM User"
        LibraryVariableStorage.Enqueue(StrSubstNo(CurrentuserIsNotMappedToCRMUserMsg, CRMProductName.SHORT));
        CRMConnectionSetupPage."Is User Mapped To CRM User".DrillDown;
        // [THEN] Message:"User is not mapped"
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IsSOIntegrationEnabledDrillDownNotConfirmed()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Is S.Order Integration Enabled" is not set to Yes if not confirming on drill down.
        Initialize;
        InitSetup(true, '');
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit;
        // [GIVEN] "Is S.Order Integration Enabled" is "No"
        CRMConnectionSetupPage."Is S.Order Integration Enabled".AssertEquals(false);
        // [GIVEN] DrillDown on "Is S.Order Integration Enabled"
        CRMConnectionSetupPage."Is S.Order Integration Enabled".SetValue(true);
        // [WHEN] answer "No" to confirmation dialog
        // handled by ConfirmNo
        // [THEN] "Is S.Order Integration Enabled" is "No"
        CRMConnectionSetupPage."Is S.Order Integration Enabled".AssertEquals(false);
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestConnectionAction()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        Initialize;
        LibraryCRMIntegration.RegisterTestTableConnection;
        LibraryCRMIntegration.EnsureCRMSystemUser;

        CRMConnectionSetup.DeleteAll;
        InitSetup(true, '');
        CRMConnectionSetup.Get;
        CRMConnectionSetup."Is User Mapping Required" := true;
        CRMConnectionSetup.Modify;
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit;
        // [WHEN] Run "Test Connection" action
        LibraryVariableStorage.Enqueue(StrSubstNo(ConnectionSuccessNotEnabledForCurrentUserMsg, UserId, CRMProductName.SHORT));
        CRMConnectionSetupPage."Test Connection".Invoke;
        // [THEN] Message: "CRM Integration is not enabled for User"
        // handled by MessageDequeue
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SynchronizeNowNotConfirmed()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] No sync should bne done if not confirming action "Synchronize Modified Records"
        Initialize;
        LibraryCRMIntegration.ConfigureCRM;
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit;
        // [GIVEN] Run "Synchronize Modified Records" action
        CRMConnectionSetupPage.SynchronizeNow.Invoke;
        // [WHEN] Answer No to confirmation
        // handled by ConfirmNo
        // [THEN] No sync is done
        Assert.AreEqual(0, IntegrationSynchJob.Count, 'Expected zero jobs to be created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartInitialSynchAction()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
        CRMFullSynchReviewPage: TestPage "CRM Full Synch. Review";
    begin
        // [FEATURE] [UI]
        Initialize;
        LibraryCRMIntegration.ConfigureCRM;
        CreateTableMapping;
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit;
        // [WHEN] run action StartInitialSynch
        CRMFullSynchReviewPage.Trap;
        CRMConnectionSetupPage.StartInitialSynchAction.Invoke;
        // [THEN] CRMFullSynchReview page is open
        CRMFullSynchReviewPage.Close;
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [Scope('OnPrem')]
    procedure SynchronizeNowEnumeratesAllMappings()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupTestPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        Initialize;
        LibraryCRMIntegration.ConfigureCRM;
        if not CRMConnectionSetup.Get then
            LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', true);

        CreateTableMapping;

        CRMConnectionSetupTestPage.OpenEdit;
        Assert.IsTrue(CRMConnectionSetupTestPage.SynchronizeNow.Enabled, 'Expected the Synchronize Now action to be enabled');
        CRMConnectionSetupTestPage.SynchronizeNow.Invoke;

        Assert.AreEqual(3, IntegrationSynchJob.Count, 'Expected a job to be created for each mapping and direction');
    end;

    [Test]
    [HandlerFunctions('CRMSystemUserListHandler')]
    [Scope('OnPrem')]
    procedure CoupleUsersActionOpensCRMSystemUsersList()
    var
        CRMConnectionSetupTestPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI] [Salesperson]
        // [SCENARIO] Action "Couple Salespersons" should open CRM System User List, where coupling controls are enabled
        Initialize;
        LibraryCRMIntegration.RegisterTestTableConnection;
        // [GIVEN] There is a record in CRM Systemuser table
        LibraryCRMIntegration.EnsureCRMSystemUser;
        // [GIVEN] "CRM Connection Setup" page is open
        CRMConnectionSetupTestPage.OpenEdit;

        // [WHEN] Run action "Couple Salespersons"
        CRMConnectionSetupTestPage.CoupleUsers.Invoke;

        // [THEN] CRM System User List is open, where Salesperson Code column is editable, action Couple is enabled
        // returned by CRMSystemUserListHandler
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Salesperson Code column should be editable.');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Couple action should be enabled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IsUserMappingRequiredFalseByDefault()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 178384] Init Value of "Is User Mapping Required" should be 'No' by default in CRM Connection Setup
        Initialize;
        CRMConnectionSetup.Init;
        CRMConnectionSetup.Insert;
        CRMConnectionSetup.TestField("Is User Mapping Required", false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnableCRMJobQueueEntriesOnEnableCRMConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [SCENARIO] Enabling CRM Connection move all CRM Job Queue Entries in "Ready" status
        Initialize;
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;

        // [GIVEN] CRM Connection Setup with Integration Table Mapping and CRM Job Queue Entries
        CreateCRMConnectionSetup;
        CRMConnectionSetup.DeleteAll;
        InitSetup(false, '');

        // [WHEN] Enable the connection
        CRMConnectionSetup.Get;
        CRMConnectionSetup.Validate("Is Enabled", true);
        CRMConnectionSetup.Modify(true);

        // [THEN] All CRM Job Queue Entries has Status = Ready
        VerifyJobQueueEntriesStatusIsReady;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DisableCRMJobQueueEntriesOnDisableCRMConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [SCENARIO] Disabling CRM Connection move all CRM Job Queue Entries in "On Hold" status
        Initialize;

        // [GIVEN] CRM Connection Setup with Integration Table Mapping and CRM Job Queue Entries
        CreateCRMConnectionSetup;
        CRMConnectionSetup.DeleteAll;
        InitSetup(true, '');

        // [WHEN] Disable the connection
        CRMConnectionSetup.Get;
        CRMConnectionSetup.Validate("Is Enabled", false);
        CRMConnectionSetup.Modify(true);

        // [THEN] All CRM Job Queue Entries has Status = On Hold
        VerifyJobQueueEntriesStatusIsOnHold;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserNotMappedForDisabledCRMUser()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSystemuser: Record "CRM Systemuser";
        User: Record User;
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [User] [UI]
        // [SCENARIO 209341] CRM Connection setup declares user is not mapped when CRM User is disabled

        Initialize;
        LibraryCRMIntegration.ConfigureCRM;

        // [GIVEN] CRM Connection Setup
        CRMConnectionSetup.Get;

        // [GIVEN] CRM User "CU" with email "EMAIL"
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser);

        // [GIVEN] Current user has Authentication Email = "EMAIL"
        LibraryPermissions.CreateWindowsUser(User, UserId);
        User.Validate("Authentication Email", CRMSystemuser.InternalEMailAddress);
        User.Modify;

        // [WHEN] User Mapping is enabled
        CRMConnectionSetup."Is User Mapping Required" := true;
        CRMConnectionSetup.Modify;

        // [THEN] CRM Connection setup page with Is User Mapped To CRM User = TRUE
        CRMConnectionSetupPage.OpenView;
        CRMConnectionSetupPage."Is User Mapped To CRM User".AssertEquals(true);
        CRMConnectionSetupPage.Close;

        // [WHEN] CRM User "CU" is disabled in CRM
        CRMSystemuser.Validate(IsDisabled, true);
        CRMSystemuser.Modify(true);

        // [THEN] CRM Connection setup page with Is User Mapped To CRM User = FALSE
        CRMConnectionSetupPage.OpenView;
        CRMConnectionSetupPage."Is User Mapped To CRM User".AssertEquals(false);
        CRMConnectionSetupPage.Close;
    end;

    [Test]
    [HandlerFunctions('MessageDequeue')]
    [Scope('OnPrem')]
    procedure DisableCRMSalesOrderIntegration()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 211784] Disable CRM Sales Order Integration from CRM Connection Setup page
        Initialize;

        // [GIVEN] CRM Connection Enabled and Sales Order Integration enabled
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCRMOrganization;
        SetSalesOrderIntegrationInOrg(true);

        // [GIVEN] Open CRM Connection Setup page and "Sales Order Integration Enabled" = TRUE
        CRMConnectionSetupPage.OpenEdit;
        CRMConnectionSetupPage."Is S.Order Integration Enabled".AssertEquals(true);

        // [WHEN] Set "Sales Order Integration Enabled" = FALSE
        LibraryVariableStorage.Enqueue(StrSubstNo(CRMSOIntegrationDisabledMsg, CRMProductName.SHORT));
        CRMConnectionSetupPage."Is S.Order Integration Enabled".SetValue(false);

        // [THEN] Then Message appears that Sales Order Integration is now disabled and "Sales Order Integration Enabled" = FALSE
        CRMConnectionSetupPage."Is S.Order Integration Enabled".AssertEquals(false);
        CRMConnectionSetupPage.Close;
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure JobQueueEntriesDescription()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Table Mapping] [UI]
        // [SCENARIO 229986] CRM synchronization job queue entries have proper description
        Initialize;

        // [GIVEN] New CRM connection setup
        PrepareNewConnectionSetup;

        // [GIVEN] Open CRM connection setup page
        CRMConnectionSetup.OpenEdit;

        // [WHEN] Reset configuration action is being clicked
        CRMConnectionSetup.ResetConfiguration.Invoke;

        // [THEN] Created job queue entries does not have "%2" in the description
        JobQueueEntry.SetFilter(Description, '*%2*');
        Assert.RecordIsEmpty(JobQueueEntry);

        // [THEN] Created job queue entries have description with "Dynamics 365 Sales"
        JobQueueEntry.SetFilter(Description, StrSubstNo('*%1*', CRMProductName.SHORT));
        Assert.RecordIsNotEmpty(JobQueueEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AutoCreateSalesOrdersJobQueueEntryCreatedOnResetConfiguration()
    var
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [SCENARIO 229986] Job queue entry for codeunit "Auto Create Sales Orders" created while resetting configuration if CRMConnectionSetup."Auto Create Sales Orders" = TRUE
        Initialize;

        // [GIVEN] New CRM connection setup
        PrepareNewConnectionSetup;

        // [GIVEN] CRMConnectionSetup."Auto Create Sales Orders" = TRUE
        SetAutoCreateSalesOrders(true);

        // [GIVEN] Open CRM connection setup page
        CRMConnectionSetup.OpenEdit;

        // [WHEN] Reset configuration action is being clicked
        CRMConnectionSetup.ResetConfiguration.Invoke;

        // [THEN] Job queue entry for codeunit "Auto Create Sales Orders" created
        VerifyAutoCreateSalesOrdersJobQueueEntryExists;
    end;

    [Test]
    [HandlerFunctions('ConfirmYes,MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AutoCreateSalesOrdersJobQueueEntryDoesNotCreatedOnResetConfiguration()
    var
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [SCENARIO 229986] Job queue entry for codeunit "Auto Create Sales Orders" does not created while resetting configuration if CRMConnectionSetup."Auto Create Sales Orders" = FALSE
        Initialize;

        // [GIVEN] New CRM connection setup
        PrepareNewConnectionSetup;

        // [GIVEN] CRMConnectionSetup."Auto Create Sales Orders" = FALSE
        SetAutoCreateSalesOrders(false);

        // [GIVEN] Open CRM connection setup page
        CRMConnectionSetup.OpenEdit;

        // [WHEN] Reset configuration action is being clicked
        CRMConnectionSetup.ResetConfiguration.Invoke;

        // [THEN] Job queue entry for codeunit "Auto Create Sales Orders" does not created
        VerifyAutoCreateSalesOrdersJobQueueEntryDoesNotExist;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AutoCreateSalesOrdersEditableIfOrdersIntegrationEnabled()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 229986] CRMConnectionSetup."Auto Create Sales Orders" is editable in case of orders integration enabled
        Initialize;

        // [GIVEN] CRM Connection Enabled and Sales Order Integration enabled
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCRMOrganization;
        SetSalesOrderIntegrationInOrg(true);

        // [WHEN] Opened CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit;

        // [THEN] Sales Order Integration enabled
        CRMConnectionSetupPage."Is S.Order Integration Enabled".AssertEquals(true);

        // [THEN] "Auto Create Sales Orders" is editable
        Assert.IsTrue(CRMConnectionSetupPage."Auto Create Sales Orders".Editable, 'Field must be editable.');
    end;

    [Test]
    [HandlerFunctions('MessageOk')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AutoCreateSalesOrdersNotEditableIfOrdersIntegrationDisabled()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 229986] CRMConnectionSetup."Auto Create Sales Orders" = FALSE and not editable in case of orders integration disabled
        Initialize;

        // [GIVEN] CRM Connection Enabled and Sales Order Integration enabled
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCRMOrganization;
        SetSalesOrderIntegrationInOrg(true);

        // [GIVEN] CRM Connection Setup with "Auto Create Sales Orders" = TRUE
        SetAutoCreateSalesOrders(true);

        // [GIVEN] Opened CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit;

        // [WHEN] Order integration is being disabled
        CRMConnectionSetupPage."Is S.Order Integration Enabled".SetValue(false);

        // [THEN] "Auto Create Sales Orders" = FALSE
        CRMConnectionSetupPage."Auto Create Sales Orders".AssertEquals(false);

        // [THEN] "Auto Create Sales Orders" is not editable
        Assert.IsFalse(CRMConnectionSetupPage."Auto Create Sales Orders".Editable, 'Field must be not editable.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnablingAutoCreateSalesOrdersMakesJobQueueEntryCreated()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 229986] Setting CRMConnectionSetup."Auto Create Sales Orders" = TRUE makes job queue entry created
        Initialize;
        JobQueueEntry.DeleteAll;

        // [GIVEN] CRM Connection Enabled and Sales Order Integration enabled
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCRMOrganization;
        SetSalesOrderIntegrationInOrg(true);

        // [GIVEN] Opened CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit;

        // [WHEN] Set "Auto Create Sales Orders" = TRUE
        CRMConnectionSetupPage."Auto Create Sales Orders".SetValue(true);

        // [THEN] Job queue entry created with Object ID to Run = "Process Sbmt. CRM Sales Orders"
        VerifyAutoCreateSalesOrdersJobQueueEntryExists;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DisablingAutoCreateSalesOrdersMakesJobQueueEntryDeleted()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 229986] Setting CRMConnectionSetup."Auto Create Sales Orders" = FALSE makes job queue entry deleted
        Initialize;
        JobQueueEntry.DeleteAll;

        // [GIVEN] CRM Connection Enabled and Sales Order Integration enabled
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCRMOrganization;
        SetSalesOrderIntegrationInOrg(true);

        // [GIVEN] Opened CRM Connection Setup page
        CRMConnectionSetupPage.OpenEdit;

        // [GIVEN] Set "Auto Create Sales Orders" = TRUE
        CRMConnectionSetupPage."Auto Create Sales Orders".SetValue(true);

        // [WHEN] Set "Auto Create Sales Orders" = FALSE
        CRMConnectionSetupPage."Auto Create Sales Orders".SetValue(false);

        // [THEN] Job queue entry does not exist with Object ID to Run = "Process Sbmt. CRM Sales Orders"
        VerifyAutoCreateSalesOrdersJobQueueEntryDoesNotExist;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTGetJobQueueEntriesObjectIDToRunFilter()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        "Filter": Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 229986] GetJobQueueEntriesObjectIDToRunFilter returns filter which contains codeunits 5339, 5350, 5349

        // [WHEN] Function GetJobQueueEntriesObjectIDToRunFilter is being run
        Filter := CRMConnectionSetup.GetJobQueueEntriesObjectIDToRunFilter;

        // [THEN] Resulted filter contains codeunit 5339
        VerifyCodeunitInFilter(Filter, CODEUNIT::"Integration Synch. Job Runner");
        // [THEN] Resulted filter contains codeunit 5350
        VerifyCodeunitInFilter(Filter, CODEUNIT::"CRM Statistics Job");
        // [THEN] Resulted filter contains codeunit 5349
        VerifyCodeunitInFilter(Filter, CODEUNIT::"Auto Create Sales Orders");
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure IntegrationTableMappingNameCannotBeBlank()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
    begin
        // [FEATURE] [Table Mapping] [UI]
        // [SCENARIO 235022] You cannot create Integration Table Mapping with blank Name.
        Initialize;

        IntegrationTableMapping.Init;
        IntegrationTableMapping."Table ID" := DATABASE::"Integration Table Mapping";
        IntegrationTableMapping.Insert;

        IntegrationTableMappingList.OpenEdit;
        IntegrationTableMappingList.GotoRecord(IntegrationTableMapping);
        asserterror IntegrationTableMappingList.Name.SetValue('');

        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure ConnectionSetupDefaultSDKVersion9()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO 234755] Connection Setup has SDK Version 9 by default
        Initialize;

        // [WHEN] Connection Setup page opened first time
        CRMConnectionSetupPage.OpenEdit;

        // [THEN] SDK Version = 9 by default
        CRMConnectionSetupPage.SDKVersion.AssertEquals(9);

        // [WHEN] Server address in entered and page closed
        CRMConnectionSetupPage."Server Address".SetValue('https://test.dynamics.com');
        CRMConnectionSetupPage.Close;

        // [THEN] CRM Connection Setup record has Proxy Version = 9
        CRMConnectionSetup.Get;
        CRMConnectionSetup.TestField("Proxy Version", 9);

        // [WHEN] CRM Connection Setup record has Proxy Version = 0 and CRM Connection Setup page is opened
        CRMConnectionSetup.Validate("Proxy Version", 0);
        CRMConnectionSetup.Modify;
        CRMConnectionSetupPage.OpenEdit;

        // [THEN] SDK Version = 9 by default
        CRMConnectionSetupPage.SDKVersion.AssertEquals(9);
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure ConnectionSetupSDKVersionEnabledDisabled()
    var
        CRMConnectionSetup: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO 234755] SDK Version selection is enabled only when connection is not enabled
        Initialize;
        // [GIVEN] Connection is not enabled
        // [WHEN] Connection Setup opened and connection not enabled
        CRMConnectionSetup.OpenEdit;
        // [THEN] SDK Version field is enabled
        Assert.IsTrue(CRMConnectionSetup.SDKVersion.Enabled, 'Expected "SDK Version" field to be enabled');
        CRMConnectionSetup.Close;

        // [GIVEN] Connection is enabled
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCRMOrganization;
        // [WHEN] Connection Setup opened
        CRMConnectionSetup.OpenEdit;
        // [THEN] SDK Version field is not enabled
        Assert.IsFalse(CRMConnectionSetup.SDKVersion.Enabled, 'Expected "SDK Version" field not to be enabled');
        CRMConnectionSetup.Close;
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure ConnectionSetupChangeSDKVersion()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO 234755] When SDK Version is changed in page it changes in record also
        Initialize;
        // [GIVEN] Connection is not enabled
        // [GIVEN] Connection Setup page is opened

        // [WHEN] SDK Version is set to "8"
        CRMConnectionSetupPage.OpenEdit;
        CRMConnectionSetupPage.SDKVersion.SetValue(8);
        CRMConnectionSetupPage.Close;
        // [THEN] Proxy Version in CRM Connection Setup record is "8"
        CRMConnectionSetup.Get;
        CRMConnectionSetup.TestField("Proxy Version", 8);

        // [WHEN] SDK Version is set to "9"
        CRMConnectionSetupPage.OpenEdit;
        CRMConnectionSetupPage.SDKVersion.SetValue(9);
        CRMConnectionSetupPage.Close;
        // [THEN] Proxy Version in CRM Connection Setup record is "9"
        CRMConnectionSetup.Get;
        CRMConnectionSetup.TestField("Proxy Version", 9);
    end;

    [Test]
    [HandlerFunctions('SDKVersionListModalHandler')]
    [Scope('OnPrem')]
    procedure ConnectionSetupChangeSDKVersionConnectStringUpdate()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO 234755] When CRM Proxy Version is changed in page it is also changed in connection string
        Initialize;

        // [GIVEN] Connection is not enabled
        // [GIVEN] Connection Setup page is opened
        LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', true);

        // [WHEN] Proxy Version is set to "8"
        CRMConnectionSetupPage.OpenEdit;
        LibraryVariableStorage.Enqueue(8);
        CRMConnectionSetupPage.SDKVersion.AssistEdit;

        // [THEN] Proxy Version in Connection String is "8"
        CRMConnectionSetupPage.SDKVersion.AssertEquals(8);
        Assert.ExpectedMessage('ProxyVersion=8', CRMConnectionSetupPage."Connection String".Value);
        CRMConnectionSetup.Get;
        Assert.ExpectedMessage('ProxyVersion=8', CRMConnectionSetup.GetConnectionString);

        // [WHEN] Proxy Version is set to "9"
        LibraryVariableStorage.Enqueue(9);
        CRMConnectionSetupPage.SDKVersion.AssistEdit;

        // [THEN] Proxy Version in Connection String is "9"
        CRMConnectionSetupPage.SDKVersion.AssertEquals(9);
        Assert.ExpectedMessage('ProxyVersion=9', CRMConnectionSetupPage."Connection String".Value);
        CRMConnectionSetup.Get;
        Assert.ExpectedMessage('ProxyVersion=9', CRMConnectionSetup.GetConnectionString);
        CRMConnectionSetupPage.Close;
    end;

    [Scope('OnPrem')]
    procedure CRMIntegrationEnabledStateWhenDisableConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [CRM Connection Setup] [UT]
        // [SCENARIO 254415] CRMIntegrationEnabledState <> Enabled when disable CRM Connection Setup
        // [GIVEN] CRM Connection Setup
        Initialize;
        LibraryCRMIntegration.RegisterTestTableConnection;
        LibraryCRMIntegration.EnsureCRMSystemUser;
        LibraryCRMIntegration.CreateCRMOrganization;
        // [GIVEN] CRMIntegrationEnabledState = Enabled
        Assert.IsTrue(CRMIntegrationManagement.IsCRMIntegrationEnabled, CRMIntegrationEnabledStateErr);

        // [WHEN] Disable the connection
        CRMConnectionSetup.Get;
        CRMConnectionSetup.Validate("Is Enabled", false);
        CRMConnectionSetup.Modify(true);

        // [THEN] CRMIntegrationEnabledState <> Enabled
        Assert.IsFalse(CRMIntegrationManagement.IsCRMIntegrationEnabled, CRMIntegrationEnabledStateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DisableReasonCleanedOnConnectionEnable()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [CRM Connection Setup] [UT]
        // [SCENARIO 257435] Disable Reason is cleared when Connection is enabled
        Initialize;
        LibraryCRMIntegration.RegisterTestTableConnection;
        LibraryCRMIntegration.EnsureCRMSystemUser;
        LibraryCRMIntegration.CreateCRMOrganization;

        // [GIVEN] Connection is disabled, "Disable Reason" = ABC
        CRMConnectionSetup.DeleteAll;
        InitSetup(false, '');
        CRMConnectionSetup.Get;
        CRMConnectionSetup."Disable Reason" := 'ABC';
        CRMConnectionSetup.Modify;

        // [WHEN] Enable the connection
        CRMConnectionSetup.Validate("Is Enabled", true);

        // [THEN] "Disable Reason" is empty
        CRMConnectionSetup.TestField("Disable Reason", '');
    end;

    [Test]
    [HandlerFunctions('ConnectionBrokenNotificationHandler,ConfirmYes')]
    [Scope('OnPrem')]
    procedure DisableConnectionNotificationConnectionSetup()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [SCENARIO 257435] Verify Disable Reason is displayed in notification if connection was disabled
        Initialize;
        InitSetup(false, '');

        // [GIVEN] CRM Connection is disabled due to reason "ABC"
        CRMConnectionSetup.Get;
        CRMConnectionSetup."Disable Reason" := 'ABC';
        CRMConnectionSetup.Modify;

        // [WHEN] CRM Connection Setup page is opened
        CRMConnectionSetupPage.OpenEdit;

        // [THEN] Notification message includes connection disabled reason "ABC"
        Assert.AreEqual(
          StrSubstNo(ConnectionDisabledMsg, CRMConnectionSetup."Disable Reason"),
          LibraryVariableStorage.DequeueText, 'Unexpected notification.');

        CRMConnectionSetupPage.Close;
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnableDisableCRMItemAvailabilityWebService()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Item Availability]
        // [SCENARIO 265230] CRM Item Availability service can be enabled and disabled
        Initialize;

        // [GIVEN] CRM Connection Enabled and Sales Order Integration enabled
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCRMOrganization;

        // [GIVEN] CRM Connection is enabled, Item Availability service is not setup
        // [WHEN] CRM Connection Setup page is opened
        CRMConnectionSetupPage.OpenEdit;

        // [THEN] Dynamics 365 Business Central Item Availability Web Service is Enabled = FALSE
        CRMConnectionSetupPage.ItemAvailabilityWebServEnabled.AssertEquals(false);

        // [THEN] OData Url is empty
        CRMConnectionSetupPage.NAVODataURL.AssertEquals('');

        // [WHEN] DrillDown on Dynamics 365 Business Central Item Availability Web Service is Enabled pressed
        CRMConnectionSetupPage.ItemAvailabilityWebServEnabled.DrillDown;
        CRMConnectionSetupPage.Close;
        CRMConnectionSetupPage.OpenView;

        // [THEN] Dynamics 365 Business Central Item Availability Web Service is Enabled = TRUE
        CRMConnectionSetupPage.ItemAvailabilityWebServEnabled.AssertEquals(true);

        // [THEN] OData URL contains links to ProductItemAvailability Web Service
        Assert.ExpectedMessage('/ProductItemAvailability', CRMConnectionSetupPage.NAVODataURL.Value);

        // [WHEN] DrillDown on Dynamics 365 Business Central Item Availability Web Service is Enabled pressed
        CRMConnectionSetupPage.ItemAvailabilityWebServEnabled.DrillDown;
        CRMConnectionSetupPage.Close;
        CRMConnectionSetupPage.OpenView;

        // [THEN] Dynamics 365 Business Central Item Availability Web Service is Enabled = FALSE
        CRMConnectionSetupPage.ItemAvailabilityWebServEnabled.AssertEquals(false);

        // [THEN] OData URL is empty
        CRMConnectionSetupPage.NAVODataURL.AssertEquals('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GetItemAvailabilityWebServiceURLReturnsEmptyValue()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [UT] [Item Availability]
        // [SCENARIO 265230] GetItemAvailabilityWebServiceURL returns empty value if web service is not enabled
        Initialize;

        Assert.AreEqual('', CRMIntegrationManagement.GetItemAvailabilityWebServiceURL, 'Wrong value returned');
    end;

    [Test]
    [HandlerFunctions('CRMAssistedSetupModalHandler,ConfirmYes')]
    [Scope('OnPrem')]
    procedure RunAssistedSetupFromCRMConnectionSetup()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [SCENARIO 266927] CRM Connection Assisted Setup can be opened from CRM Connection Setup page
        Initialize;

        // [GIVEN] CRM Connection Setup page is opened, Server Address "SA"
        CRMConnectionSetupPage.OpenEdit;
        CRMConnectionSetupPage."Server Address".SetValue('TEST');

        // [WHEN] Assisted Setup is invoked
        CRMConnectionSetupPage."Assisted Setup".Invoke;

        // [THEN] CRM Connection Setup wizard is opened and Server Address = "SA"
        // Wizard page is opened in CRMAssistedSetupModalHandler
        Assert.ExpectedMessage(CRMConnectionSetupPage."Server Address".Value, LibraryVariableStorage.DequeueText);
    end;

    local procedure Initialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        LibraryCRMIntegration.ResetEnvironment;
        LibraryVariableStorage.Clear;
        if CryptographyManagement.IsEncryptionEnabled then
            CryptographyManagement.DisableEncryption(true);
        Assert.IsFalse(EncryptionEnabled, 'Encryption should be disabled');

        Clear(CRMSetupTest);
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, '');
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM));
        Assert.AreEqual(
          '', GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM),
          'DEFAULTTABLECONNECTION should not be registered');

        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();

        if IsInitialized then
            exit;

        IsInitialized := true;
        SetTenantLicenseStateToTrial;
    end;

    local procedure AssertConnectionNotRegistered(ConnectionName: Code[10])
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.Get(ConnectionName);
        CRMConnectionSetup.RegisterConnection;
        CRMConnectionSetup.UnregisterConnection;
    end;

    local procedure CreateTableMapping()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        with IntegrationTableMapping do begin
            Init;
            "Table ID" := DATABASE::Currency;
            "Integration Table ID" := DATABASE::"CRM Transactioncurrency";
            Validate("Integration Table UID Fld. No.", CRMTransactioncurrency.FieldNo(TransactionCurrencyId));
            "Synch. Codeunit ID" := CODEUNIT::"CRM Integration Table Synch.";

            Name := 'FIRST';
            Direction := Direction::FromIntegrationTable;
            Insert;

            Name := 'SECOND';
            Direction := Direction::Bidirectional;
            Insert;
        end;
    end;

    local procedure CreateIntTableMappingWithJobQueueEntries()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        IntegrationTableMapping.DeleteAll;
        CreateTableMapping;
        JobQueueEntry.DeleteAll;
        InsertJobQueueEntries;
        InsertJobQueueEntriesWithError;
        IntegrationTableMapping.FindFirst;
        JobQueueEntry.ModifyAll("Record ID to Process", IntegrationTableMapping.RecordId);
    end;

    local procedure CreateCRMConnectionSetup()
    begin
        LibraryCRMIntegration.RegisterTestTableConnection;
        LibraryCRMIntegration.EnsureCRMSystemUser;
        LibraryCRMIntegration.CreateCRMOrganization;
        CreateIntTableMappingWithJobQueueEntries;
    end;

    local procedure InitSetup(Enable: Boolean; Version: Text[30])
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.Init;
        CRMConnectionSetup."Is Enabled" := Enable;
        CRMConnectionSetup."Is CRM Solution Installed" := Enable;
        CRMConnectionSetup."Is User Mapping Required" := false;
        CRMConnectionSetup."Server Address" := '@@test@@';
        CRMConnectionSetup.Validate("User Name", 'tester@domain.net');
        CRMConnectionSetup.SetPassword('Password');
        CRMConnectionSetup."CRM Version" := Version;
        CRMConnectionSetup.Insert;

        if CRMConnectionSetup."Is Enabled" then
            CRMConnectionSetup.RegisterConnection;
    end;

    local procedure InsertJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.DeleteAll;
        InsertJobQueueEntry(CODEUNIT::"Integration Synch. Job Runner", JobQueueEntry.Status::Ready);
        InsertJobQueueEntry(CODEUNIT::"Integration Synch. Job Runner", JobQueueEntry.Status::"In Process");
        InsertJobQueueEntry(CODEUNIT::"CRM Statistics Job", JobQueueEntry.Status::Ready);
        InsertJobQueueEntry(CODEUNIT::"Exchange PowerShell Runner", JobQueueEntry.Status::"In Process");
    end;

    local procedure InsertJobQueueEntriesWithError()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        InsertJobQueueEntry(CODEUNIT::"CRM Statistics Job", JobQueueEntry.Status::Error);
        InsertJobQueueEntry(CODEUNIT::"Exchange PowerShell Runner", JobQueueEntry.Status::Error);
    end;

    local procedure InsertJobQueueEntry(ID: Integer; Status: Option)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init;
        JobQueueEntry.ID := CreateGuid;
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := ID;
        JobQueueEntry.Status := Status;
        JobQueueEntry.Insert;
    end;

    local procedure MockCRMConnectionSetupWithEnableValidConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.DeleteAll;
        LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', false);
        CRMConnectionSetup.Get;
        CRMConnectionSetup.SetPassword('password');
        CRMConnectionSetup."Restore Connection" := true;
        CRMConnectionSetup.Modify;
    end;

    local procedure PrepareNewConnectionSetup()
    var
        JobQueueEntry: Record "Job Queue Entry";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        LibraryCRMIntegration.ConfigureCRM;

        IntegrationTableMapping.DeleteAll(true);
        JobQueueEntry.DeleteAll;

        LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', true);
    end;

    local procedure SetAutoCreateSalesOrders(NewAutoCreateOrders: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.Get;
        CRMConnectionSetup.Validate("Auto Create Sales Orders", NewAutoCreateOrders);
        CRMConnectionSetup.Modify(true);
    end;

    local procedure VerifyCurrencyData(CRMConnectionSetup: Record "CRM Connection Setup"; CRMOrganization: Record "CRM Organization")
    begin
        CRMConnectionSetup.TestField(CurrencyDecimalPrecision, CRMOrganization.CurrencyDecimalPrecision);
        CRMConnectionSetup.TestField(BaseCurrencyId, CRMOrganization.BaseCurrencyId);
        CRMConnectionSetup.TestField(BaseCurrencyPrecision, CRMOrganization.BaseCurrencyPrecision);
        CRMConnectionSetup.TestField(BaseCurrencySymbol, CRMOrganization.BaseCurrencySymbol);
    end;

    local procedure VerifyJobQueueEntriesStatusIsReady()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.FindSet;
        repeat
            Assert.IsTrue(JobQueueEntry.Status = JobQueueEntry.Status::Ready, JobQueueEntryStatusReadyErr);
        until JobQueueEntry.Next = 0;
    end;

    local procedure VerifyJobQueueEntriesStatusIsOnHold()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.FindSet;
        repeat
            Assert.IsTrue(JobQueueEntry.Status = JobQueueEntry.Status::"On Hold", JobQueueEntryStatusOnHoldErr);
        until JobQueueEntry.Next = 0;
    end;

    local procedure VerifyAutoCreateSalesOrdersJobQueueEntryExists()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Auto Create Sales Orders");
        JobQueueEntry.FindFirst;
    end;

    local procedure VerifyAutoCreateSalesOrdersJobQueueEntryDoesNotExist()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Auto Create Sales Orders");
        Assert.RecordIsEmpty(JobQueueEntry);
    end;

    local procedure VerifyCodeunitInFilter("Filter": Text; CodeunitId: Integer)
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Codeunit);
        AllObj.FilterGroup(2);
        AllObj.SetFilter("Object ID", Filter);
        AllObj.FilterGroup(0);
        AllObj.SetRange("Object ID", CodeunitId);
        Assert.IsTrue(AllObj.FindFirst, StrSubstNo('Filter does not contain codeunit %1', CodeunitId));
    end;

    local procedure SetSalesOrderIntegrationInOrg(EnabledSalesOrderIntegration: Boolean)
    var
        CRMOrganization: Record "CRM Organization";
    begin
        CRMOrganization.FindFirst;
        CRMOrganization.IsSOPIntegrationEnabled := EnabledSalesOrderIntegration;
        CRMOrganization.Modify;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageOk(Message: Text)
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageDequeue(Message: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMOptionMappingModalHandler(var CRMOptionMappingPage: TestPage "CRM Option Mapping")
    begin
        Assert.IsFalse(CRMOptionMappingPage.Editable, 'The page should be NOT editable');
        CRMOptionMappingPage.First;
        CRMOptionMappingPage.Record.AssertEquals(LibraryVariableStorage.DequeueText);
        CRMOptionMappingPage."Option Value".AssertEquals(LibraryVariableStorage.DequeueInteger);
        CRMOptionMappingPage."Option Value Caption".AssertEquals(LibraryVariableStorage.DequeueText);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CRMSystemUserListHandler(var CRMSystemuserList: TestPage "CRM Systemuser List")
    begin
        LibraryVariableStorage.Enqueue(CRMSystemuserList.SalespersonPurchaserCode.Editable);
        LibraryVariableStorage.Enqueue(CRMSystemuserList.Couple.Visible);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SDKVersionListModalHandler(var SDKVersionList: TestPage "SDK Version List")
    begin
        SDKVersionList.GotoKey(LibraryVariableStorage.DequeueInteger);
        SDKVersionList.OK.Invoke;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ConnectionBrokenNotificationHandler(var ConnectionBrokenNotification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(ConnectionBrokenNotification.Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMAssistedSetupModalHandler(var CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard")
    begin
        LibraryVariableStorage.Enqueue(CRMConnectionSetupWizard.ServerAddress.Value);
    end;

    local procedure SetTenantLicenseStateToTrial()
    var
        TenantLicenseState: Record "Tenant License State";
    begin
        TenantLicenseState."Start Date" := CurrentDateTime;
        TenantLicenseState.State := TenantLicenseState.State::Trial;
        TenantLicenseState.Insert;
    end;
}

