codeunit 143053 "Library - Crypto"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    [Scope('OnPrem')]
    procedure CompareTwoArrayOfBytes(Bytes1: DotNet Array; Bytes2: DotNet Array): Boolean
    begin
        exit(ConvertBytesToString(Bytes1) = ConvertBytesToString(Bytes2));
    end;

    [Scope('OnPrem')]
    procedure ConvertBytesToString(Bytes: DotNet Array): Text
    var
        Encoding: DotNet Encoding;
    begin
        exit(Encoding.ASCII.GetString(Bytes));
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure ComputeHash(Data: DotNet Array; HashAlgorithm: Text; var Hash: DotNet Array)
    var
        CryptoConfig: DotNet CryptoConfig;
        HashAlgorithmObject: DotNet HashAlgorithm;
    begin
        HashAlgorithmObject := CryptoConfig.CreateFromName(HashAlgorithm);
        Hash := HashAlgorithmObject.ComputeHash(Data);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure SignTextRSA(Data: Text; Encoding: DotNet Encoding; "Key": DotNet RSA; HashAlgorithm: Text; var Signature: DotNet Array)
    begin
        SignByteArrayRSA(Encoding.GetBytes(Data), Key, HashAlgorithm, Signature);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure SignByteArrayRSA(Data: DotNet Array; "Key": DotNet RSA; HashAlgorithm: Text; var Signature: DotNet Array)
    var
        RSACryptoServiceProvider: DotNet RSACryptoServiceProvider;
    begin
        RSACryptoServiceProvider := RSACryptoServiceProvider.RSACryptoServiceProvider;
        RSACryptoServiceProvider.ImportParameters(Key.ExportParameters(true));
        Signature := RSACryptoServiceProvider.SignData(Data, HashAlgorithm);
    end;

    [Scope('OnPrem')]
    procedure VerifySignedTextRSA(SignedData: Text; Encoding: DotNet Encoding; "Key": DotNet RSA; HashAlgorithm: Text; Signature: DotNet Array): Boolean
    begin
        exit(VerifySignedByteArrayRSA(Encoding.GetBytes(SignedData), Key, HashAlgorithm, Signature));
    end;

    [Scope('OnPrem')]
    procedure VerifySignedByteArrayRSA(SignedData: DotNet Array; "Key": DotNet RSA; HashAlgorithm: Text; Signature: DotNet Array): Boolean
    var
        RSACryptoServiceProvider: DotNet RSACryptoServiceProvider;
    begin
        RSACryptoServiceProvider := RSACryptoServiceProvider.RSACryptoServiceProvider;
        RSACryptoServiceProvider.ImportParameters(Key.ExportParameters(false));
        exit(RSACryptoServiceProvider.VerifyData(SignedData, HashAlgorithm, Signature));
    end;

    [Scope('OnPrem')]
    procedure GenerateRandomBytes(var Bytes: DotNet Array)
    var
        Encoding: DotNet Encoding;
    begin
        Bytes := Encoding.ASCII.GetBytes(GenerateRandomText);
    end;

    [Scope('OnPrem')]
    procedure GenerateRandomText(): Text
    begin
        exit(LibraryUtility.GenerateRandomText(256));
    end;

    [Scope('OnPrem')]
    procedure GetDefaultHashAlgorithm(): Text
    var
        CryptoManagement: Codeunit "Crypto Management";
    begin
        exit(CryptoManagement.DefaultHashAlgorithm);
    end;

    [Scope('OnPrem')]
    procedure GetUnsupportedHashAlgorithm(): Text
    begin
        exit('UNSUPPORTEDHASHALGORITHM');
    end;
}

