table 13401 "Depr. Diff. Posting Buffer"
{
    Caption = 'Depr. Diff. Posting Buffer';

    fields
    {
        field(1; "Depr. Difference Acc."; Code[20])
        {
            Caption = 'Depr. Difference Acc.';
        }
        field(2; "Depr. Difference Bal. Acc."; Code[20])
        {
            Caption = 'Depr. Difference Bal. Acc.';
        }
        field(3; "Depreciation Amount 1"; Decimal)
        {
            Caption = 'Depreciation Amount 1';
        }
        field(4; "Depreciation Amount 2"; Decimal)
        {
            Caption = 'Depreciation Amount 2';
        }
        field(5; "FA No."; Code[20])
        {
            Caption = 'FA No.';
        }
    }

    keys
    {
        key(Key1; "Depr. Difference Acc.", "Depr. Difference Bal. Acc.", "FA No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

