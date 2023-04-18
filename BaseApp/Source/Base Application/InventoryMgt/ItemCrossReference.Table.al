table 5717 "Item Cross Reference"
{
    Caption = 'Item Cross Reference';
    ObsoleteReason = 'Replaced by ItemReference table as part of Item Reference feature.';
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(3; "Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure';
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(4; "Cross-Reference Type"; Option)
        {
            Caption = 'Cross-Reference Type';
            OptionCaption = ' ,Customer,Vendor,Bar Code';
            OptionMembers = " ",Customer,Vendor,"Bar Code";

            trigger OnValidate()
            begin
                if ("Cross-Reference Type" <> xRec."Cross-Reference Type") and
                   (xRec."Cross-Reference Type" <> xRec."Cross-Reference Type"::" ") or
                   ("Cross-Reference Type" = "Cross-Reference Type"::"Bar Code")
                then
                    "Cross-Reference Type No." := '';
            end;
        }
        field(5; "Cross-Reference Type No."; Code[30])
        {
            Caption = 'Cross-Reference Type No.';
            TableRelation = IF ("Cross-Reference Type" = CONST(Customer)) Customer."No."
            ELSE
            IF ("Cross-Reference Type" = CONST(Vendor)) Vendor."No.";
        }
        field(6; "Cross-Reference No."; Code[20])
        {
            Caption = 'Cross-Reference No.';
            NotBlank = true;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Discontinue Bar Code"; Boolean)
        {
            Caption = 'Discontinue Bar Code';

        }
        field(9; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Unit of Measure", "Cross-Reference Type", "Cross-Reference Type No.", "Cross-Reference No.")
        {
            Clustered = true;
        }
        key(Key2; "Cross-Reference No.")
        {
        }
        key(Key3; "Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.", "Discontinue Bar Code")
        {
        }
        key(Key4; "Cross-Reference Type", "Cross-Reference No.")
        {
        }
        key(Key5; "Item No.", "Variant Code", "Unit of Measure", "Cross-Reference Type", "Cross-Reference No.", "Discontinue Bar Code")
        {
        }
        key(Key6; "Cross-Reference Type", "Cross-Reference Type No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", "Cross-Reference Type", "Cross-Reference Type No.", "Cross-Reference No.", Description)
        {
        }
    }
}
