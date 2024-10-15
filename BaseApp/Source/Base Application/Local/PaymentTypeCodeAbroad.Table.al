table 15000027 "Payment Type Code Abroad"
{
    Caption = 'Payment Type Code Abroad';
    DrillDownPageID = "Payment Type Codes Abroad";
    LookupPageID = "Payment Type Codes Abroad";

    fields
    {
        field(1; "Code"; Code[2])
        {
            Caption = 'Code';
            Numeric = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
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

