page 8901 "Finance Manager Role Center"
{
    Caption = 'Finance Manager Role Center';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'General Ledger';
                action("Chart of Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Chart of Accounts';
                    RunObject = Page "Chart of Accounts";
                }
                action("Budgets")
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Budgets';
                    RunObject = Page "G/L Budget Names";
                }
                action("Account Schedules")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Schedules';
                    RunObject = Page "Account Schedule Names";
                }
                action("Analyses by Dimensions")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Analysis by Dimensions';
                    RunObject = Page "Analysis View List";
                }
                group("Group1")
                {
                    Caption = 'VAT';
                    action("VAT Statements")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Statements';
                        RunObject = Page "VAT Statement";
                    }
                    action("VAT Returns")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Returns';
                        RunObject = Page "VAT Report List";
                    }
                    action("ECSL Report")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'EC Sales List Reports';
                        RunObject = Page "EC Sales List Reports";
                    }
                    group("Group2")
                    {
                        Caption = 'Reports';
                        action("VAT Exceptions")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT Exceptions';
                            RunObject = Report "VAT Exceptions";
                        }
                        action("VAT Reconciliation")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT Reconciliation';
                            RunObject = Report "VAT Reconciliation";
                        }
                        action("VAT Register")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT Register';
                            RunObject = Report "VAT Register";
                        }
                        action("VAT Registration No. Check")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Batch VAT Registration No. Check';
                            RunObject = Report "VAT Registration No. Check";
                        }
                        action("VAT Statement")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT Statement';
                            RunObject = Report "VAT Statement";
                        }
                        action("VAT- VIES Declaration Tax Auth")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT- VIES Declaration Tax Auth';
                            RunObject = Report "VAT- VIES Declaration Tax Auth";
                        }
                        action("VAT- VIES Declaration Disk")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT- VIES Declaration Disk...';
                            RunObject = Report "VAT- VIES Declaration Disk";
                        }
                        action("Day Book VAT Entry")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Day Book VAT Entry';
                            RunObject = Report "Day Book VAT Entry";
                        }
                        action("Day Book Cust. Ledger Entry")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Day Book Cust. Ledger Entry';
                            RunObject = Report "Day Book Cust. Ledger Entry";
                        }
                        action("Day Book Vendor Ledger Entry")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Day Book Vendor Ledger Entry';
                            RunObject = Report "Day Book Vendor Ledger Entry";
                        }
                    }
                }
                group("Group3")
                {
                    Caption = 'Intercompany';
                    action("General Journals")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Intercompany General Journal';
                        RunObject = Page "IC General Journal";
                    }
                    action("Inbox Transactions")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Intercompany Inbox Transactions';
                        RunObject = Page "IC Inbox Transactions";
                    }
                    action("Outbox Transactions")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Intercompany Outbox Transactions';
                        RunObject = Page "IC Outbox Transactions";
                    }
                    action("Handled Inbox Transactions")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Handled Intercompany Inbox Transactions';
                        RunObject = Page "Handled IC Inbox Transactions";
                    }
                    action("Handled Outbox Transactions")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Handled Intercompany Outbox Transactions';
                        RunObject = Page "Handled IC Outbox Transactions";
                    }
                    action("Intercompany Transactions")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'IC Transaction';
                        RunObject = Report "IC Transactions";
                    }
                }
                group("Group4")
                {
                    Caption = 'Consolidation';
                    action("Business Units")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Business Units';
                        RunObject = Page "Business Unit List";
                    }
                    action("Export Consolidation")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Export Consolidation...';
                        RunObject = Report "Export Consolidation";
                    }
                    action("G/L Consolidation Eliminations")
                    {
                        ApplicationArea = Suite;
                        Caption = 'G/L Consolidation Eliminations';
                        RunObject = Report "G/L Consolidation Eliminations";
                    }
                }
                group("Group5")
                {
                    Caption = 'Journals';
                    action("General Journals1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'General Journals';
                        RunObject = Page "General Journal";
                    }
                    action("Recurring Journals")
                    {
                        ApplicationArea = Suite, FixedAssets;
                        Caption = 'Recurring General Journals';
                        RunObject = Page "Recurring General Journal";
                    }
                    action("Intrastat Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Intrastat Journals';
                        RunObject = Page "Intrastat Journal";
                    }
                    action("General Journals2")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Intercompany General Journal';
                        RunObject = Page "IC General Journal";
                    }
                }
                group("Group6")
                {
                    Caption = 'Register/Entries';
                    action("G/L Registers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Registers';
                        RunObject = Page "G/L Registers";
                    }
                    action("Navigate")
                    {
                        ApplicationArea = Basic, Suite, FixedAssets, CostAccounting;
                        Caption = 'Navigate';
                        RunObject = Page "Navigate";
                    }
                    action("General Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'General Ledger Entries';
                        RunObject = Page "General Ledger Entries";
                    }
                    action("G/L Budget Entries")
                    {
                        ApplicationArea = Suite;
                        Caption = 'G/L Budget Entries';
                        RunObject = Page "G/L Budget Entries";
                    }
                    action("VAT Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Entries';
                        RunObject = Page "VAT Entries";
                    }
                    action("Analysis View Entries")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Analysis View Entries';
                        RunObject = Page "Analysis View Entries";
                    }
                    action("Analysis View Budget Entries")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Analysis View Budget Entries';
                        RunObject = Page "Analysis View Budget Entries";
                    }
                    action("Item Budget Entries")
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Item Budget Entries';
                        RunObject = Page "Item Budget Entries";
                    }
                }
                group("Group7")
                {
                    Caption = 'Reports';
                    group("Group8")
                    {
                        Caption = 'Entries';
                        action("G/L Register")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'G/L Register';
                            RunObject = Report "G/L Register";
                        }
                        action("Detail Trial Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Detail Trial Balance';
                            RunObject = Report "Detail Trial Balance";
                        }
                        action("Dimensions - Detail")
                        {
                            ApplicationArea = Dimensions;
                            Caption = 'Dimensions - Detail';
                            RunObject = Report "Dimensions - Detail";
                        }
                        action("Dimensions - Total")
                        {
                            ApplicationArea = Dimensions;
                            Caption = 'Dimensions - Total';
                            RunObject = Report "Dimensions - Total";
                        }
                        action("Check Value Posting")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Dimension Check Value Posting';
                            RunObject = Report "Check Value Posting";
                        }
                    }
                    group("Group9")
                    {
                        Caption = 'Financial Statement';
                        action("Account Schedule")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Account Schedule';
                            RunObject = Report "Account Schedule";
                        }
                        action("Trial Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Trial Balance';
                            RunObject = Report "Trial Balance";
                        }
                        action("Trial Balance/Budget")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Trial Balance/Budget';
                            RunObject = Report "Trial Balance/Budget";
                        }
                        action("Trial Balance/Previous Year")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Trial Balance/Previous Year';
                            RunObject = Report "Trial Balance/Previous Year";
                        }
                        action("Closing Trial Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Closing Trial Balance';
                            RunObject = Report "Closing Trial Balance";
                        }
                        action("Consolidated Trial Balance")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Consolidated Trial Balance';
                            RunObject = Report "Consolidated Trial Balance";
                        }
                        action("Consolidated Trial Balance (4)")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Consolidated Trial Balance (4)';
                            RunObject = Report "Consolidated Trial Balance (4)";
                        }
                        action("Budget")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Budget';
                            RunObject = Report "Budget";
                        }
                        action("Trial Balance by Period")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Trial Balance by Period';
                            RunObject = Report "Trial Balance by Period";
                        }
                        action("Fiscal Year Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Fiscal Year Balance';
                            RunObject = Report "Fiscal Year Balance";
                        }
                        action("Balance Comp. - Prev. Year")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Balance Comp. - Prev. Year';
                            RunObject = Report "Balance Comp. - Prev. Year";
                        }
                        action("Balance Sheet")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Balance Sheet';
                            RunObject = Codeunit "Run Acc. Sched. Balance Sheet";
                            AccessByPermission = TableData 15 = R;
                        }
                        action("Income Statement")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Income Statement';
                            RunObject = Codeunit "Run Acc. Sched. Income Stmt.";
                            AccessByPermission = TableData 15 = R;
                        }
                        action("Statement of Cashflows")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Cash Flow Statement';
                            RunObject = Codeunit "Run Acc. Sched. CashFlow Stmt.";
                            AccessByPermission = TableData 15 = R;
                        }
                        action("Statement of Retained Earnings")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Retained Earnings Statement';
                            RunObject = Codeunit "Run Acc. Sched. Retained Earn.";
                            AccessByPermission = TableData 15 = R;
                        }
                    }
                    group("Group10")
                    {
                        Caption = 'Miscellaneous';
                        action("Intrastat - Checklist")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Intrastat - Checklist';
                            RunObject = Report "Intrastat - Checklist";
                        }
                        action("Intrastat - Form")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Intrastat - Form';
                            RunObject = Report "Intrastat - Form";
                        }
                        action("Foreign Currency Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Foreign Currency Balance';
                            RunObject = Report "Foreign Currency Balance";
                        }
                        action("XBRL Spec. 2 Instance Document")
                        {
                            ApplicationArea = Suite;
                            Caption = 'XBRL Spec. 2 Instance Document';
                            RunObject = Report "XBRL Export Instance - Spec. 2";
                        }
                        action("XBRL Mapping of G/L Accounts")
                        {
                            ApplicationArea = Suite;
                            Caption = 'XBRL Mapping of G/L Accounts';
                            RunObject = Report "XBRL Mapping of G/L Accounts";
                        }
                        action("Reconcile Cust. and Vend. Accs")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Reconcile Cust. and Vend. Accs';
                            RunObject = Report "Reconcile Cust. and Vend. Accs";
                        }
                        action("G/L Deferral Summary")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'G/L Deferral Summary';
                            RunObject = Report "Deferral Summary - G/L";
                        }
                    }
                    group("Group11")
                    {
                        Caption = 'Setup List';
                        action("Chart of Accounts1")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Chart of Accounts';
                            RunObject = Report "Chart of Accounts";
                        }
                        action("Change Log Setup List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Change Log Setup List';
                            RunObject = Report "Change Log Setup List";
                        }
                    }
                }
                group("Group12")
                {
                    Caption = 'Setup';
                    action("General Ledger Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'General Ledger Setup';
                        RunObject = Page "General Ledger Setup";
                    }
                    action("Deferral Template List")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Deferral Templates';
                        RunObject = Page "Deferral Template List";
                    }
                    action("Journal Templates")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'General Journal Templates';
                        RunObject = Page "General Journal Templates";
                    }
                    action("G/L Account Categories")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Account Categories';
                        RunObject = Page "G/L Account Categories";
                        AccessByPermission = TableData 570 = R;
                    }
                    action("XBRL Taxonomies")
                    {
                        ApplicationArea = Suite;
                        Caption = 'XBRL Taxonomies';
                        RunObject = Page "XBRL Taxonomies";
                    }
                    action("VAT Report Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Report Setup';
                        RunObject = Page "VAT Report Setup";
                    }
                }
            }
            group("Group13")
            {
                Caption = 'Cash Management';
                action("Bank Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Accounts';
                    RunObject = Page "Bank Account List";
                }
                action("Receivables-Payables")
                {
                    ApplicationArea = Suite;
                    Caption = 'Receivables-Payables';
                    RunObject = Page "Receivables-Payables";
                }
                action("Payment Registration")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Registration';
                    RunObject = Page "Payment Registration";
                }
                group("Group14")
                {
                    Caption = 'Cash Flow';
                    action("Cash Flow Forecasts")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Forecasts';
                        RunObject = Page "Cash Flow Forecast List";
                    }
                    action("Chart of Cash Flow Accounts")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Chart of Cash Flow Accounts';
                        RunObject = Page "Chart of Cash Flow Accounts";
                    }
                    action("Cash Flow Manual Revenues")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Manual Revenues';
                        RunObject = Page "Cash Flow Manual Revenues";
                    }
                    action("Cash Flow Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Manual Expenses';
                        RunObject = Page "Cash Flow Manual Expenses";
                    }
                    action("Cash Flow Worksheet")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Worksheet';
                        RunObject = Page "Cash Flow Worksheet";
                    }
                }
                group("Group15")
                {
                    Caption = 'Reconciliation';
                    action("Bank Account Reconciliations")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account Reconciliations';
                        RunObject = Page "Bank Acc. Reconciliation List";
                    }
                    action("Posted Payment Reconciliations")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Payment Reconciliations';
                        RunObject = Page "Posted Payment Reconciliations";
                    }
                    action("Payment Reconciliation Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Reconciliation Journals';
                        RunObject = Page "Pmt. Reconciliation Journals";
                    }
                }
                group("Group16")
                {
                    Caption = 'Journals';
                    action("Cash Receipt Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Receipt Journals';
                        RunObject = Page "Cash Receipt Journal";
                    }
                    action("Payment Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Journals';
                        RunObject = Page "Payment Journal";
                    }
                    action("Payment Reconciliation Journals1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Reconciliation Journals';
                        RunObject = Page "Pmt. Reconciliation Journals";
                    }
                }
                group("Group17")
                {
                    Caption = 'Ledger Entries';
                    action("Bank Account Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account Ledger Entries';
                        RunObject = Page "Bank Account Ledger Entries";
                    }
                    action("Check Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Ledger Entries';
                        RunObject = Page "Check Ledger Entries";
                    }
                    action("Cash Flow Ledger Entries1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Ledger Entries';
                        RunObject = Page "Cash Flow Forecast Entries";
                    }
                }
                group("Group18")
                {
                    Caption = 'Reports';
                    action("Register")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account Register';
                        RunObject = Report "Bank Account Register";
                    }
                    action("Check Details")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account - Check Details';
                        RunObject = Report "Bank Account - Check Details";
                    }
                    action("Labels")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account - Labels';
                        RunObject = Report "Bank Account - Labels";
                    }
                    action("List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account - List';
                        RunObject = Report "Bank Account - List";
                    }
                    action("Detail Trial Bal.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Acc. - Detail Trial Bal.';
                        RunObject = Report "Bank Acc. - Detail Trial Bal.";
                    }
                    action("Receivables-Payables1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Receivables-Payables';
                        RunObject = Report "Receivables-Payables";
                    }
                    action("Cash Flow Date List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Date List';
                        RunObject = Report "Cash Flow Date List";
                    }
                    action("Dimensions - Detail1")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Cash Flow Dimensions - Detail';
                        RunObject = Report "Cash Flow Dimensions - Detail";
                    }
                }
                group("Group19")
                {
                    Caption = 'Setup';
                    action("Payment Application Rules")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Application Rules';
                        RunObject = Page "Payment Application Rules";
                    }
                    action("Cash Flow Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Setup';
                        RunObject = Page "Cash Flow Setup";
                    }
                    action("Report Selection - Cash Flow")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Flow Report Selections';
                        RunObject = Page "Report Selection - Cash Flow";
                    }
                    action("Report Selection - Bank Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Selections Bank Account';
                        RunObject = page "Report Selection - Bank Acc.";
                    }
                    action("Payment Terms")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Terms';
                        RunObject = Page "Payment Terms";
                    }
                    action("Payment Methods")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Methods';
                        RunObject = Page "Payment Methods";
                    }
                    action("Currencies")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Currencies';
                        RunObject = Page "Currencies";
                    }
                }
            }
            group("Group20")
            {
                Caption = 'Cost Accounting';
                action("Chart of Cost Centers")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Chart of Cost Centers';
                    RunObject = Page "Chart of Cost Centers";
                }
                action("Chart of Cost Objects")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Chart of Cost Objects';
                    RunObject = Page "Chart of Cost Objects";
                }
                action("Chart of Cost Types")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Chart of Cost Types';
                    RunObject = Page "Chart of Cost Types";
                }
                action("Allocations")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Allocations';
                    RunObject = Page "Cost Allocation Sources";
                }
                action("Cost Budgets")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Budgets';
                    RunObject = Page "Cost Budget Names";
                }
                action("Cost Journal")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Journals';
                    RunObject = Page "Cost Journal";
                }
                group("Group21")
                {
                    Caption = 'Registers';
                    action("Registers")
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Cost Registers';
                        RunObject = Page "Cost Registers";
                    }
                    action("Cost Budget Registers")
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Cost Budget Registers';
                        RunObject = Page "Cost Budget Registers";
                    }
                }
                group("Group22")
                {
                    Caption = 'Reports';
                    group("Group23")
                    {
                        Caption = 'Setup Information';
                        action("Allocations1")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Allocations';
                            RunObject = Report "Cost Allocations";
                        }
                    }
                    group("Group24")
                    {
                        Caption = 'Entries';
                        action("Cost Journal1")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Acctg. Journal';
                            RunObject = Report "Cost Acctg. Journal";
                        }
                        action("Account Details")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Types Details';
                            RunObject = Report "Cost Types Details";
                        }
                    }
                    group("Group25")
                    {
                        Caption = 'Cost & Revenue';
                        action("P/L Statement")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Acctg. Statement';
                            RunObject = Report "Cost Acctg. Statement";
                        }
                        action("P/L Statement per Period")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Acctg. Stmt. per Period';
                            RunObject = Report "Cost Acctg. Stmt. per Period";
                        }
                        action("Analysis")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Acctg. Analysis';
                            RunObject = Report "Cost Acctg. Analysis";
                        }
                    }
                    group("Group26")
                    {
                        Caption = 'Cost Budget';
                        action("P/L Statement with Budget")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Acctg. Statement/Budget';
                            RunObject = Report "Cost Acctg. Statement/Budget";
                        }
                        action("Cost Center")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Acctg. Balance/Budget';
                            RunObject = Report "Cost Acctg. Balance/Budget";
                        }
                    }
                }
                group("Group27")
                {
                    Caption = 'Setup';
                    action("Cost Accounting Setup")
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Cost Accounting Setup';
                        RunObject = Page "Cost Accounting Setup";
                    }
                    action("Cost Journal Templates")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cost Journal Templates';
                        RunObject = page "Cost Journal Templates";
                    }
                }
            }
            group("Group28")
            {
                Caption = 'Receivables';
                action("Customers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customers';
                    RunObject = Page "Customer List";
                }
                action("Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Invoices';
                    RunObject = Page "Sales Invoice List";
                }
                action("Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Credit Memos';
                    RunObject = Page "Sales Credit Memos";
                }
                action("Direct Debit Collections")
                {
                    ApplicationArea = Suite;
                    Caption = 'Direct Debit Collections';
                    RunObject = Page "Direct Debit Collections";
                }
                action("Create Recurring Sales Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Recurring Sales Invoices';
                    RunObject = Report "Create Recurring Sales Inv.";
                }
                action("Register Customer Payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Register Customer Payments';
                    RunObject = Page "Payment Registration";
                }
                group("Group29")
                {
                    Caption = 'Combine';
                    action("Combined Shipments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Combine Shipments...';
                        RunObject = Report "Combine Shipments";
                    }
                    action("Combined Return Receipts")
                    {
                        ApplicationArea = SalesReturnOrder, PurchReturnOrder;
                        Caption = 'Combine Return Receipts...';
                        RunObject = Report "Combine Return Receipts";
                    }
                }
                group("Group30")
                {
                    Caption = 'Reminder/Fin. Charge Memos';
                    action("Reminders")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Reminders';
                        RunObject = Page "Reminder List";
                    }
                    action("Issued Reminders")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Issued Reminders';
                        RunObject = Page "Issued Reminder List";
                    }
                    action("Finance Charge Memos")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Finance Charge Memos';
                        RunObject = Page "Finance Charge Memo List";
                    }
                    action("Issued Finance Charge Memos")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Issued Finance Charge Memos';
                        RunObject = Page "Issued Fin. Charge Memo List";
                    }
                }
                group("Group31")
                {
                    Caption = 'Journals';
                    action("Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Journals';
                        RunObject = Page "Sales Journal";
                    }
                    action("Cash Receipt Journal1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Receipt Journals';
                        RunObject = Page "Cash Receipt Journal";
                    }
                }
                group("Group32")
                {
                    Caption = 'Posted Documents';
                    action("Posted Invoices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Invoices';
                        RunObject = Page "Posted Sales Invoices";
                    }
                    action("Posted Sales Shipments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Shipments';
                        RunObject = Page "Posted Sales Shipments";
                    }
                    action("Posted Credit Memos")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Credit Memos';
                        RunObject = Page "Posted Sales Credit Memos";
                    }
                    action("Posted Return Receipts")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Posted Return Receipts';
                        RunObject = Page "Posted Return Receipts";
                    }
                }
                group("Group33")
                {
                    Caption = 'Registers/Entries';
                    action("G/L Registers1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Registers';
                        RunObject = Page "G/L Registers";
                    }
                    action("Customer Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Ledger Entries';
                        RunObject = Page "Customer Ledger Entries";
                    }
                    action("Reminder/Fin. Charge Entries")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Reminder/Fin. Charge Entries';
                        RunObject = Page "Reminder/Fin. Charge Entries";
                    }
                    action("Detailed Cust. Ledg. Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detailed Customer Ledgerg Entries';
                        RunObject = Page "Detailed Cust. Ledg. Entries";
                    }
                }
                group("Group34")
                {
                    Caption = 'Reports';
                    action("Customer Detailed Aging")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Detailed Aging';
                        RunObject = Report "Customer Detailed Aging";
                    }
                    action("Customer Statement")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Statement';
                        RunObject = Codeunit "Customer Layout - Statement";
                    }
                    action("Customer Register")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Register';
                        RunObject = Report "Customer Register";
                    }
                    action("Customer - Balance to Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Balance to Date';
                        RunObject = Report "Customer - Balance to Date";
                    }
                    action("Customer - Detail Trial Bal.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Detail Trial Bal.';
                        RunObject = Report "Customer - Detail Trial Bal.";
                    }
                    action("Customer - List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - List';
                        RunObject = Report "Customer - List";
                    }
                    action("Customer - Summary Aging")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Summary Aging';
                        RunObject = Report "Customer - Summary Aging";
                    }
                    action("Customer - Summary Aging Simp.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Customer - Summary Aging Simp.';
                        RunObject = Report "Customer - Summary Aging Simp.";
                    }
                    action("Customer - Order Summary")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Order Summary';
                        RunObject = Report "Customer - Order Summary";
                    }
                    action("Customer - Order Detail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Order Detail';
                        RunObject = Report "Customer - Order Detail";
                    }
                    action("Customer - Labels")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Customer Labels';
                        RunObject = Report "Customer - Labels";
                    }
                    action("Customer - Top 10 List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Top 10 List';
                        RunObject = Report "Customer - Top 10 List";
                    }
                    action("Sales Statistics")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Statistics';
                        RunObject = Report "Sales Statistics";
                    }
                    action("Customer/Item Sales")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer/Item Sales';
                        RunObject = Report "Customer/Item Sales";
                    }
                    action("Salesperson - Sales Statistics")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Salesperson Sales Statistics';
                        RunObject = Report "Salesperson - Sales Statistics";
                    }
                    action("Salesperson - Commission")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Salesperson Commission';
                        RunObject = Report "Salesperson - Commission";
                    }
                    action("Customer - Sales List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Sales List';
                        RunObject = Report "Customer - Sales List";
                    }
                    action("Aged Accounts Receivable")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged Accounts Receivable';
                        RunObject = Report "Aged Accounts Receivable";
                    }
                    action("Customer - Trial Balance")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Trial Balance';
                        RunObject = Report "Customer - Trial Balance";
                    }
                    action("EC Sales List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'EC Sales List';
                        RunObject = Report "EC Sales List";
                    }
                }
                group("Group35")
                {
                    Caption = 'Setup';
                    action("Sales & Receivables Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales & Receivables Setup';
                        RunObject = Page "Sales & Receivables Setup";
                    }
                    action("Payment Registration Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Registration Setup';
                        RunObject = Page "Payment Registration Setup";
                    }
                    action("Report Selection Reminder and")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Selections Reminder/Fin. Charge';
                        RunObject = Page "Report Selection - Reminder";
                    }
                    action("Reminder Terms")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reminder Terms';
                        RunObject = Page "Reminder Terms";
                    }
                    action("Finance Charge Terms")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Finance Charge Terms';
                        RunObject = Page "Finance Charge Terms";
                    }
                }
            }
            group("Group36")
            {
                Caption = 'Payables';
                action("Vendors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendors';
                    RunObject = Page "Vendor List";
                }
                action("Invoices1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Invoices';
                    RunObject = Page "Purchase Invoices";
                }
                action("Credit Memos1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Credit Memos';
                    RunObject = Page "Purchase Credit Memos";
                }
                action("Incoming Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Incoming Documents';
                    RunObject = Page "Incoming Documents";
                }
                group("Group37")
                {
                    Caption = 'Journals';
                    action("Purchase Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Journals';
                        RunObject = Page "Purchase Journal";
                    }
                    action("Payment Journals1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Journals';
                        RunObject = Page "Payment Journal";
                    }
                }
                group("Group38")
                {
                    Caption = 'Posted Documents';
                    action("Posted Credit Memos1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Credit Memos';
                        RunObject = Page "Posted Purchase Credit Memos";
                    }
                    action("Posted Purchase Invoices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Invoices';
                        RunObject = Page "Posted Purchase Invoices";
                    }
                    action("Posted Purchase Receipts")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posted Purchase Receipts';
                        RunObject = Page "Posted Purchase Receipts";
                    }
                    action("Posted Return Shipments")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Posted Purchase Return Shipments';
                        RunObject = Page "Posted Return Shipments";
                    }
                }
                group("Group39")
                {
                    Caption = 'Registers/Entries';
                    action("G/L Registers2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Registers';
                        RunObject = Page "G/L Registers";
                    }
                    action("Vendor Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Ledger Entries';
                        RunObject = Page "Vendor Ledger Entries";
                    }
                    action("Detailed Cust. Ledg. Entries1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detailed Vendor Ledger Entries';
                        RunObject = Page "Detailed Vendor Ledg. Entries";
                    }
                    action("Credit Transfer Registers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Credit Transfer Registers';
                        RunObject = Page "Credit Transfer Registers";
                    }
                    action("Employee Ledger Entries")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Employee Ledger Entries';
                        RunObject = Page "Employee Ledger Entries";
                    }
                    action("Detailed Employee Ledger Entries")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Detailed Employee Ledger Entries';
                        RunObject = Page "Detailed Empl. Ledger Entries";
                    }
                }
                group("Group40")
                {
                    Caption = 'Reports';
                    action("Aged Accounts Payable")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged Accounts Payable';
                        RunObject = Report "Aged Accounts Payable";
                    }
                    action("Payments on Hold")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payments on Hold';
                        RunObject = Report "Payments on Hold";
                    }
                    action("Purchase Statistics")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Statistics';
                        RunObject = Report "Purchase Statistics";
                    }
                    action("Vendor Item Catalog")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Item Catalog';
                        RunObject = Report "Vendor Item Catalog";
                    }
                    action("Vendor Register")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Register';
                        RunObject = Report "Vendor Register";
                    }
                    action("Vendor - Balance to Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Balance to Date';
                        RunObject = Report "Vendor - Balance to Date";
                    }
                    action("Vendor - Detail Trial Balance")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Detail Trial Balance';
                        RunObject = Report "Vendor - Detail Trial Balance";
                    }
                    action("Vendor - Labels")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Vendor - Labels';
                        RunObject = Report "Vendor - Labels";
                    }
                    action("Vendor - List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - List';
                        RunObject = Report "Vendor - List";
                    }
                    action("Vendor - Order Detail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Order Detail';
                        RunObject = Report "Vendor - Order Detail";
                    }
                    action("Vendor - Order Summary")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Order Summary';
                        RunObject = Report "Vendor - Order Summary";
                    }
                    action("Vendor - Purchase List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Purchase List';
                        RunObject = Report "Vendor - Purchase List";
                    }
                    action("Vendor - Summary Aging")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Summary Aging';
                        RunObject = Report "Vendor - Summary Aging";
                    }
                    action("Vendor - Top 10 List")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Vendor - Top 10 List';
                        RunObject = Report "Vendor - Top 10 List";
                    }
                    action("Vendor - Trial Balance")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor - Trial Balance';
                        RunObject = Report "Vendor - Trial Balance";
                    }
                    action("Vendor/Item Purchases")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor/Item Purchases';
                        RunObject = Report "Vendor/Item Purchases";
                    }
                }
                group("Group41")
                {
                    Caption = 'Setup';
                    action("Purchases & Payables Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchases & Payables Setup';
                        RunObject = Page "Purchases & Payables Setup";
                    }
                }
            }
            group("Group42")
            {
                Caption = 'Fixed Assets';
                action("Fixed Assets")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets';
                    RunObject = Page "Fixed Asset List";
                }
                action("Insurance")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Insurance';
                    RunObject = Page "Insurance List";
                }
                action("Calculate Depreciation...")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Calculate Depreciation...';
                    RunObject = Report "Calculate Depreciation";
                }
                action("Fixed Assets...")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Index Fixed Assets...';
                    RunObject = Report "Index Fixed Assets";
                }
                action("Insurance...")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Index Insurance...';
                    RunObject = Report "Index Insurance";
                }
                group("Group43")
                {
                    Caption = 'Journals';
                    action("G/L Journals")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA G/L Journals';
                        RunObject = Page "Fixed Asset G/L Journal";
                    }
                    action("FA Journals")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Journals';
                        RunObject = Page "Fixed Asset Journal";
                    }
                    action("FA Reclass. Journal")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Reclassification Journals';
                        RunObject = Page "FA Reclass. Journal";
                    }
                    action("Insurance Journals")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insurance Journals';
                        RunObject = Page "Insurance Journal";
                    }
                    action("Recurring Journals1")
                    {
                        ApplicationArea = Suite, FixedAssets;
                        Caption = 'Recurring General Journals';
                        RunObject = Page "Recurring General Journal";
                    }
                    action("Recurring Fixed Asset Journals")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Recurring Fixed Asset Journals';
                        RunObject = Page "Recurring Fixed Asset Journal";
                    }
                }
                group("Group44")
                {
                    Caption = 'Reports';
                    group("Group45")
                    {
                        Caption = 'Fixed Assets';
                        action("Posting Group - Net Change")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Posting Group - Net Change';
                            RunObject = Report "FA Posting Group - Net Change";
                        }
                        action("Register1")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Register';
                            RunObject = Report "Fixed Asset Register";
                        }
                        action("Acquisition List")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Acquisition List';
                            RunObject = Report "Fixed Asset - Acquisition List";
                        }
                        action("Analysis1")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Analysis';
                            RunObject = Report "Fixed Asset - Analysis";
                        }
                        action("Book Value 01")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Book Value 01';
                            RunObject = Report "Fixed Asset - Book Value 01";
                        }
                        action("Book Value 02")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Book Value 02';
                            RunObject = Report "Fixed Asset - Book Value 02";
                        }
                        action("Details")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Details';
                            RunObject = Report "Fixed Asset - Details";
                        }
                        action("G/L Analysis")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA G/L Analysis';
                            RunObject = Report "Fixed Asset - G/L Analysis";
                        }
                        action("List1")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA List';
                            RunObject = Report "Fixed Asset - List";
                        }
                        action("Projected Value")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Projected Value';
                            RunObject = Report "Fixed Asset - Projected Value";
                        }
                    }
                    group("Group46")
                    {
                        Caption = 'Insurance';
                        action("Uninsured FAs")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Uninsured FAs';
                            RunObject = Report "Insurance - Uninsured FAs";
                        }
                        action("Register2")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Insurance Register';
                            RunObject = Report "Insurance Register";
                        }
                        action("Analysis2")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Insurance Analysis';
                            RunObject = Report "Insurance - Analysis";
                        }
                        action("Coverage Details")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Insurance Coverage Details';
                            RunObject = Report "Insurance - Coverage Details";
                        }
                        action("List2")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Insurance List';
                            RunObject = Report "Insurance - List";
                        }
                        action("Tot. Value Insured")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'FA Total Value Insured';
                            RunObject = Report "Insurance - Tot. Value Insured";
                        }
                    }
                    group("Group47")
                    {
                        Caption = 'Maintenance';
                        action("Register3")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Maintenance Register';
                            RunObject = Report "Maintenance Register";
                        }
                        action("Analysis3")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Maintenance Analysis';
                            RunObject = Report "Maintenance - Analysis";
                        }
                        action("Details1")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Maintenance Details';
                            RunObject = Report "Maintenance - Details";
                        }
                        action("Next Service")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Maintenance Next Service';
                            RunObject = Report "Maintenance - Next Service";
                        }
                    }
                }
                group("Group48")
                {
                    Caption = 'Registers/Entries';
                    action("FA Registers")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Registers';
                        RunObject = Page "FA Registers";
                    }
                    action("Insurance Registers")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insurance Registers';
                        RunObject = Page "Insurance Registers";
                    }
                    action("FA Ledger Entries")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Ledger Entries';
                        RunObject = Page "FA Ledger Entries";
                    }
                    action("Maintenance Ledger Entries")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Maintenance Ledger Entries';
                        RunObject = Page "Maintenance Ledger Entries";
                    }
                    action("Ins. Coverage Ledger Entries")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insurance Coverage Ledger Entries';
                        RunObject = Page "Ins. Coverage Ledger Entries";
                    }
                }
                group("Group49")
                {
                    Caption = 'Setup';
                    action("FA Setup")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Setup';
                        RunObject = Page "Fixed Asset Setup";
                    }
                    action("FA Classes")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Classes';
                        RunObject = Page "FA Classes";
                    }
                    action("FA Subclasses")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Subclasses';
                        RunObject = Page "FA Subclasses";
                    }
                    action("FA Locations")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Locations';
                        RunObject = Page "FA Locations";
                    }
                    action("Insurance Types")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insurance Types';
                        RunObject = Page "Insurance Types";
                    }
                    action("Maintenance")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Maintenance';
                        RunObject = Page "Maintenance";
                    }
                    action("Depreciation Books")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Books';
                        RunObject = Page "Depreciation Book List";
                    }
                    action("Depreciation Tables")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Tables';
                        RunObject = Page "Depreciation Table List";
                    }
                    action("FA Journal Templates")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Journal Templates';
                        RunObject = Page "FA Journal Templates";
                    }
                    action("FA Reclass. Journal Templates")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Reclassification Journal Template';
                        RunObject = Page "FA Reclass. Journal Templates";
                    }
                    action("Insurance Journal Templates")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insurance Journal Templates';
                        RunObject = Page "Insurance Journal Templates";
                    }
                }
            }
            group("Group50")
            {
                Caption = 'Inventory';
                action("Inventory Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Periods';
                    RunObject = Page "Inventory Periods";
                }
                action("Phys. Invt. Counting Periods")
                {
                    ApplicationArea = Warehouse, Basic, Suite;
                    Caption = 'Physical Inventory Counting Periods';
                    RunObject = Page "Phys. Invt. Counting Periods";
                }
                action("Application Worksheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Application Worksheet';
                    RunObject = Page "Application Worksheet";
                }
                group("Group51")
                {
                    Caption = 'Costing';
                    action("Adjust Item Costs/Prices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Item Costs/Prices';
                        RunObject = Report "Adjust Item Costs/Prices";
                    }
                    action("Adjust Cost - Item Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Cost - Item Entries...';
                        RunObject = Report "Adjust Cost - Item Entries";
                    }
                    action("Update Unit Cost...")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Update Unit Costs...';
                        RunObject = Report "Update Unit Cost";
                    }
                    action("Post Inventory Cost to G/L")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Inventory Cost to G/L';
                        RunObject = Report "Post Inventory Cost to G/L";
                    }
                }
                group("Group52")
                {
                    Caption = 'Journals';
                    action("Item Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Journals';
                        RunObject = Page "Item Journal";
                    }
                    action("Item Reclass. Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Reclassification Journals';
                        RunObject = Page "Item Reclass. Journal";
                    }
                    action("Phys. Inventory Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Physical Inventory Journals';
                        RunObject = Page "Phys. Inventory Journal";
                    }
                    action("Revaluation Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revaluation Journals';
                        RunObject = Page "Revaluation Journal";
                    }
                }
                group("Group53")
                {
                    Caption = 'Reports';
                    action("Inventory Valuation")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Valuation';
                        RunObject = Report "Inventory Valuation";
                    }
                    action("Inventory Valuation - WIP")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Production Order - WIP';
                        RunObject = Report "Inventory Valuation - WIP";
                    }
                    action("Inventory - List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - List';
                        RunObject = Report "Inventory - List";
                    }
                    action("Invt. Valuation - Cost Spec.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Invt. Valuation - Cost Spec.';
                        RunObject = Report "Invt. Valuation - Cost Spec.";
                    }
                    action("Item Age Composition - Value")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Age Composition - Value';
                        RunObject = Report "Item Age Composition - Value";
                    }
                    action("Item Register - Value")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Register - Value';
                        RunObject = Report "Item Register - Value";
                    }
                    action("Physical Inventory List")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Physical Inventory List';
                        RunObject = Report "Phys. Inventory List";
                    }
                    action("Status")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Status';
                        RunObject = Report "Status";
                    }
                    action("Cost Shares Breakdown")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Cost Shares Breakdown';
                        RunObject = Report "Cost Shares Breakdown";
                    }
                    action("Item Register - Quantity")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Register - Quantity';
                        RunObject = Report "Item Register - Quantity";
                    }
                    action("Item Dimensions - Detail")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Dimensions - Detail';
                        RunObject = Report "Item Dimensions - Detail";
                    }
                    action("Item Dimensions - Total")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Dimensions - Total';
                        RunObject = Report "Item Dimensions - Total";
                    }
                    action("Inventory - G/L Reconciliation")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - G/L Reconciliation';
                        RunObject = Page "Inventory - G/L Reconciliation";
                    }
                }
                group("Group54")
                {
                    Caption = 'Setup';
                    action("Inventory Posting Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Posting Setup';
                        RunObject = Page "Inventory Posting Setup";
                    }
                    action("Inventory Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Setup';
                        RunObject = Page "Inventory Setup";
                    }
                    action("Item Charges")
                    {
                        ApplicationArea = ItemCharges;
                        Caption = 'Item Charges';
                        RunObject = Page "Item Charges";
                    }
                    action("Item Categories")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Categories';
                        RunObject = Page "Item Categories";
                    }
                    action("Rounding Methods")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Rounding Methods';
                        RunObject = Page "Rounding Methods";
                        AccessByPermission = TableData 156 = R;
                    }
                    action("Analysis Types")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Analysis Types';
                        RunObject = Page "Analysis Types";
                    }
                    action("Inventory Analysis Report")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Inventory Analysis Reports';
                        RunObject = Page "Analysis Report Inventory";
                    }
                    action("Analysis View Card")
                    {
                        ApplicationArea = InventoryAnalysis, Dimensions;
                        Caption = 'Inventory Analysis by Dimensions';
                        RunObject = Page "Analysis View List Inventory";
                    }
                    action("Analysis Column Templates")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Invt. Analysis Column Templates';
                        RunObject = Report "Run Invt. Analysis Col. Temp.";
                    }
                    action("Analysis Line Templates")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Invt. Analysis Line Templates';
                        RunObject = Report "Run Invt. Analysis Line Temp.";
                    }
                }
            }
            group("Group55")
            {
                Caption = 'Setup';
                action("General Posting Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Posting Setup';
                    RunObject = Page "General Posting Setup";
                }
                action("Incoming Documents Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Incoming Documents Setup';
                    RunObject = Page "Incoming Documents Setup";
                }
                action("Accounting Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Accounting Periods';
                    RunObject = Page "Accounting Periods";
                }
                action("Standard Text Codes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Standard Text Codes';
                    RunObject = Page "Standard Text Codes";
                }
                action("No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. Series';
                    RunObject = Page "No. Series";
                }
                group("Group56")
                {
                    Caption = 'VAT';
                    action("Posting Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Posting Setup';
                        RunObject = Page "VAT Posting Setup";
                    }
                    action("VAT Clauses")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Clauses';
                        RunObject = Page "VAT Clauses";
                    }
                    action("VAT Change Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Rate Change Setup';
                        RunObject = Page "VAT Rate Change Setup";
                    }
                    action("VAT Statement Templates")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Statement Templates';
                        RunObject = Page "VAT Statement Templates";
                    }
                    action("VAT Reports Configuration")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Reports Configuration';
                        RunObject = Page "VAT Reports Configuration";
                    }
                }
                group("Group57")
                {
                    Caption = 'Intrastat';
                    action("Intrastat Setup")
                    {
                        ApplicationArea = BasicEU;
                        Caption = 'Intrastat Setup';
                        RunObject = Page "Intrastat Setup";
                    }
                    action("Tariff Numbers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tariff Numbers';
                        RunObject = Page "Tariff Numbers";
                    }
                    action("Transaction Types")
                    {
                        ApplicationArea = BasicEU;
                        Caption = 'Transaction Types';
                        RunObject = Page "Transaction Types";
                    }
                    action("Intrastat Journal Templates")
                    {
                        ApplicationArea = BasicEU;
                        Caption = 'Intrastat Journal Templates';
                        RunObject = Page "Intrastat Journal Templates";
                    }
                }
                group("Group58")
                {
                    Caption = 'Intercompany';
                    action("Intercompany Setup")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Intercompany Setup';
                        RunObject = Page "IC Setup";
                    }
                    action("Partner Code")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Intercompany Partners';
                        RunObject = Page "IC Partner List";
                    }
                    action("Chart of Accounts2")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Intercompany Chart of Accounts';
                        RunObject = Page "IC Chart of Accounts";
                    }
                    action("Dimensions")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Intercompany Dimensions';
                        RunObject = Page "IC Dimensions";
                    }
                }
                group("Group59")
                {
                    Caption = 'Dimensions';
                    action("Dimensions1")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions';
                        RunObject = Page "Dimensions";
                    }
                    action("Analyses by Dimensions1")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Analysis by Dimensions';
                        RunObject = Page "Analysis View List";
                    }
                    action("Dimension Combinations")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimension Combinations';
                        RunObject = Page "Dimension Combinations";
                    }
                    action("Default Dimension Priorities")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Default Dimension Priorities';
                        RunObject = Page "Default Dimension Priorities";
                    }
                }
                group("Group60")
                {
                    Caption = 'Trail Codes';
                    action("Source Codes")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Source Codes';
                        RunObject = Page "Source Codes";
                    }
                    action("Reason Codes")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reason Codes';
                        RunObject = Page "Reason Codes";
                    }
                    action("Source Code Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Source Code Setup';
                        RunObject = Page "Source Code Setup";
                    }
                }
                group("Group61")
                {
                    Caption = 'Posting Groups';
                    action("General Business")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Gen. Business Posting Groups';
                        RunObject = Page "Gen. Business Posting Groups";
                    }
                    action("Gen. Product Posting Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'General Product Posting Groups';
                        RunObject = Page "Gen. Product Posting Groups";
                    }
                    action("Customer Posting Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Posting Groups';
                        RunObject = Page "Customer Posting Groups";
                    }
                    action("Vendor Posting Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Posting Groups';
                        RunObject = Page "Vendor Posting Groups";
                    }
                    action("Bank Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account Posting Groups';
                        RunObject = Page "Bank Account Posting Groups";
                    }
                    action("Inventory Posting Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Posting Groups';
                        RunObject = Page "Inventory Posting Groups";
                    }
                    action("FA Posting Groups")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Posting Groups';
                        RunObject = Page "FA Posting Groups";
                    }
                    action("Business Posting Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Business Posting Groups';
                        RunObject = Page "VAT Business Posting Groups";
                    }
                    action("Product Posting Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Product Posting Groups';
                        RunObject = Page "VAT Product Posting Groups";
                    }
                }
            }
        }
    }
}