table 12101 "Interest on Arrears"
{
    Caption = 'Interest on Arrears';
    LookupPageID = "Interest on Arrears";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            Editable = false;
        }
        field(2; "Interest Rate"; Decimal)
        {
            Caption = 'Interest Rate';
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(4; Description; Text[50])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code", "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

