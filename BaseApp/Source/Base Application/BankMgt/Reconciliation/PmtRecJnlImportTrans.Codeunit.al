namespace Microsoft.Bank.Reconciliation;

codeunit 9023 "Pmt. Rec. Jnl. Import Trans."
{

    trigger OnRun()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        BankAccReconciliation.ImportAndProcessToNewStatement();
    end;
}

