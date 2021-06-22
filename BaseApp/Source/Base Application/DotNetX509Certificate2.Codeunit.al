codeunit 3043 DotNet_X509Certificate2
{

    trigger OnRun()
    begin
    end;

    var
        DotNetX509Certificate2: DotNet X509Certificate2;
        LoadCertificateErr: Label 'Failed to load certificate.';

    procedure X509Certificate2(DotNet_Array: Codeunit DotNet_Array; Password: Text; DotNet_X509KeyStorageFlags: Codeunit DotNet_X509KeyStorageFlags)
    var
        DotNetArray: DotNet Array;
        DotNetX509KeyStorageFlags: DotNet X509KeyStorageFlags;
    begin
        DotNet_Array.GetArray(DotNetArray);
        DotNet_X509KeyStorageFlags.GetX509KeyStorageFlags(DotNetX509KeyStorageFlags);
        DotNetX509Certificate2 := DotNetX509Certificate2.X509Certificate2(DotNetArray, Password, DotNetX509KeyStorageFlags);

        if IsDotNetNull() then
            Error(LoadCertificateErr);
    end;

    procedure Export(DotNet_X509ContentType: Codeunit DotNet_X509ContentType; Password: Text; var DotNet_Array: Codeunit DotNet_Array)
    var
        DotNetX509ContentType: DotNet X509ContentType;
    begin
        DotNet_X509ContentType.GetX509ContentType(DotNetX509ContentType);
        DotNet_Array.SetArray(DotNetX509Certificate2.Export(DotNetX509ContentType, Password));
    end;

    procedure FriendlyName(): Text
    begin
        exit(DotNetX509Certificate2.FriendlyName);
    end;

    procedure Thumbprint(): Text
    begin
        exit(DotNetX509Certificate2.Thumbprint);
    end;

    procedure Issuer(): Text
    begin
        exit(DotNetX509Certificate2.Issuer);
    end;

    procedure Subject(): Text
    begin
        exit(DotNetX509Certificate2.Subject);
    end;

    procedure Expiration() Expiration: DateTime
    begin
        Evaluate(Expiration, DotNetX509Certificate2.GetExpirationDateString);
    end;

    procedure HasPrivateKey(): Boolean
    begin
        exit(DotNetX509Certificate2.HasPrivateKey);
    end;

    procedure IsDotNetNull(): Boolean
    begin
        exit(IsNull(DotNetX509Certificate2));
    end;

    [Scope('OnPrem')]
    procedure PublicKey(var AsymmetricAlgorithm: Codeunit DotNet_AsymmetricAlgorithm)
    begin
        AsymmetricAlgorithm.SetAsymmetricAlgorithm(DotNetX509Certificate2.PublicKey."Key");
    end;

    [Scope('OnPrem')]
    procedure PrivateKey(var AsymmetricAlgorithm: Codeunit DotNet_AsymmetricAlgorithm)
    begin
        AsymmetricAlgorithm.SetAsymmetricAlgorithm(DotNetX509Certificate2.PrivateKey);
    end;

    [Scope('OnPrem')]
    procedure GetX509Certificate2(var DotNetX509Certificate2_2: DotNet X509Certificate2)
    begin
        DotNetX509Certificate2_2 := DotNetX509Certificate2;
    end;

    [Scope('OnPrem')]
    procedure SetX509Certificate2(var DotNetX509Certificate2_2: DotNet X509Certificate2)
    begin
        DotNetX509Certificate2 := DotNetX509Certificate2_2;
    end;
}

