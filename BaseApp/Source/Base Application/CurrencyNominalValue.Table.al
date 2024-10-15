table 11743 "Currency Nominal Value"
{
    Caption = 'Currency Nominal Value';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '20.0';
    DataClassification = CustomerContent;

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
