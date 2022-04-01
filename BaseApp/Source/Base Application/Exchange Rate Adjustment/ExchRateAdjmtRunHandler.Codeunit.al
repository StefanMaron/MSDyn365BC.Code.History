codeunit 599 "Exch. Rate Adjmt. Run Handler"
{
    trigger OnRun()
    begin
        RunExchangeRateAdjustment();
    end;

    local procedure RunExchangeRateAdjustment()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunExchangeRateAdjustment(IsHandled);
        if IsHandled then
            exit;

#if not CLEAN20
        Report.Run(Report::"Adjust Exchange Rates");
#else
        Report.Run(Report::"Exch. Rate Adjustment");
#endif
    end;

    procedure RunCustExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    var
#if not CLEAN20
        AdjustExchangeRates: Report "Adjust Exchange Rates";
#else
        ExchRateAdjmtProcess: Codeunit "Exch. Rate Adjmt. Process";
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCustExchRateAdjustment(GenJnlLine, TempCustLedgerEntry, IsHandled);
        if not IsHandled then
#if not CLEAN20
            AdjustExchangeRates.AdjustExchRateCust(GenJnlLine, TempCustLedgerEntry);
#else
            ExchRateAdjmtProcess.AdjustExchRateCust(GenJnlLine, TempCustLedgerEntry);
#endif
    end;

    procedure RunVendExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary)
    var
#if not CLEAN20
        AdjustExchangeRates: Report "Adjust Exchange Rates";
#else
        ExchRateAdjmtProcess: Codeunit "Exch. Rate Adjmt. Process";
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunVendExchRateAdjustment(GenJnlLine, TempVendorLedgerEntry, IsHandled);
        if not IsHandled then
#if not CLEAN20
            AdjustExchangeRates.AdjustExchRateVend(GenJnlLine, TempVendorLedgerEntry);
#else
            ExchRateAdjmtProcess.AdjustExchRateVend(GenJnlLine, TempVendorLedgerEntry);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunExchangeRateAdjustment(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCustExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunVendExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;
}