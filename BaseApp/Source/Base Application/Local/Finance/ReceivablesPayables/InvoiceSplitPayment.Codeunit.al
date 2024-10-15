// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.Setup;

codeunit 7000005 "Invoice-Split Payment"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'Sales %1 no. %2 cannot be posted, because the due date field for one or more installments is more than the legal limit of %3 days after the document date %4 for the original document.';
        Text002: Label 'Purchase %1 no. %2 cannot be posted, because the due date field for one or more installments is more than the legal limit of %3 days after the document date %4 for the original document.';
        Text003: Label 'Service %1 no. %2 cannot be posted, because the due date field for one or more installments is more than the legal limit of %3 days after the document date %4 for the original document.';
        Text1100000: Label 'You cannot select a bill-based %1 for a Credit memo.';
        Text1100001: Label '%1 must be 1 if %2 is True in %3';
        Text1100002: Label 'Transfer of Invoice %1 into bills';
        Text1100003: Label 'Unrealized VAT Type must be "Percentage" in VAT Posting Setup.';
        Text1100004: Label 'Bill %1/%2';
        Text1100005: Label 'The sum of %1 cannot be greater then 100 in the installments for %2 %3.';
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        ServSetup: Record "Service Mgt. Setup";
        Currency: Record Currency;
        CurrencyExchRate: Record "Currency Exchange Rate";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DueDateAdjust: Codeunit "Due Date-Adjust";
        Installment: Record Installment;
        CurrencyFactor: Decimal;
        VATAmountLCY: Decimal;
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
        RemainingAmount: Decimal;
        RemainingAmountLCY: Decimal;
        NextDueDate: Date;
        CurrDocNo: Integer;
        TotalPerc: Decimal;
        ExistsVATNoReal: Boolean;
        ErrorMessage: Boolean;

#if not CLEAN23
    [Obsolete('Use the SplitSalesInv with additional parameter HideProgressWindow instead', '23.0')]
    procedure SplitSalesInv(var SalesHeader: Record "Sales Header"; var CustLedgEntry: Record "Cust. Ledger Entry"; var Window: Dialog; SourceCode: Code[10]; GenJnlLineExtDocNo: Code[35]; GenJnlLineDocNo: Code[20]; VATAmount: Decimal)
    begin
        SplitSalesInv(SalesHeader, CustLedgEntry, Window, SourceCode, GenJnlLineExtDocNo, GenJnlLineDocNo, VATAmount, false);
    end;
#endif

    procedure SplitSalesInv(var SalesHeader: Record "Sales Header"; var CustLedgEntry: Record "Cust. Ledger Entry"; var Window: Dialog; SourceCode: Code[10]; GenJnlLineExtDocNo: Code[35]; GenJnlLineDocNo: Code[20]; VATAmount: Decimal; HideProgressWindow: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SepaDirectDebitMandate: Record "SEPA Direct Debit Mandate";
        BillNo: Integer;
        IsHandled: Boolean;
    begin
        with SalesHeader do begin
            if not PaymentMethod.Get("Payment Method Code") then
                exit;
            if (not PaymentMethod."Create Bills") and (not PaymentMethod."Invoices to Cartera") then
                exit;
            IsHandled := false;
            OnSplitSalesInvOnBeforeCheckPaymentMethod(SalesHeader, PaymentMethod, PaymentTerms, IsHandled);
            if not IsHandled then
                if PaymentMethod."Create Bills" and ("Document Type" = "Document Type"::"Credit Memo") then
                    Error(Text1100000, FieldCaption("Payment Method Code"));

            if "Currency Code" = '' then
                CurrencyFactor := 1
            else
                CurrencyFactor := "Currency Factor";

            GLSetup.Get();
            SalesSetup.Get();
            TestField("Payment Terms Code");
            PaymentTerms.Get("Payment Terms Code");
            PaymentTerms.CalcFields("No. of Installments");
            if PaymentTerms."No. of Installments" = 0 then
                PaymentTerms."No. of Installments" := 1;
            IsHandled := false;
            OnSplitSalesInvOnBeforeCheckPaymentMethod(SalesHeader, PaymentMethod, PaymentTerms, IsHandled);
            if not IsHandled then
                if PaymentMethod."Invoices to Cartera" and (PaymentTerms."No. of Installments" > 1) then
                    Error(
                      Text1100001,
                      PaymentTerms.FieldCaption("No. of Installments"),
                      PaymentMethod.FieldCaption("Invoices to Cartera"),
                      PaymentMethod.TableCaption());
            CustLedgEntry.Find('+');
            CustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
            if CustLedgEntry."Remaining Amount" = 0 then
                exit;

            TotalAmount := CustLedgEntry."Remaining Amount";
            TotalAmountLCY := CustLedgEntry."Remaining Amt. (LCY)";
            RemainingAmount := TotalAmount;
            RemainingAmountLCY := TotalAmountLCY;

            // close invoice entry
            if PaymentMethod."Create Bills" then begin
                GenJnlLine.Init();
                GenJnlLine."Posting Date" := "Posting Date";
                GenJnlLine."Document Date" := "Document Date";
                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
                GenJnlLine.Validate("Account No.", "Bill-to Customer No.");
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                GenJnlLine."Document No." := GenJnlLineDocNo;
                GenJnlLine.Description := CopyStr(StrSubstNo(Text1100002, GenJnlLineDocNo), 1, MaxStrLen(GenJnlLine.Description));
                GenJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := "Dimension Set ID";
                GenJnlLine."Direct Debit Mandate ID" := "Direct Debit Mandate ID";
                GenJnlLine."Reason Code" := "Reason Code";
                GenJnlLine."External Document No." := GenJnlLineExtDocNo;
                GenJnlLine.Validate("Currency Code", "Currency Code");
                GenJnlLine.Amount := -TotalAmount;
                GenJnlLine."Amount (LCY)" := -TotalAmountLCY;
                GenJnlLine."System-Created Entry" := true;
                GenJnlLine."On Hold" := "On Hold";
                GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
                GenJnlLine."Applies-to Doc. No." := GenJnlLineDocNo;
                GenJnlLine."Source Code" := SourceCode;
                GenJnlLine."Currency Factor" := CurrencyFactor;
                GenJnlLine."Payment Terms Code" := "Payment Terms Code";
                GenJnlLine."Payment Method Code" := "Payment Method Code";
#if not CLEAN22
                GenJnlLine."Pmt. Address Code" := "Pay-at Code";
#endif
                if SepaDirectDebitMandate.Get("Direct Debit Mandate ID") then
                    GenJnlLine."Recipient Bank Account" := SepaDirectDebitMandate."Customer Bank Account Code"
                else
                    GenJnlLine."Recipient Bank Account" := "Cust. Bank Acc. Code";
                GenJnlLine."Salespers./Purch. Code" := "Salesperson Code";

                if GLSetup."Unrealized VAT" then begin
                    FindCustVATSetup(VATPostingSetup, SalesHeader);
                    if ErrorMessage then
                        Error(Text1100003);
                end;

                OnBeforeSplitSalesInvCloseEntry(GenJnlLine, SalesHeader);

                if GLSetup."Unrealized VAT" and ExistsVATNoReal then
                    GenJnlLine2.Copy(GenJnlLine)
                else
                    GenJnlPostLine.Run(GenJnlLine);
            end;

            // create bills
            if "Currency Code" = '' then begin
                Currency."Invoice Rounding Precision" := GLSetup."Inv. Rounding Precision (LCY)";
                Currency."Invoice Rounding Type" := GLSetup."Inv. Rounding Type (LCY)";
                Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";
                if SalesSetup."Invoice Rounding" then
                    GLSetup.TestField("Inv. Rounding Precision (LCY)")
                else
                    GLSetup.TestField("Amount Rounding Precision");
            end else begin
                Currency.Get("Currency Code");
                if SalesSetup."Invoice Rounding" then
                    Currency.TestField("Invoice Rounding Precision")
                else
                    Currency.TestField("Amount Rounding Precision");
            end;
            TotalAmount := RoundReceivableAmt(TotalAmount);

            VATAmountLCY := RoundReceivableAmtLCY(VATAmount / CurrencyFactor);

            if PaymentTerms."No. of Installments" > 0 then begin
                Installment.SetRange("Payment Terms Code", PaymentTerms.Code);
                if Installment.Find('-') then;
            end;

            NextDueDate := "Due Date";

            GenJnlLine.Init();
            GenJnlLine."Posting Date" := "Posting Date";
            GenJnlLine."Document Date" := "Document Date";
            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
            GenJnlLine.Validate("Account No.", "Bill-to Customer No.");
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Bill;
            GenJnlLine."Document No." := GenJnlLineDocNo;
            GenJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            GenJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            GenJnlLine."Dimension Set ID" := "Dimension Set ID";
            GenJnlLine."Direct Debit Mandate ID" := "Direct Debit Mandate ID";
            GenJnlLine."Reason Code" := "Reason Code";
            GenJnlLine."External Document No." := GenJnlLineExtDocNo;
            GenJnlLine.Validate("Currency Code", "Currency Code");
            GenJnlLine."System-Created Entry" := true;
            GenJnlLine."On Hold" := "On Hold";
            GenJnlLine."Source Code" := SourceCode;
            GenJnlLine."Currency Factor" := CurrencyFactor;
            GenJnlLine."Payment Terms Code" := "Payment Terms Code";
            GenJnlLine."Payment Method Code" := "Payment Method Code";
#if not CLEAN22
            GenJnlLine."Pmt. Address Code" := "Pay-at Code";
#endif
            if SepaDirectDebitMandate.Get("Direct Debit Mandate ID") then
                GenJnlLine."Recipient Bank Account" := SepaDirectDebitMandate."Customer Bank Account Code"
            else
                GenJnlLine."Recipient Bank Account" := "Cust. Bank Acc. Code";
            GenJnlLine."Salespers./Purch. Code" := "Salesperson Code";

            CurrDocNo := 1;
            repeat
                if not HideProgressWindow then
                    Window.Update(6, CurrDocNo);
                GenJnlLine."Due Date" := NextDueDate;
                CheckSalesDueDate(SalesHeader, GenJnlLine."Due Date", PaymentTerms."Max. No. of Days till Due Date");
                if not "Due Date Modified" then
                    DueDateAdjust.SalesAdjustDueDate(
                      GenJnlLine."Due Date", "Document Date", PaymentTerms.CalculateMaxDueDate("Document Date"), "Bill-to Customer No.");
                NextDueDate := GenJnlLine."Due Date";
                if CurrDocNo < PaymentTerms."No. of Installments" then begin
                    Installment.TestField("% of Total");
                    if CurrDocNo = 1 then begin
                        TotalPerc := Installment."% of Total";
                        case PaymentTerms."VAT distribution" of
                            PaymentTerms."VAT distribution"::"First Installment":
                                begin
                                    GenJnlLine.Amount := RoundReceivableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100 + VATAmount);
                                    GenJnlLine."Amount (LCY)" :=
                                      RoundReceivableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                            PaymentTerms."VAT distribution"::"Last Installment":
                                begin
                                    GenJnlLine.Amount := RoundReceivableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100);
                                    GenJnlLine."Amount (LCY)" :=
                                      RoundReceivableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                            PaymentTerms."VAT distribution"::Proportional:
                                begin
                                    GenJnlLine.Amount := RoundReceivableAmt(TotalAmount * Installment."% of Total" / 100);
                                    GenJnlLine."Amount (LCY)" :=
                                      RoundReceivableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                        end;
                    end else begin
                        TotalPerc := TotalPerc + Installment."% of Total";
                        if TotalPerc >= 100 then
                            Error(
                              Text1100005,
                              Installment.FieldCaption("% of Total"),
                              PaymentTerms.TableCaption(),
                              PaymentTerms.Code);
                        case PaymentTerms."VAT distribution" of
                            PaymentTerms."VAT distribution"::"First Installment",
                            PaymentTerms."VAT distribution"::"Last Installment":
                                begin
                                    GenJnlLine.Amount := RoundReceivableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100);
                                    GenJnlLine."Amount (LCY)" :=
                                      RoundReceivableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                            PaymentTerms."VAT distribution"::Proportional:
                                begin
                                    GenJnlLine.Amount := RoundReceivableAmt(TotalAmount * Installment."% of Total" / 100);
                                    GenJnlLine."Amount (LCY)" :=
                                      RoundReceivableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                        end;
                    end;
                    RemainingAmount := RemainingAmount - GenJnlLine.Amount;
                    RemainingAmountLCY := RemainingAmountLCY - GenJnlLine."Amount (LCY)";
                    OnAfterSplitSalesInvCalculateAmounts(GenJnlLine, SalesHeader, RemainingAmount, RemainingAmountLCY, Installment, CurrDocNo, PaymentTerms);
                    Installment.TestField("Gap between Installments");
                    NextDueDate := CalculateDate(Installment."Gap between Installments", NextDueDate);
                    Installment.Next();
                end else begin
                    GenJnlLine.Amount := RemainingAmount;
                    GenJnlLine."Amount (LCY)" := RemainingAmountLCY;
                end;

                OnBeforeSplitSalesInvCreateBills(GenJnlLine, SalesHeader, Installment, CurrDocNo, PaymentTerms, RemainingAmount, RemainingAmountLCY);

                if PaymentMethod."Create Bills" and ((GenJnlLine.Amount <> 0) or (GenJnlLine."Amount (LCY)" <> 0)) then begin
                    BillNo += 1;
                    GenJnlLine."Bill No." := Format(BillNo);
                    GenJnlLine.Description :=
                      CopyStr(
                        StrSubstNo(Text1100004, GenJnlLineDocNo, BillNo),
                        1,
                        MaxStrLen(GenJnlLine.Description));
                    GenJnlPostLine.Run(GenJnlLine);
                end;
                CurrDocNo += 1;
            until (CurrDocNo > PaymentTerms."No. of Installments") or (RemainingAmount = 0);

            if GLSetup."Unrealized VAT" and ExistsVATNoReal then
                GenJnlPostLine.Run(GenJnlLine2);
        end;
    end;

    procedure SplitPurchInv(var PurchHeader: Record "Purchase Header"; var VendLedgEntry: Record "Vendor Ledger Entry"; var Window: Dialog; SourceCode: Code[10]; GenJnlLineExtDocNo: Code[35]; GenJnlLineDocNo: Code[20]; VATAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        BillNo: Integer;
        IsHandled: Boolean;
    begin
        with PurchHeader do begin
            if not PaymentMethod.Get("Payment Method Code") then
                exit;
            if (not PaymentMethod."Create Bills") and (not PaymentMethod."Invoices to Cartera") then
                exit;
            IsHandled := false;
            OnSplitPurchInvOnBeforeCheckPaymentMethod(PurchHeader, PaymentMethod, PaymentTerms, IsHandled);
            if not IsHandled then
                if PaymentMethod."Create Bills" and ("Document Type" = "Document Type"::"Credit Memo") then
                    Error(
                      Text1100000,
                      FieldCaption("Payment Method Code"));

            if "Currency Code" = '' then
                CurrencyFactor := 1
            else
                CurrencyFactor := "Currency Factor";

            GLSetup.Get();
            PurchSetup.Get();
            TestField("Payment Terms Code");
            PaymentTerms.Get("Payment Terms Code");
            PaymentTerms.CalcFields("No. of Installments");
            if PaymentTerms."No. of Installments" = 0 then
                PaymentTerms."No. of Installments" := 1;
            IsHandled := false;
            OnSplitPurchInvOnBeforeCheckPaymentMethod(PurchHeader, PaymentMethod, PaymentTerms, IsHandled);
            if not IsHandled then
                if PaymentMethod."Invoices to Cartera" and (PaymentTerms."No. of Installments" > 1) then
                    Error(
                      Text1100001,
                      PaymentTerms.FieldCaption("No. of Installments"),
                      PaymentMethod.FieldCaption("Invoices to Cartera"),
                      PaymentMethod.TableCaption());
            VendLedgEntry.Find('+');
            VendLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
            if VendLedgEntry."Remaining Amount" = 0 then
                exit;
            TotalAmount := VendLedgEntry."Remaining Amount";
            TotalAmountLCY := VendLedgEntry."Remaining Amt. (LCY)";
            RemainingAmount := VendLedgEntry."Remaining Amount";
            RemainingAmountLCY := VendLedgEntry."Remaining Amt. (LCY)";

            // close invoice entry
            if PaymentMethod."Create Bills" then begin
                GenJnlLine.Init();
                GenJnlLine."Posting Date" := "Posting Date";
                GenJnlLine."Document Date" := "Document Date";
                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
                GenJnlLine.Validate("Account No.", "Pay-to Vendor No.");
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                GenJnlLine."Document No." := GenJnlLineDocNo;
                GenJnlLine.Description := CopyStr(StrSubstNo(Text1100002, GenJnlLineDocNo), 1, MaxStrLen(GenJnlLine.Description));
                GenJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := "Dimension Set ID";
                GenJnlLine."Reason Code" := "Reason Code";
                GenJnlLine."External Document No." := GenJnlLineExtDocNo;
                GenJnlLine.Validate("Currency Code", "Currency Code");
                GenJnlLine.Amount := -TotalAmount;
                GenJnlLine."Amount (LCY)" := -TotalAmountLCY;
                GenJnlLine."System-Created Entry" := true;
                GenJnlLine."On Hold" := "On Hold";
                GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
                GenJnlLine."Applies-to Doc. No." := GenJnlLineDocNo;
                GenJnlLine."Source Code" := SourceCode;
                GenJnlLine."Currency Factor" := CurrencyFactor;
                GenJnlLine."Payment Terms Code" := "Payment Terms Code";
                GenJnlLine."Payment Method Code" := "Payment Method Code";
#if not CLEAN22
                GenJnlLine."Pmt. Address Code" := "Pay-at Code";
#endif
                GenJnlLine."Recipient Bank Account" := "Vendor Bank Acc. Code";
                GenJnlLine."Salespers./Purch. Code" := "Purchaser Code";

                if GLSetup."Unrealized VAT" then begin
                    FindVendVATSetup(VATPostingSetup, PurchHeader);
                    if ErrorMessage then
                        Error(Text1100003);
                end;

                OnBeforeSplitPurchInvCloseEntry(GenJnlLine, PurchHeader);

                if GLSetup."Unrealized VAT" and ExistsVATNoReal then begin
                    GenJnlLine2.Copy(GenJnlLine);
                end else
                    GenJnlPostLine.Run(GenJnlLine);
            end;
            // create bills
            if "Currency Code" = '' then begin
                Currency."Invoice Rounding Precision" := GLSetup."Inv. Rounding Precision (LCY)";
                Currency."Invoice Rounding Type" := GLSetup."Inv. Rounding Type (LCY)";
                Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";
                if PurchSetup."Invoice Rounding" then
                    GLSetup.TestField("Inv. Rounding Precision (LCY)")
                else
                    GLSetup.TestField("Amount Rounding Precision");
            end else begin
                Currency.Get("Currency Code");
                if SalesSetup."Invoice Rounding" then
                    Currency.TestField("Invoice Rounding Precision")
                else
                    Currency.TestField("Amount Rounding Precision");
            end;
            TotalAmount := RoundPayableAmt(TotalAmount);

            VATAmountLCY := RoundPayableAmtLCY(VATAmount / CurrencyFactor);

            if PaymentTerms."No. of Installments" > 0 then begin
                Installment.SetRange("Payment Terms Code", PaymentTerms.Code);
                if Installment.Find('-') then;
            end;

            NextDueDate := "Due Date";

            GenJnlLine.Init();
            GenJnlLine."Posting Date" := "Posting Date";
            GenJnlLine."Document Date" := "Document Date";
            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
            GenJnlLine.Validate("Account No.", "Pay-to Vendor No.");
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Bill;
            GenJnlLine."Document No." := GenJnlLineDocNo;
            GenJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            GenJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            GenJnlLine."Dimension Set ID" := "Dimension Set ID";
            GenJnlLine."Reason Code" := "Reason Code";
            GenJnlLine."External Document No." := GenJnlLineExtDocNo;
            GenJnlLine.Validate("Currency Code", "Currency Code");
            GenJnlLine."System-Created Entry" := true;
            GenJnlLine."On Hold" := "On Hold";
            GenJnlLine."Source Code" := SourceCode;
            GenJnlLine."Currency Factor" := CurrencyFactor;
            GenJnlLine."Payment Terms Code" := "Payment Terms Code";
            GenJnlLine."Payment Method Code" := "Payment Method Code";
#if not CLEAN22
            GenJnlLine."Pmt. Address Code" := "Pay-at Code";
#endif
            GenJnlLine."Recipient Bank Account" := "Vendor Bank Acc. Code";
            GenJnlLine."Salespers./Purch. Code" := "Purchaser Code";

            CurrDocNo := 1;
            repeat
                Window.Update(6, CurrDocNo);
                GenJnlLine."Due Date" := NextDueDate;
                CheckPurchDueDate(PurchHeader, GenJnlLine."Due Date", PaymentTerms."Max. No. of Days till Due Date");
                if not "Due Date Modified" then
                    DueDateAdjust.PurchAdjustDueDate(
                      GenJnlLine."Due Date", "Document Date", PaymentTerms.CalculateMaxDueDate("Document Date"), "Pay-to Vendor No.");
                NextDueDate := GenJnlLine."Due Date";
                if CurrDocNo < PaymentTerms."No. of Installments" then begin
                    Installment.TestField("% of Total");
                    OnBeforeSplitPurchInvCalculateAmounts(GenJnlLine, PurchHeader, TotalAmount, VATAmount, TotalAmountLCY, VATAmountLCY);
                    if CurrDocNo = 1 then begin
                        TotalPerc := Installment."% of Total";
                        case PaymentTerms."VAT distribution" of
                            PaymentTerms."VAT distribution"::"First Installment":
                                begin
                                    GenJnlLine.Amount := RoundPayableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100 + VATAmount);
                                    GenJnlLine."Amount (LCY)" :=
                                      RoundPayableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                            PaymentTerms."VAT distribution"::"Last Installment":
                                begin
                                    GenJnlLine.Amount := RoundPayableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100);
                                    GenJnlLine."Amount (LCY)" :=
                                      RoundPayableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                            PaymentTerms."VAT distribution"::Proportional:
                                begin
                                    GenJnlLine.Amount := RoundPayableAmt(TotalAmount * Installment."% of Total" / 100);
                                    GenJnlLine."Amount (LCY)" :=
                                      RoundPayableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                        end;
                    end else begin
                        TotalPerc := TotalPerc + Installment."% of Total";
                        if TotalPerc >= 100 then
                            Error(
                              Text1100005,
                              Installment.FieldCaption("% of Total"),
                              PaymentTerms.TableCaption(),
                              PaymentTerms.Code);
                        case PaymentTerms."VAT distribution" of
                            PaymentTerms."VAT distribution"::"First Installment",
                            PaymentTerms."VAT distribution"::"Last Installment":
                                begin
                                    GenJnlLine.Amount := RoundPayableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100);
                                    GenJnlLine."Amount (LCY)" := RoundPayableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                            PaymentTerms."VAT distribution"::Proportional:
                                begin
                                    GenJnlLine.Amount := RoundPayableAmt(TotalAmount * Installment."% of Total" / 100);
                                    GenJnlLine."Amount (LCY)" := RoundPayableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                        end;
                    end;
                    RemainingAmount := RemainingAmount - GenJnlLine.Amount;
                    RemainingAmountLCY := RemainingAmountLCY - GenJnlLine."Amount (LCY)";
                    OnAfterSplitPurchInvCalculateAmounts(GenJnlLine, PurchHeader, RemainingAmount, RemainingAmountLCY);
                    Installment.TestField("Gap between Installments");
                    NextDueDate := CalculateDate(Installment."Gap between Installments", NextDueDate);
                    Installment.Next();
                end else begin
                    GenJnlLine.Amount := RemainingAmount;
                    GenJnlLine."Amount (LCY)" := RemainingAmountLCY;
                end;

                OnBeforeSplitPurchInvCreateBills(GenJnlLine, PurchHeader);

                if PaymentMethod."Create Bills" and ((GenJnlLine.Amount <> 0) or (GenJnlLine."Amount (LCY)" <> 0)) then begin
                    BillNo += 1;
                    GenJnlLine."Bill No." := Format(BillNo);
                    GenJnlLine.Description :=
                      CopyStr(
                        StrSubstNo(Text1100004, GenJnlLineDocNo, BillNo),
                        1,
                        MaxStrLen(GenJnlLine.Description));
                    GenJnlPostLine.Run(GenJnlLine);
                end;
                CurrDocNo += 1;
            until (CurrDocNo > PaymentTerms."No. of Installments") or (RemainingAmount = 0);

            if GLSetup."Unrealized VAT" and ExistsVATNoReal then
                GenJnlPostLine.Run(GenJnlLine2);
        end;
    end;

    procedure RoundReceivableAmt(Amount: Decimal): Decimal
    begin
        if SalesSetup."Invoice Rounding" then
            Amount := Round(Amount, Currency."Invoice Rounding Precision", SelectStr(Currency."Invoice Rounding Type" + 1, '=,>,<'))
        else
            Amount := Round(Amount, Currency."Amount Rounding Precision");

        exit(Amount);
    end;

    procedure RoundReceivableAmtLCY(Amount: Decimal): Decimal
    begin
        if SalesSetup."Invoice Rounding" then
            Amount := Round(Amount, GLSetup."Inv. Rounding Precision (LCY)", SelectStr(GLSetup."Inv. Rounding Type (LCY)" + 1, '=,>,<'))
        else
            Amount := Round(Amount, GLSetup."Amount Rounding Precision");

        exit(Amount);
    end;

    procedure RoundPayableAmt(Amount: Decimal): Decimal
    begin
        if SalesSetup."Invoice Rounding" then
            Amount := Round(Amount, Currency."Invoice Rounding Precision", SelectStr(Currency."Invoice Rounding Type" + 1, '=,>,<'))
        else
            Amount := Round(Amount, Currency."Amount Rounding Precision");

        exit(Amount);
    end;

    procedure RoundPayableAmtLCY(Amount: Decimal): Decimal
    begin
        if SalesSetup."Invoice Rounding" then
            Amount := Round(Amount, GLSetup."Inv. Rounding Precision (LCY)", SelectStr(GLSetup."Inv. Rounding Type (LCY)" + 1, '=,>,<'))
        else
            Amount := Round(Amount, GLSetup."Amount Rounding Precision");

        exit(Amount);
    end;

    procedure FindCustVATSetup(var VATSetup: Record "VAT Posting Setup"; SalesHeader2: Record "Sales Header")
    var
        Customer: Record Customer;
        PostingGroup: Code[20];
        SalesLine2: Record "Sales Line";
    begin
        Customer.Get(SalesHeader2."Bill-to Customer No.");

        VATSetup.SetCurrentKey("VAT Bus. Posting Group", "VAT Prod. Posting Group");
        VATSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");

        SalesLine2.SetCurrentKey("Document Type", "Document No.", "Line No.");
        SalesLine2.SetRange("Document Type", SalesHeader2."Document Type");
        SalesLine2.SetRange("Document No.", SalesHeader2."No.");
        SalesLine2.Find('-');

        repeat
            case SalesLine2.Type of
                SalesLine2.Type::Item:
                    begin
                        PostingGroup := SalesLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
                SalesLine2.Type::Resource:
                    begin
                        PostingGroup := SalesLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
                SalesLine2.Type::"G/L Account":
                    begin
                        PostingGroup := SalesLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
            end;
        until SalesLine2.Next() = 0;
    end;

    procedure FindVendVATSetup(var VATSetup: Record "VAT Posting Setup"; PurchHeader2: Record "Purchase Header")
    var
        PostingGroup: Code[20];
        PurchLine2: Record "Purchase Line";
    begin
        VATSetup.SetCurrentKey("VAT Bus. Posting Group", "VAT Prod. Posting Group");
        VATSetup.SetRange("VAT Bus. Posting Group", PurchHeader2."VAT Bus. Posting Group");

        PurchLine2.SetCurrentKey("Document Type", "Document No.", "Line No.");
        PurchLine2.SetRange("Document Type", PurchHeader2."Document Type");
        PurchLine2.SetRange("Document No.", PurchHeader2."No.");
        PurchLine2.Find('-');

        repeat
            case PurchLine2.Type of
                PurchLine2.Type::Item:
                    begin
                        PostingGroup := PurchLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
                PurchLine2.Type::"G/L Account":
                    begin
                        PostingGroup := PurchLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
            end;
        until PurchLine2.Next() = 0;
    end;

    procedure SplitServiceInv(var ServiceHeader: Record "Service Header"; var CustLedgEntry: Record "Cust. Ledger Entry"; var Window: Dialog; SourceCode: Code[10]; GenJnlLineExtDocNo: Code[35]; GenJnlLineDocNo: Code[20]; VATAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        BillNo: Integer;
    begin
        with ServiceHeader do begin
            if not PaymentMethod.Get("Payment Method Code") then
                exit;
            if (not PaymentMethod."Create Bills") and (not PaymentMethod."Invoices to Cartera") then
                exit;
            if PaymentMethod."Create Bills" and ("Document Type" = "Document Type"::"Credit Memo") then
                Error(
                  Text1100000,
                  FieldCaption("Payment Method Code"));

            if "Currency Code" = '' then
                CurrencyFactor := 1
            else
                CurrencyFactor := "Currency Factor";

            GLSetup.Get();
            ServSetup.Get();
            TestField("Payment Terms Code");
            PaymentTerms.Get("Payment Terms Code");
            PaymentTerms.CalcFields("No. of Installments");
            if PaymentTerms."No. of Installments" = 0 then
                PaymentTerms."No. of Installments" := 1;
            if PaymentMethod."Invoices to Cartera" and (PaymentTerms."No. of Installments" > 1) then
                Error(
                  Text1100001,
                  PaymentTerms.FieldCaption("No. of Installments"),
                  PaymentMethod.FieldCaption("Invoices to Cartera"),
                  PaymentMethod.TableCaption());
            CustLedgEntry.Find('+');
            CustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
            if CustLedgEntry."Remaining Amount" = 0 then
                exit;
            TotalAmount := CustLedgEntry."Remaining Amount";
            TotalAmountLCY := CustLedgEntry."Remaining Amt. (LCY)";
            RemainingAmount := TotalAmount;
            RemainingAmountLCY := TotalAmountLCY;

            // close invoice entry
            if PaymentMethod."Create Bills" then begin
                GenJnlLine.Init();
                GenJnlLine."Posting Date" := "Posting Date";
                GenJnlLine."Document Date" := "Document Date";
                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
                GenJnlLine.Validate("Account No.", "Bill-to Customer No.");
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                GenJnlLine."Document No." := GenJnlLineDocNo;
                GenJnlLine.Description :=
                  CopyStr(StrSubstNo(Text1100002, GenJnlLineDocNo), 1, MaxStrLen(GenJnlLine.Description));
                GenJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := "Dimension Set ID";
                GenJnlLine."Reason Code" := "Reason Code";
                GenJnlLine."External Document No." := GenJnlLineExtDocNo;
                GenJnlLine.Validate("Currency Code", "Currency Code");
                GenJnlLine.Amount := -TotalAmount;
                GenJnlLine."Amount (LCY)" := -TotalAmountLCY;
                GenJnlLine."System-Created Entry" := true;
                GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
                GenJnlLine."Applies-to Doc. No." := GenJnlLineDocNo;
                GenJnlLine."Source Code" := SourceCode;
                GenJnlLine."Currency Factor" := CurrencyFactor;
                GenJnlLine."Payment Method Code" := "Payment Method Code";
#if not CLEAN22
                GenJnlLine."Pmt. Address Code" := "Pay-at Code";
#endif
                GenJnlLine."Recipient Bank Account" := "Cust. Bank Acc. Code";
                GenJnlLine."Salespers./Purch. Code" := "Salesperson Code";

                if GLSetup."Unrealized VAT" then begin
                    FindCustVATSetupServ(VATPostingSetup, ServiceHeader);
                    if ErrorMessage then
                        Error(Text1100003);
                end;

                OnBeforeSplitServInvCloseEntry(GenJnlLine, ServiceHeader);

                if GLSetup."Unrealized VAT" and ExistsVATNoReal then begin
                    GenJnlLine2.Copy(GenJnlLine);
                end else
                    GenJnlPostLine.Run(GenJnlLine);
            end;

            // create bills
            if "Currency Code" = '' then begin
                Currency."Invoice Rounding Precision" := GLSetup."Inv. Rounding Precision (LCY)";
                Currency."Invoice Rounding Type" := GLSetup."Inv. Rounding Type (LCY)";
                Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";
            end else
                Currency.Get("Currency Code");
            TotalAmount := RoundReceivableAmt(TotalAmount);

            VATAmountLCY := RoundReceivableAmtLCY(VATAmount / CurrencyFactor);

            if PaymentTerms."No. of Installments" > 0 then begin
                Installment.SetRange("Payment Terms Code", PaymentTerms.Code);
                if Installment.Find('-') then;
            end;

            NextDueDate := "Due Date";

            GenJnlLine.Init();
            GenJnlLine."Posting Date" := "Posting Date";
            GenJnlLine."Document Date" := "Document Date";
            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
            GenJnlLine.Validate("Account No.", "Bill-to Customer No.");
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Bill;
            GenJnlLine."Document No." := GenJnlLineDocNo;
            GenJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            GenJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            GenJnlLine."Dimension Set ID" := "Dimension Set ID";
            GenJnlLine."Reason Code" := "Reason Code";
            GenJnlLine."External Document No." := GenJnlLineExtDocNo;
            GenJnlLine.Validate("Currency Code", "Currency Code");
            GenJnlLine."System-Created Entry" := true;
            GenJnlLine."Source Code" := SourceCode;
            GenJnlLine."Currency Factor" := CurrencyFactor;
            GenJnlLine."Payment Method Code" := "Payment Method Code";
#if not CLEAN22
            GenJnlLine."Pmt. Address Code" := "Pay-at Code";
#endif
            GenJnlLine."Recipient Bank Account" := "Cust. Bank Acc. Code";
            GenJnlLine."Salespers./Purch. Code" := "Salesperson Code";

            CurrDocNo := 1;
            repeat
                Window.Update(6, CurrDocNo);
                GenJnlLine."Due Date" := NextDueDate;
                CheckServiceDueDate(ServiceHeader, GenJnlLine."Due Date", PaymentTerms."Max. No. of Days till Due Date");
                DueDateAdjust.SalesAdjustDueDate(
                  GenJnlLine."Due Date", "Document Date", PaymentTerms.CalculateMaxDueDate("Document Date"), "Bill-to Customer No.");
                NextDueDate := GenJnlLine."Due Date";
                if CurrDocNo < PaymentTerms."No. of Installments" then begin
                    Installment.TestField("% of Total");
                    if CurrDocNo = 1 then begin
                        TotalPerc := Installment."% of Total";
                        case PaymentTerms."VAT distribution" of
                            PaymentTerms."VAT distribution"::"First Installment":
                                begin
                                    GenJnlLine.Amount := RoundReceivableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100 + VATAmount);
                                    GenJnlLine."Amount (LCY)" :=
                                      RoundReceivableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                            PaymentTerms."VAT distribution"::"Last Installment":
                                begin
                                    GenJnlLine.Amount := RoundReceivableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100);
                                    GenJnlLine."Amount (LCY)" :=
                                      RoundReceivableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                            PaymentTerms."VAT distribution"::Proportional:
                                begin
                                    GenJnlLine.Amount := RoundReceivableAmt(TotalAmount * Installment."% of Total" / 100);
                                    GenJnlLine."Amount (LCY)" :=
                                      RoundReceivableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                        end;
                    end else begin
                        TotalPerc := TotalPerc + Installment."% of Total";
                        if TotalPerc >= 100 then
                            Error(
                              Text1100005,
                              Installment.FieldCaption("% of Total"),
                              PaymentTerms.TableCaption(),
                              PaymentTerms.Code);
                        case PaymentTerms."VAT distribution" of
                            PaymentTerms."VAT distribution"::"First Installment",
                            PaymentTerms."VAT distribution"::"Last Installment":
                                begin
                                    GenJnlLine.Amount := RoundReceivableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100);
                                    GenJnlLine."Amount (LCY)" :=
                                      RoundReceivableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                            PaymentTerms."VAT distribution"::Proportional:
                                begin
                                    GenJnlLine.Amount := RoundReceivableAmt(TotalAmount * Installment."% of Total" / 100);
                                    GenJnlLine."Amount (LCY)" :=
                                      RoundReceivableAmtLCY(
                                        CurrencyExchRate.ExchangeAmtFCYToLCY("Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                                end;
                        end;
                    end;
                    RemainingAmount := RemainingAmount - GenJnlLine.Amount;
                    RemainingAmountLCY := RemainingAmountLCY - GenJnlLine."Amount (LCY)";
                    Installment.TestField("Gap between Installments");
                    NextDueDate := CalculateDate(Installment."Gap between Installments", NextDueDate);
                    Installment.Next();
                end else begin
                    GenJnlLine.Amount := RemainingAmount;
                    GenJnlLine."Amount (LCY)" := RemainingAmountLCY;
                end;

                OnBeforeSplitServInvCreateBills(GenJnlLine, ServiceHeader);

                if PaymentMethod."Create Bills" and ((GenJnlLine.Amount <> 0) or (GenJnlLine."Amount (LCY)" <> 0)) then begin
                    BillNo += 1;
                    GenJnlLine."Bill No." := Format(BillNo);
                    GenJnlLine.Description :=
                      CopyStr(
                        StrSubstNo(Text1100004, GenJnlLineDocNo, BillNo),
                        1,
                        MaxStrLen(GenJnlLine.Description));
                    GenJnlPostLine.Run(GenJnlLine);
                end;
                CurrDocNo += 1;
            until (CurrDocNo > PaymentTerms."No. of Installments") or (RemainingAmount = 0);

            if GLSetup."Unrealized VAT" and ExistsVATNoReal then
                GenJnlPostLine.Run(GenJnlLine2);
        end;
    end;

    procedure FindCustVATSetupServ(var VATSetup: Record "VAT Posting Setup"; ServiceHeader2: Record "Service Header")
    var
        Customer: Record Customer;
        ServiceLine2: Record "Service Line";
        PostingGroup: Code[20];
    begin
        Customer.Get(ServiceHeader2."Bill-to Customer No.");

        VATSetup.SetCurrentKey("VAT Bus. Posting Group", "VAT Prod. Posting Group");
        VATSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");

        ServiceLine2.SetCurrentKey("Document Type", "Document No.", "Line No.");
        ServiceLine2.SetRange("Document Type", ServiceHeader2."Document Type");
        ServiceLine2.SetRange("Document No.", ServiceHeader2."No.");
        ServiceLine2.Find('-');

        repeat
            case ServiceLine2.Type of
                ServiceLine2.Type::Item:
                    begin
                        PostingGroup := ServiceLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
                ServiceLine2.Type::Resource:
                    begin
                        PostingGroup := ServiceLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
                ServiceLine2.Type::"G/L Account":
                    begin
                        PostingGroup := ServiceLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
            end;
        until ServiceLine2.Next() = 0;
    end;

    local procedure CalculateDate(DateFormulaText: Code[20]; DueDate: Date): Date
    var
        DateFormula: DateFormula;
    begin
        Evaluate(DateFormula, DateFormulaText);
        exit(CalcDate(DateFormula, DueDate));
    end;

    procedure CheckDueDate(NewDueDate: Date; InitialDocumentDate: Date; MaxNoOfDays: Integer): Boolean
    var
        MaxAllowedDueDate: Date;
    begin
        if MaxNoOfDays > 0 then begin
            MaxAllowedDueDate := InitialDocumentDate + MaxNoOfDays;
            exit(NewDueDate <= MaxAllowedDueDate);
        end;

        exit(true);
    end;

    local procedure CheckSalesDueDate(SalesHeader: Record "Sales Header"; NewDueDate: Date; MaxNoOfDays: Integer)
    begin
        with SalesHeader do
            if not CheckDueDate(NewDueDate, "Document Date", MaxNoOfDays) then
                Error(Text001, "Document Type", "No.", MaxNoOfDays, "Document Date");
    end;

    local procedure CheckPurchDueDate(PurchaseHeader: Record "Purchase Header"; NewDueDate: Date; MaxNoOfDays: Integer)
    begin
        with PurchaseHeader do
            if not CheckDueDate(NewDueDate, "Document Date", MaxNoOfDays) then
                Error(Text002, "Document Type", "No.", MaxNoOfDays, "Document Date");
    end;

    local procedure CheckServiceDueDate(ServiceHeader: Record "Service Header"; NewDueDate: Date; MaxNoOfDays: Integer)
    begin
        with ServiceHeader do
            if not CheckDueDate(NewDueDate, "Document Date", MaxNoOfDays) then
                Error(Text003, "Document Type", "No.", MaxNoOfDays, "Document Date");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSplitSalesInvCalculateAmounts(var GenJournalLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var RemainingAmount: Decimal; var RemainingAmountLCY: Decimal; Installment: Record Installment; CurrDocNo: Integer; PaymentTerms: Record "Payment Terms")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSplitPurchInvCalculateAmounts(var GenJournalLine: Record "Gen. Journal Line"; var PurchaseHeader: Record "Purchase Header"; var RemainingAmount: Decimal; var RemainingAmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitSalesInvCloseEntry(var GenJournalLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitSalesInvCreateBills(var GenJournalLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; Installment: Record Installment; CurrDocNo: Integer; PaymentTerms: Record "Payment Terms"; RemainingAmount: Decimal; RemainingAmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitPurchInvCalculateAmounts(var GenJournalLine: Record "Gen. Journal Line"; var PurchaseHeader: Record "Purchase Header"; var TotalAmount: Decimal; var VATAmount: Decimal; var TotalAmountLCY: Decimal; var VATAmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitPurchInvCloseEntry(var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitPurchInvCreateBills(var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitServInvCloseEntry(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitServInvCreateBills(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitPurchInvOnBeforeCheckPaymentMethod(var PurchHeader: Record "Purchase Header"; var PaymentMethod: Record "Payment Method"; var PaymentTerms: Record "Payment Terms"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitSalesInvOnBeforeCheckPaymentMethod(var SalesHeader: Record "Sales Header"; var PaymentMethod: Record "Payment Method"; var PaymentTerms: Record "Payment Terms"; var IsHandled: Boolean)
    begin
    end;
}

