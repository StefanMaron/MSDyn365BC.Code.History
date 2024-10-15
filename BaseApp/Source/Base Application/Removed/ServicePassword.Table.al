table 1261 "Service Password"
{
    Caption = 'Service Password';
    ObsoleteReason = 'The suggested way to store the secrets is Isolated Storage, therefore Service Password will be removed.';
    ObsoleteState = Removed;
    ReplicateData = false;
    ObsoleteTag = '15.0';
    DataClassification = CustomerContent;

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
        Key := CreateGuid();
    end;

    procedure SavePassword(PasswordText: Text)
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        OutStream: OutStream;
    begin
        if CryptographyManagement.IsEncryptionPossible() then
            PasswordText := CryptographyManagement.EncryptText(CopyStr(PasswordText,1,215));
        Value.CreateOutStream(OutStream);
        OutStream.Write(PasswordText);
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
        if CryptographyManagement.IsEncryptionPossible() then
            exit(CryptographyManagement.Decrypt(PasswordText));
        exit(PasswordText);
    end;
}

