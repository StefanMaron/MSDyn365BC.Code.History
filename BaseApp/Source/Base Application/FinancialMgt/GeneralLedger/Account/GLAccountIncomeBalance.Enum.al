namespace Microsoft.Finance.GeneralLedger.Account;

enum 18 "G/L Account Income/Balance"
{
    AssignmentCompatibility = true;
    Extensible = false;

    value(0; " ") { Caption = ' '; }
    value(1; "Income Statement") { Caption = 'Income Statement'; }
    value(2; "Balance Sheet") { Caption = 'Balance Sheet'; }
}