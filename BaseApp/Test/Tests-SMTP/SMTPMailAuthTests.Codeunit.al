// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 139752 "SMTP Mail Auth Tests"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        TokenFromCacheTxt: Label 'aGVhZGVy.eyJ1bmlxdWVfbmFtZSI6InRlc3R1c2VyQGRvbWFpbi5jb20iLCJ1cG4iOiJ0ZXN0dXNlckBkb21haW4uY29tIn0=.c2lnbmF0dXJl', Comment = 'Access token example (with no secret data)', Locked = true;
        TokenFromCacheUserNameTxt: Label 'testuser@domain.com', Locked = true;
        AuthenticationSuccessfulMsg: Label '%1 was authenticated.';
        AuthenticationFailedMsg: Label 'Could not authenticate.';
        TokenFromCache: Text;

    [Test]
    procedure GetUserNameTest()
    var
        SMTPMail: Codeunit "SMTP Mail";
        ReturnedUserName: Text;
    begin
        SMTPMail.GetUserName(TokenFromCacheTxt, ReturnedUserName);
        Assert.AreEqual(TokenFromCacheUserNameTxt, ReturnedUserName, 'Incorrect returned username.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetOAuth2CredentialsTest()
    var
        SMTPMail: Codeunit "SMTP Mail";
        SMTPMailAuthTests: Codeunit "SMTP Mail Auth Tests";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        UserName: Text;
        AuthToken: Text;
    begin
        // [SCENARIO] If the provided server is the O365 SMTP server, and there is available token cache,
        // the access token is acquires from cache and the user name variable is filled.

        // [GIVEN] Environment is on-prem and token from cache with credentials is available.
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        SetAuthFlowProvider(Codeunit::"SMTP Mail Auth Tests");
        SMTPMailAuthTests.SetTokenCache(TokenFromCacheTxt);
        BindSubscription(SMTPMailAuthTests);

        // [WHEN] AuthenticateWithOAuth2 is called.
        SMTPMail.GetOAuth2Credentials(UserName, AuthToken);

        // [THEN] The AuthToken and UserName have the expected values.
        Assert.AreEqual(TokenFromCacheUserNameTxt, UserName, 'UserName should not have been filled.');
        Assert.AreEqual(TokenFromCacheTxt, AuthToken, 'AuthToken should not have been filled.');
    end;

    [Test]
    [HandlerFunctions('VerifyAuthenticationSuccessMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CheckAuthenticationSuccessTest()
    var
        SMTPMail: Codeunit "SMTP Mail";
        SMTPMailAuthTests: Codeunit "SMTP Mail Auth Tests";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [SCENARIO] If the provided server is the O365 SMTP server, and there is available token cache,
        // CheckAuthentication shows a message that authentication was successful.

        // [GIVEN] Environment is on-prem and token from cache with credentials is available.
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        SetAuthFlowProvider(Codeunit::"SMTP Mail Auth Tests");
        SMTPMailAuthTests.SetTokenCache(TokenFromCacheTxt);
        BindSubscription(SMTPMailAuthTests);

        // [WHEN] CheckAuthentication is called.
        SMTPMail.CheckOAuth2Authentication();

        // [THEN] The message handler verifies that message is about successful authentication.
    end;

    [Test]
    [HandlerFunctions('VerifyAuthenticationFailMessageHandler,AzureADAccessDialogModalPageHandler')]
    procedure CheckAuthenticationFailTest()
    var
        SMTPMail: Codeunit "SMTP Mail";
        SMTPMailAuthTests: Codeunit "SMTP Mail Auth Tests";
    begin
        // [SCENARIO] If the provided server is the O365 SMTP server, but there is no available token cache,
        // CheckAuthentication shows a message that authentication failed.

        // [GIVEN] There is no available token cache
        SetAuthFlowProvider(Codeunit::"SMTP Mail Auth Tests");
        SMTPMailAuthTests.SetTokenCache('');
        BindSubscription(SMTPMailAuthTests);

        // [WHEN] CheckAuthentication is called.
        SMTPMail.CheckOAuth2Authentication();

        // [THEN] The message handler verifies that message is about failed authentication.
    end;

    [MessageHandler]
    procedure VerifyAuthenticationSuccessMessageHandler(Message: Text[1024])
    begin
        Assert.AreEqual(StrSubstNo(AuthenticationSuccessfulMsg, TokenFromCacheUserNameTxt), Message, 'Incorrect message is shown.');
    end;

    [MessageHandler]
    procedure VerifyAuthenticationFailMessageHandler(Message: Text[1024])
    begin
        Assert.AreEqual(AuthenticationFailedMsg, Message, 'Incorrect message is shown.');
    end;

    [ModalPageHandler]
    procedure AzureADAccessDialogModalPageHandler(var AzureADAccessDialog: TestPage "Azure AD Access Dialog")
    begin
    end;

    local procedure SetAuthFlowProvider(ProviderCodeunit: Integer)
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
        AzureADAppSetup: Record "Azure AD App Setup";
    begin
        AzureADMgtSetup.Get();
        AzureADMgtSetup."Auth Flow Codeunit ID" := ProviderCodeunit;
        AzureADMgtSetup.Modify();

        if not AzureADAppSetup.Get() then begin
            AzureADAppSetup.Init();
            AzureADAppSetup."Redirect URL" := 'http://dummyurl:1234/Main_Instance1/WebClient/OAuthLanding.htm';
            AzureADAppSetup."App ID" := CreateGuid();
            AzureADAppSetup.SetSecretKeyToIsolatedStorage(CreateGuid());
            AzureADAppSetup.Insert();
        end;
    end;

    internal procedure SetTokenCache(TokenCache: Text)
    begin
        TokenFromCache := TokenCache;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnAcquireTokenFromCacheWithCredentials', '', false, false)]
    local procedure OnAcquireTokenFromCacheWithCredentials(ClientID: Text; AppKey: Text; ResourceName: Text; var AccessToken: Text)
    begin
        AccessToken := TokenFromCache;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnCheckProvider', '', false, false)]
    local procedure OnCheckProvider(var Result: Boolean)
    begin
        Result := true;
    end;
}
