table 17432 "Posted Payroll Doc. Line AE"
{
    Caption = 'Posted Payroll Doc. Line AE';

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Posted Payroll Document";
        }
        field(3; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(4; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = 'Ledger Entry,Payroll Document,Salary,External Income';
            OptionMembers = "Ledger Entry","Payroll Document",Salary,"External Income";
        }
        field(5; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(8; "Wage Period Code"; Code[10])
        {
            Caption = 'Wage Period Code';
            TableRelation = "Payroll Period";
        }
        field(9; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(10; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
        }
        field(11; "Element Type"; Option)
        {
            Caption = 'Element Type';
            Editable = false;
            OptionCaption = 'Wage,Bonus';
            OptionMembers = Wage,Bonus;
        }
        field(13; "Bonus Type"; Option)
        {
            Caption = 'Bonus Type';
            OptionCaption = ' ,Monthly,Quarterly,Semi-Annual,Annual';
            OptionMembers = " ",Monthly,Quarterly,"Semi-Annual",Annual;
        }
        field(20; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(21; "Inclusion Factor"; Decimal)
        {
            Caption = 'Inclusion Factor';
        }
        field(22; "Amount for AE"; Decimal)
        {
            Caption = 'Amount for AE';
        }
        field(23; "Indexed Amount for AE"; Decimal)
        {
            Caption = 'Indexed Amount for AE';
        }
        field(24; "Salary Indexation"; Boolean)
        {
            Caption = 'Salary Indexation';
        }
        field(25; "Depends on Salary Element"; Code[20])
        {
            Caption = 'Depends on Salary Element';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Wage));
        }
        field(26; "Amount for FSI"; Decimal)
        {
            Caption = 'Amount for FSI';
        }
    }

    keys
    {
        key(Key1; "Document No.", "Document Line No.", "Wage Period Code", "Source Type", "Entry No.")
        {
            Clustered = true;
            SumIndexFields = "Amount for AE", "Amount for FSI", "Indexed Amount for AE";
        }
    }

    fieldgroups
    {
    }
}

