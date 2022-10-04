codeunit 131016 "Library - Power BI Service Mgt"
{
    // // Mock for Power BI Service Mgt (codeunit 6301) that unit tests can use to test Power BI pages without live PBI connections.

    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
#if not CLEAN21
        MockPowerBIReportBuffer: Record "Power BI Report Buffer";
#endif
        BlobReportMap: DotNet GenericDictionary2;
        MockExceptionMessage: Text;
        MockExceptionDetails: Text;
        MockDeploymentUploadSuccessful: Boolean;
        MockDeploymentRefreshSuccessful: Boolean;
        MockDeploymentServiceAvailable: Boolean;
        MockDeploymentShouldRetry: Boolean;
        MockDeploymentRetryAfter: DateTime;
        MockUrlTxt: Label 'http://www.powerbi.com', Locked = true;
        MockDeploymentUploadCount: Integer;
        MockDeploymentRetryCount: Integer;
        ContextTxt: Label 'Context1';

    [Scope('OnPrem')]
    procedure GetContext(): Text[30]
    begin
        exit(ContextTxt);
    end;

#if not CLEAN21
    procedure SetupMockPBIService()
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
        AzureADAppSetup: Record "Azure AD App Setup";
    begin
        // Sets the system to use this codeunit for Power BI service calls instead of the default, by overwriting
        // values in table 6303.
        AzureADMgtSetup.Get();
        AzureADMgtSetup."PBI Service Mgt. Codeunit ID" := CODEUNIT::"Library - Power BI Service Mgt";
        AzureADMgtSetup."Auth Flow Codeunit ID" := CODEUNIT::"Library - Azure AD Auth Flow";
        AzureADMgtSetup.Modify();
        with AzureADAppSetup do
            if not Get() then begin
                Init();
                "Redirect URL" := 'http://dummyurl:1234/Main_Instance1/WebClient/OAuthLanding.htm';
                "App ID" := CreateGuid();
                SetSecretKeyToIsolatedStorage(CreateGuid());
                Insert();
            end;
    end;

    procedure AddReport(Id: Guid; Name: Text[100]; Enabled: Boolean)
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
    begin
        // Adds a fake report to the mocked PBI account.
        MockPowerBIReportBuffer.Init();
        MockPowerBIReportBuffer.ReportID := Id;
        MockPowerBIReportBuffer.ReportName := Name;
        MockPowerBIReportBuffer.Enabled := Enabled;
        MockPowerBIReportBuffer.Insert();
        if Enabled = true then begin
            PowerBIReportConfiguration.Reset();
            PowerBIReportConfiguration.Init();
            PowerBIReportConfiguration."User Security ID" := UserSecurityId;
            PowerBIReportConfiguration.Context := ContextTxt;
            PowerBIReportConfiguration."Report ID" := Id;
            PowerBIReportConfiguration.Insert();
        end;
    end;

    procedure ClearReports()
    begin
        // Empties the list of reports in the mocked PBI account.
        MockPowerBIReportBuffer.Reset();
        MockPowerBIReportBuffer.DeleteAll();
        if not IsNull(BlobReportMap) then
            BlobReportMap.Clear
    end;

    procedure AddPowerBIReport(ReportId: Guid; Name: Text[100]; BlobId: Guid)
    begin
        // Adds a fake report to the mocked PBI account.
        AddReport(ReportId, Name, false);
        if IsNull(BlobReportMap) then
            BlobReportMap := BlobReportMap.Dictionary();

        BlobReportMap.Add(BlobId, ReportId);
    end;
    #endif

    procedure AddException(ExceptionMessage: Text; ExceptionDetails: Text)
    begin
        // Sets the values of the exception that gets returned when calling GetReports.
        MockExceptionMessage := ExceptionMessage;
        MockExceptionDetails := ExceptionDetails;
    end;

    procedure ClearException()
    begin
        // Clears the stored exception values that get returned when calling GetReports.
        MockExceptionMessage := '';
        MockExceptionDetails := '';
    end;

#if not CLEAN21
    local procedure CanHandle(): Boolean
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
    begin
        // Determines whether the PBI service calls are set to use this codeunit rather than the regular non-mocked version,
        // by checking table 6303. Tests need to call SetupMockPBIService() to set this correctly.
        if AzureADMgtSetup.Get() then
            exit(AzureADMgtSetup."PBI Service Mgt. Codeunit ID" = CODEUNIT::"Library - Power BI Service Mgt");

        exit(false);
    end;

#if not CLEAN21
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Power BI Service Mgt.", 'OnGetReports', '', false, false)]
    local procedure OnGetReports(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary; var ExceptionMessage: Text; var ExceptionDetails: Text; EnglishContext: Text[30])
    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
    begin
        // Event handler mock for GetReports, where we ask Power BI for a list of all reports in the user's account.
        if CanHandle and MockPowerBIReportBuffer.FindSet() then begin
            repeat
                Clear(TempPowerBIReportBuffer);
                TempPowerBIReportBuffer.TransferFields(MockPowerBIReportBuffer);
                TempPowerBIReportBuffer.Enabled := PowerBIServiceMgt.IsReportEnabled(TempPowerBIReportBuffer.ReportID, EnglishContext);
                TempPowerBIReportBuffer.Insert();
            until MockPowerBIReportBuffer.Next() = 0;

            ExceptionMessage := MockExceptionMessage;
            ExceptionDetails := MockExceptionDetails;
        end;
    end;
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Power BI Service Mgt.", 'OnUploadReports', '', false, false)]
    local procedure OnUploadReports(var ApiRequestList: DotNet ImportReportRequestList; var ApiResponseList: DotNet ImportReportResponseList)
    var
        UploadRequest: DotNet ImportReportRequest;
        MockResponse: DotNet ImportReportResponse;
        MockReport: DotNet ImportedReport;
        DotNetDateTime: DotNet DateTime;
    begin
        // Event handler mock for ImportReports, where we send a list of reports to Power BI to upload into
        // the user's account.
        if CanHandle() then begin
            if not MockDeploymentServiceAvailable then begin
                DotNetDateTime := MockDeploymentRetryAfter;
                ApiResponseList.RetryAfter := DotNetDateTime;
            end;

            foreach UploadRequest in ApiRequestList do begin
                MockDeploymentUploadCount := MockDeploymentUploadCount + 1;
                MockResponse := MockResponse.ImportReportResponse(UploadRequest.ReportId);

                if MockDeploymentServiceAvailable and MockDeploymentUploadSuccessful then begin
                    MockResponse.ImportId := CreateGuid();

                    if MockDeploymentRefreshSuccessful then begin
                        MockReport := MockReport.ImportedReport(GetPowerBIReportId(UploadRequest.ReportId), MockUrlTxt);
                        MockResponse.ImportedReport := MockReport;
                    end else
                        MockResponse.SetRetry(MockDeploymentShouldRetry, MockDeploymentRetryAfter);
                end;

                ApiResponseList.Add(MockResponse);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Power BI Service Mgt.", 'OnRetryUploads', '', false, false)]
    local procedure OnRetryUploads(var ImportIdList: DotNet ImportedReportRequestList; var ApiResponseList: DotNet ImportedReportResponseList)
    var
        MockResponse: DotNet ImportedReportResponse;
        MockReport: DotNet ImportedReport;
        DotNetDateTime: DotNet DateTime;
        ImportId: Text;
    begin
        // Event handler mock for GetImportedReports, where we send a list of previously uploaded reports to
        // Power BI to finish refreshing.
        if CanHandle() then begin
            if not MockDeploymentServiceAvailable then begin
                DotNetDateTime := MockDeploymentRetryAfter;
                ApiResponseList.RetryAfter := DotNetDateTime;
            end;

            foreach ImportId in ImportIdList do begin
                MockDeploymentRetryCount := MockDeploymentRetryCount + 1;
                MockResponse := MockResponse.ImportedReportResponse(ImportId);

                if MockDeploymentServiceAvailable and MockDeploymentRefreshSuccessful then begin
                    MockReport := MockReport.ImportedReport(CreateGuid, MockUrlTxt);
                    MockResponse.ImportedReport := MockReport;
                end else
                    MockResponse.SetRetry(MockDeploymentShouldRetry, MockDeploymentRetryAfter);

                ApiResponseList.Add(MockResponse);
            end;
            ImportIdList.Clear();
        end;
    end;
#endif

    procedure SetMockDeploymentResults(ServiceAvailable: Boolean; UploadSuccessful: Boolean; RefreshSuccessful: Boolean; ShouldRetry: Boolean; RetryAfter: DateTime)
    begin
        // Sets the intended output of any following calls to the mock deployment service (OnUploadReports/OnRetryUploads)
        // to simulate various success/failure states of the mock service.
        MockDeploymentServiceAvailable := ServiceAvailable;
        MockDeploymentUploadSuccessful := UploadSuccessful;
        MockDeploymentRefreshSuccessful := RefreshSuccessful;
        MockDeploymentShouldRetry := ShouldRetry;
        MockDeploymentRetryAfter := RetryAfter;
    end;

    procedure GetMockDeploymentUploadCount(): Integer
    begin
        // Gets cumulative number of reports that have been attempted to upload (regardless of success/failure).
        exit(MockDeploymentUploadCount);
    end;

    procedure GetMockDeploymentRetryCount(): Integer
    begin
        // Gets cumulative number of reports that have been attempted to retry (regardless of success/failure).
        exit(MockDeploymentRetryCount);
    end;

    procedure ResetMockDeploymentCounts()
    begin
        // Sets the counts of uploaded/retried reports back to 0 for starting a new unit test.
        MockDeploymentUploadCount := 0;
        MockDeploymentRetryCount := 0;
    end;

    local procedure GetPowerBIReportId(BlobId: Guid): Guid
    var
        DummyValue: Variant;
    begin
        if BlobReportMap.TryGetValue(BlobId, DummyValue) then
            exit(DummyValue);
        exit(CreateGuid());
    end;
}

