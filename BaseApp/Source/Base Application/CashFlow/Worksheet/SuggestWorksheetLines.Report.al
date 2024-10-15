﻿namespace Microsoft.CashFlow.Worksheet;

using Microsoft.Bank.Ledger;
using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Document;
using System.AI;
using System.Environment.Configuration;

report 840 "Suggest Worksheet Lines"
{
    Caption = 'Suggest Worksheet Lines';
    Permissions = TableData "Dimension Set ID Filter Line" = rimd,
                  TableData "Cash Flow Forecast Entry" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Cash Flow Forecast"; "Cash Flow Forecast")
        {
            DataItemTableView = sorting("No.") order(Ascending);
            dataitem("Cash Flow Account"; "Cash Flow Account")
            {
                DataItemTableView = sorting("No.") ORDER(Ascending) where("G/L Integration" = filter(Balance | Both), "G/L Account Filter" = filter(<> ''));

                trigger OnAfterGetRecord()
                var
                    GLAcc: Record "G/L Account";
                    TempGLAccount: Record "G/L Account" temporary;
                begin
                    GLAcc.SetFilter("No.", "G/L Account Filter");

                    ClearCircularRefData();
                    GetSubPostingGLAccounts(GLAcc, TempGLAccount);

                    if TempGLAccount.FindSet() then
                        repeat
                            TempGLAccount.CalcFields(Balance);

                            Window.Update(2, Text004);
                            Window.Update(3, TempGLAccount."No.");
                            InsertCFLineForGLAccount(TempGLAccount);
                        until TempGLAccount.Next() = 0;
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::"Liquid Funds".AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();
                end;
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemTableView = sorting(Open, "Due Date") ORDER(Ascending) where(Open = const(true), "Remaining Amount" = filter(<> 0));

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, Text005);
                    Window.Update(3, "Entry No.");

                    if "Customer No." <> '' then
                        Customer.Get("Customer No.")
                    else
                        Customer.Init();

                    CalcFields("Remaining Amt. (LCY)", "Remaining Amount");

                    InsertCFLineForCustLedgerEntry();
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();
                end;
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemTableView = sorting(Open, "Due Date") ORDER(Ascending) where(Open = const(true), "Remaining Amount" = filter(<> 0));

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, Text006);
                    Window.Update(3, "Entry No.");

                    if "Vendor No." <> '' then
                        Vendor.Get("Vendor No.")
                    else
                        Vendor.Init();

                    CalcFields("Remaining Amt. (LCY)", "Remaining Amount");

                    InsertCFLineForVendorLedgEntry();
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();
                end;
            }
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") ORDER(Ascending) where("Document Type" = const(Order));

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, Text007);
                    Window.Update(3, "Document No.");

                    PurchHeader.Get("Document Type", "Document No.");
                    if PurchHeader."Buy-from Vendor No." <> '' then
                        Vendor.Get(PurchHeader."Pay-to Vendor No.")
                    else
                        Vendor.Init();

                    InsertCFLineForPurchaseLine();
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();

                    if not ApplicationAreaMgmtFacade.IsSuiteEnabled() and not ApplicationAreaMgmtFacade.IsAllDisabled() then
                        CurrReport.Break();
                end;
            }
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") ORDER(Ascending) where("Document Type" = const(Order));

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, Text008);
                    Window.Update(3, "Document No.");

                    SalesHeader.Get("Document Type", "Document No.");
                    if SalesHeader."Sell-to Customer No." <> '' then
                        Customer.Get(SalesHeader."Bill-to Customer No.")
                    else
                        Customer.Init();

                    InsertCFLineForSalesLine();
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();
                end;
            }
            dataitem(InvestmentFixedAsset; "Fixed Asset")
            {
                DataItemTableView = sorting("No.") where("Budgeted Asset" = const(true));

                trigger OnAfterGetRecord()
                begin
                    if FADeprBook.Get("No.", FASetup."Default Depr. Book") then begin
                        FADeprBook.CalcFields("Acquisition Cost");

                        Window.Update(2, Text009);
                        Window.Update(3, "No.");

                        InsertCFLineForFixedAssetsBudget();
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::"Fixed Assets Budget".AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();

                    FASetup.Get();
                end;
            }
            dataitem(SaleFixedAsset; "Fixed Asset")
            {
                DataItemTableView = sorting("No.") where("Budgeted Asset" = const(false));

                trigger OnAfterGetRecord()
                begin
                    if FADeprBook.Get("No.", FASetup."Default Depr. Book") then
                        if (FADeprBook."Disposal Date" = 0D) and
                           (FADeprBook."Projected Disposal Date" <> 0D) and
                           (FADeprBook."Projected Proceeds on Disposal" <> 0)
                        then begin
                            Window.Update(2, Text010);
                            Window.Update(3, "No.");

                            InsertCFLineForFixedAssetsDisposal();
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::"Fixed Assets Disposal".AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();

                    FASetup.Get();
                end;
            }
            dataitem("Cash Flow Manual Expense"; "Cash Flow Manual Expense")
            {
                DataItemTableView = sorting(Code) order(Ascending);

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, Text011);
                    Window.Update(3, Code);

                    InsertCFLineForManualExpense();
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Expense".AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();
                end;
            }
            dataitem("Cash Flow Manual Revenue"; "Cash Flow Manual Revenue")
            {
                DataItemTableView = sorting(Code) order(Ascending);

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, Text012);
                    Window.Update(3, Code);

                    InsertCFLineForManualRevenue();
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Revenue".AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();
                end;
            }
            dataitem(CFAccountForBudget; "Cash Flow Account")
            {
                DataItemTableView = sorting("No.") ORDER(Ascending) where("G/L Integration" = filter(Budget | Both), "G/L Account Filter" = filter(<> ''));

                trigger OnAfterGetRecord()
                var
                    GLAcc: Record "G/L Account";
                begin
                    GLAcc.SetFilter("No.", "G/L Account Filter");
                    if GLAcc.FindSet() then
                        repeat
                            Window.Update(2, Text031);
                            Window.Update(3, GLAcc."No.");

                            GLBudgEntry.SetRange("Budget Name", GLBudgName);
                            GLBudgEntry.SetRange("G/L Account No.", GLAcc."No.");
                            GLBudgEntry.SetRange(Date, "Cash Flow Forecast"."G/L Budget From", "Cash Flow Forecast"."G/L Budget To");
                            OnCFAccountForBudgetOnAfterGetRecordOnAfterGLBudgEntrySetFilters(GLBudgEntry);
                            if GLBudgEntry.FindSet() then
                                repeat
                                    InsertCFLineForGLBudget(GLAcc);
                                until GLBudgEntry.Next() = 0;
                        until GLAcc.Next() = 0;
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::"G/L Budget".AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();
                end;
            }
            dataitem("Service Line"; "Service Line")
            {
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where("Document Type" = const(Order));

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, Text032);
                    Window.Update(3, "Document No.");

                    ServiceHeader.Get("Document Type", "Document No.");
                    if ServiceHeader."Bill-to Customer No." <> '' then
                        Customer.Get(ServiceHeader."Bill-to Customer No.")
                    else
                        Customer.Init();

                    InsertCFLineForServiceLine();
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();
                end;
            }
            dataitem("Job Planning Line"; "Job Planning Line")
            {
                DataItemTableView = sorting("Job No.", "Planning Date", "Document No.");

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, JobsMsg);
                    Window.Update(3, "Job No.");

                    if not ("Line Type" in ["Line Type"::Billable, "Line Type"::"Both Budget and Billable"]) then
                        exit;

                    OnJobPlanningLineOnAfterGetRecordOnBeforeInsertCFLineForJobPlanningLine("Job Planning Line");
                    InsertCFLineForJobPlanningLine();
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::Job.AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();

                    if not ApplicationAreaMgmtFacade.IsJobsEnabled() and not ApplicationAreaMgmtFacade.IsAllDisabled() then
                        CurrReport.Break();
                end;
            }
            dataitem("Purchase Header"; "Purchase Header")
            {
                DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));

                trigger OnAfterGetRecord()
                var
                    PurchaseOrder: Page "Purchase Order";
                begin
                    Window.Update(2, PurchaseOrder.Caption);
                    Window.Update(3, "No.");

                    InsertCFLineForTax(DATABASE::"Purchase Header");
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::Tax.AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();

                    if not ApplicationAreaMgmtFacade.IsSuiteEnabled() and not ApplicationAreaMgmtFacade.IsAllDisabled() then
                        CurrReport.Break();

                    CashFlowManagement.SetViewOnPurchaseHeaderForTaxCalc("Purchase Header", DummyDate);
                end;
            }
            dataitem("Sales Header"; "Sales Header")
            {
                DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));

                trigger OnAfterGetRecord()
                var
                    SalesOrder: Page "Sales Order";
                begin
                    Window.Update(2, SalesOrder.Caption);
                    Window.Update(3, "No.");

                    InsertCFLineForTax(DATABASE::"Sales Header");
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::Tax.AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();

                    CashFlowManagement.SetViewOnSalesHeaderForTaxCalc("Sales Header", DummyDate);
                end;
            }
            dataitem("VAT Entry"; "VAT Entry")
            {

                trigger OnAfterGetRecord()
                var
                    VATEntries: Page "VAT Entries";
                begin
                    Window.Update(2, VATEntries.Caption);
                    Window.Update(3, "Entry No.");

                    InsertCFLineForTax(DATABASE::"VAT Entry");
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::Tax.AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();

                    CashFlowManagement.SetViewOnVATEntryForTaxCalc("VAT Entry", DummyDate);
                end;
            }
            dataitem("Cash Flow Azure AI Buffer"; "Cash Flow Azure AI Buffer")
            {

                trigger OnAfterGetRecord()
                begin
                    InsertCFLineForAzureAIForecast(DATABASE::"Cash Flow Azure AI Buffer");
                end;

                trigger OnPreDataItem()
                var
                    CashFlowForecastHandler: Codeunit "Cash Flow Forecast Handler";
                begin
                    if not ConsiderSource["Cash Flow Source Type"::"Azure AI".AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();

                    if not CashFlowForecastHandler.CalculateForecast() then
                        CurrReport.Break();

                    SetRange(Type, Type::Forecast, Type::Correction);
                    if FindSet() then;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
            end;

            trigger OnPostDataItem()
            var
                TempCashFlowForecast: Record "Cash Flow Forecast" temporary;
            begin
                InsertWorksheetLines(TempCashFlowForecast);
                DeleteEntries(TempCashFlowForecast);
                if NeedsManualPmtUpdate then
                    Message(ManualPmtRevExpNeedsUpdateMsg, TempCashFlowForecast."No.");
            end;

            trigger OnPreDataItem()
            begin
                SetRange("No.", CashFlowNo);
                LineNo := 0;
                NeedsManualPmtUpdate := false;
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
                    field(CashFlowNo; CashFlowNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Forecast';
                        TableRelation = "Cash Flow Forecast";
                        ToolTip = 'Specifies the cash flow forecast for which you want to make the calculation.';
                    }
                    group("Source Types to Include:")
                    {
                        Caption = 'Source Types to Include:';
                        field("ConsiderSource[SourceType::""Liquid Funds""]"; ConsiderSource["Cash Flow Source Type"::"Liquid Funds".AsInteger()])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Liquid Funds';
                            ToolTip = 'Specifies if you want to transfer the balances of the general ledger accounts that are defined as liquid funds.';
                        }
                        field("ConsiderSource[SourceType::Receivables]"; ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Receivables';
                            ToolTip = 'Specifies if you want to include open customer ledger entries in the cash flow forecast.';
                        }
                        field("ConsiderSource[SourceType::""Sales Order""]"; ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Sales Orders';
                            ToolTip = 'Specifies if you want to include sales orders in the cash flow forecast.';
                        }
                        field("ConsiderSource[SourceType::""Service Orders""]"; ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()])
                        {
                            ApplicationArea = Service;
                            Caption = 'Service Orders';
                            ToolTip = 'Specifies if you want to include service orders in the cash flow forecast.';
                        }
                        field("ConsiderSource[SourceType::""Sale of Fixed Asset""]"; ConsiderSource["Cash Flow Source Type"::"Fixed Assets Disposal".AsInteger()])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Fixed Assets Disposal';
                            ToolTip = 'Specifies if planned sales of fixed assets as revenues are included in the cash flow forecast.';
                        }
                        field("ConsiderSource[SourceType::""Cash Flow Manual Revenue""]"; ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Revenue".AsInteger()])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Cash Flow Manual Revenues';
                            ToolTip = 'Specifies if manual revenues in the cash flow forecast are included.';
                        }
                        field("ConsiderSource[SourceType::Payables]"; ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Payables';
                            ToolTip = 'Specifies if you want to include open vendor ledger entries in the cash flow forecast.';
                        }
                        field("ConsiderSource[SourceType::""Purchase Order""]"; ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()])
                        {
                            ApplicationArea = Suite;
                            Caption = 'Purchase Orders';
                            ToolTip = 'Specifies if you want to include purchase orders in the cash flow forecast.';
                        }
                        field("ConsiderSource[SourceType::""Budgeted Fixed Asset""]"; ConsiderSource["Cash Flow Source Type"::"Fixed Assets Budget".AsInteger()])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Fixed Assets Budget';
                            ToolTip = 'Specifies if planned investments of fixed assets are included in the cash flow forecast.';
                        }
                        field("ConsiderSource[SourceType::""Cash Flow Manual Expense""]"; ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Expense".AsInteger()])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Cash Flow Manual Expenses';
                            ToolTip = 'Specifies if manual expenses in the cash flow forecast are included.';
                        }
                        field("ConsiderSource[SourceType::""G/L Budget""]"; ConsiderSource["Cash Flow Source Type"::"G/L Budget".AsInteger()])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'G/L Budget';
                            ToolTip = 'Specifies if the budget entries of the marked general ledger accounts in the cash flow forecast are included.';
                        }
                        field(GLBudgName; GLBudgName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'G/L Budget Name';
                            TableRelation = "G/L Budget Name";
                            ToolTip = 'Specifies the name of the general ledger budget if you have selected G/L budget.';
                        }
                        field("ConsiderSource[SourceType::Job]"; ConsiderSource["Cash Flow Source Type"::Job.AsInteger()])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Jobs';
                            ToolTip = 'Specifies if you want to include jobs in the cash flow forecast.';
                        }
                        field("ConsiderSource[SourceType::Tax]"; ConsiderSource["Cash Flow Source Type"::Tax.AsInteger()])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Taxes';
                            ToolTip = 'Specifies if you want to include tax information in the cash flow forecast.';
                        }
                        field("ConsiderSource[SourceType::""Azure AI""]"; ConsiderSource["Cash Flow Source Type"::"Azure AI".AsInteger()])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Azure AI Forecast';
                            ToolTip = 'Specifies whether to include Azure AI in the cash flow forecast.';
                        }
                    }
                    field(Summarized; Summarized)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Group by Document Type';
                        ToolTip = 'Specifies if the information is grouped by sales orders, purchase orders, and service orders.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        var
            CFManualExpense: Record "Cash Flow Manual Expense";
            CFManualRevenue: Record "Cash Flow Manual Revenue";
            GLBudgetEntry: Record "G/L Budget Entry";
            GLAcc: Record "G/L Account";
        begin
            if ConsiderSource["Cash Flow Source Type"::"Liquid Funds".AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::"Liquid Funds".AsInteger()] := GLAcc.ReadPermission;
            if ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] := "Cust. Ledger Entry".ReadPermission;
            if ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()] := "Vendor Ledger Entry".ReadPermission;
            if ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] := "Purchase Line".ReadPermission;
            if ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := "Sales Line".ReadPermission;
            if ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Expense".AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Expense".AsInteger()] := CFManualExpense.ReadPermission;
            if ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Revenue".AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Revenue".AsInteger()] := CFManualRevenue.ReadPermission;
            if ConsiderSource["Cash Flow Source Type"::"Fixed Assets Budget".AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::"Fixed Assets Budget".AsInteger()] := InvestmentFixedAsset.ReadPermission;
            if ConsiderSource["Cash Flow Source Type"::"Fixed Assets Disposal".AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::"Fixed Assets Disposal".AsInteger()] := SaleFixedAsset.ReadPermission;
            if ConsiderSource["Cash Flow Source Type"::"G/L Budget".AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::"G/L Budget".AsInteger()] := GLBudgetEntry.ReadPermission;
            if ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] := "Service Line".ReadPermission;
            if ConsiderSource["Cash Flow Source Type"::Job.AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::Job.AsInteger()] := "Job Planning Line".ReadPermission;
            if ConsiderSource["Cash Flow Source Type"::Tax.AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::Tax.AsInteger()] := "Sales Header".ReadPermission and
                  "Purchase Header".ReadPermission and "VAT Entry".ReadPermission;
            if ConsiderSource["Cash Flow Source Type"::"Azure AI".AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::"Azure AI".AsInteger()] := "Cash Flow Azure AI Buffer".ReadPermission;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if CashFlowNo = '' then
            Error(Text000);

        if not SelectionCashFlowForecast.Get(CashFlowNo) then
            Error(Text001);

        if NoOptionsChosen() then
            Error(Text002, CashFlowNo);

        CFSetup.Get();
        GLSetup.Get();

        Window.Open(
          Text003 +
          Text033 +
          Text034);

        Window.Update(1, "Cash Flow Forecast"."No.");
    end;

    var
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
        GLBudgEntry: Record "G/L Budget Entry";
        GLSetup: Record "General Ledger Setup";
        FALedgerEntry: Record "FA Ledger Entry";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        CashFlowManagement: Codeunit "Cash Flow Management";
        TotalAccounts: List of [Code[20]];
        TotalAccountPairs: List of [Code[50]];
        LastTotalAccount: Code[20];
        CashFlowNo: Code[20];
        LineNo: Integer;
        DateLastExecution: Date;
        ExecutionDate: Date;
        GLBudgName: Code[10];
        MultiSalesLines: Boolean;
        Summarized: Boolean;
        NeedsManualPmtUpdate: Boolean;
        DummyDate: Date;
        TaxLastSourceTableNumProcessed: Integer;
        TaxLastPayableDateProcessed: Date;

        Text000: Label 'You must choose a cash flow forecast.';
        Text001: Label 'Choose a valid cash flow forecast.';
        Text002: Label 'Choose one option for filling the cash flow forecast no. %1.';
        Text003: Label 'Cash Flow Forecast No.      #1##########\\';
        Text004: Label 'Liquid Funds';
        Text005: Label 'Receivables';
        Text006: Label 'Payables';
        Text007: Label 'Purchase Orders';
        Text008: Label 'Sales Orders';
        Text009: Label 'Fixed Assets Budget';
        Text010: Label 'Fixed Assets Disposal';
        Text011: Label 'Cash Flow Manual Expenses';
        Text012: Label 'Cash Flow Manual Revenues';
        Text013: Label '%1 Balance=%2';
        Text025: Label '%1 %2 %3';
        Text027: Label '%1 AC= %2';
        Text028: Label 'Cash Flow Manual Expenses %1';
        Text029: Label 'Cash Flow Manual Revenues %1';
        Text030: Label '%1 Budget %2 ';
        Text031: Label 'G/L Budget';
        Text032: Label 'Service Orders';
        Text033: Label 'Search for          #2####################\';
        Text034: Label 'Record found        #3####################';
        ManualPmtRevExpNeedsUpdateMsg: Label 'There are one or more Cash Flow Manual Revenues/Expenses with a Recurring Frequency.\But the Recurring Frequency cannot be applied because the Manual Payments To date in Cash Flow Forecast %1 is empty.\Fill in this date in order to get multiple lines.';
        JobsMsg: Label 'Jobs';
        PostedSalesDocumentDescriptionTxt: Label 'Posted Sales %1 - %2 %3', Comment = '%1 = Source Document Type (e.g. Invoice), %2 = Due Date, %3 = Source Name (e.g. Customer Name). Example: Posted Sales Invoice - 04-05-18 The Cannon Group PLC';
        PostedPurchaseDocumentDescriptionTxt: Label 'Posted Purchase %1 - %2 %3', Comment = '%1 = Source Document Type (e.g. Invoice), %2 = Due Date, %3 = Source Name (e.g. Vendor Name). Example: Posted Purchase Invoice - 04-05-18 The Cannon Group PLC';
        SalesDocumentDescriptionTxt: Label 'Sales %1 - %2 %3', Comment = '%1 = Source Document Type (e.g. Invoice), %2 = Due Date, %3 = Source Name (e.g. Customer Name). Example: Sales Invoice - 04-05-18 The Cannon Group PLC';
        PurchaseDocumentDescriptionTxt: Label 'Purchase %1 - %2 %3', Comment = '%1 = Source Document Type (e.g. Invoice), %2 = Due Date, %3 = Source Name (e.g. Vendor Name). Example: Purchase Invoice - 04-05-18 The Cannon Group PLC';
        ServiceDocumentDescriptionTxt: Label 'Service %1 - %2 %3', Comment = '%1 = Source Document Type (e.g. Invoice), %2 = Due Date, %3 = Source Name (e.g. Customer Name). Example: Service Invoice - 04-05-18 The Cannon Group PLC';
        TaxForMsg: Label 'Taxes from %1', Comment = '%1 = The description of the source tyoe based on which taxes are calculated.';
        AzureAIForecastDescriptionTxt: Label 'Predicted %1 in the period starting on %2 with precision of +/-  %3.', Comment = '%1 =RECEIVABLES or PAYABLES or PAYABLES TAX or RECEIVABLES TAX, %2 = Date; %3 Percentage';
        AzureAIForecastTaxDescriptionTxt: Label 'Predicted tax on %1 in the period starting on %2 with precision of +/-  %3.', Comment = '%1 =RECEIVABLES or PAYABLES, %2 = Date; %3 Percentage';
        AzureAICorrectionDescriptionTxt: Label 'Correction due to posted %1', Comment = '%1 = SALES ORDERS or PURCHASE ORDERS';
        AzureAICorrectionTaxDescriptionTxt: Label 'Correction of tax amount due to posted %1', Comment = '%1 = RECEIVABLES or PAYABLES';
        AzureAIOrdersCorrectionDescriptionTxt: Label 'Correction due to %1', Comment = '%1 = SALES or PURCHASE';
        AzureAIOrdersTaxCorrectionDescriptionTxt: Label 'Correction of tax amount due to %1', Comment = '%1 = SALES ORDERS or PURCHASE ORDERS';
        XRECEIVABLESTxt: Label 'RECEIVABLES', Locked = true;
        XPAYABLESTxt: Label 'PAYABLES', Locked = true;
        XPAYABLESCORRECTIONTxt: Label 'Payables Correction';
        XRECEIVABLESCORRECTIONTxt: Label 'Receivables Correction';
        XSALESORDERSTxt: Label 'Sales Orders';
        XPURCHORDERSTxt: Label 'Purchase Orders';
        XTAXPAYABLESTxt: Label 'TAX TO RETURN', Locked = true;
        XTAXRECEIVABLESTxt: Label 'TAX TO PAY', Locked = true;
        XTAXPAYABLESCORRECTIONTxt: Label 'Tax from Purchase entries';
        XTAXRECEIVABLESCORRECTIONTxt: Label 'Tax from Sales entries';
        XTAXSALESORDERSTxt: Label 'Tax from Sales Orders';
        XTAXPURCHORDERSTxt: Label 'Tax from Purchase Orders';
        CircularRefsErr: Label 'There are one or more circular references where the following G/L accounts reference to each other either directly or indirectly:\ %1.\Change the value of the Totaling field in one of these accounts.', Comment = '%1 - list of accounts.';
        ThreePlaceHoldersLbl: Label '%1%2%3', Locked = true, Comment = '%1%2%3 are placeholders';

    protected var
        CFSetup: Record "Cash Flow Setup";
        SelectionCashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine2: Record "Cash Flow Worksheet Line";
        TempCFWorksheetLine: Record "Cash Flow Worksheet Line" temporary;
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        Customer: Record Customer;
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
        Window: Dialog;
        ConsiderSource: array[16] of Boolean;
        TotalAmt: Decimal;

    local procedure InsertConditionMet(): Boolean
    begin
        exit(TempCFWorksheetLine."Amount (LCY)" <> 0);
    end;

    procedure InsertTempCFWorksheetLine(CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; MaxPmtTolerance: Decimal)
    var
        IsHandled: Boolean;
    begin
        with TempCFWorksheetLine do begin
            LineNo := LineNo + 100;
            TransferFields(CashFlowWorksheetLine);
            "Cash Flow Forecast No." := "Cash Flow Forecast"."No.";
            "Line No." := LineNo;

            IsHandled := false;
            OnInsertTempCFWorksheetLineOnBeforeCalculateCFAmountAndCFDate(TempCFWorksheetLine, IsHandled);
            if not IsHandled then
                CalculateCFAmountAndCFDate(MaxPmtTolerance);
            SetCashFlowDate(TempCFWorksheetLine, "Cash Flow Date");

            if Abs("Amount (LCY)") < Abs(MaxPmtTolerance) then
                "Amount (LCY)" := 0
            else
                "Amount (LCY)" := "Amount (LCY)" - MaxPmtTolerance;

            if InsertConditionMet() then
                if not Insert() then
                    Modify();
        end;
    end;

    local procedure InsertWorksheetLines(var TempCashFlowForecast: Record "Cash Flow Forecast" temporary)
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        LastCFForecastNo: Code[20];
    begin
        CFWorksheetLine.LockTable();

        CFWorksheetLine.Reset();
        CFWorksheetLine.DeleteAll();

        LastCFForecastNo := '';
        TempCFWorksheetLine.Reset();
        TempCFWorksheetLine.SetCurrentKey("Cash Flow Forecast No.");
        if TempCFWorksheetLine.FindSet() then
            repeat
                CFWorksheetLine := TempCFWorksheetLine;
                CFWorksheetLine.Insert(true);

                if LastCFForecastNo <> CFWorksheetLine."Cash Flow Forecast No." then begin
                    TempCashFlowForecast."No." := CFWorksheetLine."Cash Flow Forecast No.";
                    TempCashFlowForecast.Insert();
                    LastCFForecastNo := CFWorksheetLine."Cash Flow Forecast No.";
                end;
            until TempCFWorksheetLine.Next() = 0;

        TempCFWorksheetLine.DeleteAll();
    end;

    local procedure DeleteEntries(var TempCashFlowForecast: Record "Cash Flow Forecast" temporary)
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        TempCashFlowForecast.Reset();
        if TempCashFlowForecast.FindSet() then begin
            CFForecastEntry.LockTable();
            CFForecastEntry.Reset();
            repeat
                CFForecastEntry.SetRange("Cash Flow Forecast No.", TempCashFlowForecast."No.");
                CFForecastEntry.DeleteAll();
            until TempCashFlowForecast.Next() = 0;
        end;
        TempCashFlowForecast.DeleteAll();
    end;

    local procedure InsertCFLineForGLAccount(GLAcc: Record "G/L Account")
    begin
        with CFWorksheetLine2 do begin
            Init();
            "Source Type" := "Source Type"::"Liquid Funds";
            "Source No." := GLAcc."No.";
            "Document No." := GLAcc."No.";
            "Cash Flow Account No." := "Cash Flow Account"."No.";
            Description :=
              CopyStr(
                StrSubstNo(Text013, GLAcc.Name, Format(GLAcc.Balance)),
                1, MaxStrLen(Description));
            SetCashFlowDate(CFWorksheetLine2, WorkDate());
            "Amount (LCY)" := GLAcc.Balance;
            "Shortcut Dimension 2 Code" := GLAcc."Global Dimension 2 Code";
            "Shortcut Dimension 1 Code" := GLAcc."Global Dimension 1 Code";
            MoveDefualtDimToJnlLineDim(DATABASE::"G/L Account", GLAcc."No.", "Dimension Set ID");
            InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
        end;
    end;

    local procedure InsertCFLineForCustLedgerEntry()
    var
        MaxPmtTolerance: Decimal;
    begin
        with CFWorksheetLine2 do begin
            Init();
            "Source Type" := "Source Type"::Receivables;
            "Source No." := "Cust. Ledger Entry"."Document No.";
            "Document Type" := "Cust. Ledger Entry"."Document Type";
            "Document Date" := "Cust. Ledger Entry"."Document Date";
            "Shortcut Dimension 2 Code" := "Cust. Ledger Entry"."Global Dimension 2 Code";
            "Shortcut Dimension 1 Code" := "Cust. Ledger Entry"."Global Dimension 1 Code";
            "Dimension Set ID" := "Cust. Ledger Entry"."Dimension Set ID";
            "Cash Flow Account No." := CFSetup."Receivables CF Account No.";
            Description := CopyStr(
                StrSubstNo(PostedSalesDocumentDescriptionTxt,
                  Format("Document Type"),
                  Format("Cust. Ledger Entry"."Due Date"),
                  Customer.Name),
                1, MaxStrLen(Description));
            "Document No." := "Cust. Ledger Entry"."Document No.";
            SetCashFlowDate(CFWorksheetLine2, "Cust. Ledger Entry"."Due Date");
            "Amount (LCY)" := "Cust. Ledger Entry"."Remaining Amt. (LCY)";
            "Pmt. Discount Date" := "Cust. Ledger Entry"."Pmt. Discount Date";
            "Pmt. Disc. Tolerance Date" := "Cust. Ledger Entry"."Pmt. Disc. Tolerance Date";

            if "Cust. Ledger Entry"."Currency Code" <> '' then
                Currency.Get("Cust. Ledger Entry"."Currency Code")
            else
                Currency.InitRoundingPrecision();

            "Payment Discount" := Round("Cust. Ledger Entry"."Remaining Pmt. Disc. Possible" /
                "Cust. Ledger Entry"."Adjusted Currency Factor", Currency."Amount Rounding Precision");

            if "Cash Flow Forecast"."Consider Pmt. Tol. Amount" then
                MaxPmtTolerance := Round("Cust. Ledger Entry"."Max. Payment Tolerance" /
                    "Cust. Ledger Entry"."Adjusted Currency Factor", Currency."Amount Rounding Precision")
            else
                MaxPmtTolerance := 0;

            "Payment Terms Code" := '';

            OnInsertCFLineForCustLedgerEntryOnBeforeInsertTempCFWorksheetLine(CFWorksheetLine2, "Cash Flow Forecast", "Cust. Ledger Entry");
            InsertTempCFWorksheetLine(CFWorksheetLine2, MaxPmtTolerance);
        end;
    end;

    local procedure InsertCFLineForVendorLedgEntry()
    var
        MaxPmtTolerance: Decimal;
    begin
        with CFWorksheetLine2 do begin
            Init();
            "Source Type" := "Source Type"::Payables;
            "Source No." := "Vendor Ledger Entry"."Document No.";
            "Document Type" := "Vendor Ledger Entry"."Document Type";
            "Document Date" := "Vendor Ledger Entry"."Document Date";
            "Shortcut Dimension 2 Code" := "Vendor Ledger Entry"."Global Dimension 2 Code";
            "Shortcut Dimension 1 Code" := "Vendor Ledger Entry"."Global Dimension 1 Code";
            "Dimension Set ID" := "Vendor Ledger Entry"."Dimension Set ID";
            "Cash Flow Account No." := CFSetup."Payables CF Account No.";
            Description := CopyStr(
                StrSubstNo(PostedPurchaseDocumentDescriptionTxt,
                  Format("Document Type"),
                  Format("Vendor Ledger Entry"."Due Date"),
                  Vendor.Name),
                1, MaxStrLen(Description));
            SetCashFlowDate(CFWorksheetLine2, "Vendor Ledger Entry"."Due Date");
            "Document No." := "Vendor Ledger Entry"."Document No.";
            "Amount (LCY)" := "Vendor Ledger Entry"."Remaining Amt. (LCY)";
            "Pmt. Discount Date" := "Vendor Ledger Entry"."Pmt. Discount Date";
            "Pmt. Disc. Tolerance Date" := "Vendor Ledger Entry"."Pmt. Disc. Tolerance Date";

            if "Vendor Ledger Entry"."Currency Code" <> '' then
                Currency.Get("Vendor Ledger Entry"."Currency Code")
            else
                Currency.InitRoundingPrecision();

            "Payment Discount" := Round("Vendor Ledger Entry"."Remaining Pmt. Disc. Possible" /
                "Vendor Ledger Entry"."Adjusted Currency Factor", Currency."Amount Rounding Precision");

            if "Cash Flow Forecast"."Consider Pmt. Tol. Amount" then
                MaxPmtTolerance := Round("Vendor Ledger Entry"."Max. Payment Tolerance" /
                    "Vendor Ledger Entry"."Adjusted Currency Factor", Currency."Amount Rounding Precision")
            else
                MaxPmtTolerance := 0;

            "Payment Terms Code" := '';

            InsertTempCFWorksheetLine(CFWorksheetLine2, MaxPmtTolerance);
        end;
    end;

    local procedure InsertCFLineForPurchaseLine()
    var
        PurchLine2: Record "Purchase Line";
    begin
        PurchLine2 := "Purchase Line";
        if Summarized and (PurchLine2.Next() <> 0) and (PurchLine2."Buy-from Vendor No." <> '') and
           (PurchLine2."Document No." = "Purchase Line"."Document No.")
        then begin
            TotalAmt += CalculateLineAmountForPurchaseLine(PurchHeader, "Purchase Line");
            MultiSalesLines := true;
        end else
            with CFWorksheetLine2 do begin
                Init();
                "Source Type" := "Source Type"::"Purchase Orders";
                "Source No." := "Purchase Line"."Document No.";
                "Source Line No." := "Purchase Line"."Line No.";
                "Document Type" := "Document Type"::Invoice;
                "Document Date" := PurchHeader."Document Date";
                "Shortcut Dimension 1 Code" := PurchHeader."Shortcut Dimension 1 Code";
                "Shortcut Dimension 2 Code" := PurchHeader."Shortcut Dimension 2 Code";
                "Dimension Set ID" := PurchHeader."Dimension Set ID";
                "Cash Flow Account No." := CFSetup."Purch. Order CF Account No.";
                Description :=
                  CopyStr(
                    StrSubstNo(
                      PurchaseDocumentDescriptionTxt,
                      PurchHeader."Document Type",
                      Format(PurchHeader."Order Date"),
                      PurchHeader."Buy-from Vendor Name"),
                    1, MaxStrLen(Description));
                SetCashFlowDate(CFWorksheetLine2, PurchHeader."Due Date");
                "Document No." := "Purchase Line"."Document No.";
                "Amount (LCY)" := CalculateLineAmountForPurchaseLine(PurchHeader, "Purchase Line");

                if Summarized and MultiSalesLines then begin
                    "Amount (LCY)" := "Amount (LCY)" + TotalAmt;
                    MultiSalesLines := false;
                    TotalAmt := 0;
                end;

                "Payment Terms Code" := PurchHeader."Payment Terms Code";

                OnInsertCFLineForPurchaseLineOnBeforeInsertTempCFWorksheetLine(CFWorksheetLine2, PurchHeader, "Purchase Line");
                InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
            end;
    end;

    local procedure InsertCFLineForSalesLine()
    var
        SalesLine2: Record "Sales Line";
    begin
        SalesLine2 := "Sales Line";
        if Summarized and (SalesLine2.Next() <> 0) and (SalesLine2."Sell-to Customer No." <> '') and
           (SalesLine2."Document No." = "Sales Line"."Document No.")
        then begin
            TotalAmt += CalculateLineAmountForSalesLine(SalesHeader, "Sales Line");
            MultiSalesLines := true;
        end else
            with CFWorksheetLine2 do begin
                Init();
                "Document Type" := "Document Type"::Invoice;
                "Document Date" := SalesHeader."Document Date";
                "Source Type" := "Source Type"::"Sales Orders";
                "Source No." := "Sales Line"."Document No.";
                "Source Line No." := "Sales Line"."Line No.";
                "Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
                "Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
                "Dimension Set ID" := SalesHeader."Dimension Set ID";
                "Cash Flow Account No." := CFSetup."Sales Order CF Account No.";
                Description :=
                  CopyStr(
                    StrSubstNo(
                      SalesDocumentDescriptionTxt,
                      SalesHeader."Document Type",
                      Format(SalesHeader."Order Date"),
                      SalesHeader."Sell-to Customer Name"),
                    1, MaxStrLen(Description));
                SetCashFlowDate(CFWorksheetLine2, SalesHeader."Due Date");
                "Document No." := "Sales Line"."Document No.";
                if SalesHeader."Prepayment %" = 100 then
                    "Amount (LCY)" := GetSalesOrderPrepaymentAmt("Sales Line")
                else
                    "Amount (LCY)" := CalculateLineAmountForSalesLine(SalesHeader, "Sales Line");

                if Summarized and MultiSalesLines then begin
                    "Amount (LCY)" := "Amount (LCY)" + TotalAmt;
                    MultiSalesLines := false;
                    TotalAmt := 0;
                end;

                "Payment Terms Code" := SalesHeader."Payment Terms Code";

                InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
            end;
    end;

    local procedure InsertCFLineForFixedAssetsBudget()
    begin
        SetFALedgerEntryFilters();
        if FALedgerEntry.FindSet() then
            repeat
                InitCFLineForFixedAssetsBudget();
                CFWorksheetLine2.MoveDefualtDimToJnlLineDim(DATABASE::"Fixed Asset", InvestmentFixedAsset."No.", CFWorksheetLine2."Dimension Set ID");
                InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
            until FALedgerEntry.Next() = 0;
    end;

    local procedure SetFALedgerEntryFilters()
    begin
        FALedgerEntry.Reset();
        FALedgerEntry.SetRange("FA No.", FADeprBook."FA No.");
        FALedgerEntry.SetRange("Depreciation Book Code", FADeprBook."Depreciation Book Code");
        FALedgerEntry.SetRange("FA Posting Category", FALedgerEntry."FA Posting Category"::" ");
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
    end;

    local procedure InitCFLineForFixedAssetsBudget()
    begin
        with CFWorksheetLine2 do begin
            Init();
            "Source Type" := "Source Type"::"Fixed Assets Budget";
            "Source No." := InvestmentFixedAsset."No.";
            "Document No." := InvestmentFixedAsset."No.";
            "Cash Flow Account No." := CFSetup."FA Budget CF Account No.";
            Description :=
              CopyStr(
                StrSubstNo(
                  Text027, InvestmentFixedAsset."No.", Format(-FALedgerEntry.Amount)),
                1, MaxStrLen(Description));
            SetCashFlowDate(CFWorksheetLine2, FALedgerEntry."Posting Date");
            "Amount (LCY)" := -FALedgerEntry.Amount;
            "Shortcut Dimension 2 Code" := InvestmentFixedAsset."Global Dimension 2 Code";
            "Shortcut Dimension 1 Code" := InvestmentFixedAsset."Global Dimension 1 Code";
        end;
        OnAfterInitCFLineForFixedAssetsBudget(CFWorksheetLine2, FADeprBook, InvestmentFixedAsset);
    end;

    local procedure InsertCFLineForFixedAssetsDisposal()
    begin
        with CFWorksheetLine2 do begin
            Init();
            "Source Type" := "Source Type"::"Fixed Assets Disposal";
            "Source No." := SaleFixedAsset."No.";
            "Document No." := SaleFixedAsset."No.";
            "Cash Flow Account No." := CFSetup."FA Disposal CF Account No.";
            Description :=
              CopyStr(
                StrSubstNo(
                  Text027, SaleFixedAsset."No.", Format(FADeprBook."Projected Proceeds on Disposal")),
                1, MaxStrLen(Description));
            SetCashFlowDate(CFWorksheetLine2, FADeprBook."Projected Disposal Date");
            "Amount (LCY)" := FADeprBook."Projected Proceeds on Disposal";
            "Shortcut Dimension 2 Code" := SaleFixedAsset."Global Dimension 2 Code";
            "Shortcut Dimension 1 Code" := SaleFixedAsset."Global Dimension 1 Code";
            MoveDefualtDimToJnlLineDim(DATABASE::"Fixed Asset", SaleFixedAsset."No.", "Dimension Set ID");
            InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
        end;
    end;

    local procedure InsertCFLineForManualExpense()
    begin
        with CFWorksheetLine2 do begin
            "Cash Flow Manual Expense".TestField("Starting Date");
            Init();
            "Source Type" := "Source Type"::"Cash Flow Manual Expense";
            "Source No." := "Cash Flow Manual Expense".Code;
            "Document No." := "Cash Flow Manual Expense".Code;
            "Cash Flow Account No." := "Cash Flow Manual Expense"."Cash Flow Account No.";
            "Shortcut Dimension 1 Code" := "Cash Flow Manual Expense"."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := "Cash Flow Manual Expense"."Global Dimension 2 Code";
            MoveDefualtDimToJnlLineDim(DATABASE::"Cash Flow Manual Expense", "Cash Flow Manual Expense".Code, "Dimension Set ID");
            Description := CopyStr(StrSubstNo(Text028, "Cash Flow Manual Expense".Description), 1, MaxStrLen(Description));
            DateLastExecution := "Cash Flow Forecast"."Manual Payments To";
            if ("Cash Flow Manual Expense"."Ending Date" <> 0D) and
               ("Cash Flow Manual Expense"."Ending Date" < "Cash Flow Forecast"."Manual Payments To")
            then
                DateLastExecution := "Cash Flow Manual Expense"."Ending Date";
            ExecutionDate := "Cash Flow Manual Expense"."Starting Date";
            if Format("Cash Flow Manual Expense"."Recurring Frequency") <> '' then begin
                if DateLastExecution = 0D then begin
                    NeedsManualPmtUpdate := true;
                    InsertManualData(
                      ExecutionDate, "Cash Flow Forecast", -"Cash Flow Manual Expense".Amount);
                end else
                    while ExecutionDate <= DateLastExecution do begin
                        InsertManualData(
                          ExecutionDate, "Cash Flow Forecast", -"Cash Flow Manual Expense".Amount);
                        ExecutionDate := CalcDate("Cash Flow Manual Expense"."Recurring Frequency", ExecutionDate);
                    end;
            end else
                InsertManualData(ExecutionDate, "Cash Flow Forecast", -"Cash Flow Manual Expense".Amount);
        end;
    end;

    local procedure InsertCFLineForManualRevenue()
    begin
        with CFWorksheetLine2 do begin
            "Cash Flow Manual Revenue".TestField("Starting Date");
            Init();
            "Source Type" := "Source Type"::"Cash Flow Manual Revenue";
            "Source No." := "Cash Flow Manual Revenue".Code;
            "Document No." := "Cash Flow Manual Revenue".Code;
            "Cash Flow Account No." := "Cash Flow Manual Revenue"."Cash Flow Account No.";
            "Shortcut Dimension 1 Code" := "Cash Flow Manual Revenue"."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := "Cash Flow Manual Revenue"."Global Dimension 2 Code";
            MoveDefualtDimToJnlLineDim(DATABASE::"Cash Flow Manual Revenue", "Cash Flow Manual Revenue".Code, "Dimension Set ID");
            Description := CopyStr(StrSubstNo(Text029, "Cash Flow Manual Revenue".Description), 1, MaxStrLen(Description));
            DateLastExecution := "Cash Flow Forecast"."Manual Payments To";
            if ("Cash Flow Manual Revenue"."Ending Date" <> 0D) and
               ("Cash Flow Manual Revenue"."Ending Date" < "Cash Flow Forecast"."Manual Payments To")
            then
                DateLastExecution := "Cash Flow Manual Revenue"."Ending Date";
            ExecutionDate := "Cash Flow Manual Revenue"."Starting Date";
            if Format("Cash Flow Manual Revenue"."Recurring Frequency") <> '' then begin
                if DateLastExecution = 0D then begin
                    NeedsManualPmtUpdate := true;
                    InsertManualData(
                      ExecutionDate, "Cash Flow Forecast", "Cash Flow Manual Revenue".Amount);
                end else
                    while ExecutionDate <= DateLastExecution do begin
                        InsertManualData(
                          ExecutionDate, "Cash Flow Forecast", "Cash Flow Manual Revenue".Amount);
                        ExecutionDate := CalcDate("Cash Flow Manual Revenue"."Recurring Frequency", ExecutionDate);
                    end;
            end else
                InsertManualData(ExecutionDate, "Cash Flow Forecast", "Cash Flow Manual Revenue".Amount);
        end;
    end;

    local procedure InsertCFLineForGLBudget(GLAcc: Record "G/L Account")
    begin
        with CFWorksheetLine2 do begin
            Init();
            "Source Type" := "Source Type"::"G/L Budget";
            "Source No." := GLAcc."No.";
            "G/L Budget Name" := GLBudgEntry."Budget Name";
            "Document No." := Format(GLBudgEntry."Entry No.");
            "Cash Flow Account No." := CFAccountForBudget."No.";
            Description :=
              CopyStr(
                StrSubstNo(
                  Text030, GLAcc.Name, Format(GLBudgEntry.Description)),
                1, MaxStrLen(Description));
            SetCashFlowDate(CFWorksheetLine2, GLBudgEntry.Date);
            "Amount (LCY)" := -GLBudgEntry.Amount;
            "Shortcut Dimension 1 Code" := GLBudgEntry."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := GLBudgEntry."Global Dimension 2 Code";
            "Dimension Set ID" := GLBudgEntry."Dimension Set ID";
            InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
        end;
    end;

    local procedure InsertCFLineForServiceLine()
    var
        ServiceLine2: Record "Service Line";
    begin
        ServiceLine2 := "Service Line";
        if Summarized and (ServiceLine2.Next() <> 0) and (ServiceLine2."Customer No." <> '') and
           (ServiceLine2."Document No." = "Service Line"."Document No.")
        then begin
            TotalAmt += CalculateLineAmountForServiceLine("Service Line");

            MultiSalesLines := true;
        end else
            with CFWorksheetLine2 do begin
                Init();
                "Source Type" := "Source Type"::"Service Orders";
                "Source No." := "Service Line"."Document No.";
                "Source Line No." := "Service Line"."Line No.";
                "Document Type" := "Document Type"::Invoice;
                "Document Date" := ServiceHeader."Document Date";
                "Shortcut Dimension 1 Code" := ServiceHeader."Shortcut Dimension 1 Code";
                "Shortcut Dimension 2 Code" := ServiceHeader."Shortcut Dimension 2 Code";
                "Dimension Set ID" := ServiceHeader."Dimension Set ID";
                "Cash Flow Account No." := CFSetup."Service CF Account No.";
                Description :=
                  CopyStr(
                    StrSubstNo(
                      ServiceDocumentDescriptionTxt,
                      ServiceHeader."Document Type",
                      ServiceHeader.Name,
                      Format(ServiceHeader."Order Date")),
                    1, MaxStrLen(Description));
                SetCashFlowDate(CFWorksheetLine2, ServiceHeader."Due Date");
                "Document No." := "Service Line"."Document No.";
                "Amount (LCY)" := CalculateLineAmountForServiceLine("Service Line");

                if Summarized and MultiSalesLines then begin
                    "Amount (LCY)" := "Amount (LCY)" + TotalAmt;
                    MultiSalesLines := false;
                    TotalAmt := 0;
                end;

                "Payment Terms Code" := ServiceHeader."Payment Terms Code";

                InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
            end;
    end;

    local procedure InsertCFLineForJobPlanningLine()
    var
        Job: Record Job;
        InsertConditionHasBeenMetAlready: Boolean;
    begin
        if (TempCFWorksheetLine."Source Type" = TempCFWorksheetLine."Source Type"::Job) and
           ("Job Planning Line"."Job No." = TempCFWorksheetLine."Source No.") and
           ("Job Planning Line"."Planning Date" = TempCFWorksheetLine."Document Date") and
           ("Job Planning Line"."Document No." = TempCFWorksheetLine."Document No.")
        then begin
            InsertConditionHasBeenMetAlready := InsertConditionMet();
            TempCFWorksheetLine."Amount (LCY)" += GetJobPlanningAmountForCFLine("Job Planning Line");
            InsertOrModifyCFLine(InsertConditionHasBeenMetAlready);
        end else
            with CFWorksheetLine2 do begin
                Init();
                "Source Type" := "Source Type"::Job;
                "Source No." := "Job Planning Line"."Job No.";
                "Document Type" := "Document Type"::Invoice;
                "Document Date" := "Job Planning Line"."Planning Date";

                Job.Get("Job Planning Line"."Job No.");
                "Shortcut Dimension 1 Code" := Job."Global Dimension 1 Code";
                "Shortcut Dimension 2 Code" := Job."Global Dimension 2 Code";
                "Cash Flow Account No." := CFSetup."Job CF Account No.";
                Description :=
                  CopyStr(
                    StrSubstNo(
                      Text025,
                      Job.TableCaption(),
                      Job.Description,
                      Format("Job Planning Line"."Document Date")),
                    1, MaxStrLen(Description));

                if "Job Planning Line"."Planning Due Date" = 0D then
                    if "Job Planning Line".UpdatePlannedDueDate() then
                        "Job Planning Line".Modify();
                SetCashFlowDate(CFWorksheetLine2, "Job Planning Line"."Planning Due Date");

                "Document No." := "Job Planning Line"."Document No.";
                "Amount (LCY)" := GetJobPlanningAmountForCFLine("Job Planning Line");

                InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
            end;
    end;

    local procedure InsertCFLineForTax(SourceTableNum: Integer)
    var
        TaxPayableDate: Date;
        SourceNo: Code[20];
        InsertConditionHasBeenMetAlready: Boolean;
    begin
        TaxPayableDate := GetTaxPayableDateFromSource(SourceTableNum);
        if IsDateBeforeStartOfCurrentPeriod(TaxPayableDate) or HasTaxBeenPaidOn(TaxPayableDate) then
            exit;
        SourceNo := Format(SourceTableNum);
        if Summarized and (TaxLastSourceTableNumProcessed <> SourceTableNum) and
           (TaxLastPayableDateProcessed <> TaxPayableDate)
        then begin
            TotalAmt += GetTaxAmountFromSource(SourceTableNum);
            MultiSalesLines := true;
        end else
            if (TempCFWorksheetLine."Source Type" = TempCFWorksheetLine."Source Type"::Tax) and
               (TempCFWorksheetLine."Source No." = SourceNo) and
               (TempCFWorksheetLine."Document Date" = TaxPayableDate)
            then begin
                InsertConditionHasBeenMetAlready := InsertConditionMet();
                TempCFWorksheetLine."Amount (LCY)" += GetTaxAmountFromSource(SourceTableNum);
                InsertOrModifyCFLine(InsertConditionHasBeenMetAlready);
            end else
                with CFWorksheetLine2 do begin
                    Init();
                    "Source Type" := "Source Type"::Tax;
                    "Source No." := SourceNo;
                    "Document Type" := "Document Type"::" ";
                    "Document Date" := TaxPayableDate;

                    "Shortcut Dimension 1 Code" := '';
                    "Shortcut Dimension 2 Code" := '';
                    "Cash Flow Account No." := CFSetup."Tax CF Account No.";
                    Description := GetDescriptionForTaxCashFlowLine(SourceTableNum);
                    SetCashFlowDate(CFWorksheetLine2, "Document Date");
                    "Document No." := '';
                    "Amount (LCY)" := GetTaxAmountFromSource(SourceTableNum);

                    if Summarized and MultiSalesLines and (TaxLastSourceTableNumProcessed = SourceTableNum) then begin
                        "Amount (LCY)" := "Amount (LCY)" + TotalAmt;
                        MultiSalesLines := false;
                        TotalAmt := 0;
                    end;

                    InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
                end;

        TaxLastSourceTableNumProcessed := SourceTableNum;
        TaxLastPayableDateProcessed := TaxPayableDate;
    end;

    local procedure InsertCFLineForAzureAIForecast(SourceTableNum: Integer)
    begin
        if "Cash Flow Azure AI Buffer"."Delta %" > CFSetup."Variance %" then
            exit;

        with CFWorksheetLine2 do begin
            Init();
            "Source Type" := "Source Type"::"Azure AI";
            "Source No." := Format(SourceTableNum);
            "Document Type" := "Document Type"::" ";
            "Document Date" := "Cash Flow Azure AI Buffer"."Period Start";
            SetCashFlowDate(CFWorksheetLine2, "Document Date");
            "Amount (LCY)" := "Cash Flow Azure AI Buffer".Amount;

            case "Cash Flow Azure AI Buffer"."Group Id" of
                XRECEIVABLESTxt:
                    begin
                        "Cash Flow Account No." := CFSetup."Receivables CF Account No.";
                        Description :=
                          StrSubstNo(
                            AzureAIForecastDescriptionTxt, LowerCase(XRECEIVABLESTxt), "Cash Flow Azure AI Buffer"."Period Start",
                            Round("Cash Flow Azure AI Buffer".Delta));
                    end;
                XPAYABLESTxt:
                    begin
                        "Cash Flow Account No." := CFSetup."Payables CF Account No.";
                        Description :=
                          StrSubstNo(
                            AzureAIForecastDescriptionTxt, LowerCase(XPAYABLESTxt), "Cash Flow Azure AI Buffer"."Period Start",
                            Round("Cash Flow Azure AI Buffer".Delta));
                    end;
                XPAYABLESCORRECTIONTxt:
                    if ConsiderSource["Source Type"::Payables.AsInteger()] then begin
                        "Cash Flow Account No." := CFSetup."Payables CF Account No.";
                        Description := StrSubstNo(AzureAICorrectionDescriptionTxt, LowerCase(XPAYABLESTxt));
                    end else
                        exit;
                XRECEIVABLESCORRECTIONTxt:
                    if ConsiderSource["Source Type"::Receivables.AsInteger()] then begin
                        "Cash Flow Account No." := CFSetup."Receivables CF Account No.";
                        Description := StrSubstNo(AzureAICorrectionDescriptionTxt, LowerCase(XRECEIVABLESTxt))
                    end else
                        exit;
                XPURCHORDERSTxt:
                    if ConsiderSource["Source Type"::"Purchase Orders".AsInteger()] then begin
                        "Cash Flow Account No." := CFSetup."Purch. Order CF Account No.";
                        Description := StrSubstNo(AzureAIOrdersCorrectionDescriptionTxt, LowerCase(XPURCHORDERSTxt))
                    end else
                        exit;
                XSALESORDERSTxt:
                    if ConsiderSource["Source Type"::"Sales Orders".AsInteger()] then begin
                        "Cash Flow Account No." := CFSetup."Sales Order CF Account No.";
                        Description := StrSubstNo(AzureAIOrdersCorrectionDescriptionTxt, LowerCase(XSALESORDERSTxt))
                    end else
                        exit;
                XTAXRECEIVABLESTxt:
                    if ConsiderSource["Source Type"::Tax.AsInteger()] then begin
                        "Cash Flow Account No." := CFSetup."Tax CF Account No.";
                        Description :=
                          StrSubstNo(
                            AzureAIForecastTaxDescriptionTxt, LowerCase(XRECEIVABLESTxt), "Cash Flow Azure AI Buffer"."Period Start",
                            Round("Cash Flow Azure AI Buffer".Delta))
                    end else
                        exit;
                XTAXPAYABLESTxt:
                    if ConsiderSource["Source Type"::Tax.AsInteger()] then begin
                        "Cash Flow Account No." := CFSetup."Tax CF Account No.";
                        Description :=
                          StrSubstNo(
                            AzureAIForecastTaxDescriptionTxt, LowerCase(XPAYABLESTxt), "Cash Flow Azure AI Buffer"."Period Start",
                            Round("Cash Flow Azure AI Buffer".Delta));
                    end else
                        exit;
                XTAXPAYABLESCORRECTIONTxt:
                    if ConsiderSource["Source Type"::Tax.AsInteger()] then begin
                        "Cash Flow Account No." := CFSetup."Tax CF Account No.";
                        Description := StrSubstNo(AzureAICorrectionTaxDescriptionTxt, LowerCase(XPAYABLESTxt));
                    end else
                        exit;
                XTAXRECEIVABLESCORRECTIONTxt:
                    if ConsiderSource["Source Type"::Tax.AsInteger()] then begin
                        "Cash Flow Account No." := CFSetup."Tax CF Account No.";
                        Description := StrSubstNo(AzureAICorrectionTaxDescriptionTxt, LowerCase(XRECEIVABLESTxt))
                    end else
                        exit;
                XTAXPURCHORDERSTxt:
                    if ConsiderSource["Source Type"::Tax.AsInteger()] then begin
                        "Cash Flow Account No." := CFSetup."Tax CF Account No.";
                        Description := StrSubstNo(AzureAIOrdersTaxCorrectionDescriptionTxt, LowerCase(XPURCHORDERSTxt))
                    end else
                        exit;
                XTAXSALESORDERSTxt:
                    if ConsiderSource["Source Type"::Tax.AsInteger()] then begin
                        "Cash Flow Account No." := CFSetup."Tax CF Account No.";
                        Description := StrSubstNo(AzureAIOrdersTaxCorrectionDescriptionTxt, LowerCase(XSALESORDERSTxt))
                    end else
                        exit;
            end;
        end;

        InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
    end;

    local procedure InsertOrModifyCFLine(InsertConditionHasBeenMetAlready: Boolean)
    begin
        CFWorksheetLine2."Amount (LCY)" := TempCFWorksheetLine."Amount (LCY)";
        if InsertConditionHasBeenMetAlready then
            TempCFWorksheetLine.Modify()
        else
            InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
    end;

    local procedure GetSubPostingGLAccounts(var GLAccount: Record "G/L Account"; var TempGLAccount: Record "G/L Account" temporary)
    var
        SubGLAccount: Record "G/L Account";
    begin
        if not GLAccount.FindSet() then
            exit;

        repeat
            case GLAccount."Account Type" of
                GLAccount."Account Type"::Posting:
                    begin
                        TempGLAccount.Init();
                        TempGLAccount.TransferFields(GLAccount);
                        if TempGLAccount.Insert() then;
                    end;
                GLAccount."Account Type"::"End-Total",
                GLAccount."Account Type"::Total:
                    begin
                        CheckCircularRefs(GLAccount);

                        SubGLAccount.SetFilter("No.", GLAccount.Totaling);
                        SubGLAccount.FilterGroup := 2;
                        SubGLAccount.SetFilter("No.", '<>%1', GLAccount."No.");
                        SubGLAccount.FilterGroup := 0;
                        GetSubPostingGLAccounts(SubGLAccount, TempGLAccount);
                    end;
            end;
        until GLAccount.Next() = 0;
    end;

    local procedure SetCashFlowDate(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; CashFlowDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCashFlowDate(CashFlowWorksheetLine, IsHandled);
        if IsHandled then
            exit;

        CashFlowWorksheetLine."Cash Flow Date" := CashFlowDate;
        if CashFlowDate < WorkDate() then begin
            if SelectionCashFlowForecast."Overdue CF Dates to Work Date" then
                CashFlowWorksheetLine."Cash Flow Date" := WorkDate();
            CashFlowWorksheetLine.Overdue := true;
        end
    end;

    local procedure CalculateLineAmountForPurchaseLine(PurchHeader2: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"): Decimal
    var
        PrepmtAmtInvLCY: Decimal;
    begin
        if PurchHeader2."Currency Code" <> '' then begin
            Currency.Get(PurchHeader2."Currency Code");
            PrepmtAmtInvLCY :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  PurchHeader2."Posting Date", PurchHeader2."Currency Code",
                  PurchaseLine."Prepmt. Amt. Inv.", PurchHeader2."Currency Factor"),
                Currency."Amount Rounding Precision");
        end else
            PrepmtAmtInvLCY := PurchaseLine."Prepmt. Amt. Inv.";

        Currency.InitRoundingPrecision();
        if PurchHeader2."Prices Including VAT" then
            exit(-(GetPurchaseAmountForCFLine(PurchaseLine) - PrepmtAmtInvLCY));
        exit(
          -(GetPurchaseAmountForCFLine(PurchaseLine) -
            (PrepmtAmtInvLCY +
             Round(PrepmtAmtInvLCY * PurchaseLine."VAT %" / 100, Currency."Amount Rounding Precision", Currency.VATRoundingDirection()))));
    end;

    local procedure CalculateLineAmountForSalesLine(SalesHeader2: Record "Sales Header"; SalesLine: Record "Sales Line"): Decimal
    var
        PrepmtAmtInvLCY: Decimal;
    begin
        if SalesHeader2."Currency Code" <> '' then begin
            Currency.Get(SalesHeader2."Currency Code");
            PrepmtAmtInvLCY :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  SalesHeader2."Posting Date", SalesHeader2."Currency Code",
                  SalesLine."Prepmt. Amt. Inv.", SalesHeader2."Currency Factor"),
                Currency."Amount Rounding Precision");
        end else
            PrepmtAmtInvLCY := SalesLine."Prepmt. Amt. Inv.";

        Currency.InitRoundingPrecision();
        if SalesHeader2."Prices Including VAT" then
            exit(GetSalesAmountForCFLine(SalesLine) - PrepmtAmtInvLCY);
        exit(
          GetSalesAmountForCFLine(SalesLine) -
          (PrepmtAmtInvLCY +
           Round(PrepmtAmtInvLCY * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision", Currency.VATRoundingDirection())));
    end;

    local procedure CalculateLineAmountForServiceLine(ServiceLine: Record "Service Line"): Decimal
    begin
        exit(GetServiceAmountForCFLine(ServiceLine));
    end;

    local procedure NoOptionsChosen() Result: Boolean
    var
        SourceType: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNoOptionsChosen(Result, IsHandled);
        if IsHandled then
            exit(Result);

        for SourceType := 1 to ArrayLen(ConsiderSource) do
            if ConsiderSource[SourceType] then
                exit(false);
        exit(true);
    end;

    procedure InitializeRequest(NewConsiderSource: array[16] of Boolean; CFNo: Code[20]; NewGLBudgetName: Code[10]; GroupByDocumentType: Boolean)
    begin
        CopyArray(ConsiderSource, NewConsiderSource, 1);
        CashFlowNo := CFNo;
        GLBudgName := NewGLBudgetName;
        Summarized := GroupByDocumentType;
        OnAfterInitializeRequest(ConsiderSource, CashFlowNo, GLBudgName, Summarized)
    end;

    local procedure InsertManualData(ExecutionDate: Date; CashFlowForecast: Record "Cash Flow Forecast"; ManualAmount: Decimal)
    begin
        if ((CashFlowForecast."Manual Payments From" <> 0D) and
            (ExecutionDate < CashFlowForecast."Manual Payments From")) or
           ((CashFlowForecast."Manual Payments To" <> 0D) and
            (ExecutionDate > CashFlowForecast."Manual Payments To"))
        then
            exit;

        with CFWorksheetLine2 do begin
            SetCashFlowDate(CFWorksheetLine2, ExecutionDate);
            "Amount (LCY)" := ManualAmount;
            InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
        end;
    end;

    local procedure GetPurchaseAmountForCFLine(PurchaseLine: Record "Purchase Line"): Decimal
    begin
        exit(PurchaseLine."Outstanding Amount (LCY)" + PurchaseLine."Amt. Rcd. Not Invoiced (LCY)");
    end;

    local procedure GetSalesAmountForCFLine(SalesLine: Record "Sales Line"): Decimal
    begin
        exit(SalesLine."Outstanding Amount (LCY)" + SalesLine."Shipped Not Invoiced (LCY)");
    end;

    local procedure GetServiceAmountForCFLine(ServiceLine: Record "Service Line"): Decimal
    begin
        exit(ServiceLine."Outstanding Amount (LCY)" + ServiceLine."Shipped Not Invoiced (LCY)");
    end;

    local procedure GetJobPlanningAmountForCFLine(JobPlanningLine: Record "Job Planning Line"): Decimal
    begin
        JobPlanningLine.CalcFields("Invoiced Amount (LCY)");
        exit(JobPlanningLine."Line Amount (LCY)" - JobPlanningLine."Invoiced Amount (LCY)");
    end;

    local procedure GetTaxPayableDateFromSource(SourceTableNum: Integer): Date
    var
        CashFlowSetup: Record "Cash Flow Setup";
        DocumentDate: Date;
    begin
        case SourceTableNum of
            DATABASE::"Sales Header":
                DocumentDate := "Sales Header"."Document Date";
            DATABASE::"Purchase Header":
                DocumentDate := "Purchase Header"."Document Date";
            DATABASE::"VAT Entry":
                DocumentDate := "VAT Entry"."Document Date";
        end;

        OnGetTaxPayableDateFromSourceOnBeforeExit(SourceTableNum, "Sales Header", "Purchase Header", "VAT Entry", DocumentDate);
        exit(CashFlowSetup.GetTaxPaymentDueDate(DocumentDate));
    end;

    local procedure HasTaxBeenPaidOn(PaymentDate: Date): Boolean
    var
        CashFlowSetup: Record "Cash Flow Setup";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        TaxPaymentStartDate: Date;
        BalanceAccountType: Enum "Gen. Journal Account Type";
    begin
        TaxPaymentStartDate := CashFlowSetup.GetTaxPaymentStartDate(PaymentDate);
        case CashFlowSetup."Tax Bal. Account Type" of
            CashFlowSetup."Tax Bal. Account Type"::" ":
                exit(false);
            CashFlowSetup."Tax Bal. Account Type"::Vendor:
                BalanceAccountType := BankAccountLedgerEntry."Bal. Account Type"::Vendor;
            CashFlowSetup."Tax Bal. Account Type"::"G/L Account":
                BalanceAccountType := BankAccountLedgerEntry."Bal. Account Type"::"G/L Account";
        end;
        BankAccountLedgerEntry.SetRange("Bal. Account Type", BalanceAccountType);
        BankAccountLedgerEntry.SetFilter("Posting Date", '%1..%2', TaxPaymentStartDate, PaymentDate);
        BankAccountLedgerEntry.SetRange("Bal. Account No.", CashFlowSetup."Tax Bal. Account No.");
        exit(not BankAccountLedgerEntry.IsEmpty);
    end;

    local procedure GetDescriptionForTaxCashFlowLine(SourceTableNum: Integer): Text[250]
    var
        PurchaseOrders: Page "Purchase Orders";
        SalesOrders: Page "Sales Orders";
        VATEntries: Page "VAT Entries";
    begin
        case SourceTableNum of
            DATABASE::"Purchase Header":
                exit(StrSubstNo(TaxForMsg, PurchaseOrders.Caption));
            DATABASE::"Sales Header":
                exit(StrSubstNo(TaxForMsg, SalesOrders.Caption));
            DATABASE::"VAT Entry":
                exit(StrSubstNo(TaxForMsg, VATEntries.Caption));
        end;
    end;

    local procedure GetTaxAmountFromSource(SourceTableNum: Integer): Decimal
    var
        CashFlowManagement: Codeunit "Cash Flow Management";
    begin
        case SourceTableNum of
            DATABASE::"Sales Header":
                exit(CashFlowManagement.GetTaxAmountFromSalesOrder("Sales Header"));
            DATABASE::"Purchase Header":
                exit(CashFlowManagement.GetTaxAmountFromPurchaseOrder("Purchase Header"));
            DATABASE::"VAT Entry":
                exit("VAT Entry".Amount);
        end;
    end;

    local procedure IsDateBeforeStartOfCurrentPeriod(Date: Date): Boolean
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        exit(Date < CashFlowSetup.GetCurrentPeriodStartDate());
    end;

    local procedure CheckCircularRefs(var GLAccount: Record "G/L Account")
    var
        AccountPair: Code[50];
        RecursiveLimit: Integer;
    begin
        RecursiveLimit := GetRecursiveLimit();
        AccountPair := StrSubstNo(ThreePlaceHoldersLbl, LastTotalAccount, '|', GLAccount."No.");
        TotalAccountPairs.Add(AccountPair);
        TotalAccounts.Add(GLAccount."No.");
        LastTotalAccount := GLAccount."No.";
        if TotalAccountPairs.Contains(AccountPair) then
            if CountRepeatedElement(AccountPair) >= RecursiveLimit then
                Error(CircularRefsErr, GetCircularRefErrorMessage(AccountPair));
    end;

    local procedure ClearCircularRefData()
    begin
        Clear(TotalAccounts);
        Clear(TotalAccountPairs);
        LastTotalAccount := '';
    end;

    local procedure CountRepeatedElement(AccountPair: Code[50]) Result: Integer
    var
        Index: Integer;
    begin
        for Index := TotalAccountPairs.IndexOf(AccountPair) to TotalAccountPairs.LastIndexOf(AccountPair) do
            if TotalAccountPairs.Get(Index) = AccountPair then
                Result += 1;
    end;

    local procedure GetRecursiveLimit() Limit: Integer
    begin
        Limit := 3;
        OnAfterGetRecursiveLimit(Limit);
    end;

    local procedure GetCircularRefErrorMessage(AccountPair: Code[50]) CircularRefs: Text;
    var
        Index: Integer;
        StartIndex: Integer;
        EndIndex: Integer;
        SeparatorChar: Text[1];
    begin
        EndIndex := TotalAccountPairs.Count();
        TotalAccountPairs.RemoveAt(EndIndex);
        EndIndex -= 1;
        StartIndex := TotalAccountPairs.LastIndexOf(AccountPair);
        for Index := 1 to EndIndex do begin
            if Index = StartIndex then
                CircularRefs += '(';
            if Index = EndIndex then
                SeparatorChar := ')'
            else
                SeparatorChar := ',';
            CircularRefs += StrSubstNo(ThreePlaceHoldersLbl, TotalAccounts.Get(Index), SeparatorChar, ' ');
        end;
    end;

    procedure SetSummarized(NewSummarized: Boolean)
    begin
        Summarized := NewSummarized;
    end;

    procedure GetSummarized(): Boolean
    begin
        exit(Summarized);
    end;

    local procedure GetSalesOrderPrepaymentAmt(SalesLine: Record "Sales Line"): Decimal
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RemainingAmount: Decimal;
    begin
        SalesInvoiceHeader.SetLoadFields("Prepayment Order No.");
        SalesInvoiceHeader.SetRange("Prepayment Order No.", SalesLine."Document No.");
        SalesInvoiceHeader.SetFilter("Remaining Amount", '<>%1', 0);
        if SalesInvoiceHeader.FindSet() then
            repeat
                SalesInvoiceHeader.CalcFields("Remaining Amount");
                RemainingAmount += SalesInvoiceHeader."Remaining Amount";
            until SalesInvoiceHeader.Next() = 0;

        exit(RemainingAmount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCFAccountForBudgetOnAfterGetRecordOnAfterGLBudgEntrySetFilters(var GLBudgEntry: Record "G/L Budget Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTaxPayableDateFromSourceOnBeforeExit(SourceTableNum: Integer; SalesHeader: Record "Sales Header"; PurchaseHeader: Record "Purchase Header"; VATEntry: Record "VAT Entry"; var DocumentDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCFLineForCustLedgerEntryOnBeforeInsertTempCFWorksheetLine(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; CashFlowForecast: Record "Cash Flow Forecast"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCashFlowDate(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNoOptionsChosen(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobPlanningLineOnAfterGetRecordOnBeforeInsertCFLineForJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecursiveLimit(var Limit: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeRequest(var ConsiderSource: array[16] of Boolean; var CashFlowNo: Code[20]; var GLBudgName: Code[10]; var Summarized: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitCFLineForFixedAssetsBudget(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; FADepreciationBook: Record "FA Depreciation Book"; InvestmentFixedAsset: Record "Fixed Asset")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempCFWorksheetLineOnBeforeCalculateCFAmountAndCFDate(TempCashFlowWorksheetLine: Record "Cash Flow Worksheet Line" temporary; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCFLineForPurchaseLineOnBeforeInsertTempCFWorksheetLine(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
    end;
}

