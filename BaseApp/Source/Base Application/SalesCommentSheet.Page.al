page 67 "Sales Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Comment Sheet';
    DataCaptionFields = "Document Type", "No.";
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Sales Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Date)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the date the comment was created.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the comment itself.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies a code for the comment.';
                    Visible = false;
                }
                field("Print On Quote"; "Print On Quote")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment line to print on the sales quote document.';
                    Visible = false;
                }
                field("Print On Pick Ticket"; "Print On Pick Ticket")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment line is printed on the pick ticket document.';
                    Visible = false;
                }
                field("Print On Order Confirmation"; "Print On Order Confirmation")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment line is printed on the sales order document.';
                    Visible = false;
                }
                field("Print On Shipment"; "Print On Shipment")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment is printed on the sales shipment document.';
                    Visible = false;
                }
                field("Print On Invoice"; "Print On Invoice")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment is printed on the sales invoice document.';
                    Visible = false;
                }
                field("Print On Credit Memo"; "Print On Credit Memo")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment is printed on the sales credit memo document.';
                    Visible = false;
                }
                field("Print On Return Authorization"; "Print On Return Authorization")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment line is printed on return authorizations.';
                    Visible = false;
                }
                field("Print On Return Receipt"; "Print On Return Receipt")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that this comment line is printed on return receipts.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine;
    end;
}

