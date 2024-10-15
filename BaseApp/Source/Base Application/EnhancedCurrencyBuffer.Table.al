table 11774 "Enhanced Currency Buffer"
{
    Caption = 'Enhanced Currency Buffer';
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(2; "Total Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Amount';
            DataClassification = SystemMetadata;
        }
        field(3; "Total Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(4; Counter; Integer)
        {
            Caption = 'Counter';
            DataClassification = SystemMetadata;
        }
        field(5; "Total Credit Amount"; Decimal)
        {
            Caption = 'Total Credit Amount';
            DataClassification = SystemMetadata;
        }
        field(6; "Total Debit Amount"; Decimal)
        {
            Caption = 'Total Debit Amount';
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

