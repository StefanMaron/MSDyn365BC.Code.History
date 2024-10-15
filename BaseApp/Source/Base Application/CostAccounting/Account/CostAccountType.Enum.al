namespace Microsoft.CostAccounting.Account;

enum 1103 "Cost Account Type"
{
    AssignmentCompatibility = true;
    Extensible = false;

    value(0; "Cost Type")
    {
        Caption = 'Cost Type';
    }
    value(1; Heading)
    {
        Caption = 'Heading';
    }
    value(2; Total)
    {
        Caption = 'Total';
    }
    value(3; "Begin-Total")
    {
        Caption = 'Begin-Total';
    }
    value(4; "End-Total")
    {
        Caption = 'End-Total';
    }
}