codeunit 145017 "Crypto Mgt. UT"
{
    // // [FEATURE] [Cryptography] [UT]

    Subtype = Test;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryCertificateCZ: Codeunit "Library - Certificate CZ";
        LibraryCrypto: Codeunit "Library - Crypto";
        IsInitialized: Boolean;
        HashIncorrectErr: Label 'Hash is incorrect.';
        HashAlgNotSupportedErr: Label 'Hash algorithm %1 is not supported.\\Supported algorithms are:\\%2.', Comment = '%1 = hash algorithm; %2 = supported algorithms';
        KeyNotValidErr: Label 'Key not valid for use in specified state.';
        SignatureIncorrectErr: Label 'Signature is incorrect.';
        SignatureNotValidErr: Label 'Signature is not valid.';

    [Test]
    [Scope('OnPrem')]
    procedure ComputingHashByDefaultHashAlgorithm()
    var
        CryptoManagement: Codeunit "Crypto Management";
        Bytes: DotNet Array;
        Hash: DotNet Array;
        ControlHash: DotNet Array;
    begin
        // [SCENARIO] Compute hash by default hash algorithm
        // [GIVEN] Generate random array of bytes
        Initialize;

        GenerateRandomBytes(Bytes);

        // [WHEN] Compute hash
        CryptoManagement.ComputeHash(Bytes, GetDefaultHashAlgorithm, Hash);

        // [THEN] Hash must be the same as control hash
        ComputeHash(Bytes, GetDefaultHashAlgorithm, ControlHash);
        Assert.IsTrue(CompareTwoArrayOfBytes(Hash, ControlHash), HashIncorrectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComputingHashByUnsupportedHashAlgorithm()
    var
        CryptoManagement: Codeunit "Crypto Management";
        Bytes: DotNet Array;
        Hash: DotNet Array;
    begin
        // [SCENARIO] Compute hash by unsupported hash algorithm
        // [GIVEN] Generate random array of bytes
        Initialize;

        GenerateRandomBytes(Bytes);

        // [WHEN] Compute hash
        asserterror CryptoManagement.ComputeHash(Bytes, GetUnsupportedHashAlgorithm, Hash);

        // [THEN] Error occurs
        Assert.ExpectedError(
          StrSubstNo(
            HashAlgNotSupportedErr, GetUnsupportedHashAlgorithm, CryptoManagement.GetSupportedHashAlgorithms));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SigningTextWithPrivateKey()
    var
        CryptoManagement: Codeunit "Crypto Management";
        Encoding: DotNet Encoding;
        "Key": DotNet AsymmetricAlgorithm;
        Signature: DotNet Array;
        ControlSignature: DotNet Array;
        Data: Text;
    begin
        // [SCENARIO] Sign text with private key
        // [GIVEN] Generate random text
        // [GIVEN] Get test private key
        Initialize;

        Data := GenerateRandomText;
        GetCertificatePrivateKey(Key);

        // [WHEN] Sign text
        CryptoManagement.SignTextRSA(Data, Encoding.ASCII, Key, GetDefaultHashAlgorithm, Signature);

        // [THEN] Signature must be the same as control signature
        // [THEN] Signature is valid
        SignTextRSA(Data, Encoding.ASCII, Key, GetDefaultHashAlgorithm, ControlSignature);
        Assert.IsTrue(CompareTwoArrayOfBytes(Signature, ControlSignature), SignatureIncorrectErr);
        Assert.IsTrue(VerifySignedTextRSA(Data, Encoding.ASCII, Key, GetDefaultHashAlgorithm, Signature), SignatureNotValidErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SigningTextWithPublicKey()
    var
        CryptoManagement: Codeunit "Crypto Management";
        Encoding: DotNet Encoding;
        "Key": DotNet AsymmetricAlgorithm;
        Signature: DotNet Array;
        Data: Text;
    begin
        // [SCENARIO] Sign text with public key
        // [GIVEN] Generate random text
        // [GIVEN] Get test public key
        Initialize;

        Data := GenerateRandomText;
        GetCertificatePublicKey(Key);

        // [WHEN] Sign text
        asserterror CryptoManagement.SignTextRSA(Data, Encoding.ASCII, Key, GetDefaultHashAlgorithm, Signature);

        // [THEN] Error occurs
        Assert.ExpectedError(KeyNotValidErr);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit;
    end;

    local procedure CompareTwoArrayOfBytes(Bytes1: DotNet Array; Bytes2: DotNet Array): Boolean
    begin
        exit(LibraryCrypto.CompareTwoArrayOfBytes(Bytes1, Bytes2));
    end;

    local procedure ComputeHash(Data: DotNet Array; HashAlgorithm: Text; var Hash: DotNet Array)
    begin
        LibraryCrypto.ComputeHash(Data, HashAlgorithm, Hash);
    end;

    local procedure GenerateRandomBytes(var Bytes: DotNet Array)
    begin
        LibraryCrypto.GenerateRandomBytes(Bytes);
    end;

    local procedure GenerateRandomText(): Text
    begin
        exit(LibraryCrypto.GenerateRandomText);
    end;

    local procedure GetCertificatePrivateKey(var "Key": DotNet AsymmetricAlgorithm)
    begin
        LibraryCertificateCZ.GetCertificatePrivateKey(Key);
    end;

    local procedure GetCertificatePublicKey(var "Key": DotNet AsymmetricAlgorithm)
    begin
        LibraryCertificateCZ.GetCertificatePublicKey(Key);
    end;

    local procedure GetDefaultHashAlgorithm(): Text
    begin
        exit(LibraryCrypto.GetDefaultHashAlgorithm);
    end;

    local procedure GetUnsupportedHashAlgorithm(): Text
    begin
        exit(LibraryCrypto.GetUnsupportedHashAlgorithm);
    end;

    local procedure SignTextRSA(Data: Text; Encoding: DotNet Encoding; "Key": DotNet RSA; HashAlgorithm: Text; var Signature: DotNet Array)
    begin
        LibraryCrypto.SignTextRSA(Data, Encoding, Key, HashAlgorithm, Signature);
    end;

    local procedure VerifySignedTextRSA(SignedData: Text; Encoding: DotNet Encoding; "Key": DotNet RSA; HashAlgorithm: Text; Signature: DotNet Array): Boolean
    begin
        exit(LibraryCrypto.VerifySignedTextRSA(SignedData, Encoding, Key, HashAlgorithm, Signature));
    end;
}

