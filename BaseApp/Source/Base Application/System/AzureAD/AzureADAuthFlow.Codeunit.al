namespace System.Azure.Identity;

using System;
using System.Utilities;

codeunit 6303 "Azure AD Auth Flow"
{
    // // This codeunit should never be called directly. It should only be called through COD6300.


    trigger OnRun()
    begin
    end;

    var
        AuthFlow: DotNet ALAzureAdCodeGrantFlow;
        ProviderNotInitializedErr: Label 'The Azure AD Authentication Flow provider has not been initialized.';

    [InherentPermissions(PermissionObjectType::TableData, Database::"Azure AD Mgt. Setup", 'R')]
    procedure CanHandle(): Boolean
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
        UserAccountHelper: DotNet NavUserAccountHelper;
    begin
        // only return false in SaaS if an extension explicitly overwrote the default
        if UserAccountHelper.IsAzure() then
            if AzureADMgtSetup.Get() then
                exit((AzureADMgtSetup."Auth Flow Codeunit ID" = CODEUNIT::"Azure AD Auth Flow") or
                     (AzureADMgtSetup."Auth Flow Codeunit ID" = 0))
            else
                exit(true);

        // have a stricter check for tests and OnPrem (legacy behavior)
        if AzureADMgtSetup.Get() then
            exit(AzureADMgtSetup."Auth Flow Codeunit ID" = CODEUNIT::"Azure AD Auth Flow");

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure Initialize(RedirectUri: Text)
    var
        Uri: DotNet Uri;
    begin
        if not IsNull(AuthFlow) then
            exit;

        if CanHandle() then
            AuthFlow := AuthFlow.ALAzureAdCodeGrantFlow(Uri.Uri(RedirectUri))
        else
            OnInitialize(RedirectUri, AuthFlow);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure AcquireTokenByAuthorizationCode(AuthorizationCode: Text; ResourceName: Text) AccessToken: Text
    begin
        CheckProvider();
        if CanHandle() then
            AccessToken := AuthFlow.ALAcquireTokenByAuthorizationCode(AuthorizationCode, ResourceName)
        else
            OnAcquireTokenByAuthorizationCode(AuthorizationCode, ResourceName, AccessToken);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure AcquireTokenByAuthorizationCodeWithCredentials(AuthorizationCode: Text; ClientID: Text; ApplicationKey: Text; ResourceName: Text) AccessToken: Text
    begin
        CheckProvider();
        if CanHandle() then
            AccessToken := AuthFlow.ALAcquireTokenByAuthorizationCodeWithCredentials(AuthorizationCode, ClientID, ApplicationKey, ResourceName)
        else
            OnAcquireTokenByAuthorizationCodeWithCredentials(AuthorizationCode, ClientID, ApplicationKey, ResourceName, AccessToken);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure AcquireTokenFromCache(ResourceName: Text) AccessToken: Text
    begin
        CheckProvider();
        if CanHandle() then
            AccessToken := AuthFlow.ALAcquireTokenFromCache(ResourceName)
        else
            OnAcquireTokenFromCache(ResourceName, AccessToken);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure AcquireTokenFromCacheState(ResourceName: Text; AadUserId: Text; TokenCacheState: Text; var NewTokenCacheState: Text) AccessToken: Text
    begin
        CheckProvider();
        if CanHandle() then
            AccessToken := AuthFlow.ALAcquireTokenFromTokenCacheState(ResourceName, AadUserId, TokenCacheState, NewTokenCacheState)
        else
            OnAcquireTokenFromCacheState(ResourceName, AadUserId, TokenCacheState, NewTokenCacheState, AccessToken);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure AcquireGuestToken(ResourceName: Text; GuestTenantId: Text) AccessToken: Text
    begin
        CheckProvider();
        if CanHandle() then
            AccessToken := AuthFlow.ALAcquireGuestToken(ResourceName, GuestTenantId)
        else
            OnAcquireGuestToken(ResourceName, GuestTenantId, AccessToken);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure AcquireOnBehalfOfToken(ResourceName: Text) AccessToken: Text
    begin
        CheckProvider();
        if CanHandle() then
            AccessToken := AuthFlow.ALAcquireOnBehalfOfToken(ResourceName)
        else
            OnAcquireAcquireOnBehalfOfToken(ResourceName, AccessToken);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure AcquireOnBehalfOfTokenAndTokenCacheState(ResourceName: Text; var TokenCacheState: Text) AccessToken: Text
    begin
        CheckProvider();
        if CanHandle() then
            AccessToken := AuthFlow.ALAcquireOnBehalfOfToken(ResourceName, TokenCacheState)
        else
            OnAcquireOnBehalfOfTokenAndTokenCacheState(ResourceName, AccessToken, TokenCacheState);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure AcquireTokenFromCacheWithCredentials(ClientID: Text; AppKey: Text; ResourceName: Text) AccessToken: Text
    begin
        CheckProvider();
        if CanHandle() then
            AccessToken := AuthFlow.ALAcquireTokenFromCacheWithCredentials(ClientID, AppKey, ResourceName)
        else
            OnAcquireTokenFromCacheWithCredentials(ClientID, AppKey, ResourceName, AccessToken);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure AcquireApplicationToken(ClientID: Text; ClientSecret: Text; Authority: Text; ResourceUri: Text) AccessToken: Text
    begin
        CheckProvider();
        AccessToken := AuthFlow.ALAcquireApplicationToken(ClientID, ClientSecret, Authority, ResourceUri);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetSaasClientId() ClientID: Text
    begin
        CheckProvider();
        if CanHandle() then
            ClientID := AuthFlow.ALGetSaasClientId()
        else
            OnGetSaasClientId(ClientID);
    end;

    [Scope('OnPrem')]
    procedure GetInitialTenantDomainName() InitialTenantDomainName: Text
    begin
        CheckProvider();
        if CanHandle() then
            InitialTenantDomainName := AuthFlow.ALGetInitialDomainNameFromAad();
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure CreateExchangeServiceWrapperWithToken(Token: Text; var Service: DotNet ExchangeServiceWrapper)
    var
        ServiceFactory: DotNet ServiceWrapperFactory;
    begin
        if CanHandle() then
            Service := ServiceFactory.CreateServiceWrapperWithToken(Token)
        else
            OnCreateExchangeServiceWrapperWithToken(Token, Service);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetLastErrorMessage(): Text
    begin
        if not IsNull(AuthFlow) then
            exit(AuthFlow.LastErrorMessage());
    end;

    local procedure CheckProvider()
    var
        Initialized: Boolean;
    begin
        if CanHandle() then
            Initialized := not IsNull(AuthFlow)
        else
            OnCheckProvider(Initialized);

        if not Initialized then
            Error(ProviderNotInitializedErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitialize(RedirectUri: Text; var AzureADAuthFlow: DotNet ALAzureAdCodeGrantFlow)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAcquireTokenByAuthorizationCode(AuthorizationCode: Text; ResourceName: Text; var AccessToken: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAcquireTokenByAuthorizationCodeWithCredentials(AuthorizationCode: Text; ClientID: Text; ApplicationKey: Text; ResourceName: Text; var AccessToken: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAcquireTokenFromCache(ResourceName: Text; var AccessToken: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAcquireTokenFromCacheState(ResourceName: Text; AadUserId: Text; TokenCacheState: Text; var NewTokenCacheState: Text; var AccessToken: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAcquireGuestToken(ResourceName: Text; GuestTenantId: Text; var AccessToken: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAcquireAcquireOnBehalfOfToken(ResourceName: Text; var AccessToken: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAcquireOnBehalfOfTokenAndTokenCacheState(ResourceName: Text; var AccessToken: Text; var TokenCacheState: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAcquireTokenFromCacheWithCredentials(ClientID: Text; AppKey: Text; ResourceName: Text; var AccessToken: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSaasClientId(var ClientID: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateExchangeServiceWrapperWithToken(Token: Text; var Service: DotNet ExchangeServiceWrapper)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckProvider(var Result: Boolean)
    begin
    end;
}

