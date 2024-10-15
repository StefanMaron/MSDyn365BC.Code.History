namespace Microsoft.Manufacturing.Routing;

page 99000796 "Routing Comment List"
{
    AutoSplitKey = true;
    Caption = 'Comment List';
    DataCaptionExpression = Rec.Caption();
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Routing Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date when the comment was created.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the actual comment.';
                }
                field("Code"; Rec.Code)
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
}

