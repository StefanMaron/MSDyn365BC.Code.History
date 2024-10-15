table 14932 "Excel Template Sheet Buffer"
{
    Caption = 'Excel Template Sheet Buffer';

    fields
    {
        field(1; "Sheet Name"; Text[31])
        {
            Caption = 'Sheet Name';
            DataClassification = SystemMetadata;
        }
        field(2; "Paper Height"; Decimal)
        {
            Caption = 'Paper Height';
            DataClassification = SystemMetadata;
        }
        field(4; "Current Paper Height"; Decimal)
        {
            Caption = 'Current Paper Height';
            DataClassification = SystemMetadata;
        }
        field(5; "Last Page No."; Integer)
        {
            Caption = 'Last Page No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Sheet Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

