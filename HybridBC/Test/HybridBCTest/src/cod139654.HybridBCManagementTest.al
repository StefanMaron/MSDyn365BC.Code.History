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
        InsertDetailsOnWebhookNotificationInsert(SubscriptionIdTxt);
    end;

    [Test]
    procedure InsertDetailsOnWebhookNotificationInsertForServiceSubscription()
    begin
        InsertDetailsOnWebhookNotificationInsert(ServiceSubscriptionIdTxt);
    end;

    local procedure InsertDetailsOnWebhookNotificationInsert(SubscriptionId: Text)
    var
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        RunId: Text;
        StartTime: DateTime;
        TriggerType: Text;
    begin
        // [GIVEN] A Webhook Subscription exists for DynamicsBC
        Initialize();

        // [WHEN] A notification record is inserted
        InsertNotification(SubscriptionId, RunId, StartTime, TriggerType, 1, '');

        // [THEN] The correct Hybrid Replication Detail records are created.
        with HybridReplicationDetail do begin
            SetRange("Run ID", RunId);
            Assert.AreEqual(5, Count(), 'Unexpected number of detail records.');
            Get(RunId, 'Good Table', CompanyName());
            Assert.IsFalse(Errors.HasValue(), 'Successful table should not report errors.');
            Assert.AreEqual(Status::Successful, Status, 'Successful table should have success status.');

            Get(RunId, 'Bad Table', CompanyName());
            Assert.IsTrue(Errors.HasValue(), 'Failed table should report errors.');
            Assert.AreEqual(Status::Failed, Status, 'Failed table should have failed status.');

            Get(RunId, 'Big Good Table', CompanyName());
            Assert.IsFalse(Errors.HasValue(), 'Successful table should not report errors.');
            Assert.AreEqual(Status::Successful, Status, 'Successful table should have success status.');

            Get(RunId, 'Big Bad Table', CompanyName());
            Assert.IsTrue(Errors.HasValue(), 'Failed table should report errors.');
            Assert.AreEqual(Status::Warning, Status, 'Failed table that doesnot exist onprem should have warning status.');

            Get(RunId, 'Warning Table', CompanyName());
            Assert.IsTrue(Errors.HasValue(), 'Failed table should report errors.');
            Assert.AreEqual(Status::Warning, Status, 'Failed table that doesnot exist onprem should have warning status.');

            SetRange(Status, Status::Warning);
            Assert.AreEqual(2, Count(), 'Replication detail should have two warning status entries.');
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

        Json += ', "IncrementalTables": [' +
                            '{' +
                            '"TableName": "Good Table",' +
                            '"CompanyName": "' + CompanyName() + '",' +
                            '"$companyid": 0,' +
                            '"NewVersion": 742,' +
                            '"Errors": ""' +
                            '},' +
                            '{' +
                            '"TableName": "Bad Table",' +
                            '"CompanyName": "' + CompanyName() + '",' +
                            '"$companyid": 0,' +
                            '"NewVersion": 742,' +
                            '"ErrorCode": "50001"' +
                            '},' +
                            '{' +
                            '"TableName": "Warning Table",' +
                            '"CompanyName": "' + CompanyName() + '",' +
                            '"$companyid": 0,' +
                            '"NewVersion": 742,' +
                            '"ErrorCode": "50004"' +
                            '}' +
                        ']';
        Json += ', "FullTables": [' +
                            '{' +
                            '"TableName": "Big Good Table",' +
                            '"CompanyName": "' + CompanyName() + '",' +
                            '"$companyid": 0,' +
                            '"NewVersion": 742,' +
                            '"Errors": ""' +
                            '},' +
                            '{' +
                            '"TableName": "Big Bad Table",' +
                            '"CompanyName": "' + CompanyName() + '",' +
                            '"$companyid": 0,' +
                            '"NewVersion": 742,' +
                            '"ErrorCode": "50004",' +
                            '"Errors": "Failure processing data for Table = ''Bad Table''\\\\r\\\\n' +
                                        'Error message: Explicit value must be specified for identity column in table ''' +
                                        'CRONUS International Ltd_$Bad Table''."' +
                            '}' +
                        ']';
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
}
