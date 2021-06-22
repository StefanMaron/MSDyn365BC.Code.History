table 128002 "UPG - CRM Connection Setup"
{
    fields
    {
        field(1; "Primary Key"; Code[20])
        {
            Caption = 'Primary Key';
        }
        field(5; "Last Update Invoice Entry No."; Integer)
        {
            Caption = 'Last Update Invoice Entry No.';
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
}