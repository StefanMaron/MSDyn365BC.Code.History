table 11777 "Multiple Interest Calc. Line"
{
    Caption = 'Multiple Interest Calc. Line';

    fields
    {
        field(1; Date; Date)
        {
            Caption = 'Date';
        }
        field(2; "Interest Rate"; Decimal)
        {
            Caption = 'Interest Rate';
        }
        field(3; Days; Integer)
        {
            Caption = 'Days';
        }
        field(4; "Rate Factor"; Decimal)
        {
            Caption = 'Rate Factor';
        }
    }

    keys
    {
        key(Key1; Date)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

