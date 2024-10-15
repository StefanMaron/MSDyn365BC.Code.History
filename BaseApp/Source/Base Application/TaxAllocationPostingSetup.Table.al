table 14955 "Tax Allocation Posting Setup"
{
    Caption = 'Tax Allocation Posting Setup';

    fields
    {
        field(1; "Main Posting Group"; Code[20])
        {
            Caption = 'Main Posting Group';
            TableRelation = "Payroll Posting Group";
        }
        field(2; "Payroll Element Code"; Code[20])
        {
            Caption = 'Payroll Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Funds));
        }
        field(3; "Tax Allocated Posting Group"; Code[20])
        {
            Caption = 'Tax Allocated Posting Group';
            TableRelation = "Payroll Posting Group";
        }
    }

    keys
    {
        key(Key1; "Main Posting Group", "Payroll Element Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

