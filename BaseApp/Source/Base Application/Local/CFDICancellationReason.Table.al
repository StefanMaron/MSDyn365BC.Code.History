table 27003 "CFDI Cancellation Reason"
{
    DrillDownPageID = "CFDI Cancellation Reasons";
    LookupPageID = "CFDI Cancellation Reasons";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Substitution Number Required"; Boolean)
        {
            Caption = 'Substitution Number Required';
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

