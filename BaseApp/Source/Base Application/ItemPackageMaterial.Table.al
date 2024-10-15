table 31071 "Item Package Material"
{
    Caption = 'Item Package Material';
    ObsoleteState = Removed;
    ObsoleteReason = 'The functionality of Packaging Material will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '18.0';

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
        }
        field(3; "Item Unit Of Measure Code"; Code[10])
        {
            Caption = 'Item Unit Of Measure Code';
            NotBlank = true;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
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

