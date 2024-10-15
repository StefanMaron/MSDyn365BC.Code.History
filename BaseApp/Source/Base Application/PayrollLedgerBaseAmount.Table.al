table 17439 "Payroll Ledger Base Amount"
{
    Caption = 'Payroll Ledger Base Amount';
    LookupPageID = "Payroll Base Amount Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            TableRelation = "Payroll Ledger Entry";
        }
        field(3; "Base Type"; Option)
        {
            Caption = 'Base Type';
            OptionCaption = 'Income Tax,FSI,FSI Injury,Federal FMI,Territorial FMI,PF Accum. Part,PF Insur. Part';
            OptionMembers = "Income Tax",FSI,"FSI Injury","Federal FMI","Territorial FMI","PF Accum. Part","PF Insur. Part";
        }
        field(4; "Detailed Base Type"; Option)
        {
            Caption = 'Detailed Base Type';
            OptionCaption = ' ,Salary,Bonus,Quarter Bonus,Year Bonus';
            OptionMembers = " ",Salary,Bonus,"Quarter Bonus","Year Bonus";
        }
        field(6; "Element Type"; Option)
        {
            Caption = 'Element Type';
            OptionCaption = 'Wage,Bonus,Income Tax,Netto Salary,Tax Deduction,Deduction,Other,Funds,Reporting';
            OptionMembers = Wage,Bonus,"Income Tax","Netto Salary","Tax Deduction",Deduction,Other,Funds,Reporting;
        }
        field(7; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
        }
        field(10; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(11; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(12; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(13; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(15; "Payroll Directory Code"; Code[10])
        {
            Caption = 'Payroll Directory Code';
            TableRelation = "Payroll Directory".Code;
        }
    }

    keys
    {
        key(Key1; "Entry No.", "Base Type", "Detailed Base Type")
        {
            Clustered = true;
        }
        key(Key2; "Employee No.", "Base Type", "Detailed Base Type", "Element Type", "Element Code", "Payroll Directory Code", "Period Code", "Posting Date")
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
    }
}

