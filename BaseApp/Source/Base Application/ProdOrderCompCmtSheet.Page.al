page 99000842 "Prod. Order Comp. Cmt. Sheet"
{
    AutoSplitKey = true;
    Caption = 'Comment List';
    DataCaptionExpression = Caption;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Prod. Order Comp. Cmt Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Date)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the actual comment text.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a code for the comments.';
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
        SetupNewLine;
    end;
}

