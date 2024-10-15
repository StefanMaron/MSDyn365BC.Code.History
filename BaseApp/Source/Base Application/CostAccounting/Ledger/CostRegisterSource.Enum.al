namespace Microsoft.CostAccounting.Ledger;

enum 1107 "Cost Register Source"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Transfer from G/L")
    {
        Caption = 'Transfer from G/L';
    }
    value(1; "Cost Journal")
    {
        Caption = 'Cost Journal';
    }
    value(2; Allocation)
    {
        Caption = 'Allocation';
    }
    value(3; "Transfer from Budget")
    {
        Caption = 'Transfer from Budget';
    }
}