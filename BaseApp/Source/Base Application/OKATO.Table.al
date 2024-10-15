table 12427 OKATO
{
    Caption = 'OKATO';
    LookupPageID = "OKATO Codes";

    fields
    {
        field(1; "Code"; Code[11])
        {
            Caption = 'Code';
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Region Code"; Code[2])
        {
            Caption = 'Region Code';
        }
        field(4; "Tax Authority No."; Code[20])
        {
            Caption = 'Tax Authority No.';
            TableRelation = Vendor WHERE("Vendor Type" = CONST("Tax Authority"));
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
        fieldgroup(DropDown; "Code", Name, "Region Code", "Tax Authority No.")
        {
        }
    }
}

