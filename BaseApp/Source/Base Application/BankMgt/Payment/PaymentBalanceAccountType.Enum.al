namespace Microsoft.Bank.Payment;

enum 96 "Payment Balance Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "G/L Account") { Caption = 'G/L Account'; }
    value(1; "Bank Account") { Caption = 'Bank Account'; }
}