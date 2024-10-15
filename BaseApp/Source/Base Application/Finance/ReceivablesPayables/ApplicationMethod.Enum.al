namespace Microsoft.Finance.ReceivablesPayables;

enum 1381 "Application Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Manual)
    {
        Caption = 'Manual';
    }
    value(1; "Apply to Oldest")
    {
        Caption = 'Apply to Oldest';
    }
}