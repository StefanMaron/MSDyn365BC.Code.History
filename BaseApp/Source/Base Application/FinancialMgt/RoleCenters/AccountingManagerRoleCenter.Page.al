﻿namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Deposit;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Reports;
using Microsoft.Bank.Statement;
using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Reports;
using Microsoft.CashFlow.Setup;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Allocation;
using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Reports;
using Microsoft.CostAccounting.Setup;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Costing;
#if not CLEAN22
using Microsoft.Inventory.Intrastat;
#endif
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Reports;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Analysis;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Task;
using System.Threading;
using Microsoft.Sales.Reports;
using Microsoft.Purchases.Reports;

page 9001 "Accounting Manager Role Center"
{
    Caption = 'Accounting Manager';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            group(Control1900724808)
            {
                ShowCaption = false;
                part(Control99; "Finance Performance")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                part(Control1902304208; "Account Manager Activities")
                {
                    ApplicationArea = Basic, Suite;
                }
                part("User Tasks Activities"; "User Tasks Activities")
                {
                    ApplicationArea = Suite;
                }
                part(Control1907692008; "My Customers")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Control1900724708)
            {
                ShowCaption = false;
                part(Control103; "Trailing Sales Orders Chart")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                part(Control106; "My Job Queue")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                part(Control100; "Cash Flow Forecast Chart")
                {
                    ApplicationArea = Basic, Suite;
                }
                part(Control1902476008; "My Vendors")
                {
                    ApplicationArea = Basic, Suite;
                }
                part(Control108; "Report Inbox Part")
                {
                    ApplicationArea = Basic, Suite;
                }
                systempart(Control1901377608; MyNotes)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("&G/L Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&G/L Trial Balance';
                Image = "Report";
                RunObject = Report "Trial Balance";
                ToolTip = 'View, print, or send a report that shows the balances for the general ledger accounts, including the debits and credits. You can use this report to ensure accurate accounting practices.';
            }
            action("Chart of Accounts")
            {
                Caption = 'Chart of Accounts';
                Image = "Report";
                RunObject = Report "Chart of Accounts";
                ToolTip = 'View the chart of accounts.';
            }
            action("&Bank Detail Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Bank Detail Trial Balance';
                Image = "Report";
                RunObject = Report "Bank Acc. - Detail Trial Bal.";
                ToolTip = 'View, print, or send a report that shows a detailed trial balance for selected bank accounts. You can use the report at the close of an accounting period or fiscal year.';
            }
            action("Account Schedule Layout")
            {
                Caption = 'Account Schedule Layout';
                Image = "Report";
                RunObject = Report "Account Schedule Layout";
                ToolTip = 'Adjust the layout of the account schedule.';
            }
            action("&Account Schedule")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Account Schedule';
                Image = "Report";
                RunObject = Report "Account Schedule";
                ToolTip = 'Open an account schedule to analyze figures in general ledger accounts or to compare general ledger entries with general ledger budget entries.';
            }
            action("Account Balances by GIFI Code")
            {
                Caption = 'Account Balances by GIFI Code';
                Image = "Report";
                RunObject = Report "Account Balances by GIFI Code";
                ToolTip = 'Review your account balances by General Index of Financial Information (GIFI) codes.';
            }
            action(Budget)
            {
                ApplicationArea = Suite;
                Caption = 'Budget';
                Image = "Report";
                RunObject = Report Budget;
                ToolTip = 'View or edit estimated amounts for a range of accounting periods.';
            }
            action("Trial Bala&nce/Budget")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Trial Bala&nce/Budget';
                Image = "Report";
                RunObject = Report "Trial Balance/Budget";
                ToolTip = 'View a trial balance in comparison to a budget. You can choose to see a trial balance for selected dimensions. You can use the report at the close of an accounting period or fiscal year.';
            }
            action("Trial Bala&nce, Spread Periods")
            {
                Caption = 'Trial Bala&nce, Spread Periods';
                Image = "Report";
                RunObject = Report "Trial Balance, Spread Periods";
                ToolTip = 'View a trial balance with amounts shown in separate columns for each time period.';
            }
            action("Trial Balance, per Global Dim.")
            {
                Caption = 'Trial Balance, per Global Dim.';
                Image = "Report";
                RunObject = Report "Trial Balance, per Global Dim.";
                ToolTip = 'View three types of departmental trial balances: current trial balance and trial balances which compare current amounts to either the prior year or to the current budget. Each department selected will have a separate trial balance generated.';
            }
            action("Trial Balance, Spread G. Dim.")
            {
                Caption = 'Trial Balance, Spread G. Dim.';
                Image = "Report";
                RunObject = Report "Trial Balance, Spread G. Dim.";
                ToolTip = 'View the chart of accounts with balances or net changes, with each department in a separate column. This report can be used at the close of an accounting period or fiscal year.';
            }
            action("Trial Balance Detail/Summary")
            {
                Caption = 'Trial Balance Detail/Summary';
                Image = "Report";
                RunObject = Report "Trial Balance Detail/Summary";
                ToolTip = 'View general ledger account balances and activities for all the selected accounts, one transaction per line. You can include general ledger accounts which have a balance and including the closing entries within the period.';
            }
            action("&Fiscal Year Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Fiscal Year Balance';
                Image = "Report";
                RunObject = Report "Fiscal Year Balance";
                ToolTip = 'View, print, or send a report that shows balance sheet movements for selected periods. The report shows the closing balance by the end of the previous fiscal year for the selected ledger accounts. It also shows the fiscal year until this date, the fiscal year by the end of the selected period, and the balance by the end of the selected period, excluding the closing entries. The report can be used at the close of an accounting period or fiscal year.';
            }
            action("Balance Comp. - Prev. Y&ear")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance Comp. - Prev. Y&ear';
                Image = "Report";
                RunObject = Report "Balance Comp. - Prev. Year";
                ToolTip = 'View a report that shows your company''s assets, liabilities, and equity compared to the previous year.';
            }
            action("&Closing Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Closing Trial Balance';
                Image = "Report";
                RunObject = Report "Closing Trial Balance";
                ToolTip = 'View, print, or send a report that shows this year''s and last year''s figures as an ordinary trial balance. The closing of the income statement accounts is posted at the end of a fiscal year. The report can be used in connection with closing a fiscal year.';
            }
            action("Consol. Trial Balance")
            {
                Caption = 'Consol. Trial Balance';
                Image = "Report";
                RunObject = Report "Consolidated Trial Balance";
                ToolTip = 'View the trial balance for a consolidated company.';
            }
            separator(Action49)
            {
            }
            action("Cash Flow Date List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Flow Date List';
                Image = "Report";
                RunObject = Report "Cash Flow Date List";
                ToolTip = 'View forecast entries for a period of time that you specify. The registered cash flow forecast entries are organized by source types, such as receivables, sales orders, payables, and purchase orders. You specify the number of periods and their length.';
            }
            separator(Action115)
            {
            }
            action("Aged Accounts &Receivable")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Aged Accounts &Receivable';
                Image = "Report";
                RunObject = Report "Aged Accounts Receivable NA";
                ToolTip = 'View an overview of when your receivables from customers are due or overdue (divided into four periods). You must specify the date you want aging calculated from and the length of the period that each column will contain data for.';
            }
            action("Aged Accounts Pa&yable")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Aged Accounts Pa&yable';
                Image = "Report";
                RunObject = Report "Aged Accounts Payable NA";
                ToolTip = 'View an overview of when your payables to vendors are due or overdue (divided into four periods). You must specify the date you want aging calculated from and the length of the period that each column will contain data for.';
            }
            action("Projected Cash Receipts")
            {
                Caption = 'Projected Cash Receipts';
                Image = "Report";
                RunObject = Report "Projected Cash Receipts";
                ToolTip = 'View projections about cash receipts for up to four periods. You can specify the start date as well as the type of periods, such as days, weeks, months, or years.';
            }
            action("Cash Requirem. by Due Date")
            {
                Caption = 'Cash Requirem. by Due Date';
                Image = "Report";
                RunObject = Report "Cash Requirements by Due Date";
                ToolTip = 'View cash requirements for a specific due date. The report includes open entries that are not on hold. Based on these entries, the report calculates the values for the remaining amount and remaining amount in the local currency.';
            }
            action("Projected Cash Payments")
            {
                Caption = 'Projected Cash Payments';
                Image = PaymentForecast;
                RunObject = Report "Projected Cash Payments";
                ToolTip = 'View projections about what future payments to vendors will be. Current orders are used to generate a chart, using the specified time period and start date, to break down future payments. The report also includes a total balance column.';
            }
            action("Reconcile Cust. and Vend. Accs")
            {
                Caption = 'Reconcile Cust. and Vend. Accs';
                Image = "Report";
                RunObject = Report "Reconcile Cust. and Vend. Accs";
                ToolTip = 'View whether a certain general ledger account reconciles the balance on a certain date for the corresponding posting group. This report shows the accounts that are included in the reconciliation with the general ledger balance and the customer or the vendor ledger balance for each account. Under each account, there is a list of the subtotals from customer or vendor ledger. Any differences between the general ledger balance and the customer or vendor ledger balance are also shown.';
            }
            action("Daily Invoicing Report")
            {
                Caption = 'Daily Invoicing Report';
                Image = "Report";
                RunObject = Report "Daily Invoicing Report";
                ToolTip = 'View the total invoice or credit memo activity, or both. This report can be run for a particular day, or range of dates. The report shows one line for each invoice or credit memo. You can view the bill-to customer number, name, payment terms, salesperson code, amount, sales tax, amount including tax, and total of all invoices or credit memos.';
            }
            action("Bank Account - Reconcile")
            {
                Caption = 'Bank Account - Reconcile';
                Image = "Report";
                RunObject = Report "Bank Account - Reconcile";
                ToolTip = 'Reconcile bank transactions with bank account ledger entries to ensure that your bank account in Dynamics NAV reflects your actual liquidity.';
            }
            separator(Action53)
            {
            }
            separator("Sales Tax")
            {
                Caption = 'Sales Tax';
                IsHeader = true;
            }
            action("Sales Tax Details")
            {
                Caption = 'Sales Tax Details';
                Image = "Report";
                RunObject = Report "Sales Tax Detail List";
                ToolTip = 'View a complete or partial list of all sales tax details. For each jurisdiction, all tax groups with their tax types and effective dates are listed.';
            }
            action("Sales Tax Groups")
            {
                Caption = 'Sales Tax Groups';
                Image = "Report";
                RunObject = Report "Sales Tax Group List";
                ToolTip = 'View a complete or partial list of sales tax groups.';
            }
            action("Sales Tax Jurisdictions")
            {
                Caption = 'Sales Tax Jurisdictions';
                Image = "Report";
                RunObject = Report "Sales Tax Jurisdiction List";
                ToolTip = 'View a list of sales tax jurisdictions that you can use to identify tax authorities for sales and purchases tax calculations. This report shows the codes that are associated with a report-to jurisdiction area. Each sales tax area is assigned a tax account for sales and a tax account for purchases. These accounts define the sales tax rates for each sales tax jurisdiction.';
            }
            action("Sales Tax Areas")
            {
                Caption = 'Sales Tax Areas';
                Image = "Report";
                RunObject = Report "Sales Tax Area List";
                ToolTip = 'View a complete or partial list of sales tax areas.';
            }
            action("Sales Tax Detail by Area")
            {
                Caption = 'Sales Tax Detail by Area';
                Image = "Report";
                RunObject = Report "Sales Tax Detail by Area";
                ToolTip = 'Verify that each sales tax area is set up correctly. Each sales tax area includes all of its jurisdictions. For each jurisdiction, all tax groups are listed with their tax types and effective dates. Note that the same sales tax jurisdiction, along with all of its details, may appear more than once since the jurisdiction may be used in more than one area.';
            }
            action("Sales Taxes Collected")
            {
                Caption = 'Sales Taxes Collected';
                Image = "Report";
                RunObject = Report "Sales Taxes Collected";
                ToolTip = 'View a report that shows the sales taxes that have been collected on behalf of the authorities.';
            }
            action("VAT &Statement")
            {
                ApplicationArea = VAT;
                Caption = 'VAT &Statement';
                Image = "Report";
                RunObject = Report "VAT Statement";
                ToolTip = 'View a statement of posted VAT and calculate the duty liable to the customs authorities for the selected period.';
            }
            action("G/L - VAT Reconciliation")
            {
                ApplicationArea = VAT;
                Caption = 'G/L - VAT Reconciliation';
                Image = "Report";
                RunObject = Report "G/L - VAT Reconciliation";
                ToolTip = 'Verify that the VAT amounts on the VAT statements match the amounts from the G/L entries.';
            }
            action("VAT - VIES Declaration Tax Aut&h")
            {
                ApplicationArea = BasicEU;
                Caption = 'VAT - VIES Declaration Tax Aut&h';
                Image = "Report";
                RunObject = Report "VAT- VIES Declaration Tax Auth";
                ToolTip = 'View information to the customs and tax authorities for sales to other EU countries/regions. If the information must be printed to a file, you can use the VAT- VIES Declaration Disk report.';
            }
            action("VAT - VIES Declaration Dis&k")
            {
                ApplicationArea = BasicEU;
                Caption = 'VAT - VIES Declaration Dis&k';
                Image = "Report";
                RunObject = Report "VAT- VIES Declaration Disk";
                ToolTip = 'Report your sales to other EU countries or regions to the customs and tax authorities. If the information must be printed out on a printer, you can use the VAT- VIES Declaration Tax Auth report. The information is shown in the same format as in the declaration list from the customs and tax authorities.';
            }
            action("EC Sales &List")
            {
                ApplicationArea = BasicEU;
                Caption = 'EC Sales &List';
                Image = "Report";
                RunObject = Report "EC Sales List";
                ToolTip = 'Calculate VAT amounts from sales, and submit the amounts to a tax authority.';
            }
            separator(Action60)
            {
            }
#if not CLEAN22
            action("&Intrastat - Checklist")
            {
                ApplicationArea = BasicEU;
                Caption = '&Intrastat - Checklist';
                Image = "Report";
                RunObject = Report "Intrastat - Checklist";
                ToolTip = 'View a checklist that you can use to find possible errors before printing and also as documentation for what is printed. You can use the report to check the Intrastat journal before you use the Intrastat - Make Disk Tax Auth batch job.';
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';
                ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
            }
            action("Intrastat - For&m")
            {
                ApplicationArea = BasicEU;
                Caption = 'Intrastat - For&m';
                Image = "Report";
                RunObject = Report "Intrastat - Form";
                ToolTip = 'View all the information that must be transferred to the printed Intrastat form.';
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';
                ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
            }

            separator(Action4)
            {
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';
                ObsoleteReason = 'Action4 will be removed as part of the effort of moving Intrastat, use another anchor instead.';
            }
#endif
            action("Cost Accounting P/L Statement")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Accounting P/L Statement';
                Image = "Report";
                RunObject = Report "Cost Acctg. Statement";
                ToolTip = 'View the credit and debit balances per cost type, together with the chart of cost types.';
            }
            action("CA P/L Statement per Period")
            {
                ApplicationArea = CostAccounting;
                Caption = 'CA P/L Statement per Period';
                Image = "Report";
                RunObject = Report "Cost Acctg. Stmt. per Period";
                ToolTip = 'View profit and loss for cost types over two periods with the comparison as a percentage.';
            }
            action("CA P/L Statement with Budget")
            {
                ApplicationArea = CostAccounting;
                Caption = 'CA P/L Statement with Budget';
                Image = "Report";
                RunObject = Report "Cost Acctg. Statement/Budget";
                ToolTip = 'View a comparison of the balance to the budget figures and calculates the variance and the percent variance in the current accounting period, the accumulated accounting period, and the fiscal year.';
            }
            action("Cost Accounting Analysis")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Accounting Analysis';
                Image = "Report";
                RunObject = Report "Cost Acctg. Analysis";
                ToolTip = 'View balances per cost type with columns for seven fields for cost centers and cost objects. It is used as the cost distribution sheet in Cost accounting. The structure of the lines is based on the chart of cost types. You define up to seven cost centers and cost objects that appear as columns in the report.';
            }
            separator(Action1400022)
            {
            }
            action("Outstanding Purch. Order Aging")
            {
                Caption = 'Outstanding Purch. Order Aging';
                Image = "Report";
                RunObject = Report "Outstanding Purch. Order Aging";
                ToolTip = 'View vendor orders aged by their expected date. Only orders that have not been received appear on the report.';
            }
            action("Inventory Valuation")
            {
                Caption = 'Inventory Valuation';
                Image = "Report";
                RunObject = Report "Inventory Valuation";
                ToolTip = 'View, print, or save a list of the values of the on-hand quantity of each inventory item.';
            }
            action("Item Turnover")
            {
                Caption = 'Item Turnover';
                Image = "Report";
                RunObject = Report "Item Turnover";
                ToolTip = 'View a detailed account of item turnover by periods after you have set the relevant filters for location and variant.';
            }
        }
        area(embedding)
        {
            action(Action2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Chart of Accounts';
                RunObject = Page "Chart of Accounts";
                ToolTip = 'View the chart of accounts.';
            }
            action(Vendors)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendors';
                Image = Vendor;
                RunObject = Page "Vendor List";
                ToolTip = 'View or edit detailed information for the vendors that you trade with. From each vendor card, you can open related information, such as purchase statistics and ongoing orders, and you can define special prices and line discounts that the vendor grants you if certain conditions are met.';
            }
            action(VendorsBalance)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance';
                Image = Balance;
                RunObject = Page "Vendor List";
                RunPageView = where("Balance (LCY)" = filter(<> 0));
                ToolTip = 'View a summary of the bank account balance in different periods.';
            }
            action("Purchase Orders")
            {
                ApplicationArea = Suite;
                Caption = 'Purchase Orders';
                RunObject = Page "Purchase Order List";
                ToolTip = 'Create purchase orders to mirror sales documents that vendors send to you. This enables you to record the cost of purchases and to track accounts payable. Posting purchase orders dynamically updates inventory levels so that you can minimize inventory costs and provide better customer service. Purchase orders allow partial receipts, unlike with purchase invoices, and enable drop shipment directly from your vendor to your customer. Purchase orders can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature.';
            }
            action(Budgets)
            {
                ApplicationArea = Suite;
                Caption = 'Budgets';
                RunObject = Page "G/L Budget Names";
                ToolTip = 'View or edit estimated amounts for a range of accounting periods.';
            }
            action("Bank Accounts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Accounts';
                Image = BankAccount;
                RunObject = Page "Bank Account List";
                ToolTip = 'View or set up detailed information about your bank account, such as which currency to use, the format of bank files that you import and export as electronic payments, and the numbering of checks.';
            }
            action(BankDeposit)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Deposit';
                Image = DepositSlip;
                RunObject = codeunit "Open Deposits Page";
                ToolTip = 'Create a new bank deposit.';
            }
            action("VAT Statements")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'VAT Statements';
                RunObject = Page "VAT Statement Names";
                ToolTip = 'View a statement of posted VAT amounts, calculate your VAT settlement amount for a certain period, such as a quarter, and prepare to send the settlement to the tax authorities.';
            }
            action(Items)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Items';
                Image = Item;
                RunObject = Page "Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
            }
            action(Customers)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customers';
                Image = Customer;
                RunObject = Page "Customer List";
                ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
            }
            action(CustomersBalance)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance';
                Image = Balance;
                RunObject = Page "Customer List";
                RunPageView = where("Balance (LCY)" = filter(<> 0));
                ToolTip = 'View a summary of the bank account balance in different periods.';
            }
            action("Sales Orders")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Orders';
                Image = "Order";
                RunObject = Page "Sales Order List";
                ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
            }
            action(Reminders)
            {
                ApplicationArea = Suite;
                Caption = 'Reminders';
                Image = Reminder;
                RunObject = Page "Reminder List";
                ToolTip = 'Remind customers about overdue amounts based on reminder terms and the related reminder levels. Each reminder level includes rules about when the reminder will be issued in relation to the invoice due date or the date of the previous reminder and whether interests are added. Reminders are integrated with finance charge memos, which are documents informing customers of interests or other money penalties for payment delays.';
            }
            action("Finance Charge Memos")
            {
                ApplicationArea = Suite;
                Caption = 'Finance Charge Memos';
                Image = FinChargeMemo;
                RunObject = Page "Finance Charge Memo List";
                ToolTip = 'Send finance charge memos to customers with delayed payments, typically following a reminder process. Finance charges are calculated automatically and added to the overdue amounts on the customer''s account according to the specified finance charge terms and penalty/interest amounts.';
            }
            action("Incoming Documents")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Incoming Documents';
                Image = Documents;
                RunObject = Page "Incoming Documents";
                ToolTip = 'Handle incoming documents, such as vendor invoices in PDF or as image files, that you can manually or automatically convert to document records, such as purchase invoices. The external files that represent incoming documents can be attached at any process stage, including to posted documents and to the resulting vendor, customer, and general ledger entries.';
            }
            action("EC Sales List")
            {
                ApplicationArea = BasicEU;
                Caption = 'EC Sales List';
                RunObject = Page "EC Sales List Reports";
                ToolTip = 'Prepare the EC Sales List report so you can submit VAT amounts to a tax authority.';
            }
        }
        area(sections)
        {
            group(Journals)
            {
                Caption = 'Journals';
                Image = Journals;
                action(PurchaseJournals)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Journals';
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const(Purchases),
                                        Recurring = const(false));
                    ToolTip = 'Post any purchase-related transaction directly to a vendor, bank, or general ledger account instead of using dedicated documents. You can post all types of financial purchase transactions, including payments, refunds, and finance charge amounts. Note that you cannot post item quantities with a purchase journal.';
                }
                action(SalesJournals)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Journals';
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const(Sales),
                                        Recurring = const(false));
                    ToolTip = 'Post any sales-related transaction directly to a customer, bank, or general ledger account instead of using dedicated documents. You can post all types of financial sales transactions, including payments, refunds, and finance charge amounts. Note that you cannot post item quantities with a sales journal.';
                }
                action(CashReceiptJournals)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Receipt Journals';
                    Image = Journals;
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const("Cash Receipts"),
                                        Recurring = const(false));
                    ToolTip = 'Register received payments by manually applying them to the related customer, vendor, or bank ledger entries. Then, post the payments to G/L accounts and thereby close the related ledger entries.';
                }
                action(PaymentJournals)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Journals';
                    Image = Journals;
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const(Payments),
                                        Recurring = const(false));
                    ToolTip = 'Register payments to vendors. A payment journal is a type of general journal that is used to post outgoing payment transactions to G/L, bank, customer, vendor, employee, and fixed assets accounts. The Suggest Vendor Payments functions automatically fills the journal with payments that are due. When payments are posted, you can export the payments to a bank file for upload to your bank if your system is set up for electronic banking. You can also issue computer checks from the payment journal.';
                }
                action(ICGeneralJournals)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'IC General Journals';
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const(Intercompany),
                                        Recurring = const(false));
                    ToolTip = 'Post intercompany transactions. IC general journal lines must contain either an IC partner account or a customer or vendor account that has been assigned an intercompany partner code.';
                }
                action(GeneralJournals)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Journals';
                    Image = Journal;
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const(General),
                                        Recurring = const(false));
                    ToolTip = 'Post financial transactions directly to general ledger accounts and other accounts, such as bank, customer, vendor, and employee accounts. Posting with a general journal always creates entries on general ledger accounts. This is true even when, for example, you post a journal line to a customer account, because an entry is posted to a general ledger receivables account through a posting group.';
                }
#if not CLEAN22
                action("Intrastat Journals")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Intrastat Journals';
                    Image = "Report";
                    RunObject = Page "Intrastat Jnl. Batches";
                    ToolTip = 'Summarize the value of your purchases and sales with business partners in the EU for statistical purposes and prepare to send it to the relevant authority.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';
                    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
                }
#endif
            }
            group("Fixed Assets")
            {
                Caption = 'Fixed Assets';
                Image = FixedAssets;
                action(Action17)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets';
                    RunObject = Page "Fixed Asset List";
                    ToolTip = 'Manage periodic depreciation of your machinery or machines, keep track of your maintenance costs, manage insurance policies related to fixed assets, and monitor fixed asset statistics.';
                }
                action(Insurance)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Insurance';
                    RunObject = Page "Insurance List";
                    ToolTip = 'Manage insurance policies for fixed assets and monitor insurance coverage.';
                }
                action("Fixed Assets G/L Journals")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets G/L Journals';
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const(Assets),
                                        Recurring = const(false));
                    ToolTip = 'Post fixed asset transactions, such as acquisition and depreciation, in integration with the general ledger. The FA G/L Journal is a general journal, which is integrated into the general ledger.';
                }
                action("Fixed Assets Journals")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets Journals';
                    RunObject = Page "FA Journal Batches";
                    RunPageView = where(Recurring = const(false));
                    ToolTip = 'Post fixed asset transactions, such as acquisition and depreciation book without integration to the general ledger.';
                }
                action("Fixed Assets Reclass. Journals")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets Reclass. Journals';
                    RunObject = Page "FA Reclass. Journal Batches";
                    ToolTip = 'Transfer, split, or combine fixed assets by preparing reclassification entries to be posted in the fixed asset journal.';
                }
                action("Insurance Journals")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Insurance Journals';
                    RunObject = Page "Insurance Journal Batches";
                    ToolTip = 'Post entries to the insurance coverage ledger.';
                }
                action("<Action3>")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Recurring General Journals';
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const(General),
                                        Recurring = const(true));
                    ToolTip = 'Define how to post transactions that recur with few or no changes to general ledger, bank, customer, vendor, or fixed asset accounts';
                }
                action("Recurring Fixed Asset Journals")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Recurring Fixed Asset Journals';
                    RunObject = Page "FA Journal Batches";
                    RunPageView = where(Recurring = const(true));
                    ToolTip = 'Post recurring fixed asset transactions, such as acquisition and depreciation book without integration to the general ledger.';
                }
            }
            group("Cash Flow")
            {
                Caption = 'Cash Flow';
                action("Cash Flow Forecasts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Forecasts';
                    RunObject = Page "Cash Flow Forecast List";
                    ToolTip = 'Combine various financial data sources to find out when a cash surplus or deficit might happen or whether you should pay down debt, or borrow to meet upcoming expenses.';
                }
                action("Chart of Cash Flow Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Chart of Cash Flow Accounts';
                    RunObject = Page "Chart of Cash Flow Accounts";
                    ToolTip = 'View a chart contain a graphical representation of one or more cash flow accounts and one or more cash flow setups for the included general ledger, purchase, sales, services, or fixed assets accounts.';
                }
                action("Cash Flow Manual Revenues")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Manual Revenues';
                    RunObject = Page "Cash Flow Manual Revenues";
                    ToolTip = 'Record manual revenues, such as rental income, interest from financial assets, or new private capital to be used in cash flow forecasting.';
                }
                action("Cash Flow Manual Expenses")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Manual Expenses';
                    RunObject = Page "Cash Flow Manual Expenses";
                    ToolTip = 'Record manual expenses, such as salaries, interest on credit, or planned investments to be used in cash flow forecasting.';
                }
            }
            group("Cost Accounting")
            {
                Caption = 'Cost Accounting';
                action("Cost Types")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Types';
                    RunObject = Page "Chart of Cost Types";
                    ToolTip = 'View the chart of cost types with a structure and functionality that resembles the general ledger chart of accounts. You can transfer the general ledger income statement accounts or create your own chart of cost types.';
                }
                action("Cost Centers")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Centers';
                    RunObject = Page "Chart of Cost Centers";
                    ToolTip = 'Manage cost centers, which are departments and profit centers that are responsible for costs and income. Often, there are more cost centers set up in cost accounting than in any dimension that is set up in the general ledger. In the general ledger, usually only the first level cost centers for direct costs and the initial costs are used. In cost accounting, additional cost centers are created for additional allocation levels.';
                }
                action("Cost Objects")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Objects';
                    RunObject = Page "Chart of Cost Objects";
                    ToolTip = 'Set up cost objects, which are products, product groups, or services of a company. These are the finished goods of a company that carry the costs. You can link cost centers to departments and cost objects to projects in your company.';
                }
                action("Cost Allocations")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Allocations';
                    RunObject = Page "Cost Allocation Sources";
                    ToolTip = 'Manage allocation rules to allocate costs and revenues between cost types, cost centers, and cost objects. Each allocation consists of an allocation source and one or more allocation targets. For example, all costs for the cost type Electricity and Heating are an allocation source. You want to allocate the costs to the cost centers Workshop, Production, and Sales, which are three allocation targets.';
                }
                action("Cost Budgets")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Budgets';
                    RunObject = Page "Cost Budget Names";
                    ToolTip = 'Set up cost accounting budgets that are created based on cost types just as a budget for the general ledger is created based on general ledger accounts. A cost budget is created for a certain period of time, for example, a fiscal year. You can create as many cost budgets as needed. You can create a new cost budget manually, or by importing a cost budget, or by copying an existing cost budget as the budget base.';
                }
            }
            group("Posted Documents")
            {
                Caption = 'Posted Documents';
                Image = FiledPosted;
                action("Posted Sales Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Invoices';
                    Image = PostedOrder;
                    RunObject = Page "Posted Sales Invoices";
                    ToolTip = 'Open the list of posted sales invoices.';
                }
                action("Posted Sales Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Credit Memos';
                    Image = PostedOrder;
                    RunObject = Page "Posted Sales Credit Memos";
                    ToolTip = 'Open the list of posted sales credit memos.';
                }
                action("Posted Purchase Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Purchase Invoices';
                    RunObject = Page "Posted Purchase Invoices";
                    ToolTip = 'Open the list of posted purchase invoices.';
                }
                action("Posted Purchase Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Purchase Credit Memos';
                    RunObject = Page "Posted Purchase Credit Memos";
                    ToolTip = 'Open the list of posted purchase credit memos.';
                }
                action("Issued Reminders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Issued Reminders';
                    Image = OrderReminder;
                    RunObject = Page "Issued Reminder List";
                    ToolTip = 'View the list of issued reminders.';
                }
                action("Issued Fin. Charge Memos")
                {
                    ApplicationArea = Suite;
                    Caption = 'Issued Fin. Charge Memos';
                    Image = PostedMemo;
                    RunObject = Page "Issued Fin. Charge Memo List";
                    ToolTip = 'View the list of issued finance charge memos.';
                }
                action("G/L Registers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Registers';
                    Image = GLRegisters;
                    RunObject = Page "G/L Registers";
                    ToolTip = 'View posted G/L entries.';
                }
                action("Cost Accounting Registers")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Accounting Registers';
                    RunObject = Page "Cost Registers";
                    ToolTip = 'Get an overview of all cost entries sorted by posting date. ';
                }
                action("Cost Accounting Budget Registers")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Accounting Budget Registers';
                    RunObject = Page "Cost Budget Registers";
                    ToolTip = 'Get an overview of all cost budget entries sorted by posting date. ';
                }
                action("Posted Deposits")
                {
                    Caption = 'Posted Deposits';
                    Image = PostedDeposit;
                    RunObject = Page "Posted Deposit List";
                    ToolTip = 'View the posted deposit header, deposit header lines, deposit comments, and deposit dimensions.';
                }
                action("Posted Bank Deposits")
                {
                    Caption = 'Posted Bank Deposits';
                    Image = PostedDeposit;
                    RunObject = codeunit "Open P. Bank Deposits L. Page";
                    ToolTip = 'View the posted bank deposit header, bank deposit header lines, bank deposit comments, and bank deposit dimensions.';
                }
                action("Posted Bank Recs.")
                {
                    Caption = 'Posted Bank Recs.';
                    RunObject = Page "Posted Bank Rec. List";
                    ToolTip = 'View the entries and the balance on your bank accounts against a statement from the bank.';
                }
                action("Bank Statements")
                {
                    Caption = 'Bank Statements';
                    RunObject = Page "Bank Account Statement List";
                    ToolTip = 'View posted bank statements and reconciliations.';
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
                Image = Administration;
                action(Currencies)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currencies';
                    Image = Currency;
                    RunObject = Page Currencies;
                    ToolTip = 'View the different currencies that you trade in or update the exchange rates by getting the latest rates from an external service provider.';
                }
                action("Accounting Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Accounting Periods';
                    Image = AccountingPeriods;
                    RunObject = Page "Accounting Periods";
                    ToolTip = 'Set up the number of accounting periods, such as 12 monthly periods, within the fiscal year and specify which period is the start of the new fiscal year.';
                }
                action("Number Series")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Number Series';
                    RunObject = Page "No. Series";
                    ToolTip = 'View or edit the number series that are used to organize transactions';
                }
                action("Analysis Views")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Analysis Views';
                    RunObject = Page "Analysis View List";
                    ToolTip = 'Analyze amounts in your general ledger by their dimensions using analysis views that you have set up.';
                }
                action("Account Schedules")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Financial Reporting';
                    RunObject = Page "Financial Reports";
                    ToolTip = 'Get insight into the financial data stored in your chart of accounts. Financial reports analyze figures in G/L accounts, and compare general ledger entries with general ledger budget entries. For example, you can view the general ledger entries as percentages of the budget entries. Financial reports provide the data for core financial statements and views, such as the Cash Flow chart.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("Bank Account Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Posting Groups';
                    RunObject = Page "Bank Account Posting Groups";
                    ToolTip = 'Set up posting groups, so that payments in and out of each bank account are posted to the specified general ledger account.';
                }
                action("IRS 1099 Form-Box")
                {
                    ApplicationArea = BasicUS;
                    Caption = 'IRS 1099 Form-Box';
                    Image = "1099Form";
                    RunObject = Page "IRS 1099 Form-Box";
                    ToolTip = 'Set up 1099 tax forms to use on vendor cards, track posted amounts, and print or export 1099 information. After you have set up a 1099 code, you can enter it as a default 1099 form for a vendor.';
                }
                action("GIFI Codes")
                {
                    ApplicationArea = BasicCA;
                    Caption = 'GIFI Codes';
                    RunObject = Page "GIFI Codes";
                    ToolTip = 'View or edit the General Index of Financial Information (GIFI) codes that you use to collect, validate, and process financial tax information.';
                }
                action("Tax Areas")
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Tax Areas';
                    RunObject = Page "Tax Area List";
                    ToolTip = 'View a complete or partial list of sales tax areas.';
                }
                action("Tax Jurisdictions")
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Tax Jurisdictions';
                    RunObject = Page "Tax Jurisdictions";
                    ToolTip = 'View a list of sales tax jurisdictions that you can use to identify tax authorities for sales and purchases tax calculations. This report shows the codes that are associated with a report-to jurisdiction area. Each sales tax area is assigned a tax account for sales and a tax account for purchases. These accounts define the sales tax rates for each sales tax jurisdiction.';
                }
                action("Tax Groups")
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Tax Groups';
                    RunObject = Page "Tax Groups";
                    ToolTip = 'View a complete or partial list of sales tax groups.';
                }
                action("Tax Details")
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Tax Details';
                    RunObject = Page "Tax Details";
                    ToolTip = 'View a complete or partial list of all sales tax details. For each jurisdiction, all tax groups with their tax types and effective dates are listed.';
                }
                action("Tax  Business Posting Groups")
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Tax  Business Posting Groups';
                    RunObject = Page "VAT Business Posting Groups";
                    ToolTip = 'View or edit trade-type posting groups that you assign to customer and vendor cards to link tax amounts with the appropriate general ledger account.';
                }
                action("Tax Product Posting Groups")
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Tax Product Posting Groups';
                    RunObject = Page "VAT Product Posting Groups";
                    ToolTip = 'View or edit item-type posting groups that you assign to customer and vendor cards to link VAT amounts with the appropriate general ledger account.';
                }
            }
            group("Cash Management")
            {
                Caption = 'Cash Management';
                action(Action1400017)
                {
                    Caption = 'Bank Accounts';
                    Image = BankAccount;
                    RunObject = Page "Bank Account List";
                    ToolTip = 'View or set up your customers'' and vendors'' bank accounts. You can set up any number of bank accounts for each.';
                }
                action(Deposit)
                {
                    Caption = 'Bank Deposit';
                    Image = DepositSlip;
                    RunObject = codeunit "Open Deposits Page";
                    ToolTip = 'Create a new bank deposit.';
                }
                action("Bank Rec.")
                {
                    Caption = 'Bank Rec.';
                    RunObject = Page "Bank Acc. Reconciliation List";
                    ToolTip = 'View or set up your customers'' and vendors'' bank accounts. You can set up any number of bank accounts for each.';
                }
            }
        }
        area(creation)
        {
            action("Sales &Credit Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales &Credit Memo';
                Image = CreditMemo;
                RunObject = Page "Sales Credit Memo";
                RunPageMode = Create;
                ToolTip = 'Create a new sales credit memo to revert a posted sales invoice.';
            }
            action("P&urchase Credit Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'P&urchase Credit Memo';
                Image = CreditMemo;
                RunObject = Page "Purchase Credit Memo";
                RunPageMode = Create;
                ToolTip = 'Create a new purchase credit memo so you can manage returned items to a vendor.';
            }
            action("Bank Account Reconciliation")
            {
                Caption = 'Bank Account Reconciliation';
                Image = BankAccountRec;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Bank Acc. Reconciliation List";
                RunPageMode = Create;
                ToolTip = 'Reconcile bank transactions with bank account ledger entries to ensure that your bank account in Dynamics NAV reflects your actual liquidity.';
            }
        }
        area(processing)
        {
            separator(Tasks)
            {
                Caption = 'Tasks';
                IsHeader = true;
            }
            action("Cas&h Receipt Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cas&h Receipt Journal';
                Image = CashReceiptJournal;
                RunObject = Page "Cash Receipt Journal";
                ToolTip = 'Apply received payments to the related non-posted sales documents.';
            }
            action("Pa&yment Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Pa&yment Journal';
                Image = PaymentJournal;
                RunObject = Page "Payment Journal";
                ToolTip = 'Make payments to vendors.';
            }
            action("Purchase Journal")
            {
                Caption = 'Purchase Journal';
                Image = Journals;
                RunObject = Page "Purchase Journal";
                ToolTip = 'Open the list of purchase journals where you can batch post purchase transactions to G/L, bank, customer, vendor and fixed assets accounts.';
            }
            action(Action1480100)
            {
                Caption = 'Deposit';
                Image = DepositSlip;
                RunObject = codeunit "Open Deposit Page";
                ToolTip = 'Create a new deposit.';
            }
            separator(Action67)
            {
            }
            action("Analysis &Views")
            {
                ApplicationArea = Dimensions;
                Caption = 'Analysis &Views';
                Image = AnalysisView;
                RunObject = Page "Analysis View List";
                ToolTip = 'Analyze amounts in your general ledger by their dimensions using analysis views that you have set up.';
            }
            action("Analysis by &Dimensions")
            {
                ApplicationArea = Dimensions;
                Caption = 'Analysis by &Dimensions';
                Image = AnalysisViewDimension;
                RunObject = Page "Analysis by Dimensions";
                ToolTip = 'Analyze activities using dimensions information.';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'This functionality runs correctly from the Analysis View List page';
                ObsoleteTag = '18.0';
            }
            action("Calculate Deprec&iation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Calculate Deprec&iation';
                Ellipsis = true;
                Image = CalculateDepreciation;
                RunObject = Report "Calculate Depreciation";
                ToolTip = 'Calculate depreciation according to the conditions that you define. If the fixed assets that are included in the batch job are integrated with the general ledger (defined in the depreciation book that is used in the batch job), the resulting entries are transferred to the fixed assets general ledger journal. Otherwise, the batch job transfers the entries to the fixed asset journal. You can then post the journal or adjust the entries before posting, if necessary.';
            }
            action("Import Co&nsolidation from Database")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Co&nsolidation from Database';
                Ellipsis = true;
                Image = ImportDatabase;
                RunObject = Report "Import Consolidation from DB";
                ToolTip = 'Import entries from the business units that will be included in a consolidation. You can use the batch job if the business unit comes from the same database in Business Central as the consolidated company.';
            }
            action("Bank Account R&econciliation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account R&econciliation';
                Image = BankAccountRec;
                RunObject = Page "Bank Acc. Reconciliation List";
                ToolTip = 'View the entries and the balance on your bank accounts against a statement from the bank.';
            }
            action("Payment Reconciliation Journals")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Reconciliation Journals';
                Image = ApplyEntries;
                RunObject = Page "Pmt. Reconciliation Journals";
                RunPageMode = View;
                ToolTip = 'Reconcile unpaid documents automatically with their related bank transactions by importing a bank statement feed or file. In the payment reconciliation journal, incoming or outgoing payments on your bank are automatically, or semi-automatically, applied to their related open customer or vendor ledger entries. Any open bank account ledger entries related to the applied customer or vendor ledger entries will be closed when you choose the Post Payments and Reconcile Bank Account action. This means that the bank account is automatically reconciled for payments that you post with the journal.';
            }
            action("Adjust E&xchange Rates")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Adjust E&xchange Rates';
                Ellipsis = true;
                Image = AdjustExchangeRates;
                RunObject = Codeunit "Exch. Rate Adjmt. Run Handler";
                ToolTip = 'Adjust general ledger, customer, vendor, and bank account entries to reflect a more updated balance if the exchange rate has changed since the entries were posted.';
            }
            action("P&ost Inventory Cost to G/L")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'P&ost Inventory Cost to G/L';
                Image = PostInventoryToGL;
                RunObject = Report "Post Inventory Cost to G/L";
                ToolTip = 'Record the quantity and value changes to the inventory in the item ledger entries and the value entries when you post inventory transactions, such as sales shipments or purchase receipts.';
            }
            separator(Action97)
            {
            }
            action("C&reate Reminders")
            {
                ApplicationArea = Suite;
                Caption = 'C&reate Reminders';
                Ellipsis = true;
                Image = CreateReminders;
                RunObject = Report "Create Reminders";
                ToolTip = 'Create reminders for one or more customers with overdue payments.';
            }
            action("Create Finance Charge &Memos")
            {
                ApplicationArea = Suite;
                Caption = 'Create Finance Charge &Memos';
                Ellipsis = true;
                Image = CreateFinanceChargememo;
                RunObject = Report "Create Finance Charge Memos";
                ToolTip = 'Create finance charge memos for one or more customers with overdue payments.';
            }
            separator(Action73)
            {
            }
#if not CLEAN22
            action("Intrastat &Journal")
            {
                ApplicationArea = BasicEU;
                Caption = 'Intrastat &Journal';
                Image = Journal;
                RunObject = Page "Intrastat Jnl. Batches";
                ToolTip = 'Report your trade with other EU countries/regions for Intrastat reporting.';
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';
                ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
            }
#endif
            action("Calc. and Pos&t VAT Settlement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Calc. and Pos&t VAT Settlement';
                Image = SettleOpenTransactions;
                RunObject = Report "Calc. and Post VAT Settlement";
                ToolTip = 'Close open VAT entries and transfers purchase and sales VAT amounts to the VAT settlement account. For every VAT posting group, the batch job finds all the VAT entries in the VAT Entry table that are included in the filters in the definition window.';
            }
            separator(Action80)
            {
                Caption = 'Administration';
                IsHeader = true;
            }
            action("General &Ledger Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'General &Ledger Setup';
                Image = Setup;
                RunObject = Page "General Ledger Setup";
                ToolTip = 'Post financial transactions directly to general ledger accounts and other accounts, such as bank, customer, vendor, and employee accounts. Posting with a general journal always creates entries on general ledger accounts. This is true even when, for example, you post a journal line to a customer account, because an entry is posted to a general ledger receivables account through a posting group.';
            }
            action("&Sales && Receivables Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Sales && Receivables Setup';
                Image = Setup;
                RunObject = Page "Sales & Receivables Setup";
                ToolTip = 'Define your general policies for sales invoicing and returns, such as when to show credit and stockout warnings and how to post sales discounts. Set up your number series for creating customers and different sales documents.';
            }
            action("&Purchases && Payables Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Purchases && Payables Setup';
                Image = Setup;
                RunObject = Page "Purchases & Payables Setup";
                ToolTip = 'Define your general policies for purchase invoicing and returns, such as whether to require vendor invoice numbers and how to post purchase discounts. Set up your number series for creating vendors and different purchase documents.';
            }
            action("&Fixed Asset Setup")
            {
                ApplicationArea = FixedAssets;
                Caption = '&Fixed Asset Setup';
                Image = Setup;
                RunObject = Page "Fixed Asset Setup";
                ToolTip = 'Define your accounting policies for fixed assets, such as the allowed posting period and whether to allow posting to main assets. Set up your number series for creating new fixed assets.';
            }
            action("Cash Flow Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Flow Setup';
                Image = CashFlowSetup;
                RunObject = Page "Cash Flow Setup";
                ToolTip = 'Set up the accounts where cash flow figures for sales, purchase, and fixed-asset transactions are stored.';
            }
            action("Cost Accounting Setup")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Accounting Setup';
                Image = CostAccountingSetup;
                RunObject = Page "Cost Accounting Setup";
                ToolTip = 'Specify how you transfer general ledger entries to cost accounting, how you link dimensions to cost centers and cost objects, and how you handle the allocation ID and allocation document number.';
            }
            separator(History)
            {
                Caption = 'History';
                IsHeader = true;
            }
            action("Navi&gate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                RunObject = Page Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
            }
            action("Export GIFI Info. to Excel")
            {
                ApplicationArea = BasicCA;
                Caption = 'Export GIFI Info. to Excel';
                Image = ExportToExcel;
                RunObject = Report "Export GIFI Info. to Excel";
                ToolTip = 'Export balance information using General Index of Financial Information (GIFI) codes and save the exported file in Excel. You can use the file to transfer information to your tax preparation software.';
            }
        }
    }
}

