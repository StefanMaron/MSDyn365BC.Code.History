table 27018 "SAT Payment Method"
{
    Caption = 'SAT Payment Method';
    DataPerCompany = false;
    DrillDownPageID = "SAT Payment Methods";
    LookupPageID = "SAT Payment Methods";

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

