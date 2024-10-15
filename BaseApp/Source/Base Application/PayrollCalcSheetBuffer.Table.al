table 17455 "Payroll Calc Sheet Buffer"
{
    Caption = 'Payroll Calc Sheet Buffer';

    fields
    {
        field(1; "Element Type"; Option)
        {
            Caption = 'Element Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Wage,Bonus,Income Tax,Netto Salary,Tax Deduction,Deduction,Other,Funds,Reporting';
            OptionMembers = Wage,Bonus,"Income Tax","Netto Salary","Tax Deduction",Deduction,Other,Funds,Reporting;
        }
        field(2; "Element Group"; Code[20])
        {
            Caption = 'Element Group';
            DataClassification = SystemMetadata;
            TableRelation = "Payroll Element Group";
        }
        field(3; "Posting Type"; Option)
        {
            Caption = 'Posting Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Not Post,Charge,Liability,Liability Charge';
            OptionMembers = "Not Post",Charge,Liability,"Liability Charge";
        }
        field(5; "Check Stub Section"; Option)
        {
            Caption = 'Check Stub Section';
            DataClassification = SystemMetadata;
            OptionCaption = ',Salary,Net Salary,Other Info,Net Distrib. Salary,Tax Info,Wage Info';
            OptionMembers = ,Salary,"Net Salary","Other Info","Net Distrib. Salary","Tax Info","Wage Info";
        }
        field(6; "Check Stub Sequence"; Integer)
        {
            Caption = 'Check Stub Sequence';
            DataClassification = SystemMetadata;
        }
        field(9; "What Print"; Option)
        {
            Caption = 'What Print';
            DataClassification = SystemMetadata;
            OptionCaption = 'Not Print,Current Value,From Begin Year,Balance,Current+From Begin Year,Current+Balance';
            OptionMembers = "Not Print","Current Value","From Begin Year",Balance,"Current+From Begin Year","Current+Balance";
        }
        field(11; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(12; "Amount From Begin Date"; Decimal)
        {
            Caption = 'Amount From Begin Date';
            DataClassification = SystemMetadata;
        }
        field(13; Balance; Decimal)
        {
            Caption = 'Balance';
            DataClassification = SystemMetadata;
        }
        field(14; Hours; Decimal)
        {
            Caption = 'Hours';
            DataClassification = SystemMetadata;
        }
        field(15; "Declaration Status"; Text[30])
        {
            Caption = 'Declaration Status';
            DataClassification = SystemMetadata;
        }
        field(16; "Tax Allowance"; Integer)
        {
            Caption = 'Tax Allowance';
            DataClassification = SystemMetadata;
        }
        field(17; "Additional Deduction"; Decimal)
        {
            Caption = 'Additional Deduction';
            DataClassification = SystemMetadata;
        }
        field(18; "Other Allowance"; Integer)
        {
            Caption = 'Other Allowance';
            DataClassification = SystemMetadata;
        }
        field(19; "Not Income Tax"; Boolean)
        {
            Caption = 'Not Income Tax';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Check Stub Section", "Check Stub Sequence")
        {
            Clustered = true;
        }
        key(Key2; "Element Type", "Element Group")
        {
        }
    }

    fieldgroups
    {
    }
}

