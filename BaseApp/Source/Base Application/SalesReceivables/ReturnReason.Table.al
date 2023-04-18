table 6635 "Return Reason"
{
    Caption = 'Return Reason';
    DrillDownPageID = "Return Reasons";
    LookupPageID = "Return Reasons";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Default Location Code"; Code[10])
        {
            Caption = 'Default Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(4; "Inventory Value Zero"; Boolean)
        {
            Caption = 'Inventory Value Zero';
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
        fieldgroup(DropDown; "Code", Description, "Default Location Code", "Inventory Value Zero")
        {
        }
    }
}

