page 99000841 "Prod. Order Rtng. Cmt. List"
{
    AutoSplitKey = true;
    Caption = 'Comment List';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Prod. Order Rtng Comment Line";

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
                    ToolTip = 'Specifies a code for the comment.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

