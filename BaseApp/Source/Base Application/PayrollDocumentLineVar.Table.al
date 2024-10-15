table 17437 "Payroll Document Line Var."
{
    Caption = 'Payroll Document Line Var.';
    LookupPageID = "Payroll Doc. Line Variables";

    fields
    {
        field(1; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            Editable = false;
            TableRelation = "Payroll Element";
        }
        field(2; Variable; Text[30])
        {
            Caption = 'Variable';
        }
        field(3; Value; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Value';
            Editable = false;
        }
        field(4; Error; Boolean)
        {
            Caption = 'Error';
            Editable = false;
        }
        field(7; Calculated; Boolean)
        {
            Caption = 'Calculated';
            Editable = false;
        }
        field(8; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(9; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(10; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
    }

    keys
    {
        key(Key1; "Document No.", "Document Line No.", Variable)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

