// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using System;
#if not CLEAN24
#pragma warning disable AL0432
codeunit 10174 "EInvoice OnPrem Communication" implements "EInvoice Communication", "EInvoice Communication V2"
#pragma warning restore AL0432
#else
codeunit 10174 "EInvoice OnPrem Communication" implements "EInvoice Communication V2"
#endif
{
    Access = Internal;

    var
        Parameters: DotNet GenericList1;

#if not CLEAN24
    [NonDebuggable]
    [Obsolete('Replaced by InvokeMethodWithCertificate with SecretText data type for CertPassword parameter', '24.0')]
    procedure InvokeMethodWithCertificate(Uri: Text; MethodName: Text; CertBase64: Text; CertPassword: Text) Response: Text;
    begin
        if not TryToInvokeMethodWithCertificate(Uri, MethodName, CertBase64, CertPassword, Response) then
            Error(GetLastErrorText());
    end;

    [NonDebuggable]
    [Obsolete('Replaced by SignDataWithCertificate with SecretText data type for CertPassword parameter', '24.0')]
    procedure SignDataWithCertificate(OriginalString: Text; Cert: Text; CertPassword: Text) Response: Text;
    begin
        if not TryToSignDataWithCertificate(OriginalString, Cert, CertPassword, Response) then
            Error(GetLastErrorText());
    end;
#endif

    [NonDebuggable]
    procedure InvokeMethodWithCertificate(Uri: Text; MethodName: Text; CertBase64: Text; CertPassword: SecretText) Response: Text;
    begin
        if not TryToInvokeMethodWithCertificate(Uri, MethodName, CertBase64, CertPassword, Response) then
            Error(GetLastErrorText());
    end;

    [NonDebuggable]
    procedure SignDataWithCertificate(OriginalString: Text; Cert: Text; CertPassword: SecretText) Response: Text;
    begin
        if not TryToSignDataWithCertificate(OriginalString, Cert, CertPassword, Response) then
            Error(GetLastErrorText());
    end;

    [NonDebuggable]
    [TryFunction]
    local procedure TryToInvokeMethodWithCertificate(Uri: Text; MethodName: Text; CertBase64: Text; CertPassword: SecretText; var Response: Text);
    var
        SOAPWebServiceInvoker: DotNet SOAPWebServiceInvoker;
    begin
        Response := SOAPWebServiceInvoker.InvokeMethodWithCertificate(Uri, MethodName, CertBase64, CertPassword.Unwrap(), Parameters);
    end;

    [NonDebuggable]
    [TryFunction]
    local procedure TryToSignDataWithCertificate(OriginalString: Text; Cert: Text; CertPassword: SecretText; var Response: Text);
    var
        CFDISignatureProvider: DotNet CFDISignatureProvider;
    begin
        Response := CFDISignatureProvider.SignDataWithCertificate(OriginalString, Cert, CertPassword.Unwrap());
    end;

    procedure AddParameters(Parameter: Variant)
    begin
        if IsNull(Parameters) then
            Parameters := Parameters.List();
        Parameters.Add(Parameter);
    end;
}
