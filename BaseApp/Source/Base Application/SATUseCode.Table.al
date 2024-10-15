table 27012 "SAT Use Code"
{
    Caption = 'SAT Use Code';
    DataPerCompany = false;
    DrillDownPageID = "SAT Use Codes";
    LookupPageID = "SAT Use Codes";

    fields
    {
        field(1; "SAT Use Code"; Code[10])
        {
            Caption = 'SAT Use Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "SAT Use Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

