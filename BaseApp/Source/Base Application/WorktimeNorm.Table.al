table 17394 "Worktime Norm"
{
    Caption = 'Worktime Norm';
    LookupPageID = "Worktime Norms";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(3; "Hours per Week"; Decimal)
        {
            Caption = 'Hours per Week';
        }
        field(4; "Hours per Year"; Decimal)
        {
            Caption = 'Hours per Year';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

