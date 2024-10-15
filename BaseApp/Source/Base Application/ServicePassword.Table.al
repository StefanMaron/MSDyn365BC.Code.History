table 1261 "Service Password"
{
    Caption = 'Service Password';
    ObsoleteReason = 'The suggested way to store the secrets is Isolated Storage, therefore Service Password will be removed.';
    ObsoleteState = Removed;
    ReplicateData = false;

    fields
    {
        field(1; "Key"; Guid)
        {
            Caption = 'Key';
        }
        field(2; Value; BLOB)
        {
            Caption = 'Value';
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        Key := CreateGuid;
    end;

    procedure SavePassword(PasswordText: Text)
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        OutStream: OutStream;
    begin
        // NAVCZ
        if StrLen(PasswordText) > BlockToEncryptLength then begin
            SaveLongText(PasswordText);
            exit;
        end;
        // NAVCZ

        if CryptographyManagement.IsEncryptionPossible then
            PasswordText := CryptographyManagement.Encrypt(PasswordText);
        Value.CreateOutStream(OutStream);
        OutStream.Write(PasswordText);
    end;

    [Scope('OnPrem')]
    procedure SaveCertificate(X509Certificate2: DotNet X509Certificate2; WithPrivateKey: Boolean)
    var
        CertificateCZMgt: Codeunit "Certificate CZ Management";
    begin
        // NAVCZ
        SaveLongText(CertificateCZMgt.EncodeCertificateToBase64(X509Certificate2, WithPrivateKey));
    end;

    local procedure SaveLongText(Text: Text)
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        OutStream: OutStream;
        EncryptedText: Text;
        Position: Integer;
    begin
        // NAVCZ
        Value.CreateOutStream(OutStream);
        if not CryptographyManagement.IsEncryptionPossible then begin
            OutStream.Write(Text);
            exit;
        end;

        Position := 1;
        repeat
            EncryptedText += CryptographyManagement.Encrypt(CopyStr(Text, Position, BlockToEncryptLength));
            Position += BlockToEncryptLength;
        until Position >= StrLen(Text);

        OutStream.Write(EncryptedText);
    end;

    procedure GetPassword(): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        InStream: InStream;
        PasswordText: Text;
    begin
        CalcFields(Value);
        Value.CreateInStream(InStream);
        InStream.Read(PasswordText);

        // NAVCZ
        if StrLen(PasswordText) > BlockEncryptedLength then
            exit(GetLongText);
        // NAVCZ

        if CryptographyManagement.IsEncryptionPossible then
            exit(CryptographyManagement.Decrypt(PasswordText));
        exit(PasswordText);
    end;

    [Scope('OnPrem')]
    procedure GetCertificate(var X509Certificate2: DotNet X509Certificate2)
    var
        CertificateCZMgt: Codeunit "Certificate CZ Management";
    begin
        // NAVCZ
        CertificateCZMgt.DecodeCertificateFromBase64(GetLongText, X509Certificate2);
    end;

    local procedure GetLongText(): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        InStream: InStream;
        Text: Text;
        DecryptedText: Text;
        Position: Integer;
    begin
        // NAVCZ
        CalcFields(Value);
        Value.CreateInStream(InStream);
        InStream.Read(Text);
        if not CryptographyManagement.IsEncryptionPossible then
            exit(Text);

        Position := 1;
        repeat
            DecryptedText += CryptographyManagement.Decrypt(CopyStr(Text, Position, BlockEncryptedLength));
            Position += BlockEncryptedLength;
        until Position >= StrLen(Text);

        exit(DecryptedText);
    end;

    local procedure BlockToEncryptLength(): Integer
    begin
        // NAVCZ
        exit(214);
    end;

    local procedure BlockEncryptedLength(): Integer
    begin
        // NAVCZ
        exit(344);
    end;
}

