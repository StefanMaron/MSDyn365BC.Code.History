table 27020 "SAT MX Resources"
{
    Caption = 'SAT MX Resources';
    DataPerCompany = false;

    fields
    {
        field(1; "Code"; Code[50])
        {
            Caption = 'Code';
        }
        field(2; Blob; BLOB)
        {
            Caption = 'Blob';
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

