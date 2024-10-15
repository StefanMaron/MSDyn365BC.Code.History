table 17397 "Payroll Limit"
{
    Caption = 'Payroll Limit';

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'MROT,FSI Limit';
            OptionMembers = MROT,"FSI Limit";
        }
        field(2; "Payroll Period"; Code[10])
        {
            Caption = 'Payroll Period';
            TableRelation = "Payroll Period";
        }
        field(3; Amount; Decimal)
        {
            Caption = 'Amount';
        }
    }

    keys
    {
        key(Key1; Type, "Payroll Period")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

