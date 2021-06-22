table 5886 "Exp. Phys. Invt. Tracking"
{
    Caption = 'Exp. Phys. Invt. Tracking';
    DrillDownPageID = "Exp. Phys. Invt. Tracking";
    LookupPageID = "Exp. Phys. Invt. Tracking";

    fields
    {
        field(1; "Order No"; Code[20])
        {
            Caption = 'Order No';
            TableRelation = "Phys. Invt. Order Header";
        }
        field(2; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            TableRelation = "Phys. Invt. Order Line"."Line No." WHERE("Document No." = FIELD("Order No"));
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

    procedure InsertLine(DocumentNo: Code[20]; LineNo: Integer; SerialNo: Code[50]; LotNo: Code[50]; Quantity: Decimal)
    begin
        Init;
        "Order No" := DocumentNo;
        "Order Line No." := LineNo;
        "Serial No." := SerialNo;
        "Lot No." := LotNo;
        "Quantity (Base)" := Quantity;
        Insert;
    end;

    procedure DeleteLine(DocumentNo: Code[20]; LineNo: Integer; RemoveAll: Boolean)
    begin
        SetRange("Order No", DocumentNo);
        SetRange("Order Line No.", LineNo);
        if not RemoveAll then
            SetRange("Quantity (Base)", 0);
        DeleteAll();
    end;
}

