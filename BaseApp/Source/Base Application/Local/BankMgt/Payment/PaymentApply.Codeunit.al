﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;

codeunit 10861 "Payment-Apply"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm;
    TableNo = "Payment Line";

    trigger OnRun()
    begin
        Apply(Rec);
    end;

    local procedure Apply(var PaymentLine: Record "Payment Line")
    var
        PaymentHeader: Record "Payment Header";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
    begin
        PaymentHeader.Get(PaymentLine."No.");

        GenJnlLine."Account Type" := PaymentLine."Account Type";
        GenJnlLine."Account No." := PaymentLine."Account No.";
        GenJnlLine.Amount := PaymentLine.Amount;
        GenJnlLine."Amount (LCY)" := PaymentLine."Amount (LCY)";
        GenJnlLine."Currency Code" := PaymentLine."Currency Code";
        GenJnlLine."Posting Date" := PaymentHeader."Posting Date";
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Applies-to ID" := PaymentLine."Applies-to ID";
        GenJnlLine."Applies-to Doc. No." := PaymentLine."Applies-to Doc. No.";
        GenJnlLine."Applies-to Doc. Type" := PaymentLine."Applies-to Doc. Type";

        PaymentLine.GetCurrency();
        AccType := GenJnlLine."Account Type";
        AccNo := GenJnlLine."Account No.";
        case AccType of
            AccType::Customer:
                begin
                    ApplyCustomer(PaymentLine);
                    if PaymentLine.Amount <> 0 then
                        if not PaymentToleranceMgt.PmtTolGenJnl(GenJnlLine) then
                            exit;
                end;
            AccType::Vendor:
                begin
                    ApplyVendor(PaymentLine);
                    if PaymentLine.Amount <> 0 then
                        if not PaymentToleranceMgt.PmtTolGenJnl(GenJnlLine) then
                            exit;
                end;
            else
                Error(
                    Text005,
                    GenJnlLine.FieldCaption("Account Type"), GenJnlLine.FieldCaption("Bal. Account Type"));
        end;

        PaymentLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type";
        PaymentLine."Applies-to Doc. No." := GenJnlLine."Applies-to Doc. No.";
        PaymentLine."Applies-to ID" := GenJnlLine."Applies-to ID";
        PaymentLine."Due Date" := GenJnlLine."Due Date";
        PaymentLine.Amount := GenJnlLine.Amount;
        PaymentLine."Amount (LCY)" := GenJnlLine."Amount (LCY)";
        PaymentLine.Validate(Amount);
        PaymentLine.Validate("Amount (LCY)");
        if (PaymentLine."Direct Debit Mandate ID" = '') and (GenJnlLine."Direct Debit Mandate ID" <> '') then
            PaymentLine.Validate("Direct Debit Mandate ID", GenJnlLine."Direct Debit Mandate ID");

        OnAfterApply(GenJnlLine);
    end;

    var
        Text001: Label 'The %1 in the %2 will be changed from %3 to %4.\';
        Text002: Label 'Do you wish to continue?';
        Text003: Label 'The update has been interrupted to respect the warning.';
        Text005: Label 'The %1 or %2 must be Customer or Vendor.';
        Text006: Label 'All entries in one application must be in the same currency.';
        Text007: Label 'All entries in one application must be in the same currency or one or more of the EMU currencies.';
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ApplyCustEntries: Page "Apply Customer Entries";
        ApplyVendEntries: Page "Apply Vendor Entries";
        AccNo: Code[20];
        CurrencyCode2: Code[10];
        OK: Boolean;
        AccType: Enum "Gen. Journal Account Type";


    local procedure ApplyCustomer(PaymentLine: Record "Payment Line")
    begin
        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
        CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange(Open, true);
        GenJnlLine."Applies-to ID" := GetAppliesToID(GenJnlLine."Applies-to ID", PaymentLine);
        ApplyCustEntries.SetGenJnlLine(GenJnlLine, GenJnlLine.FieldNo("Applies-to ID"));
        ApplyCustEntries.SetRecord(CustLedgEntry);
        ApplyCustEntries.SetTableView(CustLedgEntry);
        ApplyCustEntries.LookupMode(true);
        OK := ApplyCustEntries.RunModal() = ACTION::LookupOK;
        Clear(ApplyCustEntries);
        if not OK then
            exit;
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
        CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
        if CustLedgEntry.Find('-') then begin
            CurrencyCode2 := CustLedgEntry."Currency Code";
            if GenJnlLine.Amount = 0 then begin
                repeat
                    CheckAgainstApplnCurrency(CurrencyCode2, CustLedgEntry."Currency Code", "Gen. Journal Account Type"::Customer.AsInteger(), true);
                    CustLedgEntry.CalcFields("Remaining Amount");
                    CustLedgEntry."Remaining Amount" :=
                        CurrExchRate.ExchangeAmount(
                        CustLedgEntry."Remaining Amount",
                        CustLedgEntry."Currency Code", GenJnlLine."Currency Code", GenJnlLine."Posting Date");
                    CustLedgEntry."Remaining Amount" :=
                        Round(CustLedgEntry."Remaining Amount", Currency."Amount Rounding Precision");
                    CustLedgEntry."Remaining Pmt. Disc. Possible" :=
                        CurrExchRate.ExchangeAmount(
                        CustLedgEntry."Remaining Pmt. Disc. Possible",
                        CustLedgEntry."Currency Code", GenJnlLine."Currency Code", GenJnlLine."Posting Date");
                    CustLedgEntry."Remaining Pmt. Disc. Possible" :=
                        Round(CustLedgEntry."Remaining Pmt. Disc. Possible", Currency."Amount Rounding Precision");
                    CustLedgEntry."Amount to Apply" :=
                        CurrExchRate.ExchangeAmount(
                        CustLedgEntry."Amount to Apply",
                        CustLedgEntry."Currency Code", GenJnlLine."Currency Code", GenJnlLine."Posting Date");
                    CustLedgEntry."Amount to Apply" :=
                        Round(CustLedgEntry."Amount to Apply", Currency."Amount Rounding Precision");
                    if ((CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::"Credit Memo") and
                        (CustLedgEntry."Remaining Pmt. Disc. Possible" <> 0) or
                        (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice)) and
                        (GenJnlLine."Posting Date" <= CustLedgEntry."Pmt. Discount Date")
                    then
                        GenJnlLine.Amount := GenJnlLine.Amount - (CustLedgEntry."Amount to Apply" - CustLedgEntry."Remaining Pmt. Disc. Possible")
                    else
                        GenJnlLine.Amount := GenJnlLine.Amount - CustLedgEntry."Amount to Apply";
                until CustLedgEntry.Next() = 0;
                GenJnlLine."Amount (LCY)" := GenJnlLine.Amount;
                GenJnlLine."Currency Factor" := 1;
                if (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer) or
                    (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor)
                then begin
                    GenJnlLine.Amount := -GenJnlLine.Amount;
                    GenJnlLine."Amount (LCY)" := -GenJnlLine."Amount (LCY)";
                end;
                GenJnlLine.Validate(Amount);
                GenJnlLine.Validate("Amount (LCY)");
            end else
                repeat
                    CheckAgainstApplnCurrency(CurrencyCode2, CustLedgEntry."Currency Code", "Gen. Journal Account Type"::Customer.AsInteger(), true);
                until CustLedgEntry.Next() = 0;
            ConfirmAndCheckApplnCurrency(GenJnlLine, Text001 + Text002, CustLedgEntry."Currency Code", "Gen. Journal Account Type"::Customer.AsInteger());
        end else
            GenJnlLine."Applies-to ID" := '';
        GenJnlLine."Due Date" := CustLedgEntry."Due Date";
        GenJnlLine."Direct Debit Mandate ID" := CustLedgEntry."Direct Debit Mandate ID";

        OnAfterApplyCustomer(CustLedgEntry, GenJnlLine);
    end;

    local procedure ApplyVendor(PaymentLine: Record "Payment Line")
    begin
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
        VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange(Open, true);
        GenJnlLine."Applies-to ID" := GetAppliesToID(GenJnlLine."Applies-to ID", PaymentLine);
        ApplyVendEntries.SetGenJnlLine(GenJnlLine, GenJnlLine.FieldNo("Applies-to ID"));
        ApplyVendEntries.SetRecord(VendLedgEntry);
        ApplyVendEntries.SetTableView(VendLedgEntry);
        ApplyVendEntries.LookupMode(true);
        OK := ApplyVendEntries.RunModal() = ACTION::LookupOK;
        Clear(ApplyVendEntries);
        if not OK then
            exit;
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
        VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
        if VendLedgEntry.Find('+') then begin
            CurrencyCode2 := VendLedgEntry."Currency Code";
            if GenJnlLine.Amount = 0 then begin
                repeat
                    CheckAgainstApplnCurrency(CurrencyCode2, VendLedgEntry."Currency Code", "Gen. Journal Account Type"::Vendor.AsInteger(), true);
                    VendLedgEntry.CalcFields("Remaining Amount");
                    VendLedgEntry."Remaining Amount" :=
                        CurrExchRate.ExchangeAmount(
                        VendLedgEntry."Remaining Amount",
                        VendLedgEntry."Currency Code", GenJnlLine."Currency Code", GenJnlLine."Posting Date");
                    VendLedgEntry."Remaining Amount" :=
                        Round(VendLedgEntry."Remaining Amount", Currency."Amount Rounding Precision");
                    VendLedgEntry."Remaining Pmt. Disc. Possible" :=
                        CurrExchRate.ExchangeAmount(
                        VendLedgEntry."Remaining Pmt. Disc. Possible",
                        VendLedgEntry."Currency Code", GenJnlLine."Currency Code", GenJnlLine."Posting Date");
                    VendLedgEntry."Remaining Pmt. Disc. Possible" :=
                        Round(VendLedgEntry."Remaining Pmt. Disc. Possible", Currency."Amount Rounding Precision");
                    VendLedgEntry."Amount to Apply" :=
                        CurrExchRate.ExchangeAmount(
                        VendLedgEntry."Amount to Apply",
                        VendLedgEntry."Currency Code", GenJnlLine."Currency Code", GenJnlLine."Posting Date");
                    VendLedgEntry."Amount to Apply" :=
                        Round(VendLedgEntry."Amount to Apply", Currency."Amount Rounding Precision");
                    if ((VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::"Credit Memo") and
                        (VendLedgEntry."Remaining Pmt. Disc. Possible" <> 0) or
                        (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Invoice)) and
                        (GenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date")
                    then
                        GenJnlLine.Amount := GenJnlLine.Amount - (VendLedgEntry."Amount to Apply" - VendLedgEntry."Remaining Pmt. Disc. Possible")
                    else
                        GenJnlLine.Amount := GenJnlLine.Amount - VendLedgEntry."Amount to Apply";
                until VendLedgEntry.Next(-1) = 0;
                GenJnlLine."Amount (LCY)" := GenJnlLine.Amount;
                GenJnlLine."Currency Factor" := 1;
                if (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer) or
                    (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor)
                then begin
                    GenJnlLine.Amount := -GenJnlLine.Amount;
                    GenJnlLine."Amount (LCY)" := -GenJnlLine."Amount (LCY)";
                end;
                GenJnlLine.Validate(Amount);
                GenJnlLine.Validate("Amount (LCY)");
            end else
                repeat
                    CheckAgainstApplnCurrency(CurrencyCode2, VendLedgEntry."Currency Code", "Gen. Journal Account Type"::Vendor.AsInteger(), true);
                until VendLedgEntry.Next(-1) = 0;
            ConfirmAndCheckApplnCurrency(GenJnlLine, Text001 + Text002, VendLedgEntry."Currency Code", "Gen. Journal Account Type"::Vendor.AsInteger());
        end else
            GenJnlLine."Applies-to ID" := '';
        GenJnlLine."Due Date" := VendLedgEntry."Due Date";

        OnAfterApplyVendor(VendLedgEntry, GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure CheckAgainstApplnCurrency(ApplnCurrencyCode: Code[10]; CompareCurrencyCode: Code[10]; AccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset"; Message: Boolean): Boolean
    var
        Currency: Record Currency;
        Currency2: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        CurrencyAppln: Option No,EMU,All;
    begin
        if ApplnCurrencyCode = CompareCurrencyCode then
            exit(true);

        case AccType of
            AccType::Customer:
                begin
                    SalesSetup.Get();
                    CurrencyAppln := SalesSetup."Appln. between Currencies";
                    case CurrencyAppln of
                        CurrencyAppln::No:
                            begin
                                if ApplnCurrencyCode <> CompareCurrencyCode then
                                    if Message then
                                        Error(Text006);

                                exit(false);
                            end;
                        CurrencyAppln::EMU:
                            begin
                                GLSetup.Get();
                                if not Currency.Get(ApplnCurrencyCode) then
                                    Currency."EMU Currency" := GLSetup."EMU Currency";
                                if not Currency2.Get(CompareCurrencyCode) then
                                    Currency2."EMU Currency" := GLSetup."EMU Currency";
                                if not Currency."EMU Currency" or not Currency2."EMU Currency" then
                                    if Message then
                                        Error(Text007);

                                exit(false);
                            end;
                    end;
                end;
            AccType::Vendor:
                begin
                    PurchSetup.Get();
                    CurrencyAppln := PurchSetup."Appln. between Currencies";
                    case CurrencyAppln of
                        CurrencyAppln::No:
                            begin
                                if ApplnCurrencyCode <> CompareCurrencyCode then
                                    if Message then
                                        Error(Text006);

                                exit(false);
                            end;
                        CurrencyAppln::EMU:
                            begin
                                GLSetup.Get();
                                if not Currency.Get(ApplnCurrencyCode) then
                                    Currency."EMU Currency" := GLSetup."EMU Currency";
                                if not Currency2.Get(CompareCurrencyCode) then
                                    Currency2."EMU Currency" := GLSetup."EMU Currency";
                                if not Currency."EMU Currency" or not Currency2."EMU Currency" then
                                    if Message then
                                        Error(Text007);

                                exit(false);
                            end;
                    end;
                end;
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetCurrency()
    begin
        if GenJnlLine."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get(GenJnlLine."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteApply(Rec: Record "Payment Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteApply(Rec, CustLedgEntry, VendLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if Rec."Applies-to ID" = '' then
            exit;

        case Rec."Account Type" of
            Rec."Account Type"::Customer:
                begin
                    CustLedgEntry.Init();
                    CustLedgEntry.SetCurrentKey("Applies-to ID");
                    if Rec."Applies-to Doc. No." <> '' then begin
                        CustLedgEntry.SetRange("Document No.", Rec."Applies-to Doc. No.");
                        CustLedgEntry.SetRange("Document Type", Rec."Applies-to Doc. Type");
                    end;
                    CustLedgEntry.SetRange("Applies-to ID", Rec."Applies-to ID");
                    OnDeleteApplyOnBeforeCustLedgEntryModifyAll(Rec, CustLedgEntry);
                    CustLedgEntry.ModifyAll("Applies-to ID", '');
                end;
            Rec."Account Type"::Vendor:
                begin
                    VendLedgEntry.Init();
                    VendLedgEntry.SetCurrentKey("Applies-to ID");
                    if Rec."Applies-to Doc. No." <> '' then begin
                        VendLedgEntry.SetRange("Document No.", Rec."Applies-to Doc. No.");
                        VendLedgEntry.SetRange("Document Type", Rec."Applies-to Doc. Type");
                    end;
                    VendLedgEntry.SetRange("Applies-to ID", Rec."Applies-to ID");
                    OnDeleteApplyOnBeforeVendLedgEntryModifyAll(Rec, VendLedgEntry);
                    VendLedgEntry.ModifyAll("Applies-to ID", '');
                end;
        end;
    end;

    local procedure ConfirmAndCheckApplnCurrency(var GenJnlLine: Record "Gen. Journal Line"; Question: Text; CurrencyCode: Code[10]; AccountType: Option)
    begin
        if GenJnlLine."Currency Code" <> CurrencyCode2 then
            if GenJnlLine.Amount = 0 then begin
                if not Confirm(Question, true, GenJnlLine.FieldCaption("Currency Code"), GenJnlLine.TableCaption(), GenJnlLine."Currency Code", CurrencyCode) then
                    Error(Text003);
                GenJnlLine."Currency Code" := CurrencyCode
            end else
                CheckAgainstApplnCurrency(GenJnlLine."Currency Code", CurrencyCode, AccountType, true);
    end;

    local procedure GetAppliesToID(AppliesToID: Code[50]; PaymentLine: Record "Payment Line"): Code[50]
    begin
        if AppliesToID = '' then
            if PaymentLine."Document No." <> '' then
                AppliesToID := PaymentLine."No." + '/' + PaymentLine."Document No."
            else
                AppliesToID := PaymentLine."No." + '/' + Format(PaymentLine."Line No.");
        exit(AppliesToID);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApply(GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyCustomer(CustLedgEntry: Record "Cust. Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyVendor(VendLedgEntry: Record "Vendor Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteApply(Rec: Record "Payment Line"; CustLedgEntry: Record "Cust. Ledger Entry"; VendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteApplyOnBeforeCustLedgEntryModifyAll(PaymentLine: Record "Payment Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteApplyOnBeforeVendLedgEntryModifyAll(PaymentLine: Record "Payment Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;
}

