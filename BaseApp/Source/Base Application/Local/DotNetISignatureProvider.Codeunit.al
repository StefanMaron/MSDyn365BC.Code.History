codeunit 10149 DotNet_ISignatureProvider
{

    trigger OnRun()
    begin
    end;

    var
        DotNetISignatureProvider: DotNet ISignatureProvider;

    procedure SignDataWithCertificate(Data: Text; Certificate: Text; DotNet_SecureString: Codeunit DotNet_SecureString): Text
    var
        EInvoiceObjectFactory: Codeunit "E-Invoice Object Factory";
        SecureStringPassword: DotNet SecureString;
    begin
        EInvoiceObjectFactory.GetSignatureProvider(DotNetISignatureProvider);
        DotNet_SecureString.GetSecureString(SecureStringPassword);
        exit(DotNetISignatureProvider.SignDataWithCertificate(Data, Certificate, SecureStringPassword));
    end;

    procedure LastUsedCertificate(): Text
    begin
        exit(DotNetISignatureProvider.LastUsedCertificate);
    end;

    procedure LastUsedCertificateSerialNo(): Text
    begin
        exit(DotNetISignatureProvider.LastUsedCertificateSerialNo);
    end;

    [Scope('OnPrem')]
    procedure GetISignatureProvider(var DotNetISignatureProvider2: DotNet ISignatureProvider)
    begin
        DotNetISignatureProvider2 := DotNetISignatureProvider;
    end;

    [Scope('OnPrem')]
    procedure SetISignatureProvider(var DotNetISignatureProvider2: DotNet ISignatureProvider)
    begin
        DotNetISignatureProvider := DotNetISignatureProvider2;
    end;
}

