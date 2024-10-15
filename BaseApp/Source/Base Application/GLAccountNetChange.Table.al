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

