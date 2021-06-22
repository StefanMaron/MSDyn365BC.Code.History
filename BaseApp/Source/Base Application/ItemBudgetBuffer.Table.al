table 7136 "Item Budget Buffer"
{
    Caption = 'Item Budget Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;
            TableRelation = Item;
        }
        field(2; "Source Type"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
        }
        field(3; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            DataClassification = SystemMetadata;
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Source Type" = CONST(Item)) Item;
        }
        field(4; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
            TableRelation = Location;
        }
        field(5; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(6; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(7; "Budget Dimension 1 Code"; Code[20])
        {
            Caption = 'Budget Dimension 1 Code';
            DataClassification = SystemMetadata;
        }
        field(8; "Budget Dimension 2 Code"; Code[20])
        {
            Caption = 'Budget Dimension 2 Code';
            DataClassification = SystemMetadata;
        }
        field(9; "Budget Dimension 3 Code"; Code[20])
        {
            Caption = 'Budget Dimension 3 Code';
            DataClassification = SystemMetadata;
        }
        field(10; Date; Date)
        {
            Caption = 'Date';
            DataClassification = SystemMetadata;
        }
        field(11; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(12; "Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Sales Amount';
            DataClassification = SystemMetadata;
        }
        field(13; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount';
            DataClassification = SystemMetadata;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
    }

    keys
    {
        key(Key1; "Item No.", "Source Type", "Source No.", "Location Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Budget Dimension 1 Code", "Budget Dimension 2 Code", "Budget Dimension 3 Code", Date)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

