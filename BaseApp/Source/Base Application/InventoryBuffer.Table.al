table 307 "Inventory Buffer"
{
    Caption = 'Inventory Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;
            TableRelation = Item;
        }
        field(4; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
            TableRelation = Location;
        }
        field(5; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(6; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = SystemMetadata;
        }
        field(5400; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(5401; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            DataClassification = SystemMetadata;
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            DataClassification = SystemMetadata;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            DataClassification = SystemMetadata;
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
            DataClassification = SystemMetadata;
        }
        field(14900; "CD No."; Code[50])
        {
            Caption = 'CD No.';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by field Package No.';
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Dimension Entry No.", "Location Code", "Bin Code", "Lot No.", "Serial No.", "Package No.")
        {
            Clustered = true;
        }
        key(Key2; "Location Code", "Variant Code", Quantity)
        {
            SumIndexFields = Quantity;
        }
    }

    fieldgroups
    {
    }
}

