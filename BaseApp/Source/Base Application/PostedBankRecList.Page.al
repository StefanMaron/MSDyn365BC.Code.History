page 10129 "Posted Bank Rec. List"
{
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    Caption = 'Posted Bank Reconciliations List';
    CardPageID = "Posted Bank Rec. Worksheet";
    Editable = false;
    PageType = List;
    SourceTable = "Posted Bank Rec. Header";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the bank account the reconciliation applies to.';
                }
                field("Statement No."; "Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statement number to be reconciled.';
                }
                field("Statement Date"; "Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the as-of date of the statement. All G/L balances will be calculated based upon this date.';
                }
                field("Statement Balance"; "Statement Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount entered by the operator from the balance found on the bank statement.';
                }
                field("Date Created"; "Date Created")
                {
                    ToolTip = 'Specifies a date automatically populated when the record is created.';
                    Visible = false;
                }
                field("Time Created"; "Time Created")
                {
                    ToolTip = 'Specifies the  time created, which is automatically populated when the record is created.';
                    Visible = false;
                }
            }
        }
    }

#if not CLEAN20
    actions
    {
        area(reporting)
        {
            action("Bank Reconciliation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Reconciliation';
                Image = Worksheet;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Bank Reconciliation";
                ToolTip = 'View the details of the posted bank reconciliation. ';
            }
        }
    }
#endif
}

