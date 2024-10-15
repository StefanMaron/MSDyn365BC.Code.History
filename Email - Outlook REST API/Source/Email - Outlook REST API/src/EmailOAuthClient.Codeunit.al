// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 4507 "Email - OAuth Client" implements "Email - OAuth Client"
{
    /// <summary>
    /// Retrieves the Access token for the current user to connect to Outlook API
    /// </summary>
    /// <param name="AccessToken">Out parameter with the Access token of the account</param>
    [NonDebuggable]
    procedure GetAccessToken(var AccessToken: Text)
    begin
        TryGetAccessTokenInternal(AccessToken);
    end;

    [NonDebuggable]
    procedure TryGetAccessToken(var AccessToken: Text): Boolean
    begin
        exit(TryGetAccessTokenInternal(AccessToken));
    end;

    // Interfaces do not support properties for the procedures, so using an internal function
    [TryFunction]
    [NonDebuggable]
    local procedure TryGetAccessTokenInternal(var AccessToken: Text)
    var
        EnvironmentInformation: Codeunit "Environment Information";
        OAuthErr: Text;
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then begin
            if (not AcquireOnBehalfOfTokenFromStoredTokenCache(AccessToken)) or (AccessToken = '') then
                if OAuth2.AcquireOnBehalfOfToken('', GraphResourceURLTxt, AccessToken) then;
        end else begin
            Initialize();
            if (not OAuth2.AcquireAuthorizationCodeTokenFromCache(ClientId, ClientSecret, RedirectURL, OAuthAuthorityUrlTxt, GraphResourceURLTxt, AccessToken)) or (AccessToken = '') then
                OAuth2.AcquireTokenByAuthorizationCode(ClientId, ClientSecret, OAuthAuthorityUrlTxt, RedirectURL, GraphResourceURLTxt, Enum::"Prompt Interaction"::None, AccessToken, OAuthErr);
        end;

        if AccessToken = '' then
            Error(CouldNotGetAccessTokenErr);
    end;

    local procedure Initialize()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        EmailOutlookAPIHelper: Codeunit "Email - Outlook API Helper";
    begin
        if IsInitialized then
            exit;

        if not EnvironmentInformation.IsSaaSInfrastructure() then begin
            EmailOutlookAPIHelper.GetClientIDAndSecret(ClientId, ClientSecret);
            RedirectURL := EmailOutlookAPIHelper.GetRedirectURL();
            if RedirectURL = '' then
                OAuth2.GetDefaultRedirectUrl(RedirectURL);
        end;

        IsInitialized := true;
    end;

    [NonDebuggable]
    local procedure AcquireOnBehalfOfTokenFromStoredTokenCache(var AccessToken: Text): Boolean
    var
        User: Record User;
        TokenCache: Text;
        NewTokenCache: Text;
        AADUserID: Text;
    begin
        if not User.Get(UserSecurityId()) then begin
            Session.LogMessage('AL00001', StrSubstNo(NoUserErr, UserSecurityId()), Verbosity::Error, DataClassification::EndUserPseudonymousIdentifiers, TelemetryScope::ExtensionPublisher, 'Category', EmailCategoryLbl);
            exit(false);
        end;

        if not IsolatedStorage.Get(TokenCacheTok + UserSecurityId(), DataScope::Module, TokenCache) then begin
            Session.LogMessage('AL00002', StrSubstNo(NoStoredTokenCacheErr, UserSecurityId()), Verbosity::Error, DataClassification::EndUserPseudonymousIdentifiers, TelemetryScope::ExtensionPublisher, 'Category', EmailCategoryLbl);
            exit(false);
        end;

        if (not OAuth2.AcquireOnBehalfOfTokenByTokenCache(User."Authentication Email", '', GraphResourceURLTxt, TokenCache, AccessToken, NewTokenCache)) or (AccessToken = '') then begin
            Session.LogMessage('AL00003', StrSubstNo(CouldNotAcquireAccessTokenFromCacheErr, User."Authentication Email"), Verbosity::Error, DataClassification::EndUserIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', EmailCategoryLbl);
            if not IsolatedStorage.Delete(TokenCacheTok + UserSecurityId()) then
                Session.LogMessage('AL00008', StrSubstNo(CouldNotDeleteTokenCacheTxt, User."Authentication Email"), Verbosity::Warning, DataClassification::EndUserIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', EmailCategoryLbl);
            exit(false);
        end;

        if NewTokenCache <> TokenCache then
            StoreTokenCacheState(NewTokenCache);

        exit(true);
    end;

    [NonDebuggable]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterInitialization', '', false, false)]
    local procedure UpdateTokenCacheForUserOnLogin()
    begin
        StoreTokenCacheOnLogin();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Email, 'OnGetTestEmailBody', '', false, false)]
    local procedure UpdateTokenCacheForUserOnSendingTestEmail(Connector: Enum "Email Connector"; var Body: Text)
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        StoreTokenCacheState();
    end;

    [NonDebuggable]
    local procedure StoreTokenCacheOnLogin()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        if not (Session.CurrentClientType() in [ClientType::Web, ClientType::Windows, ClientType::Desktop, ClientType::Tablet, ClientType::Phone]) then
            exit;

        if IsolatedStorage.Contains(TokenCacheTok + UserSecurityId()) then
            exit;

        if not StoreTokenCacheState() then
            Session.LogMessage('AL00009', StrSubstNo(SoringTokenCacheFailedErr, GetLastErrorText()), Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', EmailCategoryLbl);

        // populate the entry in isolated storage to not spend time on the next log in
        if not IsolatedStorage.Contains(TokenCacheTok + UserSecurityId()) then
            IsolatedStorage.Set(TokenCacheTok + UserSecurityId(), '', DataScope::Module);
    end;

    [NonDebuggable]
    local procedure StoreTokenCacheState(): Boolean
    var
        AccessToken: Text;
        TokenCache: Text;
    begin
        if not OAuth2.AcquireOnBehalfAccessTokenAndTokenCache(OAuthAuthorityUrlTxt, '', GraphResourceURLTxt, AccessToken, TokenCache) then begin
            Session.LogMessage('AL00004', StrSubstNo(CouldNotAcquireOnBehalfOfAccessTokenErr, UserSecurityId()), Verbosity::Error, DataClassification::EndUserPseudonymousIdentifiers, TelemetryScope::ExtensionPublisher, 'Category', EmailCategoryLbl);
            exit(false);
        end else
            exit(StoreTokenCacheState(TokenCache));
    end;

    [NonDebuggable]
    local procedure StoreTokenCacheState(TokenCacheState: Text): Boolean
    begin
        if TokenCacheState = '' then begin
            Session.LogMessage('AL00005', StrSubstNo(EmptyTokenCacheErr, UserSecurityId()), Verbosity::Error, DataClassification::EndUserPseudonymousIdentifiers, TelemetryScope::ExtensionPublisher, 'Category', EmailCategoryLbl);
            exit(false);
        end else begin
            Session.LogMessage('AL00006', StrSubstNo(StoredTokenCacheTxt, UserSecurityId()), Verbosity::Normal, DataClassification::EndUserPseudonymousIdentifiers, TelemetryScope::ExtensionPublisher, 'Category', EmailCategoryLbl);
            if IsolatedStorage.Set(TokenCacheTok + UserSecurityId(), TokenCacheState, DataScope::Module) then
                exit(true);

            Session.LogMessage('AL00007', StrSubstNo(FailedToSaveTokenCacheTxt, UserSecurityId()), Verbosity::Warning, DataClassification::EndUserPseudonymousIdentifiers, TelemetryScope::ExtensionPublisher, 'Category', EmailCategoryLbl);
            exit(false);
        end;
    end;

    internal procedure AuthorizationCodeTokenCacheExists(): Boolean
    var
        [NonDebuggable]
        AccessToken: Text;
    begin
        Initialize();
        exit(OAuth2.AcquireAuthorizationCodeTokenFromCache(ClientId, ClientSecret, RedirectURL, OAuthAuthorityUrlTxt, GraphResourceURLTxt, AccessToken) and (AccessToken <> ''))
    end;

    internal procedure SignInUsingAuthorizationCode(): Boolean
    var
        [NonDebuggable]
        AccessToken: Text;
        OAuthErr: Text;
    begin
        Initialize();
        exit(OAuth2.AcquireTokenByAuthorizationCode(ClientID, ClientSecret, OAuthAuthorityUrlTxt, RedirectURL, GraphResourceURLTxt, Enum::"Prompt Interaction"::"Select Account", AccessToken, OAuthErr) and (AccessToken <> ''));
    end;

    var
        OAuth2: Codeunit OAuth2;

        [NonDebuggable]
        ClientId: Text;
        [NonDebuggable]
        ClientSecret: Text;
        RedirectURL: Text;
        IsInitialized: Boolean;
        OAuthAuthorityUrlTxt: Label 'https://login.microsoftonline.com/common/oauth2', Locked = true;
        GraphResourceURLTxt: Label 'https://graph.microsoft.com/', Locked = true;
        ChooseYourOrganizationEmailAccountTxt: Label 'Please, choose your email account associated with your organization in the account selection window.';
        TokenCacheTok: Label 'TokenCache', Locked = true;
        CouldNotGetAccessTokenErr: Label 'Could not get access token. Please, try to log out and log in again.';
        EmailCategoryLbl: Label 'EmailOAuth', Locked = true;
        NoStoredTokenCacheErr: Label 'Failed to get token cache from the isolated storage for user security ID: %1.', Locked = true;
        StoredTokenCacheTxt: Label 'Stored token cache in the isolated storage for user security ID: %1.', Locked = true;
        FailedToSaveTokenCacheTxt: Label 'Failed to save the token cache to isolated starage for user security ID: %1.', Locked = true;
        SoringTokenCacheFailedErr: Label 'Failed to run the storing token cache codeunit. Error: %1.', Locked = true;
        CouldNotDeleteTokenCacheTxt: Label 'Failed to delete the token cache from isolated starage for user security ID: %1.', Locked = true;
        NoUserErr: Label 'Could not find user with security ID: %1.', Locked = true;
        CouldNotAcquireAccessTokenFromCacheErr: Label 'Could not acquire a new access token by token cache for user: %1.', Locked = true;
        EmptyAccessTokenFromCacheErr: Label 'The access token for the user %1 is empty.', Locked = true;
        EmptyTokenCacheErr: Label 'The acquired token cache is empty. User: %1.', Locked = true;
        CouldNotAcquireOnBehalfOfAccessTokenErr: Label 'Failed to acquire an on-belaf-of access token for user security ID: %1', Locked = true;
}