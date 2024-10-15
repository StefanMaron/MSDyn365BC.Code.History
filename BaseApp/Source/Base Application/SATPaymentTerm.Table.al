table 27017 "SAT Payment Term"
{
    Caption = 'SAT Payment Term';
    DataPerCompany = false;
    DrillDownPageID = "SAT Payment Terms";
    LookupPageID = "SAT Payment Terms";

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

