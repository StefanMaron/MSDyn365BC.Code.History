codeunit 7202 "CDS Discoverability Oauth"
{

    SingleInstance = true;

    var
        RequestTokenUrlTxt: Label 'https://login.microsoftonline.com/common/oauth2', Locked = true;
        ScopeTxt: Label 'user_impersonation', Locked = true;
        ConsumerKeyTxt: Label 'globaldisco-clientid', Locked = true;
        ConsumerSecretTxt: Label 'globaldisco-clientsecret', Locked = true;
        ResourceUrlTxt: Label 'globaldisco-resourceurl', Locked = true;
        GlobalDiscoOauthCategoryLbl: Label 'Global Discoverability OAuth', Locked = true;
        MissingKeySecretResourceErr: Label 'The consumer key secret or resource URL have not been initialized and are missing from the Azure Key Vault.';
        MissingStateErr: Label 'The returned authorization code is missing information about the returned state.';
        MismatchingStateErr: Label 'The authroization code returned state is missmatching the expected state value.';
        ConsumerKey: Text;
        ConsumerSecret: Text;
        ResourceUrl: Text;
        ExpectedState: Text;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure StartAuthorizationProcess(): Text
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureADMgt: Codeunit "Azure AD Mgt.";
        CallbackUrl: Text;
        AuthRequestUrl: Text;
    begin

        ExpectedState := Format(CreateGuid(), 0, 4);

        if ConsumerKey = '' then
            if not AzureKeyVault.GetAzureKeyVaultSecret(ConsumerKeyTxt, ConsumerKey) then;

        if ConsumerSecret = '' then
            if not AzureKeyVault.GetAzureKeyVaultSecret(ConsumerSecretTxt, ConsumerSecret) then;

        if ResourceUrl = '' then
            if not AzureKeyVault.GetAzureKeyVaultSecret(ResourceUrlTxt, ResourceUrl) then;

        CallbackUrl := AzureADMgt.GetRedirectUrl();
        CallbackUrl := GetCallbackUrlNoEnvironment(CallbackUrl);

        if (ConsumerKey = '') OR (ConsumerSecret = '') OR (ResourceUrl = '') then begin
            SendTraceTag('0000BFG', GlobalDiscoOauthCategoryLbl, Verbosity::Error, MissingKeySecretResourceErr, DataClassification::SystemMetadata);
            exit('');
        end;

        if not GetAuthRequestUrl(ConsumerKey, ConsumerSecret, ScopeTxt, RequestTokenUrlTxt, CallbackUrl, ExpectedState, ResourceUrl, AuthRequestUrl) then
            exit('');

        exit(AuthRequestUrl);
    end;

    local procedure GetCallbackUrlNoEnvironment(CallbackUrl: Text): Text
    var
        NewCallbackUrl: Text;
    begin
        NewCallbackUrl := CopyStr(CallbackUrl, 1, 8);
        CallbackUrl := CopyStr(CallbackUrl, 9);
        if StrPos(CallbackUrl, '/') = 0 then
            exit(NewCallbackUrl + CallbackUrl);
        NewCallbackUrl += CopyStr(CallbackUrl, 1, StrPos(CallbackUrl, '/') - 1);
        CallbackUrl := CopyStr(CallbackUrl, StrPos(CallbackUrl, '/') + 1);
        if StrPos(CallbackUrl, '/') > 0 then
            NewCallbackUrl += CopyStr(CallbackUrl, StrPos(CallbackUrl, '/'))
        else
            if CallbackUrl <> '' then
                NewCallbackUrl += '/' + CallbackUrl;

        exit(NewCallbackUrl);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure CompleteAuthorizationProcess(AuthorizationCode: Text; var CDSConnectionSetup: Record "CDS Connection Setup"): Text
    var
        AzureADAuthFlow: Codeunit "Azure AD Auth Flow";
        AzureADMgt: Codeunit "Azure AD Mgt.";
        CallbackUrl: Text;
        State: Text;
        AuthCode: Text;
        AccessTokenKey: Text;
    begin
        if not GetOAuthProperties(AuthorizationCode, AuthCode, State) then begin
            SendTraceTag('0000BFH', GlobalDiscoOauthCategoryLbl, Verbosity::Error, MissingStateErr, DataClassification::SystemMetadata);
            exit;
        end;

        if (ExpectedState <> State) then begin
            SendTraceTag('0000BFI', GlobalDiscoOauthCategoryLbl, Verbosity::Error, MismatchingStateErr, DataClassification::SystemMetadata);
            exit;
        end;

        CallbackUrl := AzureADMgt.GetRedirectUrl();
        CallbackUrl := GetCallbackUrlNoEnvironment(CallbackUrl);
        AzureADAuthFlow.Initialize(CallbackUrl);

        AccessTokenKey :=
                AzureADAuthFlow.AcquireTokenByAuthorizationCodeWithCredentials(AuthCode,
                  ConsumerKey, ConsumerSecret, ResourceUrl);

        exit(AccessTokenKey);
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure GetAuthRequestUrl(ClientId: Text; ClientSecret: Text; Scope: Text; Url: Text; CallBackUrl: Text; State: Text; ResourceUrl: Text; var AuthRequestUrl: Text)
    var
        OAuthAuthorization: DotNet OAuthAuthorization;
        Consumer: DotNet Consumer;
        Token: DotNet Token;
    begin
        Token := Token.Token('', '');
        Consumer := Consumer.Consumer(ClientId, ClientSecret);
        OAuthAuthorization := OAuthAuthorization.OAuthAuthorization(Consumer, Token);
        AuthRequestUrl := OAuthAuthorization.CalculateAuthRequestUrl(Url, CallBackUrl, Scope, State);
        AuthRequestUrl := AuthRequestUrl + '&prompt=consent&resource=' + ResourceUrl;

    end;

    [NonDebuggable]
    local procedure GetOAuthProperties(AuthorizationCode: Text; var CodeOut: Text; var StateOut: Text): Boolean
    var
        JObject: JsonObject;
        JToken: JsonToken;
    begin
        if JObject.ReadFrom(AuthorizationCode) then
            if JObject.Get('code', JToken) then
                if JToken.IsValue() then
                    if JToken.WriteTo(AuthorizationCode) then
                        AuthorizationCode := AuthorizationCode.TrimStart('"').TrimEnd('"');
        CodeOut := GetPropertyFromCode(AuthorizationCode, 'code');
        StateOut := GetPropertyFromCode(AuthorizationCode, 'state');

        if (StateOut = '') then
            exit(false);

        exit(true);
    end;

    [NonDebuggable]
    local procedure GetPropertyFromCode(CodeTxt: Text; Property: Text) Value: Text
    var
        I: Integer;
        NumberOfProperties: Integer;
    begin
        CodeTxt := ConvertStr(CodeTxt, '&', ',');
        CodeTxt := ConvertStr(CodeTxt, '=', ',');
        NumberOfProperties := Round((StrLen(CodeTxt) - StrLen(DelChr(CodeTxt, '=', ','))) / 2, 1, '>');
        for I := 1 to NumberOfProperties do
            if SelectStr(2 * I - 1, CodeTxt) = Property then
                Value := SelectStr(2 * I, CodeTxt);
    end;

}