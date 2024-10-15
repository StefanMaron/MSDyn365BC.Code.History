table 11743 "Currency Nominal Value"
{
    Caption = 'Currency Nominal Value';
    LookupPageID = "Currency Nominal Values";

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

