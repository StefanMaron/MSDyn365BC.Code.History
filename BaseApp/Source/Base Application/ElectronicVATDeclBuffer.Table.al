table 11028 "Electronic VAT Decl. Buffer"
{
    ObsoleteReason = 'Moved to Elster extension';
    ObsoleteState = Pending;
    ObsoleteTag = '18.10';

    fields
    {
        field(1; "Code"; Code[20])
        {
        }
        field(2; Amount; Decimal)
        {
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

