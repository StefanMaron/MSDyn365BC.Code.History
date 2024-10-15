table 27029 "SAT Suburb"
{
    DataPerCompany = false;

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'Code';
        }
        field(2; "Suburb Code"; Code[10])
        {
        }
        field(3; "Postal Code"; Code[20])
        {
            Caption = 'Postal Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

