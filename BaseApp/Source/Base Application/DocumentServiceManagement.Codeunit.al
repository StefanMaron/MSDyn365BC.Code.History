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
        SetDocumentService;
        SetProperties(false);
        if DocumentServiceRec.FindFirst() then
            if DocumentServiceRec."Authentication Type" = DocumentServiceRec."Authentication Type"::Legacy then
                if IsNull(DocumentService.Credentials) then
                    Error(ValidateConnectionErr);
        DocumentService.ValidateConnection;
        CheckError;
    end;

    [Scope('OnPrem')]
    procedure SaveFile(SourcePath: Text; TargetName: Text; Overwrite: Boolean): Text
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

        exit(SaveStream(SourceStream, TargetName, Overwrite));
    end;

    procedure IsConfigured(): Boolean
    var
        DocumentServiceRec: Record "Document Service";
    begin
        // Returns TRUE if Dynamics NAV has been configured with a Document Service.

        with DocumentServiceRec do begin
            if Count > 1 then
                Error(MultipleConfigsErr);

            if not FindFirst then
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
            if FindLast then
                if Location <> '' then begin
                    SetDocumentService;
                    SetProperties(true);
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

        SetDocumentService;
        HyperLink(DocumentService.GenerateViewableDocumentAddress(TargetURI));
        CheckError;
    end;

    [NonDebuggable]
    local procedure SetProperties(GetTokenFromCache: Boolean)
    var
        DocumentServiceRec: Record "Document Service";
        DocumentServiceCache: Record "Document Service Cache";
        DocumentServiceHelper: DotNet NavDocumentServiceHelper;
        AccessToken: Text;
    begin
        with DocumentServiceRec do begin
            if not FindFirst then
                Error(NoConfigErr);

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
                if DocumentServiceCache.Get(SystemId) then begin
                    if GetTokenFromCache then
                        GetTokenFromCache := DocumentServiceCache."Use Cached Token";
                end else
                    CreateDocumentServiceCache(DocumentServiceCache, DocumentServiceRec, GetTokenFromCache);

                GetAccessToken(Location, AccessToken, GetTokenFromCache);
                DocumentService.Properties.SetProperty('Token', AccessToken);
                if not DocumentServiceCache."Use Cached Token" then begin
                    DocumentServiceCache."Use Cached Token" := true;
                    DocumentServiceCache.Modify();
                end;
            end;

            if not (DocumentServiceHelper.LastErrorMessage = '') then
                Error(DocumentServiceHelper.LastErrorMessage);
        end;
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

    local procedure SaveStream(Stream: InStream; TargetName: Text; Overwrite: Boolean): Text
    var
        DocumentURI: Text;
    begin
        // Saves a stream to the Document Service using the configured location specified in Dynamics NAV.
        SetDocumentService;
        SetProperties(true);

        DocumentURI := DocumentService.Save(Stream, TargetName, Overwrite);
        CheckError;

        exit(DocumentURI);
    end;

    [NonDebuggable]
    local procedure GetAccessToken(Location: Text; var AccessToken: Text; GetTokenFromCache: Boolean)
    var
        OAuth2: Codeunit OAuth2;
        PromptInteraction: Enum "Prompt Interaction";
        ClientId: Text;
        ClientSecret: Text;
        RedirectURL: Text;
        ResourceURL: Text;
        AuthError: Text;
    begin
        ResourceURL := GetResourceUrl(Location);
        ClientId := GetClientId();
        ClientSecret := GetClientSecret();
        RedirectURL := GetRedirectURL();

        if GetTokenFromCache then
            OAuth2.AcquireAuthorizationCodeTokenFromCache(ClientId, ClientSecret, RedirectURL, OAuthAuthorityUrlLbl, ResourceURL, AccessToken);

        if AccessToken <> '' then
            exit;

        Session.LogMessage('0000DB7', AccessTokenAcquiredFromCacheErr, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
        OAuth2.AcquireTokenByAuthorizationCode(
                    ClientId,
                    ClientSecret,
                    OAuthAuthorityUrlLbl,
                    RedirectURL,
                    ResourceURL,
                    PromptInteraction::Consent,
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
    local procedure GetResourceUrl(Location: Text): Text
    begin
        exit(Location.Substring(1, Location.IndexOf('.com') + 3));
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
        CreateCache: Boolean;
        Token: Text;
    begin
        if DocumentServiceCache.FindFirst() then
            GetTokenFromCache := DocumentServiceCache."Use Cached Token"
        else begin
            GetTokenFromCache := true;
            CreateCache := true;
        end;

        GetAccessToken(Location, Token, GetTokenFromCache);
        Session.SetDocumentServiceToken(Token);

        if CreateCache then begin
            DocumentServiceRec.FindFirst();
            CreateDocumentServiceCache(DocumentServiceCache, DocumentServiceRec, true);
        end;

        if not DocumentServiceCache."Use Cached Token" then begin
            DocumentServiceCache."Use Cached Token" := true;
            DocumentServiceCache.Modify();
        end;
    end;

    local procedure CreateDocumentServiceCache(var DocumentServiceCache: Record "Document Service Cache"; DocumentService: Record "Document Service"; UseCache: Boolean)
    begin
        DocumentServiceCache."Document Service Id" := DocumentService.SystemId;
        DocumentServiceCache."Use Cached Token" := UseCache;
        DocumentServiceCache.Insert();
    end;


    [EventSubscriber(ObjectType::Table, Database::"Document Service", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyDocumentService(var Rec: Record "Document Service"; var xRec: Record "Document Service"; RunTrigger: Boolean)
    var
        DocumentServiceCache: Record "Document Service Cache";
    begin
        if Rec.IsTemporary() then
            exit;

        if DocumentServiceCache.Get(Rec.SystemId) then begin
            if DocumentServiceCache."Use Cached Token" then begin
                DocumentServiceCache."Use Cached Token" := false;
                DocumentServiceCache.Modify();
            end;
        end else
            CreateDocumentServiceCache(DocumentServiceCache, Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Service", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertDocumentService(var Rec: Record "Document Service"; RunTrigger: Boolean)
    var
        DocumentServiceCache: Record "Document Service Cache";
    begin
        if Rec.IsTemporary() then
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

