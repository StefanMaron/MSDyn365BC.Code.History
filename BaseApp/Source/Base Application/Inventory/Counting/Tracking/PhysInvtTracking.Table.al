namespace Microsoft.Inventory.Counting.Tracking;

table 5885 "Phys. Invt. Tracking"
{
    Caption = 'Phys. Invt. Tracking';
    ObsoleteReason = 'Replaced by table Invt.Order.Tracking.';
#if not CLEAN24
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
#endif
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Lot No"; Code[50])
        {
            Caption = 'Lot No';
            DataClassification = SystemMetadata;
        }
        field(10; "Qty. Recorded (Base)"; Decimal)
        {
            Caption = 'Qty. Recorded (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(11; "Qty. Expected (Base)"; Decimal)
        {
            Caption = 'Qty. Expected (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(20; "Qty. To Transfer"; Decimal)
        {
            Caption = 'Qty. To Transfer';
            DataClassification = SystemMetadata;
        }
        field(21; "Outstanding Quantity"; Decimal)
        {
            Caption = 'Outstanding Quantity';
            DataClassification = SystemMetadata;
        }
        field(22; Open; Boolean)
        {
            Caption = 'Open';
            DataClassification = SystemMetadata;
        }
        field(23; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Serial No.", "Lot No")
        {
            Clustered = true;
        }
        key(Key2; Open)
        {
        }
    }

    fieldgroups
    {
    }
}

