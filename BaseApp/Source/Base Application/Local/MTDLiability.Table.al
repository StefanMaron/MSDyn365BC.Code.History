table 10533 "MTD-Liability"
{
    Caption = 'VAT Liability';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Pending;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "From Date"; Date)
        {
            Caption = 'From Date';
        }
        field(2; "To Date"; Date)
        {
            Caption = 'To Date';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ',VAT Return Debit Charge';
            OptionMembers = ,"VAT Return Debit Charge";
        }
        field(4; "Original Amount"; Decimal)
        {
            Caption = 'Original Amount';
        }
        field(5; "Outstanding Amount"; Decimal)
        {
            Caption = 'Outstanding Amount';
        }
        field(6; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
    }

    keys
    {
        key(Key1; "From Date", "To Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

