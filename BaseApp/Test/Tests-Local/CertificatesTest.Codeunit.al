codeunit 145015 "Certificates Test"
{
    // // [FEATURE] [Certificate] [UT]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryCertificateCZ: Codeunit "Library - Certificate CZ";
        CertificateNotExistErr: Label 'Certificate with thumbprint %1 is not exist in store:\\Type: %2\Location: %3\Name: %4.', Comment = '%1 = thumbprint; %2 = store type; %3 = store location; %4 = store name';
        ServerTypeTxt: Label 'Server';
        ClientTypeTxt: Label 'Client';
        IsInitialized: Boolean;
        ThumbprintsErr: Label 'Thumbprints must be the same.';
        MustHavePrivateKeyErr: Label 'Imported certificate must have a private key.';
        MustNotHavePrivateKeyErr: Label 'Imported certificate must not have a private key.';
        CertificateIsNotImportedErr: Label 'Certificate is not imported in the database.';
        DateTimeValidErr: Label '%1 cannot be after %2.', Comment = '%1 = date of valid from, %2 = date of valid to';
        OutOfRangeErr: Label '%1 %2 is out of range of certificate validity.', Comment = '%1 = field name of datetime type; %2 = date time';
        NotCertificateUserErr: Label 'User %1 is not user of certificate %2 %3.', Comment = '%1 = user id; %2 = user id; %3 = valid from';
        PrivateKeyNotExistErr: Label 'Certificate does not contain a private key.';
        CertMustBeLoadedErr: Label 'Certificate must be loaded.';
        CertMustNotBeLoadedErr: Label 'Certificate must not be loaded.';
        CertMustBeValidErr: Label 'Certificate must be valid.';
        IsolatedStorageMustBeDeletedErr: Label 'Isolated Storage entry must be deleted.';
        VerifyMustBeSuccessErr: Label 'Verify must be successful.';

    [Test]
    [Scope('OnPrem')]
    procedure LoadNotExistCertificateFromClientStore()
    var
        CertificateCZ: Record "Certificate CZ";
    begin
        // [SCENARIO] Loading not exist certificate from client Windows certificate store throws an error
        LoadNotExistCertificateFromStore(CertificateCZ."Store Type"::Client);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadNotExistCertificateFromServerStore()
    var
        CertificateCZ: Record "Certificate CZ";
    begin
        // [SCENARIO] Loading not exist certificate from server Windows certificate store throws an error
        LoadNotExistCertificateFromStore(CertificateCZ."Store Type"::Server);
    end;

    local procedure LoadNotExistCertificateFromStore(StoreType: Option)
    var
        CertificateCZ: Record "Certificate CZ";
        X509Certificate2: DotNet X509Certificate2;
        StoreTypeTxt: Text;
    begin
        // [GIVEN] Create Certificate with fake thumbprint
        Initialize;

        CreateCertificate(CertificateCZ, '', StoreType);
        CertificateCZ.Validate("Store Location", CertificateCZ."Store Location"::"Local Machine");
        CertificateCZ.Validate("Store Name", CertificateCZ."Store Name"::My);
        CertificateCZ.Thumbprint := GetFakeThumbprint;

        // [WHEN] Load certificate from Windows certificate store
        asserterror CertificateCZ.LoadCertificateFromStore(X509Certificate2);

        // [THEN] Error occurs
        if StoreType = CertificateCZ."Store Type"::Client then
            StoreTypeTxt := ClientTypeTxt
        else
            StoreTypeTxt := ServerTypeTxt;

        Assert.ExpectedError(
          StrSubstNo(
            CertificateNotExistErr, GetFakeThumbprint, StoreTypeTxt,
            FormatStoreLocation(CertificateCZ."Store Location"), FormatStoreName(CertificateCZ."Store Name")));
    end;

    [Test]
    [HandlerFunctions('EncryptionConfirmHandler')]
    [Scope('OnPrem')]
    procedure SaveCertificateToDatabaseFromStreamWithEncryptionEnabled()
    begin
        // [SCENARIO] Save certificate to database from stream with encryption
        SaveCertificateToDatabaseFromStream(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveCertificateToDatabaseFromStreamWithEncryptionDisabled()
    begin
        // [SCENARIO] Save certificate to database from stream without encryption
        SaveCertificateToDatabaseFromStream(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveCertificateToDatabaseFromStreamWithoutPrivateKey()
    begin
        // [SCENARIO] Save certificate to database from stream without private key
        SaveCertificateToDatabaseFromStream(false, false);
    end;

    local procedure SaveCertificateToDatabaseFromStream(WithPrivateKey: Boolean; WithEncryption: Boolean)
    var
        CertificateCZ: Record "Certificate CZ";
        TempBlob: Codeunit "Temp Blob";
        CryptographyManagement: Codeunit "Cryptography Management";
        InputStream: InStream;
        X509Certificate2: DotNet X509Certificate2;
    begin
        // [GIVEN] Set up the encryption
        // [GIVEN] Create Certificate record with Store Type = Database
        // [GIVEN] Prepare certificate blob
        Initialize;

        if WithEncryption then
            if not CryptographyManagement.IsEncryptionEnabled then
                CryptographyManagement.EnableEncryption(FALSE);

        if not WithEncryption then
            if CryptographyManagement.IsEncryptionEnabled then
                CryptographyManagement.DisableEncryption(true);

        CreateCertificate(CertificateCZ, '', CertificateCZ."Store Type"::Database);
        GetCertificateBlob(true, TempBlob);
        TempBlob.CreateInStream(InputStream);

        // [WHEN] Save certificate to database and load certificate from database
        CertificateCZ.SaveCertificateFromStream(InputStream, GetCertificatePassword, WithPrivateKey);
        CertificateCZ.LoadCertificateFromStore(X509Certificate2);

        // [THEN] Certificate is imported in the database
        // [THEN] Thumbprint of certificate from database must be the same as
        // thumbprint of certificate that was imported to database
        // [THEN] Private key of certificate is stored in database if we want
        // Private key of certificte is not stored in database if we do no want
        Assert.IsTrue(CertificateCZ.HasCertificate, CertificateIsNotImportedErr);
        Assert.AreEqual(
          LibraryCertificateCZ.GetCertificateThumbprint, X509Certificate2.Thumbprint, ThumbprintsErr);
        if WithPrivateKey then
            Assert.IsTrue(X509Certificate2.HasPrivateKey, MustHavePrivateKeyErr)
        else
            Assert.IsFalse(X509Certificate2.HasPrivateKey, MustNotHavePrivateKeyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateCertificateInformation()
    var
        CertificateCZ: Record "Certificate CZ";
        X509Certificate2: DotNet X509Certificate2;
    begin
        // [SCENARIO] Update certificate information (valid from, valid to, ...) from imported certificate
        // [GIVEN] Create Certificate record with imported certificate in database
        Initialize;

        CreateDatabaseCertificate(CertificateCZ, '', true);

        // [WHEN] Update certificate information
        CertificateCZ.UpdateCertificateInformation;

        // [THEN] Certificate information are the same as in imported certificate
        GetCertificateObject(X509Certificate2);
        Assert.AreEqual(CertificateCZ.GetCertificateValidFrom, CertificateCZ."Valid From", '');
        Assert.AreEqual(CertificateCZ.GetCertificateValidTo, CertificateCZ."Valid To", '');
        Assert.AreEqual(CertificateCZ.GetCertificateFriendlyName, CertificateCZ.Description, '');
        Assert.AreEqual(X509Certificate2.Thumbprint, CertificateCZ.Thumbprint, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeValidFromAfterValidTo()
    var
        CertificateCZ: Record "Certificate CZ";
    begin
        // [SCENARIO] Change Valid From after Valid To must raised error
        // [GIVEN] Create Certificate record with imported certificate in database
        Initialize;

        CreateDatabaseCertificate(CertificateCZ, '', true);

        // [WHEN] Validate Valid From to Valid To + 1D
        asserterror
          CertificateCZ.Validate("Valid From",
            CreateDateTime(CalcDate('<+1D>', DT2Date(CertificateCZ."Valid To")), DT2Time(CertificateCZ."Valid To")));

        // [THEN] Error occurs
        Assert.ExpectedError(
          StrSubstNo(DateTimeValidErr, CertificateCZ.FieldCaption("Valid From"), CertificateCZ.FieldCaption("Valid To")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeValidFromOutOfRangeOfCertificate()
    var
        CertificateCZ: Record "Certificate CZ";
        CertificateValidFrom: DateTime;
        ValidFrom: DateTime;
    begin
        // [SCENARIO] Change Valid From out of range of certificate validity
        // [GIVEN] Create Certificate record with imported certificate in database
        Initialize;

        CreateDatabaseCertificate(CertificateCZ, '', true);

        CertificateValidFrom := CertificateCZ.GetCertificateValidFrom;
        ValidFrom :=
          CreateDateTime(
            CalcDate('<-1D>', DT2Date(CertificateValidFrom)), DT2Time(CertificateValidFrom));

        // [WHEN] Validate Valid From to Valid From of certificate - 1D
        asserterror CertificateCZ.Validate("Valid From", ValidFrom);

        // [THEN] Error occurs
        Assert.ExpectedError(
          StrSubstNo(OutOfRangeErr, CertificateCZ.FieldCaption("Valid From"), ValidFrom));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeValidToOutOfRangeOfCertificate()
    var
        CertificateCZ: Record "Certificate CZ";
        CertificateValidTo: DateTime;
        ValidTo: DateTime;
    begin
        // [SCENARIO] Change Valid To out of range of certificate validity
        // [GIVEN] Create Certificate record with imported certificate in database
        Initialize;

        CreateDatabaseCertificate(CertificateCZ, '', true);

        CertificateValidTo := CertificateCZ.GetCertificateValidTo;
        ValidTo :=
          CreateDateTime(
            CalcDate('<+1D>', DT2Date(CertificateValidTo)), DT2Time(CertificateValidTo));

        // [WHEN] Validate Valid To to Valid To of certificate + 1D
        asserterror CertificateCZ.Validate("Valid To", ValidTo);

        // [THEN] Error occurs
        Assert.ExpectedError(
          StrSubstNo(OutOfRangeErr, CertificateCZ.FieldCaption("Valid To"), ValidTo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadValidCertificate()
    var
        CertificateCZCode: Record "Certificate CZ Code";
        CertificateCZ: Record "Certificate CZ";
        ValidCertificateCZ: Record "Certificate CZ";
        IsLoaded: Boolean;
    begin
        // [SCENARIO] Valid certificate must be loaded if certificate is exist
        // [GIVEN] Create Certificate record with imported certificate in database
        // [GIVEN] Get Certificate Code
        Initialize;

        CreateDatabaseCertificate(CertificateCZ, '', true);
        CertificateCZCode.Get(CertificateCZ."Certificate Code");

        // [WHEN] Load valid certificate
        IsLoaded := CertificateCZCode.LoadValidCertificate(ValidCertificateCZ);

        // [THEN] Loading is successful
        // [THEN] Loaded certificate is valid
        // [THEN] Loaded certificate has the same Valid From as Valid From of created certificate
        Assert.IsTrue(IsLoaded, CertMustBeLoadedErr);
        Assert.IsTrue(CertificateCZ.IsValid, CertMustBeValidErr);
        Assert.AreEqual(CertificateCZ."Valid From", ValidCertificateCZ."Valid From", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadValidCertificateIfNotExist()
    var
        CertificateCZCode: Record "Certificate CZ Code";
        CertificateCZ: Record "Certificate CZ";
        ValidCertificateCZ: Record "Certificate CZ";
        IsLoaded: Boolean;
    begin
        // [SCENARIO] Valid certificate must not be loaded if certificate is not exist
        // [GIVEN] Create Certificate record with imported certificate in database
        // [GIVEN] Validate Valid To to TODAY - 1D
        // [GIVEN] Get Certificate Code
        Initialize;

        CreateDatabaseCertificate(CertificateCZ, '', true);
        CertificateCZ.Validate("Valid To", CreateDateTime(CalcDate('<-1D>', Today), DT2Time(CertificateCZ."Valid To")));
        CertificateCZ.Modify;

        CertificateCZCode.Get(CertificateCZ."Certificate Code");

        // [WHEN] Load valid certificate
        IsLoaded := CertificateCZCode.LoadValidCertificate(ValidCertificateCZ);

        // [THEN] Loading is not successful
        Assert.IsFalse(IsLoaded, CertMustNotBeLoadedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDatabaseCertificate()
    var
        CertificateCZ: Record "Certificate CZ";
    begin
        // [SCENARIO] Delete database certificate record
        // [GIVEN] Create Certificate record with imported certificate in database
        Initialize;

        CreateDatabaseCertificate(CertificateCZ, '', true);

        // [WHEN] Delete certificate
        CertificateCZ.Delete(true);

        // [THEN] Isolated Storage entry is deleted too
        Assert.IsFalse(ISOLATEDSTORAGE.CONTAINS(CertificateCZ."Certificate Key", DATASCOPE::Company), IsolatedStorageMustBeDeletedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDatabaseCertificateFromAnotherUser()
    var
        CertificateCZ: Record "Certificate CZ";
    begin
        // [SCENARIO] Delete database certificate record from another user
        // [GIVEN] Create Certificate record with imported certificate in database
        // [GIVEN] Validate User ID to another user than USERID
        Initialize;

        CreateDatabaseCertificate(CertificateCZ, UserId, true);
        CertificateCZ.Rename(CertificateCZ."Certificate Code", 'TEST', CertificateCZ."Valid From");

        // [WHEN] Delete certificate
        asserterror CertificateCZ.Delete(true);

        // [THEN] Error occurs
        Assert.ExpectedError(
          StrSubstNo(NotCertificateUserErr, UserId, CertificateCZ."Certificate Code", CertificateCZ."Valid From"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SignUTF8Text()
    var
        CertificateCZ: Record "Certificate CZ";
        Signature: DotNet Array;
        UTF8Text: Text;
        HashAlgorithm: Text;
    begin
        // [SCENARIO] Sign text in UTF8 encoding by certificate
        // [GIVEN] Create Certificate record with imported certificate in database
        Initialize;

        CreateDatabaseCertificate(CertificateCZ, '', true);
        UTF8Text := 'utf8texttosigned';
        HashAlgorithm := 'SHA256';

        // [WHEN] Sign text in UTF8 encoding
        CertificateCZ.SignUTF8Text(UTF8Text, HashAlgorithm, Signature);

        // [THEN] Verify is successful
        Assert.IsTrue(CertificateCZ.VerifySignedUTF8Text(UTF8Text, 'SHA256', Signature, false), VerifyMustBeSuccessErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SignUTF8TextWithoutPrivateKey()
    var
        CertificateCZ: Record "Certificate CZ";
        Signature: DotNet Array;
        UTF8Text: Text;
        HashAlgorithm: Text;
    begin
        // [SCENARIO] Sign text in UTF8 encoding by certificate without private key
        // [GIVEN] Create Certificate record with imported certificate in database without private key
        Initialize;

        CreateDatabaseCertificate(CertificateCZ, '', false);
        UTF8Text := 'utf8texttosigned';
        HashAlgorithm := 'SHA256';

        // [WHEN] Sign text in UTF8 encoding
        asserterror CertificateCZ.SignUTF8Text(UTF8Text, HashAlgorithm, Signature);

        // [THEN] Error occurs
        Assert.ExpectedError(PrivateKeyNotExistErr);
    end;

    local procedure Initialize()
    var
    begin
        if IsInitialized then
            exit;

        if EncryptionKeyExists then
            DeleteEncryptionKey;
        IsInitialized := true;
        Commit;
    end;

    local procedure CreateCertificate(var CertificateCZ: Record "Certificate CZ"; UserCode: Code[50]; StoreType: Option)
    var
        CertificateCZCode: Record "Certificate CZ Code";
    begin
        LibraryCertificateCZ.CreateCertificateCode(CertificateCZCode);
        LibraryCertificateCZ.CreateCertificate(CertificateCZ, CertificateCZCode.Code, UserCode, StoreType);
    end;

    local procedure CreateDatabaseCertificate(var CertificateCZ: Record "Certificate CZ"; UserCode: Code[50]; WithPrivateKey: Boolean)
    begin
        CreateCertificate(CertificateCZ, UserCode, CertificateCZ."Store Type"::Database);
        LibraryCertificateCZ.SaveCertificateObjectToDatabase(CertificateCZ, WithPrivateKey);
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure EncryptionConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        case true of
            StrPos(Message, 'Do you want to save the encryption key?') <> 0:
                Reply := false;
            StrPos(Message, 'Enabling encryption will generate an encryption key') <> 0:
                Reply := true;
            StrPos(Message, 'Disabling encryption will decrypt the encrypted data') <> 0:
                Reply := true;
            else
                Reply := false;
        end;
    end;
}

