page 11741 "Cash Desk Events"
{
    Caption = 'Cash Desk Events';
    Editable = false;
    PageType = List;
    SourceTable = "Cash Desk Event";

    layout
    {
        area(content)
        {
            repeater(Control1220009)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies code of cash desk events.';
                }
                field("Cash Document Type"; "Cash Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the cash desk document represents a cash receipt (Receipt) or a withdrawal (Wirthdrawal)';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description of cash desk events.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account thet the entry will be posted to. To see the options, choose the field.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the entry on the journal line will be posted to.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies default document type for selected cash desk events.';
                }
                field("EET Transaction"; "EET Transaction")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the value of Yes will automatically be filled when the row meets the conditions for a recorded sale.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
    }
}

