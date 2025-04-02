// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Ledger;
using System.Utilities;
using Microsoft.Bank.Deposit;

report 35 "Document Entries"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Foundation/Navigate/DocumentEntries.rdlc';
    Caption = 'Document Entries';
    AllowScheduling = false;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(DocNoFilter; Text001 + Format(DocNoFilter))
            {
            }
            column(PostingDateFilter; Text002 + PostingDateFilter)
            {
            }
            column(DocEntryNoofRecords; TempDocumentEntry."No. of Records")
            {
            }
            column(DocEntryTableName; TempDocumentEntry."Table Name")
            {
            }
            column(PrintAmtsInLCY; PrintAmountsInLCY)
            {
            }
            column(CurrencyCaptionRBC; CurrencyCaptionRBC)
            {
            }
            column(DocEntriesCaption; DocEntriesCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; PageNoCaptionLbl)
            {
            }
            column(NavigateFiltersCaption; NavigateFiltersCaptionLbl)
            {
            }
            column(DocEntryNofRecordsCaption; DocEntryNoofRecordsCptnLbl)
            {
            }
            column(DocEntryTableNameCaption; DocEntryTableNameCaptionLbl)
            {
            }
            dataitem("Sales Shipment Header"; "Sales Shipment Header")
            {
                DataItemTableView = sorting("No.");
                column(PostingDate_SalesShipmentHdr; Format("Posting Date"))
                {
                }
                column(No_SalesShipmentHdr; "No.")
                {
                    IncludeCaption = false;
                }
                column(SellToCustNo_SalesShipmentHdr; "Sell-to Customer No.")
                {
                    IncludeCaption = false;
                }
                column(BillToCustNo_SalesShipmentHdr; "Bill-to Customer No.")
                {
                    IncludeCaption = false;
                }
                column(PostingDescription_SalesShipmentHdr; "Posting Description")
                {
                    IncludeCaption = false;
                }
                column(BillToCustNo_SalesShipmentHdrCaption; FieldCaption("Bill-to Customer No."))
                {
                }
                column(SellToCustNo_SalesShipmentHdrCaption; FieldCaption("Sell-to Customer No."))
                {
                }
                column(PostingDescription_SalesShipmentHdrCaption; FieldCaption("Posting Description"))
                {
                }
                column(No_SalesShipmentHdrCaption; FieldCaption("No."))
                {
                }
                column(CurrencyCode_SalesShipmentHdr; "Currency Code")
                {
                }
                column(SalesShipmentHdrPostingDateCaption; SalesShptHeaderPostingDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Sales Shipment Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Sales Invoice Header"; "Sales Invoice Header")
            {
                DataItemTableView = sorting("No.");
                column(PostingDate_SalesInvHdr; Format("Posting Date"))
                {
                }
                column(No_SalesInvHdr; "No.")
                {
                    IncludeCaption = false;
                }
                column(PostingDescription_SalesInvHdr; "Posting Description")
                {
                    IncludeCaption = false;
                }
                column(SellToCustNo_SalesInvHdr; "Sell-to Customer No.")
                {
                    IncludeCaption = false;
                }
                column(BillToCustNo_SalesInvHdr; "Bill-to Customer No.")
                {
                    IncludeCaption = false;
                }
                column(Amt_SalesInvHdr; Amount)
                {
                    IncludeCaption = false;
                }
                column(AmtInclVAT_SalesInvHdr; "Amount Including VAT")
                {
                    IncludeCaption = false;
                }
                column(BillToCustNo_SalesInvHdrCaption; FieldCaption("Bill-to Customer No."))
                {
                }
                column(SellToCustNo_SalesInvHdrCaption; FieldCaption("Sell-to Customer No."))
                {
                }
                column(PostingDescription_SalesInvHdrCaption; FieldCaption("Posting Description"))
                {
                }
                column(No_SalesInvHdrCaption; FieldCaption("No."))
                {
                }
                column(Amt_SalesInvHdrCaption; FieldCaption(Amount))
                {
                }
                column(AmtInclVAT_SalesInvHdrCaption; FieldCaption("Amount Including VAT"))
                {
                }
                column(CurrencyCode_SalesInvHdr; "Currency Code")
                {
                }
                column(SalesInvHdrPostingDateCaption; SalesInvHeaderPostDateCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountsInLCY then
                        if "Currency Code" <> '' then begin
                            Amount := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", Amount, "Currency Factor");
                            "Amount Including VAT" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Amount Including VAT", "Currency Factor");
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Sales Invoice Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Return Receipt Header"; "Return Receipt Header")
            {
                DataItemTableView = sorting("No.");
                column(PostingDate_ReturnRcptHdr; Format("Posting Date"))
                {
                }
                column(No_ReturnRcptHdr; "No.")
                {
                    IncludeCaption = false;
                }
                column(PostingDescription_ReturnRcptHdr; "Posting Description")
                {
                    IncludeCaption = false;
                }
                column(SellToCustNo_ReturnRcptHdr; "Sell-to Customer No.")
                {
                    IncludeCaption = false;
                }
                column(BillToCustNo_ReturnRcptHdr; "Bill-to Customer No.")
                {
                    IncludeCaption = false;
                }
                column(BillToCustNo_ReturnRcptHdrCaption; FieldCaption("Bill-to Customer No."))
                {
                }
                column(SellToCustNo_ReturnRcptHdrCaption; FieldCaption("Sell-to Customer No."))
                {
                }
                column(PostingDescription_ReturnRcptHdrCaption; FieldCaption("Posting Description"))
                {
                }
                column(No_ReturnRcptHdrCaption; FieldCaption("No."))
                {
                }
                column(CurrencyCode_ReturnRcptHdr; "Currency Code")
                {
                }
                column(ReturnRcptHdrPostingDateCaption; ReturnRcptHeaderPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Return Receipt Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Sales Cr.Memo Header"; "Sales Cr.Memo Header")
            {
                DataItemTableView = sorting("No.");
                column(PostingDate_SalesCrMemoHdr; Format("Posting Date"))
                {
                }
                column(No_SalesCrMemoHdr; "No.")
                {
                    IncludeCaption = false;
                }
                column(PostingDescription_SalesCrMemoHdr; "Posting Description")
                {
                    IncludeCaption = false;
                }
                column(SellToCustNo_SalesCrMemoHdr; "Sell-to Customer No.")
                {
                    IncludeCaption = false;
                }
                column(BillToCustNo_SalesCrMemoHdr; "Bill-to Customer No.")
                {
                    IncludeCaption = false;
                }
                column(Amt_SalesCrMemoHdr; Amount)
                {
                    IncludeCaption = false;
                }
                column(AmtInclVAT_SalesCrMemoHdr; "Amount Including VAT")
                {
                    IncludeCaption = false;
                }
                column(BillToCustNo_SalesCrMemoHdrCaption; FieldCaption("Bill-to Customer No."))
                {
                }
                column(SellToCustNo_SalesCrMemoHdrCaption; FieldCaption("Sell-to Customer No."))
                {
                }
                column(PostingDescription_SalesCrMemoHdrCaption; FieldCaption("Posting Description"))
                {
                }
                column(No_SalesCrMemoHdrCaption; FieldCaption("No."))
                {
                }
                column(AmtInclVAT_SalesCrMemoHdrCaption; FieldCaption("Amount Including VAT"))
                {
                }
                column(Amt_SalesCrMemoHdrCaption; FieldCaption(Amount))
                {
                }
                column(CurrencyCode_SalesCrMemoHdr; "Currency Code")
                {
                }
                column(SalesCrMemoHdrPostingDateCaption; SalesCrMemoHeaderPostDtCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountsInLCY then
                        if "Currency Code" <> '' then begin
                            Amount := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", Amount, "Currency Factor");
                            "Amount Including VAT" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Amount Including VAT", "Currency Factor");
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Sales Cr.Memo Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Issued Reminder Header"; "Issued Reminder Header")
            {
                DataItemTableView = sorting("No.");
                column(PostingDate_IssuedReminderHdr; Format("Posting Date"))
                {
                }
                column(No_IssuedReminderHdr; "No.")
                {
                    IncludeCaption = false;
                }
                column(PostingDescription_IssuedReminderHdr; "Posting Description")
                {
                    IncludeCaption = false;
                }
                column(CurrencyCode_IssuedReminderHdr; "Currency Code")
                {
                }
                column(VATAmt_IssuedReminderHdr; "VAT Amount")
                {
                    IncludeCaption = false;
                }
                column(AdditionalFee_IssuedReminderHdr; "Additional Fee")
                {
                    AutoCalcField = true;
                    IncludeCaption = false;
                }
                column(InterestAmt_IssuedReminderHdr; "Interest Amount")
                {
                    IncludeCaption = false;
                }
                column(RemainingAmt_IssuedReminderHdr; "Remaining Amount")
                {
                    IncludeCaption = false;
                }
                column(PostingDescription_IssuedReminderHdrCaption; FieldCaption("Posting Description"))
                {
                }
                column(No_IssuedReminderHdrCaption; FieldCaption("No."))
                {
                }
                column(RemainingAmt_IssuedReminderHdrCaption; FieldCaption("Remaining Amount"))
                {
                }
                column(InterestAmt_IssuedReminderHdrCaption; FieldCaption("Interest Amount"))
                {
                }
                column(AdditionalFee_IssuedReminderHdrCaption; FieldCaption("Additional Fee"))
                {
                }
                column(VATAmt_IssuedReminderHdrCaption; FieldCaption("VAT Amount"))
                {
                }
                column(IssuedReminderHdrPostingDateCaption; IssuedReminderHeaderPostDtCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountsInLCY then
                        if "Currency Code" <> '' then begin
                            "Remaining Amount" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Remaining Amount", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                            "Interest Amount" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Interest Amount", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                            "Additional Fee" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Additional Fee", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                            "VAT Amount" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "VAT Amount", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Issued Reminder Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Issued Fin. Charge Memo Header"; "Issued Fin. Charge Memo Header")
            {
                DataItemTableView = sorting("No.");
                column(PostingDate_IssuedFinChargeMemoHdr; Format("Posting Date"))
                {
                }
                column(No_IssuedFinChargeMemoHdr; "No.")
                {
                    IncludeCaption = false;
                }
                column(PostingDescription_IssuedFinChargeMemoHdr; "Posting Description")
                {
                    IncludeCaption = false;
                }
                column(RemainingAmt_IssuedFinChargeMemoHdr; "Remaining Amount")
                {
                    IncludeCaption = false;
                }
                column(InterestAmt_IssuedFinChargeMemoHdr; "Interest Amount")
                {
                    IncludeCaption = false;
                }
                column(AdditionalFee_IssuedFinChargeMemoHdr; "Additional Fee")
                {
                    IncludeCaption = false;
                }
                column(VATAmt_IssuedFinChargeMemoHdr; "VAT Amount")
                {
                    IncludeCaption = false;
                }
                column(VATAmt_IssuedFinChargeMemoHdrCaption; FieldCaption("VAT Amount"))
                {
                }
                column(AdditionalFee_IssuedFinChargeMemoHdrCaption; FieldCaption("Additional Fee"))
                {
                }
                column(InterestAmt_IssuedFinChargeMemoHdrCaption; FieldCaption("Interest Amount"))
                {
                }
                column(RemainingAmt_IssuedFinChargeMemoHdrCaption; FieldCaption("Remaining Amount"))
                {
                }
                column(PostingDescription_IssuedFinChargeMemoHdrCaption; FieldCaption("Posting Description"))
                {
                }
                column(No_IssuedFinChargeMemoHdrCaption; FieldCaption("No."))
                {
                }
                column(CurrencyCode_IssuedFinChargeMemoHdr; "Currency Code")
                {
                }
                column(IssuedFinChargeMemoHdrPostingDateCaption; IssuedFinChgMemoHeaderPostDateCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountsInLCY then
                        if "Currency Code" <> '' then begin
                            "Remaining Amount" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Remaining Amount", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                            "Interest Amount" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Interest Amount", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                            "Additional Fee" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Additional Fee", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                            "VAT Amount" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "VAT Amount", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Issued Fin. Charge Memo Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Posted Deposit Header"; "Posted Deposit Header")
            {
                DataItemTableView = sorting("No.");
                column(CurrencyCaption_PostedDepositHdr; CurrencyCaption)
                {
                }
                column(PostingDate_PostedDepositHdr; Format("Posting Date"))
                {
                }
                column(No_PostedDepositHdr; "No.")
                {
                    IncludeCaption = false;
                }
                column(PostingDescription_PostedDepositHdr; "Posting Description")
                {
                    IncludeCaption = false;
                }
                column(BankAccNo_PostedDepositHdr; "Bank Account No.")
                {
                    IncludeCaption = false;
                }
                column(TotalDepositAmt_PostedDepositHdr; "Total Deposit Amount")
                {
                    IncludeCaption = false;
                }
                column(No_PostedDepositHdrCaption; FieldCaption("No."))
                {
                }
                column(PostingDescription_PostedDepositHdrCaption; FieldCaption("Posting Description"))
                {
                }
                column(BankAccNo_PostedDepositHdrCaption; FieldCaption("Bank Account No."))
                {
                }
                column(TotalDepositAmt_PostedDepositHdrCaption; FieldCaption("Total Deposit Amount"))
                {
                }
                column(CurrencyCode_PostedDepositHdr; "Currency Code")
                {
                }
                column(PostedDepositHdrPostingDateCaption; PostedDepositHeaderPostingDateCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountsInLCY then
                        if "Currency Code" <> '' then
                            "Total Deposit Amount" :=
                              CurrExchRate.ExchangeAmtFCYToLCY(
                                "Posting Date", "Currency Code", "Total Deposit Amount", "Currency Factor");
                end;

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Posted Deposit Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Purch. Rcpt. Header"; "Purch. Rcpt. Header")
            {
                DataItemTableView = sorting("No.");
                column(PostingDate_PurchRcptHdr; Format("Posting Date"))
                {
                }
                column(No_PurchRcptHdr; "No.")
                {
                    IncludeCaption = false;
                }
                column(PostingDescrption_PurchRcptHdr; "Posting Description")
                {
                    IncludeCaption = false;
                }
                column(BuyFromVendNo_PurchRcptHdr; "Buy-from Vendor No.")
                {
                    IncludeCaption = false;
                }
                column(PayToVendNo_PurchRcptHdr; "Pay-to Vendor No.")
                {
                    IncludeCaption = false;
                }
                column(PayToVendNo_PurchRcptHdrCaption; FieldCaption("Pay-to Vendor No."))
                {
                }
                column(BuyFromVendNo_PurchRcptHdrCaption; FieldCaption("Buy-from Vendor No."))
                {
                }
                column(PostingDescrption_PurchRcptHdrCaption; FieldCaption("Posting Description"))
                {
                }
                column(No_PurchRcptHdrCaption; FieldCaption("No."))
                {
                }
                column(CurrencyCode_PurchRcptHdr; "Currency Code")
                {
                }
                column(PurchRcptHdrPostingDateCaption; PurchRcptHeaderPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Purch. Rcpt. Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Purch. Inv. Header"; "Purch. Inv. Header")
            {
                DataItemTableView = sorting("No.");
                column(PostingDate_PurchInvHdr; Format("Posting Date"))
                {
                }
                column(No_PurchInvHdr; "No.")
                {
                    IncludeCaption = false;
                }
                column(PostingDescription_PurchInvHdr; "Posting Description")
                {
                    IncludeCaption = false;
                }
                column(BuyFromVendNo_PurchInvHdr; "Buy-from Vendor No.")
                {
                    IncludeCaption = false;
                }
                column(PayToVendNo_PurchInvHdr; "Pay-to Vendor No.")
                {
                    IncludeCaption = false;
                }
                column(Amt_PurchInvHdr; Amount)
                {
                    IncludeCaption = false;
                }
                column(CurrencyCode_PurchInvHdr; "Currency Code")
                {
                }
                column(AmtInclVAT_PurchInvHdr; "Amount Including VAT")
                {
                    IncludeCaption = false;
                }
                column(Amt_PurchInvHdrCaption; FieldCaption(Amount))
                {
                }
                column(PayToVendNo_PurchInvHdrCaption; FieldCaption("Pay-to Vendor No."))
                {
                }
                column(BuyFromVendNo_PurchInvHdrCaption; FieldCaption("Buy-from Vendor No."))
                {
                }
                column(PostingDescription_PurchInvHdrCaption; FieldCaption("Posting Description"))
                {
                }
                column(No_PurchInvHdrCaption; FieldCaption("No."))
                {
                }
                column(AmtInclVAT_PurchInvHdrCaption; FieldCaption("Amount Including VAT"))
                {
                }
                column(PurchInvHdrPostingDateCaption; PurchInvHeaderPostDtCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountsInLCY then
                        if "Currency Code" <> '' then begin
                            Amount := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", Amount, "Currency Factor");
                            "Amount Including VAT" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Amount Including VAT", "Currency Factor");
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Purch. Inv. Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Return Shipment Header"; "Return Shipment Header")
            {
                DataItemTableView = sorting("No.");
                column(PostingDate_ReturnShipmentHdr; Format("Posting Date"))
                {
                }
                column(No_ReturnShipmentHdr; "No.")
                {
                    IncludeCaption = false;
                }
                column(PostingDescription_ReturnShipmentHdr; "Posting Description")
                {
                    IncludeCaption = false;
                }
                column(BuyFromVendNo_ReturnShipmentHdr; "Buy-from Vendor No.")
                {
                    IncludeCaption = false;
                }
                column(PayToVendNo_ReturnShipmentHdr; "Pay-to Vendor No.")
                {
                    IncludeCaption = false;
                }
                column(PayToVendNo_ReturnShipmentHdrCaption; FieldCaption("Pay-to Vendor No."))
                {
                }
                column(BuyFromVendNo_ReturnShipmentHdrCaption; FieldCaption("Buy-from Vendor No."))
                {
                }
                column(PostingDescription_ReturnShipmentHdrCaption; FieldCaption("Posting Description"))
                {
                }
                column(No_ReturnShipmentHdrCaption; FieldCaption("No."))
                {
                }
                column(CurrencyCode_ReturnShipmentHdr; "Currency Code")
                {
                }
                column(ReturnShipmentHdrPostingDateCaption; ReturnShptHeaderPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Return Shipment Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Purch. Cr. Memo Hdr."; "Purch. Cr. Memo Hdr.")
            {
                DataItemTableView = sorting("No.");
                column(PostingDate_PurchCrMemoHdr; Format("Posting Date"))
                {
                }
                column(No_PurchCrMemoHdr; "No.")
                {
                    IncludeCaption = false;
                }
                column(PostingDescription_PurchCrMemoHdr; "Posting Description")
                {
                    IncludeCaption = false;
                }
                column(BuyFromVendNo_PurchCrMemoHdr; "Buy-from Vendor No.")
                {
                    IncludeCaption = false;
                }
                column(PayToVendNo_PurchCrMemoHdr; "Pay-to Vendor No.")
                {
                    IncludeCaption = false;
                }
                column(Amt_PurchCrMemoHdr; Amount)
                {
                    IncludeCaption = false;
                }
                column(CurrencyCode_PurchCrMemoHdr; "Currency Code")
                {
                }
                column(AmtInclVAT_PurchCrMemoHdr; "Amount Including VAT")
                {
                    IncludeCaption = false;
                }
                column(Amt_PurchCrMemoHdrCaption; FieldCaption(Amount))
                {
                }
                column(PayToVendNo_PurchCrMemoHdrCaption; FieldCaption("Pay-to Vendor No."))
                {
                }
                column(BuyFromVendNo_PurchCrMemoHdrCaption; FieldCaption("Buy-from Vendor No."))
                {
                }
                column(PostingDescription_PurchCrMemoHdrCaption; FieldCaption("Posting Description"))
                {
                }
                column(No_PurchCrMemoHdrCaption; FieldCaption("No."))
                {
                }
                column(AmtInclVAT_PurchCrMemoHdrCaption; FieldCaption("Amount Including VAT"))
                {
                }
                column(PurchCrMemoHdrPostingDateCaption; PurchCrMemoHdrPostDtCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountsInLCY then
                        if "Currency Code" <> '' then begin
                            Amount := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", Amount, "Currency Factor");
                            "Amount Including VAT" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Amount Including VAT", "Currency Factor");
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Purch. Cr. Memo Hdr." then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Transfer Shipment Header"; "Transfer Shipment Header")
            {
                DataItemTableView = sorting("No.");
                column(PostingDate_TransferShipmentHdr; Format("Posting Date"))
                {
                }
                column(No_TransferShipmentHdr; "No.")
                {
                    IncludeCaption = false;
                }
                column(TransferFromCode_TransferShipmentHdr; "Transfer-from Code")
                {
                    IncludeCaption = false;
                }
                column(TransferFromName_TransferShipmentHdr; "Transfer-from Name")
                {
                    IncludeCaption = false;
                }
                column(TransferToCode_TransferShipmentHdr; "Transfer-to Code")
                {
                    IncludeCaption = false;
                }
                column(TransferToName_TransferShipmentHdr; "Transfer-to Name")
                {
                    IncludeCaption = false;
                }
                column(TransferToName_TransferShipmentHdrCaption; FieldCaption("Transfer-to Name"))
                {
                }
                column(TransferToCode_TransferShipmentHdrCaption; FieldCaption("Transfer-to Code"))
                {
                }
                column(TransferFromName_TransferShipmentHdrCaption; FieldCaption("Transfer-from Name"))
                {
                }
                column(TransferFromCode_TransferShipmentHdrCaption; FieldCaption("Transfer-from Code"))
                {
                }
                column(No_TransferShipmentHdrCaption; FieldCaption("No."))
                {
                }
                column(TransferShipmentHdrPostingDateCaption; TransShptHeaderPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Transfer Shipment Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Transfer Receipt Header"; "Transfer Receipt Header")
            {
                DataItemTableView = sorting("No.");
                column(PostingDate_TransferRcptHdr; Format("Posting Date"))
                {
                }
                column(No_TransferRcptHdr; "No.")
                {
                    IncludeCaption = false;
                }
                column(TransferFromCode_TransferRcptHdr; "Transfer-from Code")
                {
                    IncludeCaption = false;
                }
                column(TransferFromName_TransferRcptHdr; "Transfer-from Name")
                {
                    IncludeCaption = false;
                }
                column(TransferToCode_TransferRcptHdr; "Transfer-to Code")
                {
                    IncludeCaption = false;
                }
                column(TransferToName_TransferRcptHdr; "Transfer-to Name")
                {
                    IncludeCaption = false;
                }
                column(TransferToName_TransferRcptHdrCaption; FieldCaption("Transfer-to Name"))
                {
                }
                column(TransferToCode_TransferRcptHdrCaption; FieldCaption("Transfer-to Code"))
                {
                }
                column(TransferFromName_TransferRcptHdrCaption; FieldCaption("Transfer-from Name"))
                {
                }
                column(TransferFromCode_TransferRcptHdrCaption; FieldCaption("Transfer-from Code"))
                {
                }
                column(No_TransferRcptHdrCaption; FieldCaption("No."))
                {
                }
                column(TransferRcptHdrPostingDateCaption; TransRcptHeaderPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Transfer Receipt Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Posted Whse. Shipment Line"; "Posted Whse. Shipment Line")
            {
                DataItemTableView = sorting("Posted Source No.", "Posting Date");
                column(PostingDate_PostedWhseShipmentLine; Format("Posting Date"))
                {
                }
                column(ItemNo_PostedWhseShipmentLine; "Item No.")
                {
                    IncludeCaption = false;
                }
                column(Qty_PostedWhseShipmentLine; Quantity)
                {
                    IncludeCaption = false;
                }
                column(UOMCode_PostedWhseShipmentLine; "Unit of Measure Code")
                {
                    IncludeCaption = false;
                }
                column(Description_PostedWhseShipmentLine; Description)
                {
                    IncludeCaption = false;
                }
                column(PostedSourceDoc_PostedWhseShipmentLine; "Posted Source Document")
                {
                    IncludeCaption = false;
                }
                column(PostedSourceNo_PostedWhseShipmentLine; "Posted Source No.")
                {
                    IncludeCaption = false;
                }
                column(No_PostedWhseShipmentLine; "No.")
                {
                }
                column(LineNo_PostedWhseShipmentLine; "Line No.")
                {
                }
                column(Qty_PostedWhseShipmentLineCaption; FieldCaption(Quantity))
                {
                }
                column(UOMCode_PostedWhseShipmentLineCaption; FieldCaption("Unit of Measure Code"))
                {
                }
                column(Description_PostedWhseShipmentLineCaption; FieldCaption(Description))
                {
                }
                column(ItemNo_PostedWhseShipmentLineCaption; FieldCaption("Item No."))
                {
                }
                column(PostedSourceNo_PostedWhseShipmentLineCaption; FieldCaption("Posted Source No."))
                {
                }
                column(PostedSourceDoc_PostedWhseShipmentLineCaption; FieldCaption("Posted Source Document"))
                {
                }
                column(PostedWhseShipmentLinePostingDateCaption; PostedWhseShptLinePostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Posted Whse. Shipment Line" then
                        CurrReport.Break();

                    SetCurrentKey("Posted Source No.", "Posting Date");
                    SetFilter("Posted Source No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Posted Whse. Receipt Line"; "Posted Whse. Receipt Line")
            {
                DataItemTableView = sorting("Posted Source No.", "Posting Date");
                column(PostingDate_PostedWhseRcptLine; Format("Posting Date"))
                {
                }
                column(Description_PostedWhseRcptLine; Description)
                {
                }
                column(ItemNo_PostedWhseRcptLine; "Item No.")
                {
                }
                column(UOMCode_PostedWhseRcptLine; "Unit of Measure Code")
                {
                }
                column(Qty_PostedWhseRcptLine; Quantity)
                {
                }
                column(PostedSourceDoc_PostedWhseRcptLine; "Posted Source Document")
                {
                }
                column(PostedSourceNo_PostedWhseRcptLine; "Posted Source No.")
                {
                }
                column(No_PostedWhseRcptLine; "No.")
                {
                }
                column(LineNo_PostedWhseRcptLine; "Line No.")
                {
                }
                column(Qty_PostedWhseRcptLineCaption; FieldCaption(Quantity))
                {
                }
                column(UOMCode_PostedWhseRcptLineCaption; FieldCaption("Unit of Measure Code"))
                {
                }
                column(Description_PostedWhseRcptLineCaption; FieldCaption(Description))
                {
                }
                column(ItemNo_PostedWhseRcptLineCaption; FieldCaption("Item No."))
                {
                }
                column(PostedSourceNo_PostedWhseRcptLineCaption; FieldCaption("Posted Source No."))
                {
                }
                column(PostedSourceDoc_PostedWhseRcptLineCaption; FieldCaption("Posted Source Document"))
                {
                }
                column(PostedWhseRcptLinePostingDateCaption; PostedWhseRcptLinePostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Posted Whse. Receipt Line" then
                        CurrReport.Break();

                    SetCurrentKey("Posted Source No.", "Posting Date");
                    SetFilter("Posted Source No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Posted Deposit Line"; "Posted Deposit Line")
            {
                DataItemTableView = sorting("Document No.", "Posting Date");
                column(CurrencyCaption_PostedDepositLine; CurrencyCaption)
                {
                }
                column(PostingDate_PostedDepositLine; Format("Posting Date"))
                {
                }
                column(DepositNo_PostedDepositLine; "Deposit No.")
                {
                }
                column(Description_PostedDepositLine; Description)
                {
                }
                column(AccType_PostedDepositLine; "Account Type")
                {
                }
                column(AccNo_PostedDepositLine; "Account No.")
                {
                }
                column(DocNo_PostedDepositLine; "Document No.")
                {
                }
                column(Amt_PostedDepositLine; Amount)
                {
                }
                column(EntryNo_PostedDepositLine; "Entry No.")
                {
                }
                column(BankAccLedgEntryNo_PostedDepositLine; "Bank Account Ledger Entry No.")
                {
                }
                column(CurrencyCode_PostedDepositLine; "Currency Code")
                {
                }
                column(DepositNo_PostedDepositLineCaption; FieldCaption("Deposit No."))
                {
                }
                column(Description_PostedDepositLineCaption; FieldCaption(Description))
                {
                }
                column(AccType_PostedDepositLineCaption; FieldCaption("Account Type"))
                {
                }
                column(AccNo_PostedDepositLineCaption; FieldCaption("Account No."))
                {
                }
                column(DocNo_PostedDepositLineCaption; FieldCaption("Document No."))
                {
                }
                column(Amt_PostedDepositLineCaption; FieldCaption(Amount))
                {
                }
                column(EntryNo_PostedDepositLineCaption; FieldCaption("Entry No."))
                {
                }
                column(BankAccLedgEntryNo_PostedDepositLineCaption; FieldCaption("Bank Account Ledger Entry No."))
                {
                }
                column(PostedDepositLinePostingDateCaption; PostedDepositLinePostingDateCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountsInLCY then
                        if "Currency Code" <> '' then begin
                            if PostedDepositHeader."No." <> "Deposit No." then
                                PostedDepositHeader.Get("Deposit No.");
                            Amount :=
                              CurrExchRate.ExchangeAmtFCYToLCY(
                                "Posting Date", "Currency Code", Amount, PostedDepositHeader."Currency Factor");
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Posted Deposit Line" then
                        CurrReport.Break();

                    if NavigateDeposit then begin
                        SetCurrentKey("Deposit No.");
                        SetFilter("Deposit No.", DocNoFilter);
                    end else begin
                        SetCurrentKey("Document No.", "Posting Date");
                        SetFilter("Document No.", DocNoFilter);
                    end;
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemTableView = sorting("G/L Account No.", "Posting Date");
                column(PostingDate_GLEntry; Format("Posting Date"))
                {
                }
                column(DocNo_GLEntry; "Document No.")
                {
                }
                column(Description_GLEntry; Description)
                {
                }
                column(VATAmt_GLEntry; "VAT Amount")
                {
                }
                column(DebitAmt_GLEntry; "Debit Amount")
                {
                }
                column(CreditAmt_GLEntry; "Credit Amount")
                {
                }
                column(EntryNo_GLEntry; "Entry No.")
                {
                }
                column(Qty_GLEntry; Quantity)
                {
                }
                column(GLAccNo_GLEntry; "G/L Account No.")
                {
                }
                column(EntryNo_GLEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(CreditAmt_GLEntryCaption; FieldCaption("Credit Amount"))
                {
                }
                column(DebitAmt_GLEntryCaption; FieldCaption("Debit Amount"))
                {
                }
                column(VATAmt_GLEntryCaption; FieldCaption("VAT Amount"))
                {
                }
                column(Description_GLEntryCaption; FieldCaption(Description))
                {
                }
                column(DocNo_GLEntryCaption; FieldCaption("Document No."))
                {
                }
                column(Qty_GLEntryCaption; FieldCaption(Quantity))
                {
                }
                column(GLAccNo_GLEntryCaption; FieldCaption("G/L Account No."))
                {
                }
                column(GLEntryPostingDateCaption; GLEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"G/L Entry" then
                        CurrReport.Break();

                    if NavigateDeposit then begin
                        SetCurrentKey("External Document No.", "Posting Date");
                        SetFilter("External Document No.", DocNoFilter);
                    end else begin
                        SetCurrentKey("Document No.", "Posting Date");
                        SetFilter("Document No.", DocNoFilter);
                    end;
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("VAT Entry"; "VAT Entry")
            {
                DataItemTableView = sorting("Document No.", "Posting Date");
                column(PostingDate_VATEntry; Format("Posting Date"))
                {
                }
                column(DocNo_VATEntry; "Document No.")
                {
                }
                column(Amt_VATEntry; Amount)
                {
                }
                column(EntryNo_VATEntry; "Entry No.")
                {
                }
                column(EntryNo_VATEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(Amt_VATEntryCaption; FieldCaption(Amount))
                {
                }
                column(DocNo_VATEntryCaption; FieldCaption("Document No."))
                {
                }
                column(VATEntryPostingDateCaption; VATEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"VAT Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemTableView = sorting("Document No.");
                column(EntryNo_CustLedgEntry; "Entry No.")
                {
                }
                column(Amount_CustLedgEntry; Amount)
                {
                }
                column(PstDate_CustLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_CustLedgEntry; "Document No.")
                {
                }
                column(Description_CustLedgEntry; Description)
                {
                }
                column(RemainingAmt_CustLedgEntry; "Remaining Amount")
                {
                }
                column(CurrencyCode_CustLedgEntry; "Currency Code")
                {
                }
                column(CustNo_CustLedgEntry; "Customer No.")
                {
                }
                column(AmtLCY_CustLedgEntry; "Amount (LCY)")
                {
                }
                column(RemainingAmtLCY_CustLedgEntry; "Remaining Amt. (LCY)")
                {
                }
                column(EntryNo_CustLedgEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(RemainingAmt_CustLedgEntryCaption; FieldCaption("Remaining Amount"))
                {
                }
                column(Amt_CustLedgEntryCaption; FieldCaption(Amount))
                {
                }
                column(Description_CustLedgEntryCaption; FieldCaption(Description))
                {
                }
                column(DocNo_CustLedgEntryCaption; FieldCaption("Document No."))
                {
                }
                column(CustNo_CustLedgEntryCaption; FieldCaption("Customer No."))
                {
                }
                column(CustLedgEntryPostingDateCaption; CustLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Cust. Ledger Entry" then
                        CurrReport.Break();

                    if NavigateDeposit then begin
                        SetCurrentKey("External Document No.", "Posting Date");
                        SetFilter("External Document No.", DocNoFilter);
                    end else begin
                        SetCurrentKey("Document No.");
                        SetFilter("Document No.", DocNoFilter);
                    end;
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Detailed Cust. Ledg. Entry"; "Detailed Cust. Ledg. Entry")
            {
                DataItemTableView = sorting("Document No.");
                column(PostingDate_DetailedCustLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_DetailedCustLedgEntry; "Document No.")
                {
                }
                column(DebitAmt_DetailedCustLedgEntry; "Debit Amount")
                {
                }
                column(CreditAmt_DetailedCustLedgEntry; "Credit Amount")
                {
                }
                column(EntryNo_DetailedCustLedgEntry; "Entry No.")
                {
                }
                column(DocType_DetailedCustLedgEntry; "Document Type")
                {
                }
                column(CurrencyCode_DetailedCustLedgEntry; "Currency Code")
                {
                }
                column(DebitAmtLCY_DetailedCustLedgEntry; "Debit Amount (LCY)")
                {
                }
                column(CreditAmtLCY_DetailedCustLedgEntry; "Credit Amount (LCY)")
                {
                }
                column(EntryNo_DetailedCustLedgEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(CreditAmt_DetailedCustLedgEntryCaption; FieldCaption("Credit Amount"))
                {
                }
                column(DebitAmt_DetailedCustLedgEntryCaption; FieldCaption("Debit Amount"))
                {
                }
                column(DocNo_DetailedCustLedgEntryCaption; FieldCaption("Document No."))
                {
                }
                column(DocType_DetailedCustLedgEntryCaption; FieldCaption("Document Type"))
                {
                }
                column(DetailedCustLedgEntryPostingDateCaption; DtldCustLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Detailed Cust. Ledg. Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Reminder/Fin. Charge Entry"; "Reminder/Fin. Charge Entry")
            {
                DataItemTableView = sorting(Type, "No.");
                column(EntryNo_ReminderFinChargeEntry; "Entry No.")
                {
                }
                column(PostingDate_ReminderFinChargeEntry; Format("Posting Date"))
                {
                }
                column(DocNo_ReminderFinChargeEntry; "Document No.")
                {
                }
                column(ReminderLevel_ReminderFinChargeEntry; "Reminder Level")
                {
                }
                column(InterestAmt_ReminderFinChargeEntry; "Interest Amount")
                {
                }
                column(RemainingAmt_ReminderFinChargeEntry; "Remaining Amount")
                {
                }
                column(EntryNo_ReminderFinChargeEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(InterestAmt_ReminderFinChargeEntryCaption; FieldCaption("Interest Amount"))
                {
                }
                column(ReminderLevel_ReminderFinChargeEntryCaption; FieldCaption("Reminder Level"))
                {
                }
                column(DocNo_ReminderFinChargeEntryCaption; FieldCaption("Document No."))
                {
                }
                column(RemainingAmt_ReminderFinChargeEntryCaption; FieldCaption("Remaining Amount"))
                {
                }
                column(ReminderFinChargeEntryPostingDateCaption; ReminderEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Reminder/Fin. Charge Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemTableView = sorting("Document No.");
                column(EntryNo_VendLedgEntry; "Entry No.")
                {
                }
                column(PostingDate_VendLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_VendLedgEntry; "Document No.")
                {
                }
                column(Description_VendLedgEntry; Description)
                {
                }
                column(Amt_VendLedgEntry; Amount)
                {
                }
                column(RemainingAmt_VendLedgEntry; "Remaining Amount")
                {
                }
                column(CurrencyCode_VendLedgEntry; "Currency Code")
                {
                }
                column(AmtLCY_VendLedgEntry; "Amount (LCY)")
                {
                }
                column(RemainingAmtLCY_VendLedgEntry; "Remaining Amt. (LCY)")
                {
                }
                column(EntryNo_VendLedgEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(RemainingAmt_VendLedgEntryCaption; FieldCaption("Remaining Amount"))
                {
                }
                column(Amt_VendLedgEntryCaption; FieldCaption(Amount))
                {
                }
                column(Description_VendLedgEntryCaption; FieldCaption(Description))
                {
                }
                column(DocNo_VendLedgEntryCaption; FieldCaption("Document No."))
                {
                }
                column(VendLedgEntryPostingDateCaption; VendLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Vendor Ledger Entry" then
                        CurrReport.Break();

                    if NavigateDeposit then begin
                        SetCurrentKey("External Document No.");
                        SetFilter("External Document No.", DocNoFilter);
                    end else begin
                        SetCurrentKey("Document No.");
                        SetFilter("Document No.", DocNoFilter);
                    end;
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
            {
                DataItemTableView = sorting("Document No.");
                column(PostingDate_DetailedVendLedgEntry; Format("Posting Date"))
                {
                }
                column(DebitAmt_DetailedVendLedgEntry; "Debit Amount")
                {
                }
                column(CreditAmt_DetailedVendLedgEntry; "Credit Amount")
                {
                }
                column(EntryNo_DetailedVendLedgEntry; "Entry No.")
                {
                }
                column(DocType_DetailedVendLedgEntry; "Document Type")
                {
                }
                column(DocNo_DetailedVendLedgEntry; "Document No.")
                {
                }
                column(CurrencyCode_DetailedVendLedgEntry; "Currency Code")
                {
                }
                column(DebitAmtLCY_DetailedVendLedgEntry; "Debit Amount (LCY)")
                {
                }
                column(CreditAmtLCY_DetailedVendLedgEntry; "Credit Amount (LCY)")
                {
                }
                column(EntryNo_DetailedVendLedgEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(CreditAmt_DetailedVendLedgEntryCaption; FieldCaption("Credit Amount"))
                {
                }
                column(DebitAmt_DetailedVendLedgEntryCaption; FieldCaption("Debit Amount"))
                {
                }
                column(DocNo_DetailedVendLedgEntryCaption; FieldCaption("Document No."))
                {
                }
                column(DocType_DetailedVendLedgEntryCaption; FieldCaption("Document Type"))
                {
                }
                column(DetailedVendLedgEntryPostingDateCaption; DtldVendLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Detailed Vendor Ledg. Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemTableView = sorting("Document No.");
                column(EntryNo_ItemLedgEntry; "Entry No.")
                {
                }
                column(PostingDate_ItemLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_ItemLedgEntry; "Document No.")
                {
                }
                column(Description_ItemLedgEntry; Description)
                {
                }
                column(Qty_ItemLedgEntry; Quantity)
                {
                }
                column(RemainingQty_ItemLedgEntry; "Remaining Quantity")
                {
                }
                column(EntryNo_ItemLedgEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(RemainingQty_ItemLedgEntryCaption; FieldCaption("Remaining Quantity"))
                {
                }
                column(Qty_ItemLedgEntryCaption; FieldCaption(Quantity))
                {
                }
                column(Description_ItemLedgEntryCaption; FieldCaption(Description))
                {
                }
                column(DocNo_ItemLedgEntryCaption; FieldCaption("Document No."))
                {
                }
                column(Open_ItemLedgEntry; Format(Open))
                {
                }
                column(ItemLedgEntryPostingDateCaption; ItemLedgEntryPostDtCaptionLbl)
                {
                }
                column(ItemLedgEntryOpenCaption; CaptionClassTranslate(FieldCaption(Open)))
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Item Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Value Entry"; "Value Entry")
            {
                DataItemTableView = sorting("Document No.");
                column(PostingDate_ValueEntry; Format("Posting Date"))
                {
                }
                column(DocNo_ValueEntry; "Document No.")
                {
                }
                column(Description_ValueEntry; Description)
                {
                }
                column(EntryNo_ValueEntry; "Entry No.")
                {
                }
                column(ValuedQty_ValueEntry; "Valued Quantity")
                {
                }
                column(InvoicedQty_ValueEntry; "Invoiced Quantity")
                {
                }
                column(EntryNo_ValueEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(InvoicedQty_ValueEntryCaption; FieldCaption("Invoiced Quantity"))
                {
                }
                column(ValuedQty_ValueEntryCaption; FieldCaption("Valued Quantity"))
                {
                }
                column(Description_ValueEntryCaption; FieldCaption(Description))
                {
                }
                column(DocNo_ValueEntryCaption; FieldCaption("Document No."))
                {
                }
                column(ValueEntryPostingDateCaption; ValueEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Value Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Phys. Inventory Ledger Entry"; "Phys. Inventory Ledger Entry")
            {
                DataItemTableView = sorting("Document No.", "Posting Date");
                column(EntryNo_PhysInvtLedgEntry; "Entry No.")
                {
                }
                column(PostingDate_PhysInvtLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_PhysInvtLedgEntry; "Document No.")
                {
                }
                column(Description_PhysInvtLedgEntry; Description)
                {
                }
                column(Qty_PhysInvtLedgEntry; Quantity)
                {
                }
                column(UnitAmt_PhysInvtLedgEntry; "Unit Amount")
                {
                }
                column(UnitCost_PhysInvtLedgEntry; "Unit Cost")
                {
                }
                column(Amt_PhysInvtLedgEntry; Amount)
                {
                }
                column(EntryNo_PhysInvtLedgEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(Amt_PhysInvtLedgEntryCaption; FieldCaption(Amount))
                {
                }
                column(UnitCost_PhysInvtLedgEntryCaption; FieldCaption("Unit Cost"))
                {
                }
                column(UnitAmt_PhysInvtLedgEntryCaption; FieldCaption("Unit Amount"))
                {
                }
                column(Qty_PhysInvtLedgEntryCaption; FieldCaption(Quantity))
                {
                }
                column(Description_PhysInvtLedgEntryCaption; FieldCaption(Description))
                {
                }
                column(DocNo_PhysInvtLedgEntryCaption; FieldCaption("Document No."))
                {
                }
                column(PhysInventoryLedgEntryPostingDateCaption; PhysInvtLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Phys. Inventory Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Res. Ledger Entry"; "Res. Ledger Entry")
            {
                DataItemTableView = sorting("Document No.", "Posting Date");
                column(PostingDate_ResLedgEntry; Format("Posting Date"))
                {
                }
                column(Description_ResLedgEntry; Description)
                {
                }
                column(DocNo_ResLedgEntry; "Document No.")
                {
                }
                column(EntryNo_ResLedgEntry; "Entry No.")
                {
                }
                column(Qty_ResLedgEntry; Quantity)
                {
                }
                column(UnitCost_ResLedgEntry; "Unit Cost")
                {
                }
                column(UnitPrice_ResLedgEntry; "Unit Price")
                {
                }
                column(EntryNo_ResLedgEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(UnitPrice_ResLedgEntryCaption; FieldCaption("Unit Price"))
                {
                }
                column(UnitCost_ResLedgEntryCaption; FieldCaption("Unit Cost"))
                {
                }
                column(Qty_ResLedgEntryCaption; FieldCaption(Quantity))
                {
                }
                column(Description_ResLedgEntryCaption; FieldCaption(Description))
                {
                }
                column(DocNo_ResLedgEntryCaption; FieldCaption("Document No."))
                {
                }
                column(ResLedgEntryPostingDateCaption; ResLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Res. Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Job Ledger Entry"; "Job Ledger Entry")
            {
                DataItemTableView = sorting("Document No.", "Posting Date");
                column(PostingDate_JobLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_JobLedgEntry; "Document No.")
                {
                }
                column(Description_JobLedgEntry; Description)
                {
                }
                column(Qty_JobLedgEntry; Quantity)
                {
                }
                column(UnitCostLCY_JobLedgEntry; "Unit Cost (LCY)")
                {
                }
                column(UnitPriceLCY_JobLedgEntry; "Unit Price (LCY)")
                {
                }
                column(EntryNo_JobLedgEntry; "Entry No.")
                {
                }
                column(EntryNo_JobLedgEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(UnitPriceLCY_JobLedgEntryCaption; FieldCaption("Unit Price (LCY)"))
                {
                }
                column(UnitCostLCY_JobLedgEntryCaption; FieldCaption("Unit Cost (LCY)"))
                {
                }
                column(Qty_JobLedgEntryCaption; FieldCaption(Quantity))
                {
                }
                column(Description_JobLedgEntryCaption; FieldCaption(Description))
                {
                }
                column(DocNo_JobLedgEntryCaption; FieldCaption("Document No."))
                {
                }
                column(JobLedgEntryPostingDateCaption; JobLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Job Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
            {
                DataItemTableView = sorting("Document No.", "Posting Date");
                column(EntryNo_BankAccLedgEntry; "Entry No.")
                {
                }
                column(PostingDate_BankAccLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_BankAccLedgEntry; "Document No.")
                {
                }
                column(Description_BankAccLedgEntry; Description)
                {
                }
                column(DebitAmt_BankAccLedgEntry; "Debit Amount")
                {
                }
                column(CreditAmt_BankAccLedgEntry; "Credit Amount")
                {
                }
                column(CurrencyCode_BankAccLedgEntry; "Currency Code")
                {
                }
                column(DebitAmtLCY_BankAccLedgEntry; "Debit Amount (LCY)")
                {
                }
                column(CreditAmtLCY_BankAccLedgEntry; "Credit Amount (LCY)")
                {
                }
                column(EntryNo_BankAccLedgEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(CreditAmt_BankAccLedgEntryCaption; FieldCaption("Credit Amount"))
                {
                }
                column(DebitAmt_BankAccLedgEntryCaption; FieldCaption("Debit Amount"))
                {
                }
                column(Description_BankAccLedgEntryCaption; FieldCaption(Description))
                {
                }
                column(DocNo_BankAccLedgEntryCaption; FieldCaption("Document No."))
                {
                }
                column(BankAccLedgEntryPostingDateCaption; BankAccLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Bank Account Ledger Entry" then
                        CurrReport.Break();

                    if NavigateDeposit then begin
                        SetCurrentKey("External Document No.", "Posting Date");
                        SetFilter("External Document No.", DocNoFilter);
                    end else begin
                        SetCurrentKey("Document No.", "Posting Date");
                        SetFilter("Document No.", DocNoFilter);
                    end;
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Check Ledger Entry"; "Check Ledger Entry")
            {
                DataItemTableView = sorting("Document No.", "Posting Date");
                column(DocNo_CheckLedgEntry; "Document No.")
                {
                }
                column(PostingDate_CheckLedgEntry; Format("Posting Date"))
                {
                }
                column(Description_CheckLedgEntry; Description)
                {
                }
                column(Amt_CheckLedgEntry; Amount)
                {
                }
                column(Open_CheckLedgEntry; Open)
                {
                }
                column(EntryNo_CheckLedgEntry; "Entry No.")
                {
                }
                column(CheckDate_CheckLedgEntry; Format("Check Date"))
                {
                }
                column(CheckNo_CheckLedgEntry; "Check No.")
                {
                }
                column(CheckType_CheckLedgEntry; "Check Type")
                {
                }
                column(Amt_CheckLedgEntryCaption; FieldCaption(Amount))
                {
                }
                column(Description_CheckLedgEntryCaption; FieldCaption(Description))
                {
                }
                column(DocNo_CheckLedgEntryCaption; FieldCaption("Document No."))
                {
                }
                column(EntryNo_CheckLedgEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(CheckType_CheckLedgEntryCaption; FieldCaption("Check Type"))
                {
                }
                column(CheckNo_CheckLedgEntryCaption; FieldCaption("Check No."))
                {
                }
                column(CheckLedgerEntryOpenCaption; FieldCaption(Open))
                {
                }
                column(CheckLedgerEntryPostingDateCaption; CheckLedgEntryPostDtCaptionLbl)
                {
                }
                column(CheckLedgerEntryCheckDateCaption; CheckLedgEntryCheckDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Check Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("FA Ledger Entry"; "FA Ledger Entry")
            {
                DataItemTableView = sorting("Document Type", "Document No.");
                column(PostingDate_FALedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_FALedgEntry; "Document No.")
                {
                }
                column(Description_FALedgEntry; Description)
                {
                }
                column(EntryNo_FALedgEntry; "Entry No.")
                {
                }
                column(Amt_FALedgEntry; Amount)
                {
                }
                column(AmtLCY_FALedgEntry; "Amount (LCY)")
                {
                }
                column(EntryNo_FALedgEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(Description_FALedgEntryCaption; FieldCaption(Description))
                {
                }
                column(DocNo_FALedgEntryCaption; FieldCaption("Document No."))
                {
                }
                column(Amt_FALedgEntryCaption; FieldCaption(Amount))
                {
                }
                column(FALedgerEntryPostingDateCaption; FALedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"FA Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Maintenance Ledger Entry"; "Maintenance Ledger Entry")
            {
                DataItemTableView = sorting("Document No.", "Posting Date");
                column(EntryNo_MaintenanceLedgEntry; "Entry No.")
                {
                }
                column(PostingDate_MaintenanceLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_MaintLedgEntry; "Document No.")
                {
                }
                column(Description_MaintenanceLedgEntry; Description)
                {
                }
                column(Amt_MaintLedgEntry; Amount)
                {
                }
                column(AmtLCY_MaintenanceLedgEntry; "Amount (LCY)")
                {
                }
                column(EntryNo_MaintenanceLedgEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(Description_MaintenanceLedgEntryCaption; FieldCaption(Description))
                {
                }
                column(DocNo_MaintenanceLedgEntryCaption; FieldCaption("Document No."))
                {
                }
                column(Amt_MaintenanceLedgEntryCaption; FieldCaption(Amount))
                {
                }
                column(MaintenanceLedgerEntryPostingDateCaption; MaintenanceLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Maintenance Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Ins. Coverage Ledger Entry"; "Ins. Coverage Ledger Entry")
            {
                DataItemTableView = sorting("Document No.", "Posting Date");
                column(PostingDate_InsCoverageLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_InsCoverageLedgEntry; "Document No.")
                {
                }
                column(Description_InsCoverageLedgEntry; Description)
                {
                }
                column(Amt_InsCoverageLedgEntry; Amount)
                {
                }
                column(EntryNo_InsCoverageLedgEntry; "Entry No.")
                {
                }
                column(InsuranceNo_InsCoverageLedgEntry; "Insurance No.")
                {
                }
                column(EntryNo_InsCoverageLedgEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(Amt_InsCoverageLedgEntryCaption; FieldCaption(Amount))
                {
                }
                column(Description_InsCoverageLedgEntryCaption; FieldCaption(Description))
                {
                }
                column(InsuranceNo_InsCoverageLedgEntryCaption; FieldCaption("Insurance No."))
                {
                }
                column(DocNo_InsCoverageLedgEntryCaption; FieldCaption("Document No."))
                {
                }
                column(InsCoverageLedgerEntryPostingDateCaption; InsCoverageLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Ins. Coverage Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Warehouse Entry"; "Warehouse Entry")
            {
                DataItemTableView = sorting("Reference No.", "Registering Date");
                column(EntryNo_WhseEntry; "Entry No.")
                {
                }
                column(RegisteringDate_WhseEntry; Format("Registering Date"))
                {
                }
                column(ItemNo_WhseEntry; "Item No.")
                {
                }
                column(Description_WhseEntry; Description)
                {
                }
                column(Qty_WhseEntry; Quantity)
                {
                }
                column(ReferenceNo_WhseEntry; "Reference No.")
                {
                }
                column(UOMCode_WhseEntry; "Unit of Measure Code")
                {
                }
                column(EntryNo_WhseEntryCaption; FieldCaption("Entry No."))
                {
                }
                column(Qty_WhseEntryCaption; FieldCaption(Quantity))
                {
                }
                column(Description_WhseEntryCaption; FieldCaption(Description))
                {
                }
                column(ItemNo_WhseEntryCaption; FieldCaption("Item No."))
                {
                }
                column(ReferenceNo_WhseEntryCaption; FieldCaption("Reference No."))
                {
                }
                column(UOMCode_WhseEntryCaption; FieldCaption("Unit of Measure Code"))
                {
                }
                column(WarehouseEntryRegisteringDateCaption; WhseEntryRegisteringDateCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Warehouse Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Reference No.", "Registering Date");
                    SetFilter("Reference No.", DocNoFilter);
                    SetFilter("Registering Date", PostingDateFilter);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not TempDocumentEntry.Find('-') then
                        CurrReport.Break();
                end else
                    if TempDocumentEntry.Next() = 0 then
                        CurrReport.Break();
                CurrencyCaptionRBC := Text003;
            end;

            trigger OnPreDataItem()
            begin
                if not PrintAmountsInLCY then
                    CurrencyCaption := Text003
                else
                    CurrencyCaption := '';
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
                    field(PrintAmountsInLCY; PrintAmountsInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if amounts in the report are displayed in LCY. If you leave the check box blank, amounts are shown in foreign currencies.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        CurrExchRate: Record "Currency Exchange Rate";
        PostedDepositHeader: Record "Posted Deposit Header";
#pragma warning disable AA0074
        Text001: Label 'Document No. : ';
        Text002: Label 'Posting Date : ';
#pragma warning restore AA0074
        PrintAmountsInLCY: Boolean;
#pragma warning disable AA0074
        Text003: Label 'Currency Code';
#pragma warning restore AA0074
        CurrencyCaptionRBC: Text[30];
        NavigateDeposit: Boolean;
        DocEntriesCaptionLbl: Label 'Document Entries';
        PageNoCaptionLbl: Label 'Page';
        NavigateFiltersCaptionLbl: Label 'Navigate Filters';
        DocEntryNoofRecordsCptnLbl: Label 'No. of Records';
        DocEntryTableNameCaptionLbl: Label 'Table Name';
        SalesShptHeaderPostingDtCaptionLbl: Label 'Posting Date';
        SalesInvHeaderPostDateCaptionLbl: Label 'Posting Date';
        ReturnRcptHeaderPostDtCaptionLbl: Label 'Posting Date';
        SalesCrMemoHeaderPostDtCaptionLbl: Label 'Posting Date';
        IssuedReminderHeaderPostDtCaptionLbl: Label 'Posting Date';
        IssuedFinChgMemoHeaderPostDateCaptionLbl: Label 'Posting Date';
        PurchRcptHeaderPostDtCaptionLbl: Label 'Posting Date';
        PurchInvHeaderPostDtCaptionLbl: Label 'Posting Date';
        ReturnShptHeaderPostDtCaptionLbl: Label 'Posting Date';
        PurchCrMemoHdrPostDtCaptionLbl: Label 'Posting Date';
        TransShptHeaderPostDtCaptionLbl: Label 'Posting Date';
        TransRcptHeaderPostDtCaptionLbl: Label 'Posting Date';
        PostedWhseShptLinePostDtCaptionLbl: Label 'Posting Date';
        PostedWhseRcptLinePostDtCaptionLbl: Label 'Posting Date';
        GLEntryPostDtCaptionLbl: Label 'Posting Date';
        VATEntryPostDtCaptionLbl: Label 'Posting Date';
        CustLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        DtldCustLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        ReminderEntryPostDtCaptionLbl: Label 'Posting Date';
        VendLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        DtldVendLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        ItemLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        ValueEntryPostDtCaptionLbl: Label 'Posting Date';
        PhysInvtLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        ResLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        JobLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        BankAccLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        CheckLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        CheckLedgEntryCheckDtCaptionLbl: Label 'Check Date';
        FALedgEntryPostDtCaptionLbl: Label 'Posting Date';
        MaintenanceLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        InsCoverageLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        WhseEntryRegisteringDateCaptionLbl: Label 'Registering Date';
        PostedDepositHeaderPostingDateCaptionLbl: Label 'Posting Date';
        PostedDepositLinePostingDateCaptionLbl: Label 'Posting Date';

    protected var
        TempDocumentEntry: Record "Document Entry" temporary;
        CurrencyCaption: Text[30];
        DocNoFilter: Text;
        PostingDateFilter: Text;

    procedure TransferDocEntries(var NewDocumentEntry: Record "Document Entry")
    var
        TempDocumentEntry2: Record "Document Entry" temporary;
    begin
        TempDocumentEntry2 := NewDocumentEntry;
        NewDocumentEntry.Reset();
        if NewDocumentEntry.Find('-') then
            repeat
                TempDocumentEntry := NewDocumentEntry;
                TempDocumentEntry.Insert();
            until NewDocumentEntry.Next() = 0;
        NewDocumentEntry := TempDocumentEntry2;
    end;

    procedure TransferFilters(NewDocNoFilter: Text; NewPostingDateFilter: Text)
    begin
        DocNoFilter := NewDocNoFilter;
        PostingDateFilter := NewPostingDateFilter;
    end;

    procedure SetExternal()
    begin
        NavigateDeposit := true;
    end;
}

