table 6300 "Azure AD App Setup"
{
    Caption = 'Azure AD App Setup';
    DataPerCompany = false;
    ReplicateData = false;

    fields
    {
        field(1; "App ID"; Guid)
        {
            Caption = 'App ID';
            NotBlank = true;
        }
        field(2; "Secret Key"; BLOB)
        {
            Caption = 'Secret Key';
        }
        field(3; "Primary Key"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Primary Key';
        }
        field(4; "Redirect URL"; Text[150])
        {
            Caption = 'Redirect URL';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if Count > 1 then
            Error(OnlyOneRecordErr);
    end;

    var
        CryptographyManagement: Codeunit "Cryptography Management";
        OnlyOneRecordErr: Label 'There should be only one record for Azure AD App Setup.';

    procedure GetSecretKey() SecretKey: Text
    var
        InStream: InStream;
    begin
        CalcFields("Secret Key");
        "Secret Key".CreateInStream(InStream);
        InStream.Read(SecretKey);

        if CryptographyManagement.IsEncryptionPossible then
            exit(CryptographyManagement.Decrypt(SecretKey));

        exit(SecretKey);
    end;

    procedure SetSecretKey(SecretKey: Text)
    var
        OutStream: OutStream;
    begin
        if CryptographyManagement.IsEncryptionPossible then
            SecretKey := CryptographyManagement.Encrypt(SecretKey);

        "Secret Key".CreateOutStream(OutStream);
        OutStream.Write(SecretKey);
    end;
}

