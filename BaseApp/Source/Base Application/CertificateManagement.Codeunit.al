codeunit 1259 "Certificate Management"
{

    trigger OnRun()
    begin
    end;

    var
        TempBlob: Codeunit "Temp Blob";
        DotNet_X509Certificate2: Codeunit DotNet_X509Certificate2;
        PasswordSuffixTxt: Label 'Password', Locked = true;
        SavingPasswordErr: Label 'Could not save the password.';
        SavingCertErr: Label 'Could not save the certificate.';
        ReadingCertErr: Label 'Could not get the certificate.';
        FileManagement: Codeunit "File Management";
        SelectFileTxt: Label 'Select a certificate file';
        CertFileNotValidDotNetTok: Label 'Cannot find the requested object.', Locked = true;
        CertFileNotValidErr: Label 'This is not a valid certificate file.';
        CertFileFilterTxt: Label 'Certificate Files (*.pfx, *.p12,*.p7b,*.cer,*.crt,*.der)|*.pfx;*.p12;*.p7b;*.cer;*.crt;*.der', Locked = true;
        CertExtFilterTxt: Label '.pfx.p12.p7b.cer.crt.der', Locked = true;
        CryptographyManagement: Codeunit "Cryptography Management";
        UploadedCertFileName: Text;
        [NonDebuggable]
        CertPassword: Text;

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
    procedure ReadCertFromBlob(var IsolatedCertificate: Record "Isolated Certificate"; NewTempBlob: Codeunit "Temp Blob"): Boolean
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
        if not TempBlob.HasValue then
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

    [Scope('OnPrem')]
    procedure SaveCertToIsolatedStorage(IsolatedCertificate: Record "Isolated Certificate")
    var
        Base64Convert: Codeunit "Base64 Convert";
        InStream: InStream;
        CertString: Text;
    begin
        if not TempBlob.HasValue then
            Error(CertFileNotValidErr);

        TempBlob.CreateInStream(InStream);
        CertString := Base64Convert.ToBase64(InStream);
        if not ISOLATEDSTORAGE.Set(IsolatedCertificate.Code, CertString, GetCertDataScope(IsolatedCertificate)) then
            Error(SavingCertErr);
    end;

    [Scope('OnPrem')]
    procedure SavePasswordToIsolatedStorage(var IsolatedCertificate: Record "Isolated Certificate")
    begin
        if CertPassword <> '' then begin
            if CryptographyManagement.IsEncryptionEnabled then begin
                if not ISOLATEDSTORAGE.SetEncrypted(IsolatedCertificate.Code + PasswordSuffixTxt, CertPassword, GetCertDataScope(IsolatedCertificate)) then
                    Error(SavingPasswordErr);
            end else
                if not ISOLATEDSTORAGE.Set(IsolatedCertificate.Code + PasswordSuffixTxt, CertPassword, GetCertDataScope(IsolatedCertificate)) then
                    Error(SavingPasswordErr);
        end;
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
    procedure GetCertAsDotNetX509Certificate2(IsolatedCertificate: Record "Isolated Certificate"; var DotNetX509Certificate2: Codeunit DotNet_X509Certificate2)
    var
        StoredPassword: Text;
    begin
        // NAVCZ
        if IsolatedStorage.Get(IsolatedCertificate.Code + PasswordSuffixTxt, GetCertDataScope(IsolatedCertificate), StoredPassword) then;
        ConvertBase64StringToDotNetX509Certificate2(GetCertAsBase64String(IsolatedCertificate), StoredPassword, DotNetX509Certificate2);
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
        DotNet_X509KeyStorageFlags.Exportable;
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
            Validate("Expiry Date", DotNet_X509Certificate2.ExpirationLocalTime);
            Validate("Has Private Key", DotNet_X509Certificate2.HasPrivateKey);
            Validate(ThumbPrint, CopyStr(DotNet_X509Certificate2.Thumbprint, 1, MaxStrLen(ThumbPrint)));
            Validate("Issued By", GetIssuer(DotNet_X509Certificate2.Issuer));
            Validate("Issued To", GetIssuer(DotNet_X509Certificate2.Subject));
        end;
    end;

    [Scope('OnPrem')]
    procedure ConvertBase64StringToDotNetX509Certificate2(Base64String: Text; Password: Text; var DotNetX509Certificate2: Codeunit DotNet_X509Certificate2)
    var
        DotNetArrayBytes: Codeunit DotNet_Array;
        DotNetX509KeyStorageFlags: Codeunit DotNet_X509KeyStorageFlags;
        Convert: DotNet Convert;
    begin
        // NAVCZ
        DotNetArrayBytes.SetArray(Convert.FromBase64String(Base64String));
        DotNetX509KeyStorageFlags.Exportable();
        DotNetX509Certificate2.X509Certificate2(DotNetArrayBytes, Password, DotNetX509KeyStorageFlags);
    end;

    [Scope('OnPrem')]
    procedure ConvertDotNetX509Certificate2ToBase64String(DotNetX509Certificate2: Codeunit DotNet_X509Certificate2; Password: Text; WithPrivateKey: Boolean): Text
    var
        DotNetArrayBytes: Codeunit DotNet_Array;
        Bytes: DotNet Array;
        Convert: DotNet Convert;
    begin
        // NAVCZ
        if DotNetX509Certificate2.IsDotNetNull() then
            exit('');

        ConvertDotNetX509Certificate2ToBytes(DotNetX509Certificate2, Password, WithPrivateKey, DotNetArrayBytes);
        DotNetArrayBytes.GetArray(Bytes);
        exit(Convert.ToBase64String(Bytes));
    end;

    [Scope('OnPrem')]
    procedure ConvertDotNetX509Certificate2ToBytes(DotNetX509Certificate2: Codeunit DotNet_X509Certificate2; Password: Text; WithPrivateKey: Boolean; var DotNetArrayBytes: Codeunit DotNet_Array): Boolean
    var
        X509Certificate2: DotNet X509Certificate2;
        X509ContentType: DotNet X509ContentType;
        Bytes: DotNet Array;
    begin
        // NAVCZ
        DotNetX509Certificate2.GetX509Certificate2(X509Certificate2);
        if IsNull(X509Certificate2) then
            exit(false);

        if WithPrivateKey then
            Bytes := X509Certificate2.Export(X509ContentType.Pkcs12, Password)
        else
            Bytes := X509Certificate2.GetRawCertData;

        DotNetArrayBytes.SetArray(Bytes);
        exit(not IsNull(Bytes));
    end;

    [Scope('OnPrem')]
    procedure GetCertificateCommonName(DotNetX509Certificate2: Codeunit DotNet_X509Certificate2): Text
    var
        X509Certificate2: DotNet X509Certificate2;
        X509NameType: DotNet X509NameType;
    begin
        // NAVCZ
        DotNetX509Certificate2.GetX509Certificate2(X509Certificate2);
        if IsNull(X509Certificate2) then
            exit('');

        exit(X509Certificate2.GetNameInfo(X509NameType.SimpleName, false));
    end;
}