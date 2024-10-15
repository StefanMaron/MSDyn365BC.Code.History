table 5005362 "Post. Exp. Ph. In. Track. Line"
{
    Caption = 'Post. Exp. Ph. In. Track. Line';
    ObsoleteReason = 'Merged to W1';
    ObsoleteState = Pending;

    fields
    {
        field(1; "Order No"; Code[20])
        {
            Caption = 'Order No';
        }
        field(2; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            TableRelation = "Posted Phys. Invt. Order Line"."Line No." WHERE("Document No." = FIELD("Order No"));
        }
        field(3; "Serial No."; Code[20])
        {
            Caption = 'Serial No.';
        }
        field(4; "Lot No."; Code[20])
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
            SumIndexFields = "Quantity (Base)";
        }
    }

    fieldgroups
    {
    }
}

