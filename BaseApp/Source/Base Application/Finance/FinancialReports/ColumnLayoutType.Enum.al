namespace Microsoft.Finance.FinancialReports;

enum 331 "Column Layout Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Formula")
    {
        Caption = 'Formula';
    }
    value(1; "Net Change")
    {
        Caption = 'Net Change';
    }
    value(2; "Balance at Date")
    {
        Caption = 'Balance at Date';
    }
    value(3; "Beginning Balance")
    {
        Caption = 'Beginning Balance';
    }
    value(4; "Year to Date")
    {
        Caption = 'Year to Date';
    }
    value(5; "Rest of Fiscal Year")
    {
        Caption = 'Rest of Fiscal Year';
    }
    value(6; "Entire Fiscal Year")
    {
        Caption = 'Entire Fiscal Year';
    }
#if not CLEAN23
    value(7; "Subsidiary")
    {
        Caption = 'Subsidiary';
        ObsoleteReason = 'Value Subsidiary is unused.';
        ObsoleteState = Pending;
        ObsoleteTag = '23.0';
    }
#endif
}