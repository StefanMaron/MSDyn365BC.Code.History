table 17358 "Classificator OKIN"
{
    Caption = 'Classificator OKIN';
    LookupPageID = "OKIN Codes";

    fields
    {
        field(1; Group; Code[10])
        {
            Caption = 'Group';
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(3; Name; Text[250])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(Key1; Group, "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

