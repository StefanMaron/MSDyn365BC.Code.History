codeunit 380 "Bank Acc. Recon. Test"
{

    trigger OnRun()
    begin
    end;

    procedure TotalOutstandingPayments(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    begin
        exit(
            BankAccReconciliation."Total Outstd Payments" -
            BankAccReconciliation."Total Applied Amount Payments"
        )
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
                Total := BankAccReconciliation."Total Outstd Bank Transactions" -
                    (BankAccReconciliation."Total Applied Amount" - BankAccReconciliation."Total Applied Amount Payments");
            BankAccReconciliation."Statement Type"::"Payment Application":
                Total := BankAccReconciliation."Total Outstd Bank Transactions" -
                    (BankAccReconciliation."Total Applied Amount" - BankAccReconciliation."Total Applied Amount Payments" - BankAccReconciliation."Total Unposted Applied Amount");
        end;
        exit(Total);
    end;
}

