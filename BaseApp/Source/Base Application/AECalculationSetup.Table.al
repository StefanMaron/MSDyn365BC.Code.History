table 17458 "AE Calculation Setup"
{
    Caption = 'AE Calculation Setup';
    LookupPageID = "AE Calculation Setup";

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Calculation,Bonus Setup';
            OptionMembers = Calculation,"Bonus Setup";
        }
        field(2; "AE Calc Type"; Option)
        {
            Caption = 'AE Calc Type';
            OptionCaption = 'Vacation,Sick Leave,Child Care 1,Child Care 2,Others,Pregnancy Leave';
            OptionMembers = Vacation,"Sick Leave","Child Care 1","Child Care 2",Others,"Pregnancy Leave";
        }
        field(3; "Bonus Type"; Option)
        {
            Caption = 'Bonus Type';
            OptionCaption = ' ,Monthly,Quarterly,Semi-Annual,Annual';
            OptionMembers = " ",Monthly,Quarterly,"Semi-Annual",Annual;
        }
        field(4; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(5; "AE Calc Months"; Decimal)
        {
            Caption = 'AE Calc Months';
        }
        field(6; "AE Bonus Calc Type"; Option)
        {
            Caption = 'AE Bonus Calc Type';
            OptionCaption = ' ,YTD,Period,Period and After';
            OptionMembers = " ",YTD,Period,"Period and After";
        }
        field(7; "AE Bonus Calc Method"; Option)
        {
            Caption = 'AE Bonus Calc Method';
            OptionCaption = ' ,Full,Average,Minimum,Maximum,Last,Match by Period';
            OptionMembers = " ",Full,"Average",Minimum,Maximum,Last,"Match by Period";
        }
        field(8; "Time Bonus Calc Method"; Option)
        {
            Caption = 'Time Bonus Calc Method';
            OptionCaption = ' ,Full,Proportional';
            OptionMembers = " ",Full,Proportional;
        }
        field(9; "Average Month Days"; Decimal)
        {
            Caption = 'Average Month Days';
        }
        field(10; "Month Days Calc Method"; Option)
        {
            Caption = 'Month Days Calc Method';
            OptionCaption = 'Average,Calendar';
            OptionMembers = "Average",Calendar;
        }
        field(11; "Days for Calc Type"; Option)
        {
            Caption = 'Days for Calc Type';
            OptionCaption = ' ,Working Days,Calendar Days,Whole Year';
            OptionMembers = " ","Working Days","Calendar Days","Whole Year";
        }
        field(12; "Recalc for Bonus Amount"; Boolean)
        {
            Caption = 'Recalc for Bonus Amount';
        }
        field(13; "Use FSI Limits"; Boolean)
        {
            Caption = 'Use FSI Limits';
        }
        field(14; "Setup Code"; Code[10])
        {
            Caption = 'Setup Code';
        }
        field(15; "Exclude Current Period"; Boolean)
        {
            Caption = 'Exclude Current Period';
        }
        field(17; "Use Excluded Days"; Boolean)
        {
            Caption = 'Use Excluded Days';
        }
    }

    keys
    {
        key(Key1; Type, "AE Calc Type", "Bonus Type", "Period Code", "Setup Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

