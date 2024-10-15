namespace Microsoft.Warehouse.ADCS;

using System;

table 7710 "ADCS User"
{
    Caption = 'ADCS User';

    fields
    {
        field(1; Name; Code[50])
        {
            Caption = 'Name';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }
        field(2; Password; Text[250])
        {
            Caption = 'Password';
            NotBlank = true;

            trigger OnValidate()
            begin
                TestField(Password);
                Password := CalculatePassword(CopyStr(Password, 1, 30));
            end;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField(Password);
    end;

    trigger OnModify()
    begin
        TestField(Password);
    end;

    trigger OnRename()
    begin
        Error(RenameIsNotAllowed);
    end;

    var
        RenameIsNotAllowed: Label 'You cannot rename the record.';

    [Scope('OnPrem')]
    procedure CalculatePassword(Input: Text[30]) HashedValue: Text[250]
    var
        Convert: DotNet Convert;
        CryptoProvider: DotNet SHA512Managed;
        Encoding: DotNet Encoding;
    begin
        CryptoProvider := CryptoProvider.SHA512Managed();
        HashedValue := Convert.ToBase64String(CryptoProvider.ComputeHash(Encoding.Unicode.GetBytes(Input + Name)));
        CryptoProvider.Clear();
        CryptoProvider.Dispose();
    end;
}

