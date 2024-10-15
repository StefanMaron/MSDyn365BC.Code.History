#if not CLEAN20
page 11790 "Detailed Issued Reminder Lines"
{
    Caption = 'Detailed Issued Reminder Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Detailed Issued Reminder Line";
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
    ObsoleteReason = 'Replaced by Finance Charge Interest Rate';

    layout
    {
        area(content)
        {
            repeater(Control1220013)
            {
                ShowCaption = false;
                field("Issued Reminder No."; Rec."Issued Reminder No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of issued reminder.';
                    Visible = false;
                }
                field("Issued Reminder Line No."; Rec."Issued Reminder Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line number of issued reminder.';
                    Visible = false;
                }
                field("Detailed Customer Entry No."; Rec."Detailed Customer Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of detailed customer entry.';
                    Visible = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line number.';
                    Visible = false;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the entry.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type of the customer ledger entry this reminder line is for.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the issued reminder number.';
                }
                field("Base Amount"; Rec."Base Amount")
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
                field("Interest Rate"; Rec."Interest Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage to use to calculate interest for this reminder.';
                }
                field("Interest Amount"; Rec."Interest Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the interest amounts on the reminder lines.';
                }
                field("Interest Base Amount"; Rec."Interest Base Amount")
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

#endif