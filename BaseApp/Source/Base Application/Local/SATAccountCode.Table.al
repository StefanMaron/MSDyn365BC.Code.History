table 27000 "SAT Account Code"
{
    Caption = 'SAT Account Code';
    DrillDownPageID = "SAT Account Codes";
    LookupPageID = "SAT Account Codes";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
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

