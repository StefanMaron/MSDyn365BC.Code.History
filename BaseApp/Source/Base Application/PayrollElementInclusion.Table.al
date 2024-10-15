table 17447 "Payroll Element Inclusion"
{
    Caption = 'Payroll Element Inclusion';

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Vacation,Sick Leave,Travel,Other';
            OptionMembers = Vacation,"Sick Leave",Travel,Other;
        }
        field(2; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(3; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
        }
    }

    keys
    {
        key(Key1; Type, "Period Code", "Element Code")
        {
            Clustered = true;
        }
        key(Key2; "Element Code")
        {
        }
    }

    fieldgroups
    {
    }
}

