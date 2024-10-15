table 27024 "SAT Hazardous Material"
{
    DataPerCompany = false;
    DrillDownPageID = "SAT Hazardous Materials";
    LookupPageID = "SAT Hazardous Materials";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[250])
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

