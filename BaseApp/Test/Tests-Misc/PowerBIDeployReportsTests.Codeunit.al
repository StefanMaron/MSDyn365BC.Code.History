codeunit 139088 "PowerBI Deploy Reports Tests"
{
    // // Unit tests for automated deployment of OOB PBI reports. Tests the methods in codeunit 6301 (can't
    // // handle UI or background sessions of the deployment code on pages 6303/6306), using mock deployment
    // // service in codeunit 131016.
    // 
    // //upload ignores reports you don't have permissions to...?
    // 
    // //selection happy path successful (creates rows)
    // //selection ignores reports that shouldn't be selected...
    // //selection ignores failed reports
    // //selection ignores pages you don't have access to?
    // //selection doesn't overwrite existing selection
    // //selection handles multiples fine?

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [PowerBI] [Report Deployment]
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        LibraryPowerBIServiceMgt: Codeunit "Library - Power BI Service Mgt";
        LibraryAzureADAuthFlow: Codeunit "Library - Azure AD Auth Flow";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        NullGuid: Guid;
        Report1NameTxt: Label 'Report1';
        Report2NameTxt: Label 'Report2';
        Report3NameTxt: Label 'Report3';
        Context1Txt: Label 'Context1';


    // Tests

#if not CLEAN19
    [Test]
    [HandlerFunctions('SelectionPageHandler')]
    [Scope('OnPrem')]
    procedure TestDefaultSelectionWithSpinnerPart()
    begin
        TestDefaultSelection(false);
    end;

    [Test]
    [HandlerFunctions('SelectionPageHandler')]
    [Scope('OnPrem')]
    procedure TestDefaultSelectionWithFactboxPart()
    begin
        TestDefaultSelection(true);
    end;
    [Test]
    [HandlerFunctions('SelectionPageHandler')]
    [Scope('OnPrem')]
    procedure TestDefaultSelectionForGPWithSpinnerPart()
    begin
        TestDefaultSelectionAfterIntelligentCloudSync(false);
    end;

    [Test]
    [HandlerFunctions('SelectionPageHandler')]
    [Scope('OnPrem')]
    procedure TestDefaultSelectionForGPWithFactboxPart()
    begin
        TestDefaultSelectionAfterIntelligentCloudSync(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUploadingIgnoresAlreadyDeployedReports()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part";
        ReportId1: Guid;
        ReportId2: Guid;
        ReportId3: Guid;
    begin
        // [SCENARIO] UploadDefaultReport only uploads reports that haven't already been deployed.
        Init();
        OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt);
        PowerBIReportSpinnerPartTestPage.OptInGettingStarted.Drilldown();

        // [GIVEN] Blobs exist and some are already uploaded.
        ReportId1 := CreateGuid();
        AddBlobToDatabase(ReportId1, 'Report 1', 1);
        AddCompletedUploadToDatabase(ReportId1, CreateGuid(), true);
        ReportId2 := CreateGuid();
        AddBlobToDatabase(ReportId2, 'Report 2', 1);
        AddDefaultSelectionToDatabase(ReportId2, Context1Txt, true);
        ReportId3 := CreateGuid();
        AddBlobToDatabase(ReportId3, 'Report 3', 1);
        AddPartialUploadToDatabase(ReportId3, CreateGuid(), false, 0DT);

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);

        // [WHEN] System calls UploadDefaultReport.
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        // [THEN] Uploads table has a new row with correct values.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have uploaded one report.');
        Assert.AreEqual(3, PowerBIReportUploads.Count, 'Table 6307 should now have three records total.');
        PowerBIReportUploads.Get(ReportId2, UserSecurityId);
        PowerBIReportSpinnerPartTestPage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUploadingWithMultipleUsers()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part";
        ReportId1: Guid;
        ReportId2: Guid;
    begin
        // [SCENARIO] UploadDefaultReport uploads undeployed reports for current user only and ignores other users.
        Init();
        OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt);
        PowerBIReportSpinnerPartTestPage.OptInGettingStarted.Drilldown();

        // [GIVEN] Blobs exist, and a different user has already uploaded something.
        ReportId1 := CreateGuid();
        AddBlobToDatabase(ReportId1, 'Report 1', 1);
        AddDefaultSelectionToDatabase(ReportId1, Context1Txt, true);
        ReportId2 := CreateGuid();
        AddBlobToDatabase(ReportId2, 'Report 2', 1);
        AddReportUploadToDatabase(ReportId2, CreateGuid(), CreateGuid(), NullGuid, 1, true, '', false, 0DT);

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);

        // [WHEN] System calls UploadDefaultReport.
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        // [THEN] Uploads table has new rows with correct values.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have uploaded two reports.');
        Assert.AreEqual(2, PowerBIReportUploads.Count, 'Table 6307 should have three records total.');
        PowerBIReportUploads.SetFilter("User ID", UserSecurityId);
        PowerBIReportUploads.Find('-');
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Current user should have two records.');
        PowerBIReportSpinnerPartTestPage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUploadingNewVersionOfOldReport()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part";
        ReportId: Guid;
        NewVersion: Integer;
    begin
        // [SCENARIO] UploadDefaultReport overwrites user's reports that have a newer version since they were deployed.
        Init();
        OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt);
        PowerBIReportSpinnerPartTestPage.OptInGettingStarted.Drilldown();

        // [GIVEN] Blob exists and has been uploaded for older version.
        ReportId := CreateGuid();
        AddReportUploadToDatabase(ReportId, UserSecurityId, CreateGuid(), NullGuid, 0, true, '', false, 0DT);
        NewVersion := 2;
        AddBlobToDatabase(ReportId, 'Report 1', NewVersion);
        AddDefaultSelectionToDatabase(ReportId, Context1Txt, true);

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);

        // [WHEN] System calls UploadDefaultReport.
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        // [THEN] Uploads table has updated the existing row.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have uploaded one report.');
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Table 6307 should still have only one record.');
        PowerBIReportUploads.Get(ReportId, UserSecurityId);
        Assert.AreEqual(NewVersion, PowerBIReportUploads."Deployed Version", 'Record should have updated version number.');
        Assert.AreEqual(true, PowerBIReportUploads."Is Selection Done", 'Already selected report should still be selected.');
        PowerBIReportSpinnerPartTestPage.Close;
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure TestUploadingDuringServiceOutage()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIServiceStatusSetup: Record "Power BI Service Status Setup";
        PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part";
        OutageDateTime: DateTime;
        Id: Guid;
    begin
        // [SCENARIO] UploadDefaultReport tries to upload when Power BI is completely unavailable.
        Init();
        OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt);
        PowerBIReportSpinnerPartTestPage.OptInGettingStarted.Drilldown();

        // [GIVEN] Blob exists and hasn't been uploaded yet.
        Id := CreateGuid();
        AddBlobToDatabase(Id, 'Report 1', 1);
        AddDefaultSelectionToDatabase(Id, Context1Txt, true);

        OutageDateTime := CreateDateTime(20990101D, 0T);
        LibraryPowerBIServiceMgt.SetMockDeploymentResults(false, false, false, true, OutageDateTime);

        // [WHEN] System calls UploadDefaultReport.
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        // [THEN] Uploads table is still empty and service is marked as unavailable.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have tried uploading the report.');
        Assert.AreEqual(0, PowerBIReportUploads.Count, 'Failure should not add any records to table 6307.');
        PowerBIServiceStatusSetup.Reset();
        PowerBIServiceStatusSetup.FindFirst;
        Assert.AreEqual(OutageDateTime, PowerBIServiceStatusSetup."Retry After", 'Service failure should update table 6309.');
        Assert.IsFalse(PowerBIServiceMgt.IsPBIServiceAvailable,
          'Service should be marked as unavailable when retry time is in the future.');
        PowerBIReportSpinnerPartTestPage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUploadingWithUploadError()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part";
        Id: Guid;
    begin
        // [SCENARIO] UploadDefaultReport fails to upload report at all.
        Init();
        OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt);
        PowerBIReportSpinnerPartTestPage.OptInGettingStarted.Drilldown();

        // [GIVEN] Blob exists and hasn't been uploaded yet.
        Id := CreateGuid();
        AddBlobToDatabase(Id, 'Report 1', 1);
        AddDefaultSelectionToDatabase(Id, Context1Txt, true);

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, false, false, true, 0DT);

        // [WHEN] System calls UploadDefaultReport.
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        // [THEN] Uploads table is still empty but service is marked as available still.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have tried uploading the report.');
        Assert.AreEqual(0, PowerBIReportUploads.Count, 'Failure should not add any records to table 6307.');
        Assert.IsTrue(PowerBIServiceMgt.IsPBIServiceAvailable,
          'Service should be marked as available still if upload did not fail from service unavailability.');
        PowerBIReportSpinnerPartTestPage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUploadingWithRefreshError()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part";
        ReportId: Guid;
        ReportVersion: Integer;
        ShouldRetry: Boolean;
        RetryAfter: DateTime;
    begin
        // [SCENARIO] UploadDefaultReport uploads a report but fails to refresh it.
        Init();
        OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt);
        PowerBIReportSpinnerPartTestPage.OptInGettingStarted.Drilldown();

        // [GIVEN] Blob exists and hasn't been uploaded yet.
        ReportId := CreateGuid();
        ReportVersion := 3;
        AddBlobToDatabase(ReportId, 'Report 1', ReportVersion);
        AddDefaultSelectionToDatabase(ReportId, Context1Txt, true);

        ShouldRetry := true;
        RetryAfter := CreateDateTime(20990101D, 0T);
        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, false, ShouldRetry, RetryAfter);

        // [WHEN] System calls UploadDefaultReport.
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        // [THEN] Uploads table has a new row showing a report that needs to be retried.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have tried uploading the report.');
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Table 6307 should have a row added.');
        PowerBIReportUploads.Get(ReportId, UserSecurityId);
        Assert.IsTrue(IsNullGuid(PowerBIReportUploads."Uploaded Report ID"), 'Record should not have a report ID when it fails.');
        Assert.IsFalse(IsNullGuid(PowerBIReportUploads."Import ID"), 'Record should get an import ID for retrying later.');
        Assert.AreEqual(ReportVersion, PowerBIReportUploads."Deployed Version", 'Record should have the correct version number.');
        Assert.IsFalse(PowerBIReportUploads."Is Selection Done", 'Failed upload should not be selected yet.');
        Assert.AreEqual('', PowerBIReportUploads."Report Embed Url", 'Failed upload should not have a report URL yet.');
        Assert.AreEqual(ShouldRetry, PowerBIReportUploads."Should Retry", 'Should Retry value should match the return from the service.');
        Assert.AreEqual(RetryAfter, PowerBIReportUploads."Retry After", 'Retry After time should match the return from the service.');
        PowerBIReportSpinnerPartTestPage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUploadingUpdatesOngoingDeploymentStatus()
    var
        PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part";
        Id: Guid;
    begin
        // [SCENARIO] UploadDefaultReport marks deployment as finished, regardless of success or failure.
        Init();
        OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt);
        PowerBIReportSpinnerPartTestPage.OptInGettingStarted.Drilldown();

        // [GIVEN] Blob exists and hasn't been uploaded yet.
        Id := CreateGuid();
        AddBlobToDatabase(Id, 'Report 1', 1);
        AddDefaultSelectionToDatabase(Id, Context1Txt, true);

        // [WHEN] System calls UploadDefaultReport.
        PowerBIServiceMgt.SetIsSynchronizing(true);
        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, false, false, false, 0DT);
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        // [THEN] OngoingDeployments table gets set back to false each time.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have tried to upload one report.');
        Assert.IsFalse(PowerBIServiceMgt.IsUserSynchronizingReports(), 'Ongoing deployment table should be set back to false.');

        PowerBIServiceMgt.SetIsSynchronizing(true);
        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        Assert.AreEqual(2, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have uploaded second time.');
        Assert.IsFalse(PowerBIServiceMgt.IsUserSynchronizingReports(), 'Ongoing deployment table should be set back to false again.');
        PowerBIReportSpinnerPartTestPage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSuccessfulRetryOfPreviousUpload()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        ReportId: Guid;
    begin
        // [SCENARIO] RetryAllPartialReportUploads finishes user's failed reports and handles successful return.
        Init;

        // [GIVEN] Blob with partial upload exists.
        ReportId := CreateGuid();
        AddBlobToDatabase(ReportId, 'Report 1', 1);
        AddPartialUploadToDatabase(ReportId, CreateGuid(), true, 0DT);

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);

        // [WHEN] System calls RetryAllPartialReportUploads.
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        // [THEN] Uploads table record is updated with correct values.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentRetryCount, 'Service should have retried one report.');
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Table 6307 should still have one record.');
        PowerBIReportUploads.Get(ReportId, UserSecurityId);
        Assert.IsFalse(IsNullGuid(PowerBIReportUploads."Uploaded Report ID"), 'Record should be updated with a report ID.');
        Assert.IsTrue(IsNullGuid(PowerBIReportUploads."Import ID"), 'Record should not have an import ID anymore.');
        Assert.AreEqual(false, PowerBIReportUploads."Is Selection Done", 'Report should not be marked as selected yet.');
        Assert.AreNotEqual('', PowerBIReportUploads."Report Embed Url", 'Report should have a URL from the PBI service.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetryingIgnoresAlreadySuccesfulReports()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        ReportId: Guid;
        PbiReportId: Guid;
        ReportVersion: Integer;
    begin
        // [SCENARIO] RetryAllPartialReportUploads won't retry an upload that was already successful.
        Init;

        // [GIVEN] Blob exists and has been partially uploaded.
        ReportId := CreateGuid();
        ReportVersion := 1;
        AddBlobToDatabase(ReportId, 'Report 1', ReportVersion);
        PbiReportId := CreateGuid();
        AddCompletedUploadToDatabase(ReportId, PbiReportId, false);

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);

        // [WHEN] System calls RetryAllPartialReportUploads.
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        // [THEN] Uploads table record is unchanged.
        Assert.AreEqual(0, LibraryPowerBIServiceMgt.GetMockDeploymentRetryCount, 'Service should not have retried any reports.');
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Table 6307 should still have only one record.');
        PowerBIReportUploads.Get(ReportId, UserSecurityId);
        Assert.AreEqual(PbiReportId, PowerBIReportUploads."Uploaded Report ID", 'ID in PBI account should not have changed.');
        Assert.IsTrue(IsNullGuid(PowerBIReportUploads."Import ID"), 'Record should still have no import ID.');
        Assert.AreNotEqual('', PowerBIReportUploads."Report Embed Url", 'Report should still have a URL from the PBI service.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetryingIgnoresNonRetriableReports()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        ReportId: Guid;
        ReportVersion: Integer;
    begin
        // [SCENARIO] RetryAllPartialReportUploads won't retry an upload that has ShouldRetry=false.
        Init;

        // [GIVEN] Blob exists and has been partially uploaded.
        ReportId := CreateGuid();
        ReportVersion := 1;
        AddBlobToDatabase(ReportId, 'Report 1', ReportVersion);
        AddPartialUploadToDatabase(ReportId, CreateGuid(), false, 0DT);

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);

        // [WHEN] System calls RetryAllPartialReportUploads.
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        // [THEN] Uploads table record is unchanged.
        Assert.AreEqual(0, LibraryPowerBIServiceMgt.GetMockDeploymentRetryCount, 'Service should not have retried any reports.');
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Table 6307 should still have only one record.');
        PowerBIReportUploads.Get(ReportId, UserSecurityId);
        Assert.IsTrue(IsNullGuid(PowerBIReportUploads."Uploaded Report ID"), 'PBI ID should still be empty.');
        Assert.IsFalse(PowerBIReportUploads."Should Retry", 'ShouldRetry should still be set to false.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetryingDuringServiceOutage()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIServiceStatusSetup: Record "Power BI Service Status Setup";
        ReportId: Guid;
        OutageDateTime: DateTime;
    begin
        // [SCENARIO] RetryAllPartialReportUploads tries to upload when Power BI is completely unavailable.
        Init;

        // [GIVEN] Blob exists and needs to be retried.
        ReportId := CreateGuid();
        AddBlobToDatabase(ReportId, 'Report 1', 1);
        AddPartialUploadToDatabase(ReportId, CreateGuid(), true, 0DT);

        OutageDateTime := CreateDateTime(20990101D, 0T);
        LibraryPowerBIServiceMgt.SetMockDeploymentResults(false, false, false, true, OutageDateTime);

        // [WHEN] System calls RetryAllPartialReportUploads.
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        // [THEN] Uploads table is unchanged and service is marked as unavailable.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentRetryCount, 'Service should have tried refreshing the report.');
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Still one record in table 6307.');
        PowerBIReportUploads.Get(ReportId, UserSecurityId);
        Assert.IsTrue(IsNullGuid(PowerBIReportUploads."Uploaded Report ID"), 'Report was not uploaded yet.');
        Assert.IsTrue(PowerBIReportUploads."Should Retry", 'Service failure should leave the report as still retryable.');

        PowerBIServiceStatusSetup.Reset();
        PowerBIServiceStatusSetup.FindFirst;
        Assert.AreEqual(OutageDateTime, PowerBIServiceStatusSetup."Retry After", 'Service failure should update table 6309.');
        Assert.IsFalse(PowerBIServiceMgt.IsPBIServiceAvailable,
          'Service should be marked as unavailable when retry time is in the future.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetryingHandlesRefreshError()
    var
        AllProfile: Record "All Profile";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ReportId: Guid;
        NewRetryTime: DateTime;
        RoleCenterContext: Text[30];
    begin
        // [SCENARIO] RetryAllPartialReportUploads can deal with the retry still failing.
        Init;

        // [GIVEN] Blob exists and has been partially uploaded.
        ReportId := CreateGuid();
        ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
        RoleCenterContext := AllProfile."Profile ID";

        AddBlobToDatabase(ReportId, 'Report 1', 1);
        AddDefaultSelectionToDatabase(ReportId, RoleCenterContext, true);
        AddPartialUploadToDatabase(ReportId, CreateGuid(), true, 0DT);

        NewRetryTime := CurrentDateTime;
        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, false, false, true, NewRetryTime);

        // [WHEN] System calls RetryAllPartialReportUploads.
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        // [THEN] Uploads table record is unchanged.
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Table 6307 should still have only one record.');
        PowerBIReportUploads.Get(ReportId, UserSecurityId);
        Assert.IsTrue(IsNullGuid(PowerBIReportUploads."Uploaded Report ID"), 'PBI ID should still be empty.');
        Assert.IsFalse(IsNullGuid(PowerBIReportUploads."Import ID"), 'Import ID should still have a value.');
        Assert.IsTrue(PowerBIReportUploads."Should Retry", 'ShouldRetry should be updated.');
        Assert.AreEqual(NewRetryTime, PowerBIReportUploads."Retry After", 'RetryAfter should be updated.');
    end;

#if not CLEAN18
    [Test]
    [Scope('OnPrem')]
    procedure TestRetryingUpdatesOngoingDeploymentStatus()
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ReportId: Guid;
        RoleCenterContext: Text[30];
    begin
        // [SCENARIO] RetryAllPartialReportUploads marks deployment as finished, regardless of success or failure.
        Init;

        // [GIVEN] Blob exists and needs to be retried.
        ReportId := CreateGuid();
        ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
        RoleCenterContext := AllProfile."Profile ID";

        AddBlobToDatabase(ReportId, 'Report 1', 1);
        AddDefaultSelectionToDatabase(ReportId, RoleCenterContext, true);
        AddPartialUploadToDatabase(ReportId, CreateGuid(), true, 0DT);

        PowerBIServiceMgt.SetIsRetryingUploads(true);
        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, false, false, true, 0DT);

        // [WHEN] System calls RetryAllPartialReportUploads.
        PowerBIServiceMgt.RetryAllPartialReportUploads;

        // [THEN] OngoingDeployments table gets set back to false each time.
        Assert.IsFalse(PowerBIServiceMgt.IsUserDeployingReports, 'Ongoing deployment table should be set back to false.');

        PowerBIServiceMgt.SetIsRetryingUploads(true);
        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, false, true, false, 0DT);
        PowerBIServiceMgt.RetryAllPartialReportUploads;

        Assert.IsFalse(PowerBIServiceMgt.IsUserDeployingReports, 'Ongoing deployment table should be set back to false again.');
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure TestGPDeploymentInNewCompany()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part";
        ReportId1: Guid;
        ReportId2: Guid;
        ReportId3: Guid;
        Id2: Guid;
    begin
        // [SCENARIO] When user logs in for the first time after Intelligent Cloud sync, only reports for gp and that context must be deployed.
        Init();
        OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt);
        PowerBIReportSpinnerPartTestPage.OptInGettingStarted.Drilldown();

        // [GIVEN] Reports are available in system tables
        InitDefaultSelectionTests(ReportId1, ReportId2, ReportId3);
        Id2 := CreateGuid();
        LibraryPowerBIServiceMgt.AddPowerBIReport(CreateGuid(), Report1NameTxt, ReportId1);
        LibraryPowerBIServiceMgt.AddPowerBIReport(Id2, Report2NameTxt, ReportId2);

        // [WHEN] Intelligent Cloud is enabled and report deployment begins
        EnableIntelligentCloudForGP;
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        // [THEN] The all reports should be deployed
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'GP report should be deployed.');
        PowerBIReportUploads.SetFilter(IsGP, '%1', false);
        Assert.AreEqual(0, PowerBIReportUploads.Count, 'There should no BC reports');
        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetFilter(IsGP, '%1', true);
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'There should be 1 GP report');
        PowerBIReportSpinnerPartTestPage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAndSetReportFilter()
    var
        PowerBIEmbedHelper: Codeunit "Power BI Embed Helper";
        CallbackMessage: Text;
        CurrentListSelection: Text;
        CurrentReportFirstPage: Text;
        ResponseForWebPage: Text;
        LatestReceivedFilterInfo: Text;
    begin
        // Valid
        CallbackMessage := '{"method":"POST","url":"/reports/undefined/events/loaded","headers":{"id":"q627d"},"body":{}}';
        PowerBIEmbedHelper.HandleAddInCallback(CallbackMessage, CurrentListSelection, CurrentReportFirstPage, LatestReceivedFilterInfo, ResponseForWebPage);
        Assert.AreNotEqual(ResponseForWebPage, '', 'Unexpected response.');

        // Invalid - we swallow expection..so no error should be thrown
        CallbackMessage := '{"id": "getpagesfromreport"}';
        PowerBIEmbedHelper.HandleAddInCallback(CallbackMessage, CurrentListSelection, CurrentReportFirstPage, LatestReceivedFilterInfo, ResponseForWebPage);
        Assert.AreEqual(ResponseForWebPage, '', 'Unexpected response.');

        // Invalid - we swallow expection..so no error should be thrown
        CallbackMessage := '{"id": "getpagesfromreport", "body": "error"}';
        PowerBIEmbedHelper.HandleAddInCallback(CallbackMessage, CurrentListSelection, CurrentReportFirstPage, LatestReceivedFilterInfo, ResponseForWebPage);
        Assert.AreEqual(ResponseForWebPage, '', 'Unexpected response.');
    end;

    [Test]
    [HandlerFunctions('SetupWizardPageHandler')]
    [Scope('OnPrem')]
    procedure TestFreFromSpinnerWithNoLicense()
    var
        PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part";
        PowerBIEmbedSetupWizard: TestPage "Power BI Embed Setup Wizard";
    begin
        // Test the first run experience from the Power BI report spinner license.
        InitWithoutLicense();
        OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, 'BUSINESS MANAGER');

        Assert.IsTrue(PowerBIReportSpinnerPartTestPage.OptInGettingStarted.Visible(), 'Getting started is not visible.');

        asserterror PowerBIReportSpinnerPartTestPage.OptInGettingStarted.Drilldown();
        Assert.ExpectedError('We could not check your license for Power BI. Make sure you have an active Power BI license for your user account.\\If you just activated a license, it might take a few minutes for Power BI to update.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFreFromSpinnerWithLicense()
    var
        PowerBIReportSpinnerPart: TestPage "Power BI Report Spinner Part";
        PowerBIEmbedSetupWizard: TestPage "Power BI Embed Setup Wizard";
    begin
        // Test the first run experience from the Power BI report spinner with no license.
        InitWithoutLicense();
        OpenSpinnerPartPage(PowerBIReportSpinnerPart, 'BUSINESS MANAGER');

        Assert.IsTrue(PowerBIReportSpinnerPart.OptInGettingStarted.Visible(), 'Getting started is not visible.');

        AssignLicense();
        PowerBIReportSpinnerPart.OptInGettingStarted.Drilldown();

        Assert.IsFalse(PowerBIReportSpinnerPart.OptInGettingStarted.Visible(), 'Getting started is still visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsDeployingShowsLabelSpinner()
    var
        PowerBIUserStatus: Record "Power BI User Status";
        PowerBIReportSpinnerPart: TestPage "Power BI Report Spinner Part";
        PowerBIEmbedSetupWizard: TestPage "Power BI Embed Setup Wizard";
    begin
        // Test the first run experience from the Power BI report spinner with no license.
        InitWithoutLicense();
        OpenSpinnerPartPage(PowerBIReportSpinnerPart, 'BUSINESS MANAGER');

        Assert.IsTrue(PowerBIReportSpinnerPart.OptInGettingStarted.Visible(), 'Getting started is not visible.');

        AssignLicense();
        if not PowerBIUserStatus.Get(UserSecurityId()) then begin
            PowerBIUserStatus.Init();
            PowerBIUserStatus."User Security ID" := UserSecurityId();
            PowerBIUserStatus.Insert();
        end;

        PowerBIUserStatus."Is Synchronizing" := true;
        PowerBIUserStatus.Modify();

        PowerBIReportSpinnerPart.OptInGettingStarted.Drilldown();

        Assert.IsFalse(PowerBIReportSpinnerPart.OptInGettingStarted.Visible(), 'Getting started is still visible.');
        Assert.IsFalse(PowerBIReportSpinnerPart.NoReportsMessage2.Visible(), 'Label about deploying is not visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsDeployingShowsLabelFactbox()
    var
        PowerBIUserStatus: Record "Power BI User Status";
        PowerBIReportFactbox: TestPage "Power BI Report FactBox";
        PowerBIEmbedSetupWizard: TestPage "Power BI Embed Setup Wizard";
    begin
        // Test the first run experience from the Power BI report spinner with no license.
        InitWithoutLicense();
        OpenFactBoxPartPage(PowerBIReportFactbox, 'BUSINESS MANAGER');

        Assert.IsTrue(PowerBIReportFactbox.OptInGettingStarted.Visible(), 'Getting started is not visible.');

        AssignLicense();
        if not PowerBIUserStatus.Get(UserSecurityId()) then begin
            PowerBIUserStatus.Init();
            PowerBIUserStatus."User Security ID" := UserSecurityId();
            PowerBIUserStatus.Insert();
        end;

        PowerBIUserStatus."Is Synchronizing" := true;
        PowerBIUserStatus.Modify();

        PowerBIReportFactbox.OptInGettingStarted.Drilldown();

        Assert.IsFalse(PowerBIReportFactbox.OptInGettingStarted.Visible(), 'Getting started is still visible.');
        Assert.IsFalse(PowerBIReportFactbox.NoReportsMessage2.Visible(), 'Label about deploying is not visible.');
    end;

    // Helpers

    local procedure Init()
    begin
        InitWithoutLicense();
        AssignLicense();
    end;

    local procedure AssignLicense()
    var
        PowerBIUserLicense: Record "Power BI User License";
    begin
        PowerBIUserLicense.Init();
        PowerBIUserLicense."User Security ID" := UserSecurityId;
        PowerBIUserLicense."Has Power BI License" := true;
        PowerBIUserLicense.Insert();
    end;

    local procedure InitWithoutLicense()
    var
        PowerBIBlob: Record "Power BI Blob";
        IntelligentCloud: Record "Intelligent Cloud";
        PowerBIUserLicense: Record "Power BI User License";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBICustomerReports: Record "Power BI Customer Reports";
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        PowerBIUserConfiguration: Record "Power BI User Configuration";
#if not CLEAN18
        PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
#endif
        PowerBIServiceStatusSetup: Record "Power BI Service Status Setup";
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
        PowerBISessionManager: Codeunit "Power BI Session Manager";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        PowerBISessionManager.ClearState();

        // Sets all tables and settings back to initial state so each test can run with a blank slate.
        LibraryPowerBIServiceMgt.SetupMockPBIService;
        if not IsInitialized then begin
            BindSubscription(LibraryPowerBIServiceMgt);
            BindSubscription(LibraryAzureADAuthFlow);
            EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
            IsInitialized := true;
        end;

        LibraryAzureADAuthFlow.SetCachedTokenAvailable(true);
        LibraryPowerBIServiceMgt.ResetMockDeploymentCounts;

        PowerBIBlob.DeleteAll();
        PowerBIDefaultSelection.DeleteAll();
        PowerBIReportUploads.DeleteAll();
        PowerBIReportConfiguration.DeleteAll();
        PowerBIUserConfiguration.DeleteAll();
#if not CLEAN18
        PowerBIOngoingDeployments.DeleteAll();
#endif
        PowerBIServiceStatusSetup.DeleteAll();
        PowerBICustomerReports.DeleteAll();
        IntelligentCloud.DeleteAll();

        LibraryPowerBIServiceMgt.ClearReports;

        PowerBIUserLicense.DeleteAll();
    end;

    local procedure AddBlobToDatabase(Id: Guid; Name: Text[200]; Version: Integer)
    begin
        AddBlobToDatabaseGP(Id, Name, Version, false);
    end;

    local procedure AddBlobToDatabaseGP(Id: Guid; Name: Text[200]; Version: Integer; GPEnabled: Boolean)
    var
        PowerBIBlob: Record "Power BI Blob";
    begin
        // Helper method to add a row to table 2000000144 with the given values and a dummy blob.
        PowerBIBlob.Reset();
        PowerBIBlob.Init();
        PowerBIBlob.Id := Id;
        PowerBIBlob.Name := Name;
        PowerBIBlob.Version := Version;
        PowerBIBlob."GP Enabled" := GPEnabled;
        PowerBIBlob.Insert();
    end;

    local procedure AddDefaultSelectionToDatabase(Id: Guid; Context: Text[30]; Selected: Boolean)
    var
        PowerBIDefaultSelection: Record "Power BI Default Selection";
    begin
        // Helper method to add a row to table 2000000145 with the given values.
        PowerBIDefaultSelection.Reset();
        PowerBIDefaultSelection.Id := Id;
        PowerBIDefaultSelection.Context := Context;
        PowerBIDefaultSelection.Selected := Selected;
        PowerBIDefaultSelection.Insert();
    end;

    local procedure AddReportUploadToDatabase(BlobId: Guid; UserId: Guid; ReportId: Guid; ImportId: Guid; Version: Integer; SelectionDone: Boolean; EmbedUrl: Text[250]; ShouldRetry: Boolean; RetryAfter: DateTime)
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
        // Helper method to add a row to table 6307 with the given values.
        PowerBIReportUploads.Init();
        PowerBIReportUploads."PBIX BLOB ID" := BlobId;
        PowerBIReportUploads."User ID" := UserId;
        PowerBIReportUploads."Uploaded Report ID" := ReportId;
        PowerBIReportUploads."Import ID" := ImportId;
        PowerBIReportUploads."Deployed Version" := Version;
        PowerBIReportUploads."Is Selection Done" := SelectionDone;
        PowerBIReportUploads."Report Embed Url" := EmbedUrl;
        PowerBIReportUploads."Should Retry" := ShouldRetry;
        PowerBIReportUploads."Retry After" := RetryAfter;
        PowerBIReportUploads.Insert();
    end;

    local procedure AddCompletedUploadToDatabase(BlobId: Guid; UploadedId: Guid; SelectionDone: Boolean)
    begin
        // Simple helper for quickly adding a completed upload to table 6307.
        AddReportUploadToDatabase(BlobId, UserSecurityId, UploadedId, NullGuid, 1, SelectionDone, 'https://www.powerbi.com', false, 0DT);
    end;

    local procedure AddPartialUploadToDatabase(BlobId: Guid; ImportId: Guid; ShouldRetry: Boolean; RetryAfter: DateTime)
    begin
        // Simple helper for quickly adding an upload with unfinished refresh to table 6307.
        AddReportUploadToDatabase(BlobId, UserSecurityId, NullGuid, ImportId, 1, false, '', ShouldRetry, RetryAfter);
    end;

    local procedure EnableIntelligentCloudForGP()
    var
        IntelligentCloud: Record "Intelligent Cloud";
    begin
        IntelligentCloud.Init();
        IntelligentCloud."Primary Key" := '';
        IntelligentCloud.Enabled := true;
        IntelligentCloud.Insert();
    end;

    [HandlerFunctions('SetupWizardPageHandler')]
    local procedure OpenSpinnerPartPage(var PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part"; Context: Text[30])
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        SetPowerBIUserConfig: Codeunit "Set Power BI User Config";
        PowerBIReportSpinnerPart: Page "Power BI Report Spinner Part";
    begin
        PowerBIReportSpinnerPartTestPage.Trap;
        PowerBIReportSpinnerPart.SetContext(Context);
        PowerBIReportSpinnerPart.Run;
    end;

    [HandlerFunctions('SetupWizardPageHandler')]
    local procedure OpenFactBoxPartPage(var PowerBIReportFactBoxTestPage: TestPage "Power BI Report FactBox"; Context: Text[30])
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        SetPowerBIUserConfig: Codeunit "Set Power BI User Config";
        PowerBIReportFactBox: Page "Power BI Report FactBox";
        IsVisible: Boolean;
    begin
        PowerBIReportFactBoxTestPage.Trap;
        PowerBIReportFactBox.InitFactBox(Context, Context, IsVisible);
        PowerBIReportFactBox.SetFactBoxVisibility(IsVisible); // hidden by default so set to true to show factbox
        PowerBIReportFactBox.Run;
    end;

#if not CLEAN19
    local procedure OpenReportSelectionPage(var PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection"; Context: Text[30])
    var
        PowerBIReportSelection: Page "Power BI Report Selection";
    begin
        PowerBIReportSelectionTestPage.Trap;
        PowerBIReportSelection.SetContext(Context);
        PowerBIReportSelection.RunModal;
    end;
#endif

    local procedure InitDefaultSelectionTests(var ReportId1: Guid; var ReportId2: Guid; var ReportId3: Guid)
    begin
        ReportId1 := CreateGuid();
        AddBlobToDatabaseGP(ReportId1, Report1NameTxt, 1, false);
        AddDefaultSelectionToDatabase(ReportId1, Context1Txt, true);
        ReportId2 := CreateGuid();
        AddBlobToDatabaseGP(ReportId2, Report2NameTxt, 1, true);
        AddDefaultSelectionToDatabase(ReportId2, Context1Txt, true);
        ReportId3 := CreateGuid();
        AddBlobToDatabaseGP(ReportId3, Report3NameTxt, 1, false);
        AddDefaultSelectionToDatabase(ReportId3, '', false); // When Selection is FALSE, Context must be blank

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);
    end;

#if not CLEAN19
    [HandlerFunctions('SelectionPageHandler')]
    local procedure TestDefaultSelection(IsFactboxTest: Boolean)
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIReportFactBoxTestPage: TestPage "Power BI Report FactBox";
        PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part";
        PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection";
        ReportId1: Guid;
        ReportId2: Guid;
        ReportId3: Guid;
        Id1: Guid;
        Id3: Guid;
        ExistingReport: Text[100];
    begin
        // [SCENARIO] When user login for the first time the default selected report must be proper.
        Init;

        // [GIVEN] Reports that need to be uploaded and selected by default
        InitDefaultSelectionTests(ReportId1, ReportId2, ReportId3);

        // Mocking powerbi api
        Id1 := CreateGuid();
        Id3 := CreateGuid();
        ExistingReport := 'SExisting';
        // This one is deployed report
        LibraryPowerBIServiceMgt.AddPowerBIReport(Id1, Report1NameTxt, ReportId1);
        // This is existing report in workspace
        LibraryPowerBIServiceMgt.AddPowerBIReport(Id3, ExistingReport, Id3);

        // [WHEN] PowerBI part is loaded and report deployment is done
        if IsFactboxTest = false then begin
            OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt);
            PowerBIReportSpinnerPartTestPage.OptInGettingStarted.Drilldown();
        end else begin
            OpenFactBoxPartPage(PowerBIReportFactBoxTestPage, Context1Txt);
            PowerBIReportFactBoxTestPage.OptInGettingStarted.Drilldown();
        end;

        // [THEN] The default selected report must be proper
        OpenReportSelectionPage(PowerBIReportSelectionTestPage, Context1Txt);
        PowerBIReportSelectionTestPage.First;
        PowerBIReportSelectionTestPage.ReportName.AssertEquals(Report1NameTxt);
        PowerBIReportSelectionTestPage.Enabled.AssertEquals(true);
        PowerBIReportSelectionTestPage.Next;
        PowerBIReportSelectionTestPage.ReportName.AssertEquals(ExistingReport);
        PowerBIReportSelectionTestPage.Enabled.AssertEquals(false);
        Assert.IsFalse(PowerBIReportSelectionTestPage.Next, 'Only two reports must be available');

        PowerBIUserConfiguration.Reset();
        Assert.AreEqual(1, PowerBIUserConfiguration.Count, 'There must be only one selected report');
        PowerBIUserConfiguration.FindFirst;
        Assert.AreEqual(Id1, PowerBIUserConfiguration."Selected Report ID", 'Wrong report is selected');

        Assert.AreEqual(1, PowerBIReportUploads.Count, 'There must be only one report deployed');

        // [WHEN] Another report is enabled through selection page
        PowerBIReportSelectionTestPage.Enabled.SetValue(true);
        PowerBIReportSelectionTestPage.ReportName.AssertEquals(ExistingReport);
        PowerBIReportSelectionTestPage.Enabled.AssertEquals(true);
        PowerBIReportSelectionTestPage.Close;

        // [THEN] The default selected report must be proper
        OpenReportSelectionPage(PowerBIReportSelectionTestPage, Context1Txt);
        PowerBIReportSelectionTestPage.First;
        PowerBIReportSelectionTestPage.ReportName.AssertEquals(Report1NameTxt);
        PowerBIReportSelectionTestPage.Enabled.AssertEquals(true);
        PowerBIReportSelectionTestPage.Next;
        PowerBIReportSelectionTestPage.ReportName.AssertEquals(ExistingReport);
        PowerBIReportSelectionTestPage.Enabled.AssertEquals(true);
        Assert.IsFalse(PowerBIReportSelectionTestPage.Next, 'Only two reports must be available');
        PowerBIReportSelectionTestPage.Close;
        if IsFactboxTest = false then
            PowerBIReportSpinnerPartTestPage.Close
        else
            PowerBIReportFactBoxTestPage.Close;
    end;

    local procedure TestDefaultSelectionAfterIntelligentCloudSync(IsFactboxTest: Boolean)
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        PowerBIReportFactBoxTestPage: TestPage "Power BI Report FactBox";
        PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part";
        PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection";
        ReportId1: Guid;
        ReportId2: Guid;
        ReportId3: Guid;
        Id2: Guid;
    begin
        // [SCENARIO] When user login for the first time after Intelligent Cloud sync the default selected report must be a GP report.
        Init;

        // [GIVEN] Reports are available in system table and user has already logged in once
        InitDefaultSelectionTests(ReportId1, ReportId2, ReportId3);
        Id2 := CreateGuid();
        LibraryPowerBIServiceMgt.AddPowerBIReport(Id2, Report1NameTxt, ReportId1);
        LibraryPowerBIServiceMgt.AddPowerBIReport(CreateGuid(), Report2NameTxt, ReportId2);

        if IsFactboxTest = false then begin
            OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt);
            PowerBIReportSpinnerPartTestPage.OptInGettingStarted.Drilldown();
            PowerBIReportSpinnerPartTestPage.Close
        end else begin
            OpenFactBoxPartPage(PowerBIReportFactBoxTestPage, Context1Txt);
            PowerBIReportFactBoxTestPage.OptInGettingStarted.Drilldown();
            PowerBIReportFactBoxTestPage.Close
        end;

        // [WHEN] Intelligent Cloud is enabled and user refreshes page again
        EnableIntelligentCloudForGP;
        if IsFactboxTest = false then begin
            OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt);
            PowerBIReportSpinnerPartTestPage.OptInGettingStarted.Drilldown();
        end else begin
            OpenFactBoxPartPage(PowerBIReportFactBoxTestPage, Context1Txt);
            PowerBIReportFactBoxTestPage.OptInGettingStarted.Drilldown();
        end;

        // [THEN] The default selected report must be GP one
        OpenReportSelectionPage(PowerBIReportSelectionTestPage, Context1Txt);
        PowerBIReportSelectionTestPage.FILTER.SetFilter(ReportName, Report1NameTxt);
        PowerBIReportSelectionTestPage.First;
        PowerBIReportSelectionTestPage.ReportName.AssertEquals(Report1NameTxt);
        PowerBIReportSelectionTestPage.Enabled.AssertEquals(true);
        PowerBIReportSelectionTestPage.Close;
        if IsFactboxTest = false then
            PowerBIReportSpinnerPartTestPage.Close
        else
            PowerBIReportFactBoxTestPage.Close;

        PowerBIUserConfiguration.Reset();
        Assert.AreEqual(1, PowerBIUserConfiguration.Count, 'There must be only one selected report');
        PowerBIUserConfiguration.FindFirst;
        Assert.AreEqual(Id2, PowerBIUserConfiguration."Selected Report ID", 'Wrong report is selected');
    end;

    // Handlers

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectionPageHandler(var PowerBIReportSelection: Page "Power BI Report Selection"; var Response: Action)
    begin
        PowerBIReportSelection.Run;
    end;
#endif

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetupWizardPageHandler(var PowerBIEmbedSetupWizard: TestPage "Power BI Embed Setup Wizard")
    begin
        PowerBIEmbedSetupWizard.ActionNext.Invoke(); // Intro -> Licensecheck
        PowerBIEmbedSetupWizard.ActionNext.Invoke(); // Licensecheck -> Done

        Assert.IsTrue(PowerBIEmbedSetupWizard.ActionFinish.Visible() and PowerBIEmbedSetupWizard.ActionFinish.Enabled(), 'Wizard not completed.');
        PowerBIEmbedSetupWizard.ActionFinish.Invoke();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnBeforeJobQueueScheduleTask', '', false, false)]
    local procedure ExecuteJobQueueInForeground(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
        Assert.AreEqual(JobQueueEntry."Object ID to Run", Codeunit::"Power BI Report Synchronizer", 'Wrong codeunit scheduled');
        Assert.AreEqual(JobQueueEntry."Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit, 'Wrong codeunit scheduled');

        DoNotScheduleTask := true;

        Codeunit.Run(JobQueueEntry."Object ID to Run");
    end;
}