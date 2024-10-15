﻿namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Deposit;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Reports;
using Microsoft.Bank.Statement;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Costing;
#if not CLEAN22
using Microsoft.Inventory.Intrastat;
#endif
using Microsoft.Inventory.Reports;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;
using Microsoft.Foundation.Navigate;
using System.Automation;
using Microsoft.Foundation.Task;
using System.Threading;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Analysis;
using Microsoft.Sales.Reports;
using Microsoft.Purchases.Reports;

page 9004 "Bookkeeper Role Center"
{
    Caption = 'Bookkeeper';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
#if not CLEAN24
            group(Control1900724808)
            {
                ObsoleteReason = 'Group removed for better alignment of Role Centers parts';
                ObsoleteState = Pending;
                ObsoleteTag = '24.0';
                ShowCaption = false;
                part(Control1901197008; "Bookkeeper Activities")
                {
                    ApplicationArea = Basic, Suite;
                }
                part("User Tasks Activities"; "User Tasks Activities")
                {
                    ApplicationArea = Suite;
                }
                part(ApprovalsActivities; "Approvals Activities")
                {
                    ApplicationArea = Basic, Suite;
                }
                part(Control1907692008; "My Customers")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Control1900724708)
            {
                ObsoleteReason = 'Group removed for better alignment of Role Centers parts';
                ObsoleteState = Pending;
                ObsoleteTag = '24.0';
                ShowCaption = false;
                part(Control17; "My Job Queue")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                part(Control1902476008; "My Vendors")
                {
                    ApplicationArea = Basic, Suite;
                }
                part(Control18; "Report Inbox Part")
                {
                    ApplicationArea = Basic, Suite;
                }
                systempart(Control1901377608; MyNotes)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
#else
            part(Control1901197008; "Bookkeeper Activities")
            {
                ApplicationArea = Basic, Suite;
            }
            part("User Tasks Activities"; "User Tasks Activities")
            {
                ApplicationArea = Suite;
            }
            part(ApprovalsActivities; "Approvals Activities")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control1907692008; "My Customers")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control17; "My Job Queue")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
            part(Control1902476008; "My Vendors")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control18; "Report Inbox Part")
            {
                ApplicationArea = Basic, Suite;
            }
            systempart(Control1901377608; MyNotes)
            {
                ApplicationArea = Basic, Suite;
            }
#endif
        }
    }

    actions
    {
        area(reporting)
        {
            action("Chart of Accounts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Chart of Accounts';
                RunObject = Report "Chart of Accounts";
                ToolTip = 'Analyze figures in general ledger accounts or compare general ledger entries with general ledger budget entries. For example, you can view the G/L entries as percentages of the budget entries. You use the Account Schedule window to set up account schedules.';
            }
            action("G/L Register")
            {
                Caption = 'G/L Register';
                Image = GLRegisters;
                RunObject = Report "G/L Register";
                ToolTip = 'View posted journal entries sorted and divided by each register.';
            }
            group("&Trial Balance")
            {
                Caption = '&Trial Balance';
                Image = Balance;
                action("Trial Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Trial Balance';
                    Image = "Report";
                    RunObject = Report "Trial Balance";
                    ToolTip = 'View, print, or send a report that shows the balances for the general ledger accounts, including the debits and credits. You can use this report to ensure accurate accounting practices.';
                }
                action("Bank &Detail Trial Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank &Detail Trial Balance';
                    Image = "Report";
                    RunObject = Report "Bank Acc. - Detail Trial Bal.";
                    ToolTip = 'View transactions for all bank accounts with subtotals per account. Each account shows the opening balance on the first line, the list of transactions for the account and a closing balance on the last line.';
                }
                action("T&rial Balance/Budget")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'T&rial Balance/Budget';
                    Image = "Report";
                    RunObject = Report "Trial Balance/Budget";
                    ToolTip = 'View a trial balance in comparison to a budget. You can choose to see a trial balance for selected dimensions. You can use the report at the close of an accounting period or fiscal year.';
                }
                action("Trial Balance by &Period")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Trial Balance by &Period';
                    Image = "Report";
                    RunObject = Report "Trial Balance by Period";
                    ToolTip = 'Show the opening balance by general ledger account, the movements in the selected period of month, quarter, or year, and the resulting closing balance.';
                }
                action("Trial Balance, Spread Periods")
                {
                    Caption = 'Trial Balance, Spread Periods';
                    Image = "Report";
                    RunObject = Report "Trial Balance, Spread Periods";
                    ToolTip = 'View a trial balance with amounts shown in separate columns for each time period.';
                }
                action("Closing Trial Balance")
                {
                    Caption = 'Closing Trial Balance';
                    Image = "Report";
                    RunObject = Report "Closing Trial Balance";
                    ToolTip = 'View this year''s and last year''s figures as an ordinary trial balance.';
                }
                action("Consol. Trial Balance")
                {
                    Caption = 'Consol. Trial Balance';
                    Image = "Report";
                    RunObject = Report "Consolidated Trial Balance";
                    ToolTip = 'View the trial balance for a consolidated company.';
                }
                action("Trial Balance Detail/Summary")
                {
                    Caption = 'Trial Balance Detail/Summary';
                    Image = "Report";
                    RunObject = Report "Trial Balance Detail/Summary";
                    ToolTip = 'View general ledger account balances and activities for all the selected accounts, one transaction per line. You can include general ledger accounts which have a balance and including the closing entries within the period.';
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
            }
            action("&Fiscal Year Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Fiscal Year Balance';
                Image = "Report";
                RunObject = Report "Fiscal Year Balance";
                ToolTip = 'View, print, or send a report that shows balance sheet movements for selected periods. The report shows the closing balance by the end of the previous fiscal year for the selected ledger accounts. It also shows the fiscal year until this date, the fiscal year by the end of the selected period, and the balance by the end of the selected period, excluding the closing entries. The report can be used at the close of an accounting period or fiscal year.';
            }
            action("Balance C&omp. . Prev. Year")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance C&omp. . Prev. Year';
                Image = "Report";
                RunObject = Report "Balance Comp. - Prev. Year";
                ToolTip = 'View a report that shows your company''s assets, liabilities, and equity compared to the previous year.';
            }
            separator(Action44)
            {
            }
            action("Account Schedule Layout")
            {
                Caption = 'Account Schedule Layout';
                Image = "Report";
                RunObject = Report "Account Schedule Layout";
                ToolTip = 'Adjust the layout of the account schedule.';
            }
            action("Account Schedule")
            {
                Caption = 'Account Schedule';
                Image = "Report";
                RunObject = Report "Account Schedule";
                ToolTip = 'Set up the account schedule to analyze figures in general ledger accounts.';
            }
            action("Account Balances by GIFI Code")
            {
                Caption = 'Account Balances by GIFI Code';
                Image = "Report";
                RunObject = Report "Account Balances by GIFI Code";
                ToolTip = 'Review your account balances by General Index of Financial Information (GIFI) codes.';
            }
            separator(Action49)
            {
            }
            action("Aged Accounts Receivable")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Aged Accounts Receivable';
                Image = "Report";
                RunObject = Report "Aged Accounts Receivable NA";
                ToolTip = 'View overdue customer payments.';
            }
            action("Aged Accou&nts Payable")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Aged Accou&nts Payable';
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
            action("Bank Account - Reconcile")
            {
                Caption = 'Bank Account - Reconcile';
                Image = "Report";
                RunObject = Report "Bank Account - Reconcile";
                ToolTip = 'Reconcile bank transactions with bank account ledger entries to ensure that your bank account in Dynamics NAV reflects your actual liquidity.';
            }
            action("Reconcile Customer and &Vendor Accounts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reconcile Customer and &Vendor Accounts';
                Image = "Report";
                RunObject = Report "Reconcile Cust. and Vend. Accs";
                ToolTip = 'View if a certain general ledger account reconciles the balance on a certain date for the corresponding posting group. The report shows the accounts that are included in the reconciliation with the general ledger balance and the customer or the vendor ledger balance for each account and shows any differences between the general ledger balance and the customer or vendor ledger balance.';
            }
            separator(Action53)
            {
            }
            action("G/L - VAT Reconciliation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L - VAT Reconciliation';
                Image = "Report";
                RunObject = Report "G/L - VAT Reconciliation";
                ToolTip = 'Verify that the VAT amounts on the VAT statements match the amounts from the G/L entries.';
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
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Taxes Collected';
                Image = "Report";
                RunObject = Report "Sales Taxes Collected";
                ToolTip = 'Use an EU VAT number validation service to validated the VAT number of a business partner.';
            }
            separator(Action1400017)
            {
            }
            action("Inventory Valuation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Inventory Valuation';
                Image = "Report";
                RunObject = Report "Inventory Valuation";
                ToolTip = 'View information to the customs and tax authorities for sales to other EU countries/regions. If the information must be printed to a file, you can use the VAT- VIES Declaration Disk report.';
            }
        }
        area(embedding)
        {
            ToolTip = 'Collect and make payments, prepare statements, and manage reminders.';
            action(Action2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Chart of Accounts';
                RunObject = Page "Chart of Accounts";
                ToolTip = 'View the chart of accounts.';
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
            action(VendorsPaymentonHold)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment on Hold';
                RunObject = Page "Vendor List";
                RunPageView = where(Blocked = filter(Payment));
                ToolTip = 'View a list of all vendor ledger entries on which the On Hold field is marked.';
            }
            action("VAT Statements")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'VAT Statements';
                RunObject = Page "VAT Statement Names";
                ToolTip = 'View a statement of posted VAT amounts, calculate your VAT settlement amount for a certain period, such as a quarter, and prepare to send the settlement to the tax authorities.';
            }
            action("Purchase Invoices")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Invoices';
                RunObject = Page "Purchase Invoices";
                ToolTip = 'Create purchase invoices to mirror sales documents that vendors send to you. This enables you to record the cost of purchases and to track accounts payable. Posting purchase invoices dynamically updates inventory levels so that you can minimize inventory costs and provide better customer service. Purchase invoices can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature.';
            }
            action("Purchase Orders")
            {
                ApplicationArea = Suite;
                Caption = 'Purchase Orders';
                RunObject = Page "Purchase Order List";
                ToolTip = 'Create purchase orders to mirror sales documents that vendors send to you. This enables you to record the cost of purchases and to track accounts payable. Posting purchase orders dynamically updates inventory levels so that you can minimize inventory costs and provide better customer service. Purchase orders allow partial receipts, unlike with purchase invoices, and enable drop shipment directly from your vendor to your customer. Purchase orders can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature.';
            }
            action("Sales Invoices")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Invoices';
                Image = Invoice;
                RunObject = Page "Sales Invoice List";
                ToolTip = 'Register your sales to customers and invite them to pay according to the delivery and payment terms by sending them a sales invoice document. Posting a sales invoice registers shipment and records an open receivable entry on the customer''s account, which will be closed when payment is received. To manage the shipment process, use sales orders, in which sales invoicing is integrated.';
            }
            action("Sales Orders")
            {
                ApplicationArea = Suite;
                Caption = 'Sales Orders';
                Image = "Order";
                RunObject = Page "Sales Order List";
                ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
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
            action(RecurringGeneralJournals)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recurring General Journals';
                RunObject = Page "General Journal Batches";
                RunPageView = where("Template Type" = const(General),
                                    Recurring = const(true));
                ToolTip = 'Define how to post transactions that recur with few or no changes to general ledger, bank, customer, vendor, or fixed asset accounts';
            }
#if not CLEAN22
            action("Intrastat Journals")
            {
                ApplicationArea = BasicEU;
                Caption = 'Intrastat Journals';
                RunObject = Page "Intrastat Jnl. Batches";
                ToolTip = 'Summarize the value of your purchases and sales with business partners in the EU for statistical purposes and prepare to send it to the relevant authority.';
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';
                ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
            }
#endif
        }
        area(sections)
        {
            group("Posted Documents")
            {
                Caption = 'Posted Documents';
                Image = FiledPosted;
                ToolTip = 'View posted invoices and credit memos, and analyze G/L registers.';
                action("Posted Sales Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Shipments';
                    Image = PostedShipment;
                    RunObject = Page "Posted Sales Shipments";
                    ToolTip = 'Open the list of posted sales shipments.';
                }
                action("Posted Sales Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Invoices';
                    Image = PostedOrder;
                    RunObject = Page "Posted Sales Invoices";
                    ToolTip = 'Open the list of posted sales invoices.';
                }
                action("Posted Return Receipts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Return Receipts';
                    Image = PostedReturnReceipt;
                    RunObject = Page "Posted Return Receipts";
                    ToolTip = 'Open the list of posted return receipts.';
                }
                action("Posted Sales Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Credit Memos';
                    Image = PostedOrder;
                    RunObject = Page "Posted Sales Credit Memos";
                    ToolTip = 'Open the list of posted sales credit memos.';
                }
                action("Posted Purchase Receipts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Purchase Receipts';
                    RunObject = Page "Posted Purchase Receipts";
                    ToolTip = 'Open the list of posted purchase receipts.';
                }
                action("Posted Purchase Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Purchase Invoices';
                    RunObject = Page "Posted Purchase Invoices";
                    ToolTip = 'Open the list of posted purchase invoices.';
                }
                action("Posted Return Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Return Shipments';
                    RunObject = Page "Posted Return Shipments";
                    ToolTip = 'Open the list of posted return shipments.';
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
                action("Issued Fi. Charge Memos")
                {
                    ApplicationArea = Suite;
                    Caption = 'Issued Fi. Charge Memos';
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
                action("Posted Deposit List")
                {
                    Caption = 'Posted Deposit List';
                    RunObject = Page "Posted Deposit List";
                    ToolTip = 'View the posted deposit header, deposit header lines, deposit comments, and deposit dimensions.';
                }
                action("Posted Bank Deposit List")
                {
                    Caption = 'Posted Bank Deposit List';
                    RunObject = codeunit "Open P. Bank Deposits L. Page";
                    ToolTip = 'View the posted bank deposit header, bank deposit header lines, bank deposit comments, and bank deposit dimensions.';
                }
                action("Posted Bank Rec. List")
                {
                    Caption = 'Posted Bank Rec. List';
                    RunObject = Page "Posted Bank Rec. List";
                    ToolTip = 'View a list of the posted bank reconciliations (statements).';
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
#if not CLEAN25
                action("IRS 1099 Form-Box")
                {
                    Caption = 'IRS 1099 Form-Box';
                    Image = "1099Form";
                    RunObject = Page "IRS 1099 Form-Box";
                    ToolTip = 'Set up 1099 tax forms to use on vendor cards, track posted amounts, and print or export 1099 information. After you have set up a 1099 code, you can enter it as a default 1099 form for a vendor.';
                    ObsoleteReason = 'Moved to IRS Forms App.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';
                }
#endif
                action("GIFI Codes")
                {
                    Caption = 'GIFI Codes';
                    RunObject = Page "GIFI Codes";
                    ToolTip = 'View or edit the General Index of Financial Information (GIFI) codes that you use to collect, validate, and process financial tax information.';
                }
                action("Tax Areas")
                {
                    Caption = 'Tax Areas';
                    RunObject = Page "Tax Area List";
                    ToolTip = 'View a complete or partial list of sales tax areas.';
                }
                action("Tax Jurisdictions")
                {
                    Caption = 'Tax Jurisdictions';
                    RunObject = Page "Tax Jurisdictions";
                    ToolTip = 'View a list of sales tax jurisdictions that you can use to identify tax authorities for sales and purchases tax calculations. This report shows the codes that are associated with a report-to jurisdiction area. Each sales tax area is assigned a tax account for sales and a tax account for purchases. These accounts define the sales tax rates for each sales tax jurisdiction.';
                }
                action("Tax Groups")
                {
                    Caption = 'Tax Groups';
                    RunObject = Page "Tax Groups";
                    ToolTip = 'View a complete or partial list of sales tax groups.';
                }
                action("Tax Details")
                {
                    Caption = 'Tax Details';
                    RunObject = Page "Tax Details";
                    ToolTip = 'View a complete or partial list of all sales tax details. For each jurisdiction, all tax groups with their tax types and effective dates are listed.';
                }
                action("Tax  Business Posting Groups")
                {
                    Caption = 'Tax  Business Posting Groups';
                    RunObject = Page "VAT Business Posting Groups";
                    ToolTip = 'View or edit trade-type posting groups that you assign to customer and vendor cards to link tax amounts with the appropriate general ledger account.';
                }
                action("Tax Product Posting Groups")
                {
                    Caption = 'Tax Product Posting Groups';
                    RunObject = Page "VAT Product Posting Groups";
                    ToolTip = 'View or edit item-type posting groups that you assign to customer and vendor cards to link VAT amounts with the appropriate general ledger account.';
                }
            }
            group("Cash Management")
            {
                Caption = 'Cash Management';
                action(Action1400001)
                {
                    Caption = 'Bank Accounts';
                    Image = BankAccount;
                    RunObject = Page "Bank Account List";
                    ToolTip = 'View or set up your customers'' and vendors'' bank accounts. You can set up any number of bank accounts for each.';
                }
                action(Deposit)
                {
                    Caption = 'Deposit';
                    Image = DepositSlip;
                    RunObject = codeunit "Open Deposits Page";
                    ToolTip = 'Create a new deposit. ';
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
            action("C&ustomer")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'C&ustomer';
                Image = Customer;
                RunObject = Page "Customer Card";
                RunPageMode = Create;
                ToolTip = 'Create a new customer card.';
            }
            action("Sales &Invoice")
            {
                Caption = 'Sales &Invoice';
                Image = NewSalesInvoice;
                RunObject = Page "Sales Invoice";
                RunPageMode = Create;
                ToolTip = 'Create a new invoice for the sales of items or services. Invoice quantities cannot be posted partially.';
            }
            action("Sales Credit &Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Credit &Memo';
                Image = CreditMemo;
                RunObject = Page "Sales Credit Memo";
                RunPageMode = Create;
                ToolTip = 'Create a new sales credit memo to revert a posted sales invoice.';
            }
            action("Sales &Fin. Charge Memo")
            {
                ApplicationArea = Suite;
                Caption = 'Sales &Fin. Charge Memo';
                Image = FinChargeMemo;
                RunObject = Page "Finance Charge Memo";
                RunPageMode = Create;
                ToolTip = 'Create a new finance charge memo to fine a customer for late payment.';
            }
            action("Sales &Reminder")
            {
                ApplicationArea = Suite;
                Caption = 'Sales &Reminder';
                Image = Reminder;
                RunObject = Page Reminder;
                RunPageMode = Create;
                ToolTip = 'Create a new reminder for a customer who has overdue payments.';
            }
            separator(Action554)
            {
            }
            action("&Vendor")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Vendor';
                Image = Vendor;
                RunObject = Page "Vendor Card";
                RunPageMode = Create;
                ToolTip = 'Set up a new vendor from whom you buy goods or services. ';
            }
            action("&Purchase Invoice")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Purchase Invoice';
                Image = NewPurchaseInvoice;
                RunObject = Page "Purchase Invoice";
                RunPageMode = Create;
                ToolTip = 'Create new purchase invoice.';
            }
        }
        area(processing)
        {
            separator(Tasks)
            {
                Caption = 'Tasks';
                IsHeader = true;
            }
            action("Cash Re&ceipt Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Re&ceipt Journal';
                Image = CashReceiptJournal;
                RunObject = Page "Cash Receipt Journal";
                ToolTip = 'Open the cash receipt journal to post incoming payments.';
            }
            action("Payment &Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment &Journal';
                Image = PaymentJournal;
                RunObject = Page "Payment Journal";
                ToolTip = 'View or edit the payment journal where you can register payments to vendors.';
            }
            separator(Action77)
            {
            }
            action("Bank Account Reconciliations")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account Reconciliations';
                Image = BankAccountRec;
                RunObject = Page "Bank Acc. Reconciliation List";
                ToolTip = 'Reconcile entries in your bank account ledger entries with the actual transactions in your bank account, according to the latest bank statement.';
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
            action("Reconcile AP to GL")
            {
                Caption = 'Reconcile AP to GL';
                Image = "Report";
                RunObject = Report "Reconcile AP to GL";
                ToolTip = 'List all items that have been received on purchase orders, but for which you have not been invoiced. The value of these items is not reflected in the general ledger because the cost is unknown until they are invoiced. The report gives an estimated value of the purchase orders, you can use as an accrual to your general ledger.';
            }
            action("Post Inventor&y Cost to G/L")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Post Inventor&y Cost to G/L';
                Ellipsis = true;
                Image = PostInventoryToGL;
                RunObject = Report "Post Inventory Cost to G/L";
                ToolTip = 'Post the quantity and value changes to the inventory in the item ledger entries and the value entries when you post inventory transactions, such as sales shipments or purchase receipts.';
            }
            action("Calc. and Pos&t VAT Settlement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Calc. and Pos&t VAT Settlement';
                Ellipsis = true;
                Image = SettleOpenTransactions;
                RunObject = Report "Calc. and Post VAT Settlement";
                ToolTip = 'Close open VAT entries and transfers purchase and sales VAT amounts to the VAT settlement account. For every VAT posting group, the batch job finds all the VAT entries in the VAT Entry table that are included in the filters in the definition window.';
            }
            separator(Action84)
            {
                Caption = 'Administration';
                IsHeader = true;
            }
            action("General Ledger Setup")
            {
                Caption = 'General Ledger Setup';
                Image = Setup;
                RunObject = Page "General Ledger Setup";
                ToolTip = 'Define your general accounting policies, such as the allowed posting period and how payments are processed. Set up your default dimensions for financial analysis.';
            }
            action("Sa&les && Receivables Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sa&les && Receivables Setup';
                Image = Setup;
                RunObject = Page "Sales & Receivables Setup";
                ToolTip = 'Define your general policies for sales invoicing and returns, such as when to show credit and stockout warnings and how to post sales discounts. Set up your number series for creating customers and different sales documents.';
            }
            action("Inventory to G/L Reconcile")
            {
                ApplicationArea = Suite;
                Caption = 'Inventory to G/L Reconcile';
                RunObject = Report "Inventory to G/L Reconcile";
                ToolTip = 'Calculate VAT amounts from sales, and submit the amounts to a tax authority.';
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
                ApplicationArea = Basic, Suite;
                Caption = 'Export GIFI Info. to Excel';
                RunObject = Report "Export GIFI Info. to Excel";
                ToolTip = 'Report your sales to other EU countries or regions to the customs and tax authorities. If the information must be printed out on a printer, you can use the VAT- VIES Declaration Tax Auth report. The information is shown in the same format as in the declaration list from the customs and tax authorities.';
            }
            action(Approvals)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Approvals';
                Image = Approvals;
                RunObject = Page "Requests to Approve";
                ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';
            }
            action("Sales Order Shipment")
            {
                Caption = 'Sales Order Shipment';
                RunObject = Page "Sales Order Shipment List";
                ToolTip = 'View or edit sales order shipments, reopen a shipment, post a shipment, print a test report, or post and print a shipment.';
            }
            action("Sales Order Invoice")
            {
                Caption = 'Sales Order Invoice';
                RunObject = Page "Sales Order Invoice List";
                ToolTip = 'Create a sales order invoices, for example to calculate invoice discounts or reopen an invoice.';
            }
            group(Action22)
            {
                Caption = 'Approvals';
                ToolTip = 'Request approval of your documents, cards, or journal lines or, as the approver, approve requests made by other users.';
                action("Requests Sent for Approval")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Requests Sent for Approval';
                    Image = Approvals;
                    RunObject = Page "Approval Entries";
                    RunPageView = where(Status = filter(Open));
                    ToolTip = 'View the approval requests that you have sent.';
                }
                action(RequestsToApprove)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Requests to Approve';
                    Image = Approvals;
                    RunObject = Page "Requests to Approve";
                    ToolTip = 'Accept or reject other users'' requests to create or change certain documents, cards, or journal lines that you must approve before they can proceed. The list is filtered to requests where you are set up as the approver.';
                }
            }
            action("Payment Registration")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Registration';
                Image = Payment;
                RunObject = Page "Payment Registration";
                ToolTip = 'Apply customer payments observed on your bank account to non-posted sales documents to record that payment is made.';
            }
            action("Payment Reconciliation Journals")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Reconciliation Journals';
                Image = ApplyEntries;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Pmt. Reconciliation Journals";
                RunPageMode = View;
                ToolTip = 'Reconcile unpaid documents automatically with their related bank transactions by importing a bank statement feed or file. In the payment reconciliation journal, incoming or outgoing payments on your bank are automatically, or semi-automatically, applied to their related open customer or vendor ledger entries. Any open bank account ledger entries related to the applied customer or vendor ledger entries will be closed when you choose the Post Payments and Reconcile Bank Account action. This means that the bank account is automatically reconciled for payments that you post with the journal.';
            }
        }
    }
}

