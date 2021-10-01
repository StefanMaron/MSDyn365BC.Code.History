codeunit 132908 TestCompanyChangePages
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [My Settings] [Company] [UI]
    end;

    var
        CompanyDisplayNameTxt: Label 'Company display name';
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
#if not CLEAN19
        CompanySetUpInProgressMsg: Label 'Company %1 was just created, and we are still setting it up for you.', Comment = '%1 - a company name';
#endif
        LibraryPermissions: Codeunit "Library - Permissions";
        SetupStatus: Enum "Company Setup Status";
        NoConfigPackDefinedMsg: Label 'No configuration package file is defined within the specified filter';
        GlobalSessionID: Integer;
        GlobalTaskID: Guid;

#if not CLEAN19
    [Test]
    [HandlerFunctions('AllowedCompaniesReturnsDisplayNameModalHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AllowedCompaniesDisplayName()
    var
        MySettings: TestPage "My Settings";
        ActualName: Text;
    begin
        // [GIVEN] The current company, where "Name" is 'A', "Display Name" is 'X'
        SetDisplayName(CompanyDisplayNameTxt);
        // [GIVEN] "My Settings" page is open
        MySettings.OpenView;
        // [WHEN] Click on "Company" control
        MySettings.Company.AssistEdit;
        // [THEN] Page "Allowed Companies" is open, where "Name" is 'X'
        ActualName := LibraryVariableStorage.DequeueText; // sent by AllowedCompaniesReturnsDisplayNameModalHandler
        Assert.AreEqual(CompanyDisplayNameTxt, ActualName, 'Wrong Name on Allowed Companies page');
    end;

    [Test]
    [HandlerFunctions('AllowedCompaniesReturnsDisplayNameModalHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AllowedCompaniesBlankDisplayName()
    var
        MySettings: TestPage "My Settings";
        ActualName: Text;
    begin
        // [GIVEN] The current company, where "Name" is 'A', "Display Name" is <blank>
        SetDisplayName('');
        // [GIVEN] "My Settings" page is open
        MySettings.OpenView();
        // [WHEN] Click on "Company" control
        MySettings.Company.AssistEdit();
        // [THEN] Page "Allowed Companies" is open, where "Name" is COMPANYNAME
        ActualName := LibraryVariableStorage.DequeueText; // sent by AllowedCompaniesReturnsDisplayNameModalHandler
        Assert.AreEqual(CompanyName(), ActualName, 'Wrong Name on Allowed Companies page');
    end;
#endif

    [Test]
    [HandlerFunctions('PickCompanyModalHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CompletedCompanyCanBeSelected()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        UserSettings: TestPage "User Settings";
    begin
        // [SCENARIO] Company can be selected in My Settings if its setup is completed
        Initialize();
        // [GIVEN] Current company is 'A', "Display Name" is 'X'
        SetDisplayName(CompanyDisplayNameTxt);
        // [GIVEN] There is no Assisted Company Setup Status record
        AssistedCompanySetupStatus.DeleteAll();
        // [GIVEN] "My Settings" page is open
        UserSettings.OpenView();
        // [WHEN] Click on "Company" control and pick 'X'
        LibraryVariableStorage.Enqueue(CompanyName); // for PickCompanyModalHandler
        UserSettings.Company.AssistEdit(); // handled by PickCompanyModalHandler
        // [THEN] "Company" is 'X', no errors/messages
        UserSettings.Company.AssertEquals(CompanyDisplayNameTxt);
    end;

    [Test]
    [HandlerFunctions('PickCompanyModalHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CompanyCanBeSelectedIfSetupSessionIsZero()
    var
        UserSettings: TestPage "User Settings";
    begin
        // [SCENARIO] Company can be selected in My Settings if "Company Setup Session ID" is zero
        Initialize();
        // [GIVEN] Current company is 'A', "Display Name" is 'X'
        SetDisplayName(CompanyDisplayNameTxt);
        // [GIVEN] There is Assisted Company Setup Status record, where "Company Setup Session ID" is 0
        SetAssistedCompanySetupStatus(CompanyName, 0, 1);
        // [GIVEN] "My Settings" page is open
        UserSettings.OpenView();

        // [WHEN] Click on "Company" control and pick 'X'
        LibraryVariableStorage.Enqueue(CompanyName); // for PickCompanyModalHandler
        UserSettings.Company.AssistEdit(); // handled by PickCompanyModalHandler

        // [THEN] "Company" is 'X', no errors/messages
        UserSettings.Company.AssertEquals(CompanyDisplayNameTxt);
    end;

     [Test]
    [HandlerFunctions('PickCompanyModalHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CompanyCannotBeSelectedIfSetupSessionIsNotZero()
    var
        Company: Record Company;
        UserSettings: TestPage "User Settings";
        SelectedCompany: Text;
        ActualMessage: Text;
    begin
        // [SCENARIO] Company cannot be selected in My Settings if Company Setup Session is active
        Initialize();
        // [GIVEN] the new company 'B', that is in progress of setup
        Company.Init();
        Company.Name := LibraryUtility.GenerateGUID();
        Company.Insert();
        // [GIVEN] There is Assisted Company Setup Status record for 'B', where "Company Setup Session ID" is active
        SetAssistedCompanySetupStatus(Company.Name, SessionId, 0);

        // [GIVEN] "My Settings" page is open
        UserSettings.OpenEdit();
        SelectedCompany := UserSettings.Company.Value();
        // [GIVEN] Click on "Company" control and see
        LibraryVariableStorage.Enqueue(Company.Name); // for PickCompanyModalHandler
        UserSettings.Company.AssistEdit(); // handled by PickCompanyModalHandler
        // [GIVEN] page Allowed Companies , where "Setup Status" is 'In Progress' for 'B', and 'No' for 'A'
        Assert.AreEqual(SetupStatus::"In Progress".AsInteger(), LibraryVariableStorage.DequeueInteger(), 'SetupStatus for company B');

        // [WHEN] Pick company 'B'
        // handled by PickCompanyModalHandler

        // [THEN] "Company" is still 'A'
        UserSettings.Company.AssertEquals(SelectedCompany);
        // [THEN] the message is shown: 'Company B set up is in progress'
        ActualMessage := LibraryVariableStorage.DequeueText(); // by MessageHandler
        Assert.ExpectedMessage(StrSubstNo(CompanySetUpInProgressMsg, Company.Name), ActualMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExistsConfigurationPackageFileIsNoForNoDataOptions()
    var
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        NewCompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data";
    begin
        // [FEATURE] [UT]
        // [GIVEN] Config. Package "EXTENDED" is in config. package files
        InitCompanySetupWithPackage('ENU.EXTENDED');
        // [THEN] ExistsConfigurationPackageFile() is 'Yes' for CompanyData::"Extended Data"
        Assert.IsTrue(
          AssistedCompanySetup.ExistsConfigurationPackageFile(NewCompanyData::"Extended Data"), 'CompanyData::Extended Data');
        // [THEN] ExistsConfigurationPackageFile() is 'No' for CompanyData::"None" and CompanyData::"Full No Data"
        Assert.IsFalse(
          AssistedCompanySetup.ExistsConfigurationPackageFile(NewCompanyData::None), 'CompanyData::None');
        Assert.IsFalse(
          AssistedCompanySetup.ExistsConfigurationPackageFile(NewCompanyData::"Full No Data"), 'CompanyData::Full No Data');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCompanyDataForStandardPack()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        Company: Record Company;
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        TestCompanyChangePages: Codeunit TestCompanyChangePages;
        NewCompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data";
        ExpectedTaskID: Guid;
        ExpectedSessionID: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] FillCompanyData() for Standard data sets "Evaluation Company" to 'No' and schedules a task
        Initialize;
        // [GIVEN] Config. Package "STANDARD" is in config. package files
        InitCompanySetupWithPackage('ENU.STANDARD');

        // [WHEN] FillCompanyData() with "Standard Data"
        BindSubscription(TestCompanyChangePages);
        MockTaskScheduling(TestCompanyChangePages, ExpectedTaskID, ExpectedSessionID, 1);
        AssistedCompanySetup.FillCompanyData(CompanyName, NewCompanyData::"Standard Data");

        // [THEN] Assisted Company Setup Status, where "Task ID" is filled
        AssistedCompanySetupStatus.Get(CompanyName);
        AssistedCompanySetupStatus.TestField("Task ID", ExpectedTaskID);
        // [THEN] Company, where "Evaluation Company" is "No"
        Company.Get(CompanyName);
        Company.TestField("Evaluation Company", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCompanyDataForEvaluationPack()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        Company: Record Company;
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        TestCompanyChangePages: Codeunit TestCompanyChangePages;
        NewCompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data";
        ExpectedTaskID: Guid;
        ExpectedSessionID: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] FillCompanyData() for Evaluation data sets "Evaluation Company" to 'Yes' and schedules a task
        Initialize;
        // [GIVEN] Config. Package "EVALUATION" is in config. package files
        InitCompanySetupWithPackage('ENU.EVALUATION');

        // [WHEN] FillCompanyData() with "Evaluation Data"
        BindSubscription(TestCompanyChangePages);
        MockTaskScheduling(TestCompanyChangePages, ExpectedTaskID, ExpectedSessionID, 1);
        AssistedCompanySetup.FillCompanyData(CompanyName, NewCompanyData::"Evaluation Data");

        // [THEN] Assisted Company Setup Status, where "Task ID" is filled
        AssistedCompanySetupStatus.Get(CompanyName);
        AssistedCompanySetupStatus.TestField("Task ID", ExpectedTaskID);
        // [THEN] Company, where "Evaluation Company" is "Yes"
        Company.Get(CompanyName);
        Company.TestField("Evaluation Company", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCompanyDataForExtendedPack()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        Company: Record Company;
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        TestCompanyChangePages: Codeunit TestCompanyChangePages;
        NewCompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data";
        ExpectedTaskID: Guid;
        ExpectedSessionID: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] FillCompanyData() for Extended data sets "Evaluation Company" to 'No' and schedules a task
        Initialize;
        // [GIVEN] Config. Package "EXTENDED" is in config. package files
        InitCompanySetupWithPackage('ENU.EXTENDED');

        // [WHEN] FillCompanyData() with "Extended Data"
        BindSubscription(TestCompanyChangePages);
        MockTaskScheduling(TestCompanyChangePages, ExpectedTaskID, ExpectedSessionID, 1);
        AssistedCompanySetup.FillCompanyData(CompanyName, NewCompanyData::"Extended Data");

        // [THEN] Assisted Company Setup Status, where "Task ID" is filled
        AssistedCompanySetupStatus.Get(CompanyName);
        AssistedCompanySetupStatus.TestField("Task ID", ExpectedTaskID);
        // [THEN] Company, where "Evaluation Company" is "No"
        Company.Get(CompanyName);
        Company.TestField("Evaluation Company", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCompanyDataForExtendedNoDataPack()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        Company: Record Company;
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        TestCompanyChangePages: Codeunit TestCompanyChangePages;
        NewCompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data";
        ExpectedTaskID: Guid;
        ExpectedSessionID: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] FillCompanyData() for Full No Data sets "Evaluation Company" to 'No' and does not schedule a task
        Initialize;
        // [GIVEN] Config. Package "EXTENDED" is in config. package files
        InitCompanySetupWithPackage('ENU.EXTENDED');

        // [WHEN] FillCompanyData() with "Full No Data"
        BindSubscription(TestCompanyChangePages);
        MockTaskScheduling(TestCompanyChangePages, ExpectedTaskID, ExpectedSessionID, 1);
        AssistedCompanySetup.FillCompanyData(CompanyName, NewCompanyData::"Full No Data");

        // [THEN] Assisted Company Setup Status, where "Task ID" is <null>
        AssistedCompanySetupStatus.Get(CompanyName);
        Assert.IsTrue(IsNullGuid(AssistedCompanySetupStatus."Task ID"), 'Task ID should be null');
        // [THEN] Company, where "Evaluation Company" is "No"
        Company.Get(CompanyName);
        Company.TestField("Evaluation Company", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindConfigPackageFileIfLanguageDoesNotMatch()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        ConfigurationPackageFile: array[2] of Record "Configuration Package File";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        GlobalLang: Integer;
    begin
        // [FEATURE] [Language] [UT]
        // [SCENARIO 217007] Existing config. package should be picked up even if language does not match the global language
        AssistedCompanySetupStatus.DeleteAll();
        // [GIVEN] GLOBALLANGUAGE is 1033 (ENU)
        GlobalLang := GlobalLanguage;
        // [GIVEN] ConfigurationPackageFile 'DEU.STANDARD', where "Language Code" = 1031 (DEU)
        ConfigurationPackageFile[1].DeleteAll();
        ConfigurationPackageFile[1].Code := 'DEU.STANDARD';
        ConfigurationPackageFile[1]."Language ID" := GlobalLang - 1;
        ConfigurationPackageFile[1].Insert();
        // [GIVEN] ConfigurationPackageFile 'DAN.EVALUATION', where "Language Code" = 1030 (DAN)
        ConfigurationPackageFile[1].Code := 'DAN.EVALUATION';
        ConfigurationPackageFile[1]."Language ID" := GlobalLang + 1;
        ConfigurationPackageFile[1].Insert();
        // [GIVEN] ConfigurationPackageFile 'DAN.STANDARD', where "Language Code" = 1030 (DAN)
        ConfigurationPackageFile[1].Code := 'DAN.STANDARD';
        ConfigurationPackageFile[1]."Language ID" := GlobalLang + 1;
        ConfigurationPackageFile[1].Insert();

        // [WHEN] run FindConfigurationPackageFile
        AssistedCompanySetup.FindConfigurationPackageFile(ConfigurationPackageFile[2], 1);

        // [THEN] ConfigurationPackageFile 'DAN.STANDARD' is found
        Assert.RecordCount(ConfigurationPackageFile[2], 2);
        ConfigurationPackageFile[2].TestField(Code, ConfigurationPackageFile[1].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindConfigPackageFileIfLanguageMatches()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        ConfigurationPackageFile: array[2] of Record "Configuration Package File";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        GlobalLang: Integer;
    begin
        // [FEATURE] [Language] [UT]
        // [SCENARIO 217007] Existing config. package should be picked if language matches the global language
        AssistedCompanySetupStatus.DeleteAll();
        // [GIVEN] GLOBALLANGUAGE is 1033 (ENU)
        GlobalLang := GlobalLanguage;
        // [GIVEN] ConfigurationPackageFile 'DEU.STANDARD', where "Language Code" = 1031 (DEU)
        ConfigurationPackageFile[1].DeleteAll();
        ConfigurationPackageFile[1].Code := 'DEU.STANDARD';
        ConfigurationPackageFile[1]."Language ID" := GlobalLang - 1;
        ConfigurationPackageFile[1].Insert();
        // [GIVEN] ConfigurationPackageFile 'ENU.EVALUATION', where "Language Code" = 1033 (ENU)
        ConfigurationPackageFile[1].Code := 'ENU.EVALUATION';
        ConfigurationPackageFile[1]."Language ID" := GlobalLang;
        ConfigurationPackageFile[1].Insert();
        // [GIVEN] ConfigurationPackageFile 'ENU.STANDARD', where "Language Code" = 1033 (ENU)
        ConfigurationPackageFile[1].Code := 'ENU.STANDARD';
        ConfigurationPackageFile[1]."Language ID" := GlobalLang;
        ConfigurationPackageFile[1].Insert();

        // [WHEN] run FindConfigurationPackageFile
        AssistedCompanySetup.FindConfigurationPackageFile(ConfigurationPackageFile[2], 1);

        // [THEN] ConfigurationPackageFile 'ENU.STANDARD' is found
        Assert.RecordCount(ConfigurationPackageFile[2], 1);
        ConfigurationPackageFile[2].TestField(Code, ConfigurationPackageFile[1].Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RunSetupIfNoConfigPacksExist()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        ConfigurationPackageFile: Record "Configuration Package File";
        GeneralLedgerSetup: Record "General Ledger Setup";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        TaskID: Guid;
        MessageText: Text;
    begin
        // [FEATURE] [Import Config. Package Files] [UT]
        // [GIVEN] AssistedCompanySetupStatus, where "Task ID" = 'x'
        AssistedCompanySetupStatus.DeleteAll();
        TaskID := CreateGuid;
        AssistedCompanySetupStatus."Company Name" := CompanyName;
        AssistedCompanySetupStatus."Task ID" := TaskID;
        AssistedCompanySetupStatus.Insert();
        if not GeneralLedgerSetup.Get then
            GeneralLedgerSetup.Insert(); // to avoid RUN(CODEUNIT::"Company-Initialize")
        // [GIVEN] There are no ConfigurationPackageFile records
        ConfigurationPackageFile.DeleteAll();

        // [WHEN] Run Codeunit 1805
        CODEUNIT.Run(CODEUNIT::"Import Config. Package Files", ConfigurationPackageFile);

        // [THEN] Message: "Critical Error: No configuration package file is defined within the specified filter"
        MessageText := LibraryVariableStorage.DequeueText; // from MessageHandler
        Assert.ExpectedMessage(NoConfigPackDefinedMsg, MessageText);
        // [THEN] "Company Setup Session ID" is 0, "Server Instance ID" = 0, "Task ID" = 'x'
        AssistedCompanySetupStatus.Find;
        AssistedCompanySetupStatus.TestField("Company Setup Session ID", 0);
        AssistedCompanySetupStatus.TestField("Server Instance ID", 0);
        AssistedCompanySetupStatus.TestField("Task ID", TaskID);
        // [THEN] One Job Queue Log Entry added, where "ID" = 'x', "Status" = 'Error',
        JobQueueLogEntry.SetRange(ID, TaskID);
        Assert.RecordCount(JobQueueLogEntry, 1);
        JobQueueLogEntry.FindLast;
        JobQueueLogEntry.TestField(Status, JobQueueLogEntry.Status::Error);
        // [THEN] Description and Error message are 'No configuration package file is defined ...'
        Assert.ExpectedMessage(NoConfigPackDefinedMsg, JobQueueLogEntry."Error Message");
        Assert.ExpectedMessage(NoConfigPackDefinedMsg, JobQueueLogEntry.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsCompanySetupInProgressOnSameNST()
    var
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
    begin
        // [FEATURE] [UT]
        MockAssistedCompanySetupStatus(CompanyName, ServiceInstanceId, SessionId);
        Assert.IsTrue(AssistedCompanySetup.IsCompanySetupInProgress(CompanyName), 'IsCompanySetupInProgress');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsCompanySetupInProgressOnAnotherNST()
    var
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
    begin
        // [FEATURE] [UT]
        MockAssistedCompanySetupStatus(CompanyName, -ServiceInstanceId, SessionId);
        Assert.IsFalse(AssistedCompanySetup.IsCompanySetupInProgress(CompanyName), 'IsCompanySetupInProgress');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsCompanySetupInProgressOnInactiveSession()
    var
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
    begin
        // [FEATURE] [UT]
        MockAssistedCompanySetupStatus(CompanyName, ServiceInstanceId, -SessionId);
        Assert.IsFalse(AssistedCompanySetup.IsCompanySetupInProgress(CompanyName), 'IsCompanySetupInProgress');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsCompanySetupInProgressOnZeroSessionID()
    var
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
    begin
        // [FEATURE] [UT]
        MockAssistedCompanySetupStatus(CompanyName, ServiceInstanceId, 0);
        Assert.IsFalse(AssistedCompanySetup.IsCompanySetupInProgress(CompanyName), 'IsCompanySetupInProgress');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupNewCompanyForDataTypeNone()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        NewCompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Company with "None" data, has no application areas set, none configuration package applied
        // [GIVEN] No ApplicationAreaSetup, no AssistedCompanySetupStatus
        ClearExpTierAndAppAreaSetup;
        AssistedCompanySetupStatus.DeleteAll();

        // [WHEN] SetUpNewCompany() with "CompanyData::None"
        AssistedCompanySetup.SetUpNewCompany(CompanyName, NewCompanyData::None);

        // [THEN] ApplicationAreaSetup, where "Basic" and "Suite" are 'Yes', no AssistedCompanySetupStatus
        ApplicationAreaSetup.SetRange("Company Name", CompanyName);
        ApplicationAreaSetup.FindFirst;
        LibraryApplicationArea.VerifyApplicationAreaEssentialExperience(ApplicationAreaSetup);
        Assert.IsTrue(AssistedCompanySetupStatus.Get(CompanyName), 'Expected that record exists.');
        Assert.AreEqual(AssistedCompanySetupStatus.GetCompanySetupStatusValue(CompanyName), SetupStatus::Completed,
          'Expected that Status is completed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupNewCompanyForDataTypeStandard()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        GLEntry: Record "G/L Entry";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        TestCompanyChangePages: Codeunit TestCompanyChangePages;
        NewCompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data";
        ExpectedTaskID: Guid;
        ExpectedSessionID: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Company with "Standard Data" has "Suite" experience, 'STANDARD' configuration package applied
        // [GIVEN] No ApplicationAreaSetup, no AssistedCompanySetupStatus
        ClearExpTierAndAppAreaSetup;
        AssistedCompanySetupStatus.DeleteAll();
        // [GIVEN] No G/L Entries (to be able to enable Assisted Company Setup)
        GLEntry.DeleteAll();
        // [GIVEN] Config. Package "STANDARD" is in config. package files
        InsertConfigPackageFile('ENU.STANDARD');

        // [WHEN] SetUpNewCompany() with "CompanyData::Standard Data"
        BindSubscription(TestCompanyChangePages);
        MockTaskScheduling(TestCompanyChangePages, ExpectedTaskID, ExpectedSessionID, 1);
        AssistedCompanySetup.SetUpNewCompany(CompanyName, NewCompanyData::"Standard Data");

        // [THEN] ApplicationAreaSetup, where "Basic" and "Suite" are 'Yes'
        ApplicationAreaSetup.SetRange("Company Name", CompanyName);
        ApplicationAreaSetup.FindFirst;
        LibraryApplicationArea.VerifyApplicationAreaEssentialExperience(ApplicationAreaSetup);
        // [THEN] AssistedCompanySetupStatus, where "Enabled" is false, "Task ID" is not <null>
        AssistedCompanySetupStatus.SetRange("Company Name", CompanyName);
        AssistedCompanySetupStatus.FindFirst;
        AssistedCompanySetupStatus.TestField(Enabled, false);
        AssistedCompanySetupStatus.TestField("Task ID", ExpectedTaskID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupNewCompanyForDataTypeEvaluation()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        GLEntry: Record "G/L Entry";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        TestCompanyChangePages: Codeunit TestCompanyChangePages;
        NewCompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data";
        ExpectedTaskID: Guid;
        ExpectedSessionID: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Company with "Evaluation Data" has "Basic" experience, 'EVALUATION' configuration package applied
        // [GIVEN] No ApplicationAreaSetup, no AssistedCompanySetupStatus
        ClearExpTierAndAppAreaSetup;
        AssistedCompanySetupStatus.DeleteAll();
        // [GIVEN] No G/L Entries (to be able to enable Assisted Company Setup)
        GLEntry.DeleteAll();
        // [GIVEN] Config. Package "EVALUATION" is in config. package files
        InsertConfigPackageFile('ENU.EVALUATION');

        // [WHEN] SetUpNewCompany() with "CompanyData::Evaluation Data"
        BindSubscription(TestCompanyChangePages);
        MockTaskScheduling(TestCompanyChangePages, ExpectedTaskID, ExpectedSessionID, 1);
        AssistedCompanySetup.SetUpNewCompany(CompanyName, NewCompanyData::"Evaluation Data");

        // [THEN] ApplicationAreaSetup, where "Basic" and "Relationship Mgmt" are 'Yes', "Suite" is 'No'
        ApplicationAreaSetup.SetRange("Company Name", CompanyName);
        ApplicationAreaSetup.FindFirst;
        LibraryApplicationArea.VerifyApplicationAreaEssentialExperience(ApplicationAreaSetup);
        // [THEN] AssistedCompanySetupStatus, where "Enabled" is 'No', "Task ID" is not <null>
        AssistedCompanySetupStatus.SetRange("Company Name", CompanyName);
        AssistedCompanySetupStatus.FindFirst;
        AssistedCompanySetupStatus.TestField(Enabled, false);
        AssistedCompanySetupStatus.TestField("Task ID", ExpectedTaskID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupNewCompanyForDataTypeExtended()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        TestCompanyChangePages: Codeunit TestCompanyChangePages;
        NewCompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data";
        ExpectedTaskID: Guid;
        ExpectedSessionID: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Company with "Extended Data" has "Full" experience, 'EXTENDED' configuration package applied
        // [GIVEN] No ApplicationAreaSetup, no AssistedCompanySetupStatus, no G/L Entries
        // [GIVEN] Config. Package "EXTENDED" is in config. package files
        LibraryPermissions.SetTestTenantEnvironmentType(true);
        ClearExpTierAndAppAreaSetup;
        ClearCompanySetupWithPackage('ENU.EXTENDED');

        // [WHEN] SetUpNewCompany() with "CompanyData::Extended Data"
        BindSubscription(TestCompanyChangePages);
        MockTaskScheduling(TestCompanyChangePages, ExpectedTaskID, ExpectedSessionID, 1);
        AssistedCompanySetup.SetUpNewCompany(CompanyName, NewCompanyData::"Extended Data");

        // [THEN] ApplicationAreaSetup, where "Basic" and "Suite" are 'No'
        ApplicationAreaSetup.SetRange("Company Name", CompanyName);
        ApplicationAreaSetup.FindFirst;
        LibraryApplicationArea.VerifyApplicationAreaEssentialExperience(ApplicationAreaSetup);
        // [THEN] AssistedCompanySetupStatus, where "Enabled" is 'No', "Task ID" is not <null>
        AssistedCompanySetupStatus.SetRange("Company Name", CompanyName);
        AssistedCompanySetupStatus.FindFirst;
        AssistedCompanySetupStatus.TestField(Enabled, false);
        AssistedCompanySetupStatus.TestField("Task ID", ExpectedTaskID);
        LibraryPermissions.SetTestTenantEnvironmentType(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupNewCompanyForDataTypeExtendedNoData()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        TestCompanyChangePages: Codeunit TestCompanyChangePages;
        NewCompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data";
        ExpectedTaskID: Guid;
        ExpectedSessionID: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Company with "Extended Data" has "Full" experience, 'EXTENDED' configuration package is not applied
        // [GIVEN] No ApplicationAreaSetup, no AssistedCompanySetupStatus, no G/L Entries
        // [GIVEN] Config. Package "EXTENDED" is in config. package files
        LibraryPermissions.SetTestTenantEnvironmentType(true);
        ClearExpTierAndAppAreaSetup;
        ClearCompanySetupWithPackage('ENU.EXTENDED');

        // [WHEN] SetUpNewCompany() with "CompanyData::Full No Data"
        BindSubscription(TestCompanyChangePages);
        MockTaskScheduling(TestCompanyChangePages, ExpectedTaskID, ExpectedSessionID, 1);
        AssistedCompanySetup.SetUpNewCompany(CompanyName, NewCompanyData::"Full No Data");

        // [THEN] ApplicationAreaSetup, where "Basic" and "Suite" are 'No'
        ApplicationAreaSetup.SetRange("Company Name", CompanyName);
        ApplicationAreaSetup.FindFirst;
        LibraryApplicationArea.VerifyApplicationAreaEssentialExperience(ApplicationAreaSetup);
        // [THEN] AssistedCompanySetupStatus has a rec for the comapny and status is completed
        Assert.IsTrue(AssistedCompanySetupStatus.Get(CompanyName), 'Expected that record exists.');
        Assert.AreEqual(AssistedCompanySetupStatus.GetCompanySetupStatusValue(CompanyName), SetupStatus::Completed,
          'Expected that Status is completed.');
        LibraryPermissions.SetTestTenantEnvironmentType(false);
    end;

    [Test]
    [HandlerFunctions('JobQueueLogModalHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure StatusOnCompaniesPageDrillsDownToLogEntries()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        Company: Record Company;
        JobQueueLogEntry: Record "Job Queue Log Entry";
        CompaniesPage: TestPage Companies;
    begin
        // [FEATURE] [Status]
        // [SCENARIO] "Assisted Company Setup Status" field on "Companies" page drills down to job queue log entries
        Initialize;
        // [GIVEN] Two related Job Queue Log Entries, where Status is 'Success' and 'In Process'
        SetAssistedCompanySetupStatus(CompanyName, SessionId, 1);
        AssistedCompanySetupStatus.FindFirst;
        MockJobQueueLogEntries(AssistedCompanySetupStatus."Task ID", JobQueueLogEntry);

        // [GIVEN] Allowed Companies page is open
        Company.Get(CompanyName);
        CompaniesPage.OpenEdit;
        CompaniesPage.GotoRecord(Company);
        Assert.IsFalse(CompaniesPage.SetupStatus.Editable, 'AssistedCompanySetupStatus.EDITABLE');
        CompaniesPage.SetupStatus.AssertEquals(JobQueueLogEntry.Status::"In Process" + 1);

        // [WHEN] Drill down on "Assisted Company Setup Status" on Companies page
        CompaniesPage.SetupStatus.DrillDown; // handled by JobQueueLogModalHandler

        // [THEN] The first entry's "Status" is 'In Process', the second  - 'Success'
        Assert.AreEqual(JobQueueLogEntry.Status::"In Process", LibraryVariableStorage.DequeueInteger, 'the first entry status');
        Assert.AreEqual(JobQueueLogEntry.Status::Success, LibraryVariableStorage.DequeueInteger, 'the second entry status');
    end;

    [Test]
    [HandlerFunctions('JobQueueLogModalHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure StatusOnSelectedCompanyPageDrillsDownToLogEntries()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        Company: Record Company;
        JobQueueLogEntry: Record "Job Queue Log Entry";
        AllowedCompanies: Page "Allowed Companies";
        AllowedCompaniesPage: TestPage "Allowed Companies";
    begin
        // [FEATURE] [Status]
        // [SCENARIO] "Setup Status" field on "Allowed Companies" page drills down to job queue log entries
        Initialize;
        // [GIVEN] Two related Job Queue Log Entries, where Status is 'Success' and 'In Process'
        SetAssistedCompanySetupStatus(CompanyName, SessionId, 1);
        AssistedCompanySetupStatus.FindFirst;
        MockJobQueueLogEntries(AssistedCompanySetupStatus."Task ID", JobQueueLogEntry);

        // [GIVEN] Allowed Companies page is open
        AllowedCompaniesPage.Trap();
        AllowedCompanies.Initialize();
        AllowedCompanies.Run();
        Company.Get(CompanyName);
        AllowedCompaniesPage.GotoRecord(Company);
        Assert.IsFalse(AllowedCompaniesPage.SetupStatus.Editable, 'SetupStatus.EDITABLE');
        AllowedCompaniesPage.SetupStatus.AssertEquals(JobQueueLogEntry.Status::"In Process" + 1);

        // [WHEN] Drill down on "Setup Status" on Allowed Companies page
        AllowedCompaniesPage.SetupStatus.DrillDown(); // handled by JobQueueLogModalHandler

        // [THEN] The first entry's "Status" is 'In Process', the second  - 'Success'
        Assert.AreEqual(JobQueueLogEntry.Status::"In Process", LibraryVariableStorage.DequeueInteger, 'the first entry status');
        Assert.AreEqual(JobQueueLogEntry.Status::Success, LibraryVariableStorage.DequeueInteger, 'the second entry status');
    end;

    [Test]
    [HandlerFunctions('ConfigPackageErrorsModalHandler')]
    [Scope('OnPrem')]
    procedure TestLookupDetailsFromApplyConfigPackageError()
    var
        JobQueueLogEntries: TestPage "Job Queue Log Entries";
        PackageCode: Code[20];
    begin
        // [SCENARIO 217901] Details action from Job Queue Log Entries for apply configuration package error opens the list of package erros
        Initialize();
        ClearConfigPackageErrors();

        PackageCode := 'XX';
        // [GIVEN] Configuration package error for package XX
        MockConfigPackageErrorRecord(PackageCode);
        // [GIVEN] Configuration package error for package YY
        MockConfigPackageErrorRecord('YY');
        // [GIVEN] Job Queue Log Entry error record for package XX
        MockJobQueueErrorLogEntry(PackageCode);
        JobQueueLogEntries.OpenView();

        // [WHEN] User click Details action
        JobQueueLogEntries.Details.Invoke();

        // [THEN] Page Config. Package Errors page opened with filter for package XX
        Assert.AreEqual(PackageCode, LibraryVariableStorage.DequeueText, 'Wrong filter.');
    end;

    [Test]
    [HandlerFunctions('CopyCompanySetGetNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyCompanyLeadingTrailingSpacesTrimmedCompanyName()
    var
        CompanyName: Text[30];
    begin
        // [FEATURE] [Copy Company]
        // [SCENARIO 288739] Stan opens "Companies" page, runs "Copy Company", sets "New Company Name". Leading and trailing spaces are trimmed for "New Company Name" value.
        Initialize();

        // [GIVEN] Create text string "T1" = "  abc def  " for the new company name.
        CompanyName := StrSubstNo('%1 %2', LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(StrSubstNo('  %1  ', CompanyName));

        // [WHEN] Run the report "Copy Company". Set "T1" as "New Company Name".
        Commit();
        Report.Run(Report::"Copy Company", true);

        // [THEN] All leading and trailing spaces are trimmed for "T1". "New Company Name" = "abc def".
        Assert.AreEqual(CompanyName, LibraryVariableStorage.DequeueText, '');
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
        LibraryApplicationArea.EnableBasicSetup;
    end;

    local procedure ClearCompanySetupWithPackage(PackageCode: Code[20])
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        GLEntry: Record "G/L Entry";
    begin
        ApplicationAreaSetup.DeleteAll();
        AssistedCompanySetupStatus.DeleteAll();
        GLEntry.DeleteAll(); // to be able to enable Assisted Company Setup

        InsertConfigPackageFile(PackageCode);
    end;

    local procedure ClearConfigPackageErrors()
    var
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageError.DeleteAll();
    end;

    local procedure ClearExpTierAndAppAreaSetup()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        ApplicationAreaSetup.DeleteAll();
        ExperienceTierSetup.DeleteAll();
    end;

    local procedure InitCompanySetupWithPackage(PackageCode: Code[20])
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        Company: Record Company;
    begin
        AssistedCompanySetupStatus.DeleteAll();
        AssistedCompanySetupStatus."Company Name" := CompanyName;
        AssistedCompanySetupStatus.Insert();

        Company.Get(CompanyName);
        Company."Evaluation Company" := false;
        Company.Modify();

        InsertConfigPackageFile(PackageCode);
    end;

    local procedure InsertConfigPackageFile(PackageCode: Code[20])
    var
        ConfigurationPackageFile: Record "Configuration Package File";
    begin
        ConfigurationPackageFile.DeleteAll();
        ConfigurationPackageFile.Code := PackageCode;
        ConfigurationPackageFile."Language ID" := GlobalLanguage;
        ConfigurationPackageFile.Insert();
    end;

    [Normal]
    local procedure SetDisplayName(DisplayName: Text[250])
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName());
        Company."Display Name" := DisplayName;
        Company.Modify();
    end;

    local procedure SetAssistedCompanySetupStatus(Name: Text; SessionID: Integer; SessionDelta: Integer)
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        TestCompanyChangePages: Codeunit TestCompanyChangePages;
    begin
        MockAssistedCompanySetupStatus(Name, ServiceInstanceId, SessionID);
        with AssistedCompanySetupStatus do begin
            Get(Name);
            MockTaskScheduling(TestCompanyChangePages, "Task ID", "Company Setup Session ID", SessionDelta);
            Modify;
        end;
    end;

    local procedure MockAssistedCompanySetupStatus(Name: Text; SrvInstanceID: Integer; SessionID: Integer)
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        with AssistedCompanySetupStatus do begin
            SetRange("Company Name", Name);
            DeleteAll();
            Init;
            "Company Name" := CopyStr(Name, 1, MaxStrLen("Company Name"));
            "Company Setup Session ID" := SessionID;
            "Server Instance ID" := SrvInstanceID;
            Insert;
        end;
    end;

    local procedure MockJobQueueLogEntries(TaskID: Guid; var JobQueueLogEntry: Record "Job Queue Log Entry")
    begin
        // creates three entries, two of which belong to the TaskID, where one is 'Success', and second is 'In Process'
        JobQueueLogEntry.DeleteAll();
        JobQueueLogEntry."Entry No." := 0;
        JobQueueLogEntry.ID := CreateGuid;
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
        JobQueueLogEntry."Object Type to Run" := JobQueueLogEntry."Object Type to Run"::Codeunit;
        JobQueueLogEntry."Object ID to Run" := Codeunit::"Import Config. Package Files";
        JobQueueLogEntry.Insert();
        JobQueueLogEntry."Entry No." := 0;
        JobQueueLogEntry.ID := TaskID;
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Success;
        JobQueueLogEntry."Object Type to Run" := JobQueueLogEntry."Object Type to Run"::Codeunit;
        JobQueueLogEntry."Object ID to Run" := Codeunit::"Import Config. Package Files";
        JobQueueLogEntry.Insert();
        JobQueueLogEntry."Entry No." := 0;
        JobQueueLogEntry.ID := TaskID;
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::"In Process";
        JobQueueLogEntry."Object Type to Run" := JobQueueLogEntry."Object Type to Run"::Codeunit;
        JobQueueLogEntry."Object ID to Run" := Codeunit::"Import Config. Package Files";
        JobQueueLogEntry.Insert();
    end;

    local procedure MockTaskScheduling(var TestCompanyChangePages: Codeunit TestCompanyChangePages; var ExpectedTaskID: Guid; var ExpectedSessionID: Integer; Delta: Integer)
    begin
        ExpectedTaskID := CreateGuid;
        ExpectedSessionID := SessionId() + Delta;
        TestCompanyChangePages.SetTaskID(ExpectedTaskID);
        TestCompanyChangePages.SetSessionID(ExpectedSessionID);
    end;

    local procedure MockConfigPackageErrorRecord(PackageCode: Code[20])
    var
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageError."Package Code" := PackageCode;
        ConfigPackageError.Insert();
    end;

    local procedure MockJobQueueErrorLogEntry(PackageCode: Code[20])
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueLogEntry.DeleteAll();
        JobQueueLogEntry."Entry No." := 1;
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
        JobQueueLogEntry."Object Type to Run" := JobQueueLogEntry."Object Type to Run"::Codeunit;
        JobQueueLogEntry."Object ID to Run" := CODEUNIT::"Import Config. Package Files";
        JobQueueLogEntry."Error Message" :=
          CopyStr(
            StrSubstNo(
              '%1 <%2>, %3 <%4>',
              LibraryUtility.GenerateRandomText(10), CompanyName,
              LibraryUtility.GenerateRandomText(10), PackageCode),
            1,
            MaxStrLen(JobQueueLogEntry."Error Message"));
        JobQueueLogEntry.Insert();
    end;

    [Scope('OnPrem')]
    procedure SetTaskID(TaskID: Guid)
    begin
        GlobalTaskID := TaskID;
    end;

    [Scope('OnPrem')]
    procedure SetSessionID(SessionID: Integer)
    begin
        GlobalSessionID := SessionID;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AllowedCompaniesReturnsDisplayNameModalHandler(var AllowedCompanies: TestPage "Allowed Companies")
    begin
        LibraryVariableStorage.Enqueue(AllowedCompanies.CompanyDisplayName.Value);
        AllowedCompanies.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobQueueLogModalHandler(var JobQueueLogEntries: TestPage "Job Queue Log Entries")
    begin
        JobQueueLogEntries.First;
        LibraryVariableStorage.Enqueue(JobQueueLogEntries.Status.AsInteger);
        JobQueueLogEntries.Next;
        LibraryVariableStorage.Enqueue(JobQueueLogEntries.Status.AsInteger);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickCompanyModalHandler(var AccessibleCompanies: TestPage "Accessible Companies")
    var
        CompanyNameToPick: Text;
    begin
        CompanyNameToPick := LibraryVariableStorage.DequeueText(); // should be set from test
        AccessibleCompanies.GotoKey(CompanyNameToPick);
        Assert.IsFalse(AccessibleCompanies.SetupStatus.Editable, 'SetupStatus.EDITABLE');
        LibraryVariableStorage.Enqueue(AccessibleCompanies.SetupStatus.AsInteger);
        AccessibleCompanies.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigPackageErrorsModalHandler(var ConfigPackageErrors: TestPage "Config. Package Errors")
    begin
        LibraryVariableStorage.Enqueue(ConfigPackageErrors.FILTER.GetFilter("Package Code"));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text)
    begin
        LibraryVariableStorage.Enqueue(Msg)
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyCompanySetGetNameRequestPageHandler(var CopyCompany: TestRequestPage "Copy Company")
    begin
        CopyCompany."New Company Name".SetValue(LibraryVariableStorage.DequeueText);
        LibraryVariableStorage.Enqueue(CopyCompany."New Company Name".Value);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Company Setup", 'OnBeforeScheduleTask', '', false, false)]
    local procedure OnBeforeScheduleTask(var DoNotScheduleTask: Boolean; var TaskID: Guid; var SessionID: Integer)
    begin
        DoNotScheduleTask := true;
        TaskID := GlobalTaskID;
        SessionID := GlobalSessionID;
    end;
}

