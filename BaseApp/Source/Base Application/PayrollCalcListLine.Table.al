table 17452 "Payroll Calc List Line"
{
    Caption = 'Payroll Calc List Line';

    fields
    {
        field(1; "No."; Code[30])
        {
            Caption = 'No.';
        }
        field(2; "Last Name & Initials"; Text[90])
        {
            Caption = 'Last Name & Initials';
        }
        field(3; "Appointment Name"; Text[250])
        {
            Caption = 'Appointment Name';
        }
        field(4; Days; Decimal)
        {
            Caption = 'Days';
        }
        field(5; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            TableRelation = "Organizational Unit";
        }
        field(6; Hours; Decimal)
        {
            Caption = 'Hours';
        }
        field(7; "Hours Tariff"; Decimal)
        {
            Caption = 'Hours Tariff';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Last Name & Initials")
        {
        }
    }

    fieldgroups
    {
    }
}

