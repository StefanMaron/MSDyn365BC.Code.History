page 2000042 "CODA Statement List"
{
    Caption = 'CODA Statement List';
    CardPageID = "CODA Statement";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "CODA Statement";

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
                    Editable = false;
                    ToolTip = 'Specifies the number of the bank account that the statement has been made for.';
                }
                field("Statement No."; "Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the statement.';
                }
                field("Statement Date"; "Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the statement was created.';
                }
                field("Balance Last Statement"; "Balance Last Statement")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ending balance of the last bank account statement, which you have imported for this bank account.';
                }
                field("Statement Ending Balance"; "Statement Ending Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ending balance of the bank account statement.';
                }
            }
        }
    }

    actions
    {
    }
}

