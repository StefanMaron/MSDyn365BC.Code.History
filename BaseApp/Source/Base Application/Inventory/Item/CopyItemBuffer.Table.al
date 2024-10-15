namespace Microsoft.Inventory.Item;

table 729 "Copy Item Buffer"
{
    Caption = 'Copy Item Buffer';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Source Item No."; Code[20])
        {
            Caption = 'Source Item No.';
            TableRelation = Item;
            DataClassification = SystemMetadata;
        }
        field(3; "Target Item No."; Code[20])
        {
            Caption = 'Target Item No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Target No. Series"; Code[20])
        {
            Caption = 'Target No. Series';
            DataClassification = SystemMetadata;
        }
        field(5; "Number of Copies"; Integer)
        {
            Caption = 'Number of Copies';
            DataClassification = SystemMetadata;
        }
        field(10; "General Item Information"; Boolean)
        {
            Caption = 'General Item Information';
            DataClassification = SystemMetadata;
        }
        field(11; "Units of Measure"; Boolean)
        {
            Caption = 'Units of Measure';
            DataClassification = SystemMetadata;
        }
        field(12; Dimensions; Boolean)
        {
            Caption = 'Dimensions';
            DataClassification = SystemMetadata;
        }
        field(13; Picture; Boolean)
        {
            Caption = 'Picture';
            DataClassification = SystemMetadata;
        }
        field(14; Comments; Boolean)
        {
            Caption = 'Comments';
            DataClassification = SystemMetadata;
        }
        field(15; "Sales Prices"; Boolean)
        {
            Caption = 'Sales Prices';
            DataClassification = SystemMetadata;
        }
        field(16; "Sales Line Discounts"; Boolean)
        {
            Caption = 'Sales Line Discounts';
            DataClassification = SystemMetadata;
        }
        field(17; "Purchase Prices"; Boolean)
        {
            Caption = 'Purchase Prices';
            DataClassification = SystemMetadata;
        }
        field(18; "Purchase Line Discounts"; Boolean)
        {
            Caption = 'Purchase Line Discounts';
            DataClassification = SystemMetadata;
        }
        field(19; Troubleshooting; Boolean)
        {
            Caption = 'Troubleshooting';
            DataClassification = SystemMetadata;
        }
        field(20; "Resource Skills"; Boolean)
        {
            Caption = 'Resource Skills';
            DataClassification = SystemMetadata;
        }
        field(21; "Item Variants"; Boolean)
        {
            Caption = 'Item Variants';
            DataClassification = SystemMetadata;
        }
        field(22; Translations; Boolean)
        {
            Caption = 'Translations';
            DataClassification = SystemMetadata;
        }
        field(23; "Extended Texts"; Boolean)
        {
            Caption = 'Extended Texts';
            DataClassification = SystemMetadata;
        }
        field(24; "BOM Components"; Boolean)
        {
            Caption = 'Assembly BOM Components';
            DataClassification = SystemMetadata;
        }
        field(25; "Item Vendors"; Boolean)
        {
            Caption = 'Item Vendors';
            DataClassification = SystemMetadata;
        }
        field(26; Attributes; Boolean)
        {
            Caption = 'Attributes';
            DataClassification = SystemMetadata;
        }
        field(27; "Item Cross References"; Boolean)
        {
            Caption = 'Item Cross References';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced with parameter Item References';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
        field(28; "Item References"; Boolean)
        {
            Caption = 'Item References';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

