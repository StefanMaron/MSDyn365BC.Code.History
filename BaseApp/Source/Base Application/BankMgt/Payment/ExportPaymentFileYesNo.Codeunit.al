namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Requisition;

codeunit 1209 "Export Payment File (Yes/No)"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        BankAcc: Record "Bank Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        if not Rec.FindSet() then
            Error(NothingToExportErr);
        Rec.SetRange("Journal Template Name", Rec."Journal Template Name");
        Rec.SetRange("Journal Batch Name", Rec."Journal Batch Name");

        GenJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name");
        GenJnlBatch.TestField("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"Bank Account");
        GenJnlBatch.TestField("Bal. Account No.");

        Rec.CheckDocNoOnLines();
        if Rec.IsExportedToPaymentFile() then
            if not Confirm(ExportAgainQst) then
                exit;
        BankAcc.Get(GenJnlBatch."Bal. Account No.");
        CODEUNIT.Run(BankAcc.GetPaymentExportCodeunitID(), Rec);

        OnAfterOnRun(Rec, GenJnlBatch, BankAcc);
    end;

    var
        ExportAgainQst: Label 'One or more of the selected lines have already been exported. Do you want to export again?';
        NothingToExportErr: Label 'There is nothing to export.';

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var GenJournalLine: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch"; BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnBeforeGetDirectCost', '', false, false)]
    local procedure OnBeforeGetDirectCost()
    begin
    end;
}

