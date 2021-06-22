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
        PowerBIUserLicense: Record "Power BI User License";
        PowerBIBlob: Record "Power BI Blob";
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
        PowerBIServiceStatusSetup: Record "Power BI Service Status Setup";
        PowerBICustomerReports: Record "Power BI Customer Reports";
        IntelligentCloud: Record "Intelligent Cloud";
        PowerBIReportBuffer: Record "Power BI Report Buffer";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        LibraryPowerBIServiceMgt: Codeunit "Library - Power BI Service Mgt";
        LibraryAzureADAuthFlow: Codeunit "Library - Azure AD Auth Flow";
        Assert: Codeunit Assert;
        PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection";
        PowerBIReportFactBoxTestPage: TestPage "Power BI Report FactBox";
        PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part";
        IsInitialized: Boolean;
        NullGuid: Guid;
        Report1NameTxt: Label 'Report1';
        Report2NameTxt: Label 'Report2';
        Report3NameTxt: Label 'Report3';
        Context1Txt: Label 'Context1';
        ReportId1: Guid;
        ReportId2: Guid;
        ReportId3: Guid;
        IsFactboxTest: Boolean;

    [Test]
    [HandlerFunctions('SelectionPageHandler')]
    [Scope('OnPrem')]
    procedure TestDefaultSelectionWithSpinnerPart()
    begin
        IsFactboxTest := false;
        TestDefaultSelection;
    end;

    [Test]
    [HandlerFunctions('SelectionPageHandler')]
    [Scope('OnPrem')]
    procedure TestDefaultSelectionWithFactboxPart()
    begin
        IsFactboxTest := true;
        TestDefaultSelection;
    end;

    [Test]
    [HandlerFunctions('SelectionPageHandler')]
    [Scope('OnPrem')]
    procedure TestDefaultSelectionForGPWithSpinnerPart()
    begin
        IsFactboxTest := false;
        TestDefaultSelectionAfterIntelligentCloudSync;
    end;

    [Test]
    [HandlerFunctions('SelectionPageHandler')]
    [Scope('OnPrem')]
    procedure TestDefaultSelectionForGPWithFactboxPart()
    begin
        IsFactboxTest := true;
        TestDefaultSelectionAfterIntelligentCloudSync;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUploadingIgnoresAlreadyDeployedReports()
    var
        ReportId1: Guid;
        ReportId2: Guid;
        ReportId3: Guid;
    begin
        // [SCENARIO] UploadDefaultReport only uploads reports that haven't already been deployed.
        InitAndOpenPage;

        // [GIVEN] Blobs exist and some are already uploaded.
        ReportId1 := CreateGuid;
        AddBlobToDatabase(ReportId1, 'Report 1', 1);
        AddCompletedUploadToDatabase(ReportId1, CreateGuid, true);
        ReportId2 := CreateGuid;
        AddBlobToDatabase(ReportId2, 'Report 2', 1);
        AddDefaultSelectionToDatabase(ReportId2, Context1Txt, true);
        ReportId3 := CreateGuid;
        AddBlobToDatabase(ReportId3, 'Report 3', 1);
        AddPartialUploadToDatabase(ReportId3, CreateGuid, false, 0DT);

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);

        // [WHEN] System calls UploadDefaultReport.
        PowerBIServiceMgt.UploadDefaultReport;

        // [THEN] Uploads table has a new row with correct values.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have uploaded one report.');
        PowerBIReportUploads.Reset;
        Assert.AreEqual(3, PowerBIReportUploads.Count, 'Table 6307 should now have three records total.');
        PowerBIReportUploads.Get(ReportId2, UserSecurityId);
        PowerBIReportSpinnerPartTestPage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUploadingWithMultipleUsers()
    var
        ReportId1: Guid;
        ReportId2: Guid;
    begin
        // [SCENARIO] UploadDefaultReport uploads undeployed reports for current user only and ignores other users.
        InitAndOpenPage;

        // [GIVEN] Blobs exist, and a different user has already uploaded something.
        ReportId1 := CreateGuid;
        AddBlobToDatabase(ReportId1, 'Report 1', 1);
        AddDefaultSelectionToDatabase(ReportId1, Context1Txt, true);
        ReportId2 := CreateGuid;
        AddBlobToDatabase(ReportId2, 'Report 2', 1);
        AddReportUploadToDatabase(ReportId2, CreateGuid, CreateGuid, NullGuid, 1, true, '', false, 0DT);

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);

        // [WHEN] System calls UploadDefaultReport.
        PowerBIServiceMgt.UploadDefaultReport;

        // [THEN] Uploads table has new rows with correct values.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have uploaded two reports.');
        PowerBIReportUploads.Reset;
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
        ReportId: Guid;
        NewVersion: Integer;
    begin
        // [SCENARIO] UploadDefaultReport overwrites user's reports that have a newer version since they were deployed.
        InitAndOpenPage;

        // [GIVEN] Blob exists and has been uploaded for older version.
        ReportId := CreateGuid;
        AddReportUploadToDatabase(ReportId, UserSecurityId, CreateGuid, NullGuid, 0, true, '', false, 0DT);
        NewVersion := 2;
        AddBlobToDatabase(ReportId, 'Report 1', NewVersion);
        AddDefaultSelectionToDatabase(ReportId, Context1Txt, true);

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);

        // [WHEN] System calls UploadDefaultReport.
        PowerBIServiceMgt.UploadDefaultReport;

        // [THEN] Uploads table has updated the existing row.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have uploaded one report.');
        PowerBIReportUploads.Reset;
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Table 6307 should still have only one record.');
        PowerBIReportUploads.Get(ReportId, UserSecurityId);
        Assert.AreEqual(NewVersion, PowerBIReportUploads."Deployed Version", 'Record should have updated version number.');
        Assert.AreEqual(true, PowerBIReportUploads."Is Selection Done", 'Already selected report should still be selected.');
        PowerBIReportSpinnerPartTestPage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUploadingDuringServiceOutage()
    var
        OutageDateTime: DateTime;
        Id: Guid;
    begin
        // [SCENARIO] UploadDefaultReport tries to upload when Power BI is completely unavailable.
        InitAndOpenPage;

        // [GIVEN] Blob exists and hasn't been uploaded yet.
        Id := CreateGuid;
        AddBlobToDatabase(Id, 'Report 1', 1);
        AddDefaultSelectionToDatabase(Id, Context1Txt, true);

        OutageDateTime := CreateDateTime(20990101D, 0T);
        LibraryPowerBIServiceMgt.SetMockDeploymentResults(false, false, false, true, OutageDateTime);

        // [WHEN] System calls UploadDefaultReport.
        PowerBIServiceMgt.UploadDefaultReport;

        // [THEN] Uploads table is still empty and service is marked as unavailable.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have tried uploading the report.');
        PowerBIReportUploads.Reset;
        Assert.AreEqual(0, PowerBIReportUploads.Count, 'Failure should not add any records to table 6307.');
        PowerBIServiceStatusSetup.Reset;
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
        Id: Guid;
    begin
        // [SCENARIO] UploadDefaultReport fails to upload report at all.
        InitAndOpenPage;

        // [GIVEN] Blob exists and hasn't been uploaded yet.
        Id := CreateGuid;
        AddBlobToDatabase(Id, 'Report 1', 1);
        AddDefaultSelectionToDatabase(Id, Context1Txt, true);

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, false, false, true, 0DT);

        // [WHEN] System calls UploadDefaultReport.
        PowerBIServiceMgt.UploadDefaultReport;

        // [THEN] Uploads table is still empty but service is marked as available still.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have tried uploading the report.');
        PowerBIReportUploads.Reset;
        Assert.AreEqual(0, PowerBIReportUploads.Count, 'Failure should not add any records to table 6307.');
        Assert.IsTrue(PowerBIServiceMgt.IsPBIServiceAvailable,
          'Service should be marked as available still if upload did not fail from service unavailability.');
        PowerBIReportSpinnerPartTestPage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUploadingWithRefreshError()
    var
        ReportId: Guid;
        ReportVersion: Integer;
        ShouldRetry: Boolean;
        RetryAfter: DateTime;
    begin
        // [SCENARIO] UploadDefaultReport uploads a report but fails to refresh it.
        InitAndOpenPage;

        // [GIVEN] Blob exists and hasn't been uploaded yet.
        ReportId := CreateGuid;
        ReportVersion := 3;
        AddBlobToDatabase(ReportId, 'Report 1', ReportVersion);
        AddDefaultSelectionToDatabase(ReportId, Context1Txt, true);

        ShouldRetry := true;
        RetryAfter := CreateDateTime(20990101D, 0T);
        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, false, ShouldRetry, RetryAfter);

        // [WHEN] System calls UploadDefaultReport.
        PowerBIServiceMgt.UploadDefaultReport;

        // [THEN] Uploads table has a new row showing a report that needs to be retried.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have tried uploading the report.');
        PowerBIReportUploads.Reset;
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Table 6307 should have a row added.');
        PowerBIReportUploads.Get(ReportId, UserSecurityId);
        Assert.IsTrue(IsNullGuid(PowerBIReportUploads."Uploaded Report ID"), 'Record should not have a report ID when it fails.');
        Assert.IsFalse(IsNullGuid(PowerBIReportUploads."Import ID"), 'Record should get an import ID for retrying later.');
        Assert.AreEqual(ReportVersion, PowerBIReportUploads."Deployed Version", 'Record should have the correct version number.');
        Assert.IsFalse(PowerBIReportUploads."Is Selection Done", 'Failed upload should not be selected yet.');
        Assert.AreEqual('', PowerBIReportUploads."Embed Url", 'Failed upload should not have a report URL yet.');
        Assert.AreEqual(ShouldRetry, PowerBIReportUploads."Should Retry", 'Should Retry value should match the return from the service.');
        Assert.AreEqual(RetryAfter, PowerBIReportUploads."Retry After", 'Retry After time should match the return from the service.');
        PowerBIReportSpinnerPartTestPage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUploadingUpdatesOngoingDeploymentStatus()
    var
        Id: Guid;
    begin
        // [SCENARIO] UploadDefaultReport marks deployment as finished, regardless of success or failure.
        InitAndOpenPage;

        // [GIVEN] Blob exists and hasn't been uploaded yet.
        Id := CreateGuid;
        AddBlobToDatabase(Id, 'Report 1', 1);
        AddDefaultSelectionToDatabase(Id, Context1Txt, true);

        // [WHEN] System calls UploadDefaultReport.
        PowerBIServiceMgt.SetIsDeployingReports(true);
        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, false, false, false, 0DT);
        PowerBIServiceMgt.UploadDefaultReport;

        // [THEN] OngoingDeployments table gets set back to false each time.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have tried to upload one report.');
        Assert.IsFalse(PowerBIServiceMgt.IsUserDeployingReports, 'Ongoing deployment table should be set back to false.');

        PowerBIServiceMgt.SetIsDeployingReports(true);
        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);
        PowerBIServiceMgt.UploadDefaultReport;

        Assert.AreEqual(2, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'Service should have uploaded second time.');
        Assert.IsFalse(PowerBIServiceMgt.IsUserDeployingReports, 'Ongoing deployment table should be set back to false again.');
        PowerBIReportSpinnerPartTestPage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSuccessfulRetryOfPreviousUpload()
    var
        ReportId: Guid;
    begin
        // [SCENARIO] RetryAllPartialReportUploads finishes user's failed reports and handles successful return.
        Init;

        // [GIVEN] Blob with partial upload exists.
        ReportId := CreateGuid;
        AddBlobToDatabase(ReportId, 'Report 1', 1);
        AddPartialUploadToDatabase(ReportId, CreateGuid, true, 0DT);

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);

        // [WHEN] System calls RetryAllPartialReportUploads.
        PowerBIServiceMgt.RetryAllPartialReportUploads;

        // [THEN] Uploads table record is updated with correct values.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentRetryCount, 'Service should have retried one report.');
        PowerBIReportUploads.Reset;
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Table 6307 should still have one record.');
        PowerBIReportUploads.Get(ReportId, UserSecurityId);
        Assert.IsFalse(IsNullGuid(PowerBIReportUploads."Uploaded Report ID"), 'Record should be updated with a report ID.');
        Assert.IsTrue(IsNullGuid(PowerBIReportUploads."Import ID"), 'Record should not have an import ID anymore.');
        Assert.AreEqual(false, PowerBIReportUploads."Is Selection Done", 'Report should not be marked as selected yet.');
        Assert.AreNotEqual('', PowerBIReportUploads."Embed Url", 'Report should have a URL from the PBI service.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetryingIgnoresAlreadySuccesfulReports()
    var
        ReportId: Guid;
        PbiReportId: Guid;
        ReportVersion: Integer;
    begin
        // [SCENARIO] RetryAllPartialReportUploads won't retry an upload that was already successful.
        Init;

        // [GIVEN] Blob exists and has been partially uploaded.
        ReportId := CreateGuid;
        ReportVersion := 1;
        AddBlobToDatabase(ReportId, 'Report 1', ReportVersion);
        PbiReportId := CreateGuid;
        AddCompletedUploadToDatabase(ReportId, PbiReportId, false);

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);

        // [WHEN] System calls RetryAllPartialReportUploads.
        PowerBIServiceMgt.RetryAllPartialReportUploads;

        // [THEN] Uploads table record is unchanged.
        Assert.AreEqual(0, LibraryPowerBIServiceMgt.GetMockDeploymentRetryCount, 'Service should not have retried any reports.');
        PowerBIReportUploads.Reset;
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Table 6307 should still have only one record.');
        PowerBIReportUploads.Get(ReportId, UserSecurityId);
        Assert.AreEqual(PbiReportId, PowerBIReportUploads."Uploaded Report ID", 'ID in PBI account should not have changed.');
        Assert.IsTrue(IsNullGuid(PowerBIReportUploads."Import ID"), 'Record should still have no import ID.');
        Assert.AreNotEqual('', PowerBIReportUploads."Embed Url", 'Report should still have a URL from the PBI service.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetryingIgnoresNonRetriableReports()
    var
        ReportId: Guid;
        ReportVersion: Integer;
    begin
        // [SCENARIO] RetryAllPartialReportUploads won't retry an upload that has ShouldRetry=false.
        Init;

        // [GIVEN] Blob exists and has been partially uploaded.
        ReportId := CreateGuid;
        ReportVersion := 1;
        AddBlobToDatabase(ReportId, 'Report 1', ReportVersion);
        AddPartialUploadToDatabase(ReportId, CreateGuid, false, 0DT);

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);

        // [WHEN] System calls RetryAllPartialReportUploads.
        PowerBIServiceMgt.RetryAllPartialReportUploads;

        // [THEN] Uploads table record is unchanged.
        Assert.AreEqual(0, LibraryPowerBIServiceMgt.GetMockDeploymentRetryCount, 'Service should not have retried any reports.');
        PowerBIReportUploads.Reset;
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Table 6307 should still have only one record.');
        PowerBIReportUploads.Get(ReportId, UserSecurityId);
        Assert.IsTrue(IsNullGuid(PowerBIReportUploads."Uploaded Report ID"), 'PBI ID should still be empty.');
        Assert.IsFalse(PowerBIReportUploads."Should Retry", 'ShouldRetry should still be set to false.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetryingDuringServiceOutage()
    var
        ReportId: Guid;
        OutageDateTime: DateTime;
    begin
        // [SCENARIO] RetryAllPartialReportUploads tries to upload when Power BI is completely unavailable.
        Init;

        // [GIVEN] Blob exists and needs to be retried.
        ReportId := CreateGuid;
        AddBlobToDatabase(ReportId, 'Report 1', 1);
        AddPartialUploadToDatabase(ReportId, CreateGuid, true, 0DT);

        OutageDateTime := CreateDateTime(20990101D, 0T);
        LibraryPowerBIServiceMgt.SetMockDeploymentResults(false, false, false, true, OutageDateTime);

        // [WHEN] System calls RetryAllPartialReportUploads.
        PowerBIServiceMgt.RetryAllPartialReportUploads;

        // [THEN] Uploads table is unchanged and service is marked as unavailable.
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentRetryCount, 'Service should have tried refreshing the report.');
        PowerBIReportUploads.Reset;
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Still one record in table 6307.');
        PowerBIReportUploads.Get(ReportId, UserSecurityId);
        Assert.IsTrue(IsNullGuid(PowerBIReportUploads."Uploaded Report ID"), 'Report was not uploaded yet.');
        Assert.IsTrue(PowerBIReportUploads."Should Retry", 'Service failure should leave the report as still retryable.');

        PowerBIServiceStatusSetup.Reset;
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
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ReportId: Guid;
        NewRetryTime: DateTime;
        RoleCenterContext: Text[30];
    begin
        // [SCENARIO] RetryAllPartialReportUploads can deal with the retry still failing.
        Init;

        // [GIVEN] Blob exists and has been partially uploaded.
        ReportId := CreateGuid;
        ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
        RoleCenterContext := AllProfile."Profile ID";

        AddBlobToDatabase(ReportId, 'Report 1', 1);
        AddDefaultSelectionToDatabase(ReportId, RoleCenterContext, true);
        AddPartialUploadToDatabase(ReportId, CreateGuid, true, 0DT);

        NewRetryTime := CurrentDateTime;
        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, false, false, true, NewRetryTime);

        // [WHEN] System calls RetryAllPartialReportUploads.
        PowerBIServiceMgt.RetryAllPartialReportUploads;

        // [THEN] Uploads table record is unchanged.
        PowerBIReportUploads.Reset;
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'Table 6307 should still have only one record.');
        PowerBIReportUploads.Get(ReportId, UserSecurityId);
        Assert.IsTrue(IsNullGuid(PowerBIReportUploads."Uploaded Report ID"), 'PBI ID should still be empty.');
        Assert.IsFalse(IsNullGuid(PowerBIReportUploads."Import ID"), 'Import ID should still have a value.');
        Assert.IsTrue(PowerBIReportUploads."Should Retry", 'ShouldRetry should be updated.');
        Assert.AreEqual(NewRetryTime, PowerBIReportUploads."Retry After", 'RetryAfter should be updated.');
    end;

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
        ReportId := CreateGuid;
        ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
        RoleCenterContext := AllProfile."Profile ID";

        AddBlobToDatabase(ReportId, 'Report 1', 1);
        AddDefaultSelectionToDatabase(ReportId, RoleCenterContext, true);
        AddPartialUploadToDatabase(ReportId, CreateGuid, true, 0DT);

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

    local procedure Init()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
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

        PowerBIBlob.Reset;
        PowerBIBlob.DeleteAll;

        PowerBIDefaultSelection.Reset;
        PowerBIDefaultSelection.DeleteAll;

        PowerBIReportUploads.Reset;
        PowerBIReportUploads.DeleteAll;

        PowerBIReportConfiguration.Reset;
        PowerBIReportConfiguration.DeleteAll;

        PowerBIUserConfiguration.Reset;
        PowerBIUserConfiguration.DeleteAll;

        PowerBIOngoingDeployments.Reset;
        PowerBIOngoingDeployments.DeleteAll;

        PowerBIServiceStatusSetup.Reset;
        PowerBIServiceStatusSetup.DeleteAll;

        PowerBICustomerReports.Reset;
        PowerBICustomerReports.DeleteAll;

        PowerBIReportBuffer.Reset;
        PowerBIReportBuffer.DeleteAll;

        IntelligentCloud.Reset;
        IntelligentCloud.DeleteAll;

        PowerBIUserLicense.Reset;
        PowerBIUserLicense.DeleteAll;
        PowerBIUserLicense.Init;
        PowerBIUserLicense."User Security ID" := UserSecurityId;
        PowerBIUserLicense."Has Power BI License" := true;
        PowerBIUserLicense.Insert;

        LibraryPowerBIServiceMgt.ClearReports;
    end;

    local procedure InitAndOpenPage()
    begin
        Init;
        // Our new logic in UploadDefaultReport relies on entries in Power BI User Configuration table.
        // Opening page will set those values.
        OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt);
    end;

    local procedure AddBlobToDatabase(Id: Guid; Name: Text[200]; Version: Integer)
    begin
        AddBlobToDatabaseGP(Id, Name, Version, false);
    end;

    local procedure AddBlobToDatabaseGP(Id: Guid; Name: Text[200]; Version: Integer; GPEnabled: Boolean)
    begin
        // Helper method to add a row to table 2000000144 with the given values and a dummy blob.
        PowerBIBlob.Reset;
        PowerBIBlob.Init;
        PowerBIBlob.Id := Id;
        PowerBIBlob.Name := Name;
        PowerBIBlob.Version := Version;
        PowerBIBlob."GP Enabled" := GPEnabled;
        PowerBIBlob.Insert;
    end;

    local procedure AddDefaultSelectionToDatabase(Id: Guid; Context: Text[30]; Selected: Boolean)
    begin
        // Helper method to add a row to table 2000000145 with the given values.
        PowerBIDefaultSelection.Reset;
        PowerBIDefaultSelection.Id := Id;
        PowerBIDefaultSelection.Context := Context;
        PowerBIDefaultSelection.Selected := Selected;
        PowerBIDefaultSelection.Insert;
    end;

    local procedure AddReportUploadToDatabase(BlobId: Guid; UserId: Guid; ReportId: Guid; ImportId: Guid; Version: Integer; SelectionDone: Boolean; EmbedUrl: Text[250]; ShouldRetry: Boolean; RetryAfter: DateTime)
    begin
        // Helper method to add a row to table 6307 with the given values.
        PowerBIReportUploads.Reset;
        PowerBIReportUploads.Init;
        PowerBIReportUploads."PBIX BLOB ID" := BlobId;
        PowerBIReportUploads."User ID" := UserId;
        PowerBIReportUploads."Uploaded Report ID" := ReportId;
        PowerBIReportUploads."Import ID" := ImportId;
        PowerBIReportUploads."Deployed Version" := Version;
        PowerBIReportUploads."Is Selection Done" := SelectionDone;
        PowerBIReportUploads."Embed Url" := EmbedUrl;
        PowerBIReportUploads."Should Retry" := ShouldRetry;
        PowerBIReportUploads."Retry After" := RetryAfter;
        PowerBIReportUploads.Insert;
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
    begin
        IntelligentCloud.Init;
        IntelligentCloud."Primary Key" := '';
        IntelligentCloud.Enabled := true;
        IntelligentCloud.Insert;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectionPageHandler(var PowerBIReportSelection: Page "Power BI Report Selection"; var Response: Action)
    begin
        PowerBIReportSelection.Run;
    end;

    local procedure OpenSpinnerPartPage(var PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part"; Context: Text[30])
    var
        PowerBIReportSpinnerPart: Page "Power BI Report Spinner Part";
    begin
        PowerBIReportSpinnerPartTestPage.Trap;
        PowerBIReportSpinnerPart.SetContext(Context);
        PowerBIReportSpinnerPart.Run;
        // HACK: DeployTimer is not initalized since it is a webclient addin. Pong doesn't get called. So need to call logic in Pong explicitly
        PowerBIServiceMgt.SelectDefaultReports;
    end;

    local procedure OpenFactBoxPartPage(var PowerBIReportFactBoxTestPage: TestPage "Power BI Report FactBox"; Context: Text[30])
    var
        PowerBIReportFactBox: Page "Power BI Report FactBox";
        IsVisible: Boolean;
    begin
        PowerBIReportFactBoxTestPage.Trap;
        PowerBIReportFactBox.InitFactBox(Context, Context, IsVisible);
        PowerBIReportFactBox.SetFactBoxVisibility(IsVisible); // hidden by default so set to true to show factbox
        PowerBIReportFactBox.Run;
        IsVisible := true;
        // HACK: DeployTimer is not initalized since it is a webclient addin. Pong doesn't get called. So need to call logic in Pong explicitly
        PowerBIServiceMgt.SelectDefaultReports;
    end;

    local procedure OpenReportSelectionPage(var PowerBIReportSelectionTestPage: TestPage "Power BI Report Selection"; Context: Text[30])
    var
        PowerBIReportSelection: Page "Power BI Report Selection";
    begin
        PowerBIReportSelectionTestPage.Trap;
        PowerBIReportSelection.SetContext(Context);
        PowerBIReportSelection.RunModal;
    end;

    local procedure InitDefaultSelectionTests()
    begin
        ReportId1 := CreateGuid;
        AddBlobToDatabaseGP(ReportId1, Report1NameTxt, 1, false);
        AddDefaultSelectionToDatabase(ReportId1, Context1Txt, true);
        ReportId2 := CreateGuid;
        AddBlobToDatabaseGP(ReportId2, Report2NameTxt, 1, true);
        AddDefaultSelectionToDatabase(ReportId2, Context1Txt, true);
        ReportId3 := CreateGuid;
        AddBlobToDatabaseGP(ReportId3, Report3NameTxt, 1, false);
        AddDefaultSelectionToDatabase(ReportId3, '', false); // When Selection is FALSE, Context must be blank

        LibraryPowerBIServiceMgt.SetMockDeploymentResults(true, true, true, false, 0DT);
    end;

    [HandlerFunctions('SelectionPageHandler')]
    local procedure TestDefaultSelection()
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part";
        Id1: Guid;
        Id3: Guid;
        ExistingReport: Text[100];
    begin
        // [SCENARIO] When user login for the first time the default selected report must be proper.
        Init;

        // [GIVEN] Reports that need to be uploaded and selected by default
        InitDefaultSelectionTests;

        // Mocking powerbi api
        Id1 := CreateGuid;
        Id3 := CreateGuid;
        ExistingReport := 'SExisting';
        // This one is deployed report
        LibraryPowerBIServiceMgt.AddPowerBIReport(Id1, Report1NameTxt, ReportId1);
        // This is existing report in workspace
        LibraryPowerBIServiceMgt.AddPowerBIReport(Id3, ExistingReport, Id3);

        // [WHEN] PowerBI part is loaded and report deployment is done
        if IsFactboxTest = false then
            OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt)
        else
            OpenFactBoxPartPage(PowerBIReportFactBoxTestPage, Context1Txt);

        // [THEN] The default selected report must be proper
        OpenReportSelectionPage(PowerBIReportSelectionTestPage, Context1Txt);
        PowerBIReportSelectionTestPage.First;
        PowerBIReportSelectionTestPage.ReportName.AssertEquals(Report1NameTxt);
        PowerBIReportSelectionTestPage.Enabled.AssertEquals(true);
        PowerBIReportSelectionTestPage.Next;
        PowerBIReportSelectionTestPage.ReportName.AssertEquals(ExistingReport);
        PowerBIReportSelectionTestPage.Enabled.AssertEquals(false);
        Assert.IsFalse(PowerBIReportSelectionTestPage.Next, 'Only two reports must be available');

        PowerBIUserConfiguration.Reset;
        Assert.AreEqual(1, PowerBIUserConfiguration.Count, 'There must be only one selected report');
        PowerBIUserConfiguration.FindFirst;
        Assert.AreEqual(Id1, PowerBIUserConfiguration."Selected Report ID", 'Wrong report is selected');

        PowerBIReportUploads.Reset;
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

    local procedure TestDefaultSelectionAfterIntelligentCloudSync()
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        PowerBIReportSpinnerPartTestPage: TestPage "Power BI Report Spinner Part";
        Id2: Guid;
    begin
        // [SCENARIO] When user login for the first time after Intelligent Cloud sync the default selected report must be a GP report.
        Init;

        // [GIVEN] Reports are available in system table and user has already logged in once
        InitDefaultSelectionTests;
        Id2 := CreateGuid;
        LibraryPowerBIServiceMgt.AddPowerBIReport(Id2, Report1NameTxt, ReportId1);
        LibraryPowerBIServiceMgt.AddPowerBIReport(CreateGuid, Report2NameTxt, ReportId2);

        if IsFactboxTest = false then begin
            OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt);
            PowerBIReportSpinnerPartTestPage.Close
        end else begin
            OpenFactBoxPartPage(PowerBIReportFactBoxTestPage, Context1Txt);
            PowerBIReportFactBoxTestPage.Close
        end;

        // [WHEN] Intelligent Cloud is enabled and user refreshes page again
        EnableIntelligentCloudForGP;
        if IsFactboxTest = false then
            OpenSpinnerPartPage(PowerBIReportSpinnerPartTestPage, Context1Txt)
        else
            OpenFactBoxPartPage(PowerBIReportFactBoxTestPage, Context1Txt);

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

        PowerBIUserConfiguration.Reset;
        Assert.AreEqual(1, PowerBIUserConfiguration.Count, 'There must be only one selected report');
        PowerBIUserConfiguration.FindFirst;
        Assert.AreEqual(Id2, PowerBIUserConfiguration."Selected Report ID", 'Wrong report is selected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGPDeploymentInNewCompany()
    var
        Id2: Guid;
    begin
        // [SCENARIO] When user logs in for the first time after Intelligent Cloud sync, only reports for gp and that context must be deployed.
        InitAndOpenPage;

        // [GIVEN] Reports are available in system tables
        InitDefaultSelectionTests;
        Id2 := CreateGuid;
        LibraryPowerBIServiceMgt.AddPowerBIReport(CreateGuid, Report1NameTxt, ReportId1);
        LibraryPowerBIServiceMgt.AddPowerBIReport(Id2, Report2NameTxt, ReportId2);

        // [WHEN] Intelligent Cloud is enabled and report deployment begins
        EnableIntelligentCloudForGP;
        PowerBIServiceMgt.UploadDefaultReport;

        // [THEN] The all reports should be deployed
        Assert.AreEqual(1, LibraryPowerBIServiceMgt.GetMockDeploymentUploadCount, 'GP report should be deployed.');
        PowerBIReportUploads.Reset;
        PowerBIReportUploads.SetFilter(IsGP, '%1', false);
        Assert.AreEqual(0, PowerBIReportUploads.Count, 'There should no BC reports');
        PowerBIReportUploads.Reset;
        PowerBIReportUploads.SetFilter(IsGP, '%1', true);
        Assert.AreEqual(1, PowerBIReportUploads.Count, 'There should be 1 GP report');
        PowerBIReportSpinnerPartTestPage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAndSetReportFilter()
    var
        PowerBIReportFactBox: Page "Power BI Report FactBox";
        Json: Text;
    begin
        // Valid
        Json := '{"id": "getpagesfromreport", "body": [{"name":"n1"}]}';
        PowerBIReportFactBox.GetAndSetReportFilter(Json);

        // Invalid - we swallow expection..so no error should be thrown
        Json := '{"id": "getpagesfromreport"}';
        PowerBIReportFactBox.GetAndSetReportFilter(Json);

        // Invalid - we swallow expection..so no error should be thrown
        Json := '{"id": "getpagesfromreport", "body": "error"}';
        PowerBIReportFactBox.GetAndSetReportFilter(Json);
    end;
}

