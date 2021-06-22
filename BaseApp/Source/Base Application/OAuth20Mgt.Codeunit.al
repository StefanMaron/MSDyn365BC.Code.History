codeunit 1140 "OAuth 2.0 Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        AuthRequiredNotificationMsg: Label 'Choose the Request Authorization Code action to complete the authorization process.';
        RequestAuthCodeTxt: Label 'Request authorization code.', Locked = true;
        RequestAccessTokenTxt: Label 'Request access token.', Locked = true;
        RefreshAccessTokenTxt: Label 'Refresh access token.', Locked = true;
        InvokeRequestTxt: Label 'Invoke %1 request.', Comment = '%1 - request type, e.g. GET, POST', Locked = true;
        RefreshSuccessfulTxt: Label 'Refresh token successful.';
        RefreshFailedTxt: Label 'Refresh token failed.';
        AuthorizationSuccessfulTxt: Label 'Authorization successful.';
        AuthorizationFailedTxt: Label 'Authorization failed.';
        ReasonTxt: Label 'Reason: ';
        EncryptionIsNotActivatedQst: Label 'Data encryption is not activated. It is recommended that you encrypt data. \Do you want to open the Data Encryption Management window?';
        ActivityLogContextTxt: Label 'OAuth 2.0', Locked = true;
        AuthorizeTxt: Label 'Authorize';
        LimitExceededTxt: Label 'Http daily request limit is exceeded.', Locked = true;
        EnvironmentBlocksErr: Label 'Environment blocks an outgoing HTTP request to ''%1''.', Comment = '%1 - url, e.g. https://microsoft.com';
        ConnectionErr: Label 'Connection to the remote service ''%1'' could not be established.', Comment = '%1 - url, e.g. https://microsoft.com';

    [EventSubscriber(ObjectType::Page, 1140, 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordPageEvent(var Rec: Record "OAuth 2.0 Setup")
    var
        SetupNotification: Notification;
    begin
        SetupNotification.Id := GetRequestAuthNotificationGUID();
        SetupNotification.Recall();

        if not (Rec.Status in [Rec.Status::Disabled, Rec.Status::Error]) then
            exit;

        SetupNotification.Message := AuthRequiredNotificationMsg;
        SetupNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        SetupNotification.SetData(Rec.FieldName(Code), Rec.Code);
        SetupNotification.AddAction(AuthorizeTxt, CODEUNIT::"OAuth 2.0 Mgt.", 'RequestAuthFromNotification');
        SetupNotification.Send();
    end;

    [Scope('OnPrem')]
    procedure RequestAuthFromNotification(AuthNotification: Notification)
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
    begin
        if not AuthNotification.HasData(OAuth20Setup.FieldName(Code)) then
            exit;

        if not OAuth20Setup.Get(AuthNotification.GetData(OAuth20Setup.FieldName(Code))) then
            exit;

        OAuth20Setup.RequestAuthorizationCode();
    end;

    local procedure GetRequestAuthNotificationGUID(): Guid
    begin
        exit('7CC74E1E-641D-4FCC-A074-1F64CEE53AEA');
    end;

    [NonDebuggable]
    procedure GetAuthorizationURL(OAuth20Setup: Record "OAuth 2.0 Setup"; ClientID: Text): Text
    begin
        with OAuth20Setup do begin
            TestField("Service URL");
            TestField("Authorization URL Path");
            TestField("Authorization Response Type");
            TestField("Access Token URL Path");
            TestField("Client ID");
            TestField(Scope);
            TestField("Redirect URL");

            LogActivity(OAuth20Setup, true, RequestAuthCodeTxt, '', '', '', true);
            exit(
              StrSubstNo(
                '%1%2?response_type=%3&client_id=%4&scope=%5&redirect_uri=%6',
                "Service URL", "Authorization URL Path", "Authorization Response Type", ClientID, Scope, "Redirect URL"));
        end;
    end;

    /// <summary>
    /// Request access token using application/json ContentType.
    /// </summary>
    [NonDebuggable]
    procedure RequestAccessToken(var OAuth20Setup: Record "OAuth 2.0 Setup"; var MessageText: Text; AuthorizationCode: Text; ClientID: Text; ClientSecret: Text; var AccessToken: Text; var RefreshToken: Text): Boolean
    begin
        exit(
            RequestAccessTokenWithGivenRequestJson(
                OAuth20Setup, '', MessageText, AuthorizationCode, ClientID, ClientSecret, AccessToken, RefreshToken));
    end;

    /// <summary>
    /// Request access token using given request json and application/json ContentType.
    /// </summary>
    [NonDebuggable]
    procedure RequestAccessTokenWithGivenRequestJson(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var MessageText: Text; AuthorizationCode: Text; ClientID: Text; ClientSecret: Text; var AccessToken: Text; var RefreshToken: Text) Result: Boolean
    begin
        exit(RequestAccessTokenWithGivenRequestJsonAndContentType(OAuth20Setup, RequestJson, MessageText, AuthorizationCode, ClientID, ClientSecret, AccessToken, RefreshToken, false));
    end;

    /// <summary>
    /// Request access token using application/x-www-form-urlencoded ContentType if UseUrlEncodedContentType is set to true or application/json ContentType otherwise.
    /// </summary>
    [NonDebuggable]
    procedure RequestAccessTokenWithContentType(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var MessageText: Text; AuthorizationCode: Text; ClientID: Text; ClientSecret: Text; var AccessToken: Text; var RefreshToken: Text; UseUrlEncodedContentType: Boolean) Result: Boolean
    begin
        exit(RequestAccessTokenWithGivenRequestJsonAndContentType(OAuth20Setup, RequestJson, MessageText, AuthorizationCode, ClientID, ClientSecret, AccessToken, RefreshToken, UseUrlEncodedContentType));
    end;

    [NonDebuggable]
    local procedure RequestAccessTokenWithGivenRequestJsonAndContentType(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var MessageText: Text; AuthorizationCode: Text; ClientID: Text; ClientSecret: Text; var AccessToken: Text; var RefreshToken: Text; UseUrlEncodedContentType: Boolean) Result: Boolean
    var
        RequestJsonContent: JsonObject;
        RequestUrlContent: Text;
        ResponseJson: Text;
        HttpError: Text;
        ExpireInSec: BigInteger;
    begin
        with OAuth20Setup do begin
            Status := Status::Disabled;
            TestField("Service URL");
            TestField("Access Token URL Path");
            TestField("Client ID");
            TestField("Client Secret");
            TestField("Redirect URL");

            if UseUrlEncodedContentType then begin
                CreateContentRequestForAccessToken(RequestUrlContent, ClientSecret, ClientID, "Redirect URL", AuthorizationCode);
                CreateRequestJSONForAccessRefreshTokenURLEncoded(RequestJson, "Service URL", "Access Token URL Path", RequestUrlContent);
            end else begin
                CreateContentRequestJSONForAccessToken(RequestJsonContent, ClientSecret, ClientID, "Redirect URL", AuthorizationCode);
                CreateRequestJSONForAccessRefreshToken(RequestJson, "Service URL", "Access Token URL Path", RequestJsonContent);
            end;

            Result := RequestAccessAndRefreshTokens(RequestJson, ResponseJson, AccessToken, RefreshToken, ExpireInSec, HttpError);
            SaveResultForRequestAccessAndRefreshTokens(
              OAuth20Setup, MessageText, Result, RequestAccessTokenTxt, AuthorizationSuccessfulTxt,
              AuthorizationFailedTxt, HttpError, RequestJson, ResponseJson, ExpireInSec);
        end;
    end;

    /// <summary>
    /// Refreshes access token using application/json ContentType.
    /// </summary>
    [NonDebuggable]
    procedure RefreshAccessToken(var OAuth20Setup: Record "OAuth 2.0 Setup"; var MessageText: Text; ClientID: Text; ClientSecret: Text; var AccessToken: Text; var RefreshToken: Text): Boolean
    begin
        exit(
            RefreshAccessTokenWithGivenRequestJson(
                OAuth20Setup, '', MessageText, ClientID, ClientSecret, AccessToken, RefreshToken));
    end;

    /// <summary>
    /// Refreshes access token with given request json using application/json ContentType.
    /// </summary>
    [NonDebuggable]
    procedure RefreshAccessTokenWithGivenRequestJson(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var MessageText: Text; ClientID: Text; ClientSecret: Text; var AccessToken: Text; var RefreshToken: Text) Result: Boolean
    begin
        exit(RefreshAccessTokenWithGivenRequestJsonAndContentType(OAuth20Setup, RequestJson, MessageText, ClientID, ClientSecret, AccessToken, RefreshToken, false));
    end;

    /// <summary>
    /// Refreshes access token using application/x-www-form-urlencoded ContentType if UseUrlEncodedContentType is set to true or application/json ContentType otherwise.
    /// </summary>
    [NonDebuggable]
    procedure RefreshAccessTokenWithContentType(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var MessageText: Text; ClientID: Text; ClientSecret: Text; var AccessToken: Text; var RefreshToken: Text; UseUrlEncodedContentType: Boolean): Boolean
    begin
        exit(RefreshAccessTokenWithGivenRequestJsonAndContentType(OAuth20Setup, RequestJson, MessageText, ClientID, ClientSecret, AccessToken, RefreshToken, UseUrlEncodedContentType));
    end;

    [NonDebuggable]
    local procedure RefreshAccessTokenWithGivenRequestJsonAndContentType(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var MessageText: Text; ClientID: Text; ClientSecret: Text; var AccessToken: Text; var RefreshToken: Text; UseUrlEncodedContentType: Boolean) Result: Boolean
    var
        RequestJsonContent: JsonObject;
        RequestUrlContent: Text;
        ResponseJson: Text;
        HttpError: Text;
        ExpireInSec: BigInteger;
    begin
        with OAuth20Setup do begin
            Status := Status::Disabled;
            TestField("Service URL");
            TestField("Refresh Token URL Path");
            TestField("Client ID");
            TestField("Client Secret");
            TestField("Refresh Token");

            if UseUrlEncodedContentType then begin
                CreateContentRequestForRefreshAccessToken(RequestUrlContent, ClientSecret, ClientID, RefreshToken);
                CreateRequestJSONForAccessRefreshTokenURLEncoded(RequestJson, "Service URL", "Refresh Token URL Path", RequestUrlContent);
            end else begin
                CreateContentRequestJSONForRefreshAccessToken(RequestJsonContent, ClientSecret, ClientID, RefreshToken);
                CreateRequestJSONForAccessRefreshToken(RequestJson, "Service URL", "Refresh Token URL Path", RequestJsonContent);
            end;

            Result := RequestAccessAndRefreshTokens(RequestJson, ResponseJson, AccessToken, RefreshToken, ExpireInSec, HttpError);
            SaveResultForRequestAccessAndRefreshTokens(
              OAuth20Setup, MessageText, Result, RefreshAccessTokenTxt, RefreshSuccessfulTxt,
              RefreshFailedTxt, HttpError, RequestJson, ResponseJson, ExpireInSec);
        end;
    end;

    [NonDebuggable]
    local procedure SaveResultForRequestAccessAndRefreshTokens(var OAuth20Setup: Record "OAuth 2.0 Setup"; var MessageText: Text; Result: Boolean; Context: Text; SuccessMsg: Text; ErrorMsg: Text; HttpError: Text; RequestJson: Text; ResponseJson: Text; ExpireInSec: BigInteger)
    begin
        if Result then begin
            MessageText := SuccessMsg;
            OAuth20Setup.Status := OAuth20Setup.Status::Enabled;
            if ExpireInSec > 0 then
                OAuth20Setup."Access Token Due DateTime" := CurrentDateTime() + ExpireInSec * 1000;
        end else begin
            MessageText := ErrorMsg;
            if HttpError <> '' then
                MessageText += '\' + ReasonTxt + HttpError;
            OAuth20Setup.Status := OAuth20Setup.Status::Error;
        end;
        LogActivity(OAuth20Setup, Result, Context, MessageText, RequestJson, ResponseJson, true);
    end;

    [NonDebuggable]
    procedure InvokeRequest(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var ResponseJson: Text; var HttpError: Text; AccessToken: Text; RetryOnCredentialsFailure: Boolean) Result: Boolean
    var
        StatusCode: Integer;
        StatusReason: Text;
        StatusDetails: Text;
    begin
        if RetryOnCredentialsFailure and (OAuth20Setup."Access Token Due DateTime" <> 0DT) then
            if OAuth20Setup."Access Token Due DateTime" < CurrentDateTime() then begin
                if OAuth20Setup.RefreshAccessToken(HttpError) then
                    exit(OAuth20Setup.InvokeRequest(RequestJson, ResponseJson, HttpError, false));
                exit(false);
            end;

        Result := InvokeSingleRequest(OAuth20Setup, RequestJson, ResponseJson, HttpError, AccessToken);
        if not Result and RetryOnCredentialsFailure then
            if GetHttpStatusFromJsonResponse(ResponseJson, StatusCode, StatusReason, StatusDetails) then
                if StatusCode = 401 then // Unauthorized
                    if OAuth20Setup.RefreshAccessToken(HttpError) then
                        exit(OAuth20Setup.InvokeRequest(RequestJson, ResponseJson, HttpError, false));
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure RequestAuthorizationCode(OAuth20Setup: Record "OAuth 2.0 Setup")
    begin
        HyperLink(GetAuthorizationURL(OAuth20Setup, OAuth20Setup.GetToken(OAuth20Setup."Client ID")));
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure RequestAndSaveAccessToken(var OAuth20Setup: Record "OAuth 2.0 Setup"; var MessageText: Text; AuthorizationCode: Text) Result: Boolean
    var
        AccessToken: Text;
        RefreshToken: Text;
    begin
        Result :=
          RequestAccessToken(
            OAuth20Setup, MessageText, AuthorizationCode,
            OAuth20Setup.GetToken(OAuth20Setup."Client ID"), OAuth20Setup.GetToken(OAuth20Setup."Client Secret"),
            AccessToken, RefreshToken);

        if Result then
            SaveTokens(OAuth20Setup, AccessToken, RefreshToken);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure RefreshAndSaveAccessToken(var OAuth20Setup: Record "OAuth 2.0 Setup"; var MessageText: Text) Result: Boolean
    var
        AccessToken: Text;
        RefreshToken: Text;
    begin
        RefreshToken := OAuth20Setup.GetToken(OAuth20Setup."Refresh Token");
        Result :=
          RefreshAccessToken(
            OAuth20Setup, MessageText,
            OAuth20Setup.GetToken(OAuth20Setup."Client ID"), OAuth20Setup.GetToken(OAuth20Setup."Client Secret"),
            AccessToken, RefreshToken);

        if Result then
            SaveTokens(OAuth20Setup, AccessToken, RefreshToken);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure InvokeRequestBasic(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJSON: Text; var ResponseJSON: Text; var HttpError: Text; RetryOnCredentialsFailure: Boolean): Boolean
    begin
        exit(
          InvokeRequest(
            OAuth20Setup, RequestJSON, ResponseJSON, HttpError,
            OAuth20Setup.GetToken(OAuth20Setup."Access Token"), RetryOnCredentialsFailure));
    end;

    [Scope('OnPrem')]
    procedure CheckEncryption()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not EnvironmentInfo.IsSaaS() and not EncryptionEnabled() and GuiAllowed() then
            if Confirm(EncryptionIsNotActivatedQst) then
                Page.RunModal(Page::"Data Encryption Management");
    end;

    [NonDebuggable]
    local procedure InvokeSingleRequest(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var ResponseJson: Text; var HttpError: Text; AccessToken: Text) Result: Boolean
    var
        RequestJObject: JsonObject;
        HeaderJObject: JsonObject;
        JToken: JsonToken;
    begin
        with OAuth20Setup do begin
            TestField("Service URL");
            TestField("Access Token");

            if RequestJObject.ReadFrom(RequestJson) then;
            RequestJObject.Add('ServiceURL', "Service URL");
            HeaderJObject.Add('Authorization', StrSubstNo('Bearer %1', AccessToken));
            if RequestJObject.SelectToken('Header', JToken) then
                JToken.AsObject().Add('Authorization', StrSubstNo('Bearer %1', AccessToken))
            else
                RequestJObject.Add('Header', HeaderJObject);
            RequestJObject.WriteTo(RequestJson);

            if "Latest Datetime" = 0DT then
                "Daily Count" := 0
            else
                if "Latest Datetime" < CreateDateTime(Today(), 0T) then
                    "Daily Count" := 0;
            if ("Daily Limit" <= 0) or ("Daily Count" < "Daily Limit") or ("Latest Datetime" = 0DT) then begin
                Result := InvokeHttpJSONRequest(RequestJson, ResponseJson, HttpError);
                "Latest Datetime" := CurrentDateTime();
                "Daily Count" += 1;
            end else begin
                Result := false;
                HttpError := LimitExceededTxt;
                SendTraceTag('00009YL', ActivityLogContextTxt, Verbosity::Normal, LimitExceededTxt, DataClassification::SystemMetadata);
            end;
            RequestJObject.Get('Method', JToken);
            LogActivity(
                OAuth20Setup, Result, StrSubstNo(InvokeRequestTxt, JToken.AsValue().AsText()),
                HttpError, RequestJson, ResponseJson, false);
        end;
    end;

    [NonDebuggable]
    local procedure SaveTokens(var OAuth20Setup: Record "OAuth 2.0 Setup"; AccessToken: Text; RefreshToken: Text)
    begin
        with OAuth20Setup do begin
            SetToken("Access Token", AccessToken);
            SetToken("Refresh Token", RefreshToken);
            Modify();
            Commit(); // need to prevent rollback to save new keys
        end;
    end;

    [NonDebuggable]
    local procedure RequestAccessAndRefreshTokens(RequestJson: Text; var ResponseJson: Text; var AccessToken: Text; var RefreshToken: Text; var ExpireInSec: BigInteger; var HttpError: Text): Boolean
    begin
        AccessToken := '';
        RefreshToken := '';
        ResponseJson := '';
        if InvokeHttpJSONRequest(RequestJson, ResponseJson, HttpError) then
            exit(ParseAccessAndRefreshTokens(ResponseJson, AccessToken, RefreshToken, ExpireInSec));
    end;

    [NonDebuggable]
    local procedure ParseAccessAndRefreshTokens(ResponseJson: Text; var AccessToken: Text; var RefreshToken: Text; var ExpireInSec: BigInteger) Result: Boolean
    var
        JToken: JsonToken;
        NewAccessToken: Text;
        NewRefreshToken: Text;
    begin
        AccessToken := '';
        RefreshToken := '';
        ExpireInSec := 0;

        if JToken.ReadFrom(ResponseJson) then
            if JToken.SelectToken('Content', JToken) then
                foreach JToken in JToken.AsObject().Values() do
                    case JToken.Path() of
                        'Content.access_token':
                            NewAccessToken := JToken.AsValue().AsText();
                        'Content.refresh_token':
                            NewRefreshToken := JToken.AsValue().AsText();
                        'Content.expires_in':
                            ExpireInSec := JToken.AsValue().AsBigInteger();
                    end;
        if (NewAccessToken = '') or (NewRefreshToken = '') then
            exit(false);

        AccessToken := NewAccessToken;
        RefreshToken := NewRefreshToken;
        exit(true);
    end;

    [NonDebuggable]
    local procedure CreateRequestJSONForAccessRefreshTokenUrlEncoded(var JsonString: Text; ServiceURL: Text; URLRequestPath: Text; Content: Text)
    var
        JObject: JsonObject;
    begin
        if JObject.ReadFrom(JsonString) then;
        JObject.Add('ServiceURL', ServiceURL);
        JObject.Add('Method', 'POST');
        JObject.Add('URLRequestPath', URLRequestPath);
        JObject.Add('Content-Type', 'application/x-www-form-urlencoded');
        JObject.Add('Content', Content);
        JObject.WriteTo(JsonString);
    end;

    [NonDebuggable]
    local procedure CreateRequestJSONForAccessRefreshToken(var JsonString: Text; ServiceURL: Text; URLRequestPath: Text; var ContentJson: JsonObject)
    var
        JObject: JsonObject;
    begin
        if JObject.ReadFrom(JsonString) then;
        JObject.Add('ServiceURL', ServiceURL);
        JObject.Add('Method', 'POST');
        JObject.Add('URLRequestPath', URLRequestPath);
        JObject.Add('Content-Type', 'application/json');
        JObject.Add('Content', ContentJson);
        JObject.WriteTo(JsonString);
    end;

    [NonDebuggable]
    local procedure CreateContentRequestForAccessToken(var UrlString: Text; ClientSecret: Text; ClientID: Text; RedirectURI: Text; AuthorizationCode: Text)
    var
        HttpUtility: DotNet HttpUtility;
    begin
        UrlString := HttpUtility.UrlEncode(StrSubstNo('grant_type=authorization_code&client_secret=%1&client_id=%2&redirect_uri=%3&code=%4',
            ClientSecret, ClientID, RedirectURI, AuthorizationCode));
    end;

    [NonDebuggable]
    local procedure CreateContentRequestJSONForAccessToken(var JObject: JsonObject; ClientSecret: Text; ClientID: Text; RedirectURI: Text; AuthorizationCode: Text)
    begin
        JObject.Add('grant_type', 'authorization_code');
        JObject.Add('client_secret', ClientSecret);
        JObject.Add('client_id', ClientID);
        JObject.Add('redirect_uri', RedirectURI);
        JObject.Add('code', AuthorizationCode);
    end;

    [NonDebuggable]
    local procedure CreateContentRequestForRefreshAccessToken(var UrlString: Text; ClientSecret: Text; ClientID: Text; RefreshToken: Text)
    var
        HttpUtility: DotNet HttpUtility;
    begin
        UrlString := HttpUtility.UrlEncode(StrSubstNo('grant_type=refresh_token&client_secret=%1&client_id=%2&refresh_token=%3',
            ClientSecret, ClientID, RefreshToken));
    end;

    [NonDebuggable]
    local procedure CreateContentRequestJSONForRefreshAccessToken(var JObject: JsonObject; ClientSecret: Text; ClientID: Text; RefreshToken: Text)
    begin
        JObject.Add('grant_type', 'refresh_token');
        JObject.Add('client_secret', ClientSecret);
        JObject.Add('client_id', ClientID);
        JObject.Add('refresh_token', RefreshToken);
    end;

    [NonDebuggable]
    local procedure LogActivity(var OAuth20Setup: Record "OAuth 2.0 Setup"; Result: Boolean; ActivityDescription: Text; ActivityMessage: Text; RequestJson: Text; ResponseJson: Text; MaskContent: Boolean)
    var
        ActivityLog: Record "Activity Log";
        JObject: JsonObject;
        JToken: JsonToken;
        RequestJObject: JsonObject;
        ResponseJObject: JsonObject;
        Context: Text[30];
        Status: Option;
        JsonString: Text;
        DetailedInfoExists: Boolean;
    begin
        Context := CopyStr(StrSubstNo('%1 %2', ActivityLogContextTxt, OAuth20Setup.Code), 1, MaxStrLen(Context));
        if Result then
            Status := ActivityLog.Status::Success
        else
            Status := ActivityLog.Status::Failed;

        ActivityLog.LogActivity(OAuth20Setup.RecordId(), Status, Context, ActivityDescription, ActivityMessage);
        if RequestJObject.ReadFrom(MaskHeaders(RequestJson)) then begin
            if MaskContent then
                if RequestJObject.SelectToken('Content', JToken) then
                    RequestJObject.Replace('Content', '***');
            JObject.Add('Request', RequestJObject);
            DetailedInfoExists := true;
        end;
        if ResponseJObject.ReadFrom(ResponseJson) then begin
            if MaskContent then
                if ResponseJObject.SelectToken('Content', JToken) then
                    ResponseJObject.Replace('Content', '***');
            JObject.Add('Response', ResponseJObject);
            DetailedInfoExists := true;
        end;
        if DetailedInfoExists then
            if JObject.WriteTo(JsonString) then
                if JsonString <> '' then
                    ActivityLog.SetDetailedInfoFromText(JsonString);
        OAuth20Setup."Activity Log ID" := ActivityLog.ID;
        OAuth20Setup.Modify();

        Commit(); // need to prevent rollback to save the log
    end;

    [NonDebuggable]
    local procedure MaskHeaders(RequestJson: Text) Result: Text;
    var
        JObject: JsonObject;
        JToken: JsonToken;
        KeyValue: Text;
    begin
        Result := RequestJson;
        if JObject.ReadFrom(RequestJson) then
            if JObject.SelectToken('Header', JToken) then begin
                foreach KeyValue in JToken.AsObject().Keys() do
                    JToken.AsObject().Replace(KeyValue, '***');
                JObject.WriteTo(Result);
            end;
    end;

    [NonDebuggable]
    local procedure SetHttpStatus(var JObject: JsonObject; StatusCode: Integer; StatusReason: Text; StatusDetails: Text)
    var
        JObject2: JsonObject;
    begin
        JObject2.Add('code', StatusCode);
        JObject2.Add('reason', StatusReason);
        if StatusDetails <> '' then
            JObject2.Add('details', StatusDetails);
        JObject.Add('Status', JObject2);
    end;

    [NonDebuggable]
    procedure GetHttpStatusFromJsonResponse(JsonString: Text; var StatusCode: Integer; var StatusReason: Text; var StatusDetails: Text): Boolean
    var
        JObject: JsonObject;
        JToken: JsonToken;
    begin
        if JObject.ReadFrom(JsonString) then
            if JObject.SelectToken('Status', JToken) then begin
                foreach JToken in JToken.AsObject().Values() do
                    case JToken.Path() of
                        'Status.code':
                            StatusCode := JToken.AsValue().AsInteger();
                        'Status.reason':
                            StatusReason := JToken.AsValue().AsText();
                        'Status.details':
                            StatusDetails := JToken.AsValue().AsText();
                    end;
                exit(true);
            end;
    end;

    [NonDebuggable]
    local procedure InvokeHttpJSONRequest(RequestJson: Text; var ResponseJson: Text; var HttpError: Text) Result: Boolean
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        ErrorMessage: Text;
    begin
        ResponseJson := '';
        HttpError := '';

        Client.Clear();
        Client.Timeout(60000);
        InitHttpRequestContent(RequestMessage, RequestJson);
        InitHttpRequestMessage(RequestMessage, RequestJson);

        if not Client.Send(RequestMessage, ResponseMessage) then
            if ResponseMessage.IsBlockedByEnvironment() then
                ErrorMessage := StrSubstNo(EnvironmentBlocksErr, RequestMessage.GetRequestUri())
            else
                ErrorMessage := StrSubstNo(ConnectionErr, RequestMessage.GetRequestUri());

        if ErrorMessage <> '' then
            Error(ErrorMessage);

        exit(ProcessHttpResponseMessage(ResponseMessage, ResponseJson, HttpError));
    end;

    [NonDebuggable]
    local procedure InitHttpRequestContent(var RequestMessage: HttpRequestMessage; RequestJson: Text)
    var
        ContentHeaders: HttpHeaders;
        JToken: JsonToken;
        ContentJToken: JsonToken;
        ContentJson: Text;
    begin
        if JToken.ReadFrom(RequestJson) then
            if JToken.SelectToken('Content', ContentJToken) then begin
                RequestMessage.Content().Clear();
                ContentJToken.WriteTo(ContentJson);
                RequestMessage.Content().WriteFrom(ContentJson);
                if JToken.SelectToken('Content-Type', JToken) then begin
                    RequestMessage.Content().GetHeaders(ContentHeaders);
                    ContentHeaders.Clear();
                    ContentHeaders.Add('Content-Type', JToken.AsValue().AsText());
                end;
            end;
    end;

    [NonDebuggable]
    local procedure InitHttpRequestMessage(var RequestMessage: HttpRequestMessage; RequestJson: Text)
    var
        RequestHeaders: HttpHeaders;
        JToken: JsonToken;
        JToken2: JsonToken;
        ServiceURL: Text;
        HeadersJson: Text;
    begin
        if JToken.ReadFrom(RequestJson) then begin
            RequestMessage.GetHeaders(RequestHeaders);
            RequestHeaders.Clear();
            if JToken.SelectToken('Accept', JToken2) then
                RequestHeaders.Add('Accept', JToken2.AsValue().AsText());
            if JToken.AsObject().Get('Header', JToken2) then begin
                JToken2.WriteTo(HeadersJson);
                if JToken2.ReadFrom(HeadersJson) then
                    foreach JToken2 in JToken2.AsObject().Values() do
                        RequestHeaders.Add(JToken2.Path(), JToken2.AsValue().AsText());
            end;

            if JToken.SelectToken('Method', JToken2) then
                RequestMessage.Method(JToken2.AsValue().AsText());

            if JToken.SelectToken('ServiceURL', JToken2) then begin
                ServiceURL := JToken2.AsValue().AsText();
                if JToken.SelectToken('URLRequestPath', JToken2) then
                    ServiceURL += JToken2.AsValue().AsText();
                RequestMessage.SetRequestUri(ServiceURL);
            end;
        end;
    end;

    [NonDebuggable]
    local procedure ProcessHttpResponseMessage(var ResponseMessage: HttpResponseMessage; var ResponseJson: Text; var HttpError: Text) Result: Boolean
    var
        ResponseJObject: JsonObject;
        ContentJObject: JsonObject;
        JToken: JsonToken;
        ResponseText: Text;
        JsonResponse: Boolean;
        StatusCode: Integer;
        StatusReason: Text;
        StatusDetails: Text;
    begin
        Result := ResponseMessage.IsSuccessStatusCode();
        StatusCode := ResponseMessage.HttpStatusCode();
        StatusReason := ResponseMessage.ReasonPhrase();

        if ResponseMessage.Content().ReadAs(ResponseText) then
            JsonResponse := ContentJObject.ReadFrom(ResponseText);
        if JsonResponse then
            ResponseJObject.Add('Content', ContentJObject);

        if not Result then begin
            HttpError := StrSubstNo('HTTP error %1 (%2)', StatusCode, StatusReason);
            if JsonResponse then
                if ContentJObject.SelectToken('error_description', JToken) then begin
                    StatusDetails := JToken.AsValue().AsText();
                    HttpError += StrSubstNo('\%1', StatusDetails);
                end;
        end;

        SetHttpStatus(ResponseJObject, StatusCode, StatusReason, StatusDetails);
        ResponseJObject.WriteTo(ResponseJson);
    end;
}
