codeunit 7203 "CDS Environment"
{
    Access = Internal;

    trigger OnRun();
    begin
    end;

    var
        OAuthAuthorityUrlAuthCodeTxt: Label 'https://login.microsoftonline.com/common/oauth2', Locked = true;
        ResourceUrlTxt: Label 'https://globaldisco.crm.dynamics.com', Locked = true;
        ConsumerKeyLbl: Label 'globaldisco-clientid', Locked = true;
        ConsumerSecretLbl: Label 'globaldisco-clientsecret', Locked = true;
        GlobalDiscoOauthCategoryLbl: Label 'Global Discoverability OAuth', Locked = true;
        MissingKeyErr: Label 'The consumer key has not been initialized and are missing from the Azure Key Vault.';
        MissingSecretErr: Label 'The consumer secret has not been initialized and are missing from the Azure Key Vault.';
        ReceivedEmptyOnBehalfOfTokenErr: Label 'The On-Behalf-Of authorization for the current user to the Global Discoverability service has failed - the token returned is empty.', Locked = true;
        CategoryTok: Label 'AL Common Data Service Integration', Locked = true;
        SelectedDefaultEnvironmentTxt: Label 'Selected the default environment: %1', Locked = true, Comment = '%1 = The URL of the by default selected environment';
        SelectedEnvironmentTxt: Label 'Selected environment: %1', Locked = true, Comment = '%1 = The URL of the selected environment';
        ReceivedEmptyAuthCodeTokenErr: Label 'The auth code authorization for the current user to the Global Discoverability service has failed - the token returned is empty.', Locked = true;
        RequestFailedTxt: Label 'Request failed', Locked = true;
        CannotReadResponseTxt: Label 'Cannot read response.', Locked = true;
        CannotParseResponseTxt: Label 'Cannot parse response.', Locked = true;
        CannotInsertEnvironmentTxt: Label 'Cannot insert environment.', Locked = true;
        EnvironmentUrlEmptyTxt: Label 'Environment URL is empty.', Locked = true;
        NoEnvironmentsWhenUrlNotEmptyMsg: Label 'No Common Data Service environments were discovered.';
        NoEnvironmentsWhenUrlEmptyMsg: Label 'No Common Data Service environments were discovered. Please enter the URL of the Common Data Service environment to connect to.';
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
            SendTraceTag('0000BFV', CategoryTok, Verbosity::Normal, StrSubstNo(SelectedDefaultEnvironmentTxt, TempCDSEnvironment.Url), DataClassification::OrganizationIdentifiableInformation);
            exit(true);
        end;

        Commit();
        if PAGE.RunModal(PAGE::"CDS Environments", TempCDSEnvironment) = ACTION::LookupOK then begin
            SendTraceTag('0000AVC', CategoryTok, VERBOSITY::Normal, StrSubstNo(SelectedEnvironmentTxt, TempCDSEnvironment.Url), DataClassification::OrganizationIdentifiableInformation);
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
        AzureKeyVault: Codeunit "Azure Key Vault";
        PromptInteraction: Enum "Prompt Interaction";
        ConsumerKey: Text;
        ConsumerSecret: Text;
        Token: Text;
        Err: Text;
    begin
        OAuth2.AcquireOnBehalfOfToken(CDSIntegrationImpl.GetRedirectURL(), '', Token);

        if Token = '' then begin
            SendTraceTag('0000BRA', GlobalDiscoOauthCategoryLbl, Verbosity::Error, ReceivedEmptyOnBehalfOfTokenErr, DataClassification::SystemMetadata);

            if ConsumerKey = '' then
                if not AzureKeyVault.GetAzureKeyVaultSecret(ConsumerKeyLbl, ConsumerKey) then
                    SendTraceTag('0000BRB', GlobalDiscoOauthCategoryLbl, Verbosity::Normal, MissingKeyErr, DataClassification::SystemMetadata);

            if ConsumerSecret = '' then
                if not AzureKeyVault.GetAzureKeyVaultSecret(ConsumerSecretLbl, ConsumerSecret) then
                    SendTraceTag('0000BRC', GlobalDiscoOauthCategoryLbl, Verbosity::Normal, MissingSecretErr, DataClassification::SystemMetadata);

            if (ConsumerKey <> '') AND (ConsumerSecret <> '') then
                OAuth2.AcquireTokenByAuthorizationCode(ConsumerKey, ConsumerSecret, OAuthAuthorityUrlAuthCodeTxt, CDSIntegrationImpl.GetRedirectURL(), ResourceUrlTxt, PromptInteraction::Login, Token, Err);

            if Token = '' then
                SendTraceTag('0000C6I', GlobalDiscoOauthCategoryLbl, Verbosity::Error, ReceivedEmptyAuthCodeTokenErr, DataClassification::SystemMetadata);
        end;

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
            SendTraceTag('0000AVE', CategoryTok, VERBOSITY::Normal, RequestFailedTxt, DataClassification::SystemMetadata);
            exit(0);
        end;

        if not ResponseMessage.IsSuccessStatusCode() then begin
            StatusCode := ResponseMessage.HttpStatusCode();
            SendTraceTag('0000B1B', CategoryTok, VERBOSITY::Warning, StrSubstNo(RequestFailedWithStatusCodeTxt, StatusCode), DATACLASSIFICATION::SystemMetadata);
            exit(0);
        end;

        if not ResponseMessage.Content().ReadAs(ResponseStream) then begin
            SendTraceTag('0000AVF', CategoryTok, VERBOSITY::Normal, CannotReadResponseTxt, DataClassification::SystemMetadata);
            exit(0);
        end;

        while not ResponseStream.EOS() do begin
            ResponseStream.ReadText(EnvironmentsListLine);
            EnvironmentsList += EnvironmentsListLine;
        end;

        if not JsonResponse.ReadFrom(EnvironmentsList) then begin
            SendTraceTag('0000AVG', CategoryTok, VERBOSITY::Normal, CannotParseResponseTxt, DataClassification::SystemMetadata);
            exit(0);
        end;
        if not JsonResponse.Get('value', JToken) then begin
            SendTraceTag('0000AVH', CategoryTok, VERBOSITY::Normal, CannotParseResponseTxt, DataClassification::SystemMetadata);
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
                SendTraceTag('0000AVI', CategoryTok, VERBOSITY::Normal, EnvironmentUrlEmptyTxt, DataClassification::SystemMetadata)
            else
                if not TempCDSEnvironment.Insert() then
                    SendTraceTag('0000AVJ', CategoryTok, VERBOSITY::Normal, CannotInsertEnvironmentTxt, DataClassification::SystemMetadata)
                else
                    EnvironmentCount += 1;
        end;

        exit(EnvironmentCount);
    end;
}