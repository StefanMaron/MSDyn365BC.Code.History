#if not CLEAN19
codeunit 11773 "Bank Acc. Recon. Handler"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Merge to W1.';
    ObsoleteTag = '19.0';

    [EventSubscriber(ObjectType::Table, Database::"Bank Acc. Reconciliation", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertBankAccReconciliation(var Rec: Record "Bank Acc. Reconciliation"; RunTrigger: Boolean)
    var
        BankAccount: Record "Bank Account";
    begin
        with Rec do begin
            if not RunTrigger or IsTemporary then
                exit;

            BankAccount.Get("Bank Account No.");
            "Copy VAT Setup to Jnl. Line" := BankAccount."Copy VAT Setup to Jnl. Line";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Acc. Reconciliation", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteBankAccReconciliation(var Rec: Record "Bank Acc. Reconciliation"; RunTrigger: Boolean)
    var
        IssuedBankStmtHdr: Record "Issued Bank Statement Header";
    begin
        with Rec do begin
            if not RunTrigger or IsTemporary then
                exit;

            if IssuedBankStmtHdr.Get("Statement No.") then
                IssuedBankStmtHdr.UpdatePaymentReconciliationStatus(IssuedBankStmtHdr."Payment Reconciliation Status"::" ");
        end;
    end;
}
#endif