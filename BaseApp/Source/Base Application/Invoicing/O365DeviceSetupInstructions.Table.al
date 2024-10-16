table 1307 "O365 Device Setup Instructions"
{
    Caption = 'O365 Device Setup Instructions';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Code[10])
        {
            Caption = 'Key';
        }
        field(10; "Setup URL"; Text[250])
        {
            Caption = 'Setup URL';
            ExtendedDatatype = URL;
            ObsoleteReason = 'This field is obsolete after refactoring.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(11; "QR Code"; BLOB)
        {
            Caption = 'QR Code';
            SubType = Bitmap;
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
    var
        ClientTypeManagement: Codeunit "Client Type Management";

    procedure GetActivationCode(): Text
    var
        Url: Text;
        AddressWithoutProtocol: Text;
        ActivationCode: Text;
        AllowedCharacters: Text;
        I: Integer;
    begin
        Url := GetUrl(ClientTypeManagement.GetCurrentClientType());

        AddressWithoutProtocol := CopyStr(Url, StrPos(Url, '://') + 3);
        AllowedCharacters := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        for I := 1 to StrLen(AddressWithoutProtocol) do
            if StrPos(AllowedCharacters, UpperCase(Format(AddressWithoutProtocol[I]))) > 0 then
                ActivationCode += Format(AddressWithoutProtocol[I])
            else
                exit(ActivationCode);
    end;
}

