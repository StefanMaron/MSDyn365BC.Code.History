table 11501 "VAT Currency Adjustment Buffer"
{
    Caption = 'VAT Currency Adjustment Buffer';

    fields
    {
        field(1; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(2; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(3; "VAT Sales Base Amt."; Decimal)
        {
            Caption = 'VAT Sales Base Amt.';
        }
        field(4; "VAT Sales Base Amt. Adj."; Decimal)
        {
            Caption = 'VAT Sales Base Amt. Adj.';
        }
        field(5; "VAT Purch. Base Amt."; Decimal)
        {
            Caption = 'VAT Purch. Base Amt.';
        }
        field(6; "VAT Purch. Base Amt. Adj."; Decimal)
        {
            Caption = 'VAT Purch. Base Amt. Adj.';
        }
    }

    keys
    {
        key(Key1; "Gen. Bus. Posting Group", "Gen. Prod. Posting Group")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

