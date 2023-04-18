codeunit 6301 "Power BI Service Mgt."
{
    // // Manages access to the Power BI service API's (aka powerbi.com)

    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        GenericErr: Label 'An error occurred while trying to get reports from the Power BI service. Please try again or contact your system administrator if the error persists.';
        PowerBiResourceNameTxt: Label 'Power BI Services';
        MainPageRatioTxt: Label '16:9', Locked = true;
        FactboxRatioTxt: Label '4:3', Locked = true;
        UnauthorizedErr: Label 'You do not have a Power BI account. If you have just activated a license, it might take several minutes for the changes to be effective in Power BI.';
        DataNotFoundErr: Label 'The report(s) you are trying to load do not exist.';
        NavAppSourceUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862351', Locked = true;
        Dyn365AppSourceUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862352', Locked = true;
        PowerBIMyOrgUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862353', Locked = true;
        JobQueueCategoryCodeTxt: Label 'PBI EMBED', Locked = true;
        JobQueueCategoryDescriptionTxt: Label 'Synchronize Power BI reports', MaxLength = 30;
        // Telemetry constants
        PowerBiLicenseCheckErrorTelemetryMsg: Label 'Power BI license check finished with status code: %1. Error: %2', Locked = true;
        PowerBiLicenseCheckStatusCodeTelemetryMsg: Label 'Power BI license check returned status code: %1.', Locked = true;
        PowerBiTelemetryCategoryLbl: Label 'AL Power BI Embedded', Locked = true;
        OngoingDeploymentTelemetryMsg: Label 'Setting Power BI Ongoing Deployment record for user. Field: %1; Value: %2.', Locked = true;
        ErrorWebResponseTelemetryMsg: Label 'GetData failed with an error. The status code is: %1.', Locked = true;
#if not CLEAN22
        RetryAfterNotSatisfiedTelemetryMsg: Label 'PowerBI service not ready. Will retry after: %1.', Locked = true;
#endif
        EmptyAccessTokenTelemetryMsg: Label 'Encountered an empty access token.', Locked = true;
        ScheduleSyncTelemetryMsg: Label 'Scheduling sync for UTC datetime: %1.', Locked = true;
#if not CLEAN21
        HackPowerBIGuidTxt: Label '06D251CE-A824-44B2-A5F9-318A0674C3FB', Locked = true;
        DeploymentDisabledTelemetryMsg: Label 'Report deployment is disabled (tenant: %1, app service: %2)', Locked = true;
        GhostReportTelemetryMsg: Label 'Power BI Report Configuration has an entry without URL and with null ID.', Locked = true;
        GetReportsForContextTelemetryMsg: Label 'Empty report URL when loading Power BI reports (but the report ID is not empty).', Locked = true;
        ServiceCallsDisabledTelemetryMsg: Label 'Service calls are disabled for the tenant.', Locked = true;
#endif

#if not CLEAN21
    [Obsolete('Use physical table PowerBIReportConfiguration instead of temporary table TempPowerBIReportBuffer.', '21.0')]
    [Scope('OnPrem')]
    procedure GetReportsForUserContext(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary; EnglishContext: Text[30])
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
    begin
        // Populates a buffer of reports to show to the user for the current context.
        // Some rows of "Power BI Report Configuration" might be old and not contain a cached ReportEmbedUrl, in which
        // case we can craft it using the report ID (if not null). If even the report ID is null, we have no way to recover
        // the report that was selected (should never happen, but...)
        if not TempPowerBIReportBuffer.IsEmpty() then
            exit;

        PowerBIReportConfiguration.Reset();
        PowerBIReportConfiguration.SetFilter("User Security ID", UserSecurityId());
        PowerBIReportConfiguration.SetFilter(Context, EnglishContext);

        if PowerBIReportConfiguration.FindSet() then
            repeat
                if PowerBIReportConfiguration.ReportEmbedUrl <> '' then begin
                    TempPowerBIReportBuffer.ReportID := PowerBIReportConfiguration."Report ID";
                    TempPowerBIReportBuffer.Validate(ReportEmbedUrl, PowerBIReportConfiguration.ReportEmbedUrl);
                    TempPowerBIReportBuffer."Workspace Name" := PowerBIReportConfiguration."Workspace Name";
                    TempPowerBIReportBuffer."Workspace ID" := PowerBIReportConfiguration."Workspace ID";
                    TempPowerBIReportBuffer.Enabled := true;
                    if TempPowerBIReportBuffer.Insert() then;
                end else
                    if not IsNullGuid(PowerBIReportConfiguration."Report ID") then
                        Session.LogMessage('0000B6Z', GetReportsForContextTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl)
                    else
                        Session.LogMessage('0000EDL', GhostReportTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
            until PowerBIReportConfiguration.Next() = 0;
    end;
#endif

    [Scope('OnPrem')]
    procedure CheckForPowerBILicenseInForeground(): Boolean
    var
        DummyResponseText: Text;
        ExceptionMessage: Text;
        ExceptionDetails: Text;
        ErrorStatusCode: Integer;
    begin
        DummyResponseText := GetDataCatchErrors(ExceptionMessage, ExceptionDetails, ErrorStatusCode, GetReportsUrl());

        if ExceptionMessage <> '' then
            Session.LogMessage('0000B6Y', StrSubstNo(PowerBiLicenseCheckErrorTelemetryMsg, ErrorStatusCode, GetLastErrorText(true)), Verbosity::Warning, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);

        Session.LogMessage('0000C0H', StrSubstNo(PowerBiLicenseCheckStatusCodeTelemetryMsg, ErrorStatusCode), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);

        // REMARK: 404 means the Power BI user workspace has not been provisioned yet. It could be that the user just activated a license and we can actually
        // start autodeployment already, or that the user does not have a license at all and autodeployment would fail. We do not have a way to distinguish
        // these cases. So, we take the conservative approach and consider it a missing license scenario (if the license has just been assigned, it usually takes
        // 10-15 minutes to propagate and provision, so not too bad; the user can force this by uploading a report from the Power BI home page).
        if (ErrorStatusCode = 0) and (ExceptionMessage = '') then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure IsReportEnabled(ReportId: Guid; EnglishContext: Text): Boolean
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
    begin
        exit(PowerBIReportConfiguration.Get(UserSecurityId(), ReportId, EnglishContext));
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure IsUserReadyForPowerBI(): Boolean
    begin
        if not AzureAdMgt.IsAzureADAppSetupDone() then
            exit(false);

        exit(AzureAdMgt.GetAccessToken(GetPowerBIResourceUrl(), GetPowerBiResourceName(), false) <> '');
    end;

    procedure GetPowerBIResourceUrl(): Text
    var
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
    begin
        exit(PowerBIUrlMgt.GetPowerBIResourceUrl());
    end;

    procedure GetPowerBiResourceName(): Text
    begin
        exit(PowerBiResourceNameTxt);
    end;

    procedure GetGenericError(): Text
    begin
        exit(GenericErr);
    end;

#if not CLEAN20
    [Obsolete('Use GetFactboxRatio or GetMainPageRatio instead.', '20.0')]
    procedure GetReportPageSize(): Text
    begin
        exit('16:9');
    end;
#endif

    procedure GetFactboxRatio(): Text
    begin
        exit(FactboxRatioTxt);
    end;

    procedure GetMainPageRatio(): Text
    begin
        exit(MainPageRatioTxt);
    end;

    procedure GetUnauthorizedErrorText(): Text
    begin
        exit(UnauthorizedErr);
    end;

    procedure GetContentPacksServicesUrl(): Text
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        // Gets the URL for AppSource's list of content packs, like Power BI's Services button, filtered to Dynamics reports.
        if EnvironmentInfo.IsSaaS() then
            exit(Dyn365AppSourceUrlTxt);

        exit(NavAppSourceUrlTxt);
    end;

    procedure GetContentPacksMyOrganizationUrl(): Text
    begin
        // Gets the URL for Power BI's embedded AppSource page listing reports shared by the user's organization.
        exit(PowerBIMyOrgUrlTxt);
    end;

#if not CLEAN22
    [Scope('OnPrem')]
    procedure SynchronizeReportsInBackground()
    var
        JobQueueEntry: Record "Job Queue Entry";
        PowerBIServiceStatusSetup: Record "Power BI Service Status Setup";
        ScheduledDateTime: DateTime;
    begin
        if PowerBIServiceStatusSetup.FindFirst() and (PowerBIServiceStatusSetup."Retry After" > CurrentDateTime()) then
            ScheduledDateTime := PowerBIServiceStatusSetup."Retry After"
        else
            ScheduledDateTime := CurrentDateTime();

        Session.LogMessage('0000FB2', StrSubstNo(ScheduleSyncTelemetryMsg, Format(ScheduledDateTime, 50, 9)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
        JobQueueEntry.ScheduleJobQueueEntryForLater(Codeunit::"Power BI Report Synchronizer", ScheduledDateTime, GetJobQueueCategoryCode(), '')
    end;
#else
    [Scope('OnPrem')]
    procedure SynchronizeReportsInBackground()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduledDateTime: DateTime;
    begin
        ScheduledDateTime := CurrentDateTime();

        Session.LogMessage('0000FB2', StrSubstNo(ScheduleSyncTelemetryMsg, Format(ScheduledDateTime, 50, 9)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
        JobQueueEntry.ScheduleJobQueueEntryForLater(Codeunit::"Power BI Report Synchronizer", ScheduledDateTime, GetJobQueueCategoryCode(), '')
    end;
#endif

    [Scope('OnPrem')]
    procedure IsUserSynchronizingReports(): Boolean
    var
        PowerBIUserStatus: Record "Power BI User Status";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if PowerBIUserStatus.Get(UserSecurityId()) then
            if PowerBIUserStatus."Is Synchronizing" then
                exit(true);

        JobQueueEntry.SetRange("User ID", UserId());
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Power BI Report Synchronizer");
        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::Ready, JobQueueEntry.Status::"In Process");

        if not JobQueueEntry.IsEmpty() then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure SetIsSynchronizing(IsSynchronizing: Boolean)
    var
        PowerBIUserStatus: Record "Power BI User Status";
    begin
        SendPowerBiOngoingDeploymentsTelemetry(PowerBIUserStatus.FieldCaption("Is Synchronizing"), IsSynchronizing);
        PowerBIUserStatus.LockTable();

        if PowerBIUserStatus.Get(UserSecurityId()) then begin
            PowerBIUserStatus."Is Synchronizing" := IsSynchronizing;
            PowerBIUserStatus.Modify();
        end else begin
            PowerBIUserStatus.Init();
            PowerBIUserStatus."User Security ID" := UserSecurityId();
            PowerBIUserStatus."Is Synchronizing" := IsSynchronizing;
            PowerBIUserStatus.Insert();
        end;
    end;

    local procedure SendPowerBiOngoingDeploymentsTelemetry(FieldChanged: Text; NewValue: Boolean)
    begin
        Session.LogMessage('0000AYR', StrSubstNo(OngoingDeploymentTelemetryMsg, FieldChanged, NewValue), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
    end;

#if not CLEAN22
    [Scope('OnPrem')]
    [Obsolete('Power BI service status is no longer cached.', '22.0')]
    procedure IsPBIServiceAvailable(): Boolean
    var
        PowerBIServiceStatusSetup: Record "Power BI Service Status Setup";
    begin
        // Checks whether the Power BI service is available for deploying default reports, based on
        // whether previous deployments have failed with a retry date/time that we haven't reached yet.
        PowerBIServiceStatusSetup.Reset();
        if PowerBIServiceStatusSetup.FindFirst() then
            if PowerBIServiceStatusSetup."Retry After" > CurrentDateTime then begin
                Session.LogMessage('0000B64', StrSubstNo(RetryAfterNotSatisfiedTelemetryMsg, PowerBIServiceStatusSetup."Retry After"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
                exit(false);
            end;

        exit(true);
    end;
#endif

#if not CLEAN21
    [Obsolete('Disabling the integration through AzureADMgtSetup has been discontinued. Remove permissions from single users instead.', '21.0')]
    procedure CanHandleServiceCalls() CanHandle: Boolean
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
    begin
        // Checks if the current codeunit is allowed to handle Power BI service requests rather than a mock.
        CanHandle := false;
        if AzureADMgtSetup.Get() then
            CanHandle := (AzureADMgtSetup."PBI Service Mgt. Codeunit ID" = CODEUNIT::"Power BI Service Mgt.");

        if not CanHandle then
            Session.LogMessage('0000EDM', ServiceCallsDisabledTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
    end;

    [Scope('OnPrem')]
    [Obsolete('Global switch for Power BI report deployment is no longer supported.', '21.0')]
    procedure IsPowerBIDeploymentEnabled(): Boolean
    var
        PowerBIBlob: Record "Power BI Blob";
        DisabledForAppService: Boolean;
    begin
        DisabledForAppService := PowerBIBlob.Get(HackPowerBIGuidTxt);

        if not DisabledForAppService then
            exit(true);

        Session.LogMessage('0000DZ0', StrSubstNo(DeploymentDisabledTelemetryMsg, false, DisabledForAppService), Verbosity::Normal,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetPowerBiTelemetryCategory());
        exit(false);
    end;

    [Scope('OnPrem')]
    [IntegrationEvent(false, false)]
    [Obsolete('Events to override the Power BI integration behavior are no longer supported.', '21.0')]
    procedure OnGetReports(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary; var ExceptionMessage: Text; var ExceptionDetails: Text; EnglishContext: Text[30])
    begin
    end;

    [Scope('OnPrem')]
    [IntegrationEvent(false, false)]
    [Obsolete('Events to override the Power BI integration behavior are no longer supported.', '21.0')]
    procedure OnUploadReports(var ApiRequestList: DotNet ImportReportRequestList; var ApiResponseList: DotNet ImportReportResponseList)
    begin
    end;

    [Scope('OnPrem')]
    [IntegrationEvent(false, false)]
    [Obsolete('Events to override the Power BI integration behavior are no longer supported.', '21.0')]
    procedure OnRetryUploads(var ImportIdList: DotNet ImportedReportRequestList; var ApiResponseList: DotNet ImportedReportResponseList)
    begin
    end;
#endif

    [Scope('OnPrem')]
    procedure HasUploads(): Boolean
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
        exit(not PowerBIReportUploads.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure GetData(var ExceptionMessage: Text; var ExceptionDetails: Text; Url: Text) ResponseText: Text
    var
        HttpStatusCode: Integer;
    begin
        ResponseText := GetDataCatchErrors(ExceptionMessage, ExceptionDetails, HttpStatusCode, Url);

        if ExceptionMessage <> '' then begin
            Session.LogMessage('0000BJL', StrSubstNo(ErrorWebResponseTelemetryMsg, HttpStatusCode), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);

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
    [NonDebuggable]
    procedure GetDataCatchErrors(var ExceptionMessage: Text; var ExceptionDetails: Text; var ErrorStatusCode: Integer; Url: Text): Text
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        WebRequestHelper: Codeunit "Web Request Helper";
        HttpWebResponse: DotNet HttpWebResponse;
        WebException: DotNet WebException;
        Exception: DotNet Exception;
        ResponseText: Text;
        AccessToken: Text;
    begin
        Clear(ErrorStatusCode);
        Clear(ExceptionMessage);
        Clear(ExceptionDetails);

        AccessToken := AzureAdMgt.GetAccessToken(GetPowerBIResourceUrl(), GetPowerBiResourceName(), false);

        if AccessToken = '' then begin
            Session.LogMessage('0000FT6', EmptyAccessTokenTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
            ExceptionMessage := UnauthorizedErr;
            ExceptionDetails := UnauthorizedErr;
            ErrorStatusCode := 401;
            exit('');
        end;

        if not WebRequestHelper.GetResponseTextUsingCharset('GET', Url, AccessToken, ResponseText) then begin
            Exception := GetLastErrorObject();
            ExceptionMessage := Exception.Message;
            ExceptionDetails := Exception.ToString();

            DotNetExceptionHandler.Collect();
            if DotNetExceptionHandler.CastToType(WebException, GetDotNetType(WebException)) then begin // If this is true, WebException is not null
                HttpWebResponse := WebException.Response;
                if not IsNull(HttpWebResponse) then
                    ErrorStatusCode := HttpWebResponse.StatusCode;
            end;
        end;

        if WebRequestHelper.IsFailureStatusCode(Format(ErrorStatusCode)) and (ExceptionMessage = '') then
            ExceptionMessage := GenericErr;

        exit(ResponseText);
    end;

    [Scope('OnPrem')]
    procedure GetReportsUrl(): Text
    var
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
    begin
        exit(PowerBIUrlMgt.GetPowerBIReportsUrl());
    end;

    [Scope('OnPrem')]
    procedure GetEnglishContext(): Code[30]
    var
        AllProfile: Record "All Profile";
    begin
        // Returns an English profile ID for the Report Selection
        ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
        exit(AllProfile."Profile ID");
    end;

    procedure IsUserAdminForPowerBI(UserSecurityId: Guid): Boolean
    var
        UserPermissions: Codeunit "User Permissions";
    begin
        exit(UserPermissions.IsSuper(UserSecurityId));
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
        PowerBIBlob: Record "Power BI Blob";
#if not CLEAN21
        PowerBIUserLicense: Record "Power BI User License";
#endif
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        AreBlobPermissionsValid: Boolean;
        AreSelectionPermissionsValid: Boolean;
        AreUserConfigPermissionsValid: Boolean;
    begin
#if not CLEAN21
        if not (PowerBIUserLicense.WritePermission and PowerBIUserLicense.ReadPermission) then
            exit(false);
#endif
        AreBlobPermissionsValid := PowerBIBlob.ReadPermission;
        AreSelectionPermissionsValid := PowerBIDefaultSelection.ReadPermission;
        AreUserConfigPermissionsValid := PowerBIUserConfiguration.WritePermission and PowerBIUserConfiguration.ReadPermission;

        exit(AreBlobPermissionsValid and AreSelectionPermissionsValid and AreUserConfigPermissionsValid);
    end;

    procedure GetPowerBiTelemetryCategory(): Text
    begin
        exit(PowerBiTelemetryCategoryLbl);
    end;

    [Scope('OnPrem')]
    procedure GetJobQueueCategoryCode(): Code[10]
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        JobQueueCategory.InsertRec(
            CopyStr(JobQueueCategoryCodeTxt, 1, MaxStrLen(JobQueueCategory.Code)),
            CopyStr(JobQueueCategoryDescriptionTxt, 1, MaxStrLen(JobQueueCategory.Description)));

        exit(JobQueueCategory.Code);
    end;
}