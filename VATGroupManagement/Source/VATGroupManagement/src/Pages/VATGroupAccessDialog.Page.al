page 4710 "VAT Group Access Dialog"
{
    Caption = 'Waiting for a response - do not close this page';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            usercontrol(OAuthIntegration; "Microsoft.Dynamics.Nav.Client.OAuthIntegration")
            {
                ApplicationArea = All;

                trigger ControlAddInReady();
                var
                    URI: DotNet Uri;
                begin
                    SendTraceTag('0000DMG', Oauth2CategoryLbl, Verbosity::Normal, OAuthCodeStartMsg, DataClassification::SystemMetadata);
                    URI := URI.Uri(OAuthRequestUrl);
                    CurrPage.OAuthIntegration.StartAuthorization(URI);
                end;

                trigger AuthorizationCodeRetrieved(authorizationCode: Text)
                var
                    ClientTypeMgt: Codeunit "Client Type Management";
                    StateOut: Text;
                begin
                    if ClientTypeMgt.GetCurrentClientType() = ClientType::Windows then begin
                        AuthCode := authorizationCode;
                        Message(CloseWindowMsg);
                    end else begin
                        VATGroupCommunication.GetOAuthProperties(authorizationCode, AuthCode, StateOut);
                        if StateIn = '' then begin
                            SendTraceTag('0000DMH', Oauth2CategoryLbl, Verbosity::Error, MissingStateErr, DataClassification::SystemMetadata);
                            AuthError := AuthError + NoStateErr;
                        end else
                            if StateOut <> StateIn then begin
                                SendTraceTag('0000DMI', Oauth2CategoryLbl, Verbosity::Error, MismatchingStateErr, DataClassification::SystemMetadata);
                                AuthError := AuthError + NotMatchingStateErr;
                            end;
                    end;
                    CurrPage.Close();
                end;

                trigger AuthorizationErrorOccurred(error: Text; description: Text)
                begin
                    SendTraceTag('0000DMJ', Oauth2CategoryLbl, Verbosity::Error, StrSubstNo(OauthFailErrMsg, error, description), DataClassification::SystemMetadata);
                    AuthError := StrSubstNo(AuthCodeErrorLbl, error, description);
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        VATGroupCommunication: Codeunit "VAT Group Communication";
        OAuthRequestUrl: Text;
        AuthError: Text;
        AuthCode: Text;
        StateIn: Text;
        OAuthCodeStartMsg: Label 'The authorization code flow grant process has started.', Locked = true;
        Oauth2CategoryLbl: Label 'OAuth2', Locked = true;
        OauthFailErrMsg: Label 'Error: %1 ; Description: %2.', Comment = '%1 = OAuth error message ; %2 = description of OAuth failure error message', Locked = true;
        AuthCodeErrorLbl: Label 'Error: %1, description: %2', Comment = '%1 = The authorization error message, %2 = The authorization error description';
        MissingStateErr: Label 'The returned authorization code is missing information about the returned state.', Locked = true;
        MismatchingStateErr: Label 'The authroization code returned state is missmatching the expected state value.', Locked = true;
        NoStateErr: Label 'No state has been returned';
        NotMatchingStateErr: Label 'The state parameter value does not match.';
        CloseWindowMsg: Label 'Authorization completed. Close the window to proceed.';

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure SetOAuth2Properties(AuthRequestUrl: Text; AuthInitialState: Text)
    begin
        OAuthRequestUrl := AuthRequestUrl;
        StateIn := AuthInitialState;
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetAuthCode(): Text
    begin
        exit(AuthCode);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetAuthError(): Text
    begin
        exit(AuthError);
    end;
}