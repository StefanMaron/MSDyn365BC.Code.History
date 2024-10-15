#pragma warning disable AL0432
codeunit 11793 "Bank Account Handler CZP"
{
    var

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnBeforeRenameEvent', '', false, false)]
    local procedure SyncOnBeforeRenameBankAccount(var Rec: Record "Bank Account"; RunTrigger: Boolean)
    begin
        CashDeskChangeAction(Rec, RunTrigger);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnBeforeInsertEvent', '', false, false)]
    local procedure SyncOnBeforeInsertBankAccount(var Rec: Record "Bank Account"; RunTrigger: Boolean)
    begin
        CashDeskChangeAction(Rec, RunTrigger);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SyncOnBeforeModifyBankAccount(var Rec: Record "Bank Account"; RunTrigger: Boolean)
    begin
        CashDeskChangeAction(Rec, RunTrigger);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SyncOnBeforeDeleteBankAccount(var Rec: Record "Bank Account"; RunTrigger: Boolean)
    begin
        CashDeskChangeAction(Rec, RunTrigger);
    end;

    local procedure CashDeskChangeAction(var Rec: Record "Bank Account"; RunTrigger: Boolean)
#if not CLEAN17
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CashDeskDisableChangeErr: Label 'You cannot change Cash Desks because are obsolete.';
#endif
    begin
        if NavApp.IsInstalling() then
            exit;
        if Rec.IsTemporary() then
            exit;
        if not RunTrigger then
            exit;
#if not CLEAN17
        BankAccountLedgerEntry.SetRange("Bank Account No.", Rec."No.");
        if BankAccountLedgerEntry.IsEmpty() then
            exit;
        if Rec."Account Type" = Rec."Account Type"::"Cash Desk" then
            Error(CashDeskDisableChangeErr);
#endif
    end;
}
