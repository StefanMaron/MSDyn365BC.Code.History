namespace Microsoft.Bank.Reconciliation;

enum 1254 "Bank Acc. Rec. Stmt. Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Bank Reconciliation") { Caption = 'Bank Reconciliation'; }
    value(1; "Payment Application") { Caption = 'Payment Application'; }
}