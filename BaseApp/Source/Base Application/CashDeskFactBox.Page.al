page 11748 "Cash Desk FactBox"
{
    Caption = 'Cash Desk';
    PageType = CardPart;
    SourceTable = "Bank Account";

    layout
    {
        area(content)
        {
            field("No."; "No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of the cash document.';
            }
            field(CalcBalance; CalcBalance)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statistics';
                ToolTip = 'Specifies the total receipts and withdrawals in cash desk.';
            }
            field(Balance; Balance)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the cash desk card''s current balance denominated in the applicable foreign currency.';
            }
            field("Debit Amount"; "Debit Amount")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total amount that the cash desk consists of, if it is a debit amount.';
            }
            field("Credit Amount"; "Credit Amount")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the cash desk card''s current balance denominated in the applicable foreign currency.';
            }
            field("Balance (LCY)"; "Balance (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the cash desk card''s current balance. The amount is in the local currency.';
            }
            field("Debit Amount (LCY)"; "Debit Amount (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total amount that the cash desk consists of, if it is a debit amount. The amount is in the local currency.';
            }
            field("Credit Amount (LCY)"; "Credit Amount (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total amount that the cash desk consists of, if it is a credit amount. The amount is in the local currency.';
            }
            field("Cashier No."; "Cashier No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the cashier number from employee list.';
            }
            field("Responsibility ID (Release)"; "Responsibility ID (Release)")
            {
                ApplicationArea = Basic, Suite;
                LookupPageID = "User Lookup";
                ToolTip = 'Specifies the responsibility ID for release from employee list.';
            }
            field("Responsibility ID (Post)"; "Responsibility ID (Post)")
            {
                ApplicationArea = Basic, Suite;
                LookupPageID = "User Lookup";
                ToolTip = 'Specifies the responsibility ID for posting from employee list.';
            }
        }
    }

    actions
    {
    }
}

