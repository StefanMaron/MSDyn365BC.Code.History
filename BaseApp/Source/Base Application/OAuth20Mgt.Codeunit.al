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

            LogActivity(OAuth20Setup, true, RequestAuthCodeTxt, '', '', '');
            exit(
              StrSubstNo(
                '%1%2?response_type=%3&client_id=%4&scope=%5&redirect_uri=%6',
                "Service URL", "Authorization URL Path", "Authorization Response Type", ClientID, Scope, "Redirect URL"));
        end;
    end;

    [NonDebuggable]
    procedure RequestAccessToken(var OAuth20Setup: Record "OAuth 2.0 Setup"; var MessageText: Text; AuthorizationCode: Text; ClientID: Text; ClientSecret: Text; var AccessToken: Text; var RefreshToken: Text): Boolean
    begin
        exit(
            RequestAccessTokenWithGivenRequestJson(
                OAuth20Setup, '', MessageText, AuthorizationCode, ClientID, ClientSecret, AccessToken, RefreshToken));
    end;

    [NonDebuggable]
    procedure RequestAccessTokenWithGivenRequestJson(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var MessageText: Text; AuthorizationCode: Text; ClientID: Text; ClientSecret: Text; var AccessToken: Text; var RefreshToken: Text) Result: Boolean
    var
        RequestJsonContent: Text;
        HttpError: Text;
    begin
        with OAuth20Setup do begin
            Status := Status::Disabled;
            TestField("Service URL");
            TestField("Access Token URL Path");
            TestField("Client ID");
            TestField("Client Secret");
            TestField("Redirect URL");

            CreateContentRequestJSONForAccessToken(RequestJsonContent, ClientSecret, ClientID, "Redirect URL", AuthorizationCode);
            CreateRequestJSONForAccessRefreshToken(RequestJson, "Service URL", "Access Token URL Path", RequestJsonContent);

            Result := RequestAccessAndRefreshTokens(RequestJson, AccessToken, RefreshToken, HttpError);
            SaveResultForRequestAccessAndRefreshTokens(
              OAuth20Setup, MessageText, Result, RequestAccessTokenTxt, AuthorizationSuccessfulTxt, AuthorizationFailedTxt, HttpError);
        end;
    end;

    [NonDebuggable]
    procedure RefreshAccessToken(var OAuth20Setup: Record "OAuth 2.0 Setup"; var MessageText: Text; ClientID: Text; ClientSecret: Text; var AccessToken: Text; var RefreshToken: Text): Boolean
    begin
        exit(
            RefreshAccessTokenWithGivenRequestJson(
                OAuth20Setup, '', MessageText, ClientID, ClientSecret, AccessToken, RefreshToken));
    end;

    [NonDebuggable]
    procedure RefreshAccessTokenWithGivenRequestJson(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var MessageText: Text; ClientID: Text; ClientSecret: Text; var AccessToken: Text; var RefreshToken: Text) Result: Boolean
    var
        RequestJsonContent: Text;
        HttpError: Text;
    begin
        with OAuth20Setup do begin
            Status := Status::Disabled;
            TestField("Service URL");
            TestField("Refresh Token URL Path");
            TestField("Client ID");
            TestField("Client Secret");
            TestField("Refresh Token");

            CreateContentRequestJSONForRefreshAccessToken(RequestJsonContent, ClientSecret, ClientID, RefreshToken);
            CreateRequestJSONForAccessRefreshToken(RequestJson, "Service URL", "Refresh Token URL Path", RequestJsonContent);

            Result := RequestAccessAndRefreshTokens(RequestJson, AccessToken, RefreshToken, HttpError);
            SaveResultForRequestAccessAndRefreshTokens(
              OAuth20Setup, MessageText, Result, RefreshAccessTokenTxt, RefreshSuccessfulTxt, RefreshFailedTxt, HttpError);
        end;
    end;

    local procedure SaveResultForRequestAccessAndRefreshTokens(var OAuth20Setup: Record "OAuth 2.0 Setup"; var MessageText: Text; Result: Boolean; Context: Text; SuccessMsg: Text; ErrorMsg: Text; HttpError: Text)
    begin
        if Result then begin
            MessageText := SuccessMsg;
            OAuth20Setup.Status := OAuth20Setup.Status::Enabled;
        end else begin
            MessageText := ErrorMsg;
            if HttpError <> '' then
                MessageText += '\' + ReasonTxt + HttpError;
            OAuth20Setup.Status := OAuth20Setup.Status::Error;
        end;
        LogActivity(OAuth20Setup, Result, Context, MessageText, '', '');
    end;

    [NonDebuggable]
    procedure InvokeRequest(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var ResponseJson: Text; var HttpError: Text; AccessToken: Text; RetryOnCredentialsFailure: Boolean) Result: Boolean
    var
        JSONMgt: Codeunit "JSON Management";
    begin
        Result := InvokeSingleRequest(OAuth20Setup, RequestJson, ResponseJson, HttpError, AccessToken);
        if not Result and RetryOnCredentialsFailure then
            if JSONMgt.InitializeFromString(ResponseJson) then
                if JSONMgt.HasValue('Error.code', '401') then // Unauthorized
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
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        JSONMgt: Codeunit "JSON Management";
    begin
        with OAuth20Setup do begin
            TestField("Service URL");
            TestField("Access Token");

            JSONMgt.InitializeObject(RequestJson);
            JSONMgt.SetValue('ServiceURL', "Service URL");
            JSONMgt.SetValue('Header.Authorization', StrSubstNo('Bearer %1', AccessToken));
            RequestJson := JSONMgt.WriteObjectToString();

            if "Latest Datetime" = 0DT then
                "Daily Count" := 0
            else
                if CreateDateTime(Today(), 0T) - "Latest Datetime" > 0 then
                    "Daily Count" := 0;
            if ("Daily Limit" <= 0) or ("Daily Count" < "Daily Limit") or ("Latest Datetime" = 0DT) then begin
                Result := HttpWebRequestMgt.InvokeJSONRequest(RequestJson, ResponseJson, HttpError);
                "Latest Datetime" := CurrentDateTime();
                "Daily Count" += 1;
            end else begin
                Result := false;
                HttpError := LimitExceededTxt;
                SendTraceTag('00009YL', ActivityLogContextTxt, Verbosity::Normal, LimitExceededTxt, DataClassification::SystemMetadata);
            end;
            LogActivity(OAuth20Setup, Result, StrSubstNo(InvokeRequestTxt, JSONMgt.GetValue('Method')), HttpError, RequestJson, ResponseJson);
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
    local procedure RequestAccessAndRefreshTokens(RequestJson: Text; var AccessToken: Text; var RefreshToken: Text; var HttpError: Text): Boolean
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        ResponseJson: Text;
    begin
        AccessToken := '';
        RefreshToken := '';
        if HttpWebRequestMgt.InvokeJSONRequest(RequestJson, ResponseJson, HttpError) then
            exit(ParseAccessAndRefreshTokens(ResponseJson, AccessToken, RefreshToken));
    end;

    [NonDebuggable]
    local procedure ParseAccessAndRefreshTokens(ResponseJson: Text; var AccessToken: Text; var RefreshToken: Text): Boolean
    var
        JSONMgt: Codeunit "JSON Management";
        NewAccessToken: Text;
        NewRefreshToken: Text;
    begin
        if not JSONMgt.InitializeFromString(ResponseJson) then
            exit(false);

        JSONMgt.SelectTokenFromRoot('Content');
        NewAccessToken := JSONMgt.GetValue('access_token');
        if NewAccessToken = '' then
            exit(false);

        NewRefreshToken := JSONMgt.GetValue('refresh_token');
        if NewRefreshToken = '' then
            exit(false);

        AccessToken := NewAccessToken;
        RefreshToken := NewRefreshToken;
        exit(true);
    end;

    [NonDebuggable]
    local procedure CreateRequestJSONForAccessRefreshToken(var JsonString: Text; ServiceURL: Text; URLRequestPath: Text; Content: Text)
    var
        JSONMgt: Codeunit "JSON Management";
    begin
        JSONMgt.InitializeObject(JsonString);
        JSONMgt.SetValue('ServiceURL', ServiceURL);
        JSONMgt.SetValue('Method', 'POST');
        JSONMgt.SetValue('URLRequestPath', URLRequestPath);
        JSONMgt.SetValue('Header.Content-Type', 'application/json');
        JSONMgt.SetValue('Content', Content);
        JsonString := JSONMgt.WriteObjectToString();
    end;

    [NonDebuggable]
    local procedure CreateContentRequestJSONForAccessToken(var JsonString: Text; ClientSecret: Text; ClientID: Text; RedirectURI: Text; AuthorizationCode: Text)
    var
        JSONMgt: Codeunit "JSON Management";
    begin
        JSONMgt.SetValue('grant_type', 'authorization_code');
        JSONMgt.SetValue('client_secret', ClientSecret);
        JSONMgt.SetValue('client_id', ClientID);
        JSONMgt.SetValue('redirect_uri', RedirectURI);
        JSONMgt.SetValue('code', AuthorizationCode);
        JsonString := JSONMgt.WriteObjectToString();
    end;

    [NonDebuggable]
    local procedure CreateContentRequestJSONForRefreshAccessToken(var JsonString: Text; ClientSecret: Text; ClientID: Text; RefreshToken: Text)
    var
        JSONMgt: Codeunit "JSON Management";
    begin
        JSONMgt.SetValue('grant_type', 'refresh_token');
        JSONMgt.SetValue('client_secret', ClientSecret);
        JSONMgt.SetValue('client_id', ClientID);
        JSONMgt.SetValue('refresh_token', RefreshToken);
        JsonString := JSONMgt.WriteObjectToString();
    end;

    [NonDebuggable]
    local procedure LogActivity(var OAuth20Setup: Record "OAuth 2.0 Setup"; Result: Boolean; ActivityDescription: Text; ActivityMessage: Text; RequestJson: Text; ResponseJson: Text)
    var
        ActivityLog: Record "Activity Log";
        JSONMgt: Codeunit "JSON Management";
        Context: Text[30];
        Status: Option;
        JsonString: Text;
    begin
        Context := CopyStr(StrSubstNo('%1 %2', ActivityLogContextTxt, OAuth20Setup.Code), 1, MaxStrLen(Context));
        if Result then
            Status := ActivityLog.Status::Success
        else
            Status := ActivityLog.Status::Failed;

        ActivityLog.LogActivity(OAuth20Setup.RecordId(), Status, Context, ActivityDescription, ActivityMessage);
        JSONMgt.AddJson('Request', MaskHeaders(RequestJson));
        JSONMgt.AddJson('Response', ResponseJson);
        JsonString := JSONMgt.WriteObjectToString();
        if JsonString <> '' then
            ActivityLog.SetDetailedInfoFromText(JsonString);
        OAuth20Setup."Activity Log ID" := ActivityLog.ID;
        OAuth20Setup.Modify();

        Commit(); // need to prevent rollback to save the log
    end;

    [NonDebuggable]
    local procedure MaskHeaders(RequestJson: Text) Result: Text;
    var
        JSONMgt: Codeunit "JSON Management";
        ResultJSONMgt: Codeunit "JSON Management";
        Name: Text;
        Value: Text;
    begin
        Result := RequestJson;
        JSONMgt.InitializeObject(RequestJson);
        if JSONMgt.SelectTokenFromRoot('Header') then
            if JSONMgt.ReadProperties() then begin
                ResultJSONMgt.InitializeObject(Result);
                while JSONMgt.GetNextProperty(Name, Value) do
                    ResultJSONMgt.SetValue(STRSUBSTNO('Header.%1', Name), '***');
                Result := ResultJSONMgt.WriteObjectToString();
            end;
    end;
}

