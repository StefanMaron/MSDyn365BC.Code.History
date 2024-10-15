table 11028 "Electronic VAT Decl. Buffer"
{
    ObsoleteReason = 'Moved to Elster extension';
#if not CLEAN21
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#endif
    ReplicateData = false;

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

