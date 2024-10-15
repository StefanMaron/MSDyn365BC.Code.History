table 2101 "O365 Item Basket Entry"
{
    Caption = 'O365 Item Basket Entry';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(3; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(4; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DecimalPlaces = 2 : 5;
        }
        field(5; "Line Total"; Decimal)
        {
            Caption = 'Line Total';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            TableRelation = "Unit of Measure";
            ValidateTableRelation = false;
        }
        field(92; Picture; MediaSet)
        {
            Caption = 'Picture';
        }
        field(150; "Brick Text 1"; Text[30])
        {
            Caption = 'Brick Text 1';
        }
        field(151; "Brick Text 2"; Text[30])
        {
            Caption = 'Line Amount';
        }
    }

    keys
    {
        key(Key1; "Item No.")
        {
            Clustered = true;
        }
        key(Key2; Description)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; Description, "Item No.", Quantity, "Unit Price", "Brick Text 2", Picture)
        {
        }
    }
}

