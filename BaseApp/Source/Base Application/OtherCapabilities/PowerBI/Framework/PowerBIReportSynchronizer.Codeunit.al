/// <summary>
/// Encapsulates the logic to deploy and/or delete default Power BI reports. Should be run in background.
/// </summary>
codeunit 6325 "Power BI Report Synchronizer"
{

    trigger OnRun()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
#if not CLEAN22
        if not DeploymentServiceAvailable() then
            exit;
#else
        if EnvironmentInformation.IsOnPrem() then
            exit;
#endif

        PowerBIServiceMgt.SetIsSynchronizing(true);

        DeleteMarkedDefaultReports();
        RetryPartialUploadBatch();
        UploadOutOfTheBoxReport();
        UploadCustomerReports();
        SelectDefaultReports();

        PowerBIServiceMgt.SetIsSynchronizing(false);

        if GetReportsToRetry(PowerBIReportUploads) then
            PowerBIServiceMgt.SynchronizeReportsInBackground();
    end;

    local procedure UploadOutOfTheBoxReport()
    var
        PageId: Text[50];
    begin
        PageId := GetPageId();

        if PageId = '' then begin
            Session.LogMessage('0000E1I', PageIdEmptyForDeploymentTxt, Verbosity::Warning, DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            exit;
        end;

        UploadOutOfTheBoxReportForContext(PageId);
    end;

    local procedure DeleteMarkedDefaultReports()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBICustomerReports: Record "Power BI Customer Reports";
    begin
        // Deletes a batch of default reports that have been marked for deletion for the current user. Reports are
        // deleted from the user's Power BI workspace first, and then removed from the uploads table if that was
        // successful.
        // Should only be called as part of a background session to reduce perf impact.

        if GetReportsToDelete(PowerBIReportUploads) then
            if PowerBIReportUploads.FindSet() then
                repeat
                    PowerBICustomerReports.Reset();
                    PowerBICustomerReports.SetFilter(Id, PowerBIReportUploads."PBIX BLOB ID");
                    repeat
                        if PowerBICustomerReports.Id = PowerBIReportUploads."PBIX BLOB ID" then
                            PowerBICustomerReports.Delete();
                    until PowerBICustomerReports.Next() = 0;
                    PowerBIReportUploads.Delete();
                until PowerBIReportUploads.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure UserNeedsToSynchronize(Context: Text[50]): Boolean
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        ReportsToUpload: Dictionary of [Guid, Boolean];
    begin
#if not CLEAN22
        if not DeploymentServiceAvailable() then
            exit(false);
#else
        if EnvironmentInformation.IsOnPrem() then
            exit(false);
#endif

        // Upload
        if GetOutOfTheBoxReportsToUpload(Context, ReportsToUpload) then
            exit(true);

        if GetCustomerReportsToUpload(ReportsToUpload) then
            exit(true);

        // Retry
        if GetReportsToRetry(PowerBIReportUploads) then
            exit(true);

        // Delete
        if GetReportsToDelete(PowerBIReportUploads) then
            exit(true);

        exit(false)
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
        NullGuid: Guid;
    begin
        // Finds all recently uploaded default reports and enables/selects them on the appropriate pages
        // per table 2000000145.
        // (Note that each report only gets auto-selection done one time - if the user later deselects it
        // we won't keep reselecting it.)

        // If the GP flag is set in TAB2000000146, the report for the selected page/role center is removed
        // and we select the GP report

        // Get a page ID for a page where configuration exists (=user has clicked get started) but no default report is selected
        PageId := GetPageId();

        Session.LogMessage('0000ED3', StrSubstNo(PageIdTelemetryMsg, PageId), Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        if PageId = '' then
            exit;

        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetRange("User ID", UserSecurityId());
        PowerBIReportUploads.SetFilter("Uploaded Report ID", '<>%1', NullGuid);
        PowerBIReportUploads.SetRange("Is Selection Done", false);

        if not IntelligentCloud.Get() then
            PowerBIReportUploads.SetFilter(IsGP, '%1', false);

        if PowerBIReportUploads.FindSet() then
            repeat
                PowerBIReportUploads."Is Selection Done" := true;
                PowerBIReportUploads.Modify();

                PowerBIDefaultSelection.Reset();
                PowerBIDefaultSelection.SetFilter(Id, PowerBIReportUploads."PBIX BLOB ID");
                PowerBIDefaultSelection.SetFilter(Context, PageId);

                if PowerBIDefaultSelection.FindFirst() then begin
                    PowerBIReportConfiguration.Reset();
                    PowerBIReportConfiguration.SetFilter("User Security ID", UserSecurityId());
                    PowerBIReportConfiguration.SetFilter("Report ID", PowerBIReportUploads."Uploaded Report ID");
                    PowerBIReportConfiguration.SetFilter(Context, PowerBIDefaultSelection.Context);
                    if not PowerBIReportConfiguration.IsEmpty() then
                        if PowerBIReportConfiguration.Delete() then;
                    PowerBIReportConfiguration.Init();
                    PowerBIReportConfiguration."User Security ID" := UserSecurityId();
                    PowerBIReportConfiguration."Report ID" := PowerBIReportUploads."Uploaded Report ID";
                    PowerBIReportConfiguration.Validate(ReportEmbedUrl, PowerBIReportUploads."Report Embed Url");
                    PowerBIReportConfiguration.Context := PowerBIDefaultSelection.Context;
                    if PowerBIReportConfiguration.Insert() then;

                    if PowerBIDefaultSelection.Selected then begin
                        PowerBIUserConfiguration.Reset();

                        PowerBIUserConfiguration.CreateOrReadForCurrentUser(PowerBIDefaultSelection.Context);
                        PowerBIBlob.Reset();
                        PowerBIBlob.SetFilter(Id, PowerBIUserConfiguration."Selected Report ID");
                        if (IntelligentCloud.Get() and not PowerBIBlob."GP Enabled") or
                           IsNullGuid(PowerBIUserConfiguration."Selected Report ID")
                        then begin
                            PowerBIUserConfiguration."Selected Report ID" := PowerBIReportUploads."Uploaded Report ID";
                            PowerBIUserConfiguration.Modify();
                        end;
                    end;
                end;
            until PowerBIReportUploads.Next() = 0;
    end;

    local procedure GetPowerBIBlob(var PowerBIBlob: Record "Power BI Blob"; BlobId: Guid): Boolean
    begin
        if not IsNullGuid(BlobId) then
            if PowerBIBlob.Get(BlobId) then
                exit(true);

        // This is most of the times expected, e.g. if we are determining if a blob is OutOfTheBox or Customer Uploaded
        Session.LogMessage('0000B61', StrSubstNo(BlobDoesNotExistTelemetryMsg, BlobId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
        exit(false);
    end;

#if not CLEAN22
    local procedure DeploymentServiceAvailable(): Boolean
    begin
        if EnvironmentInformation.IsOnPrem() then
            exit(false);

        if PowerBiServiceMgt.IsPBIServiceAvailable() then
            exit(true);

        exit(false);
    end;
#endif

    local procedure GetOutOfTheBoxBlobIdForDeployment(Context: Text[50]): Guid
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        IntelligentCloud: Record "Intelligent Cloud";
        NullGuid: Guid;
    begin
        // Gets the blob id to be deployed for the given context.
        // Currently supports only one report for each context.

        PowerBIDefaultSelection.Reset();
        PowerBIDefaultSelection.SetFilter(Context, Context);

        if PowerBIDefaultSelection.IsEmpty() then
            exit(NullGuid);

        if PowerBIDefaultSelection.FindSet() then
            repeat
                PowerBIBlob.Reset();
                PowerBIBlob.SetRange(Id, PowerBIDefaultSelection.Id);
                PowerBIBlob.SetRange("GP Enabled", IntelligentCloud.Get());
                if not PowerBIBlob.IsEmpty() then
                    exit(PowerBIDefaultSelection.Id);
            until PowerBIDefaultSelection.Next() = 0;

        PowerBIBlob.SetRange("GP Enabled", false);
        if PowerBIBlob.FindFirst() then
            exit(PowerBIBlob.Id);

        exit(NullGuid);
    end;

    local procedure GetPageId(): Text[50]
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
        NullGuid: Guid;
    begin
        // Get a page ID for a page where configuration exists (=user has clicked get started) but no default report is selected
        PowerBIUserConfiguration.Reset();
        PowerBIUserConfiguration.SetRange("User Security ID", UserSecurityId());
        PowerBIUserConfiguration.SetRange("Profile ID", PowerBIServiceMgt.GetEnglishContext());
        PowerBIUserConfiguration.SetRange("Selected Report ID", NullGuid);

        if not PowerBIUserConfiguration.FindFirst() then
            exit('');

        exit(PowerBIUserConfiguration."Page ID");
    end;

    local procedure UploadOutOfTheBoxReportForContext(Context: Text[50])
    var
        PowerBIBlob: Record "Power BI Blob";
        ApiRequest: DotNet ImportReportRequest;
        ApiRequestList: DotNet ImportReportRequestList;
        BlobStream: InStream;
        ReportsToUpload: Dictionary of [Guid, Boolean];
        BlobId: Guid;
        EnvName: Text;
        NeedsOverwrite: Boolean;
    begin
        // Prepare API Request List. 
        // Note: this is not currently refactored to a separate function because otherwise the stream variable would fall out
        // of scope and be disposed before being used. TODO this might cause issue in case of multiple reports uploaded at the same time.
        ApiRequestList := ApiRequestList.ImportReportRequestList();
        EnvName := EnvironmentInformation.GetEnvironmentName();

        // OutOfTheBox
        PowerBIBlob.SetAutoCalcFields("Blob File");
        if GetOutOfTheBoxReportsToUpload(Context, ReportsToUpload) then
            foreach BlobId in ReportsToUpload.Keys() do begin
                NeedsOverwrite := ReportsToUpload.Get(BlobId); // NOTE this is Get from a dictionary, so it returns the dictionary value associated with the key BlobId

                PowerBIBlob.Get(BlobId); // Fails only in case of race conditions, which is OK
                PowerBIBlob."Blob File".CreateInStream(BlobStream);

                ApiRequest := ApiRequest.ImportReportRequest(PowerBIBlob.Id, BlobStream, MakeReportNameForUpload(PowerBIBlob.Name, EnvName), EnvName, NeedsOverwrite);
                ApiRequestList.Add(ApiRequest);
            end;

        UploadFromApiRequestList(ApiRequestList, EnvName);
    end;

    local procedure UploadCustomerReports()
    var
        PowerBICustomerReports: Record "Power BI Customer Reports";
        ApiRequest: DotNet ImportReportRequest;
        ApiRequestList: DotNet ImportReportRequestList;
        BlobStream: InStream;
        ReportsToUpload: Dictionary of [Guid, Boolean];
        BlobId: Guid;
        EnvName: Text;
        NeedsOverwrite: Boolean;
    begin
        // Prepare API Request List. 
        // Note: this is not currently refactored to a separate function because otherwise the stream variable would fall out
        // of scope and be disposed before being used. TODO this might cause issue in case of multiple reports uploaded at the same time.
        ApiRequestList := ApiRequestList.ImportReportRequestList();
        EnvName := EnvironmentInformation.GetEnvironmentName();

        // Customer
        PowerBICustomerReports.SetAutoCalcFields("Blob File");
        if GetCustomerReportsToUpload(ReportsToUpload) then
            foreach BlobId in ReportsToUpload.Keys() do begin
                NeedsOverwrite := ReportsToUpload.Get(BlobId); // NOTE this is Get from a dictionary, so it returns the dictionary value associated with the key BlobId

                PowerBICustomerReports.Get(BlobId); // Fails only in case of race conditions, which is OK
                PowerBICustomerReports."Blob File".CreateInStream(BlobStream);

                ApiRequest := ApiRequest.ImportReportRequest(PowerBICustomerReports.Id, BlobStream, MakeReportNameForUpload(PowerBICustomerReports.Name, EnvName), EnvName, NeedsOverwrite);
                ApiRequestList.Add(ApiRequest);
            end;

        UploadFromApiRequestList(ApiRequestList, EnvName);
    end;

    [NonDebuggable]
    local procedure UploadFromApiRequestList(ApiRequestList: DotNet ImportReportRequestList; EnvName: Text)
    var
        UrlHelper: Codeunit "Url Helper";
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
        PbiServiceWrapper: DotNet ServiceWrapper;
        ApiResponseList: DotNet ImportReportResponseList;
        ApiResponse: DotNet ImportReportResponse;
#if not CLEAN22
        DotNetDateTime: DotNet DateTime;
#endif
        AzureAccessToken: Text;
        BusinessCentralAccessToken: Text;
    begin
        Session.LogMessage('0000DZ1', StrSubstNo(ReportUploadStartingMsg, ApiRequestList.Count()), Verbosity::Normal,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        if ApiRequestList.Count() > 0 then begin
            AzureAccessToken := AzureAdMgt.GetAccessToken(PowerBIServiceMgt.GetPowerBIResourceUrl(), PowerBIServiceMgt.GetPowerBiResourceName(), false);

            if AzureAccessToken = '' then begin
                Session.LogMessage('0000B62', EmptyAccessTokenTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
                exit;
            end;

            PbiServiceWrapper := PbiServiceWrapper.ServiceWrapper(AzureAccessToken, PowerBIUrlMgt.GetPowerBIApiUrl());

            BusinessCentralAccessToken := AzureAdMgt.GetAccessToken(UrlHelper.GetFixedEndpointWebServiceUrl(), '', false);

            if BusinessCentralAccessToken = '' then begin
                Session.LogMessage('0000B63', EmptyAccessTokenTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
                exit;
            end;

            ApiResponseList := PbiServiceWrapper.ImportReports(ApiRequestList,
                CompanyName, EnvName, BusinessCentralAccessToken, GetServiceRetries());

            foreach ApiResponse in ApiResponseList do
                HandleUploadResponse(ApiResponse.ImportId, ApiResponse.RequestReportId,
                  ApiResponse.ImportedReport, ApiResponse.ShouldRetry, ApiResponse.RetryAfter);

#if not CLEAN22
            if not IsNull(ApiResponseList.RetryAfter) then begin
                DotNetDateTime := ApiResponseList.RetryAfter;
                UpdatePBIServiceAvailability(DotNetDateTime);
            end;
#endif
        end;
    end;

    local procedure GetServiceRetries(): Integer
    begin
        // Const - number of attempts for deployment API calls.
        exit(25);
    end;

    local procedure MakeReportNameForUpload(PbixReportName: Text; EnvironmentName: Text): Text
    begin
        exit(StrSubstNo(ReportEnvNameTxt, EnvironmentName, PbixReportName));
    end;

    [NonDebuggable]
    local procedure RetryPartialUploadBatch()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
        UrlHelper: Codeunit "Url Helper";
        PbiServiceWrapper: DotNet ServiceWrapper;
        ImportIdList: DotNet ImportedReportRequestList;
        ApiResponseList: DotNet ImportedReportResponseList;
        ApiResponse: DotNet ImportedReportResponse;
#if not CLEAN22
        DotNetDateTime: DotNet DateTime;
#endif
        AzureAccessToken: Text;
        BusinessCentralAccessToken: Text;
        EnvName: Text;
        NullGuid: Guid;
    begin
        // Retries a batch of default reports that have had their uploads started but not finished, based on
        // the passed in priority (see DoesDefaultReportMatchPriority). This will attempt to have the PBI service
        // retry the connection/refresh tasks to finish the upload process.
        ImportIdList := ImportIdList.ImportedReportRequestList();
        EnvName := EnvironmentInformation.GetEnvironmentName();

        if GetReportsToRetry(PowerBIReportUploads) then
            if PowerBIReportUploads.FindSet() then
                repeat
                    ImportIdList.Add(PowerBIReportUploads."Import ID");
                until PowerBIReportUploads.Next() = 0;

        if ImportIdList.Count > 0 then begin
            AzureAccessToken := AzureAdMgt.GetAccessToken(PowerBIServiceMgt.GetPowerBIResourceUrl(), PowerBIServiceMgt.GetPowerBiResourceName(), false);

            PbiServiceWrapper := PbiServiceWrapper.ServiceWrapper(AzureAccessToken, PowerBIUrlMgt.GetPowerBIApiUrl());
            BusinessCentralAccessToken := AzureAdMgt.GetAccessToken(UrlHelper.GetFixedEndpointWebServiceUrl(), '', false);

            if BusinessCentralAccessToken = '' then
                exit;

            ApiResponseList := PbiServiceWrapper.GetImportedReports(ImportIdList,
                CompanyName, EnvName, BusinessCentralAccessToken, GetServiceRetries());

            foreach ApiResponse in ApiResponseList do
                HandleUploadResponse(ApiResponse.ImportId, NullGuid, ApiResponse.ImportedReport,
                  ApiResponse.ShouldRetry, ApiResponse.RetryAfter);

#if not CLEAN22
            if not IsNull(ApiResponseList.RetryAfter) then begin
                DotNetDateTime := ApiResponseList.RetryAfter;
                UpdatePBIServiceAvailability(DotNetDateTime);
            end;
#endif
        end;
    end;

#if not CLEAN22
    local procedure UpdatePBIServiceAvailability(RetryAfter: DateTime)
    var
        PowerBIServiceStatusSetup: Record "Power BI Service Status Setup";
    begin
        // Sets the cross-company variable that tracks when the Power BI service is available for
        // deployment calls - service failures will return the date/time which we shouldn't attempt
        // new calls before.
        PowerBIServiceStatusSetup.Reset();
        if PowerBIServiceStatusSetup.FindFirst() then begin
            PowerBIServiceStatusSetup."Retry After" := RetryAfter;
            PowerBIServiceStatusSetup.Modify();
        end else begin
            PowerBIServiceStatusSetup.Init();
            PowerBIServiceStatusSetup."Retry After" := RetryAfter;
            PowerBIServiceStatusSetup.Insert();
        end;
    end;
#endif

    local procedure HandleUploadResponse(ImportId: Text; BlobId: Guid; ReturnedReport: DotNet ImportedReport; ShouldRetry: DotNet Nullable1;
                                                                                           RetryAfter: DotNet Nullable1) WasSuccessful: Boolean
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBICustomerReports: Record "Power BI Customer Reports";
        DotNetBoolean: DotNet Boolean;
        DotNetDateTime: DotNet DateTime;
        NullGuid: Guid;
    begin
        // Deals with individual responses from the Power BI service for importing or finishing imports of
        // default reports. This is what updates the tables so we know which reports are actually ready
        // to be selected, versus still needing work, depending on the info sent back by the service.
        // Returns true if the upload completely finished (i.e. got a report ID back), otherwise false.
        if ImportId <> '' then begin
            PowerBIReportUploads.Reset();
            PowerBIReportUploads.SetFilter("User ID", UserSecurityId());

            // Empty blob ID happens when we're finishing a partial upload (existing record in table 6307).
            if IsNullGuid(BlobId) then
                PowerBIReportUploads.SetFilter("Import ID", ImportId)
            else
                PowerBIReportUploads.SetFilter("PBIX BLOB ID", BlobId);

            if PowerBIReportUploads.IsEmpty() then begin
                // First time this report has been uploaded.
                PowerBIReportUploads.Init();
                PowerBIReportUploads."PBIX BLOB ID" := BlobId;
                PowerBIReportUploads."User ID" := UserSecurityId();
                PowerBIReportUploads."Is Selection Done" := false;
            end else
                // Overwriting or finishing a previously uploaded report.
                PowerBIReportUploads.FindFirst();

            if not IsNull(ReturnedReport) then begin
                WasSuccessful := true;
                PowerBIReportUploads."Uploaded Report ID" := ReturnedReport.ReportId;
                PowerBIReportUploads.Validate("Report Embed Url",
                    CopyStr(ReturnedReport.EmbedUrl, 1, MaxStrLen(PowerBIReportUploads."Report Embed Url")));
                PowerBIReportUploads."Import ID" := NullGuid;
                PowerBIReportUploads."Should Retry" := false;
                PowerBIReportUploads."Retry After" := 0DT;
            end else begin
                WasSuccessful := false;
                PowerBIReportUploads."Import ID" := ImportId;
                PowerBIReportUploads."Uploaded Report ID" := NullGuid;
                if not IsNull(ShouldRetry) then begin
                    DotNetBoolean := ShouldRetry;
                    PowerBIReportUploads."Should Retry" := DotNetBoolean.Equals(true);
                end;
                if not IsNull(RetryAfter) then begin
                    DotNetDateTime := RetryAfter;
                    PowerBIReportUploads."Retry After" := DotNetDateTime;
                end;
            end;

            if GetPowerBIBlob(PowerBIBlob, PowerBIReportUploads."PBIX BLOB ID") then begin
                PowerBIReportUploads."Deployed Version" := PowerBIBlob.Version;
                PowerBIReportUploads.IsGP := PowerBIBlob."GP Enabled";
            end else
                if PowerBICustomerReports.Get(PowerBIReportUploads."PBIX BLOB ID") then
                    PowerBIReportUploads."Deployed Version" := PowerBICustomerReports.Version;

            if PowerBIReportUploads.IsEmpty() then
                PowerBIReportUploads.Insert()
            else
                PowerBIReportUploads.Modify();
            Commit();
        end;
    end;

    local procedure GetReportsToRetry(var PowerBIReportUploads: Record "Power BI Report Uploads"): Boolean
    var
        NullGuid: Guid;
    begin
        // Checks whether the user has any partially deployed OutOfTheBox reports that we need to finish.
        // NOTE: there are two cases. 
        // 1) The upload errored out partway through, in which case we get ShouldRetry=true from Power BI and we save it in table 6307 "Power BI Report Uploads"
        // 2) The upload is still ongoing, so we get ShouldRetry=false
        // In both cases we don't have a final report ID from the PBI website yet ("Uploaded Report ID"), but for now we only catch the first case (the second needs more investigation).

        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetRange("User ID", UserSecurityId());
        PowerBIReportUploads.SetRange("Uploaded Report ID", NullGuid);
        PowerBIReportUploads.SetRange("Should Retry", true);
        PowerBIReportUploads.SetRange("Needs Deletion", false);
        PowerBIReportUploads.SetFilter("Retry After", '<%1', CurrentDateTime());

        exit(not PowerBIReportUploads.IsEmpty());
    end;

    local procedure GetOutOfTheBoxReportsToUpload(Context: Text[50]; var ReportsToOverwriteOrUpload: Dictionary of [Guid, Boolean]): Boolean
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        BlobId: Guid;
    begin
        Clear(ReportsToOverwriteOrUpload);
        if Context = '' then
            exit(false);

        // OutOfTheBox reports
        BlobId := GetOutOfTheBoxBlobIdForDeployment(Context);
        if not GetPowerBIBlob(PowerBIBlob, BlobId) then
            exit(false);

        if not PowerBIReportUploads.Get(PowerBIBlob.Id, UserSecurityId()) then
            ReportsToOverwriteOrUpload.Add(PowerBIBlob.Id, false)
        else
            if PowerBIReportUploads."Deployed Version" < PowerBIBlob.Version then
                if not PowerBIReportUploads."Needs Deletion" then
                    ReportsToOverwriteOrUpload.Add(PowerBIBlob.Id, true);

        exit(ReportsToOverwriteOrUpload.Count() > 0);
    end;

    local procedure GetCustomerReportsToUpload(var ReportsToOverwriteOrUpload: Dictionary of [Guid, Boolean]): Boolean
    var
        PowerBICustomerReports: Record "Power BI Customer Reports";
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
        Clear(ReportsToOverwriteOrUpload);

        // Customer reports
        PowerBICustomerReports.Reset();
        if PowerBICustomerReports.FindSet() then
            repeat
                if not PowerBIReportUploads.Get(PowerBICustomerReports.Id, UserSecurityId()) then
                    ReportsToOverwriteOrUpload.Add(PowerBICustomerReports.Id, false)
                else
                    if PowerBIReportUploads."Deployed Version" < PowerBICustomerReports.Version then
                        if not PowerBIReportUploads."Needs Deletion" then
                            ReportsToOverwriteOrUpload.Add(PowerBICustomerReports.Id, true)
            until PowerBICustomerReports.Next() = 0;

        exit(ReportsToOverwriteOrUpload.Count() > 0);
    end;

    local procedure GetReportsToDelete(var PowerBIReportUploads: Record "Power BI Report Uploads"): Boolean
    begin
        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetRange("User ID", UserSecurityId());
        PowerBIReportUploads.SetRange("Needs Deletion", true);
        exit(not PowerBIReportUploads.IsEmpty());
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        EnvironmentInformation: Codeunit "Environment Information";
        BlobDoesNotExistTelemetryMsg: Label 'Trying to upload a non-existing blob, with ID: %1.', Locked = true;
        PageIdTelemetryMsg: Label 'Selecting default reports for page: %1.', Locked = true;
        ReportUploadStartingMsg: Label 'Starting to upload %1 Power BI Reports.', Locked = true;
        EmptyAccessTokenTelemetryMsg: Label 'Encountered an empty access token.', Locked = true;
        PageIdEmptyForDeploymentTxt: Label 'Page ID for Power BI deployment is empty.', Locked = true;
        ReportEnvNameTxt: Label '%1 %2', Locked = true;

}
