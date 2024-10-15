namespace Microsoft.Finance.FinancialReports;

enum 5000 "Financial Report View Layout"
{
    Extensible = true;

    value(0; "Show None")
    {
        Caption = 'Show None';
    }
    value(1; "Show Filters Only")
    {
        Caption = 'Show Filters Only';
    }
    value(2; "Show All")
    {
        Caption = 'Show All';
    }
}