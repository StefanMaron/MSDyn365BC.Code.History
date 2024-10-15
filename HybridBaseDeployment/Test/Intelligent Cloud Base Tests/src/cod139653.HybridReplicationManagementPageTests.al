codeunit 139653 "Replication Mgt Page Tests"
{
    // [FEATURE] [Intelligent Edge Hybrid Management Page]
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize(IsSaas: Boolean)
    var
        HybridDeploymentSetup: Record "Hybrid Deployment Setup";
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        AssistedSetup: Codeunit "Assisted Setup";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        PermissionManager: Codeunit "Permission Manager";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(IsSaas);
        PermissionManager.SetTestabilityIntelligentCloud(true);
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
        AssistedSetup.Complete(Page::"Hybrid Cloud Setup Wizard");

        IntelligentCloudSetup.DeleteAll();
        IntelligentCloudSetup.Init();
        IntelligentCloudSetup."Product ID" := 'Dynamics BC';
        IntelligentCloudSetup."Company Creation Task Status" := IntelligentCloudSetup."Company Creation Task Status"::Completed;
        IntelligentCloudSetup."Deployed Version" := 'V1.0';
        IntelligentCloudSetup."Latest Version" := 'V2.0';
        IntelligentCloudSetup.Insert();

        if not Initialized then begin
            HybridDeploymentSetup.DeleteAll();
            HybridDeploymentSetup."Handler Codeunit ID" := Codeunit::"Library - Hybrid Management";
            HybridDeploymentSetup.Insert();
            BindSubscription(LibraryHybridManagement);
            HybridDeploymentSetup.Get();
        end else
            exit;

        Initialized := true;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,GeneralMessageHandler')]
    procedure TestRunReplicationNow()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        ReplicationManagementPage: TestPage "Intelligent Cloud Management";
    begin
        // [SCENARIO] User Opens up the Hybrid Replication Management Page and clicks 'Run Replication Now' button on the ribbon.

        // Remove Inprogress and Failed run records for past 24 hrs
        HybridReplicationSummary.SetFilter("Start Time", '>%1', (CurrentDateTime() - 86400000));
        if not HybridReplicationSummary.IsEmpty() then begin
            HybridReplicationSummary.SetRange("Trigger Type", HybridReplicationSummary."Trigger Type"::Manual);
            HybridReplicationSummary.SetFilter(Status, '<>%1', HybridReplicationSummary.Status::Failed);
            HybridReplicationSummary.DeleteAll();
        end;

        // [GIVEN] User Opens up the Hybrid Replication Management Page.
        Initialize(true);
        ReplicationManagementPage.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        with ReplicationManagementPage do
            // [WHEN] User clicks 'Run Replication Now' action in the ribbon.
            RunReplicationNow.Invoke();
    end;

    [Test]
    [HandlerFunctions('GetRuntimeKeyMessageHandler')]
    procedure TestGetRuntimeKey()
    var
        ReplicationManagementPage: TestPage "Intelligent Cloud Management";
    begin
        // [SCENARIO] User Opens up the Hybrid Replication Management Page and clicks 'Get Service Key' button on the ribbon.

        // [GIVEN] User Opens up the Hybrid Replication Management Page.
        Initialize(true);
        ReplicationManagementPage.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        with ReplicationManagementPage do
            // [WHEN] User clicks 'Get Service Key' action in the ribbon.
            GetRuntimeKey.Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,GenerateNewKeyMessageHandler')]
    procedure TestGenerateNewKey()
    var
        ReplicationManagementPage: TestPage "Intelligent Cloud Management";
    begin
        // [SCENARIO] User Opens up the Hybrid Replication Management Page and clicks 'Get Service Key' button on the ribbon.

        // [GIVEN] User Opens up the Hybrid Replication Management Page.
        Initialize(true);
        ReplicationManagementPage.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        with ReplicationManagementPage do
            // [WHEN] User clicks 'Get Service Key' action in the ribbon.
            GenerateNewKey.Invoke();
    end;

    [Test]
    [HandlerFunctions('ManageSchedulePageHandler')]
    procedure TestManageSchedule()
    var
        ReplicationManagementPage: TestPage "Intelligent Cloud Management";
    begin
        // [SCENARIO] User Opens up the Hybrid Replication Management Page and clicks 'Get Service Key' button on the ribbon.

        // [GIVEN] User Opens up the Hybrid Replication Management Page.
        Initialize(true);
        ReplicationManagementPage.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [WHEN] User clicks 'Manage Schedule' action in the ribbon.
        ReplicationManagementPage.ManageSchedule.Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,GeneralMessageHandler')]
    procedure TestRunReplication()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        ReplicationManagementPage: TestPage "Intelligent Cloud Management";
        ExpectedRunId: Text;
        ExpectedSource: Text;
    begin
        // [SCENARIO] User Opens up the Hybrid Replication Management Page and clicks 'Get Service Key' button on the ribbon.

        // [GIVEN] User Opens up the Hybrid Replication Management Page.
        Initialize(true);
        ReplicationManagementPage.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [GIVEN] Intelligent Cloud is set up
        SetupIntelligentCloud(ExpectedRunId, ExpectedSource);

        // [WHEN] User clicks 'Replicate Now' action in the ribbon.
        HybridReplicationSummary.DeleteAll();
        ReplicationManagementPage.RunReplicationNow.Invoke();

        // [THEN] A Replication Summary record is created that has InProgress status
        with HybridReplicationSummary do begin
            FindFirst();
            Assert.AreEqual(ExpectedRunId, "Run ID", 'Run ID');
            Assert.AreEqual(Status::InProgress, Status, 'Status');
            Assert.AreEqual(ExpectedSource, Source, 'Source');
            Assert.AreEqual("Trigger Type"::Manual, "Trigger Type", 'Trigger Type');
            Assert.AreEqual(ReplicationType::Full, ReplicationType, 'Replication Type');

            // [THEN] The correct replication type is passed to the service
            Assert.AreEqual(ReplicationType::Normal, LibraryHybridManagement.GetActualReplicationType(), 'Replication run type');
        end;
    end;

    [Test]
    procedure TestCreateDiagnosticRun()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        ReplicationManagementPage: TestPage "Intelligent Cloud Management";
        ExpectedRunId: Text;
        ExpectedSource: Text;
    begin
        // [SCENARIO] User can create a diagnostic/schema-only replication run

        // [GIVEN] The intelligent cloud is set up
        Initialize(true);
        HybridReplicationSummary.DeleteAll();
        SetupIntelligentCloud(ExpectedRunId, ExpectedSource);
        LibraryHybridManagement.SetDiagnosticRunsEnabled(true);

        // [WHEN] User Opens up the Hybrid Replication Management Page.
        ReplicationManagementPage.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [WHEN] User chooses to create a diagnostic run
        ReplicationManagementPage.RunDiagnostic.Invoke();

        // [THEN] A Replication Summary record is created that has InProgress status and Diagnostic Replication Type
        with HybridReplicationSummary do begin
            FindFirst();
            Assert.AreEqual(ExpectedRunId, "Run ID", 'Run ID');
            Assert.AreEqual(Status::InProgress, Status, 'Status');
            Assert.AreEqual(ExpectedSource, Source, 'Source');
            Assert.AreEqual("Trigger Type"::Manual, "Trigger Type", 'Trigger Type');
            Assert.AreEqual(ReplicationType::Diagnostic, ReplicationType, 'Replication Type');

            // [THEN] The correct replication type is passed to the service
            Assert.AreEqual(ReplicationType::Diagnostic, LibraryHybridManagement.GetActualReplicationType(), 'Replication run type');
        end;
    end;

    [Test]
    procedure CreateDiagnosticRunIsNotVisibleIfUnsupported()
    var
        ReplicationManagementPage: TestPage "Intelligent Cloud Management";
        ExpectedRunId: Text;
        ExpectedSource: Text;
    begin
        // [SCENARIO] User doesn't have ability to create diagnostic runs for unsupported products

        // [GIVEN] The intelligent cloud is set up for a product that doesn't support diagnostic runs
        Initialize(true);
        SetupIntelligentCloud(ExpectedRunId, ExpectedSource);
        LibraryHybridManagement.SetDiagnosticRunsEnabled(false);

        // [WHEN] User Opens up the Hybrid Replication Management Page.
        ReplicationManagementPage.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [THEN] The diagnostic run button is not visible
        Assert.IsFalse(ReplicationManagementPage.RunDiagnostic.Visible(), 'Diagnostic run button should not be visible.');
    end;

    [Test]
    procedure ManageCustomTablesIsNotVisibleIfUnsupported()
    var
        ReplicationManagementPage: TestPage "Intelligent Cloud Management";
        ExpectedRunId: Text;
        ExpectedSource: Text;
    begin
        // [SCENARIO] User doesn't have ability to manage custom tables for unsupported products

        // [GIVEN] The intelligent cloud is set up for a product that doesn't support custom table mapping
        Initialize(true);
        SetupIntelligentCloud(ExpectedRunId, ExpectedSource);
        LibraryHybridManagement.SetTableMappingEnabled(false);

        // [WHEN] User Opens up the Hybrid Replication Management Page.
        ReplicationManagementPage.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [THEN] The manage custom tables action is not visible
        Assert.IsFalse(ReplicationManagementPage.ManageCustomTables.Visible(), 'Manage Custom Tables should not be visible.');
    end;

    [Test]
    procedure TestOpenManageCustomTables()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        ReplicationManagementPage: TestPage "Intelligent Cloud Management";
        MigrationTableMapping: TestPage "Migration Table Mapping";
        ExpectedRunId: Text;
        ExpectedSource: Text;
    begin
        // [SCENARIO] User can manage custom table mappings to use in the migration

        // [GIVEN] The intelligent cloud is set up
        Initialize(true);
        HybridReplicationSummary.DeleteAll();
        SetupIntelligentCloud(ExpectedRunId, ExpectedSource);
        LibraryHybridManagement.SetTableMappingEnabled(true);

        // [WHEN] User Opens up the Hybrid Replication Management Page.
        ReplicationManagementPage.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [WHEN] User chooses to manage custom tables
        MigrationTableMapping.Trap();
        ReplicationManagementPage.ManageCustomTables.Invoke();

        // [THEN] The migration table mapping page is opened in edit mode
        Assert.IsTrue(MigrationTableMapping.Editable, 'Page should be editable');
    end;

    [Test]
    procedure ManageCustomTablesFailsForInvalidApp()
    var
        MigrationTableMappingRec: Record "Migration Table Mapping";
        MigrationTableMapping: TestPage "Migration Table Mapping";
    begin
        // [SCENARIO] User is not allowed to specify tables from apps that don't exist

        // [GIVEN] The intelligent cloud is set up
        Initialize(true);
        MigrationTableMappingRec.DeleteAll();

        // [WHEN] User chooses to manage custom tables
        MigrationTableMapping.Trap();
        Page.Run(Page::"Migration Table Mapping", MigrationTableMappingRec);

        // [WHEN] User enters bogus app name
        // [THEN] The page gives them an error because the app doesn't exist
        asserterror MigrationTableMapping."Extension Name".SetValue('My Nonexistent App');
    end;

    [Test]
    procedure ManageCustomTablesCanSetValidAppWithAbbreviation()
    var
        PublishedApplication: Record "Published Application";
        MigrationTableMappingRec: Record "Migration Table Mapping";
        MigrationTableMapping: TestPage "Migration Table Mapping";
    begin
        // [SCENARIO] User can enter a substring of the extension name, and the page will fill in the rest

        // [GIVEN] The intelligent cloud is set up
        Initialize(true);
        MigrationTableMappingRec.DeleteAll();

        // [GIVEN] At least one custom app exists
        PublishedApplication.Init();
        PublishedApplication."Runtime Package ID" := CreateGuid();
        PublishedApplication.ID := CreateGuid();
        PublishedApplication.Name := 'My Test App';
        PublishedApplication."Package ID" := CreateGuid();
        PublishedApplication.Insert(false);

        // [WHEN] User chooses to manage custom tables
        MigrationTableMapping.Trap();
        Page.Run(Page::"Migration Table Mapping", MigrationTableMappingRec);

        // [WHEN] The user enters the first few characters of their extensions and tabs off
        MigrationTableMapping."Extension Name".SetValue('My T');

        // [THEN] The page finds the correct extension
        MigrationTableMapping."Extension Name".AssertEquals('My Test App');
    end;

    [Test]
    procedure ManageCustomTablesPreventsInvalidAppAndTableNames()
    var
        MigrationTableMappingRec: Record "Migration Table Mapping";
    begin
        // [SCENARIO] UI prevents user from entering non-existent app and table name values

        // [GIVEN] The intelligent cloud is set up
        Initialize(true);
        MigrationTableMappingRec.DeleteAll();

        // [WHEN] User attempts to set invalid extension
        // [THEN] They get a validation error
        asserterror MigrationTableMappingRec.Validate("App ID", CreateGuid());

        // [WHEN] User attempts to set invalid table name
        // [THEN] They get a validation error
        MigrationTableMappingRec."App ID" := CreateGuid();
        asserterror MigrationTableMappingRec.Validate("Table Name", 'Foobar Table');
    end;

    [Test]
    procedure ManageCustomTablesHidesLockedRecords()
    var
        MigrationTableMappingRec: Record "Migration Table Mapping";
        MigrationTableMapping: TestPage "Migration Table Mapping";
    begin
        // [SCENARIO] Page filter hides any locked records

        // [GIVEN] The intelligent cloud is set up
        Initialize(true);
        MigrationTableMappingRec.DeleteAll();

        // [GIVEN] A few mappings already exist but are locked
        MigrationTableMappingRec.Init();
        MigrationTableMappingRec."App ID" := CreateGuid();
        MigrationTableMappingRec."Table ID" := 139653;
        MigrationTableMappingRec.Locked := true;
        MigrationTableMappingRec.Insert(false);

        MigrationTableMappingRec.Init();
        MigrationTableMappingRec."App ID" := CreateGuid();
        MigrationTableMappingRec."Table ID" := 139654;
        MigrationTableMappingRec.Locked := true;
        MigrationTableMappingRec.Insert(false);

        // [WHEN] User chooses to manage custom tables
        MigrationTableMapping.Trap();
        Page.Run(Page::"Migration Table Mapping", MigrationTableMappingRec);

        // [THEN] The list appears empty
        Assert.IsFalse(MigrationTableMapping.First(), 'No records expected in the page view.');
    end;

    [Test]
    procedure ManageCustomTablesDeleteAllForApp()
    var
        MigrationTableMappingRec: Record "Migration Table Mapping";
        MigrationTableMapping: TestPage "Migration Table Mapping";
        AppId: Guid;
    begin
        // [SCENARIO] User can choose to delete all mapping records for a given extension

        // [GIVEN] The intelligent cloud is set up
        Initialize(true);
        MigrationTableMappingRec.DeleteAll();
        AppId := CreateGuid();

        // [GIVEN] A few mappings already exist
        MigrationTableMappingRec.Init();
        MigrationTableMappingRec."App ID" := AppId;
        MigrationTableMappingRec."Table ID" := 139653;
        MigrationTableMappingRec.Insert(false);

        MigrationTableMappingRec.Init();
        MigrationTableMappingRec."App ID" := AppId;
        MigrationTableMappingRec."Table ID" := 139654;
        MigrationTableMappingRec.Insert(false);

        // [WHEN] User chooses to manage custom tables
        MigrationTableMapping.Trap();
        Page.Run(Page::"Migration Table Mapping", MigrationTableMappingRec);

        // [WHEN] User chooses to delete all mappings for an extension
        MigrationTableMapping.First();
        MigrationTableMapping.DeleteAllForExtension.Invoke();

        // [THEN] The records are removed from the table
        Assert.IsTrue(MigrationTableMappingRec.IsEmpty(), 'Mapping table should be empty.');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure TestIntelligentCloudManagementPagewithUpdateNotification()
    var
        ReplicationManagementPage: TestPage "Intelligent Cloud Management";
    begin
        // [SCENARIO] User Opens up the Intelligent Cloud Management Page when update notification is available.

        // [GIVEN] User Opens up the Intelligent Cloud Management Page.
        Initialize(true);
        ReplicationManagementPage.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [THEN] Check for Update action should be enabled
        with ReplicationManagementPage do
            Assert.IsTrue(CheckForUpdate.Enabled(), 'Check for update action should be enabled');
    end;

    [Test]
    [HandlerFunctions('RunUpdateMessageHandler')]
    procedure TestIntelligentCloudUpdate()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        IntelligentCloudUpdatePage: TestPage "Intelligent Cloud Update";
    begin
        // [SCENARIO] User Opens up the Intelligent Cloud Update Page and clicks 'Update' button.

        // [GIVEN] User Opens up the Intelligent Cloud Update Page.
        Initialize(true);
        IntelligentCloudUpdatePage.Trap();
        Page.Run(Page::"Intelligent Cloud Update");

        // [THEN] Intelligent Cloud pipeline upgrade is run
        with IntelligentCloudUpdatePage do begin
            Assert.IsTrue(ActionUpdate.Enabled(), 'Update action should be enabled');
            ActionUpdate.Invoke();
        end;

        // [THEN] The Deployed Version in Intelligent Cloud Setup should be udpated to Latest Version
        if IntelligentCloudSetup.Get() then
            Assert.AreEqual('V2.0', IntelligentCloudSetup."Deployed Version", 'Deployed version is not updated.');
    end;

    [Test]
    [HandlerFunctions('DisableIntelligentCloudPageHandler')]
    procedure TestDisableIntelligentCloud()
    var
        ReplicationManagementPage: TestPage "Intelligent Cloud Management";
    begin
        // [SCENARIO] User can choose to disable intelligent cloud on the ribbon

        // [GIVEN] User Opens up the Hybrid Replication Management Page.
        Initialize(true);
        ReplicationManagementPage.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [WHEN] User clicks the 'Disable Replication' action in the ribbon.
        ReplicationManagementPage.DisableIntelligentCloud.Invoke();
    end;

    [Test]
    procedure TestUpdateStatusForInProgressRuns()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        ReplicationManagementPage: TestPage "Intelligent Cloud Management";
        RunId: Text;
        Status: Text;
        Errors: Text;
    begin
        // [SCENARIO 291819] User can refresh replication status for in-progress runs
        // [GIVEN] There is at least one in-progress record in the Replication Summary table
        RunId := CreateGuid();
        HybridReplicationSummary.CreateInProgressRecord(RunId, HybridReplicationSummary.ReplicationType::Normal);

        // [GIVEN] The replication run has finished since the page was last updated
        Status := Format(HybridReplicationSummary.Status::Failed);
        Errors := '"The thing failed"';
        LibraryHybridManagement.SetExpectedRunId(RunId);
        LibraryHybridManagement.SetExpectedStatus(Status, Errors);

        // [WHEN] The user opens the Hybrid Replication Management page in a SaaS environment
        Initialize(true);
        ReplicationManagementPage.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [WHEN] and chooses the "Refresh Status" action
        ReplicationManagementPage.RefreshStatus.Invoke();

        // [THEN] The InProgress runs that have finished are updated accordingly
        ReplicationManagementPage.Last();
        ReplicationManagementPage.Status.AssertEquals(Format(HybridReplicationSummary.Status::Failed));
        ReplicationManagementPage.Details.AssertEquals('The thing failed');
    end;

    [Test]
    procedure TestIncompatibleSchemaMessageText()
    var
        HybridMessageManagement: Codeunit "Hybrid Message Management";
        Message: Text;
        Message2: Text;
        InnerMessage: Text;
    begin
        InnerMessage := '[No_]PK,|[Description]T,L,|[Statistics Group]L,';
        Message := HybridMessageManagement.ResolveMessageCode('50011', InnerMessage);
        Assert.AreNotEqual('', Message, 'Message not resolved for 50011');
        Assert.AreNotEqual(InnerMessage, Message, 'Message not resolved for 50011');

        InnerMessage := '[No_]PK,|[Description]T,|[Statistics Group]L,';
        Message2 := HybridMessageManagement.ResolveMessageCode('50011', InnerMessage);
        Assert.AreNotEqual(Message, Message2, 'InnerMessage not parsed correctly');
    end;

    [Test]
    procedure TestOnPremActionVisible()
    var
        ReplicationManagementPage: TestPage "Intelligent Cloud Management";
    begin
        // [SCENARIO] User opens Hybrid Replication Mananagement page from on-premise.

        // [GIVEN] User opens the Hybrid Replication Management page.
        Initialize(false);
        ReplicationManagementPage.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [THEN] Verify On-premise actions.
        VerifyActionsVisibleState(ReplicationManagementPage, false);
    end;

    [Test]
    procedure TestSaasActionsVisible()
    var
        ReplicationManagementPage: TestPage "Intelligent Cloud Management";
    begin
        // [SCENARIO] User opens Hybrid Replication Mananagement page from cloud.

        // [GIVEN] User opens the Hybrid Replication Management page.
        Initialize(true);
        ReplicationManagementPage.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [THEN] Verify cloud actions.
        VerifyActionsVisibleState(ReplicationManagementPage, true);
    end;

    [Test]
    [HandlerFunctions('UpdateCompanySelectionMessageHandler')]
    procedure TestCompanySelectionUpdate()
    var
        HybridCompany: Record "Hybrid Company";
        HybridCompaniesManagement: TestPage "Hybrid Companies Management";
        SelectCompany: text[50];
    begin
        // [SCENARIO] User selects a company to replicate from the 'Hybrid Companies Management' page and clicks 'Update'.

        // [GIVEN] Companies have been synchronized from on-premise.
        SelectCompany := 'Not Selected Company';
        SetupTestHybridCompanies();

        // [GIVEN] User Opens up the Hybrid Replication Management Page.
        Initialize(true);
        HybridCompaniesManagement.Trap();
        Page.Run(Page::"Hybrid Companies Management");

        // [WHEN] User selects a company to replicate and clicks 'OK'
        SelectCompanyName(HybridCompaniesManagement, SelectCompany);
        HybridCompaniesManagement.Replicate.SetValue(true);
        HybridCompaniesManagement.OK.Invoke();

        // [THEN] The company is successfully marked to replicate.
        HybridCompany.Get(SelectCompany);
        Assert.AreEqual(true, HybridCompany.Replicate, 'Company should be selected for replication.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure TestCompanySelectionCanceled()
    var
        HybridCompany: Record "Hybrid Company";
        HybridCompaniesManagement: TestPage "Hybrid Companies Management";
        SelectCompany: text[50];
    begin
        // [SCENARIO] User selects a company to replicate from the 'Hybrid Companies Management' page and clicks 'Cancel'.

        // [GIVEN] Companies have been synchronized from on-premise.
        SelectCompany := 'Not Selected Company';
        SetupTestHybridCompanies();

        // [GIVEN] User Opens up the Hybrid Replication Management Page.
        Initialize(true);
        HybridCompaniesManagement.Trap();
        Page.Run(Page::"Hybrid Companies Management");

        // [WHEN] User selects a company to replicate and clicks 'Cancel'
        SelectCompanyName(HybridCompaniesManagement, SelectCompany);
        HybridCompaniesManagement.Replicate.SetValue(true);
        HybridCompaniesManagement.Cancel.Invoke();

        // [THEN] The company is wasn't selected to replicate.
        HybridCompany.Get(SelectCompany);
        Assert.AreEqual(false, HybridCompany.Replicate, 'Company should NOT be selected for replication.');
    end;

    [Test]
    procedure TestNoCompaniesSelectedForReplication()
    var
        HybridCompaniesManagement: TestPage "Hybrid Companies Management";
    begin
        // [SCENARIO] User un-selects all companies to replicate from the 'Hybrid Companies Management' page.

        // [GIVEN] Companies have been synchronized from on-premise.
        SetupTestHybridCompanies();

        // [GIVEN] User Opens up the Hybrid Replication Management Page.
        Initialize(true);
        HybridCompaniesManagement.Trap();
        Page.Run(Page::"Hybrid Companies Management");

        // [WHEN] User selects each company to NOT replicate and clicks 'OK'
        HybridCompaniesManagement.First();
        repeat
            HybridCompaniesManagement.Replicate.SetValue(false);
        until not HybridCompaniesManagement.Next();

        asserterror HybridCompaniesManagement.OK.Invoke();

        // [THEN] The error displayed that at lease one company has to be selected.
        Assert.ExpectedError('You must select at least one company to migrate to continue.');
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(question: Text[1024]; var reply: Boolean)
    begin
        reply := true;
    end;

    [MessageHandler]
    procedure UpdateCompanySelectionMessageHandler(message: Text[1024])
    begin
        // [THEN] The expected message is returned to the user
        Assert.AreEqual('Company selection changes will be reflected on your next migration.', message, 'Company selection update message incorrect.');
    end;

    [MessageHandler]
    procedure RunReplicationNowMessageHandler(message: Text[1024])
    begin
        // [THEN] The expected message is incorrect
        Assert.AreEqual(RunReplicationTxt, message, 'Incorrect message.');
    end;

    [MessageHandler]
    procedure GetRuntimeKeyMessageHandler(message: Text[1024])
    begin
        // [THEN] The runtime integration key is returned to the user
        Assert.AreEqual(StrSubstNo(IntegrationKeyTxt, TestPrimaryKeyTxt), message, 'The incoming integration runtime id is not correct.');
    end;

    [MessageHandler]
    procedure GenerateNewKeyMessageHandler(message: Text[1024])
    begin
        // [THEN] The runtime integration key is returned to the user
        Assert.AreEqual(StrSubstNo(NewIntegrationKeyTxt, TestPrimaryKeyTxt), message, 'The incoming integration runtime id is not correct.');
    end;

    [MessageHandler]
    procedure GeneralMessageHandler(message: Text[1024])
    begin
    end;

    [MessageHandler]
    procedure RunUpdateMessageHandler(message: Text[1024])
    begin
        // [THEN] The expected update run message is returned to the user
        Assert.AreEqual(UpdateReplicationTxt, message, 'The run update message is not correct.');
    end;

    [PageHandler]
    procedure ManageSchedulePageHandler(var manageSchedule: TestPage "Intelligent Cloud Schedule")
    begin
        Assert.IsTrue(manageSchedule.Editable(), 'Manage schedule page should be enabled.'); //we can add more tests for the manage schedule page

        // Verify Schedule days are not visible.
        manageSchedule.Recurrence.SetValue(RecurrenceOption::Daily);
        Assert.IsFalse(manageSchedule.Sunday.Visible(), 'Schedule window Sunday should be visable.');
        Assert.IsFalse(manageSchedule.Monday.Visible(), 'Schedule window Monay should be disabled.');
        Assert.IsFalse(manageSchedule.Tuesday.Visible(), 'Schedule window Tuesday should be disabled.');
        Assert.IsFalse(manageSchedule.Wednesday.Visible(), 'Schedule window Wednesday should be disabled.');
        Assert.IsFalse(manageSchedule.Thursday.Visible(), 'Schedule window Thursday should be disabled.');
        Assert.IsFalse(manageSchedule.Friday.Visible(), 'Schedule window Friday should be disabled.');
        Assert.IsFalse(manageSchedule.Saturday.Visible(), 'Schedule window Saturday should be disabled.');

        // Verify Schedule days are visible.
        manageSchedule.Recurrence.SetValue(RecurrenceOption::Weekly);
        Assert.IsTrue(manageSchedule.Sunday.Visible(), 'Schedule window Sunday should be enabled. Run %1');
        Assert.IsTrue(manageSchedule.Monday.Visible(), 'Schedule window Monay should be enabled. Run %1');
        Assert.IsTrue(manageSchedule.Tuesday.Visible(), 'Schedule window Tuesday should be enabled. Run %1');
        Assert.IsTrue(manageSchedule.Wednesday.Visible(), 'Schedule window Wednesday should be enabled. Run %1');
        Assert.IsTrue(manageSchedule.Thursday.Visible(), 'Schedule window Thursday should be enabled. Run %1');
        Assert.IsTrue(manageSchedule.Friday.Visible(), 'Schedule window Friday should be enabled. Run %1');
        Assert.IsTrue(manageSchedule.Saturday.Visible(), 'Schedule window Saturday should be enabled. Run %1');
    end;

    [PageHandler]
    procedure DisableIntelligentCloudPageHandler(var hybridCloudReady: TestPage "Intelligent Cloud Ready")
    begin
        Assert.IsTrue(hybridCloudReady.Editable(), 'Intelligent Cloud Ready page should be enabled.');
    end;

    [SendNotificationHandler]
    procedure SendNotificationHandler(var Notification: Notification): Boolean;
    begin
        Assert.AreEqual(ICUpdateAvailableTxt, Notification.Message(), 'Update available notification message was different than expected');
    end;

    local procedure VerifyActionsVisibleState(ReplicationManagementPage: TestPage "Intelligent Cloud Management"; IsSaas: Boolean)
    begin
        // Cloud only actions.
        Assert.AreEqual(IsSaas, ReplicationManagementPage.ManageSchedule.Visible(), 'ManageSchedule should be visible.');
        Assert.AreEqual(IsSaas, ReplicationManagementPage.RefreshStatus.Visible(), 'RefreshStatus should be visible.');
        Assert.AreEqual(IsSaas, ReplicationManagementPage.GetRuntimeKey.Visible(), 'GetRuntimeKey should be visible.');
        Assert.AreEqual(IsSaas, ReplicationManagementPage.DisableIntelligentCloud.Visible(), 'DisableIntelligentCloud should be visible.');
        Assert.AreEqual(IsSaas, ReplicationManagementPage.UpdateReplicationCompanies.Visible(), 'UpdateReplicationCompanies should be visible.');
        Assert.AreEqual(IsSaas, ReplicationManagementPage.RunReplicationNow.Visible(), 'RunReplicationNow should be visible.');
        Assert.AreEqual(IsSaas, ReplicationManagementPage.ResetAllCloudData.Visible(), 'ResetAllCloudData should be visible.');
        Assert.AreEqual(IsSaas, ReplicationManagementPage.GenerateNewKey.Visible(), 'GenerateNewKey should be visible.');
        Assert.AreEqual(IsSaas, ReplicationManagementPage.CheckForUpdate.Visible(), 'CheckForUpdate should be visible.');

        // On-Premise actions.
        Assert.AreEqual(not IsSaas, ReplicationManagementPage.PrepareTables.Visible(), 'PrepareTables should be visible.');
    end;

    local procedure SetupTestHybridCompanies()
    begin
        CreateOrUpdateHybridCompany('Not Selected Company', 'Company not selected for replication', false);
        CreateOrUpdateHybridCompany('Replicated Company', 'Selected replicated company', true);
        CreateOrUpdateHybridCompany('Another Not Selected Company', 'Another company not selected for replication', false);
    end;

    local procedure CreateOrUpdateHybridCompany(Name: text[50]; DisplayName: text[250]; Replicate: Boolean)
    var
        HybridCompany: Record "Hybrid Company";
    begin
        HybridCompany.Init();
        if HybridCompany.Get(Name) then begin
            HybridCompany."Display Name" := DisplayName;
            HybridCompany.Replicate := Replicate;
            HybridCompany.Modify();
        end else begin
            HybridCompany.Name := Name;
            HybridCompany."Display Name" := DisplayName;
            HybridCompany.Replicate := Replicate;
            HybridCompany.Insert();
        end;
    end;

    local procedure SelectCompanyName(var HybridCompaniesManagement: TestPage "Hybrid Companies Management"; CompanyName: text[50])
    begin
        HybridCompaniesManagement.First();
        if HybridCompaniesManagement.Name.Value() <> CompanyName then
            repeat
                HybridCompaniesManagement.Next();
            until HybridCompaniesManagement.Name.Value() = CompanyName;
    end;

    local procedure SetupIntelligentCloud(var ExpectedRunId: Text; var ExpectedSource: Text)
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
    begin
        LibraryHybridManagement.SetExpectedRunId(ExpectedRunId);
        LibraryHybridManagement.SetExpectedProduct(ExpectedSource);
        IntelligentCloudSetup.Get();
        IntelligentCloudSetup."Product ID" := CopyStr(ExpectedSource, 1, 250);
        IntelligentCloudSetup."Company Creation Task Status" := IntelligentCloudSetup."Company Creation Task Status"::Completed;
        IntelligentCloudSetup.Modify();
    end;

    var
        Assert: Codeunit Assert;
        LibraryHybridManagement: Codeunit "Library - Hybrid Management";
        Initialized: Boolean;
        RecurrenceOption: Option Daily,Weekly;
        RunReplicationTxt: Label 'Replication has been successfully triggered; you can track the status on the management page.';
        IntegrationKeyTxt: Label 'Primary key for the integration runtime is: %1', Comment = '%1 = Integration Runtime Key';
        NewIntegrationKeyTxt: Label 'New Primary key for the integration runtime is: %1', Comment = '%1 = Integration Runtime Key';
        TestPrimaryKeyTxt: Label 'TestPrimaryKey';
        ICUpdateAvailableTxt: Label 'An update is available for the Cloud Migration.';
        UpdateReplicationTxt: Label 'The update has completed successfully.';
}
