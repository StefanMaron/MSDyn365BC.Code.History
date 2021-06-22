table 212 "Job Posting Buffer"
{
    Caption = 'Job Posting Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            DataClassification = SystemMetadata;
            TableRelation = Job;
        }
        field(2; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Usage,Sale';
            OptionMembers = Usage,Sale;
        }
        field(3; "Posting Group Type"; Option)
        {
            Caption = 'Posting Group Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Resource,Item,G/L Account';
            OptionMembers = Resource,Item,"G/L Account";
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Job Posting Group";
        }
        field(6; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(7; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(8; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = SystemMetadata;
        }
        field(9; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            DataClassification = SystemMetadata;
            TableRelation = "Work Type";
        }
        field(20; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(21; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(22; "Total Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Cost';
            DataClassification = SystemMetadata;
        }
        field(23; "Total Price"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Price';
            DataClassification = SystemMetadata;
        }
        field(24; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
            DataClassification = SystemMetadata;
        }
        field(25; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Business Posting Group";
        }
        field(26; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Product Posting Group";
        }
        field(27; "Additional-Currency Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
            DataClassification = SystemMetadata;
        }
        field(28; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = SystemMetadata;
        }
        field(29; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
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
        key(Key1; "Job No.", "Entry Type", "Posting Group Type", "No.", "Variant Code", "Posting Group", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Unit of Measure Code", "Work Type Code", "Dimension Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

