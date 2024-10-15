table 14968 "Payroll Analysis Cell Value"
{
    Caption = 'Payroll Analysis Cell Value';

    fields
    {
        field(2; "Row No."; Integer)
        {
            Caption = 'Row No.';
        }
        field(3; "Column No."; Integer)
        {
            Caption = 'Column No.';
        }
        field(4; Value; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Value';
        }
        field(5; Error; Boolean)
        {
            Caption = 'Error';
        }
        field(6; "Period Error"; Boolean)
        {
            Caption = 'Period Error';
        }
        field(7; "Formula Error"; Boolean)
        {
            Caption = 'Formula Error';
        }
        field(8; "Cyclic Error"; Boolean)
        {
            Caption = 'Cyclic Error';
        }
    }

    keys
    {
        key(Key1; "Row No.", "Column No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

