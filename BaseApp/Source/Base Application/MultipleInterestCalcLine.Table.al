table 11777 "Multiple Interest Calc. Line"
{
    Caption = 'Multiple Interest Calc. Line';
#if not CLEAN20
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
#endif
    ObsoleteReason = 'Replaced by Finance Charge Interest Rate';

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

