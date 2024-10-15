#if not CLEAN23
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 595 "Adjust Exchange Rates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Adjust Exchange Rates';
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "Exch. Rate Adjmt. Reg." = rimd,
                  TableData "VAT Entry" = rimd,
                  TableData "Detailed Cust. Ledg. Entry" = rimd,
                  TableData "Detailed Vendor Ledg. Entry" = rimd;
    ProcessingOnly = true;
    UsageCategory = Tasks;
    ObsoleteReason = 'Replaced by new report 596 "Exch. Rate Adjustment"';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    dataset
    {
        dataitem(Currency; Currency)
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";
            dataitem("Bank Account"; "Bank Account")
            {
                DataItemLink = "Currency Code" = field(Code);
                DataItemTableView = sorting("Bank Acc. Posting Group");
                RequestFilterFields = "No.";
                dataitem(BankAccountGroupTotal; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;

                    trigger OnAfterGetRecord()
                    var
                        BankAccount: Record "Bank Account";
                        GroupTotal: Boolean;
                    begin
                        BankAccount.Copy("Bank Account");
                        if BankAccount.Next() = 1 then begin
                            if BankAccount."Bank Acc. Posting Group" <> "Bank Account"."Bank Acc. Posting Group" then
                                GroupTotal := true;
                        end else
                            GroupTotal := true;

                        if GroupTotal then
                            if TotalAdjAmount <> 0 then begin
                                AdjExchRateBufferUpdate(
                                  "Bank Account"."Currency Code", "Bank Account"."Bank Acc. Posting Group",
                                  TotalAdjBase, TotalAdjBaseLCY, TotalAdjAmount, 0, 0, 0, PostingDate, '', 0);
                                OnAfterAdjExchRateBufferUpdate("Bank Account");
                                InsertExchRateAdjmtReg(
                                    "Exch. Rate Adjmt. Account Type"::"Bank Account", "Bank Account"."Bank Acc. Posting Group", "Bank Account"."Currency Code");
                                TotalBankAccountsAdjusted += 1;
                                ResetTempAdjmtBuffer();
                                TotalAdjBase := 0;
                                TotalAdjBaseLCY := 0;
                                TotalAdjAmount := 0;
                            end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    BankAccNo := BankAccNo + 1;
                    Window.Update(1, Round(BankAccNo / BankAccNoTotal * 10000, 1));

                    TempDimSetEntry.Reset();
                    TempDimSetEntry.DeleteAll();
                    TempDimBuf.Reset();
                    TempDimBuf.DeleteAll();

                    CalcFields("Balance at Date", "Balance at Date (LCY)");
                    CurrAdjBase := "Balance at Date";
                    CurrAdjBaseLCY := "Balance at Date (LCY)";
                    CurrAdjAmount :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCYAdjmt(
                          PostingDate, Currency.Code, "Balance at Date", Currency."Currency Factor")) -
                      "Balance at Date (LCY)";

                    if CurrAdjAmount <> 0 then begin
                        PostBankAccAdjmt("Bank Account");

                        TotalAdjBase := TotalAdjBase + CurrAdjBase;
                        TotalAdjBaseLCY := TotalAdjBaseLCY + CurrAdjBaseLCY;
                        TotalAdjAmount := TotalAdjAmount + CurrAdjAmount;
                        Window.Update(4, TotalAdjAmount);
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if not AdjBank then
                        CurrReport.Break();

                    SetRange("Date Filter", StartDate, EndDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                "Last Date Adjusted" := PostingDate;
                if not TestMode then
                    Modify();

                "Currency Factor" := CurrExchRate.ExchangeRateAdjmt(PostingDate, Code);

                TempCurrencyToAdjust := Currency;
                TempCurrencyToAdjust.Insert();
                if TempCurrencyToAdjust.Conventional then
                    CurrReport.Skip();
            end;

            trigger OnPostDataItem()
            begin
                if (Code = '') and (AdjCust or AdjVend or AdjBank) then
                    Error(Text011Err);
            end;

            trigger OnPreDataItem()
            begin
                CheckPostingDate();
                if EndDate = 0D then
                    Error(Text12401Err);
                if (not AdjCust) and (not AdjVend) and (not AdjBank) then
                    CurrReport.Break();

                GetSelectedDims();

                Window.Open(
                  Text006Txt +
                  Text007Txt +
                  Text008Txt +
                  Text009Txt +
                  Text010Txt);

                CustNoTotal := Customer.Count();
                VendNoTotal := Vendor.Count();
                CopyFilter(Code, "Bank Account"."Currency Code");
                FilterGroup(2);
                "Bank Account".SetFilter("Currency Code", '<>%1', '');
                FilterGroup(0);
                BankAccNoTotal := "Bank Account".Count();
                "Bank Account".Reset();
            end;
        }
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            dataitem(CustomerLedgerEntryLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem("Detailed Cust. Ledg. Entry"; "Detailed Cust. Ledg. Entry")
                {
                    DataItemTableView = sorting("Cust. Ledger Entry No.", "Posting Date");

                    trigger OnAfterGetRecord()
                    begin
                        AdjustCustomerLedgerEntry(CustLedgerEntry, "Posting Date");
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetCurrentKey("Cust. Ledger Entry No.");
                        SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
                        SetFilter("Posting Date", '%1..', CalcDate('<+1D>', PostingDate));
                        if GLSetup."Enable Russian Accounting" then
                            SetRange("Entry Type", "Entry Type"::Application);
                        SetRange("Agreement No.", CustLedgerEntry."Agreement No.");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TempDtldCustLedgEntrySums.DeleteAll();

                    if FirstEntry then begin
                        TempCustLedgerEntry.Find('-');
                        FirstEntry := false
                    end else
                        if TempCustLedgerEntry.Next() = 0 then
                            CurrReport.Break();
                    CustLedgerEntry.Get(TempCustLedgerEntry."Entry No.");
                    if GLSetup."Cancel Prepmt. Adjmt. in TA" and CustLedgerEntry.Prepayment then
                        CurrReport.Skip();
                    CustLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    AdjustCustomerLedgerEntry(CustLedgerEntry, PostingDate);
                    if GLSetup."Cancel Curr. Prepmt. Adjmt." and CustLedgerEntry.Prepayment then
                        CustLedgerEntry."Remaining Amt. (LCY)" := TaxAccRemainingAmt;
                end;

                trigger OnPreDataItem()
                begin
                    if not TempCustLedgerEntry.Find('-') then
                        CurrReport.Break();
                    FirstEntry := true;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CustNo := CustNo + 1;
                Window.Update(2, Round(CustNo / CustNoTotal * 10000, 1));

                PrepareTempCustLedgEntry(Customer, TempCustLedgerEntry);

                OnCustomerAfterGetRecordOnAfterFindCustLedgerEntriesToAdjust(TempCustLedgerEntry);
            end;

            trigger OnPostDataItem()
            begin
                if CustNo <> 0 then
                    if GLSetup."Enable Russian Accounting" then
                        HandlePostAdjmtRU(1)
                    else
                        HandlePostAdjmt(1); // Customer
            end;

            trigger OnPreDataItem()
            begin
                if not AdjCust then
                    CurrReport.Break();

                DtldCustLedgEntry.LockTable();
                CustLedgerEntry.LockTable();

                CustNo := 0;

                if DtldCustLedgEntry.Find('+') then
                    NewEntryNo := DtldCustLedgEntry."Entry No." + 1
                else
                    NewEntryNo := 1;

                Clear(DimMgt);
            end;
        }
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            dataitem(VendorLedgerEntryLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
                {
                    DataItemTableView = sorting("Vendor Ledger Entry No.", "Posting Date");

                    trigger OnAfterGetRecord()
                    begin
                        AdjustVendorLedgerEntry(VendorLedgerEntry, "Posting Date");
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetCurrentKey("Vendor Ledger Entry No.");
                        SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
                        SetFilter("Posting Date", '%1..', CalcDate('<+1D>', PostingDate));
                        if GLSetup."Enable Russian Accounting" then
                            SetRange("Entry Type", "Entry Type"::Application);
                        SetRange("Agreement No.", VendorLedgerEntry."Agreement No.");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TempDtldVendLedgEntrySums.DeleteAll();

                    if FirstEntry then begin
                        TempVendorLedgerEntry.Find('-');
                        FirstEntry := false
                    end else
                        if TempVendorLedgerEntry.Next() = 0 then
                            CurrReport.Break();
                    VendorLedgerEntry.Get(TempVendorLedgerEntry."Entry No.");
                    if GLSetup."Cancel Prepmt. Adjmt. in TA" and VendorLedgerEntry.Prepayment then
                        CurrReport.Skip();
                    VendorLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    AdjustVendorLedgerEntry(VendorLedgerEntry, PostingDate);
                    if GLSetup."Cancel Curr. Prepmt. Adjmt." and VendorLedgerEntry.Prepayment then
                        VendorLedgerEntry."Remaining Amt. (LCY)" := TaxAccRemainingAmt;
                end;

                trigger OnPreDataItem()
                begin
                    if not TempVendorLedgerEntry.Find('-') then
                        CurrReport.Break();
                    FirstEntry := true;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                VendNo := VendNo + 1;
                Window.Update(3, Round(VendNo / VendNoTotal * 10000, 1));

                PrepareTempVendLedgEntry(Vendor, TempVendorLedgerEntry);

                OnVendorAfterGetRecordOnAfterFindVendLedgerEntriesToAdjust(TempVendorLedgerEntry);
            end;

            trigger OnPostDataItem()
            begin
                if VendNo <> 0 then
                    if GLSetup."Enable Russian Accounting" then
                        HandlePostAdjmtRU(2)
                    else
                        HandlePostAdjmt(2); // Vendor
            end;

            trigger OnPreDataItem()
            begin
                if not AdjVend then
                    CurrReport.Break();

                DtldVendLedgEntry.LockTable();
                VendorLedgerEntry.LockTable();

                VendNo := 0;
                if DtldVendLedgEntry.Find('+') then
                    NewEntryNo := DtldVendLedgEntry."Entry No." + 1
                else
                    NewEntryNo := 1;

                Clear(DimMgt);
            end;
        }
        dataitem("VAT Posting Setup"; "VAT Posting Setup")
        {
            DataItemTableView = sorting("VAT Bus. Posting Group", "VAT Prod. Posting Group");

            trigger OnAfterGetRecord()
            begin
                VATEntryNo := VATEntryNo + 1;
                Window.Update(1, 10000 * VATEntryNo div VATEntryNoTotal);

                VATEntry.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                VATEntry.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");

                if "VAT Calculation Type" <> "VAT Calculation Type"::"Sales Tax" then begin
                    AdjustVATEntries(VATEntry.Type::Purchase, false);
                    if (VATEntry2.Amount <> 0) or (VATEntry2."Additional-Currency Amount" <> 0) then begin
                        AdjustVATAccount(
                          GetPurchAccount(false),
                          VATEntry2.Amount, VATEntry2."Additional-Currency Amount",
                          VATEntryTotalBase.Amount, VATEntryTotalBase."Additional-Currency Amount");
                        if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then
                            AdjustVATAccount(
                              GetRevChargeAccount(false),
                              -VATEntry2.Amount, -VATEntry2."Additional-Currency Amount",
                              -VATEntryTotalBase.Amount, -VATEntryTotalBase."Additional-Currency Amount");
                    end;
                    if (VATEntry2."Remaining Unrealized Amount" <> 0) or
                       (VATEntry2."Add.-Curr. Rem. Unreal. Amount" <> 0)
                    then begin
                        TestField("Unrealized VAT Type");
                        AdjustVATAccount(
                          GetPurchAccount(true),
                          VATEntry2."Remaining Unrealized Amount",
                          VATEntry2."Add.-Curr. Rem. Unreal. Amount",
                          VATEntryTotalBase."Remaining Unrealized Amount",
                          VATEntryTotalBase."Add.-Curr. Rem. Unreal. Amount");
                        if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then
                            AdjustVATAccount(
                              GetRevChargeAccount(true),
                              -VATEntry2."Remaining Unrealized Amount",
                              -VATEntry2."Add.-Curr. Rem. Unreal. Amount",
                              -VATEntryTotalBase."Remaining Unrealized Amount",
                              -VATEntryTotalBase."Add.-Curr. Rem. Unreal. Amount");
                    end;

                    AdjustVATEntries(VATEntry.Type::Sale, false);
                    if (VATEntry2.Amount <> 0) or (VATEntry2."Additional-Currency Amount" <> 0) then
                        AdjustVATAccount(
                          GetSalesAccount(false),
                          VATEntry2.Amount, VATEntry2."Additional-Currency Amount",
                          VATEntryTotalBase.Amount, VATEntryTotalBase."Additional-Currency Amount");
                    if (VATEntry2."Remaining Unrealized Amount" <> 0) or
                       (VATEntry2."Add.-Curr. Rem. Unreal. Amount" <> 0)
                    then begin
                        TestField("Unrealized VAT Type");
                        AdjustVATAccount(
                          GetSalesAccount(true),
                          VATEntry2."Remaining Unrealized Amount",
                          VATEntry2."Add.-Curr. Rem. Unreal. Amount",
                          VATEntryTotalBase."Remaining Unrealized Amount",
                          VATEntryTotalBase."Add.-Curr. Rem. Unreal. Amount");
                    end;
                end else begin
                    if TaxJurisdiction.Find('-') then
                        repeat
                            VATEntry.SetRange("Tax Jurisdiction Code", TaxJurisdiction.Code);
                            AdjustVATEntries(VATEntry.Type::Purchase, false);
                            AdjustPurchTax(false);
                            AdjustVATEntries(VATEntry.Type::Purchase, true);
                            AdjustPurchTax(true);
                            AdjustVATEntries(VATEntry.Type::Sale, false);
                            AdjustSalesTax();
                        until TaxJurisdiction.Next() = 0;
                    VATEntry.SetRange("Tax Jurisdiction Code");
                end;
                Clear(VATEntryTotalBase);
            end;

            trigger OnPreDataItem()
            begin
                if TestMode then
                    CurrReport.Break();

                if not AdjGLAcc or
                   (GLSetup."VAT Exchange Rate Adjustment" = GLSetup."VAT Exchange Rate Adjustment"::"No Adjustment")
                then
                    CurrReport.Break();

                VATEntryNoTotal := VATEntry.Count();

                if VATEntryNoTotal = 0 then
                    CurrReport.Break();

                Window.Open(
                  Text012Txt +
                  Text013Txt);

                if GLSetup."Journal Templ. Name Mandatory" then
                    VATEntry.SetCurrentKey(
                        "Journal Templ. Name", Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Document Type", "Posting Date")
                else
                    if not
                        VATEntry.SetCurrentKey(
                            Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date")
                    then
                        VATEntry.SetCurrentKey(
                            Type, Closed, "Tax Jurisdiction Code", "Use Tax", "Posting Date");
                VATEntry.SetRange(Closed, false);
                VATEntry.SetRange("Posting Date", StartDate, EndDate);
            end;
        }
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.") where("Exchange Rate Adjustment" = filter("Adjust Amount" .. "Adjust Additional-Currency Amount"));

            trigger OnAfterGetRecord()
            begin
                GLAccNo := GLAccNo + 1;
                Window.Update(1, Round(GLAccNo / GLAccNoTotal * 10000, 1));
                if "Exchange Rate Adjustment" = "Exchange Rate Adjustment"::"No Adjustment" then
                    CurrReport.Skip();

                TempDimSetEntry.Reset();
                TempDimSetEntry.DeleteAll();
                CalcFields("Net Change", "Additional-Currency Net Change");
                case "Exchange Rate Adjustment" of
                    "Exchange Rate Adjustment"::"Adjust Amount":
                        PostGLAccAdjmt(
                          "No.", "Exchange Rate Adjustment"::"Adjust Amount",
                          Round(
                            CurrExchRate2.ExchangeAmtFCYToLCYAdjmt(
                              PostingDate, GLSetup."Additional Reporting Currency",
                              "Additional-Currency Net Change", AddCurrCurrencyFactor) -
                            "Net Change"),
                          "Net Change",
                          "Additional-Currency Net Change");
                    "Exchange Rate Adjustment"::"Adjust Additional-Currency Amount":
                        PostGLAccAdjmt(
                          "No.", "Exchange Rate Adjustment"::"Adjust Additional-Currency Amount",
                          Round(
                            CurrExchRate2.ExchangeAmtLCYToFCY(
                              PostingDate, GLSetup."Additional Reporting Currency",
                              "Net Change", AddCurrCurrencyFactor) -
                            "Additional-Currency Net Change",
                            Currency3."Amount Rounding Precision"),
                          "Net Change",
                          "Additional-Currency Net Change");
                end;
            end;

            trigger OnPostDataItem()
            begin
                if AdjGLAcc then begin
                    PostGLAccAdjmtTotal();
                    TotalGLAccountsAdjusted += 1;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if not AdjGLAcc then
                    CurrReport.Break();

                Window.Open(
                  Text014Txt +
                  Text015Txt);

                GLAccNoTotal := Count;
                SetRange("Date Filter", StartDate, EndDate);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Adjustment Period")
                    {
                        Caption = 'Adjustment Period';
                        field(StartingDate; StartDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                        }
                        field(EndingDate; EndDateReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the last date for which entries are adjusted. This date is usually the same as the posting date in the Posting Date field.';

                            trigger OnValidate()
                            begin
                                PostingDate := EndDateReq;
                            end;
                        }
                    }
                    field(PostingDescription; PostingDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies text for the general ledger entries that are created by the batch job. The default text is Exchange Rate Adjmt. of %1 %2, in which %1 is replaced by the currency code and %2 is replaced by the currency amount that is adjusted. For example, Exchange Rate Adjmt. of EUR 38,000.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date on which the general ledger entries are posted. This date is usually the same as the ending date in the Ending Date field.';

                        trigger OnValidate()
                        begin
                            CheckPostingDate();
                        end;
                    }
                    field(DocumentNo; PostingDocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the document number that will appear on the general ledger entries that are created by the batch job.';
                        Visible = not IsJournalTemplNameVisible;
                    }
                    field(JournalTemplateName; GenJnlLineReq."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnValidate()
                        begin
                            GenJnlLineReq."Journal Batch Name" := '';
                        end;
                    }
                    field(JournalBatchName; GenJnlLineReq."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch Name';
                        Lookup = true;
                        ToolTip = 'Specifies the name of the journal batch that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            GenJnlManagement: Codeunit GenJnlManagement;
                        begin
                            GenJnlManagement.SetJnlBatchName(GenJnlLineReq);
                            if GenJnlLineReq."Journal Batch Name" <> '' then
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                        end;

                        trigger OnValidate()
                        begin
                            if GenJnlLineReq."Journal Batch Name" <> '' then begin
                                GenJnlLineReq.TestField("Journal Template Name");
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                            end;
                        end;
                    }
                    field(AdjCustAcc; AdjCust)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Customers';
                        ToolTip = 'Specifies if you want to adjust customers for currency fluctuations.';
                    }
                    field(AdjVendAcc; AdjVend)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Vendors';
                        ToolTip = 'Specifies if you want to adjust vendors for currency fluctuations.';
                    }
                    field(AdjBankAcc; AdjBank)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Bank Accounts';
                        ToolTip = 'Specifies if you want to adjust bank accounts for currency fluctuations.';
                    }
                    field(AdjGLAcc; AdjGLAcc)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Adjust G/L Accounts for Add.-Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to post in an additional reporting currency and adjust general ledger accounts for currency fluctuations between LCY and the additional reporting currency.';
                    }
                    field(TestMode; TestMode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Test Mode';
                    }
                    field(DimForPositive; ColumnDimPos)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Dimensions for Positive';

                        trigger OnAssistEdit()
                        var
                            DimSelectionBuf: Record "Dimension Selection Buffer";
                        begin
                            DimSelectionBuf.SetDimSelectionChange(3, REPORT::"Adjust Exchange Rates", ColumnDimPos);
                        end;
                    }
                    field(DimForNegative; ColumnDimNeg)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Dimensions for Negative';

                        trigger OnAssistEdit()
                        var
                            DimSelectionBuf: Record "Dimension Selection Buffer";
                        begin
                            DimSelectionBuf.SetDimSelectionChange(3, -REPORT::"Adjust Exchange Rates", ColumnDimNeg);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            DimSelectionBuf: Record "Dimension Selection Buffer";
        begin
            if PostingDescription = '' then
                PostingDescription := Text016Txt;
            if not (AdjCust or AdjVend or AdjBank or AdjGLAcc) then begin
                AdjCust := true;
                AdjVend := true;
                AdjBank := true;
            end;
            GLSetup.Get();
            IsJournalTemplNameVisible := GLSetup."Journal Templ. Name Mandatory";
            ColumnDimPos := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Adjust Exchange Rates", '');
            ColumnDimNeg := DimSelectionBuf.GetDimSelectionText(3, -REPORT::"Adjust Exchange Rates", '')
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInitReport(IsHandled);
        if IsHandled then
            exit;
    end;

    trigger OnPostReport()
    begin
        if GenJnlPostLine.IsGLEntryInconsistent() then
            GenJnlPostLine.ShowInconsistentEntries()
        else begin
            UpdateAnalysisView.UpdateAll(0, true);
            if TotalCustomersAdjusted + TotalVendorsAdjusted + TotalBankAccountsAdjusted + TotalGLAccountsAdjusted < 1 then
                Message(NothingToAdjustMsg)
            else
                Message(RatesAdjustedMsg);
        end;

        OnAfterPostReport(ExchRateAdjReg, PostingDate);
    end;

    trigger OnPreReport()
    begin
        if EndDateReq = 0D then
            EndDate := DMY2Date(31, 12, 9999)
        else
            EndDate := EndDateReq;

        GLSetup.Get();
        if GLSetup."Journal Templ. Name Mandatory" then begin
            if GenJnlLineReq."Journal Template Name" = '' then
                Error(PleaseEnterErr, GenJnlLineReq.FieldCaption("Journal Template Name"));
            if GenJnlLineReq."Journal Batch Name" = '' then
                Error(PleaseEnterErr, GenJnlLineReq.FieldCaption("Journal Batch Name"));
            Clear(NoSeriesMgt);
            Clear(PostingDocNo);
            GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
            GenJnlBatch.TestField("No. Series");
            PostingDocNo := NoSeriesMgt.GetNextNo(GenJnlBatch."No. Series", PostingDate, true);
        end else
            if PostingDocNo = '' then
                Error(Text000Err);
        if (not AdjCust) and (not AdjVend) and (not AdjBank) and AdjGLAcc then
            if not Confirm(Text001Txt + Text004Txt, false) then
                Error(Text005Err);

        SourceCodeSetup.Get();

        if ExchRateAdjReg.FindLast() then
            ExchRateAdjReg.Init();

        if AdjGLAcc then begin
            GLSetup.TestField("Additional Reporting Currency");

            Currency3.Get(GLSetup."Additional Reporting Currency");
            "G/L Account".Get(Currency3.GetRealizedGLGainsAccount());
            "G/L Account".TestField("Exchange Rate Adjustment", "G/L Account"."Exchange Rate Adjustment"::"No Adjustment");

            "G/L Account".Get(Currency3.GetRealizedGLLossesAccount());
            "G/L Account".TestField("Exchange Rate Adjustment", "G/L Account"."Exchange Rate Adjustment"::"No Adjustment");

            with VATPostingSetup2 do
                if Find('-') then
                    repeat
                        if "VAT Calculation Type" <> "VAT Calculation Type"::"Sales Tax" then begin
                            CheckExchRateAdjustment(
                              "Purchase VAT Account", TableCaption(), FieldCaption("Purchase VAT Account"));
                            CheckExchRateAdjustment(
                              "Reverse Chrg. VAT Acc.", TableCaption(), FieldCaption("Reverse Chrg. VAT Acc."));
                            CheckExchRateAdjustment(
                              "Purch. VAT Unreal. Account", TableCaption(), FieldCaption("Purch. VAT Unreal. Account"));
                            CheckExchRateAdjustment(
                              "Reverse Chrg. VAT Unreal. Acc.", TableCaption(), FieldCaption("Reverse Chrg. VAT Unreal. Acc."));
                            CheckExchRateAdjustment(
                              "Sales VAT Account", TableCaption(), FieldCaption("Sales VAT Account"));
                            CheckExchRateAdjustment(
                              "Sales VAT Unreal. Account", TableCaption(), FieldCaption("Sales VAT Unreal. Account"));
                        end;
                    until Next() = 0;

            with TaxJurisdiction2 do
                if Find('-') then
                    repeat
                        CheckExchRateAdjustment(
                          "Tax Account (Purchases)", TableCaption(), FieldCaption("Tax Account (Purchases)"));
                        CheckExchRateAdjustment(
                          "Reverse Charge (Purchases)", TableCaption(), FieldCaption("Reverse Charge (Purchases)"));
                        CheckExchRateAdjustment(
                          "Unreal. Tax Acc. (Purchases)", TableCaption(), FieldCaption("Unreal. Tax Acc. (Purchases)"));
                        CheckExchRateAdjustment(
                          "Unreal. Rev. Charge (Purch.)", TableCaption(), FieldCaption("Unreal. Rev. Charge (Purch.)"));
                        CheckExchRateAdjustment(
                          "Tax Account (Sales)", TableCaption(), FieldCaption("Tax Account (Sales)"));
                        CheckExchRateAdjustment(
                          "Unreal. Tax Acc. (Sales)", TableCaption(), FieldCaption("Unreal. Tax Acc. (Sales)"));
                    until Next() = 0;

            AddCurrCurrencyFactor :=
              CurrExchRate2.ExchangeRateAdjmt(PostingDate, GLSetup."Additional Reporting Currency");
        end;
    end;

    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
        TempDtldCustLedgEntrySums: Record "Detailed Cust. Ledg. Entry" temporary;
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        TempDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary;
        TempDtldVendLedgEntrySums: Record "Detailed Vendor Ledg. Entry" temporary;
        ExchRateAdjReg: Record "Exch. Rate Adjmt. Reg.";
        SourceCodeSetup: Record "Source Code Setup";
        TempAdjExchRateBuffer: Record "Adjust Exchange Rate Buffer" temporary;
        TempAdjExchRateBuffer2: Record "Adjust Exchange Rate Buffer" temporary;
        TempCurrencyToAdjust: Record Currency temporary;
        Currency3: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        CurrExchRate2: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
        VATEntryTotalBase: Record "VAT Entry";
        TaxJurisdiction: Record "Tax Jurisdiction";
        VATPostingSetup2: Record "VAT Posting Setup";
        TaxJurisdiction2: Record "Tax Jurisdiction";
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        GenJnlLineReq: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        DimMgt: Codeunit DimensionManagement;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        Window: Dialog;
        TotalAdjBase: Decimal;
        TotalAdjBaseLCY: Decimal;
        TotalAdjAmount: Decimal;
        GainsAmount: Decimal;
        LossesAmount: Decimal;
        PostingDate: Date;
        PostingDescription: Text[100];
        CurrAdjBase: Decimal;
        CurrAdjBaseLCY: Decimal;
        CurrAdjAmount: Decimal;
        CustNo: Decimal;
        CustNoTotal: Decimal;
        VendNo: Decimal;
        VendNoTotal: Decimal;
        BankAccNo: Decimal;
        BankAccNoTotal: Decimal;
        GLAccNo: Decimal;
        GLAccNoTotal: Decimal;
        GLAmtTotal: Decimal;
        GLAddCurrAmtTotal: Decimal;
        GLNetChangeTotal: Decimal;
        GLAddCurrNetChangeTotal: Decimal;
        GLNetChangeBase: Decimal;
        GLAddCurrNetChangeBase: Decimal;
        PostingDocNo: Code[20];
        StartDate: Date;
        EndDate: Date;
        EndDateReq: Date;
        Correction: Boolean;
        HideUI: Boolean;
        OK: Boolean;
        AdjCust: Boolean;
        AdjVend: Boolean;
        AdjBank: Boolean;
        AdjGLAcc: Boolean;
        IsJournalTemplNameVisible: Boolean;
        AddCurrCurrencyFactor: Decimal;
        VATEntryNoTotal: Decimal;
        VATEntryNo: Decimal;
        NewEntryNo: Integer;
        Text018Err: Label 'This posting date cannot be entered because it does not occur within the adjustment period. Reenter the posting date.';
        FirstEntry: Boolean;
        MaxAdjExchRateBufIndex: Integer;
        Text12401Err: Label 'You must determine period';
        TestMode: Boolean;
        ColumnDimPos: Text[250];
        Text12402Txt: Label 'Dimensions';
        ColumnDimNeg: Text[250];
        DimSelectionBuf: Record "Dimension Selection Buffer";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDimPos: Record "Selected Dimension" temporary;
        TempSelectedDimNeg: Record "Selected Dimension" temporary;
        BalAccType: Option "None",Real,Unreal;
        PrepmtAdjmt: Boolean;
        TaxAccRemainingAmt: Decimal;
        RatesAdjustedMsg: Label 'One or more currency exchange rates have been adjusted.';
        NothingToAdjustMsg: Label 'There is nothing to adjust.';
        TotalBankAccountsAdjusted: Integer;
        TotalCustomersAdjusted: Integer;
        TotalVendorsAdjusted: Integer;
        TotalGLAccountsAdjusted: Integer;

        Text000Err: Label 'Document No. must be entered.';
        Text001Txt: Label 'Do you want to adjust general ledger entries for currency fluctuations without adjusting customer, vendor and bank ledger entries? This may result in incorrect currency adjustments to payables, receivables and bank accounts.\\ ';
        Text004Txt: Label 'Do you wish to continue?';
        Text005Err: Label 'The adjustment of exchange rates has been canceled.';
        Text006Txt: Label 'Adjusting exchange rates...\\';
        Text007Txt: Label 'Bank Account    @1@@@@@@@@@@@@@\\';
        Text008Txt: Label 'Customer        @2@@@@@@@@@@@@@\';
        Text009Txt: Label 'Vendor          @3@@@@@@@@@@@@@\';
        Text010Txt: Label 'Adjustment      #4#############';
        Text011Err: Label 'No currencies have been found.';
        Text012Txt: Label 'Adjusting VAT Entries...\\';
        Text013Txt: Label 'VAT Entry    @1@@@@@@@@@@@@@';
        Text014Txt: Label 'Adjusting general ledger...\\';
        Text015Txt: Label 'G/L Account    @1@@@@@@@@@@@@@';
        Text016Txt: Label 'Adjmt. of %1 %2, Ex.Rate Adjust.', Comment = '%1 = Currency Code, %2= Adjust Amount';
        Text017Err: Label '%1 on %2 %3 must be %4. When this %2 is used in %5, the exchange rate adjustment is defined in the %6 field in the %7. %2 %3 is used in the %8 field in the %5. ';
        PleaseEnterErr: Label 'Please enter a %1.', Comment = '%1 - field caption';

    local procedure PostAdjmt(GLAccNo: Code[20]; PostingAmount: Decimal; AdjBase2: Decimal; CurrencyCode2: Code[10]; var DimSetEntry: Record "Dimension Set Entry"; PostingDate2: Date; ICCode: Code[20]; CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; Gains: Boolean) TransactionNo: Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        if PostingAmount = 0 then
            exit;

        GenJnlLine.Init();
        GenJnlLine.Validate("Posting Date", PostingDate2);
        if GLSetup."Enable Russian Accounting" then begin
            GenJnlLine."Document No." := CVLedgEntryBuf."Document No.";
            GenJnlLine."Document Type" := CVLedgEntryBuf."Document Type";
            GenJnlLine.Correction := CVLedgEntryBuf.Positive;
        end else
            GenJnlLine."Document No." := PostingDocNo;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", GLAccNo);
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
        GenJnlLine."Gen. Bus. Posting Group" := '';
        GenJnlLine."Gen. Prod. Posting Group" := '';
        GenJnlLine."VAT Bus. Posting Group" := '';
        GenJnlLine."VAT Prod. Posting Group" := '';
        GenJnlLine.Description :=
            PadStr(StrSubstNo(PostingDescription, CurrencyCode2, AdjBase2), MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate(Amount, PostingAmount);
        GenJnlLine."Source Currency Code" := CurrencyCode2;
        GenJnlLine."IC Partner Code" := ICCode;
        if CurrencyCode2 = GLSetup."Additional Reporting Currency" then
            GenJnlLine."Source Currency Amount" := 0;
        GenJnlLine."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
        GenJnlLine."Journal Template Name" := GenJnlLineReq."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlLineReq."Journal Batch Name";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Source Type" := CVLedgEntryBuf."Bal. Account Type";
        GenJnlLine."Source No." := CVLedgEntryBuf."Bal. Account No.";
        case GenJnlLine."Source Type" of
            GenJnlLine."Source Type"::Customer:
                PrepmtAdjmt := GLSetup."Cancel Curr. Prepmt. Adjmt." and CVLedgEntryBuf.Prepayment;
            GenJnlLine."Source Type"::Vendor:
                PrepmtAdjmt := GLSetup."Cancel Curr. Prepmt. Adjmt." and CVLedgEntryBuf.Prepayment;
        end;
        GenJnlLine."Agreement No." := CVLedgEntryBuf."Agreement No.";
        GetTempJnlLineDim(DimSetEntry, GenJnlLine, BalAccType::Unreal, CurrencyCode2, Gains);

        TransactionNo := PostGenJnlLine(GenJnlLine, DimSetEntry);

        OnAfterPostAdjmt(GenJnlLine);
    end;

    local procedure PostBankAccAdjmt(BankAccount: Record "Bank Account")
    var
        GenJnlLine: Record "Gen. Journal Line";
        AccNo: Code[20];
    begin
        GenJnlLine.Init();
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine."Document No." := PostingDocNo;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Bank Account";
        GenJnlLine.Validate("Account No.", BankAccount."No.");
        GenJnlLine.Description := PadStr(StrSubstNo(PostingDescription, Currency.Code, CurrAdjBase), MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate(Amount, 0);
        GenJnlLine."Amount (LCY)" := CurrAdjAmount;
        GenJnlLine."Source Currency Code" := Currency.Code;
        if Currency.Code = GLSetup."Additional Reporting Currency" then
            GenJnlLine."Source Currency Amount" := 0;
        GenJnlLine."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Journal Template Name" := GenJnlLineReq."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlLineReq."Journal Batch Name";
        GetJnlLineDefDim(GenJnlLine, TempDimSetEntry);
        CopyDimSetEntryToDimBuf(TempDimSetEntry, TempDimBuf);
        GenJnlLine."Source Type" := GenJnlLine."Source Type"::"Bank Account";
        GenJnlLine."Source No." := BankAccount."No.";
        if not TestMode then begin
            GetTempJnlLineDim(TempDimSetEntry, GenJnlLine, BalAccType::Real, Currency.Code, CurrAdjAmount > 0);
            PostGenJnlLine(GenJnlLine, TempDimSetEntry);
        end;

        if CurrAdjAmount <> 0 then begin
            GetDimSetEntry(GetDimCombID(TempDimBuf), TempDimSetEntry);
            if CurrAdjAmount > 0 then
                AccNo := GetRealizedGainsAccount(Currency)
            else
                AccNo := GetRealizedLossesAccount(Currency);
        end;
    end;

    local procedure GetRealizedGainsAccount(Currency: Record Currency) AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRealizedGainsAccount(Currency, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        exit(Currency.GetRealizedGainsAccount());
    end;

    local procedure GetRealizedLossesAccount(Currency: Record Currency) AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRealizedLossesAccount(Currency, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        exit(Currency.GetRealizedLossesAccount());
    end;

    local procedure PostCustAdjmt(AdjExchRateBuffer: Record "Adjust Exchange Rate Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var TempDimSetEntry: Record "Dimension Set Entry" temporary; var TempCVLedgEntryBuf: Record "CV Ledger Entry Buffer" temporary)
    var
        CustPostingGr: Record "Customer Posting Group";
    begin
        OnBeforePostCustAdjmt(AdjExchRateBuffer, TempDtldCVLedgEntryBuf, TempDimSetEntry, TempAdjExchRateBuffer);
        CustPostingGr.Get(TempAdjExchRateBuffer."Posting Group");
        TempDtldCVLedgEntryBuf."Transaction No." :=
            PostAdjmt(
                CustPostingGr.GetReceivablesAccount(), AdjExchRateBuffer.AdjAmount,
                AdjExchRateBuffer.AdjBase, AdjExchRateBuffer."Currency Code", TempDimSetEntry,
                AdjExchRateBuffer."Posting Date", AdjExchRateBuffer."IC Partner Code",
                TempCVLedgEntryBuf, true);
        OnAfterPostCustAdjmt(AdjExchRateBuffer);
        if TempDtldCVLedgEntryBuf.Insert() then;
        InsertExchRateAdjmtReg(
            "Exch. Rate Adjmt. Account Type"::Customer, AdjExchRateBuffer."Posting Group", AdjExchRateBuffer."Currency Code");
        TempDtldCVLedgEntryBuf."Exch. Rate Adjmt. Reg. No." := ExchRateAdjReg."No.";
        TempDtldCVLedgEntryBuf.Modify();
        TotalCustomersAdjusted += 1;
    end;

    local procedure PostVendAdjmt(AdjExchRateBuffer: Record "Adjust Exchange Rate Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var TempDimSetEntry: Record "Dimension Set Entry" temporary; var TempCVLedgEntryBuf: Record "CV Ledger Entry Buffer" temporary)
    var
        VendPostingGr: Record "Vendor Posting Group";
    begin
        OnBeforePostVendAdjmt(AdjExchRateBuffer, TempDtldCVLedgEntryBuf, TempDimSetEntry, TempAdjExchRateBuffer);
        VendPostingGr.Get(TempAdjExchRateBuffer."Posting Group");
        TempDtldCVLedgEntryBuf."Transaction No." :=
            PostAdjmt(
                VendPostingGr.GetPayablesAccount(), AdjExchRateBuffer.AdjAmount,
                AdjExchRateBuffer.AdjBase, AdjExchRateBuffer."Currency Code", TempDimSetEntry,
                AdjExchRateBuffer."Posting Date", AdjExchRateBuffer."IC Partner Code",
                TempCVLedgEntryBuf, true);
        if TempDtldCVLedgEntryBuf.Insert() then;
        InsertExchRateAdjmtReg(
            "Exch. Rate Adjmt. Account Type"::Vendor, AdjExchRateBuffer."Posting Group", AdjExchRateBuffer."Currency Code");
        TempDtldCVLedgEntryBuf."Exch. Rate Adjmt. Reg. No." := ExchRateAdjReg."No.";
        TempDtldCVLedgEntryBuf.Modify();
        TotalVendorsAdjusted += 1;
    end;

    local procedure GetDimSetEntry(EntryNo: Integer; var TempDimSetEntry: Record "Dimension Set Entry" temporary)
    begin
        TempDimSetEntry.Reset();
        TempDimSetEntry.DeleteAll();
        TempDimBuf.Reset();
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(EntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
    end;

    local procedure InsertExchRateAdjmtReg(AdjustAccType: Enum "Exch. Rate Adjmt. Account Type"; PostingGrCode: Code[20]; CurrencyCode: Code[10])
    begin
        if TestMode then
            exit;

        if TempCurrencyToAdjust.Code <> CurrencyCode then
            TempCurrencyToAdjust.Get(CurrencyCode);

        with ExchRateAdjReg do begin
            "No." := "No." + 1;
            "Creation Date" := PostingDate;
            "Account Type" := AdjustAccType;
            "Posting Group" := PostingGrCode;
            "Currency Code" := TempCurrencyToAdjust.Code;
            "Currency Factor" := TempCurrencyToAdjust."Currency Factor";
            "Adjusted Base" := TempAdjExchRateBuffer.AdjBase;
            "Adjusted Base (LCY)" := TempAdjExchRateBuffer.AdjBaseLCY;
            "Adjusted Amt. (LCY)" := TempAdjExchRateBuffer.AdjAmount;
            Insert();
        end;
    end;

    procedure InitializeRequest(NewStartDate: Date; NewEndDate: Date; NewPostingDescription: Text[100]; NewPostingDate: Date)
    begin
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        PostingDescription := NewPostingDescription;
        PostingDate := NewPostingDate;
        if EndDate = 0D then
            EndDateReq := DMY2Date(31, 12, 9999)
        else
            EndDateReq := EndDate;
    end;

    procedure InitializeRequest2(NewStartDate: Date; NewEndDate: Date; NewPostingDescription: Text[100]; NewPostingDate: Date; NewPostingDocNo: Code[20]; NewAdjCustVendBank: Boolean; NewAdjGLAcc: Boolean)
    begin
        InitializeRequest(NewStartDate, NewEndDate, NewPostingDescription, NewPostingDate);
        PostingDocNo := NewPostingDocNo;
        AdjBank := NewAdjCustVendBank;
        AdjCust := NewAdjCustVendBank;
        AdjVend := NewAdjCustVendBank;
        AdjGLAcc := NewAdjGLAcc;
        TestMode := false;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest3(NewStartDate: Date; NewEndDate: Date; NewPostingDescription: Text[50]; NewPostingDate: Date; NewDocNo: Code[20]; NewAdjBank: Boolean; NewAdjCust: Boolean; NewAdjVend: Boolean; NewAdjGLAcc: Boolean; NewTestMode: Boolean)
    begin
        // Use for RU tests and demo data tool
        ClearAll();
        StartDate := NewStartDate;
        EndDateReq := NewEndDate;
        PostingDate := NewPostingDate;
        PostingDescription := NewPostingDescription;
        if PostingDescription = '' then
            PostingDescription := Text016Txt;
        PostingDocNo := NewDocNo;
        AdjBank := NewAdjBank;
        AdjCust := NewAdjCust;
        AdjVend := NewAdjVend;
        AdjGLAcc := NewAdjGLAcc;
        TestMode := NewTestMode;
    end;

    local procedure AdjExchRateBufferUpdate(CurrencyCode2: Code[10]; PostingGroup2: Code[20]; AdjBase2: Decimal; AdjBaseLCY2: Decimal; AdjAmount2: Decimal; GainsAmount2: Decimal; LossesAmount2: Decimal; DimEntryNo: Integer; Postingdate2: Date; ICCode: Code[20]; EntryNo: Integer): Integer
    begin
        TempAdjExchRateBuffer.Init();
        if not GLSetup."Enable Russian Accounting" then
            EntryNo := 0;

        OK := TempAdjExchRateBuffer.Get(CurrencyCode2, PostingGroup2, DimEntryNo, Postingdate2, ICCode, EntryNo);

        TempAdjExchRateBuffer.AdjBase += AdjBase2;
        TempAdjExchRateBuffer.AdjBaseLCY += AdjBaseLCY2;
        TempAdjExchRateBuffer.AdjAmount += AdjAmount2;
        TempAdjExchRateBuffer.TotalGainsAmount += GainsAmount2;
        TempAdjExchRateBuffer.TotalLossesAmount += LossesAmount2;

        if not OK then begin
            TempAdjExchRateBuffer."Currency Code" := CurrencyCode2;
            TempAdjExchRateBuffer."Posting Group" := PostingGroup2;
            TempAdjExchRateBuffer."Dimension Entry No." := DimEntryNo;
            TempAdjExchRateBuffer."Posting Date" := Postingdate2;
            TempAdjExchRateBuffer."IC Partner Code" := ICCode;
            MaxAdjExchRateBufIndex += 1;
            TempAdjExchRateBuffer.Index := MaxAdjExchRateBufIndex;
            TempAdjExchRateBuffer."Entry No." := EntryNo;
            TempAdjExchRateBuffer.Insert();
        end else
            TempAdjExchRateBuffer.Modify();

        exit(TempAdjExchRateBuffer.Index);
    end;

    local procedure HandlePostAdjmt(AdjustAccType: Integer)
    var
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        CVLedgEntryBuf: Record "CV Ledger Entry Buffer";
    begin
        SummarizeExchRateAdjmtBuffer(TempAdjExchRateBuffer, TempAdjExchRateBuffer2);

        // Post per posting group and per currency
        if TempAdjExchRateBuffer2.Find('-') then
            repeat
                TempAdjExchRateBuffer.SetRange("Currency Code", TempAdjExchRateBuffer2."Currency Code");
                TempAdjExchRateBuffer.SetRange("Dimension Entry No.", TempAdjExchRateBuffer2."Dimension Entry No.");
                TempAdjExchRateBuffer.SetRange("Posting Date", TempAdjExchRateBuffer2."Posting Date");
                TempAdjExchRateBuffer.SetRange("IC Partner Code", TempAdjExchRateBuffer2."IC Partner Code");
                TempAdjExchRateBuffer.Find('-');

                GetDimSetEntry(TempAdjExchRateBuffer."Dimension Entry No.", TempDimSetEntry);
                repeat
                    TempDtldCVLedgEntryBuf.Init();
                    TempDtldCVLedgEntryBuf."Entry No." := TempAdjExchRateBuffer.Index;
                    if TempAdjExchRateBuffer.AdjAmount <> 0 then
                        case AdjustAccType of
                            1: // Customer
                                PostCustAdjmt(TempAdjExchRateBuffer, TempDtldCVLedgEntryBuf, TempDimSetEntry, CVLedgEntryBuf);
                            2: // Vendor
                                PostVendAdjmt(TempAdjExchRateBuffer, TempDtldCVLedgEntryBuf, TempDimSetEntry, CVLedgEntryBuf);
                        end;
                until TempAdjExchRateBuffer.Next() = 0;

                TempCurrencyToAdjust.Get(TempAdjExchRateBuffer2."Currency Code");
                if TempAdjExchRateBuffer2.TotalGainsAmount <> 0 then
                    PostAdjmt(
                        GetUnrealizedGainsAccount(TempCurrencyToAdjust),
                        -TempAdjExchRateBuffer2.TotalGainsAmount, -TempAdjExchRateBuffer2.AdjBase,
                        TempAdjExchRateBuffer2."Currency Code", TempDimSetEntry,
                        TempAdjExchRateBuffer2."Posting Date", TempAdjExchRateBuffer2."IC Partner Code",
                        CVLedgEntryBuf, true);
                if TempAdjExchRateBuffer2.TotalLossesAmount <> 0 then
                    PostAdjmt(
                        GetUnrealizedLossesAccount(TempCurrencyToAdjust),
                        -TempAdjExchRateBuffer2.TotalLossesAmount, -TempAdjExchRateBuffer2.AdjBase,
                        TempAdjExchRateBuffer2."Currency Code", TempDimSetEntry,
                        TempAdjExchRateBuffer2."Posting Date", TempAdjExchRateBuffer2."IC Partner Code",
                        CVLedgEntryBuf, true);
            until TempAdjExchRateBuffer2.Next() = 0;

        case AdjustAccType of
            1: // Customer
                InsertCustLedgEntries(TempDtldCustLedgEntry, TempDtldCVLedgEntryBuf);
            2: // Vendor
                InsertVendLedgEntries(TempDtldVendLedgEntry, TempDtldCVLedgEntryBuf);
        end;

        ResetTempAdjmtBuffer();
        ResetTempAdjmtBuffer2();

        TempDtldCustLedgEntry.Reset();
        TempDtldCustLedgEntry.DeleteAll();
        TempDtldVendLedgEntry.Reset();
        TempDtldVendLedgEntry.DeleteAll();
    end;

    local procedure SummarizeExchRateAdjmtBuffer(var TempAdjExchRateBuffer: Record "Adjust Exchange Rate Buffer" temporary; var TempAdjExchRateBuffer2: Record "Adjust Exchange Rate Buffer" temporary)
    begin
        if TempAdjExchRateBuffer.Find('-') then
            // Summarize per currency and dimension combination
            repeat
                TempAdjExchRateBuffer2.Init();
                OK :=
                  TempAdjExchRateBuffer2.Get(
                    TempAdjExchRateBuffer."Currency Code",
                    '',
                    TempAdjExchRateBuffer."Dimension Entry No.",
                    TempAdjExchRateBuffer."Posting Date",
                    TempAdjExchRateBuffer."IC Partner Code");
                TempAdjExchRateBuffer2.AdjBase += TempAdjExchRateBuffer.AdjBase;
                TempAdjExchRateBuffer2.TotalGainsAmount += TempAdjExchRateBuffer.TotalGainsAmount;
                TempAdjExchRateBuffer2.TotalLossesAmount += TempAdjExchRateBuffer.TotalLossesAmount;
                if not OK then begin
                    TempAdjExchRateBuffer2."Currency Code" := TempAdjExchRateBuffer."Currency Code";
                    TempAdjExchRateBuffer2."Dimension Entry No." := TempAdjExchRateBuffer."Dimension Entry No.";
                    TempAdjExchRateBuffer2."Posting Date" := TempAdjExchRateBuffer."Posting Date";
                    TempAdjExchRateBuffer2."IC Partner Code" := TempAdjExchRateBuffer."IC Partner Code";
                    TempAdjExchRateBuffer2.Insert();
                end else
                    TempAdjExchRateBuffer2.Modify();
            until TempAdjExchRateBuffer.Next() = 0;
    end;

    local procedure InsertCustLedgEntries(var TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary)
    var
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        GLEntry: Record "G/L Entry";
        LastEntryNo: Integer;
        LastTransactionNo: Integer;
    begin
        GLEntry.GetLastEntry(LastEntryNo, LastTransactionNo);

        if TempDtldCustLedgEntry.Find('-') then
            repeat
                if TempDtldCVLedgEntryBuf.Get(TempDtldCustLedgEntry."Transaction No.") then
                    TempDtldCustLedgEntry."Transaction No." := TempDtldCVLedgEntryBuf."Transaction No."
                else
                    TempDtldCustLedgEntry."Transaction No." := LastTransactionNo;
                DtldCustLedgEntry2 := TempDtldCustLedgEntry;
                DtldCustLedgEntry2."Exch. Rate Adjmt. Reg. No." := TempDtldCVLedgEntryBuf."Exch. Rate Adjmt. Reg. No.";
                DtldCustLedgEntry2.Insert(true);
            until TempDtldCustLedgEntry.Next() = 0;
    end;

    local procedure InsertVendLedgEntries(var TempDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary)
    var
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        GLEntry: Record "G/L Entry";
        LastEntryNo: Integer;
        LastTransactionNo: Integer;
    begin
        GLEntry.GetLastEntry(LastEntryNo, LastTransactionNo);

        if TempDtldVendLedgEntry.Find('-') then
            repeat
                if TempDtldCVLedgEntryBuf.Get(TempDtldVendLedgEntry."Transaction No.") then
                    TempDtldVendLedgEntry."Transaction No." := TempDtldCVLedgEntryBuf."Transaction No."
                else
                    TempDtldVendLedgEntry."Transaction No." := LastTransactionNo;
                DtldVendLedgEntry2 := TempDtldVendLedgEntry;
                DtldVendLedgEntry2."Exch. Rate Adjmt. Reg. No." := TempDtldCVLedgEntryBuf."Exch. Rate Adjmt. Reg. No.";
                DtldVendLedgEntry2.Insert(true);
            until TempDtldVendLedgEntry.Next() = 0;
    end;

    local procedure PrepareTempCustLedgEntry(Customer: Record Customer; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        TempCustLedgerEntry.DeleteAll();

        Currency.CopyFilter(Code, CustLedgerEntry2."Currency Code");
        CustLedgerEntry2.FilterGroup(2);
        CustLedgerEntry2.SetFilter("Currency Code", '<>%1', '');
        CustLedgerEntry2.FilterGroup(0);

        DtldCustLedgEntry2.Reset();
        DtldCustLedgEntry2.SetCurrentKey("Customer No.", "Posting Date", "Entry Type");
        DtldCustLedgEntry2.SetRange("Customer No.", Customer."No.");
        DtldCustLedgEntry2.SetRange("Posting Date", CalcDate('<+1D>', EndDate), DMY2Date(31, 12, 9999));
        if GLSetup."Enable Russian Accounting" then
            DtldCustLedgEntry2.SetRange("Entry Type", DtldCustLedgEntry2."Entry Type"::Application);
        DtldCustLedgEntry2.SetFilter("Agreement No.", Customer.GetFilter("Agreement Filter"));
        if DtldCustLedgEntry2.Find('-') then
            repeat
                CustLedgerEntry2."Entry No." := DtldCustLedgEntry2."Cust. Ledger Entry No.";
                if CustLedgerEntry2.Find('=') then
                    if (CustLedgerEntry2."Posting Date" >= StartDate) and
                        (CustLedgerEntry2."Posting Date" <= EndDate)
                    then begin
                        TempCustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No.";
                        if TempCustLedgerEntry.Insert() then;
                    end;
            until DtldCustLedgEntry2.Next() = 0;

        CustLedgerEntry2.SetCurrentKey("Customer No.", Open);
        CustLedgerEntry2.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry2.SetRange(Open, true);
        CustLedgerEntry2.SetRange("Posting Date", 0D, EndDate);
        if CustLedgerEntry2.Find('-') then
            repeat
                TempCustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No.";
                if TempCustLedgerEntry.Insert() then;
            until CustLedgerEntry2.Next() = 0;
        CustLedgerEntry2.Reset();
    end;

    local procedure PrepareTempVendLedgEntry(Vendor: Record Vendor; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary);
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        TempVendorLedgerEntry.DeleteAll();

        Currency.CopyFilter(Code, VendorLedgerEntry2."Currency Code");
        VendorLedgerEntry2.FilterGroup(2);
        VendorLedgerEntry2.SetFilter("Currency Code", '<>%1', '');
        VendorLedgerEntry2.FilterGroup(0);

        DtldVendLedgEntry2.Reset();
        DtldVendLedgEntry2.SetCurrentKey("Vendor No.", "Posting Date", "Entry Type");
        DtldVendLedgEntry2.SetRange("Vendor No.", Vendor."No.");
        DtldVendLedgEntry2.SetRange("Posting Date", CalcDate('<+1D>', EndDate), DMY2Date(31, 12, 9999));
        if GLSetup."Enable Russian Accounting" then
            DtldVendLedgEntry2.SetRange("Entry Type", DtldVendLedgEntry2."Entry Type"::Application);
        DtldVendLedgEntry2.SetFilter("Agreement No.", Vendor.GetFilter("Agreement Filter"));
        if DtldVendLedgEntry2.Find('-') then
            repeat
                VendorLedgerEntry2."Entry No." := DtldVendLedgEntry2."Vendor Ledger Entry No.";
                if VendorLedgerEntry2.Find('=') then
                    if (VendorLedgerEntry2."Posting Date" >= StartDate) and
                        (VendorLedgerEntry2."Posting Date" <= EndDate)
                    then begin
                        TempVendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No.";
                        if TempVendorLedgerEntry.Insert() then;
                    end;
            until DtldVendLedgEntry2.Next() = 0;

        VendorLedgerEntry2.SetCurrentKey("Vendor No.", Open);
        VendorLedgerEntry2.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry2.SetRange(Open, true);
        VendorLedgerEntry2.SetRange("Posting Date", 0D, EndDate);
        if VendorLedgerEntry2.Find('-') then
            repeat
                TempVendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No.";
                if TempVendorLedgerEntry.Insert() then;
            until VendorLedgerEntry2.Next() = 0;
        VendorLedgerEntry2.Reset();
    end;

    local procedure AdjustVATEntries(VATType: Enum "General Posting Type"; UseTax: Boolean)
    begin
        Clear(VATEntry2);
        VATEntry.SetRange(Type, VATType);
        VATEntry.SetRange("Use Tax", UseTax);
        if VATEntry.Find('-') then
            repeat
                Accumulate(VATEntry2.Base, VATEntry.Base);
                Accumulate(VATEntry2.Amount, VATEntry.Amount);
                Accumulate(VATEntry2."Unrealized Amount", VATEntry."Unrealized Amount");
                Accumulate(VATEntry2."Unrealized Base", VATEntry."Unrealized Base");
                Accumulate(VATEntry2."Remaining Unrealized Amount", VATEntry."Remaining Unrealized Amount");
                Accumulate(VATEntry2."Remaining Unrealized Base", VATEntry."Remaining Unrealized Base");
                Accumulate(VATEntry2."Additional-Currency Amount", VATEntry."Additional-Currency Amount");
                Accumulate(VATEntry2."Additional-Currency Base", VATEntry."Additional-Currency Base");
                Accumulate(VATEntry2."Add.-Currency Unrealized Amt.", VATEntry."Add.-Currency Unrealized Amt.");
                Accumulate(VATEntry2."Add.-Currency Unrealized Base", VATEntry."Add.-Currency Unrealized Base");
                Accumulate(VATEntry2."Add.-Curr. Rem. Unreal. Amount", VATEntry."Add.-Curr. Rem. Unreal. Amount");
                Accumulate(VATEntry2."Add.-Curr. Rem. Unreal. Base", VATEntry."Add.-Curr. Rem. Unreal. Base");

                Accumulate(VATEntryTotalBase.Base, VATEntry.Base);
                Accumulate(VATEntryTotalBase.Amount, VATEntry.Amount);
                Accumulate(VATEntryTotalBase."Unrealized Amount", VATEntry."Unrealized Amount");
                Accumulate(VATEntryTotalBase."Unrealized Base", VATEntry."Unrealized Base");
                Accumulate(VATEntryTotalBase."Remaining Unrealized Amount", VATEntry."Remaining Unrealized Amount");
                Accumulate(VATEntryTotalBase."Remaining Unrealized Base", VATEntry."Remaining Unrealized Base");
                Accumulate(VATEntryTotalBase."Additional-Currency Amount", VATEntry."Additional-Currency Amount");
                Accumulate(VATEntryTotalBase."Additional-Currency Base", VATEntry."Additional-Currency Base");
                Accumulate(VATEntryTotalBase."Add.-Currency Unrealized Amt.", VATEntry."Add.-Currency Unrealized Amt.");
                Accumulate(VATEntryTotalBase."Add.-Currency Unrealized Base", VATEntry."Add.-Currency Unrealized Base");
                Accumulate(
                    VATEntryTotalBase."Add.-Curr. Rem. Unreal. Amount", VATEntry."Add.-Curr. Rem. Unreal. Amount");
                Accumulate(VATEntryTotalBase."Add.-Curr. Rem. Unreal. Base", VATEntry."Add.-Curr. Rem. Unreal. Base");

                AdjustVATAmount(VATEntry.Base, VATEntry."Additional-Currency Base");
                AdjustVATAmount(VATEntry.Amount, VATEntry."Additional-Currency Amount");
                AdjustVATAmount(VATEntry."Unrealized Amount", VATEntry."Add.-Currency Unrealized Amt.");
                AdjustVATAmount(VATEntry."Unrealized Base", VATEntry."Add.-Currency Unrealized Base");
                AdjustVATAmount(VATEntry."Remaining Unrealized Amount", VATEntry."Add.-Curr. Rem. Unreal. Amount");
                AdjustVATAmount(VATEntry."Remaining Unrealized Base", VATEntry."Add.-Curr. Rem. Unreal. Base");
                VATEntry.Modify();

                Accumulate(VATEntry2.Base, -VATEntry.Base);
                Accumulate(VATEntry2.Amount, -VATEntry.Amount);
                Accumulate(VATEntry2."Unrealized Amount", -VATEntry."Unrealized Amount");
                Accumulate(VATEntry2."Unrealized Base", -VATEntry."Unrealized Base");
                Accumulate(VATEntry2."Remaining Unrealized Amount", -VATEntry."Remaining Unrealized Amount");
                Accumulate(VATEntry2."Remaining Unrealized Base", -VATEntry."Remaining Unrealized Base");
                Accumulate(VATEntry2."Additional-Currency Amount", -VATEntry."Additional-Currency Amount");
                Accumulate(VATEntry2."Additional-Currency Base", -VATEntry."Additional-Currency Base");
                Accumulate(VATEntry2."Add.-Currency Unrealized Amt.", -VATEntry."Add.-Currency Unrealized Amt.");
                Accumulate(VATEntry2."Add.-Currency Unrealized Base", -VATEntry."Add.-Currency Unrealized Base");
                Accumulate(VATEntry2."Add.-Curr. Rem. Unreal. Amount", -VATEntry."Add.-Curr. Rem. Unreal. Amount");
                Accumulate(VATEntry2."Add.-Curr. Rem. Unreal. Base", -VATEntry."Add.-Curr. Rem. Unreal. Base");
            until VATEntry.Next() = 0;
    end;

    local procedure AdjustVATAmount(var AmountLCY: Decimal; var AmountAddCurr: Decimal)
    begin
        case GLSetup."VAT Exchange Rate Adjustment" of
            GLSetup."VAT Exchange Rate Adjustment"::"Adjust Amount":
                AmountLCY :=
                  Round(
                    CurrExchRate2.ExchangeAmtFCYToLCYAdjmt(
                      PostingDate, GLSetup."Additional Reporting Currency",
                      AmountAddCurr, AddCurrCurrencyFactor));
            GLSetup."VAT Exchange Rate Adjustment"::"Adjust Additional-Currency Amount":
                AmountAddCurr :=
                  Round(
                    CurrExchRate2.ExchangeAmtLCYToFCY(
                      PostingDate, GLSetup."Additional Reporting Currency",
                      AmountLCY, AddCurrCurrencyFactor));
        end;
    end;

    local procedure AdjustVATAccount(AccNo: Code[20]; AmountLCY: Decimal; AmountAddCurr: Decimal; BaseLCY: Decimal; BaseAddCurr: Decimal)
    begin
        "G/L Account".Get(AccNo);
        "G/L Account".SetRange("Date Filter", StartDate, EndDate);
        case GLSetup."VAT Exchange Rate Adjustment" of
            GLSetup."VAT Exchange Rate Adjustment"::"Adjust Amount":
                PostGLAccAdjmt(
                  AccNo, GLSetup."VAT Exchange Rate Adjustment"::"Adjust Amount",
                  -AmountLCY, BaseLCY, BaseAddCurr);
            GLSetup."VAT Exchange Rate Adjustment"::"Adjust Additional-Currency Amount":
                PostGLAccAdjmt(
                  AccNo, GLSetup."VAT Exchange Rate Adjustment"::"Adjust Additional-Currency Amount",
                  -AmountAddCurr, BaseLCY, BaseAddCurr);
        end;
    end;

    local procedure AdjustPurchTax(UseTax: Boolean)
    begin
        if (VATEntry2.Amount <> 0) or (VATEntry2."Additional-Currency Amount" <> 0) then begin
            TaxJurisdiction.TestField("Tax Account (Purchases)");
            AdjustVATAccount(
              TaxJurisdiction."Tax Account (Purchases)",
              VATEntry2.Amount, VATEntry2."Additional-Currency Amount",
              VATEntryTotalBase.Amount, VATEntryTotalBase."Additional-Currency Amount");
            if UseTax then begin
                TaxJurisdiction.TestField("Reverse Charge (Purchases)");
                AdjustVATAccount(
                  TaxJurisdiction."Reverse Charge (Purchases)",
                  -VATEntry2.Amount, -VATEntry2."Additional-Currency Amount",
                  -VATEntryTotalBase.Amount, -VATEntryTotalBase."Additional-Currency Amount");
            end;
        end;
        if (VATEntry2."Remaining Unrealized Amount" <> 0) or
           (VATEntry2."Add.-Curr. Rem. Unreal. Amount" <> 0)
        then begin
            TaxJurisdiction.TestField("Unrealized VAT Type");
            TaxJurisdiction.TestField("Unreal. Tax Acc. (Purchases)");
            AdjustVATAccount(
              TaxJurisdiction."Unreal. Tax Acc. (Purchases)",
              VATEntry2."Remaining Unrealized Amount", VATEntry2."Add.-Curr. Rem. Unreal. Amount",
              VATEntryTotalBase."Remaining Unrealized Amount", VATEntry2."Add.-Curr. Rem. Unreal. Amount");

            if UseTax then begin
                TaxJurisdiction.TestField("Unreal. Rev. Charge (Purch.)");
                AdjustVATAccount(
                  TaxJurisdiction."Unreal. Rev. Charge (Purch.)",
                  -VATEntry2."Remaining Unrealized Amount",
                  -VATEntry2."Add.-Curr. Rem. Unreal. Amount",
                  -VATEntryTotalBase."Remaining Unrealized Amount",
                  -VATEntryTotalBase."Add.-Curr. Rem. Unreal. Amount");
            end;
        end;
    end;

    local procedure AdjustSalesTax()
    begin
        TaxJurisdiction.TestField("Tax Account (Sales)");
        AdjustVATAccount(
          TaxJurisdiction."Tax Account (Sales)",
          VATEntry2.Amount, VATEntry2."Additional-Currency Amount",
          VATEntryTotalBase.Amount, VATEntryTotalBase."Additional-Currency Amount");
        if (VATEntry2."Remaining Unrealized Amount" <> 0) or
           (VATEntry2."Add.-Curr. Rem. Unreal. Amount" <> 0)
        then begin
            TaxJurisdiction.TestField("Unrealized VAT Type");
            TaxJurisdiction.TestField("Unreal. Tax Acc. (Sales)");
            AdjustVATAccount(
              TaxJurisdiction."Unreal. Tax Acc. (Sales)",
              VATEntry2."Remaining Unrealized Amount",
              VATEntry2."Add.-Curr. Rem. Unreal. Amount",
              VATEntryTotalBase."Remaining Unrealized Amount",
              VATEntryTotalBase."Add.-Curr. Rem. Unreal. Amount");
        end;
    end;

    local procedure Accumulate(var TotalAmount: Decimal; AmountToAdd: Decimal)
    begin
        TotalAmount := TotalAmount + AmountToAdd;
    end;

    local procedure PostGLAccAdjmt(GLAccNo: Code[20]; ExchRateAdjmt: Enum "Exch. Rate Adjustment Type"; Amount: Decimal; NetChange: Decimal; AddCurrNetChange: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.Init();
        case ExchRateAdjmt of
            "G/L Account"."Exchange Rate Adjustment"::"Adjust Amount":
                begin
                    GenJnlLine."Additional-Currency Posting" := GenJnlLine."Additional-Currency Posting"::"Amount Only";
                    GenJnlLine."Currency Code" := '';
                    GenJnlLine.Amount := Amount;
                    GenJnlLine."Amount (LCY)" := GenJnlLine.Amount;
                    GLAmtTotal := GLAmtTotal + GenJnlLine.Amount;
                    GLAddCurrNetChangeTotal := GLAddCurrNetChangeTotal + AddCurrNetChange;
                    GLNetChangeBase := GLNetChangeBase + NetChange;
                end;
            "G/L Account"."Exchange Rate Adjustment"::"Adjust Additional-Currency Amount":
                begin
                    GenJnlLine."Additional-Currency Posting" := GenJnlLine."Additional-Currency Posting"::"Additional-Currency Amount Only";
                    GenJnlLine."Currency Code" := GLSetup."Additional Reporting Currency";
                    GenJnlLine.Amount := Amount;
                    GenJnlLine."Amount (LCY)" := 0;
                    GLAddCurrAmtTotal := GLAddCurrAmtTotal + GenJnlLine.Amount;
                    GLNetChangeTotal := GLNetChangeTotal + NetChange;
                    GLAddCurrNetChangeBase := GLAddCurrNetChangeBase + AddCurrNetChange;
                end;
        end;
        if GenJnlLine.Amount <> 0 then begin
            GenJnlLine."Document No." := PostingDocNo;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine."Account No." := GLAccNo;
            GenJnlLine."Posting Date" := PostingDate;
            case GenJnlLine."Additional-Currency Posting" of
                GenJnlLine."Additional-Currency Posting"::"Amount Only":
                    GenJnlLine.Description :=
                      StrSubstNo(
                        PostingDescription,
                        GLSetup."Additional Reporting Currency",
                        AddCurrNetChange);
                GenJnlLine."Additional-Currency Posting"::"Additional-Currency Amount Only":
                    GenJnlLine.Description :=
                      StrSubstNo(
                        PostingDescription,
                        '',
                        NetChange);
            end;
            GenJnlLine."System-Created Entry" := true;
            GenJnlLine."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
            GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
            GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
            GetJnlLineDefDim(GenJnlLine, TempDimSetEntry);
            GetTempJnlLineDim(TempDimSetEntry, GenJnlLine, BalAccType::None, '', Amount > 0);
            PostGenJnlLine(GenJnlLine, TempDimSetEntry);
        end;
    end;

    local procedure PostGLAccAdjmtTotal()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.Init();
        GenJnlLine."Document No." := PostingDocNo;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
        GenJnlLine."System-Created Entry" := true;

        if GLAmtTotal <> 0 then begin
            if GLAmtTotal < 0 then
                GenJnlLine."Account No." := Currency3.GetRealizedGLLossesAccount()
            else
                GenJnlLine."Account No." := Currency3.GetRealizedGLGainsAccount();
            GenJnlLine.Description :=
                StrSubstNo(
                PostingDescription,
                GLSetup."Additional Reporting Currency",
                GLAddCurrNetChangeTotal);
            GenJnlLine."Additional-Currency Posting" := GenJnlLine."Additional-Currency Posting"::"Amount Only";
            GenJnlLine."Currency Code" := '';
            GenJnlLine.Amount := -GLAmtTotal;
            GenJnlLine."Amount (LCY)" := -GLAmtTotal;
            GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
            GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
            GetJnlLineDefDim(GenJnlLine, TempDimSetEntry);
            PostGenJnlLine(GenJnlLine, TempDimSetEntry);
        end;
        if GLAddCurrAmtTotal <> 0 then begin
            if GLAddCurrAmtTotal < 0 then
                GenJnlLine."Account No." := Currency3.GetRealizedGLLossesAccount()
            else
                GenJnlLine."Account No." := Currency3.GetRealizedGLGainsAccount();
            GenJnlLine.Description :=
                StrSubstNo(
                PostingDescription, '',
                GLNetChangeTotal);
            GenJnlLine."Additional-Currency Posting" := GenJnlLine."Additional-Currency Posting"::"Additional-Currency Amount Only";
            GenJnlLine."Currency Code" := GLSetup."Additional Reporting Currency";
            GenJnlLine.Amount := -GLAddCurrAmtTotal;
            GenJnlLine."Amount (LCY)" := 0;
            GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
            GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
            GetJnlLineDefDim(GenJnlLine, TempDimSetEntry);
            PostGenJnlLine(GenJnlLine, TempDimSetEntry);
        end;

        with ExchRateAdjReg do begin
            "No." := "No." + 1;
            "Creation Date" := PostingDate;
            "Account Type" := "Account Type"::"G/L Account";
            "Posting Group" := '';
            "Currency Code" := GLSetup."Additional Reporting Currency";
            "Currency Factor" := CurrExchRate2."Adjustment Exch. Rate Amount";
            "Adjusted Base" := 0;
            "Adjusted Base (LCY)" := GLNetChangeBase;
            "Adjusted Amt. (LCY)" := GLAmtTotal;
            "Adjusted Base (Add.-Curr.)" := GLAddCurrNetChangeBase;
            "Adjusted Amt. (Add.-Curr.)" := GLAddCurrAmtTotal;
            Insert();
        end;
    end;

    local procedure CheckExchRateAdjustment(AccNo: Code[20]; SetupTableName: Text[100]; SetupFieldName: Text[100])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo = '' then
            exit;
        GLAcc.Get(AccNo);
        if GLAcc."Exchange Rate Adjustment" <> GLAcc."Exchange Rate Adjustment"::"No Adjustment" then begin
            GLAcc."Exchange Rate Adjustment" := GLAcc."Exchange Rate Adjustment"::"No Adjustment";
            Error(
              Text017Err,
              GLAcc.FieldCaption("Exchange Rate Adjustment"), GLAcc.TableCaption(),
              GLAcc."No.", GLAcc."Exchange Rate Adjustment",
              SetupTableName, GLSetup.FieldCaption("VAT Exchange Rate Adjustment"),
              GLSetup.TableCaption(), SetupFieldName);
        end;
    end;

    local procedure HandleCustDebitCredit(Correction: Boolean; AdjAmount: Decimal)
    begin
        if (AdjAmount > 0) and not Correction or
           (AdjAmount < 0) and Correction
        then begin
            TempDtldCustLedgEntry."Debit Amount (LCY)" := AdjAmount;
            TempDtldCustLedgEntry."Credit Amount (LCY)" := 0;
        end else begin
            TempDtldCustLedgEntry."Debit Amount (LCY)" := 0;
            TempDtldCustLedgEntry."Credit Amount (LCY)" := -AdjAmount;
        end;
    end;

    local procedure HandleVendDebitCredit(Correction: Boolean; AdjAmount: Decimal)
    begin
        if (AdjAmount > 0) and not Correction or
           (AdjAmount < 0) and Correction
        then begin
            TempDtldVendLedgEntry."Debit Amount (LCY)" := AdjAmount;
            TempDtldVendLedgEntry."Credit Amount (LCY)" := 0;
        end else begin
            TempDtldVendLedgEntry."Debit Amount (LCY)" := 0;
            TempDtldVendLedgEntry."Credit Amount (LCY)" := -AdjAmount;
        end;
    end;

    local procedure GetJnlLineDefDim(var GenJnlLine: Record "Gen. Journal Line"; var DimSetEntry: Record "Dimension Set Entry")
    var
        DimSetID: Integer;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::"G/L Account":
                DimMgt.AddDimSource(DefaultDimSource, Database::"G/L Account", GenJnlLine."Account No.");
            GenJnlLine."Account Type"::"Bank Account":
                DimMgt.AddDimSource(DefaultDimSource, Database::"Bank Account", GenJnlLine."Account No.");
        end;
        DimSetID :=
            DimMgt.GetDefaultDimID(
                DefaultDimSource, GenJnlLine."Source Code",
                GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code",
                GenJnlLine."Dimension Set ID", 0);
        DimMgt.GetDimensionSet(DimSetEntry, DimSetID);

        OnAfterGetJnlLineDefDim(GenJnlLine, DimSetEntry);
    end;

    local procedure CopyDimSetEntryToDimBuf(var DimSetEntry: Record "Dimension Set Entry"; var DimBuf: Record "Dimension Buffer")
    begin
        if DimSetEntry.Find('-') then
            repeat
                DimBuf."Table ID" := DATABASE::"Dimension Buffer";
                DimBuf."Entry No." := 0;
                DimBuf."Dimension Code" := DimSetEntry."Dimension Code";
                DimBuf."Dimension Value Code" := DimSetEntry."Dimension Value Code";
                DimBuf.Insert();
            until DimSetEntry.Next() = 0;
    end;

    local procedure GetDimCombID(var DimBuf: Record "Dimension Buffer"): Integer
    var
        DimEntryNo: Integer;
    begin
        DimEntryNo := DimBufMgt.FindDimensions(DimBuf);
        if DimEntryNo = 0 then
            DimEntryNo := DimBufMgt.InsertDimensions(DimBuf);
        exit(DimEntryNo);
    end;

    local procedure PostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var DimSetEntry: Record "Dimension Set Entry") Result: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostGenJnlLine(GenJnlLine, DimSetEntry, GenJnlPostLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GenJnlLine."Shortcut Dimension 1 Code" := GetGlobalDimVal(GLSetup."Global Dimension 1 Code", DimSetEntry);
        GenJnlLine."Shortcut Dimension 2 Code" := GetGlobalDimVal(GLSetup."Global Dimension 2 Code", DimSetEntry);
        GenJnlLine."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        OnPostGenJnlLineOnBeforeGenJnlPostLineRun(GenJnlLine);
        GenJnlPostLine.Run(GenJnlLine);
        OnPostGenJnlLineOnAfterGenJnlPostLineRun(GenJnlLine, GenJnlPostLine);

        exit(GenJnlPostLine.GetNextTransactionNo());
    end;

    local procedure GetGlobalDimVal(GlobalDimCode: Code[20]; var DimSetEntry: Record "Dimension Set Entry"): Code[20]
    var
        DimVal: Code[20];
    begin
        if GlobalDimCode = '' then
            DimVal := ''
        else begin
            DimSetEntry.SetRange("Dimension Code", GlobalDimCode);
            if DimSetEntry.Find('-') then
                DimVal := DimSetEntry."Dimension Value Code"
            else
                DimVal := '';
            DimSetEntry.SetRange("Dimension Code");
        end;
        exit(DimVal);
    end;

    procedure CheckPostingDate()
    begin
        if PostingDate < StartDate then
            Error(Text018Err);
        if PostingDate > EndDateReq then
            Error(Text018Err);
    end;

    procedure AdjustCustomerLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; PostingDate2: Date)
    var
        DimSetEntry: Record "Dimension Set Entry";
        DimEntryNo: Integer;
        OldAdjAmount: Decimal;
        Adjust: Boolean;
        AdjExchRateBufIndex: Integer;
    begin
        CustLedgerEntry.SetRange("Date Filter", 0D, PostingDate2);
        TempCurrencyToAdjust.Get(CustLedgerEntry."Currency Code");
        if TempCurrencyToAdjust.Conventional then
            CurrReport.Skip();
        GainsAmount := 0;
        LossesAmount := 0;
        OldAdjAmount := 0;
        Adjust := false;

        TempDimSetEntry.Reset();
        TempDimSetEntry.DeleteAll();
        TempDimBuf.Reset();
        TempDimBuf.DeleteAll();
        DimSetEntry.SetRange("Dimension Set ID", CustLedgerEntry."Dimension Set ID");
        CopyDimSetEntryToDimBuf(DimSetEntry, TempDimBuf);
        DimEntryNo := GetDimCombID(TempDimBuf);

        CustLedgerEntry.CalcFields(
            Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)", "Original Amt. (LCY)",
            "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");

        // Calculate Old Unrealized Gains and Losses
        SetUnrealizedGainLossFilterCust(DtldCustLedgEntry, CustLedgerEntry."Entry No.");
        DtldCustLedgEntry.CalcSums("Amount (LCY)");

        SetUnrealizedGainLossFilterCust(TempDtldCustLedgEntrySums, CustLedgerEntry."Entry No.");
        TempDtldCustLedgEntrySums.CalcSums("Amount (LCY)");
        OldAdjAmount := DtldCustLedgEntry."Amount (LCY)" + TempDtldCustLedgEntrySums."Amount (LCY)";
        CustLedgerEntry."Remaining Amt. (LCY)" += TempDtldCustLedgEntrySums."Amount (LCY)";
        if GLSetup."Cancel Curr. Prepmt. Adjmt." and CustLedgerEntry.Prepayment then begin
            CustLedgerEntry."Remaining Amt. (LCY)" :=
                GetTaxAccRemainingAmt(0, CustLedgerEntry."Entry No.", PostingDate2, CustLedgerEntry."Remaining Amt. (LCY)");
            TaxAccRemainingAmt := CustLedgerEntry."Remaining Amt. (LCY)";
        end;
        CustLedgerEntry."Debit Amount (LCY)" += TempDtldCustLedgEntrySums."Amount (LCY)";
        CustLedgerEntry."Credit Amount (LCY)" += TempDtldCustLedgEntrySums."Amount (LCY)";
        TempDtldCustLedgEntrySums.Reset();

        // Modify Currency factor on Customer Ledger Entry
        if CustLedgerEntry."Adjusted Currency Factor" <> TempCurrencyToAdjust."Currency Factor" then begin
            CustLedgerEntry."Adjusted Currency Factor" := TempCurrencyToAdjust."Currency Factor";
            CustLedgerEntry.Modify();
        end;

        // Calculate New Unrealized Gains and Losses
        CurrAdjAmount :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCYAdjmt(
                    PostingDate2, TempCurrencyToAdjust.Code, CustLedgerEntry."Remaining Amount", TempCurrencyToAdjust."Currency Factor")) -
                CustLedgerEntry."Remaining Amt. (LCY)";

        if CurrAdjAmount <> 0 then begin
            if GLSetup."Enable Russian Accounting" then
                if CustLedgerEntry."Adjusted Currency Factor" <> TempCurrencyToAdjust."Currency Factor" then begin
                    CustLedgerEntry."Adjusted Currency Factor" := TempCurrencyToAdjust."Currency Factor";
                    if not TestMode then
                        CustLedgerEntry.Modify();
                end;
            OnAdjustCustomerLedgerEntryOnBeforeInitDtldCustLedgEntry(Customer, CustLedgerEntry);
            InitDtldCustLedgEntry(CustLedgerEntry, TempDtldCustLedgEntry);
            TempDtldCustLedgEntry."Entry No." := NewEntryNo;
            TempDtldCustLedgEntry."Posting Date" := PostingDate2;
            if GLSetup."Enable Russian Accounting" then begin
                TempDtldCustLedgEntry."Document No." := CustLedgerEntry."Document No.";
                TempDtldCustLedgEntry."Document Type" := CustLedgerEntry."Document Type";
                TempDtldCustLedgEntry.Prepayment := CustLedgerEntry.Prepayment;
            end else
                TempDtldCustLedgEntry."Document No." := PostingDocNo;

            Correction :=
                (CustLedgerEntry."Debit Amount" < 0) or
                (CustLedgerEntry."Credit Amount" < 0) or
                (CustLedgerEntry."Debit Amount (LCY)" < 0) or
                (CustLedgerEntry."Credit Amount (LCY)" < 0);

            if OldAdjAmount > 0 then
                case true of
                    (CurrAdjAmount > 0):
                        begin
                            TempDtldCustLedgEntry."Amount (LCY)" := CurrAdjAmount;
                            TempDtldCustLedgEntry."Entry Type" := TempDtldCustLedgEntry."Entry Type"::"Unrealized Gain";
                            HandleCustDebitCredit(Correction, TempDtldCustLedgEntry."Amount (LCY)");
                            InsertTempDtldCustomerLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            GainsAmount := CurrAdjAmount;
                            Adjust := true;
                        end;
                    (CurrAdjAmount < 0):
                        if -CurrAdjAmount <= OldAdjAmount then begin
                            TempDtldCustLedgEntry."Amount (LCY)" := CurrAdjAmount;
                            TempDtldCustLedgEntry."Entry Type" := TempDtldCustLedgEntry."Entry Type"::"Unrealized Loss";
                            HandleCustDebitCredit(Correction, TempDtldCustLedgEntry."Amount (LCY)");
                            InsertTempDtldCustomerLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            LossesAmount := CurrAdjAmount;
                            Adjust := true;
                        end else begin
                            CurrAdjAmount := CurrAdjAmount + OldAdjAmount;
                            TempDtldCustLedgEntry."Amount (LCY)" := -OldAdjAmount;
                            TempDtldCustLedgEntry."Entry Type" := TempDtldCustLedgEntry."Entry Type"::"Unrealized Loss";
                            HandleCustDebitCredit(Correction, TempDtldCustLedgEntry."Amount (LCY)");
                            InsertTempDtldCustomerLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            AdjExchRateBufIndex :=
                                AdjExchRateBufferUpdate(
                                    CustLedgerEntry."Currency Code", CustLedgerEntry."Customer Posting Group",
                                    0, 0, -OldAdjAmount, 0, -OldAdjAmount, DimEntryNo, PostingDate2, Customer."IC Partner Code",
                                    CustLedgerEntry."Entry No.");
                            TempDtldCustLedgEntry."Transaction No." := AdjExchRateBufIndex;
                            ModifyTempDtldCustomerLedgerEntry();
                            Adjust := false;
                        end;
                end;
            if OldAdjAmount < 0 then
                case true of
                    (CurrAdjAmount < 0):
                        begin
                            TempDtldCustLedgEntry."Amount (LCY)" := CurrAdjAmount;
                            TempDtldCustLedgEntry."Entry Type" := TempDtldCustLedgEntry."Entry Type"::"Unrealized Loss";
                            HandleCustDebitCredit(Correction, TempDtldCustLedgEntry."Amount (LCY)");
                            InsertTempDtldCustomerLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            LossesAmount := CurrAdjAmount;
                            Adjust := true;
                        end;
                    (CurrAdjAmount > 0):
                        if CurrAdjAmount <= -OldAdjAmount then begin
                            TempDtldCustLedgEntry."Amount (LCY)" := CurrAdjAmount;
                            TempDtldCustLedgEntry."Entry Type" := TempDtldCustLedgEntry."Entry Type"::"Unrealized Gain";
                            HandleCustDebitCredit(Correction, TempDtldCustLedgEntry."Amount (LCY)");
                            InsertTempDtldCustomerLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            GainsAmount := CurrAdjAmount;
                            Adjust := true;
                        end else begin
                            CurrAdjAmount := OldAdjAmount + CurrAdjAmount;
                            TempDtldCustLedgEntry."Amount (LCY)" := -OldAdjAmount;
                            TempDtldCustLedgEntry."Entry Type" := TempDtldCustLedgEntry."Entry Type"::"Unrealized Gain";
                            HandleCustDebitCredit(Correction, TempDtldCustLedgEntry."Amount (LCY)");
                            InsertTempDtldCustomerLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            AdjExchRateBufIndex :=
                                AdjExchRateBufferUpdate(
                                    CustLedgerEntry."Currency Code", CustLedgerEntry."Customer Posting Group",
                                    0, 0, -OldAdjAmount, -OldAdjAmount, 0, DimEntryNo, PostingDate2, Customer."IC Partner Code",
                                    CustLedgerEntry."Entry No.");
                            TempDtldCustLedgEntry."Transaction No." := AdjExchRateBufIndex;
                            ModifyTempDtldCustomerLedgerEntry();
                            Adjust := false;
                        end;
                end;
            if not Adjust then begin
                TempDtldCustLedgEntry."Amount (LCY)" := CurrAdjAmount;
                HandleCustDebitCredit(Correction, TempDtldCustLedgEntry."Amount (LCY)");
                TempDtldCustLedgEntry."Entry No." := NewEntryNo;
                if CurrAdjAmount < 0 then begin
                    TempDtldCustLedgEntry."Entry Type" := TempDtldCustLedgEntry."Entry Type"::"Unrealized Loss";
                    GainsAmount := 0;
                    LossesAmount := CurrAdjAmount;
                end else
                    if CurrAdjAmount > 0 then begin
                        TempDtldCustLedgEntry."Entry Type" := TempDtldCustLedgEntry."Entry Type"::"Unrealized Gain";
                        GainsAmount := CurrAdjAmount;
                        LossesAmount := 0;
                    end;
                InsertTempDtldCustomerLedgerEntry();
                NewEntryNo := NewEntryNo + 1;
            end;

            TotalAdjAmount := TotalAdjAmount + CurrAdjAmount;
            if not HideUI then
                Window.Update(4, TotalAdjAmount);
            AdjExchRateBufIndex :=
                AdjExchRateBufferUpdate(
                    CustLedgerEntry."Currency Code", CustLedgerEntry."Customer Posting Group",
                    CustLedgerEntry."Remaining Amount", CustLedgerEntry."Remaining Amt. (LCY)", TempDtldCustLedgEntry."Amount (LCY)",
                    GainsAmount, LossesAmount, DimEntryNo, PostingDate2, Customer."IC Partner Code",
                    CustLedgerEntry."Entry No.");
            TempDtldCustLedgEntry."Transaction No." := AdjExchRateBufIndex;
            ModifyTempDtldCustomerLedgerEntry();
        end;
    end;

    procedure AdjustVendorLedgerEntry(VendLedgerEntry: Record "Vendor Ledger Entry"; PostingDate2: Date)
    var
        DimSetEntry: Record "Dimension Set Entry";
        DimEntryNo: Integer;
        OldAdjAmount: Decimal;
        Adjust: Boolean;
        AdjExchRateBufIndex: Integer;
    begin
        VendLedgerEntry.SetRange("Date Filter", 0D, PostingDate2);
        TempCurrencyToAdjust.Get(VendLedgerEntry."Currency Code");
        if TempCurrencyToAdjust.Conventional then
            CurrReport.Skip();
        GainsAmount := 0;
        LossesAmount := 0;
        OldAdjAmount := 0;
        Adjust := false;

        TempDimBuf.Reset();
        TempDimBuf.DeleteAll();
        DimSetEntry.SetRange("Dimension Set ID", VendLedgerEntry."Dimension Set ID");
        CopyDimSetEntryToDimBuf(DimSetEntry, TempDimBuf);
        DimEntryNo := GetDimCombID(TempDimBuf);

        VendLedgerEntry.CalcFields(
            Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)", "Original Amt. (LCY)",
            "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");

        // Calculate Old Unrealized GainLoss
        SetUnrealizedGainLossFilterVend(DtldVendLedgEntry, VendLedgerEntry."Entry No.");
        DtldVendLedgEntry.CalcSums("Amount (LCY)");

        SetUnrealizedGainLossFilterVend(TempDtldVendLedgEntrySums, VendLedgerEntry."Entry No.");
        TempDtldVendLedgEntrySums.CalcSums("Amount (LCY)");
        OldAdjAmount := DtldVendLedgEntry."Amount (LCY)" + TempDtldVendLedgEntrySums."Amount (LCY)";
        VendLedgerEntry."Remaining Amt. (LCY)" += TempDtldVendLedgEntrySums."Amount (LCY)";
        if GLSetup."Cancel Curr. Prepmt. Adjmt." and VendLedgerEntry.Prepayment then begin
            VendLedgerEntry."Remaining Amt. (LCY)" :=
                GetTaxAccRemainingAmt(1, VendLedgerEntry."Entry No.", PostingDate2, VendLedgerEntry."Remaining Amt. (LCY)");
            TaxAccRemainingAmt := VendLedgerEntry."Remaining Amt. (LCY)";
        end;
        VendLedgerEntry."Debit Amount (LCY)" += TempDtldVendLedgEntrySums."Amount (LCY)";
        VendLedgerEntry."Credit Amount (LCY)" += TempDtldVendLedgEntrySums."Amount (LCY)";
        TempDtldVendLedgEntrySums.Reset();

        // Modify Currency factor on Vendor Ledger Entry
        if VendLedgerEntry."Adjusted Currency Factor" <> TempCurrencyToAdjust."Currency Factor" then begin
            VendLedgerEntry."Adjusted Currency Factor" := TempCurrencyToAdjust."Currency Factor";
            VendLedgerEntry.Modify();
        end;

        // Calculate New Unrealized Gains and Losses
        CurrAdjAmount :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCYAdjmt(
                    PostingDate2, TempCurrencyToAdjust.Code, VendLedgerEntry."Remaining Amount", TempCurrencyToAdjust."Currency Factor")) -
                VendLedgerEntry."Remaining Amt. (LCY)";

        if CurrAdjAmount <> 0 then begin
            if GLSetup."Enable Russian Accounting" then
                if VendLedgerEntry."Adjusted Currency Factor" <> TempCurrencyToAdjust."Currency Factor" then begin
                    VendLedgerEntry."Adjusted Currency Factor" := TempCurrencyToAdjust."Currency Factor";
                    if not TestMode then
                        VendLedgerEntry.Modify();
                end;
            OnAdjustVendorLedgerEntryOnBeforeInitDtldVendLedgEntry(Vendor, VendLedgerEntry);
            InitDtldVendLedgEntry(VendLedgerEntry, TempDtldVendLedgEntry);
            TempDtldVendLedgEntry."Entry No." := NewEntryNo;
            TempDtldVendLedgEntry."Posting Date" := PostingDate2;
            if GLSetup."Enable Russian Accounting" then begin
                TempDtldVendLedgEntry."Document No." := VendLedgerEntry."Document No.";
                TempDtldVendLedgEntry."Document Type" := VendLedgerEntry."Document Type";
                TempDtldVendLedgEntry.Prepayment := VendLedgerEntry.Prepayment;
            end else
                TempDtldVendLedgEntry."Document No." := PostingDocNo;

            Correction :=
                (VendLedgerEntry."Debit Amount" < 0) or
                (VendLedgerEntry."Credit Amount" < 0) or
                (VendLedgerEntry."Debit Amount (LCY)" < 0) or
                (VendLedgerEntry."Credit Amount (LCY)" < 0);

            if OldAdjAmount > 0 then
                case true of
                    (CurrAdjAmount > 0):
                        begin
                            TempDtldVendLedgEntry."Amount (LCY)" := CurrAdjAmount;
                            TempDtldVendLedgEntry."Entry Type" := TempDtldVendLedgEntry."Entry Type"::"Unrealized Gain";
                            HandleVendDebitCredit(Correction, TempDtldVendLedgEntry."Amount (LCY)");
                            InsertTempDtldVendorLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            GainsAmount := CurrAdjAmount;
                            Adjust := true;
                        end;
                    (CurrAdjAmount < 0):
                        if -CurrAdjAmount <= OldAdjAmount then begin
                            TempDtldVendLedgEntry."Amount (LCY)" := CurrAdjAmount;
                            TempDtldVendLedgEntry."Entry Type" := TempDtldVendLedgEntry."Entry Type"::"Unrealized Loss";
                            HandleVendDebitCredit(Correction, TempDtldVendLedgEntry."Amount (LCY)");
                            InsertTempDtldVendorLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            LossesAmount := CurrAdjAmount;
                            Adjust := true;
                        end else begin
                            CurrAdjAmount := CurrAdjAmount + OldAdjAmount;
                            TempDtldVendLedgEntry."Amount (LCY)" := -OldAdjAmount;
                            TempDtldVendLedgEntry."Entry Type" := TempDtldVendLedgEntry."Entry Type"::"Unrealized Loss";
                            HandleVendDebitCredit(Correction, TempDtldVendLedgEntry."Amount (LCY)");
                            InsertTempDtldVendorLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            AdjExchRateBufIndex :=
                                AdjExchRateBufferUpdate(
                                    VendLedgerEntry."Currency Code", VendLedgerEntry."Vendor Posting Group",
                                    0, 0, -OldAdjAmount, 0, -OldAdjAmount, DimEntryNo, PostingDate2, Vendor."IC Partner Code",
                                    VendLedgerEntry."Entry No.");
                            TempDtldVendLedgEntry."Transaction No." := AdjExchRateBufIndex;
                            ModifyTempDtldVendorLedgerEntry();
                            Adjust := false;
                        end;
                end;
            if OldAdjAmount < 0 then
                case true of
                    (CurrAdjAmount < 0):
                        begin
                            TempDtldVendLedgEntry."Amount (LCY)" := CurrAdjAmount;
                            TempDtldVendLedgEntry."Entry Type" := TempDtldVendLedgEntry."Entry Type"::"Unrealized Loss";
                            HandleVendDebitCredit(Correction, TempDtldVendLedgEntry."Amount (LCY)");
                            InsertTempDtldVendorLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            LossesAmount := CurrAdjAmount;
                            Adjust := true;
                        end;
                    (CurrAdjAmount > 0):
                        if CurrAdjAmount <= -OldAdjAmount then begin
                            TempDtldVendLedgEntry."Amount (LCY)" := CurrAdjAmount;
                            TempDtldVendLedgEntry."Entry Type" := TempDtldVendLedgEntry."Entry Type"::"Unrealized Gain";
                            HandleVendDebitCredit(Correction, TempDtldVendLedgEntry."Amount (LCY)");
                            InsertTempDtldVendorLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            GainsAmount := CurrAdjAmount;
                            Adjust := true;
                        end else begin
                            CurrAdjAmount := OldAdjAmount + CurrAdjAmount;
                            TempDtldVendLedgEntry."Amount (LCY)" := -OldAdjAmount;
                            TempDtldVendLedgEntry."Entry Type" := TempDtldVendLedgEntry."Entry Type"::"Unrealized Gain";
                            HandleVendDebitCredit(Correction, TempDtldVendLedgEntry."Amount (LCY)");
                            InsertTempDtldVendorLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            AdjExchRateBufIndex :=
                                AdjExchRateBufferUpdate(
                                    VendLedgerEntry."Currency Code", VendLedgerEntry."Vendor Posting Group",
                                    0, 0, -OldAdjAmount, -OldAdjAmount, 0, DimEntryNo, PostingDate2, Vendor."IC Partner Code",
                                    VendLedgerEntry."Entry No.");
                            TempDtldVendLedgEntry."Transaction No." := AdjExchRateBufIndex;
                            ModifyTempDtldVendorLedgerEntry();
                            Adjust := false;
                        end;
                end;

            if not Adjust then begin
                TempDtldVendLedgEntry."Amount (LCY)" := CurrAdjAmount;
                HandleVendDebitCredit(Correction, TempDtldVendLedgEntry."Amount (LCY)");
                TempDtldVendLedgEntry."Entry No." := NewEntryNo;
                if CurrAdjAmount < 0 then begin
                    TempDtldVendLedgEntry."Entry Type" := TempDtldVendLedgEntry."Entry Type"::"Unrealized Loss";
                    GainsAmount := 0;
                    LossesAmount := CurrAdjAmount;
                end else
                    if CurrAdjAmount > 0 then begin
                        TempDtldVendLedgEntry."Entry Type" := TempDtldVendLedgEntry."Entry Type"::"Unrealized Gain";
                        GainsAmount := CurrAdjAmount;
                        LossesAmount := 0;
                    end;
                InsertTempDtldVendorLedgerEntry();
                NewEntryNo := NewEntryNo + 1;
            end;

            TotalAdjAmount := TotalAdjAmount + CurrAdjAmount;
            if not HideUI then
                Window.Update(4, TotalAdjAmount);
            AdjExchRateBufIndex :=
                AdjExchRateBufferUpdate(
                    VendLedgerEntry."Currency Code", VendLedgerEntry."Vendor Posting Group",
                    VendLedgerEntry."Remaining Amount", VendLedgerEntry."Remaining Amt. (LCY)",
                    TempDtldVendLedgEntry."Amount (LCY)", GainsAmount, LossesAmount, DimEntryNo, PostingDate2, Vendor."IC Partner Code",
                    VendLedgerEntry."Entry No.");
            TempDtldVendLedgEntry."Transaction No." := AdjExchRateBufIndex;
            ModifyTempDtldVendorLedgerEntry();
        end;
    end;

    [Scope('OnPrem')]
    procedure AdjustExchRateCust(GenJournalLine: Record "Gen. Journal Line"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PostingDate2: Date;
    begin
        PostingDate2 := GenJournalLine."Posting Date";
        if TempCustLedgerEntry.FindSet() then
            repeat
                CustLedgerEntry2.Get(TempCustLedgerEntry."Entry No.");
                CustLedgerEntry2.SetRange("Date Filter", 0D, PostingDate2);
                CustLedgerEntry2.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                if ShouldAdjustEntry(
                        PostingDate2, CustLedgerEntry2."Currency Code", CustLedgerEntry2."Remaining Amount",
                        CustLedgerEntry2."Remaining Amt. (LCY)", CustLedgerEntry2."Adjusted Currency Factor")
                then begin
                    InitVariablesForSetLedgEntry(GenJournalLine);
                    SetCustLedgEntry(CustLedgerEntry2);
                    AdjustCustomerLedgerEntry(CustLedgerEntry2, PostingDate2);

                    DetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
                    DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry2."Entry No.");
                    DetailedCustLedgEntry.SetFilter("Posting Date", '%1..', CalcDate('<+1D>', PostingDate2));
                    if DetailedCustLedgEntry.FindSet() then
                        repeat
                            AdjustCustomerLedgerEntry(CustLedgerEntry2, DetailedCustLedgEntry."Posting Date");
                        until DetailedCustLedgEntry.Next() = 0;
                    HandlePostAdjmt(1);
                end;
            until TempCustLedgerEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure AdjustExchRateVend(GenJournalLine: Record "Gen. Journal Line"; var TempVendLedgerEntry: Record "Vendor Ledger Entry" temporary)
    var
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PostingDate2: Date;
    begin
        PostingDate2 := GenJournalLine."Posting Date";
        if TempVendLedgerEntry.FindSet() then
            repeat
                VendLedgerEntry2.Get(TempVendLedgerEntry."Entry No.");
                VendLedgerEntry2.SetRange("Date Filter", 0D, PostingDate2);
                VendLedgerEntry2.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                if ShouldAdjustEntry(
                        PostingDate2, VendLedgerEntry2."Currency Code",
                        VendLedgerEntry2."Remaining Amount", VendLedgerEntry2."Remaining Amt. (LCY)", VendLedgerEntry2."Adjusted Currency Factor")
                then begin
                    InitVariablesForSetLedgEntry(GenJournalLine);
                    SetVendLedgEntry(VendLedgerEntry2);
                    AdjustVendorLedgerEntry(VendLedgerEntry2, PostingDate2);

                    DetailedVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
                    DetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgerEntry2."Entry No.");
                    DetailedVendLedgEntry.SetFilter("Posting Date", '%1..', CalcDate('<+1D>', PostingDate2));
                    if DetailedVendLedgEntry.FindSet() then
                        repeat
                            AdjustVendorLedgerEntry(VendLedgerEntry2, DetailedVendLedgEntry."Posting Date");
                        until DetailedVendLedgEntry.Next() = 0;
                    HandlePostAdjmt(2);
                end;
            until TempVendLedgerEntry.Next() = 0;
    end;

    local procedure ResetTempAdjmtBuffer()
    begin
        TempAdjExchRateBuffer.Reset();
        TempAdjExchRateBuffer.DeleteAll();
    end;

    local procedure ResetTempAdjmtBuffer2()
    begin
        TempAdjExchRateBuffer2.Reset();
        TempAdjExchRateBuffer2.DeleteAll();
    end;

    local procedure SetCustLedgEntry(CustLedgerEntryToAdjust: Record "Cust. Ledger Entry")
    begin
        Customer.Get(CustLedgerEntryToAdjust."Customer No.");
        AddCurrency(CustLedgerEntryToAdjust."Currency Code", CustLedgerEntryToAdjust."Adjusted Currency Factor");
        DtldCustLedgEntry.LockTable();
        CustLedgerEntry.LockTable();
        NewEntryNo := DtldCustLedgEntry.GetLastEntryNo() + 1;
    end;

    local procedure SetVendLedgEntry(VendLedgerEntryToAdjust: Record "Vendor Ledger Entry")
    begin
        Vendor.Get(VendLedgerEntryToAdjust."Vendor No.");
        AddCurrency(VendLedgerEntryToAdjust."Currency Code", VendLedgerEntryToAdjust."Adjusted Currency Factor");
        DtldVendLedgEntry.LockTable();
        VendorLedgerEntry.LockTable();
        NewEntryNo := DtldVendLedgEntry.GetLastEntryNo() + 1;
    end;

    local procedure ShouldAdjustEntry(PostingDate: Date; CurCode: Code[10]; RemainingAmount: Decimal; RemainingAmtLCY: Decimal; AdjCurFactor: Decimal): Boolean
    begin
        exit(Round(CurrExchRate.ExchangeAmtFCYToLCYAdjmt(PostingDate, CurCode, RemainingAmount, AdjCurFactor)) - RemainingAmtLCY <> 0);
    end;

    local procedure InitVariablesForSetLedgEntry(GenJournalLine: Record "Gen. Journal Line")
    begin
        InitializeRequest(
            GenJournalLine."Posting Date", GenJournalLine."Posting Date", Text016Txt, GenJournalLine."Posting Date");
        GenJnlLineReq."Journal Template Name" := GenJournalLine."Journal Template Name";
        GenJnlLineReq."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        PostingDocNo := GenJournalLine."Document No.";
        HideUI := true;
        GLSetup.Get();
        SourceCodeSetup.Get();
        if ExchRateAdjReg.FindLast() then
            ExchRateAdjReg.Init();
    end;

    local procedure AddCurrency(CurrencyCode: Code[10]; CurrencyFactor: Decimal)
    var
        CurrencyToAdd: Record Currency;
    begin
        if TempCurrencyToAdjust.Get(CurrencyCode) then begin
            TempCurrencyToAdjust."Currency Factor" := CurrencyFactor;
            TempCurrencyToAdjust.Modify();
        end else begin
            CurrencyToAdd.Get(CurrencyCode);
            TempCurrencyToAdjust := CurrencyToAdd;
            TempCurrencyToAdjust."Currency Factor" := CurrencyFactor;
            TempCurrencyToAdjust.Insert();
        end;
    end;

    local procedure InitDtldCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry"; var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        DtldCustLedgEntry.Init();
        DtldCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntry."Entry No.";
        DtldCustLedgEntry.Amount := 0;
        DtldCustLedgEntry."Customer No." := CustLedgEntry."Customer No.";
        DtldCustLedgEntry."Currency Code" := CustLedgEntry."Currency Code";
        DtldCustLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(DtldCustLedgEntry."User ID"));
        DtldCustLedgEntry."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
        DtldCustLedgEntry."Journal Batch Name" := CustLedgEntry."Journal Batch Name";
        DtldCustLedgEntry."Reason Code" := CustLedgEntry."Reason Code";
        DtldCustLedgEntry."Initial Entry Due Date" := CustLedgEntry."Due Date";
        DtldCustLedgEntry."Initial Entry Global Dim. 1" := CustLedgEntry."Global Dimension 1 Code";
        DtldCustLedgEntry."Initial Entry Global Dim. 2" := CustLedgEntry."Global Dimension 2 Code";
        DtldCustLedgEntry."Initial Document Type" := CustLedgEntry."Document Type";
        DtldCustLedgEntry."Prepmt. Diff. in TA" := GLSetup."Cancel Curr. Prepmt. Adjmt." and CustLedgEntry.Prepayment;
        DtldCustLedgEntry."Agreement No." := CustLedgEntry."Agreement No.";
        DtldCustLedgEntry."Customer Posting Group" := CustLedgEntry."Customer Posting Group";
        DtldCustLedgEntry."Initial Entry Posting Date" := CustLedgEntry."Posting Date";
        DtldCustLedgEntry."Initial Entry Positive" := (CustLedgEntry.Amount >= 0);

        OnAfterInitDtldCustLedgerEntry(DtldCustLedgEntry);
    end;

    local procedure InitDtldVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry"; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
        DtldVendLedgEntry.Init();
        DtldVendLedgEntry."Vendor Ledger Entry No." := VendLedgEntry."Entry No.";
        DtldVendLedgEntry.Amount := 0;
        DtldVendLedgEntry."Vendor No." := VendLedgEntry."Vendor No.";
        DtldVendLedgEntry."Currency Code" := VendLedgEntry."Currency Code";
        DtldVendLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(DtldVendLedgEntry."User ID"));
        DtldVendLedgEntry."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
        DtldVendLedgEntry."Journal Batch Name" := VendLedgEntry."Journal Batch Name";
        DtldVendLedgEntry."Reason Code" := VendLedgEntry."Reason Code";
        DtldVendLedgEntry."Initial Entry Due Date" := VendLedgEntry."Due Date";
        DtldVendLedgEntry."Initial Entry Global Dim. 1" := VendLedgEntry."Global Dimension 1 Code";
        DtldVendLedgEntry."Initial Entry Global Dim. 2" := VendLedgEntry."Global Dimension 2 Code";
        DtldVendLedgEntry."Initial Document Type" := VendLedgEntry."Document Type";
        DtldVendLedgEntry."Prepmt. Diff. in TA" := GLSetup."Cancel Curr. Prepmt. Adjmt." and VendLedgEntry.Prepayment;
        DtldVendLedgEntry."Agreement No." := VendLedgEntry."Agreement No.";
        DtldVendLedgEntry."Vendor Posting Group" := VendLedgEntry."Vendor Posting Group";
        DtldVendLedgEntry."Initial Entry Posting Date" := VendLedgEntry."Posting Date";
        DtldVendLedgEntry."Initial Entry Positive" := (VendLedgEntry.Amount >= 0);

        OnAfterInitDtldVendLedgerEntry(DtldVendLedgEntry);
    end;

    local procedure GetUnrealizedGainsAccount(Currency: Record Currency) AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUnrealizedGainsAccount(Currency, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        exit(Currency.GetUnrealizedGainsAccount());
    end;

    local procedure GetUnrealizedLossesAccount(Currency: Record Currency) AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUnrealizedLossesAccount(Currency, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        exit(Currency.GetUnrealizedLossesAccount());
    end;

    local procedure SetUnrealizedGainLossFilterCust(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; EntryNo: Integer)
    begin
        with DtldCustLedgEntry do begin
            Reset();
            SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
            SetRange("Cust. Ledger Entry No.", EntryNo);
            SetRange("Entry Type", "Entry Type"::"Unrealized Loss", "Entry Type"::"Unrealized Gain");
            SetRange("Prepmt. Diff. in TA", GLSetup."Cancel Curr. Prepmt. Adjmt." and Prepayment);
        end;
    end;

    local procedure SetUnrealizedGainLossFilterVend(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; EntryNo: Integer)
    begin
        with DtldVendLedgEntry do begin
            Reset();
            SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
            SetRange("Vendor Ledger Entry No.", EntryNo);
            SetRange("Entry Type", "Entry Type"::"Unrealized Loss", "Entry Type"::"Unrealized Gain");
            SetRange("Prepmt. Diff. in TA", GLSetup."Cancel Curr. Prepmt. Adjmt." and Prepayment);
        end;
    end;

    local procedure InsertTempDtldCustomerLedgerEntry()
    begin
        TempDtldCustLedgEntry.Insert();
        TempDtldCustLedgEntrySums := TempDtldCustLedgEntry;
        TempDtldCustLedgEntrySums.Insert();
    end;

    local procedure InsertTempDtldVendorLedgerEntry()
    begin
        TempDtldVendLedgEntry.Insert();
        TempDtldVendLedgEntrySums := TempDtldVendLedgEntry;
        TempDtldVendLedgEntrySums.Insert();
    end;

    local procedure ModifyTempDtldCustomerLedgerEntry()
    begin
        TempDtldCustLedgEntry.Modify();
        TempDtldCustLedgEntrySums := TempDtldCustLedgEntry;
        TempDtldCustLedgEntrySums.Modify();
    end;

    local procedure ModifyTempDtldVendorLedgerEntry()
    begin
        TempDtldVendLedgEntry.Modify();
        TempDtldVendLedgEntrySums := TempDtldVendLedgEntry;
        TempDtldVendLedgEntrySums.Modify();
    end;

    local procedure HandlePostAdjmtRU(AdjustAccType: Integer)
    var
        CustPostingGr: Record "Customer Posting Group";
        VendPostingGr: Record "Vendor Posting Group";
        GLEntry: Record "G/L Entry";
        PostAccount: Code[20];
        CVLedgEntryBuf: Record "CV Ledger Entry Buffer" temporary;
        Gains: Boolean;
    begin
        if TempAdjExchRateBuffer.Find('-') then begin
            // Summarize per currency and dimension combination
            repeat
                TempAdjExchRateBuffer2.Init();
                OK :=
                  TempAdjExchRateBuffer2.Get(
                    TempAdjExchRateBuffer."Currency Code",
                    '',
                    TempAdjExchRateBuffer."Dimension Entry No.",
                    TempAdjExchRateBuffer."Posting Date",
                    TempAdjExchRateBuffer."IC Partner Code",
                    TempAdjExchRateBuffer."Entry No.");
                TempAdjExchRateBuffer2.AdjBase += TempAdjExchRateBuffer.AdjBase;
                TempAdjExchRateBuffer2.TotalGainsAmount += TempAdjExchRateBuffer.TotalGainsAmount;
                TempAdjExchRateBuffer2.TotalLossesAmount += TempAdjExchRateBuffer.TotalLossesAmount;
                if not OK then begin
                    TempAdjExchRateBuffer2."Currency Code" := TempAdjExchRateBuffer."Currency Code";
                    TempAdjExchRateBuffer2."Dimension Entry No." := TempAdjExchRateBuffer."Dimension Entry No.";
                    TempAdjExchRateBuffer2."Posting Date" := TempAdjExchRateBuffer."Posting Date";
                    TempAdjExchRateBuffer2."IC Partner Code" := TempAdjExchRateBuffer."IC Partner Code";
                    TempAdjExchRateBuffer2."Entry No." := TempAdjExchRateBuffer."Entry No.";
                    TempAdjExchRateBuffer2.Insert();
                end else
                    TempAdjExchRateBuffer2.Modify();
            until TempAdjExchRateBuffer.Next() = 0;

            // Post per posting group and per currency
            if not TestMode then
                if TempAdjExchRateBuffer2.Find('-') then
                    repeat
                        with TempAdjExchRateBuffer do begin
                            SetRange("Currency Code", TempAdjExchRateBuffer2."Currency Code");
                            SetRange("Dimension Entry No.", TempAdjExchRateBuffer2."Dimension Entry No.");
                            SetRange("Posting Date", TempAdjExchRateBuffer2."Posting Date");
                            SetRange("IC Partner Code", TempAdjExchRateBuffer2."IC Partner Code");
                            SetRange("Entry No.", TempAdjExchRateBuffer2."Entry No.");
                            TempDimBuf.Reset();
                            TempDimBuf.DeleteAll();
                            TempDimSetEntry.Reset();
                            TempDimSetEntry.DeleteAll();
                            Find('-');
                            DimBufMgt.GetDimensions("Dimension Entry No.", TempDimBuf);
                            DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
                            repeat
                                if AdjAmount <> 0 then begin
                                    case AdjustAccType of
                                        1: // Customer
                                            begin
                                                CustPostingGr.Get("Posting Group");
                                                CustLedgEntryToCVLedgEntry("Entry No.", CVLedgEntryBuf, AdjAmount);
                                                if CVLedgEntryBuf.Prepayment then begin
                                                    if GLSetup."Cancel Curr. Prepmt. Adjmt." then begin
                                                        Currency.Get("Currency Code");
                                                        PostAccount := Currency.GetPDBalGainLossAccTA();
                                                    end else
                                                        PostAccount := CustPostingGr.GetPrepaymentAccount(true);
                                                end else
                                                    PostAccount := CustPostingGr.GetReceivablesAccount();
                                                InsertExchRateAdjmtReg(1, "Posting Group", "Currency Code");
                                            end;
                                        2: // Vendor
                                            begin
                                                VendPostingGr.Get("Posting Group");
                                                VendLedgEntryToCVLedgEntry("Entry No.", CVLedgEntryBuf, AdjAmount);
                                                if CVLedgEntryBuf.Prepayment then begin
                                                    if GLSetup."Cancel Curr. Prepmt. Adjmt." then begin
                                                        Currency.Get("Currency Code");
                                                        PostAccount := Currency.GetPDBalGainLossAccTA();
                                                    end else
                                                        PostAccount := VendPostingGr.GetPrepaymentAccount(true);
                                                end else
                                                    PostAccount := VendPostingGr.GetPayablesAccount();
                                                InsertExchRateAdjmtReg(2, "Posting Group", "Currency Code");
                                            end;
                                    end;
                                    if GLSetup."Summarize Gains/Losses" then
                                        if (TotalGainsAmount <> 0) and (TotalLossesAmount <> 0) then
                                            case true of
                                                TotalGainsAmount < 0:
                                                    begin
                                                        TotalLossesAmount := TotalLossesAmount + TotalGainsAmount;
                                                        TotalGainsAmount := 0;
                                                    end;
                                                TotalLossesAmount > 0:
                                                    begin
                                                        TotalGainsAmount := TotalLossesAmount + TotalGainsAmount;
                                                        TotalLossesAmount := 0;
                                                    end;
                                            end;
                                    if TotalGainsAmount <> 0 then begin
                                        if GLSetup."Currency Adjmt with Correction" then begin
                                            CVLedgEntryBuf.Positive := TotalGainsAmount < 0;
                                            Gains := true;
                                        end else
                                            Gains := TotalGainsAmount > 0;
                                        PostAdjmt(
                                          PostAccount, TotalGainsAmount, AdjBase, "Currency Code", TempDimSetEntry,
                                          "Posting Date", "IC Partner Code", CVLedgEntryBuf, Gains);
                                    end;
                                    if TotalLossesAmount <> 0 then begin
                                        if GLSetup."Currency Adjmt with Correction" then begin
                                            CVLedgEntryBuf.Positive := TotalLossesAmount > 0;
                                            Gains := false;
                                        end else
                                            Gains := TotalLossesAmount > 0;
                                        PostAdjmt(
                                          PostAccount, TotalLossesAmount, AdjBase, "Currency Code", TempDimSetEntry,
                                          "Posting Date", "IC Partner Code", CVLedgEntryBuf, Gains);
                                    end;
                                end;
                            until Next() = 0;
                        end;
                    until TempAdjExchRateBuffer2.Next() = 0;

            GLEntry.FindLast();
            UpdateTransactionNo(AdjustAccType);

            TempAdjExchRateBuffer.Reset();
            TempAdjExchRateBuffer.DeleteAll();
            TempAdjExchRateBuffer2.Reset();
            TempAdjExchRateBuffer2.DeleteAll();
            TempDtldCustLedgEntry.Reset();
            TempDtldCustLedgEntry.DeleteAll();
            TempDtldVendLedgEntry.Reset();
            TempDtldVendLedgEntry.DeleteAll();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetTempJnlLineDim(var TempDimSetEntry: Record "Dimension Set Entry"; var GenJnlLine: Record "Gen. Journal Line"; BalAccType: Option "None",Real,Unreal; CurrencyCode: Code[10]; Gains: Boolean)
    var
        AdjCurrency: Record Currency;
    begin
        if (GenJnlLine."Amount (LCY)" = 0) and (GenJnlLine.Amount = 0) then
            exit;

        if BalAccType <> BalAccType::None then begin
            GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
            AdjCurrency.Get(CurrencyCode);
        end;

        if Gains then
            case BalAccType of
                BalAccType::Real:
                    GenJnlLine."Bal. Account No." := AdjCurrency.GetRealizedGainsAccount();
                BalAccType::Unreal:
                    begin
                        GenJnlLine."Bal. Account No." := AdjCurrency.GetUnrealizedGainsAccount();
                        if PrepmtAdjmt then
                            case GenJnlLine."Source Type" of
                                GenJnlLine."Source Type"::Customer:
                                    GenJnlLine."Bal. Account No." := AdjCurrency.GetSalesPDGainsAccTA();
                                GenJnlLine."Source Type"::Vendor:
                                    GenJnlLine."Bal. Account No." := AdjCurrency.GetPurchPDGainsAccTA();
                            end;
                    end;
            end
        else
            case BalAccType of
                BalAccType::Real:
                    GenJnlLine."Bal. Account No." := AdjCurrency.GetRealizedLossesAccount();
                BalAccType::Unreal:
                    begin
                        GenJnlLine."Bal. Account No." := AdjCurrency.GetUnrealizedLossesAccount();
                        if PrepmtAdjmt then
                            case GenJnlLine."Source Type" of
                                GenJnlLine."Source Type"::Customer:
                                    GenJnlLine."Bal. Account No." := AdjCurrency.GetSalesPDLossesAccTA();
                                GenJnlLine."Source Type"::Vendor:
                                    GenJnlLine."Bal. Account No." := AdjCurrency.GetPurchPDLossesAccTA();
                            end;
                    end;
            end;

        if Gains then
            CopySelectedDimToJnlLineDim(TempSelectedDimPos, TempDimSetEntry, GenJnlLine)
        else
            CopySelectedDimToJnlLineDim(TempSelectedDimNeg, TempDimSetEntry, GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure CopySelectedDimToJnlLineDim(var SelectedDim: Record "Selected Dimension"; var DimSetEntry: Record "Dimension Set Entry"; var GenJnlLine: Record "Gen. Journal Line")
    var
        DimVal: Record "Dimension Value";
    begin
        if SelectedDim.FindSet() then
            repeat
                DimVal.Get(SelectedDim."Dimension Code", SelectedDim."New Dimension Value Code");
                DimSetEntry."Dimension Code" := SelectedDim."Dimension Code";
                DimSetEntry."Dimension Value Code" := SelectedDim."New Dimension Value Code";
                DimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
                if not DimSetEntry.Insert() then
                    DimSetEntry.Modify();
            until SelectedDim.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetSelectedDims()
    begin
        if ColumnDimPos <> '' then begin
            DimSelectionBuf.CompareDimText(3, REPORT::"Adjust Exchange Rates", '', ColumnDimPos, Text12402Txt);
            SelectedDim.GetSelectedDim(UserId, 3, REPORT::"Adjust Exchange Rates", '', TempSelectedDimPos);
            TempSelectedDimPos.SetFilter("New Dimension Value Code", '<>%1', '');
        end;
        if ColumnDimNeg <> '' then begin
            DimSelectionBuf.CompareDimText(3, -REPORT::"Adjust Exchange Rates", '', ColumnDimNeg, Text12402Txt);
            SelectedDim.GetSelectedDim(UserId, 3, -REPORT::"Adjust Exchange Rates", '', TempSelectedDimNeg);
            TempSelectedDimNeg.SetFilter("New Dimension Value Code", '<>%1', '');
        end;
    end;

    local procedure CustLedgEntryToCVLedgEntry(EntryNo: Integer; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; AdjmtAmount: Decimal)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        with CustLedgEntry do begin
            Get(EntryNo);
            CVLedgEntryBuf."Document No." := "Document No.";
            CVLedgEntryBuf."Document Type" := "Document Type";
            CVLedgEntryBuf."Bal. Account Type" := CVLedgEntryBuf."Bal. Account Type"::Customer;
            CVLedgEntryBuf."Bal. Account No." := "Customer No.";
            CVLedgEntryBuf.Prepayment := Prepayment;
            CVLedgEntryBuf."Agreement No." := "Agreement No.";
        end;
    end;

    [Scope('OnPrem')]
    procedure VendLedgEntryToCVLedgEntry(EntryNo: Integer; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; AdjmtAmount: Decimal)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        with VendLedgEntry do begin
            Get(EntryNo);
            CVLedgEntryBuf."Document No." := "Document No.";
            CVLedgEntryBuf."Document Type" := "Document Type";
            CVLedgEntryBuf."Bal. Account Type" := CVLedgEntryBuf."Bal. Account Type"::Vendor;
            CVLedgEntryBuf."Bal. Account No." := "Vendor No.";
            CVLedgEntryBuf.Prepayment := Prepayment;
            CVLedgEntryBuf."Agreement No." := "Agreement No.";
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateTransactionNo(AdjustAccType: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        if not TestMode then
            case AdjustAccType of
                1:
                    begin // Customer
                        if TempDtldCustLedgEntry.Find('-') then
                            repeat
                                GLEntry.SetRange("Document Type", TempDtldCustLedgEntry."Document Type");
                                GLEntry.SetRange("Document No.", TempDtldCustLedgEntry."Document No.");
                                GLEntry.FindLast();
                                TempDtldCustLedgEntry."Transaction No." := GLEntry."Transaction No.";
                                DtldCustLedgEntry := TempDtldCustLedgEntry;
                                DtldCustLedgEntry.Insert(true);
                            until TempDtldCustLedgEntry.Next() = 0;
                    end;
                2:
                    begin // Vendor
                        if TempDtldVendLedgEntry.Find('-') then
                            repeat
                                GLEntry.SetRange("Document Type", TempDtldVendLedgEntry."Document Type");
                                GLEntry.SetRange("Document No.", TempDtldVendLedgEntry."Document No.");
                                GLEntry.FindLast();
                                TempDtldVendLedgEntry."Transaction No." := GLEntry."Transaction No.";
                                DtldVendLedgEntry := TempDtldVendLedgEntry;
                                DtldVendLedgEntry.Insert(true);
                            until TempDtldVendLedgEntry.Next() = 0;
                    end;
            end;
    end;

    [Scope('OnPrem')]
    procedure GetTaxAccRemainingAmt(AdjustAccType: Option Customer,Vendor; CVLedgerEntryNo: Integer; PostingDate3: Date; RemainingAmount: Decimal): Decimal
    var
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        RealizedGainLossAmount: Decimal;
        TaxAccUnRealizedGainLossAmt: Decimal;
    begin
        RealizedGainLossAmount := 0;
        TaxAccUnRealizedGainLossAmt := 0;

        case AdjustAccType of
            AdjustAccType::Customer:
                begin
                    DtldCustLedgEntry2.Reset();
                    DtldCustLedgEntry2.SetCurrentKey("Applied Cust. Ledger Entry No.", "Entry Type");
                    DtldCustLedgEntry2.SetRange("Applied Cust. Ledger Entry No.", CVLedgerEntryNo);
                    DtldCustLedgEntry2.SetRange("Entry Type", DtldCustLedgEntry2."Entry Type"::Application);
                    DtldCustLedgEntry2.SetRange("Posting Date", 0D, PostingDate3);
                    DtldCustLedgEntry2.SetRange("Prepmt. Diff.", true);
                    if DtldCustLedgEntry2.FindSet() then
                        repeat
                            RealizedGainLossAmount := RealizedGainLossAmount + DtldCustLedgEntry2."Amount (LCY)";
                        until DtldCustLedgEntry2.Next() = 0;

                    DtldCustLedgEntry2.Reset();
                    DtldCustLedgEntry2.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date", "Prepmt. Diff. in TA");
                    DtldCustLedgEntry2.SetRange("Cust. Ledger Entry No.", CVLedgerEntryNo);
                    DtldCustLedgEntry2.SetRange(
                      "Entry Type",
                      DtldCustLedgEntry2."Entry Type"::"Unrealized Loss",
                      DtldCustLedgEntry2."Entry Type"::"Realized Gain");
                    DtldCustLedgEntry2.SetRange("Posting Date", 0D, PostingDate3);
                    DtldCustLedgEntry2.SetRange("Prepmt. Diff. in TA", true);
                    DtldCustLedgEntry2.CalcSums("Amount (LCY)");
                    TaxAccUnRealizedGainLossAmt := DtldCustLedgEntry2."Amount (LCY)";
                end;
            AdjustAccType::Vendor:
                begin
                    DtldVendLedgEntry2.Reset();
                    DtldVendLedgEntry2.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                    DtldVendLedgEntry2.SetRange("Applied Vend. Ledger Entry No.", CVLedgerEntryNo);
                    DtldVendLedgEntry2.SetRange("Entry Type", DtldVendLedgEntry2."Entry Type"::Application);
                    DtldVendLedgEntry2.SetRange("Posting Date", 0D, PostingDate3);
                    DtldVendLedgEntry2.SetRange("Prepmt. Diff.", true);
                    if DtldVendLedgEntry2.FindSet() then
                        repeat
                            RealizedGainLossAmount := RealizedGainLossAmount + DtldVendLedgEntry2."Amount (LCY)";
                        until DtldVendLedgEntry2.Next() = 0;

                    DtldVendLedgEntry2.Reset();
                    DtldVendLedgEntry2.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date", "Prepmt. Diff. in TA");
                    DtldVendLedgEntry2.SetRange("Vendor Ledger Entry No.", CVLedgerEntryNo);
                    DtldVendLedgEntry2.SetRange(
                      "Entry Type",
                      DtldVendLedgEntry2."Entry Type"::"Unrealized Loss",
                      DtldVendLedgEntry2."Entry Type"::"Realized Gain");
                    DtldVendLedgEntry2.SetRange("Posting Date", 0D, PostingDate3);
                    DtldVendLedgEntry2.SetRange("Prepmt. Diff. in TA", true);
                    DtldVendLedgEntry2.CalcSums("Amount (LCY)");
                    TaxAccUnRealizedGainLossAmt := DtldVendLedgEntry2."Amount (LCY)";
                end;
        end;

        exit(RemainingAmount + TaxAccUnRealizedGainLossAmt - RealizedGainLossAmount);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeOnInitReport(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetJnlLineDefDim(var GenJnlLine: Record "Gen. Journal Line"; var DimSetEntry: Record "Dimension Set Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDtldCustLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDtldVendLedgerEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReport(ExchRateAdjReg: Record "Exch. Rate Adjmt. Reg."; PostingDate: Date);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustomerAfterGetRecordOnAfterFindCustLedgerEntriesToAdjust(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustCustomerLedgerEntryOnBeforeInitDtldCustLedgEntry(var Customer: Record Customer; CusLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustVendorLedgerEntryOnBeforeInitDtldVendLedgEntry(var Vendor: Record Vendor; VendLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRealizedGainsAccount(Currency: Record Currency; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRealizedLossesAccount(Currency: Record Currency; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnrealizedGainsAccount(Currency: Record Currency; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnrealizedLossesAccount(Currency: Record Currency; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCustAdjmt(var AdjExchRateBuffer: Record "Adjust Exchange Rate Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var TempDimSetEntry: Record "Dimension Set Entry" temporary; var TempAdjExchRateBuffer: Record "Adjust Exchange Rate Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostVendAdjmt(var AdjExchRateBuffer: Record "Adjust Exchange Rate Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var TempDimSetEntry: Record "Dimension Set Entry" temporary; var TempAdjExchRateBuffer: Record "Adjust Exchange Rate Buffer" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var DimSetEntry: Record "Dimension Set Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendorAfterGetRecordOnAfterFindVendLedgerEntriesToAdjust(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGenJnlLineOnAfterGenJnlPostLineRun(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGenJnlLineOnBeforeGenJnlPostLineRun(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAdjExchRateBufferUpdate(var BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAdjmt(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostCustAdjmt(var AdjExchRateBuffer: Record "Adjust Exchange Rate Buffer")
    begin
    end;
}
#endif
