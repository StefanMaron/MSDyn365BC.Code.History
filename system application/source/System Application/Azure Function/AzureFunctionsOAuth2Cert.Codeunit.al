// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Functions;

using System.Utilities;
using System.Security.Authentication;
using System.Telemetry;

codeunit 7807 "Azure Functions OAuth2 Cert" implements "Azure Functions Authentication"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        [NonDebuggable]
        AuthenticationCodeGlobal, EndpointGlobal : Text;
        [NonDebuggable]
        ClientIdGlobal, OAuthAuthorityUrlGlobal, RedirectURLGlobal : Text;
        CertGlobal: SecretText;
        [NonDebuggable]
        AccessToken: Text;
        ScopesGlobal: List of [Text];
        BearerLbl: Label 'Bearer %1', Locked = true;
        FailedToGetTokenErr: Label 'Authorization failed to Azure function: %1', Locked = true;
        AzureFunctionCategoryLbl: Label 'Connect to Azure Functions', Locked = true;

    [NonDebuggable]
    procedure Authenticate(var RequestMessage: HttpRequestMessage): Boolean
    var
        Uri: Codeunit Uri;
        OAuth2: Codeunit OAuth2;
        UriBuilder: Codeunit "Uri Builder";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Headers: HttpHeaders;
        Dimensions: Dictionary of [Text, Text];
        IdToken: Text;
    begin
        UriBuilder.Init(EndpointGlobal);

        OAuth2.AcquireTokensWithCertificate(ClientIdGlobal, CertGlobal.Unwrap(), RedirectURLGlobal, OAuthAuthorityUrlGlobal, ScopesGlobal, AccessToken, IdToken);

        if AccessToken = '' then begin
            UriBuilder.GetUri(Uri);
            Dimensions.Add('FunctionHost', Format(Uri.GetHost()));
            FeatureTelemetry.LogError('0000I75', AzureFunctionCategoryLbl, 'Acquiring token', StrSubstNo(FailedToGetTokenErr, Uri.GetHost()), '', Dimensions);
            exit(false);
        end;

        RequestMessage.GetHeaders(Headers);
        Headers.Remove('Authorization');
        Headers.Add('Authorization', SecretStrSubstNo(BearerLbl, AccessToken));

        if AuthenticationCodeGlobal <> '' then
            UriBuilder.AddQueryParameter('Code', AuthenticationCodeGlobal);

        UriBuilder.GetUri(Uri);
        RequestMessage.SetRequestUri(Uri.GetAbsoluteUri());
        exit(true);
    end;

    [NonDebuggable]
    procedure SetAuthParameters(Endpoint: Text; AuthenticationCode: Text; ClientId: Text; Cert: SecretText; OAuthAuthorityUrl: Text; RedirectURL: Text; Scopes: List of [Text])
    begin
        EndpointGlobal := Endpoint;
        AuthenticationCodeGlobal := AuthenticationCode;
        ClientIdGlobal := ClientId;
        CertGlobal := Cert;
        OAuthAuthorityUrlGlobal := OAuthAuthorityUrl;
        RedirectURLGlobal := RedirectURL;
        ScopesGlobal := Scopes;
    end;
}