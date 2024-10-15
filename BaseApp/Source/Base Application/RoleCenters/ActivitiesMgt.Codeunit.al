// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Receivables;
using System.Environment;

codeunit 1311 "Activities Mgt."
{

    trigger OnRun()
    begin
        if IsCueDataStale() then
            RefreshActivitiesCueData();
    end;

    var
        DefaultWorkDate: Date;
        RefreshFrequencyErr: Label 'Refresh intervals of less than 10 minutes are not supported.';
        NoSubCategoryWithAdditionalReportDefinitionOfCashAccountsTok: Label 'There are no %1 with %2 specified for %3', Comment = '%1 Table Comment G/L Account Category, %2 field Additional Report Definition, %3 value: Cash Accounts';

    procedure OverdueSalesInvoiceAmount(CalledFromWebService: Boolean; UseCachedValue: Boolean): Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ActivitiesCue: record "Activities Cue";
        Amount: Decimal;
    begin
        Amount := 0;
        if UseCachedValue then
            if ActivitiesCue.Get() then
                if not IsPassedCueData(ActivitiesCue) then
                    exit(ActivitiesCue."Overdue Sales Invoice Amount");
        SetFilterOverdueSalesInvoice(CustLedgerEntry, CalledFromWebService);
        CustLedgerEntry.SetAutoCalcFields("Remaining Amt. (LCY)");
        if CustLedgerEntry.FindSet() then
            repeat
                Amount := Amount + CustLedgerEntry."Remaining Amt. (LCY)";
            until CustLedgerEntry.Next() = 0;
        exit(Amount);
    end;

    procedure SetFilterOverdueSalesInvoice(var CustLedgerEntry: Record "Cust. Ledger Entry"; CalledFromWebService: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetFilterOverdueSalesInvoice(CustLedgerEntry, CalledFromWebService, IsHandled);
        if IsHandled then
            exit;

        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange(Open, true);
        if CalledFromWebService then
            CustLedgerEntry.SetFilter("Due Date", '<%1', Today)
        else
            CustLedgerEntry.SetFilter("Due Date", '<%1', GetDefaultWorkDate());
    end;

    procedure DrillDownCalcOverdueSalesInvoiceAmount()
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDrillDownCalcOverdueSalesInvoiceAmount(CustLedgerEntry, IsHandled);
        if IsHandled then
            exit;

        SetFilterOverdueSalesInvoice(CustLedgerEntry, false);
        CustLedgerEntry.SetFilter("Remaining Amt. (LCY)", '<>0');
        CustLedgerEntry.SetCurrentKey("Remaining Amt. (LCY)");
        CustLedgerEntry.Ascending := false;

        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgerEntry);
    end;

    procedure OverduePurchaseInvoiceAmount(CalledFromWebService: Boolean; UseCachedValue: Boolean): Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ActivitiesCue: Record "Activities Cue";
        Amount: Decimal;
    begin
        Amount := 0;
        if UseCachedValue then
            if ActivitiesCue.Get() then
                if not IsPassedCueData(ActivitiesCue) then
                    exit(ActivitiesCue."Overdue Purch. Invoice Amount");
        SetFilterOverduePurchaseInvoice(VendorLedgerEntry, CalledFromWebService);
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amt. (LCY)");
        if VendorLedgerEntry.FindSet() then
            repeat
                Amount := Amount + VendorLedgerEntry."Remaining Amt. (LCY)";
            until VendorLedgerEntry.Next() = 0;
        exit(-Amount);
    end;

    procedure SetFilterOverduePurchaseInvoice(var VendorLedgerEntry: Record "Vendor Ledger Entry"; CalledFromWebService: Boolean)
    begin
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        if CalledFromWebService then
            VendorLedgerEntry.SetFilter("Due Date", '<%1', Today)
        else
            VendorLedgerEntry.SetFilter("Due Date", '<%1', GetDefaultWorkDate());
        OnAfterSetFilterOverduePurchaseInvoice(VendorLedgerEntry, CalledFromWebService);
    end;

    procedure DrillDownOverduePurchaseInvoiceAmount()
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDrillDownOverduePurchaseInvoiceAmount(VendorLedgerEntry, IsHandled);
        if IsHandled then
            exit;

        SetFilterOverduePurchaseInvoice(VendorLedgerEntry, false);
        VendorLedgerEntry.SetFilter("Remaining Amt. (LCY)", '<>0');
        VendorLedgerEntry.SetCurrentKey("Remaining Amt. (LCY)");
        VendorLedgerEntry.Ascending := true;

        PAGE.Run(PAGE::"Vendor Ledger Entries", VendorLedgerEntry);
    end;

    procedure CalcSalesThisMonthAmount(CalledFromWebService: Boolean) Amount: Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        SetFilterForCalcSalesThisMonthAmount(CustLedgerEntry, CalledFromWebService);
        CustLedgerEntry.CalcSums("Sales (LCY)");
        Amount := CustLedgerEntry."Sales (LCY)";
    end;

    [Scope('OnPrem')]
    procedure SetFilterForCalcSalesThisMonthAmount(var CustLedgerEntry: Record "Cust. Ledger Entry"; CalledFromWebService: Boolean)
    begin
        CustLedgerEntry.SetFilter("Document Type", '%1|%2',
          CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::"Credit Memo");
        if CalledFromWebService then
            CustLedgerEntry.SetRange("Posting Date", CalcDate('<-CM>', Today), Today)
        else
            CustLedgerEntry.SetRange("Posting Date", CalcDate('<-CM>', GetDefaultWorkDate()), GetDefaultWorkDate());
    end;

    procedure DrillDownSalesThisMonth()
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetFilter("Document Type", '%1|%2',
          CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::"Credit Memo");
        CustLedgerEntry.SetRange("Posting Date", CalcDate('<-CM>', GetDefaultWorkDate()), GetDefaultWorkDate());
        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgerEntry);
    end;

    procedure CalcSalesYTD() Amount: Decimal
    var
        AccountingPeriod: Record "Accounting Period";
        [SecurityFiltering(SecurityFilter::Filtered)]
        CustLedgEntrySales: Query "Cust. Ledg. Entry Sales";
    begin
        CustLedgEntrySales.SetRange(Posting_Date, AccountingPeriod.GetFiscalYearStartDate(GetDefaultWorkDate()), GetDefaultWorkDate());
        CustLedgEntrySales.Open();

        if CustLedgEntrySales.Read() then
            Amount := CustLedgEntrySales.Sum_Sales_LCY;
    end;

    procedure CalcTop10CustomerSalesYTD() Amount: Decimal
    var
        AccountingPeriod: Record "Accounting Period";
        Top10CustomerSales: Query "Top 10 Customer Sales";
    begin
        // Total Sales (LCY) by top 10 list of customers year-to-date.
        Top10CustomerSales.SetRange(Posting_Date, AccountingPeriod.GetFiscalYearStartDate(GetDefaultWorkDate()), GetDefaultWorkDate());
        Top10CustomerSales.Open();

        while Top10CustomerSales.Read() do
            Amount += Top10CustomerSales.Sum_Sales_LCY;
    end;

    procedure CalcTop10CustomerSalesRatioYTD() Amount: Decimal
    var
        TotalSales: Decimal;
    begin
        // Ratio of Sales by top 10 list of customers year-to-date.
        TotalSales := CalcSalesYTD();
        if TotalSales <> 0 then
            Amount := CalcTop10CustomerSalesYTD() / TotalSales;
    end;

    procedure CalcAverageCollectionDays() AverageDays: Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SumCollectionDays: Integer;
        CountInvoices: Integer;
    begin
        GetPaidSalesInvoices(CustLedgerEntry);
        if CustLedgerEntry.FindSet() then begin
            repeat
                SumCollectionDays += (CustLedgerEntry."Closed at Date" - CustLedgerEntry."Posting Date");
                CountInvoices += 1;
            until CustLedgerEntry.Next() = 0;

            AverageDays := SumCollectionDays / CountInvoices;
        end
    end;

    procedure CalcNoOfReservedFromStockSalesOrders() Number: Integer
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
    begin
        Number := 0;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetLoadFields("Document Type", "No.");
        if SalesHeader.FindSet() then
            repeat
                if SalesHeader.GetQtyReservedFromStockState() = Enum::"Reservation From Stock"::Full then
                    Number += 1;
            until SalesHeader.Next() = 0;
    end;

    procedure DrillDownNoOfReservedFromStockSalesOrders()
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetLoadFields("Document Type", "No.");
        if SalesHeader.FindSet() then
            repeat
                if SalesHeader.GetQtyReservedFromStockState() = Enum::"Reservation From Stock"::Full then
                    SalesHeader.Mark(true);
            until SalesHeader.Next() = 0;
        SalesHeader.MarkedOnly(true);
        Page.Run(Page::"Sales Order List", SalesHeader);
    end;

    local procedure GetPaidSalesInvoices(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange(Open, false);
        CustLedgerEntry.SetRange("Posting Date", CalcDate('<CM-3M>', GetDefaultWorkDate()), GetDefaultWorkDate());
        CustLedgerEntry.SetRange("Closed at Date", CalcDate('<CM-3M>', GetDefaultWorkDate()), GetDefaultWorkDate());
    end;

    procedure CalcCashAccountsBalances() CashAccountBalance: Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GLAccount: Record "G/L Account";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GLAccCategory: Record "G/L Account Category";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GLEntries: Record "G/L Entry";
    begin
        GLAccount.SetRange("Account Category", GLAccount."Account Category"::Assets);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetFilter("Account Subcategory Entry No.", CreateFilterForGLAccSubCategoryEntries(GLAccCategory."Additional Report Definition"::"Cash Accounts"));
        GLEntries.SetFilter("G/L Account No.", CreateFilterForGLAccounts(GLAccount));
        GLEntries.CalcSums(Amount);
        CashAccountBalance := GLEntries.Amount;
    end;

    procedure DrillDownCalcCashAccountsBalances()
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GLAccount: Record "G/L Account";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GLAccCategory: Record "G/L Account Category";
    begin
        GLAccount.SetRange("Account Category", GLAccount."Account Category"::Assets);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        TestifSubCategoryIsSpecifield();
        GLAccount.SetFilter("Account Subcategory Entry No.", CreateFilterForGLAccSubCategoryEntries(GLAccCategory."Additional Report Definition"::"Cash Accounts"));
        PAGE.Run(PAGE::"Chart of Accounts", GLAccount);
    end;

    local procedure SetGLAccountsFilterForARAccounts(var GLAccount: Record "G/L Account"): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategory: Record "G/L Account Category";
    begin
        if not GeneralLedgerSetup.Get() then
            exit(false);
        if not GLAccountCategory.Get(GeneralLedgerSetup."Acc. Receivables Category") then
            exit(false);
        GLAccount.SetRange("Account Category", GLAccount."Account Category"::Assets);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange("Account Subcategory Entry No.", GLAccountCategory."Entry No.");
        exit(true);
    end;

    internal procedure CalcARAccountsBalances(): Decimal
    var
        GLAccount: Record "G/L Account";
        GLEntries: Record "G/L Entry";
    begin
        if not SetGLAccountsFilterForARAccounts(GLAccount) then
            exit(0);
        GLEntries.SetFilter("G/L Account No.", CreateFilterForGLAccounts(GLAccount));
        GLEntries.CalcSums(Amount);
        exit(GLEntries.Amount);
    end;

    internal procedure DrillDownCalcARAccountsBalances()
    var
        GLAccount: Record "G/L Account";
    begin
        if not SetGLAccountsFilterForARAccounts(GLAccount) then
            Page.Run(Page::"General Ledger Setup");
        PAGE.Run(PAGE::"Chart of Accounts", GLAccount);
    end;

    local procedure TestifSubCategoryIsSpecifield();
    var
        GLAccCategory: Record "G/L Account Category";
    begin
        GLAccCategory.setrange("Additional Report Definition", GlaccCategory."Additional Report Definition"::"Cash Accounts");
        if GLAccCategory.IsEmpty() then
            Message(NoSubCategoryWithAdditionalReportDefinitionOfCashAccountsTok,
              GLAccCategory.TableCaption(), GLAccCategory.FieldCaption("Additional Report Definition"),
              GLAccCategory."Additional Report Definition"::"Cash Accounts");
    end;

    local procedure RefreshActivitiesCueData()
    var
        ActivitiesCue: Record "Activities Cue";
    begin
        ActivitiesCue.LockTable();

        ActivitiesCue.Get();

        if not IsPassedCueData(ActivitiesCue) then
            exit;

        ActivitiesCue.SetFilter("Due Date Filter", '>=%1', GetDefaultWorkDate());
        ActivitiesCue.SetFilter("Overdue Date Filter", '<%1', GetDefaultWorkDate());
        ActivitiesCue.SetFilter("Due Next Week Filter", '%1..%2', CalcDate('<1D>', GetDefaultWorkDate()), CalcDate('<1W>', GetDefaultWorkDate()));

        if ActivitiesCue.FieldActive("Overdue Sales Invoice Amount") then
            ActivitiesCue."Overdue Sales Invoice Amount" := OverdueSalesInvoiceAmount(false, false);

        if ActivitiesCue.FieldActive("Overdue Purch. Invoice Amount") then
            ActivitiesCue."Overdue Purch. Invoice Amount" := OverduePurchaseInvoiceAmount(false, false);

        if ActivitiesCue.FieldActive("Sales This Month") then
            ActivitiesCue."Sales This Month" := CalcSalesThisMonthAmount(false);

        if ActivitiesCue.FieldActive("Average Collection Days") then
            ActivitiesCue."Average Collection Days" := CalcAverageCollectionDays();

        if ActivitiesCue.FieldActive("S. Ord. - Reserved From Stock") then
            ActivitiesCue."S. Ord. - Reserved From Stock" := CalcNoOfReservedFromStockSalesOrders();

        ActivitiesCue."Last Date/Time Modified" := CurrentDateTime;
        OnRefreshActivitiesCueDataOnBeforeModify(ActivitiesCue);
        ActivitiesCue.Modify();
        Commit();
    end;

    [Scope('OnPrem')]
    procedure IsCueDataStale(): Boolean
    var
        ActivitiesCue: Record "Activities Cue";
    begin
        if not ActivitiesCue.Get() then
            exit(false);

        exit(IsPassedCueData(ActivitiesCue));
    end;

    local procedure IsPassedCueData(ActivitiesCue: Record "Activities Cue"): Boolean
    begin
        if ActivitiesCue."Last Date/Time Modified" = 0DT then
            exit(true);

        exit(CurrentDateTime - ActivitiesCue."Last Date/Time Modified" >= GetActivitiesCueRefreshInterval())
    end;

    local procedure GetDefaultWorkDate(): Date
    var
        LogInManagement: Codeunit LogInManagement;
    begin
        if DefaultWorkDate = 0D then
            DefaultWorkDate := LogInManagement.GetDefaultWorkDate();
        exit(DefaultWorkDate);
    end;

    local procedure GetActivitiesCueRefreshInterval() Interval: Duration
    var
        MinInterval: Duration;
    begin
        MinInterval := 10 * 60 * 1000; // 10 minutes
        Interval := 60 * 60 * 1000; // 1 hr
        OnGetRefreshInterval(Interval);
        if Interval < MinInterval then
            Error(RefreshFrequencyErr);
    end;

    local procedure CreateFilterForGLAccSubCategoryEntries(AddRepDef: Option): Text
    var
        GLAccCategory: Record "G/L Account Category";
        FilterOperand: Char;
        FilterTxt: Text;
    begin
        FilterOperand := '|';
        GLAccCategory.SetRange("Additional Report Definition", AddRepDef);
        if GLAccCategory.FindSet() then
            repeat
                if FilterTxt = '' then
                    FilterTxt := Format(GLAccCategory."Entry No.") + FilterOperand
                else
                    FilterTxt := FilterTxt + Format(GLAccCategory."Entry No.") + FilterOperand;
            until GLAccCategory.Next() = 0;
        // Remove the last |
        exit(DelChr(FilterTxt, '>', FilterOperand));
    end;

    local procedure CreateFilterForGLAccounts(var GLAccount: Record "G/L Account"): Text
    var
        FilterOperand: Char;
        FilterTxt: Text;
    begin
        FilterOperand := '|';
        if GLAccount.FindSet() then
            repeat
                if FilterTxt = '' then
                    FilterTxt := Format(GLAccount."No.") + FilterOperand
                else
                    FilterTxt := FilterTxt + Format(GLAccount."No.") + FilterOperand;
            until GLAccount.Next() = 0;
        // Remove the last |
        exit(DelChr(FilterTxt, '>', FilterOperand));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterOverduePurchaseInvoice(var VendorLedgerEntry: Record "Vendor Ledger Entry"; CalledFromWebService: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownCalcOverdueSalesInvoiceAmount(var CustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownOverduePurchaseInvoiceAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetFilterOverdueSalesInvoice(var CustLedgerEntry: Record "Cust. Ledger Entry"; CalledFromWebService: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRefreshInterval(var Interval: Duration)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRefreshActivitiesCueDataOnBeforeModify(var ActivitiesCue: Record "Activities Cue")
    begin
    end;
}

