codeunit 6300 "Azure AD Mgt."
{
    // // Provides functions to authorize NAV app to use Azure Active Directory resources on behalf of a user.


    trigger OnRun()
    begin
    end;

    var
        AzureADAppSetup: Record "Azure AD App Setup";
        TypeHelper: Codeunit "Type Helper";
        AzureADNotSetupErr: Label '%1 is not registered in your Azure Active Directory tenant.', Comment = '%1 - product name';
        AzureAdSetupTxt: Label 'Set Up Azure Active Directory Application';
        O365ResourceNameTxt: Label 'Office 365 Services', Locked = true;
        OAuthLandingPageTxt: Label 'OAuthLanding.htm', Locked = true;

    [Scope('OnPrem')]
    procedure GetAuthCodeUrl(ResourceName: Text) AuthCodeUrl: Text
    begin
        // Pass ResourceName as empty string if you want to authorize all azure resources.
        AuthCodeUrl := GetAzureADAuthEndpoint;
        AuthCodeUrl += '?response_type=code';
        AuthCodeUrl += '&client_id=' + UrlEncode(GetClientId);
        if ResourceName <> '' then
            AuthCodeUrl += '&resource=' + UrlEncode(ResourceName);
        AuthCodeUrl += '&redirect_uri=' + UrlEncode(GetRedirectUrl);
    end;

    local procedure AcquireTokenByAuthorizationCode(AuthorizationCode: Text; ResourceUrl: Text) AccessToken: Text
    var
        AzureADAuthFlow: Codeunit "Azure AD Auth Flow";
    begin
        // This will return access token and also cache it for future use.
        AzureADAuthFlow.Initialize(GetRedirectUrl);

        if IsSaaS then
            AccessToken := AzureADAuthFlow.AcquireTokenByAuthorizationCode(AuthorizationCode, ResourceUrl)
        else begin
            AzureADAppSetup.FindFirst;
            AccessToken := AzureADAuthFlow.AcquireTokenByAuthorizationCodeWithCredentials(
                AuthorizationCode,
                GetClientId,
                AzureADAppSetup.GetSecretKey,
                ResourceUrl);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetAccessToken(ResourceUrl: Text; ResourceName: Text; ShowDialog: Boolean) AccessToken: Text
    var
        AzureADAccessDialog: Page "Azure AD Access Dialog";
        AuthorizationCode: Text;
    begin
        // Does everything required to retrieve an access token for the given service, including
        // showing the Azure AD wizard and auth code retrieval form if necessary.
        if (not IsAzureADAppSetupDone) and ShowDialog then begin
            PAGE.RunModal(PAGE::"Azure AD App Setup Wizard");
            if not IsAzureADAppSetupDone then
                // Don't continue if user cancelled or errored out of the setup wizard.
                exit('');
        end;

        if AcquireToken(ResourceUrl, AccessToken) then begin
            if AccessToken <> '' then
                exit(AccessToken);
        end;

        if ShowDialog then
            AuthorizationCode := AzureADAccessDialog.GetAuthorizationCode(ResourceUrl, ResourceName);
        if AuthorizationCode <> '' then
            AccessToken := AcquireTokenByAuthorizationCode(AuthorizationCode, ResourceUrl);
    end;

    [Scope('OnPrem')]
    procedure GetGuestAccessToken(ResourceUrl: Text; GuestTenantId: Text) AccessToken: Text
    begin
        // Gets an access token for a guest user on a different tenant
        if AcquireGuestToken(ResourceUrl, GuestTenantId, AccessToken) then begin
            if AccessToken <> '' then
                exit(AccessToken);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetOnBehalfAccessToken(ResourceUrl: Text): Text
    var
        AzureADAuthFlow: Codeunit "Azure AD Auth Flow";
    begin
        AzureADAuthFlow.Initialize(GetRedirectUrl);
        exit(AzureADAuthFlow.AcquireOnBehalfOfToken(ResourceUrl));
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetOnBehalfAccessTokenAndTokenCacheState(ResourceUrl: Text; var TokenCacheState: Text): Text
    var
        AzureADAuthFlow: Codeunit "Azure AD Auth Flow";
    begin
        AzureADAuthFlow.Initialize(GetRedirectUrl);
        exit(AzureADAuthFlow.AcquireOnBehalfOfTokenAndTokenCacheState(ResourceUrl, TokenCacheState));
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetTokenFromTokenCacheState(ResourceId: Text; AadUserId: Text; TokenCacheState: Text; var NewTokenCacheState: Text): Text
    var
        AzureADAuthFlow: Codeunit "Azure AD Auth Flow";
    begin
        AzureADAuthFlow.Initialize(GetRedirectUrl);
        exit(AzureADAuthFlow.AcquireTokenFromCacheState(ResourceId, AadUserId, TokenCacheState, NewTokenCacheState));
    end;

    local procedure UrlEncode(UrlComponent: Text): Text
    var
        HttpUtility: DotNet HttpUtility;
    begin
        exit(HttpUtility.UrlEncode(UrlComponent));
    end;

    procedure GetAzureADAuthEndpoint(): Text
    var
        UrlHelper: Codeunit "Url Helper";
    begin
        exit(UrlHelper.GetAzureADAuthEndpoint);
    end;

    [Scope('OnPrem')]
    procedure GetDefaultRedirectUrl(): Text[150]
    var
        UriBuilder: DotNet UriBuilder;
        PathString: DotNet String;
    begin
        // Due to a bug in ADAL 2.9, it will not consider URI's to be equal if one URI specified the default port number (ex: 443 for HTTPS)
        // and the other did not. UriBuilder(...).Uri.ToString() is a way to remove any protocol-default port numbers, such as 80 for HTTP
        // and 443 for HTTPS. This bug appears to be fixed in ADAL 3.1+.
        UriBuilder := UriBuilder.UriBuilder(GetUrl(CLIENTTYPE::Web));

        // Append a '/' character to the end of the path if one does not exist already.
        PathString := UriBuilder.Path;
        if PathString.LastIndexOf('/') < (PathString.Length - 1) then
            UriBuilder.Path := UriBuilder.Path + '/';

        // Append the desired redirect page to the path.
        UriBuilder.Path := UriBuilder.Path + OAuthLandingPageTxt;
        UriBuilder.Query := '';

        // Pull out the full URL by the URI and convert it to a string.
        exit(UriBuilder.Uri.ToString);
    end;

    [Scope('OnPrem')]
    procedure GetRedirectUrl(): Text[150]
    begin
        if not IsSaaS and not AzureADAppSetup.IsEmpty then begin
            // Use existing redirect URL if already in table - necessary for Windows client which would otherwise
            // generate a different URL for each computer and thus not match the company's Azure application.
            AzureADAppSetup.FindFirst;
            exit(AzureADAppSetup."Redirect URL");
        end;

        exit(GetDefaultRedirectUrl);
    end;

    procedure GetO365Resource(): Text
    var
        UrlHelper: Codeunit "Url Helper";
    begin
        exit(UrlHelper.GetO365Resource);
    end;

    procedure GetO365ResourceName(): Text
    begin
        exit(O365ResourceNameTxt);
    end;

    procedure IsSaaS(): Boolean
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        exit(EnvironmentInfo.IsSaaS);
    end;

    local procedure GetClientId() ClientID: Text
    var
        AzureADAuthFlow: Codeunit "Azure AD Auth Flow";
    begin
        if IsSaaS then begin
            AzureADAuthFlow.Initialize(GetRedirectUrl);
            ClientID := AzureADAuthFlow.GetSaasClientId;
        end else begin
            if AzureADAppSetup.IsEmpty then
                Error(AzureADNotSetupErr, PRODUCTNAME.Short);

            AzureADAppSetup.FindFirst;
            ClientID := TypeHelper.GetGuidAsString(AzureADAppSetup."App ID");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetInitialTenantDomainName() InitialTenantDomainName: Text
    var
        AzureADAuthFlow: Codeunit "Azure AD Auth Flow";
    begin
        if IsSaaS then begin
            AzureADAuthFlow.Initialize(GetRedirectUrl);
            InitialTenantDomainName := AzureADAuthFlow.GetInitialTenantDomainName;
        end;
    end;

    procedure IsAzureADAppSetupDone(): Boolean
    begin
        if (not IsSaaS) and AzureADAppSetup.IsEmpty then
            exit(false);

        exit(true);
    end;

    [Obsolete('To add the record "Azure AD App Setup Wizard" in the Assisted Setup table use the method Add provided in the Assisted Setup codeunit','16.0')]
    procedure CreateAssistedSetup()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Info: ModuleInfo;
        AssistedSetupGroup: Enum "Assisted Setup Group";
    begin
        if IsSaaS() then
            exit;
        NavApp.GetCurrentModuleInfo(Info);
        AssistedSetup.Add(Info.Id(), PAGE::"Azure AD App Setup Wizard", AzureAdSetupTxt, AssistedSetupGroup::GettingStarted);
        if IsAzureADAppSetupDone then
            AssistedSetup.Complete(PAGE::"Azure AD App Setup Wizard");
    end;

    [Scope('OnPrem')]
    procedure CreateExchangeServiceWrapperWithToken(Token: Text; var Service: DotNet ExchangeServiceWrapper)
    var
        AzureADAuthFlow: Codeunit "Azure AD Auth Flow";
    begin
        AzureADAuthFlow.CreateExchangeServiceWrapperWithToken(Token, Service);
    end;

    [TryFunction]
    local procedure AcquireGuestToken(ResourceName: Text; GuestTenantId: Text; var AccessToken: Text)
    var
        AzureADAuthFlow: Codeunit "Azure AD Auth Flow";
    begin
        if IsSaaS then begin
            // This is SaaS-only functionality at this point, so On-Prem/PaaS will not retrieve an access token
            AzureADAuthFlow.Initialize(GetRedirectUrl);
            AccessToken := AzureADAuthFlow.AcquireGuestToken(ResourceName, GuestTenantId);
        end else
            AccessToken := '';
    end;

    [TryFunction]
    local procedure AcquireToken(ResourceName: Text; var AccessToken: Text)
    var
        AzureADAuthFlow: Codeunit "Azure AD Auth Flow";
    begin
        // This function will return access token for a resource
        // Need to run the Azure AD Setup wizard before calling into this.
        // Returns empty string if access token not available

        AzureADAuthFlow.Initialize(GetRedirectUrl);

        if IsSaaS then
            AccessToken := AzureADAuthFlow.AcquireTokenFromCache(ResourceName)
        else begin
            AzureADAppSetup.FindFirst;
            AccessToken := AzureADAuthFlow.AcquireTokenFromCacheWithCredentials(
                GetClientId,
                AzureADAppSetup.GetSecretKey,
                ResourceName);
        end;
    end;
}

