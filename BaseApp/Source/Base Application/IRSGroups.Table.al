table 10901 "IRS Groups"
{
    Caption = 'IRS Groups';
    LookupPageID = "IRS Group";

    fields
    {
        field(1; "No."; Code[2])
        {
            Caption = 'No.';
        }
        field(2; Class; Text[60])
        {
            Caption = 'Class';
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

