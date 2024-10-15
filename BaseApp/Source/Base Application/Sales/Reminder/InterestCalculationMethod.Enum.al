namespace Microsoft.Sales.FinanceCharge;

enum 5 "Interest Calculation Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Average Daily Balance") { Caption = 'Average Daily Balance'; }
    value(1; "Balance Due") { Caption = 'Balance Due'; }
}