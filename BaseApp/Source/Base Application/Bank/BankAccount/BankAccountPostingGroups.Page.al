namespace Microsoft.Bank.BankAccount;

page 373 "Bank Account Posting Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Account Posting Groups';
    PageType = List;
    SourceTable = "Bank Account Posting Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the G/L account that bank transactions, such as bank payment reconciliations, are posted to when the bank account card contains this code.';
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account to which bank account entries in this posting group are posted.';
                }
                field("Liabs. for Disc. Bills Acc."; Rec."Liabs. for Disc. Bills Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account that will reflect the debt due to the discounting of bills for this bank general ledger group.';
                }
                field("Bank Services Acc."; Rec."Bank Services Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account that will reflect the banking expenses for document discount management services for this group.';
                }
                field("Discount Interest Acc."; Rec."Discount Interest Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account that will reflect the interest charged for discounting of bills/invoices, for this group.';
                }
                field("Rejection Expenses Acc."; Rec."Rejection Expenses Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account that will reflect the costs derived from the rejection of documents for this group.';
                }
                field("Liabs. for Factoring Acc."; Rec."Liabs. for Factoring Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account that will reflect the debt due to the discounting of invoices for this group.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

