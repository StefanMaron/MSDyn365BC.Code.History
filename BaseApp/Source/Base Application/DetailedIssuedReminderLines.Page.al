page 11790 "Detailed Issued Reminder Lines"
{
    Caption = 'Detailed Issued Reminder Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Detailed Issued Reminder Line";

    layout
    {
        area(content)
        {
            repeater(Control1220013)
            {
                ShowCaption = false;
                field("Issued Reminder No."; "Issued Reminder No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of issued reminder.';
                    Visible = false;
                }
                field("Issued Reminder Line No."; "Issued Reminder Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line number of issued reminder.';
                    Visible = false;
                }
                field("Detailed Customer Entry No."; "Detailed Customer Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of detailed customer entry.';
                    Visible = false;
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line number.';
                    Visible = false;
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the entry.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type of the customer ledger entry this reminder line is for.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the issued reminder number.';
                }
                field("Base Amount"; "Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base amount of the issued reminder lines.';
                    Visible = false;
                }
                field(Days; Days)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of finance charge memo days.';
                }
                field("Interest Rate"; "Interest Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage to use to calculate interest for this reminder.';
                }
                field("Interest Amount"; "Interest Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the interest amounts on the reminder lines.';
                }
                field("Interest Base Amount"; "Interest Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the interest base amount.';
                }
            }
        }
    }

    actions
    {
    }
}

