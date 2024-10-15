table 18014 "Transfer Buffer"
{
    Caption = 'Transfer Buffer';

    fields
    {
        field(1; Type; Enum "Transfer Buffer Type")
        {
            Caption = 'Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "G/L Account"; Code[20])
        {
            Caption = 'G/L Account';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "G/L Account";
        }
        field(3; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(4; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(5; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Job;
        }
        field(6; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Gen. Business Posting Group";
        }
        field(8; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Gen. Product Posting Group";
        }
        field(9; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = EndUserIdentifiableInformation;
            DecimalPlaces = 1 : 5;
        }
        field(11; "Amount (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (ACY)';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "Src. Curr. Amount"; Decimal)
        {
            Caption = 'Src. Curr. Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(23; "Tax Amount"; Decimal)
        {
            Caption = 'Tax Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(26; "Tax %"; Decimal)
        {
            Caption = 'Tax %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(39; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(40; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Location;
        }
        field(41; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(44; "Charges Amount"; Decimal)
        {
            Caption = 'Charges Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(45; "Amount Loaded on Inventory"; Decimal)
        {
            Caption = 'Amount Loaded on Inventory';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(47; "Capital Item"; Boolean)
        {
            Caption = 'Capital Item';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(16521; "GST Amount"; Decimal)
        {
            Caption = 'GST Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16522; "GST Amount Loaded on Inventory"; Decimal)
        {
            Caption = 'GST Amount Loaded on Inventory';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16528; "Custom Duty Amount"; Decimal)
        {
            Caption = 'Custom Duty Amount';
            DataClassification = EndUserIdentifiableInformation;
            MinValue = 0;
        }
        field(18000; "Sorting No."; Integer)
        {
            Caption = 'Sorting No.';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
    keys
    {
        key(Key1; Type, "G/L Account", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Inventory Posting Group", "Item No.")
        {
            Clustered = true;
        }
        key(Key2; "Sorting No.")
        {

        }
    }
}

