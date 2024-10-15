table 10240 "B10 Adjustment"
{
    Caption = 'B10 Adjustment';

    fields
    {
        field(1; Date; Date)
        {
            Caption = 'Date';
            NotBlank = true;
        }
        field(2; "Adjustment Amount"; Decimal)
        {
            Caption = 'Adjustment Amount';
            DecimalPlaces = 2 : 5;
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

