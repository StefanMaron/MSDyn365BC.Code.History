table 10902 "IRS Types"
{
    Caption = 'IRS Types';
    LookupPageID = "IRS Type";

    fields
    {
        field(1; "No."; Code[4])
        {
            Caption = 'No.';
        }
        field(2; Type; Text[60])
        {
            Caption = 'Type';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

