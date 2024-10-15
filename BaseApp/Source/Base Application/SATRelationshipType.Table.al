table 27011 "SAT Relationship Type"
{
    Caption = 'SAT Relationship Type';
    DataPerCompany = false;

    fields
    {
        field(1; "SAT Relationship Type"; Code[10])
        {
            Caption = 'SAT Relationship Type';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "SAT Relationship Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

