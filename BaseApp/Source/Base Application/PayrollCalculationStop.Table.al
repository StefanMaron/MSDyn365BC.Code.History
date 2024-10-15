table 17423 "Payroll Calculation Stop"
{
    Caption = 'Payroll Calculation Stop';
    LookupPageID = "Payroll Expression Stops";

    fields
    {
        field(1; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
        }
        field(2; Variable; Text[30])
        {
            Caption = 'Variable';
        }
        field(3; Value; Decimal)
        {
            Caption = 'Value';
        }
        field(4; Comparison; Option)
        {
            Caption = 'Comparison';
            OptionCaption = ' ,=,<>,>,<,>=,<=';
            OptionMembers = " ","=","<>",">","<",">=","<=";
        }
        field(5; Global; Boolean)
        {
            Caption = 'Global';
        }
        field(6; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
    }

    keys
    {
        key(Key1; "Element Code", "Period Code", Variable)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

