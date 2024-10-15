namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.Statement;
using Microsoft.Foundation.Reporting;

codeunit 372 "Bank Acc. Recon. Post+Print"
{
    TableNo = "Bank Acc. Reconciliation";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec);

        BankAccRecon.Copy(Rec);

        if not Confirm(Text000, false) then
            exit;

        CODEUNIT.Run(CODEUNIT::"Bank Acc. Reconciliation Post", BankAccRecon);
        Rec := BankAccRecon;
        Commit();

        if BankAccStmt.Get(Rec."Bank Account No.", Rec."Statement No.") then
            DocPrint.PrintBankAccStmt(BankAccStmt);
    end;

    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccStmt: Record "Bank Account Statement";
        DocPrint: Codeunit "Document-Print";
#pragma warning disable AA0074
        Text000: Label 'Do you want to post and print the Reconciliation?';
#pragma warning restore AA0074

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
    end;
}

