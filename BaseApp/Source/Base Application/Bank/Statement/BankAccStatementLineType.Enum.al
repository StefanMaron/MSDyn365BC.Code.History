namespace Microsoft.Bank.Statement;

enum 1249 "Bank Acc. Statement Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Bank Account Ledger Entry") { Caption = 'Bank Account Ledger Entry'; }
    value(1; "Check Ledger Entry") { Caption = 'Check Ledger Entry'; }
    value(2; "Difference") { Caption = 'Difference'; }
}