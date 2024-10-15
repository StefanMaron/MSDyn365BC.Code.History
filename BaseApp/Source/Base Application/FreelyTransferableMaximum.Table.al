table 11405 "Freely Transferable Maximum"
{
    Caption = 'Freely Transferable Maximum';
    DataCaptionFields = "Country/Region Code", "Currency Code";
    DrillDownPageID = "Freely Transferable Maximums";
    LookupPageID = "Freely Transferable Maximums";

    fields
    {
        field(1; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(9; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(10; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
    }

    keys
    {
        key(Key1; "Country/Region Code", "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

