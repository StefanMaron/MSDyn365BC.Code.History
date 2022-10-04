#if not CLEAN21
codeunit 374 "Bank Acc. Recon. Apply Entries"
{
    TableNo = "Bank Acc. Reconciliation Line";
    ObsoleteReason = 'Entries are applied when a Bank Ledger Entry with a Check Ledger Entry is matched. This page is redundant, add your extensions to MatchBankRecLines codeunit instead.';
    ObsoleteTag = '21.0';
    ObsoleteState = Pending;

    trigger OnRun()
    begin
    end;

    var
        BankAccReconLine2: Record "Bank Acc. Reconciliation Line";
        CheckLedgEntry: Record "Check Ledger Entry";
        ApplyCheckLedgEntry: Page "Apply Check Ledger Entries";

    procedure ApplyEntries(var BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    begin
        BankAccReconLine2 := BankAccReconLine;
        BankAccReconLine2.TestField("Ready for Application", true);
        with BankAccReconLine2 do
            case Type of
                Type::"Check Ledger Entry":
                    begin
                        CheckLedgEntry.Reset();
                        CheckLedgEntry.SetCurrentKey("Bank Account No.", Open);
                        CheckLedgEntry.SetRange("Bank Account No.", "Bank Account No.");
                        CheckLedgEntry.SetRange(Open, true);
                        CheckLedgEntry.SetFilter(
                          "Entry Status", '%1|%2', CheckLedgEntry."Entry Status"::Posted,
                          CheckLedgEntry."Entry Status"::"Financially Voided");
                        CheckLedgEntry.SetFilter(
                          "Statement Status", '%1|%2', CheckLedgEntry."Statement Status"::Open,
                          CheckLedgEntry."Statement Status"::"Check Entry Applied");
                        CheckLedgEntry.SetFilter("Statement No.", '''''|%1', "Statement No.");
                        CheckLedgEntry.SetFilter("Statement Line No.", '0|%1', "Statement Line No.");
                        ApplyCheckLedgEntry.SetStmtLine(BankAccReconLine);
                        ApplyCheckLedgEntry.SetRecord(CheckLedgEntry);
                        ApplyCheckLedgEntry.SetTableView(CheckLedgEntry);
                        ApplyCheckLedgEntry.LookupMode(true);
                        if ApplyCheckLedgEntry.RunModal() = ACTION::LookupOK then;
                        Clear(ApplyCheckLedgEntry);

                        OnAfterApplyCheckLedgEntry(BankAccReconLine);
                    end;
            end;

        OnAfterApplyEntries(BankAccReconLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyCheckLedgEntry(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyEntries(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;
}

#endif