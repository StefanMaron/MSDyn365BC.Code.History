table 5871 "Memoized Result"
{
    Caption = 'Memoized Result';

    fields
    {
        field(1; Input; Decimal)
        {
            Caption = 'Input';
        }
        field(2; Output; Boolean)
        {
            Caption = 'Output';
        }
    }

    keys
    {
        key(Key1; Input)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

