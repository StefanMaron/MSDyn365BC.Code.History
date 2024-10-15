table 28070 "Tax Posting Buffer"
{
    Caption = 'Tax Posting Buffer';

    fields
    {
        field(2; "Tax Invoice No."; Code[20])
        {
            Caption = 'Tax Invoice No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Invoice No."; Text[30])
        {
            Caption = 'Invoice No.';
            DataClassification = SystemMetadata;
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Purchase Invoice,Sales Invoice,Purchase Credit Memo,Sales Credit Memo';
            OptionMembers = "Purchase Invoice","Sales Invoice","Purchase Credit Memo","Sales Credit Memo";
        }
    }

    keys
    {
        key(Key1; "Tax Invoice No.", Type)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

