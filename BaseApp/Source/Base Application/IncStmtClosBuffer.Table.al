table 10700 "Inc. Stmt. Clos. Buffer"
{
    Caption = 'Inc. Stmt. Clos. Buffer';

    fields
    {
        field(1; "Account No."; Text[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
        }
        field(2; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(3; "Additional-Currency Amount"; Decimal)
        {
            Caption = 'Additional-Currency Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Account No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

