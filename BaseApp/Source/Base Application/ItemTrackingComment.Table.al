table 6506 "Item Tracking Comment"
{
    Caption = 'Item Tracking Comment';

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Serial No.,Lot No.';
            OptionMembers = " ","Serial No.","Lot No.";
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;
        }
        field(3; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(4; "Serial/Lot No."; Code[50])
        {
            Caption = 'Serial/Lot No.';
            NotBlank = true;
        }
        field(5; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(11; Date; Date)
        {
            Caption = 'Date';
        }
        field(13; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; Type, "Item No.", "Variant Code", "Serial/Lot No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

