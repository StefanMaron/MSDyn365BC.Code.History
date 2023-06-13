codeunit 1259 "Certificate Management"
{

    trigger OnRun()
    begin
    end;

    var
        TempBlob: Codeunit "Temp Blob";
        DotNet_X509Certificate2: Codeunit DotNet_X509Certificate2;
        FileManagement: Codeunit "File Management";
        CryptographyManagement: Codeunit "Cryptography Management";
        UploadedCertFileName: Text;
        [NonDebuggable]
        CertPassword: Text;

        PasswordSuffixTxt: Label 'Password', Locked = true;
        SavingPasswordErr: Label 'Could not save the password.';
        SavingCertErr: Label 'Could not save the certificate.';
        ReadingCertErr: Label 'Could not get the certificate.';
        SelectFileTxt: Label 'Select a certificate file';
        CertFileNotValidDotNetTok: Label 'Cannot find the requested object.', Locked = true;
        CertFileNotValidErr: Label 'This is not a valid certificate file.';
        CertFileFilterTxt: Label 'Certificate Files (*.pfx, *.p12,*.p7b,*.cer,*.crt,*.der)|*.pfx;*.p12;*.p7b;*.cer;*.crt;*.der', Locked = true;
        CertExtFilterTxt: Label '.pfx.p12.p7b.cer.crt.der', Locked = true;

    [Scope('OnPrem')]
    procedure UploadAndVerifyCert(var IsolatedCertificate: Record "Isolated Certificate"): Boolean
    var
        FileName: Text;
    begin
        FileName := FileManagement.BLOBImportWithFilter(TempBlob, SelectFileTxt, FileName, CertFileFilterTxt, CertExtFilterTxt);
        if FileName = '' then
            Error('');

        UploadedCertFileName := FileManagement.GetFileName(FileName);
        exit(VerifyCert(IsolatedCertificate));
    end;

    [Scope('OnPrem')]
    procedure InitIsolatedCertificateFromBlob(var IsolatedCertificate: Record "Isolated Certificate"; NewTempBlob: Codeunit "Temp Blob"): Boolean
    var
        User: Record User;
    begin
        TempBlob := NewTempBlob;
        if not VerifyCert(IsolatedCertificate) then
            exit(false);

        DeleteCertAndPasswordFromIsolatedStorage(IsolatedCertificate);
        if User.Get(UserSecurityId()) then
            IsolatedCertificate.SetScope();
        SaveCertToIsolatedStorage(IsolatedCertificate);
        SavePasswordToIsolatedStorage(IsolatedCertificate);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure VerifyCert(var IsolatedCertificate: Record "Isolated Certificate"): Boolean
    begin
        if not TempBlob.HasValue() then
            Error(CertFileNotValidErr);

        if ReadCertFromBlob(CertPassword) then begin
            ValidateCertFields(IsolatedCertificate);
            exit(true);
        end;

        if StrPos(GetLastErrorText, CertFileNotValidDotNetTok) <> 0 then
            Error(CertFileNotValidErr);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure VerifyCertFromString(var IsolatedCertificate: Record "Isolated Certificate"; CertString: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(CertString, OutStream);
        VerifyCert(IsolatedCertificate);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure SaveCertToIsolatedStorage(IsolatedCertificate: Record "Isolated Certificate")
    var
        Base64Convert: Codeunit "Base64 Convert";
        InStream: InStream;
        CertString: Text;
    begin
        if not TempBlob.HasValue() then
            Error(CertFileNotValidErr);

        TempBlob.CreateInStream(InStream);
        CertString := Base64Convert.ToBase64(InStream);
        if not ISOLATEDSTORAGE.Set(IsolatedCertificate.Code, CertString, GetCertDataScope(IsolatedCertificate)) then
            Error(SavingCertErr);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure SavePasswordToIsolatedStorage(var IsolatedCertificate: Record "Isolated Certificate")
    begin
        if CertPassword <> '' then
            if CryptographyManagement.IsEncryptionEnabled() then begin
                if not ISOLATEDSTORAGE.SetEncrypted(IsolatedCertificate.Code + PasswordSuffixTxt, CertPassword, GetCertDataScope(IsolatedCertificate)) then
                    Error(SavingPasswordErr);
            end else
                if not ISOLATEDSTORAGE.Set(IsolatedCertificate.Code + PasswordSuffixTxt, CertPassword, GetCertDataScope(IsolatedCertificate)) then
                    Error(SavingPasswordErr);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetPasswordAsSecureString(var DotNet_SecureString: Codeunit DotNet_SecureString; IsolatedCertificate: Record "Isolated Certificate")
    var
        DotNetHelper_SecureString: Codeunit DotNetHelper_SecureString;
        StoredPassword: Text;
    begin
        StoredPassword := '';
        GetPasswordFromIsolatedStorage(StoredPassword, IsolatedCertificate);
        DotNetHelper_SecureString.SecureStringFromString(DotNet_SecureString, StoredPassword);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetPassword(IsolatedCertificate: Record "Isolated Certificate") StoredPassword: Text
    begin
        GetPasswordFromIsolatedStorage(StoredPassword, IsolatedCertificate);
    end;

    [NonDebuggable]
    local procedure GetPasswordFromIsolatedStorage(var StoredPassword: Text; IsolatedCertificate: Record "Isolated Certificate")
    begin
        if ISOLATEDSTORAGE.Get(IsolatedCertificate.Code + PasswordSuffixTxt, GetCertDataScope(IsolatedCertificate), StoredPassword) then;
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetCertAsBase64String(IsolatedCertificate: Record "Isolated Certificate"): Text
    var
        CertString: Text;
    begin
        CertString := '';
        if not ISOLATEDSTORAGE.Get(IsolatedCertificate.Code, GetCertDataScope(IsolatedCertificate), CertString) then
            Error(ReadingCertErr);
        exit(CertString);
    end;

    [Scope('OnPrem')]
    procedure GetCertDataScope(IsolatedCertificate: Record "Isolated Certificate"): DataScope
    begin
        case IsolatedCertificate.Scope of
            IsolatedCertificate.Scope::Company:
                exit(DATASCOPE::Company);
            IsolatedCertificate.Scope::CompanyAndUser:
                exit(DATASCOPE::CompanyAndUser);
            IsolatedCertificate.Scope::User:
                exit(DATASCOPE::User);
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteCertAndPasswordFromIsolatedStorage(IsolatedCertificate: Record "Isolated Certificate")
    var
        CertDataScope: DataScope;
    begin
        CertDataScope := GetCertDataScope(IsolatedCertificate);
        with IsolatedCertificate do begin
            if ISOLATEDSTORAGE.Contains(Code, CertDataScope) then
                ISOLATEDSTORAGE.Delete(Code, CertDataScope);
            if ISOLATEDSTORAGE.Contains(Code + PasswordSuffixTxt, CertDataScope) then
                ISOLATEDSTORAGE.Delete(Code + PasswordSuffixTxt, CertDataScope);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetUploadedCertFileName(): Text
    begin
        exit(UploadedCertFileName);
    end;

    [Scope('OnPrem')]
    procedure SetCertPassword(CertificatePassword: Text)
    begin
        CertPassword := CertificatePassword;
    end;

    [TryFunction]
    local procedure ReadCertFromBlob(Password: Text)
    var
        DotNet_X509KeyStorageFlags: Codeunit DotNet_X509KeyStorageFlags;
        DotNet_Array: Codeunit DotNet_Array;
        Base64Convert: Codeunit "Base64 Convert";
        Convert: DotNet Convert;
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        DotNet_Array.SetArray(Convert.FromBase64String(Base64Convert.ToBase64(InStream)));
        DotNet_X509KeyStorageFlags.Exportable();
        DotNet_X509Certificate2.X509Certificate2(DotNet_Array, Password, DotNet_X509KeyStorageFlags);
    end;

    local procedure GetIssuer(Issuer: Text): Text
    begin
        if StrPos(Issuer, 'CN=') <> 0 then
            exit(SelectStr(1, CopyStr(Issuer, StrPos(Issuer, 'CN=') + 3)));
    end;

    local procedure ValidateCertFields(var IsolatedCertificate: Record "Isolated Certificate")
    begin
        with IsolatedCertificate do begin
            Validate("Expiry Date", DotNet_X509Certificate2.ExpirationLocalTime());
            Validate("Has Private Key", DotNet_X509Certificate2.HasPrivateKey());
            Validate(ThumbPrint, CopyStr(DotNet_X509Certificate2.Thumbprint(), 1, MaxStrLen(ThumbPrint)));
            Validate("Issued By", GetIssuer(DotNet_X509Certificate2.Issuer()));
            Validate("Issued To", GetIssuer(DotNet_X509Certificate2.Subject()));
        end;
    end;

    [NonDebuggable]
    procedure GetRawCertDataAsBase64String(IsolatedCertificate: Record "Isolated Certificate"): Text
    var
        X509Certificate2: DotNet X509Certificate2;
        Convert: DotNet Convert;
    begin
        GetCertAsDotNet(IsolatedCertificate, DotNet_X509Certificate2);
        DotNet_X509Certificate2.GetX509Certificate2(X509Certificate2);
        exit(Convert.ToBase64String(X509Certificate2.GetRawCertData()));
    end;

    [NonDebuggable]
    local procedure ConvertCertToDotNetFromBase64(Base64String: Text; Password: Text; var DotNetX509Certificate2: Codeunit DotNet_X509Certificate2)
    var
        DotNetArrayBytes: Codeunit DotNet_Array;
        DotNetX509KeyStorageFlags: Codeunit DotNet_X509KeyStorageFlags;
        Convert: DotNet Convert;
    begin
        DotNetArrayBytes.SetArray(Convert.FromBase64String(Base64String));
        DotNetX509KeyStorageFlags.Exportable();
        DotNetX509Certificate2.X509Certificate2(DotNetArrayBytes, Password, DotNetX509KeyStorageFlags);
    end;

    [NonDebuggable]
    procedure VerifyCertFromBase64(Base64String: Text): Boolean
    var
        DotNetX509Certificate2: Codeunit DotNet_X509Certificate2;
        X509Certificate2: DotNet X509Certificate2;
        X509Chain: DotNet X509Chain;
        X509RevocationMode: DotNet X509RevocationMode;
    begin
        ConvertCertToDotNetFromBase64(Base64String, '', DotNetX509Certificate2);
        DotNetX509Certificate2.GetX509Certificate2(X509Certificate2);
        X509Chain := X509Chain.X509Chain();
        X509Chain.ChainPolicy.RevocationMode := X509RevocationMode.NoCheck;
        exit(X509Chain.Build(X509Certificate2));
    end;

    [NonDebuggable]
    local procedure GetCertAsDotNet(IsolatedCertificate: Record "Isolated Certificate"; var DotNetX509Certificate2: Codeunit DotNet_X509Certificate2)
    begin
        ConvertCertToDotNetFromBase64(
            GetCertAsBase64String(IsolatedCertificate), GetPassword(IsolatedCertificate), DotNetX509Certificate2);
    end;

    [NonDebuggable]
    procedure GetCertSimpleName(IsolatedCertificate: Record "Isolated Certificate"): Text
    var
        DotNetX509Certificate2: Codeunit DotNet_X509Certificate2;
        X509Certificate2: DotNet X509Certificate2;
        X509NameType: DotNet X509NameType;
    begin
        GetCertAsDotNet(IsolatedCertificate, DotNetX509Certificate2);
        DotNetX509Certificate2.GetX509Certificate2(X509Certificate2);
        if IsNull(X509Certificate2) then
            exit('');
        exit(X509Certificate2.GetNameInfo(X509NameType.SimpleName, false));
    end;

    [NonDebuggable]
    procedure GetCertPrivateKey(IsolatedCertificate: Record "Isolated Certificate"; var SignatureKey: Codeunit "Signature Key")
    var
        DotNetX509Certificate2: Codeunit DotNet_X509Certificate2;
        DotNetAsymmetricAlgorithm: Codeunit DotNet_AsymmetricAlgorithm;
    begin
        IsolatedCertificate.TestField("Has Private Key");
        GetCertAsDotNet(IsolatedCertificate, DotNetX509Certificate2);
        DotNetX509Certificate2.PrivateKey(DotNetAsymmetricAlgorithm);
        SignatureKey.FromXmlString(DotNetAsymmetricAlgorithm.ToXmlString(true));
    end;
}