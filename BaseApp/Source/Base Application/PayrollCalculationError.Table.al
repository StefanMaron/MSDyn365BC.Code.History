table 17420 "Payroll Calculation Error"
{
    Caption = 'Payroll Calculation Error';
    LookupPageID = "Payroll Expression Errors";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

