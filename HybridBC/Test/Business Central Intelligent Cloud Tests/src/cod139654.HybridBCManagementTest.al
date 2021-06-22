codeunit 139654 "HybridBC Management Test"
{
    // [FEATURE] [Intelligent Edge Hybrid Business Central Wizard]
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryHybridManagement: Codeunit "Library - Hybrid Management";
        Initialized: Boolean;
        SubscriptionIdTxt: Label 'DynamicsBC_IntelligentCloud';
        ServiceSubscriptionIdTxt: Label 'IntelligentCloudService_DynamicsBC';

    [Test]
    procedure InsertSummaryOnWebhookNotificationInsertForSubscription()
    begin
        InsertSummaryOnWebhookNotificationInsert(SubscriptionIdTxt);
    end;

    [Test]
    procedure InsertSummaryOnWebhookNotificationInsertForServiceSubscription()
    begin
        InsertSummaryOnWebhookNotificationInsert(ServiceSubscriptionIdTxt);
    end;

    local procedure InsertSummaryOnWebhookNotificationInsert(SubscriptionId: Text)
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridBCWizard: Codeunit "Hybrid BC Wizard";
        RunId: Text;
        StartTime: DateTime;
        TriggerType: Text;
    begin
        // [GIVEN] A Webhook Subscription exists for DynamicsBC
        Initialize();

        // [WHEN] A notification record is inserted
        TriggerType := 'Scheduled';
        InsertNotification(SubscriptionId, RunId, StartTime, TriggerType, HybridReplicationSummary.ReplicationType::Diagnostic, '');

        // [THEN] A Hybrid Replication Summary record is created
        HybridReplicationSummary.Get(RunId);
        with HybridReplicationSummary do begin
            Assert.AreEqual(Source, HybridBCWizard.ProductName(), 'Unexpected value in summary for source.');
            Assert.AreEqual("Run ID", RunId, 'Unexpected value in summary for Run ID.');
            Assert.AreEqual("Start Time", StartTime, 'Unexpected value in summary for Start Time.');
            Assert.AreEqual("Trigger Type", "Trigger Type"::Scheduled, 'Unexpected value in summary for Trigger Type.');
            Assert.AreEqual(ReplicationType, ReplicationType::Diagnostic, 'Unexpected value in summary for Replication Type.');
        end;
    end;

    [Test]
    procedure InsertSummaryWithDetailsOnWebhookNotificationInsertForSubscription()
    begin
        InsertSummaryWithDetailsOnWebhookNotificationInsert(SubscriptionIdTxt);
    end;

    [Test]
    procedure InsertSummaryWithDetailsOnWebhookNotificationInsertForServiceSubscription()
    begin
        InsertSummaryWithDetailsOnWebhookNotificationInsert(ServiceSubscriptionIdTxt);
    end;

    [Test]
    procedure CreateDiagnosticRunActionIsAvailable()
    var
        IntelligentCloudManagement: TestPage "Intelligent Cloud Management";
    begin
        // [SCENARIO] The option to create a diagnostic run from the management page is available

        // [GIVEN] Intelligent cloud is set up for Business Central
        Initialize();

        // [WHEN] The Intelligent Cloud Management page is launched
        IntelligentCloudManagement.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [THEN] The action to create a diagnostic run is available
        Assert.IsTrue(IntelligentCloudManagement.RunDiagnostic.Visible(), 'Diagnostic run action is not visible');
        Assert.IsTrue(IntelligentcloudManagement.RunDiagnostic.Enabled(), 'Diagnostic run action is not enabled');
    end;

    [Test]
    procedure MapUsersActionIsAvailable()
    var
        HybridCompany: Record "Hybrid Company";
        IntelligentCloudManagement: TestPage "Intelligent Cloud Management";
    begin
        // [SCENARIO] The option to map users from the management page is available

        // [GIVEN] Intelligent cloud is set up for Business Central
        Initialize();

        // [GIVEN] User is signed in to a replicated company
        if HybridCompany.Get(CompanyName()) then
            HybridCompany.Delete();

        HybridCompany.Init();
        HybridCompany.Name := CopyStr(CompanyName(), 1, 50);
        HybridCompany.Replicate := true;
        HybridCompany.Insert();

        // [WHEN] The Intelligent Cloud Management page is launched
        IntelligentCloudManagement.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [THEN] The action to map users is available
        Assert.IsTrue(IntelligentCloudManagement.MapUsers.Visible(), 'Map users action is not visible');
        Assert.IsTrue(IntelligentcloudManagement.MapUsers.Enabled(), 'Map users action is not enabled');
    end;

    [Test]
    procedure SetupChecklistActionIsAvailable()
    var
        HybridCompany: Record "Hybrid Company";
        IntelligentCloudManagement: TestPage "Intelligent Cloud Management";
    begin
        // [SCENARIO] The option to run the setup checklist from the management page is available

        // [GIVEN] Intelligent cloud is set up for Business Central
        Initialize();

        // [GIVEN] User is signed in to a replicated company
        if HybridCompany.Get(CompanyName()) then
            HybridCompany.Delete();

        HybridCompany.Init();
        HybridCompany.Name := CopyStr(CompanyName(), 1, 50);
        HybridCompany.Replicate := true;
        HybridCompany.Insert();

        // [WHEN] The Intelligent Cloud Management page is launched
        IntelligentCloudManagement.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [THEN] The action to run the setup checklist is available
        Assert.IsTrue(IntelligentCloudManagement.SetupChecklist.Visible(), 'Setup checklist action is not visible');
        Assert.IsTrue(IntelligentcloudManagement.SetupChecklist.Enabled(), 'Setup checklist action is not enabled');
    end;

    [Test]
    procedure TableMappingActionIsAvailable()
    var
        IntelligentCloudManagement: TestPage "Intelligent Cloud Management";
    begin
        // [SCENARIO] The "Manage Custom Tables" action is visible and enabled for BC migrations.

        // [GIVEN] Intelligent cloud is set up for Business Central
        Initialize();

        // [WHEN] The Intelligent Cloud Management page is launched
        IntelligentCloudManagement.Trap();
        Page.Run(Page::"Intelligent Cloud Management");

        // [THEN] The action to manage mapped tables is enabled and visible
        Assert.IsTrue(IntelligentCloudManagement.ManageCustomTables.Visible(), 'Map tables action is not visible');
        Assert.IsTrue(IntelligentcloudManagement.ManageCustomTables.Enabled(), 'Map tables action is not enabled');
    end;

    [Test]
    procedure TablesNotMigratedCueIsVisible()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        IntelligentCloudStatFactbox: TestPage "Intelligent Cloud Stat Factbox";
    begin
        // [SCENARIO] The Tables not Migrated cue appears on the management page

        // [GIVEN] Intelligent cloud is set up for Business Central
        Initialize();
        if not HybridReplicationSummary.FindFirst() then begin
            HybridReplicationSummary.Init();
            HybridReplicationSummary."Run ID" := CreateGuid();
            HybridReplicationSummary.Insert();
        end;

        // [WHEN] The Intelligent Cloud Management factbox page is launched
        IntelligentCloudStatFactbox.Trap();
        Page.Run(Page::"Intelligent Cloud Stat Factbox");

        // [THEN] The Tables not Migrated cue is available
        Assert.IsTrue(IntelligentCloudStatFactbox."Tables not Migrated".Visible(), 'Tables not Migrated is not visible');
    end;


    local procedure InsertSummaryWithDetailsOnWebhookNotificationInsert(SubscriptionId: Text)
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridBCWizard: Codeunit "Hybrid BC Wizard";
        RunId: Text;
        StartTime: DateTime;
        TriggerType: Text;
    begin
        // [GIVEN] A Webhook Subscription exists for DynamicsBC
        Initialize();

        // [WHEN] A notification record is inserted
        TriggerType := 'Scheduled';
        InsertNotification(SubscriptionId, RunId, StartTime, TriggerType, HybridReplicationSummary.ReplicationType::Diagnostic, 'INIT');

        // [THEN] A Hybrid Replication Summary record is created
        HybridReplicationSummary.Get(RunId);
        with HybridReplicationSummary do begin
            Assert.AreEqual(Source, HybridBCWizard.ProductName(), 'Unexpected value in summary for source.');
            Assert.AreEqual("Run ID", RunId, 'Unexpected value in summary for Run ID.');
            Assert.AreEqual("Start Time", StartTime, 'Unexpected value in summary for Start Time.');
            Assert.AreEqual("Trigger Type", "Trigger Type"::Scheduled, 'Unexpected value in summary for Trigger Type.');
            Assert.AreEqual(ReplicationType, ReplicationType::Diagnostic, 'Unexpected value in summary for Replication Type.');
            Assert.IsTrue(Details.HasValue(), 'Details should contain text.');
        end;
    end;

    [Test]
    procedure InsertDetailsOnWebhookNotificationInsertForSubscription()
    begin
        UpdateDetailsOnWebhookNotificationInsert(SubscriptionIdTxt);
    end;

    [Test]
    procedure InsertDetailsOnWebhookNotificationInsertForServiceSubscription()
    begin
        UpdateDetailsOnWebhookNotificationInsert(ServiceSubscriptionIdTxt);
    end;

    local procedure UpdateDetailsOnWebhookNotificationInsert(SubscriptionId: Text)
    var
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        HybridMessageManagement: Codeunit "Hybrid Message Management";
        RunId: Text;
        StartTime: DateTime;
        TriggerType: Text;
        ExpectedMessage: Text;
        ErrorCodes: array[4] of Text[10];
        i: Integer;
    begin
        RunId := CreateGuid();
        InitializeIntelligentCloudTableStatusTable(RunId);

        // [GIVEN] A Webhook Subscription exists for DynamicsBC
        Initialize();

        // [GIVEN] Replication detail records have been populated by the pipeline
        ErrorCodes[1] := '50001';
        ErrorCodes[2] := '50002';
        ErrorCodes[3] := '50004';
        ErrorCodes[4] := '50005';
        for i := 1 to 4 do begin
            HybridReplicationDetail.Init();
            HybridReplicationDetail."Run ID" := RunId;
            HybridReplicationDetail."Table Name" := StrSubstNo('Table %1', i);
            HybridReplicationDetail."Company Name" := CopyStr(CompanyName(), 1, 30);
            HybridReplicationDetail."Error Code" := ErrorCodes[i];
            HybridReplicationDetail.Insert();
        end;

        // [WHEN] A replication notification is sent to Business Central
        InsertNotification(SubscriptionId, RunId, StartTime, TriggerType, 1, '');

        // [THEN] The Hybrid Replication Detail records have the Error Message field set
        for i := 1 to 4 do
            with HybridReplicationDetail do begin
                ExpectedMessage := HybridMessageManagement.ResolveMessageCode(ErrorCodes[i], '');
                Get(RunId, StrSubstNo('Table %1', i), CompanyName());
                Assert.AreNotEqual('', "Error Message", 'Error message should not be empty.');
                Assert.AreEqual(ExpectedMessage, "Error Message", 'Error message did not get properly translated.');
            end;
    end;

    [Test]
    procedure TestGetHybridBCProductName()
    var
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        HybridBCWiard: Codeunit "Hybrid BC Wizard";
        ProductName: Text;
    begin
        // [GIVEN] Dynamics BC is set up as the intelligent cloud product
        Initialize();

        // [WHEN] The GetChosenProductName method is called
        ProductName := HybridCloudManagement.GetChosenProductName();

        // [THEN] The returned value is set to the Business Central product name.
        Assert.AreEqual(HybridBCWiard.ProductName(), ProductName, 'Incorrect product name returned.');
    end;

    [Test]
    procedure VerifyGetMessageText()
    var
        HybridMessageManagement: Codeunit "Hybrid Message Management";
        Message: Text;
        InnerMessage: Text;
        i: Integer;
    begin
        for i := 50001 to 50007 do begin
            Message := HybridMessageManagement.ResolveMessageCode(CopyStr(Format(i), 1, 10), '');
            Assert.AreNotEqual('', Message, StrSubstNo('No message provided for code %1', i));

            if i in [50001, 50002, 50004, 50005, 50006, 50007] then begin
                InnerMessage := StrSubstNo('blah blah SqlErrorNumber=%1, blah blah', i);
                Message := HybridMessageManagement.ResolveMessageCode('', InnerMessage);
                Assert.AreNotEqual('', Message, StrSubstNo('Unable to resolve sql error for code %1', i));
                Assert.AreNotEqual(InnerMessage, Message, StrSubstNo('Unable to resolve sql error for code %1', i));
            end;
        end;
    end;

    [Test]
    procedure UpdateLatestVersionOnServiceWebhookNotificationInsert()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
    begin
        // [GIVEN] A Webhook Service Subscription exists for DynamicsBC
        Initialize();

        // [WHEN] A service notification record is inserted
        InsertServiceNotification('UpgradeAvailable', '3.1.1');

        // [THEN] The available latest version is updated.
        IntelligentCloudSetup.Get();
        Assert.AreEqual('3.1.1', IntelligentCloudSetup."Latest Version", 'Latest version available is not updated on service webhook notification.');
    end;

    local procedure Initialize()
    var
        WebhookSubscription: Record "Webhook Subscription";
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PermissionManager: Codeunit "Permission Manager";
        HybridBCWizard: Codeunit "Hybrid BC Wizard";
    begin
        if Initialized then
            exit;

        WebhookSubscription.DeleteAll();
        WebhookSubscription.Init();
        WebhookSubscription."Subscription ID" := COPYSTR(SubscriptionIdTxt, 1, 150);
        WebhookSubscription.Endpoint := 'Hybrid';
        WebhookSubscription.Insert();

        WebhookSubscription.Init();
        WebhookSubscription."Subscription ID" := COPYSTR(ServiceSubscriptionIdTxt, 1, 150);
        WebhookSubscription.Endpoint := 'Hybrid';
        WebhookSubscription.Insert();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        PermissionManager.SetTestabilityIntelligentCloud(true);
        LibraryHybridManagement.SetDiagnosticRunsEnabled(true);

        IntelligentCloudSetup."Product ID" := HybridBCWizard.ProductId();
        IF NOT IntelligentCloudSetup.Insert() then
            IntelligentCloudSetup.Modify();

        BindSubscription(LibraryHybridManagement);
        Initialized := true;
    end;

    local procedure AdditionalNotificationText(MessageCode: Code[10]) Json: Text
    begin
        if MessageCode <> '' then
            Json := ', "Code": "' + MessageCode + '"';
    end;

    local procedure InsertNotification(SubscriptionId: Text; var RunId: Text; var StartTime: DateTime; var TriggerType: Text; ReplicationType: Integer; MessageCode: Code[10])
    var
        WebhookNotification: Record "Webhook Notification";
        NotificationStream: OutStream;
        NotificationText: Text;
    begin
        NotificationText := LibraryHybridManagement.GetNotificationPayload(SubscriptionId, RunId, StartTime, TriggerType, ReplicationType, AdditionalNotificationText(MessageCode));
        WebhookNotification.Init();
        WebhookNotification.ID := CreateGuid();
        WebhookNotification."Subscription ID" := CopyStr(SubscriptionIdTxt, 1, 150);
        WebhookNotification.Notification.CreateOutStream(NotificationStream, TextEncoding::UTF8);
        NotificationStream.WriteText(NotificationText);
        WebhookNotification.Insert(true);
    end;

    local procedure InsertServiceNotification(ServiceType: Text; Version: Text)
    var
        WebhookNotification: Record "Webhook Notification";
        NotificationStream: OutStream;
        NotificationText: Text;
    begin
        NotificationText := LibraryHybridManagement.GetServiceNotificationPayload(ServiceSubscriptionIdTxt, ServiceType, Version);
        WebhookNotification.Init();
        WebhookNotification.ID := CreateGuid();
        WebhookNotification."Subscription ID" := CopyStr(ServiceSubscriptionIdTxt, 1, 150);
        WebhookNotification.Notification.CreateOutStream(NotificationStream, TextEncoding::UTF8);
        NotificationStream.WriteText(NotificationText);
        WebhookNotification.Insert(true);
    end;

    local procedure InitializeIntelligentCloudTableStatusTable(RunId: Text)
    var
        IntelligentCloudTableStatus: Record "Intelligent Cloud Table Status";
    begin
        IntelligentCloudTableStatus.DeleteAll();
        IntelligentCloudTableStatus.Init();
        IntelligentCloudTableStatus."Run ID" := RunId;
        IntelligentCloudTableStatus."Table Name" := 'Good Table';
        IntelligentCloudTableStatus."Company Name" := CompanyName();
        IntelligentCloudTableStatus."New Version" := 100;
        IntelligentCloudTableStatus."Error Code" := '';
        IntelligentCloudTableStatus."Error Message" := '';
        IntelligentCloudTableStatus.Insert();

        IntelligentCloudTableStatus.Init();
        IntelligentCloudTableStatus."Run ID" := RunId;
        IntelligentCloudTableStatus."Table Name" := 'Warning Table';
        IntelligentCloudTableStatus."Company Name" := CompanyName();
        IntelligentCloudTableStatus."New Version" := 100;
        IntelligentCloudTableStatus."Error Code" := '50004';
        IntelligentCloudTableStatus."Error Message" := 'The table does not exist in the local instance.';
        IntelligentCloudTableStatus.Insert();

        IntelligentCloudTableStatus.Init();
        IntelligentCloudTableStatus."Run ID" := RunId;
        IntelligentCloudTableStatus."Table Name" := 'Bad Table';
        IntelligentCloudTableStatus."Company Name" := CompanyName();
        IntelligentCloudTableStatus."New Version" := 100;
        IntelligentCloudTableStatus."Error Code" := '50888';
        IntelligentCloudTableStatus."Error Message" := 'This is an actual error.';
        IntelligentCloudTableStatus.Insert();
    end;
}
