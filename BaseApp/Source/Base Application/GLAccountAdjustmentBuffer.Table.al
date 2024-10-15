table 11770 "G/L Account Adjustment Buffer"
{
    Caption = 'G/L Account Adjustment Buffer';
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(2; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(10; "Debit Amount"; Decimal)
        {
            Caption = 'Debit Amount';
            DataClassification = SystemMetadata;
        }
        field(11; "Credit Amount"; Decimal)
        {
            Caption = 'Credit Amount';
            DataClassification = SystemMetadata;
        }
        field(15; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(16; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Document No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

