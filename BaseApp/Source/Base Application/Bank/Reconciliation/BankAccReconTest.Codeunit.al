// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 380 "Bank Acc. Recon. Test"
{

    trigger OnRun()
    begin
    end;

    procedure TotalPositiveDifference(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    begin
        case BankAccReconciliation."Statement Type" of
            BankAccReconciliation."Statement Type"::"Bank Reconciliation":
                exit(0);
            BankAccReconciliation."Statement Type"::"Payment Application":
                exit(BankAccReconciliation."Total Positive Adjustments");
        end;
    end;

    procedure TotalNegativeDifference(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    begin
        case BankAccReconciliation."Statement Type" of
            BankAccReconciliation."Statement Type"::"Bank Reconciliation":
                exit(0);
            BankAccReconciliation."Statement Type"::"Payment Application":
                exit(BankAccReconciliation."Total Negative Adjustments");
        end;
    end;

    local procedure SetOutstandingFilters(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange(Open, true);
        BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::Open);
        if BankAccReconciliation."Statement Date" <> 0D then
            BankAccountLedgerEntry.SetRange("Posting Date", 0D, BankAccReconciliation."Statement Date");
    end;

    procedure TotalOutstandingBankTransactions(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Total: Decimal;
        DocNo: Text;
    begin
        SetOutstandingFilters(BankAccReconciliation, BankAccountLedgerEntry);
        BankAccountLedgerEntry.SetRange("Check Ledger Entries", 0);

        BankAccountLedgerEntry.CalcSums(Amount);
        Total := BankAccountLedgerEntry.Amount;

        if BankAccReconciliation."Statement Type" = BankAccReconciliation."Statement Type"::"Payment Application" then begin
            // When the BankAccReconciliation is created from the Payment Reconciliation Journal:
            // we subtract the "Applied Amount" to Bank Ledger Entries with no CLE, since those are no longer outstanding.
            // These are the lines with "Account Type" "Bank Account", that are applied to some "Document No." (Lines of type Bank Account without Doc. No are bank to bank transfers, which are not outstanding)
            BankAccReconciliation.SetFiltersOnBankAccReconLineTable(BankAccReconciliation, BankAccReconciliationLine);
            BankAccReconciliationLine.SetRange("Account Type", BankAccReconciliationLine."Account Type"::"Bank Account");
            if BankAccReconciliationLine.FindSet() then
                repeat
                    DocNo := BankAccReconciliationLine.GetAppliedToDocumentNo('|');
                    if DocNo <> '' then begin
                        // We will just subtract the "Applied Amount" if there is no Check Ledger Entry
                        // associated to that BLE
                        BankAccountLedgerEntry.Reset();
                        BankAccountLedgerEntry.SetFilter("Document No.", DocNo);
                        BankAccountLedgerEntry.SetRange("Check Ledger Entries", 0);
                        if not BankAccountLedgerEntry.IsEmpty() then
                            Total -= BankAccReconciliationLine."Applied Amount";
                    end;
                until BankAccReconciliationLine.Next() = 0;
        end;
        exit(Total);
    end;

    procedure TotalOutstandingPayments(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Total: Decimal;
        DocNo: Text;
    begin
        SetOutstandingFilters(BankAccReconciliation, BankAccountLedgerEntry);
        BankAccountLedgerEntry.SetFilter("Check Ledger Entries", '<>0');

        BankAccountLedgerEntry.CalcSums(Amount);
        Total := BankAccountLedgerEntry.Amount;

        if BankAccReconciliation."Statement Type" = BankAccReconciliation."Statement Type"::"Payment Application" then begin
            // When the BankAccReconciliation is created from the Payment Reconciliation Journal:
            // we subtract the "Applied Amount" to Bank Ledger Entries with CLEs, since those are no longer outstanding.
            // These are the lines with "Account Type" "Bank Account", that are applied to some "Document No." (Lines of type Bank Account without Doc. No are bank to bank transfers, which are not outstanding)
            BankAccReconciliation.SetFiltersOnBankAccReconLineTable(BankAccReconciliation, BankAccReconciliationLine);
            BankAccReconciliationLine.SetRange("Account Type", BankAccReconciliationLine."Account Type"::"Bank Account");
            if BankAccReconciliationLine.FindSet() then
                repeat
                    DocNo := BankAccReconciliationLine.GetAppliedToDocumentNo('|');
                    if DocNo <> '' then begin
                        // We will just subtract the "Applied Amount" if there are Check Ledger Entry
                        // associated to that BLE
                        BankAccountLedgerEntry.Reset();
                        BankAccountLedgerEntry.SetFilter("Document No.", DocNo);
                        BankAccountLedgerEntry.SetFilter("Check Ledger Entries", '<>0');
                        if not BankAccountLedgerEntry.IsEmpty() then
                            Total -= BankAccReconciliationLine."Applied Amount";
                    end;
                until BankAccReconciliationLine.Next() = 0;
        end;
        exit(Total);
    end;

    procedure GetGLAccountBalanceLCY(BankAcc: Record "Bank Account"; BankAccPostingGroup: Record "Bank Account Posting Group"; StatementDate: Date): Decimal
    var
        GLAccount: Record "G/L Account";
        GLEntries: Record "G/L Entry";
    begin
        if BankAccPostingGroup."G/L Account No." = '' then
            exit(0);

        if not GLAccount.Get(BankAccPostingGroup."G/L Account No.") then
            exit(0);

        GLEntries.SetRange("G/L Account No.", BankAccPostingGroup."G/L Account No.");
        if (StatementDate <> 0D) then
            GLEntries.SetFilter("Posting Date", '<= %1', StatementDate);

        if GLEntries.IsEmpty() then
            exit(0);

        GLEntries.CalcSums(Amount);
        exit(GLEntries.Amount);
    end;

    procedure GetGLAccountBalance(TotalBalOnGLAccountLCY: Decimal; StatementDate: Date; CurrencyCode: Code[10]): Decimal
    var
        Currency: Record "Currency Exchange Rate";
        ExchangeRate: Decimal;
    begin
        ExchangeRate := Currency.ExchangeRate(StatementDate, CurrencyCode);
        exit(TotalBalOnGLAccountLCY * ExchangeRate);
    end;
}

