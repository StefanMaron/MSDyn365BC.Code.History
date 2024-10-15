﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

#if not CLEAN21
using System;
using System.Azure.Identity;
using System.Azure.KeyVault;
using System.Email;
using System.Integration;
using System.Text;
using System.Utilities;
#endif

table 407 "Graph Mail Setup"
{
    Caption = 'Graph Mail Setup';
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif
    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; "Refresh Code"; BLOB)
        {
            Caption = 'Refresh Code';
            ObsoleteReason = 'The suggested way to store the secrets is Isolated Storage, therefore this field will be removed.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(3; "Expires On"; DateTime)
        {
            Caption = 'Expires On';
        }
        field(4; "Sender Email"; Text[250])
        {
            Caption = 'Sender Email';
        }
        field(5; "Sender Name"; Text[250])
        {
            Caption = 'Sender Name';
        }
        field(6; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(7; "Sender AAD ID"; Text[80])
        {
            Caption = 'Sender Microsoft Entra ID';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
#if not CLEAN21
    var
        GraphMailCategoryTxt: Label 'AL GraphMail', Locked = true;
        GraphMailSentMsg: Label 'Sent an email', Locked = true;
        GraphMailSetupStartMsg: Label 'Setting up graph mail', Locked = true;
        GraphMailSetupFinishMsg: Label 'Graph mail setup for current user', Locked = true;
        GraphMailGetTokenMsg: Label 'Attempting to get a token using the existing refresh code', Locked = true;
        ClientResourceNameTxt: Label 'MailerResourceId', Locked = true;
        MissingClientInfoErr: Label 'Missing configuration data. Contact a system administrator.';
        InvalidResultErr: Label 'The configuration data is not valid. Contact a system administrator.';
        AuthFailErr: Label 'Could not authenticate while sending mail.';
        NotEnabledErr: Label 'Not enabled.';
        TestEmailSubjectTxt: Label 'Test Email';
        MissingEmailMsg: Label 'It looks like you don''t have an email address set up for your account.\Go to Settings and add it, or try again later if you already have added it.';
        UserInfoFailedErr: Label 'Failed to set the user info.', Locked = true;
        RefreshTokenKeyTxt: Label 'RefreshTokenKey', Locked = true;

    [Scope('OnPrem')]
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure IsEnabled(): Boolean
    var
        GraphMail: Codeunit "Graph Mail";
    begin
        exit(GraphMail.IsEnabled());
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure RenewRefreshToken()
    begin
        GetToken();
    end;

    [NonDebuggable]
    local procedure GetToken(): Text
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        ResourceId: Text;
        TokenCacheState: Text;
        AccessToken: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(ClientResourceNameTxt, ResourceId) then
            Error(MissingClientInfoErr);

        if ResourceId = '' then
            Error(MissingClientInfoErr);

        if not IsEnabled() then
            Error(NotEnabledErr);

        if not TryGetToken(ResourceId, TokenCacheState, "Sender AAD ID", AccessToken) then begin
            if IsolatedStorage.Contains(Format(RefreshTokenKeyTxt), DataScope::Company) then
                IsolatedStorage.Delete(Format(RefreshTokenKeyTxt), DataScope::Company);
            Clear("Expires On");
            Validate(Enabled, false);
            Modify();
            exit;
        end;

        SetRefreshToken(TokenCacheState);
        Validate("Expires On", CreateDateTime(Today + 14, Time));
        Modify();

        exit(AccessToken);
    end;

    [NonDebuggable]
    [TryFunction]
    [Scope('OnPrem')]
    local procedure TryGetToken(ResourceId: Text; var TokenCacheState: Text; AadUserId: Text; var AccessToken: Text)
    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
    begin
        Session.LogMessage('00001QL', GraphMailGetTokenMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphMailCategoryTxt);
        AccessToken := AzureADMgt.GetTokenFromTokenCacheState(ResourceId, AadUserId, GetTokenCacheState(), TokenCacheState);

        if AccessToken = '' then
            Error('');
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure SendTestMail(Recipient: Text)
    var
        TempEmailItem: Record "Email Item" temporary;
        GraphMail: Codeunit "Graph Mail";
        Payload: Text;
    begin
        if Recipient = '' then
            Error('');

        TempEmailItem."Send to" := CopyStr(Recipient, 1, MaxStrLen(TempEmailItem."Send to"));
        TempEmailItem."From Address" := CopyStr("Sender Email", 1, MaxStrLen(TempEmailItem."From Address"));
        TempEmailItem."From Name" := CopyStr("Sender Name", 1, MaxStrLen(TempEmailItem."From Name"));
        TempEmailItem.Subject := TestEmailSubjectTxt;
        TempEmailItem.SetBodyText(GraphMail.GetTestMessageBody());

        Payload := GraphMail.PrepareMessage(TempEmailItem);

        SendWebRequest(Payload, GetToken());
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure SendMail(TempEmailItem: Record "Email Item" temporary; var TokenCacheState: Text)
    var
        GraphMail: Codeunit "Graph Mail";
        AzureKeyVault: Codeunit "Azure Key Vault";
        Payload: Text;
        [NonDebuggable]
        Token: Text;
        ResourceId: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(ClientResourceNameTxt, ResourceId) then
            Error(MissingClientInfoErr);

        if not TryGetToken(ResourceId, TokenCacheState, "Sender AAD ID", Token) then
            Error(AuthFailErr);

        Payload := GraphMail.PrepareMessage(TempEmailItem);

        SendWebRequest(Payload, Token);
        Session.LogMessage('00001QM', GraphMailSentMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphMailCategoryTxt);
    end;

    [NonDebuggable]
    local procedure SendWebRequest(Payload: Text; Token: Text): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        GraphMail: Codeunit "Graph Mail";
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
        ResponseInStream: InStream;
    begin
        TempBlob.CreateInStream(ResponseInStream);

        HttpWebRequestMgt.Initialize(StrSubstNo('%1/v1.0/me/sendMail', GraphMail.GetGraphDomain()));
        HttpWebRequestMgt.SetMethod('POST');
        HttpWebRequestMgt.SetContentType('application/json');
        HttpWebRequestMgt.SetReturnType('application/json');
        HttpWebRequestMgt.AddHeader('Authorization', StrSubstNo('Bearer %1', Token));
        HttpWebRequestMgt.AddBodyAsText(Payload);

        if not HttpWebRequestMgt.GetResponse(ResponseInStream, HttpStatusCode, ResponseHeaders) then begin
            HttpWebRequestMgt.ProcessFaultResponse('');
            exit(false);
        end;

        exit(true);
    end;

    [NonDebuggable]
    local procedure GetTokenCacheState() TokenCacheState: Text
    begin
        TokenCacheState := '';
        if NOT IsolatedStorage.Get(Format(RefreshTokenKeyTxt), DataScope::Company, TokenCacheState) then
            exit('');
        exit(TokenCacheState)
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure SetRefreshToken(Token: Text)
    begin
        IsolatedStorage.Set(Format(RefreshTokenKeyTxt), Token, DataScope::Company);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure Initialize(ShowDialogs: Boolean): Boolean
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureADMgt: Codeunit "Azure AD Mgt.";
        ResourceId: Text;
        TokenCacheState: Text;
        Token: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(ClientResourceNameTxt, ResourceId) then
            Error(MissingClientInfoErr);

        if ResourceId = '' then
            Error(MissingClientInfoErr);

        Session.LogMessage('00001QN', GraphMailSetupStartMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphMailCategoryTxt);
        Token := AzureADMgt.GetOnBehalfAccessTokenAndTokenCacheState(ResourceId, TokenCacheState);

        if Token = '' then
            Error(InvalidResultErr);

        SetRefreshToken(TokenCacheState);
        Validate("Expires On", CreateDateTime(Today + 14, Time));

        if not SetUserFields(Token) then begin
            if GuiAllowed and ShowDialogs then
                Message(MissingEmailMsg);
            Init(); // clean the rec
            Session.LogMessage('00007IB', UserInfoFailedErr, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphMailCategoryTxt);
            exit(false);
        end;

        Session.LogMessage('00001QO', GraphMailSetupFinishMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphMailCategoryTxt);

        exit(true);
    end;

    [NonDebuggable]
    local procedure SetUserFields(Token: Text): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        JSONManagement: Codeunit "JSON Management";
        GraphMail: Codeunit "Graph Mail";
        HttpStatusCode: DotNet HttpStatusCode;
        JsonObject: DotNet JObject;
        ResponseHeaders: DotNet NameValueCollection;
        ResponseInStream: InStream;
        JsonResult: Variant;
        UserProfileJson: Text;
    begin
        TempBlob.CreateInStream(ResponseInStream);

        HttpWebRequestMgt.Initialize(StrSubstNo('%1/v1.0/me/', GraphMail.GetGraphDomain()));
        HttpWebRequestMgt.SetReturnType('application/json');
        HttpWebRequestMgt.AddHeader('Authorization', StrSubstNo('Bearer %1', Token));

        HttpWebRequestMgt.GetResponse(ResponseInStream, HttpStatusCode, ResponseHeaders);
        ResponseInStream.ReadText(UserProfileJson);
        JSONManagement.InitializeObject(UserProfileJson);
        JSONManagement.GetJSONObject(JsonObject);

        JSONManagement.GetPropertyValueFromJObjectByName(JsonObject, 'displayName', JsonResult);
        Validate("Sender Name", JsonResult);

        JSONManagement.GetPropertyValueFromJObjectByName(JsonObject, 'mail', JsonResult);
        Validate("Sender Email", JsonResult);

        JSONManagement.GetPropertyValueFromJObjectByName(JsonObject, 'id', JsonResult);
        Validate("Sender AAD ID", JsonResult);

        if "Sender Email" = '' then
            exit(false);

        exit(true);
    end;
#endif
}

