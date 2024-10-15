table 269 "G/L Account Net Change"
{
    Caption = 'G/L Account Net Change';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; "Net Change in Jnl."; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Net Change in Jnl.';
        }
        field(4; "Balance after Posting"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Balance after Posting';
        }
        field(11760; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Fixed Asset,IC Partner,Employee';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner",Employee;
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of GL Journal reconciliation by type will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
        }
    }

    keys
    {
        key(Key1; "No.", Type)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

