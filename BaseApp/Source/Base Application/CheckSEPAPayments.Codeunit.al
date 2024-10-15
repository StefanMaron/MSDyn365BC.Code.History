codeunit 2000004 "Check SEPA Payments"
{
    TableNo = "Payment Journal Line";

    trigger OnRun()
    begin
        CheckPaymJnlLine.Init();
        CheckPaymJnlLine.CheckCompanyName;

        if FindSet then begin
            CheckPaymJnlLine.CheckExportProtocol("Export Protocol Code");
            repeat
                CheckPaymJnlLine.CheckCustVendName(Rec);
                CheckPaymJnlLine.FillGroupLineAmountBuf(Rec);
                CheckPaymJnlLine.CheckBankForSEPA(Rec);
                CheckPaymJnlLine.CheckBeneficiaryBankForSEPA(Rec, true);
                CheckPaymJnlLine.ErrorIfCurrencyNotEuro(Rec);
                OnAfterCheckPaymJnlLine(Rec, CheckPaymJnlLine);
            until Next() = 0;
            CheckPaymJnlLine.CheckTotalLineAmounts;
        end else
            CheckPaymJnlLine.ErrorNoPayments;

        CheckPaymJnlLine.ShowErrorLog;
    end;

    var
        CheckPaymJnlLine: Codeunit CheckPaymJnlLine;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPaymJnlLine(var PaymentJournalLine: Record "Payment Journal Line"; var CheckPaymJnlLine: Codeunit CheckPaymJnlLine)
    begin
    end;
}

