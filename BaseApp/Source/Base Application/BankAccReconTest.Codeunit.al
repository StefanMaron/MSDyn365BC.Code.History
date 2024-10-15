codeunit 380 "Bank Acc. Recon. Test"
{

    trigger OnRun()
    begin
    end;

    procedure TotalOutstandingPayments(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    begin
        if BankAccReconciliation."Statement Type" = BankAccReconciliation."Statement Type"::"Payment Application" then
            exit(
                BankAccReconciliation."Total Outstd Payments" -
                BankAccReconciliation."Total Applied Amount Payments"
            );
        exit(OutstandingPayments(BankAccReconciliation));
    end;

    procedure TotalPositiveDifference(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    begin
        case BankAccReconciliation."Statement Type" of
            BankAccReconciliation."Statement Type"::"Bank Reconciliation":
                exit(BankAccReconciliation."Total Positive Difference");
            BankAccReconciliation."Statement Type"::"Payment Application":
                exit(BankAccReconciliation."Total Positive Adjustments");
        end;
    end;

    procedure TotalNegativeDifference(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    begin
        case BankAccReconciliation."Statement Type" of
            BankAccReconciliation."Statement Type"::"Bank Reconciliation":
                exit(BankAccReconciliation."Total Negative Difference");
            BankAccReconciliation."Statement Type"::"Payment Application":
                exit(BankAccReconciliation."Total Negative Adjustments");
        end;
    end;

    procedure TotalOutstandingBankTransactions(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    var
        Total: Decimal;
    begin
        case BankAccReconciliation."Statement Type" of
            BankAccReconciliation."Statement Type"::"Bank Reconciliation":
                Total := OutstandingBankTransactions(BankAccReconciliation);
            BankAccReconciliation."Statement Type"::"Payment Application":
                Total := BankAccReconciliation."Total Outstd Bank Transactions" -
                    (BankAccReconciliation."Total Applied Amount" - BankAccReconciliation."Total Applied Amount Payments" - BankAccReconciliation."Total Unposted Applied Amount");
        end;
        exit(Total);
    end;

    local procedure SetOutstandingFilters(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange(Open, true);
        BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::Open);
        if BankAccReconciliation."Statement Date" <> 0D then
            BankAccountLedgerEntry.SetRange("Posting Date", 0D, BankAccReconciliation."Statement Date");
    end;

    local procedure OutstandingBankTransactions(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        Total: Decimal;
    begin
        Total := 0;
        SetOutstandingFilters(BankAccReconciliation, BankAccountLedgerEntry);
        BankAccountLedgerEntry.SetRange("Check Ledger Entries", 0);

        if BankAccountLedgerEntry.FindSet() then
            repeat
                Total += BankAccountLedgerEntry.Amount;
            until BankAccountLedgerEntry.Next() = 0;
        exit(Total);
    end;

    local procedure OutstandingPayments(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        Total: Decimal;
    begin
        Total := 0;
        SetOutstandingFilters(BankAccReconciliation, BankAccountLedgerEntry);
        BankAccountLedgerEntry.SetFilter("Check Ledger Entries", '<>0');

        if BankAccountLedgerEntry.FindSet() then
            repeat
                Total += BankAccountLedgerEntry.Amount;
            until BankAccountLedgerEntry.Next() = 0;
        exit(Total);
    end;

}

