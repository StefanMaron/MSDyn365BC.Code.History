table 27027 "SAT Municipality"
{
    DataPerCompany = false;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; State; Code[10])
        {
            Caption = 'State';
            TableRelation = "SAT State";
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code", State)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

