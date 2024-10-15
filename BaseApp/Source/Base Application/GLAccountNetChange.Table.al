table 269 "G/L Account Net Change"
{
#if CLEAN18
    Tabletype = temporary;
#else
    ObsoleteState = Pending;
    ObsoleteTag = '18.0';
    ObsoleteReason = 'This table will be marked as temporary. Please ensure you do not store any data in the table.';
#endif
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
#if CLEAN18
            ObsoleteState = Removed; 
#else 
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'The functionality of GL Journal reconciliation by type will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';
        }
    }

    keys
    {
#if CLEAN18
        key(Key1; "No.")
#else 
        key(Key1; "No.", Type)
#endif         
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

