namespace Microsoft.Bank.BankAccount;

enum 272 "Bank Payment Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; "Computer Check")
    {
        Caption = 'Computer Check';
    }
    value(2; "Manual Check")
    {
        Caption = 'Manual Check';
    }
    value(3; "Electronic Payment")
    {
        Caption = 'Electronic Payment';
    }
    value(4; "Electronic Payment-IAT")
    {
        Caption = 'Electronic Payment-IAT';
    }
}