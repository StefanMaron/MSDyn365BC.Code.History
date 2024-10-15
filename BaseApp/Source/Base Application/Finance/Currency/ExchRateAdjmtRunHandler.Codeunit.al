// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.HumanResources.Payables;
using Microsoft.Sales.Receivables;
#if not CLEAN23
using System.Environment.Configuration;
#endif

codeunit 599 "Exch. Rate Adjmt. Run Handler"
{
    trigger OnRun()
    begin
        RunExchangeRateAdjustment();
    end;

#if not CLEAN23
    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
#endif

    local procedure RunExchangeRateAdjustment()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunExchangeRateAdjustment(IsHandled);
        if IsHandled then
            exit;

#if not CLEAN23
        IsHandled := FeatureKeyManagement.IsExtensibleExchangeRateAdjustmentEnabled();
        Commit();

        if IsHandled then
            Report.Run(Report::"Exch. Rate Adjustment")
        else
            Report.Run(Report::"Adjust Exchange Rates");
#else
        Report.Run(Report::"Exch. Rate Adjustment");
#endif
    end;

    procedure RunCustExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    var
#if not CLEAN23
        AdjustExchangeRates: Report "Adjust Exchange Rates";
#endif
        ExchRateAdjmtProcess: Codeunit "Exch. Rate Adjmt. Process";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCustExchRateAdjustment(GenJnlLine, TempCustLedgerEntry, IsHandled);
        if not IsHandled then
#if not CLEAN23
            if FeatureKeyManagement.IsExtensibleExchangeRateAdjustmentEnabled() then
                ExchRateAdjmtProcess.AdjustExchRateCust(GenJnlLine, TempCustLedgerEntry)
            else
                AdjustExchangeRates.AdjustExchRateCust(GenJnlLine, TempCustLedgerEntry);
#else
            ExchRateAdjmtProcess.AdjustExchRateCust(GenJnlLine, TempCustLedgerEntry);
#endif
    end;

    procedure RunVendExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary)
    var
#if not CLEAN23
        AdjustExchangeRates: Report "Adjust Exchange Rates";
#endif
        ExchRateAdjmtProcess: Codeunit "Exch. Rate Adjmt. Process";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunVendExchRateAdjustment(GenJnlLine, TempVendorLedgerEntry, IsHandled);
        if not IsHandled then
#if not CLEAN23
            if FeatureKeyManagement.IsExtensibleExchangeRateAdjustmentEnabled() then
                ExchRateAdjmtProcess.AdjustExchRateVend(GenJnlLine, TempVendorLedgerEntry)
            else
                AdjustExchangeRates.AdjustExchRateVend(GenJnlLine, TempVendorLedgerEntry);
#else
            ExchRateAdjmtProcess.AdjustExchRateVend(GenJnlLine, TempVendorLedgerEntry);
#endif
    end;

    procedure RunEmplExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary)
    var
        ExchRateAdjmtProcess: Codeunit "Exch. Rate Adjmt. Process";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunEmplExchRateAdjustment(GenJnlLine, TempEmployeeLedgerEntry, IsHandled);
        if not IsHandled then
#if not CLEAN23
            if FeatureKeyManagement.IsExtensibleExchangeRateAdjustmentEnabled() then
                ExchRateAdjmtProcess.AdjustExchRateEmpl(GenJnlLine, TempEmployeeLedgerEntry)
#else
            ExchRateAdjmtProcess.AdjustExchRateEmpl(GenJnlLine, TempEmployeeLedgerEntry);
#endif
    end;

#if not CLEAN23
    internal procedure ShowFeatureManagement(ErrorInfo: ErrorInfo)
    begin
        Page.RunModal(Page::"Feature Management");
    end;
#endif

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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunEmplExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;
}

