codeunit 9510 "Document Service Management"
{
    // Provides functions for the storage of documents to online services such as O365 (Office 365).
    Permissions = TableData "Document Service Cache" = rimd;

    trigger OnRun()
    begin
    end;

    var
        NoConfigErr: Label 'No online document configuration was found.';
        MultipleConfigsErr: Label 'More than one online document configuration was found.';
        SourceFileNotFoundErr: Label 'Cannot open the specified document from the following location: %1 due to the following error: %2.', Comment = '%1=Full path to the file on disk;%2=the detailed error describing why the document could not be accessed.';
        RequiredSourceNameErr: Label 'You must specify a source path for the document.';
        DocumentService: DotNet IDocumentService;
        DocumentServiceFactory: DotNet DocumentServiceFactory;
        ServiceType: Text;
        LastServiceType: Text;
        RequiredTargetNameErr: Label 'You must specify a name for the document.';
        RequiredTargetURIErr: Label 'You must specify the URI that you want to open.';
        ValidateConnectionErr: Label 'Cannot connect because the user name and password have not been specified, or because the connection was canceled.';
        AccessTokenErrMsg: Label 'Failed to acquire an access token.';
        AccessTokenEmptyErr: Label 'There was a problem authenticating. Please try to sign out and sign in again.';
        MissingClientIdOrSecretErr: Label 'The client ID or client secret have not been initialized.';
        SharePointIsoStorageSecretNotConfiguredErr: Label 'Client secret for SharePoint has not been configured.';
        SharePointIsoStorageSecretNotConfiguredLbl: Label 'Client secret for SharePoint has not been configured.', Locked = true;
        AuthTokenOrCodeNotReceivedErr: Label 'No access token or authorization error code received. The authorization failure error is: %1.', Comment = '%1=Authentiaction Failure Error', Locked = true;
        AccessTokenAcquiredFromCacheErr: Label 'The attempt to acquire the access token form cache has failed.', Locked = false;
        OAuthAuthorityUrlLbl: Label 'https://login.microsoftonline.com/common/oauth2', Locked = true;
        SharePointTelemetryCategoryTxt: Label 'AL Sharepoint Integration', Locked = true;
        SharePointClientIdAKVSecretNameLbl: Label 'sharepoint-clientid', Locked = true;
        SharePointClientSecretAKVSecretNameLbl: Label 'sharepoint-clientsecret', Locked = true;
        MissingClientIdTelemetryTxt: Label 'The client ID has not been initialized.', Locked = true;
        MissingClientSecretTelemetryTxt: Label 'The client secret has not been initialized.', Locked = true;
        InitializedClientIdTelemetryTxt: Label 'The client ID has been initialized.', Locked = true;
        InitializedClientSecretTelemetryTxt: Label 'The client secret has been initialized.', Locked = true;
        CantFindMySiteErr: Label 'Could not determine the location of your OneDrive for Business, contact your partner to set this up.';
        UnknownLocationErr: Label 'An unexpected error occurred while trying to configure the Document Service. Try again later.';
        DocumentSharingNoNameErr: Label 'The document to be shared has not specified a name.';
        DocumentSharingNoExtErr: Label 'The document to be shared has not specified a file extension.';
        SharePointFileExistsInstructionsTxt: Label 'A file named "%1" already exists in your %2 folder in OneDrive for Business.\\ Would you like to add this new file as the latest version of the existing file, or rename it and keep them both?', Comment = '%1 = a file name, for example "CustomerCard.xlsx"; %2 = the product name, for example "Business Central"';
        SharePointFileExistsOptionsTxt: Label 'Replace,Keep both', Comment = 'A comma separated list with two options.';
        DocumentServiceCategoryLbl: Label 'AL DocumentService', Locked = true;
        DocumentSharingStartLbl: Label 'Handling document sharing event.', Locked = true;
        DocumentServiceDefaultingLbl: Label 'Configuring defaults for document service', Locked = true;
        DefaultLocationErrCodeErr: Label 'Graph request to determine root storage location resulted in status code: %1', Locked = true;
        CouldNotFindLocationInResponseErr: Label 'Graph request could not find the webUrl property for the default location.', Locked = true;
        LocationResponseInvalidErr: Label 'Graph request did not return a JSON document.', Locked = true;
        LocationFoundTxt: Label 'A default location was found of length %1', Locked = true;
        TokenRequestTxt: Label 'A token was requested. GetTokenFromCache: %1', Locked = true;
        NoDocumentServiceFoundErr: Label 'There''s no connection set up for OneDrive, so %1 can''t copy your files.\\ To set up a connection, open the page %2.', Comment = '%1= the product name for Business Central; %2= the page caption for Document Service Setup.';
        CheckingDriveProgressTxt: Label 'Checking that you have a valid drive.';
        CheckingBcDocumentFolderProgressTxt: Label 'Checking that the default folder exists.';
        SharepointUnexpectedStatusCodeErr: Label 'OneDrive returned an unexpected error code: %1.', Comment = '%1 = An error code from OneDrive, for example 503';
        SharepointInvalidJsonErr: Label 'OneDrive returned an invalid response. Details: %1.', Comment = '%1 = The response details from OneDrive (e.g. "Your Drive is not available")';
        MissingOneDriveLicenseSaasErr: Label 'You don''t have a license for OneDrive.';
        MissingOneDriveLicenseOnPremErr: Label 'You don''t have a license for OneDrive, or your Azure app registration for %1 on-premises doesn''t have the necessary permissions.', Comment = '%1 = the product name for Business Central';
        GraphApiUrlOnPremTxt: Label 'https://graph.microsoft.com', Locked = true;
        StartingLinkGenerationTelemetryMsg: Label 'Starting OneDrive link generation.', Locked = true;
        UsingDefaultDocumentServiceTelemetryMsg: Label 'Using default Document Service setup.', Locked = true;
        UsingCustomDocumentServiceTelemetryMsg: Label 'Using a Document Service retrieved from the database.', Locked = true;
        EmptyTokenTelemetryMsg: Label 'Empty access token from Azure AD Mgt.', Locked = true;
        SharepointStatusCodeTelemetryMsg: Label 'Sharepoint returned an error code: %1.', Locked = true;
        NoCompanyFolderTelemetryMsg: Label 'No company specific folder found, falling back to base Document Service folder.', Locked = true;
        NoCompanyOrBcFolderTelemetryMsg: Label 'No Document Service folder found, falling back to OneDrive root.', Locked = true;
        ConfigurationForTestConnectionTelemetryMsg: Label 'Configuration for test connection retrieved, with authentication: %1.', Locked = true;
        TrySaveStreamFromRecTelemetryMsg: Label 'TrySaveStreamFromRec started with conflict behavior: %1.', Locked = true;
        SettingResourceLocationTelemetryTxt: Label 'Setting resource location (old location length: %1, new location length: %2).', Locked = true;
        LocationTooLongTelemetryMsg: Label 'Maximum location length is %1, but the new location has length %2.', Locked = true;

    [Scope('OnPrem')]
    procedure TestConnection()
    var
        DocumentServiceRec: Record "Document Service";
        DocumentServiceHelper: DotNet NavDocumentServiceHelper;
    begin
        // Tests connectivity to the Document Service using the current configuration in Dynamics NAV.
        // An error occurrs if unable to successfully connect.
        if not IsConfigured then
            Error(NoConfigErr);

        DocumentServiceHelper.Reset();
        SetDocumentService();

        if DocumentServiceRec.FindFirst() then begin
            Session.LogMessage('0000FR2', StrSubstNo(ConfigurationForTestConnectionTelemetryMsg, DocumentServiceRec."Authentication Type"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);

            SetProperties(false, DocumentServiceRec);

            if DocumentServiceRec."Authentication Type" = DocumentServiceRec."Authentication Type"::Legacy then
                if IsNull(DocumentService.Credentials) then
                    Error(ValidateConnectionErr);
        end else
            Error(NoConfigErr);

        DocumentService.ValidateConnection;
        CheckError;
    end;

#if not CLEAN19
    [Scope('OnPrem')]
    [Obsolete('Use SaveFile(SourcePath; TargetName; ConflictBehavior) instead', '19.0')]
    procedure SaveFile(SourcePath: Text; TargetName: Text; Overwrite: Boolean): Text
    begin
        if Overwrite then
            exit(SaveFile(SourcePath, TargetName, Enum::"Doc. Service Conflict Behavior"::Replace))
        else
            exit(SaveFile(SourcePath, TargetName, Enum::"Doc. Service Conflict Behavior"::Rename));
    end;
#endif

    [Scope('OnPrem')]
    procedure SaveFile(SourcePath: Text; TargetName: Text; ConflictBehavior: Enum "Doc. Service Conflict Behavior"): Text
    var
        SourceFile: File;
        SourceStream: InStream;
    begin
        // Saves a file to the Document Service using the configured location specified in Dynamics NAV.
        // SourcePath: The path to a physical file on the Dynamics NAV server.
        // TargetName: The name which will be given to the file saved to the Document Service.
        // Overwrite: TRUE if the target file should be overwritten.
        // - An error is shown if Overwrite is FALSE and a file with that name already exists.
        // Returns: A URI to the file on the Document Service.

        if SourcePath = '' then
            Error(RequiredSourceNameErr);

        if TargetName = '' then
            Error(RequiredTargetNameErr);

        if not IsConfigured then
            Error(NoConfigErr);

        if not SourceFile.Open(SourcePath) then
            Error(SourceFileNotFoundErr, SourcePath, GetLastErrorText);

        SourceFile.CreateInStream(SourceStream);

        exit(SaveStream(SourceStream, TargetName, ConflictBehavior));
    end;

    procedure IsConfigured(): Boolean
    var
        DocumentServiceRec: Record "Document Service";
    begin
        // Returns TRUE if Dynamics NAV has been configured with a Document Service.

        with DocumentServiceRec do begin
            if Count > 1 then
                Error(MultipleConfigsErr);

            if not FindFirst() then
                exit(false);

            if (Location = '') or (Folder = '') then
                exit(false);
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure IsServiceUri(TargetURI: Text): Boolean
    var
        DocumentServiceRec: Record "Document Service";
        IsValid: Boolean;
    begin
        // Returns TRUE if the TargetURI points to a location on the currently-configured Document Service.

        if TargetURI = '' then
            exit(false);

        with DocumentServiceRec do begin
            if FindLast() then
                if Location <> '' then begin
                    SetDocumentService();
                    SetProperties(true, DocumentServiceRec);
                    EnsureDocumentServiceCache(DocumentServiceRec, true);
                    IsValid := DocumentService.IsValidUri(TargetURI);
                    CheckError;
                    exit(IsValid);
                end
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure SetServiceType(RequestedServiceType: Text)
    var
        DocumentServiceHelper: DotNet NavDocumentServiceHelper;
    begin
        // Sets the type name of the Document Service.
        // The type must match the DocumentServiceMetadata attribute value on the IDocumentServiceHandler interface
        // exposed by at least one assembly in the Server installation folder.
        // By default, Dynamics NAV uses the SharePoint Online Document Service with type named 'SHAREPOINTONLINE'.
        ServiceType := RequestedServiceType;
        DocumentServiceHelper.SetDocumentServiceType(RequestedServiceType);
    end;

    procedure GetServiceType(): Text
    begin
        // Gets the name of the current Document Service.

        exit(ServiceType);
    end;

    [Scope('OnPrem')]
    procedure OpenDocument(TargetURI: Text)
    begin
        // Navigates to the specified URI on the Document Service from the client device.

        if TargetURI = '' then
            Error(RequiredTargetURIErr);

        if not IsConfigured then
            Error(NoConfigErr);

        SetDocumentService();
        HyperLink(DocumentService.GenerateViewableDocumentAddress(TargetURI));
        CheckError;
    end;

    local procedure InitializeDefaultService(var DocumentServiceRec: Record "Document Service"; Name: Code[30])
    var
        OAuth2: Codeunit OAuth2;
        RedirectUrl: Text;
    begin
        DocumentServiceRec.Init();
        DocumentServiceRec."Service ID" := Name;
        DocumentServiceRec."Authentication Type" := DocumentServiceRec."Authentication Type"::OAuth2;
        OAuth2.GetDefaultRedirectUrl(RedirectUrl);
        DocumentServiceRec."Redirect URL" := CopyStr(RedirectUrl, 1, MaxStrLen(DocumentServiceRec."Redirect URL"));
        DocumentServiceRec.Location := GetDefaultLocation();
        DocumentServiceRec.Folder := GetDefaultFolderName();
    end;

    local procedure GetDefaultFolderName(): Text[250]
    begin
        exit(CopyStr(GetSafeDocumentServiceFolderName(ProductName.Short()), 1, 250));
    end;

    local procedure GetSafeCompanyName(): Text
    var
        Company: Record "Company";
        SafeCompanyName: Text;
    begin
        if (not Company.Get(CompanyName())) or (Company."Display Name" = '') then
            exit(GetSafeDocumentServiceFolderName(CompanyName()));

        SafeCompanyName := GetSafeDocumentServiceFolderName(Company."Display Name");

        if SafeCompanyName = '' then
            exit(GetSafeDocumentServiceFolderName(CompanyName()));

        exit(SafeCompanyName);
    end;

    local procedure GetSafeDocumentServiceFolderName(FolderName: Text): Text
    var
        FileManagement: Codeunit "File Management";
    begin
        FolderName := FileManagement.GetSafeFileName(FolderName);
        FolderName := DelChr(FolderName, '<', ' '); // Remove leading whitespace
        FolderName := DelChr(FolderName, '>', '. '); // Remove trailing periods and whitespace
        FolderName := DelChr(FolderName, '=', '%'); // Remove all percentage symbols

        exit(FolderName);
    end;

    [NonDebuggable]
    local procedure GetDefaultLocation(): Text[250]
    var
        UrlHelper: Codeunit "Url Helper";
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        UriBuilder: Codeunit "Uri Builder";
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        ResponseHeaders: DotNet NameValueCollection;
        StatusCode: DotNet HttpStatusCode;
        DriveJsonObject: JsonObject;
        Location: Text;
        ResponseContent: Text;
        ResponseErrorMessage: Text;
        ResponseErrorDetails: Text;
        Endpoint: Text;
        Token: Text;
    begin
        Endpoint := GetGraphSiteRootUrl();
        Token := AzureAdMgt.GetOnBehalfAccessToken(UrlHelper.GetGraphUrl());

        if Token = '' then begin
            Session.LogMessage('0000FSJ', EmptyTokenTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            Error(AccessTokenEmptyErr);
        end;

        HttpWebRequestMgt.Initialize(Endpoint);
        HttpWebRequestMgt.DisableUI();
        HttpWebRequestMgt.SetReturnType('application/json');
        HttpWebRequestMgt.AddHeader('Authorization', 'Bearer ' + Token);

        if not HttpWebRequestMgt.SendRequestAndReadTextResponse(ResponseContent, ResponseErrorMessage, ResponseErrorDetails, StatusCode, ResponseHeaders) then begin
            if StatusCode.ToString() = '404' then
                Error(CantFindMySiteErr);

            Session.LogMessage('0000FJY', StrSubstNo(DefaultLocationErrCodeErr, StatusCode.ToString()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);
            Error(UnknownLocationErr);
        end;

        if not DriveJsonObject.ReadFrom(ResponseContent) then begin
            Session.LogMessage('0000FLF', LocationResponseInvalidErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);
            Error(UnknownLocationErr);
        end;

        if not ExtractWebUrlFromJson(DriveJsonObject, Location) then begin
            Session.LogMessage('0000FLG', CouldNotFindLocationInResponseErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);
            Error(UnknownLocationErr);
        end;

        UriBuilder.Init(Location);
        Location := 'https://' + UriBuilder.GetHost() + '/';

        Session.LogMessage('0000FLH', StrSubstNo(LocationFoundTxt, StrLen(Location)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);
        exit(CopyStr(Location, 1, 250));
    end;

    local procedure SetResourceLocation(var DocumentServiceRec: Record "Document Service"): Boolean
    var
        NewLocation: Text;
    begin
        SetDocumentService();
        SetProperties(true, DocumentServiceRec);

        NewLocation := DocumentService.GetLocation();

        Session.LogMessage('0000GB1', StrSubstNo(SettingResourceLocationTelemetryTxt, StrLen(DocumentServiceRec.Location), StrLen(NewLocation)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);

        if NewLocation <> '' then begin
            if StrLen(NewLocation) > MaxStrLen(DocumentServiceRec.Location) then
                Session.LogMessage('0000GB2', StrSubstNo(LocationTooLongTelemetryMsg, MaxStrLen(DocumentServiceRec.Location), StrLen(NewLocation)), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);

            DocumentServiceRec.Location := CopyStr(NewLocation, 1, MaxStrLen(DocumentServiceRec.Location));
            exit(true);
        end;

        exit(false); // Couldn't resolve a location, credentials may be invalid for the target site
    end;

    [NonDebuggable]
    local procedure SetProperties(GetTokenFromCache: Boolean; var DocumentServiceRec: Record "Document Service")
    var
        DocumentServiceCache: Record "Document Service Cache";
        DocumentServiceHelper: DotNet NavDocumentServiceHelper;
        AccessToken: Text;
    begin
        with DocumentServiceRec do begin
            // The Document Service will throw an exception if the property is not known to the service type provider.
            DocumentService.Properties.SetProperty(FieldName(Description), Description);
            DocumentService.Properties.SetProperty(FieldName(Location), Location);
            DocumentService.Properties.SetProperty(FieldName("Document Repository"), "Document Repository");
            DocumentService.Properties.SetProperty(FieldName(Folder), Folder);
            DocumentService.Properties.SetProperty(FieldName("Authentication Type"), "Authentication Type");
            DocumentService.Properties.SetProperty(FieldName("User Name"), "User Name");

            if ("Authentication Type" = "Authentication Type"::Legacy) then begin
                DocumentService.Properties.SetProperty(FieldName(Password), Password);
                DocumentService.Credentials := DocumentServiceHelper.ProvideCredentials;
            end else begin
                if DocumentServiceCache.Get(SystemId) then
                    if GetTokenFromCache then
                        GetTokenFromCache := DocumentServiceCache."Use Cached Token";

                GetAccessToken(Location, AccessToken, GetTokenFromCache);
                DocumentService.Properties.SetProperty('Token', AccessToken);
            end;

            if not (DocumentServiceHelper.LastErrorMessage = '') then
                Error(DocumentServiceHelper.LastErrorMessage);
        end;
    end;

    procedure GetMyBusinessCentralFilesLink(): Text
    var
        DocumentServiceFolder: Text;
        DriveRootFolderJson: JsonObject;
        DriveBcFolderJson: JsonObject;
        DriveFolderUrl: Text;
        WebUrl: Text;
        ProgressDialog: Dialog;
    begin
        Session.LogMessage('0000FMJ', StartingLinkGenerationTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);

        ProgressDialog.Open('#1##############################');

        ProgressDialog.Update(1, CheckingDriveProgressTxt);
        GetDriveFolderInfo(GetGraphDriveRootUrl(), DriveRootFolderJson);

        ProgressDialog.Update(1, CheckingBcDocumentFolderProgressTxt);
        // Try to open the company specific folder. If it does not exist, open the document service folder. Otherwise, show a dialog and fall back.
        DocumentServiceFolder := GetDocumentServiceFolder() + '/' + GetSafeCompanyName();
        DriveFolderUrl := MakeChildrenPathUrl(GetGraphDriveRootUrl(), DocumentServiceFolder);
        if GetDriveFolderInfo(DriveFolderUrl, DriveBcFolderJson) then
            if ExtractWebUrlFromJson(DriveBcFolderJson, WebUrl) then
                exit(WebUrl);

        Session.LogMessage('0000FN5', NoCompanyFolderTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
        DocumentServiceFolder := GetDocumentServiceFolder();
        DriveFolderUrl := MakeChildrenPathUrl(GetGraphDriveRootUrl(), DocumentServiceFolder);
        if GetDriveFolderInfo(DriveFolderUrl, DriveBcFolderJson) then
            if ExtractWebUrlFromJson(DriveBcFolderJson, WebUrl) then
                exit(WebUrl);

        Session.LogMessage('0000FN6', NoCompanyOrBcFolderTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
        if ExtractWebUrlFromJson(DriveRootFolderJson, WebUrl) then
            exit(WebUrl);
    end;

    [TryFunction]
    local procedure ExtractWebUrlFromJson(DriveBcFolderJson: JsonObject; var WebUrl: Text)
    var
        DriveWebUrlJson: JsonToken;
    begin
        if DriveBcFolderJson.Get('webUrl', DriveWebUrlJson) then
            if DriveWebUrlJson.IsValue then begin
                WebUrl := DriveWebUrlJson.AsValue().AsText();
                exit;
            end;

        Error('');
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure GetDriveFolderInfo(FolderUrl: Text; var FolderJson: JsonObject)
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        AzureADMgt: Codeunit "Azure AD Mgt.";
        Token: Text;
        ResponseBody: Text;
        ErrorMessage: Text;
        ErrorDetails: Text;
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
    begin
        Token := AzureADMgt.GetAccessToken(GetGraphDomain(), AzureADMgt.GetO365ResourceName(), false);
        if Token = '' then begin
            Session.LogMessage('0000FMK', EmptyTokenTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            LicenseError();
        end;

        HttpWebRequestMgt.Initialize(FolderUrl);
        HttpWebRequestMgt.DisableUI();
        HttpWebRequestMgt.SetMethod('GET');
        HttpWebRequestMgt.SetReturnType('application/json');
        HttpWebRequestMgt.AddHeader('Authorization', 'Bearer ' + Token);

        if not HttpWebRequestMgt.SendRequestAndReadTextResponse(ResponseBody, ErrorMessage, ErrorDetails, HttpStatusCode, ResponseHeaders) then begin
            Session.LogMessage('0000FML', StrSubstNo(SharepointStatusCodeTelemetryMsg, HttpStatusCode), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);

            if HttpStatusCode in [401, 403, 404] then
                LicenseError()
            else
                Error(SharepointUnexpectedStatusCodeErr, HttpStatusCode);
        end;

        if not FolderJson.ReadFrom(ResponseBody) then
            Error(SharepointInvalidJsonErr, ResponseBody);
    end;

    local procedure LicenseError()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then
            Error(MissingOneDriveLicenseSaasErr)
        else
            Error(MissingOneDriveLicenseOnPremErr, ProductName.Short());
    end;

    local procedure GetDocumentServiceFolder(): Text
    var
        DocumentServiceRec: Record "Document Service";
        EnvironmentInformation: Codeunit "Environment Information";
        DummyDocumentServiceConfig: Page "Document Service Config";
    begin
        if IsConfigured() then begin
            DocumentServiceRec.FindFirst();
            Session.LogMessage('0000FMM', UsingCustomDocumentServiceTelemetryMsg, Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            exit(DocumentServiceRec.Folder);
        end;

        if EnvironmentInformation.IsSaaSInfrastructure() then begin
            Session.LogMessage('0000FMN', UsingDefaultDocumentServiceTelemetryMsg, Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            exit(GetDefaultFolderName());
        end;

        Error(NoDocumentServiceFoundErr, ProductName.Short(), DummyDocumentServiceConfig.Caption());
    end;

    local procedure GetGraphDriveRootUrl(): Text
    var
        Domain: Text;
    begin
        Domain := GetGraphDomain();

        Domain := DelChr(Domain, '>', '/');
        exit(Domain + '/v1.0/me/drive/root')
    end;

    local procedure GetGraphSiteRootUrl(): Text
    var
        Domain: Text;
    begin
        Domain := GetGraphDomain();

        Domain := DelChr(Domain, '>', '/');
        exit(Domain + '/v1.0/sites/root')
    end;

    local procedure MakeChildrenPathUrl(RootDriveUrl: Text; FolderString: Text): Text
    var
        Uri: Codeunit Uri;
        Folders: List of [Text];
        Folder: Text;
    begin
        // From: https://docs.microsoft.com/en-us/onedrive/developer/rest-api/?view=odsp-graph-online#path-based-addressing-within-a-drive
        // A driveItem can be addressed by either a unique identifier or where that item exists in the drive's hierarchy (i.e. user path).
        // Within an API request, a colon can be used to shift between API path space and user path space.
        // Ensure user data within the URL follows the addressing and path encoding requirements.
        // Examples:
        // /drive/root:/path/to/file                          -> Access a driveItem by path under the root.

        Folders := FolderString.Split('/');
        RootDriveUrl := DelChr(RootDriveUrl, '>', '/') + ':';

        foreach Folder in Folders do
            if Folder <> '' then
                RootDriveUrl := RootDriveUrl + '/' + Uri.EscapeDataString(Folder);

        exit(RootDriveUrl);
    end;

    local procedure GetGraphDomain(): Text
    var
        UrlHelper: Codeunit "Url Helper";
        Domain: Text;
    begin
        Domain := UrlHelper.GetGraphUrl();
        if Domain = '' then
            Domain := GraphApiUrlOnPremTxt; // This fallback is needed for OnPremise

        exit(Domain)
    end;

    local procedure SetDocumentService()
    var
        RequestedServiceType: Text;
    begin
        // Sets the Document Service for the current Service Type, reusing an existing service if possible.

        RequestedServiceType := GetServiceType;

        if RequestedServiceType = '' then
            RequestedServiceType := 'SHAREPOINTONLINE';

        if LastServiceType <> RequestedServiceType then begin
            DocumentService := DocumentServiceFactory.CreateService(RequestedServiceType);
            LastServiceType := RequestedServiceType;
        end;
    end;

    local procedure CheckError()
    begin
        // Checks whether the Document Service received an error and displays that error to the user.

        if not IsNull(DocumentService.LastError) and (DocumentService.LastError.Message <> '') then
            Error(DocumentService.LastError.Message);
    end;

    [TryFunction]
    local procedure TrySaveStreamFromRec(Stream: InStream; TargetName: Text; ConflictBehavior: Enum "Doc. Service Conflict Behavior"; var DocumentServiceRec: Record "Document Service"; var DocumentUri: Text; var UploadedFileName: Text)
    var
        LocalDocumentService: Record "Document Service";
        DotNetConflictBehavior: DotNet ConflictBehavior;
        DotNetUploadedDocument: DotNet UploadedDocument;
    begin
        Session.LogMessage('0000FTC', StrSubstNo(TrySaveStreamFromRecTelemetryMsg, Format(ConflictBehavior)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
        Clear(DocumentUri);

        // Saves a stream to the Document Service using the configured location specified in Dynamics NAV.
        SetDocumentService();

        if DocumentServiceRec."Service ID" <> '' then
            SetProperties(true, DocumentServiceRec)
        else begin
            if not LocalDocumentService.FindFirst() then
                Error(NoConfigErr);

            SetProperties(true, LocalDocumentService);
        end;

        DotNetConflictBehavior := ConflictBehavior.AsInteger();
        DotNetUploadedDocument := DocumentService.Save(Stream, TargetName, DotNetConflictBehavior);
        CheckError;

        UploadedFileName := TargetName;
        if not IsNull(DotNetUploadedDocument) then begin
            if not IsNull(DotNetUploadedDocument.Uri) then
                DocumentUri := DotNetUploadedDocument.Uri.AbsoluteUri;
            if not IsNull(DotNetUploadedDocument.FileName) then
                UploadedFileName := DotNetUploadedDocument.FileName;
        end;
    end;

    local procedure SaveStream(Stream: InStream; TargetName: Text; ConflictBehavior: Enum "Doc. Service Conflict Behavior") DocumentUri: Text
    var
        DocumentServiceRec: Record "Document Service";
        UploadedFileName: Text;
    begin
        TrySaveStreamFromRec(Stream, TargetName, ConflictBehavior, DocumentServiceRec, DocumentUri, UploadedFileName);
    end;

    [NonDebuggable]
    local procedure GetAccessToken(Location: Text; var AccessToken: Text; GetTokenFromCache: Boolean)
    var
        OAuth2: Codeunit OAuth2;
        PromptInteraction: Enum "Prompt Interaction";
        Scopes: List of [Text];
        ClientId: Text;
        ClientSecret: Text;
        RedirectURL: Text;
        AuthError: Text;
    begin
        Session.LogMessage('0000FSI', StrSubstNo(TokenRequestTxt, Format(GetTokenFromCache)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
        GetScopes(Location, Scopes);
        ClientId := GetClientId();
        ClientSecret := GetClientSecret();
        RedirectURL := GetRedirectURL();

        if GetTokenFromCache then
            OAuth2.AcquireAuthorizationCodeTokenFromCache(ClientId, ClientSecret, RedirectURL, OAuthAuthorityUrlLbl, Scopes, AccessToken);
        if AccessToken <> '' then
            exit;

        Session.LogMessage('0000DB7', AccessTokenAcquiredFromCacheErr, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
        OAuth2.AcquireTokenByAuthorizationCode(
                    ClientId,
                    ClientSecret,
                    OAuthAuthorityUrlLbl,
                    RedirectURL,
                    Scopes,
                    PromptInteraction::"Select Account",
                    AccessToken,
                    AuthError
                );

        if AccessToken = '' then begin
            Session.LogMessage('0000DB8', StrSubstNo(AuthTokenOrCodeNotReceivedErr, AuthError), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            Error(AccessTokenErrMsg);
        end;
    end;

    [NonDebuggable]
    local procedure GetClientId(): Text
    var
        DocumentServiceRec: Record "Document Service";
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
        ClientId: Text;
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then
            if not AzureKeyVault.GetAzureKeyVaultSecret(SharePointClientIdAKVSecretNameLbl, ClientId) then
                Session.LogMessage('0000DB9', MissingClientIdTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt)
            else begin
                Session.LogMessage('0000DBA', InitializedClientIdTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
                exit(ClientId);
            end;

        if DocumentServiceRec.FindFirst() then begin
            ClientId := DocumentServiceRec."Client Id";
            OnGetSharePointClientId(ClientId);
            if ClientId <> '' then begin
                Session.LogMessage('0000DBB', InitializedClientIdTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
                exit(ClientId);
            end;
        end;

        Error(MissingClientIdOrSecretErr);
    end;

    [NonDebuggable]
    local procedure GetClientSecret(): Text
    var
        DocumentServiceRec: Record "Document Service";
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
        ClientSecret: Text;
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then
            if not AzureKeyVault.GetAzureKeyVaultSecret(SharePointClientSecretAKVSecretNameLbl, ClientSecret) then
                Session.LogMessage('0000DBC', MissingClientSecretTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt)
            else begin
                Session.LogMessage('0000DBD', InitializedClientSecretTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
                exit(ClientSecret);
            end;

        if not DocumentServiceRec.IsEmpty() then begin
            ClientSecret := GetClientSecretFromIsolatedStorage();
            if ClientSecret <> '' then begin
                Session.LogMessage('0000DBE', InitializedClientSecretTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
                exit(ClientSecret);
            end;
        end;

        OnGetSharePointClientSecret(ClientSecret);
        if ClientSecret <> '' then begin
            Session.LogMessage('0000DBF', InitializedClientSecretTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            exit(ClientSecret);
        end;

        Error(MissingClientIdOrSecretErr);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    local procedure GetRedirectURL(): Text
    var
        DocumentServiceRec: Record "Document Service";
        EnvironmentInformation: Codeunit "Environment Information";
        RedirectURL: Text;
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then
            exit(RedirectURL);

        if DocumentServiceRec.FindFirst() then
            RedirectURL := DocumentServiceRec."Redirect URL";

        if RedirectURL = '' then
            OnGetSharePointRedirectURL(RedirectURL);

        exit(RedirectURL);
    end;

    [NonDebuggable]
    local procedure GetScopes(Location: Text; var Scopes: List of [Text])
    begin
        Scopes.Add(Location.Substring(1, Location.IndexOf('.com') + 3) + '/AllSites.FullControl');
        Scopes.Add(Location.Substring(1, Location.IndexOf('.com') + 3) + '/User.ReadWrite.All');
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    internal procedure SetClientSecret(ClientSecret: Text)
    var
        DocumentServiceRec: Record "Document Service";
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
    begin
        if not DocumentServiceRec.FindFirst() then
            Error(NoConfigErr);

        if ClientSecret = '' then
            if not IsNullGuid(DocumentServiceRec."Client Secret Key") then begin
                IsolatedStorageManagement.Delete(DocumentServiceRec."Client Secret Key", DATASCOPE::Company);
                exit;
            end;

        if IsNullGuid(DocumentServiceRec."Client Secret Key") then begin
            DocumentServiceRec."Client Secret Key" := CreateGuid();
            DocumentServiceRec.Modify();
        end;

        IsolatedStorageManagement.Set(DocumentServiceRec."Client Secret Key", ClientSecret, DATASCOPE::Company);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    local procedure GetClientSecretFromIsolatedStorage(): Text
    var
        DocumentServiceRec: Record "Document Service";
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        ClientSecret: Text;
    begin
        if not DocumentServiceRec.FindFirst() then
            Error(NoConfigErr);

        if IsNullGuid(DocumentServiceRec."Client Secret Key") or
           not IsolatedStorage.Contains(DocumentServiceRec."Client Secret Key", DATASCOPE::Company)
        then begin
            Session.LogMessage('0000DBG', SharePointIsoStorageSecretNotConfiguredLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            Error(SharePointIsoStorageSecretNotConfiguredErr);
        end;

        IsolatedStorageManagement.Get(DocumentServiceRec."Client Secret Key", DATASCOPE::Company, ClientSecret);
        exit(ClientSecret);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    [TryFunction]
    internal procedure TryGetClientSecretFromIsolatedStorage(var ClientSecret: Text)
    begin
        ClientSecret := GetClientSecretFromIsolatedStorage();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OnOpenInExcel', '', false, false)]
    [NonDebuggable]
    local procedure OnTryAcquireAccessTokenOnOpenInExcel(Location: Text)
    var
        DocumentServiceRec: Record "Document Service";
        DocumentServiceCache: Record "Document Service Cache";
        GetTokenFromCache: Boolean;
        Token: Text;
    begin
        if DocumentServiceRec.FindFirst() and DocumentServiceCache.Get(DocumentServiceRec.SystemId) then
            GetTokenFromCache := DocumentServiceCache."Use Cached Token"
        else
            GetTokenFromCache := true;

        GetAccessToken(Location, Token, GetTokenFromCache);
        Session.SetDocumentServiceToken(Token);

        if (not IsNullGuid(DocumentServiceRec.SystemId)) and (not DocumentServiceCache."Use Cached Token") then
            EnsureDocumentServiceCache(DocumentServiceRec, true);
    end;

    local procedure CreateDocumentServiceCache(var DocumentServiceCache: Record "Document Service Cache"; DocumentService: Record "Document Service"; UseCache: Boolean)
    begin
        DocumentServiceCache."Document Service Id" := DocumentService.SystemId;
        DocumentServiceCache."Use Cached Token" := UseCache;
        DocumentServiceCache.Insert();
    end;

    local procedure EnsureDocumentServiceCache(DocumentService: Record "Document Service"; UseCache: Boolean)
    var
        DocumentServiceCache: Record "Document Service Cache";
    begin
        DocumentServiceCache.Init();
        DocumentServiceCache."Document Service Id" := DocumentService.SystemId;
        DocumentServiceCache."Use Cached Token" := UseCache;
        if not DocumentServiceCache.Modify() then
            DocumentServiceCache.Insert();
    end;

    procedure OpenInOneDrive(FileName: Text; FileExtension: Text; InStream: InStream)
    var
        DocumentSharing: Codeunit "Document Sharing";
    begin
        DocumentSharing.Share(FileName, FileExtension, InStream, Enum::"Document Sharing Intent"::Open);
    end;

    procedure OpenInOneDriveFromMedia(FileName: Text; FileExtension: Text; MediaId: Guid)
    var
        DocumentSharingIntent: Enum "Document Sharing Intent";
    begin
        InvokeDocumentSharingFlowFromMedia(FileName, FileExtension, MediaId, DocumentSharingintent::Open);
    end;

    procedure ShareWithOneDrive(FileName: Text; FileExtension: Text; InStream: InStream)
    var
        DocumentSharing: Codeunit "Document Sharing";
    begin
        DocumentSharing.Share(FileName, FileExtension, InStream, Enum::"Document Sharing Intent"::Share);
    end;

    procedure ShareWithOneDriveFromMedia(FileName: Text; FileExtension: Text; MediaId: Guid)
    var
        DocumentSharingIntent: Enum "Document Sharing Intent";
    begin
        InvokeDocumentSharingFlowFromMedia(FileName, FileExtension, MediaId, DocumentSharingintent::Share);
    end;

    local procedure InvokeDocumentSharingFlowFromMedia(FileName: Text; FileExtension: Text; MediaId: Guid; DocumentSharingIntent: Enum "Document Sharing Intent")
    var
        TempDocumentSharing: Record "Document Sharing" temporary;
        TenantMedia: Record "Tenant Media";
    begin
        SetFileNameAndExtension(TempDocumentSharing, FileName, FileExtension);

        TenantMedia.Get(MediaId);
        TenantMedia.CalcFields(Content);
        TempDocumentSharing.Data := TenantMedia.Content;
        TempDocumentSharing."Document Sharing Intent" := DocumentSharingIntent;
        TempDocumentSharing.Insert();
        Codeunit.Run(Codeunit::"Document Sharing", TempDocumentSharing);
    end;

    local procedure InitTempDocumentServiceRecord(var TempDocumentServiceRec: Record "Document Service" temporary)
    var
        DocumentServiceRec: Record "Document Service";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not IsConfigured() and EnvironmentInformation.IsSaaSInfrastructure() then begin
            Session.LogMessage('0000FK0', DocumentServiceDefaultingLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);
            InitializeDefaultService(TempDocumentServiceRec, 'SHARE');
        end else begin
            if not DocumentServiceRec.FindFirst() then
                Error(CantFindMySiteErr);

            TempDocumentServiceRec.TransferFields(DocumentServiceRec);
        end;

        Clear(TempDocumentServiceRec."User Name"); // Clearing the user name will ensure the NST uploads to the personal store (e.g. OneDrive)
        TempDocumentServiceRec.Folder := CopyStr(TempDocumentServiceRec.Folder + '/' + GetSafeCompanyName(), 1, MaxStrLen(TempDocumentServiceRec.Folder));

        if not SetResourceLocation(TempDocumentServiceRec) then
            Error(CantFindMySiteErr);
    end;

    local procedure SetFileNameAndExtension(var TempDocumentSharing: Record "Document Sharing" temporary; FileName: Text; FileExtension: Text)
    begin
        TempDocumentSharing.Name := CopyStr(FileName, 1, MaxStrLen(TempDocumentSharing.Name) - StrLen(FileExtension)) + FileExtension;
        TempDocumentSharing.Extension := CopyStr(FileExtension, 1, MaxStrLen(TempDocumentSharing.Extension));
    end;

    internal procedure GetTelemetryCategory(): Text
    begin
        exit(DocumentServiceCategoryLbl);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Service", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyDocumentService(var Rec: Record "Document Service"; var xRec: Record "Document Service"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        EnsureDocumentServiceCache(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Service", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertDocumentService(var Rec: Record "Document Service"; RunTrigger: Boolean)
    var
        DocumentServiceCache: Record "Document Service Cache";
    begin
        if Rec.IsTemporary() then
            exit;

        if DocumentServiceCache.Get(Rec.SystemId) then
            exit;

        CreateDocumentServiceCache(DocumentServiceCache, Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Service", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteDocumentService(var Rec: Record "Document Service"; RunTrigger: Boolean)
    var
        DocumentServiceCache: Record "Document Service Cache";
    begin
        if Rec.IsTemporary() then
            exit;

        if DocumentServiceCache.Get(Rec.SystemId) then
            DocumentServiceCache.Delete();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Sharing", 'OnCanUploadDocument', '', false, false)]
    local procedure OnCanUploadDocument(var CanUpload: Boolean)
    var
        EnvironmentInformation: Codeunit "Environment Information";
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
    begin
        if CanUpload then
            exit;

        if PrivacyNotice.IsApprovalStateDisagreed(PrivacyNoticeRegistrations.GetOneDrivePrivacyNoticeId()) then
            exit;

        CanUpload := IsConfigured() or EnvironmentInformation.IsSaaSInfrastructure();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Sharing", 'OnUploadDocument', '', false, false)]
    local procedure OnUploadDocument(var DocumentSharing: Record "Document Sharing" temporary; var Handled: Boolean)
    var
        TempDocumentServiceRec: Record "Document Service" temporary;
        EnvironmentInformation: Codeunit "Environment Information";
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
        DocumentUri: Text;
        UploadedFileName: Text;
        InStr: InStream;
        OutStr: OutStream;
    begin
        if Handled then
            exit;

        Session.LogMessage('0000FJZ', DocumentSharingStartLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);

        if not IsConfigured() and (not EnvironmentInformation.IsSaaSInfrastructure()) then begin
            Handled := False;
            exit;
        end;

        if not PrivacyNotice.ConfirmPrivacyNoticeApproval(PrivacyNoticeRegistrations.GetOneDrivePrivacyNoticeId()) then
            exit;

        InitTempDocumentServiceRecord(TempDocumentServiceRec);

        if DocumentSharing.Name = '' then
            Error(DocumentSharingNoNameErr);

        if DocumentSharing.Extension = '' then
            Error(DocumentSharingNoExtErr);

        DocumentSharing.CalcFields(DocumentSharing.Data);
        DocumentSharing.Data.CreateInStream(InStr);

        if not GuiAllowed() then
            TrySaveStreamFromRec(InStr, DocumentSharing.Name, Enum::"Doc. Service Conflict Behavior"::Fail, TempDocumentServiceRec, DocumentUri, UploadedFileName)
        else
            if not TrySaveStreamFromRec(InStr, DocumentSharing.Name, Enum::"Doc. Service Conflict Behavior"::Fail, TempDocumentServiceRec, DocumentUri, UploadedFileName)
                or (DocumentUri = '')
            then
                case StrMenu(SharePointFileExistsOptionsTxt, 0, StrSubstNo(SharePointFileExistsInstructionsTxt, DocumentSharing.Name, ProductName.Short())) of
                    0: // Cancel
                        begin
                            Handled := false;
                            exit;
                        end;
                    1: // Replace
                        TrySaveStreamFromRec(InStr, DocumentSharing.Name, Enum::"Doc. Service Conflict Behavior"::Replace, TempDocumentServiceRec, DocumentUri, UploadedFileName);
                    2: // Keep both
                        TrySaveStreamFromRec(InStr, DocumentSharing.Name, Enum::"Doc. Service Conflict Behavior"::Rename, TempDocumentServiceRec, DocumentUri, UploadedFileName);
                end;
        EnsureDocumentServiceCache(TempDocumentServiceRec, true);

        DocumentSharing.Name := CopyStr(UploadedFileName, 1, MaxStrLen(DocumentSharing.Name));
        DocumentSharing.DocumentUri := CopyStr(DocumentUri, 1, MaxStrLen(DocumentSharing.DocumentUri));

        DocumentSharing.Token.CreateOutStream(OutStr);
        OutStr.WriteText(DocumentService.Properties.GetProperty('Token'));

        DocumentSharing.DocumentPreviewUri := CopyStr(
            DocumentService.GenerateViewableDocumentAddress(DocumentSharing.DocumentUri),
            1,
            MaxStrLen(DocumentSharing.DocumentPreviewUri));

        if DocumentService.Properties.IsPropertySet('DocumentRootLocation') then
            DocumentSharing.DocumentRootUri := DocumentService.Properties.GetProperty('DocumentRootLocation');

        DocumentSharing.Modify();

        Handled := DocumentSharing.DocumentUri <> '';
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSharePointClientId(var ClientId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSharePointClientSecret(var ClientSecret: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSharePointRedirectURL(var RedirectURL: Text)
    begin
    end;
}

