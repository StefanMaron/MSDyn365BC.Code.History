codeunit 6301 "Power BI Service Mgt."
{
    // // Manages access to the Power BI service API's (aka powerbi.com)

    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        EnvironmentInformation: Codeunit "Environment Information";
        PowerBISessionManager: Codeunit "Power BI Session Manager";
        GenericErr: Label 'An error occurred while trying to get reports from the Power BI service. Please try again or contact your system administrator if the error persists.';
        PowerBiResourceNameTxt: Label 'Power BI Services';
        OngoingDeploymentTelemetryMsg: Label 'Setting Power BI Ongoing Deployment record for user. Field: %1; Value: %2.', Locked = true;
        ErrorWebResponseTelemetryMsg: Label 'Getting data failed with status code: %1. Exception Message: %2. Exception Details: %3.', Locked = true;
        RetryAfterNotSatisfiedTelemetryMsg: Label 'PowerBI service not ready. Will retry after: %1.', Locked = true;
        BlobDoesNotExistTelemetryMsg: Label 'Trying to upload a non-existing blob, with ID: %1.', Locked = true;
        EmptyAccessTokenTelemetryMsg: Label 'Encountered an empty access token.', Locked = true;
        ParseReportsWarningTelemetryMsg: Label 'Parse reports encountered an unexpected token.', Locked = true;
        UrlTooLongTelemetryMsg: Label 'Parsing reports encountered a URL that is too long to be saved to ReportEmbedUrl. Json message: %1.', Locked = true;
        ReportPageSizeTxt: Label '16:9', Locked = true;
        PowerBIurlErr: Label 'https://powerbi.microsoft.com', Locked = true;
        UnauthorizedErr: Label 'You do not have a Power BI account. You can get a Power BI account at the following location.';
        DataNotFoundErr: Label 'The report(s) you are trying to load do not exist.';
        NavAppSourceUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862351', Locked = true;
        Dyn365AppSourceUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862352', Locked = true;
        PowerBIMyOrgUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862353', Locked = true;
        NullGuidTxt: Label '00000000-0000-0000-0000-000000000000', Locked = true;
        ItemTxt: Label 'Items', Locked = true;
        VendorTxt: Label 'Vendors', Locked = true;
        CustomerTxt: Label 'Customers', Locked = true;
        SalesTxt: Label 'Sales Orders', Locked = true;
        InvoicesTxt: Label 'Purchase Invoices', Locked = true;
        HackPowerBIGuidTxt: Label '06D251CE-A824-44B2-A5F9-318A0674C3FB', Locked = true;
        UpdateEmbedCache: Boolean;
        PowerBiTelemetryCategoryLbl: Label 'PowerBI', Locked = true;
        ReportEnvNameTxt: Label '%1 %2', Locked = true;
        EnvNameTxt: Text;

    [Scope('OnPrem')]
    procedure GetReports(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary; var ExceptionMessage: Text; var ExceptionDetails: Text; EnglishContext: Text[30])
    var
        JObj: JsonObject;
        Url: Text;
        ResponseText: Text;
    begin
        // Gets a list of reports from the user's Power BI account and loads them into the given buffer.
        // Reports are marked as Enabled if they've previously been selected for the given context (page ID).
        if not TempPowerBIReportBuffer.IsEmpty then
            exit;

        if not CanHandleServiceCalls then begin
            OnGetReports(TempPowerBIReportBuffer, ExceptionMessage, ExceptionDetails, EnglishContext);
            exit;
        end;

        Url := GetReportsUrl;

        ResponseText := GetData(ExceptionMessage, ExceptionDetails, Url);

        JObj.ReadFrom(ResponseText); // TODO: check versions

        ParseReports(TempPowerBIReportBuffer, JObj, EnglishContext);
    end;

    [Scope('OnPrem')]
    procedure GetReportsForUserContext(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary; var ExceptionMessage: Text; var ExceptionDetails: Text; EnglishContext: Text[30])
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
        JObj: JsonObject;
        Url: Text;
        ResponseText: Text;
    begin
        // Checks whether the user has any reports with blank URLs, for the current context (to be used by spinner/factbox).
        // These would be Report Configuration (table 6301) rows created before the addition of the URL column, so they
        // don't have a cached URL we can load. In that case we need to load reports the old fashioned way, from the PBI
        // service with a GetReports call. (Empty URLs like this only get updated on running the Select Reports page.)
        if not TempPowerBIReportBuffer.IsEmpty then
            exit;

        Url := GetReportsUrl;

        PowerBIReportConfiguration.Reset();
        PowerBIReportConfiguration.SetFilter("User Security ID", UserSecurityId);
        PowerBIReportConfiguration.SetFilter(Context, EnglishContext);

        if PowerBIReportConfiguration.Find('-') then
            repeat
                if PowerBIReportConfiguration.ReportEmbedUrl <> '' then begin
                    // get it from cache
                    TempPowerBIReportBuffer.ReportID := PowerBIReportConfiguration."Report ID";
                    TempPowerBIReportBuffer.Validate(ReportEmbedUrl, PowerBIReportConfiguration.ReportEmbedUrl);
                    TempPowerBIReportBuffer.Enabled := true;
                    if TempPowerBIReportBuffer.Insert() then;
                end else begin
                    // get url from power bi
                    // There should never be a case when this code block gets called. So logging telemetry to troubleshoot in case it happens.
                    SendTraceTag('0000B6Z', PowerBiTelemetryCategoryLbl, Verbosity::Warning,
                        StrSubstNo('GetReportsForUserContext : GetData from powerbi Context: %1 ReportId: %2', EnglishContext, Format(PowerBIReportConfiguration."Report ID")),
                        DataClassification::CustomerContent);
                    if not IsNullGuid(PowerBIReportConfiguration."Report ID") then begin
                        // If both the embed URL and the ID are empty, we have no data about the report to load, so no action is possible.
                        ResponseText := GetData(ExceptionMessage, ExceptionDetails, Url + '/' + Format(PowerBIReportConfiguration."Report ID"));
                        JObj.ReadFrom(ResponseText);
                        ParseReport(TempPowerBIReportBuffer, JObj, EnglishContext);
                    end;
                end;
            until PowerBIReportConfiguration.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckForPowerBILicense(): Boolean
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
        // Checks whether the user has power bi license/account or not
        if PowerBISessionManager.GetHasPowerBILicense then
            exit(true);

        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetFilter("User ID", UserSecurityId);

        // Record in this table indicates the power bi service is already called on behalf of this user.
        if not PowerBIReportUploads.IsEmpty then begin
            PowerBISessionManager.SetHasPowerBILicense(true);
            exit(true);
        end;

        TASKSCHEDULER.CreateTask(CODEUNIT::"PBI Check License Task", 0, true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure IsReportEnabled(ReportId: Guid; EnglishContext: Text): Boolean
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
    begin
        exit(PowerBIReportConfiguration.Get(UserSecurityId, ReportId, EnglishContext));
    end;

    [Scope('OnPrem')]
    procedure IsUserReadyForPowerBI(): Boolean
    begin
        if not AzureAdMgt.IsAzureADAppSetupDone then
            exit(false);

        exit(AzureAdMgt.GetAccessToken(GetPowerBIResourceUrl, GetPowerBiResourceName, false) <> '');
    end;

    procedure GetPowerBIResourceUrl(): Text
    var
        UrlHelper: Codeunit "Url Helper";
    begin
        exit(UrlHelper.GetPowerBIResourceUrl);
    end;

    procedure GetPowerBiResourceName(): Text
    begin
        exit(PowerBiResourceNameTxt);
    end;

    procedure GetGenericError(): Text
    begin
        exit(GenericErr);
    end;

    procedure GetReportPageSize(): Text
    begin
        exit(ReportPageSizeTxt);
    end;

    procedure GetUnauthorizedErrorText(): Text
    begin
        exit(UnauthorizedErr);
    end;

    procedure GetPowerBIUrl(): Text
    begin
        exit(PowerBIurlErr);
    end;

    procedure GetContentPacksServicesUrl(): Text
    begin
        // Gets the URL for AppSource's list of content packs, like Power BI's Services button, filtered to Dynamics reports.
        if AzureADMgt.IsSaaS then
            exit(Dyn365AppSourceUrlTxt);

        exit(NavAppSourceUrlTxt);
    end;

    procedure GetContentPacksMyOrganizationUrl(): Text
    begin
        // Gets the URL for Power BI's embedded AppSource page listing reports shared by the user's organization.
        exit(PowerBIMyOrgUrlTxt);
    end;

    [Scope('OnPrem')]
    procedure UploadDefaultReportInBackground()
    begin
        if not CanHandleServiceCalls then begin
            UploadDefaultReport;
            exit;
        end;
        // Schedules a background task to do default report deployment (codeunit 6311 which calls back into
        // the UploadAllDefaultReports method in this codeunit).
        SetIsDeployingReports(true);
        TASKSCHEDULER.CreateTask(CODEUNIT::"PBI Start Uploads Task", CODEUNIT::"PBI Deployment Failure", true);
    end;

    [Scope('OnPrem')]
    procedure UploadDefaultReport()
    var
        PageId: Text[50];
    begin
        PageId := GetPageId;

        if PageId = '' then begin
            SetIsDeployingReports(false);
            exit;
        end;

        UploadDefaultReportForContext(PageId);
        SetIsDeployingReports(false);
    end;

    local procedure UploadDefaultReportForContext(Context: Text[50])
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBICustomerReports: Record "Power BI Customer Reports";
        UrlHelper: Codeunit "Url Helper";
        PbiServiceWrapper: DotNet ServiceWrapper;
        ApiRequest: DotNet ImportReportRequest;
        ApiRequestList: DotNet ImportReportRequestList;
        ApiResponseList: DotNet ImportReportResponseList;
        ApiResponse: DotNet ImportReportResponse;
        DotNetDateTime: DotNet DateTime;
        BlobStream: InStream;
        AzureAccessToken: Text;
        BusinessCentralAccessToken: Text;
        BlobId: Guid;
    begin
        // Uploads a default report
        if not IsPBIServiceAvailable then
            exit;

        BlobId := GetBlobIdForDeployment(Context);
        if not PowerBIBlob.Get(BlobId) then begin
            SendTraceTag('0000B61', PowerBiTelemetryCategoryLbl, Verbosity::Warning,
                StrSubstNo(BlobDoesNotExistTelemetryMsg, BlobId), DataClassification::SystemMetadata);
            exit;
        end;

        ApiRequestList := ApiRequestList.ImportReportRequestList;
        SetEnvironmentForDeployment();

        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetFilter("User ID", UserSecurityId);
        PowerBIReportUploads.SetFilter("PBIX BLOB ID", PowerBIBlob.Id);
        if PowerBIReportUploads.IsEmpty or
           (PowerBIReportUploads.FindFirst and (PowerBIReportUploads."Deployed Version" <> PowerBIBlob.Version) and
            not PowerBIReportUploads."Needs Deletion")
        then begin
            PowerBIBlob.CalcFields("Blob File"); // Calcfields necessary for accessing stored Blob bytes.
            PowerBIBlob."Blob File".CreateInStream(BlobStream);
            ApiRequest := ApiRequest.ImportReportRequest
              (PowerBIBlob.Id, BlobStream, StrSubstNo(ReportEnvNameTxt, EnvNameTxt, PowerBIBlob.Name), EnvNameTxt, not PowerBIReportUploads.IsEmpty);
            ApiRequestList.Add(ApiRequest);
        end;

        if not PowerBICustomerReports.IsEmpty then begin
            PowerBICustomerReports.Reset();
            if PowerBICustomerReports.Find('-') then
                repeat
                    PowerBIReportUploads.Reset();
                    PowerBIReportUploads.SetFilter("User ID", UserSecurityId);
                    PowerBIReportUploads.SetFilter("PBIX BLOB ID", PowerBICustomerReports.Id);
                    if PowerBIReportUploads.IsEmpty or (PowerBIReportUploads.FindFirst and
                                                        (PowerBIReportUploads."Deployed Version" <> PowerBICustomerReports.Version) and
                                                        not PowerBIReportUploads."Needs Deletion")
                    then begin
                        PowerBICustomerReports.CalcFields("Blob File"); // Calcfields necessary for accessing stored Blob bytes.
                        PowerBICustomerReports."Blob File".CreateInStream(BlobStream);
                        ApiRequest := ApiRequest.ImportReportRequest
                          (PowerBICustomerReports.Id, BlobStream, PowerBICustomerReports.Name, EnvNameTxt, not PowerBIReportUploads.IsEmpty);
                        ApiRequestList.Add(ApiRequest);
                    end;
                until PowerBICustomerReports.Next = 0;
        end;
        if ApiRequestList.Count > 0 then begin
            if CanHandleServiceCalls then begin
                AzureAccessToken := AzureAdMgt.GetAccessToken(GetPowerBIResourceUrl, GetPowerBiResourceName, false);

                if AzureAccessToken = '' then begin
                    SendTraceTag('0000B62', PowerBiTelemetryCategoryLbl, Verbosity::Warning, EmptyAccessTokenTelemetryMsg, DataClassification::SystemMetadata);
                    exit;
                end;

                PbiServiceWrapper := PbiServiceWrapper.ServiceWrapper(AzureAccessToken, UrlHelper.GetPowerBIApiUrl);

                BusinessCentralAccessToken := AzureAdMgt.GetAccessToken(UrlHelper.GetFixedEndpointWebServiceUrl(), '', false);

                if BusinessCentralAccessToken <> '' then
                    ApiResponseList := PbiServiceWrapper.ImportReports(ApiRequestList,
                        CompanyName, EnvNameTxt, BusinessCentralAccessToken, GetServiceRetries)
                else begin
                    SendTraceTag('0000B63', PowerBiTelemetryCategoryLbl, Verbosity::Warning, EmptyAccessTokenTelemetryMsg, DataClassification::SystemMetadata);
                    SetIsDeployingReports(false);
                    exit;
                end;
            end else begin
                ApiResponseList := ApiResponseList.ImportReportResponseList;
                OnUploadReports(ApiRequestList, ApiResponseList);
            end;
            foreach ApiResponse in ApiResponseList do
                HandleUploadResponse(ApiResponse.ImportId, ApiResponse.RequestReportId,
                  ApiResponse.ImportedReport, ApiResponse.ShouldRetry, ApiResponse.RetryAfter);

            if not IsNull(ApiResponseList.RetryAfter) then begin
                DotNetDateTime := ApiResponseList.RetryAfter;
                UpdatePBIServiceAvailability(DotNetDateTime);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure RetryUnfinishedReportsInBackground()
    begin
        if not CanHandleServiceCalls then begin
            RetryAllPartialReportUploads;
            exit;
        end;
        // Schedules a background task to do completion of partial uploads (codeunit 6312 which calls
        // back into the RetryAllPartialReportUploads method in this codeunit).
        SetIsRetryingUploads(true);
        TASKSCHEDULER.CreateTask(CODEUNIT::"PBI Retry Uploads Task", CODEUNIT::"PBI Retry Failure", true);
    end;

    [Scope('OnPrem')]
    procedure RetryAllPartialReportUploads()
    begin
        // Starts a sequence of default report deployments for any reports that only partially finished.
        // Prioritizes the active role center over other reports since the user will probably see those first.
        // Unlike UploadAllDefaultReports, doesn't end early if anything failed - want to avoid getting stuck
        // on a faulty report.
        // Should only be called as part of a background session to reduce perf impact (see RetryUnfinishedReportsInBackground).
        RetryPartialUploadBatch;

        SetIsRetryingUploads(false);
    end;

    local procedure RetryPartialUploadBatch()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        UrlHelper: Codeunit "Url Helper";
        PbiServiceWrapper: DotNet ServiceWrapper;
        ImportIdList: DotNet ImportedReportRequestList;
        ApiResponseList: DotNet ImportedReportResponseList;
        ApiResponse: DotNet ImportedReportResponse;
        DotNetDateTime: DotNet DateTime;
        AzureAccessToken: Text;
        BusinessCentralAccessToken: Text;
    begin
        // Retries a batch of default reports that have had their uploads started but not finished, based on
        // the passed in priority (see DoesDefaultReportMatchPriority). This will attempt to have the PBI service
        // retry the connection/refresh tasks to finish the upload process.
        // Returns true if all attempted retries completely finished, otherwise false.
        if not IsPBIServiceAvailable then
            exit;

        ImportIdList := ImportIdList.ImportedReportRequestList;

        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetFilter("User ID", UserSecurityId);
        PowerBIReportUploads.SetFilter("Uploaded Report ID", NullGuidTxt);
        PowerBIReportUploads.SetFilter("Should Retry", '%1', true);
        PowerBIReportUploads.SetFilter("Retry After", '<%1', CurrentDateTime);
        PowerBIReportUploads.SetFilter("Needs Deletion", '%1', false);
        if PowerBIReportUploads.Find('-') then
            repeat
                ImportIdList.Add(PowerBIReportUploads."Import ID");
            until PowerBIReportUploads.Next = 0;

        if ImportIdList.Count > 0 then begin
            if CanHandleServiceCalls then begin
                AzureAccessToken := AzureAdMgt.GetAccessToken(GetPowerBIResourceUrl, GetPowerBiResourceName, false);

                PbiServiceWrapper := PbiServiceWrapper.ServiceWrapper(AzureAccessToken, UrlHelper.GetPowerBIApiUrl);
                BusinessCentralAccessToken := AzureAdMgt.GetAccessToken(UrlHelper.GetFixedEndpointWebServiceUrl(), '', false);

                if BusinessCentralAccessToken <> '' then
                    ApiResponseList := PbiServiceWrapper.GetImportedReports(ImportIdList,
                        CompanyName, EnvNameTxt, BusinessCentralAccessToken, GetServiceRetries)
                else
                    exit;
            end else begin
                ApiResponseList := ApiResponseList.ImportedReportResponseList;
                OnRetryUploads(ImportIdList, ApiResponseList);
            end;
            foreach ApiResponse in ApiResponseList do
                HandleUploadResponse(ApiResponse.ImportId, NullGuidTxt, ApiResponse.ImportedReport,
                  ApiResponse.ShouldRetry, ApiResponse.RetryAfter);

            if not IsNull(ApiResponseList.RetryAfter) then begin
                DotNetDateTime := ApiResponseList.RetryAfter;
                UpdatePBIServiceAvailability(DotNetDateTime);
            end;
        end;
    end;

    local procedure HandleUploadResponse(ImportId: Text; BlobId: Guid; ReturnedReport: DotNet ImportedReport; ShouldRetry: DotNet Nullable1; RetryAfter: DotNet Nullable1) WasSuccessful: Boolean
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBICustomerReports: Record "Power BI Customer Reports";
        DotNetBoolean: DotNet Boolean;
        DotNetDateTime: DotNet DateTime;
    begin
        // Deals with individual responses from the Power BI service for importing or finishing imports of
        // default reports. This is what updates the tables so we know which reports are actually ready
        // to be selected, versus still needing work, depending on the info sent back by the service.
        // Returns true if the upload completely finished (i.e. got a report ID back), otherwise false.
        if ImportId <> '' then begin
            PowerBIReportUploads.Reset();
            PowerBIReportUploads.SetFilter("User ID", UserSecurityId);

            // Empty blob ID happens when we're finishing a partial upload (existing record in table 6307).
            if IsNullGuid(BlobId) then
                PowerBIReportUploads.SetFilter("Import ID", ImportId)
            else
                PowerBIReportUploads.SetFilter("PBIX BLOB ID", BlobId);

            if PowerBIReportUploads.IsEmpty then begin
                // First time this report has been uploaded.
                PowerBIReportUploads.Init();
                PowerBIReportUploads."PBIX BLOB ID" := BlobId;
                PowerBIReportUploads."User ID" := UserSecurityId;
                PowerBIReportUploads."Is Selection Done" := false;
            end else
                // Overwriting or finishing a previously uploaded report.
                PowerBIReportUploads.FindFirst;

            if not IsNull(ReturnedReport) then begin
                WasSuccessful := true;
                PowerBIReportUploads."Uploaded Report ID" := ReturnedReport.ReportId;
                PowerBIReportUploads.Validate("Report Embed Url",
                    CopyStr(ReturnedReport.EmbedUrl, 1, MaxStrLen(PowerBIReportUploads."Report Embed Url")));
                PowerBIReportUploads."Import ID" := NullGuidTxt;
                PowerBIReportUploads."Should Retry" := false;
                PowerBIReportUploads."Retry After" := 0DT;
            end else begin
                WasSuccessful := false;
                PowerBIReportUploads."Import ID" := ImportId;
                PowerBIReportUploads."Uploaded Report ID" := NullGuidTxt;
                if not IsNull(ShouldRetry) then begin
                    DotNetBoolean := ShouldRetry;
                    PowerBIReportUploads."Should Retry" := DotNetBoolean.Equals(true);
                end;
                if not IsNull(RetryAfter) then begin
                    DotNetDateTime := RetryAfter;
                    PowerBIReportUploads."Retry After" := DotNetDateTime;
                end;
            end;

            if PowerBIBlob.Get(PowerBIReportUploads."PBIX BLOB ID") then begin
                PowerBIReportUploads."Deployed Version" := PowerBIBlob.Version;
                PowerBIReportUploads.IsGP := PowerBIBlob."GP Enabled";
            end else
                if PowerBICustomerReports.Get(PowerBIReportUploads."PBIX BLOB ID") then
                    PowerBIReportUploads."Deployed Version" := PowerBICustomerReports.Version;

            if PowerBIReportUploads.IsEmpty then
                PowerBIReportUploads.Insert
            else
                PowerBIReportUploads.Modify();
            Commit();
        end;
    end;

    [Scope('OnPrem')]
    procedure SelectDefaultReports()
    var
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        IntelligentCloud: Record "Intelligent Cloud";
        PowerBIBlob: Record "Power BI Blob";
        PageId: Text[50];
    begin
        // Finds all recently uploaded default reports and enables/selects them on the appropriate pages
        // per table 2000000145.
        // (Note that each report only gets auto-selection done one time - if the user later deselects it
        // we won't keep reselecting it.)

        // If the GP flag is set in TAB2000000146, the report for the selected page/role center is removed
        // and we select the GP report
        PageId := GetPageId;

        if PageId = '' then
            exit;

        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetFilter("User ID", UserSecurityId);
        PowerBIReportUploads.SetFilter("Uploaded Report ID", '<>%1', NullGuidTxt);
        PowerBIReportUploads.SetFilter("Is Selection Done", '%1', false);

        if not IntelligentCloud.Get then
            PowerBIReportUploads.SetFilter(IsGP, '%1', false);

        if PowerBIReportUploads.Find('-') then
            repeat
                PowerBIReportUploads."Is Selection Done" := true;
                PowerBIReportUploads.Modify();

                PowerBIDefaultSelection.Reset();
                PowerBIDefaultSelection.SetFilter(Id, PowerBIReportUploads."PBIX BLOB ID");
                PowerBIDefaultSelection.SetFilter(Context, PageId);

                if PowerBIDefaultSelection.FindFirst then begin
                    PowerBIReportConfiguration.Reset();
                    PowerBIReportConfiguration.SetFilter("User Security ID", UserSecurityId);
                    PowerBIReportConfiguration.SetFilter("Report ID", PowerBIReportUploads."Uploaded Report ID");
                    PowerBIReportConfiguration.SetFilter(Context, PowerBIDefaultSelection.Context);
                    if not PowerBIReportConfiguration.IsEmpty then
                        if PowerBIReportConfiguration.Delete then;
                    PowerBIReportConfiguration.Init();
                    PowerBIReportConfiguration."User Security ID" := UserSecurityId;
                    PowerBIReportConfiguration."Report ID" := PowerBIReportUploads."Uploaded Report ID";
                    PowerBIReportConfiguration.Validate(ReportEmbedUrl, PowerBIReportUploads."Report Embed Url");
                    PowerBIReportConfiguration.Context := PowerBIDefaultSelection.Context;
                    if PowerBIReportConfiguration.Insert() then;

                    if PowerBIDefaultSelection.Selected then begin
                        PowerBIUserConfiguration.Reset();
                        PowerBIUserConfiguration.SetFilter("User Security ID", UserSecurityId);
                        PowerBIUserConfiguration.SetFilter("Page ID", PowerBIDefaultSelection.Context);
                        PowerBIUserConfiguration.SetFilter("Profile ID", GetEnglishContext);

                        // Don't want to override user's existing selections (e.g. in upgrade scenarios).
                        if PowerBIUserConfiguration.IsEmpty then begin
                            PowerBIUserConfiguration.Init();
                            PowerBIUserConfiguration."User Security ID" := UserSecurityId;
                            PowerBIUserConfiguration."Page ID" := PowerBIDefaultSelection.Context;
                            PowerBIUserConfiguration."Profile ID" := GetEnglishContext;
                            PowerBIUserConfiguration."Selected Report ID" := PowerBIReportUploads."Uploaded Report ID";
                            PowerBIUserConfiguration."Report Visibility" := true;
                            PowerBIUserConfiguration.Insert();
                        end else begin
                            // Modify existing selection if entry exists but no report selected (e.g. active page created
                            // empty configuration entry on page load before upload code even runs).
                            PowerBIUserConfiguration.FindFirst;
                            PowerBIBlob.Reset();
                            PowerBIBlob.SetFilter(Id, PowerBIUserConfiguration."Selected Report ID");
                            if (IntelligentCloud.Get and not PowerBIBlob."GP Enabled") or
                               IsNullGuid(PowerBIUserConfiguration."Selected Report ID")
                            then begin
                                PowerBIUserConfiguration."Selected Report ID" := PowerBIReportUploads."Uploaded Report ID";
                                PowerBIUserConfiguration.Modify();
                            end;
                        end;
                    end;
                end;
            until PowerBIReportUploads.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure DeleteDefaultReportsInBackground()
    begin
        // Schedules a background task to do default report deletion (codeunit 6315 which calls back into
        // the DeleteMarkedDefaultReports method in this codeunit).
        SetIsDeletingReports(true);
        TASKSCHEDULER.CreateTask(CODEUNIT::"PBI Start Deletions Task", CODEUNIT::"PBI Deletion Failure", true);
    end;

    [Scope('OnPrem')]
    procedure DeleteMarkedDefaultReports()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBICustomerReports: Record "Power BI Customer Reports";
    begin
        // Deletes a batch of default reports that have been marked for deletion for the current user. Reports are
        // deleted from the user's Power BI workspace first, and then removed from the uploads table if that was
        // successful.
        // Should only be called as part of a background session to reduce perf impact (see DeleteDefaultReportsInBackground).
        if not IsPBIServiceAvailable then
            exit;

        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetFilter("User ID", UserSecurityId);
        PowerBIReportUploads.SetFilter("Needs Deletion", '%1', true);

        if PowerBIReportUploads.Find('-') then
            repeat
                PowerBICustomerReports.Reset();
                PowerBICustomerReports.SetFilter(Id, PowerBIReportUploads."PBIX BLOB ID");
                repeat
                    if PowerBICustomerReports.Id = PowerBIReportUploads."PBIX BLOB ID" then
                        PowerBICustomerReports.Delete();
                until PowerBICustomerReports.Next = 0;
                PowerBIReportUploads.Delete();
            until PowerBIReportUploads.Next = 0;

        // TODO: Delete from ReportConfiguration table and replace with null GUID in UserConfiguration table.
        // TODO: ^^^ may confuse page 6303 depending on timing?
        // TODO: Only do after API says it was deleted from workspace successfully (below)

        // REPEAT
        // IF NOT ISNULLGUID(PowerBIReportUploads."Uploaded Report ID") THEN BEGIN
        // TODO: Add Uploaded Report ID to API request list
        // END;

        // IF NOT ISNULLGUID(PowerBIReportUploads."Import ID") THEN BEGIN
        // TODO: Add Import ID to API request list
        // END;
        // UNTIL PowerBIReportUploads.NEXT = 0;

        // TODO: Send list of IDs to PBI API to try deleting those reports.
        // TODO: For each successfully delete report according to the API return, delete that row now.
        // TODO: Set service availability depending on API's response.

        SetIsDeletingReports(false);
    end;

    [Scope('OnPrem')]
    procedure UserNeedsToDeployReports(Context: Text[50]): Boolean
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBICustomerReports: Record "Power BI Customer Reports";
        BlobId: Guid;
    begin
        // Checks whether the user has any un-uploaded OOB reports, by checking for rows in table 2000000144
        // without corresponding rows in table 6307 yet (or rows that are an old version).
        BlobId := GetBlobIdForDeployment(Context);
        if not PowerBIBlob.Get(BlobId) then
            exit(false);

        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetFilter("User ID", UserSecurityId);
        PowerBIReportUploads.SetFilter("PBIX BLOB ID", PowerBIBlob.Id);

        if not PowerBIReportUploads.FindFirst then
            exit(true);

        if PowerBIReportUploads."Deployed Version" < PowerBIBlob.Version then
            exit(true);

        PowerBICustomerReports.Reset();
        if PowerBICustomerReports.Find('-') then
            repeat
                PowerBIReportUploads.Reset();
                PowerBIReportUploads.SetFilter("User ID", UserSecurityId);
                PowerBIReportUploads.SetFilter("PBIX BLOB ID", PowerBICustomerReports.Id);

                if PowerBIReportUploads.IsEmpty then
                    exit(true);

                PowerBIReportUploads.FindFirst;
                if PowerBIReportUploads."Deployed Version" < PowerBICustomerReports.Version then
                    exit(true);

            until PowerBICustomerReports.Next = 0;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure UserNeedsToRetryUploads(): Boolean
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
        // Checks whether the user has any partially deployed OOB reports that we need to finish the upload
        // process on (probably because it errored out partway through) i.e. rows in table 6307 that don't
        // have a final report ID from the PBI website yet.
        if not IsPBIServiceAvailable() or IsUserRetryingUploads() then
            exit(false);

        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetFilter("User ID", UserSecurityId);
        PowerBIReportUploads.SetFilter("Uploaded Report ID", NullGuidTxt);
        PowerBIReportUploads.SetFilter("Should Retry", '%1', true);
        PowerBIReportUploads.SetFilter("Retry After", '<%1', CurrentDateTime);
        exit(not PowerBIReportUploads.IsEmpty());
    end;

    [Scope('OnPrem')]
    procedure UserNeedsToDeleteReports(): Boolean
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
        // Checks whether the user has any uploaded OOB reports (including partially uploaded but not successfully
        // refreshed) by checking for rows in table 6307 with Needs Deletion set to TRUE.
        if not IsPBIServiceAvailable or IsUserDeletingReports then
            exit(false);

        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetFilter("User ID", UserSecurityId);
        PowerBIReportUploads.SetFilter("Needs Deletion", '%1', true);
        exit(not PowerBIReportUploads.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure IsUserDeployingReports(): Boolean
    var
        PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
    begin
        // Checks whether any background sessions are running (or waiting to run) for doing PBI default
        // report uploads, based on the values in table 6308.
        PowerBIOngoingDeployments.Reset();
        PowerBIOngoingDeployments.SetFilter("User Security ID", UserSecurityId);
        exit(PowerBIOngoingDeployments.FindFirst and PowerBIOngoingDeployments."Is Deploying Reports");
    end;

    [Scope('OnPrem')]
    procedure IsUserRetryingUploads(): Boolean
    var
        PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
    begin
        // Checks whether any background sessions are running (or waiting to run) for finishing partial
        // uploads of PBI default reports, based on the values in table 6308.
        PowerBIOngoingDeployments.Reset();
        PowerBIOngoingDeployments.SetFilter("User Security ID", UserSecurityId);
        exit(PowerBIOngoingDeployments.FindFirst and PowerBIOngoingDeployments."Is Retrying Uploads");
    end;

    [Scope('OnPrem')]
    procedure IsUserDeletingReports(): Boolean
    var
        PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
    begin
        // Checks whether any background sessions are running (or waiting to run) for deleting any
        // uploaded PBI default reports, based on the values in table 6308.
        PowerBIOngoingDeployments.Reset();
        PowerBIOngoingDeployments.SetFilter("User Security ID", UserSecurityId);
        exit(PowerBIOngoingDeployments.FindFirst and PowerBIOngoingDeployments."Is Deleting Reports");
    end;

    [Scope('OnPrem')]
    procedure SetIsDeployingReports(IsDeploying: Boolean)
    var
        PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
    begin
        // Sets values in table 6308 to indicate a report deployment session is currently running or
        // waiting to run. This lets us make sure we don't schedule any simulatenous sessions that would
        // accidentally deploy a report multiple times or something.
        SendPowerBiOngoingDeploymentsTelemetry(PowerBIOngoingDeployments.FieldCaption("Is Deploying Reports"), IsDeploying);
        PowerBIOngoingDeployments.LockTable();

        if PowerBIOngoingDeployments.Get(UserSecurityId) then begin
            PowerBIOngoingDeployments."Is Deploying Reports" := IsDeploying;
            PowerBIOngoingDeployments.Modify();
        end else begin
            PowerBIOngoingDeployments.Init();
            PowerBIOngoingDeployments."User Security ID" := UserSecurityId;
            PowerBIOngoingDeployments."Is Deploying Reports" := IsDeploying;
            PowerBIOngoingDeployments.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure SetIsRetryingUploads(IsRetrying: Boolean)
    var
        PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
    begin
        // Sets values in table 6308 to indicate a deployment retry session is currently running or
        // waiting to run. This lets us make sure we don't schedule any simulatenous sessions that would
        // accidentally retry an upload multiple times or something.
        SendPowerBiOngoingDeploymentsTelemetry(PowerBIOngoingDeployments.FieldCaption("Is Retrying Uploads"), IsRetrying);
        PowerBIOngoingDeployments.LockTable();

        if PowerBIOngoingDeployments.Get(UserSecurityId) then begin
            PowerBIOngoingDeployments."Is Retrying Uploads" := IsRetrying;
            PowerBIOngoingDeployments.Modify();
        end else begin
            PowerBIOngoingDeployments.Init();
            PowerBIOngoingDeployments."User Security ID" := UserSecurityId;
            PowerBIOngoingDeployments."Is Retrying Uploads" := IsRetrying;
            PowerBIOngoingDeployments.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure SetIsDeletingReports(IsDeleting: Boolean)
    var
        PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
    begin
        // Sets values in table 6308 to indicate a report deletion session is currently running or
        // waiting to run. This lets us make sure we don't schedule any simultaneous sessions that would
        // accidentally delete a report that is already trying to delete or something.
        SendPowerBiOngoingDeploymentsTelemetry(PowerBIOngoingDeployments.FieldCaption("Is Deleting Reports"), IsDeleting);
        PowerBIOngoingDeployments.LockTable();

        if PowerBIOngoingDeployments.Get(UserSecurityId) then begin
            PowerBIOngoingDeployments."Is Deleting Reports" := IsDeleting;
            PowerBIOngoingDeployments.Modify();
        end else begin
            PowerBIOngoingDeployments.Init();
            PowerBIOngoingDeployments."User Security ID" := UserSecurityId;
            PowerBIOngoingDeployments."Is Deleting Reports" := IsDeleting;
            PowerBIOngoingDeployments.Insert();
        end;
    end;

    local procedure SendPowerBiOngoingDeploymentsTelemetry(FieldChanged: Text; NewValue: Boolean)
    begin
        SendTraceTag('0000AYR',
            PowerBiTelemetryCategoryLbl,
            Verbosity::Normal,
            StrSubstNo(OngoingDeploymentTelemetryMsg, FieldChanged, NewValue),
            DataClassification::SystemMetadata
            );
    end;

    local procedure GetServiceRetries(): Integer
    begin
        // Const - number of attempts for deployment API calls.
        exit(25);
    end;

    [Scope('OnPrem')]
    procedure IsPBIServiceAvailable(): Boolean
    var
        PowerBIServiceStatusSetup: Record "Power BI Service Status Setup";
    begin
        // Checks whether the Power BI service is available for deploying default reports, based on
        // whether previous deployments have failed with a retry date/time that we haven't reached yet.
        PowerBIServiceStatusSetup.Reset();
        if PowerBIServiceStatusSetup.FindFirst then
            if PowerBIServiceStatusSetup."Retry After" > CurrentDateTime then begin
                SendTraceTag('0000B64', PowerBiTelemetryCategoryLbl, Verbosity::Normal,
                    StrSubstNo(RetryAfterNotSatisfiedTelemetryMsg, PowerBIServiceStatusSetup."Retry After"), DataClassification::SystemMetadata);
                exit(false);
            end;

        exit(true);
    end;

    local procedure UpdatePBIServiceAvailability(RetryAfter: DateTime)
    var
        PowerBIServiceStatusSetup: Record "Power BI Service Status Setup";
    begin
        // Sets the cross-company variable that tracks when the Power BI service is available for
        // deployment calls - service failures will return the date/time which we shouldn't attempt
        // new calls before.
        PowerBIServiceStatusSetup.Reset();
        if PowerBIServiceStatusSetup.FindFirst then begin
            PowerBIServiceStatusSetup."Retry After" := RetryAfter;
            PowerBIServiceStatusSetup.Modify();
        end else begin
            PowerBIServiceStatusSetup.Init();
            PowerBIServiceStatusSetup."Retry After" := RetryAfter;
            PowerBIServiceStatusSetup.Insert();
        end;
    end;

    [Scope('OnPrem')]
    [Obsolete('Use more specific tags to make data classification and filtering easier.','16.0')]
    procedure LogException(var ExceptionMessage: Text; var ExceptionDetails: Text)
    begin
    end;

    [Scope('OnPrem')]
    [Obsolete('Use more specific tags to make data classification and filtering easier.','16.0')]
    procedure LogMessage(Message: Text)
    begin
    end;

    procedure CanHandleServiceCalls(): Boolean
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
    begin
        // Checks if the current codeunit is allowed to handle Power BI service requests rather than a mock.
        if AzureADMgtSetup.Get then
            exit(AzureADMgtSetup."PBI Service Mgt. Codeunit ID" = CODEUNIT::"Power BI Service Mgt.");

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReports(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary; var ExceptionMessage: Text; var ExceptionDetails: Text; EnglishContext: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUploadReports(var ApiRequestList: DotNet ImportReportRequestList; var ApiResponseList: DotNet ImportReportResponseList)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetryUploads(var ImportIdList: DotNet ImportedReportRequestList; var ApiResponseList: DotNet ImportedReportResponseList)
    begin
    end;

    [Scope('OnPrem')]
    procedure HasUploads(): Boolean
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
        exit(not PowerBIReportUploads.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure GetFactboxFilterFromID(PageId: Text): Text
    begin
        // Checks the Page ID of the calling page and supplies an English filter term for the Report Selection
        case PageId of
            'Page 22':
                exit(CustomerTxt);
            'Page 27':
                exit(VendorTxt);
            'Page 31':
                exit(ItemTxt);
            'Page 9305':
                exit(SalesTxt);
            'Page 9308':
                exit(InvoicesTxt);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetData(var ExceptionMessage: Text; var ExceptionDetails: Text; Url: Text) ResponseText: Text
    var
        HttpStatusCode: Integer;
    begin
        ResponseText := GetDataCatchErrors(ExceptionMessage, ExceptionDetails, HttpStatusCode, Url);

        if ExceptionMessage <> '' then begin
            SendTraceTag('0000BJL', PowerBiTelemetryCategoryLbl, Verbosity::Warning,
                StrSubstNo(ErrorWebResponseTelemetryMsg, HttpStatusCode, ExceptionMessage, ExceptionDetails), DataClassification::CustomerContent);

            case true of
                HttpStatusCode = 401:
                    Error(UnauthorizedErr);
                HttpStatusCode = 404:
                    Error(DataNotFoundErr);
                else
                    Error(GenericErr);
            end;
        end;
    end;

    [Scope('OnPrem')]
    local procedure GetDataCatchErrors(var ExceptionMessage: Text; var ExceptionDetails: Text; var HttpStatusCode: Integer; Url: Text): Text
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        WebRequestHelper: Codeunit "Web Request Helper";
        HttpWebResponse: DotNet HttpWebResponse;
        WebException: DotNet WebException;
        Exception: DotNet Exception;
        ResponseText: Text;
    begin
        Clear(HttpStatusCode);
        Clear(ExceptionMessage);
        Clear(ExceptionDetails);

        if not WebRequestHelper.GetResponseTextUsingCharset(
             'GET', Url, AzureAdMgt.GetAccessToken(GetPowerBIResourceUrl, GetPowerBiResourceName, false), ResponseText)
        then begin
            Exception := GetLastErrorObject;
            ExceptionMessage := Exception.Message;
            ExceptionDetails := Exception.ToString;

            DotNetExceptionHandler.Collect;
            if DotNetExceptionHandler.CastToType(WebException, GetDotNetType(WebException)) then begin // If this is true, WebException is not null
                HttpWebResponse := WebException.Response;
                if not IsNull(HttpWebResponse) then
                    HttpStatusCode := HttpWebResponse.StatusCode;
            end;
        end;

        if WebRequestHelper.IsFailureStatusCode(Format(HttpStatusCode)) and (ExceptionMessage = '') then
            ExceptionMessage := GenericErr;

        exit(ResponseText);
    end;

    local procedure ParseReport(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary; JObj: JsonObject; EnglishContext: Text[30])
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
        JToken: JsonToken;
    begin
        TempPowerBIReportBuffer.Init();

        // report GUID identifier
        JObj.SelectToken('id', JToken);
        Evaluate(TempPowerBIReportBuffer.ReportID, JToken.AsValue().AsText());

        // report name
        JObj.SelectToken('name', JToken);
        TempPowerBIReportBuffer.ReportName := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempPowerBIReportBuffer.ReportName));

        // report embedding url; if the url is too long, handle gracefully but issue an error message to telemetry
        JObj.SelectToken('embedUrl', JToken);
        if JToken.IsValue() then
            if StrLen(JToken.AsValue().AsText()) > MaxStrLen(TempPowerBIReportBuffer.ReportEmbedUrl) then
                SendTraceTag('0000BAV', PowerBiTelemetryCategoryLbl, Verbosity::Error,
                    StrSubstNo(UrlTooLongTelemetryMsg, JObj), DataClassification::CustomerContent);
        TempPowerBIReportBuffer.Validate(ReportEmbedUrl,
            CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempPowerBIReportBuffer.ReportEmbedUrl)));

        PowerBIReportConfiguration.Reset();
        if PowerBIReportConfiguration.Get(UserSecurityId, TempPowerBIReportBuffer.ReportID, EnglishContext) then begin
            // report enabled
            TempPowerBIReportBuffer.Enabled := true;

            if PowerBIReportConfiguration.ReportEmbedUrl = '' then
                UpdateEmbedCache := true;
        end;

        TempPowerBIReportBuffer.Insert();
    end;

    local procedure ParseReports(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary; JObj: JsonObject; EnglishContext: Text[30])
    var
        k: Text;
        JToken: JsonToken;
        JArrayElement: JsonToken;
    begin
        foreach k in JObj.Keys() do
            if k = 'value' then begin
                if JObj.Get(k, JToken) and JToken.IsArray() then
                    foreach JArrayElement in JToken.AsArray() do
                        if JArrayElement.IsObject then
                            ParseReport(TempPowerBIReportBuffer, JArrayElement.AsObject(), EnglishContext)
                        else
                            SendTraceTag('0000B70', PowerBiTelemetryCategoryLbl, Verbosity::Warning, ParseReportsWarningTelemetryMsg, DataClassification::SystemMetadata)
                else
                    SendTraceTag('0000B71', PowerBiTelemetryCategoryLbl, Verbosity::Warning, ParseReportsWarningTelemetryMsg, DataClassification::SystemMetadata);
            end;
    end;

    [Scope('OnPrem')]
    procedure GetReportsUrl(): Text
    var
        UrlHelper: Codeunit "Url Helper";
    begin
        exit(UrlHelper.GetPowerBIReportsUrl);
    end;

    [Scope('OnPrem')]
    procedure IsPowerBIDeploymentEnabled(): Boolean
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
    begin
        // First check for application service
        if PowerBIBlob.Get(HackPowerBIGuidTxt) then
            exit(false);

        // Now check for current tenant
        if PowerBIOngoingDeployments.Get(HackPowerBIGuidTxt) then
            exit(false);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetIsDeployingReports(): Boolean
    begin
        exit(IsPowerBIDeploymentEnabled and (IsUserDeployingReports or IsUserRetryingUploads or
                                             IsUserDeletingReports));
    end;

    [Scope('OnPrem')]
    procedure UpdateEmbedUrlCache(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary; EnglishContext: Text)
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
    begin
        if UpdateEmbedCache then begin
            TempPowerBIReportBuffer.Reset();
            if TempPowerBIReportBuffer.Find('-') then
                repeat
                    if TempPowerBIReportBuffer.ReportEmbedUrl <> '' then
                        if PowerBIReportConfiguration.Get(UserSecurityId, TempPowerBIReportBuffer.ReportID, EnglishContext) then begin
                            PowerBIReportConfiguration.Validate(ReportEmbedUrl, TempPowerBIReportBuffer.ReportEmbedUrl);
                            if PowerBIReportConfiguration.Modify then;
                        end;
                until TempPowerBIReportBuffer.Next = 0;

            UpdateEmbedCache := false;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetEnglishContext(): Code[30]
    var
        AllProfile: Record "All Profile";
        CurrentLanguage: Integer;
    begin
        // Returns an English profile ID for the Report Selection
        ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
        exit(AllProfile."Profile ID");
    end;

    local procedure GetBlobIdForDeployment(Context: Text[50]): Guid
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        IntelligentCloud: Record "Intelligent Cloud";
    begin
        PowerBIDefaultSelection.Reset();
        PowerBIDefaultSelection.SetFilter(Context, Context);

        if PowerBIDefaultSelection.IsEmpty then
            exit(NullGuidTxt);

        if PowerBIDefaultSelection.Find('-') then
            repeat
                PowerBIBlob.Reset();
                PowerBIBlob.SetFilter(Id, '%1', PowerBIDefaultSelection.Id);
                PowerBIBlob.SetFilter("GP Enabled", '%1', IntelligentCloud.Get);
                if not PowerBIBlob.IsEmpty then
                    exit(PowerBIDefaultSelection.Id);
            until PowerBIDefaultSelection.Next = 0;

        PowerBIBlob.SetFilter("GP Enabled", '%1', false);
        if PowerBIBlob.FindFirst then
            exit(PowerBIBlob.Id);

        exit(NullGuidTxt);
    end;

    local procedure GetPageId(): Text[50]
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
    begin
        PowerBIUserConfiguration.Reset();
        PowerBIUserConfiguration.SetFilter("User Security ID", UserSecurityId);
        PowerBIUserConfiguration.SetFilter("Profile ID", GetEnglishContext);
        PowerBIUserConfiguration.SetFilter("Selected Report ID", '%1', NullGuidTxt);

        if not PowerBIUserConfiguration.FindFirst then
            exit('');

        exit(PowerBIUserConfiguration."Page ID");
    end;

    [Scope('OnPrem')]
    procedure FormatSpecialChars(Selection: Text): Text
    var
        i: Integer;
    begin
        if Selection = '' then
            exit('');

        for i := 1 to StrLen(Selection) do
            // EX: 1 1/2" (Char at pos 4 and 6) -> 1 1\/2\" (Char now at pos 5 and 7)
            if (Selection[i] in [34]) or (Selection[i] in [47]) or (Selection[i] in [92])
            then begin
                Selection := InsStr(Selection, '\', i);
                i := i + 1;
            end;
        exit(Selection);
    end;

    procedure CheckPowerBITablePermissions(): Boolean
    var
        PowerBIUserLicense: Record "Power BI User License";
        PowerBIBlob: Record "Power BI Blob";
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        AreLicensePermissionsValid: Boolean;
        AreBlobPermissionsValid: Boolean;
        AreSelectionPermissionsValid: Boolean;
        AreUserConfigPermissionsValid: Boolean;
    begin
        AreLicensePermissionsValid := PowerBIUserLicense.WritePermission and PowerBIUserLicense.ReadPermission;
        AreBlobPermissionsValid := PowerBIBlob.ReadPermission;
        AreSelectionPermissionsValid := PowerBIDefaultSelection.ReadPermission;
        AreUserConfigPermissionsValid := PowerBIUserConfiguration.WritePermission and PowerBIUserConfiguration.ReadPermission;

        exit(AreLicensePermissionsValid and AreBlobPermissionsValid and AreSelectionPermissionsValid and AreUserConfigPermissionsValid);
    end;

    local procedure SetEnvironmentForDeployment(): Text
    begin
        EnvNameTxt := EnvironmentInformation.GetEnvironmentName();
    end;

    procedure GetPowerBiTelemetryCategory(): Text
    begin
        exit(PowerBiTelemetryCategoryLbl);
    end;

}
