codeunit 7203 "CDS Environment"
{
    Access = Internal;

    trigger OnRun();
    begin
    end;

    var
        OAuthAuthorityUrlAuthCodeTxt: Label 'https://login.microsoftonline.com/common/oauth2', Locked = true;
        ScopesLbl: Label 'https://globaldisco.crm.dynamics.com/user_impersonation', Locked = true;
        GlobalDiscoOauthCategoryLbl: Label 'Global Discoverability OAuth', Locked = true;
        MissingKeyErr: Label 'The consumer key has not been initialized and are missing from the Azure Key Vault.';
        MissingSecretErr: Label 'The consumer secret has not been initialized and are missing from the Azure Key Vault.';
        ReceivedEmptyOnBehalfOfTokenErr: Label 'The On-Behalf-Of authorization for the current user to the Global Discoverability service has failed - the token returned is empty.', Locked = true;
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        SelectedDefaultEnvironmentTxt: Label 'Selected the default environment: %1', Locked = true, Comment = '%1 = The URL of the by default selected environment';
        SelectedEnvironmentTxt: Label 'Selected environment: %1', Locked = true, Comment = '%1 = The URL of the selected environment';
        ReceivedEmptyAuthCodeTokenErr: Label 'The auth code authorization for the current user to the Global Discoverability service has failed - the token returned is empty.', Locked = true;
        AcquiringAuthCodeTokenWithCertificateTxt: Label 'Attempting to acquire a token for Global Discoverability via authorization code flow, with app id and SNI certificate.', Locked = true;
        RequestFailedTxt: Label 'Request failed', Locked = true;
        CannotReadResponseTxt: Label 'Cannot read response.', Locked = true;
        CannotParseResponseTxt: Label 'Cannot parse response.', Locked = true;
        CannotInsertEnvironmentTxt: Label 'Cannot insert environment.', Locked = true;
        EnvironmentUrlEmptyTxt: Label 'Environment URL is empty.', Locked = true;
        NoEnvironmentsWhenUrlNotEmptyMsg: Label 'No Dataverse environments were discovered.';
        NoEnvironmentsWhenUrlEmptyMsg: Label 'No Dataverse environments were discovered. Enter the URL of the Dataverse environment to connect to.';
        GlobalDiscoApiUrlTok: Label 'https://globaldisco.crm.dynamics.com/api/discovery/v1.0/Instances', Locked = true;
        RequestFailedWithStatusCodeTxt: Label 'Request failed with status code %1.', Locked = true;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure SelectTenantEnvironment(var CDSConnectionSetup: Record "CDS Connection Setup"; Token: Text; GuiAllowed: Boolean): Boolean
    var
        TempCDSEnvironment: Record "CDS Environment" temporary;
        EnvironmentCount: Integer;
    begin
        if Token = '' then
            exit(false);

        EnvironmentCount := GetCDSEnvironments(TempCDSEnvironment, Token);

        if EnvironmentCount = 0 then begin
            if GuiAllowed then
                if (CDSConnectionSetup."Server Address" <> '') then
                    Message(NoEnvironmentsWhenUrlNotEmptyMsg)
                else
                    Message(NoEnvironmentsWhenUrlEmptyMsg);

            exit(false);
        end;

        if EnvironmentCount = 1 then begin
            TempCDSEnvironment.FindFirst();
            CDSConnectionSetup."Server Address" := TempCDSEnvironment.Url;
            Session.LogMessage('0000BFV', StrSubstNo(SelectedDefaultEnvironmentTxt, TempCDSEnvironment.Url), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit(true);
        end;

        Commit();
        if PAGE.RunModal(PAGE::"CDS Environments", TempCDSEnvironment) = ACTION::LookupOK then begin
            Session.LogMessage('0000AVC', StrSubstNo(SelectedEnvironmentTxt, TempCDSEnvironment.Url), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            CDSConnectionSetup."Server Address" := TempCDSEnvironment.Url;
            exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetGlobalDiscoverabilityToken(): Text
    var
        OAuth2: Codeunit OAuth2;
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        PromptInteraction: Enum "Prompt Interaction";
        Scopes: List of [Text];
        ConsumerKey: Text;
        ConsumerSecret: Text;
        FirstPartyAppId: Text;
        FirstPartyAppCertificate: Text;
        RedirectUrl: Text;
        Token: Text;
        Err: Text;
    begin
        Scopes.Add(ScopesLbl);
        OAuth2.AcquireOnBehalfOfToken(CDSIntegrationImpl.GetRedirectURL(), Scopes, Token);
        if Token <> '' then
            exit(Token);

        Session.LogMessage('0000BRA', ReceivedEmptyOnBehalfOfTokenErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GlobalDiscoOauthCategoryLbl);

        FirstPartyAppId := CDSIntegrationImpl.GetCDSConnectionFirstPartyAppId();
        FirstPartyAppCertificate := CDSIntegrationImpl.GetCDSConnectionFirstPartyAppCertificate();
        RedirectUrl := CDSIntegrationImpl.GetRedirectURL();
        if (FirstPartyappId <> '') and (FirstPartyAppCertificate <> '') then begin
            Session.LogMessage('0000EI6', AcquiringAuthCodeTokenWithCertificateTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GlobalDiscoOauthCategoryLbl);
            OAuth2.AcquireAuthorizationCodeTokenFromCacheWithCertificate(FirstPartyappId, FirstPartyAppCertificate, RedirectUrl, OAuthAuthorityUrlAuthCodeTxt, Scopes, Token);
            if Token = '' then
                OAuth2.AcquireTokenByAuthorizationCodeWithCertificate(FirstPartyappId, FirstPartyAppCertificate, OAuthAuthorityUrlAuthCodeTxt, RedirectUrl, Scopes, PromptInteraction::Login, Token, Err);

            if Token = '' then
                Session.LogMessage('0000EI7', ReceivedEmptyAuthCodeTokenErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GlobalDiscoOauthCategoryLbl);

            exit(Token);
        end;

        ConsumerKey := CDSIntegrationImpl.GetCDSConnectionClientId();
        ConsumerSecret := CDSIntegrationImpl.GetCDSConnectionClientSecret();

        if ConsumerKey = '' then
            Session.LogMessage('0000BRB', MissingKeyErr, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GlobalDiscoOauthCategoryLbl);

        if ConsumerSecret = '' then
            Session.LogMessage('0000BRC', MissingSecretErr, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GlobalDiscoOauthCategoryLbl);

        if (ConsumerKey <> '') AND (ConsumerSecret <> '') then begin
            OAuth2.AcquireAuthorizationCodeTokenFromCache(ConsumerKey, ConsumerSecret, RedirectUrl, OAuthAuthorityUrlAuthCodeTxt, Scopes, Token);
            if Token = '' then
                OAuth2.AcquireTokenByAuthorizationCode(ConsumerKey, ConsumerSecret, OAuthAuthorityUrlAuthCodeTxt, RedirectUrl, Scopes, PromptInteraction::Login, Token, Err);
        end;
        if Token = '' then
            Session.LogMessage('0000C6I', ReceivedEmptyAuthCodeTokenErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GlobalDiscoOauthCategoryLbl);

        exit(Token);
    end;

    [NonDebuggable]
    local procedure GetCDSEnvironments(var TempCDSEnvironment: Record "CDS Environment" temporary; Token: Text): Integer
    var
        TempBlob: Codeunit "Temp Blob";
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        Client: HttpClient;
        ResponseStream: InStream;
        EnvironmentsListLine: Text;
        EnvironmentsList: Text;
        IsSuccessful: Boolean;
        JsonResponse: JsonObject;
        JsonEnvironment: JsonToken;
        JsonEnvironmentList: JsonArray;
        JObject: JsonObject;
        JToken: JsonToken;
        StatusCode: Integer;
        EnvironmentCount: Integer;
    begin
        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', 'Bearer ' + Token);

        RequestMessage.SetRequestUri(GlobalDiscoApiUrlTok);
        RequestMessage.Method('GET');

        Clear(TempBlob);
        TempBlob.CreateInStream(ResponseStream);

        IsSuccessful := Client.Send(RequestMessage, ResponseMessage);

        if not IsSuccessful then begin
            Session.LogMessage('0000AVE', RequestFailedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit(0);
        end;

        if not ResponseMessage.IsSuccessStatusCode() then begin
            StatusCode := ResponseMessage.HttpStatusCode();
            Session.LogMessage('0000B1B', StrSubstNo(RequestFailedWithStatusCodeTxt, StatusCode), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit(0);
        end;

        if not ResponseMessage.Content().ReadAs(ResponseStream) then begin
            Session.LogMessage('0000AVF', CannotReadResponseTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit(0);
        end;

        while not ResponseStream.EOS() do begin
            ResponseStream.ReadText(EnvironmentsListLine);
            EnvironmentsList += EnvironmentsListLine;
        end;

        if not JsonResponse.ReadFrom(EnvironmentsList) then begin
            Session.LogMessage('0000AVG', CannotParseResponseTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit(0);
        end;
        if not JsonResponse.Get('value', JToken) then begin
            Session.LogMessage('0000AVH', CannotParseResponseTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit(0);
        end;
        JsonEnvironmentList := JToken.AsArray();
        foreach JsonEnvironment in JsonEnvironmentList do begin
            JObject := JsonEnvironment.AsObject();

            TempCDSEnvironment.Init();

            if JObject.Get('Url', JToken) then
                TempCDSEnvironment.Url := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempCDSEnvironment.Url));

            if JObject.Get('ApiUrl', JToken) then
                TempCDSEnvironment."API Url" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempCDSEnvironment."API Url"));

            if JObject.Get('FriendlyName', JToken) then
                TempCDSEnvironment."Environment Name" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempCDSEnvironment."Environment Name"));

            if JObject.Get('Id', JToken) then
                Evaluate(TempCDSEnvironment.Id, JToken.AsValue().AsText());

            if JObject.Get('LastUpdated', JToken) then
                TempCDSEnvironment."Last Updated" := JToken.AsValue().AsDateTime();

            if JObject.Get('State', JToken) then
                TempCDSEnvironment.State := JToken.AsValue().AsInteger();

            if JObject.Get('UniqueName', JToken) then
                TempCDSEnvironment."Unique Name" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempCDSEnvironment."Unique Name"));

            if JObject.Get('UrlName', JToken) then
                TempCDSEnvironment."Url Name" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempCDSEnvironment."Url Name"));

            if JObject.Get('Version', JToken) then
                TempCDSEnvironment.Version := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempCDSEnvironment.Version));

            if TempCDSEnvironment.Url = '' then
                Session.LogMessage('0000AVI', EnvironmentUrlEmptyTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok)
            else
                if not TempCDSEnvironment.Insert() then
                    Session.LogMessage('0000AVJ', CannotInsertEnvironmentTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok)
                else
                    EnvironmentCount += 1;
        end;

        exit(EnvironmentCount);
    end;
}