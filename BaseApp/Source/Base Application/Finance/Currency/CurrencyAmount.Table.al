namespace Microsoft.Finance.Currency;

table 264 "Currency Amount"
{
    Caption = 'Currency Amount';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(2; Date; Date)
        {
            Caption = 'Date';
        }
        field(3; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
    }

    keys
    {
        key(Key1; "Currency Code", Date)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

