table 27022 "SAT Trailer Type"
{
    DataPerCompany = false;
    DrillDownPageID = "SAT Trailer Types";
    LookupPageID = "SAT Trailer Types";

    fields
    {
        field(1; "Code"; Code[10])
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

