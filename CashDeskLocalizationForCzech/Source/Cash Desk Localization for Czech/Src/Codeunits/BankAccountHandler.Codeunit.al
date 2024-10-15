#pragma warning disable AL0432
codeunit 11793 "Bank Account Handler CZP"
{
    var
        CashDeskSingleInstanceCZP: Codeunit "Cash Desk Single Instance CZP";

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

    local procedure CashDeskChangeAction(var BankAccount: Record "Bank Account"; RunTrigger: Boolean)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
#if not CLEAN17
        CashDeskDisableChangeErr: Label 'You cannot change Cash Desks because are obsolete.';
#endif
    begin
        if NavApp.IsInstalling() then
            exit;
        if BankAccount.IsTemporary() then
            exit;
        if not RunTrigger then
            exit;
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        if BankAccountLedgerEntry.IsEmpty() then
            exit;
#if not CLEAN17
        if BankAccount."Account Type" = BankAccount."Account Type"::"Cash Desk" then
            Error(CashDeskDisableChangeErr);
#endif
    end;

    [EventSubscriber(ObjectType::Report, Report::"Adjust Exchange Rates CZL", 'OnBeforeOnInitReport', '', false, false)]
    local procedure ShowCashDesksOnBeforeOnInitReport()
    begin
        CashDeskSingleInstanceCZP.SetShowAllBankAccountType(true);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Adjust Exchange Rates CZL", 'OnCloseRequestPage', '', false, false)]
    local procedure HideCashDesksOnCloseRequestPage()
    begin
        CashDeskSingleInstanceCZP.SetShowAllBankAccountType(false);
    end;
}
