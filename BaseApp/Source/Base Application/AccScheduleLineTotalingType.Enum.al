enum 85 "Acc. Schedule Line Totaling Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Posting Accounts")
    {
        Caption = 'Posting Accounts';
    }
    value(1; "Total Accounts")
    {
        Caption = 'Total Accounts';
    }
    value(2; Formula)
    {
        Caption = 'Formula';
    }
    value(5; "Set Base For Percent")
    {
        Caption = 'Set Base For Percent';
    }
    value(6; "Cost Type")
    {
        Caption = 'Cost Type';
    }
    value(7; "Cost Type Total")
    {
        Caption = 'Cost Type Total';
    }
    value(8; "Cash Flow Entry Accounts")
    {
        Caption = 'Cash Flow Entry Accounts';
    }
    value(9; "Cash Flow Total Accounts")
    {
        Caption = 'Cash Flow Total Accounts';
    }
#if not CLEAN19
    value(14; Custom)
    {
        Caption = 'Custom (Obsolete)';
        ObsoleteState = Pending;
        ObsoleteReason = 'This value is discontinued and should no longer be used.';
        ObsoleteTag = '19.0';
    }
    value(15; Constant)
    {
        Caption = 'Constant (Obsolete)';
        ObsoleteState = Pending;
        ObsoleteReason = 'This value is discontinued and should no longer be used.';
        ObsoleteTag = '19.0';
    }
#endif
}