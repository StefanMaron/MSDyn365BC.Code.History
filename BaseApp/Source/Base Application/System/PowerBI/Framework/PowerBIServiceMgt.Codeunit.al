namespace System.Integration.PowerBI;

using System;
using System.Azure.Identity;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Reflection;
using System.Security.User;
using System.Threading;
#if not CLEAN23
using System.Utilities;
#endif

codeunit 6301 "Power BI Service Mgt."
{
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        GenericErr: Label 'An error occurred while trying to get reports from the Power BI service. Please try again or contact your system administrator if the error persists.';
        PowerBiResourceNameTxt: Label 'Power BI Services';
        MainPageRatioTxt: Label '16:9', Locked = true;
        FactboxRatioTxt: Label '4:3', Locked = true;
        FailedAuthErr: Label 'We failed to authenticate with Power BI. Try to sign out and in again. This problem typically happens if you no longer have a license for Power BI or if you just changed your email or password.';
        UnauthorizedErr: Label 'You do not have a Power BI account. If you have just activated a license, it might take several minutes for the changes to be effective in Power BI.';
        PowerBIEmbedReportUrlTemplateTxt: Label 'https://app.powerbi.com/reportEmbed?reportId=%1', Locked = true;
        NavAppSourceUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862351', Locked = true;
        Dyn365AppSourceUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862352', Locked = true;
        PowerBIMyOrgUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862353', Locked = true;
        JobQueueCategoryCodeTxt: Label 'PBI EMBED', Locked = true;
        JobQueueCategoryDescriptionTxt: Label 'Synchronize Power BI reports', MaxLength = 30;
        // Telemetry constants
        PowerBiEmbedFeatureTelemetryTok: Label 'Power BI Embed', Locked = true;
        PowerBiLicenseCheckErrorTelemetryMsg: Label 'Power BI license check finished with error.', Locked = true;
        PowerBiLicenseCheckSuccessTelemetryMsg: Label 'Power BI license check returned success.', Locked = true;
        PowerBiTelemetryCategoryLbl: Label 'AL Power BI Embedded', Locked = true;
#if not CLEAN23
        OngoingDeploymentTelemetryMsg: Label 'Setting Power BI Ongoing Deployment record for user. Field: %1; Value: %2.', Locked = true;
        ErrorWebResponseTelemetryMsg: Label 'GetData failed with an error. The status code is: %1.', Locked = true;
        DataNotFoundErr: Label 'The report(s) you are trying to load do not exist.';
#endif
#if not CLEAN22
        RetryAfterNotSatisfiedTelemetryMsg: Label 'PowerBI service not ready. Will retry after: %1.', Locked = true;
#endif
        EmptyAccessTokenTelemetryMsg: Label 'Encountered an empty access token.', Locked = true;
        ScheduleSyncTelemetryMsg: Label 'Scheduling sync for UTC datetime: %1.', Locked = true;

    [Scope('OnPrem')]
    procedure CheckForPowerBILicenseInForeground(): Boolean
    var
        PowerBIServiceProvider: Interface "Power BI Service Provider";
        OperationResult: DotNet OperationResult;
    begin
        CreateServiceProvider(PowerBIServiceProvider);

        PowerBIServiceProvider.CheckUserLicense(OperationResult);

        if OperationResult.Successful then
            Session.LogMessage('0000C0H', PowerBiLicenseCheckSuccessTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl)
        else
            Session.LogMessage('0000B6Y', PowerBiLicenseCheckErrorTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);

        exit(OperationResult.Successful);
    end;

#if not CLEAN23
    [Scope('OnPrem')]
    [Obsolete('A report is enabled for a context if there is a mathcing entry in table "Power BI Report Configuration". Substitute calls to IsReportEnabled(ReportId, Context) with PowerBIReportConfiguration.Get(UserSecurityId(), ReportId, Context).', '23.0')]
    procedure IsReportEnabled(ReportId: Guid; EnglishContext: Text): Boolean
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
    begin
        exit(PowerBIReportConfiguration.Get(UserSecurityId(), ReportId, EnglishContext));
    end;
#endif

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

    procedure GetFactboxRatio(): Text
    begin
        exit(FactboxRatioTxt);
    end;

    procedure GetMainPageRatio(): Text
    begin
        exit(MainPageRatioTxt);
    end;

#if not CLEAN23
    [Obsolete('Error texts should be defined per extension. In other words, define your own text constants.', '23.0')]
    procedure GetUnauthorizedErrorText(): Text
    begin
        exit(UnauthorizedErr);
    end;
#endif

    procedure GetContentPacksServicesUrl(): Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        // Gets the URL for AppSource's list of content packs, like Power BI's Services button, filtered to Dynamics reports.
        if EnvironmentInformation.IsSaaSInfrastructure() then
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
    [Obsolete('This function requires now a context parameter.', '23.0')]
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
#elif not CLEAN23
    [Scope('OnPrem')]
    [Obsolete('This function requires now a context parameter.', '23.0')]
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
    procedure SynchronizeReportsInBackground(Context: Text[50])
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduledDateTime: DateTime;
    begin
        ScheduledDateTime := CurrentDateTime();

        Session.LogMessage('0000FB2', StrSubstNo(ScheduleSyncTelemetryMsg, Format(ScheduledDateTime, 50, 9)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
        JobQueueEntry.ScheduleJobQueueEntryForLater(Codeunit::"Power BI Report Synchronizer", ScheduledDateTime, GetJobQueueCategoryCode(), Context)
    end;

    [Scope('OnPrem')]
    procedure IsUserSynchronizingReports(): Boolean
    var
#if not CLEAN23
        PowerBIUserStatus: Record "Power BI User Status";
#endif
        JobQueueEntry: Record "Job Queue Entry";
    begin
#if not CLEAN23
        if PowerBIUserStatus.Get(UserSecurityId()) then
            if PowerBIUserStatus."Is Synchronizing" then
                exit(true);
#endif

        JobQueueEntry.SetRange("User ID", UserId());
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Power BI Report Synchronizer");
        JobQueueEntry.SetFilter(Status, '%1|%2|%3|%4', JobQueueEntry.Status::Ready, JobQueueEntry.Status::"In Process", JobQueueEntry.Status::"On Hold", JobQueueEntry.Status::"On Hold with Inactivity Timeout");

        if not JobQueueEntry.IsEmpty() then
            exit(true);

        exit(false);
    end;

#if not CLEAN23
    [Scope('OnPrem')]
    [Obsolete('Information on whether the user is synchronizing reports is no longer kept in a dedicated table. Instead, a user is synchronizing if they have a pending job queue entry for codeunit Power BI Report Synchronizer. If you want to stop synchronization for a user, create a new Job Queue Entry for codeunit Power BI Report Synchronizer and set it to On Hold. If you want to restart synchronization, make sure there is a ready job queue entry for codeunit Power BI Report Synchronizer.', '23.0')]
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
#endif

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

#if not CLEAN23
    [Obsolete('Check "Power BI Report Uploads" table directly', '23.0')]
    [Scope('OnPrem')]
    procedure HasUploads(): Boolean
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
        exit(not PowerBIReportUploads.IsEmpty);
    end;

    [Scope('OnPrem')]
    [Obsolete('Use interface "Power BI Service Provider" and its implementations instead.', '23.0')]
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
    [Obsolete('Use interface "Power BI Service Provider" and its implementations instead.', '23.0')]
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
#endif

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

    /// <summary>
    /// Add a Power BI report visual to the database, so that it's displayed in a certain context for the current user.
    /// </summary>
    /// <param name="ReportId">The ID of the Power BI Report that contains the visual to embed</param>
    /// <param name="ReportPageId">The name of the page in the report that contains the visual to embed</param>
    /// <param name="ReportVisualId">The ID of the report visual to embed</param>
    /// <param name="Context">The context where the Power BI report visual should show up</param>
    /// <remarks>
    /// The easiest way to get the necessary IDs for report visuals is to:
    ///   1. Open the Power BI report in the browser
    ///   2. Hover over the visual you want to embed, and click on the three dots menu
    ///   3. Choose to "Share" the visual, and choose "Link to this Visual"
    ///   4. Use the "Copy" button to copy the URL
    ///   5. From the URL, you can find:
    ///     a. The Report ID after the /reports/ segment 
    ///     b. The Report Page right after the Report ID
    ///     c. The visual ID in a URL query parameter called "visual"
    ///
    /// Example URL with placeholders:
    /// https://app.powerbi.com/groups/me/reports/REPORT_ID/PAGE_ID?[...]&amp;visual=VISUAL_ID
    /// </remarks>
    procedure AddReportVisualForContext(ReportId: Guid; ReportPageId: Text[200]; ReportVisualId: Text[200]; Context: Text[50])
    var
        PowerBIContextSettings: Record "Power BI Context Settings";
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
    begin
        if not PowerBIDisplayedElement.Get(UserSecurityId(), Context, PowerBIDisplayedElement.MakeReportVisualKey(ReportId, ReportPageId, ReportVisualId), PowerBIDisplayedElement.ElementType::"Report Visual") then begin
            PowerBIDisplayedElement.Init();
            PowerBIDisplayedElement.ElementType := PowerBIDisplayedElement.ElementType::"Report Visual";
            PowerBIDisplayedElement.ElementId := PowerBIDisplayedElement.MakeReportVisualKey(ReportId, ReportPageId, ReportVisualId);
            // NOTE: The Power BI team recommends to get the embed URL from the Power BI REST APIs, as the URL format might change in the future. 
            // However, currently the approach below is also supported.
            PowerBIDisplayedElement.ElementEmbedUrl := StrSubstNo(PowerBIEmbedReportUrlTemplateTxt, ReportId);
            PowerBIDisplayedElement.Context := Context;
            PowerBIDisplayedElement.UserSID := UserSecurityId();
            PowerBIDisplayedElement.ShowPanesInExpandedMode := true;
            PowerBIDisplayedElement.ShowPanesInNormalMode := false;
            PowerBIDisplayedElement.Insert(true);
        end;

        PowerBIContextSettings.CreateOrReadForCurrentUser(Context);
        if not PowerBIContextSettings.LockToSelectedElement then begin
            PowerBIContextSettings.LockToSelectedElement := true;
            PowerBIContextSettings.Modify(true);
        end;
    end;

    /// <summary>
    /// Add a Power BI report to the database, so that it's displayed in a certain context for the current user.
    /// </summary>
    /// <param name="ReportId">The ID of the Power BI Report to embed</param>
    /// <param name="Context">The context where the Power BI report should show up</param>
    procedure AddReportForContext(ReportId: Guid; Context: Text[50])
    var
        PowerBIContextSettings: Record "Power BI Context Settings";
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
    begin
        if not PowerBIDisplayedElement.Get(UserSecurityId(), Context, PowerBIDisplayedElement.MakeReportKey(ReportId), PowerBIDisplayedElement.ElementType::"Report") then begin
            PowerBIDisplayedElement.Init();
            PowerBIDisplayedElement.ElementType := PowerBIDisplayedElement.ElementType::"Report";
            PowerBIDisplayedElement.ElementId := PowerBIDisplayedElement.MakeReportKey(ReportId);
            // NOTE: The Power BI team recommends to get the embed URL from the Power BI REST APIs, as the URL format might change in the future. 
            // However, currently the approach below is also supported.
            PowerBIDisplayedElement.ElementEmbedUrl := StrSubstNo(PowerBIEmbedReportUrlTemplateTxt, ReportId);
            PowerBIDisplayedElement.Context := Context;
            PowerBIDisplayedElement.UserSID := UserSecurityId();
            PowerBIDisplayedElement.ShowPanesInExpandedMode := true;
            PowerBIDisplayedElement.ShowPanesInNormalMode := false;
            PowerBIDisplayedElement.Insert(true);
        end;

        PowerBIContextSettings.CreateOrReadForCurrentUser(Context);
        if not PowerBIContextSettings.LockToSelectedElement then begin
            PowerBIContextSettings.LockToSelectedElement := true;
            PowerBIContextSettings.Modify(true);
        end;
    end;

    procedure IsUserAdminForPowerBI(UserSecurityId: Guid): Boolean
    var
        UserPermissions: Codeunit "User Permissions";
    begin
        exit(UserPermissions.IsSuper(UserSecurityId));
    end;

#if not CLEAN23
    [Scope('OnPrem')]
    [Obsolete('Use platform capabilities to escape text in JSON strings instead. For example, text is escaped by platform when calling JsonArray.Add(Text).', '23.0')]
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
#endif

    procedure CheckPowerBITablePermissions(): Boolean
    var
#if not CLEAN23
        PowerBIUserConfiguration: Record "Power BI User Configuration";
#endif
        PowerBIBlob: Record "Power BI Blob";
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        PowerBIContextSettings: Record "Power BI Context Settings";
        PowerBICustomerReports: Record "Power BI Customer Reports";
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
    begin
#if not CLEAN23
        if not (PowerBIUserConfiguration.WritePermission and PowerBIUserConfiguration.ReadPermission) then
            exit(false);
#endif

        exit(PowerBIBlob.ReadPermission()
            and PowerBIDefaultSelection.ReadPermission()
            and PowerBICustomerReports.ReadPermission()
            and PowerBIContextSettings.WritePermission() and PowerBIContextSettings.ReadPermission()
            and PowerBIDisplayedElement.ReadPermission());
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

    internal procedure GetPowerBiFeatureTelemetryName(): Text
    begin
        exit(PowerBiEmbedFeatureTelemetryTok);
    end;

    [NonDebuggable]
    internal procedure GetEmbedAccessToken() AccessToken: Text
    var
        HttpUtility: DotNet HttpUtility;
    begin
        AccessToken := HttpUtility.JavaScriptStringEncode(
            AzureAdMgt.GetAccessToken(GetPowerBIResourceUrl(), GetPowerBiResourceName(), false)
            );

        if AccessToken = '' then begin
            Session.LogMessage('0000KQL', EmptyAccessTokenTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
            Error(FailedAuthErr);
        end;
    end;

    internal procedure CreateServiceProvider(var PowerBIServiceProvider: Interface "Power BI Service Provider")
    var
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
        PowerBIRestServiceProvider: Codeunit "Power BI Rest Service Provider";
        AzureAccessToken: Text;
        Handled: Boolean;
    begin
        OnServiceProviderCreate(PowerBIServiceProvider, Handled);

        if Handled then
            exit;

        AzureAccessToken := AzureAdMgt.GetAccessToken(GetPowerBIResourceUrl(), GetPowerBiResourceName(), false);

        if AzureAccessToken = '' then begin
            Session.LogMessage('0000B62', EmptyAccessTokenTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
            Error(UnauthorizedErr);
        end;

        PowerBIRestServiceProvider.Initialize(AzureAccessToken, PowerBIUrlMgt.GetPowerBIApiUrl());
        PowerBIServiceProvider := PowerBIRestServiceProvider;
    end;

    [InternalEvent(false)]
    local procedure OnServiceProviderCreate(var PowerBIServiceProvider: Interface "Power BI Service Provider"; var Handled: Boolean)
    begin
    end;
}