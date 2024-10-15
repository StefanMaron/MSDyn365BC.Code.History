namespace Microsoft.Manufacturing.Document;

page 99000843 "Prod. Order BOM Cmt List"
{
    AutoSplitKey = true;
    Caption = 'Comment List';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Prod. Order Comp. Cmt Line";

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
                    ToolTip = 'Specifies the date.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the actual comment text.';
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

