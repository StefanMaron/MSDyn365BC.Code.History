table 17411 "Payroll Range Line"
{
    Caption = 'Payroll Range Line';

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(2; "Range Code"; Text[20])
        {
            Caption = 'Range Code';
            Editable = false;
            TableRelation = "Payroll Range Header".Code WHERE("Element Code" = FIELD("Element Code"));
        }
        field(3; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            Editable = false;
            TableRelation = "Payroll Element";
        }
        field(4; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            Editable = false;
            TableRelation = "Payroll Period";
        }
        field(6; "Range Type"; Option)
        {
            Caption = 'Range Type';
            Editable = true;
            OptionCaption = ' ,Deduction,Tax Deduction,Exclusion,Deduct. Benefit,Tax Abatement,Limit + Tax %,Frequency,Coordination,Increase Salary,Quantity';
            OptionMembers = " ",Deduction,"Tax Deduction",Exclusion,"Deduct. Benefit","Tax Abatement","Limit + Tax %",Frequency,Coordination,"Increase Salary",Quantity;
        }
        field(10; "Over Amount"; Decimal)
        {
            Caption = 'Over Amount';
        }
        field(11; Limit; Decimal)
        {
            Caption = 'Limit';
        }
        field(12; "Tax %"; Decimal)
        {
            Caption = 'Tax %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(13; Percent; Decimal)
        {
            Caption = 'Percent';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(14; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 7;
        }
        field(15; "Tax Amount"; Decimal)
        {
            Caption = 'Tax Amount';
        }
        field(16; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(17; "Increase Wage"; Decimal)
        {
            Caption = 'Increase Wage';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Max Deduction"; Decimal)
        {
            Caption = 'Max Deduction';
        }
        field(19; "Min Amount"; Decimal)
        {
            Caption = 'Min Amount';
        }
        field(20; "Max Amount"; Decimal)
        {
            Caption = 'Max Amount';
        }
        field(21; "On Allowance"; Boolean)
        {
            Caption = 'On Allowance';
        }
        field(22; "From Allowance"; Integer)
        {
            Caption = 'From Allowance';
            MinValue = 0;
        }
        field(23; "Coordination %"; Decimal)
        {
            Caption = 'Coordination %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(24; "Max %"; Decimal)
        {
            Caption = 'Max %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(25; "Directory Code"; Code[10])
        {
            Caption = 'Directory Code';
            TableRelation = IF ("Range Type" = CONST("Tax Deduction")) "Payroll Directory".Code WHERE(Type = CONST("Tax Deduction"));
        }
        field(27; "Employee Gender"; Option)
        {
            Caption = 'Employee Gender';
            OptionCaption = ' ,Female,Male';
            OptionMembers = " ",Female,Male;
        }
        field(28; "From Birthday and Younger"; Date)
        {
            Caption = 'From Birthday and Younger';
        }
        field(29; Age; Decimal)
        {
            Caption = 'Age';
            MinValue = 0;
        }
        field(30; "Disabled Person"; Boolean)
        {
            Caption = 'Disabled Person';
        }
        field(31; Student; Boolean)
        {
            Caption = 'Student';
        }
    }

    keys
    {
        key(Key1; "Element Code", "Range Code", "Period Code", "Line No.")
        {
        }
        key(Key2; "Element Code", "Range Code", "Period Code", "Employee Gender", "From Birthday and Younger", "Line No.")
        {
            Clustered = true;
        }
        key(Key3; "Element Code", "Range Code", "Period Code", "Over Amount")
        {
        }
        key(Key4; "Element Code", "Range Code", "Period Code", "Disabled Person", Student, Age, "Over Amount")
        {
        }
    }

    fieldgroups
    {
    }
}

