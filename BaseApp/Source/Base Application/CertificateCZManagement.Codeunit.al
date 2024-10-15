codeunit 31130 "Certificate CZ Management"
{

    trigger OnRun()
    begin
    end;

    var
        CertificateNotExistErr: Label 'Certificate with thumbprint %1 is not exist in store:\\Type: %2\Location: %3\Name: %4.', Comment = '%1 = thumbprint; %2 = store type; %3 = store location; %4 = store name';
        ClientNotSupportedErr: Label 'This function is not supported in this client. Please use the Windows client.';
        PrivateKeyNotExistErr: Label 'Certificate does not contain a private key.';
        ServerTypeTxt: Label 'Server';
        ClientTypeTxt: Label 'Client';

    [TryFunction]
    [Scope('OnPrem')]
    procedure SaveCertificateToBlob(X509Certificate2: DotNet X509Certificate2; WithPrivateKey: Boolean; var TempBlob: Codeunit "Temp Blob")
    var
        MemoryStream: DotNet MemoryStream;
        ByteArray: DotNet Array;
        OutputStream: OutStream;
    begin
        if IsNull(X509Certificate2) then
            exit;

        GetCertificateByteArray(X509Certificate2, WithPrivateKey, ByteArray);

        TempBlob.CreateOutStream(OutputStream);
        MemoryStream := MemoryStream.MemoryStream(ByteArray);
        MemoryStream.WriteTo(OutputStream);
        MemoryStream.Flush;
        MemoryStream.Close;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure LoadCertificateFromBlob(TempBlob: Codeunit "Temp Blob"; Password: Text; var X509Certificate2: DotNet X509Certificate2)
    var
        InputStream: InStream;
    begin
        if not TempBlob.HasValue then
            exit;

        TempBlob.CreateInStream(InputStream);
        LoadCertificateFromStream(InputStream, Password, X509Certificate2);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure LoadCertificateFromStream(InputStream: InStream; Password: Text; var X509Certificate2: DotNet X509Certificate2)
    var
        MemoryStream: DotNet MemoryStream;
    begin
        if InputStream.EOS then
            exit;

        MemoryStream := MemoryStream.MemoryStream;
        CopyStream(MemoryStream, InputStream);

        if not GetInstanceX509Certificate2(MemoryStream.GetBuffer, Password, X509Certificate2) then
            Error(GetLastErrorText);

        MemoryStream.Close;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure LoadCertificateFromClient(StoreLocation: Option; StoreName: Option; Thumbprint: Text[80]; var X509Certificate2: DotNet X509Certificate2)
    var
        [RunOnClient]
        OpenFlags: DotNet OpenFlags;
        [RunOnClient]
        StoreLocationObject: DotNet StoreLocation;
        [RunOnClient]
        StoreNameObject: DotNet StoreName;
        [RunOnClient]
        ClientX509Certificate2: DotNet X509Certificate2;
        [RunOnClient]
        X509Certificate2Collection: DotNet X509Certificate2Collection;
        [RunOnClient]
        X509FindType: DotNet X509FindType;
        [RunOnClient]
        X509Store: DotNet X509Store;
    begin
        if (StoreLocation = 0) or (StoreName = 0) or (Thumbprint = '') then
            exit;

        if not CanRunDotNetOnClient then
            Error(ClientNotSupportedErr);

        GetStoreLocationObject(StoreLocation, StoreLocationObject);
        GetStoreNameObject(StoreName, StoreNameObject);
        X509Store := X509Store.X509Store(StoreNameObject, StoreLocationObject);
        X509Store.Open(OpenFlags.OpenExistingOnly);
        X509Certificate2Collection := X509Store.Certificates.Find(X509FindType.FindByThumbprint, Thumbprint, false);
        if X509Certificate2Collection.Count = 0 then
            Error(CertificateNotExistErr, Thumbprint, ClientTypeTxt, FormatStoreLocation(StoreLocation), FormatStoreName(StoreName));

        ClientX509Certificate2 := X509Certificate2Collection.Item(0);
        X509Store.Close;

        UploadClientCertificate(ClientX509Certificate2, X509Certificate2);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure LoadCertificateFromServer(StoreLocation: Option; StoreName: Option; Thumbprint: Text[80]; var X509Certificate2: DotNet X509Certificate2)
    var
        OpenFlags: DotNet OpenFlags;
        StoreLocationObject: DotNet StoreLocation;
        StoreNameObject: DotNet StoreName;
        X509Certificate2Collection: DotNet X509Certificate2Collection;
        X509FindType: DotNet X509FindType;
        X509Store: DotNet X509Store;
    begin
        if (StoreLocation = 0) or (StoreName = 0) or (Thumbprint = '') then
            exit;

        GetStoreLocationObject(StoreLocation, StoreLocationObject);
        GetStoreNameObject(StoreName, StoreNameObject);
        X509Store := X509Store.X509Store(StoreNameObject, StoreLocationObject);
        X509Store.Open(OpenFlags.OpenExistingOnly);
        X509Certificate2Collection := X509Store.Certificates.Find(X509FindType.FindByThumbprint, Thumbprint, false);
        if X509Certificate2Collection.Count = 0 then
            Error(CertificateNotExistErr, Thumbprint, ServerTypeTxt, FormatStoreLocation(StoreLocation), FormatStoreName(StoreName));

        X509Certificate2 := X509Certificate2Collection.Item(0);
        X509Store.Close;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure SignTextByCertificateFromClient(Data: Text; Encoding: DotNet Encoding; StoreLocation: Option; StoreName: Option; Thumbprint: Text[80]; HashAlgorithm: Text; var Signature: DotNet Array)
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        LoadCertificateFromClient(StoreLocation, StoreName, Thumbprint, X509Certificate2);
        SignTextByCertificate(Data, Encoding, X509Certificate2, HashAlgorithm, Signature);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure SignTextByCertificateFromServer(Data: Text; Encoding: DotNet Encoding; StoreLocation: Option; StoreName: Option; Thumbprint: Text[80]; HashAlgorithm: Text; var Signature: DotNet Array)
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        LoadCertificateFromServer(StoreLocation, StoreName, Thumbprint, X509Certificate2);
        SignTextByCertificate(Data, Encoding, X509Certificate2, HashAlgorithm, Signature);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure SignTextByCertificate(Data: Text; Encoding: DotNet Encoding; X509Certificate2: DotNet X509Certificate2; HashAlgorithm: Text; var Signature: DotNet Array)
    begin
        SignByteArrayByCertificate(Encoding.GetBytes(Data), X509Certificate2, HashAlgorithm, Signature);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure SignByteArrayByCertificate(Data: DotNet Array; X509Certificate2: DotNet X509Certificate2; HashAlgorithm: Text; var Signature: DotNet Array)
    var
        CryptoManagement: Codeunit "Crypto Management";
    begin
        if not X509Certificate2.HasPrivateKey then
            Error(PrivateKeyNotExistErr);

        CryptoManagement.SignByteArrayRSA(Data, X509Certificate2.PrivateKey, HashAlgorithm, Signature);
    end;

    [Scope('OnPrem')]
    procedure VerifySignedTextByCertificateFromClient(SignedData: Text; Encoding: DotNet Encoding; StoreLocation: Option; StoreName: Option; Thumbprint: Text[80]; HashAlgorithm: Text; var Signature: DotNet Array): Boolean
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        LoadCertificateFromClient(StoreLocation, StoreName, Thumbprint, X509Certificate2);
        exit(VerifySignedTextByCertificate(SignedData, Encoding, X509Certificate2, HashAlgorithm, Signature));
    end;

    [Scope('OnPrem')]
    procedure VerifySignedTextByCertificateFromServer(SignedData: Text; Encoding: DotNet Encoding; StoreLocation: Option; StoreName: Option; Thumbprint: Text[80]; HashAlgorithm: Text; var Signature: DotNet Array): Boolean
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        LoadCertificateFromServer(StoreLocation, StoreName, Thumbprint, X509Certificate2);
        exit(VerifySignedTextByCertificate(SignedData, Encoding, X509Certificate2, HashAlgorithm, Signature));
    end;

    [Scope('OnPrem')]
    procedure VerifySignedTextByCertificate(SignedData: Text; Encoding: DotNet Encoding; X509Certificate2: DotNet X509Certificate2; HashAlgorithm: Text; Signature: DotNet Array): Boolean
    var
        CryptoManagement: Codeunit "Crypto Management";
    begin
        exit(CryptoManagement.VerifySignedTextRSA(SignedData, Encoding, X509Certificate2.PublicKey.Key, HashAlgorithm, Signature));
    end;

    [Scope('OnPrem')]
    procedure EncodeCertificateToBase64(X509Certificate2: DotNet X509Certificate2; WithPrivateKey: Boolean): Text
    var
        Convert: DotNet Convert;
        ByteArray: DotNet Array;
    begin
        if IsNull(X509Certificate2) then
            exit('');

        GetCertificateByteArray(X509Certificate2, WithPrivateKey, ByteArray);
        exit(Convert.ToBase64String(ByteArray));
    end;

    [Scope('OnPrem')]
    procedure DecodeCertificateFromBase64(Base64Text: Text; var X509Certificate2: DotNet X509Certificate2)
    var
        Convert: DotNet Convert;
    begin
        if Base64Text = '' then
            exit;

        GetInstanceX509Certificate2(Convert.FromBase64String(Base64Text), '', X509Certificate2);
    end;

    [Scope('OnPrem')]
    procedure GetCertificateCommonName(X509Certificate2: DotNet X509Certificate2): Text
    var
        X509NameType: DotNet X509NameType;
    begin
        if IsNull(X509Certificate2) then
            exit('');

        exit(X509Certificate2.GetNameInfo(X509NameType.SimpleName, false));
    end;

    [TryFunction]
    local procedure UploadClientCertificate(ClientX509Certificate2: DotNet X509Certificate2; var ServerX509Certificate2: DotNet X509Certificate2)
    var
        ByteArray: DotNet Array;
    begin
        if IsNull(ClientX509Certificate2) then
            exit;

        GetCertificateByteArray(ClientX509Certificate2, ClientX509Certificate2.HasPrivateKey, ByteArray);
        GetInstanceX509Certificate2(ByteArray, '', ServerX509Certificate2);
    end;

    local procedure GetStoreLocationObject(StoreLocation: Option; var StoreLocationObject: DotNet StoreLocation)
    begin
        StoreLocationObject := StoreLocationObject.ToObject(GetDotNetType(StoreLocationObject), StoreLocation);
    end;

    local procedure GetStoreNameObject(StoreName: Option; var StoreNameObject: DotNet StoreName)
    begin
        StoreNameObject := StoreNameObject.ToObject(GetDotNetType(StoreNameObject), StoreName);
    end;

    local procedure GetCertificateByteArray(X509Certificate2: DotNet X509Certificate2; WithPrivateKey: Boolean; var ByteArray: DotNet Array): Boolean
    var
        X509ContentType: DotNet X509ContentType;
    begin
        if IsNull(X509Certificate2) then
            exit(false);

        if WithPrivateKey then
            ByteArray := X509Certificate2.Export(X509ContentType.Pkcs12)
        else
            ByteArray := X509Certificate2.GetRawCertData;

        exit(not IsNull(ByteArray));
    end;

    local procedure GetInstanceX509Certificate2(ByteArray: DotNet Array; Password: Text; var X509Certificate2: DotNet X509Certificate2): Boolean
    var
        FileManagement: Codeunit "File Management";
        File: DotNet File;
        ServerTempFileName: Text;
        IsOk: Boolean;
    begin
        ServerTempFileName := FileManagement.ServerTempFileName('');
        File.WriteAllBytes(ServerTempFileName, ByteArray);
        IsOk := TryGetInstanceX509Certificate2(ServerTempFileName, Password, X509Certificate2);
        FileManagement.DeleteServerFile(ServerTempFileName);
        exit(IsOk);
    end;

    [TryFunction]
    local procedure TryGetInstanceX509Certificate2(FilePath: Text; Password: Text; var X509Certificate2: DotNet X509Certificate2)
    var
        X509KeyStorageFlags: DotNet X509KeyStorageFlags;
    begin
        X509KeyStorageFlags := 20; // Exportable, PersistKeySet
        X509Certificate2 := X509Certificate2.X509Certificate2(FilePath, Password, X509KeyStorageFlags);
    end;

    local procedure FormatStoreLocation(StoreLocation: Option): Text
    var
        DummyCertificateCZ: Record "Certificate CZ";
    begin
        DummyCertificateCZ."Store Location" := StoreLocation;
        exit(Format(DummyCertificateCZ."Store Location"));
    end;

    local procedure FormatStoreName(StoreName: Option): Text
    var
        DummyCertificateCZ: Record "Certificate CZ";
    begin
        DummyCertificateCZ."Store Name" := StoreName;
        exit(Format(DummyCertificateCZ."Store Name"));
    end;

    local procedure CanRunDotNetOnClient(): Boolean
    var
        ActiveSession: Record "Active Session";
    begin
        if ActiveSession.Get(ServiceInstanceId, SessionId) then
            exit(ActiveSession."Client Type" in [ActiveSession."Client Type"::"Windows Client", ActiveSession."Client Type"::Unknown]);

        exit(false);
    end;
}

