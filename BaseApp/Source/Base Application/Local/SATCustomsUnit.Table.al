table 27046 "SAT Customs Unit"
{
    DrillDownPageID = "SAT Custom Units";
    LookupPageID = "SAT Custom Units";

    fields
    {
        field(1; "Code"; Code[10])
        {
        }
        field(2; Description; Text[50])
        {
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

