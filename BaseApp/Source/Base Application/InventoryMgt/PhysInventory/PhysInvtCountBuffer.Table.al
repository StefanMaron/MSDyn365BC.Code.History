table 5888 "Phys. Invt. Count Buffer"
{
    Caption = 'Phys. Invt. Count Buffer';

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(10; "Exp. Serial No."; Code[50])
        {
            Caption = 'Exp. Serial No.';
            DataClassification = SystemMetadata;
        }
        field(11; "Exp. Lot No."; Code[50])
        {
            Caption = 'Exp. Lot No.';
            DataClassification = SystemMetadata;
        }
        field(12; "Exp. Qty. (Base)"; Decimal)
        {
            Caption = 'Exp. Qty. (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(20; "Rec. No."; Integer)
        {
            Caption = 'Rec. No.';
            DataClassification = SystemMetadata;
        }
        field(21; "Rec. Line No."; Integer)
        {
            Caption = 'Rec. Line No.';
            DataClassification = SystemMetadata;
        }
        field(22; "Rec. Serial No."; Code[50])
        {
            Caption = 'Rec. Serial No.';
            DataClassification = SystemMetadata;
        }
        field(23; "Rec. Lot No."; Code[50])
        {
            Caption = 'Rec. Lot No.';
            DataClassification = SystemMetadata;
        }
        field(24; "Rec. Qty. (Base)"; Decimal)
        {
            Caption = 'Rec. Qty. (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(30; "Track. Serial No."; Code[50])
        {
            Caption = 'Track. Serial No.';
            DataClassification = SystemMetadata;
        }
        field(31; "Track. Lot No."; Code[50])
        {
            Caption = 'Track. Lot No.';
            DataClassification = SystemMetadata;
        }
        field(32; "Track. Qty. Neg. (Base)"; Decimal)
        {
            Caption = 'Track. Qty. Neg. (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(33; "Track. Qty. Pos. (Base)"; Decimal)
        {
            Caption = 'Track. Qty. Pos. (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetTrackingFields(SerialNo: Code[50]; LotNo: Code[50]; QtyPosBase: Decimal; QtyNegBase: Decimal)
    begin
        "Track. Serial No." := SerialNo;
        "Track. Lot No." := LotNo;
        "Track. Qty. Pos. (Base)" := QtyPosBase;
        "Track. Qty. Neg. (Base)" := QtyNegBase;
    end;
}

