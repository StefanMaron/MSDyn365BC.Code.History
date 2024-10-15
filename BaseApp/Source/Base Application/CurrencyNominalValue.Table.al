table 11743 "Currency Nominal Value"
{
    Caption = 'Currency Nominal Value';
#if CLEAN17
    ObsoleteState = Removed;
#else
    LookupPageID = "Currency Nominal Values";
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(2; Value; Decimal)
        {
            BlankZero = true;
            Caption = 'Value';
            DecimalPlaces = 0 : 2;
            NotBlank = true;
        }
    }

    keys
    {
        key(Key1; "Currency Code", Value)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

