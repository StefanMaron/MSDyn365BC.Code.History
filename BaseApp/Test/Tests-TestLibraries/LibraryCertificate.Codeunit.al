codeunit 143052 "Library - Certificate"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        TempBlob: Codeunit "Temp Blob";

    [Scope('OnPrem')]
    procedure CreateCertificateCZCode(var CertificateCZCode: Record "Certificate CZ Code")
    begin
        with CertificateCZCode do begin
            Init;
            Validate(Code,
              LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Certificate CZ Code"));
            Validate(Description, Code);
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateIsolatedCertificate(var IsolatedCertificate: Record "Isolated Certificate"; CertificateCode: Code[20]; CertificateScope: Option ,Company,User,CompanyAndUser)
    var
        CertificateCZCode: Record "Certificate CZ Code";
    begin
        if not CertificateCZCode.Get(CertificateCZCode) then
            CreateCertificateCZCode(CertificateCZCode);

        CertificateCode := CertificateCZCode.Code;
        IsolatedCertificate.Init;
        IsolatedCertificate.Validate("Certificate Code", CertificateCode);
        IsolatedCertificate.Insert(true);

        if CertificateScope <> 0 then begin
            IsolatedCertificate.Validate(Scope, CertificateScope);
            SetScope(IsolatedCertificate);
            IsolatedCertificate.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateIsolatedCertificateWithWithTestBlob(var IsolatedCertificate: Record "Isolated Certificate"; CertificateCode: Code[20]; CertificateScope: Option ,Company,User,CompanyAndUser)
    var
        CertificateManagement: Codeunit "Certificate Management";
    begin
        CreateIsolatedCertificate(IsolatedCertificate, CertificateCode, CertificateScope);
        IsolatedCertificate.Validate(Password, GetCertificatePassword());
        CertificateManagement.VerifyCertFromString(IsolatedCertificate, GetDemoCertificate());
        CertificateManagement.SaveCertToIsolatedStorage(IsolatedCertificate);
        CertificateManagement.SavePasswordToIsolatedStorage(IsolatedCertificate);
    end;

    [Scope('OnPrem')]
    procedure GetCertificateObject(var X509Certificate2: DotNet X509Certificate2)
    var
        CertificateManagement: Codeunit "Certificate Management";
        DotNetX509Certificate2: Codeunit DotNet_X509Certificate2;
    begin
        CertificateManagement.ConvertBase64StringToDotNetX509Certificate2(GetDemoCertificate(), GetCertificatePassword(), DotNetX509Certificate2);
        DotNetX509Certificate2.GetX509Certificate2(X509Certificate2);
    end;

    [Scope('OnPrem')]
    procedure GetCertificatePassword(): Text
    begin
        exit('');
    end;

    [Scope('OnPrem')]
    procedure GetCertificatePrivateKey(KeyStream: InStream)
    var
        X509Certificate2: DotNet X509Certificate2;
        OutputStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutputStream);
        TempBlob.CreateInStream(KeyStream);
        GetCertificateObject(X509Certificate2);
        OutputStream.Write(X509Certificate2.PrivateKey.ToXmlString(true));
    end;

    local procedure SetScope(var IsolatedCertificate: Record "Isolated Certificate")
    begin
        with IsolatedCertificate do begin
            case Scope of
                Scope::Company:
                    Validate("Company ID", CompanyName);
                Scope::User:
                    "User ID" := Format(UserSecurityId);
                Scope::CompanyAndUser:
                    begin
                        Validate("Company ID", CompanyName);
                        "User ID" := Format(UserSecurityId);
                    end;
            end;
            Modify;
        end;
    end;

    local procedure GetDemoCertificate(): Text
    begin
        exit(
          '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');
    end;
}

