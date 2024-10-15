table 11000009 "Payment History Export Buffer"
{
    Caption = 'Payment History Export Buffer';

    fields
    {
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
        }
        field(2; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(3; "No. of Net Change"; Integer)
        {
            Caption = 'No. of Net Change';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

