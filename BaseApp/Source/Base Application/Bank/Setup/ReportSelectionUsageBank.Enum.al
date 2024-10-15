namespace Microsoft.Bank.Setup;

enum 385 "Report Selection Usage Bank"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Statement") { Caption = 'Statement'; }
    value(1; "Reconciliation - Test") { Caption = 'Reconciliation - Test'; }
    value(2; "Check") { Caption = 'Check'; }
    value(8; "Posted Payment Reconciliation") { Caption = 'Posted Payment Reconciliation'; }
}
