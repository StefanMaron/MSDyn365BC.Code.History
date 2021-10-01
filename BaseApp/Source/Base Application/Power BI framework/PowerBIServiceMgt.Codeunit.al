codeunit 6301 "Power BI Service Mgt."
{
    // // Manages access to the Power BI service API's (aka powerbi.com)

    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        PowerBISessionManager: Codeunit "Power BI Session Manager";
#if not CLEAN19
        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
#endif
        GenericErr: Label 'An error occurred while trying to get reports from the Power BI service. Please try again or contact your system administrator if the error persists.';
        PowerBiResourceNameTxt: Label 'Power BI Services';
        ReportPageSizeTxt: Label '16:9', Locked = true;
        UnauthorizedErr: Label 'You do not have a Power BI account. If you have just activated a license, it might take several minutes for the changes to be effective in Power BI.';
        DataNotFoundErr: Label 'The report(s) you are trying to load do not exist.';
        NavAppSourceUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862351', Locked = true;
        Dyn365AppSourceUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862352', Locked = true;
        PowerBIMyOrgUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862353', Locked = true;
#if not CLEAN19
        ItemTxt: Label 'Items', Locked = true;
        VendorTxt: Label 'Vendors', Locked = true;
        CustomerTxt: Label 'Customers', Locked = true;
        SalesTxt: Label 'Sales Orders', Locked = true;
        InvoicesTxt: Label 'Purchase Invoices', Locked = true;
#endif
        HackPowerBIGuidTxt: Label '06D251CE-A824-44B2-A5F9-318A0674C3FB', Locked = true;
        JobQueueCategoryCodeTxt: Label 'PBI EMBED', Locked = true;
        JobQueueCategoryDescriptionTxt: Label 'Synchronize Power BI reports', Comment = 'At most 30 characters long';
        // Telemetry constants
        PowerBiTelemetryCategoryLbl: Label 'PowerBI', Locked = true;
        GetReportsForContextTelemetryMsg: Label 'Empty report URL when loading Power BI reports. Context: %1, ReportId: %2.', Locked = true;
        GhostReportTelemetryMsg: Label 'Power BI Report Configuration has an entry without URL and with null ID.', Locked = true;
        OngoingDeploymentTelemetryMsg: Label 'Setting Power BI Ongoing Deployment record for user. Field: %1; Value: %2.', Locked = true;
        ErrorWebResponseTelemetryMsg: Label 'Getting data failed with status code: %1. Exception Message: %2. Exception Details: %3.', Locked = true;
        RetryAfterNotSatisfiedTelemetryMsg: Label 'PowerBI service not ready. Will retry after: %1.', Locked = true;
#if not CLEAN19
        ParseReportsWarningTelemetryMsg: Label 'Parse reports encountered an unexpected token.', Locked = true;
        UrlTooLongTelemetryMsg: Label 'Parsing reports encountered a URL that is too long to be saved to ReportEmbedUrl. Json message: %1.', Locked = true;
#endif
        DeploymentDisabledTelemetryMsg: Label 'Report deployment is disabled (tenant: %1, app service: %2)', Locked = true;
        ServiceCallsDisabledTelemetryMsg: Label 'Service calls are disabled for the tenant.', Locked = true;
        ScheduleSyncTelemetryMsg: Label 'Scheduling sync for datetime: %1.', Locked = true;

#if not CLEAN19
    [Scope('OnPrem')]
    [Obsolete('Use GetReportsAndWorkspaces in codeunit "Power BI Workspace Mgt." instead.', '19.0')]
    procedure GetReports(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary; var ExceptionMessage: Text; var ExceptionDetails: Text; EnglishContext: Text[30])
    var
        JObj: JsonObject;
        Url: Text;
        ResponseText: Text;
    begin
        // Gets a list of reports from the user's Power BI account and loads them into the given buffer.
        // Reports are marked as Enabled if they've previously been selected for the given context (page ID).
        if not TempPowerBIReportBuffer.IsEmpty() then
            exit;

        if not CanHandleServiceCalls() then begin
            OnGetReports(TempPowerBIReportBuffer, ExceptionMessage, ExceptionDetails, EnglishContext);
            exit;
        end;

        Url := GetReportsUrl();

        ResponseText := GetData(ExceptionMessage, ExceptionDetails, Url);

        JObj.ReadFrom(ResponseText); // TODO: check versions

        ParseReports(TempPowerBIReportBuffer, JObj, EnglishContext);
    end;

    [Obsolete('Use the GetReportsForUserContext without the ExceptionMessage and ExceptionDetails parameters.', '19.0')]
    [Scope('OnPrem')]
    procedure GetReportsForUserContext(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary; var ExceptionMessage: Text; var ExceptionDetails: Text; EnglishContext: Text[30])
    begin
        GetReportsForUserContext(TempPowerBIReportBuffer, EnglishContext);

        Clear(ExceptionDetails);
        Clear(ExceptionMessage);
    end;
#endif

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
                        Session.LogMessage('0000B6Z', StrSubstNo(GetReportsForContextTelemetryMsg, EnglishContext, Format(PowerBIReportConfiguration."Report ID")), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl)
                    else
                        Session.LogMessage('0000EDL', GhostReportTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
            until PowerBIReportConfiguration.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckForPowerBILicenseInForeground(): Boolean
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
        // Checks whether the user has power bi license/account or not
        if PowerBISessionManager.GetHasPowerBILicense() then
            exit(true);

        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetFilter("User ID", UserSecurityId());

        // Record in this table indicates the power bi service is already called on behalf of this user.
        if not PowerBIReportUploads.IsEmpty() then begin
            PowerBISessionManager.SetHasPowerBILicense(true);
            exit(true);
        end;

        Codeunit.Run(Codeunit::"PBI Check License Task"); // Saves value in table

        exit(PowerBISessionManager.GetHasPowerBILicense());
    end;

    [Scope('OnPrem')]
    procedure IsReportEnabled(ReportId: Guid; EnglishContext: Text): Boolean
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
    begin
        exit(PowerBIReportConfiguration.Get(UserSecurityId(), ReportId, EnglishContext));
    end;

    [Scope('OnPrem')]
    procedure IsUserReadyForPowerBI(): Boolean
    begin
        if not AzureAdMgt.IsAzureADAppSetupDone then
            exit(false);

        exit(AzureAdMgt.GetAccessToken(GetPowerBIResourceUrl(), GetPowerBiResourceName(), false) <> '');
    end;

    procedure GetPowerBIResourceUrl(): Text
    var
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
    begin
        exit(PowerBIUrlMgt.GetPowerBIResourceUrl);
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

#if not CLEAN19
    [Obsolete('Use the function GetLicenseUrl of codeunit 6324 "Power BI Url Mgt" instead.', '19.0')]
    procedure GetPowerBIUrl(): Text
    var
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
    begin
        exit(PowerBIUrlMgt.GetLicenseUrl());
    end;
#endif

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

    [Scope('OnPrem')]
    procedure SynchronizeReportsInBackground()
    var
        JobQueueEntry: Record "Job Queue Entry";
        PowerBIServiceStatusSetup: Record "Power BI Service Status Setup";
        ScheduledDateTime: DateTime;
    begin
        // Schedules a background task to do default report deletion
        if not CanHandleServiceCalls() then begin
            Codeunit.Run(Codeunit::"Power BI Report Synchronizer"); // Run in foreground instead
            exit;
        end;

        if PowerBIServiceStatusSetup.FindFirst() and (PowerBIServiceStatusSetup."Retry After" > CurrentDateTime()) then
            ScheduledDateTime := PowerBIServiceStatusSetup."Retry After"
        else
            ScheduledDateTime := CurrentDateTime();

        Session.LogMessage('0000FB2', StrSubstNo(ScheduleSyncTelemetryMsg, ScheduledDateTime), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
        JobQueueEntry.ScheduleJobQueueEntryForLater(Codeunit::"Power BI Report Synchronizer", ScheduledDateTime, GetJobQueueCategoryCode(), '')
    end;

    [Scope('OnPrem')]
    procedure IsUserSynchronizingReports(): Boolean
    var
#if not CLEAN18
        PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
#endif
        PowerBIUserStatus: Record "Power BI User Status";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if PowerBIUserStatus.Get(UserSecurityId()) then
            if PowerBIUserStatus."Is Synchronizing" then
                exit(true);

#if not CLEAN18
        if PowerBIOngoingDeployments.Get(UserSecurityId()) then
            if PowerBIOngoingDeployments."Is Deploying Reports" or PowerBIOngoingDeployments."Is Deleting Reports" or PowerBIOngoingDeployments."Is Retrying Uploads" then
                exit(true);
#endif

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

    [Scope('OnPrem')]
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


    procedure CanHandleServiceCalls() CanHandle: Boolean
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
    begin
        // Checks if the current codeunit is allowed to handle Power BI service requests rather than a mock.
        CanHandle := false;
        if AzureADMgtSetup.Get then
            CanHandle := (AzureADMgtSetup."PBI Service Mgt. Codeunit ID" = CODEUNIT::"Power BI Service Mgt.");

        if not CanHandle then
            Session.LogMessage('0000EDM', ServiceCallsDisabledTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
    end;

    [Scope('OnPrem')]
    [IntegrationEvent(false, false)]
    procedure OnGetReports(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary; var ExceptionMessage: Text; var ExceptionDetails: Text; EnglishContext: Text[30])
    begin
    end;

    [Scope('OnPrem')]
    [IntegrationEvent(false, false)]
    procedure OnUploadReports(var ApiRequestList: DotNet ImportReportRequestList; var ApiResponseList: DotNet ImportReportResponseList)
    begin
    end;

    [Scope('OnPrem')]
    [IntegrationEvent(false, false)]
    procedure OnRetryUploads(var ImportIdList: DotNet ImportedReportRequestList; var ApiResponseList: DotNet ImportedReportResponseList)
    begin
    end;

    [Scope('OnPrem')]
    procedure HasUploads(): Boolean
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
        exit(not PowerBIReportUploads.IsEmpty);
    end;

#if not CLEAN19
    [Obsolete('Hardcoded name filtering for reports is deprecated. The user can search reports with the builtin search function in the page.', '19.0')]
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
#endif

    [Scope('OnPrem')]
    procedure GetData(var ExceptionMessage: Text; var ExceptionDetails: Text; Url: Text) ResponseText: Text
    var
        HttpStatusCode: Integer;
    begin
        ResponseText := GetDataCatchErrors(ExceptionMessage, ExceptionDetails, HttpStatusCode, Url);

        if ExceptionMessage <> '' then begin
            Session.LogMessage('0000BJL', StrSubstNo(ErrorWebResponseTelemetryMsg, HttpStatusCode, ExceptionMessage, ExceptionDetails), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);

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
    procedure GetDataCatchErrors(var ExceptionMessage: Text; var ExceptionDetails: Text; var ErrorStatusCode: Integer; Url: Text): Text
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        WebRequestHelper: Codeunit "Web Request Helper";
        HttpWebResponse: DotNet HttpWebResponse;
        WebException: DotNet WebException;
        Exception: DotNet Exception;
        ResponseText: Text;
    begin
        Clear(ErrorStatusCode);
        Clear(ExceptionMessage);
        Clear(ExceptionDetails);

        if not WebRequestHelper.GetResponseTextUsingCharset(
             'GET', Url, AzureAdMgt.GetAccessToken(GetPowerBIResourceUrl(), GetPowerBiResourceName(), false), ResponseText)
        then begin
            Exception := GetLastErrorObject();
            ExceptionMessage := Exception.Message;
            ExceptionDetails := Exception.ToString();

            DotNetExceptionHandler.Collect;
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

#if not CLEAN19
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
                Session.LogMessage('0000BAV', StrSubstNo(UrlTooLongTelemetryMsg, JObj), Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
        TempPowerBIReportBuffer.Validate(ReportEmbedUrl,
            CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempPowerBIReportBuffer.ReportEmbedUrl)));

        PowerBIReportConfiguration.Reset();
        if PowerBIReportConfiguration.Get(UserSecurityId(), TempPowerBIReportBuffer.ReportID, EnglishContext) then
            // report enabled
            TempPowerBIReportBuffer.Enabled := true;

        TempPowerBIReportBuffer."Workspace Name" := PowerBIWorkspaceMgt.GetMyWorkspaceLabel();

        TempPowerBIReportBuffer.Insert()
    end;

    local procedure ParseReports(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary; JObj: JsonObject; EnglishContext: Text[30])
    var
        JToken: JsonToken;
        JArrayElement: JsonToken;
    begin
        if JObj.Get('value', JToken) and JToken.IsArray() then begin
            foreach JArrayElement in JToken.AsArray() do
                if JArrayElement.IsObject then
                    ParseReport(TempPowerBIReportBuffer, JArrayElement.AsObject(), EnglishContext)
                else
                    Session.LogMessage('0000B70', ParseReportsWarningTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
            exit;
        end;

        Session.LogMessage('0000B71', ParseReportsWarningTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
    end;
#endif

    [Scope('OnPrem')]
    procedure GetReportsUrl(): Text
    var
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
    begin
        exit(PowerBIUrlMgt.GetPowerBIReportsUrl);
    end;

#if not CLEAN18
    [Scope('OnPrem')]
    procedure IsPowerBIDeploymentEnabled(): Boolean
    var
        PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
        PowerBIBlob: Record "Power BI Blob";
        DisabledForAppService: Boolean;
        DisabledForTenant: Boolean;
    begin
        // First check for application service
        DisabledForAppService := PowerBIBlob.Get(HackPowerBIGuidTxt);
        DisabledForTenant := PowerBIOngoingDeployments.Get(HackPowerBIGuidTxt);

        if not DisabledForAppService and not DisabledForTenant then
            exit(true);

        Session.LogMessage('0000DZ0', StrSubstNo(DeploymentDisabledTelemetryMsg, DisabledForTenant, DisabledForAppService), Verbosity::Normal,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetPowerBiTelemetryCategory());
        exit(false);
    end;
#else
    [Scope('OnPrem')]
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
#endif

#if not CLEAN19
    [Obsolete('This function was used to update old records just-in-time, and is no longer needed.', '19.0')]
    [Scope('OnPrem')]
    procedure UpdateEmbedUrlCache(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary; EnglishContext: Text)
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
    begin
        TempPowerBIReportBuffer.Reset();
        if TempPowerBIReportBuffer.Find('-') then
            repeat
                if TempPowerBIReportBuffer.ReportEmbedUrl <> '' then
                    if PowerBIReportConfiguration.Get(UserSecurityId(), TempPowerBIReportBuffer.ReportID, EnglishContext) then begin
                        PowerBIReportConfiguration.Validate(ReportEmbedUrl, TempPowerBIReportBuffer.ReportEmbedUrl);
                        if PowerBIReportConfiguration.Modify() then;
                    end;
            until TempPowerBIReportBuffer.Next() = 0;
    end;
#endif

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
        PowerBIUserLicense: Record "Power BI User License";
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        AreBlobPermissionsValid: Boolean;
        AreLicensePermissionsValid: Boolean;
        AreSelectionPermissionsValid: Boolean;
        AreUserConfigPermissionsValid: Boolean;
    begin
        AreLicensePermissionsValid := PowerBIUserLicense.WritePermission and PowerBIUserLicense.ReadPermission;
        AreBlobPermissionsValid := PowerBIBlob.ReadPermission;
        AreSelectionPermissionsValid := PowerBIDefaultSelection.ReadPermission;
        AreUserConfigPermissionsValid := PowerBIUserConfiguration.WritePermission and PowerBIUserConfiguration.ReadPermission;

        exit(AreLicensePermissionsValid and AreBlobPermissionsValid and AreSelectionPermissionsValid and AreUserConfigPermissionsValid);
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

#if not CLEAN18
    [Obsolete('User IsUserSynchronizingReports instead', '18.0')]
    [Scope('OnPrem')]
    procedure GetIsDeployingReports(): Boolean
    begin
        exit(IsPowerBIDeploymentEnabled() and (IsUserDeployingReports() or IsUserRetryingUploads() or
                                             IsUserDeletingReports() or IsUserSynchronizingReports()));
    end;

    [Obsolete('License check is no longer performed as a background task. Use CheckForPowerBILicenseInForeground instead.', '18.0')]
    [Scope('OnPrem')]
    procedure CheckForPowerBILicense(): Boolean
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
        // Checks whether the user has power bi license/account or not
        if PowerBISessionManager.GetHasPowerBILicense() then
            exit(true);

        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetFilter("User ID", UserSecurityId());

        // Record in this table indicates the power bi service is already called on behalf of this user.
        if not PowerBIReportUploads.IsEmpty() then begin
            PowerBISessionManager.SetHasPowerBILicense(true);
            exit(true);
        end;

        TaskScheduler.CreateTask(Codeunit::"PBI Check License Task", 0, true);

        exit(false);
    end;

    [Obsolete('Use SynchronizeReportsInBackground instead', '18.0')]
    [Scope('OnPrem')]
    procedure UploadDefaultReportInBackground()
    begin
        if not CanHandleServiceCalls() then begin
            Codeunit.Run(Codeunit::"PBI Start Uploads Task");
            exit;
        end;
        // Schedules a background task to do default report deployment (codeunit 6311 which calls back into
        // the UploadAllDefaultReports method in this codeunit).
        SetIsDeployingReports(true);
        TaskScheduler.CreateTask(Codeunit::"PBI Start Uploads Task", Codeunit::"PBI Deployment Failure", true);
    end;

    [Obsolete('Run codeunit "Power BI Report Synchronizer" instead', '18.0')]
    [Scope('OnPrem')]
    procedure UploadDefaultReport()
    begin
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");
        SetIsSynchronizing(false);
    end;

    [Obsolete('Use SynchronizeReportsInBackground instead', '18.0')]
    [Scope('OnPrem')]
    procedure RetryUnfinishedReportsInBackground()
    begin
        if not CanHandleServiceCalls() then begin
            Codeunit.Run(Codeunit::"PBI Retry Uploads Task");
            exit;
        end;
        // Schedules a background task to do completion of partial uploads (codeunit 6312 which calls
        // back into the RetryAllPartialReportUploads method in this codeunit).
        SetIsRetryingUploads(true);
        TaskScheduler.CreateTask(Codeunit::"PBI Retry Uploads Task", Codeunit::"PBI Retry Failure", true);
    end;

    [Obsolete('Run codeunit "Power BI Report Synchronizer" instead', '18.0')]
    [Scope('OnPrem')]
    procedure RetryAllPartialReportUploads()
    begin
        // Starts a sequence of default report deployments for any reports that only partially finished.
        // Prioritizes the active role center over other reports since the user will probably see those first.
        // Unlike UploadAllDefaultReports, doesn't end early if anything failed - want to avoid getting stuck
        // on a faulty report.
        // Should only be called as part of a background session to reduce perf impact (see RetryUnfinishedReportsInBackground).
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        SetIsRetryingUploads(false);
    end;

    [Obsolete('Use PowerBIReportSynchronizer.SelectDefaultReports instead', '18.0')]
    [Scope('OnPrem')]
    procedure SelectDefaultReports()
    var
        PowerBIReportSynchronizer: Codeunit "Power BI Report Synchronizer";
    begin
        PowerBIReportSynchronizer.SelectDefaultReports();
    end;

    [Obsolete('Use SynchronizeReportsInBackground instead', '18.0')]
    [Scope('OnPrem')]
    procedure DeleteDefaultReportsInBackground()
    begin
        // Schedules a background task to do default report deletion (codeunit 6315 which calls back into
        // the DeleteMarkedDefaultReports method in this codeunit).
        SetIsDeletingReports(true);
        TaskScheduler.CreateTask(Codeunit::"PBI Start Deletions Task", Codeunit::"PBI Deletion Failure", true);
    end;

    [Obsolete('Run codeunit "Power BI Report Synchronizer" instead', '18.0')]
    [Scope('OnPrem')]
    procedure DeleteMarkedDefaultReports()
    begin
        Codeunit.Run(Codeunit::"Power BI Report Synchronizer");

        SetIsDeletingReports(false);
    end;

    [Obsolete('Use PowerBIReportSynchronizer.UserNeedsToSynchronize instead', '18.0')]
    [Scope('OnPrem')]
    procedure UserNeedsToDeployReports(Context: Text[50]): Boolean
    var
        PowerBIReportSynchronizer: Codeunit "Power BI Report Synchronizer";
    begin
        exit(PowerBIReportSynchronizer.UserNeedsToSynchronize(Context));
    end;

    [Obsolete('Use PowerBIReportSynchronizer.UserNeedsToSynchronize instead', '18.0')]
    [Scope('OnPrem')]
    procedure UserNeedsToRetryUploads(): Boolean
    var
        PowerBIReportSynchronizer: Codeunit "Power BI Report Synchronizer";
    begin
        exit(PowerBIReportSynchronizer.UserNeedsToSynchronize(''));
    end;

    [Obsolete('Use PowerBIReportSynchronizer.UserNeedsToSynchronize instead', '18.0')]
    [Scope('OnPrem')]
    procedure UserNeedsToDeleteReports(): Boolean
    var
        PowerBIReportSynchronizer: Codeunit "Power BI Report Synchronizer";
    begin
        exit(PowerBIReportSynchronizer.UserNeedsToSynchronize(''));
    end;

    [Obsolete('Use IsUserSynchronizingReports instead.', '18.0')]
    [Scope('OnPrem')]
    procedure IsUserDeployingReports(): Boolean
    var
        PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
    begin
        // Checks whether any background sessions are running (or waiting to run) for doing PBI default
        // report uploads, based on the values in table 6308.
        PowerBIOngoingDeployments.Reset();
        PowerBIOngoingDeployments.SetFilter("User Security ID", UserSecurityId());
        exit(PowerBIOngoingDeployments.FindFirst() and PowerBIOngoingDeployments."Is Deploying Reports");
    end;

    [Obsolete('Use IsUserSynchronizingReports instead.', '18.0')]
    [Scope('OnPrem')]
    procedure IsUserRetryingUploads(): Boolean
    var
        PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
    begin
        // Checks whether any background sessions are running (or waiting to run) for finishing partial
        // uploads of PBI default reports, based on the values in table 6308.
        PowerBIOngoingDeployments.Reset();
        PowerBIOngoingDeployments.SetFilter("User Security ID", UserSecurityId());
        exit(PowerBIOngoingDeployments.FindFirst() and PowerBIOngoingDeployments."Is Retrying Uploads");
    end;

    [Obsolete('Use IsUserSynchronizingReports instead.', '18.0')]
    [Scope('OnPrem')]
    procedure IsUserDeletingReports(): Boolean
    var
        PowerBIOngoingDeployments: Record "Power BI Ongoing Deployments";
    begin
        // Checks whether any background sessions are running (or waiting to run) for deleting any
        // uploaded PBI default reports, based on the values in table 6308.
        PowerBIOngoingDeployments.Reset();
        PowerBIOngoingDeployments.SetFilter("User Security ID", UserSecurityId());
        exit(PowerBIOngoingDeployments.FindFirst() and PowerBIOngoingDeployments."Is Deleting Reports");
    end;

    [Obsolete('Use SetIsSynchronizing instead.', '18.0')]
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

        if PowerBIOngoingDeployments.Get(UserSecurityId()) then begin
            PowerBIOngoingDeployments."Is Deploying Reports" := IsDeploying;
            PowerBIOngoingDeployments.Modify();
        end else begin
            PowerBIOngoingDeployments.Init();
            PowerBIOngoingDeployments."User Security ID" := UserSecurityId();
            PowerBIOngoingDeployments."Is Deploying Reports" := IsDeploying;
            PowerBIOngoingDeployments.Insert();
        end;
    end;

    [Obsolete('Use SetIsSynchronizing instead.', '18.0')]
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

        if PowerBIOngoingDeployments.Get(UserSecurityId()) then begin
            PowerBIOngoingDeployments."Is Retrying Uploads" := IsRetrying;
            PowerBIOngoingDeployments.Modify();
        end else begin
            PowerBIOngoingDeployments.Init();
            PowerBIOngoingDeployments."User Security ID" := UserSecurityId();
            PowerBIOngoingDeployments."Is Retrying Uploads" := IsRetrying;
            PowerBIOngoingDeployments.Insert();
        end;
    end;

    [Obsolete('Use SetIsSynchronizing instead.', '18.0')]
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

        if PowerBIOngoingDeployments.Get(UserSecurityId()) then begin
            PowerBIOngoingDeployments."Is Deleting Reports" := IsDeleting;
            PowerBIOngoingDeployments.Modify();
        end else begin
            PowerBIOngoingDeployments.Init();
            PowerBIOngoingDeployments."User Security ID" := UserSecurityId();
            PowerBIOngoingDeployments."Is Deleting Reports" := IsDeleting;
            PowerBIOngoingDeployments.Insert();
        end;
    end;
#endif

}