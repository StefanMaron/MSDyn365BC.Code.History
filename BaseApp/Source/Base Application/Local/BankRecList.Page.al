#if not CLEAN21
page 10124 "Bank Rec. List"
{
    Caption = 'Bank Rec. List';
    CardPageID = "Bank Rec. Worksheet";
    Editable = false;
    PageType = List;
    SourceTable = "Bank Rec. Header";
    ObsoleteReason = 'Deprecated in favor of W1 Bank Reconciliation';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the bank account the reconciliation applies to.';
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statement number to be reconciled.';
                }
                field("Statement Date"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the as-of date of the statement. All G/L balances will be calculated based upon this date.';
                }
                field("Statement Balance"; Rec."Statement Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount entered by the operator from the balance found on the bank statement.';
                }
                field("Date Created"; Rec."Date Created")
                {
                    ToolTip = 'Specifies a date automatically populated when the record is created.';
                    Visible = false;
                }
                field("Time Created"; Rec."Time Created")
                {
                    ToolTip = 'Specifies the  time created, which is automatically populated when the record is created.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control1905344207; "Bank Rec Worksheet FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Bank Account No." = FIELD("Bank Account No."),
                              "Statement No." = FIELD("Statement No.");
                Visible = true;
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("Bank Account - Reconcile")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account - Reconcile';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Bank Account - Reconcile";
                ToolTip = 'Reconcile bank transactions with bank account ledger entries to ensure that your bank account in Dynamics NAV reflects your actual liquidity.';
            }
            action("Bank Rec. Test Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Rec. Test Report';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Bank Rec. Test Report";
                ToolTip = 'View a preliminary draft of the bank reconciliation statement. You can preview, print, or save the bank reconciliation test statement in several file formats. This step in the bank reconciliation process allows you to test the bank reconciliation statement entries for accuracy prior to posting the bank reconciliation statement.';
            }
        }
        area(Promoted)
        {
        }
    }
}

#endif