table 17456 "Posted Payroll Period AE"
{
    Caption = 'Posted Payroll Period AE';

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(5; "Period No."; Integer)
        {
            Caption = 'Period No.';
        }
        field(6; "Period End Date"; Date)
        {
            Caption = 'Period End Date';
        }
        field(7; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
        }
        field(8; Month; Integer)
        {
            Caption = 'Month';
        }
        field(9; Year; Integer)
        {
            Caption = 'Year';
        }
        field(10; "Salary Amount"; Decimal)
        {
            Caption = 'Salary Amount';
        }
        field(11; "Bonus Amount"; Decimal)
        {
            Caption = 'Bonus Amount';
        }
        field(12; "Planned Calendar Days"; Decimal)
        {
            Caption = 'Planned Calendar Days';
        }
        field(13; "Actual Calendar Days"; Decimal)
        {
            Caption = 'Actual Calendar Days';
        }
        field(14; "Planned Work Days"; Decimal)
        {
            Caption = 'Planned Work Days';
        }
        field(15; "Actual Work Days"; Decimal)
        {
            Caption = 'Actual Work Days';
        }
        field(16; "Average Days"; Decimal)
        {
            Caption = 'Average Days';
        }
        field(17; "Absence Days"; Decimal)
        {
            Caption = 'Absence Days';
        }
        field(18; "Base Salary"; Decimal)
        {
            Caption = 'Base Salary';
        }
        field(19; "Extra Salary"; Decimal)
        {
            Caption = 'Extra Salary';
        }
        field(20; "Indexation Factor"; Decimal)
        {
            Caption = 'Indexation Factor';
        }
        field(21; "Amount for FSI"; Decimal)
        {
            Caption = 'Amount for FSI';
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.", "Period No.")
        {
            Clustered = true;
            SumIndexFields = "Salary Amount", "Average Days";
        }
    }

    fieldgroups
    {
    }
}

