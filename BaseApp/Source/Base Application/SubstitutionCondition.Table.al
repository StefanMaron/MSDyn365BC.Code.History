table 5716 "Substitution Condition"
{
    Caption = 'Substitution Condition';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = "Item Substitution"."No." WHERE("No." = FIELD("No."));
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Substitution"."Variant Code" WHERE("No." = FIELD("No."),
                                                                      "Variant Code" = FIELD("Variant Code"));
        }
        field(3; "Substitute No."; Code[20])
        {
            Caption = 'Substitute No.';
            TableRelation = "Item Substitution"."Substitute No." WHERE("No." = FIELD("No."),
                                                                        "Variant Code" = FIELD("Variant Code"),
                                                                        "Substitute No." = FIELD("Substitute No."));
        }
        field(4; "Substitute Variant Code"; Code[10])
        {
            Caption = 'Substitute Variant Code';
            TableRelation = "Item Substitution"."Substitute Variant Code" WHERE("No." = FIELD("No."),
                                                                                 "Variant Code" = FIELD("Variant Code"),
                                                                                 "Substitute No." = FIELD("Substitute No."),
                                                                                 "Substitute Variant Code" = FIELD("Substitute Variant Code"));
        }
        field(5; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(6; Condition; Text[80])
        {
            Caption = 'Condition';
        }
        field(100; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Item,Catalog Item';
            OptionMembers = Item,"Nonstock Item";
        }
        field(101; "Substitute Type"; Option)
        {
            Caption = 'Substitute Type';
            OptionCaption = 'Item,Catalog Item';
            OptionMembers = Item,"Nonstock Item";
        }
    }

    keys
    {
        key(Key1; Type, "No.", "Variant Code", "Substitute Type", "Substitute No.", "Substitute Variant Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

