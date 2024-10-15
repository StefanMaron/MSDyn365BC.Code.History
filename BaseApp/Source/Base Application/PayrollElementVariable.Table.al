table 17421 "Payroll Element Variable"
{
    Caption = 'Payroll Element Variable';
    LookupPageID = "Payroll Element Variables";

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
        field(3; "Period Code"; Code[10])
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

