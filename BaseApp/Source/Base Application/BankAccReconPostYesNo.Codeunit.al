codeunit 371 "Bank Acc. Recon. Post (Yes/No)"
{
    TableNo = "Bank Acc. Reconciliation";

    trigger OnRun()
    begin
        if BankAccReconPostYesNo(Rec) then;
    end;

    var
        PostReconciliationQst: Label 'Do you want to post the Reconciliation?';
        PostPaymentsOnlyQst: Label 'Do you want to post the payments?';
        PostPaymentsAndReconcileQst: Label 'Do you want to post the payments and reconcile the bank account?';

    procedure BankAccReconPostYesNo(var BankAccReconciliation: Record "Bank Acc. Reconciliation"): Boolean
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        Question: Text;
    begin
        BankAccRecon.Copy(BankAccReconciliation);

        if BankAccRecon."Statement Type" = BankAccRecon."Statement Type"::"Payment Application" then
            if BankAccRecon."Post Payments Only" then
                Question := PostPaymentsOnlyQst
            else
                Question := PostPaymentsAndReconcileQst
        else
            Question := PostReconciliationQst;

        if not Confirm(Question, false) then
            exit(false);

        CODEUNIT.Run(CODEUNIT::"Bank Acc. Reconciliation Post", BankAccRecon);
        BankAccReconciliation := BankAccRecon;
        exit(true);
    end;
}

