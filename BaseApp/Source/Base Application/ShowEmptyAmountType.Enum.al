namespace Microsoft.Finance.FinancialReports;

enum 25 "Show Empty Amount Type"
{
    Extensible = true;

    value(0; Blank)
    {
        Caption = 'Blank';
    }
    value(1; Zero)
    {
        Caption = 'Zero';
    }
    value(2; Dash)
    {
        Caption = 'Dash';
    }
}