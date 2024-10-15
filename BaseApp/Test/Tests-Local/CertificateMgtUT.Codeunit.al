codeunit 145016 "Certificate Mgt. UT"
{
    // // [FEATURE] [Certificate] [UT]

    Subtype = Test;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryCertificateCZ: Codeunit "Library - Certificate CZ";
        IsInitialized: Boolean;
        CertMustBeNullErr: Label 'Certificate must be null.';
        PasswordIsNotCorrectErr: Label 'The specified network password is not correct.';
        CertificateNotExistErr: Label 'Certificate with thumbprint %1 is not exist in store:\\Type: %2\Location: %3\Name: %4.', Comment = '%1 = thumbprint; %2 = store type; %3 = store location; %4 = store name';
        ServerTypeTxt: Label 'Server';
        ClientTypeTxt: Label 'Client';

    [Test]
    [Scope('OnPrem')]
    procedure LoadCertificateFromBlob()
    var
        TempBlob: Codeunit "Temp Blob";
        CertificateCZManagement: Codeunit "Certificate CZ Management";
        LoadedX509Certificate2: DotNet X509Certificate2;
        X509Certificate2: DotNet X509Certificate2;
    begin
        // [SCENARIO] Load certificate object from blob
        // [GIVEN] Get test certificate blob
        Initialize;

        GetCertificateBlob(true, TempBlob);

        // [WHEN] Load certificate from blob
        CertificateCZManagement.LoadCertificateFromBlob(TempBlob, GetCertificatePassword, LoadedX509Certificate2);

        // [THEN] Loaded certificate is the same as test certificate
        GetCertificateObject(X509Certificate2);
        Assert.Compare(Format(X509Certificate2), Format(LoadedX509Certificate2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadCertificateFromEmptyBlob()
    var
        TempBlob: Codeunit "Temp Blob";
        CertificateCZManagement: Codeunit "Certificate CZ Management";
        LoadedX509Certificate2: DotNet X509Certificate2;
    begin
        // [SCENARIO] Load certificate object from empty blob
        Initialize;

        // [WHEN] Load certificate from blob
        CertificateCZManagement.LoadCertificateFromBlob(TempBlob, GetCertificatePassword, LoadedX509Certificate2);

        // [THEN] Loaded certificate is null
        Assert.IsTrue(IsNull(LoadedX509Certificate2), CertMustBeNullErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadCertificateFromBlobWithIncorrectPassword()
    var
        TempBlob: Codeunit "Temp Blob";
        CertificateCZManagement: Codeunit "Certificate CZ Management";
        LoadedX509Certificate2: DotNet X509Certificate2;
    begin
        // [SCENARIO] Load certificate object from blob with incorrect password
        // [GIVEN] Get test certificate blob
        Initialize;

        GetCertificateBlob(true, TempBlob);

        // [WHEN] Load certificate from blob
        asserterror CertificateCZManagement.LoadCertificateFromBlob(TempBlob, GetFakePassword, LoadedX509Certificate2);

        // [THEN] Error occurs
        Assert.ExpectedError(PasswordIsNotCorrectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadCertificateFromStream()
    var
        TempBlob: Codeunit "Temp Blob";
        CertificateCZManagement: Codeunit "Certificate CZ Management";
        LoadedX509Certificate2: DotNet X509Certificate2;
        X509Certificate2: DotNet X509Certificate2;
        InputStream: InStream;
    begin
        // [SCENARIO] Load certificate object from stream
        // [GIVEN] Get test certificate blob
        // [GIVEN] Create instream from test certificate blob
        Initialize;

        GetCertificateBlob(true, TempBlob);
        TempBlob.CreateInStream(InputStream);

        // [WHEN] Load certificate from stream
        CertificateCZManagement.LoadCertificateFromStream(InputStream, GetCertificatePassword, LoadedX509Certificate2);

        // [THEN] Loaded certificate is the same as test certificate
        GetCertificateObject(X509Certificate2);
        Assert.Compare(Format(X509Certificate2), Format(LoadedX509Certificate2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadCertificateFromEmptyStream()
    var
        TempBlob: Codeunit "Temp Blob";
        CertificateCZManagement: Codeunit "Certificate CZ Management";
        LoadedX509Certificate2: DotNet X509Certificate2;
        InputStream: InStream;
    begin
        // [SCENARIO] Load certificate object from empty stream
        // [GIVEN] Create instream from empty blob
        Initialize;

        TempBlob.CreateInStream(InputStream);

        // [WHEN] Load certificate from stream
        CertificateCZManagement.LoadCertificateFromStream(InputStream, GetCertificatePassword, LoadedX509Certificate2);

        // [THEN] Loaded certificate is null
        Assert.IsTrue(IsNull(LoadedX509Certificate2), CertMustBeNullErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadCertificateFromStreamWithIncorrectPassword()
    var
        TempBlob: Codeunit "Temp Blob";
        CertificateCZManagement: Codeunit "Certificate CZ Management";
        LoadedX509Certificate2: DotNet X509Certificate2;
        InputStream: InStream;
    begin
        // [SCENARIO] Load certificate object from stream with incorrect password
        // [GIVEN] Get test certificate blob
        // [GIVEN] Create instream from test certificate blob
        Initialize;

        GetCertificateBlob(true, TempBlob);
        TempBlob.CreateInStream(InputStream);

        // [WHEN] Load certificate from stream
        asserterror CertificateCZManagement.LoadCertificateFromStream(InputStream, GetFakePassword, LoadedX509Certificate2);

        // [THEN] Error occurs
        Assert.ExpectedError(PasswordIsNotCorrectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadNotExistCertificateFromClient()
    var
        CertificateCZManagement: Codeunit "Certificate CZ Management";
        X509Certificate2: DotNet X509Certificate2;
        StoreLocation: Option;
        StoreName: Option;
    begin
        // [SCENARIO] Load not exist certificate from client windows certificate store
        // [GIVEN] Initialize store location and store name
        Initialize;

        StoreLocation := 1; // Current User
        StoreName := 5; // My

        // [WHEN] Load certificate from client
        asserterror CertificateCZManagement.LoadCertificateFromClient(StoreLocation, StoreName, GetFakeThumbprint, X509Certificate2);

        // [THEN] Error occurs
        Assert.ExpectedError(
          StrSubstNo(
            CertificateNotExistErr, GetFakeThumbprint, ClientTypeTxt,
            FormatStoreLocation(StoreLocation), FormatStoreName(StoreName)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadNotExistCertificateFromServer()
    var
        CertificateCZManagement: Codeunit "Certificate CZ Management";
        X509Certificate2: DotNet X509Certificate2;
        StoreLocation: Option;
        StoreName: Option;
    begin
        // [SCENARIO] Load not exist certificate from server windows certificate store
        // [GIVEN] Initialize store location and store name
        Initialize;

        StoreLocation := 2; // Local Machine
        StoreName := 5; // My

        // [WHEN] Load certificate from server
        asserterror CertificateCZManagement.LoadCertificateFromServer(StoreLocation, StoreName, GetFakeThumbprint, X509Certificate2);

        // [THEN] Error occurs
        Assert.ExpectedError(
          StrSubstNo(
            CertificateNotExistErr, GetFakeThumbprint, ServerTypeTxt,
            FormatStoreLocation(StoreLocation), FormatStoreName(StoreName)));
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit;
    end;

    local procedure FormatStoreLocation(StoreLocation: Option): Text
    begin
        exit(LibraryCertificateCZ.FormatStoreLocation(StoreLocation));
    end;

    local procedure FormatStoreName(StoreName: Option): Text
    begin
        exit(LibraryCertificateCZ.FormatStoreName(StoreName));
    end;

    local procedure GetCertificateBlob(WithPrivateKey: Boolean; var TempBlob: Codeunit "Temp Blob")
    begin
        LibraryCertificateCZ.GetCertificateBlob(WithPrivateKey, TempBlob);
    end;

    local procedure GetCertificateObject(var X509Certificate2: DotNet X509Certificate2)
    begin
        LibraryCertificateCZ.GetCertificateObject(X509Certificate2);
    end;

    local procedure GetCertificatePassword(): Text
    begin
        exit(LibraryCertificateCZ.GetCertificatePassword);
    end;

    local procedure GetFakeThumbprint(): Text[80]
    begin
        exit(LibraryCertificateCZ.GetFakeThumbprint);
    end;

    local procedure GetFakePassword(): Text
    begin
        exit(LibraryCertificateCZ.GetFakePassword);
    end;
}

