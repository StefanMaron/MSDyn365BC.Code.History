﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using System;
using System.Azure.Functions;
using System.Azure.KeyVault;
using System.Utilities;

#if not CLEAN24
#pragma warning disable AL0432
codeunit 10175 "EInvoice SaaS Communication" implements "EInvoice Communication", "EInvoice Communication V2"
#pragma warning restore AL0432
#else
codeunit 10175 "EInvoice SaaS Communication" implements "EInvoice Communication V2"
#endif
{
    Access = Internal;

    var
        Parameters: JsonArray;
        ClientIDLbl: label 'AppNetProxyFnClientID', Locked = true;
        ClientSecretLbl: label 'AppNetProxyFnClientSecret', Locked = true;
        ResourceUrLLbl: label 'AppNetProxyFnResourceUrL', Locked = true;
        EndpointLbl: Label 'AppNetProxyFnEndpoint', Locked = true;
        AuthURlLbl: Label 'AppNetProxyFnAuthUrl', Locked = true;
        FunctionSecretErr: Label 'There was an error connecting to the service.';
        MXElectronicInvoicingTok: Label 'MXElectronicInvoicingTelemetryCategoryTok', Locked = true;
        ResponseErr: Label 'There was an error while connecting to the service. Error message: %1', Comment = '%1=Error message';
        RequestSuccessfulMsg: label 'CFDI request was submitted successfully', Locked = true;
        RequestFailedMsg: label 'CFDI request failed with reason: %1, and error message: %2', Locked = true;
        SecretsMissingMsg: label 'CFDI Az Function secrets are  missing', Locked = true;

#if not CLEAN24
    [NonDebuggable]
    [Obsolete('Replaced by InvokeMethodWithCertificate with SecretText datatype for CertPassword parameter.', '24.0')]
    procedure InvokeMethodWithCertificate(Uri: Text; MethodName: Text; CertBase64: Text; CertPassword: Text): Text
    var
        JsonObj: JsonObject;
        JValue: JsonValue;
        SerializedText, Token : Text;
    begin
        JsonObj.Add('url', Uri);
        JsonObj.Add('methodName', MethodName);
        JsonObj.Add('parameters', Parameters);
        CheckToDownloadSaaSRequest(JsonObj);

        JsonObj.Add('certificateString', CertBase64);
        JsonObj.Add('certificatePassword', CertPassword);
        JsonObj.WriteTo(SerializedText);

        Token := CommunicateWithAzureFunction('api/InvokeMethodWithCertificate', SerializedText);
        JValue.ReadFrom(Token);
        exit(JValue.AsText());
    end;

    [NonDebuggable]
    [Obsolete('Replaced by SignDataWithCertificate with SecretText datatype for CertPassword parameter.', '24.0')]
    procedure SignDataWithCertificate(OriginalString: Text; Cert: Text; CertPassword: Text): Text
    var
        SerializedText, Token : Text;
        JValue: JsonValue;
        JsonObj: JsonObject;
    begin
        ExportCertAsPFX(Cert, CertPassword);

        JsonObj.Add('data', OriginalString);
        JsonObj.Add('certificateString', Cert);
        JsonObj.Add('certificatePassword', CertPassword);
        JsonObj.WriteTo(SerializedText);

        Token := CommunicateWithAzureFunction('api/SignDataWithCertificate', SerializedText);
        if JValue.ReadFrom(Token) then
            exit(JValue.AsText())
        else
            exit(Token);
    end;
#endif

    [NonDebuggable]
    procedure InvokeMethodWithCertificate(Uri: Text; MethodName: Text; CertBase64: Text; CertPassword: SecretText): Text
    var
        JsonObj: JsonObject;
        JValue: JsonValue;
        SerializedText, Token : Text;
    begin
        JsonObj.Add('url', Uri);
        JsonObj.Add('methodName', MethodName);
        JsonObj.Add('parameters', Parameters);
        CheckToDownloadSaaSRequest(JsonObj);

        JsonObj.Add('certificateString', CertBase64);
        JsonObj.Add('certificatePassword', CertPassword.Unwrap());
        JsonObj.WriteTo(SerializedText);

        Token := CommunicateWithAzureFunction('api/InvokeMethodWithCertificate', SerializedText);
        JValue.ReadFrom(Token);
        exit(JValue.AsText());
    end;

    [NonDebuggable]
    procedure SignDataWithCertificate(OriginalString: Text; Cert: Text; CertPassword: SecretText): Text
    var
        SerializedText, Token : Text;
        JValue: JsonValue;
        JsonObj: JsonObject;
    begin
        ExportCertAsPFX(Cert, CertPassword);

        JsonObj.Add('data', OriginalString);
        JsonObj.Add('certificateString', Cert);
        JsonObj.Add('certificatePassword', CertPassword.Unwrap());
        JsonObj.WriteTo(SerializedText);

        Token := CommunicateWithAzureFunction('api/SignDataWithCertificate', SerializedText);
        if JValue.ReadFrom(Token) then
            exit(JValue.AsText())
        else
            exit(Token);
    end;

    procedure AddParameters(Parameter: Variant)
    var
        BooleanParameter: Boolean;
    begin
        if Parameter.IsBoolean then begin
            BooleanParameter := Parameter;
            Parameters.Add(BooleanParameter);
        end else
            Parameters.Add(Format(Parameter, 0, 9));
    end;

    [NonDebuggable]
    local procedure CommunicateWithAzureFunction(Path: Text; Body: Text): Text
    var
        AzureFunctions: Codeunit "Azure Functions";
        AzureFunctionsAuthentication: Codeunit "Azure Functions Authentication";
        AzureFunctionsResponse: Codeunit "Azure Functions Response";
        IAzurefunctionsAuthentication: Interface "Azure Functions Authentication";
        Response, ErrorMsg : Text;
        ClientID, ClientSecret, ResourceUrL, Endpoint, AuthUrl : Text;
    begin
        GetAzFunctionSecrets(ClientID, ClientSecret, ResourceUrL, Endpoint, AuthUrl);
        IAzurefunctionsAuthentication := AzureFunctionsAuthentication.CreateOAuth2(GetEndpoint(Endpoint, Path), '', ClientID, ClientSecret, AuthUrl, '', ResourceUrL);

        AzureFunctionsResponse := AzureFunctions.SendPostRequest(IAzurefunctionsAuthentication, Body, 'application/json');

        if AzureFunctionsResponse.IsSuccessful() then begin
            AzureFunctionsResponse.GetResultAsText(Response);
            Session.LogMessage('0000JOX', RequestSuccessfulMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
            exit(Response);
        end else begin
            AzureFunctionsResponse.GetError(ErrorMsg);
            Session.LogMessage('0000JOY', StrSubstNo(RequestFailedMsg, AzureFunctionsResponse.GetError(), ErrorMsg), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
            Error(ResponseErr, AzureFunctionsResponse.GetError());
        end;
    end;

    [NonDebuggable]
    local procedure GetAzFunctionSecrets(var ClientID: Text; var ClientSecret: Text; var ResourceUrL: Text; var Endpoint: Text; var AuthUrl: Text)
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
    begin
        if not (AzureKeyVault.GetAzureKeyVaultSecret(ClientIDLbl, ClientID)
                and AzureKeyVault.GetAzureKeyVaultSecret(ClientSecretLbl, ClientSecret)
                and AzureKeyVault.GetAzureKeyVaultSecret(ResourceUrLLbl, ResourceUrL)
                and AzureKeyVault.GetAzureKeyVaultSecret(AuthURlLbl, AuthUrl)
                and AzureKeyVault.GetAzureKeyVaultSecret(EndpointLbl, Endpoint)) then begin
            Session.LogMessage('0000JOZ', SecretsMissingMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
            Error(FunctionSecretErr);
        end;
    end;

    local procedure GetEndpoint(Host: Text; Path: Text): text
    var
        URIBuilder: Codeunit "Uri Builder";
        URI: Codeunit URI;
    begin
        URIBuilder.Init(Host);
        URIBuilder.SetPath(Path);
        URIBuilder.GetUri(URI);
        exit(URI.GetAbsoluteUri());
    end;

    [NonDebuggable]
    local procedure ExportCertAsPFX(var CertBase64: Text; CertPassword: SecretText)
    var
        X509Certificate2: DotNet X509Certificate2;
        X509Content: DotNet X509ContentType;
        X509KeyFlags: DotNet X509KeyStorageFlags;
        Convert: DotNet Convert;
    begin
        X509Certificate2 := X509Certificate2.X509Certificate2(Convert.FromBase64String(CertBase64), CertPassword.Unwrap(), X509KeyFlags.Exportable);
        CertBase64 := Convert.ToBase64String(X509Certificate2.Export(X509Content.Pfx, CertPassword.Unwrap()));
    end;

    [NonDebuggable]

    local procedure CheckToDownloadSaaSRequest(JsonObj: JsonObject)
    var
        MXElectronicInvoicingSetup: Record "MX Electronic Invoicing Setup";
        TempBlob: Codeunit "Temp Blob";
        SerializedText: Text;
        DocOutStream: OutStream;
        DocInStream: InStream;
        DocFileName: text;
    begin
        JsonObj.WriteTo(SerializedText);

        if MXElectronicInvoicingSetup.Get() then
            if MXElectronicInvoicingSetup."Download SaaS Request" then begin
                TempBlob.CreateOutStream(DocOutStream);
                DocOutStream.WriteText(SerializedText);
                TempBlob.CreateInStream(DocInStream);

                DocFileName := 'ElectronicInvoiceRequest.txt';
                DownloadFromStream(DocInStream, '', '', '', DocFileName);
            end;
    end;
}
