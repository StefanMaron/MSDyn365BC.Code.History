table 31036 "Advance Link Buffer - Entry"
{
    Caption = 'Advance Link Buffer - Entry';
#if not CLEAN19
    ObsoleteState = Pending;
#else
    ObsoleteState = Removed;
#endif
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    fields
    {
        field(1; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        field(2; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        field(3; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(10; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(11; "Advance Letter No."; Code[20])
        {
            Caption = 'Advance Letter No.';
            DataClassification = SystemMetadata;
        }
        field(12; "Advance Letter Line No."; Integer)
        {
            Caption = 'Advance Letter Line No.';
            DataClassification = SystemMetadata;
        }
        field(13; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT %", "Advance Letter No.", "Advance Letter Line No.", "Document Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Advance Letter No.")
        {
        }
    }

    fieldgroups
    {
    }
}

