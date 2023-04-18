table 266 "Customer Amount"
{
    Caption = 'Customer Amount';

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(2; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(3; "Amount 2 (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount 2 (LCY)';
        }
    }

    keys
    {
        key(Key1; "Amount (LCY)", "Amount 2 (LCY)", "Customer No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

