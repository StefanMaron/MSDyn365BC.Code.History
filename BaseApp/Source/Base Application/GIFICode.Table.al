table 10015 "GIFI Code"
{
    Caption = 'GIFI Code';
    LookupPageID = "GIFI Codes";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Name; Text[120])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

