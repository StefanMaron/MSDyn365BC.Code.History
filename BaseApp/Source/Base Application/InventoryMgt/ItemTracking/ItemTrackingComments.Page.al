page 6506 "Item Tracking Comments"
{
    AutoSplitKey = true;
    Caption = 'Item Tracking Comments';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Item Tracking Comment";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Date)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a date to reference the comment.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the item tracking comment.';
                }
            }
        }
    }

    actions
    {
    }
}

