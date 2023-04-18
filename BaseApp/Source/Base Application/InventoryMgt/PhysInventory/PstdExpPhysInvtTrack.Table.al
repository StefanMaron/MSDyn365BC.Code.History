table 5887 "Pstd. Exp. Phys. Invt. Track"
{
    Caption = 'Pstd. Exp. Phys. Invt. Track';
    DrillDownPageID = "Posted Exp. Phys. Invt. Track";
    LookupPageID = "Posted Exp. Phys. Invt. Track";

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
            TableRelation = "Pstd. Phys. Invt. Order Line"."Line No." WHERE("Document No." = FIELD("Order No"));
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

