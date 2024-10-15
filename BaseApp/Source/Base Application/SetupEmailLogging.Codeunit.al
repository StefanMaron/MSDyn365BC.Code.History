#if not CLEAN22
namespace System.EMail;

using Microsoft.CRM.Outlook;
using Microsoft.CRM.Setup;
using Microsoft.Utilities;
using System;
using System.Automation;
using System.Azure.KeyVault;
using System.Environment;
using System.Environment.Configuration;
using System.Globalization;
using System.Integration;
using System.Media;
using System.Security.Encryption;
using System.Security.Authentication;
using System.Threading;

codeunit 1641 "Setup Email Logging"
{
    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    trigger OnRun()
    begin
    end;

    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        EmailLoggingTelemetryCategoryTxt: Label 'AL Email Logging', Locked = true;
        ClearEmailLoggingSetupTxt: Label 'Clear email logging setup.', Locked = true;
        CreateEmailLoggingJobTxt: Label 'Create email logging job.', Locked = true;
        DeleteEmailLoggingJobTxt: Label 'Delete email logging job.', Locked = true;
        MissingClientIdOrSecretErr: Label 'The client ID or client secret have not been initialized.';
        MissingClientIdTelemetryTxt: Label 'The client ID has not been initialized.', Locked = true;
        MissingClientSecretTelemetryTxt: Label 'The client secret has not been initialized.', Locked = true;
        InitializedClientIdTelemetryTxt: Label 'The client ID has been initialized.', Locked = true;
        InitializedClientSecretTelemetryTxt: Label 'The client secret has been initialized.', Locked = true;
        InitializedRedirectUrlTelemetryTxt: Label 'The redirect URL has been initialized.', Locked = true;
        EmailLoggingClientIdAKVSecretNameLbl: Label 'emaillogging-clientid', Locked = true;
        EmailLoggingClientSecretAKVSecretNameLbl: Label 'emaillogging-clientsecret', Locked = true;
        TenantOAuthAuthorityUrlLbl: Label 'https://login.microsoftonline.com/%1/oauth2', Locked = true;
        CommonOAuthAuthorityUrlLbl: Label 'https://login.microsoftonline.com/common/oauth2', Locked = true;
        ScopesLbl: Label 'https://outlook.office.com/.default', Locked = true;
        ClientCredentialsAccessTokenErr: Label 'No client credentials access token received', Locked = true;
        AccessTokenErrMsg: Label 'Failed to acquire an access token.';
        AuthTokenOrCodeNotReceivedErr: Label 'No access token or authorization error code received.', Locked = true;
        AdminAccessTokenReceivedTxt: Label 'Admin access token has been received.', Locked = true;
        ClientAccessTokenReceivedTxt: Label 'Client access token has been received.', Locked = true;
        AcquireAccessTokenTxt: Label 'Asquire access token.', Locked = true;
        IgnoredClientCredentialsTxt: Label 'Ignored client credentials.', Locked = true;
        InvalidClientCredentialsTxt: Label 'Invalid client credentials.', Locked = true;
        EmptyRedirectUrlTxt: Label 'Redirect URL is empty, the default URL will be used.', Locked = true;
        FolderDoesNotExistErr: Label 'The specified Exchange folder does not exist.';
        FolderDoesNotExistTxt: Label 'Exchange folder %1 (%2) does not exist.', Locked = true;
        SetupEmailLoggingTitleTxt: Label 'Set up email logging';
        SetupEmailLoggingShortTitleTxt: Label 'Set up email logging';
        SetupEmailLoggingHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115467', Locked = true;
        VideoUrlSetupEmailLoggingTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843360', Locked = true;
        SetupEmailLoggingDescriptionTxt: Label 'Track email exchanges between your sales team and your customers and prospects, and then turn the emails into actionable opportunities.';
        EmptyAccessTokenTxt: Label 'Access token is empty.', Locked = true;
        TenantIdExtractedTxt: Label 'Tenant ID has been extracted from token.', Locked = true;
        CannotExtractTenantIdTxt: Label 'Cannot extract tenant ID from token.', Locked = true;
        CannotExtractTenantIdErr: Label 'Cannot extract tenant ID from the access token.';

    [Scope('OnPrem')]
    procedure GetExchangeFolder(var ExchangeWebServicesClient: Codeunit "Exchange Web Services Client"; var ExchangeFolder: Record "Exchange Folder"; FoldersCaption: Text): Boolean
    var
        ExchangeFoldersPage: Page "Exchange Folders";
        FolderID: Text;
    begin
        ExchangeFoldersPage.Initialize(ExchangeWebServicesClient, FoldersCaption);
        ExchangeFoldersPage.LookupMode(true);
        if Action::LookupOK = ExchangeFoldersPage.RunModal() then begin
            ExchangeFoldersPage.GetRecord(ExchangeFolder);
            FolderID := ExchangeFolder.ReadUniqueID();
            if not ExchangeWebServicesClient.FolderExists(FolderID) then begin
                Session.LogMessage('0000D9L', StrSubstNo(FolderDoesNotExistTxt, FolderID, ExchangeFolder.FullPath), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                Error(FolderDoesNotExistErr);
            end;
            exit(true);
        end;
        exit(false);
    end;

    procedure GetDomainFromEmail(Email: Text): Text
    begin
        exit(DelStr(Email, 1, StrPos(Email, '@')));
    end;

    [Scope('OnPrem')]
    procedure ClearEmailLoggingSetup(var MarketingSetup: Record "Marketing Setup")
    begin
        Session.LogMessage('0000BYG', ClearEmailLoggingSetupTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        Clear(MarketingSetup."Queue Folder Path");
        if MarketingSetup."Queue Folder UID".HasValue() then
            Clear(MarketingSetup."Queue Folder UID");

        Clear(MarketingSetup."Storage Folder Path");
        if MarketingSetup."Storage Folder UID".HasValue() then
            Clear(MarketingSetup."Storage Folder UID");

        Clear(MarketingSetup."Exchange Account User Name");
        Clear(MarketingSetup."Exchange Service URL");
        Clear(MarketingSetup."Autodiscovery E-Mail Address");
        Clear(MarketingSetup."Email Batch Size");

        if not IsNullGuid(MarketingSetup."Exchange Account Password Key") then
            IsolatedStorageManagement.Delete(MarketingSetup."Exchange Account Password Key", DATASCOPE::Company);
        Clear(MarketingSetup."Exchange Account Password Key");

        Clear(MarketingSetup."Exchange Client Id");
        Clear(MarketingSetup."Exchange Redirect URL");

        if not IsNullGuid(MarketingSetup."Exchange Client Secret Key") then
            IsolatedStorageManagement.Delete(MarketingSetup."Exchange Client Secret Key", DATASCOPE::Company);
        Clear(MarketingSetup."Exchange Client Secret Key");

        if not IsNullGuid(MarketingSetup."Exchange Tenant Id Key") then
            IsolatedStorageManagement.Delete(MarketingSetup."Exchange Tenant Id Key", DATASCOPE::Company);
        Clear(MarketingSetup."Exchange Tenant Id Key");

        Clear(MarketingSetup."Email Logging Enabled");

        MarketingSetup.Modify();
    end;

    procedure CreateEmailLoggingJobQueueSetup()
    var
        JobQueueEntry: Record "Job Queue Entry";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        Session.LogMessage('0000BYK', CreateEmailLoggingJobTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Email Logging Context Adapter");
        JobQueueEntry.DeleteTasks();

        WorkflowSetup.CreateJobQueueEntry(
          JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Email Logging Context Adapter",
          '',
          CreateDateTime(Today, Time + 60000),
          10);
    end;

    [Scope('OnPrem')]
    procedure DeleteEmailLoggingJobQueueSetup()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        Session.LogMessage('0000CIO', DeleteEmailLoggingJobTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Email Logging Context Adapter");
        JobQueueEntry.DeleteTasks();
    end;

    [Scope('OnPrem')]
    procedure PromptClientCredentials(var ClientId: Text[250]; var ClientSecret: Text[250]; var RedirectURL: Text[2048]): Boolean
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        OAuth2: Codeunit "OAuth2";
        DefaultRedirectURL: Text;
    begin
        TempNameValueBuffer.ID := 1;
        TempNameValueBuffer.Name := ClientId;
        TempNameValueBuffer.Value := ClientSecret;
        if RedirectURL = '' then begin
            OAuth2.GetDefaultRedirectUrl(DefaultRedirectURL);
            TempNameValueBuffer."Value Long" := CopyStr(DefaultRedirectURL, 1, MaxStrLen(TempNameValueBuffer."Value Long"));
        end else
            TempNameValueBuffer."Value Long" := RedirectURL;
        TempNameValueBuffer.Insert();
        Commit();
        if Page.RunModal(Page::"Exchange Client Credentials", TempNameValueBuffer) <> Action::LookupOK then begin
            Session.LogMessage('0000CIH', IgnoredClientCredentialsTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(false);
        end;
        if (TempNameValueBuffer.Name = '') or (TempNameValueBuffer.Value = '') then begin
            Session.LogMessage('0000CII', InvalidClientCredentialsTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(false);
        end;
        if TempNameValueBuffer."Value Long" = '' then
            Session.LogMessage('0000CL6', EmptyRedirectUrlTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        ClientId := TempNameValueBuffer.Name;
        ClientSecret := TempNameValueBuffer.Value;
        RedirectURL := TempNameValueBuffer."Value Long";
        exit(true);
    end;


    [Scope('OnPrem')]
    [NonDebuggable]
    procedure PromptAdminConsent(var AccessToken: Text)
    begin
        PromptAdminConsent('', '', '', AccessToken);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure PromptAdminConsent(ClientId: Text; ClientSecret: Text; RedirectURL: Text; var AccessToken: Text)
    var
        OAuth2: Codeunit OAuth2;
        PromptInteraction: Enum "Prompt Interaction";
        Scopes: List of [Text];
        AuthError: Text;
    begin
        if (ClientId = '') or (ClientSecret = '') then begin
            ClientId := GetClientId();
            ClientSecret := GetClientSecret();
        end;
        if RedirectURL = '' then
            RedirectURL := GetRedirectURL();

        Session.LogMessage('0000D9M', AcquireAccessTokenTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        Scopes.Add(ScopesLbl);
        OAuth2.AcquireTokenByAuthorizationCode(
            ClientId,
            ClientSecret,
            CommonOAuthAuthorityUrlLbl,
            RedirectURL,
            Scopes,
            PromptInteraction::Consent, AccessToken, AuthError
        );
        if AccessToken = '' then begin
            if AuthError <> '' then
                Session.LogMessage('0000CFA', AuthError, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt)
            else
                Session.LogMessage('0000CFB', AuthTokenOrCodeNotReceivedErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(AccessTokenErrMsg);
        end;
        Session.LogMessage('0000D9N', AdminAccessTokenReceivedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
    end;

#if not CLEAN24
    [NonDebuggable]
    [Obsolete('Use "GetClientCredentialsAccessToken(TenantId: SecretText; var AccessToken: SecretText)" instead.', '24.0')]
    procedure GetClientCredentialsAccessToken(TenantId: Text; var AccessToken: Text)
    var
        AccessTokenAsSecret: SecretText;
    begin
        AccessTokenAsSecret := AccessToken;
        GetClientCredentialsAccessToken(TenantId, AccessTokenAsSecret);
        AccessToken := AccessTokenAsSecret.Unwrap();
    end;
#endif
    [Scope('OnPrem')]
    procedure GetClientCredentialsAccessToken(TenantId: SecretText; var AccessToken: SecretText)
    var
        EmptyTxt: Text;
    begin
        EmptyTxt := '';
        GetClientCredentialsAccessToken(EmptyTxt, EmptyTxt, EmptyTxt, TenantId, AccessToken);
    end;

#if not CLEAN24
    [Scope('OnPrem')]
    [NonDebuggable]
    [Obsolete('Use "GetClientCredentialsAccessToken(ClientId: SecretText; ClientSecret: SecretText; RedirectURL: Text; TenantId: SecretText; var AccessToken: SecretText)" instead.', '24.0')]
    procedure GetClientCredentialsAccessToken(ClientId: Text; ClientSecret: Text; RedirectURL: Text; TenantId: Text; var AccessToken: Text)
    var
        AccessTokenAsSecret: SecretText;
    begin
        AccessTokenAsSecret := AccessToken;
        GetClientCredentialsAccessToken(ClientId, ClientSecret, RedirectURL, TenantId, AccessToken);
        AccessToken := AccessTokenAsSecret.Unwrap();
    end;
#endif
    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetClientCredentialsAccessToken(ClientId: SecretText; ClientSecret: SecretText; RedirectURL: Text; TenantId: SecretText; var AccessToken: SecretText)
    var
        OAuth2: Codeunit OAuth2;
        Scopes: List of [Text];
        AccesTokenAsText: Text;
    begin
        AccesTokenAsText := AccessToken.Unwrap();
        if ClientId.IsEmpty() or ClientSecret.IsEmpty() then begin
            ClientId := GetClientId();
            ClientSecret := GetClientSecret();
        end;
        if RedirectURL = '' then
            RedirectURL := GetRedirectURL();

        Scopes.Add(ScopesLbl);

        OAuth2.AcquireTokenWithClientCredentials(
                    ClientId.Unwrap(),
                    ClientSecret.Unwrap(),
                    StrSubstNo(TenantOAuthAuthorityUrlLbl, TenantId.Unwrap()),
                    RedirectURL,
                    Scopes,
                    AccesTokenAsText
                );
        AccessToken := AccesTokenAsText;
        if AccessToken.IsEmpty() then begin
            Session.LogMessage('0000CFC', ClientCredentialsAccessTokenErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(AccessTokenErrMsg);
        end;
        Session.LogMessage('0000D9O', ClientAccessTokenReceivedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure ExtractTenantIdFromAccessToken(var TenantId: Text; AccessToken: Text)
    begin
        if AccessToken <> '' then begin
            if TryExtractTenantIdFromAccessToken(TenantId, AccessToken) then begin
                if TenantId <> '' then begin
                    Session.LogMessage('0000D9P', TenantIdExtractedTxt, Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                    exit;
                end;
                Session.LogMessage('0000CR1', CannotExtractTenantIdTxt, Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            end else
                Session.LogMessage('0000CR2', CannotExtractTenantIdTxt, Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt)
        end else
            Session.LogMessage('0000CR3', EmptyAccessTokenTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        Error(CannotExtractTenantIdErr);
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure TryExtractTenantIdFromAccessToken(var TenantId: Text; AccessToken: Text)
    var
        JwtSecurityTokenHandler: DotNet JwtSecurityTokenHandler;
        JwtSecurityToken: DotNet JwtSecurityToken;
    begin
        JwtSecurityTokenHandler := JwtSecurityTokenHandler.JwtSecurityTokenHandler();
        JwtSecurityToken := JwtSecurityTokenHandler.ReadToken(AccessToken);
        JwtSecurityToken.Payload().TryGetValue('tid', TenantId);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetClientId(): Text
    var
        MarketingSetup: Record "Marketing Setup";
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
        ClientId: Text;
    begin
        OnGetEmailLoggingClientId(ClientId);
        if ClientId <> '' then begin
            Session.LogMessage('0000CMF', InitializedClientIdTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(ClientId);
        end;

        if EnvironmentInformation.IsSaaSInfrastructure() then
            if not AzureKeyVault.GetAzureKeyVaultSecret(EmailLoggingClientIdAKVSecretNameLbl, ClientId) then
                Session.LogMessage('0000CFD', MissingClientIdTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt)
            else begin
                Session.LogMessage('0000CMD', InitializedClientIdTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                exit(ClientId);
            end;

        if MarketingSetup.Get() then begin
            ClientId := MarketingSetup."Exchange Client Id";
            if ClientId <> '' then begin
                Session.LogMessage('0000CME', InitializedClientIdTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                exit(ClientId);
            end;
        end;

        Session.LogMessage('0000D9Q', MissingClientIdTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        Error(MissingClientIdOrSecretErr);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetClientSecret(): Text
    var
        MarketingSetup: Record "Marketing Setup";
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
        ClientSecret: Text;
    begin
        OnGetEmailLoggingClientSecret(ClientSecret);
        if ClientSecret <> '' then begin
            Session.LogMessage('0000CMI', InitializedClientSecretTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(ClientSecret);
        end;

        if EnvironmentInformation.IsSaaSInfrastructure() then
            if not AzureKeyVault.GetAzureKeyVaultSecret(EmailLoggingClientSecretAKVSecretNameLbl, ClientSecret) then
                Session.LogMessage('0000CFE', MissingClientSecretTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt)
            else begin
                Session.LogMessage('0000CMG', InitializedClientSecretTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                exit(ClientSecret);
            end;

        if MarketingSetup.Get() then begin
            ClientSecret := MarketingSetup.GetExchangeClientSecret();
            if ClientSecret <> '' then begin
                Session.LogMessage('0000CMH', InitializedClientSecretTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                exit(ClientSecret);
            end;
        end;

        Session.LogMessage('0000D9R', MissingClientSecretTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        Error(MissingClientIdOrSecretErr);
    end;

    internal procedure IsEmailLoggingUsingGraphApiFeatureEnabled() FeatureEnabled: Boolean;
    begin
        FeatureEnabled := true;
    end;

    [Scope('OnPrem')]
    procedure RegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        Language: Codeunit Language;
        ModuleInfo: ModuleInfo;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        GuidedExperienceType: Enum "Guided Experience Type";
        CurrentGlobalLanguage: Integer;
    begin
        if IsEmailLoggingUsingGraphApiFeatureEnabled() then begin
            if GuidedExperience.Exists(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Setup Email Logging") then
                GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Setup Email Logging");
            exit;
        end;

        if GuidedExperience.Exists(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Setup Email Logging") then
            exit;

        CurrentGlobalLanguage := GLOBALLANGUAGE;
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        GuidedExperience.InsertAssistedSetup(SetupEmailLoggingTitleTxt, SetupEmailLoggingShortTitleTxt, SetupEmailLoggingDescriptionTxt, 10, ObjectType::Page,
            Page::"Setup Email Logging", AssistedSetupGroup::ApprovalWorkflows, VideoUrlSetupEmailLoggingTxt, VideoCategory::ApprovalWorkflows, SetupEmailLoggingHelpTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Setup Email Logging",
            Language.GetDefaultApplicationLanguageId(), SetupEmailLoggingTitleTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetRedirectURL(): Text
    var
        MarketingSetup: Record "Marketing Setup";
        EnvironmentInformation: Codeunit "Environment Information";
        RedirectURL: Text;
    begin
        OnGetEmailLoggingRedirectURL(RedirectURL);
        if RedirectURL <> '' then begin
            Session.LogMessage('0000DUZ', InitializedRedirectUrlTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(RedirectURL);
        end;

        if EnvironmentInformation.IsSaaSInfrastructure() then
            exit('');

        if MarketingSetup.Get() then
            exit(MarketingSetup."Exchange Redirect URL");

        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEmailLoggingClientId(var ClientId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEmailLoggingClientSecret(var ClientSecret: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEmailLoggingRedirectURL(var RedirectURL: Text)
    begin
    end;
}
#endif
