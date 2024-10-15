// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN22
namespace Microsoft.eServices.EDocument;

using System.Security.Encryption;

codeunit 10149 DotNet_ISignatureProvider
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Signature provider is deprecated, use EInvoice Communication codeunit instead.';
    ObsoleteTag = '22.0';

    var
        EInvoiceCommunication: Codeunit "EInvoice Communication";

    procedure SignDataWithCertificate(Data: Text; Certificate: Text; DotNet_SecureString: Codeunit DotNet_SecureString): Text
    begin
        exit(EInvoiceCommunication.SignDataWithCertificate(Data, Certificate, DotNet_SecureString.GetPlainText()));
    end;

    procedure LastUsedCertificate(): Text
    begin
        exit(EInvoiceCommunication.LastUsedCertificate());
    end;

    procedure LastUsedCertificateSerialNo(): Text
    begin
        exit(EInvoiceCommunication.LastUsedCertificateSerialNo());
    end;
}
#endif
