namespace System.Security.Encryption;

table 1805 "Encrypted Key/Value"
{
    Caption = 'Encrypted Key/Value';
    DataPerCompany = false;
    ObsoleteReason = 'The suggested way to store the secrets is Isolated Storage, therefore Encrypted Key/Value will be removed.';
    ObsoleteState = Removed;
    ReplicateData = false;
    ObsoleteTag = '15.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Code[50])
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

    procedure GetValue(): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        InStr: InStream;
        Result: Text;
    begin
        if not Value.HasValue() then
            exit('');

        CalcFields(Value);
        Value.CreateInStream(InStr);
        InStr.Read(Result);

        if CryptographyManagement.IsEncryptionEnabled() then
            exit(CryptographyManagement.Decrypt(Result));

        exit('');
    end;

    procedure InsertValue(NewValue: Text)
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        OutStr: OutStream;
        EncryptedText: Text;
    begin
        // Encryption must be enabled on insert
        EncryptedText := CryptographyManagement.EncryptText(CopyStr(NewValue, 1, 215));
        Value.CreateOutStream(OutStr);
        OutStr.Write(EncryptedText);
    end;
}

