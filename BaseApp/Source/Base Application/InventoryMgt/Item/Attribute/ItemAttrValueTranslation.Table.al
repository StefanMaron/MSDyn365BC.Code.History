namespace Microsoft.Inventory.Item.Attribute;

using System.Globalization;

table 7503 "Item Attr. Value Translation"
{
    Caption = 'Item Attr. Value Translation';

    fields
    {
        field(1; "Attribute ID"; Integer)
        {
            Caption = 'Attribute ID';
            NotBlank = true;
        }
        field(2; ID; Integer)
        {
            Caption = 'ID';
            NotBlank = true;
        }
        field(4; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            NotBlank = true;
            TableRelation = Language;
        }
        field(5; Name; Text[250])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(Key1; "Attribute ID", ID, "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

