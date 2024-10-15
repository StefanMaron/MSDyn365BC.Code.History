table 31060 "VIES Transaction Buffer"
{
    Caption = 'VIES Transaction Buffer';

    fields
    {
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = SystemMetadata;
        }
        field(5; "EU Service"; Boolean)
        {
            Caption = 'EU Service';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Transaction No.", "EU Service")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

