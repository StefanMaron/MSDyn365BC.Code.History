codeunit 139656 "Hybrid Cloud Management Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryHybridManagement: Codeunit "Library - Hybrid Management";
        Initialized: Boolean;
        ExtensionRefreshFailureErr: Label 'Some extensions could not be updated and may need to be reinstalled to refresh their data.';
        ExtensionRefreshUnexpectedFailureErr: Label 'Failed to update extensions. You may need to verify and reinstall any missing extensions if needed.';

    local procedure Initialize()
    var
        HybridDeploymentSetup: Record "Hybrid Deployment Setup";
    begin
        if not Initialized then begin
            HybridDeploymentSetup.DeleteAll();
            HybridDeploymentSetup."Handler Codeunit ID" := Codeunit::"Library - Hybrid Management";
            HybridDeploymentSetup.Insert();
            BindSubscription(LibraryHybridManagement);
            HybridDeploymentSetup.Get();
        end;

        Initialized := true;
    end;

    [Test]
    procedure TestRedirectToSaaSWizardUrl()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
    begin
        // [SCENARIO] Verifies the redirect to SAAS wizard url is correct.

        // [GIVEN] The request to navigate to SAAS wizard is executed.

        // [THEN] The url to the SAAS wizard and filter are correct.
        Assert.AreEqual('https://businesscentral.dynamics.com/?page=4000&filter=''Primary%20Key''%20IS%20''FROMONPREM''', HybridCloudManagement.GetSaasWizardRedirectUrl(IntelligentCloudSetup), 'Redirect Url is incorrect');
    end;

    [Test]
    procedure TestParseWebhookNotification()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        NotificationHandler: Codeunit "Notification Handler";
        NotificationText: Text;
        RunId: Text;
        StartTime: DateTime;
        TriggerType: Text;
        ProductName: Text;
    begin
        Initialize();
        LibraryHybridManagement.SetExpectedProduct(ProductName);
        IntelligentCloudSetup."Product ID" := CopyStr(ProductName, 1, 250);
        if not IntelligentCloudSetup.Insert() then
            IntelligentCloudSetup.Modify();

        // [GIVEN] A valid notification payload
        NotificationText := LibraryHybridManagement.GetNotificationPayload(ProductName, RunId, StartTime, TriggerType, HybridReplicationSummary.ReplicationType::Full, ', "Status": "' + Format(HybridReplicationSummary.Status::Completed) + '"');

        // [WHEN] The function to parse that payload is called
        NotificationHandler.ParseReplicationSummary(HybridReplicationSummary, NotificationText);

        // [THEN] The expected values from the payload are set in a HybridReplicationSummary record
        Assert.AreEqual(RunId, HybridReplicationSummary."Run ID", 'Incorrect value parsed for "Run ID".');
        Assert.AreEqual(StartTime, HybridReplicationSummary."Start Time", 'Incorrect value parsed for "Start Time".');
        Assert.AreEqual(HybridReplicationSummary."Trigger Type"::Manual, HybridReplicationSummary."Trigger Type", 'Incorrect value parsed for "Trigger Type".');
        Assert.AreEqual(HybridReplicationSummary.ReplicationType::Full, HybridReplicationSummary.ReplicationType, 'Incorrect value parsed for "Replication Type".');
        Assert.AreEqual(HybridReplicationSummary.Status::Completed, HybridReplicationSummary.Status, 'Incorrect value parsed for "Status".');
        Assert.AreEqual(ProductName, HybridReplicationSummary.Source, 'Incorrect value parsed for "Source".');
    end;

    [Test]
    procedure TestParseWebhookNotificationForFailedRun()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        NotificationHandler: Codeunit "Notification Handler";
        NotificationText: Text;
        RunId: Text;
        StartTime: DateTime;
        TriggerType: Text;
        ProductName: Text;
        PipelineErrors: Text;
        Status: Text;
    begin
        Initialize();
        LibraryHybridManagement.SetExpectedProduct(ProductName);
        PipelineErrors := '[]';
        Status := Format(HybridReplicationSummary.Status::Failed);
        LibraryHybridManagement.SetExpectedStatus(Status, PipelineErrors);
        IntelligentCloudSetup."Product ID" := CopyStr(ProductName, 1, 250);
        if not IntelligentCloudSetup.Insert() then
            IntelligentCloudSetup.Modify();

        // [GIVEN] A valid notification payload
        TriggerType := 'Scheduled';
        NotificationText := LibraryHybridManagement.GetNotificationPayload(ProductName, RunId, StartTime, TriggerType, HybridReplicationSummary.ReplicationType::Normal, ', "Status": "Failed", "Details": "Bad stuff"');

        // [WHEN] The function to parse that payload is called
        NotificationHandler.ParseReplicationSummary(HybridReplicationSummary, NotificationText);

        // [THEN] The expected values from the payload are set in a HybridReplicationSummary record
        Assert.AreEqual(RunId, HybridReplicationSummary."Run ID", 'Incorrect value parsed for "Run ID".');
        Assert.AreEqual(StartTime, HybridReplicationSummary."Start Time", 'Incorrect value parsed for "Start Time".');
        Assert.AreEqual(HybridReplicationSummary."Trigger Type"::Scheduled, HybridReplicationSummary."Trigger Type", 'Incorrect value parsed for "Trigger Type".');
        Assert.AreEqual(HybridReplicationSummary.ReplicationType::Normal, HybridReplicationSummary.ReplicationType, 'Incorrect value parsed for "Replication Type".');
        Assert.AreEqual(HybridReplicationSummary.Status::Failed, HybridReplicationSummary.Status, 'Incorrect value parsed for "Status".');
        Assert.AreEqual(ProductName, HybridReplicationSummary.Source, 'Incorrect value parsed for "Source".');
        Assert.AreEqual('Bad stuff', HybridReplicationSummary.GetDetails(), 'Incorrect value parsed for "Details".');
    end;

    [Test]
    procedure TestParseWebhookNotificationForFailedRunWithPipelineErrors()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        NotificationHandler: Codeunit "Notification Handler";
        NotificationText: Text;
        RunId: Text;
        StartTime: DateTime;
        TriggerType: Text;
        ProductName: Text;
        Errors: Text;
        Status: Text;
    begin
        Initialize();
        Status := Format(HybridReplicationSummary.Status::Failed);
        Errors := '"Failure 1", "Failure 2"';
        LibraryHybridManagement.SetExpectedProduct(ProductName);
        LibraryHybridManagement.SetExpectedStatus(Status, Errors);
        IntelligentCloudSetup."Product ID" := CopyStr(ProductName, 1, 250);
        if not IntelligentCloudSetup.Insert() then
            IntelligentCloudSetup.Modify();

        // [GIVEN] A valid notification payload
        TriggerType := 'Scheduled';
        NotificationText := LibraryHybridManagement.GetNotificationPayload(ProductName, RunId, StartTime, TriggerType, HybridReplicationSummary.ReplicationType::Diagnostic, ', "Status": "Failed", "Details": "bad things"');

        // [WHEN] The function to parse that payload is called
        NotificationHandler.ParseReplicationSummary(HybridReplicationSummary, NotificationText);

        // [THEN] The expected values from the payload are set in a HybridReplicationSummary record
        Assert.AreEqual(RunId, HybridReplicationSummary."Run ID", 'Incorrect value parsed for "Run ID".');
        Assert.AreEqual(StartTime, HybridReplicationSummary."Start Time", 'Incorrect value parsed for "Start Time".');
        Assert.AreEqual(HybridReplicationSummary."Trigger Type"::Scheduled, HybridReplicationSummary."Trigger Type", 'Incorrect value parsed for "Trigger Type".');
        Assert.AreEqual(HybridReplicationSummary.Status::Failed, HybridReplicationSummary.Status, 'Incorrect value parsed for "Status".');
        Assert.AreEqual(HybridReplicationSummary.ReplicationType::Diagnostic, HybridReplicationSummary.ReplicationType, 'Incorrect value parsed for "Replication Type".');
        Assert.AreEqual(ProductName, HybridReplicationSummary.Source, 'Incorrect value parsed for "Source".');
        Assert.AreEqual('Failure 1\Failure 2', HybridReplicationSummary.GetDetails(), 'Incorrect value parsed for "Details".');
    end;

    [Test]
    procedure TestParseWebhookNotificationForCompletedRunWithExtensionRefreshErrors()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        NotificationHandler: Codeunit "Notification Handler";
        NotificationText: Text;
        RunId: Text;
        StartTime: DateTime;
        TriggerType: Text;
        ProductName: Text;
    begin
        Initialize();
        LibraryHybridManagement.SetExpectedProduct(ProductName);
        IntelligentCloudSetup."Product ID" := CopyStr(ProductName, 1, 250);
        if not IntelligentCloudSetup.Insert() then
            IntelligentCloudSetup.Modify();

        // [GIVEN] A valid notification payload
        TriggerType := 'Scheduled';
        NotificationText := LibraryHybridManagement.GetNotificationPayload(ProductName, RunId, StartTime, TriggerType, HybridReplicationSummary.ReplicationType::Normal, ', "Status": "Completed", "ExtensionRefreshFailed": { "ErrorCode": "50008", "FailedExtensions": "Late Payment Prediction, Essential Business Headlines"}');

        // [WHEN] The function to parse that payload is called
        NotificationHandler.ParseReplicationSummary(HybridReplicationSummary, NotificationText);

        // [THEN] The expected values from the payload are set in a HybridReplicationSummary record
        Assert.AreEqual(RunId, HybridReplicationSummary."Run ID", 'Incorrect value parsed for "Run ID".');
        Assert.AreEqual(StartTime, HybridReplicationSummary."Start Time", 'Incorrect value parsed for "Start Time".');
        Assert.AreEqual(HybridReplicationSummary."Trigger Type"::Scheduled, HybridReplicationSummary."Trigger Type", 'Incorrect value parsed for "Trigger Type".');
        Assert.AreEqual(HybridReplicationSummary.Status::Completed, HybridReplicationSummary.Status, 'Incorrect value parsed for "Status".');
        Assert.AreEqual(ProductName, HybridReplicationSummary.Source, 'Incorrect value parsed for "Source".');
        Assert.AreEqual(ExtensionRefreshFailureErr + ' Late Payment Prediction, Essential Business Headlines', HybridReplicationSummary.GetDetails(), 'Incorrect value parsed for "Details".');
    end;

    [Test]
    procedure TestParseWebhookNotificationForCompletedRunWithExtensionRefreshUnexpectedErrors()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        NotificationHandler: Codeunit "Notification Handler";
        NotificationText: Text;
        RunId: Text;
        StartTime: DateTime;
        TriggerType: Text;
        ProductName: Text;
    begin
        Initialize();
        LibraryHybridManagement.SetExpectedProduct(ProductName);
        IntelligentCloudSetup."Product ID" := CopyStr(ProductName, 1, 250);
        if not IntelligentCloudSetup.Insert() then
            IntelligentCloudSetup.Modify();

        // [GIVEN] A valid notification payload
        TriggerType := 'Scheduled';
        NotificationText := LibraryHybridManagement.GetNotificationPayload(ProductName, RunId, StartTime, TriggerType, HybridReplicationSummary.ReplicationType::Normal, ', "Status": "Completed", "ExtensionRefreshUnexpectedError": { "ErrorCode": "50009" }');

        // [WHEN] The function to parse that payload is called
        NotificationHandler.ParseReplicationSummary(HybridReplicationSummary, NotificationText);

        // [THEN] The expected values from the payload are set in a HybridReplicationSummary record
        Assert.AreEqual(RunId, HybridReplicationSummary."Run ID", 'Incorrect value parsed for "Run ID".');
        Assert.AreEqual(StartTime, HybridReplicationSummary."Start Time", 'Incorrect value parsed for "Start Time".');
        Assert.AreEqual(HybridReplicationSummary."Trigger Type"::Scheduled, HybridReplicationSummary."Trigger Type", 'Incorrect value parsed for "Trigger Type".');
        Assert.AreEqual(HybridReplicationSummary.Status::Completed, HybridReplicationSummary.Status, 'Incorrect value parsed for "Status".');
        Assert.AreEqual(ProductName, HybridReplicationSummary.Source, 'Incorrect value parsed for "Source".');
        Assert.AreEqual(ExtensionRefreshUnexpectedFailureErr, HybridReplicationSummary.GetDetails(), 'Incorrect value parsed for "Details".');
    end;



    [Test]
    procedure TestGetNextScheduledReplicationLaterToday()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        TodayDateTime: DateTime;
        TodayTime: Time;
        NextScheduled: DateTime;
    begin
        // [GIVEN] The intelligent cloud is scheduled for Thursday at 13:01
        Evaluate(TodayTime, '13:00');
        TodayDateTime := CreateDateTime(DMY2Date(09, 08, 2018), TodayTime);
        IntelligentCloudSetup.DeleteAll();
        IntelligentCloudSetup.Init();
        IntelligentCloudSetup.Thursday := true;
        IntelligentCloudSetup."Time to Run" := DT2Time(TodayDateTime) + 60000; // One minute in the future
        IntelligentCloudSetup.Insert();

        // [WHEN] The call to get the next scheduled run is made on Thursday at 13:00
        NextScheduled := IntelligentCloudSetup.GetNextScheduledRunDateTime(TodayDateTime);

        // [THEN] The next scheduled date time is returned as Thursday at 13:01
        Assert.AreEqual(TodayDateTime + 60000, NextScheduled, 'Unexpected next scheduled datetime');
    end;

    [Test]
    procedure TestGetNextScheduledReplicationTomorrow()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        TodayDateTime: DateTime;
        TodayTime: Time;
        NextScheduled: DateTime;
    begin
        // [GIVEN] The intelligent cloud is scheduled for Friday at 13:00
        Evaluate(TodayTime, '13:00');
        TodayDateTime := CreateDateTime(DMY2Date(09, 08, 2018), TodayTime);
        IntelligentCloudSetup.DeleteAll();
        IntelligentCloudSetup.Init();
        IntelligentCloudSetup.Recurrence := IntelligentCloudSetup.Recurrence::Weekly;
        IntelligentCloudSetup.Friday := true;
        IntelligentCloudSetup."Time to Run" := DT2Time(TodayDateTime);
        IntelligentCloudSetup.Insert();

        // [WHEN] The call to get the next scheduled run is made on Thursday at 13:00
        NextScheduled := IntelligentCloudSetup.GetNextScheduledRunDateTime(TodayDateTime);

        // [THEN] The next scheduled date time is returned as Friday at 13:00
        Assert.AreEqual(CreateDateTime(DMY2Date(10, 08, 2018), TodayTime), NextScheduled, 'Unexpected next scheduled datetime');
    end;

    [Test]
    procedure TestGetNextScheduledReplicationNextWeek()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        TodayDateTime: DateTime;
        TodayTime: Time;
        NextScheduled: DateTime;
    begin
        // [GIVEN] The intelligent cloud is scheduled for Sundays and Tuesdays at 13:00
        Evaluate(TodayTime, '13:00');
        TodayDateTime := CreateDateTime(DMY2Date(12, 08, 2018), TodayTime);
        IntelligentCloudSetup.DeleteAll();
        IntelligentCloudSetup.Init();
        IntelligentCloudSetup.Recurrence := IntelligentCloudSetup.Recurrence::Weekly;
        IntelligentCloudSetup.Tuesday := true;
        IntelligentCloudSetup.Sunday := true;
        IntelligentCloudSetup."Time to Run" := DT2Time(TodayDateTime);
        IntelligentCloudSetup.Insert();

        // [WHEN] The call to get the next scheduled run is made on Sunday at 13:01
        NextScheduled := IntelligentCloudSetup.GetNextScheduledRunDateTime(TodayDateTime + 60000);

        // [THEN] The next scheduled date time is returned as Tuesday at 13:00
        Assert.AreEqual(CreateDateTime(DMY2Date(14, 08, 2018), TodayTime), NextScheduled, 'Unexpected next scheduled datetime');
    end;

    [Test]
    procedure TestGetNextScheduledReplicationBeforeMidnight()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        TodayDateTime: DateTime;
        TodayTime: Time;
        NextScheduled: DateTime;
    begin
        // [GIVEN] The intelligent cloud is scheduled for Wednesdays at 23:59
        Evaluate(TodayTime, '23:50');
        TodayDateTime := CreateDateTime(DMY2Date(15, 08, 2018), TodayTime);
        IntelligentCloudSetup.DeleteAll();
        IntelligentCloudSetup.Init();
        IntelligentCloudSetup.Recurrence := IntelligentCloudSetup.Recurrence::Weekly;
        IntelligentCloudSetup.Wednesday := true;
        IntelligentCloudSetup."Time to Run" := DT2Time(TodayDateTime) + (9 * 60 * 1000); // 23:59
        IntelligentCloudSetup.Insert();

        // [WHEN] The call to get the next scheduled run is made on Wednesday at 23:50
        NextScheduled := IntelligentCloudSetup.GetNextScheduledRunDateTime(TodayDateTime);

        // [THEN] The next scheduled date time is returned as Wednesday (today) at 23:59
        Assert.AreEqual(CreateDateTime(DMY2Date(15, 08, 2018), IntelligentCloudSetup."Time to Run"), NextScheduled, 'Unexpected next scheduled datetime');
    end;

    [Test]
    procedure TestGetNextScheduledReplicationAfterMidnight()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        TodayDateTime: DateTime;
        TodayTime: Time;
        NextScheduled: DateTime;
    begin
        // [GIVEN] The intelligent cloud is scheduled for Wednesdays at 23:59
        Evaluate(TodayTime, '00:00');
        TodayDateTime := CreateDateTime(DMY2Date(16, 08, 2018), TodayTime);
        IntelligentCloudSetup.DeleteAll();
        IntelligentCloudSetup.Init();
        IntelligentCloudSetup.Recurrence := IntelligentCloudSetup.Recurrence::Weekly;
        IntelligentCloudSetup.Wednesday := true;
        IntelligentCloudSetup."Time to Run" := DT2Time(TodayDateTime - 60000); // 23:59
        IntelligentCloudSetup.Insert();

        // [WHEN] The call to get the next scheduled run is made on Thursday at 00:00
        NextScheduled := IntelligentCloudSetup.GetNextScheduledRunDateTime(TodayDateTime);

        // [THEN] The next scheduled date time is returned as next Wednesday at 23:59
        Assert.AreEqual(CreateDateTime(DMY2Date(22, 08, 2018), IntelligentCloudSetup."Time to Run"), NextScheduled, 'Unexpected next scheduled datetime');
    end;

    [Test]
    procedure TestGetMessageText()
    var
        HybridMessageManagement: Codeunit "Hybrid Message Management";
        Message: Text;
        InnerMessage: Text;
    begin
        InnerMessage := 'Sample inner message';
        Message := HybridMessageManagement.ResolveMessageCode('INIT', InnerMessage);
        Assert.AreNotEqual('', Message, 'Message not resolved for INIT');
        Assert.AreNotEqual(InnerMessage, Message, 'Message not resolved for INIT');

        Message := HybridMessageManagement.ResolveMessageCode('Unknown', InnerMessage);
        Assert.AreEqual(InnerMessage, Message, 'Unresolved code should default to inner message.');
    end;

    [Test]
    procedure TestUpdateReplicationStatusUpdatesStatusForInProgressRecordsWhenSucceeded()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        RunId: Text;
        Status: Text;
        Errors: Text;
    begin
        // [SCENARIO 291819] User can refresh the status of replication runs
        Initialize();
        RunId := CreateGuid();

        // [GIVEN] An in-progress record exists in the system
        HybridReplicationSummary.CreateInProgressRecord(RunId, HybridReplicationSummary.ReplicationType::Normal);

        // [GIVEN] The replication run has succeeded meanwhile
        Status := 'Succeeded';
        Errors := '[]';
        LibraryHybridManagement.SetExpectedStatus(Status, Errors);

        // [WHEN] The call to RefreshReplicationStatus is made
        HybridCloudManagement.RefreshReplicationStatus();

        // [THEN] The summary record gets updated with the new status
        HybridReplicationSummary.Get(RunId);
        Assert.AreEqual(HybridReplicationSummary.Status::Completed, HybridReplicationSummary.Status, 'Status not updated.');
        Assert.AreEqual('', HybridReplicationSummary.GetDetails(), 'Details should be empty.');
    end;

    [Test]
    procedure TestUpdateReplicationStatusUpdatesStatusForInProgressRecordsWhenFailed()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        RunId: Text;
        Status: Text;
        Errors: Text;
    begin
        // [SCENARIO 291819] User can refresh the status of replication runs
        Initialize();
        RunId := CreateGuid();

        // [GIVEN] An in-progress record exists in the system
        HybridReplicationSummary.CreateInProgressRecord(RunId, HybridReplicationSummary.ReplicationType::Normal);

        // [GIVEN] The replication run has failed meanwhile
        Status := 'Failed';
        Errors := '"Small failure 1", "Big failure 2"';
        LibraryHybridManagement.SetExpectedStatus(Status, Errors);

        // [WHEN] The call to RefreshReplicationStatus is made
        HybridCloudManagement.RefreshReplicationStatus();

        // [THEN] The summary record gets updated with the new failed status
        HybridReplicationSummary.Get(RunId);
        Assert.AreEqual(HybridReplicationSummary.Status::Failed, HybridReplicationSummary.Status, 'Status not updated.');
        Assert.AreEqual('Small failure 1\Big failure 2', HybridReplicationSummary.GetDetails(), 'Details should be empty.');
    end;

    [Test]
    procedure SetTriggerTypeOnInstallApp()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridCloudInstall: Codeunit "Hybrid Cloud Install";
    begin
        // [SCENARIO] Installing the app correctly updates the summary records to support a field change

        // [GIVEN] Several summary records exist that conform to the old schema
        // 0 represents scheduled, 1 represents manual
        CreateSummaryRecord('1', 0);
        CreateSummaryRecord('2', 0);
        CreateSummaryRecord('3', 1);
        CreateSummaryRecord('4', 1);
        CreateSummaryRecord('5', 0);

        // [WHEN] The extension app is installed
        HybridCloudInstall.UpdateHybridReplicationSummaryRecords();

        // [THEN] The replication type value is moved to the new "Trigger Type" field and the "Replication Type" is defaulted to Normal
        with HybridReplicationSummary do begin
            VerifySummaryRecord('1', "Trigger Type"::Scheduled, ReplicationType::Normal);
            VerifySummaryRecord('2', "Trigger Type"::Scheduled, ReplicationType::Normal);
            VerifySummaryRecord('3', "Trigger Type"::Manual, ReplicationType::Normal);
            VerifySummaryRecord('4', "Trigger Type"::Manual, ReplicationType::Normal);
            VerifySummaryRecord('5', "Trigger Type"::Scheduled, ReplicationType::Normal);
        end;
    end;

    local procedure CreateSummaryRecord(RunId: Text; ReplicationType: Option)
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
    begin
        HybridReplicationSummary.Init();
        HybridReplicationSummary."Run ID" := CopyStr(RunId, 1, MaxStrLen(HybridReplicationSummary."Run ID"));
        HybridReplicationSummary."Replication Type" := ReplicationType;
        HybridReplicationSummary.Insert();
    end;

    local procedure VerifySummaryRecord(RunId: Text; ExpectedTriggerType: Option; ExpectedReplicationType: Option)
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
    begin
        HybridReplicationSummary.Get(RunId);
        Assert.AreEqual(ExpectedTriggerType, HybridReplicationSummary."Trigger Type", 'Incorrect trigger type');
        Assert.AreEqual(ExpectedReplicationType, HybridReplicationSummary.ReplicationType, 'Incorrect replication type');
    end;
}