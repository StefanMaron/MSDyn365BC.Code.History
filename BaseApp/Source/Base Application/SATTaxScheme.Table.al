table 27016 "SAT Tax Scheme"
{
    Caption = 'SAT Tax Scheme';
    DataPerCompany = false;

    fields
    {
        field(1; "SAT Tax Scheme"; Code[10])
        {
            Caption = 'SAT Tax Scheme';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "SAT Tax Scheme")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

