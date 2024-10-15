table 331 "Adjust Exchange Rate Buffer"
{
    Caption = 'Adjust Exchange Rate Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(2; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            DataClassification = SystemMetadata;
        }
        field(3; AdjBase; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'AdjBase';
            DataClassification = SystemMetadata;
        }
        field(4; AdjBaseLCY; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'AdjBaseLCY';
            DataClassification = SystemMetadata;
        }
        field(5; AdjAmount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'AdjAmount';
            DataClassification = SystemMetadata;
        }
        field(6; TotalGainsAmount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'TotalGainsAmount';
            DataClassification = SystemMetadata;
        }
        field(7; TotalLossesAmount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'TotalLossesAmount';
            DataClassification = SystemMetadata;
        }
        field(8; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = SystemMetadata;
        }
        field(9; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(10; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = SystemMetadata;
        }
        field(11; Index; Integer)
        {
            Caption = 'Index';
            DataClassification = SystemMetadata;
        }
        field(11760; "Initial G/L Account No."; Code[20])
        {
            Caption = 'Initial G/L Account No.';
            DataClassification = SystemMetadata;
        }
        field(11761; "Document Type"; Option)
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund,Advance';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund,Advance;
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(11762; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(11763; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Field Entry No. will be removed and this field should not be used.';
            ObsoleteTag = '18.0';
        }
        field(31000; Advance; Boolean)
        {
            Caption = 'Advance';
            DataClassification = SystemMetadata;
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '19.0';
        }
    }

    keys
    {
        key(Key1; "Currency Code", "Posting Group", "Dimension Entry No.", "Posting Date", "IC Partner Code", Advance, "Initial G/L Account No.")
        {
            Clustered = true;
            ObsoleteState = Pending;
            ObsoleteReason = 'Field "Advance" is removed and cannot be used in an active key.';
            ObsoleteTag = '19.0';
        }
    }

    fieldgroups
    {
    }
}

