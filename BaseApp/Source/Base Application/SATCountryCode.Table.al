table 27014 "SAT Country Code"
{
    Caption = 'SAT Country Code';
    DataPerCompany = false;

    fields
    {
        field(1; "SAT Country Code"; Code[10])
        {
            Caption = 'SAT Country Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "SAT Country Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

