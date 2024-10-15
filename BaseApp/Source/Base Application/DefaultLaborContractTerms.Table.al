table 17364 "Default Labor Contract Terms"
{
    Caption = 'Default Labor Contract Terms';

    fields
    {
        field(1; "Category Code"; Code[10])
        {
            Caption = 'Category Code';
            TableRelation = "Employee Category";
        }
        field(2; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            TableRelation = "Organizational Unit";
        }
        field(3; "Job Title Code"; Code[10])
        {
            Caption = 'Job Title Code';
            TableRelation = "Job Title";
        }
        field(6; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
        }
        field(7; "Operation Type"; Option)
        {
            Caption = 'Operation Type';
            OptionCaption = 'All,Hire,Transfer,Combination,Dismissal';
            OptionMembers = All,Hire,Transfer,Combination,Dismissal;
        }
        field(8; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Payroll Element,Vacation Accrual';
            OptionMembers = "Payroll Element","Vacation Accrual";
        }
        field(9; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(10; "Org. Unit Hierarchy"; Boolean)
        {
            Caption = 'Org. Unit Hierarchy';

            trigger OnValidate()
            begin
                TestField("Org. Unit Code");
            end;
        }
        field(11; "Job Title Hierarchy"; Boolean)
        {
            Caption = 'Job Title Hierarchy';

            trigger OnValidate()
            begin
                TestField("Job Title Code");
            end;
        }
        field(12; "Additional Salary"; Boolean)
        {
            Caption = 'Additional Salary';
        }
        field(15; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(16; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(17; Percent; Decimal)
        {
            Caption = 'Percent';
        }
        field(18; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
    }

    keys
    {
        key(Key1; "Category Code", "Org. Unit Code", "Job Title Code", "Element Code", "Operation Type", "Start Date", "End Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

