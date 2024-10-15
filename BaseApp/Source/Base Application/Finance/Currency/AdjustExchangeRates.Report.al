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
using Microsoft.HumanResources.Payables;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Environment.Configuration;
using System.Environment;
using System.Utilities;

report 595 "Adjust Exchange Rates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Adjust Exchange Rates';
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "Employee Ledger Entry" = rimd,
                  TableData "Exch. Rate Adjmt. Reg." = rimd,
                  TableData "VAT Entry" = rimd,
                  TableData "Detailed Cust. Ledg. Entry" = rimd,
                  TableData "Detailed Vendor Ledg. Entry" = rimd,
                  TableData "Detailed Employee Ledger Entry" = rimd,
                  TableData "Cartera Doc." = rimd,
                  TableData "Posted Cartera Doc." = rimd,
                  TableData "Closed Cartera Doc." = rimd;
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
                                  TotalAdjBase, TotalAdjBaseLCY, TotalAdjAmount, 0, 0, 0, PostingDate, '', '');
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
                Modify();

                "Currency Factor" := CurrExchRate.ExchangeRateAdjmt(PostingDate, Code);

                TempCurrencyToAdjust := Currency;
                TempCurrencyToAdjust.Insert();
            end;

            trigger OnPostDataItem()
            begin
                if (Code = '') and (AdjCust or AdjVend or AdjEmpl or AdjBank) then
                    Error(Text011Err);
            end;

            trigger OnPreDataItem()
            begin
                CheckPostingDate();
                if (not AdjCust) and (not AdjVend) and (not AdjEmpl) and (not AdjBank) then
                    CurrReport.Break();

                Window.Open(
                  Text006Txt +
                  Text007Txt +
                  Text008Txt +
                  Text009Txt +
                  Text010Txt +
                  Text018Txt);

                CustNoTotal := Customer.Count();
                VendNoTotal := Vendor.Count();
                EmplNoTotal := Employee.Count();
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
                    AdjustCustomerLedgerEntry(CustLedgerEntry, PostingDate);
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
                    AdjustVendorLedgerEntry(VendorLedgerEntry, PostingDate);
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
        dataitem(Employee; Employee)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            dataitem(EmployeeLedgerEntryLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem("Detailed Employee Ledger Entry"; "Detailed Employee Ledger Entry")
                {
                    DataItemTableView = sorting("Employee Ledger Entry No.", "Posting Date");

                    trigger OnAfterGetRecord()
                    begin
                        AdjustEmployeeLedgerEntry(EmployeeLedgerEntry, "Posting Date");
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetCurrentKey("Employee Ledger Entry No.");
                        SetRange("Employee Ledger Entry No.", EmployeeLedgerEntry."Entry No.");
                        SetFilter("Posting Date", '%1..', CalcDate('<+1D>', PostingDate));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TempDtldEmplLedgEntrySums.DeleteAll();

                    if FirstEntry then begin
                        TempEmployeeLedgerEntry.Find('-');
                        FirstEntry := false
                    end else
                        if TempEmployeeLedgerEntry.Next() = 0 then
                            CurrReport.Break();
                    EmployeeLedgerEntry.Get(TempEmployeeLedgerEntry."Entry No.");

                    AdjustEmployeeLedgerEntry(EmployeeLedgerEntry, PostingDate);
                end;

                trigger OnPreDataItem()
                begin
                    if not TempEmployeeLedgerEntry.Find('-') then
                        CurrReport.Break();
                    FirstEntry := true;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                EmplNo := EmplNo + 1;
                Window.Update(5, Round(EmplNo / EmplNoTotal * 10000, 1));

                PrepareTempEmplLedgEntry(Employee, TempEmployeeLedgerEntry);

                OnEmployeeAfterGetRecordOnAfterFindEmplLedgerEntriesToAdjust(TempEmployeeLedgerEntry);
            end;

            trigger OnPostDataItem()
            begin
                if EmplNo <> 0 then
                    HandlePostAdjmt(3); // Employee
            end;

            trigger OnPreDataItem()
            begin
                if not AdjEmpl then
                    CurrReport.Break();

                DtldEmplLedgEntry.LockTable();
                EmployeeLedgerEntry.LockTable();

                VendNo := 0;
                if DtldEmplLedgEntry.Find('+') then
                    NewEntryNo := DtldEmplLedgEntry."Entry No." + 1
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
                    field(AdjEmplAcc; AdjEmpl)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Employees';
                        ToolTip = 'Specifies if you want to adjust employees for currency fluctuations.';
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
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PostingDescription = '' then
                PostingDescription := Text016Txt;
            if not (AdjCust or AdjVend or AdjBank or AdjGLAcc or AdjEmpl) then begin
                AdjCust := true;
                AdjVend := true;
                AdjEmpl := true;
                AdjBank := true;
            end;
            GLSetup.Get();
            IsJournalTemplNameVisible := GLSetup."Journal Templ. Name Mandatory";
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        FeatureKeyManagement: Codeunit "Feature Key Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInitReport(IsHandled);
        if IsHandled then
            exit;

        if not EnvironmentInformation.IsOnPrem() then
            if FeatureKeyManagement.IsExtensibleExchangeRateAdjustmentEnabled(false) then begin
                Report.Run(Report::"Exch. Rate Adjustment");
                CurrReport.Quit();
            end;
    end;

    trigger OnPostReport()
    begin
        if GenJnlPostLine.IsGLEntryInconsistent() then
            GenJnlPostLine.ShowInconsistentEntries()
        else begin
            UpdateAnalysisView.UpdateAll(0, true);
            if TotalCustomersAdjusted + TotalVendorsAdjusted + TotalEmployeesAdjusted + TotalBankAccountsAdjusted + TotalGLAccountsAdjusted < 1 then
                Message(NothingToAdjustMsg)
            else
                Message(RatesAdjustedMsg);
        end;

        OnAfterPostReport(ExchRateAdjReg, PostingDate);
    end;

    trigger OnPreReport()
    var
        NoSeries: Codeunit "No. Series";
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
            Clear(PostingDocNo);
            GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
            GenJnlBatch.TestField("No. Series");
            PostingDocNo := NoSeries.GetNextNo(GenJnlBatch."No. Series", PostingDate);
        end else
            if PostingDocNo = '' then
                Error(Text000Err);
        if (not AdjCust) and (not AdjVend) and (not AdjEmpl) and (not AdjBank) and AdjGLAcc then
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

            if VATPostingSetup2.Find('-') then
                repeat
                    if VATPostingSetup2."VAT Calculation Type" <> VATPostingSetup2."VAT Calculation Type"::"Sales Tax" then begin
                        CheckExchRateAdjustment(
                          VATPostingSetup2."Purchase VAT Account", VATPostingSetup2.TableCaption(), VATPostingSetup2.FieldCaption("Purchase VAT Account"));
                        CheckExchRateAdjustment(
                          VATPostingSetup2."Reverse Chrg. VAT Acc.", VATPostingSetup2.TableCaption(), VATPostingSetup2.FieldCaption("Reverse Chrg. VAT Acc."));
                        CheckExchRateAdjustment(
                          VATPostingSetup2."Purch. VAT Unreal. Account", VATPostingSetup2.TableCaption(), VATPostingSetup2.FieldCaption("Purch. VAT Unreal. Account"));
                        CheckExchRateAdjustment(
                          VATPostingSetup2."Reverse Chrg. VAT Unreal. Acc.", VATPostingSetup2.TableCaption(), VATPostingSetup2.FieldCaption("Reverse Chrg. VAT Unreal. Acc."));
                        CheckExchRateAdjustment(
                          VATPostingSetup2."Sales VAT Account", VATPostingSetup2.TableCaption(), VATPostingSetup2.FieldCaption("Sales VAT Account"));
                        CheckExchRateAdjustment(
                          VATPostingSetup2."Sales VAT Unreal. Account", VATPostingSetup2.TableCaption(), VATPostingSetup2.FieldCaption("Sales VAT Unreal. Account"));
                    end;
                until VATPostingSetup2.Next() = 0;

            if TaxJurisdiction2.Find('-') then
                repeat
                    CheckExchRateAdjustment(
                      TaxJurisdiction2."Tax Account (Purchases)", TaxJurisdiction2.TableCaption(), TaxJurisdiction2.FieldCaption("Tax Account (Purchases)"));
                    CheckExchRateAdjustment(
                      TaxJurisdiction2."Reverse Charge (Purchases)", TaxJurisdiction2.TableCaption(), TaxJurisdiction2.FieldCaption("Reverse Charge (Purchases)"));
                    CheckExchRateAdjustment(
                      TaxJurisdiction2."Unreal. Tax Acc. (Purchases)", TaxJurisdiction2.TableCaption(), TaxJurisdiction2.FieldCaption("Unreal. Tax Acc. (Purchases)"));
                    CheckExchRateAdjustment(
                      TaxJurisdiction2."Unreal. Rev. Charge (Purch.)", TaxJurisdiction2.TableCaption(), TaxJurisdiction2.FieldCaption("Unreal. Rev. Charge (Purch.)"));
                    CheckExchRateAdjustment(
                      TaxJurisdiction2."Tax Account (Sales)", TaxJurisdiction2.TableCaption(), TaxJurisdiction2.FieldCaption("Tax Account (Sales)"));
                    CheckExchRateAdjustment(
                      TaxJurisdiction2."Unreal. Tax Acc. (Sales)", TaxJurisdiction2.TableCaption(), TaxJurisdiction2.FieldCaption("Unreal. Tax Acc. (Sales)"));
                until TaxJurisdiction2.Next() = 0;

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
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        TempDtldEmplLedgEntry: Record "Detailed Employee Ledger Entry" temporary;
        TempDtldEmplLedgEntrySums: Record "Detailed Employee Ledger Entry" temporary;
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
        CarteraDoc: Record "Cartera Doc.";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary;
        GenJnlLineReq: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        CarteraSetup: Record "Cartera Setup";
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
        EmplNo: Decimal;
        EmplNoTotal: Decimal;
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
        AdjEmpl: Boolean;
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
        RatesAdjustedMsg: Label 'One or more currency exchange rates have been adjusted.';
        NothingToAdjustMsg: Label 'There is nothing to adjust.';
        TotalBankAccountsAdjusted: Integer;
        TotalCustomersAdjusted: Integer;
        TotalVendorsAdjusted: Integer;
        TotalEmployeesAdjusted: Integer;
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
        Text018Txt: Label 'Employee          @5@@@@@@@@@@@@@\';
        PleaseEnterErr: Label 'Please enter a %1.', Comment = '%1 - field caption';

    local procedure PostAdjmt(GLAccNo: Code[20]; PostingAmount: Decimal; AdjBase2: Decimal; CurrencyCode2: Code[10]; var DimSetEntry: Record "Dimension Set Entry"; PostingDate2: Date; ICCode: Code[20]) TransactionNo: Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        if PostingAmount = 0 then
            exit;

        GenJnlLine.Init();
        GenJnlLine.Validate("Posting Date", PostingDate2);
        GenJnlLine."Document No." := PostingDocNo;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", GLAccNo);
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
        PostGenJnlLine(GenJnlLine, TempDimSetEntry);

        if CurrAdjAmount <> 0 then begin
            GetDimSetEntry(GetDimCombID(TempDimBuf), TempDimSetEntry);
            if CurrAdjAmount > 0 then
                AccNo := GetRealizedGainsAccount(Currency)
            else
                AccNo := GetRealizedLossesAccount(Currency);
            PostAdjmt(
                AccNo, -CurrAdjAmount, CurrAdjBase, BankAccount."Currency Code", TempDimSetEntry, PostingDate, '');
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

    local procedure PostCustAdjmt(AdjExchRateBuffer: Record "Adjust Exchange Rate Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var TempDimSetEntry: Record "Dimension Set Entry" temporary)
    var
        CustPostingGr: Record "Customer Posting Group";
    begin
        OnBeforePostCustAdjmt(AdjExchRateBuffer, TempDtldCVLedgEntryBuf, TempDimSetEntry, TempAdjExchRateBuffer);
        CustPostingGr.Get(TempAdjExchRateBuffer."Posting Group");
        TempDtldCVLedgEntryBuf."Transaction No." :=
            PostAdjmt(
                CustPostingGr.GetReceivablesAccount(), AdjExchRateBuffer.AdjAmount,
                AdjExchRateBuffer.AdjBase, AdjExchRateBuffer."Currency Code", TempDimSetEntry,
                AdjExchRateBuffer."Posting Date", AdjExchRateBuffer."IC Partner Code");
        OnAfterPostCustAdjmt(AdjExchRateBuffer);
        if TempDtldCVLedgEntryBuf.Insert() then;
        InsertExchRateAdjmtReg(
            "Exch. Rate Adjmt. Account Type"::Customer, AdjExchRateBuffer."Posting Group", AdjExchRateBuffer."Currency Code");
        TempDtldCVLedgEntryBuf."Exch. Rate Adjmt. Reg. No." := ExchRateAdjReg."No.";
        TempDtldCVLedgEntryBuf.Modify();
        TotalCustomersAdjusted += 1;
    end;

    local procedure PostVendAdjmt(AdjExchRateBuffer: Record "Adjust Exchange Rate Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var TempDimSetEntry: Record "Dimension Set Entry" temporary)
    var
        VendPostingGr: Record "Vendor Posting Group";
    begin
        OnBeforePostVendAdjmt(AdjExchRateBuffer, TempDtldCVLedgEntryBuf, TempDimSetEntry, TempAdjExchRateBuffer);
        VendPostingGr.Get(TempAdjExchRateBuffer."Posting Group");
        TempDtldCVLedgEntryBuf."Transaction No." :=
            PostAdjmt(
                VendPostingGr.GetPayablesAccount(), AdjExchRateBuffer.AdjAmount,
                AdjExchRateBuffer.AdjBase, AdjExchRateBuffer."Currency Code", TempDimSetEntry,
                AdjExchRateBuffer."Posting Date", AdjExchRateBuffer."IC Partner Code");
        if TempDtldCVLedgEntryBuf.Insert() then;
        InsertExchRateAdjmtReg(
            "Exch. Rate Adjmt. Account Type"::Vendor, AdjExchRateBuffer."Posting Group", AdjExchRateBuffer."Currency Code");
        TempDtldCVLedgEntryBuf."Exch. Rate Adjmt. Reg. No." := ExchRateAdjReg."No.";
        TempDtldCVLedgEntryBuf.Modify();
        TotalVendorsAdjusted += 1;
    end;

    local procedure PostEmplAdjmt(AdjExchRateBuffer: Record "Adjust Exchange Rate Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var TempDimSetEntry: Record "Dimension Set Entry" temporary)
    var
        EmplPostingGr: Record "Employee Posting Group";
    begin
        OnBeforePostEmplAdjmt(AdjExchRateBuffer, TempDtldCVLedgEntryBuf, TempDimSetEntry, TempAdjExchRateBuffer);
        EmplPostingGr.Get(TempAdjExchRateBuffer."Posting Group");
        TempDtldCVLedgEntryBuf."Transaction No." :=
            PostAdjmt(
                EmplPostingGr.GetPayablesAccount(), AdjExchRateBuffer.AdjAmount,
                AdjExchRateBuffer.AdjBase, AdjExchRateBuffer."Currency Code", TempDimSetEntry,
                AdjExchRateBuffer."Posting Date", AdjExchRateBuffer."IC Partner Code");
        if TempDtldCVLedgEntryBuf.Insert() then;
        InsertExchRateAdjmtReg(
            "Exch. Rate Adjmt. Account Type"::Employee, AdjExchRateBuffer."Posting Group", AdjExchRateBuffer."Currency Code");
        TempDtldCVLedgEntryBuf."Exch. Rate Adjmt. Reg. No." := ExchRateAdjReg."No.";
        TempDtldCVLedgEntryBuf.Modify();
        TotalEmployeesAdjusted += 1;
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
        if TempCurrencyToAdjust.Code <> CurrencyCode then
            TempCurrencyToAdjust.Get(CurrencyCode);

        ExchRateAdjReg."No." := ExchRateAdjReg."No." + 1;
        ExchRateAdjReg."Creation Date" := PostingDate;
        ExchRateAdjReg."Account Type" := AdjustAccType;
        ExchRateAdjReg."Posting Group" := PostingGrCode;
        ExchRateAdjReg."Currency Code" := TempCurrencyToAdjust.Code;
        ExchRateAdjReg."Currency Factor" := TempCurrencyToAdjust."Currency Factor";
        ExchRateAdjReg."Adjusted Base" := TempAdjExchRateBuffer.AdjBase;
        ExchRateAdjReg."Adjusted Base (LCY)" := TempAdjExchRateBuffer.AdjBaseLCY;
        ExchRateAdjReg."Adjusted Amt. (LCY)" := TempAdjExchRateBuffer.AdjAmount;
        ExchRateAdjReg.Insert();
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
        AdjEmpl := NewAdjCustVendBank;
        AdjGLAcc := NewAdjGLAcc;
    end;

    local procedure AdjExchRateBufferUpdate(CurrencyCode2: Code[10]; PostingGroup2: Code[20]; AdjBase2: Decimal; AdjBaseLCY2: Decimal; AdjAmount2: Decimal; GainsAmount2: Decimal; LossesAmount2: Decimal; DimEntryNo: Integer; Postingdate2: Date; ICCode: Code[20]; AccNo: Code[20]): Integer
    begin
        TempAdjExchRateBuffer.Init();
        OK := TempAdjExchRateBuffer.Get(CurrencyCode2, PostingGroup2, AccNo, DimEntryNo, Postingdate2, ICCode);

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
            TempAdjExchRateBuffer."Account No." := AccNo;
            TempAdjExchRateBuffer.Insert();
        end else
            TempAdjExchRateBuffer.Modify();

        exit(TempAdjExchRateBuffer.Index);
    end;

    local procedure HandlePostAdjmt(AdjustAccType: Integer)
    var
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
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
                                PostCustAdjmt(TempAdjExchRateBuffer, TempDtldCVLedgEntryBuf, TempDimSetEntry);
                            2: // Vendor
                                PostVendAdjmt(TempAdjExchRateBuffer, TempDtldCVLedgEntryBuf, TempDimSetEntry);
                            3: // Empoyee
                                PostEmplAdjmt(TempAdjExchRateBuffer, TempDtldCVLedgEntryBuf, TempDimSetEntry);
                        end;
                until TempAdjExchRateBuffer.Next() = 0;

                TempCurrencyToAdjust.Get(TempAdjExchRateBuffer2."Currency Code");
                if TempAdjExchRateBuffer2.TotalGainsAmount <> 0 then
                    PostAdjmt(
                        GetUnrealizedGainsAccount(TempCurrencyToAdjust),
                        -TempAdjExchRateBuffer2.TotalGainsAmount, -TempAdjExchRateBuffer2.AdjBase,
                        TempAdjExchRateBuffer2."Currency Code", TempDimSetEntry,
                        TempAdjExchRateBuffer2."Posting Date", TempAdjExchRateBuffer2."IC Partner Code");
                if TempAdjExchRateBuffer2.TotalLossesAmount <> 0 then
                    PostAdjmt(
                        GetUnrealizedLossesAccount(TempCurrencyToAdjust),
                        -TempAdjExchRateBuffer2.TotalLossesAmount, -TempAdjExchRateBuffer2.AdjBase,
                        TempAdjExchRateBuffer2."Currency Code", TempDimSetEntry,
                        TempAdjExchRateBuffer2."Posting Date", TempAdjExchRateBuffer2."IC Partner Code");
            until TempAdjExchRateBuffer2.Next() = 0;

        case AdjustAccType of
            1: // Customer
                InsertCustLedgEntries(TempDtldCustLedgEntry, TempDtldCVLedgEntryBuf);
            2: // Vendor
                InsertVendLedgEntries(TempDtldVendLedgEntry, TempDtldCVLedgEntryBuf);
            3: // Employee
                InsertEmplLedgEntries(TempDtldEmplLedgEntry, TempDtldCVLedgEntryBuf);
        end;

        ResetTempAdjmtBuffer();
        ResetTempAdjmtBuffer2();

        TempDtldCustLedgEntry.Reset();
        TempDtldCustLedgEntry.DeleteAll();
        TempDtldVendLedgEntry.Reset();
        TempDtldVendLedgEntry.DeleteAll();
        TempDtldEmplLedgEntry.Reset();
        TempDtldEmplLedgEntry.DeleteAll();
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
                    '', '',
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

    local procedure InsertEmplLedgEntries(var TempDtldEmplLedgEntry: Record "Detailed Employee Ledger Entry" temporary; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary)
    var
        DtldEmplLedgEntry2: Record "Detailed Employee Ledger Entry";
        GLEntry: Record "G/L Entry";
        LastEntryNo: Integer;
        LastTransactionNo: Integer;
    begin
        GLEntry.GetLastEntry(LastEntryNo, LastTransactionNo);

        if TempDtldEmplLedgEntry.Find('-') then
            repeat
                if TempDtldCVLedgEntryBuf.Get(TempDtldEmplLedgEntry."Transaction No.") then
                    TempDtldEmplLedgEntry."Transaction No." := TempDtldCVLedgEntryBuf."Transaction No."
                else
                    TempDtldEmplLedgEntry."Transaction No." := LastTransactionNo;
                DtldEmplLedgEntry2 := TempDtldEmplLedgEntry;
                DtldEmplLedgEntry2."Exch. Rate Adjmt. Reg. No." := TempDtldCVLedgEntryBuf."Exch. Rate Adjmt. Reg. No.";
                DtldEmplLedgEntry2.Insert(true);
            until TempDtldEmplLedgEntry.Next() = 0;
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

    local procedure PrepareTempEmplLedgEntry(Employee: Record Employee; var TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary);
    var
        EmployeeLedgerEntry2: Record "Employee Ledger Entry";
        DtldEmplLedgEntry2: Record "Detailed Employee Ledger Entry";
    begin
        TempEmployeeLedgerEntry.DeleteAll();

        Currency.CopyFilter(Code, EmployeeLedgerEntry2."Currency Code");
        EmployeeLedgerEntry2.FilterGroup(2);
        EmployeeLedgerEntry2.SetFilter("Currency Code", '<>%1', '');
        EmployeeLedgerEntry2.FilterGroup(0);

        DtldEmplLedgEntry2.Reset();
        DtldEmplLedgEntry2.SetCurrentKey("Employee No.", "Posting Date", "Entry Type");
        DtldEmplLedgEntry2.SetRange("Employee No.", Employee."No.");
        DtldEmplLedgEntry2.SetRange("Posting Date", CalcDate('<+1D>', EndDate), DMY2Date(31, 12, 9999));
        if DtldEmplLedgEntry2.Find('-') then
            repeat
                EmployeeLedgerEntry2."Entry No." := DtldEmplLedgEntry2."Employee Ledger Entry No.";
                if EmployeeLedgerEntry2.Find('=') then
                    if (EmployeeLedgerEntry2."Posting Date" >= StartDate) and
                        (EmployeeLedgerEntry2."Posting Date" <= EndDate)
                    then begin
                        TempEmployeeLedgerEntry."Entry No." := EmployeeLedgerEntry2."Entry No.";
                        if TempEmployeeLedgerEntry.Insert() then;
                    end;
            until DtldEmplLedgEntry2.Next() = 0;

        EmployeeLedgerEntry2.SetCurrentKey("Employee No.", Open);
        EmployeeLedgerEntry2.SetRange("Employee No.", Employee."No.");
        EmployeeLedgerEntry2.SetRange(Open, true);
        EmployeeLedgerEntry2.SetRange("Posting Date", 0D, EndDate);
        if EmployeeLedgerEntry2.Find('-') then
            repeat
                TempEmployeeLedgerEntry."Entry No." := EmployeeLedgerEntry2."Entry No.";
                if TempEmployeeLedgerEntry.Insert() then;
            until EmployeeLedgerEntry2.Next() = 0;
        EmployeeLedgerEntry2.Reset();
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

        ExchRateAdjReg."No." := ExchRateAdjReg."No." + 1;
        ExchRateAdjReg."Creation Date" := PostingDate;
        ExchRateAdjReg."Account Type" := ExchRateAdjReg."Account Type"::"G/L Account";
        ExchRateAdjReg."Posting Group" := '';
        ExchRateAdjReg."Currency Code" := GLSetup."Additional Reporting Currency";
        ExchRateAdjReg."Currency Factor" := CurrExchRate2."Adjustment Exch. Rate Amount";
        ExchRateAdjReg."Adjusted Base" := 0;
        ExchRateAdjReg."Adjusted Base (LCY)" := GLNetChangeBase;
        ExchRateAdjReg."Adjusted Amt. (LCY)" := GLAmtTotal;
        ExchRateAdjReg."Adjusted Base (Add.-Curr.)" := GLAddCurrNetChangeBase;
        ExchRateAdjReg."Adjusted Amt. (Add.-Curr.)" := GLAddCurrAmtTotal;
        ExchRateAdjReg.Insert();
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

    local procedure HandleEmplDebitCredit(Correction: Boolean; AdjAmount: Decimal)
    begin
        if (AdjAmount > 0) and not Correction or
           (AdjAmount < 0) and Correction
        then begin
            TempDtldEmplLedgEntry."Debit Amount (LCY)" := AdjAmount;
            TempDtldEmplLedgEntry."Credit Amount (LCY)" := 0;
        end else begin
            TempDtldEmplLedgEntry."Debit Amount (LCY)" := 0;
            TempDtldEmplLedgEntry."Credit Amount (LCY)" := -AdjAmount;
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
            OnAdjustCustomerLedgerEntryOnBeforeInitDtldCustLedgEntry(Customer, CustLedgerEntry);
            InitDtldCustLedgEntry(CustLedgerEntry, TempDtldCustLedgEntry);
            TempDtldCustLedgEntry."Entry No." := NewEntryNo;
            TempDtldCustLedgEntry."Posting Date" := PostingDate2;
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
                                    GetCustPostingGrAcc(CustLedgerEntry));
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
                                    GetCustPostingGrAcc(CustLedgerEntry));
                            TempDtldCustLedgEntry."Transaction No." := AdjExchRateBufIndex;
                            ModifyTempDtldCustomerLedgerEntry();
                            Adjust := false;
                        end;
                end;

            CreateCustCarteraDocuments(CustLedgerEntry, CurrAdjAmount, OldAdjAmount);

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
                    GetCustPostingGrAcc(CustLedgerEntry));
            TempDtldCustLedgEntry."Transaction No." := AdjExchRateBufIndex;
            ModifyTempDtldCustomerLedgerEntry();
        end;
    end;

    local procedure CreateCustCarteraDocuments(var CustLedgerEntry: Record "Cust. Ledger Entry"; AdjAmount: Decimal; OldAdjAmount: Decimal)
    begin
        CustLedgerEntry.CalcFields(
            Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)", "Original Amt. (LCY)",
            "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");
        if (CustLedgerEntry."Document Situation" <> CustLedgerEntry."Document Situation"::" ") and CarteraSetup.ReadPermission then
            case CustLedgerEntry."Document Situation" of
                CustLedgerEntry."Document Situation"::Cartera:
                    if CarteraDoc.Get(CarteraDoc.Type::Receivable, CustLedgerEntry."Entry No.") then begin
                        CarteraDoc."Remaining Amt. (LCY)" := CustLedgerEntry."Remaining Amt. (LCY)" + AdjAmount;
                        CarteraDoc."Original Amount (LCY)" := CustLedgerEntry."Original Amt. (LCY)" + AdjAmount;
                        CarteraDoc."Adjusted Amount" := AdjAmount;
                        CarteraDoc.Adjusted := true;
                        CarteraDoc.Modify();
                    end;
                CustLedgerEntry."Document Situation"::"Posted BG/PO":
                    if PostedCarteraDoc.Get(PostedCarteraDoc.Type::Receivable, CustLedgerEntry."Entry No.") then begin
                        PostedCarteraDoc."Remaining Amt. (LCY)" := CustLedgerEntry."Remaining Amt. (LCY)";
                        PostedCarteraDoc."Adjusted Amount" := AdjAmount + OldAdjAmount;
                        PostedCarteraDoc.ReAdjusted := true;
                        PostedCarteraDoc.Modify();
                    end;
                CustLedgerEntry."Document Situation"::"Closed BG/PO",
                CustLedgerEntry."Document Situation"::"Closed Documents":
                    if ClosedCarteraDoc.Get(ClosedCarteraDoc.Type::Receivable, CustLedgerEntry."Entry No.") then begin
                        ClosedCarteraDoc."Remaining Amt. (LCY)" := CustLedgerEntry."Remaining Amt. (LCY)";
                        ClosedCarteraDoc.Modify();
                    end;
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
            OnAdjustVendorLedgerEntryOnBeforeInitDtldVendLedgEntry(Vendor, VendLedgerEntry);
            InitDtldVendLedgEntry(VendLedgerEntry, TempDtldVendLedgEntry);
            TempDtldVendLedgEntry."Entry No." := NewEntryNo;
            TempDtldVendLedgEntry."Posting Date" := PostingDate2;
            TempDtldVendLedgEntry."Document No." := PostingDocNo;

            Correction :=
                (VendLedgerEntry."Debit Amount" < 0) or
                (VendLedgerEntry."Credit Amount" < 0) or
                (VendLedgerEntry."Debit Amount (LCY)" < 0) or
                (VendLedgerEntry."Credit Amount (LCY)" < 0);

            CreateVendCarteraDocuments(VendLedgerEntry, CurrAdjAmount, OldAdjAmount);

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
                                    GetVendPostingGrAcc(VendLedgerEntry));
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
                                    GetVendPostingGrAcc(VendLedgerEntry));
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
                    GetVendPostingGrAcc(VendLedgerEntry));
            TempDtldVendLedgEntry."Transaction No." := AdjExchRateBufIndex;
            ModifyTempDtldVendorLedgerEntry();
        end;
    end;

    procedure AdjustEmployeeLedgerEntry(EmplLedgerEntry: Record "Employee Ledger Entry"; PostingDate2: Date)
    var
        DimSetEntry: Record "Dimension Set Entry";
        DimEntryNo: Integer;
        OldAdjAmount: Decimal;
        Adjust: Boolean;
        AdjExchRateBufIndex: Integer;
    begin
        EmplLedgerEntry.SetRange("Date Filter", 0D, PostingDate2);
        TempCurrencyToAdjust.Get(EmplLedgerEntry."Currency Code");
        GainsAmount := 0;
        LossesAmount := 0;
        OldAdjAmount := 0;
        Adjust := false;

        TempDimBuf.Reset();
        TempDimBuf.DeleteAll();
        DimSetEntry.SetRange("Dimension Set ID", EmplLedgerEntry."Dimension Set ID");
        CopyDimSetEntryToDimBuf(DimSetEntry, TempDimBuf);
        DimEntryNo := GetDimCombID(TempDimBuf);

        EmplLedgerEntry.CalcFields(
            Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)", "Original Amt. (LCY)",
            "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");

        // Calculate Old Unrealized GainLoss
        SetUnrealizedGainLossFilterEmpl(DtldEmplLedgEntry, EmplLedgerEntry."Entry No.");
        DtldEmplLedgEntry.CalcSums("Amount (LCY)");

        SetUnrealizedGainLossFilterEmpl(TempDtldEmplLedgEntrySums, EmplLedgerEntry."Entry No.");
        TempDtldEmplLedgEntrySums.CalcSums("Amount (LCY)");
        OldAdjAmount := DtldEmplLedgEntry."Amount (LCY)" + TempDtldEmplLedgEntrySums."Amount (LCY)";
        EmplLedgerEntry."Remaining Amt. (LCY)" += TempDtldEmplLedgEntrySums."Amount (LCY)";
        EmplLedgerEntry."Debit Amount (LCY)" += TempDtldEmplLedgEntrySums."Amount (LCY)";
        EmplLedgerEntry."Credit Amount (LCY)" += TempDtldEmplLedgEntrySums."Amount (LCY)";
        TempDtldEmplLedgEntrySums.Reset();

        // Modify Currency factor on Employee Ledger Entry
        if EmplLedgerEntry."Adjusted Currency Factor" <> TempCurrencyToAdjust."Currency Factor" then begin
            EmplLedgerEntry."Adjusted Currency Factor" := TempCurrencyToAdjust."Currency Factor";
            EmplLedgerEntry.Modify();
        end;

        // Calculate New Unrealized Gains and Losses
        CurrAdjAmount :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCYAdjmt(
                    PostingDate2, TempCurrencyToAdjust.Code, EmplLedgerEntry."Remaining Amount", TempCurrencyToAdjust."Currency Factor")) -
                EmplLedgerEntry."Remaining Amt. (LCY)";

        if CurrAdjAmount <> 0 then begin
            OnAdjustEmployeeLedgerEntryOnBeforeInitDtldEmplLedgEntry(Employee, EmplLedgerEntry);
            InitDtldEmplLedgEntry(EmplLedgerEntry, TempDtldEmplLedgEntry);
            TempDtldEmplLedgEntry."Entry No." := NewEntryNo;
            TempDtldEmplLedgEntry."Posting Date" := PostingDate2;
            TempDtldEmplLedgEntry."Document No." := PostingDocNo;

            Correction :=
                (EmplLedgerEntry."Debit Amount" < 0) or
                (EmplLedgerEntry."Credit Amount" < 0) or
                (EmplLedgerEntry."Debit Amount (LCY)" < 0) or
                (EmplLedgerEntry."Credit Amount (LCY)" < 0);

            if OldAdjAmount > 0 then
                case true of
                    (CurrAdjAmount > 0):
                        begin
                            TempDtldEmplLedgEntry."Amount (LCY)" := CurrAdjAmount;
                            TempDtldEmplLedgEntry."Entry Type" := TempDtldEmplLedgEntry."Entry Type"::"Unrealized Gain";
                            HandleEmplDebitCredit(Correction, TempDtldEmplLedgEntry."Amount (LCY)");
                            InsertTempDtldEmployeeLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            GainsAmount := CurrAdjAmount;
                            Adjust := true;
                        end;
                    (CurrAdjAmount < 0):
                        if -CurrAdjAmount <= OldAdjAmount then begin
                            TempDtldEmplLedgEntry."Amount (LCY)" := CurrAdjAmount;
                            TempDtldEmplLedgEntry."Entry Type" := TempDtldEmplLedgEntry."Entry Type"::"Unrealized Loss";
                            HandleEmplDebitCredit(Correction, TempDtldEmplLedgEntry."Amount (LCY)");
                            InsertTempDtldEmployeeLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            LossesAmount := CurrAdjAmount;
                            Adjust := true;
                        end else begin
                            CurrAdjAmount := CurrAdjAmount + OldAdjAmount;
                            TempDtldEmplLedgEntry."Amount (LCY)" := -OldAdjAmount;
                            TempDtldEmplLedgEntry."Entry Type" := TempDtldEmplLedgEntry."Entry Type"::"Unrealized Loss";

                            HandleEmplDebitCredit(Correction, TempDtldEmplLedgEntry."Amount (LCY)");
                            InsertTempDtldEmployeeLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            AdjExchRateBufIndex :=
                                AdjExchRateBufferUpdate(
                                    EmplLedgerEntry."Currency Code", EmplLedgerEntry."Employee Posting Group",
                                    0, 0, -OldAdjAmount, 0, -OldAdjAmount, DimEntryNo, PostingDate2, '', '');
                            TempDtldEmplLedgEntry."Transaction No." := AdjExchRateBufIndex;
                            ModifyTempDtldEmployeeLedgerEntry();
                            Adjust := false;
                        end;
                end;
            if OldAdjAmount < 0 then
                case true of
                    (CurrAdjAmount < 0):
                        begin
                            TempDtldEmplLedgEntry."Amount (LCY)" := CurrAdjAmount;
                            TempDtldEmplLedgEntry."Entry Type" := TempDtldEmplLedgEntry."Entry Type"::"Unrealized Loss";
                            HandleEmplDebitCredit(Correction, TempDtldEmplLedgEntry."Amount (LCY)");
                            InsertTempDtldEmployeeLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            LossesAmount := CurrAdjAmount;
                            Adjust := true;
                        end;
                    (CurrAdjAmount > 0):
                        if CurrAdjAmount <= -OldAdjAmount then begin
                            TempDtldEmplLedgEntry."Amount (LCY)" := CurrAdjAmount;
                            TempDtldEmplLedgEntry."Entry Type" := TempDtldEmplLedgEntry."Entry Type"::"Unrealized Gain";
                            HandleEmplDebitCredit(Correction, TempDtldEmplLedgEntry."Amount (LCY)");
                            InsertTempDtldEmployeeLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            GainsAmount := CurrAdjAmount;
                            Adjust := true;
                        end else begin
                            CurrAdjAmount := OldAdjAmount + CurrAdjAmount;
                            TempDtldEmplLedgEntry."Amount (LCY)" := -OldAdjAmount;
                            TempDtldEmplLedgEntry."Entry Type" := TempDtldEmplLedgEntry."Entry Type"::"Unrealized Gain";
                            HandleEmplDebitCredit(Correction, TempDtldEmplLedgEntry."Amount (LCY)");
                            InsertTempDtldEmployeeLedgerEntry();
                            NewEntryNo := NewEntryNo + 1;
                            AdjExchRateBufIndex :=
                                AdjExchRateBufferUpdate(
                                    EmplLedgerEntry."Currency Code", EmplLedgerEntry."Employee Posting Group",
                                    0, 0, -OldAdjAmount, -OldAdjAmount, 0, DimEntryNo, PostingDate2, '', '');
                            TempDtldEmplLedgEntry."Transaction No." := AdjExchRateBufIndex;
                            ModifyTempDtldEmployeeLedgerEntry();
                            Adjust := false;
                        end;
                end;

            if not Adjust then begin
                TempDtldEmplLedgEntry."Amount (LCY)" := CurrAdjAmount;
                HandleEmplDebitCredit(Correction, TempDtldEmplLedgEntry."Amount (LCY)");
                TempDtldEmplLedgEntry."Entry No." := NewEntryNo;
                if CurrAdjAmount < 0 then begin
                    TempDtldEmplLedgEntry."Entry Type" := TempDtldEmplLedgEntry."Entry Type"::"Unrealized Loss";
                    GainsAmount := 0;
                    LossesAmount := CurrAdjAmount;
                end else
                    if CurrAdjAmount > 0 then begin
                        TempDtldEmplLedgEntry."Entry Type" := TempDtldEmplLedgEntry."Entry Type"::"Unrealized Gain";
                        GainsAmount := CurrAdjAmount;
                        LossesAmount := 0;
                    end;
                InsertTempDtldEmployeeLedgerEntry();
                NewEntryNo := NewEntryNo + 1;
            end;

            TotalAdjAmount := TotalAdjAmount + CurrAdjAmount;
            if not HideUI then
                Window.Update(4, TotalAdjAmount);
            AdjExchRateBufIndex :=
                AdjExchRateBufferUpdate(
                    EmplLedgerEntry."Currency Code", EmplLedgerEntry."Employee Posting Group",
                    EmplLedgerEntry."Remaining Amount", EmplLedgerEntry."Remaining Amt. (LCY)",
                    TempDtldEmplLedgEntry."Amount (LCY)", GainsAmount, LossesAmount, DimEntryNo, PostingDate2, '', '');
            TempDtldEmplLedgEntry."Transaction No." := AdjExchRateBufIndex;
            ModifyTempDtldEmployeeLedgerEntry();
        end;
    end;

    local procedure CreateVendCarteraDocuments(var VendLedgerEntry: Record "Vendor Ledger Entry"; AdjAmount: Decimal; OldAdjAmount: Decimal)
    begin
        VendLedgerEntry.CalcFields(
            Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)", "Original Amt. (LCY)",
            "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");
        if (VendorLedgerEntry."Document Situation" <> VendorLedgerEntry."Document Situation"::" ") and CarteraSetup.ReadPermission() then
            case VendLedgerEntry."Document Situation" of
                VendLedgerEntry."Document Situation"::Cartera:
                    if CarteraDoc.Get(CarteraDoc.Type::Payable, VendLedgerEntry."Entry No.") then begin
                        CarteraDoc."Remaining Amt. (LCY)" := Abs(VendLedgerEntry."Remaining Amt. (LCY)" + CurrAdjAmount);
                        CarteraDoc."Original Amount (LCY)" := Abs(VendLedgerEntry."Original Amt. (LCY)" + CurrAdjAmount);
                        CarteraDoc."Adjusted Amount" := -AdjAmount;
                        CarteraDoc.Adjusted := true;
                        CarteraDoc.Modify();
                    end;
                VendLedgerEntry."Document Situation"::"Posted BG/PO":
                    if PostedCarteraDoc.Get(PostedCarteraDoc.Type::Payable, VendLedgerEntry."Entry No.") then begin
                        PostedCarteraDoc."Remaining Amt. (LCY)" := VendLedgerEntry."Remaining Amt. (LCY)";
                        PostedCarteraDoc."Adjusted Amount" := AdjAmount + OldAdjAmount;
                        PostedCarteraDoc.ReAdjusted := true;
                        PostedCarteraDoc.Modify();
                    end;
                VendLedgerEntry."Document Situation"::"Closed BG/PO",
                VendLedgerEntry."Document Situation"::"Closed Documents":
                    if ClosedCarteraDoc.Get(ClosedCarteraDoc.Type::Payable, VendLedgerEntry."Entry No.") then begin
                        ClosedCarteraDoc."Remaining Amt. (LCY)" := VendLedgerEntry."Remaining Amt. (LCY)";
                        ClosedCarteraDoc.Modify();
                    end;
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

    [Scope('OnPrem')]
    procedure AdjustExchRateEmpl(GenJournalLine: Record "Gen. Journal Line"; var TempEmplLedgerEntry: Record "Employee Ledger Entry" temporary)
    var
        EmplLedgerEntry2: Record "Employee Ledger Entry";
        DetailedEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        PostingDate2: Date;
    begin
        PostingDate2 := GenJournalLine."Posting Date";
        if TempEmplLedgerEntry.FindSet() then
            repeat
                EmplLedgerEntry2.Get(TempEmplLedgerEntry."Entry No.");
                EmplLedgerEntry2.SetRange("Date Filter", 0D, PostingDate2);
                EmplLedgerEntry2.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                if ShouldAdjustEntry(
                        PostingDate2, EmplLedgerEntry2."Currency Code",
                        EmplLedgerEntry2."Remaining Amount", EmplLedgerEntry2."Remaining Amt. (LCY)", EmplLedgerEntry2."Adjusted Currency Factor")
                then begin
                    InitVariablesForSetLedgEntry(GenJournalLine);
                    SetEmplLedgEntry(EmplLedgerEntry2);
                    AdjustEmployeeLedgerEntry(EmplLedgerEntry2, PostingDate2);

                    DetailedEmplLedgEntry.SetCurrentKey("Employee Ledger Entry No.");
                    DetailedEmplLedgEntry.SetRange("Employee Ledger Entry No.", EmplLedgerEntry2."Entry No.");
                    DetailedEmplLedgEntry.SetFilter("Posting Date", '%1..', CalcDate('<+1D>', PostingDate2));
                    if DetailedEmplLedgEntry.FindSet() then
                        repeat
                            AdjustEmployeeLedgerEntry(EmplLedgerEntry2, DetailedEmplLedgEntry."Posting Date");
                        until DetailedEmplLedgEntry.Next() = 0;
                    HandlePostAdjmt(3);
                end;
            until TempEmplLedgerEntry.Next() = 0;
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

    local procedure SetEmplLedgEntry(EmplLedgerEntryToAdjust: Record "Employee Ledger Entry")
    begin
        Vendor.Get(EmplLedgerEntryToAdjust."Employee No.");
        AddCurrency(EmplLedgerEntryToAdjust."Currency Code", EmplLedgerEntryToAdjust."Adjusted Currency Factor");
        DtldEmplLedgEntry.LockTable();
        EmployeeLedgerEntry.LockTable();
        NewEntryNo := DtldEmplLedgEntry.GetLastEntryNo() + 1;
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

        OnAfterInitDtldVendLedgerEntry(DtldVendLedgEntry);
    end;

    local procedure InitDtldEmplLedgEntry(EmplLedgEntry: Record "Employee Ledger Entry"; var DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry")
    begin
        DtldEmplLedgEntry.Init();
        DtldEmplLedgEntry."Employee Ledger Entry No." := EmplLedgEntry."Entry No.";
        DtldEmplLedgEntry.Amount := 0;
        DtldEmplLedgEntry."Employee No." := EmplLedgEntry."Employee No.";
        DtldEmplLedgEntry."Currency Code" := EmplLedgEntry."Currency Code";
        DtldEmplLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(DtldEmplLedgEntry."User ID"));
        DtldEmplLedgEntry."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
        DtldEmplLedgEntry."Journal Batch Name" := EmplLedgEntry."Journal Batch Name";
        DtldEmplLedgEntry."Reason Code" := EmplLedgEntry."Reason Code";
        DtldEmplLedgEntry."Initial Entry Global Dim. 1" := EmplLedgEntry."Global Dimension 1 Code";
        DtldEmplLedgEntry."Initial Entry Global Dim. 2" := EmplLedgEntry."Global Dimension 2 Code";
        DtldEmplLedgEntry."Initial Document Type" := EmplLedgEntry."Document Type";

        OnAfterInitDtldEmplLedgerEntry(DtldEmplLedgEntry);
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
        DtldCustLedgEntry.Reset();
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", EntryNo);
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::"Unrealized Loss", DtldCustLedgEntry."Entry Type"::"Unrealized Gain");
    end;

    local procedure SetUnrealizedGainLossFilterVend(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; EntryNo: Integer)
    begin
        DtldVendLedgEntry.Reset();
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", EntryNo);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::"Unrealized Loss", DtldVendLedgEntry."Entry Type"::"Unrealized Gain");
    end;

    local procedure SetUnrealizedGainLossFilterEmpl(var DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry"; EntryNo: Integer)
    begin
        DtldEmplLedgEntry.Reset();
        DtldEmplLedgEntry.SetCurrentKey("Employee Ledger Entry No.", "Entry Type");
        DtldEmplLedgEntry.SetRange("Employee Ledger Entry No.", EntryNo);
        DtldEmplLedgEntry.SetRange("Entry Type", DtldEmplLedgEntry."Entry Type"::"Unrealized Loss", DtldEmplLedgEntry."Entry Type"::"Unrealized Gain");
    end;

    [Scope('OnPrem')]
    procedure GetCustPostingGrAcc(CustLedgEntry: Record "Cust. Ledger Entry"): Code[20]
    var
        CustPostingGr: Record "Customer Posting Group";
        PostedDoc: Record "Posted Cartera Doc.";
    begin
        Clear(PostedDoc);
        CustLedgEntry.TestField("Customer Posting Group");
        CustPostingGr.Get(CustLedgEntry."Customer Posting Group");
        case true of
            (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice) and
            (CustLedgEntry."Document Status" = CustLedgEntry."Document Status"::" ") and
            (CustLedgEntry."Document Situation" = CustLedgEntry."Document Situation"::" "):
                begin
                    CustPostingGr.TestField("Receivables Account");
                    exit(CustPostingGr."Receivables Account");
                end;
            (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice) and
            (CustLedgEntry."Document Status" = CustLedgEntry."Document Status"::Rejected) and
            (CustLedgEntry."Document Situation" in [CustLedgEntry."Document Situation"::"Posted BG/PO", CustLedgEntry."Document Situation"::"Closed BG/PO"]):
                begin
                    CustPostingGr.TestField("Rejected Factoring Acc.");
                    exit(CustPostingGr."Rejected Factoring Acc.");
                end;
            (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice) and
            (CustLedgEntry."Document Status" = CustLedgEntry."Document Status"::Open) and
            (CustLedgEntry."Document Situation" = CustLedgEntry."Document Situation"::"Posted BG/PO"):
                begin
                    PostedDoc.Get(PostedDoc.Type::Receivable, CustLedgEntry."Entry No.");
                    if PostedDoc."Dealing Type" = PostedDoc."Dealing Type"::Discount then begin
                        CustPostingGr.TestField("Factoring for Discount Acc.");
                        exit(CustPostingGr."Factoring for Discount Acc.");
                    end;
                    CustPostingGr.TestField("Factoring for Collection Acc.");
                    exit(CustPostingGr."Factoring for Collection Acc.");
                end;
            (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Bill) and
            (CustLedgEntry."Document Status" = CustLedgEntry."Document Status"::Open) and
            (CustLedgEntry."Document Situation" in [CustLedgEntry."Document Situation"::Cartera, CustLedgEntry."Document Situation"::"BG/PO"]):
                begin
                    CustPostingGr.TestField("Bills Account");
                    exit(CustPostingGr."Bills Account");
                end;
            (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Bill) and
            (CustLedgEntry."Document Status" = CustLedgEntry."Document Status"::Rejected) and
            (CustLedgEntry."Document Situation" in [CustLedgEntry."Document Situation"::"Posted BG/PO", CustLedgEntry."Document Situation"::"Closed BG/PO",
                                      CustLedgEntry."Document Situation"::"Closed Documents"]):
                begin
                    CustPostingGr.TestField("Rejected Bills Acc.");
                    exit(CustPostingGr."Rejected Bills Acc.");
                end;
            (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Bill) and
            (CustLedgEntry."Document Status" = CustLedgEntry."Document Status"::Open) and
            (CustLedgEntry."Document Situation" = CustLedgEntry."Document Situation"::"Posted BG/PO"):
                begin
                    PostedDoc.Get(PostedDoc.Type::Receivable, CustLedgEntry."Entry No.");
                    if PostedDoc."Dealing Type" = PostedDoc."Dealing Type"::Discount then begin
                        CustPostingGr.TestField("Discted. Bills Acc.");
                        exit(CustPostingGr."Discted. Bills Acc.");
                    end;
                    CustPostingGr.TestField("Bills on Collection Acc.");
                    exit(CustPostingGr."Bills on Collection Acc.");
                end;
            else begin
                CustPostingGr.TestField("Receivables Account");
                exit(CustPostingGr."Receivables Account");
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetVendPostingGrAcc(VendLedgEntry: Record "Vendor Ledger Entry"): Code[20]
    var
        VendPostingGr: Record "Vendor Posting Group";
    begin
        Clear(PostedCarteraDoc);
        VendLedgEntry.TestField("Vendor Posting Group");
        VendPostingGr.Get(VendLedgEntry."Vendor Posting Group");
        case true of
            (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Invoice) and
            (VendLedgEntry."Document Status" = VendLedgEntry."Document Status"::" ") and
            (VendLedgEntry."Document Situation" = VendLedgEntry."Document Situation"::" "):
                begin
                    VendPostingGr.TestField("Payables Account");
                    exit(VendPostingGr."Payables Account");
                end;
            (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Invoice) and
            (VendLedgEntry."Document Status" = VendLedgEntry."Document Status"::Open) and
            (VendLedgEntry."Document Situation" = VendLedgEntry."Document Situation"::"Posted BG/PO"):
                begin
                    VendPostingGr.TestField("Invoices in  Pmt. Ord. Acc.");
                    exit(VendPostingGr."Invoices in  Pmt. Ord. Acc.");
                end;
            (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Bill) and
            (VendLedgEntry."Document Status" = VendLedgEntry."Document Status"::Open) and
            (VendLedgEntry."Document Situation" in [VendLedgEntry."Document Situation"::Cartera, VendLedgEntry."Document Situation"::"BG/PO"]):
                begin
                    VendPostingGr.TestField("Bills Account");
                    exit(VendPostingGr."Bills Account");
                end;
            (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Bill) and
            (VendLedgEntry."Document Status" = VendLedgEntry."Document Status"::Open) and
            (VendLedgEntry."Document Situation" = VendLedgEntry."Document Situation"::"Posted BG/PO"):
                begin
                    VendPostingGr.TestField("Bills in Payment Order Acc.");
                    exit(VendPostingGr."Bills in Payment Order Acc.");
                end;
            else begin
                VendPostingGr.TestField("Payables Account");
                exit(VendPostingGr."Payables Account");
            end;
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

    local procedure InsertTempDtldEmployeeLedgerEntry()
    begin
        TempDtldEmplLedgEntry.Insert();
        TempDtldEmplLedgEntrySums := TempDtldEmplLedgEntry;
        TempDtldEmplLedgEntrySums.Insert();
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

    local procedure ModifyTempDtldEmployeeLedgerEntry()
    begin
        TempDtldEmplLedgEntry.Modify();
        TempDtldEmplLedgEntrySums := TempDtldEmplLedgEntry;
        TempDtldEmplLedgEntrySums.Modify();
    end;

    [IntegrationEvent(true, false)]
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
    local procedure OnAfterInitDtldEmplLedgerEntry(var DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry")
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
    local procedure OnAdjustEmployeeLedgerEntryOnBeforeInitDtldEmplLedgEntry(var Employee: Record Employee; EmplLedgerEntry: Record "Employee Ledger Entry")
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostEmplAdjmt(var AdjExchRateBuffer: Record "Adjust Exchange Rate Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var TempDimSetEntry: Record "Dimension Set Entry" temporary; var TempAdjExchRateBuffer: Record "Adjust Exchange Rate Buffer" temporary)
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
    local procedure OnEmployeeAfterGetRecordOnAfterFindEmplLedgerEntriesToAdjust(var TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary)
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
