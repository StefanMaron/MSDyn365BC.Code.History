table 12119 "Customs Office"
{
    Caption = 'Customs Office';
    DrillDownPageID = "Customs Offices";
    LookupPageID = "Customs Offices";

    fields
    {
        field(1; "Code"; Code[6])
        {
            Caption = 'Code';
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
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

