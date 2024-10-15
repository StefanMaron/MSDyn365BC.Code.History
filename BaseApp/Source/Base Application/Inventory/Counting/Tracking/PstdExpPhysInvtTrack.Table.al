namespace Microsoft.Inventory.Counting.Tracking;

using Microsoft.Inventory.Counting.History;

table 5887 "Pstd. Exp. Phys. Invt. Track"
{
    Caption = 'Pstd. Exp. Phys. Invt. Track';
    ObsoleteReason = 'Replaced by table Posted.Exp.Invt.Order.Tracking.';
#if not CLEAN24
    DrillDownPageID = "Posted Exp. Phys. Invt. Track";
    LookupPageID = "Posted Exp. Phys. Invt. Track";
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
#endif
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order No"; Code[20])
        {
            Caption = 'Order No';
            TableRelation = "Pstd. Phys. Invt. Order Hdr";
        }
        field(2; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            TableRelation = "Pstd. Phys. Invt. Order Line"."Line No." where("Document No." = field("Order No"));
        }
        field(3; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(4; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }
        field(30; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Order No", "Order Line No.", "Serial No.", "Lot No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

