table 31071 "Item Package Material"
{
    Caption = 'Item Package Material';
    LookupPageID = "Item Package Materials";

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item."No.";
        }
        field(2; "Package Material Code"; Code[10])
        {
            Caption = 'Package Material Code';
            NotBlank = true;
            TableRelation = "Package Material".Code;
        }
        field(3; "Item Unit Of Measure Code"; Code[10])
        {
            Caption = 'Item Unit Of Measure Code';
            NotBlank = true;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(4; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 2 : 5;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Item Unit Of Measure Code", "Package Material Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

