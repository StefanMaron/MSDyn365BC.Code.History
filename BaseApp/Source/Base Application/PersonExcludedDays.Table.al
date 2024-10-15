table 17399 "Person Excluded Days"
{
    Caption = 'Person Excluded Days';
    DrillDownPageID = "Person Excluded Days";
    LookupPageID = "Person Excluded Days";

    fields
    {
        field(1; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            TableRelation = Person;
        }
        field(2; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(6; "Absence Starting Date"; Date)
        {
            Caption = 'Absence Starting Date';
        }
        field(7; "Absence Ending Date"; Date)
        {
            Caption = 'Absence Ending Date';
        }
        field(8; "Calendar Days"; Decimal)
        {
            Caption = 'Calendar Days';
        }
        field(9; Description; Text[50])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Person No.", "Period Code", "Document No.", "Absence Starting Date")
        {
            Clustered = true;
            SumIndexFields = "Calendar Days";
        }
    }

    fieldgroups
    {
    }
}

