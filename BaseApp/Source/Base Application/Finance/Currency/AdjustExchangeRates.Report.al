﻿#if not CLEAN23
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
using System.Security.AccessControl;

report 595 "Adjust Exchange Rates"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/Currency/AdjustExchangeRates.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Adjust Exchange Rates';
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "G/L Register" = im,
                  TableData "Exch. Rate Adjmt. Reg." = rimd,
                  TableData "VAT Entry" = rimd,
                  TableData "Detailed Cust. Ledg. Entry" = rimd,
                  TableData "Detailed Vendor Ledg. Entry" = rimd;
    UsageCategory = Tasks;
    ObsoleteReason = 'Replaced by new report 596 "Exch. Rate Adjustment"';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(IntegerNumber; Number)
            {
            }
            column(ValuationMethod; ValuationMethod)
            {
            }
            column(TxtReferenceDate; TxtReferenceDate)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(AdjustExchRatesCaption; AdjustExchRatesCaptionLbl)
            {
            }
            column(ValuationMethodCaption; ValuationMethodCaptionLbl)
            {
            }
            dataitem(Currency; Currency)
            {
                DataItemTableView = sorting(Code);
                PrintOnlyIfDetail = true;
                RequestFilterFields = "Code";
                column(BalanceAfterAdjustCaption; BalanceAfterAdjustCaptionLbl)
                {
                }
                column(AdjBaseLCYCaption; AdjBaseLCYCaptionLbl)
                {
                }
                column(BankAccountsCaption; BankAccountsCaptionLbl)
                {
                }
                dataitem("Bank Account"; "Bank Account")
                {
                    DataItemLink = "Currency Code" = field(Code);
                    DataItemTableView = sorting("Bank Acc. Posting Group");
                    RequestFilterFields = "No.";
                    column(No_BankAcc; "No.")
                    {
                        IncludeCaption = true;
                    }
                    column(CurrCode_BankAcc; "Currency Code")
                    {
                        IncludeCaption = true;
                    }
                    column(BalanceatDate_BankAcc; "Balance at Date")
                    {
                        IncludeCaption = true;
                    }
                    column(AdjBaseLCY; CurrAdjBaseLCY)
                    {
                    }
                    column(AdjAmount; CurrAdjAmount)
                    {
                    }
                    column(AdjBaseLCYAdjAmt; CurrAdjBaseLCY + CurrAdjAmount)
                    {
                    }
                    column(RelationalCurrCode; CurrExchRate3."Relational Currency Code")
                    {
                    }
                    column(AdjustmentExchRateAmt; CurrExchRate3."Adjustment Exch. Rate Amount")
                    {
                        DecimalPlaces = 6 : 6;
                    }
                    column(RelationalAdjmtExchRateAmt; CurrExchRate3."Relational Adjmt Exch Rate Amt")
                    {
                        DecimalPlaces = 6 : 6;
                    }
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
                                      TotalAdjBase, TotalAdjBaseLCY, TotalAdjAmount, 0, 0, 0, PostingDate, '');
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
                        if not AdjustBank then
                            CurrReport.Break();

                        SetRange("Date Filter", StartDate, EndDate);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    "Last Date Adjusted" := PostingDate;
                    if PostSettlement then
                        Modify();

                    "Currency Factor" := CurrExchRate.ExchangeRateAdjmt(PostingDate, Code);

                    TempCurrencyToAdjust := Currency;
                    TempCurrencyToAdjust.Insert();
                    FindCurrency(PostingDate, Code);
                end;

                trigger OnPostDataItem()
                begin
                    if (Code = '') and AdjCustVendBank then
                        Error(Text011Err);
                end;

                trigger OnPreDataItem()
                begin
                    CheckPostingDate();
                    if not AdjCustVendBank then
                        CurrReport.Break();

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
                PrintOnlyIfDetail = true;
                column(No_Cust; "No.")
                {
                }
                column(CustomerLedgerEntriesCaption; CustomerLedgerEntriesCaptionLbl)
                {
                }
                column(CustomerNoCaption; CustomerNoCaptionLbl)
                {
                }
                dataitem(CustomerLedgerEntryLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(AdjAmt; CurrAdjAmount2)
                    {
                    }
                    column(RemainingAmtLCY_CustLedgEntry; CustLedgerEntry."Remaining Amt. (LCY)")
                    {
                    }
                    column(OriginalAmtLCY_CustLedgEntry; CustLedgerEntry."Original Amt. (LCY)")
                    {
                    }
                    column(RemainingAmt_CustLedgEntry; CustLedgerEntry."Remaining Amount")
                    {
                    }
                    column(Amt_CustLedgEntry; CustLedgerEntry.Amount)
                    {
                    }
                    column(CurrCode_CustLedgEntry; CustLedgerEntry."Currency Code")
                    {
                    }
                    column(DocNo_CustLedgEntry; CustLedgerEntry."Document No.")
                    {
                    }
                    column(PostingDate_CustLedgEntry; Format(CustLedgerEntry."Posting Date"))
                    {
                    }
                    column(DocType_CustLedgEntry; CustLedgerEntry."Document Type")
                    {
                    }
                    column(EntryNo_CustLedgEntry; CustLedgerEntry."Entry No.")
                    {
                    }
                    column(CurrencyCode; CurrExchRate3."Relational Currency Code")
                    {
                    }
                    column(ExchRateAmt; CurrExchRate3."Adjustment Exch. Rate Amount")
                    {
                        DecimalPlaces = 6 : 6;
                    }
                    column(AdjmtExchRateAmt; CurrExchRate3."Relational Adjmt Exch Rate Amt")
                    {
                        DecimalPlaces = 6 : 6;
                    }
                    column(DueDate_CustLedgEntry; Format(CustLedgerEntry."Due Date"))
                    {
                    }
                    dataitem("Detailed Cust. Ledg. Entry"; "Detailed Cust. Ledg. Entry")
                    {
                        DataItemTableView = sorting("Cust. Ledger Entry No.", "Posting Date");

                        trigger OnAfterGetRecord()
                        begin
                            AdjustCustomerLedgerEntry(CustLedgerEntry, "Posting Date", true);
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
                        CustLedgerEntry.SetRange("Date Filter", StartDate, EndDate);
                        CustLedgerEntry.CalcFields(Amount, "Remaining Amount", "Original Amt. (LCY)", "Remaining Amt. (LCY)");
                        AdjustCustomerLedgerEntry(CustLedgerEntry, PostingDate, false);
                        Customer_Document_type := CustLedgerEntry."Document Type".AsInteger();
                        CurrAdjAmount2 := CurrAdjAmount;
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
                    if not AdjCustVendBank then
                        CurrReport.Break();

                    if not AdjustCustomer then
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
                PrintOnlyIfDetail = true;
                column(No_Vend; "No.")
                {
                }
                column(VendorLedgerEntriesCaption; VendorLedgerEntriesCaptionLbl)
                {
                }
                column(VendorNoCaption; VendorNoCaptionLbl)
                {
                }
                dataitem(VendorLedgerEntryLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(VendLedgEntryAdjAmt; CurrAdjAmount2)
                    {
                    }
                    column(RemainingAmtLCY_VendLedgEntry; VendorLedgerEntry."Remaining Amt. (LCY)")
                    {
                    }
                    column(OriginalAmtLCY_VendLedgEntry; VendorLedgerEntry."Original Amt. (LCY)")
                    {
                    }
                    column(RemainingAmt_VendLedgEntry; VendorLedgerEntry."Remaining Amount")
                    {
                    }
                    column(Amt_VendLedgEntry; VendorLedgerEntry.Amount)
                    {
                    }
                    column(CurrCode_VendLedgEntry; VendorLedgerEntry."Currency Code")
                    {
                    }
                    column(DocNo_VendLedgEntry; VendorLedgerEntry."Document No.")
                    {
                    }
                    column(DocumentType_VendLedgEntry; VendorLedgerEntry."Document Type")
                    {
                    }
                    column(PostingDate_VendLedgEntry; Format(VendorLedgerEntry."Posting Date"))
                    {
                    }
                    column(EntryNo_VendLedgEntry; VendorLedgerEntry."Entry No.")
                    {
                    }
                    column(VendLedgEntryCurrCode; CurrExchRate3."Relational Currency Code")
                    {
                    }
                    column(VendLedgEntryExchRateAmt; CurrExchRate3."Adjustment Exch. Rate Amount")
                    {
                        DecimalPlaces = 6 : 6;
                    }
                    column(AdjustmenttExchRateAmt; CurrExchRate3."Relational Adjmt Exch Rate Amt")
                    {
                        DecimalPlaces = 6 : 6;
                    }
                    column(DueDate_VendLedgEntry; Format(VendorLedgerEntry."Due Date"))
                    {
                    }
                    dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
                    {
                        DataItemTableView = sorting("Vendor Ledger Entry No.", "Posting Date");

                        trigger OnAfterGetRecord()
                        begin
                            AdjustVendorLedgerEntry(VendorLedgerEntry, "Posting Date", true);
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
                        VendorLedgerEntry.SetRange("Date Filter", StartDate, EndDate);
                        VendorLedgerEntry.CalcFields(Amount, "Remaining Amount", "Original Amt. (LCY)", "Remaining Amt. (LCY)");
                        AdjustVendorLedgerEntry(VendorLedgerEntry, PostingDate, false);
                        CurrAdjAmount2 := CurrAdjAmount;
                        Vendor_Document_type := VendorLedgerEntry."Document Type".AsInteger();
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
                    if not AdjCustVendBank then
                        CurrReport.Break();

                    if not AdjustVendor then
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
            dataitem("VAT Entry"; "VAT Entry")
            {
                DataItemTableView = sorting("Document No.", "Posting Date");
                column(VATEntriesCaption; VATEntriesCaptionLbl)
                {
                }
                column(EntryNo_VATEntry; NewVATEntry."Entry No.")
                {
                    IncludeCaption = true;
                }
                column(PostingDate_VATEntry; "Posting Date")
                {
                    IncludeCaption = true;
                }
                column(DocumentNo_VATEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(DocumentType_VATEntry; "Document Type")
                {
                    IncludeCaption = true;
                }
                column(Type_VATEntry; Type)
                {
                    IncludeCaption = true;
                }
                column(Base_VATEntry; NewVATEntry.Base)
                {
                    IncludeCaption = true;
                }
                column(Amount_VATEntry; NewVATEntry.Amount)
                {
                    IncludeCaption = true;
                }
                column(CurrencyCode_VATEntry; "Currency Code")
                {
                    IncludeCaption = true;
                }
                column(VATExchRateAmt; CurrExchRate."VAT Exch. Rate Amount")
                {
                    DecimalPlaces = 6 : 6;
                }
                column(RelationalVATExchRateAmt; CurrExchRate."Relational VAT Exch. Rate Amt")
                {
                    DecimalPlaces = 6 : 6;
                }

                trigger OnAfterGetRecord()
                begin
                    if (not "Unadjusted Exchange Rate") or Closed then
                        CurrReport.Skip();

                    if (Type = Type::Sale) and
                       ("VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT")
                    then
                        CurrReport.Skip();

                    if Type in [Type::Sale, Type::Purchase] then begin
                        NewVATEntry := "VAT Entry";
                        AdjustVATRate();
                        AdjVATEntriesCounter := AdjVATEntriesCounter + 1;
                        Window.Update(1, AdjVATEntriesCounter);
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    UpdateGLRegToVATEntryNo();
                end;

                trigger OnPreDataItem()
                begin
                    if not VATExchAdjust then
                        CurrReport.Break();

                    Window.Open(
                      Text92001Txt +
                      Text92002Txt);

                    CurrExchRate.Reset();
                    CurrencyCH1.Reset();
                    SetRange("Posting Date", StartDate, EndDate);
                    Currency.CopyFilter(Code, "Currency Code");

                    NewVATEntry.LockTable();
                    if NewVATEntry.FindLast() then
                        FirstVATEntry := NewVATEntry."Entry No." + 1;
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
                RequestFilterFields = "No.";
                column(GLAccountsCaption; GLAccountCaptionLbl)
                {
                }
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(KeyDate; Format(PostingDate))
                {
                }
                column(No_GLAccount; "No.")
                {
                }
                column(Name_GLAccount; Name)
                {
                    IncludeCaption = true;
                }
                column(CurrencyCode_GLAccount; "Currency Code")
                {
                }
                column(Balance_GLAccount; "Net Change")
                {
                }
                column(Add_Curr_Bal_GLAccount; "Additional-Currency Net Change")
                {
                }
                column(AddRepCurrBalAtAdjDt; AddRepCurrBalAtAdjDt)
                {
                }
                column(CurrRate; 1 / AddCurrCurrencyFactor)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Correction2; Correction2)
                {
                }

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
                            begin
                                AddRepCurrBalAtAdjDt := Round("Additional-Currency Net Change" * AddCurrCurrencyFactor, 0.01);
                                Correction2 := Round(("Additional-Currency Net Change" * AddCurrCurrencyFactor) - "Net Change", 0.01);
                                PostGLAccAdjmt(
                                  "No.", "Exchange Rate Adjustment"::"Adjust Amount",
                                  Round(
                                    CurrExchRate2.ExchangeAmtFCYToLCYAdjmt(
                                      PostingDate, GLSetup."Additional Reporting Currency",
                                      "Additional-Currency Net Change", AddCurrCurrencyFactor) -
                                    "Net Change"),
                                  "Net Change",
                                  "Additional-Currency Net Change");
                            end;
                        "Exchange Rate Adjustment"::"Adjust Additional-Currency Amount":
                            begin
                                AddRepCurrBalAtAdjDt := Round("Net Change" * AddCurrCurrencyFactor, 0.01);
                                Correction2 := Round(("Net Change" * AddCurrCurrencyFactor) - "Additional-Currency Net Change", 0.01);
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

                    Clear(Correction2);
                end;
            }
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
                                UpdateControls();
                            end;
                        }
                    }
                    group("Valuation Method")
                    {
                        Caption = 'Valuation Method';
                        field(Method; ValuationMethod)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Method';
                            OptionCaption = 'Standard,Lowest Value,BilMoG (Germany)';
                            ToolTip = 'Specifies the valuation method that is used for short-term entries.';

                            trigger OnValidate()
                            begin
                                UpdateControls();
                            end;
                        }
                        field(ValPerEnd; ValuationPeriodEndDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Valuation Reference Date';
                            Enabled = ValPerEndEnable;
                            ToolTip = 'Specifies the base date that is used to calculate which entries are short-term entries.';

                            trigger OnValidate()
                            begin
                                UpdateControls();
                            end;
                        }
                        field(DueDateLimit; DueDateTo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Short-term Liabilities Due Date';
                            Enabled = DueDateLimitEnable;
                            ToolTip = 'Specifies the date that is used to separate short-term entries from long-term entries.';

                            trigger OnValidate()
                            begin
                                if DueDateTo < ValuationPeriodEndDate then
                                    Error(Text11001);
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
                    field(AdjCustomers; AdjustCustomer)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Customers';
                        ToolTip = 'Specifies if you want to adjust customers for currency fluctuations.';
                    }
                    field(AdjVendors; AdjustVendor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Vendors';
                        ToolTip = 'Specifies if you want to adjust vendors for currency fluctuations.';
                    }
                    field(AdjustBankAccounts; AdjustBank)
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
                    field(AdjVAT; VATExchAdjust)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust VAT';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to adjust the VAT exchange rate.';
                    }
                    field(Post; PostSettlement)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post';
                        ToolTip = 'Specifies if you want to calculate and post the adjustments when you preview the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            ValPerEndEnable := true;
            DueDateLimitEnable := true;
        end;

        trigger OnOpenPage()
        begin
            if PostingDescription = '' then
                PostingDescription := Text016Txt;
            if not (AdjCustVendBank or AdjGLAcc) then
                AdjCustVendBank := true;
            GLSetup.Get();
            IsJournalTemplNameVisible := GLSetup."Journal Templ. Name Mandatory";
            UpdateControls();
        end;
    }

    labels
    {
        RelAdjmtExchRateAmtCaption = 'Relational Adjmt Exch. Rate Amt';
        AdjustmentExchRateAmtCaption = 'Adjustment Exch. Rate Amount';
        RelationalCurrencyCodeCaption = 'Relational Currency Code';
        AdjAmountCaption = 'Adjustment Amount';
        RemainingAmtLCYCaption = 'Remaining Amt. (LCY)';
        OriginalAmtLCYCaption = 'Original Amt. (LCY)';
        RemainingAmountCaption = 'Remaining Amount';
        AmountCaption = 'Amount';
        CurrencyCodeCaption = 'Currency Code';
        DocumentNoCaption = 'Document No.';
        DocumentTypeCaption = 'Document Type';
        PostingDateCaption = 'Posting Date';
        EntryNoCaption = 'Entry No.';
        DueDateCaption = 'Due Date';
        VATExchRateAmountCaption = 'VAT Exch. Rate Amount';
        RelationalVATExchRateAmtCaption = 'Relational VAT Exch. Rate Amt';
        GLAccountCaption = 'G/L Account';
        AdjustExchangeRatesGLCaption = 'Adjust Exchange Rates G/L';
        CorrectionCaption = 'Correction';
        ExrateOnKeyDateCaption = 'Exrate on Posting Date';
        AvgExRateCaption = 'Average Exrate';
        BalanceCaption = 'Balance';
        AddCurrencyBalance = 'Additional Currency Balance';
        EMUCaption = 'EMU';
        TotalRateAdjustmentCaption = 'Total Rate Adjustment';
        AddReportingCurrBalAtAdjDateCaption = 'Additional reporting currency balance at adjustment date';
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
    var
        LicPerm: Record "License Permission";
    begin
        if GenJnlPostLine.IsGLEntryInconsistent() then
            GenJnlPostLine.ShowInconsistentEntries()
        else begin
            UpdateAnalysisView.UpdateAll(0, true);
            if TotalCustomersAdjusted +
               TotalVendorsAdjusted + TotalBankAccountsAdjusted + TotalGLAccountsAdjusted + AdjVATEntriesCounter < 1
            then
                Message(NothingToAdjustMsg)
            else
                Message(RatesAdjustedMsg);
        end;

        if (LicPerm.Get(5, 3010536) and (LicPerm."Read Permission" = 1)) or
           (CopyStr(SerialNumber, 7, 3) = '000')
        then
            GlForeignCurrMgt.ShowGlRegMessage;

        OnAfterPostReport(ExchRateAdjReg, PostingDate);
    end;

    trigger OnPreReport()
    begin
        if EndDateReq = 0D then
            EndDate := DMY2Date(31, 12, 9999)
        else
            EndDate := EndDateReq;
        AdjCustVendBank :=
          AdjustCustomer or AdjustVendor or AdjustBank;

        GLSetup.Get();
        if PostSettlement then begin
            if not Confirm(Text1140000Qst, false) then
                Error(Text005Err);
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
        end;
        if not AdjCustVendBank and AdjGLAcc then
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

        if ValuationMethod = ValuationMethod::"BilMoG (Germany)" then
            TxtReferenceDate := Text11000 + Format(ValuationPeriodEndDate);
        if VATExchAdjust then
            if not Confirm(Text1150000Txt + Text004Txt) then
                Error(Text1150001Err);
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
        CurrExchRate3: Record "Currency Exchange Rate";
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
        CurrencyCH1: Record Currency;
        NewVATEntry: Record "VAT Entry";
        NewVATEntry4No: Record "VAT Entry";
        VATEntryLink: Record "G/L Entry - VAT Entry Link";
        GLEntry: Record "G/L Entry";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        DimMgt: Codeunit DimensionManagement;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        GlForeignCurrMgt: Codeunit GlForeignCurrMgt;
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
        Date2: Date;
        DueDateTo: Date;
        ValuationPeriodEndDate: Date;
        Correction: Boolean;
        HideUI: Boolean;
        OK: Boolean;
        AdjCustVendBank: Boolean;
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
        TotalGLAccountsAdjusted: Integer;
        AdjustCustomer: Boolean;
        AdjustVendor: Boolean;
        AdjustBank: Boolean;
        PostSettlement: Boolean;
        ValuationMethod: Option Standard,"Lowest Value","BilMoG (Germany)";
        TxtReferenceDate: Text[50];
        DueDateLimitEnable: Boolean;
        ValPerEndEnable: Boolean;
        CurrAdjAmount2: Decimal;
        VATExchAdjust: Boolean;
        AdjVATEntriesCounter: Integer;
        FirstVATEntry: Integer;
        Customer_Document_type: Integer;
        Vendor_Document_type: Integer;
        CorrRevChargeEntryNo: Integer;
        NextVATEntryNo: Integer;
        AddRepCurrBalAtAdjDt: Decimal;
        Correction2: Decimal;

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
        Text1140000Qst: Label 'Do you want to calculate and post the adjustment?';
        PageCaptionLbl: Label 'Page';
        AdjustExchRatesCaptionLbl: Label 'Adjust Exchange Rates';
        ValuationMethodCaptionLbl: Label 'Valuation Method';
        BalanceAfterAdjustCaptionLbl: Label 'Balance (LCY) after Adjustment';
        AdjBaseLCYCaptionLbl: Label 'Balance at Date (LCY)';
        BankAccountsCaptionLbl: Label 'Bank Accounts';
        CustomerLedgerEntriesCaptionLbl: Label 'Customer Ledger Entries';
        CustomerNoCaptionLbl: Label 'Customer No.';
        VendorLedgerEntriesCaptionLbl: Label 'Vendor Ledger Entries';
        VendorNoCaptionLbl: Label 'Vendor No.';
        Text92000Txt: Label 'VAT exch. adjustment Doc. ';
        Text92001Txt: Label 'Adjust VAT rate...\\';
        Text92002TXt: Label 'Adjusted entries  #1#####';
        Text1150000Txt: Label 'You want to adjust the VAT exchange rate. Please check whether the VAT exchange rates are correct. They cannot be corrected anymore.\\ ';
        Text1150001Err: Label 'Job cancelled.';
        VATEntriesCaptionLbl: Label 'VAT Entries';
        Text11000: Label 'Valuation Reference Date: ';
        Text11001: Label 'Short term liabilities until must not be before Valuation Reference Date.';
        GLAccountCaptionLbl: Label 'G/L Accounts';

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

        if PostSettlement then
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
        if PostSettlement then begin
            GetJnlLineDefDim(GenJnlLine, TempDimSetEntry);
            CopyDimSetEntryToDimBuf(TempDimSetEntry, TempDimBuf);
            PostGenJnlLine(GenJnlLine, TempDimSetEntry);
        end;

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
            if PostSettlement then
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
        AdjCustVendBank := NewAdjCustVendBank;
        AdjGLAcc := NewAdjGLAcc;
    end;

    local procedure AdjExchRateBufferUpdate(CurrencyCode2: Code[10]; PostingGroup2: Code[20]; AdjBase2: Decimal; AdjBaseLCY2: Decimal; AdjAmount2: Decimal; GainsAmount2: Decimal; LossesAmount2: Decimal; DimEntryNo: Integer; Postingdate2: Date; ICCode: Code[20]): Integer
    begin
        TempAdjExchRateBuffer.Init();
        OK := TempAdjExchRateBuffer.Get(CurrencyCode2, PostingGroup2, DimEntryNo, Postingdate2, ICCode);

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

        if PostSettlement then
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

                if VATEntry."Currency Code" <> GLSetup."Additional Reporting Currency" then begin
                    AdjustVATAmount(VATEntry.Base, VATEntry."Additional-Currency Base");
                    AdjustVATAmount(VATEntry.Amount, VATEntry."Additional-Currency Amount");
                    AdjustVATAmount(VATEntry."Unrealized Amount", VATEntry."Add.-Currency Unrealized Amt.");
                    AdjustVATAmount(VATEntry."Unrealized Base", VATEntry."Add.-Currency Unrealized Base");
                    AdjustVATAmount(VATEntry."Remaining Unrealized Amount", VATEntry."Add.-Curr. Rem. Unreal. Amount");
                    AdjustVATAmount(VATEntry."Remaining Unrealized Base", VATEntry."Add.-Curr. Rem. Unreal. Base");
                    if PostSettlement then
                        VATEntry.Modify();
                end;

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
            if PostSettlement then begin
                GetJnlLineDefDim(GenJnlLine, TempDimSetEntry);
                PostGenJnlLine(GenJnlLine, TempDimSetEntry);
            end;
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
            if PostSettlement then begin
                GetJnlLineDefDim(GenJnlLine, TempDimSetEntry);
                PostGenJnlLine(GenJnlLine, TempDimSetEntry);
            end;
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
            if PostSettlement then begin
                GetJnlLineDefDim(GenJnlLine, TempDimSetEntry);
                PostGenJnlLine(GenJnlLine, TempDimSetEntry);
            end;
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
            if PostSettlement then
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

    procedure AdjustCustomerLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; PostingDate2: Date; Application: Boolean)
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

        // Calculate New Unrealized Gains and Losses
        CurrAdjAmount :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCYAdjmt(
                    PostingDate2, TempCurrencyToAdjust.Code, CustLedgerEntry."Remaining Amount", TempCurrencyToAdjust."Currency Factor")) -
                CustLedgerEntry."Remaining Amt. (LCY)";

        case ValuationMethod of
            ValuationMethod::"Lowest Value":
                if (CurrAdjAmount >= 0) and (not Application) then
                    CurrReport.Skip();
            ValuationMethod::"BilMoG (Germany)":
                if not Application then
                    CalculateBilMoG(
                        CurrAdjAmount, CustLedgerEntry."Remaining Amt. (LCY)",
                        CustCalcRemOrigAmtLCY(CustLedgerEntry), CustLedgerEntry."Due Date");
        end;

        // Modify Currency Factor on Customer Ledger Entry
        if CustLedgerEntry."Adjusted Currency Factor" <> TempCurrencyToAdjust."Currency Factor" then begin
            CustLedgerEntry."Adjusted Currency Factor" := TempCurrencyToAdjust."Currency Factor";
            if PostSettlement then
                CustLedgerEntry.Modify();
        end;
        FindCurrency(PostingDate, TempCurrencyToAdjust.Code);

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
                                    0, 0, -OldAdjAmount, 0, -OldAdjAmount, DimEntryNo, PostingDate2, Customer."IC Partner Code");
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
                                    0, 0, -OldAdjAmount, -OldAdjAmount, 0, DimEntryNo, PostingDate2, Customer."IC Partner Code");
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
                    GainsAmount, LossesAmount, DimEntryNo, PostingDate2, Customer."IC Partner Code");
            TempDtldCustLedgEntry."Transaction No." := AdjExchRateBufIndex;
            ModifyTempDtldCustomerLedgerEntry();
        end;
    end;

    procedure AdjustVendorLedgerEntry(VendLedgerEntry: Record "Vendor Ledger Entry"; PostingDate2: Date; Application: Boolean)
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

        // Calculate New Unrealized Gains and Losses
        CurrAdjAmount :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCYAdjmt(
                    PostingDate2, TempCurrencyToAdjust.Code, VendLedgerEntry."Remaining Amount", TempCurrencyToAdjust."Currency Factor")) -
                VendLedgerEntry."Remaining Amt. (LCY)";

        case ValuationMethod of
            ValuationMethod::"Lowest Value":
                if (CurrAdjAmount >= 0) and (not Application) then
                    CurrReport.Skip();
            ValuationMethod::"BilMoG (Germany)":
                if not Application then
                    CalculateBilMoG(
                        CurrAdjAmount, VendLedgerEntry."Remaining Amt. (LCY)",
                        VendCalcRemOrigAmtLCY(VendLedgerEntry), VendLedgerEntry."Due Date");
        end;

        // Modify Currency Factor on Vendor Ledger Entry
        if VendLedgerEntry."Adjusted Currency Factor" <> TempCurrencyToAdjust."Currency Factor" then begin
            VendLedgerEntry."Adjusted Currency Factor" := TempCurrencyToAdjust."Currency Factor";
            if PostSettlement then
                VendLedgerEntry.Modify();
        end;

        FindCurrency(PostingDate, TempCurrencyToAdjust.Code);

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
                                    0, 0, -OldAdjAmount, 0, -OldAdjAmount, DimEntryNo, PostingDate2, Vendor."IC Partner Code");
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
                                    0, 0, -OldAdjAmount, -OldAdjAmount, 0, DimEntryNo, PostingDate2, Vendor."IC Partner Code");
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
                    TempDtldVendLedgEntry."Amount (LCY)", GainsAmount, LossesAmount, DimEntryNo, PostingDate2, Vendor."IC Partner Code");
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
                    AdjustCustomerLedgerEntry(CustLedgerEntry2, PostingDate2, false);

                    DetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
                    DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry2."Entry No.");
                    DetailedCustLedgEntry.SetFilter("Posting Date", '%1..', CalcDate('<+1D>', PostingDate2));
                    if DetailedCustLedgEntry.FindSet() then
                        repeat
                            AdjustCustomerLedgerEntry(CustLedgerEntry2, DetailedCustLedgEntry."Posting Date", false);
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
                    AdjustVendorLedgerEntry(VendLedgerEntry2, PostingDate2, false);

                    DetailedVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
                    DetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgerEntry2."Entry No.");
                    DetailedVendLedgEntry.SetFilter("Posting Date", '%1..', CalcDate('<+1D>', PostingDate2));
                    if DetailedVendLedgEntry.FindSet() then
                        repeat
                            AdjustVendorLedgerEntry(VendLedgerEntry2, DetailedVendLedgEntry."Posting Date", false);
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
        end;
    end;

    local procedure SetUnrealizedGainLossFilterVend(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; EntryNo: Integer)
    begin
        with DtldVendLedgEntry do begin
            Reset();
            SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
            SetRange("Vendor Ledger Entry No.", EntryNo);
            SetRange("Entry Type", "Entry Type"::"Unrealized Loss", "Entry Type"::"Unrealized Gain");
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

    [Scope('OnPrem')]
    procedure FindCurrency(Date: Date; CurrencyCode: Code[10])
    begin
        if (CurrExchRate3."Currency Code" <> CurrencyCode) or (Date2 <> Date) then begin
            CurrExchRate3.SetRange("Currency Code", CurrencyCode);
            CurrExchRate3.SetRange("Starting Date", 0D, Date);
            CurrExchRate3.Find('+');
            Date2 := Date;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateControls()
    begin
        if ValuationMethod = ValuationMethod::"BilMoG (Germany)" then begin
            DueDateLimitEnable := true;
            ValPerEndEnable := true;
            if ValuationPeriodEndDate = 0D then
                if EndDateReq <> 0D then
                    ValuationPeriodEndDate := CalcDate('<+CM>', EndDateReq);
            if ValuationPeriodEndDate <> 0D then
                DueDateTo := CalcDate('<+1Y>', ValuationPeriodEndDate);
        end else begin
            DueDateLimitEnable := false;
            ValPerEndEnable := false;
            ValuationPeriodEndDate := 0D;
            DueDateTo := 0D;
        end;
    end;

    local procedure UpdateGLRegToVATEntryNo()
    var
        GLRegister: Record "G/L Register";
    begin
        if PostSettlement then begin
            GenJnlPostLine.GetGLReg(GLRegister);
            if GLRegister."No." <> 0 then begin
                GLRegister."To VAT Entry No." := NewVATEntry."Entry No.";
                GLRegister.Modify();
            end else
                if NewVATEntry."Entry No." >= FirstVATEntry then begin
                    GLRegister.LockTable();
                    GLRegister.FindLast();
                    GLRegister.Init();
                    GLRegister."No." := GLRegister."No." + 1;
                    GLRegister."Creation Date" := Today();
                    GLRegister."Creation Time" := Time();
                    GLRegister."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
                    GLRegister."User ID" := UserId();
                    GLRegister."From VAT Entry No." := FirstVATEntry;
                    GLRegister."To VAT Entry No." := NewVATEntry."Entry No.";
                    GLRegister.Insert();
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalculateBilMoG(var AdjAmt2: Decimal; RemAmtLCY: Decimal; OrigRemAmtLCY: Decimal; DueDate: Date)
    begin
        if (DueDateTo < DueDate) or (DueDate = 0D) then begin
            if (RemAmtLCY = OrigRemAmtLCY) and (AdjAmt2 >= 0) then
                CurrReport.Skip();

            if (AdjAmt2 + RemAmtLCY) > OrigRemAmtLCY then
                AdjAmt2 := OrigRemAmtLCY - RemAmtLCY;
        end;
    end;

    [Scope('OnPrem')]
    procedure CustCalcRemOrigAmtLCY(CustLedgEntry2: Record "Cust. Ledger Entry"): Decimal
    var
        DtldCustEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustEntry2.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DtldCustEntry2.SetRange("Cust. Ledger Entry No.", CustLedgEntry2."Entry No.");
        DtldCustEntry2.SetRange(
          "Entry Type", DtldCustEntry2."Entry Type"::"Initial Entry", DtldCustEntry2."Entry Type"::Application);
        DtldCustEntry2.SetRange("Posting Date", CustLedgEntry2."Posting Date", PostingDate);
        DtldCustEntry2.CalcSums("Amount (LCY)");
        exit(DtldCustEntry2."Amount (LCY)");
    end;

    [Scope('OnPrem')]
    procedure VendCalcRemOrigAmtLCY(VendLedgEntry2: Record "Vendor Ledger Entry"): Decimal
    var
        DtldVendEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendEntry2.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
        DtldVendEntry2.SetRange("Vendor Ledger Entry No.", VendLedgEntry2."Entry No.");
        DtldVendEntry2.SetRange(
          "Entry Type", DtldVendEntry2."Entry Type"::"Initial Entry", DtldVendEntry2."Entry Type"::Application);
        DtldVendEntry2.SetRange("Posting Date", VendLedgEntry2."Posting Date", PostingDate);
        DtldVendEntry2.CalcSums("Amount (LCY)");
        exit(DtldVendEntry2."Amount (LCY)");
    end;

    [Scope('OnPrem')]
    procedure AdjustVATRate()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        VATGLEntry: Record "G/L Entry";
        FixAmount: Decimal;
        FixAmountAddCurr: Decimal;
        CorrBaseAmount: Decimal;
        CorrBaseAmtAddCurr: Decimal;
        VATEntryNoToModify: Integer;
    begin
        CurrExchRate.SetRange("Currency Code", "VAT Entry"."Currency Code");
        CurrExchRate.SetRange("Starting Date", 0D, "VAT Entry"."Posting Date");
        if not CurrExchRate.FindLast() then
            exit;

        CurrExchRate.TestField("VAT Exch. Rate Amount");
        CurrExchRate.TestField("Relational VAT Exch. Rate Amt");
        CurrencyCH1.Get("VAT Entry"."Currency Code");
        CurrencyCH1.TestField("Realized Gains Acc.");
        CurrencyCH1.TestField("Realized Losses Acc.");

        FixAmount :=
          Round("VAT Entry"."Amount (FCY)" / CurrExchRate."VAT Exch. Rate Amount" * CurrExchRate."Relational VAT Exch. Rate Amt",
            GLSetup."Amount Rounding Precision") - "VAT Entry".Amount;

        CorrBaseAmount :=
          Round("VAT Entry"."Base (FCY)" / CurrExchRate."VAT Exch. Rate Amount" * CurrExchRate."Relational VAT Exch. Rate Amt",
            GLSetup."Amount Rounding Precision") - "VAT Entry".Base;

        if FixAmount <> 0 then begin
            VATPostingSetup2.Get("VAT Entry"."VAT Bus. Posting Group", "VAT Entry"."VAT Prod. Posting Group");

            if PostSettlement then begin
                GLEntryVATEntryLink.SetRange("VAT Entry No.", "VAT Entry"."Entry No.");
                if GLEntryVATEntryLink.FindFirst() then begin
                    VATGLEntry.Get(GLEntryVATEntryLink."G/L Entry No.");
                    DimMgt.GetDimensionSet(TempDimSetEntry, VATGLEntry."Dimension Set ID");
                end;
            end;

            // Additional exchange rate adjustment only if "VAT Calculation Type" is "Reverse Charge VAT" (Erwerbssteuer)
            if "VAT Entry"."VAT Calculation Type" = "VAT Entry"."VAT Calculation Type"::"Reverse Charge VAT" then begin
                GenJnlLine.Init();
                GenJnlLine."Posting Date" := "VAT Entry"."Posting Date";
                GenJnlLine."Document No." := "VAT Entry"."Document No.";
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                GenJnlLine."Reason Code" := "VAT Entry"."Reason Code";
                GenJnlLine."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";

                if FixAmount > 0 then
                    GenJnlLine.Validate("Account No.", CurrencyCH1."Realized Losses Acc.");
                if FixAmount < 0 then
                    GenJnlLine.Validate("Account No.", CurrencyCH1."Realized Gains Acc.");

                if "VAT Entry".Type = "VAT Entry".Type::Sale then begin
                    VATPostingSetup2.TestField("Sales VAT Account");
                    GenJnlLine.Validate("Bal. Account No.", VATPostingSetup2."Sales VAT Account");
                end else begin
                    GenJnlLine.Validate("Bal. Account No.", VATPostingSetup2."Reverse Chrg. VAT Acc.");
                    VATPostingSetup2.TestField("Reverse Chrg. VAT Acc.");
                end;

                GenJnlLine."System-Created Entry" := true;
                GenJnlLine.Description := Text92000Txt + Format("VAT Entry"."Document No.");
                GenJnlLine."Bill-to/Pay-to No." := "VAT Entry"."Bill-to/Pay-to No.";

                GenJnlLine.Validate(Amount, FixAmount);

                if PostSettlement then begin
                    PostGenJnlLine(GenJnlLine, TempDimSetEntry);
                    GLEntry.FindLast();
                    CorrRevChargeEntryNo := GLEntry."Entry No.";
                end;
            end;
            GenJnlLine.Init();
            GenJnlLine."Posting Date" := "VAT Entry"."Posting Date";
            GenJnlLine."Document No." := "VAT Entry"."Document No.";
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine."Reason Code" := "VAT Entry"."Reason Code";
            GenJnlLine."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";

            if "VAT Entry".Type = "VAT Entry".Type::Sale then begin
                VATPostingSetup2.TestField("Sales VAT Account");
                GenJnlLine.Validate("Account No.", VATPostingSetup2."Sales VAT Account");
            end else begin
                VATPostingSetup2.TestField("Purchase VAT Account");
                GenJnlLine.Validate("Account No.", VATPostingSetup2."Purchase VAT Account");
            end;

            if FixAmount > 0 then
                GenJnlLine.Validate("Bal. Account No.", CurrencyCH1."Realized Gains Acc.");
            if FixAmount < 0 then
                GenJnlLine.Validate("Bal. Account No.", CurrencyCH1."Realized Losses Acc.");
            GenJnlLine."System-Created Entry" := true;
            GenJnlLine.Description := Text92000Txt + Format("VAT Entry"."Document No.");
            GenJnlLine."Bill-to/Pay-to No." := "VAT Entry"."Bill-to/Pay-to No.";

            GenJnlLine.Validate(Amount, FixAmount);

            if PostSettlement then begin
                Clear(GenJnlPostLine);
                PostGenJnlLine(GenJnlLine, TempDimSetEntry);
                GLEntry.FindLast();
                with NewVATEntry do begin
                    SetRange("Transaction No.", GLEntry."Transaction No.");
                    if FindLast() then
                        VATEntryNoToModify := "Entry No.";
                end;
            end;
        end;

        if (FixAmount <> 0) or (Abs(CorrBaseAmount) > 0.01) then begin  // Don't correct differences of 1 Cent or less
                                                                        // adjust VAT entries
            NewVATEntry := "VAT Entry";
            NewVATEntry."Currency Factor" := CurrExchRate."VAT Exch. Rate Amount" / CurrExchRate."Relational VAT Exch. Rate Amt";
            NewVATEntry.Amount := FixAmount;
            NewVATEntry.Base := CorrBaseAmount;

            // adjust add. curr.
            if (NewVATEntry."Additional-Currency Amount" <> 0) or
               (NewVATEntry."Additional-Currency Base" <> 0)
            then begin
                CurrencyCH1.Get(GLSetup."Additional Reporting Currency");
                CurrExchRate.SetRange("Currency Code", GLSetup."Additional Reporting Currency");
                if CurrExchRate.FindLast() then begin
                    CurrExchRate.TestField("Exchange Rate Amount");
                    CurrExchRate.TestField("Relational Exch. Rate Amount");

                    FixAmountAddCurr :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          PostingDate, GLSetup."Additional Reporting Currency", "VAT Entry".Amount + FixAmount,
                          CurrExchRate.ExchangeRate(PostingDate, GLSetup."Additional Reporting Currency")),
                        CurrencyCH1."Amount Rounding Precision") -
                      "VAT Entry"."Additional-Currency Amount";
                    CorrBaseAmtAddCurr :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          PostingDate, GLSetup."Additional Reporting Currency", "VAT Entry".Base + CorrBaseAmount,
                          CurrExchRate.ExchangeRate(PostingDate, GLSetup."Additional Reporting Currency")),
                        CurrencyCH1."Amount Rounding Precision") -
                      "VAT Entry"."Additional-Currency Base";

                    NewVATEntry."Additional-Currency Amount" := FixAmountAddCurr;
                    NewVATEntry."Additional-Currency Base" := CorrBaseAmtAddCurr;
                end;
            end;

            NewVATEntry."Unadjusted Exchange Rate" := false;
            NewVATEntry."Amount (FCY)" := 0;
            NewVATEntry."Base (FCY)" := 0;
            NewVATEntry."VAT Difference" := 0;
            NewVATEntry."Add.-Curr. VAT Difference" := 0;
            NewVATEntry."Exchange Rate Adjustment" := true;

            if not PostSettlement then
                if VATEntryNoToModify = 0 then
                    NewVATEntry."Entry No." := GetNextVATEntryNo()
                else
                    NewVATEntry."Entry No." := VATEntryNoToModify
            else begin
                if VATEntryNoToModify <> 0 then begin
                    NewVATEntry."Entry No." := VATEntryNoToModify;
                    NewVATEntry.Modify
                end else begin
                    NewVATEntry4No.FindLast();
                    NewVATEntry."Entry No." := NewVATEntry4No."Entry No." + 1;
                    NewVATEntry.Insert();
                end;
                if GLEntry."Entry No." = 0 then begin
                    VATEntryLink.SetRange("VAT Entry No.", "VAT Entry"."Entry No.");
                    if VATEntryLink.FindFirst() then
                        GLEntry."Entry No." := VATEntryLink."G/L Entry No.";
                end;
                if GLEntry."Entry No." <> 0 then
                    if not VATEntryLink.Get(GLEntry."Entry No.", NewVATEntry."Entry No.") then
                        VATEntryLink.InsertLinkSelf(GLEntry."Entry No.", NewVATEntry."Entry No.");
                if CorrRevChargeEntryNo <> 0 then begin
                    GLEntry.Get(CorrRevChargeEntryNo);
                    if not VATEntryLink.Get(GLEntry."Entry No.", NewVATEntry."Entry No.") then
                        VATEntryLink.InsertLinkSelf(GLEntry."Entry No.", NewVATEntry."Entry No.");
                end;
            end;
        end;

        "VAT Entry"."Unadjusted Exchange Rate" := false;

        if PostSettlement then begin
            "VAT Entry".Modify();
            UpdateGLRegToVATEntryNo();
        end;
    end;

    local procedure GetNextVATEntryNo(): Integer
    begin
        if NextVATEntryNo = 0 then begin
            VATEntry.SetCurrentKey("Entry No.");
            VATEntry.FindLast();
            NextVATEntryNo := VATEntry."Entry No." + 1;
        end
        else
            NextVATEntryNo += 1;

        exit(NextVATEntryNo);
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
