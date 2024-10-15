namespace Microsoft.Finance.GeneralLedger.Journal;

table 269 "G/L Account Net Change"
{
    Tabletype = temporary;
    Caption = 'G/L Account Net Change';
    ReplicateData = false;

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
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of GL Journal reconciliation by type has been removed.';
            ObsoleteTag = '21.0';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

