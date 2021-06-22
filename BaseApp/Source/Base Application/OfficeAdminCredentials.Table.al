table 1612 "Office Admin. Credentials"
{
    Caption = 'Office Admin. Credentials';
    Permissions = TableData "Office Admin. Credentials" = r;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; Email; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
            NotBlank = true;
        }
        field(3; Password; Text[250])
        {
            Caption = 'Password';
            ExtendedDatatype = Masked;
            NotBlank = true;
        }
        field(4; Endpoint; Text[250])
        {
            Caption = 'Endpoint';
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
        if Endpoint = '' then
            Validate(Endpoint, DefaultEndpoint);
    end;

    trigger OnModify()
    begin
        if Endpoint = '' then
            Validate(Endpoint, DefaultEndpoint);
    end;

    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";

    procedure DefaultEndpoint(): Text[250]
    begin
        exit('https://ps.outlook.com/powershell-liveid');
    end;

    [Scope('OnPrem')]
    procedure SavePassword(PasswordText: Text)
    begin
        PasswordText := DelChr(PasswordText, '=', ' ');
        if Password = '' then
            Password := CreateGuid;

        IsolatedStorageManagement.Set(Password, PasswordText, DATASCOPE::Company);
        Modify;
    end;

    [Scope('OnPrem')]
    procedure GetPassword(): Text
    var
        Value: Text;
    begin
        if Password <> '' then
            IsolatedStorageManagement.Get(Password, DATASCOPE::Company, Value);

        exit(Value);
    end;
}

