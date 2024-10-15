table 10703 "Acc. Schedule Buffer"
{
    Caption = 'Acc. Schedule Buffer';

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Balance (Curr. Year)"; Decimal)
        {
            Caption = 'Balance (Curr. Year)';
            DataClassification = SystemMetadata;
        }
        field(3; "Balance (Prev. Year)"; Decimal)
        {
            Caption = 'Balance (Prev. Year)';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

