table 17451 "Payroll Calc List Header"
{
    Caption = 'Payroll Calc List Header';

    fields
    {
        field(1; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
        }
        field(2; "Element Description"; Text[60])
        {
            Caption = 'Element Description';
        }
        field(3; "Print Priority"; Integer)
        {
            Caption = 'Print Priority';
        }
        field(4; "Column No."; Integer)
        {
            Caption = 'Column No.';
        }
    }

    keys
    {
        key(Key1; "Element Code")
        {
            Clustered = true;
        }
        key(Key2; "Print Priority")
        {
        }
    }

    fieldgroups
    {
    }
}

