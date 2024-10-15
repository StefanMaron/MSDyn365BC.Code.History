codeunit 31131 "Crypto Management"
{

    trigger OnRun()
    begin
    end;

    var
        HashAlgNotSupportedErr: Label 'Hash algorithm %1 is not supported.\\Supported algorithms are:\\%2.', Comment = '%1 = hash algorithm; %2 = supported algorithms';
        NotDefinedDataErr: Label 'Data are not defined.';
        NotDefinedKeyErr: Label 'Key is not defined.';
        SupportedHashAlgorithms: Option MD5,RIPEMD160,SHA1,SHA256,SHA384,SHA512;

    [TryFunction]
    [Scope('OnPrem')]
    procedure ComputeHash(Data: DotNet Array; HashAlgorithm: Text; var Hash: DotNet Array)
    var
        CryptoConfig: DotNet CryptoConfig;
        HashAlgorithmObject: DotNet HashAlgorithm;
    begin
        CheckHashAlgorithm(HashAlgorithm);
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
        CheckInputParameters(Data, Key, HashAlgorithm);

        if Data.Length = 0 then
            Error(NotDefinedDataErr);

        if HashAlgorithm = '' then
            HashAlgorithm := DefaultHashAlgorithm;

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
        CheckInputParameters(SignedData, Key, HashAlgorithm);

        if SignedData.Length = 0 then
            Error(NotDefinedDataErr);

        if HashAlgorithm = '' then
            HashAlgorithm := DefaultHashAlgorithm;

        RSACryptoServiceProvider := RSACryptoServiceProvider.RSACryptoServiceProvider;
        RSACryptoServiceProvider.ImportParameters(Key.ExportParameters(false));
        exit(RSACryptoServiceProvider.VerifyData(SignedData, HashAlgorithm, Signature));
    end;

    local procedure CheckInputParameters(Data: DotNet Object; "Key": DotNet RSA; HashAlgorithm: Text)
    begin
        if IsNull(Data) then
            Error(NotDefinedDataErr);

        if IsNull(Key) then
            Error(NotDefinedKeyErr);

        CheckHashAlgorithm(HashAlgorithm);
    end;

    local procedure CheckHashAlgorithm(HashAlgorithm: Text)
    begin
        if HashAlgorithm = '' then
            exit;

        if not Evaluate(SupportedHashAlgorithms, HashAlgorithm) then
            Error(HashAlgNotSupportedErr, HashAlgorithm, GetSupportedHashAlgorithms);
    end;

    [Scope('OnPrem')]
    procedure DefaultHashAlgorithm(): Text
    begin
        exit('SHA1');
    end;

    [Scope('OnPrem')]
    procedure GetSupportedHashAlgorithms(): Text
    var
        SupportedHashAlgorithmsText: Text;
        i: Integer;
    begin
        for i := 0 to 5 do begin
            SupportedHashAlgorithms := i;
            if SupportedHashAlgorithmsText = '' then
                SupportedHashAlgorithmsText := Format(SupportedHashAlgorithms)
            else
                SupportedHashAlgorithmsText += StrSubstNo(', %1', Format(SupportedHashAlgorithms));
        end;

        exit(SupportedHashAlgorithmsText);
    end;
}

