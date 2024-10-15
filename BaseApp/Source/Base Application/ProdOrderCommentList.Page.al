page 99000839 "Prod. Order Comment List"
{
    Caption = 'Comment List';
    DataCaptionFields = Status, "Prod. Order No.";
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Prod. Order Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Prod. Order No."; "Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the related production order.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a date.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the comment.';
                }
            }
        }
    }

    actions
    {
    }
}

