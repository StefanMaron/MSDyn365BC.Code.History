pageextension 11765 "Chart of Accounts CZL" extends "Chart of Accounts"
{
    actions
    {
        addlast("Periodic Activities")
        {
            action(CloseIncomeStatementCZL)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Close Income Statement CZ';
                Image = CloseYear;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Report "Close Income Statement CZL";
                ToolTip = 'Start the transfer of the year''s result to an account in the balance sheet and close the income statement accounts.';
            }
            action(CloseBalanceSheetCZL)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Close Balance Sheet CZ';
                Image = CloseYear;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Report "Close Balance Sheet CZL";
                ToolTip = 'Start the balances transfer of the balance sheet accounts to an closing balance sheet account and close the balance sheet accounts.';
            }
            action(OpenBalanceSheetCZL)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open Balance Sheet CZ';
                Image = Period;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Report "Open Balance Sheet CZL";
                ToolTip = 'Start the balances transfer of the balance sheet accounts from an opening balance sheet account and close the balance sheet accounts.';
            }
        }
        addafter("Trial Balance by Period")
        {
            action("General Ledger CZL")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'General Ledger';
                Image = Report;
                RunObject = Report "General Ledger CZL";
                ToolTip = 'View, print, or send a report that shows a list of general ledger entries sorted by G/L Account and accounting period. You can use this report at the close of an accounting period or fiscal year and to document your general ledger transactions according law requirements.';
            }
            action("Turnover Report by Glob. Dim. CZL")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Turnover Report by Global Dimensions';
                Image = Report;
                RunObject = Report "Turnover Rpt. by Gl. Dim. CZL";
                ToolTip = 'View, print, or send a report that shows the opening balance by general ledger account, the movements in the selected period of month, quarter, or year, and the resulting closing balance. You can use this report at the close of an accounting period or fiscal year and to document your general ledger transactions according law requirements.';
            }
            action("Joining G/L Account Adjustment CZL")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Joining G/L Account Adjustment';
                Image = Report;
                RunObject = Report "Joining G/L Account Adj. CZL";
                ToolTip = 'Verify that selected G/L account balance is cleared for selected document number.';
            }
            action("General Journal CZL")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'General Journal';
                Image = Report;
                RunObject = Report "General Journal CZL";
                ToolTip = 'View, print, or send a report that shows a list of general ledger entries sorted by date of posting. You can use this report at the close of an accounting period or fiscal year and to document your general ledger transactions according law requirements.';
            }
            action("G/L Account Group Posting Check CZL")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L Account Group Posting Check';
                Image = Report;
                RunObject = Report "G/L Acc. Group Post. Check CZL";
                ToolTip = 'View, print, or send a report that shows a list of general ledger entries sorted by date of posting and document number with different G/L account groups.';
            }
            action("General Ledger Document CZL")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'General Ledger Document';
                Image = Report;
                RunObject = Report "General Ledger Document CZL";
                ToolTip = 'View, print, or send a report of transactions posted to general ledger in form of a document.';
            }
        }
    }
}