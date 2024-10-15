table 17450 "Payroll Calc List Column"
{
    Caption = 'Payroll Calc List Column';

    fields
    {
        field(1; "No."; Code[30])
        {
            Caption = 'No.';
        }
        field(6; "Element Code"; Code[20])
        {
            Caption = 'Element Code';

            trigger OnValidate()
            begin
                if "Element Code" <> '' then begin
                    PayrollElement.Get("Element Code");
                    "Element Group" := PayrollElement."Element Group";
                end else
                    "Element Group" := '';
            end;
        }
        field(7; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(8; "Print Priority"; Integer)
        {
            Caption = 'Print Priority';
        }
        field(9; "Element Group"; Code[20])
        {
            Caption = 'Element Group';
        }
        field(10; Days; Decimal)
        {
            Caption = 'Days';
        }
        field(11; Hours; Decimal)
        {
            Caption = 'Hours';
        }
        field(20; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
    }

    keys
    {
        key(Key1; "No.", "Print Priority", "Element Code", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount, Days, Hours;
        }
        key(Key2; "Element Code", "No.")
        {
        }
        key(Key3; "Print Priority", "Element Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
        PayrollElement: Record "Payroll Element";
}

